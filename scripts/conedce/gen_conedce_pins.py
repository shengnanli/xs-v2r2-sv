#!/usr/bin/env python3
"""
gen_conedce_pins.py — emit set_user_match pins for the cone-DCE reduced Rob
partition FM, pairing golden flattened `robEntries_<N>_<field>` scalar registers
with the impl `xs_Rob_core` packed `rob_entries[N]` struct field, for ONLY the
robEntries fields that survive the partition's cone.

WHY: cone-DCE removes the golden-ONLY debug_microOp/dt_exuDebug register families
(the biggest match blowup), but the RETAINED robEntries state must still be
name-matched because golden stores it as flat per-(entry,field) scalars while the
impl core stores it as a packed-struct array — FM's signature match across that
representation gap is the residual convergence cost. Because cone-DCE already cut
the ref register population ~16x, the pin count needed here is only the KEPT
fields (e.g. pCommit: ~16 fields x 160 entries) vs the full ~42 fields, and there
are NO golden-only debug arrays left to confuse the match.

These are PURE set_user_match pairings (name-driven bijection between two
registers FM would otherwise match by signature) — NO dont_verify, NO ref
constraint, NO assumption. If a pin pairs non-equivalent registers, verify still
FAILS (fail-closed).

IMPL-PATH TEMPLATE: FM V-2023.12-SP3 does not keep `rob_entries[160]` as a
2D-subscriptable packed reg (see docs/backend/rob_fieldmap/FM_IMPL_PATH_GAP.md:
the naive `u_core/rob_entries_reg[N][bit]` raised FM-036 on 9263/9440 pins). The
REAL impl DFF name must be read from an unpinned match's report_unmatched_points
and supplied via --impl-template. This generator emits both the golden path and a
templated impl path so the correct decomposition can be dropped in once known.

USAGE
  gen_conedce_pins.py --fieldmap rob_field_map.txt --outputs <fam>.txt \
     --top Rob --impl-inst u_core \
     --impl-template 'i:/WORK/{top}/{inst}/rob_entries_reg[{n}][{bit}]' \
     --golden-template 'r:/WORK/{top}/robEntries_{n}_{field}[{fb}]' \
     --out fm_pins_<fam>.tcl
"""
import argparse, re, sys

ROB_SIZE = 160


def load_fieldmap(path):
    fm = []  # (golden_suffix, lo, width)
    for l in open(path):
        l = l.strip()
        if not l or l.startswith('#'):
            continue
        parts = l.split()
        fm.append((parts[0], int(parts[1]), int(parts[2])))
    return fm


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--fieldmap', required=True)
    ap.add_argument('--outputs', required=True,
                    help='partition output list (unused directly; kept fields are '
                         'derived from the reduced golden instead)')
    ap.add_argument('--reduced-golden', required=True,
                    help='reduced golden Rob_golden_<fam>.sv — only its kept '
                         'robEntries_* fields get pinned')
    ap.add_argument('--top', default='Rob')
    ap.add_argument('--impl-inst', default='u_core')
    ap.add_argument('--impl-template',
                    default='i:/WORK/{top}/{inst}/rob_entries_reg[{n}][{bit}]')
    ap.add_argument('--golden-template',
                    default='r:/WORK/{top}/robEntries_{n}_{field}[{fb}]')
    ap.add_argument('--out', required=True)
    args = ap.parse_args()

    fmap = load_fieldmap(args.fieldmap)
    # which robEntries fields survive the cone (present in the reduced golden)?
    red = open(args.reduced_golden).read()
    kept_fields = set()
    for m in re.finditer(r'\brobEntries_(\d+)_([A-Za-z_]+)\b', red):
        kept_fields.add(m.group(2))

    lines = []
    lines.append('# cone-DCE robEntries name-pins (set_user_match), kept fields only')
    lines.append('# golden flat robEntries_<N>_<field> <-> impl packed rob_entries[N]')
    lines.append('# PURE bijection; no dont_verify/constraint/assumption; fail-closed.')
    npins = 0
    for (suf, lo, w) in fmap:
        # normalise golden field-name to the reduced-golden style (they match the
        # fieldmap suffixes already, e.g. valid/uopNum/commitType/...).
        if suf not in kept_fields:
            # also handle name variants used in the reduced golden
            variants = {suf}
            if suf == 'uopNum':
                variants |= {'uopNum'}
            if not (variants & kept_fields):
                continue
        for n in range(ROB_SIZE):
            for b in range(w):
                gpath = args.golden_template.format(top=args.top, n=n, field=suf, fb=b)
                ipath = args.impl_template.format(top=args.top, inst=args.impl_inst,
                                                  n=n, bit=lo + b)
                lines.append(f'set_user_match {gpath} {ipath}')
                npins += 1
    lines.append(f'# total pins: {npins}')
    open(args.out, 'w').write('\n'.join(lines) + '\n')
    print(f"[gen-pins] {args.out}: {npins} pins over {len(kept_fields)} kept fields")


if __name__ == '__main__':
    main()

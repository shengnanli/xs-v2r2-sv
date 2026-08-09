#!/usr/bin/env python3
# gen_perf_completion_manifest.py — perf-partition completion-pin per-family manifest
# ------------------------------------------------------------------------------
# codex 0119 (item1): a *per-family* audit manifest for the two perf-partition
# completion-pin SoA families that A (commit 1ad23ad9) emits inline in
# run_partition_checkpoint.sh's `perf)` EXTRA_PINS block:
#
#   1. debug_lsTopdownInfo (16000 = 160 entries × 100 pins/entry)
#        per entry N=0..159:
#          golden r:/WORK/Rob/debug_lsTopdownInfo_<N>_s1_vaddr_valid_reg
#              <-> impl i:/WORK/Rob/u_core/debug_s1_valid_reg[<N>]
#          golden ..._s2_paddr_valid_reg
#              <-> impl u_core/debug_s2_valid_reg[<N>]
#          golden ..._s1_vaddr_bits_reg[k] k=0..49
#              <-> impl u_core/debug_s1_bits_reg[<N>][k]
#          golden ..._s2_paddr_bits_reg[k] k=0..47
#              <-> impl u_core/debug_s2_bits_reg[<N>][k]
#        per entry = 2 valid + 50 + 48 = 100 ; ×160 = 16000.
#
#   2. walk-pointer (161)
#        per N=0..7:
#          walkPtrVec_<N>_flag  <-> u_core/walkPtrVec_reg[<N>][flag]           (8)
#          walkingPtrVec_<N>_flag <-> u_core/walkingPtrVec_reg[<N>][flag]      (8)
#          donotNeedWalk_<N>    <-> u_core/donotNeedWalk_reg[<N>]              (8)
#          walkPtrVec_<N>_value[k] k=0..7 <-> ...walkPtrVec_reg[<N>][value][k] (64)
#          walkingPtrVec_<N>_value[k] k=0..7 <-> ...walkingPtrVec_reg[<N>][value][k] (64)
#        plus lastWalkPtr:
#          lastWalkPtr_flag     <-> u_core/lastWalkPtr_reg[flag]               (1)
#          lastWalkPtr_value[k] k=0..7 <-> u_core/lastWalkPtr_reg[value][k]    (8)
#        total = 8+8+8+64+64 + 1+8 = 161.
#
# This generator is a READ-ONLY audit layer: it does NOT set_user_match / emit
# any pin into FM. The pins themselves are emitted by A's inline echo block in
# run_partition_checkpoint.sh; this script mirrors those EXACT (ref,impl) path
# pairs and records "which pins are asserted" as the authoritative manifest, with
# a content hash over the sorted pin body. It is FAIL-CLOSED (exit != 0) if any
# enumerated golden reg is ABSENT from the cone-reduced golden — that would mean
# the cone did not retain the head-tracked debug / walk-pointer chain, so the
# corresponding pins would be invalid (FM-036) and the partition would not be
# verifying those compare points.
#
# FM-036 policy for the emitted pins is fail-closed via the driver's _rob_soa_pin
# proc + EXTRA_PIN_ASSERT_FAIL exit 7 (rob_soa_entry_pins.tcl); this manifest
# records that policy but does not re-implement it.
#
# Mirrors the style of gen_robdeqgroup_pins.py (sha256 of sorted pin body,
# per-family emitted_pin_count, path_gen rule, json.dump, fail-closed on missing).
import argparse, json, re, hashlib, sys, os

TOP_DEFAULT = "Rob"
IMPL_PREFIX_DEFAULT = "u_core"

ROB_SIZE = 160         # debug per-entry family width
COMMIT_WIDTH = 8       # walk-pointer vector width
S1_BITS = 50           # debug_s1_vaddr_bits [49:0]
S2_BITS = 48           # debug_s2_paddr_bits [47:0]
PTR_VALUE_W = 8        # rob_ptr_t.value [7:0]


def scan_golden_regs(golden_path):
    """Return the set of flat reg names declared in the reduced golden.

    Matches firtool-style declarations, e.g.:
        reg  [49:0]        debug_lsTopdownInfo_0_s1_vaddr_bits;
        reg                donotNeedWalk_0;
    (The FM compare-point path appends the firtool `_reg` suffix; we scan the
    declaration name WITHOUT `_reg`, exactly like gen_robdeqgroup_pins.py.)
    """
    pat = re.compile(
        r'^\s*reg\s+(?:\[\d+:\d+\]\s+)?([A-Za-z_][A-Za-z_0-9]*)\s*;')
    names = set()
    with open(golden_path) as fh:
        for line in fh:
            m = pat.match(line)
            if m:
                names.add(m.group(1))
    return names


def build_debug_family(top, impl_prefix, present, errors):
    """debug_lsTopdownInfo per-entry SoA family (16000 pins).

    Enumerates the EXACT (ref,impl) pairs A emits at run_partition_checkpoint.sh
    L262-273. Fail-closed: appends to `errors` for any golden reg absent from the
    reduced golden.
    """
    pins = []
    for N in range(ROB_SIZE):
        # 2 valid regs
        for gsuf, imember in (("s1_vaddr_valid", "debug_s1_valid"),
                              ("s2_paddr_valid", "debug_s2_valid")):
            gname = f"debug_lsTopdownInfo_{N}_{gsuf}"
            if gname not in present:
                errors.append(f"MISSING golden reg {gname}")
                continue
            pins.append((
                f"r:/WORK/{top}/{gname}_reg",
                f"i:/WORK/{top}/{impl_prefix}/{imember}_reg[{N}]",
            ))
        # s1 bits[0:49]
        g1 = f"debug_lsTopdownInfo_{N}_s1_vaddr_bits"
        if g1 not in present:
            errors.append(f"MISSING golden reg {g1}")
        else:
            for k in range(S1_BITS):
                pins.append((
                    f"r:/WORK/{top}/{g1}_reg[{k}]",
                    f"i:/WORK/{top}/{impl_prefix}/debug_s1_bits_reg[{N}][{k}]",
                ))
        # s2 bits[0:47]
        g2 = f"debug_lsTopdownInfo_{N}_s2_paddr_bits"
        if g2 not in present:
            errors.append(f"MISSING golden reg {g2}")
        else:
            for k in range(S2_BITS):
                pins.append((
                    f"r:/WORK/{top}/{g2}_reg[{k}]",
                    f"i:/WORK/{top}/{impl_prefix}/debug_s2_bits_reg[{N}][{k}]",
                ))
    return pins


def build_walk_family(top, impl_prefix, present, errors):
    """walk-pointer SoA family (161 pins).

    Enumerates the EXACT (ref,impl) pairs A emits at run_partition_checkpoint.sh
    L302-318 (two echo blocks: walkPtrVec/walkingPtrVec/donotNeedWalk foreach-n,
    then lastWalkPtr). Fail-closed on any absent golden reg.
    """
    pins = []
    # block 1 (gated by walkPtrVec_0_value present): foreach n in 0..7
    for N in range(COMMIT_WIDTH):
        for gname, imember in (
                (f"walkPtrVec_{N}_flag",    f"walkPtrVec_reg[{N}][flag]"),
                (f"walkingPtrVec_{N}_flag", f"walkingPtrVec_reg[{N}][flag]"),
                (f"donotNeedWalk_{N}",      f"donotNeedWalk_reg[{N}]")):
            if gname not in present:
                errors.append(f"MISSING golden reg {gname}")
                continue
            pins.append((f"r:/WORK/{top}/{gname}_reg",
                         f"i:/WORK/{top}/{impl_prefix}/{imember}"))
        # value[0:7]
        for gbase, imember in (
                (f"walkPtrVec_{N}_value",    f"walkPtrVec_reg[{N}][value]"),
                (f"walkingPtrVec_{N}_value", f"walkingPtrVec_reg[{N}][value]")):
            if gbase not in present:
                errors.append(f"MISSING golden reg {gbase}")
                continue
            for k in range(PTR_VALUE_W):
                pins.append((f"r:/WORK/{top}/{gbase}_reg[{k}]",
                             f"i:/WORK/{top}/{impl_prefix}/{imember}[{k}]"))
    # block 2 (gated by lastWalkPtr_value present): lastWalkPtr
    if "lastWalkPtr_flag" not in present:
        errors.append("MISSING golden reg lastWalkPtr_flag")
    else:
        pins.append((f"r:/WORK/{top}/lastWalkPtr_flag_reg",
                     f"i:/WORK/{top}/{impl_prefix}/lastWalkPtr_reg[flag]"))
    if "lastWalkPtr_value" not in present:
        errors.append("MISSING golden reg lastWalkPtr_value")
    else:
        for k in range(PTR_VALUE_W):
            pins.append((f"r:/WORK/{top}/lastWalkPtr_value_reg[{k}]",
                         f"i:/WORK/{top}/{impl_prefix}/lastWalkPtr_reg[value][{k}]"))
    return pins


def family_record(name, pins, expected, path_gen_rule):
    body = "\n".join(f"{r}|{i}" for r, i in sorted(pins))
    return {
        "family": name,
        "emitted_pin_count": len(pins),
        "expected_pin_count": expected,
        "count_ok": len(pins) == expected,
        "path_gen_rule": path_gen_rule,
        "family_root_sha256": hashlib.sha256(body.encode()).hexdigest(),
        "pins": [{"ref": r, "impl": i} for r, i in pins],
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--top", default=TOP_DEFAULT)
    ap.add_argument("--impl-prefix", default=IMPL_PREFIX_DEFAULT)
    ap.add_argument("--reduced-golden", required=True,
                    help="cone-reduced perf golden Rob (must retain the "
                         "debug_lsTopdownInfo + walk-pointer head chains)")
    ap.add_argument("--out", required=True, help="output dir")
    ap.add_argument("--emit-pin-list", action="store_true",
                    help="also write perf_completion_pins.list (auditable "
                         "ref<->impl map; NOT sourced by FM)")
    a = ap.parse_args()

    present = scan_golden_regs(a.reduced_golden)
    errors = []

    debug_pins = build_debug_family(a.top, a.impl_prefix, present, errors)
    walk_pins = build_walk_family(a.top, a.impl_prefix, present, errors)

    debug_fam = family_record(
        "debug_lsTopdownInfo", debug_pins, ROB_SIZE * (2 + S1_BITS + S2_BITS),
        "for N in 0..159: "
        "{s1_vaddr_valid,s2_paddr_valid}_reg<->debug_{s1,s2}_valid_reg[N]; "
        "s1_vaddr_bits_reg[k=0..49]<->debug_s1_bits_reg[N][k]; "
        "s2_paddr_bits_reg[k=0..47]<->debug_s2_bits_reg[N][k] "
        "(100/entry x160 = 16000)")
    walk_fam = family_record(
        "walk_pointer", walk_pins,
        COMMIT_WIDTH * (1 + 1 + 1 + PTR_VALUE_W + PTR_VALUE_W) + (1 + PTR_VALUE_W),
        "for N in 0..7: walkPtrVec_N_flag<->walkPtrVec_reg[N][flag]; "
        "walkingPtrVec_N_flag<->walkingPtrVec_reg[N][flag]; "
        "donotNeedWalk_N<->donotNeedWalk_reg[N]; "
        "{walkPtrVec,walkingPtrVec}_N_value_reg[k=0..7]<->..._reg[N][value][k]; "
        "plus lastWalkPtr_flag<->lastWalkPtr_reg[flag] and "
        "lastWalkPtr_value_reg[k=0..7]<->lastWalkPtr_reg[value][k] (=161)")

    os.makedirs(a.out, exist_ok=True)

    all_pins = sorted(debug_pins + walk_pins)
    total_body = "\n".join(f"{r}|{i}" for r, i in all_pins)
    total_root = hashlib.sha256(total_body.encode()).hexdigest()

    total_expected = debug_fam["expected_pin_count"] + walk_fam["expected_pin_count"]
    manifest = {
        "generator": "gen_perf_completion_manifest.py",
        "codex": "0119 item1",
        "top": a.top,
        "partition": "perf",
        "impl_prefix": a.impl_prefix,
        "reduced_golden": os.path.abspath(a.reduced_golden),
        "purpose": "authoritative per-family record of the perf-partition "
                   "completion pins A (commit 1ad23ad9) emits inline in "
                   "run_partition_checkpoint.sh perf) EXTRA_PINS. Read-only audit "
                   "layer: enumerates the EXACT (ref,impl) pairs asserted, with "
                   "content hash. Does NOT emit/set_user_match any pin itself.",
        "fm036_policy": "fail-closed via _rob_soa_pin (EXTRA_PIN_ASSERT_FAIL exit7)",
        "no_dont_verify": True,
        "no_ref_constraint": True,
        "no_blackbox_added": True,
        "families": [debug_fam, walk_fam],
        "total_pin_count": len(all_pins),
        "total_expected_pin_count": total_expected,
        "total_count_ok": len(all_pins) == total_expected and not errors,
        "total_root_sha256": total_root,
        "bijection_ok": len(errors) == 0,
        "errors": errors,
    }

    out_manifest = f"{a.out}/perf_completion_pins_manifest.json"
    with open(out_manifest, "w") as fh:
        json.dump(manifest, fh, indent=2)

    if a.emit_pin_list:
        with open(f"{a.out}/perf_completion_pins.list", "w") as fh:
            fh.write("# AUTO by gen_perf_completion_manifest.py — auditable "
                     "ref<->impl map (NOT sourced by FM; A's runner echo is the "
                     "emit path). manifest total_root sha256 = "
                     f"{total_root}\n")
            for r, i in all_pins:
                fh.write(f"{r}  <->  {i}\n")

    print(f"[perf-completion-manifest] "
          f"debug_lsTopdownInfo={debug_fam['emitted_pin_count']}"
          f"(exp {debug_fam['expected_pin_count']},ok={debug_fam['count_ok']}) "
          f"walk_pointer={walk_fam['emitted_pin_count']}"
          f"(exp {walk_fam['expected_pin_count']},ok={walk_fam['count_ok']}) "
          f"total={len(all_pins)}(exp {total_expected}) "
          f"bijection_ok={manifest['bijection_ok']} root={total_root[:12]}")
    if errors:
        for e in errors[:12]:
            print("  ", e)
        print(f"  (+{len(errors)-12} more)" if len(errors) > 12 else "", end="")
        sys.exit(2)
    if not manifest["total_count_ok"]:
        print(f"  COUNT MISMATCH total={len(all_pins)} expected={total_expected}")
        sys.exit(3)


if __name__ == "__main__":
    main()

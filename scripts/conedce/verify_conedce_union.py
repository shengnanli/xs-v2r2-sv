#!/usr/bin/env python3
"""verify_conedce_union.py — independent union verifier for the cone-DCE Rob
partition derivatives (defense in depth; re-parses the reduced module ports
directly, not the generator bookkeeping).

Asserts, over the 5 reduced golden modules (all named `Rob`, one per family):
  * TOTAL    : union of their exposed OUTPUT ports == the full golden Rob
               authored output set (2343) — no omission.
  * DISJOINT : no output exposed by >=2 partitions — no overlap.
  * NO WIDTH DRIFT : each exposed output's width == the golden width.
  * INPUT PARITY   : each reduced module's INPUT set == golden input set
               (identical constraints as the full proof — no dropped/added input).
  * IMPL SURFACE MATCH : each reduced IMPL module exposes the SAME output set as
               its reduced golden partner (ref/impl surfaces agree).
Fail-closed: any violation -> nonzero exit.
"""
import re, sys, os, hashlib, json

GOLDEN = "/home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv"
FAMS = ['commit', 'exception', 'perf', 'vecexcp', 'lsq']


def parse_ports(path, modname='Rob'):
    lines = open(path).read().split('\n')
    start = None
    for i, l in enumerate(lines):
        if re.match(r'^\s*module\s+' + re.escape(modname) + r'\s*\(', l):
            start = i
            break
    if start is None:
        raise SystemExit(f"module {modname} not found in {path}")
    outs, ins = {}, {}
    i = start + 1
    while i < len(lines):
        l = lines[i]
        if re.match(r'^\s*\);', l):
            break
        m = re.match(r'^\s*(output|input)\b(\s*\[[^\]]*\])?\s+([A-Za-z_][A-Za-z0-9_$]*)\s*,?\s*$', l)
        if m:
            (outs if m.group(1) == 'output' else ins)[m.group(3)] = (m.group(2) or '').strip()
        i += 1
    return outs, ins


def main():
    gen = sys.argv[1] if len(sys.argv) > 1 else '/tmp/rob-conedce-evidence/gen'
    g_outs, g_ins = parse_ports(GOLDEN)
    print(f"golden Rob: {len(g_outs)} outputs, {len(g_ins)} inputs")

    seen = {}
    union = set()
    fail = 0
    for fam in FAMS:
        rp = os.path.join(gen, f'Rob_golden_{fam}.sv')
        ip = os.path.join(gen, f'Rob_impl_{fam}.sv')
        r_outs, r_ins = parse_ports(rp)
        i_outs, i_ins = parse_ports(ip)
        # disjoint + width drift
        for o, w in r_outs.items():
            if o in seen:
                print(f"OVERLAP: {o} in {seen[o]} and {fam}"); fail += 1
            seen[o] = fam
            union.add(o)
            if o not in g_outs:
                print(f"ALIEN OUTPUT: {o} in {fam} not in golden"); fail += 1
            elif w != g_outs[o]:
                print(f"WIDTH DRIFT: {o} {fam}={w} golden={g_outs[o]}"); fail += 1
        # input parity (reduced golden must keep ALL golden inputs)
        if set(r_ins.keys()) != set(g_ins.keys()):
            missing = set(g_ins) - set(r_ins); extra = set(r_ins) - set(g_ins)
            print(f"INPUT DRIFT {fam}: missing={len(missing)} extra={len(extra)}")
            if missing:
                print("   e.g. missing:", sorted(missing)[:5])
            fail += 1
        # impl surface must match reduced golden surface
        if set(i_outs.keys()) != set(r_outs.keys()):
            print(f"IMPL/REF SURFACE MISMATCH {fam}: "
                  f"ref-only={sorted(set(r_outs)-set(i_outs))[:5]} "
                  f"impl-only={sorted(set(i_outs)-set(r_outs))[:5]}")
            fail += 1
        print(f"  {fam}: {len(r_outs)} outs (ref) / {len(i_outs)} outs (impl), "
              f"{len(r_ins)} ins")

    # total coverage
    missing = set(g_outs) - union
    if missing:
        print(f"OMISSION: {len(missing)} golden outputs in NO partition:",
              sorted(missing)[:8]); fail += 1
    if len(union) != len(g_outs):
        print(f"COUNT MISMATCH: union {len(union)} != golden {len(g_outs)}"); fail += 1

    union_hash = hashlib.sha256('\n'.join(sorted(union)).encode()).hexdigest()
    golden_hash = hashlib.sha256('\n'.join(sorted(g_outs)).encode()).hexdigest()
    print(f"union outputs: {len(union)}  union_sha256={union_hash}")
    print(f"golden output-set sha256={golden_hash}")
    if union_hash != golden_hash:
        print("UNION HASH != GOLDEN OUTPUT-SET HASH"); fail += 1

    if fail:
        print(f"CONEDCE_UNION_VERIFIER: FAIL ({fail} violations)")
        sys.exit(1)
    print("CONEDCE_UNION_VERIFIER: PASS "
          f"(total+disjoint+no-drift+input-parity+impl-surface, {len(union)} outputs)")


if __name__ == '__main__':
    main()

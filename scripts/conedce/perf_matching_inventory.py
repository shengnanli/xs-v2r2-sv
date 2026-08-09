#!/usr/bin/env python3
"""
perf_matching_inventory.py — machine-readable matching-completeness inventory for
a cone-DCE Rob FM checkpoint run (codex 0118-A). Parses the FM report files
(passing.rpt / failing.rpt / unverified.rpt / unmatched.rpt) into a per-register
FAMILY breakdown (ref count, impl count, matched, passing, failing, unverified,
unmatched-ref, unmatched-impl), and — when a second (baseline, e.g. pCommit) run
directory is given — the per-family DIFF (which families are unmatched in this run
but matched in the baseline = the matching-completeness gap).

This does NOT run FM. It is a static post-processor over already-produced reports
(used to produce before/after inventories around a slicer/pin-setup change).

USAGE
  perf_matching_inventory.py --run <dir_with_rpts> --out <inventory.json>
       [--baseline <dir_with_rpts>] [--label perf] [--baseline-label pcommit]
"""
import argparse, json, os, re, sys

REF_RE  = re.compile(r"^\s+Ref\s+\S+\s+r:/WORK/\w+/(.+?)\s*$")
IMPL_RE = re.compile(r"^\s+Impl\s+\S+\s+i:/WORK/\w+/(?:u_core/)?(.+?)\s*$")
FAIL_HDR = re.compile(r"^(\d+)\s+Failing compare points")
PASS_HDR = re.compile(r"^(\d+)\s+Passing compare points")
UNV_HDR  = re.compile(r"^(\d+)\s+Unverified compare points")
UNM_HDR  = re.compile(r"^(\d+)\s+Unmatched points\s+\((\d+)\s+reference,\s+(\d+)\s+implementation\)")


def famname(sig):
    """Collapse a per-instance/per-bit register signal to its family key.
    e.g. debug_lsTopdownInfo_37_s1_vaddr_bits_reg[10] -> debug_lsTopdownInfo_N_s1_vaddr_bits
         robBanksRaddrThisLine_reg[11]                -> robBanksRaddrThisLine
         vtypeBuffer/walkSize_reg[2]                  -> vtypeBuffer/walkSize
         debug_s1_bits[37][10]  (impl array)          -> debug_s1_bits
         walkPtrVec_reg[0]\\[value][2] (impl)          -> walkPtrVec
    """
    s = sig
    # drop trailing bit / array indices  [..]  and escaped \[..]
    s = re.sub(r"\\?\[[^\]]*\]", "", s)
    # drop trailing _reg
    s = re.sub(r"_reg$", "", s)
    # collapse numeric instance ids  _<n>_  and  _<n>$  to _N
    s = re.sub(r"_\d+(?=_)", "_N", s)
    s = re.sub(r"_\d+$", "_N", s)
    return s


def parse_report(path, which):
    """which in {ref, impl}. Returns list of (family, raw_sig)."""
    out = []
    if not os.path.exists(path):
        return out
    rx = REF_RE if which == "ref" else IMPL_RE
    for line in open(path, errors="replace"):
        m = rx.match(line)
        if m:
            sig = m.group(1)
            out.append((famname(sig), sig))
    return out


def header_counts(path):
    d = {}
    if not os.path.exists(path):
        return d
    for line in open(path, errors="replace"):
        for key, rx in (("failing", FAIL_HDR), ("passing", PASS_HDR),
                        ("unverified", UNV_HDR)):
            m = rx.match(line)
            if m:
                d[key] = int(m.group(1))
        m = UNM_HDR.match(line)
        if m:
            d["unmatched_total"] = int(m.group(1))
            d["unmatched_ref"] = int(m.group(2))
            d["unmatched_impl"] = int(m.group(3))
    return d


def build(run):
    rc_path = os.path.join(run, "rc.txt")
    rc = open(rc_path).read().strip() if os.path.exists(rc_path) else "?"
    fams = {}

    def bump(fam, key, n=1):
        fams.setdefault(fam, dict(passing=0, failing=0, unverified=0,
                                  unmatched_ref=0, unmatched_impl=0))[key] += n

    for rpt, key in (("passing.rpt", "passing"),
                     ("failing.rpt", "failing"),
                     ("unverified.rpt", "unverified")):
        # compare points are listed as a Ref line (representative); count by Ref.
        for fam, _ in parse_report(os.path.join(run, rpt), "ref"):
            bump(fam, key)
    for fam, _ in parse_report(os.path.join(run, "unmatched.rpt"), "ref"):
        bump(fam, "unmatched_ref")
    for fam, _ in parse_report(os.path.join(run, "unmatched.rpt"), "impl"):
        bump(fam, "unmatched_impl")

    hdr = {}
    for rpt in ("passing.rpt", "failing.rpt", "unverified.rpt", "unmatched.rpt"):
        hdr.update(header_counts(os.path.join(run, rpt)))
    return dict(run=run, rc=rc, header=hdr, families=fams)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--baseline")
    ap.add_argument("--label", default="run")
    ap.add_argument("--baseline-label", default="baseline")
    args = ap.parse_args()

    cur = build(args.run)
    result = dict(label=args.label, **cur)

    if args.baseline:
        base = build(args.baseline)
        result["baseline_label"] = args.baseline_label
        result["baseline"] = dict(run=base["run"], rc=base["rc"], header=base["header"])
        # matching gap: families UNMATCHED (either side) in run but fully matched in baseline
        gap = []
        for fam, d in sorted(cur["families"].items()):
            un = d["unmatched_ref"] + d["unmatched_impl"]
            if un == 0:
                continue
            bd = base["families"].get(fam, dict(unmatched_ref=0, unmatched_impl=0,
                                                passing=0, failing=0, unverified=0))
            bun = bd["unmatched_ref"] + bd["unmatched_impl"]
            gap.append(dict(
                family=fam,
                run_unmatched_ref=d["unmatched_ref"],
                run_unmatched_impl=d["unmatched_impl"],
                run_failing=d["failing"], run_unverified=d["unverified"],
                run_passing=d["passing"],
                baseline_unmatched=bun,
                baseline_passing=bd["passing"],
                baseline_present=fam in base["families"],
                is_matching_gap=(bun == 0 and un > 0),
            ))
        result["matching_gap_families"] = gap
        result["matching_gap_count"] = sum(1 for g in gap if g["is_matching_gap"])

    json.dump(result, open(args.out, "w"), indent=2, sort_keys=True)
    # human summary to stdout
    print(f"=== inventory {args.label}  run={args.run} rc={cur['rc']} ===")
    print("header:", json.dumps(cur["header"]))
    print(f"{'family':44s} {'pass':>6} {'fail':>6} {'unver':>6} {'unm_r':>6} {'unm_i':>6}")
    for fam, d in sorted(cur["families"].items(),
                         key=lambda kv: -(kv[1]["unmatched_ref"] + kv[1]["unmatched_impl"]
                                          + kv[1]["failing"])):
        tot = (d["unmatched_ref"] + d["unmatched_impl"] + d["failing"]
               + d["unverified"] + d["passing"])
        if tot == 0:
            continue
        print(f"{fam:44s} {d['passing']:6d} {d['failing']:6d} {d['unverified']:6d} "
              f"{d['unmatched_ref']:6d} {d['unmatched_impl']:6d}")
    if args.baseline:
        print(f"\nmatching_gap_count (unmatched here but matched in {args.baseline_label}): "
              f"{result['matching_gap_count']}")
        for g in result["matching_gap_families"]:
            if g["is_matching_gap"]:
                print(f"  GAP {g['family']:40s} run_unm={g['run_unmatched_ref']}/{g['run_unmatched_impl']} "
                      f"fail={g['run_failing']} baseline_pass={g['baseline_passing']}")


if __name__ == "__main__":
    main()

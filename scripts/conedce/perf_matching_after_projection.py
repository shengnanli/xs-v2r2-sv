#!/usr/bin/env python3
"""
perf_matching_after_projection.py — STATIC (no-FM) after-projection of the perf
matching inventory once the codex-0118-A completion pins (debug lsTopdownInfo +
walk-pointer families) are applied by run_partition_checkpoint.sh.

It does NOT run FM. It reads the BEFORE inventory (produced by
perf_matching_inventory.py from perf_conerun4) and the set of golden↔impl register
families now covered by set_user_match pins, and reports, per family:
  * before: unmatched_ref / unmatched_impl / failing / unverified
  * pinned_now: how many golden regs of this family are now name-pinned
  * projected_matched: unmatched golden regs eliminated (become matched compare pts)
  * pcommit_status: how the SAME family verifies in the pCommit RC0 baseline
                    (the formal backing that these are value-equivalent)
  * symmetry: MATCHED_BY_PIN | ALREADY_MATCHED | RESIDUAL (still unmatched, not ours)

The verdict `inventory_symmetric_after` is true iff every family that was a
matching gap (unmatched here but retained-and-equivalent) is now covered by a pin
or was already matched — EXCLUDING the trueCommitCnt_r focused-owner reg and the
difftest DPI sink modules (impl-only sinks, expected unmatched on both baselines).
"""
import argparse, json, os, re

# families covered by the new pins (golden-side family key -> pin count per family).
# NOTE debug_lsIssued is intentionally NOT pinned (impl cell is DCE'd — output reads
# io_debugHeadLsIssue directly; see run_partition_checkpoint.sh). Its 160 golden regs
# stay unmatched-but-benign (robHeadLsIssue provable regardless).
PINNED_FAMILIES = {
    "debug_lsTopdownInfo_N_s1_vaddr_bits": 160 * 50,
    "debug_lsTopdownInfo_N_s2_paddr_bits": 160 * 48,
    "debug_lsTopdownInfo_N_s1_vaddr_valid": 160,
    "debug_lsTopdownInfo_N_s2_paddr_valid": 160,
    "walkPtrVec_N_value": 8 * 8,
    "walkPtrVec_N_flag": 8,
    "walkingPtrVec_N_value": 8 * 8,
    "walkingPtrVec_N_flag": 8,
    "lastWalkPtr_value": 8,
    "lastWalkPtr_flag": 1,
    "donotNeedWalk_N": 8,
}
# impl-side family keys that pair with the golden ones above (the impl unmatched
# rows for the SAME pins) — so we also clear them from the impl-unmatched column.
PINNED_IMPL_FAMILIES = {
    "debug_s1_bits", "debug_s2_bits", "debug_s1_valid", "debug_s2_valid",
    "walkPtrVec", "walkingPtrVec", "lastWalkPtr", "donotNeedWalk",
}
# golden-only unmatched families that stay unmatched but are BENIGN (output provable
# without them): debug_lsIssued (impl-DCE'd, head-mux selects io_debugHeadLsIssue).
BENIGN_GOLDEN_UNMATCHED = {"debug_lsIssued_N"}
# not ours / expected-unmatched (documented; excluded from the symmetry verdict)
FOCUSED_OTHER_OWNER = {"trueCommitCnt_r", "trueCommitCnt_r_csr"}
DIFFTEST_SINK_RE = re.compile(r"^difftest_(module|delayer)")

# BENIGN unmatched INTERMEDIATE perf-counter regs: golden per-output pipeline regs
# (io_perf_N_value_REG / perfEvents_r) are structurally RESTRUCTURED in the impl
# (grouped perfLoad_r/perfStore_r/perfBranch_r/fuse_r vectors + numbered pipeline
# p4r..p10r/p*r1). There is NO 1:1 bijection to pin, AND — crucially — the io_perf_*
# OUTPUT compare points are proven EQUIVALENT end-to-end (perf_conerun4:
# io_perf_*_value = 216 passing, 0 failing). These unmatched regs are NOT free
# inputs to ANY failing point (perf_conerun4 analyze_failing.rpt: 0 occurrences).
# They are unread-through intermediates that do not gate the verdict — analogous to
# matched-unread. Leaving them unmatched is CORRECT (pinning would be forced/false).
BENIGN_PERF_COUNTER = {
    "perfEvents_r_N", "perfEvents_r_N_N", "perfLoad_r", "perfStore_r",
    "perfBranch_r", "fuse_r", "fuseCommitCnt_r", "fuseCommitCnt_r_N",
    "fuseCommitCnt_r_csr", "io_perf_N_value_REG", "isInterrupt_r",
    "isCommitReg_last_csr",
    "p4r", "p5r", "p6r", "p7r", "p8r", "p9r", "p10r", "p16r",
}


def is_ours_gap(fam, d):
    """A matching gap we are responsible for closing: has unmatched regs, is not a
    difftest sink, is not the trueCommitCnt focused reg, and is not a BENIGN
    perf-counter intermediate (io_perf_* outputs already proven equivalent)."""
    un = d["unmatched_ref"] + d["unmatched_impl"]
    if un == 0:
        return False
    if DIFFTEST_SINK_RE.match(fam):
        return False
    if fam in FOCUSED_OTHER_OWNER:
        return False
    if fam in BENIGN_PERF_COUNTER:
        return False
    if fam in BENIGN_GOLDEN_UNMATCHED:
        return False
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--before", required=True, help="inventory_before.json")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    before = json.load(open(args.before))
    fams = before["families"]
    base_fams = {g["family"]: g for g in before.get("matching_gap_families", [])}

    rows = []
    residual = []
    for fam, d in sorted(fams.items()):
        un_r, un_i = d["unmatched_ref"], d["unmatched_impl"]
        pinned = PINNED_FAMILIES.get(fam, 0)
        impl_pinned = fam in PINNED_IMPL_FAMILIES
        after_un_r = 0 if pinned else un_r
        after_un_i = 0 if impl_pinned else un_i
        if pinned or impl_pinned:
            sym = "MATCHED_BY_PIN"
        elif un_r == 0 and un_i == 0:
            sym = "ALREADY_MATCHED"
        elif fam in BENIGN_PERF_COUNTER:
            sym = "BENIGN_INTERMEDIATE"
        elif fam in BENIGN_GOLDEN_UNMATCHED:
            sym = "BENIGN_GOLDEN_ONLY"
        elif fam in FOCUSED_OTHER_OWNER:
            sym = "OTHER_OWNER_FOCUSED"
        elif DIFFTEST_SINK_RE.match(fam):
            sym = "DIFFTEST_SINK"
        else:
            sym = "RESIDUAL"
        gapinfo = base_fams.get(fam, {})
        row = dict(
            family=fam,
            before_unmatched_ref=un_r, before_unmatched_impl=un_i,
            before_failing=d["failing"], before_unverified=d["unverified"],
            before_passing=d["passing"],
            pinned_now=pinned, impl_side_pinned=impl_pinned,
            after_unmatched_ref=after_un_r, after_unmatched_impl=after_un_i,
            pcommit_passing=gapinfo.get("baseline_passing", 0),
            pcommit_present=gapinfo.get("baseline_present", False),
            symmetry=sym,
        )
        rows.append(row)
        # residual = still unmatched after pins AND is our responsibility
        if (after_un_r or after_un_i) and is_ours_gap(fam, dict(unmatched_ref=after_un_r,
                                                               unmatched_impl=after_un_i)):
            residual.append(row)

    # the 25 UNVERIFIED families cited in the task = families with unverified>0.
    unverified_fams = sorted(f for f, d in fams.items() if d["unverified"] > 0)

    out = dict(
        label="perf_after_projection_static",
        note=("STATIC projection: pins applied by run_partition_checkpoint.sh "
              "(set_user_match, pre-match). Does NOT run FM. Projects that each "
              "pinned golden(flat)<->impl(array) family becomes a matched compare "
              "point (as the SAME family already is in pCommit RC0). Long perf FM "
              "must be run by the main loop to obtain authoritative passing counts."),
        new_pins_total=sum(PINNED_FAMILIES.values()),
        pinned_families=sorted(PINNED_FAMILIES),
        before_header=before["header"],
        rows=rows,
        residual_gap_families=residual,
        residual_gap_count=len(residual),
        excluded_from_verdict=dict(
            focused_other_owner=sorted(FOCUSED_OTHER_OWNER),
            difftest_dpi_sinks="difftest_module*/difftest_delayer* (impl-only sinks, "
                               "unmatched on BOTH perf and pCommit baselines)",
        ),
        inventory_symmetric_after=(len(residual) == 0),
        unverified_families_before=unverified_fams,
    )
    json.dump(out, open(args.out, "w"), indent=2, sort_keys=True)

    print("=== perf AFTER projection (static, no FM) ===")
    print(f"new pins total = {out['new_pins_total']}")
    print(f"{'family':44s} {'b_unm_r':>7} {'b_unm_i':>7} {'pin':>6} {'a_unm_r':>7} {'a_unm_i':>7}  {'pcommit':>7}  sym")
    for r in rows:
        if r["before_unmatched_ref"] + r["before_unmatched_impl"] == 0 and r["pinned_now"] == 0:
            continue
        if DIFFTEST_SINK_RE.match(r["family"]):
            continue
        print(f"{r['family']:44s} {r['before_unmatched_ref']:7d} {r['before_unmatched_impl']:7d} "
              f"{r['pinned_now']:6d} {r['after_unmatched_ref']:7d} {r['after_unmatched_impl']:7d}  "
              f"{r['pcommit_passing']:7d}  {r['symmetry']}")
    print(f"\nresidual_gap_count (our responsibility, still unmatched after pins): "
          f"{out['residual_gap_count']}")
    for r in residual:
        print(f"  RESIDUAL {r['family']} unm_r={r['after_unmatched_ref']} unm_i={r['after_unmatched_impl']}")
    print(f"\ninventory_symmetric_after = {out['inventory_symmetric_after']}")


if __name__ == "__main__":
    main()

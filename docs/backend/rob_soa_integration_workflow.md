# Rob SoA full-migration — INTEGRATION WORKFLOW (codex 0104, Rob-SoA-integrator)

Sole integrator: `Rob-SoA-integrator`. Base agent/soa-canary-fix@a63efe4.
Worktree /tmp/rob-soa-integ, branch agent/rob-soa-integ. Evidence /tmp/rob-soa-integ-evidence.

## Group → owner → fields (from frozen inventory; root hash
##  a07cd2f3652b1560132f1267f01e4307638c268e21eef8ce952f329c4d67a9a9)
- G1 (SoA-group-1): needFlush, interrupt_safe, mmio, isRVC, isVset, isHls,
      realDestSize, instrSize, commitType   (9 new; valid/uopNum/stdWritebacked
      already SoA by canary → G1 delivers the remaining 9 lifecycle/control/status)
- G2 (SoA-group-2): ftqIdx_flag, ftqIdx_value, ftqOffset
- G3 (SoA-group-3): vls, vxsat, dirtyVs, wflags, fflags, rfWen, fpWen
- G4 (SoA-group-4): traceBlockInPipe_itype, _iretire, _ilastsize
      ★ilastsize array MUST be 1-bit (golden 1b; impl struct bit[1] cone-dead)★

## Absorption order (serial, one group at a time)
G1 → checkpoint-eligible after 2 → G2 → **★2-GROUP CHECKPOINT★** → G3 → G4.
Each group, in order:
1. Take the DELIVERED (committed) owner patch (git branch agent/soa-gN or a
   supplied .patch). In-flight uncommitted owner worktree edits are NOT absorbed.
2. Apply to /tmp/rob-soa-integ on top of prior absorbed groups. Resolve conflicts
   by field-disjoint union (see below).
3. Per-group co-sim: packed-ref (xs_Rob_core_packed_ref, frozen) vs SoA
   (xs_Rob_core) — `run_cosim.sh <seed> gN` — MUST be checks>1000 errors=0 for
   seed 1/7/42.
4. Full UT regression (tb.sv smoke + tb_cosim + any partition tb) errors=0.
5. FMR gate: `run_fmr_check.sh gN` — FMR_VLOG-091=0 AND FMR_ELAB-118=0
   (impl read_sverilog). Persist across all groups.
6. Commit to agent/rob-soa-integ. THEN start next group.

## Conflict resolution (all groups touch same 4 regions, disjoint fields)
The 5 edit clusters in rtl/backend/Rob.sv (base line numbers, will drift):
- DECL block (~L313-319): add `logic [W-1:0] rob_<field> [ROB_SIZE];` +
  DELETE the field from `rob_entry_t rob_entries_nf`'s implied storage (nf reset/update).
- RECONSTRUCTION always_comb (~L320-326): add
  `rob_entries[i].<struct_field> = rob_<field>[i];`
- NEXT-STATE always_comb (new; per canary/G3 pattern): add array
  `rob_<field>_next[i] = rob_entries_next[i].<struct_field>;`
- RESET loop (~L1063-1089): remove `rob_entries_nf[i].<struct_field> <= ...;`,
  add `rob_<field>[i] <= '0;` (or golden reset value).
- UPDATE loop (~L1139-1163): remove `rob_entries_nf[i].<struct_field> <= rob_entries_next[i].<f>;`,
  add `rob_<field>[i] <= rob_<field>_next[i];`
Because each field's lines are independent, a textual 3-way conflict between two
groups is resolved by KEEPING BOTH groups' field lines (union). The integrator
verifies the resolution by: (a) each field appears in exactly one decl + one
reconstr + one next + one reset + one update line, (b) the field is REMOVED from
rob_entries_nf (no double-store), (c) co-sim + FMR pass.

## DONE gate (after all 4 groups)
- rob_entries_nf FULLY DELETED (all 25 fields moved to SoA arrays; no packed
  storage struct left; `rob_entries` becomes pure reconstruction from 25 SoA arrays).
- 25 SoA arrays × 160 entries cover exactly the 25 impl-stored fields (no dup/gap).
- field-map bijection/width/reset/update audit passes (build_rob_soa_field_inventory.py
  + a coverage grep of Rob.sv confirms decl/reset/update count == 25).
- state-equation audit: valid priority (commit>enq>flush>hold) + per-field
  next-state identical to packed_ref → co-sim errors=0 all seeds.
- NO double-store / NO dont_verify / NO assumption / NO new logic blackbox /
  NO hand scalar / NO golden _GEN. FMR_VLOG-091=0 / FMR_ELAB-118=0.

## ★2-GROUP CHECKPOINT (codex 0104, after G1+G2)★
Regenerate golden+impl cone-DCE pCommit (agent/rob-conedce slicer +
scripts/conedce/) against the SoA impl and measure:
- ref reg bits / impl reg bits
- total compare points (baseline **60714**)
- field-map applied / failed
- model-building time
- 30-min matched%
EXPECTATION: compare points fall clearly toward <30k (SoA per-field naming lets
FM name-match instead of signature-matching the packed struct array). IF nearly
unchanged / mapping fails → STOP absorbing G3/G4, re-audit slicer/RTL shape.

## Harness (evidence dir)
- run_cosim.sh <seed> <label> — packed-ref vs SoA, 94 outputs/cycle, 200k.
- run_fmr_check.sh <label>    — impl read_sverilog, FMR-091/118 count.
- build_rob_soa_field_inventory.py — regen frozen inventory + audit.
- rob_soa_golden_impl_namemap.py   — golden↔impl width bijection.

## Discipline (codex 0104)
Serial heavy FM (OOM-safe). NO pkill -f (exact PID; every FM PID logged with
owner/worktree/commit). Not self-promoted — main-owned changes returned as a list.

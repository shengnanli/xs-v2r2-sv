# Rob SoA integration — STATUS (codex 0104, Rob-SoA-integrator)

Date: 2026-08-03. Branch agent/rob-soa-integ @ (see git log). Base a63efe4.

## Phase 1 (freeze field inventory) — ★DONE★
- 25 impl-stored fields (59b/entry, 9440 reg-bits) + 2 golden-only DPI sink
  (debug_ldest 6b, debug_pdest 8b) machine-parsed & audited.
- field_inventory_root_sha256 = a07cd2f3652b1560132f1267f01e4307638c268e21eef8ce952f329c4d67a9a9
- 4-group partition: partition_ok=true, 12+3+7+3=25, NO dup / NO gap.
- golden↔impl width bijection: 24/25 exact; 1 nuance (ilastsize golden 1b vs impl
  struct 2b → G4 array must be 1-bit). See rob_soa_field_inventory.md.

## Phase 2 (serial absorb 4 patches) — ★BLOCKED on owner delivery★
As of this snapshot, ALL four owner branches are 0 commits ahead of base a63efe4:
- agent/soa-g1 : 0 committed (in-flight uncommitted Rob.sv in worktree)
- agent/soa-g2 : 0 committed (in-flight uncommitted Rob.sv in worktree)
- agent/soa-g3 : 0 committed (in-flight uncommitted Rob.sv in worktree)
- agent/soa-g4 : 0 committed (no uncommitted edits at snapshot)
Owners are actively coding but (at first snapshot) had NOT delivered committed
patches. Per the serial-absorption contract (each patch = delivered,
co-sim/UT/FMR-passing unit), in-flight uncommitted worktree edits are NOT absorbed.

★UPDATE (late in session): agent/soa-g3 delivered 1 commit (58f49a5 "Rob SoA G3:
exception/redirect/vector state family → SoA"). Validated structurally READY:
- 7 SoA arrays declared with correct widths (rob_vls/vxsat/dirty_vs/wflags/rf_wen/
  fp_wen 1-bit + rob_fflags 5-bit) matching frozen inventory G3 exactly.
- reconstruction + next-state arrays added; nf reset+update lines for all 7 fields
  REMOVED (no double-store: `rob_entries_nf[i].vls` count=0; disjoint G1 field
  `mmio` still in nf count=2 — untouched, correct).
- matches canary pattern + documented workflow. Co-sim/UT/FMR gates PENDING
  in-order absorption.
BUT per absorption ORDER (G1→G2→[2-grp checkpoint]→G3→G4), G3 is NOT absorbed yet:
G1+G2 must land and be absorbed first (checkpoint gates on G1+G2; out-of-order
absorb complicates conflict resolution + violates codex 0104 checkpoint discipline).
G1 (agent/soa-g1) and G2 (agent/soa-g2) remain 0 committed → STILL BLOCKED.★

Absorption begins the moment G1 commits its group patch (then G2, then absorb the
already-delivered G3, then G4).

## Ready-to-run harness (committed under verif/ut/Rob_partitions/soa_integ/;
##  originals in /tmp/rob-soa-integ-evidence/)
- run_cosim.sh <seed> <label>  — packed-ref (xs_Rob_core_packed_ref, frozen) vs
  SoA (xs_Rob_core), 94 outputs/cycle, 200k. Validated: tb_cosim compiles clean
  (4 modules, VCS W-2024.09-SP1), simv_cosim builds. (200k run under 11+ concurrent
  owner sims is slow; harness proven, run to completion when contention clears.)
- run_fmr_check.sh <label> + fmr_check.tcl — impl read_sverilog, asserts
  FMR_VLOG-091=0 / FMR_ELAB-118=0. (Canary already established both=0 at a63efe4.)
- Absolute paths point at /tmp/rob-soa-integ (integrator worktree); adjust RTL/TBDIR
  vars if run elsewhere.

## Machine load caution (codex 0104 OOM discipline)
At snapshot: 25 concurrent VCS/fm heavy procs (owner co-sims), load avg 17. Did NOT
launch integrator FM into this load (would contend with owner runs; no new info vs
canary's established FMR=0). Heavy FM runs serially when load clears. NO pkill used.

## Next actions (once a patch lands)
1. Absorb G1 → co-sim seed 1/7/42 errors=0 → UT errors=0 → FMR 091/118=0 → commit.
2. Absorb G2 → same gates → commit.
3. ★2-GROUP CHECKPOINT★: cone-DCE pCommit (agent/rob-conedce slicer scripts/conedce/)
   on SoA impl; report ref/impl reg bits + compare points (baseline 60714) +
   field-map applied/failed + model-build time + 30-min matched%. Expect fall toward
   <30k; if nearly unchanged/mapping fails → STOP, re-audit slicer/RTL.
4. Absorb G3, G4 → DONE gate (rob_entries_nf fully deleted, 25-field coverage,
   bijection/width/reset/update + state-equation audit).
5. pCommit official RC0 → pLsqDeep → 3 parallel → 2343 union verifier.

# Rob pre-FM cone-DCE partition derivative (codex 0100 Lane 2)

Owner: `Rob-cone-DCE`. Branch `agent/rob-conedce` (base `8e07c98`; impl A+B
integration artifacts imported from freeze commit `2d486d4`). Evidence:
`/tmp/rob-conedce-evidence/`.

## Problem
The monolithic / route-B partition Rob FM does not converge: **142481 compare
points**, `match` stuck ~11% at 3.3 h. Route B (`agent/rob-routeB`) split the
proof by OUTPUT cone but each partition wrapper still instantiates the FULL `Rob`
(golden ref / impl `Rob_wrapper`), so FM reads and matches the ENTIRE model
before any cone pruning — the wall is the golden side's ~35000 flattened
`robEntries_*` / `debug_microOp_debugReg_*` / `dt_exuDebug_*` scalar registers
(the last two are difftest/debug-only, golden-ONLY, with no impl counterpart, so
they blow up `match`).

## Solution — pre-FM cone-DCE
For each partition, **physically remove** from BOTH sides, BEFORE FM reads them,
all logic/registers not in the transitive fanin cone of that partition's output
family. FM then builds only the family's cone → compare points collapse.

The golden `Rob.sv` is a single FLAT firtool module (no structs/generate/memory;
scalar `wire`/`reg`, `assign`, three `always @(posedge)` blocks, 23 leaf
instances). This makes a deterministic source-level cone slice tractable.

## Tool + exact invocation (locked)
Self-written cone-slicer (no yosys/sv2v/verilator available; firtool cannot
re-process post-firtool SV). Python 3.6.8.

* `scripts/conedce/rob_cone_slicer.py` (+ `always_tree.py`) — REF side. Builds
  the transitive fanin cone of a partition's outputs over the flat golden
  (combinational `wire`/`assign`, per-register statement-level pruning inside the
  `always @(posedge)` blocks via a recursive if/else-if/else tree, and leaf
  instance input→output cones using the golden leaf port directions), then emits
  a byte-faithful reduced module keeping ONLY cone declarations/statements/
  instances. Off-cone logic is physically deleted.
    argv: `rob_cone_slicer.py --src <golden Rob.sv> --module Rob
           --outputs verif/signoff/conedce/outlists/<fam>.txt --keep-name Rob
           --out Rob_golden_<fam>.sv --report report_golden_<fam>.json`
* `scripts/conedce/impl_port_trim.py` — IMPL side. The impl top
  (`Rob_wrapper.sv`, `xs_Rob_core u_core (.*)` + 7 golden leaves) already has a
  compact register population (no golden-style flattened debug arrays), so only
  its OUTPUT PORT SURFACE is trimmed to the family (off-family outputs demoted to
  internal wires, drivers preserved). Trivially sound (removing outputs never
  changes kept-output behaviour); no logic/reg/leaf dropped.
    argv: `impl_port_trim.py --src <Rob_wrapper.sv> --module Rob
           --outputs <fam>.txt --out Rob_impl_<fam>.sv`
* `scripts/conedce/gen_all.sh` — deterministic driver for all 5 families +
  hash manifest (`conedce_manifest.tsv`); aborts if frozen golden hash mismatches.

Output family lists (`outlists/<fam>.txt`) are taken VERBATIM from the
union-verified route-B classifier (`docs/backend/rob_partition_coverage.tsv`,
2343 outputs, union sha256 `5d76debcf845…`) — NOT re-invented.

## Soundness
* Pure fanin-cone slice: a statement/decl/instance is kept iff its LHS/output
  net reaches a kept output. Removed logic has no path to any kept output ⇒ every
  kept output is bit-identical to the full design. Registers are cone-transparent
  (kept reg + its next-state fanin preserved to input/reg boundary); conditions
  gating a kept register write are preserved.
* NO dont_verify / assumption / constant-forcing / added blackbox. The 7
  official-PASS child leaves remain both-side-elaborated leaf instances
  (RenameBuffer / VTypeBuffer / SnapshotGenerator_3 / ExceptionGen /
  NewRobDeqPtrWrapper / RobEnqPtrWrapper + difftest chain). The only black boxes
  are the difftest DPI-C sinks (same 9 as `allow/Rob.json`).
* Over-removal is never silent: a wrongly dropped driver either fails VCS
  elaboration (undriven net) or produces an FM mismatch — never a false PASS.
* Self-check gate `fm_conedce_selfcheck.tcl`: FM(reduced-golden vs FULL golden)
  must be equivalent on the kept outputs.

## Reduction achieved (register signals kept / 9446 total; compare-point proxy)
| family | outputs | reg signals kept | reduced lines |
|---|---|---|---|
| commit   | 135  | 2665 | 70301 |
| exception| 35   | 1794 | 63632 |
| perf     | 81   | 4465 | 98876 |
| vecexcp  | 28   | 1435 | 58790 |
| lsq      | 2064 | 1777 | 65792 |
All 5 remove the golden-only `debug_microOp` / `dt_exuDebug` arrays entirely for
the small partitions (24480 + 3520 register writes), the primary `match` wall.

## Gates run
* Determinism: `regen_check.sh` → **PASS** (two clean regens byte-identical, all
  10 derivatives + manifest).
* Negative tests: `negtest.sh` → **PASS** (N1 drop-output surface regression /
  N2 wrong golden hash aborts / N3 changed argv → different hash / N4 removing a
  kept register driver breaks VCS elaboration — all fail-closed).
* Structural: all 5 reduced goldens + reduced impls elaborate clean in VCS.

## Canary order (codex 0100)
pCommit first (compare-point reduction target ≥1 order); then pLsqDeep; then the
remaining 3; then root union verifier confirms 2343-output coverage. Root record
`fm-partition-union-v1` = 5 sidecar digests + shared source/tool hashes + output
union hash + 5 RUNNER_RC=0. NOT promoted on any single-partition / sim result.

## pCommit canary result (HONEST) — see pCommit_match_evidence.txt
FM reached the `Matching` phase and ran at BOUNDED memory (peak 4740 MB, vs the
route-B 6.5 GB OOM wall) — cone-DCE breaks the memory / model-build wall. But:
* FM match candidate total = **60714** (vs monolithic 142481) = **only ~2.3x**,
  NOT the ≥10x target. Reason: cone-DCE reduces the GOLDEN ref side ~16x
  (114500→7079 reg bits) but the IMPL side `xs_Rob_core rob_entries[160]` packed
  struct (~32000 bits) is NOT internally reduced — `impl_port_trim` keeps u_core
  whole (the packed-struct core updates the whole array in one always_comb/ff, so
  per-field slicing would be a readable-core RTL rewrite = crosses the "no
  functional-RTL change" line for a proof artifact). The impl core registers now
  dominate the compare points.
* The unpinned match on the golden-flat-scalar ↔ impl-packed-struct correspondence
  is SLOW (13% matched in 3229 s / 54 min) — the same signature-match cost route-B
  hit. The run was killed by SIGTERM from the harness (PID 17743 = /usr/bin/claude
  reclaiming the long background task), NOT by OOM and NOT by this owner.

Per the canary rule (>30k compare points ⇒ keep refining DCE, don't start the
others), the remaining 4 partitions were NOT launched.

### Path to RC0 (next round, honest residual)
The compare-point COUNT (60714) is tractable; the blocker is signature-match TIME
across the scalar/struct representation gap. Two options:
1. **name-pin** the retained robEntries (gen_conedce_pins.py, kept-fields-only,
   ~15 fields for pCommit) → O(N²) signature match → O(N) name match. Blocked on
   FM's REAL impl DFF decomposition path: the naive `u_core/rob_entries_reg[N][bit]`
   raises FM-036 on 9263/9440 (docs/backend/rob_fieldmap/FM_IMPL_PATH_GAP.md). The
   real path must be read from a COMPLETED unpinned match's report_unmatched_points
   (this run was killed at 13% before that report). fm_conedce_partition_pinned.tcl
   sources `$FM_PINS` before match, ready once the path is known.
2. **impl-core internal reduction** to ~10x — requires rewriting the readable
   core's rob_entry_t / update logic (invasive; out of scope for a pure proof
   artifact).

Deliverables (generator + all gates PASS) are complete and independently valuable;
per-partition RC0 is NOT achieved and is reported honestly (not fabricated).

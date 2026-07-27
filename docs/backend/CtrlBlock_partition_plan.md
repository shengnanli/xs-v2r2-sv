# CtrlBlock FM Signoff — Model-Build Bottleneck Diagnosis + Partition Proof Plan

Author: Worker H (agent/ctrlblock-w). Status: DIAGNOSIS + FIRST PARTITION CANARY.
**CtrlBlock is NOT signoff-ready.** This document records the honest state.

---

## 1. Model-build bottleneck diagnosis (WHY the monolithic run stalls)

The monolithic `make fm-CtrlBlock` (`scripts/fm_eq.tcl`) reads, on **both** the
reference and implementation sides, the golden CtrlBlock top **plus all 22
submodule instances' RTL bodies** (`FM_REF_DEPS_CtrlBlock` / `SUB_DEPS` in
`verif/ut/CtrlBlock/Makefile`). Formality therefore flattens a combined design
of roughly:

| submodule (G0 golden)          | lines   | inst pins |
|--------------------------------|--------:|----------:|
| Rob                            | 220,873 | 4,416     |
| NewDispatch                    |  20,468 | 7,633     |
| RenameTableWrapper             |   8,005 | 2,788     |
| Rename                         |   6,470 | 1,857     |
| DecodeStage                    |   9,792 | 1,076     |
| PipeGroupConnect / Fusion / …  |  ~8,000 | —         |
| **CtrlBlock glue top**         |  41,426 | (2520 top ports) |
| **combined**                   | **~320,000+** | |

Fresh reproduce (`SIGNOFF_EVIDENCE_ROOT=/tmp/ctrlblock-w-evidence bash
scripts/sidecar/run_signoff_target.sh scripts/sidecar/manifest_305.json
CtrlBlock 3600`) confirms the stall is **`Status: Elaborating design Rob …`**
during **ref-side verification-model construction** — it never reaches
`Matching`. Snapshot at 14 min / 97% CPU still in Rob elaboration
(`/tmp/ctrlblock-w-evidence/monolithic-stall/fm.log`).

**Root cause = model-build SCALE, not equivalence.** The dominant cost is
Rob (220K lines, a 160-entry ROB: per-entry `uopNum`, exception vectors, flags,
FTQ pointers → tens of thousands of DFF compare points that FM must build,
merge-dedup, and later attempt to match). NewDispatch (20K) and the rename/rat
chain add the rest. The CtrlBlock glue itself is small by comparison.

Corroborating memory (`ctrlblock-rewrite.md` round10): when a machine finally
did push through, the "failing" set was **640× `rob/robEntries_N_uopNum_reg`** —
i.e. the failures FM eventually reports are all inside the *identical Rob*
elaborated on both sides. Those are a **modeling artifact** of building the huge
identical Rob twice with different driving-structure symbolic init, not a real
glue bug. They bury the real signal.

---

## 2. Partition strategy (SOUND — no dont_verify / no point deletion / no timeout hack)

Key structural fact: the readable core `xs_CtrlBlock_core` (via
`ctrlblock_inst.svh`) **instantiates the byte-identical golden submodules by the
same instance names** as golden `CtrlBlock` (`rob`, `dispatch`, `rename`, `rat`,
`decode`, `redirectGen`, `snpt`, `pcMem`, …). So the ONLY logic that differs
between ref and impl is the **CtrlBlock glue** (pipeline staging, redirect
staging, decode-buffer FSM, writeback compression, snapshot flushVec, enqRob
packing, output staging).

**Partition = black-box the 22 submodules SYMMETRICALLY** by NOT feeding their
`.sv` bodies to `read_sverilog`; `hdlin_unresolved_modules black_box` then makes
every submodule a black box on **both** sides. FM then:
- builds a verification model for the **glue only** (tractable: ~8 min vs stall),
- inserts **boundary compare points** at each black-box's I/O pins,
- proves the glue's DFFs and the glue→black-box input pins equivalent.

### Composition obligations (what must ALSO be proven for the partition to be sound)

The glue-partition proof is valid **only in conjunction with**:

1. **Each black-boxed submodule S: prove ref(S) ≡ impl(S).**
   In the current setup this is *trivially discharged*: the impl instantiates
   the **same golden `.sv` file** for every S, so ref(S) and impl(S) are the
   identical netlist by construction. In the full REPLACEMENT program each S is
   its own signoff target (Rob, NewDispatch, Rename, … proven separately) and
   this obligation becomes each of those targets' own FM pass.

2. **Interface/boundary equality.** Every black-box instance must present the
   *same port list and connectivity* on both sides. The canary's
   `162 unmatched ref primary-input / black-box-output pins` (all
   `rob/io_commits_*`) are the ONE boundary gap to resolve: golden's `rob`
   black-box exposes `io_commits_*` outputs that fan into glue; the impl's `rob`
   boundary must expose the same pin set 1:1 so these become matched cut-points
   rather than unmatched. (This is a pin-naming/connectivity reconciliation at
   the boundary, not a logic difference — the underlying Rob is identical.)

3. **No hidden combinational path across a black box.** Because a black box hides
   its internals, any glue equivalence that depends on submodule *internal*
   behaviour would be under-verified. CtrlBlock glue only consumes submodule
   *outputs* as pipeline inputs (registered), so the boundary is clean; the
   canary's `unverified` points (6,093) are exactly the black-box boundary
   compare points (BBPin/BBNet) that are, by construction, deferred to
   obligation #1 above.

### Partition block list (blocks × interfaces)

For the CtrlBlock top the natural partition is ONE glue block + 22 leaf blocks:

| block | contents | interface | proof |
|-------|----------|-----------|-------|
| **GLUE** (this canary) | CtrlBlock top logic minus submodules | 2520 top ports + 22 black-box instance boundaries | THIS canary (20 glue diffs remain) |
| Rob | 160-entry ROB | 4,416 pins | separate target (identical golden today) |
| NewDispatch | dispatch | 7,633 pins | separate target |
| Rename / RenameTableWrapper | rename+rat | 1,857 / 2,788 pins | separate target |
| DecodeStage / FusionDecoder | decode | 1,076 / — pins | separate target |
| RedirectGenerator, SnapshotGenerator_14, pcMem, MemCtrl, GPAMem, Trace, Pipe*×8, DelayN* | small leaves | small | separate/trivial |

---

## 3. First partition canary — RESULT (native facts)

Harness: `verif/ut/CtrlBlock/fm_canary_glue.tcl` + `run_canary.sh`
(evidence: `/tmp/ctrlblock-w-evidence/glue-partition-canary/`).

- **Model build COMPLETED** in **490 s wall / 472 s CPU / 1176 MB** — vs the
  monolithic run which never finished Rob elaboration in >14 min. **Partition
  makes the model build tractable. (primary goal achieved.)**
- Verify: **68,212 passing / 20 failing / 0 aborted / 6,093 unverified
  (black-box boundary) / 1,964 not-compared const-reg.**
- The **20 failing are ALL glue-local DFFs** in 4 clusters (none in Rob):
  - **A** `io_frontend_toFtq_ftqIdxAhead_0_{value[0:5],valid}` ↔ `ftqAheadValueR/ValidR` (7)
  - **B** `redirectGen_io_oldestExuRedirect_bits_r_cfiUpdate_{backendIAF/IGPF/IPF,isMisPred,pc}` ↔ `oldestExuRedirectBits[cfiUpdate_*]`
  - **C** `flushVecNext_last_REG[,_1,_2,_3]` ↔ `flushVecNext_reg[0..3]` (5)
  - **D** `decodeBufValid_5` ↔ `decodeBufValid_reg[5]` (1)

These 4 clusters exactly match what memory rounds 5/9/10 flagged as
"NOT done" (ftqIdxAhead / io_frontend_toFtq_redirect chain) or "rolled back as
harmful" (cfiUpdate_backend). **The partition surfaced the real remaining glue
work that the monolithic run's Rob stall hid.**

---

## 4. Close-out path for the glue partition (future work, ordered)

1. **cfiUpdate (cluster B)** — golden latches `oldestExuRedirect.cfiUpdate.*`
   from the *selected-oldest* exu redirect payload; the impl's
   `oldestExuRedirectBits` currently mis-drives cfi backend fields (round10 tried
   forcing 0 → broke redirectGen internals, so it was reverted; but reverting
   left them non-equivalent). Needs the real per-candidate cfiUpdate select.
2. **ftqIdxAhead (cluster A)** — implement the `s6_flushFromRob` delay chain →
   redirectGen `_r` staging that produces `io_frontend_toFtq_ftqIdxAhead`
   (round5/9 deferred this).
3. **flushVecNext (cluster C)** — snapshot flushVec *output* staging register
   (distinct from the internal flushVec prefix-OR fixed in round9).
4. **decodeBufValid_5 (cluster D)** — lane-5 decode-buffer FSM corner.
5. **Boundary reconciliation** — align `rob/io_commits_*` black-box output pins
   1:1 so the 162 unmatched boundary pins become matched cut-points.
6. Only when GLUE = 0 failing / 0 unverified-that-matter **AND** each leaf
   block's own signoff target passes → CtrlBlock is composed-equivalent.

Until then: **the monolithic signoff-strict CtrlBlock target is NOT ready and
must not be promoted.** UT (200k×3 seeds errors=0) is functional evidence but is
NOT FM equivalence.

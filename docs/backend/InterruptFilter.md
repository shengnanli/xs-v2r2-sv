# InterruptFilter (NewCSR) — readable rewrite

RISC-V interrupt priority resolution + M/HS/VS delegation + virtual-interrupt
(hvictl/hvip) injection.  This is the last real CSR-field-logic module of NewCSR.

## Files
- `rtl/backend/newcsr_intrfilter_prims.sv` — readable parametric primitives:
  - `xs_iprio_merge` — the 2-input min-priority merge node (`minIprio`) that every
    priority-reduction tree node performs.  Selects the winning interrupt between
    a left/right candidate `{enable, isZero, greaterThan255, prioNum[7:0],
    idx[5:0]}`; `THRESH` is the per-tree idx region split (M=0x19, HS=0x1C,
    HV=0x20).  gt255 is carried by the external MEIP/SEIP leaf (reg 3) whose
    priority comes from the 11-bit mtopei/stopei IPRIO.  Unifies golden's
    a-gt255 / b-gt255 / plain node variants in one bit-exact primitive.
  - `xs_delay_n` — the 5-stage shift register backing the DelayN cells, plus the
    golden-named `DelayN_17` / `DelayN_210` wrappers.  IMPORTANT: despite the
    names these are NOT 17/210-cycle delays — the golden bodies are identical
    5-stage (REG..REG_4) shift registers of width 1 / 8; the suffix is only the
    CIRCT dedup id.  Elaborated on both FM sides (no black box).
- `rtl/backend/InterruptFilter.sv` — the readable core (module name
  `InterruptFilter`, golden-identical 312 ports).  Read DIRECTLY on the FM impl
  side (flat, no wrapper hierarchy).
- `rtl/backend/InterruptFilter_xs.sv` — the UT twin: an IDENTICAL-body copy of the
  core with the module renamed to `InterruptFilter_xs`, so the dual-instantiation
  UT compares golden `InterruptFilter` vs impl `InterruptFilter_xs` (distinct
  names ⇒ genuine comparison, not self-vs-self; verified by a bug-injection
  negative control that produces `MISMATCH` lines).
- `scripts/sidecar/gen_intrfilter.py` — the generator (see below).  Emits both the
  core and its twin from the same body.

## How it was written (generator, correct-by-construction)
`gen_intrfilter.py` machine-de-obfuscates the golden CIRCT-flattened RTL
(12,816 lines) into the readable core, preserving every expression bit-for-bit:
1. Extract the golden module body verbatim.
2. Drop the two sim-only blocks (randomize `initial`, `ifndef SYNTHESIS` VS
   candidate mutual-exclusion asserts) — they never affect datapath equivalence.
3. Factor the 19 uniform output-tree merge nodes (`mipriosRegTmp_result_*`,
   `hsipriosRegTmp_result_*`, `hvipriosRegTmp_result_*`, excluding the two top
   `*RegTmp_result` nodes whose internal predicates are re-used by the
   `io_out_{mtopi,stopi}_IPRIO` assigns) into single `xs_iprio_merge` instances.
   Constant-0 operand fields (the never-written `hvipriosReg_7_prioNum`) are wired
   to `8'h0`, matching golden's fold.  Orphaned `_GEN_` fold-helper wires are
   dead-code-eliminated.
4. Rename all residual CIRCT `_T_`/`_GEN_`/`_WIRE` noise to readable names
   (`*_sel_N` for the input sorting-network selectors, `mIidDec_N` for the
   IID-decode Mux1H chains, `mAnyPending`/`hsAnyPending`, etc.).  The generated
   core has ZERO `_T_`/`_GEN_`/`_WIRE` tokens.
5. The M/HS input-sorting reduction network (`ipriosTmp_result_*`) is a large,
   CIRCT-constant-folded sorter with per-node-specialized idx handling; it is
   transcribed faithfully (renamed, not force-factored) so it stays bit-exact.

## Structure recovered from golden
- **Priority trees**: three 8-leaf binary reduction trees (M / HS / HV) over the
  registered `mipriosReg_0..7` / `hsipriosReg_0..7` / `hvipriosReg_0..7` pipeline
  buckets.  gt255 propagates only up the left branch of the M/HS trees (reg 3 =
  external MEIP/SEIP, priority from the 11-bit mtopei/stopei IPRIO).
- **Priority order (M)**: LCOFIP > SGEIP > MEIP > VSEIP > SEIP > MTIP > VSTIP >
  STIP > MSIP > VSSIP > SSIP (delegated bits masked by mideleg).
- **Masking**: per-privilege effective enable `ip & ie & ~delegate & mode_ie`.
- **VS injection**: 5-candidate selection (Candidate1..5) with mutual exclusion
  (≤1 of {C1,C2,C3}, ≤1 of {C4,C5}, not both C2&C5) driving `vstopi_IID/IPRIO`.

## Verification
- **FM (signoff-strict)**: native `Verification SUCCEEDED`, 0 failing, 0 aborted,
  0 black box, `dont_verify=false`, 0 unmatched_impl.
  - Under a plain (non-SYNTHESIS) elaboration: 393 passing / 0 unmatched — fully
    clean.
  - Under the signoff `-define SYNTHESIS` elaboration: 383 passing / 0 failing /
    **4 unmatched_ref** = golden-only constant-0 registers
    `delayedIntrVec_delay/REG{,_1,_2,_3}_reg[6]`.  `intrVecReg[7:6]` are
    spec-hardwired 0 (RISC-V interrupt IDs never set bits 6/7), so the intrVec
    delay stages carrying bit[6] are constant-0.  Golden keeps them as
    constrained `DFF0X` registers; the structurally-cleaner impl constant-folds
    them (`DFF0`) so they have no impl counterpart.  These are benign golden-only
    cone-dead constant registers (PASS_DEAD_REF class, same category as the
    documented WbDataPath / SnoopUnit residual golden-only regs).  The strict
    verdict therefore reports PARTIAL solely on `strict_unmatched!=0`; there is no
    functional gap.
- **UT** (`verif/ut/InterruptFilter`): dual-instantiation golden `InterruptFilter`
  vs `InterruptFilter_xs`, drives all 306 interrupt inputs randomly, compares all
  13 outputs each cycle.  seeds 1/7/42 → checks=199988, errors=0 each.

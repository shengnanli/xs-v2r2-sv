# StorePipe canonical-derivative + semantic-surface — integrator notes

Three layers make the StorePipe FM proof non-vacuous AND non-spuriously-failing:

1. **canonical-derivative reference** (plumb owner): the frozen golden `StorePipe.sv`
   is a DCE-collapsed 5-line empty shell → FM-081 vacuous. The runner substitutes
   the pre-DCE observable derivative `G0-StorePipe-observable-v1` (extracted from
   frozen `SimTop.fir` 7084336-7084662, re-lowered standalone with locked
   firtool-1.62.1), hash-pinned in `LEDGER.tsv`, no env override.

2. **readable-RTL impl** (rtl owner, `agent/storepipe-rtl` @ bea2fa2): the readable
   core `xs_StorePipe_core` + 73-port wrapper `StorePipe`. The impl HONESTLY drives
   the 14 source-undefined outputs to X (it does not know a value the source never
   specifies) — codex_0092 **forbids option A (0-fill)**.

3. **target-scoped semantic-surface wrapper** (this branch, `agent/storepipe-sem`,
   codex_0092 §1 option B): the 14 `invalidate`-only output leaves (source
   UNSPECIFIED) are excluded from the FM comparison surface. Derivative firtool
   drives them to constant 0; honest impl drives X → comparing 0-vs-X was a
   spurious FM FAILED (20 failing points). Two per-side wrappers (`module
   StorePipe_surface`, `StorePipe_{ref,impl}_surface.sv`) re-export ONLY the 23
   inputs + 36 source-defined outputs and leave the 14 as internal dangling nets
   → genuinely off the surface. **Not dont_verify, not 0-fill, not a generic
   knob.** Source-derived by `derive_surface.py` (FIRRTL last-connect-wins + the
   derivative port widths), cross-checked against `observable_surface.json`, and
   hash-bound in `LEDGER.tsv` (`semantic_surface_{ref,impl}_sha256`, bound into
   `ledger_root_sha256`). The runner stages both wrappers ONLY for
   `canonical_derivative` + these exact hashes and repoints the FM top to
   `StorePipe_surface`. Four negative tests (`negtests.sh`: over-exclude,
   under-exclude, rename, source-now-defined) all fail-closed at both the
   classifier and hash-bind layers.

## Native FM result (with all three layers)

`make fm-StorePipe` against the derivative overlay + surface wrappers:
**Verification SUCCEEDED for StorePipe_surface — 424 passing compare points
(266 Port + 158 DFF), 0 failing, 0(0) unmatched.** The 14 UNSPECIFIED leaves are
present in neither passing/failing/unread/dont_verify (off-surface by
construction). Evidence: `/tmp/storepipe-sem-evidence/official-fm-native-SUCCEEDED.out`.

## Already applied on agent/storepipe-sem

- `verif/freeze/canonical/derivatives/G0-StorePipe-observable-v1/` — ledger +
  derivative + `observable_surface.json` + `derive_surface.py` + the two surface
  wrappers + `negtests.sh`; `LEDGER.tsv` binds all of them (root re-generated).
- `scripts/sidecar/run_signoff_target.sh` — canonical_derivative overlay +
  semantic-surface wrapper staging (committed-bytes, per-wrapper hash-verify, no
  env override; all-or-nothing; golden-target-carrying-surface is illegal).
- `scripts/fm_eq.tcl` — dedicated `FM_SEMANTIC_SURFACE_TOP` / `_REF_SV` / `_IMPL_SV`
  hook (repoints top, appends per-side wrapper). Inactive for every other target.
- `scripts/ut_common.mk` — passes the three surface env vars into fm_shell.
- `scripts/sidecar/gen_305_manifest.py` (from plumb) + declaration row +
  `manifest_305.json` regenerated (StorePipe: reference_kind=canonical_derivative,
  derivative_id=G0-StorePipe-observable-v1, required=SUCCEEDED, mode=signoff-strict).
- Ledger/status: `combined_ledger.tsv` (INFRA_ERROR→PROOF_GAP), `gap_schedule.tsv`,
  `FM_STATUS.md`.

## Integrator must do to reach strict SUCCEEDED / SIGNOFF_PASS

The **semantic-surface makes the 36-defined-output proof clean**; the remaining
gap is the vmucp promotion (30 symmetric matched-unread dead bits inside the
compared surface), a separate integrator decision — same as the plumb owner's note:

1. Run the official gate in an isolated clean worktree at this commit:
   `SIGNOFF_EVIDENCE_ROOT=<dir> scripts/sidecar/run_signoff_target.sh \
    scripts/sidecar/manifest_305.json StorePipe`.
   Expect the native surface proof SUCCEEDED (36 outputs), with 30 symmetric
   matched-unread under strict → PARTIAL until vmucp.
2. To promote the 30 matched-unread (all symmetric, ref↔impl same leaf after
   `u_core/` strip: 6 `s2_paddr_reg[0..5]` byte-offset dead bits + 24 firtool
   clocked-block reified `*_reg` cone-dead shadow DFFs), flip vmucp:
   - `manifest_declarations.tsv` StorePipe col 5 `false`→`true`, regen manifest;
   - add `StorePipe` to the vmucp whitelist in `scripts/fm_eq.tcl`,
     `scripts/sidecar/run_signoff_target.sh` (line ~49 `case`), and
     `scripts/sidecar/gen_305_manifest.py` (`load_declarations` guard set).
   Re-run the gate → SUCCEEDED; `combined_ledger.tsv` StorePipe → SUCCEEDED /
   SIGNOFF_PASS, drop the gap_schedule row.

## Runner semantic-surface security invariants (do NOT relax)

- Surface wrappers resolved ONLY from the committed ledger at IMPL_COMMIT, keyed
  by `derivative_id`, hash-verified per wrapper. No `GOLDEN_RTL`/path env override.
- All-or-nothing ledger surface fields (partial set → fail-closed rc=2).
- A `reference_kind=golden` target carrying a surface is rejected (illegal).
- The exclusion set is SOURCE-derived; `derive_surface.py --check` must pass in CI
  (asserts committed wrappers == FIRRTL-derived render). This is what makes
  "a leaf became source-defined" a fail-closed drift, not a silent over-exclusion.

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

## vmucp promotion — DONE (codex_0093 §2 integrator, 2026-07)

CORRECTION to an earlier draft of this note: the residual was NOT "30 symmetric
matched-unread". The pre-vmucp baseline gate (native SUCCEEDED 424p/0f, PARTIAL)
showed `unread_ref=30 / unread_impl=6`, and only **6 of the 30 were symmetric**:

- **6 genuine symmetric bijective** `s2_paddr_reg[0..5]` (ref `u_dut/...` ↔ impl
  `u_dut/u_core/...`, same 1-bit leaf) — the low 6 byte-offset bits of the 48-bit
  s2_paddr, written but never read (block addr = `{s2_paddr[47:6],6'h0}`),
  cone-dead on BOTH sides.
- **24 ref-ONLY** `_GEN_5_reg / _r_T_reg / _r_c_cat_T_*_reg / _s1_tag_match_T_*_reg`
  — these had NO impl counterpart, so they were unmatched-unread, not symmetric.
  ROOT CAUSE: the derivative was lowered WITHOUT `disallowLocalVariables`, so
  firtool kept those combinational temporaries as `automatic logic` locals INSIDE
  the clocked `always` block, which FM `read_sverilog` REIFIES as shadow DFFs.
  They exist in neither the source FIRRTL nor the readable impl core (already
  lowered with the G0 flags → 11 real DFFs, 0 shadow). These are exactly the
  "old automatic-local shadow DFFs" the vmucp gate forbids.

Integrator actions (all committed on this branch, agent/storepipe-vmucp):

1. **Re-lowered the derivative** with the correct G0 firtool flag:
   `derive.sh` FIRTOOL_ARGV += `--lowering-options=disallowLocalVariables`. Re-ran
   `derive.sh` (deterministic) → derivative StorePipe.sv now 11 registers, 0
   `automatic logic`, **byte-identical 73-port IO surface** → surface wrappers
   unchanged (same sha b8495c77/e1b171e3). `derive_surface.py --check` OK,
   `negtests.sh` 7/7 fail-closed. Ledger regenerated (reference_sv 9a0edf9b, root
   37d6a7d5, firtool_argv recorded). This kills all 24 shadow DFFs.
2. **Pinned the 6 true-bijection dead bits** via `verif/ut/StorePipe/fm_pins.tcl`
   (`set_user_match r:.../u_dut/s2_paddr_reg[N] i:.../u_dut/u_core/s2_paddr_reg[N]`
   for N=0..5). The shared `auto_match_flattened_arrays` only strips ONE `u_core/`
   level and cannot see through the double `u_dut/u_core` surface-wrapper hierarchy,
   so these land unmatched-unread; pinning them by name is TRUE-equivalence
   strengthening (NOT fake pairing, NOT dont_verify, NOT 0-fill). vmucp=true then
   makes FM compare them bit-for-bit → passing.
3. **Enabled vmucp in FOUR places** (the earlier draft listed only 3):
   - `manifest_declarations.tsv` StorePipe col 5 `true`, regen manifest;
   - `scripts/fm_eq.tcl` `ni {...}` whitelist += **`StorePipe_surface`** (NOT
     `StorePipe`: the semantic-surface hook reassigns `$top` to `StorePipe_surface`
     BEFORE the vmucp whitelist check — verified by an empirical FM_MODE_ERROR);
   - `scripts/sidecar/run_signoff_target.sh` (line ~49 `case`) += `StorePipe`;
   - `scripts/sidecar/gen_305_manifest.py` (`load_declarations` guard) += `StorePipe`;
   - `scripts/sidecar/fm_sidecar_verdict.py` (`_MU_STRENGTHEN` validator set) +=
     `StorePipe` — the 4th, validator-side gate, keyed on the manifest TARGET name.

**Official clean gate (isolated worktree, MAIN_DIRTY=0) verdict:**
`measured=SUCCEEDED required=SUCCEEDED gate=PASS`, RUNNER_RC=0. Native SUCCEEDED
**430 passing (266 Port + 164 DFF), 0 failing, 0(0) unmatched, 0 unread, 0
matched_unread_notcompared, no dont_verify, no relaxed appvars, vmucp=true.**
`combined_ledger.tsv` StorePipe → SUCCEEDED / SIGNOFF_PASS; gap_schedule row dropped.

## Runner semantic-surface security invariants (do NOT relax)

- Surface wrappers resolved ONLY from the committed ledger at IMPL_COMMIT, keyed
  by `derivative_id`, hash-verified per wrapper. No `GOLDEN_RTL`/path env override.
- All-or-nothing ledger surface fields (partial set → fail-closed rc=2).
- A `reference_kind=golden` target carrying a surface is rejected (illegal).
- The exclusion set is SOURCE-derived; `derive_surface.py --check` must pass in CI
  (asserts committed wrappers == FIRRTL-derived render). This is what makes
  "a leaf became source-defined" a fail-closed drift, not a silent over-exclusion.

# Canonical-derivative ledgers

A **canonical derivative** is an observable reference RTL that is *mechanically
extracted* from the frozen, immutable G0 canonical baseline (`SimTop.fir`) and
re-lowered STANDALONE with the *locked* firtool that produced G0. It is **not**
authored RTL and **not** a config change — it is an extraction of frozen source
whose only difference from the shipped module is the elaboration boundary.

## Why this exists

Some production modules are collapsed by whole-chip firtool DCE when a
parameter disables their sink (e.g. `StorePipe` under KunminghuV2, where
`StorePrefetchL1Enabled=false` ties off every output). The frozen golden `.sv`
for such a module is a 5-line empty shell (0 outputs, 0 registers), so an FM
proof against it is *vacuous* (FM-081 reference-is-black-box, 0 compare points).
The intact FIRRTL still lives inside the frozen `SimTop.fir`; extracting and
re-lowering it standalone recovers the full observable datapath as top-level
ports, giving a non-vacuous FM reference — **without touching G0**.

## Ledger structure (`<derivative_id>/`)

| file | role |
|---|---|
| `derive.sh` | deterministic, SHA-pinned extraction+lowering; aborts on any input drift |
| `PROVENANCE.manifest` | immutable-input hashes + intermediate `.fir` hashes + derivative SHA (no wall-clock; byte-deterministic) |
| `StorePipe.module.fir` / `.asyncreset.fir` / `.standalone.fir` | the extracted + reset-concretized + wrapped FIRRTL (intermediate, kept for audit) |
| `StorePipe.sv` | **the FM reference** the runner stages as `$GOLDEN_RTL/<top>.sv` |
| `observable_surface.json` | 36 defined output leaves + 6 perf probes + 14 `UNSPECIFIED_BY_SOURCE` |
| `build_surface.py` | reproducible generator of `observable_surface.json` |
| `LEDGER.tsv` | versioned binding: `reference_kind`, `derivative_id`, `source_baseline_id`, immutable pins, per-artifact digests, `reference_sv_sha256`, `ledger_root_sha256` |

`gen_ledger.py <dir>` regenerates `LEDGER.tsv` from the artifacts.

## Runner contract (security boundary)

`run_signoff_target.sh` substitutes the frozen golden `.sv` with a derivative
**only** when the committed manifest entry declares
`reference_kind=canonical_derivative` + a `derivative_id`. It then:

1. resolves `verif/freeze/canonical/derivatives/<derivative_id>/LEDGER.tsv`
   from the committed tree (`IMPL_COMMIT`), never the worktree checkout;
2. recomputes the ledger root digest over committed artifact bytes and matches
   `ledger_root_sha256`;
3. materializes `reference_sv` from committed bytes and matches
   `reference_sv_sha256`;
4. builds a symlink-overlay of frozen `$GOLDEN` with `<top>.sv` replaced by the
   derivative, and passes that overlay as `GOLDEN_RTL`.

There is **no environment-variable path override** — a caller cannot inject an
arbitrary `GOLDEN_RTL`/reference. The reference bytes are pinned to committed,
hash-verified ledger content. Any drift (uncommitted ledger, id/top/root/sv-sha
mismatch, artifact drift) is fail-closed (rc=2).

The reference kind + derivative id + ledger root are recorded in the evidence
`TOOLS.tsv` and bound into the expectation digest (`REFERENCE_KIND`,
`DERIVATIVE_ID`, `DERIVATIVE_LEDGER_ROOT` semantics), so the substitution is
part of the reproducible proof provenance.

## Target-scoped semantic surface (codex_0092 §1, option B)

Some derivative output leaves are `invalidate`-only in the source FIRRTL — the
source **does not specify** them (e.g. `io_miss_req_bits_store_mask`,
`io_miss_req_bits_amo_cmp`). firtool lowers each `DontCare` to an arbitrary
constant `0`; an honest readable-RTL impl drives `X`. Comparing `0`-vs-`X` is a
spurious FM FAILED. Option B (chosen over forcing the impl to 0-fill) removes
exactly those **source-undefined** output leaves from the comparison surface via
a **semantic-surface wrapper** — this is **NOT** `dont_verify`, **NOT**
0-concretization, and **NOT** a generic "exclude any point"/"swap any top" knob.

The mechanism is two per-side wrappers, both `module StorePipe_surface`, each
instantiating the real `StorePipe` (the hash-pinned derivative on the ref side;
the readable core + impl wrapper on the impl side) and **re-exporting only the 23
inputs + 36 source-defined outputs**. The 14 UNSPECIFIED-by-source outputs are
left as internal dangling nets — genuinely off the surface (present in neither
side as a compare point). FM sets the top to `StorePipe_surface` on both sides
and compares the 36 defined outputs; the surface is symmetric and non-vacuous.

Ledger fields (optional, per id):

| field | role |
|---|---|
| `semantic_surface_top` | the surface top module both sides are compared at (`StorePipe_surface`) |
| `semantic_surface_ref` / `_ref_sha256` | ref-side wrapper `StorePipe_ref_surface.sv` + its digest |
| `semantic_surface_impl` / `_impl_sha256` | impl-side wrapper `StorePipe_impl_surface.sv` + its digest |
| `surface_derive_script` | `derive_surface.py` — **re-derives** the excluded set from the committed `.module.fir` (FIRRTL last-connect-wins) + the derivative port widths, cross-checks `observable_surface.json`, and emits both wrappers; `--check` asserts the committed wrappers == source-derived render |

All these files are digested into `ledger_root_sha256`.

Runner binding (security boundary, extends steps 1-4 above):

5. if (and only if) the committed ledger declares the surface fields (all-or-
   nothing; a partial set is fail-closed), materialize **both** wrappers from
   committed bytes and match each against its ledger sha256; pass
   `FM_SEMANTIC_SURFACE_TOP` + the two wrapper paths to `fm_eq.tcl`, which
   repoints the top to `StorePipe_surface` and appends each side's wrapper. A
   golden-reference target carrying a surface, or any byte drift, is fail-closed
   (rc=2). There is **no env path override**: the wrappers are keyed by
   `derivative_id` and pinned by their hashes.

The surface is bound to the **source**: if a leaf becomes source-`connect`-defined
(or a name/width drifts), `derive_surface.py` derives a different set, the wrapper
bytes/hashes change, and both `--check` and the runner reject. `negtests.sh`
exercises four fail-closed cases (each at the classifier AND hash-bind layer):
over-exclude (>14), under-exclude (<14), rename, and source-now-defined.

## Registered derivatives

| derivative_id | source | reference_top | reference_sv_sha256 |
|---|---|---|---|
| `G0-StorePipe-observable-v1` | G0 SimTop.fir lines 7084336-7084662, firtool-1.62.1 | StorePipe | `0ad96d9250844029feea91844c69d89a9f4f05cbf0d95419dfaafd3823e261fe` |

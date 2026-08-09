# Rob cone-DCE partition proof — evidence index (codex 0100 Lane 2)

`Rob-cone-DCE` owner. Pre-FM cone-DCE derivative to break the Rob monolithic /
route-B FM convergence wall (142481 compare points; match stuck 11%/3.3 h).

## What this is
For each of the 5 union-verified output-cone partitions, a physically REDUCED
design pair is generated from the SAME frozen sources by the SAME locked tools,
removing (before FM reads them) all logic/registers outside that family's
transitive fanin cone. FM then builds only the family cone → compare points drop
≥1 order of magnitude. This is a proof artifact; it does NOT replace global G0 or
modify functional RTL.

## Layout
- `outlists/<fam>.txt` — the family output list, taken VERBATIM from the
  union-verified route-B classifier (`../../..//docs/backend/rob_partition_coverage.tsv`,
  2343 outputs).
- `impl_freeze/` — impl A+B integration inputs frozen from commit `2d486d4`
  (`Rob_wrapper.sv` + `xs_Rob_core` + pkg + deps + difftest stubs), with
  `FREEZE_SOURCE.tsv` hashes.
- generated derivatives + FM evidence live under `/tmp/rob-conedce-evidence/`
  (not committed; regenerated deterministically by `gen_all.sh`):
  - `gen/Rob_golden_<fam>.sv` (reduced ref), `gen/Rob_impl_<fam>.sv` (reduced impl),
    `gen/conedce_manifest.tsv` (hashes).
  - `part_<fam>/fm.log` + `rc.txt` (per-partition FM).
  - `fm-partition-union-v1/UNION_RECORD.tsv` (root record; only PASS when 5/5 RC0).

## Tools (locked; see ../../..//docs/backend/Rob_cone_dce.md for full argv)
- `scripts/conedce/rob_cone_slicer.py` + `always_tree.py` — ref cone slice.
- `scripts/conedce/impl_port_trim.py` — impl output-surface trim.
- `scripts/conedce/gen_all.sh` — deterministic, hash-gated driver.
- `scripts/conedce/verify_conedce_union.py` — independent union checker.
- `scripts/conedce/regen_check.sh` / `negtest.sh` — determinism / fail-closed.
- `scripts/conedce/fm_conedce_partition.tcl` + `run_conedce_partition.sh` — FM.
- `scripts/conedce/build_union_record.sh` — root union record.

## Gates (all PASS)
- Determinism: two clean regens byte-identical (10 derivatives + manifest).
- Negative tests: N1 drop-output surface regression / N2 wrong golden hash abort /
  N3 changed argv → different hash / N4 dropped register driver breaks VCS
  elaboration — all fail-closed.
- Union: 2343 outputs total + disjoint + no width drift + 891-input parity +
  impl/ref surface match; union hash == golden output-set hash.
- Structural: all 5 reduced goldens + 5 reduced impls elaborate clean in VCS.

## Discipline
cone-DCE = same-source, locked-tool, auditable physical reduction (ref+impl same
strategy), NOT a relaxation. Only the 7 official-PASS child leaf boundaries. NO
dont_verify / deleted compare points / assumption / constant-forced input /
added blackbox. Heavy FM runs serially (OOM-safe); PIDs tracked per owner; no
`pkill -f`. Not self-promoted; union record only on 5/5 RUNNER_RC=0.

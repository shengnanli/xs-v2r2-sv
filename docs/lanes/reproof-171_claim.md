# Lane claim: reproof-171

Integrator: claude (main session). Claimed 2026-10-19. Base: main 2d1d134e0（gate_all GATE_RC=0）。用户批准顺序第 3 步。

Scope: docs/oldcert_triage.tsv 里 171 张 HISTORICAL 证书（非 current-valid，原因 script_closure_changed:scripts/fm_eq.tcl）
在钉住的 PROOF_COMMIT 上官方重证，重出证书，使其各自 current-valid。
Owned paths: 这 171 个目标的 evidence/receipt、verif/proof_certificates/<target>.json、docs/fm_predictions/<target>.json（仅缺登记时补，跑前提交）、
docs/lanes/reproof-171*.md。
Not touched: ExuBlock*/Backend/XSCore/XSTile/LsqWrapper/L2Top/TL2CHICoupledL2 等父证书与 allow、派生表、rtl/、scripts/（含 fm_eq.tcl、
台账脚本——ledger-cv lane 所有）、proof_certificate 判据、G0/G1。

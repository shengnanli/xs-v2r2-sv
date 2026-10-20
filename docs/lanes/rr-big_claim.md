# Lane claim: rr-big

Integrator: claude (main session). Claimed 2026-10-19. Base: main 22cf76370（gate_all GATE_RC=0，504/504 证书 current-valid）。
用户裁定「先重证再合口径」（ledger-cv 口径暂不进 main）。

Scope: 只有 receipt、因 scripts/fm_eq.tcl 脚本闭包过期而非 current-valid 的大目标（golden ≥5000 行）官方重证。 目标清单 docs/lanes/rr-big_targets.tsv（target / golden 行 / 核内）。
Owned paths: 清单内目标的 evidence/receipt、docs/fm_predictions/<target>.json（仅缺登记时补，跑前单独提交）、docs/lanes/rr-big*.md。
Not touched: 清单外目标、verif/proof_certificates/ 与 verif/allow/（除非汇报后获批）、派生表、rtl/、scripts/、G0/G1。

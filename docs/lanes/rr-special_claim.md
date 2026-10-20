# Lane claim: rr-special

Integrator: claude (main session). Claimed 2026-10-19. Base: main 22cf76370（gate_all GATE_RC=0，504/504 证书 current-valid）。
用户裁定「先重证再合口径」（ledger-cv 口径暂不进 main）。

Scope: ledger-cv 判非 current-valid 的特殊原因目标诊断与补证：impl_golden_mc_not_shared 57、缺 RUN_CONTEXT 4、impl_golden_uncertified 2、ICacheDataArray closure_changed 1、NO_PROOF 3。 目标清单 docs/lanes/rr-special_targets.tsv（target / golden 行 / 核内）。
Owned paths: 清单内目标的 evidence/receipt、docs/fm_predictions/<target>.json（仅缺登记时补，跑前单独提交）、docs/lanes/rr-special*.md。
Not touched: 清单外目标、verif/proof_certificates/ 与 verif/allow/（除非汇报后获批）、派生表、rtl/、scripts/、G0/G1。

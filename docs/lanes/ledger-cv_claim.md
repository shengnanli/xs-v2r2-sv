# Lane claim: ledger-cv

Integrator: claude (main session). Claimed 2026-10-19. Base: main 2d1d134e0. 用户批准顺序第 2 步（承 oldcert-triage 第 6 节）。

Scope: 覆盖率台账 proven 口径改为只认「当前有效」证明：rewrite_coverage.py 与 coverage_three_axis.py 轴二
不再把脚本闭包/impl 闭包已过期的 receipt 记 PROVEN_DIRECT；满足 oldcert_triage WB1-WB6 的改记
PROVEN_IN_CONE(superseded_by=<父>)；配正反测并接入 gate。
Owned paths: scripts/rewrite_coverage.py、scripts/coverage_three_axis.py（及其 test_*）、gate_all.sh 中对应新闸行、
docs/lanes/ledger-cv*.md。
Not touched: 派生表（integrator 重出）、证书/receipt/evidence、rtl/、scripts/fm_eq.tcl、proof_certificate 判据、G0/G1。

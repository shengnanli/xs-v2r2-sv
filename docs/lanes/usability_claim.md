# Lane claim: usability

Integrator: claude (main session). Claimed 2026-10-19. Base: main 9ae0e8144. Codex 0240 C 线。

Scope: main 上可执行的整芯片 build/run/compare 入口与负载/依赖说明、带调试信息的 Verdi 启动入口；
复现说明不依赖 wt-fullchip-bench；xstile_rtl_elab.sh 改显式 -top XSTile（闭包核对另保留）。
Owned paths: verif/sim/**、scripts/xstile_rtl_elab.sh、docs/lanes/usability*.md、docs/ 下新使用说明。
Not touched: rtl/、verif/allow、证书、派生表、G0/G1。

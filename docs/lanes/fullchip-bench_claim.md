# Lane claim: fullchip-bench

Integrator: claude (main session). Claimed 2026-10-18. Base: main dabf1cda0. Codex 0238 主线 B。

Scope: 整芯片 SimTop（golden 核外 + 全重写 XSTile）编译/启动 smoke，coremark、dhrystone（及 cputest）
golden vs impl 运行；difftest 结论与逐拍对拍结论分别报告。
Owned paths: verif/sim/**（新增脚本/结果）、docs/lanes/fullchip-bench*.md、自己的 sim 工作区。
Not touched: rtl/、verif/allow、证书、派生表、scripts/full_elab_filelist.py（A 线 owner）。

# Lane claim: assert-hdr

Integrator: claude (main session). Claimed 2026-10-19. Base: main 9ae0e8144. Codex 0240 遗留 2（A 线）。

Scope: 本地公共宏头 .svh，由 rtl/backend/TrapEntryVSEventModule.sv、VSstatusModule.sv 显式 include，
去掉对 G1 extern_modules.sv 文件顺序的依赖；SYNTHESIS 两档编译、断言开关行为、两目标 FM/UT；受影响父证明 current-valid 核查。
Owned paths: rtl/common/<新宏头>.svh、上述两个 rtl 文件、其 verif/ut 目录与 evidence、docs/lanes/assert-hdr*.md。
Not touched: 其他 rtl、verif/sim/**（C 线）、派生表、G0/G1。

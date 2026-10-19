# Lane claim: reproof-chain

Integrator: claude (main session). Claimed 2026-10-19. Base: main ff7650336 + merge agent/assert-hdr@156b88772. Codex 0242 第 2 条。

Scope: 合入 A 线（两文件内联宏守卫），冻结组合提交，确认叶子/直接依赖 current-valid，依次 ExuBlock → Backend → XSCore → XSTile official 实跑；
NewCSR/CSR/ExeUnit_7 若为当前交付依赖的证明根则补齐。
Owned paths: verif/allow/{ExuBlock,Backend,XSCore,XSTile,NewCSR,CSR,ExeUnit_7}*、这些目标的 evidence/receipt/证书、docs/lanes/reproof-chain*.md。
Not touched: 其他目标证书（旧证书分类 lane 所有）、派生表（integrator 重出）、rtl/ 除 A 线两文件外、G0/G1。

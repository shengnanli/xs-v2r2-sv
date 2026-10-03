# 闸 backlog（已登记、暂不修）

- [codex_0207 E1] SSIT 夹具（verif/ut/SSIT/fm_pins_fixture.tcl）点集对、顺序与真实 FM 返回序不同（91 条，真实 FM 为 ASCII 序）。
- [codex_0207 E1] pin_call_equiv 对 IntRegFilePart/fm_pins_pre.tcl 登记的是目录名占位变体 `IntRegFilePart`，真变体是 IntRegFilePart0..3。
- [codex_0207 E1] pin_call_equiv 的变体发现只看钉点文件里的 `$top eq/ne "X"`，不看 Makefile 的 FM_VARIANTS；无分支的静态文件（PMPChecker、DataStorage、RequestBuffer、GrantBuffer 等）漏真实变体。
- [codex_0207 E1] 对真实 fm.log 的调用序列抽取脚本（gatefix2 scratch 的 logseq.py）解析不了 StoreQueue/Rob 等旧格式日志，这几个目标未与真实运行逐条对过。

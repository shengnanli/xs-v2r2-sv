# kimi-vimacu lane 预登记（2026-10-06）

起草：KIMI K3（tools/kimi_lane.py 固定流程，第 3 轮收敛）；验收与修改：Claude 集成者。

## VIMacU
- 重写件 `rtl/backend/VIMacU.sv`，UT `verif/ut/VIMacU`（Makefile 由驱动模板生成；tb.sv 由 KIMI 写、经 Claude 审阅：全部输出端口逐拍差分，fuOpType 0..6 / sew / vm-ta-ma 覆盖）。
- Claude 验收时的修改（只改名与注释，FM 复证）：KIMI 把 vmadd/vnmsub 命名成 `is_macc_wide`/`is_sub_wide`、vmulh 命名成 `high_half`（"wide" 与加宽位 fuOpType[3] 混淆，属名不副实），按 yunsuan VIMacSpec 的编码表改为 `is_vmulh/is_vmacc/is_vnmsac/is_vmadd/is_vnmsub/is_vsmul`，`exchange_sources` → `addend_is_vs2`，并加编码注释；文件头改 `//` 行注释。
- 诊断 FM（vmucp off，改名前）：native SUCCEEDED，passing 3753 / failing 0 / unmatched 0，unread 20，constant_reg 160。
- 20 位 = vimacs_0/1 的 `uopIdxS1_reg[5:1]`、`uopIdxS2_reg[5:1]`，与已签 `verif/fm_target_config/VIMac64b.tcl` 同一组对称死位；本层 `verif/ut/VIMacU/fm_pins_pre.tcl` 按 VIMac64b 同法钉 24 条。
- 模型 3933（regs 3142 + outs 791）= 3753 + 20 + 160。**official（vmucp on）预期 passing 3773、constant_reg 160、其余全零。**

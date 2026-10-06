# kimi-vipu lane 预登记（2026-10-06）

起草：KIMI K3（tools/kimi_lane.py 固定流程，第 2 轮收敛）；验收：Claude 集成者。

## VIPU
- 重写件 `rtl/backend/VIPU.sv`（387 行，`_GEN_`/`_T_` 0），UT `verif/ut/VIPU`（Makefile 由驱动模板生成，tb.sv 由 KIMI 写、经 Claude 审阅：全部输出端口逐拍差分，opcode 分类覆盖下限）。
- 诊断 FM（vmucp off）：native SUCCEEDED，passing 3930 / failing 0 / unmatched 0，matched_nc 122，constant_reg 2。
- 122 位 = VMask `vs1_reg_s1[127:8]` 120 + Reduction `vdType_reg_s1[3:2]` 2，与已签 `verif/fm_target_config/VIAlu.tcl` 同一组两侧对称死位。
- 模型 4054（regs 3262 + outs 792）= 3930 + 122 + 2。**official（vmucp on）预期 passing 4052、constant_reg 2、其余全零。**

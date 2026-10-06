# kimi-frontendbridge lane 预登记（2026-10-06）

起草：KIMI K3（tools/kimi_lane.py 固定流程，第 4 轮收敛；第一次尝试因任务说明漏列孙级依赖失败，驱动改为自动算 golden 闭包后重跑）；验收：Claude 集成者。

## FrontendBridge
- 重写件 `rtl/memblock/FrontendBridge.sv`（纯连线：三个已签子缓冲 ICacheBuffer / ICacheCtrlBuffer / InstrUncacheBuffer），UT `verif/ut/FrontendBridge`（Makefile 驱动模板生成；tb 由 KIMI 写、Claude 审阅：全部输出逐拍差分，三通道 A/D 握手 + 背压覆盖）。
- 诊断 FM（vmucp off）：native SUCCEEDED，passing 4432 / failing 0 / unmatched 0，matched_nc 345，constant_reg 395。
- 345 位 = 三子缓冲 TileLink 队列 `ram_ext/Memory_reg` 对称死位（52 + 277 + 16），与三个子目标自签核的 vmucp 组一致。
- 模型 5172（regs 4220 + outs 952）= 4432 + 345 + 395。**official（vmucp on）预期 passing 4777、constant_reg 395、其余全零。**

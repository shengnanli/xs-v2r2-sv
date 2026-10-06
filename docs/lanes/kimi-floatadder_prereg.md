# kimi-floatadder lane 记录与预登记（2026-10-06）

## 过程
- KIMI K3 固定流程（tools/kimi_lane.py）6 轮：UT 能过，诊断 FM 停在 failing 20 / unmatched 37~40 不动，最后一轮改坏编译，GAVE_UP。
- KIMI 受限代理（tools/kimi_agent.py）两次接手：补了 io_fp_format 端口、暴露出 UT Makefile golden 侧缺源（驱动早期模板未算闭包，
  集成者用新模板重生成）；两次都提前 finish(BLOCKED)，未找到根因；第二次把连线改成 firtool 风格名。
- Claude 定位根因并收尾：**失配不在本层逻辑**——两个子流水线单独签核时靠精确钉点配寄存器（FloatAdderF64Pipeline 的
  fm_pins_pre/fm_pins、FloatAdderF32F16MixedPipeline 的 fm_pins），父层没有重放这些钉点，FM 配不上 → 下游输出口报失配。
  修法：把子钉点加实例前缀照搬到 verif/ut/FloatAdder/fm_pins_pre.tcl（443）/ fm_pins.tcl（7）（与 gen_exeunit.py CHILD_PINS 同法），
  另补 14 条 F32Adder `fadd0_result1_r{,_1}[9:4,11]` ↔ `b_signed_f{32,16}_q` 逐位同式钉点（子目标单独签核时 FM 自动配上、父层配不上）。
  RTL 重写命名（opcode 具名常量、连线 f32_result/f64_result、分节与 NaN-box 说明），逻辑不变。

## 数字
- UT seed 1/7/42（initreg 0）errors=0。
- 诊断 FM（vmucp off）：native SUCCEEDED，passing 1265 / failing 0 / unmatched 0，matched_nc 5，constant_reg 167。
- 模型 1437（regs 1368 + outs 69）= 1265 + 5 + 167。**official（vmucp on）预期 passing 1270、constant_reg 167、其余全零。**

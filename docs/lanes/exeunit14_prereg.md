# exeunit14 lane 预登记（2026-10-06）

## ExeUnit_14
- 外壳 `rtl/backend/ExeUnit_14.sv` 与钉点 `verif/ut/ExeUnit_14/fm_pins_pre.tcl`（3678 条）由 `scripts/gen_exeunit.py ExeUnit_14` 生成；
  tb 由 `scripts/gen_exeunits_ut.py ExeUnit_14` 生成（本 lane 把 ExeUnit_13 / ExeUnit_14 加进其 lazy 目标表）；Makefile 手写：
  impl 源 = 各子 FU 自身 UT 的 RTL_SRCS 并集，FP_INCVT / VsetModule 改用本仓重写件。
- 子：Dispatcher_14 / VFAlu / VCVT_8 / VIPU / VSetRvfWvf / ClockGate×3，全为已签核件，两侧白盒。
- UT seed 1/7/42（initreg 0）errors=0。诊断 FM（vmucp off）：native SUCCEEDED，passing 13522 / failing 0 / unmatched 0，
  matched_nc 926（分解见 verif/fm_target_config/ExeUnit_14.tcl），constant_reg 504。
- 模型 14952（regs 13501 + outs 1451）= 13522 + 926 + 504。**official（vmucp on）预期 passing 14448、constant_reg 504、其余全零。**

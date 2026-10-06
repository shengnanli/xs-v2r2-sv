# exeunit13 lane 预登记（2026-10-06）

## ExeUnit_13
- 外壳 `rtl/backend/ExeUnit_13.sv` 与钉点 `verif/ut/ExeUnit_13/fm_pins_pre.tcl` 由 `scripts/gen_exeunit.py ExeUnit_13` 生成；tb 由
  `scripts/gen_exeunits_ut.py ExeUnit_13` 生成；Makefile 手写（各子 FU UT 的 RTL_SRCS 并集，同 ExeUnit_14）。
- 本 lane 对 `scripts/gen_exeunit.py` 的两处改动（`--check` 对全部变体幂等，含 ExeUnit_13/14）：
  1. golden 把多个实例共用的改位宽表达式提成具名 `_GEN` 线（`_GEN = {1'h0, inPipe_1_2_pdest}` 接 Vimac/Vialu 的 ctrlPipe_2_pdest），
     解析后把「改位宽外形」的 `_GEN` 就地展开回表达式；
  2. CHILD_PIN_FILES 加 VIMacU（24 条）；VARIANTS 加 ExeUnit_13 / ExeUnit_14。
- 子：Dispatcher_13 / VFMA / VIAluFix / VIMacU / VPPU / ClockGate×4，全为已签核件，两侧白盒。
- UT seed 1/7/42（initreg 0）errors=0。诊断 FM（vmucp off，补 VIMacU 子钉点前）：native SUCCEEDED，passing 16030 / failing 0 /
  unmatched 0，钉点 4836/4836，unread 515 matched_nc + 20 对 Vimac uopIdx（分解见 verif/fm_target_config/ExeUnit_13.tcl），constant_reg 380。
- 模型 16945（regs 15892 + outs 1053）= 16030 + 515 + 20 + 380。**official（vmucp on，钉点 4860）预期 passing 16565、constant_reg 380、其余全零。**

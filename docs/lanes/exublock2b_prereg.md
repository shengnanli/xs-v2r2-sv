# exublock2b lane 预登记（2026-10-06）

## ExuBlock_2（向量执行块）
- wrapper `rtl/backend/ExuBlock_2.sv` 与钉点 `verif/ut/ExuBlock_2/fm_pins_pre.tcl`（18261 条）由 `scripts/gen_exublock.py ExuBlock_2` 生成；
  tb 由 `verif/ut/ExuBlock_2/gen.py`（照 ExuBlock_1）生成；Makefile = 五个 ExeUnit UT 的 RTL_SRCS / RTL_GOLDEN_DEPS / FM_REF_DEPS 并集。
- 本 lane 对 `scripts/gen_exublock.py` 的改动（`--check` 对 ExuBlock / ExuBlock_1 无漂移）：VARIANTS 加 ExuBlock_2；CHILD_PIN_FILES 加
  ExeUnit_13..17；PENDING_PIN_LOGS 加 ExeUnit_13（evidence/5ec0626546dd/ExeUnit_13/fm.log，PIN_END ok=4860）；子钉点支持 `-type cell`
  （VFAlu 的 cell 钉点，同 gen_exeunit.py）；tcl_esc 先转义反斜杠（同 gen_exeunit.py）。
- 基于 agent/exeunit13（ExeUnit_13 official SUCCEEDED passing 16565，evidence/5ec0626546dd）。
- 诊断 FM（vmucp off）：native SUCCEEDED，passing 61160 / failing 0 / unmatched 0，钉点 18261/18261，matched_nc 2101，constant_reg 1464。
- 模型 64725（regs 58937 + outs 5788）= 61160 + 2101 + 1464。**official（vmucp on）预期 passing 63261、constant_reg 1464、其余全零。**

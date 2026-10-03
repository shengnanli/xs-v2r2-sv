MODULE = FloatAdderWidenFormat

# 向量浮点加法器的加宽格式化前级（fpu-parents lane，misc3 group）。纯组合、无寄存器。
# child 处置（docs/coverage_three_axis.tsv / evidence 已签）：
#   ShiftLeftPriorityWithF32EXPResult（evidence/96c3fe112cb4）、ShiftLeftPriorityWithF64EXPResult
#   （evidence/1bf831352049，k3-returned lane 签核已入 main；coverage 表该行仍写 UNPROVEN 是表未刷新）
#   → 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
CHILDREN = ShiftLeftPriorityWithF32EXPResult ShiftLeftPriorityWithF64EXPResult
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) FloatAdderWidenFormat))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) FloatAdderWidenFormat))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FloatAdderWidenFormat
FM_REF_DEPS_FloatAdderWidenFormat = ShiftLeftPriorityWithF32EXPResult.sv ShiftLeftPriorityWithF64EXPResult.sv
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 纯组合零寄存器：initreg 没有作用面，三档照跑。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

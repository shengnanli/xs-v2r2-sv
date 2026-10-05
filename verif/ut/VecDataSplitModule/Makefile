MODULE = VecDataSplitModule

# 128 位向量按 8/16/32/64 位元素切开的纯组合叶子（vector-fu lane）。无子模块、无黑盒。
# tb 另带独立 oracle：按 RVV 小端元素排列逐元素从输入里取位（不经被测电路）。
RTL_DIR  = ../../../rtl
TARGETS  = VecDataSplitModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = VecDataSplitModule
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 纯组合、无寄存器：initreg 三档不影响行为，但照规范三档都跑（INITREG=0 / random / <seed>017）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

MODULE = CsrCauseTvalLeaves8
RTL_DIR = ../../../rtl
LEAVES = McauseModule ScauseModule VScauseModule MncauseModule \
 MtvalModule StvalModule VStvalModule Mtval2Module
RTL_SRCS = $(RTL_DIR)/backend/xs_CsrTrapValue_core.sv \
 $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
# 编译期开启 initreg 机制，运行期固定为 0，保证双例化未复位初值相同。
# VCS W-2024.09-SP1 不接受编译期 +vcs+initreg+0；取值只能放 SIM_ARGS。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

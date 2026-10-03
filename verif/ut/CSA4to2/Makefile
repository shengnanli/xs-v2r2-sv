MODULE = CSA4to2

# 107 位 4:2 进位保留压缩器（fpu-parents lane，misc3 group）。纯组合、无 child、无寄存器。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/CSA4to2.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/CSA4to2.sv

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析）
FM_VARIANTS = CSA4to2
FM_REF_DEPS_CSA4to2 =
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 纯组合零寄存器：initreg 没有作用面，三档照跑（"没有作用面"是结论，不是免跑的理由）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

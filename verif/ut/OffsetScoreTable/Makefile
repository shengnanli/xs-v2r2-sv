MODULE = OffsetScoreTable

# BOP 偏移评分表家族：一个参数化核 xs_OffsetScoreTable_core + 两个薄 wrapper
# （PBOP：37 个候选 / 7 位；VBOP：109 个候选 / 10 位）。一个 UT 同测两对；无子模块、无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/l2/xs_OffsetScoreTable_core.sv \
           $(RTL_DIR)/l2/OffsetScoreTable.sv \
           $(RTL_DIR)/l2/OffsetScoreTable_1.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/OffsetScoreTable.sv \
              $(GOLDEN_RTL)/OffsetScoreTable_1.sv

FM_VARIANTS = OffsetScoreTable OffsetScoreTable_1
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器异步复位，上电初值不可观测；复位域由 FM 把关。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

MODULE = SlideVs2VdTable

RTL_DIR  = ../../../rtl
# Permutation 的两个 uop 拆分查表 child（纯组合，各自 0 子模块）。
RTL_SRCS = $(RTL_DIR)/backend/slideupVs2VdTable.sv \
           $(RTL_DIR)/backend/slidednVs2VdTable.sv
TB_SRCS  = tb.sv

# 列表逐项写开（不用 $(addprefix ...)）：fm_predict.py 等读表脚本按行解析 Makefile。
GOLDEN_SRCS = $(GOLDEN_RTL)/slideupVs2VdTable.sv \
              $(GOLDEN_RTL)/slidednVs2VdTable.sv
FM_VARIANTS = slideupVs2VdTable slidednVs2VdTable

FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 无寄存器，initreg 对结果无影响；仍按全仓规矩两处都给（机制 + 取值）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

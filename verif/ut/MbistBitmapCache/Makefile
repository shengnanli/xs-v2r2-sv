# MbistBitmapCache —— bitmap cache 的 MBIST 叶子节点（xs_mbist_pipe_core 变体，由 scripts/gen_mbist_pipe_family.py 生成）。
MODULE = MbistBitmapCache

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/dft/xs_mbist_pipe_core.sv $(RTL_DIR)/dft/MbistBitmapCache.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MbistBitmapCache.sv

FM_VARIANTS = MbistBitmapCache
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，运行期 INITREG=0 / random / <seed>017 三档选初值
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check

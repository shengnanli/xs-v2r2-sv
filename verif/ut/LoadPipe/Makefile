# LoadPipe —— DCache 的 load 读流水（s0..s3），DCache 里例化 3 份（ldu_0..2）。
# 自足叶子：无子模块、无黑盒。
MODULE = LoadPipe

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/LoadPipe.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadPipe.sv

FM_VARIANTS = LoadPipe
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check

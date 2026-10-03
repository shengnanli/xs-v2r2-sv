# BoothEncoderF64F32F16_3 —— 向量浮点乘加的 Booth-4 部分积生成器（纯组合叶子：无子模块、无黑盒）。
MODULE = BoothEncoderF64F32F16_3

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/BoothEncoderF64F32F16_3.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/BoothEncoderF64F32F16_3.sv

FM_VARIANTS = BoothEncoderF64F32F16_3
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 纯组合，没有寄存器；initreg 仍按全仓口径开机制（三档读数应当逐字相同）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check

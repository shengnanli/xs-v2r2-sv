MODULE = skidBufferConnect

# VLSplit / VSSplit 出口的单项 skid buffer。核 xs_SkidBuffer_core（打包载荷），薄文件由
# scripts/gen_payload_shells.py 生成（同时生成本目录 fm_pins_pre.tcl：golden 逐字段寄存器 <-> 核里打包向量）。
# 无子模块、无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/xs_SkidBuffer_core.sv $(RTL_DIR)/memblock/skidBufferConnect.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/skidBufferConnect.sv
FM_VARIANTS = skidBufferConnect
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check

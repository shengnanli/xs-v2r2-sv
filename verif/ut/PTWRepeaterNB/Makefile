MODULE = PTWRepeaterNB

# L1 TLB 与 L2TLB 之间的单项请求/应答中继。核 xs_PTWRepeaterNB_core（打包载荷），薄文件由
# scripts/gen_payload_shells.py 生成（同时生成本目录 fm_pins_pre.tcl：golden 逐字段寄存器 <-> 核里打包向量）。
# 子模块 DelayN_1（coverage_three_axis: PROVEN_DIRECT）两侧白盒：ref 用 golden DelayN_1.sv，impl 用本仓重写件。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DelayN_core.sv $(RTL_DIR)/common/DelayN_1.sv \
           $(RTL_DIR)/mmu/xs_PTWRepeaterNB_core.sv $(RTL_DIR)/mmu/PTWRepeaterNB.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DelayN_1.sv $(GOLDEN_RTL)/PTWRepeaterNB.sv
FM_VARIANTS = PTWRepeaterNB
FM_REF_DEPS_PTWRepeaterNB = DelayN_1.sv
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

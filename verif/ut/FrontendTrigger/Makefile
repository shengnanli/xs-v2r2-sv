# FrontendTrigger —— 前端取指断点触发器（4 个 mcontrol execute 触发器 × 16 个 PC 位置）。
# 自足叶子：无子模块、无黑盒。全部寄存器异步复位。
MODULE = FrontendTrigger

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/frontend/FrontendTrigger.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/FrontendTrigger.sv

FM_VARIANTS = FrontendTrigger
FM_MERGE_DUP = false
# vmucp（加强不是放宽）：唯一的 56 个 unread 点是 tdata2[63:50]（4 个触发器 × 14 位），两侧对称死位，
# 依据与六条证据见 verif/fm_target_config/FrontendTrigger.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check
	python3 ../../../scripts/gen_newifu_lane.py --check

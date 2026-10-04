# SRT16DividerDataModule —— 64 位 radix-16 SRT 整数除法器数据通路（DivUnit 的子模块）。
# 子模块两侧白盒：CSA3_2_3956 ×4、CSA3_2_3960 ×2、CSA3_2_3962 ×25、RightShifter；
# ref 侧 golden 闭包，impl 侧本工程已签核（PROVEN_DIRECT）的重写件（CSA3_2.sv 家族核）。无黑盒。
MODULE = SRT16DividerDataModule

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/CSA3_2.sv \
           $(RTL_DIR)/backend/CSA3_2_3956.sv \
           $(RTL_DIR)/backend/CSA3_2_3960.sv \
           $(RTL_DIR)/backend/CSA3_2_3962.sv \
           $(RTL_DIR)/backend/RightShifter.sv \
           $(RTL_DIR)/backend/SRT16DividerDataModule.sv
TB_SRCS  = tb.sv

SRT_DEPS = CSA3_2_3956.sv CSA3_2_3960.sv CSA3_2_3962.sv RightShifter.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SRT16DividerDataModule.sv $(addprefix $(GOLDEN_RTL)/,$(SRT_DEPS))

FM_VARIANTS = SRT16DividerDataModule
FM_REF_DEPS_SRT16DividerDataModule = $(SRT_DEPS)
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 只有 state 复位，其余全是 RegEnable：tb 的 arm 等 golden 第一次到 s_post_1 才开比。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check

# vmucp：6 个对称死位（aLZCReg/dLZCReg[6]、udNegReg_{0,1,3,4}[67]）交 FM 实比，
# 依据与白名单见 verif/fm_target_config/SRT16DividerDataModule.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

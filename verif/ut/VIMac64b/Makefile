# VIMac64b —— 64 位向量整数乘加单元（Booth-4 + Wallace 树，三拍）。自足叶子：无子模块、无黑盒。
MODULE = VIMac64b

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/VIMac64b.sv
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/VIMac64b.sv

FM_VARIANTS = VIMac64b
FM_MERGE_DUP = false
# vmucp（加强不是放宽）：对称死位的依据与六条证据见 verif/fm_target_config/VIMac64b.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg：编译期开机制、运行期选取值（两处都要给，见 CONVENTIONS）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check

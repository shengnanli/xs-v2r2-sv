MODULE = MSHR

RTL_DIR  = ../../../rtl
# 单文件：package mshr_pkg + xs_MSHR_core（手写）+ golden 同名 wrapper（scripts/gen_mshr.py 生成）
RTL_SRCS = $(RTL_DIR)/uncore/MSHR.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MSHR.sv
FM_VARIANTS = MSHR
FM_MERGE_DUP = false
# 69 个对称死位（validCnt 64 + 断言影子 REG/REG_1..3 + state_w_pprobeackfirst）按 vmucp 实比，
# 依据见 verif/fm_target_config/MSHR.tcl
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

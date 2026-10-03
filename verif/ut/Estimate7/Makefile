MODULE = Estimate7

# Estimate7（vfrec7 / vfrsqrt7 的 7 位估算子单元，2 拍流水）。
# golden 直接 child 三个：
#   CLZ_6                 —— PROVEN_DIRECT，两侧白盒（ref golden / impl 本仓重写件）；
#   Rec7Table/Rsqrt7Table —— PROVEN_DIRECT（agent/next200c-takeover 签核 @64f5633a1）：两侧白盒，impl 读重写件 rtl/backend/Rec7Table.sv、Rsqrt7Table.sv。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/backend/Estimate7.sv \
           $(RTL_DIR)/backend/Rec7Table.sv \
           $(RTL_DIR)/backend/Rsqrt7Table.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

ESTIMATE7_TABLES = Rec7Table.sv Rsqrt7Table.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Estimate7.sv \
              $(GOLDEN_RTL)/CLZ_6.sv \
              $(addprefix $(GOLDEN_RTL)/,$(ESTIMATE7_TABLES))
FM_VARIANTS = Estimate7
FM_REF_DEPS_Estimate7 = CLZ_6.sv $(ESTIMATE7_TABLES)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

# vmucp：本 UT 的每个 FM 目标在 verif/fm_target_config/<T>.tcl 都有白名单条目与依据（双射、全零判据）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

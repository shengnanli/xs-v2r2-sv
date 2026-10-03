MODULE = Estimate7

# Estimate7（vfrec7 / vfrsqrt7 的 7 位估算子单元，2 拍流水）。
# golden 直接 child 三个：
#   CLZ_6                 —— PROVEN_DIRECT，两侧白盒（ref golden / impl 本仓重写件）；
#   Rec7Table/Rsqrt7Table —— 归 agent/newrtl-next200c 重写，尚未合入 main：
#                            两侧同源 golden（RTL_GOLDEN_DEPS），对方签核合入后按 STALE 规则重证。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/backend/Estimate7.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

ESTIMATE7_TABLES = Rec7Table.sv Rsqrt7Table.sv
RTL_GOLDEN_DEPS  = $(addprefix $(GOLDEN_RTL)/,$(ESTIMATE7_TABLES))

GOLDEN_SRCS = $(GOLDEN_RTL)/Estimate7.sv \
              $(GOLDEN_RTL)/CLZ_6.sv
FM_VARIANTS = Estimate7
FM_REF_DEPS_Estimate7 = CLZ_6.sv $(ESTIMATE7_TABLES)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

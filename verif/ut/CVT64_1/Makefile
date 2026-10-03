MODULE = CVT64_1

# CVT64_1（向量转换 64 位通道总装）+ VCVT（它外面那层纯连线壳），一个 UT 两个 FM 目标。
# golden 子树：FP_INCVT / INT2FP / Estimate7，及其下 CLZ_6 / ShiftRightJam / RoundingUnit_3 /
#   RoundingUnit_4 / Rec7Table / Rsqrt7Table。处置：
#   INT2FP / Estimate7            —— 本 lane 重写，impl 读重写件；
#   CLZ_6 / ShiftRightJam / RoundingUnit_3 / RoundingUnit_4 —— PROVEN_DIRECT，两侧白盒（impl 读重写件）；
#   FP_INCVT                      —— PROVEN_IN_CONE、无重写件：两侧同源 golden（RTL_GOLDEN_DEPS）；
#   Rec7Table / Rsqrt7Table       —— 归 agent/newrtl-next200c，未入 main：两侧同源 golden，
#                                    对方签核合入后按 STALE 规则重证。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/backend/ShiftRightJam.sv \
           $(RTL_DIR)/backend/RoundingUnit_3.sv \
           $(RTL_DIR)/backend/RoundingUnit_4.sv \
           $(RTL_DIR)/backend/INT2FP.sv \
           $(RTL_DIR)/backend/Estimate7.sv \
           $(RTL_DIR)/backend/CVT64_1.sv \
           $(RTL_DIR)/backend/VCVT.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

CVT64_GOLDEN_SHARED = FP_INCVT.sv Rec7Table.sv Rsqrt7Table.sv
RTL_GOLDEN_DEPS     = $(addprefix $(GOLDEN_RTL)/,$(CVT64_GOLDEN_SHARED))

CVT64_GOLDEN_LEAVES = CLZ_6.sv ShiftRightJam.sv RoundingUnit_3.sv RoundingUnit_4.sv \
                      INT2FP.sv Estimate7.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/CVT64_1.sv $(GOLDEN_RTL)/VCVT.sv \
              $(addprefix $(GOLDEN_RTL)/,$(CVT64_GOLDEN_LEAVES))
FM_VARIANTS = CVT64_1 VCVT
FM_REF_DEPS_CVT64_1 = $(CVT64_GOLDEN_LEAVES) $(CVT64_GOLDEN_SHARED)
FM_REF_DEPS_VCVT    = CVT64_1.sv $(CVT64_GOLDEN_LEAVES) $(CVT64_GOLDEN_SHARED)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

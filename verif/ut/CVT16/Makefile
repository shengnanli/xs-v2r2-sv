MODULE = CVT16

# CVT16（向量转换 16 位通道的转换器）+ VCVT_2（它外面那层纯连线壳），一个 UT 两个 FM 目标。
# golden 直接 child：CLZ_7 / CLZ_28×2 / CLZ_30 / ShiftRightJam_4 / RoundingUnit_11 —— 均 PROVEN_DIRECT，
#   两侧白盒（impl 读重写件）；Rec7Table / Rsqrt7Table —— 归 agent/newrtl-next200c，未入 main：
#   两侧同源 golden（RTL_GOLDEN_DEPS），对方签核合入后按 STALE 规则重证。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_28.sv \
           $(RTL_DIR)/common/CLZ_30.sv \
           $(RTL_DIR)/backend/ShiftRightJam_4.sv \
           $(RTL_DIR)/backend/RoundingUnit_11.sv \
           $(RTL_DIR)/backend/CVT16.sv \
           $(RTL_DIR)/backend/VCVT_2.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

CVT16_TABLES    = Rec7Table.sv Rsqrt7Table.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(CVT16_TABLES))

CVT16_GOLDEN_LEAVES = CLZ_7.sv CLZ_28.sv CLZ_30.sv ShiftRightJam_4.sv RoundingUnit_11.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/CVT16.sv $(GOLDEN_RTL)/VCVT_2.sv \
              $(addprefix $(GOLDEN_RTL)/,$(CVT16_GOLDEN_LEAVES))
FM_VARIANTS = CVT16 VCVT_2
FM_REF_DEPS_CVT16  = $(CVT16_GOLDEN_LEAVES) $(CVT16_TABLES)
FM_REF_DEPS_VCVT_2 = CVT16.sv $(CVT16_GOLDEN_LEAVES) $(CVT16_TABLES)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

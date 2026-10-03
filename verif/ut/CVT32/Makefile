MODULE = CVT32

# CVT32（向量转换 32 位通道的转换器）+ VCVT_1（它外面那层纯连线壳），一个 UT 两个 FM 目标。
# golden 直接 child：CLZ_7 / CLZ_9 / CLZ_28×3 / CLZ_29×2 / CLZ_30 / CLZ_31 / ShiftRightJam_2 /
#   ShiftRightJam_3 / RoundingUnit_8 / RoundingUnit_9×2 —— 均 PROVEN_DIRECT，两侧白盒（impl 读重写件）；
#   Rec7Table / Rsqrt7Table —— 归 agent/newrtl-next200c，未入 main：两侧同源 golden（RTL_GOLDEN_DEPS），
#   对方签核合入后按 STALE 规则重证。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_9.sv \
           $(RTL_DIR)/common/CLZ_28.sv \
           $(RTL_DIR)/common/CLZ_29.sv \
           $(RTL_DIR)/common/CLZ_30.sv \
           $(RTL_DIR)/common/CLZ_31.sv \
           $(RTL_DIR)/backend/ShiftRightJam_2.sv \
           $(RTL_DIR)/backend/ShiftRightJam_3.sv \
           $(RTL_DIR)/backend/RoundingUnit_8.sv \
           $(RTL_DIR)/backend/RoundingUnit_9.sv \
           $(RTL_DIR)/backend/CVT32.sv \
           $(RTL_DIR)/backend/VCVT_1.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

CVT32_TABLES    = Rec7Table.sv Rsqrt7Table.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(CVT32_TABLES))

CVT32_GOLDEN_LEAVES = CLZ_7.sv CLZ_9.sv CLZ_28.sv CLZ_29.sv CLZ_30.sv CLZ_31.sv \
                      ShiftRightJam_2.sv ShiftRightJam_3.sv RoundingUnit_8.sv RoundingUnit_9.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/CVT32.sv $(GOLDEN_RTL)/VCVT_1.sv \
              $(addprefix $(GOLDEN_RTL)/,$(CVT32_GOLDEN_LEAVES))
FM_VARIANTS = CVT32 VCVT_1
FM_REF_DEPS_CVT32  = $(CVT32_GOLDEN_LEAVES) $(CVT32_TABLES)
FM_REF_DEPS_VCVT_1 = CVT32.sv $(CVT32_GOLDEN_LEAVES) $(CVT32_TABLES)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

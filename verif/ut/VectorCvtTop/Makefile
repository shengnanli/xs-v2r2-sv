MODULE = VectorCvtTop

# VectorCvtTop（128 位向量浮点转换顶层：两份 64 位 VectorCvt 并排）。
# 子树处置：
#   VectorCvt / VCVT* / CVT64_1 / CVT32 / CVT16 / INT2FP / Estimate7 —— 本 lane 重写，impl 读重写件；
#   CLZ_* / ShiftRightJam* / RoundingUnit_*              —— PROVEN_DIRECT，两侧白盒（impl 读重写件）；
#   FP_INCVT                                            —— PROVEN_IN_CONE、无重写件：两侧同源 golden；
#   Rec7Table / Rsqrt7Table                             —— 归 agent/newrtl-next200c，未入 main：两侧同源 golden，
#                                                          对方签核合入后按 STALE 规则重证。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_9.sv \
           $(RTL_DIR)/common/CLZ_28.sv \
           $(RTL_DIR)/common/CLZ_29.sv \
           $(RTL_DIR)/common/CLZ_30.sv \
           $(RTL_DIR)/common/CLZ_31.sv \
           $(RTL_DIR)/backend/ShiftRightJam.sv \
           $(RTL_DIR)/backend/ShiftRightJam_2.sv \
           $(RTL_DIR)/backend/ShiftRightJam_3.sv \
           $(RTL_DIR)/backend/ShiftRightJam_4.sv \
           $(RTL_DIR)/backend/RoundingUnit_3.sv \
           $(RTL_DIR)/backend/RoundingUnit_4.sv \
           $(RTL_DIR)/backend/RoundingUnit_8.sv \
           $(RTL_DIR)/backend/RoundingUnit_9.sv \
           $(RTL_DIR)/backend/RoundingUnit_11.sv \
           $(RTL_DIR)/backend/INT2FP.sv \
           $(RTL_DIR)/backend/Estimate7.sv \
           $(RTL_DIR)/backend/CVT64_1.sv \
           $(RTL_DIR)/backend/VCVT.sv \
           $(RTL_DIR)/backend/CVT32.sv \
           $(RTL_DIR)/backend/VCVT_1.sv \
           $(RTL_DIR)/backend/CVT16.sv \
           $(RTL_DIR)/backend/VCVT_2.sv \
           $(RTL_DIR)/backend/VectorCvt.sv \
           $(RTL_DIR)/backend/VectorCvtTop.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

VCVT_GOLDEN_SHARED = FP_INCVT.sv Rec7Table.sv Rsqrt7Table.sv
RTL_GOLDEN_DEPS    = $(addprefix $(GOLDEN_RTL)/,$(VCVT_GOLDEN_SHARED))

VCVT_GOLDEN_LEAVES = CLZ_6.sv CLZ_7.sv CLZ_9.sv CLZ_28.sv CLZ_29.sv CLZ_30.sv CLZ_31.sv \
                     ShiftRightJam.sv ShiftRightJam_2.sv ShiftRightJam_3.sv ShiftRightJam_4.sv \
                     RoundingUnit_3.sv RoundingUnit_4.sv RoundingUnit_8.sv RoundingUnit_9.sv RoundingUnit_11.sv \
                     INT2FP.sv Estimate7.sv CVT64_1.sv VCVT.sv CVT32.sv VCVT_1.sv CVT16.sv VCVT_2.sv VectorCvt.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/VectorCvtTop.sv $(addprefix $(GOLDEN_RTL)/,$(VCVT_GOLDEN_LEAVES))
FM_VARIANTS = VectorCvtTop
FM_REF_DEPS_VectorCvtTop = $(VCVT_GOLDEN_LEAVES) $(VCVT_GOLDEN_SHARED)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

# vmucp：本 UT 的每个 FM 目标在 verif/fm_target_config/<T>.tcl 都有白名单条目与依据（双射、全零判据）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

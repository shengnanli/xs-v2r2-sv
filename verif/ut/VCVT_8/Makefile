MODULE = VCVT_8

# VCVT_8（向量浮点转换功能单元）。golden 直接 child：VectorCvtTop、Mgu。
# 子树处置：
#   VectorCvtTop / VectorCvt / VCVT* / CVT64_1 / CVT32 / CVT16 / INT2FP / Estimate7 —— 本 lane 重写，impl 读重写件；
#   CLZ_* / ShiftRightJam* / RoundingUnit_*              —— PROVEN_DIRECT，两侧白盒（impl 读重写件）；
#   Mgu（+ByteMaskTailGen/UIntToContLow1s/0s/MaskExtractor）—— 本仓重写件；Mgu 的签核 receipt 在
#     agent/fu-atomics-fpdiv-imsic（evidence/d09e1997840f/Mgu），未入 main：两侧白盒（impl 读重写件），条件项；
#   FP_INCVT                                            —— PROVEN_IN_CONE、无重写件：两侧同源 golden；
#   Rec7Table / Rsqrt7Table                             —— PROVEN_DIRECT（agent/next200c-takeover 签核 @64f5633a1）：两侧白盒，impl 读重写件 rtl/backend/Rec7Table.sv、Rsqrt7Table.sv。
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
           $(RTL_DIR)/backend/VectorCvtTop.sv \
           $(RTL_DIR)/backend/UIntToContLow1s.sv \
           $(RTL_DIR)/backend/UIntToContLow0s.sv \
           $(RTL_DIR)/backend/MaskExtractor.sv \
           $(RTL_DIR)/backend/ByteMaskTailGen.sv \
           $(RTL_DIR)/backend/Mgu.sv \
           $(RTL_DIR)/backend/VCVT_8.sv \
           $(RTL_DIR)/backend/Rec7Table.sv \
           $(RTL_DIR)/backend/Rsqrt7Table.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

VCVT_GOLDEN_SHARED = FP_INCVT.sv
VCVT_TABLES        = Rec7Table.sv Rsqrt7Table.sv
RTL_GOLDEN_DEPS    = $(addprefix $(GOLDEN_RTL)/,$(VCVT_GOLDEN_SHARED))

VCVT_GOLDEN_LEAVES = CLZ_6.sv CLZ_7.sv CLZ_9.sv CLZ_28.sv CLZ_29.sv CLZ_30.sv CLZ_31.sv \
                     ShiftRightJam.sv ShiftRightJam_2.sv ShiftRightJam_3.sv ShiftRightJam_4.sv \
                     RoundingUnit_3.sv RoundingUnit_4.sv RoundingUnit_8.sv RoundingUnit_9.sv RoundingUnit_11.sv \
                     INT2FP.sv Estimate7.sv CVT64_1.sv VCVT.sv CVT32.sv VCVT_1.sv CVT16.sv VCVT_2.sv VectorCvt.sv VectorCvtTop.sv \
                     Mgu.sv ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/VCVT_8.sv $(addprefix $(GOLDEN_RTL)/,$(VCVT_GOLDEN_LEAVES)) \
              $(addprefix $(GOLDEN_RTL)/,$(VCVT_TABLES))
FM_VARIANTS = VCVT_8
FM_REF_DEPS_VCVT_8 = $(VCVT_GOLDEN_LEAVES) $(VCVT_GOLDEN_SHARED) $(VCVT_TABLES)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

# vmucp：本 UT 的每个 FM 目标在 verif/fm_target_config/<T>.tcl 都有白名单条目与依据（双射、全零判据）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

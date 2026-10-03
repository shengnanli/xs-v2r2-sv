MODULE = CVT32

# CVT32（向量转换 32 位通道的转换器）+ VCVT_1（它外面那层纯连线壳），一个 UT 两个 FM 目标。
# golden 直接 child：CLZ_7 / CLZ_9 / CLZ_28×3 / CLZ_29×2 / CLZ_30 / CLZ_31 / ShiftRightJam_2 /
#   ShiftRightJam_3 / RoundingUnit_8 / RoundingUnit_9×2 —— 均 PROVEN_DIRECT，两侧白盒（impl 读重写件）；
#   Rec7Table / Rsqrt7Table —— PROVEN_DIRECT（agent/next200c-takeover 签核 @64f5633a1）：两侧白盒，impl 读重写件 rtl/backend/Rec7Table.sv、Rsqrt7Table.sv。
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
           $(RTL_DIR)/backend/VCVT_1.sv \
           $(RTL_DIR)/backend/Rec7Table.sv \
           $(RTL_DIR)/backend/Rsqrt7Table.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

CVT32_TABLES    = Rec7Table.sv Rsqrt7Table.sv

CVT32_GOLDEN_LEAVES = CLZ_7.sv CLZ_9.sv CLZ_28.sv CLZ_29.sv CLZ_30.sv CLZ_31.sv \
                      ShiftRightJam_2.sv ShiftRightJam_3.sv RoundingUnit_8.sv RoundingUnit_9.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/CVT32.sv $(GOLDEN_RTL)/VCVT_1.sv \
              $(addprefix $(GOLDEN_RTL)/,$(CVT32_GOLDEN_LEAVES)) \
              $(addprefix $(GOLDEN_RTL)/,$(CVT32_TABLES))
FM_VARIANTS = CVT32 VCVT_1
FM_REF_DEPS_CVT32  = $(CVT32_GOLDEN_LEAVES) $(CVT32_TABLES)
FM_REF_DEPS_VCVT_1 = CVT32.sv $(CVT32_GOLDEN_LEAVES) $(CVT32_TABLES)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

# vmucp：本 UT 的每个 FM 目标在 verif/fm_target_config/<T>.tcl 都有白名单条目与依据（双射、全零判据）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

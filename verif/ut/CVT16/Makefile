MODULE = CVT16

# CVT16（向量转换 16 位通道的转换器）+ VCVT_2（它外面那层纯连线壳），一个 UT 两个 FM 目标。
# golden 直接 child：CLZ_7 / CLZ_28×2 / CLZ_30 / ShiftRightJam_4 / RoundingUnit_11 —— 均 PROVEN_DIRECT，
#   两侧白盒（impl 读重写件）；Rec7Table / Rsqrt7Table —— PROVEN_DIRECT（agent/next200c-takeover 签核 @64f5633a1）：两侧白盒，impl 读重写件 rtl/backend/Rec7Table.sv、Rsqrt7Table.sv。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_7.sv \
           $(RTL_DIR)/common/CLZ_28.sv \
           $(RTL_DIR)/common/CLZ_30.sv \
           $(RTL_DIR)/backend/ShiftRightJam_4.sv \
           $(RTL_DIR)/backend/RoundingUnit_11.sv \
           $(RTL_DIR)/backend/CVT16.sv \
           $(RTL_DIR)/backend/VCVT_2.sv \
           $(RTL_DIR)/backend/Rec7Table.sv \
           $(RTL_DIR)/backend/Rsqrt7Table.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

CVT16_TABLES    = Rec7Table.sv Rsqrt7Table.sv

CVT16_GOLDEN_LEAVES = CLZ_7.sv CLZ_28.sv CLZ_30.sv ShiftRightJam_4.sv RoundingUnit_11.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/CVT16.sv $(GOLDEN_RTL)/VCVT_2.sv \
              $(addprefix $(GOLDEN_RTL)/,$(CVT16_GOLDEN_LEAVES)) \
              $(addprefix $(GOLDEN_RTL)/,$(CVT16_TABLES))
FM_VARIANTS = CVT16 VCVT_2
FM_REF_DEPS_CVT16  = $(CVT16_GOLDEN_LEAVES) $(CVT16_TABLES)
FM_REF_DEPS_VCVT_2 = CVT16.sv $(CVT16_GOLDEN_LEAVES) $(CVT16_TABLES)

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

# vmucp：本 UT 的每个 FM 目标在 verif/fm_target_config/<T>.tcl 都有白名单条目与依据（双射、全零判据）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

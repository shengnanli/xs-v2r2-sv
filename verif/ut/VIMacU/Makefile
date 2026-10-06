# 由 tools/kimi_lane.py 按模板生成（KIMI 只提供源清单）
MODULE = VIMacU
RTL_SRCS = $(addprefix ../../../,rtl/backend/UIntToContLow1s.sv rtl/backend/UIntToContLow0s.sv rtl/backend/MaskExtractor.sv rtl/backend/ByteMaskTailGen.sv rtl/backend/Mgu.sv rtl/backend/VecDataSplitModule.sv rtl/backend/VIMac64b.sv rtl/backend/VIMacSrcTypeModule.sv rtl/backend/VIMacU.sv)
TB_SRCS  = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,VIMacU.sv Mgu.sv ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv VecDataSplitModule.sv VIMac64b.sv VIMacSrcTypeModule.sv)
FM_VARIANTS = VIMacU
FM_REF_DEPS_VIMacU = Mgu.sv ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv VecDataSplitModule.sv VIMac64b.sv VIMacSrcTypeModule.sv
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

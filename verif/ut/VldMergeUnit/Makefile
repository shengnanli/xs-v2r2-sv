MODULE = VldMergeUnit

# 向量 load 合并链：UIntToContLow1s/0s -> ByteMaskTailGen -> VldMgu -> VldMergeUnit，五个目标一个 UT。
# VldMergeUnit 的 wrapper 与本 tb 由 scripts/gen_vldmergeunit.py 生成。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/UIntToContLow1s.sv \
           $(RTL_DIR)/backend/UIntToContLow0s.sv \
           $(RTL_DIR)/backend/MaskExtractor.sv \
           $(RTL_DIR)/backend/ByteMaskTailGen.sv \
           $(RTL_DIR)/backend/VldMgu.sv \
           $(RTL_DIR)/backend/VldMergeUnit.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/UIntToContLow1s.sv $(GOLDEN_RTL)/UIntToContLow0s.sv \
              $(GOLDEN_RTL)/MaskExtractor.sv $(GOLDEN_RTL)/ByteMaskTailGen.sv \
              $(GOLDEN_RTL)/VldMgu.sv $(GOLDEN_RTL)/VldMergeUnit.sv

FM_VARIANTS = UIntToContLow1s UIntToContLow0s ByteMaskTailGen VldMgu VldMergeUnit
# 模型严格适用（fm_predict.py）
FM_MERGE_DUP = false

# FM ref 侧：golden 本体 + golden 子模块原件；impl 侧 = RTL_SRCS 全部重写件（两侧白盒，无黑盒）
FM_REF_DEPS_ByteMaskTailGen = UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv
FM_REF_DEPS_VldMgu          = ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv
FM_REF_DEPS_VldMergeUnit    = VldMgu.sv ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

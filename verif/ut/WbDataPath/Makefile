MODULE = WbDataPath

# 本体 + 全部子模块的重写件（两侧白盒，无黑盒）。wrapper / 配置表 / tb 由 scripts/gen_wbdatapath.py 生成。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_PriorityArbSelect.sv \
           $(RTL_DIR)/backend/RealWBCollideChecker.sv \
           $(RTL_DIR)/backend/RealWBCollideChecker_1.sv \
           $(RTL_DIR)/backend/RealWBCollideChecker_2.sv \
           $(RTL_DIR)/backend/RealWBCollideChecker_3.sv \
           $(RTL_DIR)/backend/RealWBCollideChecker_4.sv \
           $(RTL_DIR)/backend/UIntToContLow1s.sv \
           $(RTL_DIR)/backend/UIntToContLow0s.sv \
           $(RTL_DIR)/backend/MaskExtractor.sv \
           $(RTL_DIR)/backend/ByteMaskTailGen.sv \
           $(RTL_DIR)/backend/VldMgu.sv \
           $(RTL_DIR)/backend/VldMergeUnit.sv \
           $(RTL_DIR)/backend/WbDataPath.sv
TB_SRCS  = tb.sv

GOLDEN_CHILDREN = RealWBCollideChecker.sv RealWBCollideChecker_1.sv RealWBCollideChecker_2.sv \
                  RealWBCollideChecker_3.sv RealWBCollideChecker_4.sv \
                  RealWBArbiter.sv RealWBArbiter_1.sv RealWBArbiter_2.sv RealWBArbiter_3.sv \
                  RealWBArbiter_14.sv RealWBArbiter_15.sv RealWBArbiter_20.sv RealWBArbiter_21.sv \
                  RealWBArbiter_26.sv \
                  VldMergeUnit.sv VldMgu.sv ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv \
                  MaskExtractor.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/WbDataPath.sv $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_CHILDREN))

FM_VARIANTS = WbDataPath
FM_MERGE_DUP = false
FM_REF_DEPS_WbDataPath = RealWBCollideChecker.sv RealWBCollideChecker_1.sv RealWBCollideChecker_2.sv RealWBCollideChecker_3.sv RealWBCollideChecker_4.sv RealWBArbiter.sv RealWBArbiter_1.sv RealWBArbiter_2.sv RealWBArbiter_3.sv RealWBArbiter_14.sv RealWBArbiter_15.sv RealWBArbiter_20.sv RealWBArbiter_21.sv RealWBArbiter_26.sv VldMergeUnit.sv VldMgu.sv ByteMaskTailGen.sv UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

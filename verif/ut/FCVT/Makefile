MODULE = FCVT

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/fcvt_pkg.sv \
           $(RTL_DIR)/backend/FCVT.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 浮点转换器 FPCVT 及其叶子（两侧 UT 共用）。
FCVT_DEPS = FPCVT.sv CVT64.sv FP_INCVT.sv CLZ_6.sv RoundingUnit_3.sv \
            RoundingUnit_4.sv ShiftRightJam.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FCVT.sv $(addprefix $(GOLDEN_RTL)/,$(FCVT_DEPS))

WRAPPER_SRCS = $(RTL_DIR)/backend/FCVT_wrapper.sv $(addprefix $(GOLDEN_RTL)/,$(FCVT_DEPS))
FM_VARIANTS = FCVT
FM_REF_DEPS_FCVT = $(FCVT_DEPS)
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

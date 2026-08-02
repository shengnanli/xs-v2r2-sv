MODULE = RobEnqPtrWrapper

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/RobEnqPtrWrapper.sv

TB_SRCS = variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RobEnqPtrWrapper.sv

WRAPPER_SRCS = $(RTL_DIR)/backend/RobEnqPtrWrapper_wrapper.sv
FM_VARIANTS = RobEnqPtrWrapper

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

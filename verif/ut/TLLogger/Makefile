MODULE = TLLogger

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/TLLogger.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/TLLogger_wrapper.sv

# 无子模块依赖
GOLDEN_SRCS = $(GOLDEN_RTL)/TLLogger.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TLLogger
FM_REF_DEPS_TLLogger = 

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

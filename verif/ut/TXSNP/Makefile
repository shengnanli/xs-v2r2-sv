MODULE = TXSNP

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/TXSNP.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/TXSNP_wrapper.sv

# 无子模块依赖
GOLDEN_SRCS = $(GOLDEN_RTL)/TXSNP.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TXSNP
FM_REF_DEPS_TXSNP = 

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

MODULE = SinkA

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/SinkA.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/SinkA_wrapper.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SinkA.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SinkA
FM_REF_DEPS_SinkA =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

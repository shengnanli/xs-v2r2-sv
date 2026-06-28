MODULE = SourceB

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/SourceB.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/SourceB_wrapper.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/SourceB.sv $(GOLDEN_RTL)/FastArbiter_6.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden SourceB 本体, FastArbiter_6 两侧均黑盒
FM_VARIANTS = SourceB
FM_REF_DEPS_SourceB =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

MODULE = RequestArb

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/l2_task_pkg.sv $(RTL_DIR)/uncore/RequestArb.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/RequestArb_wrapper.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/RequestArb.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: 无子模块, ref = golden RequestArb 本体
FM_VARIANTS = RequestArb
FM_REF_DEPS_RequestArb =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

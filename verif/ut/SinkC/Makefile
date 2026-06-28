MODULE = SinkC

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/sinkc_pkg.sv $(RTL_DIR)/uncore/SinkC.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/SinkC_wrapper.sv

# 核内例化 RRArbiterInit_14: UT/变体编译与 golden 比对都需要它
GOLDEN_SRCS = $(GOLDEN_RTL)/SinkC.sv $(GOLDEN_RTL)/RRArbiterInit_14.sv
TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden SinkC 本体, RRArbiterInit_14 两侧均黑盒
FM_VARIANTS = SinkC
FM_REF_DEPS_SinkC =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

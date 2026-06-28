MODULE = MSHRCtl

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/MSHRCtl.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/MSHRCtl_wrapper.sv

# UT 双例化两侧共享的 golden 黑盒积木: MSHR / 选择器 / SourceB / 4 个仲裁器
GOLDEN_SRCS = $(GOLDEN_RTL)/MSHRCtl.sv \
              $(GOLDEN_RTL)/MSHR.sv \
              $(GOLDEN_RTL)/MSHRSelector.sv \
              $(GOLDEN_RTL)/SourceB.sv \
              $(GOLDEN_RTL)/FastArbiter_6.sv \
              $(GOLDEN_RTL)/FastArbiter_4.sv \
              $(GOLDEN_RTL)/FastArbiter_5.sv \
              $(GOLDEN_RTL)/FastArbiter_7.sv \
              $(GOLDEN_RTL)/FastArbiter_8.sv

TB_SRCS = variants_xs.sv tb.sv

# FM: ref 仅给 golden MSHRCtl 本体, 子模块两侧均黑盒
FM_VARIANTS = MSHRCtl
FM_REF_DEPS_MSHRCtl =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random +incdir+$(RTL_DIR)/uncore
SIM_ARGS += +vcs+initreg+0

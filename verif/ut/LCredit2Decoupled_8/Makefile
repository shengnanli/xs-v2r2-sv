MODULE = LCredit2Decoupled_8

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_8.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_8_wrapper.sv $(GOLDEN_RTL)/Queue4_CHIREQ.sv $(GOLDEN_RTL)/ram_4x151.sv

# 子模块黑盒(UT 共用真定义; FM 两侧均引入同一 golden 子模块做整体等价): Queue4_CHIREQ.sv, ram_4x151.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LCredit2Decoupled_8.sv $(GOLDEN_RTL)/Queue4_CHIREQ.sv $(GOLDEN_RTL)/ram_4x151.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = LCredit2Decoupled_8
FM_REF_DEPS_LCredit2Decoupled_8 = Queue4_CHIREQ.sv ram_4x151.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

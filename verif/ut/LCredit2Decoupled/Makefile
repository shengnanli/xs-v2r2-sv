MODULE = LCredit2Decoupled

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled.sv
WRAPPER_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_wrapper.sv $(GOLDEN_RTL)/Queue4_CHISNP.sv $(GOLDEN_RTL)/ram_4x115.sv

# 子模块黑盒(UT 共用真定义; FM 两侧均引入同一 golden 子模块做整体等价): Queue4_CHISNP.sv, ram_4x115.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LCredit2Decoupled.sv $(GOLDEN_RTL)/Queue4_CHISNP.sv $(GOLDEN_RTL)/ram_4x115.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = LCredit2Decoupled
FM_REF_DEPS_LCredit2Decoupled = Queue4_CHISNP.sv ram_4x115.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

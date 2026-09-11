MODULE = LCredit2Decoupled_8

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_8.sv \
           $(GOLDEN_RTL)/Queue4_CHIREQ.sv \
           $(GOLDEN_RTL)/ram_4x151.sv
TB_SRCS = tb.sv

FM_REF_DEPS_LCredit2Decoupled_8 = Queue4_CHIREQ.sv ram_4x151.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LCredit2Decoupled_8.sv \
              $(GOLDEN_RTL)/Queue4_CHIREQ.sv \
              $(GOLDEN_RTL)/ram_4x151.sv
FM_VARIANTS = LCredit2Decoupled_8

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

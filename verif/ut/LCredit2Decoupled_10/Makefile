MODULE = LCredit2Decoupled_10

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled_10.sv \
           $(GOLDEN_RTL)/Queue4_CHIDAT.sv \
           $(GOLDEN_RTL)/ram_4x422.sv
TB_SRCS = tb.sv

FM_REF_DEPS_LCredit2Decoupled_10 = Queue4_CHIDAT.sv ram_4x422.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LCredit2Decoupled_10.sv \
              $(GOLDEN_RTL)/Queue4_CHIDAT.sv \
              $(GOLDEN_RTL)/ram_4x422.sv
FM_VARIANTS = LCredit2Decoupled_10

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

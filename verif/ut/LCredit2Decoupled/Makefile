MODULE = LCredit2Decoupled

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/LCredit2Decoupled.sv \
           $(GOLDEN_RTL)/Queue4_CHISNP.sv \
           $(GOLDEN_RTL)/ram_4x115.sv
TB_SRCS = tb.sv

FM_REF_DEPS_LCredit2Decoupled = Queue4_CHISNP.sv ram_4x115.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LCredit2Decoupled.sv \
              $(GOLDEN_RTL)/Queue4_CHISNP.sv \
              $(GOLDEN_RTL)/ram_4x115.sv
FM_VARIANTS = LCredit2Decoupled

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

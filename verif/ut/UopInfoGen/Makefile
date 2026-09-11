MODULE = UopInfoGen

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/UopInfoGen.sv
TB_SRCS = tb.sv

FM_REF_DEPS_UopInfoGen = strdiedLSNumOfUopTable.sv indexedLSNumOfUopTable.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/UopInfoGen.sv \
              $(GOLDEN_RTL)/strdiedLSNumOfUopTable.sv \
              $(GOLDEN_RTL)/indexedLSNumOfUopTable.sv
FM_VARIANTS = UopInfoGen

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

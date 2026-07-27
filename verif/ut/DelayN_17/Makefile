MODULE = DelayN_17

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/backend/DelayN.sv

TB_SRCS = $(RTL_DIR)/backend/DelayN_variants_xs.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DelayN_17.sv

WRAPPER_SRCS =
FM_VARIANTS = DelayN_17

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

MODULE = ShiftMathLeaves8

RTL_DIR = ../../../rtl/backend
LEAVES = CloseShiftLeftWithMux CloseShiftLeftWithMux_1 CloseShiftLeftWithMux_9 \
         FarShiftRightWithMuxInvFirst FarShiftRightWithMuxInvFirst_2 \
         FarShiftRightWithMuxInvFirst_18 LeftShiftModule LeftShiftWordModule
RTL_SRCS = $(addprefix $(RTL_DIR)/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

MODULE = ShiftRightLeaves6
RTL_DIR = ../../../rtl
LEAVES = ShiftRightJam ShiftRightJam_2 ShiftRightJam_3 ShiftRightJam_4 \
         RightShiftModule RightShiftWordModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

MODULE = RoundingLeaves8

RTL_DIR = ../../../rtl
LEAVES = RoundingUnit RoundingUnit_1 RoundingUnit_2 RoundingUnit_3 \
         RoundingUnit_4 RoundingUnit_8 RoundingUnit_9 RoundingUnit_11
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

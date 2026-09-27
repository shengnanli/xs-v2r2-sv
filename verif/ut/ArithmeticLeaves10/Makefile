MODULE = ArithmeticLeaves10

RTL_DIR = ../../../rtl
LEAVES = Adder_18 Adder_xb Adder_xb_3 Adder_xb_8 Adder_xb_20 \
         CSA3to2_20 CSA3to2_24 CSA3to2_124 CSA3to2_125 CSA3to2_127
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

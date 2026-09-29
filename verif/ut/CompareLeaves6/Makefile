MODULE = CompareLeaves6

RTL_DIR = ../../../rtl
LEAVES = compare_2to1 compare_2to1_2 compare_3to1 compare_3to1_1 \
         compare_3to1_2 compare_3to1_6
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES))) \
              $(GOLDEN_RTL)/Adder_xb.sv $(GOLDEN_RTL)/Adder_xb_3.sv \
              $(GOLDEN_RTL)/Adder_xb_8.sv $(GOLDEN_RTL)/Adder_xb_20.sv
FM_VARIANTS = $(LEAVES)

FM_REF_DEPS_compare_2to1 = Adder_xb_3.sv
FM_REF_DEPS_compare_2to1_2 = Adder_xb_20.sv
FM_REF_DEPS_compare_3to1 = Adder_xb.sv
FM_REF_DEPS_compare_3to1_1 = Adder_xb_3.sv
FM_REF_DEPS_compare_3to1_2 = Adder_xb_8.sv
FM_REF_DEPS_compare_3to1_6 = Adder_xb_20.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

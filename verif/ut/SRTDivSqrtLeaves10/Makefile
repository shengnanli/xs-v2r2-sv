MODULE = SRTDivSqrtLeaves10

RTL_DIR = ../../../rtl
LEAVES = r4_qds r4_qds_v2 r4_qds_spec r4_qds_v2_spec r4_qds_cg SRT4qdsCons IterBlockI8Nr4 lzc lzc_3 lzc_4
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

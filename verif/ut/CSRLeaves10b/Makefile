MODULE = CSRLeaves10b
RTL_DIR = ../../../rtl
LEAVES = Sstateen1Module Sstateen2Module Sstateen3Module Pmpcfg8Module \
 Pmpcfg10Module Pmpcfg12Module Pmpcfg14Module Pmpcfg0Module Pmpcfg2Module Pmpcfg4Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

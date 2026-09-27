MODULE = CSRLeaves15
RTL_DIR = ../../../rtl
LEAVES = MconfigptrModule MhartidModule HgeipModule MiregModule SiregModule \
 VSiregModule Tdata2Module MtopiModule StopiModule VStopiModule \
 Pmacfg0Module Pmacfg2Module Pmacfg4Module Pmacfg6Module IntSyncSyncCrossingSink
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

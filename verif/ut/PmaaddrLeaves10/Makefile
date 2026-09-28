MODULE = PmaaddrLeaves10
RTL_DIR = ../../../rtl
LEAVES = Pmaaddr1Module Pmaaddr2Module Pmaaddr3Module Pmaaddr4Module \
 Pmaaddr5Module Pmaaddr6Module Pmaaddr7Module Pmaaddr8Module \
 Pmaaddr9Module Pmaaddr10Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

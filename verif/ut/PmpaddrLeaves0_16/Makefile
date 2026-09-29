MODULE = PmpaddrLeaves0_16
RTL_DIR = ../../../rtl
LEAVES = Pmpaddr0Module Pmpaddr1Module Pmpaddr2Module Pmpaddr3Module \
 Pmpaddr4Module Pmpaddr5Module Pmpaddr6Module Pmpaddr7Module \
 Pmpaddr8Module Pmpaddr9Module Pmpaddr10Module Pmpaddr11Module \
 Pmpaddr12Module Pmpaddr13Module Pmpaddr14Module Pmpaddr15Module \
 Pmpaddr16Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

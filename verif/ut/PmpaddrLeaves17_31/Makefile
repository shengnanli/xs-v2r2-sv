MODULE = PmpaddrLeaves17_31
RTL_DIR = ../../../rtl
LEAVES = Pmpaddr17Module Pmpaddr18Module Pmpaddr19Module Pmpaddr20Module \
 Pmpaddr21Module Pmpaddr22Module Pmpaddr23Module Pmpaddr24Module \
 Pmpaddr25Module Pmpaddr26Module Pmpaddr27Module Pmpaddr28Module \
 Pmpaddr29Module Pmpaddr30Module Pmpaddr31Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

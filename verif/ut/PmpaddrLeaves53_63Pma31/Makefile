MODULE = PmpaddrLeaves53_63Pma31
RTL_DIR = ../../../rtl
LEAVES = Pmpaddr53Module Pmpaddr54Module Pmpaddr55Module Pmpaddr56Module \
         Pmpaddr57Module Pmpaddr58Module Pmpaddr59Module Pmpaddr60Module \
         Pmpaddr61Module Pmpaddr62Module Pmpaddr63Module Pmaaddr31Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

MODULE = PmaaddrLeaves30
RTL_DIR = ../../../rtl
LEAVES = Pmaaddr1Module Pmaaddr2Module Pmaaddr3Module Pmaaddr4Module \
 Pmaaddr5Module Pmaaddr6Module Pmaaddr7Module Pmaaddr8Module \
 Pmaaddr9Module Pmaaddr10Module Pmaaddr11Module Pmaaddr12Module \
 Pmaaddr13Module Pmaaddr14Module Pmaaddr15Module Pmaaddr16Module \
 Pmaaddr17Module Pmaaddr18Module Pmaaddr19Module Pmaaddr20Module \
 Pmaaddr21Module Pmaaddr22Module Pmaaddr23Module Pmaaddr24Module \
 Pmaaddr25Module Pmaaddr26Module Pmaaddr27Module Pmaaddr28Module \
 Pmaaddr29Module Pmaaddr30Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

MODULE = PmpaddrLeaves20
RTL_DIR = ../../../rtl
LEAVES = Pmpaddr33Module Pmpaddr34Module Pmpaddr35Module Pmpaddr36Module \
 Pmpaddr37Module Pmpaddr38Module Pmpaddr39Module Pmpaddr40Module \
 Pmpaddr41Module Pmpaddr42Module Pmpaddr43Module Pmpaddr44Module \
 Pmpaddr45Module Pmpaddr46Module Pmpaddr47Module Pmpaddr48Module \
 Pmpaddr49Module Pmpaddr50Module Pmpaddr51Module Pmpaddr52Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

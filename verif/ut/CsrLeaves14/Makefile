MODULE = CsrLeaves14

RTL_DIR = ../../../rtl
LEAVES = cycleModule instretModule HipModule HieModule HgeieModule \
         MscratchModule SscratchModule VSscratchModule MnscratchModule \
         Dscratch0Module Dscratch1Module ScontextModule TselectModule \
         PrivilegePermitModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

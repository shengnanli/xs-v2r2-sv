MODULE = CsrDhLeaves
RTL_DIR = ../../../rtl
LEAVES = DpcModule DretEventModule HcounterenModule HedelegModule HenvcfgModule HgatpModule HidelegModule Hstateen0Module Hstateen1Module Hstateen2Module Hstateen3Module HstatusModule HtimedeltaModule HtinstModule HtvalModule HvictlModule Hviprio1Module Hviprio2Module
RTL_SRCS = $(RTL_DIR)/backend/xs_CsrEpcTvec_core.sv \
           $(RTL_DIR)/backend/xs_CsrTrapValue_core.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
PORTLINT_ORDER = fail
# All stateful leaves are resettable except Hstateen1..3, which intentionally have no reset.
# Constant initreg keeps both independently elaborated instances aligned before their first write.
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)

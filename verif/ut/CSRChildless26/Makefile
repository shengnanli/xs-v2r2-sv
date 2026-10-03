MODULE = CSRChildless26
RTL_DIR = ../../../rtl
COMMON = $(RTL_DIR)/backend/xs_CsrChildless_common.sv
LEAVES = Mgtu MidelegModule MipModule MiselectModule MnstatusModule MretEventModule MseccfgModule Mstateen0Module Mstateen1Module Mstateen2Module Mstateen3Module MtinstModule SatpModule SbpctlModule ScounterenModule SenvcfgModule SiselectModule SlvpredctlModule SmblockctlModule SpfctlModule SretEventModule SrnctlModule Sstateen0Module StimecmpModule TrapInstMod TrapTvalMod
RTL_SRCS = $(COMMON) $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)

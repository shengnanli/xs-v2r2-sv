MODULE = PmpCfgLeaves8
RTL_DIR = ../../../rtl
LEAVES = Pmp5cfgModule Pmp6cfgModule Pmp7cfgModule Pmp8cfgModule \
 Pmp9cfgModule Pmp10cfgModule Pmp11cfgModule Pmp12cfgModule
RTL_SRCS = $(RTL_DIR)/backend/xs_Pmpcfg_core.sv $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+0

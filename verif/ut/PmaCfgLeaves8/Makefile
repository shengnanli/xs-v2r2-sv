MODULE = PmaCfgLeaves8
RTL_DIR = ../../../rtl
LEAVES = Pma0cfgModule Pma1cfgModule Pma2cfgModule Pma3cfgModule \
 Pma4cfgModule Pma5cfgModule Pma6cfgModule Pma7cfgModule
RTL_SRCS = $(RTL_DIR)/backend/xs_Pmacfg_core.sv \
 $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk

# +vcs+initreg+random opens VCS initial-register instrumentation at compile time.
# The selected runtime initialization mode is intentionally supplied through
# SIM_ARGS, never as a compile-time +vcs+initreg+0 option.
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+0

MODULE = PmaCfgLeaves8b
RTL_DIR = ../../../rtl
LEAVES = Pma8cfgModule Pma9cfgModule Pma10cfgModule Pma11cfgModule \
 Pma12cfgModule Pma13cfgModule Pma14cfgModule Pma15cfgModule
RTL_SRCS = $(RTL_DIR)/backend/xs_Pmacfg_core.sv \
 $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk

# Compile-time switch enables VCS initial-register instrumentation.  The only
# runtime mode used by this UT is deterministic zero initialization.
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)

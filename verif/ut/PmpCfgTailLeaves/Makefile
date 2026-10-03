MODULE = PmpCfgTailLeaves
RTL_DIR = ../../../rtl
LEAVES = Pmp21cfgModule Pmp22cfgModule Pmp23cfgModule Pmp24cfgModule \
 Pmp25cfgModule Pmp26cfgModule Pmp27cfgModule Pmp28cfgModule \
 Pmp29cfgModule Pmp30cfgModule Pmp31cfgModule
RTL_SRCS = $(RTL_DIR)/backend/xs_Pmpcfg_core.sv \
 $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk

# Enable VCS initial-register support at compile time.  The default runtime
# selection is deterministic zero; invoke `make run INITREG=random` for the
# independent random-initialization pass when desired.
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)

MODULE = PmpCfgLeaves8b
RTL_DIR = ../../../rtl
LEAVES = Pmp13cfgModule Pmp14cfgModule Pmp15cfgModule Pmp16cfgModule \
 Pmp17cfgModule Pmp18cfgModule Pmp19cfgModule Pmp20cfgModule
RTL_SRCS = $(RTL_DIR)/backend/xs_Pmpcfg_core_next20d.sv \
 $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
# Open initreg at compile time; this UT deliberately selects the deterministic
# zero initialization at runtime so independent golden/_xs instances agree.
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

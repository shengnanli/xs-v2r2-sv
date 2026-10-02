MODULE = HpmcounterLeaves4
RTL_DIR = ../../../rtl
LEAVES = Hpmcounter3Module Hpmcounter4Module Hpmcounter5Module Hpmcounter6Module
RTL_SRCS = $(RTL_DIR)/backend/xs_Hpmcounter_core.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk

# VCS enables register initialization at compile time; the default run selects
# deterministic zero initialization at runtime.  Never pass +vcs+initreg+0 to
# the compile command (VCS treats that spelling as obsolete).
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

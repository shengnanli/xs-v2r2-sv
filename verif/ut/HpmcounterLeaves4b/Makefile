MODULE = HpmcounterLeaves4b
RTL_DIR = ../../../rtl
LEAVES = Hpmcounter7Module Hpmcounter8Module Hpmcounter9Module Hpmcounter10Module
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES))) \
           $(RTL_DIR)/backend/xs_Hpmcounter_core.sv
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk

# Golden leaves contain only the async-reset register and its FIRRTL random-init
# scaffolding.  Synthesis removes that scaffolding; compile-time random-init
# enables the VCS mechanism, while this UT intentionally selects the zero
# runtime initialization required for the dual-instance comparison.
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

MODULE = TrapEntry200c
RTL_DIR = ../../../rtl
LEAVES = TrapEntryDEventModule TrapEntryHSEventModule TrapEntryMEventModule TrapEntryMNEventModule TrapEntryVSEventModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
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
SEEDS ?= 1 7 42
INITREGS ?= 0 1
.PHONY: matrix regress
matrix: compile
	@set -eu; for ir in $(INITREGS); do for seed in $(SEEDS); do \
		$(MAKE) --no-print-directory run SEED=$$seed INITREG=$$ir NCYCLES=$(NCYCLES); \
	done; done
regress: matrix

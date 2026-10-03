MODULE = VSatp200c
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/VSatpModule.sv
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VSatpModule.sv
FM_VARIANTS = VSatpModule
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk

# Keep the compile-time initreg support enabled; the regression selects both
# deterministic runtime initialization values below.
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS = +ncycles=$(NCYCLES) +vcs+initreg+$(INITREG)

SEEDS ?= 1 7 42
INITREGS ?= 0 1
.PHONY: regress
regress: portlint compile
	@set -e; for initreg in $(INITREGS); do \
	  for seed in $(SEEDS); do \
	    $(MAKE) --no-print-directory run SEED=$$seed INITREG=$$initreg NCYCLES=$(NCYCLES); \
	  done; \
	done

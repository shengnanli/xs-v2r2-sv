MODULE = ResultControlLeaves7

RTL_DIR = ../../../rtl
LEAVES = AluResSel ShiftResultSelect WordResultSelect MiscResultSelect \
         JumpDataModule BranchModule CommitIDModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES))) \
              $(GOLDEN_RTL)/SubModule.sv $(GOLDEN_RTL)/PrintCommitIDModule.v
FM_VARIANTS = $(LEAVES)

# BranchModule's golden implementation uses the subtractor only to recover its
# carry/borrow condition.  CommitIDModule calls the simulation provenance
# printer; the readable implementation deliberately preserves that primitive.
FM_REF_DEPS_BranchModule = SubModule.sv
FM_REF_DEPS_CommitIDModule = PrintCommitIDModule.v
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/PrintCommitIDModule.v

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

SEEDS ?= 1 2 3 4 5 6
.PHONY: regress
regress: compile
	@set -e; for seed in $(SEEDS); do \
	  $(MAKE) --no-print-directory run SEED=$$seed NCYCLES=100000; \
	done

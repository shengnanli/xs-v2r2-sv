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
# CommitIDModule has no synthesis-visible output or state: with SYNTHESIS the
# printer body is empty and Formality has no compare point.  Keep it out of
# FM_VARIANTS rather than manufacturing a vacuous green point.  Its exact port
# contract is linted below, and the differential/oracle test exhausts all 64
# hart IDs while checking the two provenance constants hierarchically.
FM_VARIANTS = AluResSel ShiftResultSelect WordResultSelect MiscResultSelect \
              JumpDataModule BranchModule

# BranchModule's golden implementation uses the subtractor only to recover its
# carry/borrow condition.  CommitIDModule calls the simulation provenance
# printer; the readable implementation deliberately preserves that primitive.
FM_REF_DEPS_BranchModule = SubModule.sv
FM_REF_DEPS_CommitIDModule = PrintCommitIDModule.v
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/PrintCommitIDModule.v

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

SEEDS ?= 1 2 3 4 5 6
.PHONY: regress portlint-commit-id
portlint-commit-id:
	python3 $(XSSV_HOME)/scripts/port_contract_lint.py --order fail \
	  --impl-src $(abspath $(RTL_DIR)/backend/CommitIDModule.sv) CommitIDModule

regress: portlint-commit-id compile
	@set -e; for seed in $(SEEDS); do \
	  $(MAKE) --no-print-directory run SEED=$$seed NCYCLES=100000; \
	done

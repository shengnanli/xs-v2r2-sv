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

# 两轮 initreg（CONVENTIONS「+vcs+initreg 的正确用法」）：编译期打开机制，运行期选取值。
# 本 UT 是 golden 与 *_xs 双例化：+vcs+initreg+random 会给两个实例各摇各的初值，
# 不复位寄存器两侧初态不同 => 假失配。所以两档用常量：make run INITREG=0 / INITREG=1。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

SEEDS ?= 1 2 3 4 5 6
.PHONY: regress portlint-commit-id
portlint-commit-id:
	python3 $(XSSV_HOME)/scripts/port_contract_lint.py --order fail \
	  --impl-src $(abspath $(RTL_DIR)/backend/CommitIDModule.sv) CommitIDModule

regress: portlint-commit-id compile
	@set -e; for seed in $(SEEDS); do \
	  $(MAKE) --no-print-directory run SEED=$$seed NCYCLES=100000; \
	done

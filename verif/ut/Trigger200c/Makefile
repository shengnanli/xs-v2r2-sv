MODULE = Trigger200c
RTL_DIR = ../../../rtl
TRIGGERS = Trigger0_Tdata1Module Trigger0_Tdata2Module \
           Trigger1_Tdata1Module Trigger1_Tdata2Module \
           Trigger2_Tdata1Module Trigger2_Tdata2Module \
           Trigger3_Tdata1Module Trigger3_Tdata2Module
RTL_SRCS = $(RTL_DIR)/backend/xs_Trigger_core.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(TRIGGERS)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(TRIGGERS)))
FM_VARIANTS = $(TRIGGERS)
# Keep canonical type bits as distinct state points; this strengthens matching
# for the firtool-flattened register representation.
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# The golden wrappers contain reset and unreset state, so compile-time initreg
# support is enabled and each matrix run selects a deterministic constant value.
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

SEEDS ?= 1 7 42
INITREGS ?= 0 1
.PHONY: all matrix
all: matrix

# Full acceptance matrix: every deterministic seed at both required initreg
# values.  The common makefile preserves a separate tagged log for each run.
matrix: simv
	@set -eu; for ir in $(INITREGS); do for seed in $(SEEDS); do \
		echo "=== Trigger200c matrix initreg=$$ir seed=$$seed ==="; \
		$(MAKE) --no-print-directory run SEED=$$seed INITREG=$$ir \
			SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+$$ir"; \
	done; done

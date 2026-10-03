# Focused 200c differential UT for the remaining queue/spill/logger leaves.
MODULE = QueueChiSpillLogger200c

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue1_core.sv \
           $(RTL_DIR)/uncore/xs_SpillRegister_core.sv \
           $(RTL_DIR)/uncore/Queue1_CHIDAT.sv \
           $(RTL_DIR)/uncore/Queue1_CHIRSP.sv \
           $(RTL_DIR)/uncore/SpillRegister_7.sv \
           $(RTL_DIR)/uncore/TLLogger_1.sv \
           $(RTL_DIR)/uncore/TLLogger_2.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Queue1_CHIDAT.sv \
              $(GOLDEN_RTL)/Queue1_CHIRSP.sv \
              $(GOLDEN_RTL)/SpillRegister_7.sv \
              $(GOLDEN_RTL)/TLLogger_1.sv \
              $(GOLDEN_RTL)/TLLogger_2.sv
FM_VARIANTS = Queue1_CHIDAT Queue1_CHIRSP SpillRegister_7 TLLogger_1 TLLogger_2
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck

gencheck:
	python3 ../../../scripts/gen_chi_queue_logger_200c.py --check
	python3 ../../../scripts/gen_queue_chi_logger_200c_ut.py --check

MODULE = BusHPerfCounter200c
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_HPerfCounter_core.sv \
           $(RTL_DIR)/backend/HPerfCounter.sv \
           $(RTL_DIR)/backend/HPerfCounter_13.sv \
           $(RTL_DIR)/backend/HPerfCounter_8.sv \
           $(RTL_DIR)/l2/BusErrorUnit.sv
TB_SRCS = tb.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/HPerfCounter.sv \
              $(GOLDEN_RTL)/HPerfCounter_13.sv \
              $(GOLDEN_RTL)/HPerfCounter_8.sv \
              $(GOLDEN_RTL)/BusErrorUnit.sv
FM_VARIANTS = HPerfCounter HPerfCounter_13 HPerfCounter_8 BusErrorUnit
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_bus_hperf_200c.py --check

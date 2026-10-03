# Focused G1 differential UT for the thirteen remaining Dispatcher leaves.
MODULE = Dispatcher200c
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_Dispatcher_core.sv \
           $(RTL_DIR)/backend/Dispatcher.sv \
           $(RTL_DIR)/backend/Dispatcher_1.sv \
           $(RTL_DIR)/backend/Dispatcher_10.sv \
           $(RTL_DIR)/backend/Dispatcher_13.sv \
           $(RTL_DIR)/backend/Dispatcher_14.sv \
           $(RTL_DIR)/backend/Dispatcher_15.sv \
           $(RTL_DIR)/backend/Dispatcher_16.sv \
           $(RTL_DIR)/backend/Dispatcher_17.sv \
           $(RTL_DIR)/backend/Dispatcher_4.sv \
           $(RTL_DIR)/backend/Dispatcher_5.sv \
           $(RTL_DIR)/backend/Dispatcher_7.sv \
           $(RTL_DIR)/backend/Dispatcher_8.sv \
           $(RTL_DIR)/backend/Dispatcher_9.sv
TB_SRCS = tb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,Dispatcher.sv Dispatcher_1.sv Dispatcher_10.sv Dispatcher_13.sv Dispatcher_14.sv Dispatcher_15.sv Dispatcher_16.sv Dispatcher_17.sv Dispatcher_4.sv Dispatcher_5.sv Dispatcher_7.sv Dispatcher_8.sv Dispatcher_9.sv)
FM_VARIANTS = Dispatcher Dispatcher_1 Dispatcher_10 Dispatcher_13 Dispatcher_14 Dispatcher_15 Dispatcher_16 Dispatcher_17 Dispatcher_4 Dispatcher_5 Dispatcher_7 Dispatcher_8 Dispatcher_9
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)
.PHONY: gencheck
gencheck:
	python3 ../../../scripts/gen_dispatcher_200c.py --check

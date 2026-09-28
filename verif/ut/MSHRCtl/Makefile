MODULE = MSHRCtl

RTL_DIR  = ../../../rtl
# 本体 + 全部 child 的重写件（两侧白盒）：
#   MSHR（本 lane）、FastArbiter_3/4/6/7 + 核（本 lane）、SourceB 及其 FastArbiter_5、
#   MSHRSelector（rtl/uncore/MSHRSelector.sv，PROVEN_DIRECT）
RTL_SRCS = $(RTL_DIR)/uncore/MSHRCtl.sv $(RTL_DIR)/uncore/MSHR.sv \
           $(RTL_DIR)/common/xs_FastArbiter_core.sv \
           $(RTL_DIR)/uncore/FastArbiter_3.sv $(RTL_DIR)/uncore/FastArbiter_4.sv \
           $(RTL_DIR)/uncore/FastArbiter_5.sv $(RTL_DIR)/uncore/FastArbiter_6.sv \
           $(RTL_DIR)/uncore/FastArbiter_7.sv $(RTL_DIR)/uncore/SourceB.sv \
           $(RTL_DIR)/uncore/MSHRSelector.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MSHRCtl.sv $(GOLDEN_RTL)/MSHR.sv \
              $(GOLDEN_RTL)/FastArbiter_3.sv $(GOLDEN_RTL)/FastArbiter_4.sv \
              $(GOLDEN_RTL)/FastArbiter_5.sv $(GOLDEN_RTL)/FastArbiter_6.sv \
              $(GOLDEN_RTL)/FastArbiter_7.sv $(GOLDEN_RTL)/SourceB.sv \
              $(GOLDEN_RTL)/MSHRSelector.sv
FM_REF_DEPS_MSHRCtl = MSHR.sv FastArbiter_3.sv FastArbiter_4.sv FastArbiter_5.sv FastArbiter_6.sv FastArbiter_7.sv SourceB.sv MSHRSelector.sv
FM_VARIANTS = MSHRCtl
FM_MERGE_DUP = false
# 5238 个对称死位 vmucp 实比（依据见 verif/fm_target_config/MSHRCtl.tcl）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

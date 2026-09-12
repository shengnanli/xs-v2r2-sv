MODULE = TXREQ

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TXREQ.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Queue16_CHIREQ.sv \
                  $(GOLDEN_RTL)/ram_16x137.sv

FM_REF_DEPS_TXREQ = Queue16_CHIREQ.sv ram_16x137.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/TXREQ.sv \
              $(GOLDEN_RTL)/Queue16_CHIREQ.sv \
              $(GOLDEN_RTL)/ram_16x137.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = TXREQ

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

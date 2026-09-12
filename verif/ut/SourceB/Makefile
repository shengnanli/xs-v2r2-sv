MODULE = SourceB

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/SourceB.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/FastArbiter_6.sv

FM_REF_DEPS_SourceB = FastArbiter_6.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SourceB.sv \
              $(GOLDEN_RTL)/FastArbiter_6.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = SourceB

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

MODULE = TXDAT_4

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/TXDAT_4.sv
TB_SRCS = tb.sv

FM_REF_DEPS_TXDAT_4 = 
GOLDEN_SRCS = $(GOLDEN_RTL)/TXDAT_4.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = TXDAT_4

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

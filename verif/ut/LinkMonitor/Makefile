MODULE = LinkMonitor

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/LinkMonitor.sv
TB_SRCS = tb.sv

RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/Decoupled2LCredit.sv \
                  $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
                  $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
                  $(GOLDEN_RTL)/LCredit2Decoupled.sv \
                  $(GOLDEN_RTL)/LCredit2Decoupled_1.sv \
                  $(GOLDEN_RTL)/LCredit2Decoupled_2.sv \
                  $(GOLDEN_RTL)/Queue4_CHISNP.sv \
                  $(GOLDEN_RTL)/ram_4x115.sv

FM_REF_DEPS_LinkMonitor = Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv LCredit2Decoupled.sv LCredit2Decoupled_1.sv LCredit2Decoupled_2.sv Queue4_CHISNP.sv ram_4x115.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LinkMonitor.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_1.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_2.sv \
              $(GOLDEN_RTL)/Queue4_CHISNP.sv \
              $(GOLDEN_RTL)/ram_4x115.sv
# 老战役审计声明继承: vmucp=加强证明(FM 实比 matched-unread, 非 waiver)
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_VARIANTS = LinkMonitor

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

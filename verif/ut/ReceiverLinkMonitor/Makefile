# 自动生成：scripts/gen_rxtxlinkmon.py —— 勿手改
MODULE = ReceiverLinkMonitor

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/linkmonitor_pkg.sv \
           $(RTL_DIR)/uncore/ReceiverLinkMonitor.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden ReceiverLinkMonitor + 6 个 flit 转换子模块(两侧共用同一例化, 白盒)。
GOLDEN_SRCS = $(GOLDEN_RTL)/ReceiverLinkMonitor.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_8.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_9.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_10.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_5.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/Queue4_CHIREQ.sv \
              $(GOLDEN_RTL)/Queue4_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue4_CHIDAT.sv \
              $(GOLDEN_RTL)/ram_4x151.sv \
              $(GOLDEN_RTL)/ram_4x73.sv \
              $(GOLDEN_RTL)/ram_4x422.sv

# impl 侧(WRAPPER_SRCS)加同套 golden flit 文件 ⇒ 两侧都 elaborate 出这 6 个子模块
# = 全白盒等价比对(非黑盒), signoff-strict 下无 unresolved/blackbox 对象。
FLIT_GOLDEN = $(GOLDEN_RTL)/LCredit2Decoupled_8.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_9.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_10.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_5.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/Queue4_CHIREQ.sv \
              $(GOLDEN_RTL)/Queue4_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue4_CHIDAT.sv \
              $(GOLDEN_RTL)/ram_4x151.sv \
              $(GOLDEN_RTL)/ram_4x73.sv \
              $(GOLDEN_RTL)/ram_4x422.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/ReceiverLinkMonitor_wrapper.sv $(FLIT_GOLDEN)
FM_VARIANTS = ReceiverLinkMonitor
# ref 侧(FM_REF_DEPS)加同套 golden flit 文件 ⇒ ref ReceiverLinkMonitor 例化解析为真 RTL。
FM_REF_DEPS_ReceiverLinkMonitor = LCredit2Decoupled_8.sv LCredit2Decoupled_9.sv LCredit2Decoupled_10.sv Decoupled2LCredit_5.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv Queue4_CHIREQ.sv Queue4_CHIRSP.sv Queue4_CHIDAT.sv ram_4x151.sv ram_4x73.sv ram_4x422.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

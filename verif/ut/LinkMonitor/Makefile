# 自动生成：scripts/gen_linkmonitor.py —— 勿手改
MODULE = LinkMonitor

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/linkmonitor_pkg.sv \
           $(RTL_DIR)/uncore/LinkMonitor.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden LinkMonitor + 6 个黑盒 flit 转换子模块 (两侧共用同一例化);
# LCredit2Decoupled(rxsnp) 内含 Queue4_CHISNP。
GOLDEN_SRCS = $(GOLDEN_RTL)/LinkMonitor.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_1.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_2.sv \
              $(GOLDEN_RTL)/Queue4_CHISNP.sv \
              $(GOLDEN_RTL)/ram_4x115.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/LinkMonitor_wrapper.sv
FM_VARIANTS = LinkMonitor
# FM: 6 个子模块不提供给任一侧 ⇒ hdlin_unresolved_modules=black_box 在 ref/impl 两侧
# 自动黑盒化并按同名配对; 比对聚焦 LinkMonitor 自身状态机/握手/计数逻辑。
# (故 FM_REF_DEPS_LinkMonitor 留空, ref 侧只读 LinkMonitor.sv)

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

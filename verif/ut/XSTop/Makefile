# 自动生成:scripts/gen_xstop.py —— 勿手改
MODULE = XSTop

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/xstop/xstop_pkg.sv \
           $(RTL_DIR)/xstop/XSTop.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 XSTop.sv + 子模块全部叶子(传递闭包,-f 显式编译)。
GOLDEN_SRCS = $(GOLDEN_RTL)/XSTop.sv

SUB_DEPS = $(GOLDEN_RTL)/CHILogger.sv $(GOLDEN_RTL)/FastArbiter_77.sv $(GOLDEN_RTL)/FastArbiter_78.sv $(GOLDEN_RTL)/FastArbiter_79.sv $(GOLDEN_RTL)/IntBuffer.sv $(GOLDEN_RTL)/MemMisc.sv $(GOLDEN_RTL)/OpenLLC.sv $(GOLDEN_RTL)/OpenNCB.sv $(GOLDEN_RTL)/OpenNCB_1.sv $(GOLDEN_RTL)/ReceiverLinkMonitor.sv $(GOLDEN_RTL)/ResetGen.sv $(GOLDEN_RTL)/TransmitterLinkMonitor.sv $(GOLDEN_RTL)/XSTile.sv

WRAPPER_SRCS = $(RTL_DIR)/xstop/XSTop_wrapper.sv $(SUB_DEPS)
FM_VARIANTS = XSTop
FM_REF_DEPS_XSTop = CHILogger.sv FastArbiter_77.sv FastArbiter_78.sv FastArbiter_79.sv IntBuffer.sv MemMisc.sv OpenLLC.sv OpenNCB.sv OpenNCB_1.sv ReceiverLinkMonitor.sv ResetGen.sv TransmitterLinkMonitor.sv XSTile.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/xstop
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable

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

SUB_DEPS = $(GOLDEN_RTL)/CHILogger.sv $(GOLDEN_RTL)/FastArbiter_77.sv $(GOLDEN_RTL)/FastArbiter_78.sv $(GOLDEN_RTL)/FastArbiter_79.sv $(GOLDEN_RTL)/IntBuffer.sv $(GOLDEN_RTL)/MemMisc.sv $(GOLDEN_RTL)/OpenLLC.sv $(GOLDEN_RTL)/OpenNCB.sv $(GOLDEN_RTL)/OpenNCB_1.sv $(GOLDEN_RTL)/ReceiverLinkMonitor.sv $(GOLDEN_RTL)/ResetGen.sv $(GOLDEN_RTL)/TransmitterLinkMonitor.sv $(GOLDEN_RTL)/XSTile.sv \
           $(GOLDEN_RTL)/XSCore.sv $(GOLDEN_RTL)/L2Top.sv \
           $(GOLDEN_RTL)/BusErrorUnit.sv $(GOLDEN_RTL)/BusPerfMonitor.sv $(GOLDEN_RTL)/DelayN_334.sv \
           $(GOLDEN_RTL)/TL2CHICoupledL2.sv $(GOLDEN_RTL)/TLBuffer_13.sv $(GOLDEN_RTL)/TLBuffer_15.sv \
           $(GOLDEN_RTL)/TLBuffer_20.sv $(GOLDEN_RTL)/TLBuffer_22.sv $(GOLDEN_RTL)/TLBuffer_6.sv \
           $(GOLDEN_RTL)/TLBuffer_8.sv $(GOLDEN_RTL)/TLLogger.sv $(GOLDEN_RTL)/TLLogger_1.sv \
           $(GOLDEN_RTL)/TLLogger_2.sv $(GOLDEN_RTL)/TLXbar_5.sv $(GOLDEN_RTL)/TLXbar_6.sv \
           $(GOLDEN_RTL)/AXI4Buffer.sv $(GOLDEN_RTL)/TLBuffer_2.sv $(GOLDEN_RTL)/TLBuffer.sv \
           $(GOLDEN_RTL)/TLXbar_2.sv

FM_TL2_LEAVES = Arbiter4_L2CacheErrorInfo.sv Arbiter4_L2ToL1Hint.sv FastArbiter_1.sv FastArbiter_2.sv FastArbiter_27.sv FastArbiter_28.sv FastArbiter_29.sv L2Cache.sv LinkMonitor.sv MMIOBridge.sv MbistIntfL2.sv Pipeline_10.sv Pipeline_11.sv Pipeline_2.sv Pipeline_3.sv Prefetcher.sv Queue72_CoupledL2Imp_Anon.sv RRArbiterInit_18.sv Slice.sv Slice_1.sv Slice_2.sv Slice_3.sv TopDownMonitor.sv MMIOBridgeEntry.sv MMIOBridgeEntry_2.sv MMIOBridgeEntry_4.sv RequestBuffer.sv Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv LCredit2Decoupled.sv LCredit2Decoupled_1.sv LCredit2Decoupled_2.sv Queue4_CHISNP.sv ram_4x115.sv

WRAPPER_SRCS = $(RTL_DIR)/xstop/XSTop_wrapper.sv $(SUB_DEPS) $(addprefix $(GOLDEN_RTL)/,$(FM_TL2_LEAVES))
FM_VARIANTS = XSTop
FM_REF_DEPS_XSTop = CHILogger.sv FastArbiter_77.sv FastArbiter_78.sv FastArbiter_79.sv IntBuffer.sv MemMisc.sv OpenLLC.sv OpenNCB.sv OpenNCB_1.sv ReceiverLinkMonitor.sv ResetGen.sv TransmitterLinkMonitor.sv XSTile.sv XSCore.sv L2Top.sv BusErrorUnit.sv BusPerfMonitor.sv DelayN_334.sv TL2CHICoupledL2.sv TLBuffer_13.sv TLBuffer_15.sv TLBuffer_20.sv TLBuffer_22.sv TLBuffer_6.sv TLBuffer_8.sv TLLogger.sv TLLogger_1.sv TLLogger_2.sv TLXbar_5.sv TLXbar_6.sv AXI4Buffer.sv TLBuffer_2.sv TLBuffer.sv TLXbar_2.sv $(FM_TL2_LEAVES)
FM_INTERFACE_ONLY = RequestBuffer
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_MERGE_DUP = false
FM_ALLOWLIST = ../../signoff/allow/XSTop.json

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/xstop
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable

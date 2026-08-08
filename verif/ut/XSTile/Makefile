# 自动生成:scripts/gen_xstile.py —— 勿手改
MODULE = XSTile

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/xstile/xstile_pkg.sv \
           $(RTL_DIR)/xstile/XSTile.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 XSTile.sv + 3 子模块(XSCore/L2Top/IntBuffer)的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/XSTile.sv

# 子模块顶+L2Top 配方上提一层(codex 0130 Lane D): L2Top 15 直子+TL2 35 叶两侧同源
# elaborate 消 inner_beu 20 failing(undriven伪影)+28 sourceId unmatched; vmucp 归零对称死reg。
SUB_DEPS = $(GOLDEN_RTL)/IntBuffer.sv $(GOLDEN_RTL)/L2Top.sv $(GOLDEN_RTL)/XSCore.sv \
           $(GOLDEN_RTL)/BusErrorUnit.sv $(GOLDEN_RTL)/BusPerfMonitor.sv $(GOLDEN_RTL)/DelayN_334.sv \
           $(GOLDEN_RTL)/TL2CHICoupledL2.sv $(GOLDEN_RTL)/TLBuffer_13.sv $(GOLDEN_RTL)/TLBuffer_15.sv \
           $(GOLDEN_RTL)/TLBuffer_20.sv $(GOLDEN_RTL)/TLBuffer_22.sv $(GOLDEN_RTL)/TLBuffer_6.sv \
           $(GOLDEN_RTL)/TLBuffer_8.sv $(GOLDEN_RTL)/TLLogger.sv $(GOLDEN_RTL)/TLLogger_1.sv \
           $(GOLDEN_RTL)/TLLogger_2.sv $(GOLDEN_RTL)/TLXbar_5.sv $(GOLDEN_RTL)/TLXbar_6.sv

# TL2 子叶(逐字同 L2Top Makefile FM_TL2_LEAVES)。
FM_TL2_LEAVES = Arbiter4_L2CacheErrorInfo.sv Arbiter4_L2ToL1Hint.sv FastArbiter_1.sv FastArbiter_2.sv FastArbiter_27.sv FastArbiter_28.sv FastArbiter_29.sv L2Cache.sv LinkMonitor.sv MMIOBridge.sv MbistIntfL2.sv Pipeline_10.sv Pipeline_11.sv Pipeline_2.sv Pipeline_3.sv Prefetcher.sv Queue72_CoupledL2Imp_Anon.sv RRArbiterInit_18.sv Slice.sv Slice_1.sv Slice_2.sv Slice_3.sv TopDownMonitor.sv MMIOBridgeEntry.sv MMIOBridgeEntry_2.sv MMIOBridgeEntry_4.sv RequestBuffer.sv Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv LCredit2Decoupled.sv LCredit2Decoupled_1.sv LCredit2Decoupled_2.sv Queue4_CHISNP.sv ram_4x115.sv

WRAPPER_SRCS = $(RTL_DIR)/xstile/XSTile_wrapper.sv $(SUB_DEPS) $(addprefix $(GOLDEN_RTL)/,$(FM_TL2_LEAVES))
FM_VARIANTS = XSTile
FM_REF_DEPS_XSTile = IntBuffer.sv L2Top.sv XSCore.sv BusErrorUnit.sv BusPerfMonitor.sv DelayN_334.sv \
    TL2CHICoupledL2.sv TLBuffer_13.sv TLBuffer_15.sv TLBuffer_20.sv TLBuffer_22.sv TLBuffer_6.sv \
    TLBuffer_8.sv TLLogger.sv TLLogger_1.sv TLLogger_2.sv TLXbar_5.sv TLXbar_6.sv $(FM_TL2_LEAVES)
FM_INTERFACE_ONLY = RequestBuffer
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
FM_MERGE_DUP = false
FM_ALLOWLIST = ../../signoff/allow/XSTile.json

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/xstile
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable

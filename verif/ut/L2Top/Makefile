# 自动生成:scripts/gen_l2top.py —— 勿手改
MODULE = L2Top

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/l2top_pkg.sv \
           $(RTL_DIR)/l2/L2Top.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 L2Top.sv + 15 子模块类型的全部叶子。
# 叶子传递闭包列在 golden_filelist.f(每文件一次),由 -f 显式编译——
# 不用 -y:golden 叶子多为自包含 pkg+module,-y 会重复解析触发 Package previously declared。
GOLDEN_SRCS = $(GOLDEN_RTL)/L2Top.sv

# 子模块顶(FM ref 依赖列表用)。
SUB_DEPS = $(GOLDEN_RTL)/BusErrorUnit.sv $(GOLDEN_RTL)/BusPerfMonitor.sv $(GOLDEN_RTL)/DelayN_334.sv $(GOLDEN_RTL)/TL2CHICoupledL2.sv $(GOLDEN_RTL)/TLBuffer_13.sv $(GOLDEN_RTL)/TLBuffer_15.sv $(GOLDEN_RTL)/TLBuffer_20.sv $(GOLDEN_RTL)/TLBuffer_22.sv $(GOLDEN_RTL)/TLBuffer_6.sv $(GOLDEN_RTL)/TLBuffer_8.sv $(GOLDEN_RTL)/TLLogger.sv $(GOLDEN_RTL)/TLLogger_1.sv $(GOLDEN_RTL)/TLLogger_2.sv $(GOLDEN_RTL)/TLXbar_5.sv $(GOLDEN_RTL)/TLXbar_6.sv

# ★TL2CHICoupledL2 子叶(FM-only 深例化, 两侧同源)★: L2Top 若只给 TL2CHICoupledL2.sv,
# 其内部 slices_*/train_pipeline*/txreq_arb 被 FM 黑盒化, 这些黑盒 output 的死高位
# (Slice.io_error_bits_address[44:45]/io_in_b_bits_address[46:47]、Pipeline.io_out_bits_tag
# [31:32]、FastArbiter.io_chosen[2]/io_out_bits_txnID[11] —— golden 里只切片消费低位)
# 在 ref(扁平)被剪、在 impl(经 u_core 层次)存活 → 26 个 impl-undriven BBPin 不对称 +
# 20 failing + 6 unverified。★修法: 把 TL2CHICoupledL2 的全部子叶两侧同源 elaborate★,
# 令 Slice/Pipeline/FastArbiter 真实逻辑驱动这些死位 → 两侧对称的 driven-but-unread,
# 再由 vmucp 实际比较归零。此即 TL2CHICoupledL2 standalone 成功的同套配方上提一层。
# 死位从 BBPin failing 转为对称 unread(vmucp passing), 完全不用 dont_verify。
FM_TL2_LEAVES = Arbiter4_L2CacheErrorInfo.sv Arbiter4_L2ToL1Hint.sv FastArbiter_1.sv FastArbiter_2.sv FastArbiter_27.sv FastArbiter_28.sv FastArbiter_29.sv L2Cache.sv LinkMonitor.sv MMIOBridge.sv MbistIntfL2.sv Pipeline_10.sv Pipeline_11.sv Pipeline_2.sv Pipeline_3.sv Prefetcher.sv Queue72_CoupledL2Imp_Anon.sv RRArbiterInit_18.sv Slice.sv Slice_1.sv Slice_2.sv Slice_3.sv TopDownMonitor.sv MMIOBridgeEntry.sv MMIOBridgeEntry_2.sv MMIOBridgeEntry_4.sv RequestBuffer.sv Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv LCredit2Decoupled.sv LCredit2Decoupled_1.sv LCredit2Decoupled_2.sv Queue4_CHISNP.sv ram_4x115.sv

# FM:impl 侧(wrapper->可读核)与 ref 侧在相同层次黑盒化子模块。
# WRAPPER_SRCS 仅 FM 用(不进 UT 编译); TL2 子叶两侧同源加入令 FM 深例化对称。
WRAPPER_SRCS = $(RTL_DIR)/l2/L2Top_wrapper.sv $(SUB_DEPS) $(addprefix $(GOLDEN_RTL)/,$(FM_TL2_LEAVES))
FM_VARIANTS = L2Top
FM_REF_DEPS_L2Top = BusErrorUnit.sv BusPerfMonitor.sv DelayN_334.sv TL2CHICoupledL2.sv TLBuffer_13.sv TLBuffer_15.sv TLBuffer_20.sv TLBuffer_22.sv TLBuffer_6.sv TLBuffer_8.sv TLLogger.sv TLLogger_1.sv TLLogger_2.sv TLXbar_5.sv TLXbar_6.sv $(FM_TL2_LEAVES)

# RequestBuffer(Slice 内部)只取端口方向(io_hasMergeA=output, 连 firtool _probe 悬空),
# 同 TL2CHICoupledL2 standalone; interface_only 令 assembly 模式生效。
FM_INTERFACE_ONLY = RequestBuffer

# 对称内部死状态的双射匹配证明(class-4, 非 waiver): 深例化后 TL2CHICoupledL2 子内的
# perf/debug/mbist 寄存器 + Slice/Pipeline 死输出位是两侧同源 golden, 名字一一配对值恒等。
# vmucp=true 令 FM 实际比较(证明 MORE) → 全 passing, unread 归零。实证: 26 unmatched +
# 20 failing + 68 unread → 0; passing 38717 → 158755, failing 0, 仅 305 Constant reg。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# perf 常量-0 寄存器两侧对称保留(见 gen 注释); 深例化后仍关合并防跨层选代表不对称。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含非综合断言/difftest;UT 关掉并关随机化,处理 flush-X。
VCS += +define+SYNTHESIS
VCS += +incdir+$(RTL_DIR)/l2
VCS += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0
# golden 叶子全集(传递闭包),-f 显式列出,每文件一次。
VCS += -f golden_filelist.f
VCS += +libext+.sv+.v
VCS += -assert disable

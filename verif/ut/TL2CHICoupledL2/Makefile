# 自动生成:scripts/gen_coupledl2.py —— 勿手改
MODULE = TL2CHICoupledL2

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(核通过 `include 引入端口/decls/glue/inst/outassign svh)。
RTL_SRCS = $(RTL_DIR)/l2/coupledl2_pkg.sv \
           $(RTL_DIR)/l2/TL2CHICoupledL2.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 双例化:顶 TL2CHICoupledL2.sv + 23 子模块类型的全部叶子(传递闭包)。
GOLDEN_SRCS = $(GOLDEN_RTL)/TL2CHICoupledL2.sv

SUB_DEPS = $(GOLDEN_RTL)/Arbiter4_L2CacheErrorInfo.sv $(GOLDEN_RTL)/Arbiter4_L2ToL1Hint.sv $(GOLDEN_RTL)/FastArbiter_1.sv $(GOLDEN_RTL)/FastArbiter_2.sv $(GOLDEN_RTL)/FastArbiter_27.sv $(GOLDEN_RTL)/FastArbiter_28.sv $(GOLDEN_RTL)/FastArbiter_29.sv $(GOLDEN_RTL)/L2Cache.sv $(GOLDEN_RTL)/LinkMonitor.sv $(GOLDEN_RTL)/MMIOBridge.sv $(GOLDEN_RTL)/MbistIntfL2.sv $(GOLDEN_RTL)/Pipeline_10.sv $(GOLDEN_RTL)/Pipeline_11.sv $(GOLDEN_RTL)/Pipeline_2.sv $(GOLDEN_RTL)/Pipeline_3.sv $(GOLDEN_RTL)/Prefetcher.sv $(GOLDEN_RTL)/Queue72_CoupledL2Imp_Anon.sv $(GOLDEN_RTL)/RRArbiterInit_18.sv $(GOLDEN_RTL)/Slice.sv $(GOLDEN_RTL)/Slice_1.sv $(GOLDEN_RTL)/Slice_2.sv $(GOLDEN_RTL)/Slice_3.sv $(GOLDEN_RTL)/TopDownMonitor.sv

# FM-only 孙子叶子(grandchildren)—— 消除黑盒引脚方向猜测导致的 12 failing:
#  (a) golden MMIOBridge 内部 MMIOBridgeEntry*: 不提供时 FM 黑盒化, 其 output
#      io_chi_rx_rsp_ready 因方向未知被判 BBPin cut-point/fan-in undriven → 8 failing。
#      提供真实 golden(两侧同源)后 FM 解析真方向 → 真实等价点 → pass。
#  (b) golden Slice 内部 RequestBuffer: 其 output io_hasMergeA 在 golden Slice 里连到
#      悬空 wire _probe(firtool probe, 无下游)。黑盒时 FM 把该引脚方向猜成 input →
#      驱动 net(_probe)在 ref 侧 undriven → 4 failing。RequestBuffer 用 interface_only
#      黑盒(只读端口方向、不拉内部逻辑): io_hasMergeA 确定为 output → _probe 变干净
#      黑盒输出(unread, 两侧同源) → 无比对点 → pass。
#      (注: 若把 RequestBuffer 当真实逻辑拉入, 其 channel[2] 常量传播在 u_core 包装
#       边界两侧不对称[ref 证得常量0, impl 侧 Constrained-0X 寄存器留比对点]反致 4 新
#       failing, 故只取 interface_only 端口方向。)
FM_GRANDCHILD_DEPS = MMIOBridgeEntry.sv MMIOBridgeEntry_2.sv MMIOBridgeEntry_4.sv RequestBuffer.sv
FM_INTERFACE_ONLY = RequestBuffer

# 对称内部死状态的双射匹配证明(class-4, 非 waiver): TL2CHICoupledL2 的 269 个
# matched-unread DFF 位于两侧同源 golden 子(LinkMonitor/TopDownMonitor/MbistIntfL2
# 等)+ 本层 perf/pCrdGrant 打拍寄存器, 名字一一配对且值恒等。vmucp=true 令 FM
# 实际比较这些 unread 寄存器(证明 MORE), 全部 passing -> unread 归零。
# 实证: unread 269 -> 0, DFF 5029 -> 5298, passing 150370 -> 150639, failing 0。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

# LinkMonitor CHI flit 转换孙子叶(FM-only, 两侧同源): 不提供时 Decoupled2LCredit/
# LCredit2Decoupled 被 FM 黑盒化, 且在 LinkMonitor 模块作用域与 linkMonitor 实例作用域
# 各报一次 unresolved(6 双重表示)→ 观察 unresolved 集含实例外副本, 与 matched pair
# 集(仅实例作用域)不一致, sidecar allow 无法自洽. 提供后两侧同源 elaborate 消重复,
# 同 LinkMonitor standalone 配方(其 GOLDEN_SRCS 含此闭包)。
FM_FLIT_DEPS = Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv LCredit2Decoupled.sv LCredit2Decoupled_1.sv LCredit2Decoupled_2.sv Queue4_CHISNP.sv ram_4x115.sv

WRAPPER_SRCS = $(RTL_DIR)/l2/TL2CHICoupledL2_wrapper.sv $(SUB_DEPS) $(addprefix $(GOLDEN_RTL)/,$(FM_GRANDCHILD_DEPS) $(FM_FLIT_DEPS))
FM_VARIANTS = TL2CHICoupledL2
FM_REF_DEPS_TL2CHICoupledL2 = Arbiter4_L2CacheErrorInfo.sv Arbiter4_L2ToL1Hint.sv FastArbiter_1.sv FastArbiter_2.sv FastArbiter_27.sv FastArbiter_28.sv FastArbiter_29.sv L2Cache.sv LinkMonitor.sv MMIOBridge.sv MbistIntfL2.sv Pipeline_10.sv Pipeline_11.sv Pipeline_2.sv Pipeline_3.sv Prefetcher.sv Queue72_CoupledL2Imp_Anon.sv RRArbiterInit_18.sv Slice.sv Slice_1.sv Slice_2.sv Slice_3.sv TopDownMonitor.sv $(FM_GRANDCHILD_DEPS) $(FM_FLIT_DEPS)

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

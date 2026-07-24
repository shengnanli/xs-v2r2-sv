# 自动生成：scripts/gen_debugmodule.py —— 勿手改
MODULE = DebugModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 + pkg。两大子块 (TLDebugModule / DebugTransportModuleJTAG):
#   UT 经 golden_filelist.f 编入真实子块 (两侧共用);
#   FM 两侧 elaborate 白盒 (codex_0034 裁定: 非 vendor 逻辑子禁黑盒,
#   golden RTL 两侧提供 = FM_REF_DEPS + WRAPPER_SRCS 同套闭包,
#   同 LinkMonitor/MainPipe_1 双侧 elaborate 法)。
RTL_SRCS = $(RTL_DIR)/uncore/debug_pkg.sv \
           $(RTL_DIR)/uncore/DebugModule.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化所需 golden 顶层 (子块依赖闭包见 golden_filelist.f)。
GOLDEN_SRCS = $(GOLDEN_RTL)/DebugModule.sv

# TLDebugModule + DebugTransportModuleJTAG 依赖闭包 (34 文件, 与 golden_filelist.f
# 一致, 自含: ram_2x66 = firtool 行为级寄存器阵列 reg[65:0]x2, 非 vendor SRAM 宏,
# 无未解析 _ext 叶子; 全链无 negedge/latch)。两侧共用同套 golden 文件 ⇒ FM 全白盒。
DBG_GOLDEN_DEPS = \
  AsyncQueueSink.sv AsyncQueueSink_1.sv AsyncQueueSink_2.sv \
  AsyncQueueSource.sv AsyncQueueSource_1.sv AsyncQueueSource_2.sv \
  AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv \
  AsyncResetSynchronizerShiftReg_w1_d3_i0.sv \
  CaptureChain.sv CaptureUpdateChain.sv CaptureUpdateChain_1.sv \
  CaptureUpdateChain_2.sv \
  ClockCrossingReg_w15.sv ClockCrossingReg_w44.sv ClockCrossingReg_w56.sv \
  DMIToTL.sv DebugTransportModuleJTAG.sv \
  JtagBypassChain.sv JtagStateMachine.sv JtagTapController.sv \
  Queue2_TLBundleD_2.sv SBToTL.sv \
  TLAsyncCrossingSink.sv TLAsyncCrossingSource.sv \
  TLBusBypass.sv TLBusBypassBar.sv \
  TLDebugModule.sv TLDebugModuleInner.sv TLDebugModuleInnerAsync.sv \
  TLDebugModuleOuter.sv TLDebugModuleOuterAsync.sv \
  TLError_1.sv TLXbar_3.sv ram_2x66.sv

# impl 侧(WRAPPER_SRCS)加同套 golden 闭包 ⇒ impl 例化的 debug/dtm 解析为真 RTL。
WRAPPER_SRCS = $(RTL_DIR)/uncore/DebugModule_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(DBG_GOLDEN_DEPS))
FM_VARIANTS = DebugModule
# ref 侧(FM_REF_DEPS)同套闭包 ⇒ ref DebugModule 例化解析为真 RTL。
# 两侧 elaborate 白盒等价比对: 顶层 glue + 两子块全链内部逻辑全部受验, 0 黑盒。
FM_REF_DEPS_DebugModule = $(DBG_GOLDEN_DEPS)
# merge_duplicated_registers=false(非放宽——比较点 1437→1611 增多):
# merge=true 时 FM 仅在 impl 侧把 dmOuter/hartResetReg_0(hartsello 恒 0 使其 D 与
# DMCONTROLReg_hartreset 相同)合并入 DMCONTROLReg_hartreset, 并把 dmiBypass/bar 的
# 恒 0 计数器(r_counter/stall_counter)整体消除; ref 侧未做同样合并 ⇒ 3 个 ref-only
# unmatched + io_resetCtrl_hartResetReq_0 锥不对称假 failing。关合并后两侧寄存器
# 1:1 同名匹配, 0 unmatched / 0 failing(两侧本是同一套 golden 子模块 RTL)。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子块含非综合断言/firtool 随机初始化; UT 关随机化并按 initreg+0 初始化,
# 双时钟域 + 异步跨域队列在两实例间确定性演化。
VCS += +define+SYNTHESIS
VCS += +vcs+initreg+random
VCS += -assert disable
VCS += +libext+.sv+.v
VCS += -f golden_filelist.f
SIM_ARGS += +vcs+initreg+0

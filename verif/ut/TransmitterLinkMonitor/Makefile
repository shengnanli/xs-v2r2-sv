# 自动生成：scripts/gen_rxtxlinkmon.py —— 勿手改
# codex_0079 自审合规重做(child 闭包): 原配置 assembly + interface_only 3 个
# Queue15 FIFO 逻辑(黑盒了队列指针/full 控制 FSM = 未证逻辑子)违规。
# 合规重做 = 两侧真实 elaborate Queue15_CHI{SNP,RSP,DAT} 的 FIFO 控制 FSM(与
# ReceiverLinkMonitor 的 Queue4 同法, 白盒实证), **仅**把叶层存储宏 ram_15x*
# 作对称黑盒(不给 FM RTL ⇒ FM 不 elaborate 其 Memory[addr] ⇒ 无 FMR_ELAB-147;
# 存储阵列非控制逻辑等价对象, 同 Queue72_CoupledL2Imp_Anon/ram_72x15 既定先例)。
# ⇒ signoff-strict, allow 为空(对称 unresolved 黑盒无需声明)。
MODULE = TransmitterLinkMonitor

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/linkmonitor_pkg.sv \
           $(RTL_DIR)/uncore/TransmitterLinkMonitor.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden TransmitterLinkMonitor + 6 flit 子模块 + 3 Queue15 + 3 ram_15x
# (两侧共用同一例化, 白盒; ram_15x* 由 GOLDEN_SRCS 提供供仿真链接)。
GOLDEN_SRCS = $(GOLDEN_RTL)/TransmitterLinkMonitor.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_11.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_3.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_4.sv \
              $(GOLDEN_RTL)/Queue15_CHISNP.sv \
              $(GOLDEN_RTL)/Queue15_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue15_CHIDAT.sv \
              $(GOLDEN_RTL)/ram_15x115.sv \
              $(GOLDEN_RTL)/ram_15x73.sv \
              $(GOLDEN_RTL)/ram_15x422.sv

# FM 逻辑闭包(两侧 elaborate 白盒): flit 转换子 + 3 个 Queue15 FIFO FSM。
# ★ram_15x* 不在此列表 ⇒ FM 两侧均 hdlin_unresolved_modules=black_box 对称黑盒。
FLIT_GOLDEN = $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_11.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_3.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_4.sv \
              $(GOLDEN_RTL)/Queue15_CHISNP.sv \
              $(GOLDEN_RTL)/Queue15_CHIRSP.sv \
              $(GOLDEN_RTL)/Queue15_CHIDAT.sv

WRAPPER_SRCS = $(RTL_DIR)/uncore/TransmitterLinkMonitor_wrapper.sv $(FLIT_GOLDEN)
FM_VARIANTS = TransmitterLinkMonitor
# ref 侧(FM_REF_DEPS)同套 flit + Queue15(不含 ram_15x*) ⇒ ref/impl 两侧 Queue15 FSM
# 均 elaborate 为真 RTL, 仅 ram_15x115/73/422 作对称叶层黑盒。
FM_REF_DEPS_TransmitterLinkMonitor = Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv LCredit2Decoupled_11.sv LCredit2Decoupled_3.sv LCredit2Decoupled_4.sv Queue15_CHISNP.sv Queue15_CHIRSP.sv Queue15_CHIDAT.sv

# ---------------------------------------------------------------------------
# 叶层存储宏 ram_15x115/73/422(reg Memory[0:14], 4-bit addr): Queue15 指针在
# 0xE(14)显式回绕恒 ≤14 不越界(见 Queue15_CHI*.sv enq/deq_ptr wrap), 但 FM 静态
# 展开 4-bit addr 会保守报 FMR_ELAB-147。**黑盒 ram_15x*(不给 FM RTL)⇒ FM 不
# elaborate 其 Memory[addr] ⇒ 无 FMR-147**。队列控制 FSM(enq_ptr/deq_ptr/
# maybe_full/ptr_match/empty)两侧白盒逐位实证 = 真等价(非黑盒队列逻辑)。
# 存储宏两侧同名同接口对称黑盒, ram 输出 BBPin 对称喂两侧 ⇒ strict 无未配对黑盒输出。
# 同 Queue72_CoupledL2Imp_Anon(ram_72x15)/L2TlbMissQueue(ram_40x47)既定先例。
# ---------------------------------------------------------------------------

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

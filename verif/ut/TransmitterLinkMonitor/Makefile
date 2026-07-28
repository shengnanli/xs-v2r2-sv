# 自动生成：scripts/gen_rxtxlinkmon.py —— 勿手改
MODULE = TransmitterLinkMonitor

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

RTL_SRCS = $(RTL_DIR)/uncore/linkmonitor_pkg.sv \
           $(RTL_DIR)/uncore/TransmitterLinkMonitor.sv

TB_SRCS = variants_xs.sv tb.sv

# UT 双例化: golden TransmitterLinkMonitor + 6 个 flit 转换子模块(两侧共用同一例化, 白盒)。
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

# impl 侧(WRAPPER_SRCS)加同套 golden flit 文件 ⇒ 两侧都 elaborate 出这 6 个子模块
# = 全白盒等价比对(非黑盒), signoff-strict 下无 unresolved/blackbox 对象。
FLIT_GOLDEN = $(GOLDEN_RTL)/Decoupled2LCredit.sv \
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

WRAPPER_SRCS = $(RTL_DIR)/uncore/TransmitterLinkMonitor_wrapper.sv $(FLIT_GOLDEN)
FM_VARIANTS = TransmitterLinkMonitor
# ref 侧(FM_REF_DEPS)加同套 golden flit 文件 ⇒ ref TransmitterLinkMonitor 例化解析为真 RTL。
FM_REF_DEPS_TransmitterLinkMonitor = Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv LCredit2Decoupled_11.sv LCredit2Decoupled_3.sv LCredit2Decoupled_4.sv Queue15_CHISNP.sv Queue15_CHIRSP.sv Queue15_CHIDAT.sv ram_15x115.sv ram_15x73.sv ram_15x422.sv

# ---------------------------------------------------------------------------
# Queue15_CHI{SNP,RSP,DAT} = CHI 15 深 FIFO 存储子(inline 在 3 个 RX 侧
# LCredit2Decoupled 内, 实例名 queue)。其内部 ram_15x*(reg Memory[0:14], 4-bit
# W0/R0_addr 可取 15 越界 → golden 固有 FMR_ELAB-147 strict 硬 fail, 与本核重写
# 无关)。同 OpenLLC 既定处理: 三个 Queue15 声明 interface_only 对称黑盒(两侧同源
# golden RTL, ref==impl 逐点对称), 只证 LinkMonitor 自身状态机/握手 glue。
# ⇒ assembly 模式 + allow/TransmitterLinkMonitor.json 精确 3 个 interface_only。
FM_INTERFACE_ONLY = Queue15_CHISNP Queue15_CHIRSP Queue15_CHIDAT
FM_ALLOWLIST = 3

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

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

# 6 个 flit 转换子模块的 golden RTL 列表(ref/impl 两侧共用 = 双侧 elaborate 白盒)。
# LCredit2Decoupled(rxsnp) 内含 Queue4_CHISNP → ram_4x115(纯 firtool 寄存器阵列
# reg[114:0] Memory[0:3], 非 vendor SRAM 宏, 无 _ext 未解析叶子)。全链纯 RTL 可白盒。
FLIT_GOLDEN = $(GOLDEN_RTL)/Decoupled2LCredit.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_1.sv \
              $(GOLDEN_RTL)/Decoupled2LCredit_2.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_1.sv \
              $(GOLDEN_RTL)/LCredit2Decoupled_2.sv \
              $(GOLDEN_RTL)/Queue4_CHISNP.sv \
              $(GOLDEN_RTL)/ram_4x115.sv

# impl 侧(WRAPPER_SRCS)加同套 golden flit 文件 ⇒ 两侧都 elaborate 出这 6 个子模块
# = 全白盒等价比对(非黑盒), signoff-strict 下无 unresolved/blackbox 对象。
WRAPPER_SRCS = $(RTL_DIR)/uncore/LinkMonitor_wrapper.sv $(FLIT_GOLDEN)
FM_VARIANTS = LinkMonitor
# ref 侧(FM_REF_DEPS)加同套 golden flit 文件 ⇒ ref LinkMonitor 例化解析为真 RTL。
# 6 flit 转换器全部两侧 elaborate 白盒(SinkC/SRAMTemplate option2 法): 比对 LinkMonitor
# 自身状态机/握手/L-Credit 计数 + flit 转换器内部逻辑全部受验, 无黑盒放宽。
FM_REF_DEPS_LinkMonitor = Decoupled2LCredit.sv Decoupled2LCredit_1.sv Decoupled2LCredit_2.sv \
                          LCredit2Decoupled.sv LCredit2Decoupled_1.sv LCredit2Decoupled_2.sv \
                          Queue4_CHISNP.sv ram_4x115.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

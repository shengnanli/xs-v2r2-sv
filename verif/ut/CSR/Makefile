MODULE = CSR

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 (CSR assembly parent 胶合逻辑) + 端口壳。core 内例化 4 子:
#   NewCSR csrMod  —— 绿 305 (SIGNOFF_PASS); assembly 黑盒 (两侧未解析)
#   IMSIC  imsic   —— 绿 305 (SIGNOFF_PASS); assembly 黑盒 (两侧未解析)
#   TrapInstMod    —— 叶子逻辑, 两侧 elaborate 白盒
#   TrapTvalMod    —— 叶子逻辑, 两侧 elaborate 白盒
RTL_SRCS = $(RTL_DIR)/backend/CSR.sv

TB_SRCS = variants_xs.sv tb.sv

# 两侧 elaborate 的 golden 叶子/子模块 (白盒受验):
#   TrapInstMod/TrapTvalMod = CSR 直属叶子逻辑。
#   IMSIC.sv (顶层) = 两侧同 elaborate, 使其 toCSR_topeis 输出的常量 0 填充位
#     ([15:8]/[31:24], 含 CSR 未读的 [11:15]/[27:31]) 在两侧都被驱动为 0
#     (否则 IMSIC 整体黑盒时这些未读输出位在 ref cone 里 undriven→X→20 假 fail)。
#     IMSIC 内的 IntFile×7 / IMSICGateWay 仍为 assembly 黑盒 (绿305子边界下沉)。
CSR_LEAVES  = TrapInstMod.sv TrapTvalMod.sv
# IMSIC.sv + IntFile.sv 两侧对称 elaborate (IntFile 是 IMSIC 的可读逻辑子, 非
#   vendor 非独立 305 => 禁黑盒, 两侧同 golden elaborate 白盒受验, 同 IMSIC 自身签核)。
#   余 IMSICGateWay (绿305, 含 vendor 宏 msi_vld_req_cpu_chain) + NewCSR (绿305)
#   为 assembly 黑盒。
CSR_ELAB    = $(CSR_LEAVES) IMSIC.sv IntFile.sv
# UT 双例化: golden CSR + 全部 elaborate 子 + IMSIC 的黑盒子 stub。
GOLDEN_SRCS = $(GOLDEN_RTL)/CSR.sv $(addprefix $(GOLDEN_RTL)/,$(CSR_ELAB)) \
              csr_child_stub.sv

# FM: assembly。NewCSR 不给源 => 自动黑盒 (输出全被读, 无 dangling)。
#   IMSIC.sv 两侧 elaborate, 其子 IntFile/IMSICGateWay 不给源 => 自动黑盒
#   (绿305子边界); TrapInstMod/TrapTvalMod 两侧 elaborate 白盒受验。
WRAPPER_SRCS = $(RTL_DIR)/backend/CSR_wrapper.sv \
               $(addprefix $(GOLDEN_RTL)/,$(CSR_ELAB))
FM_VARIANTS = CSR
FM_REF_DEPS_CSR = $(CSR_ELAB)
FM_MODE = assembly
FM_ALLOWLIST = 0

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

MODULE = MepcModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_epc.sv)+ 2 个薄 wrapper(newcsr_epc_wrappers.sv)。
# epc family: Mepc/Sepc golden 逐字节相同(仅 trap 端口名不同,wrapper 重映射)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_epc.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_epc_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MepcModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 逐 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = MepcModule SepcModule

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入;UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS

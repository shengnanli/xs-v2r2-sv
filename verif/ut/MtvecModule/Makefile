MODULE = MtvecModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_tvec.sv)+ 3 个薄 wrapper(newcsr_tvec_wrappers.sv)。
# tvec family: Mtvec/Stvec/VStvec 三者 golden 逐字节相同 = 3 golden 顶层。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_tvec.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_tvec_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MtvecModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 逐 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = MtvecModule StvecModule VStvecModule

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS

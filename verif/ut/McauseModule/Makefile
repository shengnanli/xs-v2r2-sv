MODULE = McauseModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_cause.sv)+ 2 个薄 wrapper(newcsr_cause_wrappers.sv)。
# cause family: Mcause/Scause golden 逐字节相同(仅 trap 端口名不同)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_cause.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_cause_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/McauseModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 逐 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = McauseModule ScauseModule VScauseModule MncauseModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

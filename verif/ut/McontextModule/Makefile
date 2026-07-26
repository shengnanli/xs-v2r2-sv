MODULE = McontextModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# context CSRs(newcsr_context_wrappers.sv): Mcontext(14b HCONTEXT + Hcontext 写通)
# / Scontext(32b) / Hcontext(组合别名 mcontext)。三者结构各异,无 primitive 可抽。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_context_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/McontextModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = McontextModule ScontextModule HcontextModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

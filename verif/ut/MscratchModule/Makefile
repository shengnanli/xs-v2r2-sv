MODULE = MscratchModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_scratch.sv)+ 2 个薄 wrapper(newcsr_scratch_wrappers.sv)。
# scratch family: Mscratch/Sscratch golden 逐字节相同(clock-only, 无 reset)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_scratch.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_scratch_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MscratchModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 逐 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = MscratchModule SscratchModule VSscratchModule Dscratch0Module Dscratch1Module MnscratchModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

MODULE = MidelegModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 bespoke core(newcsr_mideleg.sv)+ wrapper(newcsr_mideleg_wrappers.sv)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_mideleg.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_mideleg_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MidelegModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: golden MidelegModule vs impl(core + wrapper)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = MidelegModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

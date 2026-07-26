MODULE = MedelegModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 bespoke core(newcsr_medeleg.sv)+ wrapper(newcsr_medeleg_wrappers.sv)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_medeleg.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_medeleg_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MedelegModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: golden MedelegModule vs impl(core + wrapper)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = MedelegModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

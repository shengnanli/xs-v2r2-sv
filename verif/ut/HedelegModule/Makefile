MODULE = HedelegModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 bespoke core(newcsr_hedeleg.sv)+ wrapper(newcsr_hedeleg_wrappers.sv)。
# hedeleg = medeleg 的 H-extension 子集(guest 可委派的异常子集,14 位写寄存器)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_hedeleg.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_hedeleg_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/HedelegModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: golden HedelegModule vs impl(core + wrapper)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = HedelegModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

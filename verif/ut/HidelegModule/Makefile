MODULE = HidelegModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 bespoke core(newcsr_hideleg.sv)+ wrapper(newcsr_hideleg_wrappers.sv)。
# hideleg = HS→VS 中断委派; 仅 VSSI/VSTI/VSEI/LCOFI 4 位写寄存器, 其余读 0;
# LCOFI 输出被 mideleg_LCOFI 门控(委派须先被 HS 委派)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_hideleg.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_hideleg_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/HidelegModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: golden HidelegModule vs impl(core + wrapper)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = HidelegModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

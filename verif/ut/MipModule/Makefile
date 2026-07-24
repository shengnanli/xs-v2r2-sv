MODULE = MipModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 bespoke primitive(newcsr_mip.sv)+ 薄 wrapper(newcsr_mip_wrappers.sv)。
# MipModule: mip 中断待决聚合器(3 状态位 + 大量组合聚合)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_mip.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_mip_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MipModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: golden MipModule vs impl(primitive + wrapper)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = MipModule

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 随机初值注入；UT 定义 SYNTHESIS 关掉以对齐 reset 语义。
VCS += +define+SYNTHESIS

MODULE = MtvalModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_tval.sv)+ 4 个薄 wrapper(newcsr_tval_wrappers.sv)。
# tval family: Mtval/Stval/Mtval2/Mtinst golden 逐字节相同(仅 trap 端口名不同)。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_tval.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_tval_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MtvalModule.sv
TB_SRCS      = variants_xs.sv tb.sv

# strict FM: 逐 golden 顶层 vs impl(primitive + wrappers)。无黑盒/无 dont_verify/无 allow。
FM_VARIANTS = MtvalModule StvalModule Mtval2Module MtinstModule HtvalModule HtinstModule VStvalModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

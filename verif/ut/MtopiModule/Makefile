MODULE = MtopiModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读组合 primitive(newcsr_topi.sv: xs_topi + xs_topei)+ 6 个薄 wrapper。
# topi/topei family: {M,S,VS}topi + {M,S,VS}topei 全组合只读打包视图。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_topi.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_topi_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MtopiModule.sv $(GOLDEN_RTL)/MtopeiModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = MtopiModule StopiModule VStopiModule MtopeiModule StopeiModule VStopeiModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

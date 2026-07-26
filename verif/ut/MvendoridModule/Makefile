MODULE = MvendoridModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 常量/平凡只读 CSR(newcsr_const_wrappers.sv): mvendorid=0, mconfigptr=0,
# mhartid={58'h0,hartid}。无 primitive 可抽,逐模块忠实转写。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_const_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/MvendoridModule.sv $(GOLDEN_RTL)/MhartidModule.sv
TB_SRCS      = tb.sv

FM_VARIANTS = MvendoridModule MconfigptrModule MhartidModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

MODULE = SstcInterruptGen

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# SstcInterruptGen(Sstc STIP/VSTIP 生成器)+ DelayReg_11/12(输出流水延迟链)。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_sstc_delayreg.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/SstcInterruptGen.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = SstcInterruptGen DelayReg_11 DelayReg_12

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

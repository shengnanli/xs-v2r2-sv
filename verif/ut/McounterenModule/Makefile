MODULE = McounterenModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读 primitive(newcsr_counteren.sv)+ 3 个薄 wrapper。
# counteren family: Mcounteren/Scounteren/Hcounteren golden 逐字节相同。
RTL_SRCS     = $(RTL_DIR)/backend/newcsr_counteren.sv
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_counteren_wrappers.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/McounterenModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = McounterenModule ScounterenModule HcounterenModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

MODULE = TrapHandleModule

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# TrapHandle(组合 trap 派发器: 判 M/HS/VS + cause + 入口 PC + 双重 trap)。可读转写。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_traphandle.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/TrapHandleModule.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = TrapHandleModule

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

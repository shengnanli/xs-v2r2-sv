MODULE = Debug

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# Debug(调试 trigger/breakpoint 决策逻辑 + 4 状态寄存器)。可读转写。
RTL_SRCS     =
WRAPPER_SRCS = $(RTL_DIR)/backend/newcsr_debug.sv
GOLDEN_SRCS  = $(GOLDEN_RTL)/Debug.sv
TB_SRCS      = variants_xs.sv tb.sv

FM_VARIANTS = Debug

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

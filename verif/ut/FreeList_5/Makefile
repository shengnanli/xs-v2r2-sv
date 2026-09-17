MODULE = FreeList_5

RTL_DIR = ../../../rtl
# 核体在 FreeList.sv 里（参数化共核），本变体文件只设参数
RTL_SRCS = $(RTL_DIR)/memblock/FreeList.sv $(RTL_DIR)/memblock/FreeList_5.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FreeList_5.sv
FM_REF_DEPS_FreeList_5 =
FM_VARIANTS = FreeList_5

include ../../../scripts/ut_common.mk

# ★ io_allocateSlot_*_r / io_canAllocate_*_r 共 6 个寄存器**不复位**
#   （Chisel RegEnable(x, true.B)），两轮 initreg 都要过。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

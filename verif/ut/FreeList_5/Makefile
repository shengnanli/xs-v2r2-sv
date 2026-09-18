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
#
# ★两轮 initreg★：原先运行期参数写死成 +vcs+initreg+0，`make run INITREG=...`
# 改不动它 —— 于是"两轮"里的 random 那轮**从来没有真的跑过**（磁盘上只有
# sim_<seed>_initreg0.log 一种后缀）。改成走 INITREG 变量，与本家族其它
# UT（FreeListVariants）同一口径。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

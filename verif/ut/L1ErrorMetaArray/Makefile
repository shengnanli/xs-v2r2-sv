MODULE = L1ErrorMetaArray

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/L1ErrorMetaArray.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/L1ErrorMetaArray.sv
FM_MERGE_DUP = false
FM_VARIANTS = L1ErrorMetaArray

include ../../../scripts/ut_common.mk

# 本模块只有 meta_array 异步复位；S1 在途写寄存器与读流水寄存器 golden 侧无复位。
# 两轮 initreg（random / 0）正是对「tb 的暖机是否真的把这些无复位寄存器写实」的检验：
# 若暖机不足，+random 那轮会立刻炸出两侧上电值不同导致的失配。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

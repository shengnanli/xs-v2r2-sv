MODULE = L1FlagMetaArray

RTL_DIR = ../../../rtl
# 家族共享核 + 本变体薄 wrapper（核体不复制，见 xs_l1_meta_array_core.sv 文件头对照表）
RTL_SRCS = $(RTL_DIR)/memblock/xs_l1_meta_array_core.sv \
           $(RTL_DIR)/memblock/L1FlagMetaArray.sv
TB_SRCS = tb.sv

# 自足叶子：golden 侧 0 子模块、0 厂商宏，故无 FM_REF_DEPS_*。
GOLDEN_SRCS = $(GOLDEN_RTL)/L1FlagMetaArray.sv
FM_MERGE_DUP = false
FM_VARIANTS = L1FlagMetaArray

include ../../../scripts/ut_common.mk

# 本族只有 meta_array 异步复位；S1 在途写寄存器与读流水寄存器 golden 侧无复位。
# 两轮 initreg（random / 0）正是对「tb 的暖机是否真把这些无复位寄存器写实」的检验：
# 暖机不足时 +random 那轮会立刻炸出两侧上电值不同导致的失配。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

MODULE = GPAMem

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读顶层核(UT + FM impl 两侧)。
RTL_SRCS = $(RTL_DIR)/backend/GPAMem.sv

# UT 用 _xs 变体。
TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + 存储子模块(UT: golden GPAMem 与 GPAMem_xs 共享同一份 golden 子)。
GOLDEN_SRCS = $(GOLDEN_RTL)/GPAMem.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_4.sv \
              $(GOLDEN_RTL)/DataModule__16entry_16.sv

# FM impl 侧: 手写 wrapper + golden 存储子(两侧同源 elaborate, 非黑盒)。
# SyncDataModuleTemplate__64entry_4 是 305 signoff 目标(SyncDataModule UT 独立验证)。
WRAPPER_SRCS = $(RTL_DIR)/backend/GPAMem_wrapper.sv \
               $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_4.sv \
               $(GOLDEN_RTL)/DataModule__16entry_16.sv
FM_VARIANTS = GPAMem
# golden ref 侧 GPAMem 的子模块依赖。
FM_REF_DEPS_GPAMem = SyncDataModuleTemplate__64entry_4.sv DataModule__16entry_16.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

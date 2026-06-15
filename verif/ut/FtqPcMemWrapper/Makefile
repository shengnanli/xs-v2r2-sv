MODULE = FtqPcMemWrapper

RTL_DIR = ../../../rtl
# 手写 RTL：底层 DataModule / SyncDataModule 可读核 + FtqPcMemWrapper 可读核与包装
RTL_SRCS = $(RTL_DIR)/common/DataModule.sv \
           $(RTL_DIR)/common/SyncDataModule.sv \
           $(RTL_DIR)/frontend/FtqPcMemWrapper.sv
# FtqPcMemWrapper.sv 既含可读核也含 golden 同名包装，FM 直接用 RTL_SRCS，无额外变体
WRAPPER_SRCS =
TB_SRCS = tb.sv

GOLDEN_RTL = ../../../golden/chisel-rtl
# UT 参考 = FtqPcMemWrapper 唯一子模块 SyncDataModuleTemplate_FtqPC_64entry 及其 bank
GOLDEN_SRCS = $(GOLDEN_RTL)/SyncDataModuleTemplate_FtqPC_64entry.sv \
              $(GOLDEN_RTL)/DataModule_FtqPC_16entry.sv

# FM：golden 顶层 FtqPcMemWrapper（含其全部子模块）vs 手写同名包装
FM_VARIANTS = FtqPcMemWrapper
FM_REF_DEPS_FtqPcMemWrapper = SyncDataModuleTemplate_FtqPC_64entry.sv \
                              DataModule_FtqPC_16entry.sv

include ../../../scripts/ut_common.mk

# ★调试用★（不产生任何 signoff receipt）：官方 tb 只打汇总数，
# 这里的副本额外记每根输出的失配数与**首次失配周期**，用来定位。
MODULE = StoreQueue
RTL_DIR = ../../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/StoreQueue.sv \
           $(RTL_DIR)/memblock/SQDataModule.sv \
           $(RTL_DIR)/memblock/SQData8Module.sv \
           $(RTL_DIR)/memblock/SQAddrModule.sv \
           $(RTL_DIR)/memblock/SQAddrModule_1.sv \
           $(RTL_DIR)/memblock/DatamoduleResultBuffer.sv \
           $(RTL_DIR)/memblock/StoreExceptionBuffer.sv
TB_SRCS = tb_dbg.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/StoreQueue.sv \
              $(GOLDEN_RTL)/SQAddrModule.sv \
              $(GOLDEN_RTL)/SQAddrModule_1.sv \
              $(GOLDEN_RTL)/SQDataModule.sv \
              $(GOLDEN_RTL)/SQData8Module.sv \
              $(GOLDEN_RTL)/DatamoduleResultBuffer.sv \
              $(GOLDEN_RTL)/StoreExceptionBuffer.sv
FM_VARIANTS =
NCYCLES ?= 4000
include ../../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

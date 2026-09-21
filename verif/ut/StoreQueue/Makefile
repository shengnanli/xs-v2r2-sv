MODULE = StoreQueue

RTL_DIR = ../../../rtl
# 单文件规范：核 + golden 同名 wrapper 同文件。StoreQueue 的可读核例化 5 个
# 子模块（本仓已有重写件），它们必须一起进 UT 的 _xs 派生与 FM 的 impl 侧，
# 否则 UT 会把 golden 的同名子模块编进重写侧（假绿）。
RTL_SRCS = $(RTL_DIR)/memblock/StoreQueue.sv \
           $(RTL_DIR)/memblock/SQDataModule.sv \
           $(RTL_DIR)/memblock/SQData8Module.sv \
           $(RTL_DIR)/memblock/SQAddrModule.sv \
           $(RTL_DIR)/memblock/SQAddrModule_1.sv \
           $(RTL_DIR)/memblock/DatamoduleResultBuffer.sv \
           $(RTL_DIR)/memblock/StoreExceptionBuffer.sv
TB_SRCS = tb.sv

# golden StoreQueue 例化 5 个子模块（SQDataModule 又例化 SQData8Module），
# UT 双例化时 golden 侧闭包必须齐全。
GOLDEN_SRCS = $(GOLDEN_RTL)/StoreQueue.sv \
              $(GOLDEN_RTL)/SQAddrModule.sv \
              $(GOLDEN_RTL)/SQAddrModule_1.sv \
              $(GOLDEN_RTL)/SQDataModule.sv \
              $(GOLDEN_RTL)/SQData8Module.sv \
              $(GOLDEN_RTL)/DatamoduleResultBuffer.sv \
              $(GOLDEN_RTL)/StoreExceptionBuffer.sv

FM_VARIANTS = StoreQueue
FM_REF_DEPS_StoreQueue = SQAddrModule.sv SQAddrModule_1.sv SQDataModule.sv SQData8Module.sv DatamoduleResultBuffer.sv StoreExceptionBuffer.sv

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

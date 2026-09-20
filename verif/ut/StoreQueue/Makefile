MODULE = StoreQueue

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/StoreQueue.sv
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

MODULE = FtqPcMemWrapper

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DataModule.sv \
           $(RTL_DIR)/common/xs_SyncDataModule.sv \
           $(RTL_DIR)/frontend/FtqPcMemWrapper.sv
TB_SRCS = tb.sv

FM_REF_DEPS_FtqPcMemWrapper = SyncDataModuleTemplate_FtqPC_64entry.sv                                DataModule_FtqPC_16entry.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/SyncDataModuleTemplate_FtqPC_64entry.sv \
              $(GOLDEN_RTL)/DataModule_FtqPC_16entry.sv
FM_VARIANTS = FtqPcMemWrapper

include ../../../scripts/ut_common.mk

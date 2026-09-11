MODULE = SyncDataModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DataModule.sv \
           $(RTL_DIR)/common/xs_SyncDataModule.sv \
           $(RTL_DIR)/common/DataModule_BackendPC_16entry.sv \
           $(RTL_DIR)/common/DataModule_FtqPC_16entry.sv \
           $(RTL_DIR)/common/DataModule__64entry.sv \
           $(RTL_DIR)/common/DataModule__64entry_16.sv \
           $(RTL_DIR)/common/DataModule__16entry.sv \
           $(RTL_DIR)/common/DataModule__16entry_4.sv \
           $(RTL_DIR)/common/DataModule__16entry_8.sv \
           $(RTL_DIR)/common/DataModule__16entry_12.sv \
           $(RTL_DIR)/common/DataModule__16entry_16.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate_BackendPC_64entry.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate_FtqPC_64entry.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__1024entry.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__1024entry_1.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_1.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_2.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_3.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_4.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/DataModule_BackendPC_16entry.sv \
              $(GOLDEN_RTL)/DataModule_FtqPC_16entry.sv \
              $(GOLDEN_RTL)/DataModule__64entry.sv \
              $(GOLDEN_RTL)/DataModule__64entry_16.sv \
              $(GOLDEN_RTL)/DataModule__16entry.sv \
              $(GOLDEN_RTL)/DataModule__16entry_4.sv \
              $(GOLDEN_RTL)/DataModule__16entry_8.sv \
              $(GOLDEN_RTL)/DataModule__16entry_12.sv \
              $(GOLDEN_RTL)/DataModule__16entry_16.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate_BackendPC_64entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate_FtqPC_64entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__1024entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__1024entry_1.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_1.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_2.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_3.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_4.sv

FM_REF_DEPS_SyncDataModuleTemplate_BackendPC_64entry = DataModule_BackendPC_16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate_FtqPC_64entry = DataModule_FtqPC_16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__1024entry = DataModule__64entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__1024entry_1 = DataModule__64entry_16.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry = DataModule__16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_1 = DataModule__16entry_4.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_2 = DataModule__16entry_8.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_3 = DataModule__16entry_12.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_4 = DataModule__16entry_16.sv

FM_VARIANTS = DataModule_BackendPC_16entry DataModule_FtqPC_16entry DataModule__64entry DataModule__64entry_16 DataModule__16entry DataModule__16entry_4 DataModule__16entry_8 DataModule__16entry_12 DataModule__16entry_16 SyncDataModuleTemplate_BackendPC_64entry SyncDataModuleTemplate_FtqPC_64entry SyncDataModuleTemplate__1024entry SyncDataModuleTemplate__1024entry_1 SyncDataModuleTemplate__64entry SyncDataModuleTemplate__64entry_1 SyncDataModuleTemplate__64entry_2 SyncDataModuleTemplate__64entry_3 SyncDataModuleTemplate__64entry_4

include ../../../scripts/ut_common.mk

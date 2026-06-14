MODULE = SyncDataModule

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/DataModule.sv \
           $(RTL_DIR)/common/SyncDataModule.sv
WRAPPER_SRCS = $(RTL_DIR)/common/DataModule_variants.sv \
               $(RTL_DIR)/common/SyncDataModule_variants.sv
TB_SRCS = variants_xs.sv tb.sv

GOLDEN_RTL = ../../../golden/chisel-rtl
INNER = DataModule_BackendPC_16entry DataModule_FtqPC_16entry \
        DataModule__64entry DataModule__64entry_16 \
        DataModule__16entry DataModule__16entry_4 \
        DataModule__16entry_8 DataModule__16entry_12 DataModule__16entry_16
OUTER = SyncDataModuleTemplate_BackendPC_64entry SyncDataModuleTemplate_FtqPC_64entry \
        SyncDataModuleTemplate__1024entry SyncDataModuleTemplate__1024entry_1 \
        SyncDataModuleTemplate__64entry SyncDataModuleTemplate__64entry_1 \
        SyncDataModuleTemplate__64entry_2 SyncDataModuleTemplate__64entry_3 \
        SyncDataModuleTemplate__64entry_4
GOLDEN_SRCS = $(addsuffix .sv,$(addprefix $(GOLDEN_RTL)/,$(INNER) $(OUTER)))

FM_VARIANTS = $(INNER) $(OUTER)
FM_REF_DEPS_SyncDataModuleTemplate_BackendPC_64entry = DataModule_BackendPC_16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate_FtqPC_64entry     = DataModule_FtqPC_16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__1024entry        = DataModule__64entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__1024entry_1      = DataModule__64entry_16.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry          = DataModule__16entry.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_1        = DataModule__16entry_4.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_2        = DataModule__16entry_8.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_3        = DataModule__16entry_12.sv
FM_REF_DEPS_SyncDataModuleTemplate__64entry_4        = DataModule__16entry_16.sv

include ../../../scripts/ut_common.mk

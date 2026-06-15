MODULE = Ftq

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核（核内例化 golden 同名存储子模块）
RTL_SRCS = $(RTL_DIR)/frontend/Ftq.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 + 全部子模块（UT 双例化两侧共用同一批子模块实现，
# 比对只检验顶层互联/指针/状态机/redirect/commit 是否等价）
GOLDEN_SUBS = $(GOLDEN_RTL)/FtqNRSRAM.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_1.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_2.sv \
              $(GOLDEN_RTL)/FtqPcMemWrapper.sv \
              $(GOLDEN_RTL)/MbistPipeFtq.sv \
              $(GOLDEN_RTL)/FTBEntryGen.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_29.sv \
              $(GOLDEN_RTL)/SRAMTemplate_78.sv \
              $(GOLDEN_RTL)/sram_array_2p64x144m144s1h0l1b_ftq.sv \
              $(GOLDEN_RTL)/array_7.sv $(GOLDEN_RTL)/array_7_ext.v \
              $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/MbistClockGateCell_101.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/SyncDataModuleTemplate_FtqPC_64entry.sv \
              $(GOLDEN_RTL)/DataModule_FtqPC_16entry.sv \
              $(GOLDEN_RTL)/DataModule__16entry.sv \
              $(GOLDEN_RTL)/DataModule__16entry_4.sv \
              $(GOLDEN_RTL)/DataModule__16entry_8.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/Ftq.sv $(GOLDEN_SUBS)

# FM：golden 顶层 Ftq（含全部子模块黑盒）vs 手写同名 wrapper（→ 可读核 + golden 子模块黑盒）
WRAPPER_SRCS = $(RTL_DIR)/frontend/Ftq_wrapper.sv
FM_VARIANTS = Ftq
FM_REF_DEPS_Ftq =

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS

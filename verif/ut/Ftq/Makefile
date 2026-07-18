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

# FM：golden 顶层 Ftq（含全部子模块黑盒）vs 手写同名 wrapper（→ 可读核 + golden 子模块黑盒）。
# 存储/生成器子模块用 interface-only（仍是黑盒，但端口方向已知）：否则未解析黑盒输出直连
# 另一黑盒输入（ftq_pd_mem.rdata_1 → FTBEntryGen.pd 等）时 ref 侧连线被判多驱动 →
# net 黑盒化成自由变量，commit/update/perf 锥全部误判失配。
FM_IFONLY_SRCS = $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry.sv                  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_1.sv                  $(GOLDEN_RTL)/SyncDataModuleTemplate__64entry_2.sv                  $(GOLDEN_RTL)/FTBEntryGen.sv                  $(GOLDEN_RTL)/FtqPcMemWrapper.sv                  $(GOLDEN_RTL)/FtqNRSRAM.sv                  $(GOLDEN_RTL)/SyncDataModuleTemplate_FtqPC_64entry.sv                  $(GOLDEN_RTL)/MbistPipeFtq.sv
WRAPPER_SRCS = $(RTL_DIR)/frontend/Ftq_wrapper.sv $(FM_IFONLY_SRCS)
FM_VARIANTS = Ftq
FM_INTERFACE_ONLY = SyncDataModuleTemplate__64entry SyncDataModuleTemplate__64entry_1                     SyncDataModuleTemplate__64entry_2 FTBEntryGen FtqPcMemWrapper FtqNRSRAM                     SyncDataModuleTemplate_FtqPC_64entry MbistPipeFtq
FM_REF_DEPS_Ftq = SyncDataModuleTemplate__64entry.sv SyncDataModuleTemplate__64entry_1.sv                   SyncDataModuleTemplate__64entry_2.sv FTBEntryGen.sv FtqPcMemWrapper.sv                   FtqNRSRAM.sv SyncDataModuleTemplate_FtqPC_64entry.sv MbistPipeFtq.sv

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS

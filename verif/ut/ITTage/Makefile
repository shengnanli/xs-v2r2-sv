MODULE = ITTage

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层 SRAM 宏链（各 ITTageTable 内部 FoldedSRAMTemplate→...→sram_array_...ittage）
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
            $(GOLDEN_RTL)/array_6.sv $(GOLDEN_RTL)/array_6_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

# 可读核（xs_ITTage_core）
RTL_SRCS = $(RTL_DIR)/frontend/ITTage.sv
# FM impl：核 + golden 同名 wrapper（ITTageTable_* 黑盒；RegionWays/LFSR 双侧 elaborate）
# RegionWays(纯逻辑740行)+MaxPeriodFibonacciLFSR(确定性LFSR)非vendor → 两侧白盒比对
WRAPPER_SRCS = $(RTL_DIR)/frontend/ITTage_wrapper.sv \
               $(GOLDEN_RTL)/RegionWays.sv $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv

# UT：golden ITTage 顶层 + 全部子模块链（两侧共用同名子模块）
#   5 张表 + 其 MBIST/SRAM/WrBypass/CAM 全链 + RegionWays + LFSR
GOLDEN_SRCS = $(GOLDEN_RTL)/ITTage.sv \
              $(GOLDEN_RTL)/ITTageTable.sv $(GOLDEN_RTL)/ITTageTable_1.sv \
              $(GOLDEN_RTL)/ITTageTable_2.sv $(GOLDEN_RTL)/ITTageTable_3.sv \
              $(GOLDEN_RTL)/ITTageTable_4.sv \
              $(GOLDEN_RTL)/RegionWays.sv $(GOLDEN_RTL)/MaxPeriodFibonacciLFSR.sv \
              $(GOLDEN_RTL)/MbistPipeIttage.sv $(GOLDEN_RTL)/MbistPipeIttage_1.sv \
              $(GOLDEN_RTL)/MbistPipeIttage_2.sv $(GOLDEN_RTL)/MbistPipeIttage_3.sv \
              $(GOLDEN_RTL)/MbistPipeIttage_4.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate_21.sv $(GOLDEN_RTL)/FoldedSRAMTemplate_23.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_24.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_26.sv \
              $(GOLDEN_RTL)/SRAMTemplate_70.sv $(GOLDEN_RTL)/SRAMTemplate_72.sv \
              $(GOLDEN_RTL)/WrBypass_41.sv $(GOLDEN_RTL)/WrBypass_43.sv \
              $(GOLDEN_RTL)/IndexableCAMTemplate_41.sv $(GOLDEN_RTL)/IndexableCAMTemplate_43.sv \
              $(GOLDEN_RTL)/data_mem_0_4x2.sv \
              $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden ITTage（子模块 ITTageTable_*/RegionWays/LFSR 全部不列入依赖 →
#   hdlin_unresolved_modules=black_box 两侧同名黑盒）；impl = 核 + wrapper（同样黑盒）。
FM_VARIANTS = ITTage
FM_REF_DEPS_ITTage = RegionWays.sv MaxPeriodFibonacciLFSR.sv

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 断言 + 随机初始化；UT 仿真定义 SYNTHESIS 关掉，从复位态出发
VCS += +define+SYNTHESIS

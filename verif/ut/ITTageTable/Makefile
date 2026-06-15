MODULE = ITTageTable

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层 SRAM 宏链：FoldedSRAMTemplate_21/_23 内层 Splitted→SRAMTemplate→sram_array_...ittage
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p128x76m1s1h0l1b_bp_ittage.sv \
            $(GOLDEN_RTL)/array_6.sv $(GOLDEN_RTL)/array_6_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

# 可读核（xs_ITTageTable_core + xs_MbistPipeIttage_core）
RTL_SRCS = $(RTL_DIR)/frontend/ITTageTable.sv
# FM impl：核 + golden 同名 wrapper（FoldedSRAMTemplate_21/_23、WrBypass_41/_43 当黑盒）
WRAPPER_SRCS = $(RTL_DIR)/frontend/ITTageTable_wrapper.sv

# UT：golden 5 变体 + 子模块全链（两侧共用内层 SRAM/WrBypass/MBIST）
GOLDEN_SRCS = $(GOLDEN_RTL)/ITTageTable.sv $(GOLDEN_RTL)/ITTageTable_1.sv \
              $(GOLDEN_RTL)/ITTageTable_2.sv $(GOLDEN_RTL)/ITTageTable_3.sv \
              $(GOLDEN_RTL)/ITTageTable_4.sv \
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

# FM：ref = golden 变体（内层 SRAM/WrBypass/MBIST 黑盒）；impl = 我的核 + wrapper
# FM：把 MBIST 流水（纯 DFT）在 ref 侧也展开（impl 侧用 xs_MbistPipeIttage_core 展开），
# 两侧逻辑等价由签名分析+寄存器配对验证；SRAM/WrBypass 仍为两侧同名黑盒。
FM_VARIANTS = ITTageTable ITTageTable_1 ITTageTable_2 ITTageTable_3 ITTageTable_4
FM_REF_DEPS_ITTageTable   = MbistPipeIttage.sv
FM_REF_DEPS_ITTageTable_1 = MbistPipeIttage_1.sv
FM_REF_DEPS_ITTageTable_2 = MbistPipeIttage_2.sv
FM_REF_DEPS_ITTageTable_3 = MbistPipeIttage_3.sv
FM_REF_DEPS_ITTageTable_4 = MbistPipeIttage_4.sv

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 断言（读写同址 $fatal）+ 随机初始化，UT 仿真定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS

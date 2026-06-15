MODULE = TageTable

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层宏链：tage_us(Splitted_3→SRAMTemplate_44) + bp_tage(Splitted_4→SRAMTemplate_45)
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
            $(GOLDEN_RTL)/array_2.sv $(GOLDEN_RTL)/array_2_ext.v \
            $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
            $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/array_3_ext.v $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

# 可读核
RTL_SRCS = $(RTL_DIR)/frontend/TageTable.sv
# FM impl：核 + golden 同名 wrapper（FoldedSRAMTemplate/_1、WrBypass 当黑盒）
WRAPPER_SRCS = $(RTL_DIR)/frontend/TageTable_wrapper.sv
# UT：golden 4 变体 + 子模块全链（两侧共用）
GOLDEN_SRCS = $(GOLDEN_RTL)/TageTable.sv $(GOLDEN_RTL)/TageTable_1.sv \
              $(GOLDEN_RTL)/TageTable_2.sv $(GOLDEN_RTL)/TageTable_3.sv \
              $(GOLDEN_RTL)/FoldedSRAMTemplate.sv $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SRAMTemplate_44.sv $(GOLDEN_RTL)/SRAMTemplate_45.sv \
              $(GOLDEN_RTL)/WrBypass.sv $(GOLDEN_RTL)/IndexableCAMTemplate.sv \
              $(GOLDEN_RTL)/data_mem_0_8x3.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TageTable TageTable_1 TageTable_2 TageTable_3
FM_REF_DEPS_TageTable =
FM_REF_DEPS_TageTable_1 =
FM_REF_DEPS_TageTable_2 =
FM_REF_DEPS_TageTable_3 =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

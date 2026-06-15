MODULE = TageBTable

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层链 Folded_20→Splitted_23→SRAMTemplate_64(双口) 宏链 + WrBypass_32
MACRO_SIM = $(GOLDEN_RTL)/sram_array_2p256x16m2s1h0l1b_bp_tage_bt.sv \
            $(GOLDEN_RTL)/array_4.sv $(GOLDEN_RTL)/array_4_ext.v $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 TageBTable（Folded_20/WrBypass_32 当黑盒）
WRAPPER_SRCS = $(RTL_DIR)/frontend/TageBTable.sv
# UT：golden TageBTable + golden 子模块链（两侧共用）
GOLDEN_SRCS = $(GOLDEN_RTL)/TageBTable.sv $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv $(GOLDEN_RTL)/SRAMTemplate_64.sv \
              $(GOLDEN_RTL)/WrBypass_32.sv $(GOLDEN_RTL)/IndexableCAMTemplate_32.sv \
              $(GOLDEN_RTL)/data_mem_8x4.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = TageBTable
FM_REF_DEPS_TageBTable =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

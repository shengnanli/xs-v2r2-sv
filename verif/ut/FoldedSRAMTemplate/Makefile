MODULE = FoldedSRAMTemplate

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层 SplittedSRAMTemplate_3 → SRAMTemplate_44(bp_tage_us) 宏链
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p256x16m1s1h0l1b_bp_tage_us.sv \
            $(GOLDEN_RTL)/array_2.sv $(GOLDEN_RTL)/array_2_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 Folded（内层 SplittedSRAMTemplate_3 当黑盒）
WRAPPER_SRCS = $(RTL_DIR)/common/FoldedSRAMTemplate_variants.sv
# UT：golden Folded + golden 内层链（两侧共用内层）
GOLDEN_SRCS = $(GOLDEN_RTL)/FoldedSRAMTemplate.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_3.sv \
              $(GOLDEN_RTL)/SRAMTemplate_44.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden Folded（内层 SplittedSRAMTemplate_3 黑盒）；impl = 我的 Folded（同黑盒）
FM_VARIANTS = FoldedSRAMTemplate
FM_REF_DEPS_FoldedSRAMTemplate =

include ../../../scripts/ut_common.mk

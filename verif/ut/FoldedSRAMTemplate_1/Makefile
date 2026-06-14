MODULE = FoldedSRAMTemplate_1

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层 SRAMTemplate_45(bp_tage) 宏链（UT 需可仿真 array_ext.v）
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
            $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/array_3_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 Folded（内层 SplittedSRAMTemplate_4 当黑盒）
WRAPPER_SRCS = $(RTL_DIR)/common/FoldedSRAMTemplate_variants.sv
# UT：golden Folded + golden 内层链（两侧共用内层）
GOLDEN_SRCS = $(GOLDEN_RTL)/FoldedSRAMTemplate_1.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv \
              $(GOLDEN_RTL)/SRAMTemplate_45.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden Folded_1（内层 SplittedSRAMTemplate_4 黑盒）；impl = 我的 Folded_1（同黑盒）
FM_VARIANTS = FoldedSRAMTemplate_1
FM_REF_DEPS_FoldedSRAMTemplate_1 =

include ../../../scripts/ut_common.mk

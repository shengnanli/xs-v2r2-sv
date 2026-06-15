MODULE = FoldedSRAMTemplate_20

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层链 Splitted_23 → SRAMTemplate_64(双口 bp_tage_bt) 的宏链
MACRO_SIM = $(GOLDEN_RTL)/sram_array_2p256x16m2s1h0l1b_bp_tage_bt.sv \
            $(GOLDEN_RTL)/array_4.sv $(GOLDEN_RTL)/array_4_ext.v $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 Folded_20（内层 Splitted_23 当黑盒）
WRAPPER_SRCS = $(RTL_DIR)/common/FoldedSRAMTemplate_variants.sv
# UT：golden Folded_20 + golden 内层 Splitted_23 + SRAMTemplate_64 + 宏链
GOLDEN_SRCS = $(GOLDEN_RTL)/FoldedSRAMTemplate_20.sv $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv \
              $(GOLDEN_RTL)/SRAMTemplate_64.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = FoldedSRAMTemplate_20
FM_REF_DEPS_FoldedSRAMTemplate_20 =

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

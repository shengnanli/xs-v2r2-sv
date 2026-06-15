MODULE = SplittedSRAMTemplate_4

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# bp_tage 内层 SRAMTemplate_45 宏链（UT 需可仿真）
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p512x24m12s1h0l1b_bp_tage.sv \
            $(GOLDEN_RTL)/array_3.sv $(GOLDEN_RTL)/array_3_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 Splitted（内层 SRAMTemplate_45 当黑盒）
WRAPPER_SRCS = $(RTL_DIR)/common/SplittedSRAMTemplate_variants.sv
# UT：golden Splitted + golden 内层 SRAMTemplate_45 + 宏链（两侧共用内层）
GOLDEN_SRCS = $(GOLDEN_RTL)/SplittedSRAMTemplate_4.sv $(GOLDEN_RTL)/SRAMTemplate_45.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SplittedSRAMTemplate_4
FM_REF_DEPS_SplittedSRAMTemplate_4 =

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 断言，UT 仿真时定义 SYNTHESIS 关掉（必须在 include 之后追加）
VCS += +define+SYNTHESIS

MODULE = SplittedSRAMTemplate_23

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 内层 SRAMTemplate_64(双口 bp_tage_bt) 的宏链（UT 仿真用）
MACRO_SIM = $(GOLDEN_RTL)/sram_array_2p256x16m2s1h0l1b_bp_tage_bt.sv \
            $(GOLDEN_RTL)/array_4.sv $(GOLDEN_RTL)/array_4_ext.v $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

RTL_SRCS =
# FM impl：我的 Splitted_23（内层 SRAMTemplate_64 当黑盒，不读其定义）
WRAPPER_SRCS = $(RTL_DIR)/common/SplittedSRAMTemplate_variants.sv
# UT：golden Splitted_23 + golden 内层 SRAMTemplate_64 + 宏链（两侧共用内层）
GOLDEN_SRCS = $(GOLDEN_RTL)/SplittedSRAMTemplate_23.sv $(GOLDEN_RTL)/SRAMTemplate_64.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = SplittedSRAMTemplate_23
FM_REF_DEPS_SplittedSRAMTemplate_23 =

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 断言（含内层读写同址 $fatal），UT 仿真定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS

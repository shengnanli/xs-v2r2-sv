MODULE = SRAMTemplate

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 库单元/宏：UT 需行为级 array_ext.v 可仿真；FM 把 array_ext 当黑盒（不读），
# 其余宏链两侧共用。
MACRO_SIM = $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
            $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv
MACRO_FM  = $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
            $(GOLDEN_RTL)/array.sv \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv

# 共享设计：仅功能核（无重名风险）
RTL_SRCS = $(RTL_DIR)/common/SRAMTemplate_core.sv
# FM impl 专用：golden 同名 wrapper + 宏链黑盒（不进 UT simv，避免与 golden 同名冲突）
WRAPPER_SRCS = $(RTL_DIR)/common/SRAMTemplate_variants.sv $(MACRO_FM)
# UT simv：golden SRAMTemplate + 可仿真宏链
GOLDEN_SRCS = $(GOLDEN_RTL)/SRAMTemplate.sv $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

# FM：ref = golden SRAMTemplate + 宏链（array_ext 黑盒）
FM_VARIANTS = SRAMTemplate
FM_REF_DEPS_SRAMTemplate = sram_array_1p128x74m37s1h0l1b_icsh_tag.sv array.sv \
                           MbistClockGateCell.sv ClockGate.sv

include ../../../scripts/ut_common.mk

MODULE = SRAMTemplate_2p

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

include sram_deps.mk

# 共享设计：双端口功能核
RTL_SRCS = $(RTL_DIR)/common/SRAMTemplate_2p_core.sv
# FM impl 专用：golden 同名 wrapper + 宏链黑盒（array_ext 不读）
WRAPPER_SRCS = $(RTL_DIR)/common/SRAMTemplate_2p_variants.sv $(MACRO_FM)
# UT simv：golden 各变体 + 可仿真宏链
GOLDEN_SRCS = $(addsuffix .sv,$(addprefix $(GOLDEN_RTL)/,$(SRAM_VARIANTS))) $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = $(SRAM_VARIANTS)

include ../../../scripts/ut_common.mk

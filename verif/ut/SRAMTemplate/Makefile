MODULE = SRAMTemplate

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 生成器输出：SRAM_VARIANTS / MACRO_SIM / MACRO_FM / FM_REF_DEPS_*
include sram_deps.mk

# 共享设计：仅功能核（无重名风险）
RTL_SRCS = $(RTL_DIR)/common/SRAMTemplate_core.sv
# FM impl 专用：golden 同名 wrapper + 宏链黑盒（array_ext 不读）
WRAPPER_SRCS = $(RTL_DIR)/common/SRAMTemplate_variants.sv $(MACRO_FM)
# UT simv：golden 各变体 + 可仿真宏链
GOLDEN_SRCS = $(addsuffix .sv,$(addprefix $(GOLDEN_RTL)/,$(SRAM_VARIANTS))) $(MACRO_SIM)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = $(SRAM_VARIANTS)

include ../../../scripts/ut_common.mk

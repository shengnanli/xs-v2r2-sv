MODULE = ICacheMetaArray

RTL_DIR    = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# golden tag SRAM / Mbist / 时钟门 子模块（UT 双例化共用，FM 当黑盒）
GOLDEN_DEPS = $(GOLDEN_RTL)/SplittedSRAMTemplate.sv \
              $(GOLDEN_RTL)/SplittedSRAMTemplate_1.sv \
              $(GOLDEN_RTL)/SRAMTemplate.sv \
              $(GOLDEN_RTL)/SRAMTemplate_2.sv \
              $(GOLDEN_RTL)/sram_array_1p128x74m37s1h0l1b_icsh_tag.sv \
              $(GOLDEN_RTL)/array.sv $(GOLDEN_RTL)/array_ext.v \
              $(GOLDEN_RTL)/MbistClockGateCell.sv \
              $(GOLDEN_RTL)/ClockGate.sv \
              $(GOLDEN_RTL)/MbistPipeIcacheTag.sv

# 手写可读核（含 package）。UT 不编 golden 同名 wrapper（会与 golden 顶层撞名）；
# UT 的「手写顶层」改由 variants_xs.sv 里的 ICacheMetaArray_xs 提供（内容同 wrapper）。
RTL_SRCS     = $(RTL_DIR)/frontend/ICacheMetaArray.sv
# golden 同名 wrapper 仅 FM 用（impl 侧顶层），不进 UT 编译
WRAPPER_SRCS = $(RTL_DIR)/frontend/ICacheMetaArray_wrapper.sv
# golden 顶层 + 全部共享子模块（UT 编译只在此列一次，避免重复模块定义）
GOLDEN_SRCS  = $(GOLDEN_RTL)/ICacheMetaArray.sv $(GOLDEN_DEPS)
TB_SRCS      = variants_xs.sv tb.sv

# FM：golden 顶层 ICacheMetaArray <-> 手写核+wrapper；SRAM/Mbist 黑盒（两侧同名）。
FM_VARIANTS = ICacheMetaArray
FM_REF_DEPS_ICacheMetaArray =

include ../../../scripts/ut_common.mk

# golden 含 ifndef SYNTHESIS 的随机初始化/断言；UT 与 FM 均定义 SYNTHESIS 关掉
VCS += +define+SYNTHESIS

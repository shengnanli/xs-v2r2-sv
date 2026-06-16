MODULE = DuplicatedTagArray

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# Tag SRAM 黑盒链: TagArray -> TagSRAMBank -> SRAMTemplate_114 -> 厂商宏 -> array_9
SRAM_SRCS = $(GOLDEN_RTL)/TagArray.sv \
            $(GOLDEN_RTL)/TagSRAMBank.sv \
            $(GOLDEN_RTL)/SRAMTemplate_114.sv \
            $(GOLDEN_RTL)/sram_array_1p256x86m43s1h0l1b_dcsh_tag.sv \
            $(GOLDEN_RTL)/array_9.sv $(GOLDEN_RTL)/array_9_ext.v \
            $(GOLDEN_RTL)/MbistClockGateCell.sv $(GOLDEN_RTL)/ClockGate.sv
MBIST_SRCS = $(GOLDEN_RTL)/MbistPipeDcacheTag.sv

# 手写可读核 + pkg
RTL_SRCS = $(RTL_DIR)/memblock/dtagarray_pkg.sv $(RTL_DIR)/memblock/DuplicatedTagArray.sv
# golden 同名 wrapper (仅 FM 用)
WRAPPER_SRCS = $(RTL_DIR)/memblock/DuplicatedTagArray_wrapper.sv
# UT 双例化: golden 顶层 + _xs 镜像, 两侧共用 golden TagArray/Mbist/SRAM 黑盒
GOLDEN_SRCS = $(GOLDEN_RTL)/DuplicatedTagArray.sv $(SRAM_SRCS) $(MBIST_SRCS)
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = DuplicatedTagArray
# ref 侧不提供 TagArray/Mbist/SRAM RTL, 经 black_box 当黑盒, 两侧对称
FM_REF_DEPS_DuplicatedTagArray =

include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

MODULE = PMP
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/pmp_pkg.sv $(RTL_DIR)/memblock/PMP.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/PMP_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/PMP.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = PMP
# PMA 的 16 个 mask 寄存器低 12 位恒为 0xFFF（NAPOT 粒度），merge-dup pass 会把这些
# 常量位跨条目误并、并在 wrapper/u_core 层次边界两侧做不对称常量传播，导致两个输出
# 端口 io_pma_0/10_mask 误判 fail（寄存器本身全部等价）。关掉合并即干净比对。
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

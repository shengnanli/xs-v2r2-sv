MODULE = MemExeUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_MemExeUnit_core（纯组合透传壳 + Std store-data FU 子模块）
RTL_SRCS = $(RTL_DIR)/memblock/MemExeUnit.sv
# WRAPPER_SRCS 仅用于 FM impl 侧(不进 UT 编译): 扁平端口包装 MemExeUnit +
# golden Std（两侧 elaborate 确定性纯组合子模块, 非厂商宏——impl 与 ref 同读同一子模块）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/MemExeUnit_wrapper.sv $(GOLDEN_RTL)/Std.sv
# golden 顶层 + 其唯一子模块 Std（UT 双例化两侧共用同一定义）
GOLDEN_SRCS = $(GOLDEN_RTL)/MemExeUnit.sv $(GOLDEN_RTL)/Std.sv
# UT 变体（impl 顶层改名 MemExeUnit_xs 以与 golden MemExeUnit 双例化）
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 MemExeUnit 顶层；Std 两侧 elaborate 作为共同子模块
FM_VARIANTS = MemExeUnit
FM_REF_DEPS_MemExeUnit = Std.sv

include ../../../scripts/ut_common.mk

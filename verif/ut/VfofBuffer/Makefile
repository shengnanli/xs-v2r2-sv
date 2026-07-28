MODULE = VfofBuffer

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写 SV: 可读核 xs_VfofBuffer_core(+ pkg) + 扁平端口包装 VfofBuffer(_xs)
RTL_SRCS = $(RTL_DIR)/memblock/vfofbuffer_pkg.sv $(RTL_DIR)/memblock/VfofBuffer.sv
# WRAPPER_SRCS 仅 FM impl 顶层(不进 UT 编译): 扁平端口包装 VfofBuffer
WRAPPER_SRCS = $(RTL_DIR)/memblock/VfofBuffer_wrapper.sv
# golden 顶层(无子模块)
GOLDEN_SRCS = $(GOLDEN_RTL)/VfofBuffer.sv
# UT 变体(impl 顶层改名 VfofBuffer_xs 与 golden 双例化)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 VfofBuffer 顶层, 无依赖(自包含单条目缓冲, 0 子模块 0 黑盒)
FM_VARIANTS = VfofBuffer

include ../../../scripts/ut_common.mk

# golden VfofBuffer 含 `ifndef SYNTHESIS 断言(LogUtils assert); UT 随机激励会触发,
# 定义 SYNTHESIS 关掉(同时关随机初值注入, 两侧复位到 0 后同构)。
VCS += +define+SYNTHESIS

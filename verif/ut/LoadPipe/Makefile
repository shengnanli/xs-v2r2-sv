MODULE = LoadPipe

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 = loadpipe_pkg + LoadPipe(xs_LoadPipe_core 拼接体)
RTL_SRCS = $(RTL_DIR)/memblock/loadpipe_pkg.sv $(RTL_DIR)/memblock/LoadPipe.sv
# WRAPPER_SRCS 进入 FM 的 impl 侧(golden 同名直通核)。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadPipe_wrapper.sv
# golden 顶层 LoadPipe 无子模块例化，UT 直接读 golden LoadPipe.sv。
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadPipe.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = LoadPipe

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 的随机初始化/断言，UT 随机激励下定义 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS

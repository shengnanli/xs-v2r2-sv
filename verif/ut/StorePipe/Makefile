MODULE = StorePipe

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 = storepipe_pkg + StorePipe(xs_StorePipe_core 完整三级流水)
RTL_SRCS = $(RTL_DIR)/memblock/storepipe_pkg.sv $(RTL_DIR)/memblock/StorePipe.sv
# WRAPPER_SRCS 进入 FM 的 impl 侧(golden 同名裁剪接口直通)。
WRAPPER_SRCS = $(RTL_DIR)/memblock/StorePipe_wrapper.sv
# golden 顶层 StorePipe 本配置仅 1 端口、无子模块。
GOLDEN_SRCS = $(GOLDEN_RTL)/StorePipe.sv
TB_SRCS = variants_xs.sv tb.sv

FM_VARIANTS = StorePipe

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

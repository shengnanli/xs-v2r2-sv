MODULE = PipelineConnectPipe

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核(UT + FM 两侧都用)。
RTL_SRCS = $(RTL_DIR)/backend/PipelineConnectPipe_core.sv

# UT 用 _xs 变体(golden 同名 PipelineConnectPipe 从 GOLDEN_SRCS 例化, 避免撞名)。
TB_SRCS = variants_xs.sv tb.sv

# golden 顶层(纯叶子, 无子模块)。
GOLDEN_SRCS = $(GOLDEN_RTL)/PipelineConnectPipe.sv

# FM: golden PipelineConnectPipe vs 手写同名 wrapper(仅 FM 用, 不进 UT 编译免撞名)。
WRAPPER_SRCS = $(RTL_DIR)/backend/PipelineConnectPipe_wrapper.sv
FM_VARIANTS = PipelineConnectPipe

include ../../../scripts/ut_common.mk

VCS += +define+SYNTHESIS

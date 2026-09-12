MODULE = FAlu

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FAlu.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# FloatAdder 及其闭包（fudian 浮点加法器，不是本轮重写目标）：
# 已逐字节核对 G0 与 G1 这 19 个文件完全一致，故两侧同源 elaborate，不设黑盒。
FALU_LEAVES = FloatAdder.sv \
              FloatAdderF64Pipeline.sv FloatAdderF32F16MixedPipeline.sv \
              FarPathFloatAdderF64WidenPipeline.sv FarPathAdderF64WidenPipeline.sv \
              FarPathF32WidenF16MixedPipeline.sv FarPathF32WidenF16MixedAdderPipeline.sv \
              FarShiftRightWithMuxInvFirst.sv FarShiftRightWithMuxInvFirst_2.sv \
              ClosePathFloatAdderF64WidenPipeline.sv ClosePathAdder.sv ClosePathAdder_2.sv \
              ClosePathF32WidenF16MixedPipeline.sv \
              ClosePathF32WidenF16MixedPipelineAdder.sv \
              ClosePathF32WidenF16MixedPipelineAdder_2.sv \
              CloseShiftLeftWithMux.sv CloseShiftLeftWithMux_1.sv \
              Adder.sv Adder_2.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FAlu.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FALU_LEAVES))

FM_VARIANTS = FAlu
FM_REF_DEPS_FAlu = $(FALU_LEAVES)

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块调用未定义函数 xs_assert_v2，
# 且随机初始化 initial 块也只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
VCS += +define+SYNTHESIS

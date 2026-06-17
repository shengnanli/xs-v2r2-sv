MODULE = FAlu

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包（核内例化 golden 同名 FloatAdder 黑盒）
RTL_SRCS = $(RTL_DIR)/backend/falu_pkg.sv \
           $(RTL_DIR)/backend/FAlu.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 浮点加法器 FloatAdder 及其全部叶子（两侧 UT 共用同一份实现）。
FADD_DEPS = FloatAdder.sv \
  Adder.sv Adder_2.sv ClosePathAdder.sv ClosePathAdder_2.sv \
  ClosePathF32WidenF16MixedPipeline.sv ClosePathF32WidenF16MixedPipelineAdder.sv \
  ClosePathF32WidenF16MixedPipelineAdder_2.sv ClosePathFloatAdderF64WidenPipeline.sv \
  CloseShiftLeftWithMux.sv CloseShiftLeftWithMux_1.sv \
  FarPathAdderF64WidenPipeline.sv FarPathF32WidenF16MixedAdderPipeline.sv \
  FarPathF32WidenF16MixedPipeline.sv FarPathFloatAdderF64WidenPipeline.sv \
  FarShiftRightWithMuxInvFirst.sv FarShiftRightWithMuxInvFirst_2.sv \
  FloatAdderF32F16MixedPipeline.sv FloatAdderF64Pipeline.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FAlu.sv $(addprefix $(GOLDEN_RTL)/,$(FADD_DEPS))

# FM：golden 顶层 FAlu vs 手写同名 wrapper（→ 可读核）。加法器两侧共享同一实现。
WRAPPER_SRCS = $(RTL_DIR)/backend/FAlu_wrapper.sv $(addprefix $(GOLDEN_RTL)/,$(FADD_DEPS))
FM_VARIANTS = FAlu
FM_REF_DEPS_FAlu = $(FADD_DEPS)

# 关闭 FM 合并同值重复寄存器：加法器内部流水寄存器在 golden 顶层 / wrapper→u_core
# 两种层次下会被不对称常量传播误判，关掉后两侧黑盒按名一一配对（同 MulUnit）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError 等非综合断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS

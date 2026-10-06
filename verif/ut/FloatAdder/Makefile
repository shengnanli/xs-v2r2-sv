# 由 tools/kimi_lane.py 按模板生成（KIMI 只提供源清单）
MODULE = FloatAdder
RTL_SRCS = $(addprefix ../../../,rtl/backend/Adder.sv rtl/backend/FarShiftRightWithMuxInvFirst.sv rtl/backend/FarPathAdderF64WidenPipeline.sv rtl/backend/FarPathFloatAdderF64WidenPipeline.sv rtl/backend/ClosePathAdder.sv rtl/backend/ClosePathAdder_2.sv rtl/backend/CloseShiftLeftWithMux.sv rtl/backend/ClosePathFloatAdderF64WidenPipeline.sv rtl/backend/FloatAdderF64Pipeline.sv rtl/backend/Adder_2.sv rtl/backend/FarShiftRightWithMuxInvFirst_2.sv rtl/backend/FarPathF32WidenF16MixedAdderPipeline.sv rtl/backend/FarPathF32WidenF16MixedPipeline.sv rtl/backend/ClosePathF32WidenF16MixedPipelineAdder.sv rtl/backend/ClosePathF32WidenF16MixedPipelineAdder_2.sv rtl/backend/CloseShiftLeftWithMux_1.sv rtl/backend/ClosePathF32WidenF16MixedPipeline.sv rtl/backend/FloatAdderF32F16MixedPipeline.sv rtl/backend/FloatAdder.sv)
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,)
TB_SRCS  = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,FloatAdder.sv Adder.sv Adder_2.sv ClosePathAdder.sv ClosePathAdder_2.sv ClosePathF32WidenF16MixedPipeline.sv ClosePathF32WidenF16MixedPipelineAdder.sv ClosePathF32WidenF16MixedPipelineAdder_2.sv ClosePathFloatAdderF64WidenPipeline.sv CloseShiftLeftWithMux.sv CloseShiftLeftWithMux_1.sv FarPathAdderF64WidenPipeline.sv FarPathF32WidenF16MixedAdderPipeline.sv FarPathF32WidenF16MixedPipeline.sv FarPathFloatAdderF64WidenPipeline.sv FarShiftRightWithMuxInvFirst.sv FarShiftRightWithMuxInvFirst_2.sv FloatAdderF32F16MixedPipeline.sv FloatAdderF64Pipeline.sv)
FM_VARIANTS = FloatAdder
FM_REF_DEPS_FloatAdder = Adder.sv Adder_2.sv ClosePathAdder.sv ClosePathAdder_2.sv ClosePathF32WidenF16MixedPipeline.sv ClosePathF32WidenF16MixedPipelineAdder.sv ClosePathF32WidenF16MixedPipelineAdder_2.sv ClosePathFloatAdderF64WidenPipeline.sv CloseShiftLeftWithMux.sv CloseShiftLeftWithMux_1.sv FarPathAdderF64WidenPipeline.sv FarPathF32WidenF16MixedAdderPipeline.sv FarPathF32WidenF16MixedPipeline.sv FarPathFloatAdderF64WidenPipeline.sv FarShiftRightWithMuxInvFirst.sv FarShiftRightWithMuxInvFirst_2.sv FloatAdderF32F16MixedPipeline.sv FloatAdderF64Pipeline.sv
FM_MERGE_DUP = false
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true
PORTLINT_ORDER = fail
include ../../../scripts/ut_common.mk
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

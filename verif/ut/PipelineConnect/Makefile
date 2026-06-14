MODULE = PipelineConnect

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/PipelineConnect.sv
WRAPPER_SRCS = $(RTL_DIR)/common/PipelineConnect_variants.sv
TB_SRCS = variants_xs.sv tb.sv

GOLDEN_RTL = ../../../golden/chisel-rtl
VARIANTS = NewPipelineConnectPipe NewPipelineConnectPipe_1 NewPipelineConnectPipe_5 \
           NewPipelineConnectPipe_7 NewPipelineConnectPipe_8 NewPipelineConnectPipe_9 \
           NewPipelineConnectPipe_10 NewPipelineConnectPipe_13 NewPipelineConnectPipe_14 \
           NewPipelineConnectPipe_16 NewPipelineConnectPipe_18 NewPipelineConnectPipe_20 \
           NewPipelineConnectPipe_23 NewPipelineConnectPipe_25 NewPipelineConnectPipe_27 \
           NewPipelineConnectPipe_31 NewPipelineConnectPipe_32 NewPipelineConnectPipe_33
GOLDEN_SRCS = $(addsuffix .sv,$(addprefix $(GOLDEN_RTL)/,$(VARIANTS)))

FM_VARIANTS = $(VARIANTS)
# 各变体 golden 无子模块依赖，FM_REF_DEPS_* 全为空

include ../../../scripts/ut_common.mk

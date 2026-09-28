MODULE = ReadableLeaves15
RTL_DIR = ../../../rtl
LEAVES = Adder Adder_2 SubModule AddModule ConditionalZeroModule \
 UIntCompressor_27_000000000000001010100000000 \
 UIntCompressor_27_000011100000000000001010101 \
 UIntExtractor_27_000000000000001010100000000 \
 UIntExtractor_27_000011100000000000001010101 \
 ClosePathAdder ClosePathAdder_2 ClosePathAdderF16Pipeline \
 ClosePathAdderF16Pipeline_2 ClosePathF32WidenF16MixedPipelineAdder \
 ClosePathF32WidenF16MixedPipelineAdder_2
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS = tb.sv
G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))
FM_VARIANTS = $(LEAVES)
include ../../../scripts/ut_common.mk
VCS += +define+SYNTHESIS

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
# 两轮 initreg（CONVENTIONS「+vcs+initreg 的正确用法」）：编译期打开机制，运行期选取值。
# 本 UT 是 golden 与 *_xs 双例化：+vcs+initreg+random 会给两个实例各摇各的初值，
# 不复位寄存器两侧初态不同 => 假失配。所以两档用常量：make run INITREG=0 / INITREG=1。
VCS += +define+SYNTHESIS +vcs+initreg+random
INITREG ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

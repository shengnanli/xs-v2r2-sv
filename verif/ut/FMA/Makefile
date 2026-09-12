MODULE = FMA

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FMA.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl

# FloatFMA 及其闭包（fudian 乘加阵列，不是本轮重写目标）：两侧同源 elaborate，不设黑盒。
# 注意 FloatFMA 是 G0->G1 唯一有变化的一个：firtool 把
#   {|io_fp_a[62:52], io_fp_a[51:0]} 提成了具名 wire fp_a_significand_f64（b 源同理），
# 5 处引用改成引用该 wire，纯 CSE，逻辑不变（已逐行 diff 确认）。
# 其余 4 个（BoothEncoder / CSA*）G0 与 G1 逐字节一致。
FMA_LEAVES = FloatFMA.sv BoothEncoderF64F32F16.sv \
             CSA_Nto2With3to2MainPipeline.sv CSA4to2.sv CSA3to2.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FMA.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FMA_LEAVES))

FM_VARIANTS = FMA
FM_REF_DEPS_FMA = $(FMA_LEAVES)

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块调用未定义函数 xs_assert_v2，
# 且随机初始化 initial 块也只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
VCS += +define+SYNTHESIS

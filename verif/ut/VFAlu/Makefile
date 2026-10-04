MODULE = VFAlu

# 向量浮点 ALU FU 外壳（VecPipedFuncUnit，LAT=1：两个 VectorFloatAdder + 归约掩码 / vl 修正 / 旧 vd 移位 + Mgu / Mgtu + fflags 选择），
# vector-fu lane。
# child 处置（各自 receipt；全部两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件）：
#   VectorFloatAdder（本 lane §6）及其全部闭包（FloatAdderWidenFormat + ShiftLeftPriority*、F32WidenF16Mixed / F64Widen / F16 三种 lane
#   及其 far / close 闭包）；VecDataSplitModule（本 lane）；Mgu（evidence/d09e1997840f）+ ByteMaskTailGen / UIntToContLow1s /
#   UIntToContLow0s / MaskExtractor；Mgtu（evidence/cb2892a30a11）。impl 侧另有共享辅助件 rtl/common/xs_VecFflagsElemMask.sv。
# tb 另带按元素的独立 IEEE oracle（vfadd / vfsub / vfmin / vfmax / vfmerge 与加宽加减；含 mask / tail / vstart / vl=0 与 fflags 元素选择）。
RTL_DIR  = ../../../rtl
F16_TREE = Adder_18 FarShiftRightWithMuxInvFirst_18 FarPathAdderF16Pipeline FarPathF16Pipeline \
           ClosePathAdderF16Pipeline ClosePathAdderF16Pipeline_2 CloseShiftLeftWithMux_9 ClosePathF16Pipeline \
           FloatAdderF16Pipeline
F32_TREE = Adder_2 FarShiftRightWithMuxInvFirst_2 FarPathF32WidenF16MixedAdderPipeline FarPathF32WidenF16MixedPipeline \
           ClosePathF32WidenF16MixedPipelineAdder ClosePathF32WidenF16MixedPipelineAdder_2 CloseShiftLeftWithMux_1 \
           ClosePathF32WidenF16MixedPipeline FloatAdderF32WidenF16MixedPipeline
F64_TREE = Adder FarShiftRightWithMuxInvFirst FarPathAdderF64WidenPipeline FarPathFloatAdderF64WidenPipeline \
           ClosePathAdder ClosePathAdder_2 CloseShiftLeftWithMux ClosePathFloatAdderF64WidenPipeline \
           FloatAdderF64WidenPipeline
FMT_TREE = ShiftLeftPriorityWithF32EXPResult ShiftLeftPriorityWithF64EXPResult FloatAdderWidenFormat
MGU_TREE = UIntToContLow1s UIntToContLow0s MaskExtractor ByteMaskTailGen Mgu Mgtu
CHILDREN = $(FMT_TREE) $(F16_TREE) $(F32_TREE) $(F64_TREE) VectorFloatAdder VecDataSplitModule $(MGU_TREE)
TARGETS  = VFAlu
RTL_SRCS = $(RTL_DIR)/common/xs_VecFflagsElemMask.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = ../FpAddPathF64W/fp_add_oracle_pkg.sv tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = VFAlu
FM_REF_DEPS_VFAlu = ShiftLeftPriorityWithF32EXPResult.sv ShiftLeftPriorityWithF64EXPResult.sv FloatAdderWidenFormat.sv \
    Adder_18.sv FarShiftRightWithMuxInvFirst_18.sv FarPathAdderF16Pipeline.sv FarPathF16Pipeline.sv \
    ClosePathAdderF16Pipeline.sv ClosePathAdderF16Pipeline_2.sv CloseShiftLeftWithMux_9.sv ClosePathF16Pipeline.sv \
    FloatAdderF16Pipeline.sv \
    Adder_2.sv FarShiftRightWithMuxInvFirst_2.sv FarPathF32WidenF16MixedAdderPipeline.sv FarPathF32WidenF16MixedPipeline.sv \
    ClosePathF32WidenF16MixedPipelineAdder.sv ClosePathF32WidenF16MixedPipelineAdder_2.sv CloseShiftLeftWithMux_1.sv \
    ClosePathF32WidenF16MixedPipeline.sv FloatAdderF32WidenF16MixedPipeline.sv \
    Adder.sv FarShiftRightWithMuxInvFirst.sv FarPathAdderF64WidenPipeline.sv FarPathFloatAdderF64WidenPipeline.sv \
    ClosePathAdder.sv ClosePathAdder_2.sv CloseShiftLeftWithMux.sv ClosePathFloatAdderF64WidenPipeline.sv \
    FloatAdderF64WidenPipeline.sv VectorFloatAdder.sv VecDataSplitModule.sv \
    UIntToContLow1s.sv UIntToContLow0s.sv MaskExtractor.sv ByteMaskTailGen.sv Mgu.sv Mgtu.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 编译期打开 initreg 机制，取值在运行期选（两处缺一不可）。三档：
#   INITREG=0 / INITREG=random（seed 1 下退化为全 1）/ INITREG=<seed>017（真随机数值种子）
INITREG  ?= 0
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

MODULE = VectorFloatAdder

# 向量浮点加法单元（64 位一组：1×f64 / 2×f32 / 4×f16 五条运算 lane + 三个加宽格式化件 + 折叠路由），vector-fu lane。
# child 处置（各自 receipt；全部两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件）：
#   FloatAdderWidenFormat（evidence/d65d2da418a4）+ ShiftLeftPriorityWithF32EXPResult / ShiftLeftPriorityWithF64EXPResult；
#   FloatAdderF32WidenF16MixedPipeline（evidence/194f78e14165）+ far/close 闭包 8 件；
#   FloatAdderF64WidenPipeline（本 lane）+ far/close 闭包 8 件；
#   FloatAdderF16Pipeline（evidence/6038c4afbc60）+ far/close 闭包 8 件。
# tb 另带按元素的独立 IEEE oracle（加减含加宽、min/max、比较；复用 verif/ut/FpAddPathF64W/fp_add_oracle_pkg.sv）。
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
CHILDREN = $(FMT_TREE) $(F16_TREE) $(F32_TREE) $(F64_TREE)
TARGETS  = VectorFloatAdder
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = ../FpAddPathF64W/fp_add_oracle_pkg.sv tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = VectorFloatAdder
FM_REF_DEPS_VectorFloatAdder = ShiftLeftPriorityWithF32EXPResult.sv ShiftLeftPriorityWithF64EXPResult.sv \
    FloatAdderWidenFormat.sv \
    Adder_18.sv FarShiftRightWithMuxInvFirst_18.sv FarPathAdderF16Pipeline.sv FarPathF16Pipeline.sv \
    ClosePathAdderF16Pipeline.sv ClosePathAdderF16Pipeline_2.sv CloseShiftLeftWithMux_9.sv ClosePathF16Pipeline.sv \
    FloatAdderF16Pipeline.sv \
    Adder_2.sv FarShiftRightWithMuxInvFirst_2.sv FarPathF32WidenF16MixedAdderPipeline.sv FarPathF32WidenF16MixedPipeline.sv \
    ClosePathF32WidenF16MixedPipelineAdder.sv ClosePathF32WidenF16MixedPipelineAdder_2.sv CloseShiftLeftWithMux_1.sv \
    ClosePathF32WidenF16MixedPipeline.sv FloatAdderF32WidenF16MixedPipeline.sv \
    Adder.sv FarShiftRightWithMuxInvFirst.sv FarPathAdderF64WidenPipeline.sv FarPathFloatAdderF64WidenPipeline.sv \
    ClosePathAdder.sv ClosePathAdder_2.sv CloseShiftLeftWithMux.sv ClosePathFloatAdderF64WidenPipeline.sv \
    FloatAdderF64WidenPipeline.sv

# 关 merge_dup：lane 内有同源多份寄存器，重写件逐份照抄；关掉后逐个比，fm_predict 的模型严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：unread 点是五条 lane 子树里两侧对称的死位（本目录 fm_pins.tcl 字面钉 17 对后实比），
# 依据见 verif/fm_target_config/VectorFloatAdder.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部 RegEnable(fire) 不复位：tb 只在出现过一次 fire 之后比（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

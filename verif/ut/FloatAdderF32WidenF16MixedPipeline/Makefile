MODULE = FloatAdderF32WidenF16MixedPipeline

# FloatAdderF32WidenF16MixedPipeline（f32/f16/加宽混合浮点加法器 lane，两拍流水）。
# golden 直接 child：FarPathF32WidenF16MixedPipeline / ClosePathF32WidenF16MixedPipeline ——
#   coverage_three_axis.tsv 标 MISSING + PROVEN_IN_CONE（本仓没有重写件，只在 FAlu 的闭包里被同源证过）。
#   处置照 verif/ut/FAlu 先例：这两件及其孙子（FarPathF32WidenF16MixedAdderPipeline /
#   FarShiftRightWithMuxInvFirst_2 / Adder_2 / ClosePathF32WidenF16MixedPipelineAdder(_2) /
#   CloseShiftLeftWithMux_1）两侧**同读 golden**（RTL_GOLDEN_DEPS 与 FM_REF_DEPS 同一列表），
#   不设黑盒。★这不是"child 已重写"：本证明覆盖的是顶层 glue + 第 0/1 拍的全部控制与比较逻辑，
#   far/close 两条数据路径的内部是 golden 对 golden。★
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/FloatAdderF32WidenF16MixedPipeline.sv
TB_SRCS  = tb.sv

FPADD_GOLDEN_SUBTREE = FarPathF32WidenF16MixedPipeline.sv \
                       FarPathF32WidenF16MixedAdderPipeline.sv \
                       FarShiftRightWithMuxInvFirst_2.sv \
                       Adder_2.sv \
                       ClosePathF32WidenF16MixedPipeline.sv \
                       ClosePathF32WidenF16MixedPipelineAdder.sv \
                       ClosePathF32WidenF16MixedPipelineAdder_2.sv \
                       CloseShiftLeftWithMux_1.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FloatAdderF32WidenF16MixedPipeline.sv
RTL_GOLDEN_DEPS = $(addprefix $(GOLDEN_RTL)/,$(FPADD_GOLDEN_SUBTREE))

FM_VARIANTS = FloatAdderF32WidenF16MixedPipeline
FM_REF_DEPS_FloatAdderF32WidenF16MixedPipeline = $(FPADD_GOLDEN_SUBTREE)

# 关 merge_dup：golden 顶层有两份同源打拍（io_fp_c_r / io_fflags_r）等，关掉后 fm_predict 模型严格适用
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：3 个 unread 点全在两侧同读的 golden 子树里，依据见 verif/fm_target_config/FloatAdderF32WidenF16MixedPipeline.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器 RegEnable(fire) 不复位：+random 档两侧初值不同，tb 在两次 fire 之后才开始比对（见 tb.sv）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

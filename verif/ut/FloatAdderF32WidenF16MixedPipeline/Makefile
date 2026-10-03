MODULE = FloatAdderF32WidenF16MixedPipeline

# FloatAdderF32WidenF16MixedPipeline（f32/f16/加宽混合浮点加法器 lane，两拍流水）。
# golden 直接 child：FarPathF32WidenF16MixedPipeline / ClosePathF32WidenF16MixedPipeline 及其孙子
#   （FarPathF32WidenF16MixedAdderPipeline / FarShiftRightWithMuxInvFirst_2 / Adder_2 /
#   ClosePathF32WidenF16MixedPipelineAdder(_2) / CloseShiftLeftWithMux_1）——全部已有本仓重写件并各自签核
#   （far/close 两条路径与切段加法器由 fpaddpath-sqrtblock lane 签核，verif/ut/FpAddPathF32W16）。
#   → 两侧白盒：ref 读 golden 同名件（FM_REF_DEPS），impl 读重写件（RTL_SRCS）。无黑盒、无两侧同读 golden 的文件。
#   （此前 fpaddpath-sqrtblock 之前这棵子树两侧同读 golden，见 evidence/2c59d6196113 那一版。）
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/Adder_2.sv \
           $(RTL_DIR)/backend/FarShiftRightWithMuxInvFirst_2.sv \
           $(RTL_DIR)/backend/FarPathF32WidenF16MixedAdderPipeline.sv \
           $(RTL_DIR)/backend/FarPathF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipelineAdder.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipelineAdder_2.sv \
           $(RTL_DIR)/backend/CloseShiftLeftWithMux_1.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/FloatAdderF32WidenF16MixedPipeline.sv
TB_SRCS  = tb.sv

FPADD_GOLDEN_SUBTREE = FarPathF32WidenF16MixedPipeline.sv \
                       FarPathF32WidenF16MixedAdderPipeline.sv \
                       FarShiftRightWithMuxInvFirst_2.sv \
                       Adder_2.sv \
                       ClosePathF32WidenF16MixedPipeline.sv \
                       ClosePathF32WidenF16MixedPipelineAdder.sv \
                       ClosePathF32WidenF16MixedPipelineAdder_2.sv \
                       CloseShiftLeftWithMux_1.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/FloatAdderF32WidenF16MixedPipeline.sv $(addprefix $(GOLDEN_RTL)/,$(FPADD_GOLDEN_SUBTREE))

FM_VARIANTS = FloatAdderF32WidenF16MixedPipeline
# FM_REF_DEPS 写字面名（scripts/fm_predict.py 按字面解析）
FM_REF_DEPS_FloatAdderF32WidenF16MixedPipeline = FarPathF32WidenF16MixedPipeline.sv \
    FarPathF32WidenF16MixedAdderPipeline.sv FarShiftRightWithMuxInvFirst_2.sv Adder_2.sv \
    ClosePathF32WidenF16MixedPipeline.sv ClosePathF32WidenF16MixedPipelineAdder.sv \
    ClosePathF32WidenF16MixedPipelineAdder_2.sv CloseShiftLeftWithMux_1.sv

# 关 merge_dup：golden 顶层有两份同源打拍（io_fp_c_r / io_fflags_r）等，关掉后 fm_predict 模型严格适用
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：far/close 子树里两侧对称的死位（子树改读重写件后名字不同，由本目录 fm_pins.tcl
# 字面钉对再实比），依据见 verif/fm_target_config/FloatAdderF32WidenF16MixedPipeline.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器 RegEnable(fire) 不复位：+random 档两侧初值不同，tb 在两次 fire 之后才开始比对（见 tb.sv）。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

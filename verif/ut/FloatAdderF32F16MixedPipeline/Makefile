MODULE = FloatAdderF32F16MixedPipeline

# FloatAdderF32F16MixedPipeline（标量 FPU 的 f32/f16 浮点加减 + 比较类，两拍流水；fpu-parents lane，group adder64）。
# golden 直接 child：FarPathF32WidenF16MixedPipeline / ClosePathF32WidenF16MixedPipeline 及其孙子
#   （FarPathF32WidenF16MixedAdderPipeline / FarShiftRightWithMuxInvFirst_2 / Adder_2 /
#   ClosePathF32WidenF16MixedPipelineAdder(_2) / CloseShiftLeftWithMux_1）——全部已有本仓重写件并各自签核
#   （far/close 两条路径由 fpaddpath-sqrtblock lane 签核，evidence/1a44b00c0b57；孙子 PROVEN_DIRECT）。
#   → 两侧白盒：ref 读 golden 同名件（FM_REF_DEPS），impl 读重写件（RTL_SRCS）。无黑盒、无两侧同读 golden 的文件。
# tb 带独立 IEEE oracle（../FpAddPathF64W/fp_add_oracle_pkg.sv + tb 内比较类模型）。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/Adder_2.sv \
           $(RTL_DIR)/backend/FarShiftRightWithMuxInvFirst_2.sv \
           $(RTL_DIR)/backend/FarPathF32WidenF16MixedAdderPipeline.sv \
           $(RTL_DIR)/backend/FarPathF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipelineAdder.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipelineAdder_2.sv \
           $(RTL_DIR)/backend/CloseShiftLeftWithMux_1.sv \
           $(RTL_DIR)/backend/ClosePathF32WidenF16MixedPipeline.sv \
           $(RTL_DIR)/backend/FloatAdderF32F16MixedPipeline.sv
TB_SRCS  = ../FpAddPathF64W/fp_add_oracle_pkg.sv tb.sv

FPADD_GOLDEN_SUBTREE = FarPathF32WidenF16MixedPipeline.sv \
                       FarPathF32WidenF16MixedAdderPipeline.sv \
                       FarShiftRightWithMuxInvFirst_2.sv \
                       Adder_2.sv \
                       ClosePathF32WidenF16MixedPipeline.sv \
                       ClosePathF32WidenF16MixedPipelineAdder.sv \
                       ClosePathF32WidenF16MixedPipelineAdder_2.sv \
                       CloseShiftLeftWithMux_1.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/FloatAdderF32F16MixedPipeline.sv $(addprefix $(GOLDEN_RTL)/,$(FPADD_GOLDEN_SUBTREE))

FM_VARIANTS = FloatAdderF32F16MixedPipeline
# FM_REF_DEPS 写字面名（scripts/fm_predict.py 按字面解析）
FM_REF_DEPS_FloatAdderF32F16MixedPipeline = FarPathF32WidenF16MixedPipeline.sv \
    FarPathF32WidenF16MixedAdderPipeline.sv FarShiftRightWithMuxInvFirst_2.sv Adder_2.sv \
    ClosePathF32WidenF16MixedPipeline.sv ClosePathF32WidenF16MixedPipelineAdder.sv \
    ClosePathF32WidenF16MixedPipelineAdder_2.sv CloseShiftLeftWithMux_1.sv

# 关 merge_dup：golden 顶层有同源双份打拍（io_fp_c_r / io_fflags_r、fadd0_result0 两份等），重写件逐份照抄；
# 关掉后逐个比，fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：far/close 子树里两侧对称的死位（本目录 fm_pins.tcl 字面钉对再实比），
# 依据见 verif/fm_target_config/FloatAdderF32F16MixedPipeline.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 全部寄存器 RegEnable(fire) 不复位：tb 在第一次 fire 之后才开始比（见 tb.sv）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

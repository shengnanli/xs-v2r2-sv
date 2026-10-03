MODULE = FpAddPathF32W16

# f32/f16 混合浮点加法器的 far / close 两条两拍流水路径（fpaddpath-sqrtblock lane）：
#   FarPathF32WidenF16MixedAdderPipeline（far path 内的切段进位加法器）
#   FarPathF32WidenF16MixedPipeline      （far path 本体）
#   ClosePathF32WidenF16MixedPipeline    （close path 本体）
# child 处置（docs/coverage_three_axis.tsv 第 3 列）：Adder_2 / FarShiftRightWithMuxInvFirst_2 /
#   ClosePathF32WidenF16MixedPipelineAdder(_2) / CloseShiftLeftWithMux_1 均 REWRITTEN + PROVEN_DIRECT
#   → 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
CHILDREN = Adder_2 FarShiftRightWithMuxInvFirst_2 \
           ClosePathF32WidenF16MixedPipelineAdder ClosePathF32WidenF16MixedPipelineAdder_2 \
           CloseShiftLeftWithMux_1
TARGETS  = FarPathF32WidenF16MixedAdderPipeline FarPathF32WidenF16MixedPipeline \
           ClosePathF32WidenF16MixedPipeline
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FarPathF32WidenF16MixedAdderPipeline FarPathF32WidenF16MixedPipeline \
              ClosePathF32WidenF16MixedPipeline
FM_REF_DEPS_FarPathF32WidenF16MixedAdderPipeline =
FM_REF_DEPS_FarPathF32WidenF16MixedPipeline = Adder_2.sv FarShiftRightWithMuxInvFirst_2.sv \
                                              FarPathF32WidenF16MixedAdderPipeline.sv
FM_REF_DEPS_ClosePathF32WidenF16MixedPipeline = ClosePathF32WidenF16MixedPipelineAdder.sv \
                                                ClosePathF32WidenF16MixedPipelineAdder_2.sv \
                                                CloseShiftLeftWithMux_1.sv

# 关 merge_dup：golden 有同源双份寄存器（far 的两份 EOP 打拍、close 的两份 sel_CS4 / LZD），
# 重写件逐份照抄；关掉后逐个比，fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：仅 Far/Close 两个本体，各自的 unread 点是两侧对称的死位，
# 依据见 verif/fm_target_config/<top>.tcl；无 unread 的 AdderPipeline 不开。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = $(if $(filter FarPathF32WidenF16MixedPipeline ClosePathF32WidenF16MixedPipeline,$*),true,)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部 RegEnable(fire) 不复位：tb 只在出现过一次 fire 之后比（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

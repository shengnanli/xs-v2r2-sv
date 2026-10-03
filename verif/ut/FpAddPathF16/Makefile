MODULE = FpAddPathF16

# 纯 f16 浮点加法器的 far / close 两条两拍流水路径（fpu-parents lane，group adder16）：
#   FarPathF16Pipeline   （far path）
#   ClosePathF16Pipeline （close path）
# child 处置（docs/coverage_three_axis.tsv 第 3 列 + receipt）：Adder_18 / FarShiftRightWithMuxInvFirst_18 /
#   ClosePathAdderF16Pipeline(_2) / CloseShiftLeftWithMux_9 均 REWRITTEN + PROVEN_DIRECT；
#   FarPathAdderF16Pipeline 在 tsv 里仍记 MISSING/UNPROVEN（台账未刷新），但本仓已有重写件
#   rtl/backend/FarPathAdderF16Pipeline.sv 且 signoff-strict SUCCEEDED（evidence/1bf831352049/FarPathAdderF16Pipeline）。
#   → 全部两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
CHILDREN = Adder_18 FarShiftRightWithMuxInvFirst_18 FarPathAdderF16Pipeline \
           ClosePathAdderF16Pipeline ClosePathAdderF16Pipeline_2 CloseShiftLeftWithMux_9
TARGETS  = FarPathF16Pipeline ClosePathF16Pipeline
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FarPathF16Pipeline ClosePathF16Pipeline
FM_REF_DEPS_FarPathF16Pipeline = Adder_18.sv FarShiftRightWithMuxInvFirst_18.sv FarPathAdderF16Pipeline.sv
FM_REF_DEPS_ClosePathF16Pipeline = ClosePathAdderF16Pipeline.sv ClosePathAdderF16Pipeline_2.sv \
                                   CloseShiftLeftWithMux_9.sv

# 关 merge_dup：golden 有同源双份寄存器（far 的两份 EOP 打拍；close 的两份 sel_CS4 / EA / CS_0123），
# 重写件逐份照抄；关掉后逐个比，fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：仅 ClosePathF16Pipeline，unread 点是两侧对称死位（fm_pins.tcl 钉成对），
# 依据见 verif/fm_target_config/ClosePathF16Pipeline.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = $(if $(filter ClosePathF16Pipeline,$*),true,)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部 RegEnable(fire) 不复位：tb 只在出现过一次 fire 之后比（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

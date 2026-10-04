MODULE = FloatAdderF16Pipeline

# 纯 f16 浮点加法器顶层（far / close 两条路径 + min/max/比较/sgnj/fclass/merge/move/归约特判），backend-misc lane。
# child 处置（docs/coverage_three_axis.tsv 第 3 列）：FarPathF16Pipeline / ClosePathF16Pipeline 及其闭包
#   Adder_18 / FarShiftRightWithMuxInvFirst_18 / FarPathAdderF16Pipeline / ClosePathAdderF16Pipeline(_2) /
#   CloseShiftLeftWithMux_9 均 REWRITTEN + PROVEN_DIRECT → 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。
#   无黑盒、无两侧同读 golden 的文件。tb 另带独立 IEEE binary16 oracle（纯整数算术 + RISC-V 比较/分类语义）。
RTL_DIR  = ../../../rtl
CHILDREN = Adder_18 FarShiftRightWithMuxInvFirst_18 FarPathAdderF16Pipeline FarPathF16Pipeline \
           ClosePathAdderF16Pipeline ClosePathAdderF16Pipeline_2 CloseShiftLeftWithMux_9 ClosePathF16Pipeline
TARGETS  = FloatAdderF16Pipeline
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FloatAdderF16Pipeline
FM_REF_DEPS_FloatAdderF16Pipeline = Adder_18.sv FarShiftRightWithMuxInvFirst_18.sv FarPathAdderF16Pipeline.sv \
    FarPathF16Pipeline.sv ClosePathAdderF16Pipeline.sv ClosePathAdderF16Pipeline_2.sv \
    CloseShiftLeftWithMux_9.sv ClosePathF16Pipeline.sv

# 关 merge_dup：本体有同源双份寄存器（"走 far path" 两份、"加减类" 两份），child 里也有；重写件逐份照抄，
# 关掉后逐个比，fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：unread 点是 close 子树里两侧对称的死位（本目录 fm_pins.tcl 字面钉对后实比），
# 依据见 verif/fm_target_config/FloatAdderF16Pipeline.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部 RegEnable(fire) 不复位：tb 只在出现过一次 fire 之后比（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

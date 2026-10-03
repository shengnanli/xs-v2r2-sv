MODULE = FpAddPathF64W

# f64 浮点加法器的两个路径件（fpu-parents lane，group adder64）：
#   FarPathAdderF64WidenPipeline         （far path 内的 54 位打拍加法器，叶子）
#   ClosePathFloatAdderF64WidenPipeline  （f64 close path 本体）
# child 处置（docs/coverage_three_axis.tsv 第 3 列）：ClosePathAdder / ClosePathAdder_2 / CloseShiftLeftWithMux
#   均 REWRITTEN + PROVEN_DIRECT → 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
# tb 另带独立 IEEE oracle（fp_add_oracle_pkg.sv，纯整数算术）。
RTL_DIR  = ../../../rtl
CHILDREN = ClosePathAdder ClosePathAdder_2 CloseShiftLeftWithMux
TARGETS  = FarPathAdderF64WidenPipeline ClosePathFloatAdderF64WidenPipeline
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = fp_add_oracle_pkg.sv tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FarPathAdderF64WidenPipeline ClosePathFloatAdderF64WidenPipeline
FM_REF_DEPS_FarPathAdderF64WidenPipeline =
FM_REF_DEPS_ClosePathFloatAdderF64WidenPipeline = ClosePathAdder.sv ClosePathAdder_2.sv CloseShiftLeftWithMux.sv

# 关 merge_dup：golden close path 有同源多份寄存器（选中候选两份、sel_CS4 两份、EA 两份），重写件逐份照抄；
# 关掉后逐个比，fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：仅 close path，其 3 个 unread 点是两侧对称的死位（本目录 fm_pins.tcl 字面钉对后实比），
# 依据见 verif/fm_target_config/ClosePathFloatAdderF64WidenPipeline.tcl；无 unread 的加法器不开。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = $(if $(filter ClosePathFloatAdderF64WidenPipeline,$*),true,)

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部 RegEnable(fire) 不复位：tb 只在出现过一次 fire 之后比（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

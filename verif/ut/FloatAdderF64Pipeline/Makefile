MODULE = FloatAdderF64Pipeline

# 标量 f64 浮点加法器顶层（FloatAdder 的 f64 通路：far / close 两条路径 + min/max/比较/sgnj/fclass），vector-fu lane。
# child 处置（docs/coverage_three_axis.tsv 第 3 列 + 各自 receipt）：
#   FarPathFloatAdderF64WidenPipeline（evidence/6038c4afbc60）及其闭包 Adder / FarShiftRightWithMuxInvFirst /
#   FarPathAdderF64WidenPipeline；ClosePathFloatAdderF64WidenPipeline（evidence/5990b596a86b）及其闭包
#   ClosePathAdder / ClosePathAdder_2 / CloseShiftLeftWithMux —— 全部已签核 → 两侧白盒：ref 读 golden 同名件，
#   impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
# tb 另带独立 IEEE oracle：加减复用 verif/ut/FpAddPathF64W/fp_add_oracle_pkg.sv，比较/分类用本目录
#   fp64_misc_oracle_pkg.sv（纯整数算术，只给 tb 用）。
RTL_DIR  = ../../../rtl
CHILDREN = Adder FarShiftRightWithMuxInvFirst FarPathAdderF64WidenPipeline FarPathFloatAdderF64WidenPipeline \
           ClosePathAdder ClosePathAdder_2 CloseShiftLeftWithMux ClosePathFloatAdderF64WidenPipeline
TARGETS  = FloatAdderF64Pipeline
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = ../FpAddPathF64W/fp_add_oracle_pkg.sv fp64_misc_oracle_pkg.sv tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FloatAdderF64Pipeline
FM_REF_DEPS_FloatAdderF64Pipeline = Adder.sv FarShiftRightWithMuxInvFirst.sv FarPathAdderF64WidenPipeline.sv \
    FarPathFloatAdderF64WidenPipeline.sv ClosePathAdder.sv ClosePathAdder_2.sv CloseShiftLeftWithMux.sv \
    ClosePathFloatAdderF64WidenPipeline.sv

# 关 merge_dup：本体有同源双份寄存器（「加减类」两份），child 里也有；重写件逐份照抄，
# 关掉后逐个比，fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：unread 点是 close 子树里两侧对称的死位（本目录 fm_pins.tcl 字面钉对后实比），
# 依据见 verif/fm_target_config/FloatAdderF64Pipeline.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部 RegEnable(fire) 不复位：tb 只在出现过一次 fire 之后比（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

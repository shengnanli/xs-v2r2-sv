MODULE = FarPathFloatAdderF64WidenPipeline

# f64 浮点加法 far path 本体（backend-misc lane）。
# child 处置（docs/coverage_three_axis.tsv 第 3 列）：Adder / FarShiftRightWithMuxInvFirst / FarPathAdderF64WidenPipeline
#   均 REWRITTEN + PROVEN_DIRECT → 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
# tb 另带独立 IEEE oracle：复用 verif/ut/FpAddPathF64W/fp_add_oracle_pkg.sv（纯整数算术，只给 tb 用）。
RTL_DIR  = ../../../rtl
CHILDREN = Adder FarShiftRightWithMuxInvFirst FarPathAdderF64WidenPipeline
TARGETS  = FarPathFloatAdderF64WidenPipeline
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = ../FpAddPathF64W/fp_add_oracle_pkg.sv tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FarPathFloatAdderF64WidenPipeline
FM_REF_DEPS_FarPathFloatAdderF64WidenPipeline = Adder.sv FarShiftRightWithMuxInvFirst.sv FarPathAdderF64WidenPipeline.sv

# 关 merge_dup：sticky 原料按原码 / 反码各打一份 54 位寄存器（golden 原样），FS0 / FS1 两个加法器的 B 输入
# 寄存器也同源；重写件逐份照抄，关掉后逐个比，fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部 RegEnable(fire) 不复位：tb 只在出现过一次 fire 之后比寄存器驱动的输出（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

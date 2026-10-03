MODULE = BkuLeaves

# Bku 的四个运算叶子（fpu-parents lane）：CountModule / ClmulModule / MiscModule / HashModule。
#   全部是零子模块的叶子，无黑盒、无两侧同读 golden 的文件。
#   一个 tb 同测四对（golden vs <名>_xs）+ tb 内独立 oracle（按指令语义直接算）。
RTL_DIR  = ../../../rtl
TARGETS  = CountModule ClmulModule MiscModule HashModule
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = CountModule ClmulModule MiscModule HashModule
# 四者都没有 golden 依赖：FM_REF_DEPS_<名> 一律不写（CONVENTIONS：不写空赋值）。

# 关 merge_dup：逐个比寄存器，fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 寄存器全部 RegEnable 不复位：tb 从第一次 regEnable 起比（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

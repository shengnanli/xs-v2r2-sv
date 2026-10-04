MODULE = FloatDividerR64

# FloatDividerR64（标量浮点除法器，SRT 基 4 每拍 3 商位，f64 / f32 / f16 各一个元素）。
# golden 直接 child：ShiftLeftPriorityWithLZDResult ×2、fpdiv_r64_block ×1；
#   孙辈（fpdiv_r64_block 内）：CSA3to2_20 / CSA3to2_24 / r4_qds_v2 / r4_qds_v2_spec。
#   docs/coverage_three_axis.tsv：以上全部 PROVEN_DIRECT。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
CHILDREN = ShiftLeftPriorityWithLZDResult CSA3to2_20 CSA3to2_24 r4_qds_v2 r4_qds_v2_spec fpdiv_r64_block
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) FloatDividerR64))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) FloatDividerR64))

# FM_VARIANTS / FM_REF_DEPS 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FloatDividerR64
FM_REF_DEPS_FloatDividerR64 = ShiftLeftPriorityWithLZDResult.sv CSA3to2_20.sv CSA3to2_24.sv \
                              r4_qds_v2.sv r4_qds_v2_spec.sv fpdiv_r64_block.sv

# 关 merge_dup：让 fm_predict 的模型（寄存器位 + 输出位）严格适用；加强不是放宽
FM_MERGE_DUP = false
# 对称死位（依据与期望数见 verif/fm_target_config/FloatDividerR64.tcl）：开 vmucp 让 FM 实际比较这些点（加强不是放宽）
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 除 fsm_q（异步复位）外全部寄存器不复位：tb 从 golden 走过一次 PRE_2 之后第一次到 POST_0 起比数据输出。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

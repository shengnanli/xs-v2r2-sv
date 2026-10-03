MODULE = VectorFloatDividerR64

# VectorFloatDividerR64（向量浮点除法器，SRT 基 4 每拍 3 商位，f64×1 / f32×2 / f16×4）。
# golden 直接 child：ShiftLeftPriorityWithLZDResult ×2 / _6 ×2 / _8 ×4、fpdiv_r64_block_vector ×1；
#   孙辈（fpdiv_r64_block_vector 内）：CSA3to2_20 / CSA3to2_24 / r4_qds_v2 / r4_qds_v2_spec。
#   docs/coverage_three_axis.tsv：fpdiv_r64_block_vector / ShiftLeftPriorityWithLZDResult / CSA* / r4_qds_v2* 为
#   PROVEN_DIRECT；_6 / _8 表里仍写 MISSING/UNPROVEN（表滞后），实际已由 agent/k3-returned 重写并签核
#   （rtl/backend/ShiftLeftPriorityWithLZDResult_{6,8}.sv，receipt evidence/1bf831352049/ 两份 SUCCEEDED）。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
CHILDREN = ShiftLeftPriorityWithLZDResult ShiftLeftPriorityWithLZDResult_6 ShiftLeftPriorityWithLZDResult_8 \
           CSA3to2_20 CSA3to2_24 r4_qds_v2 r4_qds_v2_spec fpdiv_r64_block_vector
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) VectorFloatDividerR64))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) VectorFloatDividerR64))

# FM_VARIANTS / FM_REF_DEPS 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = VectorFloatDividerR64
FM_REF_DEPS_VectorFloatDividerR64 = ShiftLeftPriorityWithLZDResult.sv ShiftLeftPriorityWithLZDResult_6.sv \
                                    ShiftLeftPriorityWithLZDResult_8.sv CSA3to2_20.sv CSA3to2_24.sv \
                                    r4_qds_v2.sv r4_qds_v2_spec.sv fpdiv_r64_block_vector.sv

# 关 merge_dup：让 fm_predict 的模型（寄存器位 + 输出位）严格适用；加强不是放宽
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 除 fsm_q（异步复位）外全部寄存器不复位：tb 从 golden 第一次到 POST_0 起比数据输出（见 tb.sv 文件头）。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

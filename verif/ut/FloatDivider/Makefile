MODULE = FloatDivider

# 标量浮点除法 / 开方单元（FDivSqrt 的运算核：FloatDividerR64 + fpsqrt_r16 两个子单元 + 握手/结果汇合），vector-fu lane。
# child 处置（各自 receipt）：FloatDividerR64（evidence/6038c4afbc60）及其闭包 ShiftLeftPriorityWithLZDResult /
#   CSA3to2_20 / CSA3to2_24 / r4_qds_v2 / r4_qds_v2_spec / fpdiv_r64_block；fpsqrt_r16（evidence/44292961f2c0）及其闭包
#   lzc / r4_qds_cg / r4_qds / r4_qds_spec / fpsqrt_r16_block —— 全部已签核 → 两侧白盒：ref 读 golden 同名件，
#   impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
# tb 另带独立 IEEE oracle（除法照抄 verif/ut/FloatDividerR64、开方照抄 verif/ut/fpsqrt_r16 的整数算术参考）。
RTL_DIR  = ../../../rtl
CHILDREN = ShiftLeftPriorityWithLZDResult CSA3to2_20 CSA3to2_24 r4_qds_v2 r4_qds_v2_spec fpdiv_r64_block FloatDividerR64 \
           lzc r4_qds_cg r4_qds r4_qds_spec fpsqrt_r16_block fpsqrt_r16
TARGETS  = FloatDivider
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) $(TARGETS)))

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FloatDivider
FM_REF_DEPS_FloatDivider = ShiftLeftPriorityWithLZDResult.sv CSA3to2_20.sv CSA3to2_24.sv r4_qds_v2.sv \
    r4_qds_v2_spec.sv fpdiv_r64_block.sv FloatDividerR64.sv lzc.sv r4_qds_cg.sv r4_qds.sv r4_qds_spec.sv \
    fpsqrt_r16_block.sv fpsqrt_r16.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：FloatDividerR64 内 fp_format_onehot_q[2] 两侧对称死位（与它自签核同一点），
# 依据见 verif/fm_target_config/FloatDivider.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 两个子单元的 fsm_q 异步复位，其余寄存器不复位：结果按 tb 文件头的武装口径比。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

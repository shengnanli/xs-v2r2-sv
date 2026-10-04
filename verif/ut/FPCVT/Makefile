MODULE = FPCVT

# 标量浮点转换单元外壳（{宽度关系, sew} → 源/结果宽度独热两张译码表 + CVT64），vector-fu lane。
# child 处置：
#   CVT64 —— docs/coverage_three_axis.tsv 第 3 列 PROVEN_IN_CONE、本仓 main 无重写件（exeunits lane 有，未合入）：
#     两侧同源 golden（RTL_GOLDEN_DEPS），不设黑盒；同 verif/ut/FCVT 的处置。
#   FP_INCVT 及其 4 个 child（CLZ_6 / ShiftRightJam / RoundingUnit_3 / RoundingUnit_4）—— 已签核：两侧白盒，ref 读 golden，
#     impl 读本仓重写件（RTL_SRCS）。FM：impl 容器里 golden CVT64 例化的 FP_INCVT 解析到重写件 —— 真对比。
#   ★UT 限度★：CVT64 两侧共用 golden 定义，它例化的 FP_INCVT 两侧都解析到 golden 那份；重写件的 UT 在 verif/ut/FP_INCVT，
#     本层对它的替换由 FM 兜底。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/backend/ShiftRightJam.sv \
           $(RTL_DIR)/backend/RoundingUnit_3.sv \
           $(RTL_DIR)/backend/RoundingUnit_4.sv \
           $(RTL_DIR)/backend/FP_INCVT.sv \
           $(RTL_DIR)/backend/FPCVT.sv
TB_SRCS  = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(addprefix $(GOLDEN_RTL)/,FPCVT.sv FP_INCVT.sv CLZ_6.sv ShiftRightJam.sv RoundingUnit_3.sv RoundingUnit_4.sv)
RTL_GOLDEN_DEPS = $(GOLDEN_RTL)/CVT64.sv

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FPCVT
FM_REF_DEPS_FPCVT = CVT64.sv FP_INCVT.sv CLZ_6.sv ShiftRightJam.sv RoundingUnit_3.sv RoundingUnit_4.sv

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）严格适用。
FM_MERGE_DUP = false

# vmucp（加强不是放宽）：FP_INCVT 内 fcvtmodTrueExpReg[4:0] 两侧对称死位（同 FP_INCVT / FCVT 的签核），
# 依据与六条判据见 verif/fm_target_config/FPCVT.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 里 `ifndef SYNTHESIS 的断言块与随机初始化只在非 SYNTHESIS 下出现——定义 SYNTHESIS 与 FM 侧口径一致。
# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

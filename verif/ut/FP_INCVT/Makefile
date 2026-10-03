MODULE = FP_INCVT

# FP_INCVT（浮点源转换单元：fp->int / fp->fp widen/narrow/cross / fround / fcvtmod），fpu-parents lane（incvt 组）。
# child 处置（docs/coverage_three_axis.tsv 第 3 列）：CLZ_6 / ShiftRightJam / RoundingUnit_3 / RoundingUnit_4
#   均 REWRITTEN + PROVEN_DIRECT → 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件。无黑盒、无两侧同读 golden 的文件。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/backend/ShiftRightJam.sv \
           $(RTL_DIR)/backend/RoundingUnit_3.sv \
           $(RTL_DIR)/backend/RoundingUnit_4.sv \
           $(RTL_DIR)/backend/FP_INCVT.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL   ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS  = $(GOLDEN_RTL)/FP_INCVT.sv $(GOLDEN_RTL)/CLZ_6.sv $(GOLDEN_RTL)/ShiftRightJam.sv \
               $(GOLDEN_RTL)/RoundingUnit_3.sv $(GOLDEN_RTL)/RoundingUnit_4.sv

# FM_VARIANTS / FM_REF_DEPS_* 写字面名（scripts/fm_predict.py 按字面解析，不展开 make 变量）
FM_VARIANTS = FP_INCVT
FM_REF_DEPS_FP_INCVT = CLZ_6.sv ShiftRightJam.sv RoundingUnit_3.sv RoundingUnit_4.sv

# 关 merge_dup：让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# initreg 三档：INITREG=0 / random / <seed>017（CONVENTIONS：seed 1 的 random 档退化为全 1）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= 0
SIM_ARGS += +vcs+initreg+$(INITREG)

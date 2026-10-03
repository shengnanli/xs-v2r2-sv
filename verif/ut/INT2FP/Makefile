MODULE = INT2FP

# INT2FP（向量转换 64 位通道的整数 -> 浮点子单元，2 拍流水）。
# golden 直接 child：CLZ_6、RoundingUnit_3 —— docs/coverage_three_axis.tsv 均 PROVEN_DIRECT。
# 处置 = 两侧白盒：ref 读 golden 同名件，impl 读本仓重写件，无黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_CLZ_core.sv \
           $(RTL_DIR)/common/CLZ_6.sv \
           $(RTL_DIR)/backend/RoundingUnit_3.sv \
           $(RTL_DIR)/backend/INT2FP.sv
TB_SRCS  = ../VectorCvt_common/cvt_tb_pkg.sv tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/INT2FP.sv \
              $(GOLDEN_RTL)/CLZ_6.sv \
              $(GOLDEN_RTL)/RoundingUnit_3.sv
FM_VARIANTS = INT2FP
FM_REF_DEPS_INT2FP = CLZ_6.sv RoundingUnit_3.sv

# 关 merge_dup 让 fm_predict 的模型（寄存器位 + 输出位）严格适用（加强，不是放宽）
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的随机初始化 initial 块只在非 SYNTHESIS 下出现 —— 与 FM 侧口径一致。
INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

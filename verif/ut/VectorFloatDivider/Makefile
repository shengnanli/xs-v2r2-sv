# VectorFloatDivider —— 向量浮点除法/开方外壳：is_sqrt 派发给 VectorFloatDividerR64 / fpsqrt_vector_r16。
# 两个 child 都已签核（PROVEN_DIRECT）：两侧白盒，ref = golden 子树，impl = 重写件子树（闭包照两个 child 的 UT 抄）。无黑盒。
# UT：双例化逐拍比 + 独立 IEEE 754 oracle（除法 + 开方），tb 手写（见 tb.sv 文件头）。
MODULE = VectorFloatDivider

RTL_DIR  = ../../../rtl
DIV_CHILDREN  = ShiftLeftPriorityWithLZDResult ShiftLeftPriorityWithLZDResult_6 ShiftLeftPriorityWithLZDResult_8 \
                CSA3to2_20 CSA3to2_24 r4_qds_v2 r4_qds_v2_spec fpdiv_r64_block_vector VectorFloatDividerR64
SQRT_CHILDREN = lzc lzc_3 lzc_4 r4_qds_cg r4_qds r4_qds_spec fpsqrt_r16_block fpsqrt_vector_r16
CHILDREN = $(DIV_CHILDREN) $(SQRT_CHILDREN)
RTL_SRCS = $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(CHILDREN) VectorFloatDivider))
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(CHILDREN) VectorFloatDivider))

FM_VARIANTS = VectorFloatDivider
FM_REF_DEPS_VectorFloatDivider = $(addsuffix .sv,$(CHILDREN))

# 关 merge_dup：fm_predict 的模型（寄存器位 + 输出位）只在关掉时严格适用；加强不是放宽
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 结果通路寄存器不复位：tb 等两个迭代器各完整做过一次之后才比结果 / fflags（见 tb.sv 文件头）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
# tb.sv 手写，无生成器
gencheck:
	@echo "VectorFloatDivider: tb.sv 为手写 tb，无生成器"

# CsrDebugTime4 —— NewCSR 下 4 个自足叶（csr-l2-leaves lane）：
#   Debug             进 debug 模式判定 + Sdtrig 触发器分发（2 级不复位打拍）
#   MieModule         mie（复用 csr_irq_pkg 的中断号向量）
#   timeModule        time CSR（mtime 影子 + htimedelta）
#   XRetPermitModule  xRET 合法性（纯组合）
# 全部 golden 0 子模块例化，无黑盒，无 FM_REF_DEPS_*。
MODULE = CsrDebugTime4

RTL_DIR = ../../../rtl
LEAVES  = Debug MieModule timeModule XRetPermitModule
# 包排在前面（MieModule import csr_irq_pkg）。
RTL_SRCS = $(RTL_DIR)/backend/csr_irq_pkg.sv \
           $(addprefix $(RTL_DIR)/backend/,$(addsuffix .sv,$(LEAVES)))
TB_SRCS  = tb.sv
GOLDEN_SRCS = $(addprefix $(GOLDEN_RTL)/,$(addsuffix .sv,$(LEAVES)))

# FM_VARIANTS 必须写字面名：fm_predict.py / fm_passing_model.py 静态解析本文件，不展开变量。
FM_VARIANTS = Debug MieModule timeModule XRetPermitModule
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# +define+SYNTHESIS 关掉 golden 的 `ifndef SYNTHESIS 随机初值块，初值统一交给 +vcs+initreg。
# 不复位寄存器：Debug 的 4 个打拍位（tb warmup 冲刷）、timeModule 的 reg_time（tb arm 后再比）。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check

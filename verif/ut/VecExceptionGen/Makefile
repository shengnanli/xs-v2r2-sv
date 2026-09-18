MODULE = VecExceptionGen

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/VecExceptionGen.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/VecExceptionGen.sv

# golden VecExceptionGen 是自包含叶子（0 个子模块例化），所以没有 FM_REF_DEPS_*。
FM_VARIANTS = VecExceptionGen

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 本模块**一个寄存器都没有**（golden 里 0 个 always 块、0 个 reg 声明），
# 所以 initreg 取值理论上不影响输出。两轮（random / 0）照跑，正是对
# 「零寄存器」这个结论的检验：若哪天核里多出一个寄存器，两轮就会分岔。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: gen mutants
gen:
	python3 gen.py

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore）。
mutants:
	python3 mutants.py

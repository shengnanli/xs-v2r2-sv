MODULE = AgeDetector

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_AgeDetector_core.sv \
           $(RTL_DIR)/backend/AgeDetector.sv \
           $(RTL_DIR)/backend/AgeDetector_1.sv \
           $(RTL_DIR)/backend/AgeDetector_8.sv \
           $(RTL_DIR)/backend/AgeDetector_9.sv \
           $(RTL_DIR)/backend/AgeDetector_12.sv \
           $(RTL_DIR)/backend/AgeDetector_13.sv \
           $(RTL_DIR)/backend/AgeDetector_15.sv \
           $(RTL_DIR)/backend/AgeDetector_19.sv \
           $(RTL_DIR)/backend/AgeDetector_21.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/AgeDetector.sv    $(GOLDEN_RTL)/AgeDetector_1.sv  \
              $(GOLDEN_RTL)/AgeDetector_8.sv  $(GOLDEN_RTL)/AgeDetector_9.sv  \
              $(GOLDEN_RTL)/AgeDetector_12.sv $(GOLDEN_RTL)/AgeDetector_13.sv \
              $(GOLDEN_RTL)/AgeDetector_15.sv $(GOLDEN_RTL)/AgeDetector_19.sv \
              $(GOLDEN_RTL)/AgeDetector_21.sv

# 九个变体在 golden 里都是自包含叶子（0 个子模块例化，见 gen.py 量出的 subs），
# 所以没有 FM_REF_DEPS_*。
FM_VARIANTS = AgeDetector AgeDetector_1 AgeDetector_8 AgeDetector_9 AgeDetector_12 \
              AgeDetector_13 AgeDetector_15 AgeDetector_19 AgeDetector_21

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的 `ifndef SYNTHESIS 块里有 PopCount one-hot 断言（调用未定义的 xs_assert_v2）
# 与随机初值 initial 块；FM 两侧都带 -define SYNTHESIS 读入，UT 保持同一口径。
# 本家族全部 age 寄存器都有异步复位臂（逐个数过 golden，寄存器数 = 复位臂数），
# 正因如此两轮 initreg（random / 0）都跑，才是对"全复位"这个结论的检验。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore）。
.PHONY: mutants
mutants:
	python3 mutants.py

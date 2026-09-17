MODULE = BusyTable

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/xs_BusyTable_core.sv \
           $(RTL_DIR)/backend/BusyTable.sv \
           $(RTL_DIR)/backend/BusyTable_1.sv \
           $(RTL_DIR)/backend/BusyTable_2.sv \
           $(RTL_DIR)/backend/BusyTable_3.sv \
           $(RTL_DIR)/backend/VlBusyTable.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/BusyTable.sv   $(GOLDEN_RTL)/BusyTable_1.sv \
              $(GOLDEN_RTL)/BusyTable_2.sv $(GOLDEN_RTL)/BusyTable_3.sv \
              $(GOLDEN_RTL)/VlBusyTable.sv

# 五个变体都是自包含叶子（golden 里 0 个子模块例化），所以没有 FM_REF_DEPS_*。
FM_VARIANTS = BusyTable BusyTable_1 BusyTable_2 BusyTable_3 VlBusyTable

PORTLINT_ORDER = fail


include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 块只在 `ifndef SYNTHESIS 下出现，与 FM 侧口径一致：
# 两侧都定义 SYNTHESIS，寄存器初值交给 +vcs+initreg。
# 本家族**所有**寄存器都带异步复位（逐个数过 golden 复位臂），照理 initreg 取值
# 无关紧要——正因为如此，两轮（random / 0）都跑才是对「全复位」这个结论的检验。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore），
# 不进库。见 mutants.py 头部说明。
.PHONY: mutants
mutants:
	python3 mutants.py

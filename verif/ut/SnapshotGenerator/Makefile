MODULE = SnapshotGenerator

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/SnapshotGenerator.sv

# 真叶子：golden 里 0 个子模块例化，所以没有 FM_REF_DEPS_*。
FM_VARIANTS = SnapshotGenerator

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 两侧都定义 SYNTHESIS（golden 的随机初值 initial 块在 `ifndef SYNTHESIS 里），
# 初值交给 +vcs+initreg。★4 个快照槽不带复位★，所以 initreg 的两轮取值是真有区别的：
# tb 先跑 24 拍暖机把 4 个槽全写一遍，之后才开比对；漏写哪个，random 那轮当场炸。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

.PHONY: mutants
mutants:
	python3 mutants.py

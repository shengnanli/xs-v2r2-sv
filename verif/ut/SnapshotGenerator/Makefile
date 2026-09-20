MODULE = SnapshotGenerator

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_1.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_2.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_3.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_4.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_5.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_6.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_7.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_11.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_12.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_14.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/SnapshotGenerator.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_1.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_2.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_3.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_4.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_5.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_6.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_7.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_11.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_12.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_14.sv

# 真叶子：11 个 golden 变体每个都 0 个子模块例化，所以没有 FM_REF_DEPS_*。
# 家族形状（与 verif/ut/WrBypass 同）：一个参数化核 + 11 个薄 wrapper，
# 核体在 rtl/backend/SnapshotGenerator.sv 里，10 个变体文件只有 wrapper。
FM_VARIANTS = SnapshotGenerator SnapshotGenerator_1 SnapshotGenerator_2 SnapshotGenerator_3 SnapshotGenerator_4 SnapshotGenerator_5 SnapshotGenerator_6 SnapshotGenerator_7 SnapshotGenerator_11 SnapshotGenerator_12 SnapshotGenerator_14

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

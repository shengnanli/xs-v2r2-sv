MODULE = RenameBuffer

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator.sv \
           $(RTL_DIR)/backend/RenameBuffer.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/RenameBuffer.sv $(GOLDEN_RTL)/SnapshotGenerator.sv

# RenameBuffer 的子闭包只有 SnapshotGenerator（递归查到底，没有别的子模块），
# 它也是本 worker 的目标，两侧都完整 elaborate ⇒ **零黑盒**。
# SnapshotGenerator 自己的 FM 目标在 verif/ut/SnapshotGenerator/（一个 golden 顶层
# 只由一个 UT 出 receipt，避免两处各出一份说法不一）。
FM_VARIANTS = RenameBuffer
FM_REF_DEPS_RenameBuffer = SnapshotGenerator.sv

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 块只在 `ifndef SYNTHESIS 下出现，与 FM 侧口径一致：
# 两侧都定义 SYNTHESIS，寄存器初值交给 +vcs+initreg。
# ★本模块有一大批不复位寄存器★（256 项缓冲表 ×8 字段 / walkPtr /
# vecLoadExcp_valid / 6 组 toVecExcpMod 打拍寄存器 / 4 个快照槽），
# 所以 initreg 的两轮取值是**真的有区别**的：tb 先跑 160 拍暖机把它们全写一遍，
# 之后才开比对；暖机若漏了哪一个，random 那轮当场就炸。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# 判别力负测：注入真 bug，UT 必须报出来。变异只发生在 neg_build/（已 gitignore），
# 不进库。见 mutants.py 头部说明。
.PHONY: mutants
mutants:
	python3 mutants.py

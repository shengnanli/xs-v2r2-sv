MODULE = RenameTable

RTL_DIR = ../../../rtl
# 核体在 RenameTable.sv 里（家族共用的 xs_RenameTable_core，全仓只此一份），
# 另外三个文件只有 wrapper。SnapshotGenerator 是每个变体的**唯一**子模块，
# 四个单态化变体（_4/_5/_6/_7）+ 共享核一并带进来，两侧都完整 elaborate。
RTL_SRCS = $(RTL_DIR)/backend/SnapshotGenerator.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_4.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_5.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_6.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_7.sv \
           $(RTL_DIR)/backend/RenameTable.sv \
           $(RTL_DIR)/backend/RenameTable_1.sv \
           $(RTL_DIR)/backend/RenameTable_2.sv \
           $(RTL_DIR)/backend/RenameTable_3.sv
TB_SRCS = tb.sv

G1_CANONICAL ?= /home/eda/xs-env/G1-canonical
GOLDEN_RTL ?= $(G1_CANONICAL)/golden-rtl
GOLDEN_SRCS = $(GOLDEN_RTL)/RenameTable.sv   $(GOLDEN_RTL)/RenameTable_1.sv \
              $(GOLDEN_RTL)/RenameTable_2.sv $(GOLDEN_RTL)/RenameTable_3.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_4.sv $(GOLDEN_RTL)/SnapshotGenerator_5.sv \
              $(GOLDEN_RTL)/SnapshotGenerator_6.sv $(GOLDEN_RTL)/SnapshotGenerator_7.sv

# 子闭包递归查到底只有 SnapshotGenerator_<N> 一个（它自己 0 子模块），
# 四个变体两侧都完整 elaborate ⇒ **零黑盒、无厂商 SRAM 宏**。
# SnapshotGenerator 自己的 receipt 由 verif/ut/SnapshotGenerator 出，这里不重复。
FM_VARIANTS = RenameTable RenameTable_1 RenameTable_2 RenameTable_3
FM_REF_DEPS_RenameTable   = SnapshotGenerator_4.sv
FM_REF_DEPS_RenameTable_1 = SnapshotGenerator_5.sv
FM_REF_DEPS_RenameTable_2 = SnapshotGenerator_6.sv
FM_REF_DEPS_RenameTable_3 = SnapshotGenerator_7.sv

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# golden 含 XSError 非综合断言（"pdest for $0 should be 0"）与随机初值 initial 块；
# FM 两侧都带 -define SYNTHESIS 读入，UT 保持同一口径。
#
# ★为什么两轮 initreg 在这里是真有区别的★：本家族有**一整块无复位寄存器** ——
#   t1_raddr（N_READ 个）、spec_table_next_<i>_REG（N_ENTRIES 个）、
#   t1_wSpec_*（3 x 6 个）、t1_bypass（N_READ x N_WRITE 个）。
#   它们只被 io_redirect 清零（t1_raddr 连这个都没有，只有 !hold 使能），
#   没有任何 reset 臂 —— 逐条对着 golden 的两个 always 块数过。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# wrapper 与 tb 都由生成器产出，防手改后被静默覆盖。
.PHONY: gencheck mutants
gencheck:
	python3 gen_variants.py --check
	python3 gen_tb.py --check

mutants:
	python3 mutants.py

# RenameTableWrapper —— 五张重命名表的装配壳 + difftest 快照；四个目标：
#   RenameTableWrapper（父）、DiffRatStateBuffer（子，本 lane 重写）、
#   diff_rat_state_bank_320x776 / stateBankTags_320x3（DiffRatStateBuffer 的两个 firtool 行为级存储叶子，本 lane 重写）
#
# 五张 RenameTable（RenameTable / _1 / _2 / _3）与它们的 SnapshotGenerator 是已签核可读件，放
# RTL_GOLDEN_DEPS：不 derive、不改名，golden RenameTableWrapper 与派生出的 RenameTableWrapper_xs
# 例化同一份定义；FM 侧 ref 走 golden 文件（FM_REF_DEPS），impl 走可读件，两侧完整 elaborate。
MODULE = RenameTableWrapper

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/diff_rat_state_bank_320x776.sv \
           $(RTL_DIR)/backend/stateBankTags_320x3.sv \
           $(RTL_DIR)/backend/DiffRatStateBuffer.sv \
           $(RTL_DIR)/backend/RenameTableWrapper.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/diff_rat_state_bank_320x776.sv $(GOLDEN_RTL)/stateBankTags_320x3.sv \
              $(GOLDEN_RTL)/DiffRatStateBuffer.sv $(GOLDEN_RTL)/RenameTableWrapper.sv

RAT_IMPL = $(RTL_DIR)/backend/SnapshotGenerator.sv $(RTL_DIR)/backend/SnapshotGenerator_4.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_5.sv $(RTL_DIR)/backend/SnapshotGenerator_6.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_7.sv $(RTL_DIR)/backend/RenameTable.sv \
           $(RTL_DIR)/backend/RenameTable_1.sv $(RTL_DIR)/backend/RenameTable_2.sv $(RTL_DIR)/backend/RenameTable_3.sv
RTL_GOLDEN_DEPS = $(RAT_IMPL)

FM_VARIANTS = RenameTableWrapper DiffRatStateBuffer diff_rat_state_bank_320x776 stateBankTags_320x3
FM_REF_DEPS_RenameTableWrapper = RenameTable.sv RenameTable_1.sv RenameTable_2.sv RenameTable_3.sv \
                                 SnapshotGenerator_4.sv SnapshotGenerator_5.sv SnapshotGenerator_6.sv SnapshotGenerator_7.sv \
                                 DiffRatStateBuffer.sv diff_rat_state_bank_320x776.sv stateBankTags_320x3.sv
FM_REF_DEPS_DiffRatStateBuffer = diff_rat_state_bank_320x776.sv stateBankTags_320x3.sv
FM_REF_DEPS_diff_rat_state_bank_320x776 =
FM_REF_DEPS_stateBankTags_320x3 =

PORTLINT_ORDER = fail

# 关掉重复寄存器合并，让 passing 预测模型严格适用（scripts/fm_predict.py）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 的 XSError/assert 断言与随机初值段两侧统一用 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS

# 两档 initreg。无复位寄存器：RenameTable 的快照槽/读地址副本（tb 暖机 8 拍 snptEnq 写满槽）、
# DiffRatStateBuffer 的 bankReadData/readBankOH（只在 readValid 拍被消费，而 readValid 复位 0）、
# 两个存储叶子（只读写过的槽：stateSlotValid 复位 0 把未写的槽挡在读路径外）。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0 gencheck
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"
gencheck:
	python3 ../../../scripts/gen_renametablewrapper.py --check

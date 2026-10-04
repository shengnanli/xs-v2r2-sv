# VTypeBuffer —— 向量 vtype 重命名缓冲（Rob 的子模块）。
# 子模块两侧白盒：SyncDataModuleTemplate__64entry_4（64 项存储体，golden 侧再例化 4 个 DataModule__16entry_16）、SnapshotGenerator_1/_2（快照）；
# ref 侧 golden 闭包，impl 侧本工程已签核（PROVEN_DIRECT）的重写件。无黑盒。
MODULE = VTypeBuffer

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_DataModule.sv \
           $(RTL_DIR)/common/xs_SyncDataModule.sv \
           $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_4.sv \
           $(RTL_DIR)/backend/SnapshotGenerator.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_1.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_2.sv \
           $(RTL_DIR)/backend/VTypeBuffer.sv
TB_SRCS  = tb.sv

VTB_DEPS = SyncDataModuleTemplate__64entry_4.sv DataModule__16entry_16.sv \
           SnapshotGenerator_1.sv SnapshotGenerator_2.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/VTypeBuffer.sv $(addprefix $(GOLDEN_RTL)/,$(VTB_DEPS))

FM_VARIANTS = VTypeBuffer
FM_REF_DEPS_VTypeBuffer = $(VTB_DEPS)
FM_MERGE_DUP = false
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# 不复位状态（存储体 64 项、快照 4 槽、walkPtr / stateLastCycle / useSnapshot / snapshotVType）：
# tb 的 arm 条件保证比较窗口开在它们都被写过之后，initreg 三档都比。
VCS      += +define+SYNTHESIS +vcs+initreg+random
INITREG  ?= random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gencheck
gencheck:
	python3 gen.py --check

# 214 个对称无读者位（deqPtrOH 64 按名配上 + 150 个由 fm_pins.tcl 钉成双射）交 FM 实比，
# 依据与白名单见 verif/fm_target_config/VTypeBuffer.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

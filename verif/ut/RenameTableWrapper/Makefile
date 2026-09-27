# RenameTableWrapper —— 五张重命名表的装配壳 + difftest 快照；两个 FM 目标：
#   RenameTableWrapper（父）、DiffRatStateBuffer（子）。
#
# ★两个 firtool 行为级存储叶子 diff_rat_state_bank_320x776 / stateBankTags_320x3 不是 FM 目标★
#   深度 320 / 地址 9 位（2^9=512>320），白盒化在 **ref 侧 set_top 就触发 FMR_ELAB-147 -> FM-262 ->
#   FM-156**（与 L2TlbMissQueue 的 ram_40x47、Rob 的 dt_pcTransType_160x2 同形），根本 link 不起来；
#   golden 自身如此，任何一侧都不能白盒。唯一合规路线 = codex 0158 §1 APPROVED_MEMORY_MACRO_MODEL：
#   两条已按精确 module 名 + golden 源码 hash 登记在 verif/vendor_boundary.tsv（三项最小功能审查
#   `python3 scripts/audit_ram_memory_model.py --check` 机器复算），FM 两侧**对称黑盒**（regimeA：
#   FM_REF_DEPS 不含叶子、RTL_SRCS 不含叶子，两侧同为未解析黑盒），声明在 verif/allow/<top>.json。
#   照 L2TlbMissQueue 先例：impl 侧不另写同名叶子，直接例化 golden 那份（VCS 仿真两侧共用
#   GOLDEN_SRCS 里的 golden 叶子）；之前 rtl/backend 下的两份同名手写叶子已删——它们既不能被 FM
#   证明，又与审定 hash 不同，留着就是一个「同名但未受验」的洞。
#   ★入表不等于转绿（codex 0158）：绿灯只来自 clean native FM 结果本身★
#
# 五张 RenameTable（RenameTable / _1 / _2 / _3）与它们的 SnapshotGenerator 是已签核可读件，放
# RTL_GOLDEN_DEPS：不 derive、不改名，golden RenameTableWrapper 与派生出的 RenameTableWrapper_xs
# 例化同一份定义；FM 侧 ref 走 golden 文件（FM_REF_DEPS），impl 走可读件，两侧完整 elaborate。
MODULE = RenameTableWrapper

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/DiffRatStateBuffer.sv \
           $(RTL_DIR)/backend/RenameTableWrapper.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/diff_rat_state_bank_320x776.sv $(GOLDEN_RTL)/stateBankTags_320x3.sv \
              $(GOLDEN_RTL)/DiffRatStateBuffer.sv $(GOLDEN_RTL)/RenameTableWrapper.sv

RAT_IMPL = $(RTL_DIR)/backend/SnapshotGenerator.sv $(RTL_DIR)/backend/SnapshotGenerator_4.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_5.sv $(RTL_DIR)/backend/SnapshotGenerator_6.sv \
           $(RTL_DIR)/backend/SnapshotGenerator_7.sv $(RTL_DIR)/backend/RenameTable.sv \
           $(RTL_DIR)/backend/RenameTable_1.sv $(RTL_DIR)/backend/RenameTable_2.sv $(RTL_DIR)/backend/RenameTable_3.sv
RTL_GOLDEN_DEPS = $(RAT_IMPL)

FM_VARIANTS = RenameTableWrapper DiffRatStateBuffer
# 两个存储叶子故意不在 FM_REF_DEPS 里（两侧对称黑盒，见文件头）。
FM_REF_DEPS_RenameTableWrapper = RenameTable.sv RenameTable_1.sv RenameTable_2.sv RenameTable_3.sv \
                                 SnapshotGenerator_4.sv SnapshotGenerator_5.sv SnapshotGenerator_6.sv SnapshotGenerator_7.sv \
                                 DiffRatStateBuffer.sv
FM_REF_DEPS_DiffRatStateBuffer =
# assembly 模式 + 逐对象声明（verif/allow/RenameTableWrapper.json / DiffRatStateBuffer.json）：
# 黑盒只有上述两个审定过的存储宏（ref 7 实例 / impl 7 实例），其余（五张 RenameTable、
# SnapshotGenerator、DiffRatStateBuffer 本体）两侧全部 elaborate 受验，不走 green_child。
FM_MODE = assembly
FM_ALLOWLIST ?= 1

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

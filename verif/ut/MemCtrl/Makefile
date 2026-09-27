# MemCtrl —— MDP 装配层（SSIT + WaitTable）；两个目标 MemCtrl / WaitTable 都**没有输出端口**
#
# 子模块：
#   SSIT      —— 已签核可读件（verif/ut/SSIT），放 RTL_GOLDEN_DEPS 两侧同一份定义；
#                它自己的 4 个 SyncDataModule 叶子走 rtl/common 的可读件（同样两侧同一份）。
#                FM 侧 ref 走 golden SSIT.sv + 4 个 golden 叶子（FM_REF_DEPS），impl 走可读件。
#   WaitTable —— 本 lane 重写，是 FM_VARIANTS 里的第二个目标；UT 里随 MemCtrl_xs 一起
#                派生成 WaitTable_xs 与 golden WaitTable 对比（层次探针）。
MODULE = MemCtrl

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/MemCtrl.sv \
           $(RTL_DIR)/backend/WaitTable.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MemCtrl.sv $(GOLDEN_RTL)/WaitTable.sv

# SSIT 的 4 个 SyncDataModule 叶子：按 verif/ut/SSIT/Makefile 的同一口径，两侧都读 golden 的
# 叶子文件（它们各自是已 SUCCEEDED 的独立目标：SyncDataModuleTemplate__1024entry{,_1} /
# DataModule__64entry{,_16}，见 verif/ut/SyncDataModule）。首跑（evidence/9154088d8da0/MemCtrl）
# 用 rtl/common 可读叶子时，8898 个 unmatched-unread 里 8k+ 是这 4 个叶子内部 banked
# 数据阵列与地址/数据副本寄存器的两侧命名鸿沟（其中 _1024entry_1 是非对称写口专用核，
# 结构本就不同），本层证明的对象是 MemCtrl/WaitTable/SSIT 的逻辑，不重证叶子。
SSIT_LEAVES = SyncDataModuleTemplate__1024entry.sv SyncDataModuleTemplate__1024entry_1.sv \
              DataModule__64entry.sv DataModule__64entry_16.sv
RTL_GOLDEN_DEPS = $(RTL_DIR)/backend/SSIT.sv $(addprefix $(GOLDEN_RTL)/,$(SSIT_LEAVES))

FM_VARIANTS = MemCtrl WaitTable
FM_REF_DEPS_MemCtrl = SSIT.sv WaitTable.sv $(SSIT_LEAVES)
FM_REF_DEPS_WaitTable =

PORTLINT_ORDER = fail

# 关掉 FM 的重复寄存器合并：让 passing 预测模型（Σ寄存器位 + 输出位）严格适用，
# 跑前登记、跑后逐点对账（scripts/fm_predict.py）。两侧的重复寄存器都按 golden 保留。
FM_MERGE_DUP = false

# vmucp = 加强证明。两个目标都没有输出端口，全部寄存器在基线里都是 matched-unread
# （首跑 passing 0）；开关后 FM 把它们当比较点真比。改名的标量寄存器先由 fm_pins.tcl 钉成
# 138（MemCtrl）/ 5（WaitTable）对。依据与预期见 verif/fm_target_config/{MemCtrl,WaitTable}.tcl。
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 段与 XSError 断言两侧统一用 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS

# 两档 initreg。无复位寄存器：MemCtrl 的 7 个打拍寄存器、WaitTable 的 REG、SSIT 内部
# （SSIT 两侧同一份定义、不比对）。前两者在复位撤销后 1 拍被写定，tb 从第 2 拍起比对。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0 gencheck
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"
gencheck:
	python3 gen_tb.py --check

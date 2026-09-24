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

SDM_LEAVES = $(RTL_DIR)/common/xs_DataModule.sv \
             $(RTL_DIR)/common/xs_SyncDataModule.sv \
             $(RTL_DIR)/common/DataModule__64entry.sv \
             $(RTL_DIR)/common/DataModule__64entry_16.sv \
             $(RTL_DIR)/common/SyncDataModuleTemplate__1024entry.sv \
             $(RTL_DIR)/common/SyncDataModuleTemplate__1024entry_1.sv
RTL_GOLDEN_DEPS = $(RTL_DIR)/backend/SSIT.sv $(SDM_LEAVES)

FM_VARIANTS = MemCtrl WaitTable
FM_REF_DEPS_MemCtrl = SSIT.sv WaitTable.sv \
                      SyncDataModuleTemplate__1024entry.sv SyncDataModuleTemplate__1024entry_1.sv \
                      DataModule__64entry.sv DataModule__64entry_16.sv
FM_REF_DEPS_WaitTable =

PORTLINT_ORDER = fail

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

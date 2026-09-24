# GPAMem —— guest 物理地址暂存（按 FtqPtr 索引的 64 项表 + 块内偏移加法）
#
# 子模块只有一个：SyncDataModuleTemplate__64entry_5（4 bank × DataModule__16entry_20），
# 是 306 目标里的独立叶子（可读件在 rtl/common/，签核归 verif/ut/SyncDataModule 家族），
# 放 RTL_GOLDEN_DEPS：不 derive、不改名，golden GPAMem 与派生出的 GPAMem_xs 例化同一份
# 定义（UT 两侧对称）；FM 侧 ref 走 golden 的两个叶子文件（FM_REF_DEPS），impl 走可读件，
# 两侧都完整 elaborate、无黑盒（同 ICacheMainPipe 的做法）。
MODULE = GPAMem

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/backend/GPAMem.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/GPAMem.sv

RTL_GOLDEN_DEPS = \
  $(RTL_DIR)/common/xs_DataModule.sv \
  $(RTL_DIR)/common/xs_SyncDataModule.sv \
  $(RTL_DIR)/common/DataModule__16entry_20.sv \
  $(RTL_DIR)/common/SyncDataModuleTemplate__64entry_5.sv

FM_VARIANTS = GPAMem
FM_REF_DEPS_GPAMem = SyncDataModuleTemplate__64entry_5.sv DataModule__16entry_20.sv

PORTLINT_ORDER = fail

# 关掉 FM 的重复寄存器合并：让 passing 预测模型（Σ寄存器位 + 输出位）严格适用，
# 跑前登记、跑后逐点对账（scripts/fm_predict.py）。两侧的重复寄存器都按 golden 保留。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 的随机初值 initial 段两侧统一用 SYNTHESIS 关掉。
VCS += +define+SYNTHESIS

# 两档 initreg：编译期打开机制，运行期 +vcs+initreg+random（默认）或 +0（run-initreg0）。
# 无复位寄存器：ftqOffset（RegEnable 无 init）与表内全部数据/地址/写数据复制寄存器。
# tb 先把 64 项全写一遍并发一次读，再开比对窗口，所以两档都必须 errors=0。
VCS      += +vcs+initreg+random
SIM_ARGS += +vcs+initreg+random

.PHONY: run-initreg0
run-initreg0:
	$(MAKE) run SEED=$(SEED) SIM_ARGS="+ncycles=$(NCYCLES) +vcs+initreg+0"

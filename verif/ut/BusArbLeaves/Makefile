MODULE = BusArbLeaves

# 两个无状态叶子：
#   BusPerfMonitor          L1→L2 总线性能监视节点（综合配置下纯直连），scripts/gen_busperfmonitor.py 生成
#   Arbiter3_L2TLBImp_Anon  L2TLB 的三路应答汇流，已签核核 xs_FixedPriorityArbiter_core +
#                           scripts/gen_arbiter_chidat_l2tlb.py 生成的薄文件
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/BusPerfMonitor.sv \
           $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv $(RTL_DIR)/mmu/Arbiter3_L2TLBImp_Anon.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/BusPerfMonitor.sv $(GOLDEN_RTL)/Arbiter3_L2TLBImp_Anon.sv
FM_VARIANTS = BusPerfMonitor Arbiter3_L2TLBImp_Anon
FM_MERGE_DUP = false

PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

INITREG  ?= random
VCS      += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+$(INITREG)

.PHONY: gentb gencheck
gentb:
	python3 gen.py
gencheck:
	python3 gen.py --check

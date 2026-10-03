MODULE = MMIOBridgeLeaves

# MMIOBridge（coupledL2 tl2chi 的 TL→CHI MMIO 桥）的叶子：
#   MMIOBridgeEntry / _2 / _4 / _8   事务槽，共享核 xs_MMIOBridgeEntry_core（只差 io_id 位宽）
#   Arbiter16_CHIDAT                 16 个槽的 TXDAT 汇流，已签核核 xs_FixedPriorityArbiter_core +
#                                    scripts/gen_arbiter_chidat_l2tlb.py 生成的薄文件
# 都没有子模块、没有黑盒。
RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/uncore/xs_MMIOBridgeEntry_core.sv \
           $(RTL_DIR)/uncore/MMIOBridgeEntry.sv $(RTL_DIR)/uncore/MMIOBridgeEntry_2.sv \
           $(RTL_DIR)/uncore/MMIOBridgeEntry_4.sv $(RTL_DIR)/uncore/MMIOBridgeEntry_8.sv \
           $(RTL_DIR)/frontend/xs_FixedPriorityArbiter_core.sv \
           $(RTL_DIR)/uncore/Arbiter16_CHIDAT.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/MMIOBridgeEntry.sv $(GOLDEN_RTL)/MMIOBridgeEntry_2.sv \
              $(GOLDEN_RTL)/MMIOBridgeEntry_4.sv $(GOLDEN_RTL)/MMIOBridgeEntry_8.sv \
              $(GOLDEN_RTL)/Arbiter16_CHIDAT.sv
FM_VARIANTS = MMIOBridgeEntry MMIOBridgeEntry_2 MMIOBridgeEntry_4 MMIOBridgeEntry_8 Arbiter16_CHIDAT
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

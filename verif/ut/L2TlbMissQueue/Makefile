MODULE = L2TlbMissQueue

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/L2TlbMissQueue.sv
TB_SRCS = tb.sv

FM_REF_DEPS_L2TlbMissQueue = Queue40_L2TlbMQBundle.sv
FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbMissQueue.sv \
              $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv \
              $(GOLDEN_RTL)/ram_40x47.sv
# 老战役审计声明继承: proof_mode=assembly, 对称黑盒边界 = ram_40x47
FM_MODE = assembly
FM_ALLOWLIST ?= 1
FM_VARIANTS = L2TlbMissQueue

include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv

MODULE = L2TlbMissQueue
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/l2tlbmissqueue_pkg.sv $(RTL_DIR)/memblock/L2TlbMissQueue.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/L2TlbMissQueue_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbMissQueue.sv $(GOLDEN_RTL)/Queue40_L2TlbMQBundle.sv $(GOLDEN_RTL)/ram_40x47.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = L2TlbMissQueue
FM_REF_DEPS_L2TlbMissQueue = Queue40_L2TlbMQBundle.sv ram_40x47.sv
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv

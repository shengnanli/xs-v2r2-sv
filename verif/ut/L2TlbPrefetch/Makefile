MODULE = L2TlbPrefetch
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/l2tlbprefetch_pkg.sv $(RTL_DIR)/memblock/L2TlbPrefetch.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/L2TlbPrefetch_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbPrefetch.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = L2TlbPrefetch
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_RTL)/L2TlbPrefetch.sv $(TB_SRCS) -top tb -o simv

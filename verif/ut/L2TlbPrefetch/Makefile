MODULE = L2TlbPrefetch

RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/L2TlbPrefetch.sv
TB_SRCS = tb.sv

FM_MERGE_DUP = false
GOLDEN_SRCS = $(GOLDEN_RTL)/L2TlbPrefetch.sv
FM_VARIANTS = L2TlbPrefetch

include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_RTL)/L2TlbPrefetch.sv $(TB_SRCS) -top tb -o simv

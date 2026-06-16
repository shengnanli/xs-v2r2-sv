MODULE = HPTW
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/hptw_pkg.sv $(RTL_DIR)/memblock/HPTW.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/HPTW_wrapper.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/HPTW.sv
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = HPTW
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

simv: $(RTL_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(GOLDEN_RTL)/HPTW.sv $(TB_SRCS) -top tb -o simv

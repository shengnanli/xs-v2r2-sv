MODULE = LLPTW
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/llptw_pkg.sv $(RTL_DIR)/memblock/LLPTW.sv
WRAPPER_SRCS = $(RTL_DIR)/memblock/LLPTW_wrapper.sv
SUBMOD_SRCS = $(GOLDEN_RTL)/RRArbiterInit.sv $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LLPTW.sv $(SUBMOD_SRCS)
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = LLPTW
FM_REF_DEPS_LLPTW = RRArbiterInit.sv Arbiter2_LLPTW_Anon.sv
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

# UT：编 golden LLPTW + 两个 golden 子模块（双侧共用黑盒）+ 手写核/包装 + tb。
simv: $(RTL_SRCS) $(WRAPPER_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(WRAPPER_SRCS) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv

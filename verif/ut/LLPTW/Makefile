MODULE = LLPTW
RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl
RTL_SRCS = $(RTL_DIR)/memblock/llptw_pkg.sv $(RTL_DIR)/memblock/LLPTW.sv
SUBMOD_SRCS = $(GOLDEN_RTL)/RRArbiterInit.sv $(GOLDEN_RTL)/Arbiter2_LLPTW_Anon.sv
# FM impl 侧同样读入 golden 仲裁器源(否则 ref=真逻辑/impl=黑盒不对称:
# ref 侧 lastGrant DFF 无对而 impl 侧 2814 个仲裁器 BBPin 无对, 传染大片 failing)
WRAPPER_SRCS = $(RTL_DIR)/memblock/LLPTW_wrapper.sv $(SUBMOD_SRCS)
GOLDEN_SRCS = $(GOLDEN_RTL)/LLPTW.sv $(SUBMOD_SRCS)
TB_SRCS = variants_xs.sv tb.sv
FM_VARIANTS = LLPTW
FM_REF_DEPS_LLPTW = RRArbiterInit.sv Arbiter2_LLPTW_Anon.sv
FM_MERGE_DUP = false
include ../../../scripts/ut_common.mk

# UT：编 golden LLPTW + 两个 golden 子模块（双侧共用黑盒）+ 手写核/包装 + tb。
# UT 编译去重(保序: pkg 必须在前): WRAPPER_SRCS 现含 SUBMOD_SRCS(FM 对称用),
# 编译时只取 wrapper 本体, golden 子模块统一走 GOLDEN_SRCS
simv: $(RTL_SRCS) $(WRAPPER_SRCS) $(TB_SRCS) $(GOLDEN_SRCS)
	$(VCS) +define+SYNTHESIS $(RTL_SRCS) $(filter-out $(SUBMOD_SRCS),$(WRAPPER_SRCS)) $(GOLDEN_SRCS) $(TB_SRCS) -top tb -o simv

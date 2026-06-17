MODULE = FreeList

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包(UT 不编 FreeList_wrapper.sv，避免与 golden 顶层同名冲突；
# 手写侧用 variants_xs.sv 里的 FreeList_xs)
RTL_SRCS = $(RTL_DIR)/memblock/freelist_pkg.sv \
           $(RTL_DIR)/memblock/FreeList.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 FreeList(无子模块)
GOLDEN_SRCS = $(GOLDEN_RTL)/FreeList.sv

# FM：golden FreeList vs 手写同名 wrapper(→核)
WRAPPER_SRCS = $(RTL_DIR)/memblock/FreeList_wrapper.sv
FM_VARIANTS = FreeList

include ../../../scripts/ut_common.mk

# golden 含 XSError/XSPerf 非综合断言；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS

MODULE = LoadQueueRAW

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包
RTL_SRCS = $(RTL_DIR)/memblock/loadqueueraw_pkg.sv \
           $(RTL_DIR)/memblock/LoadQueueRAW.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 LoadQueueRAW 例化的叶子子模块：
#   paddr/mask CAM、freelist、违例输出的 DelayN / DelayNWithValid。
# UT 两侧（u_g golden、u_i 手写核）各自独立，golden 侧需带齐这些子模块。
#   含 CAM/freelist 各自再例化的 DelayN(WithValid) 写时序子模块（递归依赖）。
GOLDEN_DEPS = LqPAddrModule_1.sv LqMaskModule.sv FreeList_4.sv \
              DelayN_298.sv DelayN_13.sv \
              DelayNWithValid_148.sv DelayNWithValid_149.sv \
              DelayNWithValid_52.sv DelayNWithValid_55.sv DelayNWithValid_103.sv
GOLDEN_SRCS = $(GOLDEN_RTL)/LoadQueueRAW.sv $(addprefix $(GOLDEN_RTL)/,$(GOLDEN_DEPS))

# FM：golden 顶层 LoadQueueRAW（含上述子模块）vs 手写同名 wrapper（→ 可读核）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/LoadQueueRAW_wrapper.sv
FM_VARIANTS = LoadQueueRAW
FM_REF_DEPS_LoadQueueRAW = $(GOLDEN_DEPS)

# 本核含若干刻意保留的同值打拍寄存器（store ftq 延迟链、perf 2 拍），与 golden 子模块
# 内部寄存器名/层次不同；关闭“合并同值重复寄存器”pass 以免跨 wrapper/u_core 边界
# 误折叠导致失配。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf 行为断言（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS

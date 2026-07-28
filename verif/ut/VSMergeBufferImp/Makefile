MODULE = VSMergeBufferImp

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_VSMergeBufferImp_core(+ pkg) + 扁平端口包装 VSMergeBufferImp(_xs)
RTL_SRCS = $(RTL_DIR)/memblock/vsmergebuffer_pkg.sv $(RTL_DIR)/memblock/VSMergeBufferImp.sv
# golden 子模块闭包(FreeList_1 分配器 + NewPipelineConnectPipe_27 打拍), 两侧同 elaborate
GOLDEN_SUBS = \
  $(GOLDEN_RTL)/FreeList_1.sv \
  $(GOLDEN_RTL)/NewPipelineConnectPipe_27.sv
# UT 双例化两侧共用同一批 golden 子模块定义
GOLDEN_SRCS = $(GOLDEN_RTL)/VSMergeBufferImp.sv $(GOLDEN_SUBS)
# FM impl 顶层 wrapper + 同一批 golden 子模块(impl 侧同 elaborate)
WRAPPER_SRCS = $(RTL_DIR)/memblock/VSMergeBufferImp_wrapper.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 VSMergeBufferImp 顶层 glue; 2 子模块两侧 elaborate 作为共同定义
FM_VARIANTS = VSMergeBufferImp
FM_REF_DEPS_VSMergeBufferImp = FreeList_1.sv NewPipelineConnectPipe_27.sv

# 子模块含同构表项/流水寄存器, 关合并同值重复寄存器 pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言/随机初值; 定义 SYNTHESIS 关掉(两侧复位同构)。
VCS += +define+SYNTHESIS
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

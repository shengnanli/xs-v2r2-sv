MODULE = VSSplitImp

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_VSSplitImp_core(+ pkg) + 扁平端口包装 VSSplitImp(_xs)
RTL_SRCS = $(RTL_DIR)/memblock/vssplitimp_pkg.sv $(RTL_DIR)/memblock/VSSplitImp.sv
# golden 子模块闭包(纯结构装配壳的 3 个逻辑子, 两侧同 elaborate 黑盒)
GOLDEN_SUBS = \
  $(GOLDEN_RTL)/VSSplitPipelineImp.sv \
  $(GOLDEN_RTL)/VSSplitBufferImp.sv \
  $(GOLDEN_RTL)/skidBufferConnect.sv
# UT 双例化两侧共用同一批 golden 子模块定义
GOLDEN_SRCS = $(GOLDEN_RTL)/VSSplitImp.sv $(GOLDEN_SUBS)
# FM impl 顶层 wrapper + 同一批 golden 子模块(impl 侧同 elaborate → 子模块内部逐位自配)
WRAPPER_SRCS = $(RTL_DIR)/memblock/VSSplitImp_wrapper.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 VSSplitImp 顶层 glue; 3 子模块两侧 elaborate 作为共同定义
FM_VARIANTS = VSSplitImp
FM_REF_DEPS_VSSplitImp = VSSplitPipelineImp.sv VSSplitBufferImp.sv skidBufferConnect.sv

# 子模块含同构表项/流水寄存器, 关合并同值重复寄存器 pass。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子模块含 `ifndef SYNTHESIS 断言/随机初值; 定义 SYNTHESIS 关掉(两侧复位同构)。
VCS += +define+SYNTHESIS

MODULE = VSegmentUnit

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 可读核 xs_VSegmentUnit_core(+ pkg) + 扁平端口包装 VSegmentUnit(_xs)
RTL_SRCS = $(RTL_DIR)/memblock/vsegmentunit_pkg.sv $(RTL_DIR)/memblock/VSegmentUnit.sv
# golden 子模块闭包(VSegmentTrigger 触发比较 + NewPipelineConnectPipe_31 打拍), 两侧同 elaborate
GOLDEN_SUBS = \
  $(GOLDEN_RTL)/VSegmentTrigger.sv \
  $(GOLDEN_RTL)/NewPipelineConnectPipe_31.sv
# UT 双例化两侧共用同一批 golden 子模块定义
GOLDEN_SRCS = $(GOLDEN_RTL)/VSegmentUnit.sv $(GOLDEN_SUBS)
# FM impl 顶层 wrapper + 同一批 golden 子模块(impl 侧同 elaborate)
WRAPPER_SRCS = $(RTL_DIR)/memblock/VSegmentUnit_wrapper.sv $(GOLDEN_SUBS)
TB_SRCS = variants_xs.sv tb.sv

# FM: 只比 VSegmentUnit 顶层 glue; 2 子模块两侧 elaborate 作为共同定义
FM_VARIANTS = VSegmentUnit
FM_REF_DEPS_VSegmentUnit = VSegmentTrigger.sv NewPipelineConnectPipe_31.sv

FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 含 `ifndef SYNTHESIS 断言/随机初值; 定义 SYNTHESIS 关掉(两侧复位同构)。
VCS += +define+SYNTHESIS
FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true

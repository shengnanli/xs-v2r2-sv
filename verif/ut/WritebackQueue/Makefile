MODULE = WritebackQueue

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包。可读核例化 golden 的 WritebackEntry 黑盒（队列级逻辑重写，
# entry 状态机沿用 golden 黑盒），故 RTL_SRCS 需带上这两个 entry 文件供两侧/FM impl 解析。
RTL_SRCS = $(RTL_DIR)/memblock/writebackqueue_pkg.sv \
           $(RTL_DIR)/memblock/WritebackQueue.sv \
           $(GOLDEN_RTL)/WritebackEntry.sv \
           $(GOLDEN_RTL)/WritebackEntry_15.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 WritebackQueue（其例化的 entry 黑盒已在 RTL_SRCS 提供，避免重复编译）。
GOLDEN_SRCS = $(GOLDEN_RTL)/WritebackQueue.sv

# FM：golden 顶层 WritebackQueue（含 entry 黑盒）vs 手写同名 wrapper（→ 可读核 + entry 黑盒）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/WritebackQueue_wrapper.sv
FM_VARIANTS = WritebackQueue
# golden ref 侧依赖 entry 子模块；impl 侧 wrapper→u_core 也例化同名 entry，FM 按名配对为黑盒。
FM_REF_DEPS_WritebackQueue = WritebackEntry.sv WritebackEntry_15.sv

# 18 份结构相同的 entry / robin 仲裁状态寄存器，关掉“合并同值重复寄存器”pass，
# 避免跨 wrapper/u_core 边界把同值寄存器折叠成两侧不对称。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS

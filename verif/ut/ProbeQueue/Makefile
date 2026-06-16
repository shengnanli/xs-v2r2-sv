MODULE = ProbeQueue

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包。可读核例化 golden 的 ProbeEntry / Arbiter8_MainPipeReq 黑盒
# （队列级逻辑重写，entry 状态机与固定优先仲裁沿用 golden 黑盒），故 RTL_SRCS 需带上
# 这两个子模块文件供两侧/FM impl 解析。
RTL_SRCS = $(RTL_DIR)/memblock/probequeue_pkg.sv \
           $(RTL_DIR)/memblock/ProbeQueue.sv \
           $(GOLDEN_RTL)/ProbeEntry.sv \
           $(GOLDEN_RTL)/Arbiter8_MainPipeReq.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 ProbeQueue（其例化的 entry/arbiter 黑盒已在 RTL_SRCS 提供，避免重复编译）。
GOLDEN_SRCS = $(GOLDEN_RTL)/ProbeQueue.sv

# FM：golden 顶层 ProbeQueue（含黑盒）vs 手写同名 wrapper（→ 可读核 + 同名黑盒）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/ProbeQueue_wrapper.sv
FM_VARIANTS = ProbeQueue
FM_REF_DEPS_ProbeQueue = ProbeEntry.sv Arbiter8_MainPipeReq.sv

# 8 份结构相同的 entry 寄存器 + selected_req 一拍延迟寄存器，关掉“合并同值重复寄存器”
# pass，避免跨 wrapper/u_core 边界把同值寄存器折叠成两侧不对称。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal。
VCS += +define+SYNTHESIS

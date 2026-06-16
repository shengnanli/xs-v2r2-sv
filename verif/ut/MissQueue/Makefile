MODULE = MissQueue

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 其类型包 + 内联片段（svh 由 SV 编译时 `include 进核，不单列）。可读核例化
# golden 的 MissEntry / CMOUnit / FastArbiter 黑盒（队列级逻辑重写，entry/CMO 状态机与 amo
# 仲裁沿用 golden 黑盒），故 RTL_SRCS 需带上这三个子模块文件供两侧/FM impl 解析。
RTL_SRCS = $(RTL_DIR)/memblock/missqueue_pkg.sv \
           $(RTL_DIR)/memblock/MissQueue.sv \
           $(GOLDEN_RTL)/MissEntry.sv \
           $(GOLDEN_RTL)/CMOUnit.sv \
           $(GOLDEN_RTL)/FastArbiter.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 MissQueue（其例化的子模块黑盒已在 RTL_SRCS 提供，避免重复编译）。
GOLDEN_SRCS = $(GOLDEN_RTL)/MissQueue.sv

# FM：golden 顶层 MissQueue（含子模块黑盒）vs 手写同名 wrapper（→ 可读核 + 子模块黑盒）。
WRAPPER_SRCS = $(RTL_DIR)/memblock/MissQueue_wrapper.sv
FM_VARIANTS = MissQueue
# golden ref 侧依赖子模块；impl 侧 wrapper→u_core 也例化同名子模块，FM 按名配对为黑盒。
FM_REF_DEPS_MissQueue = MissEntry.sv CMOUnit.sv FastArbiter.sv

# 16 条结构相同的 entry + 仲裁状态寄存器，关掉“合并同值重复寄存器”pass，
# 避免跨 wrapper/u_core 边界把同值寄存器折叠成两侧不对称。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 内含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal。
# 同时加 incdir 让可读核能找到内联 svh 片段（端口/entry例化/仲裁/forward/btot）。
VCS += +define+SYNTHESIS +incdir+$(RTL_DIR)/memblock

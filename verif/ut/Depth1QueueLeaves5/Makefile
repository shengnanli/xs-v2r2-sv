MODULE = Depth1QueueLeaves5

# 族 D：5 个深度 1 队列叶（chisel3 Queue entries=1 的单态化，prereg 族 D）。
# 三种子形态共用一个共享核 rtl/common/xs_ChiselQueue1_core.sv（已随
# Queue1_ChosenQBundle 签核，本族只读复用、不修改）：
#   PIPE=1（enq_ready = deq_ready | ~full）：Queue1_PrefetchReq / Resp / Train
#   PIPE=0（enq_ready = ~full）           ：Queue1_BundleMap
#   无 ready 端口（deq_ready 恒 1 被折叠）：Queue1_UInt32（按 PIPE=1 + deq_ready=1 例化）
# 薄文件由 scripts/gen_depth1queue_leaves5.py 生成（--check 幂等）。
RTL_DIR = ../../../rtl
RTL_SRCS = $(RTL_DIR)/common/xs_ChiselQueue1_core.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchReq.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchResp.sv \
           $(RTL_DIR)/frontend/Queue1_PrefetchTrain.sv \
           $(RTL_DIR)/frontend/Queue1_UInt32.sv \
           $(RTL_DIR)/uncore/Queue1_BundleMap.sv
TB_SRCS = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/Queue1_PrefetchReq.sv \
              $(GOLDEN_RTL)/Queue1_PrefetchResp.sv \
              $(GOLDEN_RTL)/Queue1_PrefetchTrain.sv \
              $(GOLDEN_RTL)/Queue1_UInt32.sv \
              $(GOLDEN_RTL)/Queue1_BundleMap.sv
FM_VARIANTS = Queue1_PrefetchReq Queue1_PrefetchResp Queue1_PrefetchTrain \
              Queue1_UInt32 Queue1_BundleMap

# 端口表由生成器逐字取自 golden（含顺序），顺序不一致也算失败。
PORTLINT_ORDER = fail

include ../../../scripts/ut_common.mk

# ram（payload 寄存器）按 golden 不复位：双例化 UT 只能用常量初值档 ——
# +vcs+initreg+random 会给两个实例各摇各的 ram 初值，空队列读 deq_bits 必不等
# （与重写无关）。编译期 +vcs+initreg+random 只是打开机制，取值由 SIM_ARGS
# 在运行期选 +0（CONVENTIONS 2026-09-17 更正的用法）。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += +vcs+initreg+0

MODULE = StoreQueue

RTL_DIR = ../../../rtl
GOLDEN_RTL = ../../../golden/chisel-rtl

# 手写可读核 + 类型包（核通过 `include 引入端口表 / 子模块实例表 / 各分节 body）
RTL_SRCS = $(RTL_DIR)/memblock/storequeue_pkg.sv \
           $(RTL_DIR)/memblock/StoreQueue.sv

TB_SRCS = variants_xs.sv tb.sv

# golden 顶层 StoreQueue + 5 个数据存储子模块。UT 双例化两侧共用这些 golden 子模块
# （可读核与 golden 顶层各自例化同一份 SQDataModule/SQAddrModule/.../StoreExceptionBuffer）。
GOLDEN_SRCS = $(GOLDEN_RTL)/StoreQueue.sv \
  $(GOLDEN_RTL)/SQDataModule.sv $(GOLDEN_RTL)/SQData8Module.sv \
  $(GOLDEN_RTL)/SQAddrModule.sv $(GOLDEN_RTL)/SQAddrModule_1.sv \
  $(GOLDEN_RTL)/DatamoduleResultBuffer.sv $(GOLDEN_RTL)/StoreExceptionBuffer.sv

# FM：golden 顶层 StoreQueue vs 手写同名 wrapper（→ 可读核 + pkg）。
# 两侧都读入同一批 golden 子模块（5 个数据存储子件），使 ref/impl 各自把这些子模块
# 实化为同一份定义、内部寄存器逐位等价、自动配对通过；FM 真正验证的是控制逻辑
# （指针/状态机/forward/出队仲裁/mmio·nc·cbo FSM）相对真实子模块输出是否等价。
GOLDEN_SUBS = \
  $(GOLDEN_RTL)/SQDataModule.sv $(GOLDEN_RTL)/SQData8Module.sv \
  $(GOLDEN_RTL)/SQAddrModule.sv $(GOLDEN_RTL)/SQAddrModule_1.sv \
  $(GOLDEN_RTL)/DatamoduleResultBuffer.sv $(GOLDEN_RTL)/StoreExceptionBuffer.sv

WRAPPER_SRCS = $(RTL_DIR)/memblock/StoreQueue_wrapper.sv $(GOLDEN_SUBS)
FM_VARIANTS = StoreQueue
FM_REF_DEPS_StoreQueue = SQDataModule.sv SQData8Module.sv SQAddrModule.sv \
  SQAddrModule_1.sv DatamoduleResultBuffer.sv StoreExceptionBuffer.sv

# 56 表项结构相同的状态寄存器，关掉“合并同值重复寄存器”pass，避免折叠成两侧不对称。
# 关合并：golden 的 next_r 副本带 holdUnless 自反馈不会被合并，而 impl 侧为配平复制的
# pendingPtrDup/rdNextPtrDup 等纯同值副本反而会被合并 pass 折叠掉（钉点失效）。
FM_MERGE_DUP = false

include ../../../scripts/ut_common.mk

# golden 子模块含 XSError/XSPerf/assert（非综合）；UT 关掉以免随机激励触发 $fatal
VCS += +define+SYNTHESIS
# 让 `include 找到 rtl/memblock 下的 .svh（端口表 / 实例表 / 各分节 body）
VCS += +incdir+$(RTL_DIR)/memblock

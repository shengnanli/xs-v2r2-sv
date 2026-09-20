MODULE = VirtualLoadQueue

RTL_DIR  = ../../../rtl
RTL_SRCS = $(RTL_DIR)/memblock/VirtualLoadQueue.sv
TB_SRCS  = tb.sv

GOLDEN_SRCS = $(GOLDEN_RTL)/VirtualLoadQueue.sv
FM_VARIANTS = VirtualLoadQueue

include ../../../scripts/ut_common.mk

# golden 里的 XSError / XSDebug / XSPerf 都在 `ifndef SYNTHESIS 块内；
# UT 与 FM 两侧都带 +define+SYNTHESIS，随机激励不会触发 $fatal。
VCS += +define+SYNTHESIS +vcs+initreg+random
SIM_ARGS += $(INITREG)
INITREG ?= +vcs+initreg+random

# ===========================================================================
# ★FM 预期 passing —— 跑 FM **之前**写下并提交（CONVENTIONS 收口定式第 4 条）★
#
# 模型： passing = 闭包触发器位 + 顶层输出端口位
#
# 闭包触发器位（对着 golden 的 `reg` 声明逐条数出来的，不是估的）：
#   allocated        72 x 1 =   72
#   isvec            72 x 1 =   72
#   committed        72 x 1 =   72
#   uopIdx           72 x 7 =  504
#   robIdx_flag      72 x 1 =   72
#   robIdx_value     72 x 8 =  576
#   lastNeedCancel_r 72 x 1 =   72
#   enqPtrExt_0        1+7  =    8
#   deqPtr_r           1+7  =    8
#   lastCycleRedirect_valid      1
#   lastLastCycleRedirect_valid  1
#   lastEnqCancel_next_r         8
#   redirectCancelCount          8
#   lastCommitCount_next_r       4
#   io_lqDeq_next_r              4
#   io_lqEmpty_REG               1
#                        小计 = 1483
#
# 顶层输出端口位（golden 122 个端口里的 9 个 output）：
#   io_enq_canAccept 1 + io_ldWbPtr_flag 1 + io_ldWbPtr_value 7 + io_lqEmpty 1
# + io_lqDeq 4 + io_lqCancelCnt 7 + io_lqDeqRobIdx_flag 1
# + io_lqDeqRobIdx_value 8 + io_lqDeqUopIdx 7
#                        小计 =   37
#
#   ★预期 passing = 1483 + 37 = 1520★   failing/unmatched/unread 全 0
#
# 注意 golden 里 **没有** 这些（Scala 有但被 firtool DCE 掉），所以它们不计入：
#   debug_mmio[72] / debug_paddr[72x48] —— 只写不读的调试阵列
#   enqPtrExt(1..5)                     —— 只喂自己，对外不可观测
#   io.lqFull / io.enq.resp / io.ldin.ready —— 端口根本没生成
# 重写件同样不写它们；写了就会多出没有对家的 impl-only 点。
#
# 实测结果见本目录 FM_RESULT 注记（签核后补写在下面）。
# ===========================================================================

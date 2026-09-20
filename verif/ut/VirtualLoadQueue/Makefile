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

# ===========================================================================
# ★FM 实测（agent/vlq）★
#
# 首跑（commit 68d818fb+117b47dd）: native **FAILED**
#   匹配 1520 个比较点 = 765 按名 + 755 按签名，两侧 unmatched 0(0)
#   Passing  Port 21 / DFF 1483 = 1504
#   Failing  Port 16 / DFF    0 =   16
#   ★比较点总数 1520 与跑前登记的模型 **完全一致（差 +0）**，失败的是逻辑不是模型。★
#   16 个失败点 = io_lqDeqRobIdx_flag(1) + io_lqDeqRobIdx_value(8) + io_lqDeqUopIdx(7)。
#   根因（真 bug，UT 三 seed 两轮全绿也看不见）：
#     deqPtr.value 是 7 位寄存器，可表示 0..127，而队列只有 72 个条目。
#     golden 把 robIdx_flag / robIdx_value / uopIdx 摊成 **128 项** 读向量
#     （VirtualLoadQueue.sv:1731 / 1860 / 1989），下标 72..127 那 56 项**全部填条目 0**
#     —— 这是 firtool 对越界常量下标的填法。可读核的 for 循环把默认值写成了 '0。
#     仿真按构造够不着：deqPtr 只经环形加法更新，实际取值恒 <= 71；
#     Formality 会枚举这些不可达取值，一开就现形。
#   修法见 commit 97ce6679：默认值改成条目 0（bug-for-bug，不是"顺手修好"）。
#
# 重跑（commit 97ce6679）: native **SUCCEEDED**
#   Passing  Port 37 / DFF 1483 = **1520**   Failing 0
#   unmatched 0(0) / unread 0 / 黑盒 0 / 无 dont_verify / 无 ELAB 降级
#   verdict(signoff-strict) = SUCCEEDED
#
# ★★关于"预测 1520 对上了"这句话，必须加一条前提（集成者 0920 更正）★★
#   passing = 闭包触发器位 + 顶层输出端口位 这个模型
#   **只在 verification_merge_duplicated_registers = false 时成立**。
#   merge 打开时 FM 会把重复寄存器合并成一个比较点，比较点数低于寄存器位数，
#   低多少取决于设计里有多少重复结构 —— 不是能从 golden 静态算出来的量。
#   ★本目标这两跑用的是 merge_dup = **true**（ut_common.mk 的默认值，我没设
#   FM_MERGE_DUP）★，所以按判据口径它是 **MODEL_NA（模型不适用）**：
#   实测 1520 与预登记 1520 逐列相等是个**事后观测**，不是模型给出的绿灯。
#   （sidecar/native_facts.json 的 entry_appvars 里
#     verification_merge_duplicated_registers = true，可复核。）
#   为什么这里仍然相等：1520 = 1483 DFF + 37 Port，DFF 位一个没少，
#   说明这个设计**根本没有被合并掉的重复寄存器**。这不是推断，是跑出来的：
#
#   ★merge_dup=false 对照跑（模型在这个条件下才成立）★
#   commit 46bca5d516ea，evidence/46bca5d516ea/VirtualLoadQueue/：
#     FM_MERGE_DUP=false（sidecar entry_appvars 里
#     verification_merge_duplicated_registers = false，可复核）
#     Passing Port 37 / DFF 1483 = **1520**，failing 0 / unmatched 0(0) / unread 0
#     verdict=SUCCEEDED，MAKE_RC=0，dirty=False
#   两跑逐列完全相同 ⇒ merge 开关对本目标不改变任何比较点，
#   即「没有可合并的重复寄存器」是**实测**而非假设；
#   于是在模型成立的那个条件下，**预登记 1520 == 实测 1520，差 +0**。
#   关掉 merge 是加强不是放宽：比较点只增不减，不黑盒、不跳点、不约束 ref。
#
#   官方 receipt: scripts/run_proof.sh 在 detached clean worktree 上重跑一次,
#   verdict=SUCCEEDED / dirty=False / MAKE_RC=0, 证据 evidence/2844576edd7a/VirtualLoadQueue/。
#
# UT 实测: seed 1/7/42 x (+vcs+initreg+0, +vcs+initreg+random) **六轮全跑**,
#   每轮 200000 拍、逐拍比全部 9 个输出, compared=199994, errors=0 (6/6 PASSED)。
#   ★两轮 initreg 都绿在这里**不**证明复位域正确★: tb 的 fill 段按构造把三个无复位
#   阵列在比较窗口打开前写成确定值, 所以两轮必然同结果。复位域的把关在 FM ——
#   两个 always 块的分组(异步复位域 9 组 / 无复位域 6 组)与 golden 逐个寄存器对齐,
#   1483 个触发器位全部 passing。
# ===========================================================================

# IssueQueue* 家族（14 变体）差异矩阵与共享核判断（iqfam lane）

机器可读表：`verif/ut/IssueQueue_common/matrix.tsv`，由 `verif/ut/IssueQueue_common/gen_matrix.py`
从 G1 golden 实测生成（`--check` 比对）。条目阵列参数取自已签核的
`verif/ut/Entries_field_matrix/matrix.tsv`。本文件是"动手之前"的判断，数字全部可由脚本复算。

## 1. 全家族一致的部分（→ 写进共享核）

| 维度 | 实测 | 含义 |
|---|---|---|
| numEnq | 14/14 = 2 | 入队口 2 个；入队条目区 = 2 条目，全部用 NewAgeDetector(_6) 选最老 |
| 条目分区 | 14/14 都是 enq + simp + comp（`hasCompAndSimp`） | 选择结构走 Chisel 的同一个分支：comp 优先、其次 simp、最后 enq |
| DeqPolicy（deqFuSame） | 14/14 = 0 | 两发射口 FU 完全不同，没有"同 FU 双发射"分支 |
| 年龄选择器 | 每个 IQ 恰好 1 个 NewAgeDetector* + 2 个 AgeDetector*（simp 口数 = numDeq+numEnq） | simp 那个 AgeDetector 另带 2 个"转移请求"口（requestForTrans） |
| 入队源数 | 14/14 = 5 个 srcType 端口 | 入队时 srcState/dataSources 按 srcType+psrc 重算、srcLoadDependency 左移一位 |
| 寄存器种类 | deqDelay（出队打一拍，`|valid` 使能，不复位）+ GTimer 性能计时器（每发射口 2×64 位，异步复位）+ validCntDeqVec 打拍 + （仅 Ldu）load 唤醒打拍 | `regBits_other` 列 14/14 为 `-`：**没有别的寄存器** |
| 被 DCE 的 Chisel 输出 | io.status.* 全部不在端口表里 | 共享核不产出 status |

## 2. 逐变体不同的部分（→ 参数或 wrapper 连线）

| 维度 | 取值（见 matrix.tsv 同名列） | 处置 |
|---|---|---|
| numEntries / numSimp / numComp / numDeq | 24/6/16/2 … 10/2/6/1 | 核参数 |
| 发射口可接受的 FuType 位 `deqAcceptFu` | 如 AluCsrFenceDiv：口0={6}、口1={5,8,9} | 核参数（每口一个位掩码，按条目保留的 FuType 位编号） |
| 出队负载字段 `regBits_deqDelay` | 902 … 1772 位，两口字段集不同（口0/口1 各自一张表） | wrapper 按 golden 端口表拼包，核只做"使能打一拍"；核里算的字段（addrOH/iqIdx/fuType/dataSources/exuSources/loadDependency/性能时间）由核输出再拼进去 |
| 忙表（FuBusyTable*） | 0 … 18 个实例、种类 fu/int/fp/vf/v0/vl 组合各异 | 实例留在 wrapper（已签核件），每口的若干 mask 送核做 `canIssue & ~mask` |
| 唤醒出口 `wakeupToIQ` | MWQ（6 个 Alu*/Falu*）/ LOAD_REG（Ldu）/ 无（7 个） | MWQ 实例在 wrapper；lat 查表、is0Lat、`valid&wen` 门控在核（参数化）；Ldu 的 load 唤醒打拍在核（参数开关） |
| validCntDeqVec 输出 | 0,1 / 0 / 无 | 核参数（每口开关 + 位宽） |
| 向量类输入 og2Resp / vl* | 5 个 VEC 变体 | 纯连线到 Entries（wrapper） |
| 访存类 feedback / loadWakeUp / lqDeqPtr / finalIssueResp | Sta/Ldu/VlduVstu* | 连线到 Entries（wrapper）；VecMem 入队的 `blocked`（`!isFirstLoad && isVleff`）是逻辑，进核（参数开关） |
| IQ 即时唤醒 / og0Cancel / ldCancel / replaceRCIdx | INT/MEM 族有、FP 部分有、VEC 无 | 纯连线到 Entries；replaceRCIdx 直通 wakeupToIQ.rcDest |

## 3. 判断：共享核能覆盖多少

**全部 14 个变体的"IQ 自身逻辑"可以由一个参数化核覆盖**：
入队翻译（srcState/dataSources/loadDependency）+ 入队 ready + 三段选最老的组合与 deqSelOH +
按 selOH 的 Mux1H（dataSources/exuSources/loadDependency）+ iqIdx/fuType 重组 + deqDelay 打拍 +
性能计时器 + validCntDeqVec + wakeupToIQ 的门控/lat 查表。

逐变体差异全部是**参数**或**连线**，没有发现需要变体专属分支的逻辑，除了两处小开关：
Ldu 的 load 唤醒打拍（`LOAD_WAKEUP`）与 VecMem 入队 `blocked`（`VECMEM_BLOCKED`）。

wrapper 很大（端口 456–721 个，Entries 实例连线 600–870 个），必须由生成器从 golden 端口表与
golden 实例连线**机械**产出，规则 fail-closed：每个 golden 子模块端口要么接同名顶层端口/常量、
要么接另一个子模块的输出、要么接核的某个输出，三者都不中就生成失败。golden 表达式里的逻辑
一律不许抄进 wrapper（那是 svh 套壳的变体）。

## 4. FM 口径预判（canary 前）

* 子模块两侧白盒：Entries*（PROVEN）、FuBusyTable*（PROVEN）、MultiWakeupQueue*（本 lane 已签）、
  NewAgeDetector*（本 lane 已签）、AgeDetector*（PROVEN）。
* Entries 子树寄存器 ~25k 个，golden 平铺名 vs 重写数组名：单独签 Entries 时用了 ~2 万条钉点
  （`verif/ut/Entries<V>/fm_pins_pre.tcl`）。IQ 父级把同一张钉点表加上实例前缀 `entries/` 复用
  （生成器机械变换，计数照样 fail-closed），否则 matching 大概率卡死。
* Entries 单签时的 matched-unread（死负载位，vmucp）在父级里预计同样出现，按 vmucp 六条处置。

## 5. 顺序

1. canary：IssueQueueAluCsrFenceDiv（INT 族，24 条目 / 2 口，MWQ_2 + 1 个忙表）走通 UT+FM。
2. 其余 13 个按族铺开：INT（AluBrh/AluMul）→ FP（3）→ MEM（Ldu/Sta/Std）→ VEC（5）。
3. 余力：Scheduler / _1 / _2 / _3。

## 6. 结果（事后追加）

- §3 的判断成立：14 个 IssueQueue 变体共用一个手写核 `rtl/backend/xs_IssueQueue_core.sv`（479 行）；
  逐变体差异全部落成参数或生成器连线（`scripts/gen_iq.py`），实际需要的变体专属开关比预判多两类：
  写回忙表 deqResp.valid（出队 valid && 写使能）、og1 失败冲刷 / lat 查表 / is0Lat（MWQ 胶合）。
- 生成器的 fail-closed 规则在 14 个变体上跑通：golden 表达式里的逻辑没有一处被抄进 wrapper
  （readability_audit G 类：wrapper 代码区与 golden 逐字重合 ≤ 0.4%）。
- 一个真 bug 由 FM 抓到、UT 结构上看不见：向量 IQ 条目只存 7 位 psrc，但 "psrc==0" 必须按 Dispatch 端口的 8 位判。
  修法是给核的 PSRC_W 取端口宽（生成器一行），UT 激励池补 0x80..0x83 后能复现。
- FM 父级的主要工作量在钉点：条目阵列（复用 Entries 钉点表）之外，IQ 父级里常量化/无出口的寄存器
  （条目状态 dataSources、MWQ/流水 fuType、忙表写寄存器、validCnt 高位）签名失效，逐类补钉后全部 matched。
- Scheduler 4 个也签完：核 `xs_Scheduler_core.sv`（性能事件 + sta/std 成对派遣）+ `scripts/gen_sched.py`；
  父级钉点 = 各 IQ 钉点加前缀 + IQ 的 deqDelay 负载与性能计时器（调度器里大多没有出口）。

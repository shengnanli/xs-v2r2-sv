# L2 Slice child lane（agent/l2slice）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `785649ac`（main，`git worktree add /home/eda/xs-env/wt-l2slice -b agent/l2slice main`） |
| 工作树 | `/home/eda/xs-env/wt-l2slice`，分支 `agent/l2slice` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| Scala | `/home/eda/xs-env/XiangShan/coupledL2/src/main/scala/coupledL2/`（tl2chi/ 下为 CHI 版 Slice/MainPipe/TXDAT/RXSNP；公共件在上层目录） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |
| codex 冲突 | 0197 最新认领 50 叶（Pmpaddr*/Pmaaddr31/ShiftRightJam*/RightShift*），与本 lane 无交集；codex/* 分支无 coupledL2 相关 rtl 改动 |

## 1. L2Slice / L2Slice_1 / L2Slice_2 / L2Slice_3

### 1.1 结构

- `utility.mbist.MbistPipeline` 在 Slice 层的单态化：中间节点，2 个 child（child0 = Directory 层
  L2Directory*，child1 = DataStorage 层 L2DataStorage*）。`scripts/gen_mbist_pipe_family.py --scan-adjacent`
  机器判定四者都能原样套 `rtl/dft/xs_mbist_pipe_core.sv`（IS_NODE=1）；生成器新增 EXTRA_MODS，
  每个 golden 语句套模板 + 读数据归约逐位符号执行（L2Slice 1281 次等）通过后才出薄文件。
- 0 子模块、0 黑盒。唯一不复位寄存器 `pipelineDataOutReg`。

### 1.2 UT（verif/ut/L2Slice，四对同测；commit 2654e066 的字节）

逐拍 4 态比四个变体全部 80 个输出；tb 由 `verif/ut/L2Slice/gen.py` 生成。

| seed | initreg+0 | initreg+random | initreg+<seed>017 |
|---|---|---|---|
| 1  | checks=16000000 errors=0 | errors=0 | errors=0 |
| 7  | errors=0 | errors=0 | errors=0 |
| 42 | errors=0 | errors=0 | errors=0 |

覆盖（seed 1）：各变体 80/80 输出翻转；L2Slice selected(child0)=97578 拍、selected_1=55762、activated=134517。
变异自检（scratch，不进库）：M1 reqReg 改成 activated 才更新 ⇒ errors=47099（20k 拍）CAUGHT；
M2 child1 ID_LO 0x09→0x0A ⇒ elaborate 期 $fatal 拦下。
复跑：`cd verif/ut/L2Slice && make run SEED=<s> INITREG=<0|random|<s>017>`

### 1.3 跑前预测（★跑完不许改本节★）

| 目标 | passing | 其余 |
|---|---|---|
| L2Slice   | **766**（regs 316 + outs 450） | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| L2Slice_1 | **769**（317 + 452） | 同上 |
| L2Slice_2 | **771**（318 + 453） | 同上 |
| L2Slice_3 | **772**（318 + 454） | 同上 |

无 vmucp、无 fm_pins。MbistPipe* 家族 24 变体用同一核已签，预期无意外。
可能出错处：dataInReg 高 33 位只被 child1 读、beReg[7:1] 只被 child0 读——都被读，预期 unread=0。

## 2. MSHRBuffer / MSHRBuffer_1

### 2.1 结构

- `coupledL2.MSHRBuffer(wPorts)` 的两个单态化：refillBuf（2 写口，w_0 带 beatMask）、releaseBuf（3 写口，
  beatMask 被 firtool 折叠为常量 2'h3）。共用核 `xs_MSHRBuffer_core`（rtl/uncore/MSHRBuffer.sv），
  MSHRBuffer_1.sv 为薄 wrapper。存储 16 槽 × 2 beat × 256 位不复位；读口 RegEnable 异步复位。
- G0→G1 golden 两者均 0 行差异。0 子模块、0 黑盒。golden 的 assert 在 `ifndef SYNTHESIS 内。

### 2.2 UT（verif/ut/MSHRBuffer，两对同测；commit 9d5de5be）

| seed | initreg+0 | initreg+random | initreg+<seed>017 |
|---|---|---|---|
| 1/7/42 | checks=400000 errors=0 ×3 | errors=0 ×3 | errors=0 ×3 |

覆盖（seed 1 random）：读 100168 拍；w_0 部分 beat 写 58927；两口同槽冲突 1944（_1 的 w1/w2 冲突 1894）；
读 id 高位非 0 的 21273。变异：写口优先级反转 errors=781；id 只比低 4 位 errors=9305；忽略 beatMask errors=7577，均 CAUGHT。

### 2.3 跑前预测（★跑完不许改★）

| 目标 | passing | 其余 |
|---|---|---|
| MSHRBuffer   | **9216**（regs 8704 + outs 512） | failing 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| MSHRBuffer_1 | **9216**（8704 + 512） | 同上 |

可能出错处：golden 扁平名 `buffer_<i>_<b>` 与重写 `buffer[i][b]` 靠 FM 名字规整配对；若 matching 卡住或
unmatched≠0，先生成 fm_pins_pre 再谈别的。未做任何 FM 试跑。

## 3. L2 Queue 单态化 ×5（TXDAT / RXSNP / GrantBuffer 的 child）

### 3.1 结构

- 共享控制核 `rtl/common/xs_ChiselQueue_core.sv`（chisel3 Queue：指针/空满/flow 旁路/count，手写），
  薄文件 `rtl/uncore/Queue*.sv` 由 `scripts/gen_l2_queues.py`（带 --check，已进 gate_all）从 golden 生成：
  解析 W0_data 拼接顺序推每个字段 [hi:lo]，与 golden 每条 io_deq_bits_* 切片逐字段比对，对不上即失败。
- 存储 = golden `ram_<D>x<W>` 行为级叶子，按 D60 两侧同源 inline（RTL_GOLDEN_DEPS + FM_REF_DEPS），无黑盒。
  五者深度都是 2 的幂（16/16/2/16/16），不触发 ELAB-147。
- Queue10_GrantBuffer_Anon（ram_10x89，深度 10 非 2 的幂）**不在本批**：见 §6 阻塞说明。

### 3.2 UT（verif/ut/L2Queues，五对同测；commit f4328c53）

| seed | initreg+0 | initreg+random | initreg+<seed>017 |
|---|---|---|---|
| 1/7/42 | checks=7000000 errors=0 ×3 | errors=0 ×3 | errors=0 ×3 |

覆盖（seed 1）：各队列满 48050~63272 拍、出队 50929~75784；flow 直通（空队列同拍进出）DSBeat 24136 / TaskBundle 24467。
变异：去掉 flow 直通时的 do_enq 压制 errors=56741 CAUGHT；TaskBundle resp 切片错位 errors=11679 CAUGHT；
maybe_full 改成"入置 1、出清 0（同拍进出时置 1）"UT 存活 —— 经分析为**等价变异**（maybe_full 只在
ptr_match 时有意义，而同拍进出不改变 ptr 差值、不会让指针相遇），不是漏检。

### 3.3 跑前预测（★跑完不许改★）

| 目标 | passing | 其余 |
|---|---|---|
| Queue16_DSBeat         | **4361**（regs 4105 + outs 256） | failing 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| Queue16_TaskBundle     | **1155**（1081 + 74） | 同上 |
| Queue2_CHISNP          | **299**（199 + 100） | 同上 |
| Queue16_GrantQueueTask | **441**（409 + 32） | 同上 |
| Queue16_GrantQueueData | **4361**（4105 + 256） | 同上 |

可能出错处：Queue2_CHISNP 的 golden 指针名是 `wrap`/`wrap_1`（深度 2 的 Counter 命名），重写叫 enq_ptr/deq_ptr，
靠 FM 签名配对；若 unmatched≠0 先查这里。

## 4. TXDAT

### 4.1 结构

- 可读核 `xs_TXDAT_core`（§1 反压在飞计数 / §2 两拍发送寄存器 / §3 CHI DAT 报文组装），wrapper 例化三个队列
  （实例名 queue/queueData0/queueData1 与 golden 一致）。child 两侧白盒：ref golden、impl 本 lane 重写件（§3）。
- ★bug-for-bug★：golden 的流水线在飞数只有 2 位（Chisel `PopCount(3)+PopCount(1)` 不扩位），4 路同时在飞算成 0。
  第一版按"最大 20、5 位不溢出"写成 3 位，UT 当场 blockSinkBReqEntrance 失配，改为照搬 2 位截断。

### 4.2 UT（verif/ut/TXDAT；commit f4328c53）

| seed | initreg+0 | initreg+random | initreg+<seed>017 |
|---|---|---|---|
| 1/7/42 | checks=3800000 errors=0 ×3 | errors=0 ×3 | errors=0 ×3 |

覆盖（seed 1）：取任务 38414、发第二拍 38361、deassertBE 报文 65137、挡 SinkB 163006、不挡 2648、仅挡 MSHR 34346、
流水线 4 路同时在飞（截断场景）115。变异：在飞计数改 3 位 errors=16；dataID 第二拍 2→1 errors=11816；
去掉 WriteDataCancel 判据 errors=15993，均 CAUGHT。

### 4.3 跑前预测（★跑完不许改★）

| 目标 | passing | 其余 |
|---|---|---|
| TXDAT | **10264**（regs 9872 + outs 392；含三个队列与其 ram） | failing 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |

### 4.4 对账（第一跑，vmucp 关）+ 第二跑登记

- 第一跑（commit b1167e89，evidence/b1167e89e520/TXDAT）：native SUCCEEDED，passing **10196**，failing 0，unmatched 0(0)，
  **unread 68** ⇒ strict 判 PARTIAL。预测 10264，差 68 = unread 68，逐点指认：
  TaskBundle.off[3:0] 的对称死位（队列 ram 16×4 位 + taskR 4 位；TXDAT 只用 off[5:4] 作 CCID）。
  §4.3 登记的"unread 0"**预测错了**——我没把 Bundle 里只被部分读的字段算进去。
- 第二跑（本节提交后）：按 vmucp standing rule 六条加 verif/fm_target_config/TXDAT.tcl + Makefile 开 vmucp。
  登记：passing **10264**（= 10196 + 68），unread 0，failing/unmatched 0，SUCCEEDED。

## 5. L2DataStorage ×4、MbistClockGateCell_93、ClockMux（DataStorage 子树的叶子）

### 5.1 结构

- L2DataStorage / _1 / _2 / _3：MbistPipeline 在 DataStorage 层的 **extraHold 叶子**（读/写使能 2 位展宽寄存器，
  golden 无 wenReg/renReg）。新核 `rtl/dft/xs_mbist_hold_leaf_core.sv`（只写与 xs_mbist_pipe_core 不同之处）；
  薄文件由 gen_mbist_pipe_family.py（parse 识别 hold、EXTRA_MODS）生成，24 个旧变体产物与 json 字节不变。0 子模块。
- MbistClockGateCell_93：SRAM 读时钟门控（MBIST/DFT 使能 + mcp_hold + aux 时钟旁路）；child ClockGate 为锁存器
  单元模型（非 firtool，GOLDEN_REUSE 先例：SRAMTemplate_145 / DuplicatedTagArray / BitmapCache），两侧同源读 golden；
  child ClockMux 本 lane 重写（1 行组合）。

### 5.2 UT（commit 6e5509c0）

| UT | seed 1/7/42 × initreg {0, random, <seed>017} |
|---|---|
| verif/ut/L2DataStorage（四对） | checks=30400000 errors=0 ×9 |
| verif/ut/ClockGateCell93（两对，--both-phases 高/低相位各比一次） | checks=800000 errors=0 ×9 |

覆盖（seed 1 random）：L2DataStorage activated 112442、child0/3 命中 16904/16581、展宽尾拍 40511（_1.._3 同量级）。
变异：展宽改一拍清零 errors=59877、re 取展宽高位 errors=59492；ClockGate 去掉 mcp_hold errors=1533、MBIST 使能漏写口
errors=316，均 CAUGHT。★自抓★：第一次 mcp_hold 变异"存活"，查出是 harness 的文本替换命中了**文件头注释**里的同一串
（没改电路），已给 mut.sh 加"首个命中不许在注释行"断言后重做；另外 ClockGate 的 UT 起初只在时钟低相位采样，门控使能
根本不可见，已加 --both-phases。

### 5.3 跑前预测（★跑完不许改★）

| 目标 | passing | 其余 |
|---|---|---|
| L2DataStorage   | **1000**（regs 174 + outs 826） | failing 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| L2DataStorage_1 | **1005**（175 + 830） | 同上 |
| L2DataStorage_2 | **1009**（176 + 833） | 同上 |
| L2DataStorage_3 | **1010**（176 + 834） | 同上 |
| MbistClockGateCell_93 | **2**（ClockGate 锁存器 1 + out 1） | 同上；锁存器在 FM 里的归类没把握，若不是 1 个比较点就指认差额 |
| ClockMux | **1**（outs 1） | 同上 |

## 6. RXSNP

### 6.1 结构

- 可读核 `xs_RXSNP_core`（§1 地址拆分 / §2 与 16 个 MSHR 逐个比对：reqBlock、cmoBlock、replaceBlock、replaceNest /
  §3 放行 / §4 嵌套信息：优先编码与 meta 按位或 / §5 死锁计数器），wrapper 例化 Queue2_CHISNP（实例名 queue）。
  MetaEntry 用包内私有 struct（`alias` 是 SV 保留字，字段名 alias_）。child Queue2_CHISNP 两侧白盒（§3 已签）。
- 寄存器：两组 16 个 RegNext(w_replResp)（golden 就是两份，不合并）+ 64 位 stallCnt（只被 assert 读）。

### 6.2 UT（verif/ut/RXSNP；commit 038ea1b3）

| seed 1/7/42 × initreg {0, random, <seed>017} | checks=5200000 errors=0 ×9 |
|---|---|

覆盖（seed 1 random）：stall 86196、snoop 出队 67829、嵌套放行 5301、嵌套命中号非 0 12764、replaceBlock 7998。
变异：replaceBlock 去掉 !RegNext(w_replResp) 项 errors=1949；优先编码缺省值 15→0 errors=18632；
cmoBlock 漏 !s_cmometaw errors=14005，均 CAUGHT。

### 6.3 跑前预测（★跑完不许改★）

模型 passing 上限 **423**（regs 295 + outs 128）。预计有两类两侧对称的未读寄存器位（vmucp 关时不进 passing）：
  * stallCnt[63:0]：只被 `ifndef SYNTHESIS 的 assert 读，自身 +1 回路之外无读者 → 64 位；
  * 队列 ram_2x98 里 addr[4:3]（slice bank 位，parseAddress 丢掉）：2 项 × 2 位 → 4 位。
第一跑（vmucp 关）登记：passing **355**、unread **68**、failing 0、unmatched 0 ⇒ strict 判 PARTIAL（预期内）；
随后按 vmucp standing rule 加 verif/fm_target_config/RXSNP.tcl 第二跑：passing **423**、unread 0、SUCCEEDED。

### 6.4 对账（第一跑）
- 第一跑（commit 09829392，evidence/09829392463d/RXSNP）：native SUCCEEDED，passing **355**、unread **68**、failing 0、unmatched 0(0)
  ⇒ PARTIAL，与 §6.3 登记逐位相等；68 点 = stallCnt 64 + Memory[0..1][55:54] 4，与预测的两类完全一致。
- 第二跑按 §6.3 登记（vmucp 开）：passing 423、unread 0、SUCCEEDED。

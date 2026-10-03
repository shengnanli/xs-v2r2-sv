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

## 7. DataStorage 子树（DataStorage ×4、GatedSplittedSRAM ×4）

### 7.1 结构

- `xs_DataStorage_core`：SECDED(128)=137 编码 ×4 bank、读回解码报 error（打两拍对齐 MCP2）、请求路由；
  Scala 三条 MCP2 assert 用到的 5 个影子寄存器照 golden 保留（mcpEnPrev/enPrev/reqPrev/wrEnPrev/wdataPrev）。
  ★Chisel `Cat(Vec)` 把第 0 片放最高位★：wdata[127:0] 的码字在阵列字 [547:411]，读回对称还原。
- wrapper（DataStorage / _1.._3）由 gen_l2_datastorage.py 生成；GatedSplittedSRAM* 纯连线（4 个 137 位 bank +
  4 个 MbistClockGateCell_93），由 gen_l2_gated_sram.py 逐实例逐端口比对 golden 后生成。
- 子树两侧白盒：SRAMTemplate_155/166/178（PROVEN_DIRECT）、MbistClockGateCell_93/ClockMux/L2DataStorage*（§5 本 lane）；
  两侧同源 golden：ClockGate、sram_array_1p4096x137m137s1h1l2b_l2_dat、array_18。
  唯一黑盒：厂商叶子 array_18_ext（vendor_boundary.tsv 审定的 vendor_sram_leaf），每目标 4 个/侧 → assembly。

### 7.2 UT（verif/ut/DataStorage；commit 6e5509c0 的 tb）

四对同测，~1 小时/档；9 档矩阵在后台串行跑（写本节时完成 seed1×initreg0：checks=3200000 errors=0），
全部读数在文末对账补齐。DFT 辅助时钟旁路（aux_ckbp/aux_clk）钉 0：随机翻转会在 tb 改输入的瞬间造出时钟沿，
与同刻改变的地址构成仿真竞争（golden 与重写 delta 深度不同），首跑因此报过假失配，定位过程见 commit 6e5509c0 前的
调试（两侧 SRAM 引脚逐拍相同、只有竞争相位不同）。

### 7.3 跑前预测（★跑完不许改★）

| 目标 | 模型 passing | 预计 unread（vmucp 关） | 第一跑 |
|---|---|---|---|
| GatedSplittedSRAM / _1 / _2 / _3 | 2272 各 | 0 | passing 2272，无 allow 声明 ⇒ assembly PARTIAL（缺 allow）|
| DataStorage / _1 / _2 / _3 | 2532 / 2533 / 2534 / 2534 | **529**（影子寄存器 1+1+14+1+512） | passing = 模型 − 529 ⇒ PARTIAL |

第二跑：按 declare_allow.py 由第一跑 black_boxes.rpt 生成 verif/allow/<T>.json（只允许 array_18_ext ×4/侧，
class vendor_macro），DataStorage 另加 vmucp 配置 ⇒ 全部 passing = 模型值、unread 0、SUCCEEDED。
（模型 passing 大于"寄存器位 + 输出位"是因为 assembly 下黑盒输入脚也是比较点。）

## 8. Directory 子树（Directory ×4、SplittedSRAM_3..6、L2Directory_1..3）

### 8.1 结构

- `xs_Directory_core`（§0 SECDED(31)=38 / §1 读握手 / §2 s2-s3 请求寄存 / §3 8 路读出锁存与占用路 / §4 命中选路 /
  §5 输出 / §6 DRRIP 集合决斗、next state、origin 位 HoldUnless、上电初始化）；wrapper 由 gen_l2_directory.py 生成
  （golden 内部线按其自身 `wire x = 式子` 展开后映射，任何未映射的 golden 局部名即失败）。
- SplittedSRAM_3..6：tag 阵列 2（way 组）×2（数据段）纯连线，gen_l2_splitted_sram.py 生成。
- L2Directory_1..3：MBIST 普通叶子，gen_mbist_pipe_family.py EXTRA_MODS（slice 0 的 L2Directory 用已签核的
  rtl/uncore/L2Directory.sv）。
- 子树白盒：SRAMTemplate_148/150/152/153/154/159/162/163/164/165/181/185/186/187（全部 PROVEN_DIRECT）；
  两侧同源 golden：sram_array_*_l2_{tag,meta,repl,orgb}、array_14..17；唯一黑盒 array_14..17_ext → assembly。
- 自抓一个仿真语义坑：第一版 resp_meta 写成 `assign resp_meta = meta_of(way_s3)`，function 体内读模块级数组 ——
  连续赋值只对实参敏感，数组变了不重算，UT 当场失配；改成 always_comb 直接索引（CONVENTIONS 已知坑的变体）。

### 8.2 UT（verif/ut/Directory、verif/ut/L2DirectoryVariants；commit da880c55 / 919b6f88）

Directory seed1 initreg0 20k 拍：checks=3040000 errors=0，覆盖 hit 2581 / miss 2239 / replResp 2451 / retry 42 /
BRRIP 监视组 refill miss 239 / tag ECC error 2343 / 初始化完成。（激励：set ∈ {0,1,2,240}，0 与 240 分别是 SRRIP /
BRRIP 监视组；每 4000 拍里 1000 拍把读与 MSHR 压到 set 0 制造 8 路全占 → retry；SRAM 行为级存储首沿前填同一套随机数。）
9 档 200k 矩阵在后台串行跑，读数在文末对账补齐。L2DirectoryVariants seed1 random 200k：checks 全比 errors=0。

### 8.3 跑前预测（★跑完不许改★）

| 目标 | 模型 passing | 预计 unread（vmucp 关） | 第一跑 |
|---|---|---|---|
| SplittedSRAM_3..6 | 1286 各 | 0 | passing 1286，缺 allow ⇒ PARTIAL |
| Directory / _1 / _2 / _3 | 1954 / 1955 / 1955 / 1956 | **16**（req_s2_wayMask / req_s3_wayMask：Scala 只在 perf 里读，两侧对称死位） | passing = 模型 − 16 ⇒ PARTIAL |
| L2Directory_1 / _2 / _3（strict，无黑盒） | 911 / 914 / 922 | 0 | SUCCEEDED |

第二跑：allow（array_14..17_ext，tag 阵列 4 块 + meta + repl + orgb = 7 个/侧）+ Directory 的 vmucp ⇒ 模型值、SUCCEEDED。

## 9. RequestArb

### 9.1 结构

- 可读核 `xs_RequestArb_core`（上电计数 / s0 MSHR 入口 / s1 C>B>A 挑任务、目录读、s1Entrance / s2 MCP2 stall、
  refillBuf / releaseBuf 读判定）。TaskBundle 用包内 `task_t` 结构体（94 字段 383 位），结构体、golden 同名
  wrapper、fm_pins_pre.tcl 由 `scripts/gen_l2_requestarb.py` 生成，并核对 sinkA/B/C/mshrTask/taskInfo_s1/taskToPipe_s2
  六组端口字段表完全一致、golden 两组任务寄存器与字段表一一对应。0 子模块、0 黑盒。
- （原计划）钉点：golden `mshr_task_s1_bits_<f>` / `task_s2_bits_<f>`（2 × 383 位）↔ 核里两个 task_t 结构体寄存器逐位，
  fail-closed 计数 766。★风险★：重写侧结构体寄存器在 FM 里的名字（`u_core/<name>_reg[bit]`）是按惯例推的，
  若不是这个名字，钉点会整体失败并 error（不会静默）。

### 9.2 UT（verif/ut/RequestArb；commit 3714b6a0）

seed1 random 200k：checks=46400000 errors=0（232/232 输出翻转）；覆盖 s0 进 49704、s1 进 78484、回填读替换 12563、
C/B/A 各被选 14378/7356/7076、refillBuf 读 8447、releaseBuf 读 31521。变异：B 不让 C 优先 errors=776、
releaseRefillData 漏 Evict errors=127、A-Hint 也触发 MCP2 stall errors=20418，均 CAUGHT。9 档矩阵后台跑，文末对账。

### 9.3 跑前预测（★跑完不许改★）

| 目标 | passing | 其余 |
|---|---|---|
| RequestArb | **1837**（regs 779 + outs 1058） | failing 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED；钉点 ok=766 |

### 7.4 / 8.4 对账（第一跑，commit 2690db30，evidence/2690db305435/）

| 目标 | 登记 | 实测 | 判读 |
|---|---|---|---|
| L2Directory_1 / _2 / _3 | 911 / 914 / 922 SUCCEEDED | **911 / 914 / 922 SUCCEEDED** | 逐位相等，签核完成 |
| GatedSplittedSRAM ×4 | 2272，缺 allow ⇒ PARTIAL | 2272 各，PARTIAL(assembly_no_allow_decl) | 与登记一致 |
| DataStorage / _1 / _2 / _3 | 模型 − 529 = 2003 / 2004 / 2005 / 2005 | **1988 / 1989 / 1990 / 1990**，PARTIAL | ★少 15，登记错了★：见下 |
| SplittedSRAM_3..6 | 1286，unread 0 | 1286 各，**unread 4** | ★unread 登记错了★：见下 |
| Directory / _1 / _2 / _3 | 模型 − 16 = 1938 / 1939 / 1939 / 1940 | **1927 / 1928 / 1929 / 1929** unread 18 / 27 / 27 / 27 | ★少 11，登记错了★：见下 |

逐项指认（按 unread_points.txt 逐点分类，不是凑数）：
1. DataStorage：影子寄存器 529 位之外，MBIST 叶子 mbistPl 的 addrReg[12:0] + addrRdReg 1 位 + beReg 1 位共 15 位在
   DataStorage 里**也没有读者**（SRAMTemplate_155/166/178 的 bore 口不用这些位）——我只算了本层，没算子树在父层语境
   下变死的位（CONVENTIONS「同一字段在不同层次被 DCE 的程度不同，每一层都要自己量」的又一例）。另：影子寄存器与
   beReg 因名字不同（REG_* vs 语义名、标量 vs [0:0]）没被 FM 配对，526 位两侧各自落单、2 位错配 —— 须按名钉点。
2. SplittedSRAM_3..6 与 Directory*：共用核 xs_SRAMTemplate_core 的非 MCP 形态有一个 golden 没有的 rdata_last_REG，
   靠 merge_duplicated_registers 与 respReg 合并；我在本目录关了 merge（为了 passing 模型严格成立），它就成了
   重写侧独有的未读寄存器（每块 SRAM 1 个）。Directory 的另 11 位是 mbistPl 的 addrReg[9:0] / addrRdReg[9]（同 1 的
   父层语境死位）；slice 0 用的旧手写件 L2Directory 多一层 u_ctrl，名字配不上，须钉点。

第二跑的改动（本节提交里一起落地）：
- verif/allow/<T>.json ×16（declare_allow.py 由第一跑 black_boxes.rpt 生成，全部 class vendor_macro：
  GatedSplittedSRAM* / DataStorage* 各 array_18_ext ×4/侧；SplittedSRAM_* array_14_ext ×4/侧；Directory*
  array_14_ext ×4 + array_15/16/17_ext 各 1，×2 侧 = 14）。
- verif/ut/DataStorage/fm_pins_pre.tcl（530 位：影子寄存器 529 + mbistPl.beReg 1，只对 DataStorage*）；
  verif/ut/Directory/fm_pins_pre.tcl（11 位，只对 Directory）。
- verif/ut/Directory/Makefile：FM_MERGE_DUP 回到默认 true（与 SRAMTemplate 两个 UT 目录一致）⇒ 本目录 passing
  不再与模型逐位对账（MODEL_NA），这是为了不改已签核的共享 SRAM 核。

第二跑登记（vmucp 仍关）：
| 目标 | 预测 |
|---|---|
| GatedSplittedSRAM ×4 | passing 2272，SUCCEEDED（allow 精确相等） |
| SplittedSRAM_3..6 | unread 0，SUCCEEDED（passing 因 merge 开，不对账） |
| DataStorage ×4 | passing 仍 1988 / 1989 / 1990 / 1990；unread **544**，全部 matched_nc 双射 ⇒ PARTIAL |
| Directory | unread **27**（wayMask 16 + mbistPl 地址 11），全部 matched_nc ⇒ PARTIAL |
| Directory_1..3 | unread **27**，全部 matched_nc ⇒ PARTIAL |
第三跑：DataStorage* / Directory* 按 vmucp standing rule 开 vmucp，passing 分别 +544 / +27、SUCCEEDED。

### 9.4 对账（第一跑）与第二跑登记

- 第一跑（commit f6806ac5，evidence/f6806ac59aae/RequestArb）：**ERROR**，钉点 0/766 —— §9.1 标出的风险成真：
  FM 给 packed struct 寄存器起的名字是 `u_core/mshr_task_s1_bits_reg\[<字段>][bit]`，不是按惯例推的
  `u_core/mshr_task_s1_bits_reg[bit]`；钉点文件 fail-closed 报错停下，没有出 receipt。
- 定位（scratch 副本里 FM_MODE=diagnostic-full、去掉钉点，不产 receipt）：FM 自己按名/签名配上全部寄存器，
  0(0) unmatched，Verification SUCCEEDED，1837 passing，unread 0 —— 本模块没有对称阵列，根本不需要钉。
  于是删掉钉点（生成器不再产出 fm_pins_pre.tcl）。
- 第二跑登记：passing **1837**、unread 0、failing / unmatched 0、SUCCEEDED（与 §9.3 相同，钉点那一项作废）。

### 7.5 对账（第二跑，commit f6806ac5，evidence/f6806ac59aae/）与第三跑登记

- GatedSplittedSRAM / _1 / _2 / _3：passing **2272** 各，**SUCCEEDED**（allow 8 对象精确相等），与登记一致 —— 签核完成。
- SplittedSRAM_3..6：**SUCCEEDED**，unread 0（merge 开，passing 1286 各）—— 签核完成。
- DataStorage / _1 / _2 / _3：passing 1988 / 1989 / 1990 / 1990，unread **544**，全部 matched_nc、两侧独占 0，
  钉点 DS_PIN ok=530 bad=0 —— 与登记逐位相等。
- 第三跑（DataStorage* 开 vmucp：verif/fm_target_config/DataStorage*.tcl + Makefile 目标级开关）登记：
  passing **2532 / 2533 / 2534 / 2534**（= 第二跑 + 544 = 模型值）、unread 0、SUCCEEDED。

### 8.5 对账（Directory 第二跑，commit f6806ac5）与第三跑登记

- Directory / _1 / _2 / _3：passing 1926 / 1927 / 1927 / 1928（merge 开），unread **27** 各，全部 matched_nc、两侧独占 0，
  Directory 钉点 DIR_PIN ok=11 —— 与 §7.4 第二跑登记一致。
- 第三跑（Directory* 开 vmucp）：passing 1953 / 1954 / 1954 / 1955（+27）、unread 0、SUCCEEDED（merge 开，不与模型对账）。

## 10. RequestBuffer 子树（RequestBuffer、FastArbiter_2、Queue1_ChosenQBundle）

### 10.1 结构

- `xs_RequestBuffer_core`：直通 / 分配 / 去重 / 合并 / 表项更新 / 发射取消 / noFreeWay（6 份 sameSet_s3 寄存器照 golden）/
  统计 / perf 计时寄存器（照 golden 保留）。类型（a_req_t 14 字段、task_t 93 字段、entry_t）、wrapper、钉点由
  `scripts/gen_l2_reqbuf.py` 生成，核对 FastArbiter_2 载荷 = channel + a_req_t、chosenQ 出队字段 = io_out 字段。
- FastArbiter_2：已签核共享核 xs_FastArbiter_core **不改**，薄文件在载荷低 4 位捎带独热标识取回 chosenOH（io_chosen）。
- Queue1_ChosenQBundle：新共享核 `xs_ChiselQueue1_core`（深度 1：只有 full + 整字寄存器 ram）+ gen_l2_queues.py 薄文件，
  407 位字按 golden 拼接（含恒 0 的补零段）逐字段校验。
- 钉点只有 12 位（perf 的 REG_* / enable_REG_*）；其余寄存器（含 4 个对称表项）FM 自己配得上 —— 在 scratch 副本里
  diagnostic-full、不钉的诊断跑（不产 receipt）实测 0(0) unmatched compare points、Verification SUCCEEDED、1592 passing。

### 10.2 UT（verif/ut/RequestBuffer；commit aa03186a）

seed1 random 20k：checks=2220000 errors=0，111/111 输出翻转；覆盖 直通 2017 / 分配 3755 / 去重 806 / 合并 106 / 满 8119 /
发射取消 309 / 发射 3737 / noFreeWay 5000。（78 个出口字段在 A 路径上结构性恒 0，只在 chosenQ 上电初值随机时翻；
initreg 0 档翻转门限因此按 33 设。）变异：去重漏缓冲比对 errors=37119、waitMP 不置 s1 阻塞 errors=107076、
直通判定漏 s3 份额 errors=10（初版激励下存活，加"MSHR 数卡在 8 路门槛边"的拥挤相后抓到）、表项 noFreeWay 漏 s3 errors=22708、
FastArbiter_2 io_chosen 低位接错 errors=162415，均 CAUGHT。9 档矩阵后台跑，文末对账。

### 10.3 跑前预测（★跑完不许改★）

第一跑（vmucp 关）：
| 目标 | 模型 | 预计 unread | 预计 passing |
|---|---|---|---|
| FastArbiter_2 | 154 | 1（pendingMask[0]：rrGrantMask[0] 恒 0 把它与掉，同 FastArbiter_28） | 153 |
| Queue1_ChosenQBundle | 787 | 22（ram 里 valid/rdy/waitMP/waitMS：存了没人读） | 765 |
| RequestBuffer | 1708 | 119（bufferTimer 64 + chosenQ.ram 30 + issueArb.pendingMask[0] 1 + perf 1 位 12 + …）| 1592（取自诊断跑） |
RequestBuffer 的 1708 − 1592 = 116 ≠ 119（差 3）我现在指认不了，第一跑后逐点对账。
第二跑：三者按 vmucp standing rule 开 vmucp，passing = 第一跑 + unread，SUCCEEDED。

### 10.4 对账（第一跑，commit 4e3aa2c9，evidence/4e3aa2c94341/）与后续登记

- FastArbiter_2 / Queue1_ChosenQBundle：**ERROR**（未出 receipt）—— RequestBuffer 目录的钉点文件对目录里每个 FM 目标都会
  source，而它写死了 RequestBuffer 的路径，另两个目标一进来就钉点失败报错。已给钉点加 `if {$top eq "RequestBuffer"}` 守卫。
- RequestBuffer：passing **1592**（= 诊断跑，= 登记）、Constant reg 9、unread **107**（我登记的 119 算重了 12：perf 的 12 位
  已含在"诊断跑里 12 个落单"里）。逐点：bufferTimer 64 + perf 1 位 12（钉点配对，RB_PIN ok=12）+ chosenQ.ram 30 +
  issueArb.pendingMask[0] 1，全部 matched_nc。模型差 116 = 107 + Constant reg 9，逐位指认完毕（我登记时说"差 3 指认不了"，
  那 3 是我把 unread 数错算成 119 造成的）。
- 后续登记：
  | 目标 | 预测 |
  |---|---|
  | FastArbiter_2（vmucp 关） | passing 153、unread 1（pendingMask[0]）⇒ PARTIAL；再开 vmucp ⇒ 154 SUCCEEDED |
  | Queue1_ChosenQBundle（vmucp 关） | passing 765、unread 22（ram 的 valid/rdy/waitMP/waitMS）⇒ PARTIAL；再开 vmucp ⇒ 787 SUCCEEDED |
  | RequestBuffer（vmucp 开，verif/fm_target_config/RequestBuffer.tcl） | passing **1699**、unread 0、SUCCEEDED |

## 11. SinkC

### 11.1 结构 / UT

- 可读核 `xs_SinkC_core`（§1 beat 计数 / §2 4 项缓冲与分配 / §3 ProbeAck 应答与 releaseBuf 写 / §4 出队后数据读出与新数据嵌套），
  TaskBundle 结构体与 wrapper 由 `scripts/gen_l2_sinkc.py` 生成；child RRArbiterInit_16（PROVEN_DIRECT）两侧白盒。
- UT（verif/ut/SinkC，commit 1ad5331b）seed1 random 20k：checks=2220000 errors=0，111/111 输出翻转；覆盖 满 11278 / 反压 2222 /
  出任务 2092 / 新数据嵌套写 refillBuf 245 / ProbeAckData 写 releaseBuf 885 / 两拍报文第二拍 4676。变异：beat 号不看 beats1
  errors=10841、第二拍也反压 errors=202594、refillBuf 两拍次序颠倒 errors=19963，均 CAUGHT。9 档矩阵后台跑。

### 11.2 跑前预测（★跑完不许改★）

| 目标 | passing | 其余 |
|---|---|---|
| SinkC | **6868**（regs 4887 + outs 1981） | failing 0 / unmatched 0 / unread 0（我没找到对称死位）/ 无黑盒 / SUCCEEDED |

### 11.3 对账（SinkC 第一跑，commit 4a2638fc，evidence/4a2638fcec95/SinkC）

- SinkC：**SUCCEEDED** passing **5636** / failing 0 / unmatched 0 / unread 0，Constant reg **1232**。登记 6868 − 5636 = 1232 = Constant reg，
  逐位指认完毕。我登记时写"passing 6868"是把模型值直接当成了 passing，漏减常量寄存器（taskBuf / 缓冲里 Release 路径上恒 0 的字段位，
  receipt 的 constant_reg 直接给出）—— 这是预测口径错误，不是设计差异。

### 10.5 对账（第二跑，commit 4a2638fc，evidence/4a2638fcec95/）

| 目标 | 登记 | 实测 | 差额指认 |
|---|---|---|---|
| RequestBuffer（vmucp 开） | 1699 SUCCEEDED | **1699 SUCCEEDED** | 0 |
| FastArbiter_2（vmucp 关） | 153 PARTIAL | **152** PARTIAL，unread 1 | 我漏减 Constant reg 1（rrGrantMask[0]，与 FastArbiter_28 同）；154 = 152 + 1 + 1 |
| Queue1_ChosenQBundle（vmucp 关） | 765 PARTIAL | **503** PARTIAL，unread 22 | 我漏减 Constant reg **262**：golden 的 ram 写口对 RequestBuffer 出口不带的字段直接写常量 0（`211'h0`/`31'h0`/`13'h0`/…），这些位恒 0；787 = 503 + 22 + 262 |

第三跑登记（vmucp 开，依据 verif/fm_target_config/FastArbiter_2.tcl / Queue1_ChosenQBundle.tcl）：
FastArbiter_2 passing **153** SUCCEEDED；Queue1_ChosenQBundle passing **525** SUCCEEDED。

### 8.x 对账（Directory ×4 第三跑，vmucp 开，commit 4e3aa2c9，evidence/4e3aa2c94341/）

Directory / _1 / _2 / _3：**1953 / 1954 / 1954 / 1955 SUCCEEDED**，与登记逐个相等。

## 12. GrantBuffer 子树（GrantBuffer、Queue10_GrantBuffer_Anon）

### 12.1 结构 / UT

- 可读核 `xs_GrantBuffer_core`（mergeA 还原 / inflightGrant 记账 / 两拍出队 + grantBuf / 入口阻塞 / perf 计时器），TaskBundle 结构体、
  wrapper 与 32 个 perf 1 位寄存器的钉点由 `scripts/gen_l2_grantbuf.py` 生成。child：Queue16_GrantQueueTask / Queue16_GrantQueueData ×2
  （§3 已签）两侧白盒；Queue10_GrantBuffer_Anon（pftRespQueue，10 项 flow）本 lane 新增，`scripts/gen_l2_queues.py` 薄文件 + 共享核。
- golden 1596 行 / 重写 978 行（核约 330 行手写）；`_GEN_`/`_T_` 0。
- UT（verif/ut/GrantBuffer）seed1 random 20k：GrantBuffer 与 Queue10 均 PASS，errors=0，66/66、7/7 输出翻转；覆盖：第二拍 4162 /
  blockA 9353 / blockB 11143 / blockC 6217 / blockMSHR 11079 / 预取队列门槛 883 / inflight 全满 5018 / isKeyword 出队 7421 /
  计时器清零 271；Queue10 满 4880 / flow 直通 2497。
- 变异（seed1 20k，initreg 0）：预取门槛 9→10 errors=19、keyword 拍次序 errors=2158、空项优先级反向 errors=419814、GrantAck 用整 8 位
  sink errors=71374，均 CAUGHT；mergeA corrupt 不并 denied **SURVIVED** —— 等价变异：D 通道出口本来就输出 corrupt|denied，
  denied 也一起入队，出口不可区分（队列存储里那一位不同，FM 会比到）。

### 12.2 ★FM 阻塞：ram_10x89 不在 vendor_boundary 审定表★

pftRespQueue 的存储叶子 ram_10x89 深度 10、地址 4 位（10..15 越界），inline 会触发 FMR_ELAB-147；它**不在** verif/vendor_boundary.tsv
审定表里，而表头写明"一次性人工审定、declare_allow 不得自动批准"，本 lane 无权自行登记。审定工具的机器复算：
`python3 scripts/audit_ram_memory_model.py ram_10x89 --parent-ref Queue10_GrantBuffer_Anon.sv --parent-impl rtl/uncore/Queue10_GrantBuffer_Anon.sv`
→ M1 PASS、M2 PASS、M3 ref PASS、M3 impl **MANUAL**（重写件的指针在共享核 u_core 里，工具在薄文件上找不到 deq_ptr 的非阻塞赋值）
⇒ AUDIT_INCOMPLETE。重写侧指针的归纳论证与 golden 相同：xs_ChiselQueue_core 的 enq/deq 指针只有复位赋 0 与 "==DEPTH-1 回卷到 0，
否则 +1" 两种赋值，∈[0,9]。**需要 reviewer 审定 ram_10x89 后**，两个目标才可能判 SUCCEEDED。

### 12.3 跑前预测（★跑完不许改★；vmucp 关，ram_10x89 两侧 inline）

| 目标 | 模型 | 预测 |
|---|---|---|
| Queue10_GrantBuffer_Anon | 994（regs 899 + outs 95） | native 等价（failing 0 / unmatched 0），但 elab147 ⇒ 判 PARTIAL（FAILED 也可能：取决于 FM 对越界读的处理，照实记） |
| GrantBuffer | 12545（regs 11512 + outs 1033） | failing 0 / unmatched 0；unread ≥ 1056（timers 1024 + REG 16 + enable_REG 16，钉点 GB_PIN ok=32）；Constant reg ≥ 68（grantQueue 存储里 grantid 高 4 位 16×4 + grantBuf_grantid 高 4 位）；elab147 ⇒ PARTIAL |

## 13. MainPipe_1 的 child（Arbiter3_CHIREQ / Arbiter3_TaskBundle / Arbiter3_TaskWithData / CustomL1Hint / Queue16_HintQueueEntry / Queue4_HintQueueEntry）

### 13.1 结构 / UT

- Arbiter3_*：`scripts/gen_l2_arbiter3.py` 从 golden 端口表生成薄文件，核是已签核的 xs_FixedPriorityArbiter_core（未改动）。
  CHIREQ / TaskBundle 两个变体 firtool 删了 io_out_ready 与 io_in_0_ready（MainPipe 那一路 out.ready 恒 1），核 out_ready 接 1。
  golden 206/190/935 行 → 重写 177/157/998 行（TaskWithData 95 个字段 × 4 组，一个字段一行）。
- Queue16_HintQueueEntry / Queue4_HintQueueEntry：`scripts/gen_l2_queues.py` 薄文件 + 共享核（ram_16x11 / ram_4x11 两侧 inline，2 的幂）。
- CustomL1Hint：手写（golden 193 行 → 约 150 行），两个队列按 golden 实例名例化。
- UT（verif/ut/L2MainPipeLeaves）seed1 random 20k：6 个目标全 PASS、errors=0、输出全翻转；覆盖：仲裁器"只有末路" ~2450 /"三路齐请求" ~2500；
  CustomL1Hint 提示 3216 / s3 抢先 273 / hint_s1Queue 满 6619 / hintQueue 满 8732 / mergeA Grant 520。
- 变异（seed1 20k）：s1 队列不给 s3 让路 errors=5025、ParallelPriorityMux 次序 errors=587、s3 不看 need_mshr errors=18838、
  仲裁器 out_ready 接 0 errors=14858，均 CAUGHT。

### 13.2 跑前预测（★跑完不许改★；vmucp 关）

| 目标 | 模型 | 预测 |
|---|---|---|
| Arbiter3_CHIREQ | 103（纯组合） | passing 103 SUCCEEDED |
| Arbiter3_TaskBundle | 71 | passing 71 SUCCEEDED |
| Arbiter3_TaskWithData | 899 | passing 899 SUCCEEDED |
| Queue16_HintQueueEntry | 198（regs 185 + outs 13） | passing 198 SUCCEEDED |
| Queue4_HintQueueEntry | 62（regs 49 + outs 13） | passing 62 SUCCEEDED |
| CustomL1Hint | 268（regs 234 + outs 34） | failing 0 / unmatched 0 / unread 0，SUCCEEDED；passing 248..268 —— 两个队列存储里 opcode[2] 恒 1（入队的 opcode 只可能是 4/5/6），16 + 4 位可能被 FM 判常量 |

### 13.3 对账（commit a7f4ef16，evidence/a7f4ef161492/）

Arbiter3_CHIREQ 103 / Arbiter3_TaskBundle 71 / Arbiter3_TaskWithData 899 / Queue16_HintQueueEntry 198 / Queue4_HintQueueEntry 62 /
CustomL1Hint **268**：全部 SUCCEEDED，与登记逐个相等（CustomL1Hint 取登记区间上端：FM 没有把 opcode[2] 判常量）。
同一 commit 上 RequestBuffer 目录第三跑（vmucp）：FastArbiter_2 **153** / Queue1_ChosenQBundle **525** / RequestBuffer **1699** SUCCEEDED，与 §10.5 登记相等。

## 14. MainPipe_1

### 14.1 结构 / UT

- 可读核 `xs_MainPipe_1_core`（§0 复位清目录 / §1 s3 分类 / §2 可嵌套目录视图 / §3 要不要 MSHR / §4 当场响应 sink_resp /
  §5 DS、目录写、嵌套写回、预取训练 / §6 s3-s4-s5 出口 / §7 入口阻塞与状态 / §8 ECC 与 perf），约 800 行手写；
  package l2mainpipe_pkg 的 task_t 与 wrapper（四个出口仲裁器 + customL1Hint 按 golden 实例名例化）由 `scripts/gen_l2_mainpipe.py` 生成。
- golden 4368 行 / 重写 2964 行（其中 wrapper 生成约 2000 行：519 个端口 + 4 个仲裁器 × 3 路 × 95 字段的连线）；`_GEN_`/`_T_` 0。
- UT（verif/ut/MainPipe_1）seed1 random 20k：checks=7540000 errors=0，377/377 输出翻转；覆盖：MSHR 分配 ~900-1400 / B 当场响应 ~800-1250 /
  doRespData ~1500 / DCT 转发 ~600-850 / d 在 s3/s4/s5 发 1812/480/145 / txdat 在 s5 发 166 / txreq 在 s3 发 138 / txrsp 在 s3 发 1296 /
  写 releaseBuf 412 / replResp retry 110 / 丢弃后报错 6790 / 目录写 B 89、C 573 / blockB 4967 / l1Hint 402。
  **txrsp / txreq 在 s4/s5 发出是结构性不可达**（只会在 s3 输仲裁时顺延，而 s3 只会输给 s4/s5 上同一出口 —— 鸡生蛋；
  要写 releaseBuf 而留到 s4 的又被 RegNext(chnl_fire_s3) 屏蔽），UT 不覆盖、照实记。
- 变异（seed1 20k）：odOpGen 越界项给 CBOAck errors=288、丢弃后 s5 不更新地址 errors=9969、PassDirty 不看 snpHitRelease errors=7、
  d_s3 不做 latch errors=29480、s5 不屏蔽 RegNextN(fire_s3,2) errors=7175、C 写目录 clients 恒 1 errors=649，均 CAUGHT。

### 14.2 跑前预测（★跑完不许改★；vmucp 关，child 两侧白盒）

| 目标 | 模型 | 预测 |
|---|---|---|
| MainPipe_1 | 6666（regs 2473 + outs 4193） | failing 0 / unmatched 0 / unread 0 / Constant reg 0，passing **6666** SUCCEEDED（没找到对称死位：三级 task 寄存器的每个字段都进了出口仲裁器，data/perf 打拍也都有读者） |

### 14.3 对账（commit 702d4569，evidence/702d456904d5/）

- MainPipe_1：**SUCCEEDED passing 6666**（failing 0 / unmatched 0 / unread 0 / constant 0），与登记逐位相等。
- 同一 commit 的 DataStorage 目录重跑（钉点守卫改字面数后）：GatedSplittedSRAM x4 2272、DataStorage x4 2532/2533/2534/2534 SUCCEEDED，与 §7 相同。
- GrantBuffer / Queue10_GrantBuffer_Anon：**ERROR（未出 receipt）**，与 §12.2 预告一致但比预告更早：ram_10x89 inline 时
  FMR_ELAB-147 是 Unsuppressed，`set_top` 当场失败（FM-156），连比较都进不去；唯一的 FM 放行手段 `set_mismatch_message_filter`
  是禁用项。**两者都挂在 ram_10x89 的 reviewer 审定上**（审定后按 regimeA 两侧对称黑盒，Queue10 走 assembly）。

## 15. Directory：directory_pkg 搬进 uncore_common_pkg.sv（package 作用域闸）+ 第四跑登记

- 闸 check_pkg_scope 报 CROSS_FILE_PACKAGE：directory_pkg 定义在 xs_Directory_core.sv、被 Directory / Directory_1..3 引用。
  按 CONVENTIONS 搬进 rtl/uncore/uncore_common_pkg.sv（包内容逐字不变），Directory 目录 RTL_SRCS 把公共包排在最前。
  搬家前 Directory 9 档 UT 矩阵（seed 1/7/42 × initreg 0/random/<seed>017，200k）全 errors=0；搬家后 seed1 1017 20k 复验 errors=0。
- fm_predict 登记更正：Directory x4 当初登记时 JSON 记的是 merge_dup=false（那时 Makefile 还显式关 merge），后来 Directory 目录改回
  merge 默认，JSON 没有重登 —— check 因此对第三跑报"余额 1 指认不了"（1953 vs 模型 1954：正是 merge 合掉的 1 个重复寄存器，
  §8.x 文字预测 1953/1954/1954/1955 是对的）。现按 merge_dup=true 重登（模型不适用、带状判定）。
- 第四跑预测（★跑完不许改★，commit 在本登记之后）：SplittedSRAM_3..6 1286 x4，Directory / _1 / _2 / _3 **1953 / 1954 / 1954 / 1955**
  SUCCEEDED（vmucp 开，与第三跑相同 —— 这次只搬了 package 与钉点守卫写法，比较点不该变）。

## 16. UT 矩阵汇总（seed 1/7/42 × initreg 0 / random / <seed>017，各 200k 拍，种子串行；scratch utmx.sh）

| UT 目录 | 目标 | 9 档 | 每档 checks |
|---|---|---|---|
| L2Slice | L2Slice x4 | 9/9 errors=0 | 16.0M |
| MSHRBuffer | MSHRBuffer / _1 | 9/9 | 0.4M |
| L2Queues | 5 个 Queue | 9/9 | 7.0M |
| TXDAT | TXDAT | 9/9 | 3.8M |
| L2DataStorage | L2DataStorage x4 / MbistClockGateCell_93 / ClockMux | 9/9 | 30.4M |
| ClockGateCell93 | MbistClockGateCell_93（双相） | 9/9 | 0.8M |
| RXSNP | RXSNP | 9/9 | 5.2M |
| L2DirectoryVariants | L2Directory_1..3 | 9/9 | 39.0M |
| Directory | Directory x4 / SplittedSRAM_3..6 | 9/9（pkg 搬家前）+ 9/9（搬家后） | 30.4M |
| DataStorage | DataStorage x4 / GatedSplittedSRAM x4 | 9/9（补抄 rdataReg 之后；之前 seed1×1017 档首拍 4 个假失配） | 3.2M |
| RequestArb | RequestArb | 9/9 | 46.4M |
| RequestBuffer | RequestBuffer / FastArbiter_2 / Queue1_ChosenQBundle | 9/9 | 22.2M |
| SinkC | SinkC | 9/9（门限改 29 后；之前 8 档 errors=0 但翻转门限 111 判 coverage 失败） | 22.2M |
| GrantBuffer | GrantBuffer / Queue10_GrantBuffer_Anon | 9/9 | 14.6M |
| L2MainPipeLeaves | Arbiter3 x3 / Queue16/4_HintQueueEntry / CustomL1Hint | 9/9 | 28.4M |
| MainPipe_1 | MainPipe_1 | 9/9 | 75.4M |

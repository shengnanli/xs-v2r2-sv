# NewDispatch 步骤 3：FM 反例（`io_fromRename_{2..5}_ready`）的可达性判定与修法

lane：agent/newdispatch3（基线 main `b804a4f00c5d3f736dbbecc8386317fadb7fdab1`，worktree `wt-nd3`）。
接 `newdispatch_step2_results.md` 第 4 节的交接：FM 报 `ready_2..5` 失配、UT 3 seed × 200k 全绿，
两条嫌疑（节 2.6 `uopBlockByIQ` / `automatic` 声明初始化式）。★本文件先判可达性，再动 RTL★。

## 0. 结论（先说）

**反例不可达。** 不是逻辑错，是"写法让 FM 证不出"。两条交接嫌疑**都不是**根因：
`uopBlockByIQ` 的 `cnt > 3'd2` 项与 golden 逐位同构（golden 的前缀计数是 2 位/3 位混合截断，
但截断处永不溢出，见 §2.1），`automatic ... = '0` 的读法 FM 也没有报任何 FMR_VLOG 消息。

根因是一个 **golden 里不存在、impl 里却存在的自由寄存器位**：
`u_core/conserveFlowTotal_reg[2][6]`。FM 自己把它标成 **`DFF0X`（constrained 0X DFF register）**——
次态可证恒 0，但现态不许当 0 —— 且它在 golden 侧**没有配对对象**（golden 的这一位是字面常量
`1'h0`，读入时就折掉了）。于是它在 `ready_2` 的锥里是一个 unmatched 自由输入，FM 给它取 1 就得到
"失配"。而 `allowDispatch_3..5` 都经 `allowDispatch_2` 级联，所以 lane 2..5 一起红、lane 0/1 不红。

## 1. 反例的来源：这个位是怎么来的

golden（firtool 输出）里 `conserveFlowTotal_l` 的次态，逐 lane 位宽**不同**（`golden-rtl/NewDispatch.sv`
L91127–L91143、L90990–L91010）：

| lane | golden 次态形状 | highCount 位宽 | bit 6 |
|---|---|---|---|
| 0 | `{2'h0, is16, 2'h0, is2, is1}` | 1 | 字面 0 |
| 1 | `{1'h0, highCount(2b), 1'h0, 3'(…+…)}` | 2 | 字面 0 |
| 2 | `{1'h0, 2'(a + 2'(b + c)), 4'({1'h0,3'(…)} + …)}` | **2** | **字面 0** |
| 3..5 | `{3'(…), 4'(…)}` | 3 | 活的 |

这就是 Chisel `PopCount(前 lane+1 条)` 的位宽 `log2Ceil(lane+2)` = 1,2,2,3,3,3。

impl 第一版（`be28d091` 起、`b804a4f0` 同）`conserve_total()` 对**所有** lane 都用 3 位累加：
`highCount += 3'(is16[p])`。lane 2 的 bit 2 = ((a&b) & (a^b)) & c ——
**函数上恒 0**（a&b 与 a^b 互斥），**结构上是一条进位链**。FM 能证它次态恒 0（所以标 DFF0X），
但因为寄存器无复位、无初值，不敢把现态当 0；golden 那边这一位根本不是寄存器；于是配不上。

prior run（`wt-nd2-b2` 的 `fm_work/NewDispatch/unmatched.rpt`，commit `be28d091`）的 6 个 unmatched impl 点**全部**是这一族：

    Impl DFF0       i:/WORK/NewDispatch/u_core/conserveFlowTotal_reg[0][3]
    Impl DFF0       i:/WORK/NewDispatch/u_core/conserveFlowTotal_reg[0][5]
    Impl DFF0       i:/WORK/NewDispatch/u_core/conserveFlowTotal_reg[0][6]
    Impl DFF0       i:/WORK/NewDispatch/u_core/conserveFlowTotal_reg[1][3]
    Impl DFF0       i:/WORK/NewDispatch/u_core/conserveFlowTotal_reg[1][6]
    Impl DFF0X      i:/WORK/NewDispatch/u_core/conserveFlowTotal_reg[2][6]   ← 唯一的 DFF0X

lane 0/1 的那 5 个是 `DFF0`（结构常量：零扩展再相加不产生进位），FM 直接当常量 0 用，
所以 `ready_0`/`ready_1` passing；只有 `[2][6]` 是 `DFF0X`，FM 不折，成了自由输入。
golden 侧 `conserveFlowTotal_2_reg[6]` 在 matched/unmatched/failing/unread 四份报告里 **0 次出现**（读入即折）。

    grep -c 'conserveFlowTotal_2_reg\[6\]' /home/eda/xs-env/wt-nd2-b2/verif/ut/NewDispatch/fm_work/NewDispatch/{matched,unmatched,failing}.rpt

## 2. 可达性判据（可复查）

**判据**：反例要求 `conserveFlowTotal[2][6] = 1`。真实设计里该位的**唯一**写源是
`conserve_total(…, lane=2)` 的 `highCount[2]`，其中 highCount = is16[0]+is16[1]+is16[2]，
三个 1 位量之和 ≤ 3 < 4，所以 **第一拍之后该位恒 0**；第一拍之前（无复位寄存器的上电值）
golden 的整个 `conserveFlowTotal_2` 同样是未定义的（`_RANDOM` 初始化块），两侧同样不确定，
FM 也不比较那一拍（它比的是"已配对现态相等"前提下的输出函数）。★反例违反的约束就是这一条：
它给了一个前一拍逻辑**永远写不出**的现态。★

机械穷举（8/8 组合）：

    python3 -c "
    import itertools
    print(sum(((a+b+c)&7)>>2 for a,b,c in itertools.product((0,1),repeat=3)), '个组合让 bit2=1 (应为 0)')
    print(sum(((a+b+c)&7)!=((a+b+c)&3) for a,b,c in itertools.product((0,1),repeat=3)), '个组合 2 位与 3 位累加值不同 (应为 0)')"
    # 0 个组合让 bit2=1 (应为 0)
    # 0 个组合 2 位与 3 位累加值不同 (应为 0)

区分性示例（说明这个自由位为什么能翻 ready_2）：`lqFreeCount=20`、`conserveFlowTotal[2][5:0]=16`：
golden `20 > 16` 为真；impl 若 bit6=1 则 `20 > 80` 为假 → `allowDispatch_2` 不同 → `ready_2` 不同。

UT 为什么看不见：仿真里该位从第一拍起就是 0（`+vcs+initreg+0` 上电也是 0），
200k 拍 × 3 seed 自然一次都不失配 —— 这与 FM 的"全空间"读数并不矛盾。

### 2.1 顺手排掉的两条交接嫌疑

* `uopBlockByIQ`：golden `uopSelIQMatrix_l_q` 的前缀计数是 2 位/3 位混合截断（如
  `uopSelIQMatrix_2_0 = {1'h0, 2'(_GEN_42 + 2'(_GEN_43 + _GEN_76))}`），但每处截断的最大值
  （lane 2 ≤ 3、lane 4 内层 ≤ 3、lane 5 两半各 ≤ 3）都装得下，与 impl 的 3 位 `cnt` 逐位同函数；
  `iqReady[q]` 取的都是每 IQ 第 0 个口的 `io_toIssueQueues_{2q}_ready`（impl L8840–L8856）。
* `automatic logic [2:0] cnt = '0;`：本轮与 prior run 的 fm.log 里都**没有**任何 FMR_VLOG 消息指向它；
  步骤 2 撞的 FMR_VLOG-929 只针对"声明初始化式里读自己"，这里读的是别的变量。

## 3. 分支：不可达 → 改写法，不改功能

修法（`rtl/backend/NewDispatch.sv` `conserve_total()`）：highCount 按 golden 的 PopCount 位宽分两档 ——
lane 0..2 用 2 位累加、lane 3..5 用 3 位，返回 `{1'b0, highCount2, lowCount}` / `{highCount3, lowCount}`。
lane ≤ 2 时和 ≤ 3，2 位装得下，**返回值对任何输入都与原来相同**（§2 穷举第二行）。
bit 6 由此在两侧都是结构常量（字面 0），不再有自由寄存器。

★没有做的事★：没有 `dont_verify`、没有 `set_constant`/约束、没有白名单、没有放宽 appvar、
没有 `set_mismatch_message_filter`、没有加宽黑盒。

### 3.1 跑前登记（post-fix 诊断跑 / 签核跑之前写下，跑完不改）

对比基线 = 步骤 2 组 B 诊断跑 `NDstepB2-diag`（passing 51745 / failing 4698 / unmatched_ref 2006 / unmatched_impl 6）。

* **R1**（硬）：`io_fromRename_{2,3,4,5}_ready`、`io_toRenameAllFire`、`io_enqRob_req_*_valid` 全部转 passing。
* **R2**（硬）：失败点集 ⊆ {`io_toIssueQueues_*` 里 leaf ∈ 步骤 2 §4 那 20 个 unresolved 的端口} ∪ {它们锥内的寄存器}。
  即 `io_enqRob_*`/`io_toMem_*`/`io_fromRename_*_ready`/`io_toRenameAllFire`/`io_perf_*`/`io_stallReason_*`
  一个失败点都不许有。
* **R3**（弱）：failing 从 4698 落到 **[1400, 1600]**（步骤 2 组 A 清点的 1450 个 unresolved-leaf 端口位
  + 少量锥内寄存器）；passing 相应 ≥ 51745 + 3000（`lsqEnqCtrl` 那 ~3000 点应回绿）。
* **R4**：`unmatched_impl` 里不再有 `DFF0X`；`unmatched_ref` 不上升（2006）。
* **R5**：signoff-strict 仍是 **FAILED**（unresolved 的 1488 bit 还在），failing==limit(20) 时只能写"至少 20 个，计数被截断"。
* **R6**：UT 3 seed × 200k、`+vcs+initreg+0` 与 `+vcs+initreg+1` 两档，A 违反 = B 违反 = 0，六条 lane 被选中拍数与 golden 逐个相等。

反向出口：R1/R2 任一不成立 ⇒ 除了这个位还有别的根因，照实报，不放行。

## 4. 实测（待填）


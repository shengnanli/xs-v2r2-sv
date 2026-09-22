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

### 4.1 pre-fix：对 ready_2..5 的局部验证 + analyze_points + diagnose（FM 自己的话）

跑在 **修法之前** 的字节上（impl 11 个文件的快照 = main `b804a4f00c5d3f736dbbecc8386317fadb7fdab1`，
摘要见 `evidence/b804a4f00c5d/NewDispatch-nd3-analyze/impl_snapshot.sha256`），脚本 = `scripts/fm_eq.tcl`
截到 `verify` 之前 + `set_verify_points` 8 个点（`analyze.tcl` 同目录归档）。可复跑：

    cd <scratch> && FM_TOP=NewDispatch FM_MODE=diagnostic-full FM_FAILING_LIMIT=0 XSSV_HOME=<wt> \
      FM_REF_SRCS="<golden 10 文件>" FM_IMPL_SRCS="<快照 11 文件>" \
      fm_shell -64 -work_path fm_work/NewDispatch -file analyze.tcl < /dev/null > fm_work/NewDispatch/fm.log 2>&1

* 局部 verify（只验这 8 个点）：**passing 2 / failing 6**：
  `io_fromRename_0_ready`、`io_fromRename_1_ready` passing；
  `io_fromRename_{2,3,4,5}_ready`、`io_toRenameAllFire`、`io_enqRob_req_2_valid` failing —— 与全量诊断跑的分界一致。
* `report_failing_points -inputs unmatched`：**6 个失败点全部被列出**（= 锥里含 unmatched 输入点）；
  `-inputs undriven`：0 个。
* `diagnose -all`（impl 侧）→ `report_error_candidates`：

      Single error detected in implementation.
      Recommended error candidate:
          Prim    u_core/conserveFlowTotal_reg[2][6]

  ★FM 自己把唯一错误候选钉在这一个寄存器位上★（备选 1–6 全是它下游的 `gt_843`
  比较器与 mux 引脚，即 `lqFreeCount > conserveFlowTotal[2]` 那条比较）。
  ref 侧 `diagnose -r` 给的候选是 `conserveFlowTotal_0_reg[2]`（golden 侧的另一个 DFF0X），同一族。
* `analyze_points -all -limit 0 -effort high`：报 134 个 "Required Inputs"（失败模式里被钉住取值的
  **已配对**输入），全部 `i:/`。ready_2 的 38 个逐条在
  `evidence/b804a4f00c5d/NewDispatch-nd3-analyze/ready2_required_inputs.tsv`
  （sha256 `48a98ba8b1628e51fde0a8bb92c9a80be9e54924a19ab15235056c2f18295d21`）。
  其中 `conserveFlowTotal_reg[2][1,2,3,5]` 全被钉 0、`[0][4]`/`[1][1,2,5]` 钉 0、`lsqEnqCtrl canAcceptReg=1`——
  就是"低位全 0、只靠那个不在表里的自由位 [2][6] 把 `lqFreeCount > conserveFlowTotal[2]` 翻掉"的形状。
  ★`[2][6]` 本身**不在** Required Inputs 里★：它是 unmatched 输入，FM 不把它列进"已配对输入"表，
  而是在 diagnose 里直接点名。`report_failing_pattern*` 这类命令本版本不存在（FM_NOCMD），
  失败模式的完整赋值只能从 Required Inputs（已配对）+ error candidate（未配对）两份拼出，已如上归档。
* 会话已存：`nd3_sel_session.fss`（scratch，未归档，太大）。

归档目录 `evidence/b804a4f00c5d/NewDispatch-nd3-analyze/`（`MANIFEST.sha256` 覆盖全部 12 个文件，`git add -f`）。

### 4.2 post-fix UT（commit `bbf769b701a2325f43199f3758054dbd998bf394` 的 RTL；simv 编译于 796dedca，与 bbf769b7 的 RTL 只差文件头导航注释）

    cd verif/ut/NewDispatch && make compile && ./simv +ntb_random_seed=<1|7|42> +ncycles=200000 +vcs+initreg+<0|1> -l sim_<seed>_initreg<0|1>.log

| seed | initreg | A 恒等 | B 失配 | A 违反 | B 违反 | 未判定 | lane0..5 被选中拍数 golden / 重写 |
|---|---|---|---|---|---|---|---|
| 1 | 0 | 6163 位 | 536 位 | 0 | 0 | 0 | 43256/43256 86178/86178 124018/124018 152738/152738 172620/172620 184645/184645 |
| 1 | 1 | 6163 位 | 536 位 | 0 | 0 | 0 | 43256/43256 86178/86178 124018/124018 152738/152738 172620/172620 184645/184645 |
| 7 | 0 | 6163 位 | 536 位 | 0 | 0 | 0 | 43563/43563 84280/84280 122448/122448 152379/152379 172455/172455 184982/184982 |
| 7 | 1 | 6163 位 | 536 位 | 0 | 0 | 0 | 43563/43563 84280/84280 122448/122448 152379/152379 172455/172455 184982/184982 |
| 42 | 0 | 6163 位 | 536 位 | 0 | 0 | 0 | 40971/40971 82823/82823 121303/121303 152881/152881 173666/173666 184550/184550 |
| 42 | 1 | 6163 位 | 536 位 | 0 | 0 | 0 | 40971/40971 82823/82823 121303/121303 152881/152881 173666/173666 184550/184550 |

六档全部 `TEST PASSED`，checks=199944，NOUT=6699=6163+536；六条 lane 被选中拍数与 golden 逐个相等，且与步骤 2 表里同 seed 的数字一模一样（修法没改任何可观测行为）。★R6 PASS★

### 4.3 post-fix FM（RTL = `bbf769b701a2325f43199f3758054dbd998bf394`；`git diff bbf769b7 c28e6ec0 -- rtl/` 为空）

诊断跑 `ND3fix-diag`（`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，worktree `wt-nd3`；receipt 里 `impl_commit`
记的是起跑后本 lane 又提交了证据的 `c28e6ec0`，rtl/ 与 `bbf769b7` 逐字节相同），证据 `evidence/bbf769b701a2/NewDispatch-diag/`
（receipt sha256 `b893cca0c9eb9d6d8c6653c0f194fb33db7513c295e9609927e680fb5feb0b4e`）：

| 量 | 步骤 2 组 B（`be28d091`） | **本轮（`bbf769b7`）** | 差 |
|---|---|---|---|
| passing | 51745（Port 50104 / DFF 1641） | **55027**（Port 50147 / DFF **4880**） | **+3282** |
| failing | 4698（Port 1459 / DFF 3239） | **1416**（Port 1416 / DFF **0**） | −3282 |
| unverified / aborted | 0 / 0 | 0 / 0 | — |
| unmatched_ref / unmatched_impl | 2006 / 6 | 2006 / 6 | 0 |
| impl 侧 `DFF0X` | 1（`conserveFlowTotal_reg[2][6]`） | **0**（该位现为 `DFF0`，与 lane 0/1 的 5 个同类） | −1 |

    cd verif/ut/NewDispatch && XSSV_HOME=<wt> FM_MODE=diagnostic-full FM_FAILING_LIMIT=0 make fm-NewDispatch

**1416 个失败点逐 leaf 清点（和为 1416，无余项）**——全部是步骤 2 §4 那 20 个 unresolved leaf 的 `io_toIssueQueues_*` 端口位：
lqIdx_value 238 / sqIdx_value 204 / regCacheIdx_0,1 各 170 / srcType_2 136 / srcLoadDependency_{0,1}_{0,1,2} 各 44 /
useRegCache_0,1 各 34 / lqIdx_flag 34 / sqIdx_flag 34 / srcState_0 34 / srcState_1 28 / srcState_2 16 / srcState_3 10 / srcState_4 10。
（= 1488 − 72：`srcState` 里被 `SRCSTATE_LIVE` 两侧同折成常量的 72 位如登记所料仍 pass。）

| 登记 | 实测 | 裁决 |
|---|---|---|
| R1 `ready_2..5` / `toRenameAllFire` / `enqRob_req_*_valid` 转 passing | 失败点里这三族 **0 个** | ★PASS★ |
| R2 失败点 ⊆ unresolved-leaf 端口及其锥 | 1416 个全是 unresolved-leaf 端口位；`io_enqRob/io_toMem/io_fromRename_*_ready/io_toRenameAllFire/io_perf/io_stallReason` 失败点 **0**；DFF 失败点 **0**（`lsqEnqCtrl`/`uopSelIQ`/`conserveFlowTotal` 全部回绿） | ★PASS★ |
| R3 failing ∈ [1400, 1600] | 1416 | ★PASS★ |
| R4 无 DFF0X、unmatched_ref 不上升 | impl DFF0X 0；2006 → 2006 | ★PASS★ |
| R5 signoff-strict 仍 FAILED | FAILED | ★PASS★（见下） |

签核跑 `ND3fix-sign`（signoff-strict，limit 默认 20，detached worktree `wt-nd3-sign` @ `bbf769b7`，`impl_worktree_dirty=false`），
证据 `evidence/bbf769b701a2/NewDispatch/`（receipt sha256 `7022356e6266fb1a56d3aa49e1ccad8406691b437c964f8d468fb98c7c737d72`）：
`verdict=FAILED`，passing 25225 / failing **至少 20 个（计数被截断，limit=20）** / unverified 31198 / unmatched 2006；
那 20 个截断点全是 `io_toIssueQueues_*_bits_{lqIdx,sqIdx,regCacheIdx}`，握手族 0 个。
★strict 下 unread 铁律：unread_ref 72 / unread_impl 2006 仍在，本 target 不可能在 unresolved 接完之前转绿；本轮没有任何东西转绿。★

台账措辞（codex 0168 §1）：本 target ref 走 golden child、impl 走重写 child；将来转绿也只能记
「**在 NewDispatch 上下文中**已被覆盖」，不许写成 9 个 child 各自的独立 `SIGNOFF_PASS`。

## 5. 整芯片二分（coordinator 外部证据）怎么纳入可达性判定

coordinator 的二分：只有 NewDispatch 用重写件时芯片 `instrCnt=0`（`sim-work-perfbind2/diag3`，
RTL = main `b804a4f0` 即 **修法之前** 的 NewDispatch）。这条证据是真的，但它推不出「FM 反例可达」——
两者是两件事。直接在 diag3 / diag2 的 simv 上（`-debug_access+all`，`-ucli` 逐拍 `get`，不重建）量了：

    cd <scratch>/chip3/diag3 && simv -ucli -do ../sample.tcl <同 plusargs>   # 3000 拍 × 95 个握手信号
    python3 cmp_samples.py diag3/samples.txt diag2/samples.txt

* **握手从复位起 3000 拍与 golden 逐拍逐位相同**（`io_fromRename_*_valid/ready`、`io_toRenameAllFire`、
  `io_enqRob_req_*_valid`、`io_enqRob_canAccept`、34 个 IQ 的 valid/ready、`io_toMem_lsqEnqIO_req_*_valid`）；
  唯一不同的是拍 0–2（reset=1、valid 全 0，`+vcs+initreg+random` 的上电噪声，两侧都没 fire）。
  第一条真派遣在拍 1132：两侧都是 lane 0 fire、进 Rob、进 IQ 口 6，之后两侧都是 `enqRob_canAccept=0`。
  ★重写侧握手信号 3000 拍里没有一位 X/Z。★ 所以「派遣停死」不成立，`ready` 不是芯片不提交的原因。
* **payload 才是**（`payload.tcl`，拍 1132 的 IQ 口 6，两侧同一条 uop：fuType/robIdx/pdest 逐位相同）：

  | leaf | golden | 重写（b804a4f0） |
  |---|---|---|
  | srcState_0 / srcState_1 | 1 / 1（源就绪） | **0 / 0** |
  | srcType_2 | 0000 | 1001 |
  | lqIdx / sqIdx | 0/0000000, 0/000000 | 0/1110011, 1/111001 |
  | useRegCache_0/1, regCacheIdx_0/1 | 0/0, 10000/10000 | **1/1**, 10111/10001 |
  | srcLoadDependency_*_* | 全 0 | 10/11/11/00/01/01 |

  这些正是步骤 2 §4 列的 **20 个 unresolved leaf / 1488 bit**：wrapper 节 3.2 里"集中声明、故意不给驱动"，
  在 `+vcs+initreg+random` 下不是 X 而是随机常量。srcState=0 ⇒ 这条 uop 永远等不到源就绪 ⇒ 永不发射 ⇒ instrCnt=0。
  与 FM 的 1416 个失败点是**同一族**（§4.3），与 `conserveFlowTotal[2][6]` 无关。

结论不变：**FM 那组反例不可达；芯片不启动是"没接完"，不是"接错了"。** 两条交接嫌疑维持排除。

### 5.1 芯片验收跑前登记（先写后跑）

用 coordinator 的 `perfbind2_diag.sh`（本 lane 只改成可钉 commit 的副本 `perfbind2_diag_nd3.sh`），
`TAG=nd3fix COMMIT=333dbae2 EXCLUDE="rtl/backend/Rob.sv rtl/mmu/PtwCache.sv" JOBS=16`。
**预测：仍然 `instrCnt = 0`、"does not commit after 15000 cycles"。** 本轮修法只改了 FM 的可证性形状，
没有接那 1488 bit；按 §5 的机理，srcState 仍是随机常量。若反而提交了 ⇒ §5 的机理判断有错，照实报。
要让 diag3 配置启动，需要的是组 C（lqIdx/sqIdx/useRegCache/regCacheIdx/srcLoadDependency 接线 1182 bit）
**加** srcState/srcType_2 的逐 IQ 新逻辑（306 bit）——这是下一条 lane 的工作量，不在本轮范围。

证据：`evidence/chip-perfbind2-diag3-vs-diag2/`（采样脚本 + 两侧 3000 拍样本 + payload 样本，MANIFEST.sha256）。

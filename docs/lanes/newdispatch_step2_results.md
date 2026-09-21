# NewDispatch 步骤 2 跑后对账（逐条对 `newdispatch_step2_prereg.md` 的登记）

登记见 `docs/lanes/newdispatch_step2_prereg.md`（commit `9863c12390146b22cdea9686807ad92e35b0734b`，
★在任何一次本 lane 的 FM 起跑之前提交★）。本文件只记实测与裁决，**不改登记**。

## 0. 量具与三次跑的口径

所有增量读数都来自**诊断跑**（`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，
永不签核 + 不截断，两个旋钮都只增加信息、不放松判据）。签核 receipt 另跑
`scripts/run_proof.sh`（signoff-strict，limit 保持默认 20），两者不混用。

| 跑次 | commit | worktree | run id |
|---|---|---|---|
| 基线 | `1c58465e277e8b9185f2d574cb3e38cd936bb1ec` | `wt-nd2-base` | `NDbase-diag` |
| 组 A | `1155799337c1ace428f29d1b25af12a448cb1aba` | `wt-nd2-a` | `NDstepA-diag` |
| 组 B | `be28d091f3d585fa7c6515a6b519b4547b54ec79` | `wt-nd2-b2` | `NDstepB2-diag` |

可复跑（任一行）：

    cd <worktree>/verif/ut/NewDispatch && \
      XSSV_HOME=<worktree> FM_MODE=diagnostic-full FM_FAILING_LIMIT=0 make fm-NewDispatch

### ★先说一件把步骤 1 的读数作废的事★

步骤 1 的签核跑读数是 `passing 589 / failing 20 / unverified 51072`。
那个 `20` 是 `verification_failing_point_limit` 的**截断值**：撞到第 20 个失败点
FM 就停止验证，剩下 51072 个点一个都没验。
同一份 RTL 用不截断的诊断跑重测，真实读数是 **`passing 43410 / failing 8271 / unverified 0`**。

★也就是说"passing 589"从来不是"只证对了 589 个点"，而是"停下来之前先验完了 589 个"。★
步骤 1 lane 把它读成"一个点都没多证"，方向上的结论（例化不接输出换不来新点）是对的，
但那个数字本身一直在误导人。本轮所有对账都以诊断跑为准。

## 1. 静态判据（跑 FM 之前就能验）

### 判据 P（上一条 lane 建议，本 lane 登记）：★通过★

`verif/ut/NewDispatch/provable_check.py` 报的"本轮不可证寄存器"：

| 状态 | 登记预期 | 实测 | 裁决 |
|---|---|---|---|
| 组 A 之后 | 仍是 10 | **10**（IQSort_* 全家） | ★PASS★ |
| 组 B 之后 | 归零 | **0**（常量驱动 0 个、被切断次态边 0 条） | ★PASS★ |

    python3 verif/ut/NewDispatch/provable_check.py

### 驱动下限：三把互不相关的量具同一个数

main 那边新落地的 `scripts/rewritten_floor.py`（commit `9c8ac79c`）按**驱动闭包**判，
与本 lane 自己数端口的脚本、与步骤 1 lane 的计数完全独立。三者读数一致：

| commit | rewritten_floor | 本 lane 自测 | 判档 |
|---|---|---|---|
| `1c58465e`（基线） | driven=**5974**/6699 | 未驱动 725 端口 / 6669 bit | PARTIAL_DRIVE |
| `11557993`（组 A） | driven=**6683**/6699 | 未驱动 16 端口 / 56 bit | PARTIAL_DRIVE |
| `be28d091`（组 B） | driven=**6699**/6699 | 未驱动 **0** | **REWRITTEN** |

    XSSV_HOME=<worktree> python3 /home/eda/xs-env/xs-v2-sv/scripts/rewritten_floor.py --module NewDispatch

★注意这把尺子只判"驱动没驱动"，不判"驱动得对不对"★ —— 后者是 FM 的事，见下。

## 2. 组 A 的对账

### 读数

| 量 | 基线 | 组 A | 差 |
|---|---|---|---|
| passing | 43410 | **53005** | **+9595** |
| failing | 8271 | 3266 | −5005 |
| unverified / aborted | 0 / 0 | 0 / 0 | — |
| matched by name | 51681 | 56271 | +4590 |
| matched 但 unread 不比较 | 1848 | 456 | −1392 |
| unmatched_ref | 5309 | **2111** | −3198 |
| unmatched_impl | 1 | 1 | 0 |
| unread_ref / unread_impl | 72 / 5204 | 72 / 2006 | −3198 |

### 判据 A2：★通过★

登记「`unmatched_ref` 落在 **[1500, 2400]**」，实测 **2111**（点估计 2077，差 34）。

机理与登记写的一致：接上 `io_toMem` 之后 `lsqEnqCtrl` 的寄存器终于有了通往输出的
前向锥，不再是 unread，于是能与 golden 侧配对。配上的正好 4590 个
（= unmatched_ref 降的 3198 + matched_nc 降的 1392），两条路数字自洽。

### 判据 A1：★不通过，而且是往"意外地好"的方向破的★

登记：「passing 增量 = **+1945**，可接受区间 **[1850, 1990]**」。实测 **+9595**。

登记里写死的反向出口原话是：

> 如果组 A 的 passing 增量远超 1990，说明「toMem 那 4608 bit 需要正确的
> lsqEnqCtrl 输入」这个判断错了 —— 照实报，不去圆。

**这条出口就是本次触发的。下面把错在哪里逐位指认清楚，不做"差不多"的解释。**

FM 把 passing 按对象分了类，差额因此可以精确二分：

| 对象 | 基线 passing | 组 A passing | 差 |
|---|---|---|---|
| Port（端口位） | 43410 | 49945 | **+6535** |
| DFF（寄存器） | 0 | 3060 | **+3060** |

* **Port +6535 = 1945 + 4590，两项都能逐位说清**：
  * **1945** = `io_enqRob_req_*` 的 355 个直通端口的位数 —— ★与登记的点估计一字不差★。
  * **4590** = `io_toMem_lsqEnqIO_*` 的 4608 bit **减去 18**（`needAlloc` 12 + `req_*_valid` 6）。
    ★我登记时判定这 4608 bit 会整片失败，实测只有 18 bit 失败。★
  * ★错在哪★：我把「`lsqEnqCtrl` 的控制输入这轮还钉在常量 0」推成了
    「它的输出整片不可能等价」。实际上 golden 是把
    `io_fromRename_<i>_bits_<leaf>` **直接**接进 `lsqEnqCtrl.io_enq_req_<i>_bits_<leaf>`，
    而 LsqEnqCtrl 内部又把它**原样转发**到 `io_enqLsq_req_<i>_bits_<leaf>` → 顶层输出。
    这条通路根本不经过那几个控制输入，所以钉不钉 0 都等价。
    真正吃控制输入的只有 `needAlloc` / `req.valid` / `lqIdx` / `sqIdx` / `numLsElem`
    —— 而 `lqIdx/sqIdx/numLsElem` 这几个顶层输出这轮还在别的洞里，
    于是只剩 18 bit 在这一轮真红。
  * ★教训的形状★：「控制信号错 ⇒ 这个子模块的输出全错」是个**直觉上很顺、
    但对 payload 直通型子模块不成立**的推断。子模块有没有把数据和控制分开，
    决定了错误会不会扩散；我按"整块"估，就把 4590 个本来就对的位记成了会错。
* **DFF +3060**：4590 个新配上的 `lsqEnqCtrl` 寄存器里 3060 个直接就等价
  （它们也在 payload 直通侧），1530 个新进失败集。这一项我在登记里**根本没估**
  —— 登记只谈了端口位，没意识到"让子模块寄存器变成可读"本身会带进几千个新比较点。
  ★这是登记的覆盖面漏了一块，不是估错了数★，一并记在这里。

### 组 A 的 3266 个失败点逐类清点（和为 3266，无余项）

| 数量 | 类别 | 组 B 应当解决？ |
|---|---|---|
| 1450 | `io_toIssueQueues_*` 里 leaf ∈ 未接的 20 个（含 `singleStep` 34） | 部分（singleStep 会好） |
| 1546 | `lsqEnqCtrl/u_core/*`（`outReg` 1530 + `lqCounter` 7 + `sqCounter` 6 + `lqPtr` 2 + `t1_redirect` 1） | 是 |
| 102 | `u_core/uopSelIQ_reg[*]`（选择寄存器还冻着） | 是 |
| 48 | `io_perf_*_value` | 是 |
| 42 | `io_enqRob_req_*_bits_numWB` | 是 |
| 34 | `io_toIssueQueues_*_valid` | 是 |
| 12 | `io_toMem_lsqEnqIO_needAlloc_*` | 是 |
| 6+6+6 | `io_enqRob_req_*` 的 `singleStep` / `hasException` / `valid` | 是 |
| 6 | `io_fromRename_*_ready` | 是 |
| 6 | `io_toMem_lsqEnqIO_req_*_valid` | 是 |
| 1 | `io_stallReason_backReason_valid` | 是 |
| 1 | `io_toRenameAllFire` | 是 |
| **3266** | | |

## 3. ★组 B 起跑前就撞上的一件事：Formality 拒绝 link★

组 B 的第一版（`a3766ad66d94a89889a97b7fe549b7a8e0f65ade`）
**签核跑和诊断跑都没跑起来**，两次同一个原因：

    Error: Unsuppressed RTL interpretation message(s) : FMR_VLOG-929
           were produced during link. (FM-262)
    Error: Failed to set top design to 'i:/WORK/NewDispatch' (FM-156)
    Warning: Variable 'allowDispatch' is read and written inside always_comb
             will not be in sensitivity list. ... (NewDispatch.sv Line: 834)

证据：`evidence/a3766ad66d94/NewDispatch/fm.log`（`MAKE_RC` = 2）。

VCS 那边编译与仿真都没意见（阻塞赋值按程序序，`l-1` 先于 `l` 算完），
★所以这是"只有 FM 会拒收"的一类写法 —— UT 绿不代表能证★。

Formality 自己给的"解法"是

    set_mismatch_message_filter -warn FMR_VLOG-929

★那是把仪器的警报关掉，不是把问题修掉，本仓明令禁止，没有采用。★
真修法是 `be28d091`：前缀链改走滚动临时量（`prevAllowed` / `thisAllowed`），
`always_comb` 里从头到尾不读 `allowDispatch` 自己，逻辑一字未改。

判读线索一并记下：整份 log 里 `FMR_VLOG-929` **只有 1 条**、只指 `allowDispatch`。
同一文件里 `blockedByWaitForward` / `notBlockedByPrevious` 也是逐条级联，
但它们读的是普通语句里的 `[l-1]`，没有触发；触发的是
`automatic logic prev = allowDispatch[l-1];` 这种**声明初始化式**里的自读。

## 4. 组 B 的对账

### 读数（`NDstepB2-diag`，commit `be28d091f3d585fa7c6515a6b519b4547b54ec79`）

| 量 | 基线 | 组 A | 组 B | B 相对 A |
|---|---|---|---|---|
| passing | 43410 | 53005 | **51745** | **−1260** |
|   其中 Port | 43410 | 49945 | 50104 | +159 |
|   其中 DFF | 0 | 3060 | 1641 | **−1419** |
| failing | 8271 | 3266 | **4698** | +1432 |
| unverified / aborted | 0 / 0 | 0 / 0 | 0 / 0 | — |
| matched (name+signature) | 51681 | 56271 | 56443 | +172 |
| matched 但 unread 不比较 | 1848 | 456 | 388 | −68 |
| unmatched_ref | 5309 | 2111 | **2006** | −105 |
| unmatched_impl | 1 | 1 | 6 | +5 |

签核跑（signoff-strict，limit 默认 20）：`evidence/be28d091f3d5/NewDispatch/`，
`verdict=FAILED`，`passing 25225 / failing 20(截断) / unverified 31198 / unmatched 2006`。

### 判据裁决

| 判据 | 登记 | 实测 | 裁决 |
|---|---|---|---|
| B1 未驱动 output | 0 | **0**（三把量具一致） | ★PASS★ |
| B2 判据 P | 0 个不可证寄存器 | **0** | ★PASS★ |
| B3 passing 落点 | [48000, 51000]，点估计 50200 | **51745** | ★FAIL（高出区间）★ |
| B4 failing 点集 ⊆ 未接 leaf 及其锥 | 不许出现握手/enqRob/perf 的失败点 | **出现了** | ★FAIL★ |
| B5 unmatched_ref 不上升 | 不上升 | 2111 → 2006 | ★PASS★ |

**B3**：区间建立在组 A 已经证伪的那个前提上（"toMem 那 4608 bit 要等控制修好"），
组 A 一轮就到 53005。★这条不改登记、不追认★，按原样记 FAIL。
真正值得记的是另一件事：**组 B 让 passing 掉了 1260**。

**B4 是本轮最重要的一条，它抓到了真东西。** 见下。

### ★组 B 让 passing 降了 1260 —— 这是真 bug，不是判据太严★

登记里 B4 写死的话是：

> 不许出现 `io_enqRob_*` / `io_toMem_*` / `io_fromRename_*_ready` / `io_toRenameAllFire` /
> `io_perf_*` / `io_stallReason_*` 的失败点。出现任何一个，就是本轮新写的流控写错了，
> **停下来查，不放行**。

实测失败点里**确实有**：`io_fromRename_{2,3,4,5}_ready`、`io_toRenameAllFire`、
`io_enqRob_req_{2,3,4,5}_valid`、`io_toIssueQueues_*_valid`（34 个全红）。
（`io_perf_*` / `io_stallReason_*` / `io_toMem_*` 这三组**没有**失败点 ——
perf / stallReason / toMem 这几路是对的。）

**按登记，本轮到此停手，不再往前接组 C，也不宣布任何绿。**

### 已经查到哪一步（给下一条 lane 的交接，别从头查）

★根因定位到一个很窄的地方★：

* `io_fromRename_0_ready` 与 `io_fromRename_1_ready` **passing**；
  `io_fromRename_{2,3,4,5}_ready` **failing**。`io_enqRob_req_N_valid` 同一批 lane。
* 其余失败点**全部是这四条 ready 的下游**，逐条对得上：
  * `io_toRenameAllFire` = `&(~valid | firedVec)` —— firedVec[2..5] 错则错；
  * `u_core/uopSelIQ_reg[0..5]` 102 位全红 —— 装载条件是 `toRenameAllFire`，
    它一错，**六条 lane 的选择寄存器一起错**（这解释了为什么 lane0/1 的 ready 对、
    uopSelIQ 却全红：★FM 的每个比较点是"假设所有已配对寄存器相等"下的函数比较，
    所以这里红的是次态函数，不是状态传播★）；
  * `u_core/conserveFlowTotal_reg[0..5]` 33 位（每个 reg 只红它的非常量位）——
    次态选择子是 `toRenameAllFire`；
  * `lsqEnqCtrl/u_core/*` 约 3000 点 —— 它的 `iqAccept / needAlloc / req.valid`
    现在被喂了真值但那个真值是错的。★注意这是组 A 到组 B 掉 1419 个 DFF passing 的来源★：
    组 A 那些输入钉 0，payload 直通侧的 3060 个寄存器反而是等价的；
    组 B 喂进错的控制值，把其中 1419 个弄红了。
* ★已经逐字核对过、确认与 golden 一致的（不用再查）★：
  `blockedByWaitForward_2` / `thisCanActualOut_2` / `allowDispatch_{0,1,2}` /
  `isLoadVec` / `isVLoadVec` / store 侧判据 / `ready` 的四因子合取式，
  golden 原文与本文件节 2.8 的写法逐项对应（含 Verilog 的 `>` 先于 `&` 的优先级）。

**于是剩下的嫌疑收敛成两条，下一条 lane 从这里开始**：

1. ★节 2.6 的 `uopBlockByIQ`★ —— 这是唯一一个**只在 lane≥2 才可能生效**的项：
   `uopBlockMatrix[l][q] = iqReady[q] ? (cnt > 3'd2) : (|cnt)`，
   而 `cnt` 是 lane 0..l 的前缀计数，`cnt > 2` 要 `cnt ≥ 3`，
   **lane 0 和 lane 1 的前缀计数最大只有 1 和 2，这一支对它们是死码**。
   「lane0/1 对、lane2-5 错」这个分界与它一一对应，是目前最强的嫌疑。
   注意这段逻辑是**步骤 1 就写好的**，但那时 uopSelIQ 冻着、从来没被真正验过。
2. `always_comb` 的 `for` 体里 `automatic logic [2:0] cnt = '0;` 这种
   **声明初始化式**的读法 —— 本轮已经实测到 Formality 对同类构造
   （`automatic logic prev = allowDispatch[l-1];`）的读法足以让它**拒绝 link**。
   FM 与 VCS 在这类构造上未必同解，值得单独做一次最小复现。

### 本轮明确**没有**做的事（防止被读成已完成）

* 没有跑出可用的 UT 结论：3 个 seed × 200k 的仿真在机器满载下跑了 40 分钟仍未结束，
  ★本报告不含 UT 读数★。而且按现在的 RTL，UT 也**应当**是红的 ——
  tb 的判据 A 这轮刚收紧成"除 536 个悬空端口外每一位都必须始终一致"，
  而 ready[2..5] 是错的。
* 没有做组 C（`lqIdx/sqIdx/useRegCache/regCacheIdx/srcLoadDependency` 的接线）。
  登记里写的是"若组 A、组 B 都按预测落地且时间允许"才做，组 B 没落地，不做。
* ★没有用任何手段把红变绿★：没有 `dont_verify`、没有放松 appvar、没有白名单、
  没有加宽黑盒、没有 `set_mismatch_message_filter`。

## 5. 台账措辞（codex 0168 §1）

本 target 的 ref 走 golden child、impl 走重写 child。本轮**没有任何东西转绿**，
将来即便转绿也只能记「**在 NewDispatch 上下文中**已被覆盖」，
★不许写成那 9 个 child 各自的独立 `SIGNOFF_PASS`★。

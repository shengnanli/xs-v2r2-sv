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

（待 `NDstepB2-diag` 与签核跑落地后补。★B3 的区间已经可以预告会破★：
登记的 `[48000, 51000]` 是在"toMem 那 4608 bit 要等控制修好"这个**已被证伪的**
前提上算的，而组 A 一轮就已经到 53005。这条会和 A1 一样记成不通过，
**不改登记、不追认**。真正还有信息量的是 B4 那条硬判据 —— 失败点集必须
⊆ `io_toIssueQueues` 里那 20 个未接 leaf 及其锥。）

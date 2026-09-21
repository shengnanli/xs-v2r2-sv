# NewDispatch 步骤 2 跑前登记（接 725 个未驱动 output）★先提交，再动 FM★

登记人：本 lane（agent/newdispatch2，基线 `1c58465e277e8b9185f2d574cb3e38cd936bb1ec`）。
本文件**在任何一次本 lane 的 FM 起跑之前提交**，跑完逐条对账，**不许事后改**。

## 0. 本轮的量测仪器：为什么必须换成 `FM_FAILING_LIMIT=0`

步骤 1 的读数是 `passing 589 / failing 20 / unverified 51072`。
`failing` 那个 **20 是 `verification_failing_point_limit` 的截断值** ——
撞到第 20 个失败点 FM 就停止验证，剩下的 51072 个点**一个都没验**，
全部计进 `unverified`。

于是 **`passing` 在这个配置下几乎不含信息**：它等于"停下来之前碰巧先验完的点数"，
既不是"对的点有多少"，也不随设计变好而单调上升。
拿它做增量对账，会把"改对了但失败点仍≥20"读成"一点没改进"。

所以本轮的增量量测全部改用**诊断跑**：

    make fm-NewDispatch FM_MODE=diagnostic-full FM_FAILING_LIMIT=0

`diagnostic-full` 按 `fm_verdict.py` 的规矩**永不签核**（不出 SUCCEEDED），
`FM_FAILING_LIMIT=0` 是**增加信息**的旋钮（不截断），两者都不放松任何判据。
签核 receipt 另跑 `scripts/run_proof.sh NewDispatch NewDispatch`（signoff-strict，
limit 保持默认 20），两者不混用。

★为此本 lane 先在**基线 commit `1c58465e`** 上跑了一次同配置的诊断跑
（worktree `/home/eda/xs-env/wt-nd2-base`，`FM_RUN_ID=NDbase-diag`），
作为所有增量的**同口径基线**。它测的是已提交的旧字节，不是本登记要预测的对象。★

## 1. 本轮改动怎么分组（两次提交，各跑一次诊断）

### 组 A：只接线，**零新逻辑**

1. `gen_childinst()`：child 的输出，凡 golden 直接接到顶层 output 端口的，
   impl 也直接接 —— 不再新开一根 `_<inst>_<port>` 中间线。
   这一条就把 **330 个 `io_toMem_lsqEnqIO_*` 端口 / 4608 bit** 接上了。
   （步骤 1 之所以一个点没涨，根因就在这里：golden
   `.io_enqLsq_req_0_valid (io_toMem_lsqEnqIO_req_0_valid)` 是直连，
   步骤 1 却接到了一根没人读的本地线上。）
2. 新生成段 `ENQROB`：`io_enqRob_req_*` 共 **379 端口 / 2005 bit**，
   其中 **355 端口 / 1945 bit 是 `io_fromRename_*_bits_*` 逐字直通**，
   另 24 端口 / 60 bit（`valid` / `hasException` / `numWB` / `singleStep`）
   要流控才算得出来，组 A 里接 `unresolved_*`（**悬空，不钉 0**）。

组 A 之后：未驱动 output 从 **725 端口 / 6669 bit** 降到 **16 端口 / 56 bit**。

### 组 B：派遣流控（真逻辑）

`xs_NewDispatch_core` 新增节 2.8~2.12：访存分类 / `conserveFlowTotal`（不复位寄存器）/
`allowDispatch` / `thisCanActualOut` / `ready`+`firedVec`+`toRenameAllFire` /
单步调试状态机 / 给 LsqEnqCtrl 与 busy table 的入队信号 / perf 与 stallReason 口径。
wrapper 新增节 3.6（握手/perf/stallReason 出口，含 8 组两级 perf 寄存器与
`lsqEnqCtrl_io_redirect_REG_valid`）。

组 B 之后：**未驱动 output = 0**；`unresolved_ci_*` 37 条全部消失；
`unresolved_toRenameAllFire` / `unresolved_firedVec` / `unresolved_rename_valid`
三个占位常量删除。

**仍然留着的洞（本轮不碰，如实写在这里）**：
`srcState_0..4` / `srcType_2` / `lqIdx` / `sqIdx` / `useRegCache_*` /
`regCacheIdx_*` / `srcLoadDependency_*_*` 这 20 个 leaf 仍接 `unresolved_*`，
它们只影响 `io_toIssueQueues_*`，**合计 608 端口 / 1488 bit**（逐 leaf 明细见 §4）。

## 2. ★跑 FM 之前就能验的判据（上一条 lane 建议，本 lane 登记）★

**判据 P**：删掉 `unresolved_toRenameAllFire` / `unresolved_firedVec` 两行常量之后，
`verif/ut/NewDispatch/provable_check.py` 报的那 **10 个"本轮不可证寄存器"应当归零**
（IQSort_alu / _falu_fmac / _fdiv / _jmp_brh / _ldu / _mul_bku / _sta_mou /
_vfalu / _vialuFix_vfma / _vldu_vstu）。

* 组 A 之后仍应是 **10 个**（组 A 没动那两行常量）。
* 组 B 之后应当是 **0 个**。
* 若组 B 之后不为 0 ⇒ 我对"常量门控切断次态锥"这件事的理解有错，**停下来查**。
* 若组 A 之后就少了 ⇒ 同样停下来查（组 A 不该动到这条链）。

★本判据在本文件提交之前**没有跑过**。★

## 3. passing 的落点预测

### 模型与它的适用范围

`scripts/fm_predict.py model NewDispatch` 给 `expected=59000 (regs 7437 + outs 51563)`，
并且**自己就标了"模型不适用（merge_dup=true）"**。本目标 `merge_dup=true`，
模型只能当 **BOUNDED(≤ 59000)** 的上界用，
`59000` 与实测之间的带宽相对量级远超 30% —— ★按登记要求如实写：这个模型在本目标上**近乎无信息**★。
所以下面的预测**不从模型推**，而是从"哪些 output bit 的两侧锥现在逐字相同"数出来。

### 组 A 的预测（相对 **基线诊断跑**）

* **A1（本组最硬的一条）**：`passing` 增量 = **+1945**，可接受区间 **[1850, 1990]**。
  依据：新接上的 6613 bit 里，只有 `io_enqRob` 的 355 个直通端口（1945 bit）
  两侧都是"顶层输入直连输出"，无条件等价；其余 4608 bit（`io_toMem`）
  由 `lsqEnqCtrl` 驱动，而它的 `iqAccept / needAlloc / req.valid / numLsElem / redirect`
  这一轮**还钉在常量 0**，不可能与 golden 等价。
  区间下沿留 95 是给 FM 常量折叠（部分位可能在基线就已被判常量而算过了）。
  ★落在区间外就停下来查，不往前堆。★
* **A2**：`unmatched_ref` 大幅下降，落在 **[1500, 2400]**（基线 5309，其中
  `lsqEnqCtrl` 名下 3232）。依据：接上 `io_toMem` 之后 `lsqEnqCtrl` 的寄存器
  终于有了通往输出的前向锥，不再是 unread，于是能与 golden 侧配对。
  `unread_impl` 应同步下降同一量级。
* **A3（不是判据，是预期）**：`failing` 会从 20（截断值）涨到**数千**量级，
  主要是 `io_toMem` 的 4608 bit。这**不是变坏**：诊断跑不截断，
  失败点从"被隐藏在 unverified 里"变成"被点名"。

### 组 B 的预测（相对 **组 A 的诊断跑**）

* **B1**（静态，不用跑 FM）：未驱动 output = **0 端口 / 0 bit**。
* **B2**：判据 P = **0 个不可证寄存器**。
* **B3（passing 落点）**：`passing` 落在 **[48000, 51000]**。
  推导：总 output bit 51563；本轮之后仍然接 `unresolved_*` 的
  `io_toIssueQueues` 位 **1488 bit**，其中 `srcState_*` 有 **72 bit**
  被节 1.4 的 `SRCSTATE_LIVE` 掩码两侧同折成常量 0（应当仍然 pass），
  故预期失败的 output bit ≈ **1416**；再加上寄存器比较点（golden 7437 个寄存器位，
  merge_dup 会合并掉一部分，且 `srcState` 锥里的 busy table 寄存器会跟着失败）。
  于是 passing ≈ 51563 − 1416 + (配上且算对的寄存器点) ，
  取区间 **[48000, 51000]**，点估计 **50200**。
  ★这个区间宽达 3000，本身就说明"寄存器比较点有多少能配上"我估不准★ ——
  如实登记为**弱预测**；真正硬的是下面 B4。
* **B4（硬判据，本组最有信息的一条）**：诊断跑的 **`failing` 点集应当
  ⊆ {`io_toIssueQueues_*` 里 leaf ∈ 那 20 个 unresolved 的端口} ∪ {它们锥内的寄存器}**。
  换句话说：**不许出现 `io_enqRob_*` / `io_toMem_*` / `io_fromRename_*_ready` /
  `io_toRenameAllFire` / `io_perf_*` / `io_stallReason_*` 的失败点**。
  出现任何一个，就是本轮新写的流控写错了，**停下来查，不放行**。
* **B5**：`unmatched_ref` 进一步下降（`rcTagTable` 388 + busy table 家族的一部分
  仍可能配不上，因为它们的输出还接在 `unresolved_*` 上）；
  不设区间，只要求**不上升**。上升 = 新逻辑引入了新的配不上，停下来查。

### 反向出口（登记里最要紧的一条）

> 我预期组 A 只买到 1945 个点、组 B 才是大头。
> **如果组 A 的 passing 增量远超 1990**，说明"toMem 那 4608 bit 需要正确的
> lsqEnqCtrl 输入"这个判断错了 —— 照实报，不去圆。
> **如果组 B 之后 `failing` 里出现 enqRob / toMem / 握手 / perf 的点**，
> 就是流控写错，照实报卡在哪、差多少点，**不许靠放宽判据或加黑盒过关**。

## 4. 本轮之后仍未接的 20 个 leaf（逐 leaf bit 数，量自 `rtl/backend/NewDispatch.sv`）

| leaf | bit | 真来源 |
|---|---|---|
| srcState_0..4 | 各 34（共 170） | 5 个 busy table 的 `allSrcState`（**逐 IQ 取不同子集**，不是逐 lane 的标量） |
| srcType_2 | 136 | `ignoreOldVd`（VlBusyTable 的 vl 读口） |
| lqIdx_flag / lqIdx_value | 34 / 238 | `lsqEnqCtrl.io_enq_resp_*` |
| sqIdx_flag / sqIdx_value | 34 / 204 | 同上 |
| useRegCache_0/1 | 各 34 | `rcTagTable.io_readPorts_*_valid` |
| regCacheIdx_0/1 | 各 170 | `rcTagTable.io_readPorts_*_addr` |
| srcLoadDependency_{0,1}_{0,1,2} | 各 44（共 264） | `intBusyTable.io_read_*_loadDependency_*` |
| **合计** | **1488** | |

★`srcState_*` 与 `srcType_2`（306 bit）是**真需要新逻辑**的：
golden 的 `IQSelUop(q).bits.srcState(j)` 是"按该 IQ 的 FU 会读哪几个寄存器堆，
把 `allSrcState(lane)(j)(k)` 的对应子集 OR 起来"，
**子集逐 IQ 不同**，因此它不可能用现在这种"每 lane 一个标量 srcState_j"的形状表达 ——
现有核的节 1.4 掩码只表达了"这一位是不是恒 0"。这条结构性结论本 lane 新查清，
留给下一条 lane，本轮不假装能接。★
其余 1182 bit 只是接线（`lqIdx/sqIdx/useRegCache/regCacheIdx/srcLoadDependency`），
若组 A、组 B 都按预测落地且时间允许，作为**组 C** 再接，另行登记。

## 5. 台账措辞（codex 0168 §1，写在跑之前免得跑完忘）

本 target 的 ref 走 golden child、impl 走重写 child。即便将来转绿，
也只能记「**在 NewDispatch 上下文中**已被覆盖」，
★不许写成那 9 个 child 各自的独立 `SIGNOFF_PASS`★ ——
它们另有各自的 standalone 绿 receipt，那是另一件事，两者不得互相冒充。

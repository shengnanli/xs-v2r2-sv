# NewDispatch 步骤 1（只例化 7 个 child，不写控制逻辑）★跑前登记，跑后不改★

登记时间：2026-09-20。本文件**先提交，然后才动 RTL**。

## 基线（例化前，commit `410fc349`）

匹配阶段实测（`fm_work/NewDispatch/fm.log` 的 Matching Results）：

| 项 | 值 |
|---|---|
| Compare points matched by user | 102 |
| matched by name / signature / topology | 0 / 0 / 0 |
| Matched primary inputs, black-box outputs | 4708 |
| **Unmatched reference(implementation) compare points** | **7118(0)** |
| Unmatched reference(implementation) unread points | 72(0) |

`provable_check.py`：常量驱动 4 个、被切断次态边 1 条、**本轮不可证寄存器 10 个**
（IQSort_alu / _falu_fmac / _fdiv / _jmp_brh / _ldu / _mul_bku / _sta_mou /
_vfalu / _vialuFix_vfma / _vldu_vstu）。

## 机理与预测

9 个 child 的 golden 寄存器位（`fm_passing_model.reg_bits` 逐个算）：

| child | 寄存器位 |
|---|---|
| LsqEnqCtrl | 4653 |
| BusyTable | 1568 |
| RegCacheTagModule | 240 |
| BusyTable_1 | 192 |
| RegCacheTagModule_1 | 180 |
| BusyTable_2 | 128 |
| VlBusyTable | 96 |
| BusyTable_3 | 22 |
| RegCacheTagTable | 0 |
| **合计** | **7079** |

机理：impl 侧一个 child 都不例化 ⇒ golden 侧这 7079 个寄存器位**没有对应物**，
整批落进 ref-unmatched。基线 7118 − 7079 = **39**，这个吻合度本身就是该机理的证据。

### ★预测（可证伪，三个方向都写死）★

1. **unmatched compare(ref) 从 7118 降到 39 量级**（降幅 ≈7079）。
   可接受区间 **[0, 400]**；落在 400 以上说明 child 的寄存器没配上。
2. ★`provable_check.py` 那 10 个寄存器一个都不许减少★ —— 必须仍然是 **10 个**。
   若减少，说明"接线也能解开次态锥"这件事我们没想明白，**停下来查，不当成好消息**。
3. **unmatched 不会到 0，且 FM 仍然不是 SUCCEEDED**。

### ★反向出口（这条是登记里最要紧的一句）★

> 我预期 unmatched 大幅下降但**不会到 0**，且 provable_check 仍报那 10 个。
> **如果 unmatched 意外降到接近 0，说明我对"还缺控制逻辑"的判断错了——照实报。**

同样地：如果 unmatched **几乎不降**（仍在 7000 以上），说明"child 悬空是根因"
这个判断整个是错的，也照实报，不找第二个解释去圆。

## 一个已知的不确定项（先说在前面）

例化只让 child 的寄存器在 impl 侧**存在**，能不能**配上**是另一回事。
有利证据：这 4 个 child 各自的 UT **都不需要钉点文件**（`verif/ut/{BusyTable,
LsqEnqCtrl,RegCacheTagTable}` 下无 `fm_pins*.tcl`），说明它们单独跑时靠
名字/签名就能配上。为把这个优势带进 NewDispatch，★例化时用 golden 的实例名★：
`intBusyTable` / `fpBusyTable` / `vecBusyTable` / `v0BusyTable` / `vlBusyTable` /
`rcTagTable` / `lsqEnqCtrl`。若仍配不上，那就是要加钉点，属预期内的第二档工作。

## 步骤 1 的范围（写死，防止越界）

* 只做例化：1116 条连线里**只接那 920 条只引用顶层端口的**；
* 其余 196 条（`firedVec_*` / `allocPregsValid_*` 等）**维持现状**接 `unresolved_*`/常量；
* **不写** `allowDispatch` / `uopBlockByIQ` / `thisCanActualOut` —— 那是步骤 2。

---

## ★跑后补记：基线权威数是 7173 不是 7118，且我引错过一次★

**预测区间一个字没改**（下面只更正基线口径并细化分解）。

### 我的错

上面基线表里我写的 `7118(0)` 是从**还在跑**的 `fm.log` 的 Matching Results 块读的。
权威数应当取 receipt / `unmatched.rpt`：**`unmatched_ref = 7173`**。
★这正是本轮反复讲的那条「别把中间态当结果」，我自己又犯了一次★ ——
而且这次特别隐蔽：日志里有 **3 个** Matching Results 块（7220 / 7118 / 7118），
末块的 7118 看起来就是终值，但 `unmatched.rpt` 记的是 7173。

### 更有用的是：7173 能**按名字**精确二分

| 分类 | 数量 | 归属 |
|---|---|---|
| 名字含 `IQSort` | **55** | NewDispatch **自己**的寄存器 → 步骤 2 |
| 其余 | **7118** | 7 个 child 的寄存器 → 步骤 1 |
| 合计 | 7173 | |

而那 55 个**恰好就是** `provable_check.py` 静态判出的那 10 个寄存器：
IQSort_alu 16 / _falu_fmac 9 / _jmp_brh 9 / _ldu 9 / _fdiv 2 / _mul_bku 2 /
_sta_mou 2 / _vfalu 2 / _vialuFix_vfma 2 / _vldu_vstu 2 = 55 位。
★静态预判与 FM 实测一一对上，这是对 provable_check.py 的一次强验证。★

### 预测按名字重述（区间不变，只是更锐利）

* **非 IQSort unmatched：7118 → 预测 39 量级**（7118 − 7079 = 39）。
  仍用登记的可接受区间 **[0, 400]**，★不放宽★。
* **IQSort unmatched：必须仍然恰好 55**。变少 = 接线解开了控制锥，停下来查；
  变多 = 例化引入了新问题。
* 合计 unmatched 预测落在 **[55, 455]**。

反向出口不变：降到接近 0 ⇒ 我对"还缺控制逻辑"判断错了；几乎不降 ⇒ 根因判断整个错了。

---

## ★第二段登记：步骤 1 的 FM 实测（本段写于 FM 起跑之前，2026-09-21）★

上一条 lane 写完 RTL（`1b448544` 例化 7 个 child）就断在跑 FM 的路上，
**步骤 1 从未出过 receipt**。本段由接手 lane 在起跑前写死，跑完不改。

### 我重测过的量（不引用交接里的数）

| 量 | 交接给的 | 我实测 | 出处 |
|---|---|---|---|
| `rtl/backend/NewDispatch.sv` 行数 | 17626 | **17626** | `wc -l` @ `d867a0da` |
| 已驱动 `assign io_` | 5974 | **5974** | `grep -cE '^\s*assign io_'` |
| child 例化行 | 7 | **7** | 16450/16600/16676/16746/16792/16845/16974 |
| 基线 unmatched_ref | 7173 | **7173** | `evidence/410fc349f03c/NewDispatch/receipt.json` |
| 其中 IQSort | 55 | **55** | `unmatched.rpt` 逐行分类 |
| 其中非 IQSort | 7118 | **7118** | 同上 |
| passing 模型 | 59000 (regs 7437) | **59000 (regs 7437 + outs 51563)** | `fm_predict.py model`（合 main 取 `$(VAR)` 展开修复后） |

旧登记 `expected=51921 / regs=358` 作废（`$(VAR)` 没展开，7 个 child 一个都没计进来），
已按修复后的读法重新登记。**注意 `merge_dup=true`，模型不适用**，
`fm_predict check` 只会给 `BOUNDED`/`MODEL_NA`，不作为绿灯依据。

### ★点估计的一处修正（收紧，不放宽）★

上一段用静态 `reg_bits` 合计 **7079** 推出残差点估计 39。但把基线 `unmatched.rpt`
按实例名归类，真正落在 7 个 child 实例下的点是：

    lsqEnqCtrl 4653 + intBusyTable 1568 + rcTagTable 388 + fpBusyTable 192
    + vecBusyTable 128 + vlBusyTable 96 + v0BusyTable 22 = **7047**

（`rcTagTable` 388 ≠ 静态表的 240+180=420，静态表按 module 名算、实测按实例锥算。）
于是非 IQSort 里 **NewDispatch 自己的寄存器是 7118 − 7047 = 71**，不是 39。

**点估计从 39 改成 71；可接受区间仍是登记的 [0, 400]，一个字不放宽。**
这修正只可能让判据更难通过（71 比 39 离 0 远），不是事后迁就。

### 本次三条判据（与第一段完全一致，只是把点估计换成 71）

1. 非 IQSort unmatched：7118 → 预期 **71 量级**，可接受区间 **[0, 400]**。
   落在 400 以上 ⇒「child 悬空是根因」只对了一半，★照实报★。
2. IQSort unmatched：★必须仍然恰好 55★。变少也要停下来查。
3. 合计 unmatched 落在 **[55, 455]**；且 FM 仍不是 SUCCEEDED（步骤 2 未写）。

### 已知会误导的一条：`failing` 是截断值

`verification_failing_point_limit` 默认 20，撞上就停止验证、余下全计入 `unverified`。
基线 `failing 20 / unverified 51056` 就是同一件事的两面。
**本次签核跑不动这个限值**（动了不出 receipt）；真实失败集合另跑
`FM_FAILING_LIMIT=0 --mode diagnostic-full`，那份 log ★不出 receipt★。

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

# EnqEntry* FM passing 预登记与对账 —— ★用官方工具，本目录不另起炉灶★

登记与对账一律走 `scripts/fm_predict.py`：

```
python3 scripts/fm_predict.py model    EnqEntry ...     # 只算不写
python3 scripts/fm_predict.py register EnqEntry ...     # 写 docs/fm_predictions/<top>.json，然后 commit
python3 scripts/fm_predict.py check    EnqEntry ...     # 跑后对账（读 git HEAD 的登记）
```

本目录**曾经**有一份自己写的 `predict.py` / `reconcile.py`（同一个模型、同一批数字），
已经删掉。理由不是它算错了（它和官方工具逐个变体同值），而是
**同一条判据有两份实现 = 两份都得维护、迟早分叉**，而分叉的那一刻没有任何东西会响。

## 登记值（`docs/fm_predictions/EnqEntry*.json`，commit 见 git log）

| 变体 | 父级 Entries 变体 | golden regs | outs | expected passing | 钉点对数 |
|---|---|---|---|---|---|
| `EnqEntry` | AluMulBkuBrhJmp | 1447 | 2171 | **3618** | 1432 |
| `EnqEntry_4` | AluBrhJmpI2fVsetriwiVsetriwvfI2v | 1449 | 2189 | **3638** | 1432 |
| `EnqEntry_6` | AluCsrFenceDiv | 1446 | 2170 | **3616** | 1432 |
| `EnqEntry_8` | FaluFcvtF2vFmacFdiv | 1426 | 2101 | **3527** | 1411 |
| `EnqEntry_10` | FaluFmacFdiv | 1424 | 2095 | **3519** | 1411 |
| `EnqEntry_12` | FaluFmac | 1423 | 2092 | **3515** | 1411 |
| `EnqEntry_14` | VfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 1479 | 2379 | **3858** | 1461 |
| `EnqEntry_16` | VfmaVialuFixVfalu | 1459 | 2337 | **3796** | 1446 |
| `EnqEntry_18` | VfdivVidiv | 1458 | 2333 | **3791** | 1446 |

## ★模型的前提在本族成立，而且是**读回来的**不是推的★

模型 `expected = Σ实例寄存器位 + 顶层 output 端口位` 只在
`verification_merge_duplicated_registers = false` 时成立（merge 打开时比较点被合并，
少多少不是能从 golden 静态算出来的量）。

本族 9 个 Makefile 都显式写着 `FM_MERGE_DUP = false`（原因是 golden 把负载展平成
上百个逐字段寄存器、其中整组是常数，merge 会把它们并掉而可读核的向量不并 ——
置 false 是**加强**：要求逐个比而不是合并后比）。`fm_predict.py` 对 9 个变体
逐个判「模型适用」。

★并且从真跑的 sidecar 里读回来核对过★（`fm_work/EnqEntry/sidecar/native_facts.json`
的 `entry_appvars`）：

```
verification_merge_duplicated_registers      = false
verification_verify_matched_unread_compare_points = false
hdlin_unresolved_modules                     = black_box
```

「Makefile 里写了 false」和「fm_shell 里真的是 false」是两件事，这里两件都核过了。

## 对账现状：★9 个一个都还没出 receipt★

卡在共享核 `rtl/backend/xs_iq_entries_core.sv` 一行，本 lane 不许改那个文件。
详见同目录 `CORE_BLOCKER.md`。

唯一跑过的一次（EnqEntry，仓库现状未改核）：

```
FAILED  passing=3616  failing=2  unmatched=0  unread=0  constant_reg=null
        失败的两点 = io_commonOut_perfWakeupByWB_0 / _1
```

`3616 + 2 = 3618 = 登记值`。差额 2 **全部**由那两个已知错掉的输出占掉，
不是模型不准，也没有第三个来源。核补上之后再跑，用
`python3 scripts/fm_predict.py check EnqEntry ...` 出正式对账。

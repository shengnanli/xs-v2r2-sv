# EnqEntry* FM passing 预登记（★跑前写死，跑后不改★）

本文件在**任何一次 FM 跑之前**写入并提交（commit 见 git log）。跑完逐条对账，
对不上就把差额**逐位指认出来**，不许把模型调成实测值。

模型与「为什么本族直接用等号而不是区间」的依据写在 `predict.py` 的 docstring 里。
一句话：模型 = golden「寄存器位 + 顶层 output 端口位 + Σ 子实例寄存器位」；
OthersEntry lane 在**同一个核、同一档单条目**上连着两批共 18 个目标实测差全为 +0，
所以本族的判据是 `passing == model`（等号），不是区间。

## 复算
```
cd verif/ut/EnqEntry_common && python3 predict.py
```

## 输入固定（跑前的 sha256）

| 项 | sha256 |
|---|---|
| `predict.py` | `a7bf2a079b5591e34db616b9b2eb7736b7d7aaa82983de608e806461ff59af64` |
| `enqentry_gen.py` | `fca2f5b89bd3593aeaa8df3b190fe8f1633b8bbf344356a7e78615e6b5d7da2e` |
| `gen_fm_pins.py` | `68174edb743cce7aa12509daa2ae8d124a4079b64d0f776c94109bee3334fa41` |
| golden 9 文件 cat 后 | `99fe995ebb4c2297a28924ede1c53c565188712b36a69577a3e128fb8c97692b` |
| `rtl/backend/xs_iq_entries_core.sv` | `e4e4491009971cfaade049d58f977c68b7dba9f0d840f379649b3d25d934ba41` |

核的 sha256 记在这里是因为它是**共享**的：另外两条 lane 在动它。
换了核就换了被证对象，这张表要重算一遍再登记。
（此刻这一份与 `agent/othersentry` 在 PREDICTIONS.md 里登记的那一份**同 hash**。）

## 预测（本 lane 范围内 9 个变体）

| 变体 | 父级 Entries 变体 | golden regs | 子实例 regs | outs | 模型(=预测 passing) | 钉点对数 |
|---|---|---|---|---|---|---|
| `EnqEntry` | AluMulBkuBrhJmp | 1447 | 0 | 2171 | **3618** | 1432 |
| `EnqEntry_4` | AluBrhJmpI2fVsetriwiVsetriwvfI2v | 1449 | 0 | 2189 | **3638** | 1432 |
| `EnqEntry_6` | AluCsrFenceDiv | 1446 | 0 | 2170 | **3616** | 1432 |
| `EnqEntry_8` | FaluFcvtF2vFmacFdiv | 1426 | 0 | 2101 | **3527** | 1411 |
| `EnqEntry_10` | FaluFmacFdiv | 1424 | 0 | 2095 | **3519** | 1411 |
| `EnqEntry_12` | FaluFmac | 1423 | 0 | 2092 | **3515** | 1411 |
| `EnqEntry_14` | VfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 1479 | 0 | 2379 | **3858** | 1461 |
| `EnqEntry_16` | VfmaVialuFixVfalu | 1459 | 0 | 2337 | **3796** | 1446 |
| `EnqEntry_18` | VfdivVidiv | 1458 | 0 | 2333 | **3791** | 1446 |

「子实例 regs」那一列的 0 是**算出来的**不是假设的：`EnqEntry/_4/_6` 各例化 6 份
`UIntCompressor_27_000011100000000000001010101`、`_8/_10/_12` 各例化 9 份
`UIntCompressor_27_000000000000001010100000000`、`_14/_16/_18` 无子实例；
UIntCompressor 是纯组合压缩器，`reg` 声明数为 0。

判据：`实测 passing == 模型` 且 `failing = 0` 且 `unmatched = 0` 且 `unread = 0`
（本族 `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS=false`，首跑 unread 就该是 0；
不是 0 一律停下诊断，不许改那一行凑绿）。
差 != 0 一律按 fail 上报，按 receipt 里的 `constant_reg` / `unread` / `black_box`
逐位指认缺口 —— **不在事后调模型**。

## 对账

- 复算：`python3 reconcile.py <commit前缀>`（实测那一列从
  `evidence/<commit>*/<top>/receipt.json` 的 `verdict_detail` 机械读，非手抄；
  非零退出 = 对不上）。

### 状态：★9 个变体一个都还没出 receipt★

原因**不是**模型或钉点，是共享核 `rtl/backend/xs_iq_entries_core.sv` 里
`o_dbg_perf_wakeup_by_wb` 的门控信号对 `IS_ENQ` 是错的，本 lane 不许改那个文件。
详见本目录 `CORE_BLOCKER.md`。核补上之前 9 个变体的 UT/FM 都会且只会在
`io_commonOut_perfWakeupByWB_*` 上红，出 receipt 没有意义。

对账表在核落地、9 个目标跑完之后由 `reconcile.py --md` 生成后贴在这里，
★上面那张预测表原样保留，不改★。

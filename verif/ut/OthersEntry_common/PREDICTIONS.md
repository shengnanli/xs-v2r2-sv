# OthersEntry* FM passing 预登记（★跑前写死，跑后不改★）

本文件在**任何一次 FM 跑之前**写入并提交。跑完逐条对账，对不上按 fail 上报。
模型与带宽的依据写在 `predict.py` 的 docstring 里（沿用 Entries* 家族那份模型，
带宽因为本族是单条目、规模小一到两个数量级而放宽，并把带宽本身登记为待反标定项）。

## 复算
```
cd verif/ut/OthersEntry_common && python3 predict.py
```

## 输入固定

| 项 | sha256 |
|---|---|
| `predict.py` | `c6e681648d7f29a8720af7a9a62d14af0822f1931cbab9f7f2d3a05ee19334dd` |
| `othersentry_gen.py` | `6bf97782d0ed5f86ef2b36acdcc6353e738a71016bf7e9dc76d361911f011d53` |
| golden 24 文件 cat 后 | `a4b5cf5023947216d3959f67783c561b007dc302d731717850d8cfa6713a04d3` |

## 预测（12 个 INT/FP 变体，本轮落地的那批）

| 变体 | 角色 | regs | outs | 模型(上界) | 可接受下界 | 实测 passing | 对账 |
|---|---|---|---|---|---|---|---|
| `OthersEntry_44` | simp | 1449 | 2190 | **3639** | 3275 | _待填_ | _待填_ |
| `OthersEntry_50` | comp | 686 | 740 | **1426** | 1226 | _待填_ | _待填_ |
| `OthersEntry_66` | simp | 1446 | 2171 | **3617** | 3255 | _待填_ | _待填_ |
| `OthersEntry_72` | comp | 670 | 724 | **1394** | 1194 | _待填_ | _待填_ |
| `OthersEntry` | simp | 1447 | 2172 | **3619** | 3257 | _待填_ | _待填_ |
| `OthersEntry_6` | comp | 670 | 724 | **1394** | 1194 | _待填_ | _待填_ |
| `OthersEntry_88` | simp | 1426 | 2102 | **3528** | 3175 | _待填_ | _待填_ |
| `OthersEntry_90` | comp | 626 | 675 | **1301** | 1101 | _待填_ | _待填_ |
| `OthersEntry_104` | simp | 1424 | 2096 | **3520** | 3168 | _待填_ | _待填_ |
| `OthersEntry_106` | comp | 622 | 671 | **1293** | 1093 | _待填_ | _待填_ |
| `OthersEntry_120` | simp | 1423 | 2093 | **3516** | 3164 | _待填_ | _待填_ |
| `OthersEntry_122` | comp | 620 | 669 | **1289** | 1089 | _待填_ | _待填_ |

判据：实测 passing ∈ [可接受下界, 模型]，且 failing=0 / unmatched=0 / unread 可解释。
落在带外（高于模型上界，或低于下界）一律按 fail 上报，不在事后调带。

---

## 对账（★预测那张表以上原样保留，不改；这里只填实测★）

- 证明 commit：`435655c3b73ed4f62c6446417ffb8357928cd683`
- 复算：`python3 reconcile.py 435655c3`（实测那一列从
  `evidence/435655c3*/<top>/receipt.json` 的 `verdict_detail` 机械读，非手抄；非零退出=对不上）

| 变体 | 模型(上界) | 下界 | 实测 passing | 差 | failing | unmatched | unread | verdict | vmucp |
|---|---|---|---|---|---|---|---|---|---|
| `OthersEntry_44` | 3639 | 3275 | **3639** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_50` | 1426 | 1226 | **1426** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_66` | 3617 | 3255 | **3617** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_72` | 1394 | 1194 | **1394** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry` | 3619 | 3257 | **3619** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_6` | 1394 | 1194 | **1394** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_88` | 3528 | 3175 | **3528** | +0 | 0 | 0 | 0 | SUCCEEDED | true |
| `OthersEntry_90` | 1301 | 1101 | **1301** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_104` | 3520 | 3168 | **3520** | +0 | 0 | 0 | 0 | SUCCEEDED | true |
| `OthersEntry_106` | 1293 | 1093 | **1293** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_120` | 3516 | 3164 | **3516** | +0 | 0 | 0 | 0 | SUCCEEDED | true |
| `OthersEntry_122` | 1289 | 1089 | **1289** | +0 | 0 | 0 | 0 | SUCCEEDED | false |

**结果：12/12 SUCCEEDED，实测 passing 逐个正好等于模型上界（差全为 +0）。**

也就是说 predict.py 的模型「golden 寄存器位 + 顶层 output 端口位」在单条目这一档上
是**精确**的，不是上界估计 —— 12 个变体、两种角色、三个 FP/INT 子族全部逐位命中。
（Entries 阵列那一档实测差 -12 / -128，是因为阵列层有 Constant 寄存器；
  单条目这一档 constant_reg 为 null，一个都没有。）

### 带宽反标定

预登记时把可接受下界写成 `min(round(0.90*model), model-200)`，并声明「跑完用实测反标定」。
实测 12/12 差值为 0 ⇒ 这一族的正确判据其实是 **passing == model**（等号，不是区间）。
★但不在这里就把带收成等号★：12 个样本全来自 INT/FP 两个子族，
剩下 12 个（6 个 MEM + 6 个向量）还没跑，MEM 族有 needFeedBack、向量族有 ignoreOldVd，
都可能引入 Constant 寄存器。等 24 个齐了再收，收窄本身也要有样本依据。

---

## 向量族 6 个的预登记与对账（第二批）

`_164/_166` 的判据与结论见 `VEC_PROBE_PREREG.md`（跑前写死，实测全中）：
`OthersEntry_164` 3792 == 模型、`OthersEntry_166` 1713 == 模型，核 sha256 全程未变。

其余 4 个（`_150/_152` VfmaVialuFixVfalu、`_136/_138` …Vsetrvfwvf）★跑前登记如下★：
这 4 个与 `_164/_166` 的差别是 `numDeq=2`（多 deqPortIdxRead 回读口）与 `nFuTypeBit` 更大，
按 VEC_PROBE_PREREG.md 的作用域声明，它们不能靠 `_164/_166` 外推，必须各自跑过。

| 变体 | 角色 | regs | outs | **模型 passing** | 可接受下界 | 实测 | 对账 |
|---|---|---|---|---|---|---|---|
| `OthersEntry_150` | simp | 1459 | 2338 | **3797** | 3417 | _待填_ | _待填_ |
| `OthersEntry_152` | comp | 841 | 878 | **1719** | 1519 | _待填_ | _待填_ |
| `OthersEntry_136` | simp | 1479 | 2380 | **3859** | 3473 | _待填_ | _待填_ |
| `OthersEntry_138` | comp | 863 | 900 | **1763** | 1563 | _待填_ | _待填_ |

判据与前 12 个一致：`passing ∈ [下界, 模型]` 且 `failing=0 / unmatched=0`，
且 **核 `xs_iq_entries_core.sv` 的 sha256 必须仍是**
`e4e4491009971cfaade049d58f977c68b7dba9f0d840f379649b3d25d934ba41` —— 改了核就不算"核够用"。
若出现 matched_nc unread，按 standing rule 六条处理且增量必须**恰好**等于加强前的 unread 数。

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

---

## ★最终对账：18 个目标、同一个 commit★

- 证明 commit：`9c2517d9e886cd6b84be2e2b7cbb04c5f2876760`（18 份 receipt 全在这一个 commit 上）
- 复算：`python3 reconcile.py 9c2517d9` → rc=0

★为什么要在一个 commit 上重跑一遍★：VEC 那 6 个是分三批出的证
（`_164/_166` @2e593a57、`_152/_138` @35b364d5、`_150/_136` @36000097）。
中间我往 `scripts/fm_eq.tcl` 的 vmucp 白名单加过名字，而那个文件**在所有目标的证明脚本闭包里** ——
也就是说 `_152/_138` 的旧 receipt 是用另一份 fm_eq.tcl 产出的。
数字不会因此变，但"18 份证据用的是同一套脚本"这件事得是**跑出来的**，不是推出来的。

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
| `OthersEntry_164` | 3792 | 3413 | **3792** | +0 | 0 | 0 | 0 | SUCCEEDED | true |
| `OthersEntry_166` | 1713 | 1513 | **1713** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_150` | 3797 | 3417 | **3797** | +0 | 0 | 0 | 0 | SUCCEEDED | true |
| `OthersEntry_152` | 1719 | 1519 | **1719** | +0 | 0 | 0 | 0 | SUCCEEDED | false |
| `OthersEntry_136` | 3859 | 3473 | **3859** | +0 | 0 | 0 | 0 | SUCCEEDED | true |
| `OthersEntry_138` | 1763 | 1563 | **1763** | +0 | 0 | 0 | 0 | SUCCEEDED | false |

**18/18 SUCCEEDED，实测 passing 逐个正好等于模型上界（差全为 +0），failing / unmatched / unread 全 0。**

至此 24 个变体里 **18 个签核完毕**；剩 6 个 MEM 族（`_172/_174/_200/_202/_242/_244`）等 `entries-rest3` 的 E4。

---

## 第三轮跑前登记：E1/E2 参数 API 重生成后的**复证**（★跑前写死，跑后不改★）

- 登记时间点：本节所在 commit 即登记 commit；FM **尚未起跑**。
- 输入 commit：`c4084e32875698812a16172d60c74dcae74fbf29`（18 个 wrapper 重生成）
- 上游基线：`abc026650ddafea5450db45f19d15730202ada54`（main，合入 agent/entfam 之后）

### 为什么要重跑一遍已经 18/18 绿过的东西

上面那张「最终对账」表是 commit `9c2517d9e886cd6b84be2e2b7cbb04c5f2876760` 上跑的。
那之后共享核 `xs_iq_entries_core.sv` 变了两次：
`29dd150a`（E1+E2：唤醒匹配换成 kind × wen 存在性）与 `609baba5`（perfWakeupByWB 门控）。
而 `othersentry_gen.py` 与 18 个 wrapper 一个都没跟着重生成 —— 于是整族从 `29dd150a`
起**连 elaborate 都过不去**（`FMR_VLOG-273 Parameter 'IQ_TYPE_BIT' not defined`）。
所以这不是 replay，是**换了核之后的重新证明**：

| 项 | 上一轮登记值 | 本轮实际值 |
|---|---|---|
| `xs_iq_entries_core.sv` sha256 | `e4e4491009971cfaade049d58f977c68b7dba9f0d840f379649b3d25d934ba41` | `55f185f5602052b6a80bb52268d4fa24bbd842828e2d1e933ece6e73bc3d4062` |
| `othersentry_gen.py` sha256 | `6bf97782d0ed5f86ef2b36acdcc6353e738a71016bf7e9dc76d361911f011d53` | `e0a7d98b2cd1a5f1b7d163889585c9c200436c7a0ffa7ae6fccc22cbce553c57` |
| `predict.py` sha256 | `c6e681648d7f29a8720af7a9a62d14af0822f1931cbab9f7f2d3a05ee19334dd` | `b89c48464b3d063e9ed67dfb4f871545182eb29d30cea8a4c558e8a138e5e030` |

核的 sha256 已经变了，所以「核 sha 未变」那条旧判据本轮**不成立、也不再引用**。

### 预测（写死）

**预测 1（主判据）：18/18 `passing` 逐个仍然正好等于 `predict.py` 的模型值，差全为 +0。**

依据，不是"应该没事"：
1. E1/E2 换的是**表达同一张对表的方式**。生成器新加的对表安全带已在本轮重生成时
   对 18 个模块逐源逐总线核过：模型（kind × 该总线存在哪些 wen）展开出的
   `(srcType 位, wen 字段)` 对表，与 golden 里实测的那张**逐条相同**，18/18 零处不符。
   对表不变 ⇒ 锥形不变 ⇒ 比较点数不变。
2. 重生成的 before/after 集合读数：`fm_pins_pre.tcl` 18/18 **逐字节相同**
   （钉点对集合丢 0 / 增 0），wrapper 里 `io_*` 端口引用集合丢 0 / 增 0。
   钉点不变 ⇒ 双射配对不变 ⇒ vmucp 的 +9 增量应当照旧。
3. 模型值本身只由 golden 算（寄存器位 + 顶层 output 位），与 impl 侧改动无关，
   所以模型值与上一轮**必然**一致；本轮登记值确实逐个等于上表。

**预测 2：`failing = 0`、`unmatched = 0`、`blackbox = 0`。**

**预测 3（vmucp 6 个目标）：`unread = 0`，且加强带来的增量仍是 +9。**
`verif/fm_target_config/` 下已有 6 份 per-target 白名单
（`OthersEntry_88/_104/_120/_136/_150/_164`，全是 simp 条目），本轮**一字未改**、
不新增、不放宽。其余 12 个目标 vmucp=false，预测 `unread = 0`。

**预测 4（★可证伪的否定预测★）：本族没有 EnqEntry 族 `6ad7839a` 那个
`HAS_LD_DEP` 语义错。** 18/18 的 `HAS_LD_DEP` 实参与已签核父级
`Entries*` 传给同角色条目的实参求值一致（simp 取 `v.has_ld_dep`；
comp 取 `v.has_ld_dep && v.comp_has_ld_dep`），这条已在 `othersentry_gen.py`
里做成断言，重生成时 18/18 通过。若这条错了，FM 会像 EnqEntry 那样在钉点阶段
报 `FM-036 Unknown name … r_ld_dep_reg`，或给出一组恒 0 的 failing。

### 登记表（逐目标，模型值由 `scripts/fm_predict.py model` 机械算出）

| 变体 | 角色 | regs | outs | **预测 passing** | vmucp | 预测 failing/unmatched/unread |
|---|---|---|---|---|---|---|
| `OthersEntry` | simp | 1447 | 2172 | **3619** | false | 0 / 0 / 0 |
| `OthersEntry_6` | comp | 670 | 724 | **1394** | false | 0 / 0 / 0 |
| `OthersEntry_44` | simp | 1449 | 2190 | **3639** | false | 0 / 0 / 0 |
| `OthersEntry_50` | comp | 686 | 740 | **1426** | false | 0 / 0 / 0 |
| `OthersEntry_66` | simp | 1446 | 2171 | **3617** | false | 0 / 0 / 0 |
| `OthersEntry_72` | comp | 670 | 724 | **1394** | false | 0 / 0 / 0 |
| `OthersEntry_88` | simp | 1426 | 2102 | **3528** | true | 0 / 0 / 0 |
| `OthersEntry_90` | comp | 626 | 675 | **1301** | false | 0 / 0 / 0 |
| `OthersEntry_104` | simp | 1424 | 2096 | **3520** | true | 0 / 0 / 0 |
| `OthersEntry_106` | comp | 622 | 671 | **1293** | false | 0 / 0 / 0 |
| `OthersEntry_120` | simp | 1423 | 2093 | **3516** | true | 0 / 0 / 0 |
| `OthersEntry_122` | comp | 620 | 669 | **1289** | false | 0 / 0 / 0 |
| `OthersEntry_136` | simp | 1479 | 2380 | **3859** | true | 0 / 0 / 0 |
| `OthersEntry_138` | comp | 863 | 900 | **1763** | false | 0 / 0 / 0 |
| `OthersEntry_150` | simp | 1459 | 2338 | **3797** | true | 0 / 0 / 0 |
| `OthersEntry_152` | comp | 841 | 878 | **1719** | false | 0 / 0 / 0 |
| `OthersEntry_164` | simp | 1458 | 2334 | **3792** | true | 0 / 0 / 0 |
| `OthersEntry_166` | comp | 838 | 875 | **1713** | false | 0 / 0 / 0 |

★判据是**等号**，不是区间★：上一轮 18/18 差全为 +0 已经把带标定死了，
这一轮不再给自己留 10% 的余地。差额 != 0 一律按 fail 上报，
并要求逐位指认（可指认量 = receipt 里的 `constant_reg` + `unread`，两者都机械读，不许手填）。
**不在事后改本表。**

登记同时进 `docs/fm_predictions/OthersEntry*.json`（18 份，
`scripts/fm_predict.py check` 会要求登记 commit 是 receipt 里 `impl_commit` 的祖先，
所以跑完再改登记不起作用）。

### UT 的跑前登记

18 个目标 × 3 seed（1 / 7 / 42）× 200k cycle × **两档初值**
（`+vcs+initreg+random` 与 `make run-initreg0`）全部 `errors=0`。
★两档都要跑★ —— `agent/entfam` 那条 lane 自曝只跑了 random 一档，那是欠账。

### 第三轮对账（★预测那张表以上原样保留，一字未改★）

- 证明 commit：`563e6f964222aa0f871e531ff0ded97a855c5b76`（= 登记 commit 本身，18 份 receipt 全在这一个上）
- 复算一：`python3 scripts/fm_predict.py check <18 个 target>` → 18 行「逐位相等」
- 复算二：`python3 verif/ut/OthersEntry_common/reconcile.py 563e6f96` → 「对不上的: 0 个」，rc=0
- 数字全部从 `evidence/563e6f964222/<top>/receipt.json` 的 `native_facts` 机械读，非手抄。

| 变体 | 预测 passing | 实测 passing | 差 | failing | unverified | aborted | unread_nc | unmatched 六项 | bbox | vmucp | verdict | receipt sha256 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `OthersEntry` | 3619 | **3619** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `aa003796311bce6ec35533a9bf45f87789e132b9a8efd2810a1213460341abbf` |
| `OthersEntry_6` | 1394 | **1394** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `540570140aead6aad65c5ef54cf976204d2386ff275730099e5f156539b2d9b1` |
| `OthersEntry_44` | 3639 | **3639** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `7016724ae12d325318c26de50f1384d2af73c10403fcc3686b2605fc9cb1c4f5` |
| `OthersEntry_50` | 1426 | **1426** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `8731209682601fce093a58f05b905d12c4e41e74b80851d4ac78c313adc4f165` |
| `OthersEntry_66` | 3617 | **3617** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `6bab6be0d2db46c409bcc0cb15565884858fde56d65a16c8ba76d70357a86ffc` |
| `OthersEntry_72` | 1394 | **1394** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `04c8c6c8d97110b349dc6ca46defda9739575e9496ef2cd2e62e9be69cc32e03` |
| `OthersEntry_88` | 3528 | **3528** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | true | SUCCEEDED | `fa570ade3e0316cca146d90793dca033a08f342684b789081b6d10fff3d28a3d` |
| `OthersEntry_90` | 1301 | **1301** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `2dcdc1a92bfd8ce5da0d5db1025a8d6b9fb878a811ab47647baea3786cce6a9d` |
| `OthersEntry_104` | 3520 | **3520** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | true | SUCCEEDED | `b0f7d966d47cd3432acf41d56fa75512c9fd7d1b3e4ad647918bbc19f8f258d5` |
| `OthersEntry_106` | 1293 | **1293** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `ef9f3092d5542a9053420ca165d1c3a16f2f240267c8c8210a644881eca610cd` |
| `OthersEntry_120` | 3516 | **3516** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | true | SUCCEEDED | `88ecf33839af9723ef171e96fd265707898d327b175d6843bd9cce547b4f4b0e` |
| `OthersEntry_122` | 1289 | **1289** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `a215f35289d30ddb42f351e6430356221a3c6a1d696c653222a51a1b8c3226f5` |
| `OthersEntry_136` | 3859 | **3859** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | true | SUCCEEDED | `43d160dbc7e20bd106b2809fbc1f3b690fea2cbe945737fb738075c093e16caa` |
| `OthersEntry_138` | 1763 | **1763** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `b301ab09d74a0820ba238a3bff3985ac2dba2525f005841ba26759b6352b4aa4` |
| `OthersEntry_150` | 3797 | **3797** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | true | SUCCEEDED | `a5abd361976cd507ee60b4d26580ab41eefbad443fb3865b1b27afdb6c95501e` |
| `OthersEntry_152` | 1719 | **1719** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `5a16c78941583e9944f56748577a8c844ad4e9e41785bb68dc401baddc8e0242` |
| `OthersEntry_164` | 3792 | **3792** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | true | SUCCEEDED | `bad7aec50cf96d37279cef1cd2e24283ee17ae006bd94c23543d57708bd63999` |
| `OthersEntry_166` | 1713 | **1713** | +0 | 0 | 0 | 0 | 0 | 全 0（合计 0） | 0 | false | SUCCEEDED | `8931bf1a2cd51fe0262f91e30efaa24f4c910227ed0137f36947ac0971b5d435` |

**18/18 SUCCEEDED；passing 逐个正好等于登记的模型值，差全为 +0；
failing / unverified / aborted / unread_notcompared 与 unmatched 六项全 0。**

四条跑前预测逐条兑现（1 数字、2 质量维、3 vmucp 白名单不动、
4 ★否定预测：本族没有 EnqEntry `6ad7839a` 那个 `HAS_LD_DEP` 语义错★）。
第 4 条的可证伪性在于：若语义发错，FP/VEC 族 simp 的钉点脚本会在
`u_entry/r_ld_dep_reg[s][q][b]` 上当场 `FM-036 Unknown name`（EnqEntry 就是这么暴露的）；
实测 `_88/_104/_120/_136/_150/_164` 六个 simp 全部钉点成功并跑到比对阶段。

### 这一轮相对上一轮变了什么、没变什么

| | 9c2517d9（上一轮） | 563e6f96（本轮） |
|---|---|---|
| `xs_iq_entries_core.sv` | `e4e44910…` | `55f185f5…`（29dd150a + 609baba5 之后）|
| 18 个 wrapper | 旧参数 API（`IQ_TYPE_BIT`/`SRC_TYPE_BIT`）| 新 API（`*_WEN_PRESENT`/`SRC_MATCH_KIND`）|
| `fm_pins_pre.tcl` | — | **逐字节未变**（18/18）|
| `verif/fm_target_config/OthersEntry*.tcl` | — | **未变**（6 份，一字未改）|
| 18 个 passing | 3619/1394/3639/1426/… | **逐个相同** |

也就是说：换了核、换了参数 API，比较点数一个没变 —— 
这正是 E1/E2「换的是表达同一张对表的方式」那句话的可检验形式。

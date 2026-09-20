# E1/E2 回归：9 个已签核变体 passing 逐个不变 + 作用域复测

## 一、回归（公共路径改动的主证据）

`verdicts.tsv`。E1/E2 改的是共享核的公共路径，按"公共路径改动，回归证据比新增证据
重要"，9 个已签核变体全部重跑 `scripts/run_proof.sh`：

| 变体 | E1 前 passing | E1 后 passing | verdict |
|---|---|---|---|
| EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | 25300 | **25300** | SIGNOFF_PASS |
| EntriesAluMulBkuBrhJmp | 25010 | **25010** | SIGNOFF_PASS |
| EntriesFaluFcvtF2vFmacFdiv | 16619 | **16619** | SIGNOFF_PASS |
| EntriesFaluFmac | 15934 | **15934** | SIGNOFF_PASS |
| EntriesFaluFmacFdiv | 16549 | **16549** | SIGNOFF_PASS |
| EntriesVfmaVialuFixVfalu | 18369 | **18369** | SIGNOFF_PASS |
| EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | 18755 | **18755** | SIGNOFF_PASS |
| EntriesAluCsrFenceDiv | 25001 | **25001** | SIGNOFF_PASS |
| EntriesVfdivVidiv | 12136 | **12136** | SIGNOFF_PASS |

九个都是 failing 0 / unread 0 / unmatched 0 / bbox 0 / dont_verify false。
★"改动面大"这件事因此是**被实测排除**的，不是靠"我们没碰它"来保证的。★

## 二、作用域复测（继承来的数字必须自己重测）

`lane_wen_measure.py` / `.txt`。集成者转来 agent/othersentry 的 lane 分组，
本 lane **没有引用那些数字**，直接从 G1 golden 重量一遍。

### 复测确认的部分

`EntriesVfdivVidiv` / `VfmaVialuFixVfalu` / `VfmaVialuFix…Vsetrvfwvf` 三个：
**lane 0-5→vecWen、6-11→v0Wen、12-15→vlWen，每 lane 只带一个 wen**，
而且三组 lane 与三个源一一对应、互不重叠。
⇒ ★这三个变体上老机制确实够用，集成者的判断成立。★

### ★复测推翻的部分：作用域不能按"族"切★

`EntriesVlduVstu` / `EntriesVlduVstuVseglduVsegstu`（V12/V13）也是 VEC 族
（`numRegSrc==5`，src3/src4 要 V0/VL 分工），但实测：

    lane 分组: 0-15 → fpWen+rfWen+v0Wen+vecWen+vlWen   ← ★每条 lane 五个 wen 全带★
    src0: lanes 0-15 (16 条)  对表 ['0:rf','1:fp','2:vec']
    src1: lanes 0-15 (16 条)  对表 ['0:rf','1:fp','2:vec']
    src2: lanes 0-15 (16 条)  对表 ['0:rf','1:fp','2:vec']
    src3: lanes 0-15 (16 条)  对表 ['3:v0']
    src4: lanes 0-15 (16 条)  对表 ['2:vl']

★五个源全都监听全部 16 条 lane，lane 掩码把它们分不开★ ——
区分 src0..2 / src3 / src4 的**只剩每源的匹配 kind**。

于是 V12/V13 同时需要两样东西：
  * 多对（src0..2 的 fp|rf|vec 三对）—— 这是"MEM 族才要"的那一半
  * 按源分 kind（src3=V0 判 isV0(bit3)、src4=VL 判 isVp(bit2)）—— 这是"VEC 族"的那一半

**所以按「MEM 族 / VEC 族」切作用域会漏掉 V12/V13。** 真正的判别轴不是族，是
★一条 lane 上带几个 wen × lane 掩码能不能把各源分开★，这条轴横穿族边界。

一个只按 Ldu/StaMou/StdMoud（`numRegSrc==1`、全 GP）设计的 E1 里根本不会有
V0/VL 这两种 kind，V12/V13 就做不了。

### 顺带一条反直觉的

`EntriesAluCsrFenceDiv` / `EntriesFaluFmac` 这类单 wen 变体，lane 掩码同样
"分不开"（各源都听同样几条 lane）—— 但它们**所有源用同一种 kind**，所以不分也没关系。
脚本那行提示只说明"lane 掩码没有分离作用"，不等于"必须按源分表"；
两者一起看才是判据：**lane 掩码分不开 且 各源 kind 不同 ⇒ 必须按源分表**。

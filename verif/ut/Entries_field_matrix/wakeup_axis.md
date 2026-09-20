# 唤醒匹配机制的判别轴（E1 作用域的依据）

由 `verif/ut/Entries_field_matrix/wakeup_axis.py` 从 G1 golden 机械生成。
改共享核的唤醒匹配之前必须复跑并核对（`--check`）。

★判别轴不是"族"，是两条：**每 lane 带几个 wen** × **lane 掩码能不能把各源分开**★
—— 它横穿族边界：`EntriesVlduVstu` 是 VEC 族却落在 D 档。

| 变体 | nSrc | 每 lane 的 wen 数 | lane 分组 | 各源 lane 掩码 | 各源 kind | 掩码分得开 | 档 | 老机制够不够 |
|---|---|---|---|---|---|---|---|---|
| `EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v` | 2 | 1 | 0-3→rf | 0-3 / 0-3 | 0:rf / 0:rf | 是 | **B** | 够（全部源同一种 kind，没什么要隔开的） |
| `EntriesAluCsrFenceDiv` | 2 | 1 | 0-3→rf | 0-3 / 0-3 | 0:rf / 0:rf | 是 | **B** | 够（全部源同一种 kind，没什么要隔开的） |
| `EntriesAluMulBkuBrhJmp` | 2 | 1 | 0-3→rf | 0-3 / 0-3 | 0:rf / 0:rf | 是 | **B** | 够（全部源同一种 kind，没什么要隔开的） |
| `EntriesFaluFcvtF2vFmacFdiv` | 3 | 1 | 0-5→fp | 0-5 / 0-5 / 0-5 | 1:fp / 1:fp / 1:fp | 是 | **B** | 够（全部源同一种 kind，没什么要隔开的） |
| `EntriesFaluFmac` | 3 | 1 | 0-5→fp | 0-5 / 0-5 / 0-5 | 1:fp / 1:fp / 1:fp | 是 | **B** | 够（全部源同一种 kind，没什么要隔开的） |
| `EntriesFaluFmacFdiv` | 3 | 1 | 0-5→fp | 0-5 / 0-5 / 0-5 | 1:fp / 1:fp / 1:fp | 是 | **B** | 够（全部源同一种 kind，没什么要隔开的） |
| `EntriesLdu` | 1 | 3 | 0-3→fp+rf+vec | 0-3 | 0:rf+1:fp+2:vec | 是 | **C** | 不够：要多对（全部源同一种 kind） |
| `EntriesStaMou` | 1 | 3 | 0-3→fp+rf+vec | 0-3 | 0:rf+1:fp+2:vec | 是 | **C** | 不够：要多对（全部源同一种 kind） |
| `EntriesStdMoud` | 1 | 3 | 0-9→fp+rf+vec | 0-9 | 0:rf+1:fp+2:vec | 是 | **C** | 不够：要多对（全部源同一种 kind） |
| `EntriesVfdivVidiv` | 5 | 1 | 0-5→vec; 6-11→v0; 12-15→vl | 0-5 / 0-5 / 0-5 / 6-11 / 12-15 | 2:vec / 2:vec / 2:vec / 3:v0 / 2:vl | 是 | **A** | 够（各源 kind 不同，但掩码把它们隔开了） |
| `EntriesVfmaVialuFixVfalu` | 5 | 1 | 0-5→vec; 6-11→v0; 12-15→vl | 0-5 / 0-5 / 0-5 / 6-11 / 12-15 | 2:vec / 2:vec / 2:vec / 3:v0 / 2:vl | 是 | **A** | 够（各源 kind 不同，但掩码把它们隔开了） |
| `EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf` | 5 | 1 | 0-5→vec; 6-11→v0; 12-15→vl | 0-5 / 0-5 / 0-5 / 6-11 / 12-15 | 2:vec / 2:vec / 2:vec / 3:v0 / 2:vl | 是 | **A** | 够（各源 kind 不同，但掩码把它们隔开了） |
| `EntriesVlduVstu` | 5 | 5 | 0-15→fp+rf+v0+vec+vl | 0-15 / 0-15 / 0-15 / 0-15 / 0-15 | 0:rf+1:fp+2:vec / 0:rf+1:fp+2:vec / 0:rf+1:fp+2:vec / 3:v0 / 2:vl | ★否★ | **D** | ★不够：要多对**且**按源分 kind★ |
| `EntriesVlduVstuVseglduVsegstu` | 5 | 5 | 0-15→fp+rf+v0+vec+vl | 0-15 / 0-15 / 0-15 / 0-15 / 0-15 | 0:rf+1:fp+2:vec / 0:rf+1:fp+2:vec / 0:rf+1:fp+2:vec / 3:v0 / 2:vl | ★否★ | **D** | ★不够：要多对**且**按源分 kind★ |

## 五档的含义

判据两条：**每 lane 带几个 wen**（决定要不要"多对"）×
**kind 不同的那些源，掩码有没有把它们隔开**（决定要不要"按源分 kind"）。

| 档 | 每 lane wen | 各源 kind | 掩码隔开了吗 | 老机制够不够 |
|---|---|---|---|---|
| B | 1 | 全同 | （无关） | ★够★ |
| A | 1 | 不同 | 隔开了 | ★够★ |
| A\* | 1 | 不同 | **没隔开** | 不够：要按源分 kind |
| C | 多 | 全同 | （无关） | 不够：要多对 |
| D | 多 | 不同 | 没隔开 | ★不够：要多对**且**按源分 kind★ |

★"掩码分得开"必须只问 kind 不同的那些源对★ —— 这一点我第一版写错过：
向量族的 src0/1/2 共用同一张掩码(0-5)，但三者 kind 相同，重叠完全无害；
按"任意两源都不许重叠"去判，会把 A 档误判成需要改造。
同 kind 的源共用掩码既正常又普遍，**掩码要隔开的是 kind，不是源**。

## 各档都有谁

- **A**（够（各源 kind 不同，但掩码把它们隔开了））：`EntriesVfdivVidiv`、`EntriesVfmaVialuFixVfalu`、`EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf`
- **B**（够（全部源同一种 kind，没什么要隔开的））：`EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v`、`EntriesAluCsrFenceDiv`、`EntriesAluMulBkuBrhJmp`、`EntriesFaluFcvtF2vFmacFdiv`、`EntriesFaluFmac`、`EntriesFaluFmacFdiv`
- **C**（不够：要多对（全部源同一种 kind））：`EntriesLdu`、`EntriesStaMou`、`EntriesStdMoud`
- **D**（★不够：要多对**且**按源分 kind★）：`EntriesVlduVstu`、`EntriesVlduVstuVseglduVsegstu`

## 历史（为什么这张表要存在）

E1 的作用域最初被按**族**切成「MEM 族要、VEC 族不用」。
按族切会漏掉 D 档的 `EntriesVlduVstu` / `EntriesVlduVstuVseglduVsegstu` ——
它们是 VEC 族（`numRegSrc==5`），却每条 lane 带 5 个 wen、五个源全听全部 16 条 lane，
只按 `Ldu`/`StaMou`/`StdMoud`（`numRegSrc==1`、全 GP）设计的 E1 里没有 V0/VL 两种 kind，
这两个变体做不了。

A 档那三个向量变体（`VfdivVidiv` / `VfmaVialuFixVfalu` / `VfmaVialuFix…Vsetrvfwvf`）
**确实**老机制够用 —— 但依据是「掩码能分开」，**不是**「因为它是 VEC 族」。
这个区别正是本表存在的理由：★结论会传下去，限定条件不会。★


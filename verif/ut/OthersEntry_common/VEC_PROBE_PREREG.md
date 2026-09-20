# 向量族要不要等 E1 —— ★跑前判据，写死不改★

裁定（coordinator，2026-09-20）：拿 `OthersEntry_164/_166` 证伪或证实
「VEC 族不需要等 `agent/entries-rest3` 的 E1」，**跑前把判据写死**，
**无论结论如何都上报**，因为它直接决定 E1 要不要覆盖 VEC 族。

本文件在**生成任何 RTL、跑任何 FM 之前**写入并提交。

## 待证的命题

`agent/entries-rest3` 的 E1 是「WB 唤醒匹配从单对 (srcTypeBit, wen) 改成一串对按位或」。
我的矩阵实测给出的反命题是：

> VEC 族每条 WB **lane** 仍然只带**一个** wen
> （lane 0–5 `vecWen` / 6–11 `v0Wen` / 12–15 `vlWen`），
> 也就是 firtool 已经把 `EntryBundles.scala:185-193` 的「按源分工」
> 摊成了**互不相交的 lane 集合**；现有核的 `SRC_WB_MASK[s]`（每源一张 lane 掩码）
> 加上每 lane 一个 `wk_wen`，本来就表达得了这件事。
> ⇒ VEC 族不需要 E1，真正需要 E1 的是 MEM 族（单条 lane 带 fpWen/rfWen/vecWen 三个）。

`_164`(simp) / `_166`(comp) 的父级 `EntriesVfdivVidiv` 已签核，是干净对照。
两者实测 `wk_wen` 集合 = {vecWen, v0Wen, vlWen}，`n_wk=16`，`n_wk_iq=0`，
`has_ignore=1`（向量 ignoreOldVd 通路真的活）。

## ★判据（三档，跑前定死）★

判定看**两个**东西，缺一不可：

| | 条件 |
|---|---|
| (a) 核**没被改** | FM 通过时 `rtl/backend/xs_iq_entries_core.sv` 的 sha256 必须等于 `e4e4491009971cfaade049d58f977c68b7dba9f0d840f379649b3d25d934ba41`（= commit `c504c777` 上的值） |
| (b) 数字对上 | `passing == 模型`、`failing == 0`、`unmatched == 0`，且 `unread == 0`（若需 vmucp 才能归零，其增量必须**恰好**等于加强前的 unread 数） |

模型（`python3 predict.py OthersEntry_164 OthersEntry_166`，跑前算）：

| 变体 | 角色 | regs | outs | **模型 passing** | 可接受下界 |
|---|---|---|---|---|---|
| `OthersEntry_164` | simp | 1458 | 2334 | **3792** | 3413 |
| `OthersEntry_166` | comp | 838 | 875 | **1713** | 1513 |

三档结论：

1. **证实「核够用」** ⟺ (a) 且 (b)。
   ⇒ 报 coordinator：E1 可以只针对 MEM 族，不必覆盖 VEC 族。
2. **证伪「核够用」** ⟺ 为了让 (b) 成立而**改了核**（(a) 不成立）。
   ⇒ 报 coordinator：VEC 族确实要等 E1（或要另一处核改动），并说清改的是哪一处。
3. **不确定** ⟺ (b) 不成立且我也没改核（例如 FM 失配在与唤醒无关的地方）。
   ⇒ 照实报，不往 1 或 2 里靠。

## ★预先声明的边界，防止事后解释★

- **改生成器 / 薄 wrapper ≠ 改核**。`othersentry_gen.py` 与
  `rtl/backend/OthersEntry_164.sv` 本来就是这一族每个变体都要新写的东西，
  改它们仍算第 1 档。判据 (a) 只钉 `xs_iq_entries_core.sv` 的 sha256。
- **钉点文件（`fm_pins_pre.tcl`）算配套，不算改核**：它只消名差。
- **vmucp 算加强不算放宽**，但若用了，必须满足 standing rule 六条且增量恰好等于
  加强前的 unread 数；否则记第 3 档。
- 这两个变体如果**一次过**，不能因此说「其余 4 个向量变体也一定行」——
  `_150/_152`（VfmaVialuFixVfalu）与 `_136/_138`（…Vsetrvfwvf）的
  `numDeq=2`、`nFuTypeBit` 更大，要各自跑过才算。本次结论的作用域是
  **`_164/_166` 这两个**，外推要另有证据。

## 复算

```
cd verif/ut/OthersEntry_common
python3 predict.py OthersEntry_164 OthersEntry_166      # 模型
sha256sum ../../../rtl/backend/xs_iq_entries_core.sv    # 判据 (a) 的锚
```

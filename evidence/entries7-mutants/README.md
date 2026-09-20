# 已合入的 7 个变体：变异体矩阵（收尾记录）

这 7 个变体已在 `d5e0f1e7` 合入 main，本目录只是把变异体这一项跑完记一笔。

| 变体 | 抓住/适用 | N/A（本变体上是死的） | 结构型（闸在 FM） | 无效变异体 | infra |
|---|---|---|---|---|---|
| EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | **12/12** | 2 | 1 | 0 | 0 |
| EntriesAluMulBkuBrhJmp | **12/12** | 2 | 1 | 0 | 0 |
| EntriesFaluFcvtF2vFmacFdiv | **5/5** | 10 | 0 | 0 | 0 |
| EntriesFaluFmacFdiv | **5/5** | 10 | 0 | 0 | 0 |
| EntriesFaluFmac | **4/4** | 10 | 1 | 0 | 0 |
| EntriesVfmaVialuFixVfalu | **2/2** | 13 | 0 | 0 | 0 |
| EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | **2/2** | 13 | 0 | 0 | 0 |

**合计 42/42 抓住，0 逃逸，0 无效变异体，0 基础设施失败。**

## 两处值得记的

1. **适用条数与变体丰度正相关，符合预期**：Alu* 有 IQ 唤醒 7 路 + 活的
   loadDependency + regCache + 双发射口，12 条适用；Vfma* 没有 IQ 唤醒与取消网络，
   只有 2 条适用、13 条按变体字段判定为死。★"N/A 多"不是覆盖差，是这些变异在
   那个变体上根本不改电路★ —— 分母里剔除它们才是对的。

2. ★M1 曾在三个 Falu* 上报"逃逸"，查实是**空变异**★（FM 证明变异后
   passing/failing/unread 与未变异逐个相同 ⇒ 电路没变），根因是 M1 的适用性判据
   写松了（只要求 `n_wk_iq > 0`，漏了 `iq_has_ld_dep`）。判据已修，三个变体重跑后
   M1 正确落进 N/A。证据在 `evidence/m1-empty-mutant-proof/`。
   本目录的 Falu* 三份日志是**修判据之后**重跑的。

复跑：`python3 verif/ut/Entries_common/mutants.py <变体>`

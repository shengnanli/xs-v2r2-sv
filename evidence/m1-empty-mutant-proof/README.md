# M1 在 Falu* 上是**空变异**的证明（不是 UT 逃逸）

2026-09-20。`mutants.py` 跑 `EntriesFaluFmac` / `EntriesFaluFmacFdiv` /
`EntriesFaluFcvtF2vFmacFdiv` 时，M1 一律报 `★逃逸★ errors=0`。

★按本仓规矩「变异体必须先自证改变了电路」，"逃逸"在自证之前不能当结论。★
两种逃逸的处置完全相反：

  (a) 变异真改了电路、UT 没看见  ⇒ UT 没判别力，补激励/比对
  (b) 变异根本没改电路（空变异）⇒ applicability 判据写松了，**改判据**

## 判别：把 M1 注进核，跑一次 FM

    passing  failing  unread  unmatched  bbox  native      dont_verify
    未变异   15934    0       0          0     0  SUCCEEDED  false
    M1 变异  15934    0       0          0     0  SUCCEEDED  false      ← ★逐个相同★

FM 证的是**可证等价**，不是"这组激励下一样"。两侧比较点、passing 数、failing 数
全部相同 ⇒ ★M1 在本变体上没有改变电路★ ⇒ 属于 (b)。

## 机理（FM 判决之后再看源码，两者一致）

- 薄层 `rtl/backend/EntriesFaluFmac.sv` 把 `.enq_ld_dep('0)` / `.iq_ld_dep('0)` /
  `.iqd_ld_dep('0)` 全部接常数 0（`grep -n "\.\(enq\|iq\|iqd\)_ld_dep(" `）
- golden `EntriesFaluFmac.sv` 里 `io_..._srcLoadDependency` 与 `io_loadDependency`
  端口数 **都是 0**（`grep -c`）
- 于是 M1 改的那一行两个操作数恒为 0：`x |= 0` 与 `x = 0` 在 `x` 本来就是 0 时同值

## 修法

`mutants.py` 的 M1 判据由 `v.n_wk_iq > 0` 收紧为
`v.n_wk_iq > 0 and v.iq_has_ld_dep`。
`iq_has_ld_dep` 是生成器从 golden 量出来的字段（FaluFmac=False / AluCsrFenceDiv=True）。
同源先例：M2 一开始就写的是 `n_wk_iq > 0 and n_ld_cancel > 0`——
★M1 与 M2 改的是同一族信号，判据却一松一紧，这是本轮才发现的不一致。★

## 复跑

    # 1. 造带 M1 的核（把 `|=` 改成 `=`），其余不动
    # 2. cd <mutated>/verif/ut/EntriesFaluFmac && XSSV_HOME=<mutated> make fm-EntriesFaluFmac
    # 3. 与 evidence/9d2783dcbaf4/EntriesFaluFmac/receipt.json 比 passing/failing/unread

本目录存：变异后的核源码、变异跑的 fm.log.gz 与 verdict、两侧 receipt。

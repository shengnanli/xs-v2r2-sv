# OthersEntry 家族（24 变体）字段使用矩阵 —— 从 golden 实测

golden: `/home/eda/xs-env/G1-canonical/golden-rtl`

由 `verif/ut/OthersEntry_field_matrix/gen_matrix.py` 生成；改共享核或任一变体薄文件前必须复跑 `--check`。

## 这一族是什么

`OthersEntry(isComp)` = 发射队列里**非入队**的那些条目（`src/main/scala/xiangshan/backend/issue/OthersEntry.scala`）。golden 按 (IQ 参数, isComp) 单态化成 24 个模块，每个 `Entries*` 变体例化其中两个：

- `EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v`：simp=`OthersEntry_44`×6，comp=`OthersEntry_50`×16
- `EntriesAluCsrFenceDiv`：simp=`OthersEntry_66`×6，comp=`OthersEntry_72`×16
- `EntriesAluMulBkuBrhJmp`：simp=`OthersEntry`×6，comp=`OthersEntry_6`×16
- `EntriesFaluFcvtF2vFmacFdiv`：simp=`OthersEntry_88`×2，comp=`OthersEntry_90`×14
- `EntriesFaluFmac`：simp=`OthersEntry_120`×2，comp=`OthersEntry_122`×14
- `EntriesFaluFmacFdiv`：simp=`OthersEntry_104`×2，comp=`OthersEntry_106`×14
- `EntriesLdu`：simp=`OthersEntry_200`×2，comp=`OthersEntry_202`×12
- `EntriesStaMou`：simp=`OthersEntry_172`×2，comp=`OthersEntry_174`×12
- `EntriesStdMoud`：simp=`OthersEntry_242`×2，comp=`OthersEntry_244`×12
- `EntriesVfdivVidiv`：simp=`OthersEntry_164`×2，comp=`OthersEntry_166`×6
- `EntriesVfmaVialuFixVfalu`：simp=`OthersEntry_150`×2，comp=`OthersEntry_152`×12
- `EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf`：simp=`OthersEntry_136`×2，comp=`OthersEntry_138`×12

## 角色两分（结构结论，非猜测）

把 24 个模块的端口名集合按角色取并集比对：

- **comp 的端口组 ⊆ simp 的端口组，comp-only 为空集**。
- simp 独有的是：`commonIn.transSel`、`commonOut.{enqReady,transEntry.*}`，以及 `commonIn.enq.bits.payload_*` 的**整包宽负载**。
  comp 的 enq 负载只留发射口看得见那一小份。
- 也就是 `xs_iq_entries_core.sv` 里写的 `KEEP_WIDE = IS_ENQ | IS_TRANS`：
  要产出 `transEntry` 的条目才存宽负载。
  simp 行数反而比 comp 大（例：`OthersEntry_66` 2494 行 vs `OthersEntry_72` 1442 行），别拿行数猜角色。

## 矩阵（行 = 维度，列 = 变体，按 parent 分组，simp 在前）

| 维度 | OthersEntry_44 | OthersEntry_50 | OthersEntry_66 | OthersEntry_72 | OthersEntry | OthersEntry_6 | OthersEntry_88 | OthersEntry_90 | OthersEntry_120 | OthersEntry_122 | OthersEntry_104 | OthersEntry_106 | OthersEntry_200 | OthersEntry_202 | OthersEntry_172 | OthersEntry_174 | OthersEntry_242 | OthersEntry_244 | OthersEntry_164 | OthersEntry_166 | OthersEntry_150 | OthersEntry_152 | OthersEntry_136 | OthersEntry_138 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `parent` | EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v | EntriesAluCsrFenceDiv | EntriesAluCsrFenceDiv | EntriesAluMulBkuBrhJmp | EntriesAluMulBkuBrhJmp | EntriesFaluFcvtF2vFmacFdiv | EntriesFaluFcvtF2vFmacFdiv | EntriesFaluFmac | EntriesFaluFmac | EntriesFaluFmacFdiv | EntriesFaluFmacFdiv | EntriesLdu | EntriesLdu | EntriesStaMou | EntriesStaMou | EntriesStdMoud | EntriesStdMoud | EntriesVfdivVidiv | EntriesVfdivVidiv | EntriesVfmaVialuFixVfalu | EntriesVfmaVialuFixVfalu | EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf | EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf |
| `role` | simp | comp | simp | comp | simp | comp | simp | comp | simp | comp | simp | comp | simp | comp | simp | comp | simp | comp | simp | comp | simp | comp | simp | comp |
| `count` | 6 | 16 | 6 | 16 | 6 | 16 | 2 | 14 | 2 | 14 | 2 | 14 | 2 | 12 | 2 | 12 | 2 | 12 | 2 | 6 | 2 | 12 | 2 | 12 |
| `lines` | 2537 | 1511 | 2494 | 1442 | 2501 | 1443 | 2150 | 804 | 2107 | 755 | 2128 | 778 | 2159 | 1135 | 2138 | 1056 | 2175 | 1067 | 2237 | 954 | 2260 | 983 | 2320 | 1039 |
| `n_ports` | 595 | 229 | 578 | 207 | 580 | 207 | 537 | 151 | 524 | 138 | 529 | 143 | 558 | 209 | 549 | 187 | 569 | 201 | 601 | 234 | 607 | 241 | 627 | 257 |
| `nSrc` | 2 | 2 | 2 | 2 | 2 | 2 | 3 | 3 | 3 | 3 | 3 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 5 | 5 | 5 | 5 | 5 | 5 |
| `psrc_w` | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 7 | 7 | 7 | 7 | 7 | 7 |
| `srcType_w` | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| `dataSrc_w` | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| `exuSrc_w` | 3 | 3 | 3 | 3 | 3 | 3 | 2 | 2 | 2 | 2 | 2 | 2 | 3 | 3 | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 |
| `robIdx_w` | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |
| `nFuTypeBit` | 7 | 7 | 4 | 4 | 5 | 5 | 5 | 5 | 2 | 2 | 3 | 3 | 1 | 1 | 2 | 2 | 2 | 2 | 2 | 2 | 3 | 3 | 8 | 8 |
| `nWkWB` | 4 | 4 | 4 | 4 | 4 | 4 | 6 | 6 | 6 | 6 | 6 | 6 | 4 | 4 | 4 | 4 | 10 | 10 | 16 | 16 | 16 | 16 | 16 | 16 |
| `wkWB_wen` | rfWen | rfWen | rfWen | rfWen | rfWen | rfWen | fpWen | fpWen | fpWen | fpWen | fpWen | fpWen | fpWen,rfWen,vecWen | fpWen,rfWen,vecWen | fpWen,rfWen,vecWen | fpWen,rfWen,vecWen | fpWen,rfWen,vecWen | fpWen,rfWen,vecWen | v0Wen,vecWen,vlWen | v0Wen,vecWen,vlWen | v0Wen,vecWen,vlWen | v0Wen,vecWen,vlWen | v0Wen,vecWen,vlWen | v0Wen,vecWen,vlWen |
| `wkWB_pdest_w` | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |
| `nWkIQ` | 7 | 7 | 7 | 7 | 7 | 7 | 3 | 3 | 3 | 3 | 3 | 3 | 7 | 7 | 7 | 7 | 7 | 7 | 0 | 0 | 0 | 0 | 0 | 0 |
| `wkIQ_wen` | rfWen | rfWen | rfWen | rfWen | rfWen | rfWen | fpWen | fpWen | fpWen | fpWen | fpWen | fpWen | rfWen | rfWen | rfWen | rfWen | rfWen | rfWen | - | - | - | - | - | - |
| `wkIQ_rcDest` | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `nOg0Cancel` | 4 | 4 | 4 | 4 | 4 | 4 | 1 | 1 | 1 | 1 | 1 | 1 | 7 | 7 | 7 | 7 | 7 | 7 | 0 | 0 | 0 | 0 | 0 | 0 |
| `og0_idx` | 0,2,4,6 | 0,2,4,6 | 0,2,4,6 | 0,2,4,6 | 0,2,4,6 | 0,2,4,6 | 8 | 8 | 8 | 8 | 8 | 8 | 0,2,4,6,20,21,22 | 0,2,4,6,20,21,22 | 0,2,4,6,20,21,22 | 0,2,4,6,20,21,22 | 0,2,4,6,20,21,22 | 0,2,4,6,20,21,22 | - | - | - | - | - | - |
| `nOg1Cancel` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `nLdCancel` | 3 | 3 | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 3 | 3 | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 |
| `ld1Cancel` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `ld2Cancel` | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `ldDep_pipes` | 3 | 3 | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 3 | 3 | 3 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 |
| `ldDep_w` | 2 | 2 | 2 | 2 | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 2 | 2 | 2 | 2 | 2 | 2 | 0 | 0 | 0 | 0 | 0 | 0 |
| `useRegCache` | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `regCacheIdx_w` | 5 | 5 | 5 | 5 | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 | 5 | 5 | 5 | 5 | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| `imm_w` | 32 | 32 | 32 | 32 | 32 | 32 | 0 | 0 | 0 | 0 | 0 | 0 | 32 | 32 | 12 | 12 | 0 | 0 | 0 | 0 | 0 | 0 | 15 | 15 |
| `ignoreOldVd` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 |
| `blocked` | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| `deqPortIdx_in` | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 1 | 1 | 1 |
| `deqPortIdxWr` | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 |
| `o_deqPortIdxRd` | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 |
| `o_trnDeqPort` | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 |
| `vecMem` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `transSel` | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 |
| `o_enqReady` | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 |
| `o_transValid` | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 0 |
| `o_cancelByp` | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| `o_isFirstIss` | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
| `deqPayload_n` | 32 | 32 | 24 | 24 | 23 | 23 | 22 | 22 | 20 | 20 | 20 | 20 | 34 | 34 | 22 | 22 | 15 | 15 | 56 | 56 | 57 | 57 | 59 | 59 |
| `deqPayload_w` | 567 | 567 | 554 | 554 | 553 | 553 | 548 | 548 | 546 | 546 | 546 | 546 | 586 | 586 | 562 | 562 | 541 | 541 | 741 | 741 | 742 | 742 | 744 | 744 |
| `trnPayload_n` | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 | 180 | 0 |
| `trnPayload_w` | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 | 1330 | 0 |

## 维度释义

- `parent`：golden 里例化它的 Entries 变体
- `role`：simp=可被提级的中转条目(isComp=false) / comp=终端发射条目(isComp=true)
- `count`：在该 Entries 里例化几份
- `lines`：golden 行数
- `n_ports`：golden 端口数
- `nSrc`：每 uop 的源寄存器数 srcStatus[]
- `psrc_w`：srcStatus.psrc 位宽
- `srcType_w`：srcStatus.srcType 位宽
- `dataSrc_w`：srcStatus.dataSources.value 位宽
- `exuSrc_w`：srcStatus.exuSources.value 位宽（0=无 IQ 唤醒）
- `robIdx_w`：RobPtr.value 位宽
- `nFuTypeBit`：status.fuType 保留的 one-hot 位数
- `nWkWB`：写回唤醒总线路数
- `wkWB_wen`：WB 唤醒携带的写使能字段（★多字段=匹配要按位或，不是单对★）
- `wkWB_pdest_w`：WB 唤醒 pdest 位宽
- `nWkIQ`：IQ 即时唤醒总线路数（0=无 IQ 唤醒子族）
- `wkIQ_wen`：IQ 唤醒携带的写使能字段
- `wkIQ_rcDest`：IQ 唤醒是否带 rcDest（写寄存器缓存）
- `nOg0Cancel`：og0Cancel 位数（按全局 exu 下标稀疏给）
- `og0_idx`：og0Cancel 的全局 exu 下标集合
- `nOg1Cancel`：★og1Cancel 位数——全族实测★
- `nLdCancel`：ldCancel 条数（= load 流水条数）
- `ld1Cancel`：有无 ld1Cancel（配 srcLoadDependency 的 bit0）
- `ld2Cancel`：有无 ld2Cancel（配 bit1）
- `ldDep_pipes`：srcLoadDependency 的 pipe 数
- `ldDep_w`：srcLoadDependency 每 pipe 位宽
- `useRegCache`：有无 srcStatus.useRegCache
- `regCacheIdx_w`：srcStatus.regCacheIdx 位宽
- `imm_w`：commonIn.enq.bits.imm 位宽（0=该变体不带 imm）
- `ignoreOldVd`：有无 vlFromInt/vlFromVf（向量 ignoreOldVd 通路）
- `blocked`：有无 status.blocked
- `deqPortIdx_in`：enq 侧有无 status.deqPortIdx
- `deqPortIdxWr`：有无 commonIn.deqPortIdxWrite
- `o_deqPortIdxRd`：有无 commonOut.deqPortIdxRead（comp 的发射口选择回读）
- `o_trnDeqPort`：有无 commonOut.transEntry.bits.status.deqPortIdx
- `vecMem`：有无 status.vecMem（本 24 个应全 0，VecMem 是另一族）
- `transSel`：★有无 commonIn.transSel（simp 专属）★
- `o_enqReady`：有无 commonOut.enqReady
- `o_transValid`：有无 commonOut.transEntry（simp 专属）
- `o_cancelByp`：有无 commonOut.cancelBypass
- `o_isFirstIss`：有无 commonOut.isFirstIssue
- `deqPayload_n`：commonOut.entry 负载字段数（发射口可见那份）
- `deqPayload_w`：commonOut.entry 负载总位宽
- `trnPayload_n`：commonOut.transEntry 负载字段数（0=comp）
- `trnPayload_w`：commonOut.transEntry 负载总位宽

## 真正在变的维度（自动提炼）

变的 37 个 / 恒定的 8 个。

恒定（全 24 个一致，参数化核可以写死）：

- `srcType_w` = 4
- `dataSrc_w` = 4
- `robIdx_w` = 8
- `wkWB_pdest_w` = 8
- `nOg1Cancel` = 0
- `blocked` = 1
- `vecMem` = 0
- `o_isFirstIss` = 1

变的（必须走 parameter）：

- `role`：{comp, simp}
- `nSrc`：{1, 2, 3, 5}
- `psrc_w`：{7, 8}
- `exuSrc_w`：{0, 2, 3}
- `nFuTypeBit`：{1, 2, 3, 4, 5, 7, 8}
- `nWkWB`：{10, 16, 4, 6}
- `wkWB_wen`：{fpWen, fpWen,rfWen,vecWen, rfWen, v0Wen,vecWen,vlWen}
- `nWkIQ`：{0, 3, 7}
- `wkIQ_wen`：{-, fpWen, rfWen}
- `wkIQ_rcDest`：{0, 1}
- `nOg0Cancel`：{0, 1, 4, 7}
- `nLdCancel`：{0, 3}
- `ld1Cancel`：{0, 1}
- `ld2Cancel`：{0, 1}
- `ldDep_pipes`：{0, 3}
- `ldDep_w`：{0, 2}
- `useRegCache`：{0, 1}
- `regCacheIdx_w`：{0, 5}
- `imm_w`：{0, 12, 15, 32}
- `ignoreOldVd`：{0, 1}
- `deqPortIdx_in`：{0, 1}
- `deqPortIdxWr`：{0, 1}
- `o_deqPortIdxRd`：{0, 1}
- `o_trnDeqPort`：{0, 1}
- `transSel`：{0, 1}
- `o_enqReady`：{0, 1}
- `o_transValid`：{0, 1}
- `o_cancelByp`：{0, 1}
- `deqPayload_n`：{15, 20, 22, 23, 24, 32, 34, 56, 57, 59}
- `deqPayload_w`：{541, 546, 548, 553, 554, 562, 567, 586, 741, 742, 744}
- `trnPayload_n`：{0, 180}
- `trnPayload_w`：{0, 1330}

## 覆盖判断：这一族属于 Entries 共享核，不是独立族

依据（全部可从上表复核）：

1. **同一份 Scala**。`OthersEntry.scala` 的模块体只有四句：`CommonWireConnect` / `CommonIQWakeupConnect` / `EntryRegCommonConnect` / `CommonOutConnect`，全在 `EntryBundles.scala`；`EnqEntry.scala` 调的是**同样四句**，只是 `isEnq=true`。也就是说 golden 的 EnqEntry 与 OthersEntry 本来就是一份逻辑的两次单态化。
2. **本仓已有那份核**。`rtl/backend/xs_iq_entries_core.sv` 的 `xs_iq_entry` 就是这份逻辑的参数化重写，参数 `IS_ENQ` / `IS_TRANS` / `IS_COMP` 正对应三种条目；`KEEP_WIDE = IS_ENQ | IS_TRANS` 正对应本表量到的「simp 存宽负载、comp 存窄负载」。
3. **端口面对得上**。golden `OthersEntry*` 的端口就是 `CommonInBundle`/`CommonOutBundle` 摊平，而 `xs_iq_entry` 的端口是同一对 Bundle 的打包形式；差的是「摊平/改名」，属于 wrapper 的活。

结论：**复用 `xs_iq_entry`，不自建核**。自建等于把 800 行核体复制一份，违反 CONVENTIONS「变体家族：核体绝不复制」，而且两份核以后会各修各的。

### 落地形态

24 个变体 = **12 组家族参数 × 2 种角色**（本表里 simp/comp 在除角色专属端口外的每一个维度上都同值，可逐列复核）。所以：
- 核：沿用 `rtl/backend/xs_iq_entries_core.sv` 的 `xs_iq_entry`，不复制；
- 每变体一个薄文件 `rtl/backend/OthersEntry[_N].sv`：只做端口摊平 + 设参数，例化 `xs_iq_entry`；
- 生成器复用 `verif/ut/Entries_common/entries_gen.py` 已经在用的那几张表（负载字段偏移、唤醒路由），不另起一套。

### 但是：落地前必须先改共享核（★跨 lane 冲突★）

本表量出三处 `xs_iq_entry` **现在没有**的东西。三处都在共享核里，而 `agent/entries-rest3` 正在改同一个文件，所以不能由本 lane 自己动手：

**(A) 7 组 debug/perf 输出 —— 24 个变体全都要，一个也绕不过去。**
   `commonOut.{entryInValid, entryOutDeqValid, entryOutTransValid, perfLdCancel[], perfOg0Cancel[], perfWakeupByWB[], perfWakeupByIQ[][]}`。
   它们在 golden `OthersEntry*` 上是**真端口**（见上表末几行与 `EntryBundles.scala:476-483`，每个都是一行赋值，用的信号核里全都有），
   但在 `Entries*` 这一层被 firtool 消掉了，所以共享核当初没有产出它们。
   ★必须挂在 parameter 后面（例如 `HAS_DBG_OUT`，Entries 例化时给 0）★：否则这些新输出在 `xs_iq_entries_core` 里无人读，
   会给已经签核的 `EntriesAluCsrFenceDiv` / `EntriesVfdivVidiv` 带来 unread 点，把绿的打回 PARTIAL。

**(B) WB 唤醒匹配要从「单个 wen」扩成「按源分工的多 wen」。**
   本表 `wkWB_wen` 实测有 4 种形态：['fpWen', 'fpWen,rfWen,vecWen', 'rfWen', 'v0Wen,vecWen,vlWen']。
   其中 `v0Wen,vecWen,vlWen` 那一档（nSrc=5 的向量族）**不是简单按位或**：
   `EntryBundles.scala:185-193` 对 numRegSrc==5 是「源 0..2 用 `wakeUp`、源 3 用 `wakeUpV0`、源 4 用 `wakeUpVl`」，按源分工，不是同一个式子 OR 起来。
   这与 `agent/entries-rest3` 要做的「唤醒匹配从单对改成一串对按位或」是同一处代码 —— 请确认它那边是按**按源分工**实现的，不是一律 OR。

**(C) §11 里已登记的家族维度**：有 IQ 唤醒的变体 18/24 个，其中 StaMou（needFeedBackSqIdx）、向量族（ignoreOldVd / bypass2）这些在共享核 §11 里已列为待办，本族一样绕不过。

### 量出来的几条、与既有结论对表

- `nOg1Cancel` **全 24 个实测为 0** —— 原先只是「已查过的变体里全空」，现在是全族实测。
- `o_deqPortIdxRead` ⟺ 该 IQ `numDeq==2`，且 **simp 与 comp 同时有**；共享核 §2.6a 把它记成 comp 条目的性质，按本表应改成「与角色无关，只看 numDeq」。
- `transEntry` 的**负载部分**在 12 个 simp 上逐位相同（180 字段 / 1330 位，脚本里有 signature 断言），变的只有 `transEntry.bits.status.*` 与 `transEntry.bits.imm`。
- `commonOut.fuType` 是 **35 位全宽 one-hot**，而条目里存的是压缩过的 `nFuTypeBit` 位；摊回 35 位是 wrapper 的活，不必动核。
- `blocked` 在 24 个变体上**都有** `enq.bits.status.blocked` 端口，而 Entries 层矩阵只有 VecMem 两个变体为 1 —— 同一个字段在不同层次上被 DCE 的程度不同，这正是「每层都要自己量」的例子。


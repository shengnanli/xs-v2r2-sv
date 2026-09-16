# Entries* 家族 字段使用矩阵（从 golden 实测）

golden: `/home/eda/xs-env/G1-canonical/golden-rtl`

由 `verif/ut/Entries_field_matrix/gen_matrix.py` 生成，改动共享核前必须复跑并核对（`--check`）。

## 变体编号

- V00 = `EntriesAluBrhJmpI2fVsetriwiVsetriwvfI2v`
- V01 = `EntriesAluCsrFenceDiv`
- V02 = `EntriesAluMulBkuBrhJmp`
- V03 = `EntriesFaluFcvtF2vFmacFdiv`
- V04 = `EntriesFaluFmac`
- V05 = `EntriesFaluFmacFdiv`
- V06 = `EntriesLdu`
- V07 = `EntriesStaMou`
- V08 = `EntriesStdMoud`
- V09 = `EntriesVfdivVidiv`
- V10 = `EntriesVfmaVialuFixVfalu`
- V11 = `EntriesVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf`
- V12 = `EntriesVlduVstu`
- V13 = `EntriesVlduVstuVseglduVsegstu`

## 矩阵（行 = 字段维度，列 = 变体）

| 字段维度 | V00 | V01 | V02 | V03 | V04 | V05 | V06 | V07 | V08 | V09 | V10 | V11 | V12 | V13 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `numEnq` | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 |
| `numDeq` | 2 | 2 | 2 | 2 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 2 | 1 | 1 |
| `numEntries` | 24 | 24 | 24 | 18 | 18 | 18 | 16 | 16 | 16 | 10 | 16 | 16 | 16 | 16 |
| `numSimp` | 6 | 6 | 6 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 |
| `numComp` | 16 | 16 | 16 | 14 | 14 | 14 | 12 | 12 | 12 | 6 | 12 | 12 | 12 | 12 |
| `enqEntryMod` | EnqEntry_4 | EnqEntry_6 | EnqEntry | EnqEntry_8 | EnqEntry_12 | EnqEntry_10 | EnqEntry_24 | EnqEntry_20 | EnqEntry_30 | EnqEntry_18 | EnqEntry_16 | EnqEntry_14 | EnqEntryVecMem_2 | EnqEntryVecMem |
| `othersEntryMod` | OthersEntry_44x6;OthersEntry_50x16 | OthersEntry_66x6;OthersEntry_72x16 | OthersEntryx6;OthersEntry_6x16 | OthersEntry_88x2;OthersEntry_90x14 | OthersEntry_120x2;OthersEntry_122x14 | OthersEntry_104x2;OthersEntry_106x14 | OthersEntry_200x2;OthersEntry_202x12 | OthersEntry_172x2;OthersEntry_174x12 | OthersEntry_242x2;OthersEntry_244x12 | OthersEntry_164x2;OthersEntry_166x6 | OthersEntry_150x2;OthersEntry_152x12 | OthersEntry_136x2;OthersEntry_138x12 | OthersEntryVecMem_14x2;OthersEntryVecMem_16x12 | OthersEntryVecMemx2;OthersEntryVecMem_2x12 |
| `nEnqPolicy` | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 | 2 |
| `deqSelOH_w` | 24 | 24 | 24 | 18 | 18 | 18 | 16 | 16 | 16 | 10 | 16 | 16 | 16 | 16 |
| `nSrcStatus` | 2 | 2 | 2 | 3 | 3 | 3 | 1 | 1 | 1 | 5 | 5 | 5 | 5 | 5 |
| `psrc_w` | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 7 | 7 | 7 | 7 | 7 |
| `srcType_w` | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| `dataSources_w` | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| `ldDep_pipes` | 3 | 3 | 3 | 0 | 0 | 0 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 |
| `ldDep_w` | 2 | 2 | 2 | 0 | 0 | 0 | 2 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| `useRegCache` | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `regCacheIdx_w` | 5 | 5 | 5 | 0 | 0 | 0 | 5 | 5 | 5 | 0 | 0 | 0 | 0 | 0 |
| `robIdx_w` | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |
| `fuTypeBits` | 0,1,2,3,6,28,29 | 5,6,8,9 | 0,1,6,7,10 | 4,11,12,13,14 | 11,12 | 11,12,14 | 15 | 16,17 | 16,17 | 22,26 | 19,24,25 | 18,19,20,21,24,25,27,30 | 31,32 | 31,32,33,34 |
| `nFuTypeBits` | 7 | 4 | 5 | 5 | 2 | 3 | 1 | 2 | 2 | 2 | 3 | 8 | 2 | 4 |
| `imm_w` | 32 | 32 | 32 | 0 | 0 | 0 | 32 | 12 | 0 | 0 | 0 | 15 | 0 | 0 |
| `status_blocked` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| `vecMem_sqIdx` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| `vecMem_lqIdx` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| `vecMem_numLsElem` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 5 | 5 |
| `payload_srcs` | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 | 5 |
| `nDeqStatusPorts` | 15 | 12 | 13 | 13 | 10 | 11 | 6 | 7 | 7 | 14 | 15 | 20 | 22 | 24 |
| `nWkWB` | 4 | 4 | 4 | 6 | 6 | 6 | 4 | 4 | 10 | 16 | 16 | 16 | 16 | 16 |
| `nWkWBDly` | 4 | 4 | 4 | 6 | 6 | 6 | 4 | 4 | 10 | 16 | 16 | 16 | 16 | 16 |
| `wkWB_pdest_w` | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 |
| `wkWB_wen` | rfWen | rfWen | rfWen | fpWen | fpWen | fpWen | rfWen,fpWen,vecWen | rfWen,fpWen,vecWen | rfWen,fpWen,vecWen | vecWen | vecWen | vecWen | rfWen,fpWen,vecWen,v0Wen,vlWen | rfWen,fpWen,vecWen,v0Wen,vlWen |
| `nWkIQ` | 7 | 7 | 7 | 3 | 3 | 3 | 7 | 7 | 7 | 0 | 0 | 0 | 0 | 0 |
| `nWkIQDly` | 7 | 7 | 7 | 3 | 3 | 3 | 7 | 7 | 7 | 0 | 0 | 0 | 0 | 0 |
| `wkIQ_pdest_w` | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 8 | 0 | 0 | 0 | 0 | 0 |
| `wkIQ_wen` | rfWen | rfWen | rfWen | fpWen | fpWen | fpWen | rfWen | rfWen | rfWen |  |  |  |  |  |
| `wkIQ_ldDep_pipes` | 3 | 3 | 3 | 0 | 0 | 0 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 |
| `wkIQ_hasRcDest` | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `wkIQ_is0LatIdx` | 0,1 | 0,1 | 0,1 | 0 | 0 | 0 | 0,1,2,3,4,5,6 | 0,1,2,3,4,5,6 | 0,1,2,3,4,5,6 |  |  |  |  |  |
| `og0CancelIdx` | 0,2,4,6 | 0,2,4,6 | 0,2,4,6 | 8 | 8 | 8 | 0,2,4,6,20,21,22 | 0,2,4,6,20,21,22 | 0,2,4,6,20,21,22 |  |  |  |  |  |
| `og1CancelIdx` |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| `nLdCancel` | 3 | 3 | 3 | 0 | 0 | 0 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 |
| `ldCancel_ld1` | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `ldCancel_ld2` | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `nCancelDeqVec` | 2 | 2 | 2 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `nOg0Resp` | 2 | 2 | 2 | 2 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 2 | 1 | 1 |
| `og0Resp_hasBits` | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 1 |
| `nOg1Resp` | 2 | 2 | 2 | 2 | 1 | 2 | 1 | 1 | 1 | 1 | 2 | 2 | 1 | 1 |
| `og1Resp_hasBits` | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 1 |
| `nOg2Resp` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 2 | 2 | 1 | 1 |
| `og2Resp_hasBits` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 |
| `resp_hasRobIdx` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `resp_hasSqIdx` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `resp_hasUopIdx` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| `resp_hasVecReplay` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| `deqEntry_hasImm` | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 1 | 0 | 0 | 0 | 1 | 0 | 0 |
| `nExuSrcPerEntry` | 2 | 2 | 2 | 3 | 3 | 3 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `exuSources_w` | 3 | 3 | 3 | 2 | 2 | 2 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 |
| `nDataSrcPerEntry` | 2 | 2 | 2 | 3 | 3 | 3 | 1 | 1 | 1 | 5 | 5 | 5 | 5 | 5 |
| `dataSourcesOut_w` | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 | 4 |
| `nLdDepOutPerEntry` | 3 | 3 | 3 | 0 | 0 | 0 | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 |
| `ldDepOut_w` | 2 | 2 | 2 | 0 | 0 | 0 | 2 | 2 | 2 | 0 | 0 | 0 | 0 | 0 |
| `vlFromInt` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 |
| `vlFromVf` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 | 1 | 1 | 1 |
| `fromMem` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | 1 | 1 |
| `vecLdIn` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| `vecMemIn` | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 1 | 1 |
| `compMod` | OthersEntry_50 | OthersEntry_72 | OthersEntry_6 | OthersEntry_90 | OthersEntry_122 | OthersEntry_106 | OthersEntry_202 | OthersEntry_174 | OthersEntry_244 | OthersEntry_166 | OthersEntry_152 | OthersEntry_138 | OthersEntryVecMem_16 | OthersEntryVecMem_2 |
| `comp_deqPortIdxRead` | 1 | 1 | 1 | 1 | 0 | 1 | 0 | 0 | 0 | 0 | 1 | 1 | 0 | 0 |
| `comp_in_ldDep` | 1 | 1 | 1 | 0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 0 | 0 |
| `nPorts` | 848 | 828 | 831 | 651 | 598 | 641 | 705 | 700 | 753 | 638 | 762 | 788 | 870 | 876 |


## 从矩阵读出来的家族结构（三个互斥子族）

按「有没有 IQ 即时唤醒 / 有没有 load 取消」分，14 个变体正好落成三族：

| 子族 | 变体 | 特征 |
|---|---|---|
| INT/MEM（6） | AluBrhJmpI2f…, AluCsrFenceDiv, AluMulBkuBrhJmp, Ldu, StaMou, StdMoud | `nWkIQ=7`、`og0Cancel`、`ldCancel`、`cancelDeqVec`、`exuSources`、`loadDependency` 出口、`useRegCache/regCacheIdx`；**无** og2Resp / vl |
| FP（3） | FaluFcvtF2vFmacFdiv, FaluFmacFdiv, FaluFmac | `nWkIQ=3`、有 og0Cancel、**无** ldCancel / loadDependency / cancelDeqVec / regCache |
| VEC（5） | VfdivVidiv, VfmaVialuFixVfalu, VfmaVialuFixVimac…, VlduVstu, VlduVstuVseglduVsegstu | **无** IQ 唤醒与整套取消网络；有 og2Resp + `vlFromInt/Vf`；后两个另有 vecMem（fromMem/vecLdIn/vecMemIn/status.blocked） |

**已签核的 EntriesVfdivVidiv 是 VEC 族里最小的一个**（10 条目、无 vecMem）；
canary `EntriesAluCsrFenceDiv` 在 INT 族。两者在矩阵里几乎没有重叠的"可选维度"。

## 裁剪任何状态前必须先看的几行

* `og0CancelIdx` / `og1CancelIdx` —— **稀疏全局 exu 下标，不是 0..N-1**。
  Falu* 的 `nWkIQ=3` 但 og0Cancel 只留下标 `8`；Alu* 的 `nWkIQ=7` 留 `0,2,4,6`。
  共享核若按「第 w 路 IQ 唤醒配第 w 个 og0Cancel」连线，对每个变体都是错的。
  → 结论：**下标映射属于变体薄层，核只收一根已经算好的 `cancelSel[w]`。**
* `og1CancelIdx` 在 **14 个变体里全为空** —— Chisel 里 `og1Cancel` 是 `Input(ExuVec())`
  且参与 `CommonInBundle`，但 G1 配置下它一个位都没到达任何输出，firtool 全删。
  不要为它写逻辑。
* `wkIQ_is0LatIdx` —— `is0Lat` 只在部分路上是真信号，其余被折成常量真/假；
  Alu* 是 `0,1`，Ldu/StaMou/StdMoud 是 `0..6`，Falu* 是 `0`。
* `psrc_w` 7（VEC）/ 8（INT/FP）、`nSrcStatus` 1/2/3/5、`nWkWB` 4/6/10/16 ——
  这几个已经是核的参数，不构成新维度。
* `imm_w` 32/15/12/0 —— **有 imm 的变体只有 6 个**，且位宽不同（StaMou 12、
  VfmaVialuFixVimac… 15）。`deqEntry_hasImm` 与 `imm_w>0` 并不等价
  （StdMoud 有 `imm_w=0` 但 `deqEntry_hasImm=0`；VfmaVialuFixVimac… imm_w=15 且露出）。
* `status_blocked` / `vecMem_*` 只有 VlduVstu 两个变体有 —— blocked 在别处恒 0。

## 已确认的「Chisel 读起来是 A、firtool 展开成 B」

1. `wakeUpFromIQ` 在 Chisel 里是 `ValidIO`，golden 顶层**没有 valid 端口**
   （矩阵里 IQ 路数只能按 `bits_pdest` 数）。
2. `EnqEntry` 在 Chisel 里有 `enqDelayIn1` **和** `enqDelayIn2` 两套延迟唤醒输入；
   INT 族走的是 `else` 分支，只用到 enqDelayOut1 —— golden EnqEntry_6 里
   `enqDelayIn2` 整套端口不存在。
3. `og0Resp.bits.resp` 在 Alu* 里没有端口，golden 的 resp 查找表
   （`_GEN_16 = {2'h0, 2'h0, og1Resp_bits_resp, 2'h0}`）把 timer=0 的 resp 钉成
   `2'b00`=BLOCK。timer=1 才是真 resp。
4. `og1Cancel` 见上，全家族皆空。

## 已发现的「拿 VfdivVidiv 推出来会错」的两条

这两条是共享核现在的写法，对 canary 是错的 —— 正是字段矩阵要防的那类错：

* **comp 条目的 `deqPortIdx` 寄存器**。核现在按 `KEEP_WIDE`（= 有 transEntry 出口）
  决定生不生成，依据是"VfdivVidiv 的 comp 条目没有这个寄存器"。
  实测 14/14 的真实条件是 **`numDeq == 2`**（列 `comp_deqPortIdxRead`）：
  VfdivVidiv `numDeq=1` 才被折成常量 0；canary `numDeq=2`，golden `OthersEntry_72`
  **有** `io_commonOut_deqPortIdxRead`。
* **comp 条目入口的 `srcLoadDependency`**。核现在把 comp 段的 `x_ld_dep` 钉 0，
  依据是"golden 的 comp 条目入口不带这些位"。实测 14/14 的真实条件是
  **`ldDep_pipes > 0`**（列 `comp_in_ldDep`）：canary 的 `OthersEntry_72`
  **带**这些位；VfdivVidiv 那边是整条通路死了才被 DCE，不是家族不变量。

这两条等价关系由 `gen_matrix.py --check` 直接断言 —— 哪天新变体破了它，
闸会先红，而不是等 FM 去发现核里那两处 `generate` 条件写错了。


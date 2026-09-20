# Entries* 剩余 5 个访存变体：共享核覆盖判断

**结论先写在前面：5 个全部套现有核，要扩核，不要第二个核。**
扩的全是 `generate if (...)` 形态的可选维度，已实现的 9 个变体传参后**逐字不变**。

- 判断人：本 lane（第二位接手 `agent/entries-rest3`）
- 依据：G1 golden `/home/eda/xs-env/G1-canonical/golden-rtl`，逐条给行号，
  下面每一条都可以直接 `sed -n` 复核
- 前一位 lane 事前判断「可能需要扩核甚至第二个核」，本 lane **确认前半、否定后半**：
  要扩核，但不需要第二个核

## 为什么不是第二个核

分族看（矩阵 `verif/ut/Entries_field_matrix/matrix.md`）：

| 子族 | 5 个访存变体的归属 | 已签核的同族样本 |
|---|---|---|
| INT/MEM | Ldu / StaMou / StdMoud | ★EntriesAluCsrFenceDiv（canary，同族）★ |
| VEC | VlduVstu / VlduVstuVseglduVsegstu | ★EntriesVfdivVidiv + VfmaVialuFix\*（同族，本轮 3 个）★ |

也就是说 5 个里**没有一个落在新族**：条目三段结构（enq/simp/comp）、转移策略、
EnqPolicy、发射选择、issueTimer 响应窗、ignoreOldVd、负载扁平化钉点 —— 这些
占核体绝大部分的东西，5 个变体与已签核变体**逐条相同**。差异集中在**唤醒匹配的
形状**和**响应来源**两处，都是核里已有参数化位置的**加宽**，不是新机制。

## 需要扩的 6 处（每条都配 golden 行号）

### E1 唤醒匹配要从「单对 (srcTypeBit, wen)」改成「一串对的按位或」★5 个全要★

核现在的写法（`xs_iq_entries_core.sv` §2.2）是每源一个 `SRC_TYPE_BIT[s]`、
每路一根 `wk_wen[w]`：

    wk_valid[w] & wk_wen[w] & r_src_type[s][SRC_TYPE_BIT[s]] & (pdest==psrc)

golden 在访存族里是**三对相或**（`EnqEntry_24.sv:965-969`，Ldu 的 enq 条目）：

    pdest == psrc
      & ( srcType[1] & fpWen
        | srcType[0] & rfWen
        | srcType[2] & vecWen ) & valid

VEC 访存族同形，而且**同一个变体里不同源用不同的对**
（`EnqEntryVecMem_2.sv`：src0/1/2 见 :1198-1203 三对相或；
src3 见 :1425 只有 `srcType[3] & v0Wen`；src4 见 :1472 只有 `srcType[2] & vlWen`）。

已签核变体是这张表退化到 1 对的特例（`EnqEntry_6.sv:993` 只有 `srcType[0] & rfWen`），
所以改造要求是：**新参数在 1 对时必须生成与今天逐字相同的表达式**，否则
已签核的 9 个变体锥体会变，FM 会红。

> 形状建议：`wk_wen` 从 `[NUM_WK_WB]` 变成 `[NUM_WK_WB][N_WEN_KIND]`，
> 每源给一张 `SRC_WEN_PAIRS[s]` = {(typeBit, wenKind)…}。薄层照旧只搬线。

### E2 ★同一变体的「当拍窗口」和「入队延迟窗口」可以用不同的对表★（StdMoud 实测）

这条是本判断里**最容易做错**的一条，而且做错了 UT 看不见（两个窗口在正常激励下
同时命中的机会极低）。`EntriesStdMoud` 的 `EnqEntry_30.sv`：

- 当拍 IQ 唤醒（:1198-1200）：`srcType[0] & rfWen` —— **只有一对**
- 入队延迟 IQ 唤醒（:1242-1245）：`srcType[1] & fpWen | srcType[0] & rfWen` —— **两对**

核现在两个窗口共用同一份 `IQ_SRC_MASK` / `IQ_TYPE_BIT`。**必须拆成两份参数**，
并且矩阵要加两列（当拍/延迟各一列的 wen 对表），否则这是又一次
「从一个变体外推到全家族」。

#### ★E2 落地时必须配一个专属变异靶子★（集成者 0920 点名）

E2 是本判断里唯一一条「做错了 UT 按构造看不见」的：两个窗口在正常激励下同时
命中同一个源的机会极低，而错法（两窗口共用一份对表）在**当拍窗口**上是对的，
只有延迟窗口那一拍才错。所以它不能只靠"跑得久一点"。

落地时往 `verif/ut/Entries_common/mutants.py` 加一条，形状照下面写：

    ('M16', '入队延迟窗口沿用当拍窗口的 wen 对表 —— StdMoud 的 golden 两窗口'
            '对表不同（EnqEntry_30.sv:1198 一对 vs :1242 两对），共用一份就是'
            '把延迟窗口的 fpWen 那一路整条丢掉',
     "<核里延迟窗口用 IQD_SRC_PAIRS 的那一行>",
     "<换成用当拍的 IQ_SRC_PAIRS>",
     lambda v: (v.iqd_pairs != v.iq_pairs,
                '两窗口对表本来就相同的变体上，这条变异是死的 —— '
                '它只能由 StdMoud 这类变体去证')),

★适用性判据必须写成"两窗口对表不同"，不能写成"有 IQ 唤醒"★：
写成后者会让 Alu*/Falu* 上这条变异变成空转，却被记进分母 —— 那正是
`na` 桶存在的理由。这条判据需要生成器把两张对表都作为 `Variant` 字段暴露出来。

同时矩阵 `gen_matrix.py` 要加两列（当拍/延迟各一列的 wen 对表）并配 `--check`
断言，让"哪天有人把两窗口合并"这件事**先让闸红**，而不是等 FM 去发现。

### E3 已经有参数、不用动 ★Ldu / StaMou / StdMoud★

- `HAS_LD1_CANCEL=1`、`LD_PIPES=3`、`LD_DEP_W=2`：核已有参数
- `og0Resp_hasBits=1`：核 §5 的 `OG_HAS_BITS[k]` 已经是逐档参数
- `og0CancelIdx = {0,2,4,6,20,21,22}`（稀疏全局下标，`EnqEntry_24.sv:1218-1232`）：
  按既定分工属**变体薄层**，核只收算好的 `iq_cancel[w]`
- `nWkWB` 4/10、`imm_w` 32/12/0、`nSrcStatus=1`：都是现成 parameter

### E4 needFeedBack：**阵列层**的响应多路选择 ★StaMou / VlduVstu / VlduVstuVseglduVsegstu★

不是条目里的事 —— golden 在 `Entries<V>` 顶层就把 mem 响应选好了再喂进条目。

StaMou（`EntriesStaMou.sv:19341-19348`，每个条目实例一份）：

    issueResp.valid = issueTimerRead[1] ? (fromMem.slowResp.valid & 
                                           {slowResp.sqIdx} == {entry.payload.sqIdx})
                                        : ogTab[issueTimerRead[0]]

条目侧一个端口都不用加；核 §5 现在只有 `ogTab`，加一条「timer 高位选 mem 响应」
的分支即可。entry 侧要能读出 payload 里的 sqIdx —— 阵列已经有 `o_ety_payload`，
按 `pl_off` 表切片就行，**不新增核端口**。

VlduVstu 更宽一档（`EntriesVlduVstu.sv:22967-22993`）：timer==3 时在
**三个**来源里选，而且是 ★按位或★ 不是优先选择：

    (&issueTimerRead) ? hitRespsVec_0 | hitRespsVec_1 | hitRespsVec_2 : ogTab[timer]
    resp = (hit0 ? vecLdIn.resp : 0) | (hit1 ? fromMem.slowResp : 0)
         | (hit2 ? vecLdIn.finalIssueResp : 0)

命中判据是 **sqIdx 与 lqIdx 同时相等**（`:21238-21247`），比的是
条目的 `status.vecMem`，不是 payload。

> ★这正是本家族三个已知坑里的第一个（`Mux1H` 选择非 one-hot 时 golden 按位或）
> 又一次出现★ —— 照抄按位或，不要写成 `case`/优先选择。

### E5 vecMem 状态组 ★VlduVstu / VlduVstuVseglduVsegstu★

两个变体的条目比已签核的 VEC 条目**多 8 个状态寄存器**
（`EnqEntryVecMem_2.sv:908-920` vs `EnqEntry_18.sv:748-751`）：

| 寄存器 | 位宽 |
|---|---|
| `status_blocked` | 1 |
| `status_vecMem_sqIdx_flag` / `_value` | 1 + 6 |
| `status_vecMem_lqIdx_flag` / `_value` | 1 + 7 |
| `status_vecMem_numLsElem` | 5 |
| `status_isVecPartReplay` | 1 |
| `status_vecReplayMask` | 16 |
| `status_vecReplayMbIdx` | 4 |

合计 42 位/条目 × 16 条目 = 672 位。次态逻辑各只有几行：

- `blocked`（`:2058-2062`）：`{entry.vecMem.lqIdx} != {fromLsq.lqDeqPtr} & payload.vpu.isVleff`
  —— 核现在 §2.6a 把 blocked 次态钉死 0，这里要接真逻辑；
  新增一个输入 `fromLsq_lqDeqPtr`（阵列从 `io_vecMemIn_lqDeqPtr` 接过来）
- `isVecPartReplay`（`:2017-2020`）：`issueResp.valid & (&issueTimer) ? resp.isVecPartReplay : 保持`
- `vecReplayMask` / `vecReplayMbIdx`：同形
- `vecMem.sqIdx/lqIdx/numLsElem`：入队装载、之后保持（随 transEntry 传）

`issueResp` 的 bits 要从 `[1:0] resp` 加宽成 `{resp, isVecPartReplay, vecReplayMask,
vecReplayMbIdx}` —— 对不带 vecMem 的变体退化成今天的 2 位。

### E6 ★核 §11(e) 那条「bypass2 分支」对这 5 个**都不适用**，可以划掉★

核文件尾 §11(e) 写着「向量/访存族里 readVfRf && hasIQWakeUp 的变体需要
`dataSources=bypass2` 分支」。实测**不需要**：

| 变体 | `transEntry…dataSources` 表达式 | 行号 |
|---|---|---|
| EntriesAluCsrFenceDiv（已签核） | `wakeupByIQ ? 4'h2 : (T ? 4'h8 : current)` | `EnqEntry_6.sv:2897-2902` |
| EntriesLdu | **逐字相同** | `EnqEntry_24.sv:2359-2364` |
| EntriesVlduVstu | `T ? 4'h8 : reg`（无 IQ 项，与 VfdivVidiv 同形） | `EnqEntryVecMem_2.sv:2834-2837` |

也就是说核现在实现的那条 `else` 分支就是 5 个变体走的那条。
**这一条应当从 §11 的待办里删掉，并把上面三行留在原处当依据** ——
否则下一个人还会为它写一段用不上的逻辑。

## 不需要的（查过之后确认核里已对）

- `srcLoadDependency` 寄存器：矩阵 `ldDep_pipes` 列对 V09/V12/V13 都是 0（那是**顶层
  端口视角**），但 golden 的 **enq 条目**照样有 30 个（5 源 × 3 pipe × 2 位）：
  `EnqEntry_18.sv`（已签核的 VfdivVidiv）与 `EnqEntryVecMem_2.sv` 都是 30。
  ★所以这不是访存族的新维度，是已签核变体上已经验过的既有形状。★
  （用 `grep -cE '^  reg .*srcLoadDependency' <mod>.sv` 复核；simp/comp 条目两边都是 0。）
- `og1Cancel`：14/14 全空，不写。
- `deqFuSame` / `isAllComp` / `isAllSimp`：G1 的 14 个变体都不走，5 个访存变体也不走。

## 工作量估计（给排期，不是承诺）

| 项 | 改哪 | 影响已签核变体？ |
|---|---|---|
| E1 唤醒对表 | 核 §2.2/§2.2b + 生成器 + 矩阵加列 | ★会动共享核，9 个已签核变体必须全部重跑 FM★ |
| E2 两窗口分开 | 同上 | 同上 |
| E4 needFeedBack | 核 §5 + 薄层 | 退化分支，不动已签核 |
| E5 vecMem 组 | 核新增 `generate if (HAS_VEC_MEM)` | 退化分支，不动已签核 |
| E3/E6 | 不用改 | — |

★E1/E2 动的是共享核的公共路径 ⇒ 按本仓规矩，改完必须把 9 个已签核变体
（2 个旧 + 本轮 7 个）的 FM 全部重跑，不能只跑新变体。★
这是「一个核 + 薄变体」这条路线的代价，也正是它值钱的地方：
**唤醒匹配只有一处实现，改对了就是 14 个变体一起对。**

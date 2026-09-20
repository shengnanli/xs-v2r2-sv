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

### E1 唤醒匹配：★**按源分份**的对表，每份是「一串对按位或」★（5 个全要）

> **本条 2026-09-20 被集成者改过一次措辞，原因见文末「修订」。旧措辞
> 「从单对变成一串对按位或」会被读成**全源共用一张对表**，那是错的。**

#### golden 的真实结构：三个函数、三张对表，**按源分工**

`/home/eda/xs-env/XiangShan` @ `kunminghu-v2`（`133d7dc4b`），
`src/main/scala/xiangshan/backend/Bundles.scala:325-348` —— 逐字：

```scala
def wakeUp(successor: Seq[(UInt,UInt)], valid) = successor.map { case (thatPsrc, srcType) =>
  pdest === thatPsrc && ( SrcType.isFp(srcType) && this.fpWen
                        || SrcType.isXp(srcType) && this.rfWen
                        || SrcType.isVp(srcType) && this.vecWen ) && valid }
def wakeUpV0(successor, valid) = pdest === thatPsrc && ( SrcType.isV0(srcType) && this.v0Wen ) && valid
def wakeUpVl(successor, valid) = pdest === thatPsrc && ( SrcType.isVp(srcType) && this.vlWen ) && valid
```

`issue/EntryBundles.scala:185-193` 决定哪个源用哪个函数，**且只在 numRegSrc==5 时分**：

```scala
if (params.numRegSrc == 5) {
  bundle.bits.wakeUp(psrcSrcTypeVec.take(3), bundle.valid) :+   // 源 0..2
  bundle.bits.wakeUpV0(psrcSrcTypeVec(3),   bundle.valid) :+    // 源 3  ★判据是 isV0 不是 isVp★
  bundle.bits.wakeUpVl(psrcSrcTypeVec(4),   bundle.valid)       // 源 4
} else
  bundle.bits.wakeUp(psrcSrcTypeVec, bundle.valid)              // 全源同一张
```

★把三张表并成一张再按位或，会把 v0/vl 唤醒串到源 0..2★。UT 未必打得到
（要构造特定 srcType 组合），FM 会炸。

#### 从 golden RTL 实测出来的对表（复跑见本节末）

| golden enq 条目（变体） | numRegSrc | src0..2 | src3 | src4 |
|---|---|---|---|---|
| `EnqEntry_6`（AluCsrFenceDiv，**已签核**） | 2 | `[0]&rfWen` | — | — |
| `EnqEntry_12`（FaluFmac） | 3 | `[1]&fpWen` | — | — |
| `EnqEntry_24`（Ldu） | 1 | `[0]&rfWen \| [1]&fpWen \| [2]&vecWen` | — | — |
| `EnqEntry_18`（VfdivVidiv，**已签核**） | 5 | `[2]&vecWen` | `[3]&v0Wen` | `[2]&vlWen` |
| `EnqEntryVecMem_2`（VlduVstu） | 5 | `[0]&rfWen \| [1]&fpWen \| [2]&vecWen` | `[3]&v0Wen` | `[2]&vlWen` |

★**共享核今天已经是"按源分份"了**★（`SRC_WB_MASK[s]` + `SRC_TYPE_BIT[s]` 都带 `[s]`），
这正是 `EnqEntry_18` 那一行 src3 走 `[3]&v0Wen`、src4 走 `[2]&vlWen` 能过 FM 的原因。
**核缺的不是"分份"，是每份只能放 1 对。** 所以 E1 的准确表述是：

> 把每个源的对表从**定长 1 对**放宽成**变长一串对（按位或）**，
> 分份维度保持不动。

#### ★还有一条两边都没写的：每份留几对是 DCE 决定的，不是族常量★

`wakeUp()` 在 Chisel 里恒是 3 对，firtool 只保留**那个变体的 WB 总线上真有的
wen 字段**：`EnqEntry_18` 只剩 `vecWen`（VfdivVidiv 的 WB 没有 rfWen/fpWen 端口），
`EnqEntryVecMem_2` 三对全留（VlduVstu 的 WB 五个 wen 都有）。
所以**不能按"VEC 族 = 1 对 / MEM 族 = 3 对"写死**，必须逐变体从 golden 量。
好消息：`entries_gen.py` 本来就是从 golden 的 srcState 表达式机械提取这张表的
（文件头「唤醒路由表 <- golden EnqEntry_N.sv 的 currentStatus_srcStatus_<s>_srcState
表达式里出现的 WB 下标 / wen 字段 / srcType 位」），E1 是把它的**输出从 1 对放宽成
一串**，不是新写一张人工表。

#### 约束（不变）

**新参数在"每源 1 对"时必须生成与今天逐字相同的表达式** —— 这是 9 个已签核变体
不红的前提。`numRegSrc != 5` 时全源同一张的退化也正好落在这条约束里。

复跑（whitespace 归一后逐源提取，避免 golden 的换行把 `srcType[2] & vecWen`
劈成两行而漏数 —— 我第一版就是这么漏掉一对的）：

```bash
cd /home/eda/xs-env/G1-canonical/golden-rtl
python3 - EnqEntryVecMem_2 <<'EOF'
import re,sys
t=re.sub(r'\s+',' ',open(sys.argv[1]+'.sv').read())
for s in range(5):
    p=sorted(set(re.findall(r'srcStatus_%d_srcType\[(\d)\] & io_commonIn_wakeUpFromWB_\d+_bits_(\w+Wen)'%s,t)))
    if p: print('src%d: '%s+' | '.join(f'srcType[{b}]&{w}' for b,w in p))
EOF
```

#### 修订

- 2026-09-20 集成者转 `agent/othersentry` 的发现指出原措辞会被读成"全源共用一张对表"，
  并给了 Chisel 出处。本 lane 独立复核 `Bundles.scala:325-348` 与
  `EntryBundles.scala:185-193`（`XiangShan@133d7dc4b`）**逐字成立**，据此重写本节。
- ★一处数字更正★：集成者说"`nSrc=5` 的正是那 **6** 个向量变体"。实测是 **5** 个 ——
  按 golden enq 条目的 `entryReg_status_srcStatus_<n>_psrc` 寄存器个数点名：
  `EnqEntry_18`(V09 VfdivVidiv) / `EnqEntry_16`(V10) / `EnqEntry_14`(V11) /
  `EnqEntryVecMem_2`(V12) / `EnqEntryVecMem`(V13)。其余 9 个是 1/2/3。
  复跑：`for m in …; do grep -cE '^  reg .*srcStatus_[0-9]+_psrc' $m.sv; done`。
  结论方向不受影响（这 5 个里有 2 个正是本判断要做的访存变体），只是别按 6 排期。

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

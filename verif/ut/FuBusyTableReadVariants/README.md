# FuBusyTableRead 家族 UT（18 个变体）

golden 里同一份 Chisel（`FuBusyTable.scala`）生成了 18 个模块。本 UT 一口气双例化
全部 18 个变体逐拍比对；FM 逐变体各出一份 receipt。

## 这个模块在做什么

后端乱序发射队列（`IssueQueue*`）为每条出射通道维护一张 **fuBusyTable**（忙表，
由同族的 `FuBusyTableWrite` 维护），按「还差几拍写回」分槽记录写回端口的占用。
本模块把那张表翻译成**逐条目的屏蔽位**：

```
busy_mask[e] = 或_b ( fuBusyTable[b] & (条目 e 的 fuType 落在槽 b 的功能单元集合里) )
```

`fuType` 是 35 位 one-hot（`FuType.scala` 的 `addType` 顺序，0=jmp … 34=vsegstu），
"落在集合里" = 与该槽的位掩码相与后有任何一位为 1。golden 把整个与/或矩阵展平成
一条 `assign`。**本族纯组合，一个寄存器都没有。**

## 差异维度矩阵（全部从 golden 端口表与表达式实测，见 scripts/gen_fubusy_wbarb.py 的解析）

| 变体 | golden 行数 | 条目数 NE | 表宽 TW | 槽 → fuType 位（名） | 例化者 |
|---|---|---|---|---|---|
| `FuBusyTableRead` | 170 | 24 | 3 | `0`=alu(6) `2`=mul(7)+bku(10) | IssueQueueAluMulBkuBrhJmp.sv |
| `FuBusyTableRead_2` | 144 | 24 | 1 | `0`=jmp(0) | IssueQueueAluMulBkuBrhJmp.sv |
| `FuBusyTableRead_22` | 194 | 24 | 3 | `0`=jmp(0)+brh(1)+i2v(3)+vsetiwi(28)+vsetiwf(29) `2`=i2f(2) | IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv |
| `FuBusyTableRead_23` | 144 | 24 | 1 | `0`=alu(6) | IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv / IssueQueueAluCsrFenceDiv.sv |
| `FuBusyTableRead_26` | 170 | 24 | 3 | `0`=i2v(3) `2`=i2f(2) | IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv |
| `FuBusyTableRead_28` | 144 | 24 | 1 | `0`=i2v(3) | IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv |
| `FuBusyTableRead_42` | 192 | 18 | 4 | `0`=f2v(4) `1`=falu(11) `2`=fcvt(13) `3`=fmac(12) | IssueQueueFaluFcvtF2vFmacFdiv.sv |
| `FuBusyTableRead_43` | 152 | 18 | 3 | `1`=falu(11) `2`=fcvt(13) | IssueQueueFaluFcvtF2vFmacFdiv.sv |
| `FuBusyTableRead_52` | 152 | 18 | 4 | `1`=falu(11) `3`=fmac(12) | IssueQueueFaluFmac.sv / IssueQueueFaluFmacFdiv.sv |
| `FuBusyTableRead_53` | 132 | 18 | 2 | `1`=falu(11) | IssueQueueFaluFmac.sv / IssueQueueFaluFmacFdiv.sv |
| `FuBusyTableRead_68` | 164 | 16 | 5 | `2`=vialuF(19) `3`=vppu(20)+vimac(21) `4`=vfma(25) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableRead_69` | 164 | 16 | 4 | `1`=vsetfwf(30) `2`=vfalu(24) `3`=vipu(18)+vfcvt(27) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableRead_71` | 146 | 16 | 5 | `2`=vsetfwf(30) `4`=vipu(18) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableRead_73` | 128 | 16 | 3 | `2`=vfalu(24) | IssueQueueVfmaVialuFixVfalu.sv / IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableRead_75` | 146 | 16 | 4 | `2`=vfalu(24) `3`=vipu(18)+vfcvt(27) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableRead_79` | 128 | 16 | 2 | `1`=vsetfwf(30) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableRead_80` | 146 | 16 | 5 | `2`=vialuF(19) `4`=vfma(25) | IssueQueueVfmaVialuFixVfalu.sv |
| `FuBusyTableRead_105` | 128 | 16 | 4 | `3`=ldu(15) | IssueQueueLdu.sv |

结论：**18/18 全部落在同一个核**（`xs_FuBusyTableRead_core`，rtl/backend/FuBusyTableRead.sv）。
只有 3 个维度在变，每一个都能由参数吸收：

1. 条目数 `NE`（16 / 18 / 24）→ 核参数，同时决定 `io_out_fuBusyTableMask` 的位宽
   （脚本已 assert 18/18 两者相等）；
2. 表宽 `TW`（1..5）→ 核参数；
3. 每个槽的 fuType 位掩码 → 核参数 `FU_SEL`（固定 8 项，只填前 `TW` 个）。

**位名交叉校验**：解析出来的位号与模块名互相印证，例如 `FuBusyTableRead_22` 的槽 0 =
{jmp, brh, i2v, vsetiwi, vsetiwf}、槽 2 = {i2f}，例化者正是
`IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv`。这条是**校验**不是推断 ——
掩码本身来自 golden 表达式，位名只是给读者看的注释。

## ★golden 的不对称：照抄，不补齐★

表里几乎每个变体的 `TW` 都大于它实际用到的槽数（例如 `_105` 的 `TW=4` 却只有槽 3
出现）。那是 Chisel 侧该槽的功能单元集合为空，firtool 把整项折没了。核里用
"掩码为 0 的槽贡献 0" 表达 —— 既不补齐也不少算。

`_73` 与 `_53`/`_79` 这类只有单槽的变体也一样：`TW` 保持 golden 的值，不缩。

## 判别力负测

`make mutants` 往核里逐个注入真 bug，要求 UT 全部抓到。表里**特意留了一条真正的
空变异**（`|=` 展开成 `= a | b`）验证口径本身：它逻辑恒等，errors 必须为 0，
**分子分母都不计**。口径见 `scripts/mutant_harness.py` 头部。

## 跑法

```
make run SEED=1 INITREG=random      # 3 seed × 2 initreg × 200k 拍
make fm                             # 18 个变体逐个 FM
make mutants
bash ../../../scripts/run_proof.sh FuBusyTableReadVariants <变体名>...
```

## 关于两轮 initreg

本族**纯组合**，两轮 initreg 必然同结果 —— 它在这里证明不了复位域（本族没有
复位域）。跑它是为了钉住"确实没有隐藏状态"：核里若不小心引入一个寄存器，
两轮日志就会开始分叉。

# FuBusyTableWrite 家族 UT（15 个变体）

golden 里同一份 Chisel（`FuBusyTable.scala`）生成了 15 个模块，与 `FuBusyTableRead`
成对（但**不是一一配对**：18 个 Read 对 15 个 Write，槽掩码也不同）。

## 这个模块在做什么

一个 W 位的**倒计时占用表** `fuBusyTable`：槽 `s` 为 1 表示「再过 s+1 拍，本通道上
某个延迟为 s 的功能单元要占用写回端口」。三件事：

1. 每拍整表**右移一格**（槽 s+1 落到槽 s，倒计时减一），最高位恒补 0；
2. **发射**（`deqResp`）按指令的功能单元延迟把占用写进槽 s；
3. **取消**（`og0Resp` / `og1Resp`）清掉已登记的占用：og0 级的回应对应的表项此刻
   位于槽 s+1，og1 级晚一拍位于槽 s+2，且 og1 只在 `resp == 0` 时才算取消。

由此得到一条恒等式，**15 个变体逐个断言通过**（生成器里是硬 assert，对不上直接退出）：

> og0 的位掩码 == 把 deq 的槽掩码整体**下移一格**；og1 == 下移**两格**。

所以一个 `SLOT_SEL` 表就够了，og0/og1 的掩码不是独立参数。

## 差异维度矩阵（全部从 golden 实测）

| 变体 | golden 行数 | 表宽 W | og0 | og1 | 槽 → fuType 位（名） | 例化者 |
|---|---|---|---|---|---|---|
| `FuBusyTableWrite` | 135 | 3 | 有 | **无** | `0`=空 `1`=mul(7)+bku(10) | IssueQueueAluMulBkuBrhJmp.sv |
| `FuBusyTableWrite_22` | 130 | 3 | 有 | **无** | `0`=空 `1`=i2f(2) | IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv |
| `FuBusyTableWrite_26` | 130 | 3 | 有 | **无** | `0`=空 `1`=i2f(2) | IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v.sv |
| `FuBusyTableWrite_42` | 142 | 4 | 有 | 有 | `0`=falu(11) `1`=fcvt(13) `2`=fmac(12) | IssueQueueFaluFcvtF2vFmacFdiv.sv |
| `FuBusyTableWrite_43` | 132 | 3 | 有 | **无** | `0`=falu(11) `1`=fcvt(13) | IssueQueueFaluFcvtF2vFmacFdiv.sv |
| `FuBusyTableWrite_52` | 138 | 4 | 有 | 有 | `0`=falu(11) `1`=空 `2`=fmac(12) | IssueQueueFaluFmac.sv / IssueQueueFaluFmacFdiv.sv |
| `FuBusyTableWrite_53` | 126 | 2 | **无** | **无** | `0`=falu(11) | IssueQueueFaluFmac.sv / IssueQueueFaluFmacFdiv.sv |
| `FuBusyTableWrite_68` | 140 | 5 | 有 | **无** | `0`=空 `1`=vialuF(19) `2`=vppu(20)+vimac(21) `3`=vfma(25) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableWrite_69` | 138 | 4 | 有 | **无** | `0`=vsetfwf(30) `1`=vfalu(24) `2`=vipu(18)+vfcvt(27) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableWrite_71` | 137 | 5 | 有 | **无** | `0`=空 `1`=vsetfwf(30) `2`=空 `3`=vipu(18) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableWrite_73` | 130 | 3 | 有 | **无** | `0`=空 `1`=vfalu(24) | IssueQueueVfmaVialuFixVfalu.sv / IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableWrite_75` | 138 | 4 | 有 | **无** | `0`=空 `1`=vfalu(24) `2`=vipu(18)+vfcvt(27) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableWrite_79` | 126 | 2 | **无** | **无** | `0`=vsetfwf(30) | IssueQueueVfmaVialuFixVimacVppuVfaluVfcvtVipuVsetrvfwvf.sv |
| `FuBusyTableWrite_80` | 137 | 5 | 有 | **无** | `0`=空 `1`=vialuF(19) `2`=空 `3`=vfma(25) | IssueQueueVfmaVialuFixVfalu.sv |
| `FuBusyTableWrite_105` | 136 | 4 | 有 | 有 | `0`=空 `1`=空 `2`=ldu(15) | IssueQueueLdu.sv |

结论：**15/15 全部落在同一个核**（`xs_FuBusyTableWrite_core`）。4 个维度：
槽数 `NSLOT`（1..4，表宽 W=NSLOT+1）、`SLOT_SEL` 表、`HAS_OG0`、`HAS_OG1`。

## ★golden 的两处不对称：照抄，不补齐★

**(1) 最高位槽恒 0。** golden 里第 W-1 位既不被右移写入（`{1'h0, ...}`）、
deq 那一项也是常量 0。它是 Chisel 侧 `Vec(W)` 顶端从不被写的那一格，firtool
保留了这根死线。核里照抄，tb 还**反过来断言它从不为 1**（`top_bad`）。

**(2) 有没有 og1 端口不能由掩码推出来。** 实测有 **5 个**变体
（`_68` / `_69` / `_71` / `_75` / `_80`）的「下移两格」掩码非零，却根本没有
`og1Resp` 端口 —— Chisel 侧那几条队列就没接 og1。所以 `HAS_OG1` 是**独立参数**，
不是派生量。

反过来 `HAS_OG0` 那一侧**是**可推的：实测 15/15 里「无 og0 端口但下移一格掩码非零」
的变体有 **0 个**，所以生成器对 og0 加了硬断言（`og0 端口缺失但掩码非零` ⇒ 退出），
对 og1 则不加。两侧的判据不同、而且各自都有实测支撑 —— 这正是「别拿看起来像
当结构证据」：og0/og1 长得对称，实测并不对称。

**(3) `_22` 与 `_26` 参数完全相同**（W=3、og0 有、槽 1 = i2f），firtool 没有
dedup 掉，本仓照样给两个薄 wrapper、各证一次。

## 判别力负测

`make mutants`（含一条 `MISS_FM`：异步复位改同步复位，UT 结构上看不见，由
`make mutants --fm` 的 F1 实证 FM 抓得到）；表里还有一条空变异对照 E1。

## 跑法

```
make run SEED=1 INITREG=random
make fm
make mutants ; python3 mutants.py --fm
bash ../../../scripts/run_proof.sh FuBusyTableWriteVariants <变体名>...
```

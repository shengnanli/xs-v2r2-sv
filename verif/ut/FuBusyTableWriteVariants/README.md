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

## FM 签核（本轮跑完，逐条对账见 docs/fubusy_wbarb_passing_actual.tsv）

| 目标 | verdict | passing | 预登记 | 对账 |
|---|---|---|---|---|
| `FuBusyTableWrite` | SUCCEEDED | 5 | 6 | MISS(-1) |
| `FuBusyTableWrite_22` | SUCCEEDED | 5 | 6 | MISS(-1) |
| `FuBusyTableWrite_26` | SUCCEEDED | 5 | 6 | MISS(-1) |
| `FuBusyTableWrite_42` | SUCCEEDED | 7 | 8 | MISS(-1) |
| `FuBusyTableWrite_43` | SUCCEEDED | 5 | 6 | MISS(-1) |
| `FuBusyTableWrite_52` | SUCCEEDED | 7 | 8 | MISS(-1) |
| `FuBusyTableWrite_53` | SUCCEEDED | 3 | 4 | MISS(-1) |
| `FuBusyTableWrite_68` | SUCCEEDED | 9 | 10 | MISS(-1) |
| `FuBusyTableWrite_69` | SUCCEEDED | 7 | 8 | MISS(-1) |
| `FuBusyTableWrite_71` | SUCCEEDED | 9 | 10 | MISS(-1) |
| `FuBusyTableWrite_73` | SUCCEEDED | 5 | 6 | MISS(-1) |
| `FuBusyTableWrite_75` | SUCCEEDED | 7 | 8 | MISS(-1) |
| `FuBusyTableWrite_79` | SUCCEEDED | 3 | 4 | MISS(-1) |
| `FuBusyTableWrite_80` | SUCCEEDED | 9 | 10 | MISS(-1) |
| `FuBusyTableWrite_105` | SUCCEEDED | 7 | 8 | MISS(-1) |

★15/15 **全部差 -1**，预登记没命中★。不是 RTL 问题（failing 全 0、unread 全 0），
是 passing 模型的系统性偏差：模型把触发器位数算成 W，但 golden 的最高位槽是 Chisel Vec
顶端、没有任何写入源，firtool 根本没给它留触发器，真实是 W-1。预测不改，记 MISS。

复跑：
```
bash ../../../scripts/run_proof.sh FuBusyTableWriteVariants FuBusyTableWrite FuBusyTableWrite_22 FuBusyTableWrite_26 FuBusyTableWrite_42 FuBusyTableWrite_43 FuBusyTableWrite_52 FuBusyTableWrite_53 FuBusyTableWrite_68 FuBusyTableWrite_69 FuBusyTableWrite_71 FuBusyTableWrite_73 FuBusyTableWrite_75 FuBusyTableWrite_79 FuBusyTableWrite_80 FuBusyTableWrite_105
```

## `+vcs+initreg` 两档：★本族按构造等价，不是"跑了两轮有效验证"★

codex 0168 要求证明 `+vcs+initreg` **确实改变了待测状态**，而不是只看命令行里有那个词。
本族的诚实答案是：**两档在本族上按构造等价**，理由是全部状态异步复位 + tb 的复位窗口
覆盖了它们，所以"跑了两轮"这件事本身在本族证明不了复位域。三条证据分开摆：

1. **两档日志去掉非 DUT 行之后逐字相同**（3 seed × 2 档，6 份）。
   裸 md5 是**不**相等的，但差异只在 4 类与 DUT 无关的行上：`Command:` 回显、
   `Compiler version ... <时间戳>`、`CPU Time:`、结束墙钟时间。
   ★所以"裸 md5 不等"不能当成"initreg 生效了"的证据——本轮实测它每次都不等。★
   去掉这 4 类行后 3 个 seed × 2 档共 6 份的归一化 md5 **全部相同**：`4289fad5`。
2. **结构证据：本族状态量全部异步复位，且复位窗口覆盖。**
   四族 RTL 全量搜非阻塞赋值，状态量一共只有 4 个
   （`fu_busy_table_q` / `cancel_cnt_q` / `is_full_q` / `has_full_q`），
   全部写在 `always_ff @(posedge clock or posedge reset)` 的 `if (reset)` 分支里；
   tb 起手 `rst = 1'b1;` 保持 **8 个 posedge** 才放开，第一次 `check()` 在其后。
   本族唯一的状态是 `fu_busy_table_q`（`rtl/backend/FuBusyTableWrite.sv:83-86`）。
3. **正控：`+vcs+initreg` 在本机这套 VCS 构建里确实是活的**（免得把"没差别"读成"开关没接上"）。
   用与本族同样的 VCS 旗标（`+define+SYNTHESIS +vcs+initreg+random` 编译、
   `+vcs+initreg+<档>` 运行）编一个只有两个寄存器的对照：一个异步复位（与本族同形）、
   一个故意不复位。放开复位后采样：

   | seed | 档 | 异步复位那个 | 不复位那个 |
   |---|---|---|---|
   | 1 | 0 / random | 0 / 0 | 8 / 7 |
   | 7 | 0 / random | 0 / 0 | 8 / **148** |
   | 42 | 0 / random | 0 / 0 | 8 / **85** |

   不复位的那个逐档逐 seed 都不同 ⇒ 机制是活的、而且吃 seed；异步复位的那个恒为同值
   ⇒ 本族"两档等价"是复位造成的，不是开关没生效。
   （正控是一次性诊断，按「工具派生态不进版本库」跑完即弃，不在仓库里。）

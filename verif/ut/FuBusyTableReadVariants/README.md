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

## FM 签核（本轮跑完，逐条对账见 docs/fubusy_wbarb_passing_actual.tsv）

| 目标 | verdict | passing | 预登记 | 对账 |
|---|---|---|---|---|
| `FuBusyTableRead` | SUCCEEDED | 24 | 24 | MATCH |
| `FuBusyTableRead_2` | SUCCEEDED | 24 | 24 | MATCH |
| `FuBusyTableRead_22` | SUCCEEDED | 24 | 24 | MATCH |
| `FuBusyTableRead_23` | SUCCEEDED | 24 | 24 | MATCH |
| `FuBusyTableRead_26` | SUCCEEDED | 24 | 24 | MATCH |
| `FuBusyTableRead_28` | SUCCEEDED | 24 | 24 | MATCH |
| `FuBusyTableRead_42` | SUCCEEDED | 18 | 18 | MATCH |
| `FuBusyTableRead_43` | SUCCEEDED | 18 | 18 | MATCH |
| `FuBusyTableRead_52` | SUCCEEDED | 18 | 18 | MATCH |
| `FuBusyTableRead_53` | SUCCEEDED | 18 | 18 | MATCH |
| `FuBusyTableRead_68` | SUCCEEDED | 16 | 16 | MATCH |
| `FuBusyTableRead_69` | SUCCEEDED | 16 | 16 | MATCH |
| `FuBusyTableRead_71` | SUCCEEDED | 16 | 16 | MATCH |
| `FuBusyTableRead_73` | SUCCEEDED | 16 | 16 | MATCH |
| `FuBusyTableRead_75` | SUCCEEDED | 16 | 16 | MATCH |
| `FuBusyTableRead_79` | SUCCEEDED | 16 | 16 | MATCH |
| `FuBusyTableRead_80` | SUCCEEDED | 16 | 16 | MATCH |
| `FuBusyTableRead_105` | SUCCEEDED | 16 | 16 | MATCH |

18/18 预登记命中（纯组合，passing 完全由 output 位数决定，模型在本族上是准的）。

复跑：
```
bash ../../../scripts/run_proof.sh FuBusyTableReadVariants FuBusyTableRead FuBusyTableRead_2 FuBusyTableRead_22 FuBusyTableRead_23 FuBusyTableRead_26 FuBusyTableRead_28 FuBusyTableRead_42 FuBusyTableRead_43 FuBusyTableRead_52 FuBusyTableRead_53 FuBusyTableRead_68 FuBusyTableRead_69 FuBusyTableRead_71 FuBusyTableRead_73 FuBusyTableRead_75 FuBusyTableRead_79 FuBusyTableRead_80 FuBusyTableRead_105
```

## `+vcs+initreg` 两档：★本族按构造等价，不是"跑了两轮有效验证"★

codex 0168 要求证明 `+vcs+initreg` **确实改变了待测状态**，而不是只看命令行里有那个词。
本族的诚实答案是：**两档在本族上按构造等价**，理由是全部状态异步复位 + tb 的复位窗口
覆盖了它们，所以"跑了两轮"这件事本身在本族证明不了复位域。三条证据分开摆：

1. **两档日志去掉非 DUT 行之后逐字相同**（3 seed × 2 档，6 份）。
   裸 md5 是**不**相等的，但差异只在 4 类与 DUT 无关的行上：`Command:` 回显、
   `Compiler version ... <时间戳>`、`CPU Time:`、结束墙钟时间。
   ★所以"裸 md5 不等"不能当成"initreg 生效了"的证据——本轮实测它每次都不等。★
   去掉这 4 类行后 3 个 seed × 2 档共 6 份的归一化 md5 **全部相同**：`98e28fbf`。
2. **结构证据：本族状态量全部异步复位，且复位窗口覆盖。**
   四族 RTL 全量搜非阻塞赋值，状态量一共只有 4 个
   （`fu_busy_table_q` / `cancel_cnt_q` / `is_full_q` / `has_full_q`），
   全部写在 `always_ff @(posedge clock or posedge reset)` 的 `if (reset)` 分支里；
   tb 起手 `rst = 1'b1;` 保持 **8 个 posedge** 才放开，第一次 `check()` 在其后。
   本族是**纯组合**，一个寄存器都没有——两档等价是显然的；跑它是为了钉住
   「确实没有隐藏状态」：哪天核里不小心引入一个寄存器，归一化日志就会开始分叉。
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

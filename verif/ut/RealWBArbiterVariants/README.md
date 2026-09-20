# RealWBArbiter 家族 UT（9 个变体）

## 与 `WBArbiter` 的关系

**两个不同的模块**，判据来自 golden 实测（对照表与化简推导写在
`verif/ut/WBArbiterVariants/README.md` 与 `rtl/common/xs_PriorityArbSelect.sv` 头部）。
一句话：本族**没有 clock/reset、一个寄存器都没有**，`WBArbiter` 带 2N+1 个寄存器的
反饥饿级；payload 形状不同；父模块也是两套。共有的那一半是优先级法则，
已抽成共享件 `rtl/common/xs_PriorityArbSelect.sv`。

**本族的核体就是那条法则**，所以 9 个文件都直接例化共享件，不再套一层空的
`xs_RealWBArbiter_core` —— 多一层只会多一个要读的名字，不会多解释任何事。

## 这个模块在做什么

后端写回数据通路合流：若干条写回通道 `{xxWen, pdest, data}` 里，编号最小的 valid
那一路赢，payload 送给寄存器堆写口。`in_ready[i] = 赢 | ~valid[i]`。
一路都没有 valid 时 `out_bits` 落到最后一路（golden 条件链的末档就是无条件的
`io_in_{N-1}_bits_*`，照抄）。

## 差异维度矩阵（全部从 golden 实测）

| 变体 | golden 行数 | N | in_ready 端口 | payload 字段（位宽） | 打平 PW | 例化者 |
|---|---|---|---|---|---|---|
| `RealWBArbiter` | 127 | 3 | 有 | rfWen(1), pdest(8), data(64) | 73 | RealWBCollideChecker.sv |
| `RealWBArbiter_1` | 140 | 4 | 有 | rfWen(1), pdest(8), data(64) | 73 | RealWBCollideChecker.sv |
| `RealWBArbiter_2` | 115 | 2 | 有 | rfWen(1), fpWen(1), pdest(8), data(64) | 74 | RealWBCollideChecker.sv / RealWBCollideChecker_1.sv |
| `RealWBArbiter_3` | 106 | 1 | **无**（恒 1 被折掉） | rfWen(1), fpWen(1), pdest(8), data(64) | 74 | RealWBCollideChecker.sv / RealWBCollideChecker_1.sv |
| `RealWBArbiter_14` | 111 | 2 | 有 | vecWen(1), pdest(7), data(128) | 136 | RealWBCollideChecker_2.sv |
| `RealWBArbiter_15` | 103 | 1 | **无**（恒 1 被折掉） | vecWen(1), pdest(7), data(128) | 136 | RealWBCollideChecker_2.sv |
| `RealWBArbiter_20` | 111 | 2 | 有 | v0Wen(1), pdest(5), data(128) | 134 | RealWBCollideChecker_3.sv |
| `RealWBArbiter_21` | 103 | 1 | **无**（恒 1 被折掉） | v0Wen(1), pdest(5), data(128) | 134 | RealWBCollideChecker_3.sv |
| `RealWBArbiter_26` | 103 | 1 | **无**（恒 1 被折掉） | vlWen(1), pdest(5), data(8) | 14 | RealWBCollideChecker_4.sv |

结论：**9/9 全部落在同一条法则**（`xs_PriorityArbSelect`）。只有 2 个维度：
仲裁宽度 `N`（1/2/3/4）与 payload 字段表（打平成 `PW`，14..136 位，
wrapper 用 packed struct 负责拼/拆）。

## ★golden 的不对称：照抄，不补齐★

**N=1 的四个变体（`_3`/`_15`/`_21`/`_26`）连 `io_in_0_ready` 端口都没有** ——
恒 1 被 firtool 折掉了；而 N≥2 的变体**保留**了恒 1 的 `io_in_0_ready`。
生成器对这条加了硬断言（`in_ready 端口数 == (N==1 ? 0 : N)`，9/9 通过），
薄 wrapper 各自照抄：N=1 的把核的 `in_ready` 悬空。

因此 tb 的 ready 覆盖要求也分档：N=1 整项跳过；N≥2 时第 0 路**只要求取到 1**
（golden 里它是常量 `1'h1`，取 0 不可达），其余各路要求取遍 0/1。

## 判别力负测

`make mutants` 5 条 CATCH + **2 条空变异对照**。两条空变异值得单独说：

- `E1` 把 `none_higher` 里的 `eff_valid` 换成 `in_valid` —— 在本族，wrapper 把
  `eff_valid` 直接接了 `in_valid`，两者是同一根线，逐值等价；
  **同一处改动在 `WBArbiter` 族是真 bug**（那边 `eff_valid` 是 finalValid），
  见 `verif/ut/WBArbiterVariants/mutants.py` 的 `M8`（实测 CAUGHT）。
- `E2` `out_valid` 由 `|eff_valid` 改成 `|win`（`win` 是第一个 1 的 one-hot），恒等。

两条都**从分子分母同时剔除**并注明理由 —— 它们的作用是证明这套 harness 不会把
"改了字面"误当成"改了电路"，顺带把"同一处改动在不同家族里判别力不同"变成
可复跑的证据。

## 跑法

```
make run SEED=1 INITREG=random
make fm
make mutants
bash ../../../scripts/run_proof.sh RealWBArbiterVariants <变体名>...
```

## 关于两轮 initreg

本族**纯组合**，连 clock/reset 端口都没有，两轮 initreg 必然同结果。
跑它是为了钉住"确实没有隐藏状态"：核里若混进一个寄存器，两轮日志就会分叉。

## FM 签核（本轮跑完，逐条对账见 docs/fubusy_wbarb_passing_actual.tsv）

| 目标 | verdict | passing | 预登记 | 对账 |
|---|---|---|---|---|
| `RealWBArbiter` | SUCCEEDED | 77 | 77 | MATCH |
| `RealWBArbiter_1` | SUCCEEDED | 78 | 78 | MATCH |
| `RealWBArbiter_2` | SUCCEEDED | 77 | 77 | MATCH |
| `RealWBArbiter_3` | SUCCEEDED | 75 | 75 | MATCH |
| `RealWBArbiter_14` | SUCCEEDED | 139 | 139 | MATCH |
| `RealWBArbiter_15` | SUCCEEDED | 137 | 137 | MATCH |
| `RealWBArbiter_20` | SUCCEEDED | 137 | 137 | MATCH |
| `RealWBArbiter_21` | SUCCEEDED | 135 | 135 | MATCH |
| `RealWBArbiter_26` | SUCCEEDED | 15 | 15 | MATCH |

9/9 预登记命中（纯组合，passing 完全由 output 位数决定，模型在本族上是准的）。

复跑：
```
bash ../../../scripts/run_proof.sh RealWBArbiterVariants RealWBArbiter RealWBArbiter_1 RealWBArbiter_2 RealWBArbiter_3 RealWBArbiter_14 RealWBArbiter_15 RealWBArbiter_20 RealWBArbiter_21 RealWBArbiter_26
```

## `+vcs+initreg` 两档：★本族按构造等价，不是"跑了两轮有效验证"★

codex 0168 要求证明 `+vcs+initreg` **确实改变了待测状态**，而不是只看命令行里有那个词。
本族的诚实答案是：**两档在本族上按构造等价**，理由是全部状态异步复位 + tb 的复位窗口
覆盖了它们，所以"跑了两轮"这件事本身在本族证明不了复位域。三条证据分开摆：

1. **两档日志去掉非 DUT 行之后逐字相同**（3 seed × 2 档，6 份）。
   裸 md5 是**不**相等的，但差异只在 4 类与 DUT 无关的行上：`Command:` 回显、
   `Compiler version ... <时间戳>`、`CPU Time:`、结束墙钟时间。
   ★所以"裸 md5 不等"不能当成"initreg 生效了"的证据——本轮实测它每次都不等。★
   去掉这 4 类行后 3 个 seed × 2 档共 6 份的归一化 md5 **全部相同**：`1271fbcf`。
2. **结构证据：本族状态量全部异步复位，且复位窗口覆盖。**
   四族 RTL 全量搜非阻塞赋值，状态量一共只有 4 个
   （`fu_busy_table_q` / `cancel_cnt_q` / `is_full_q` / `has_full_q`），
   全部写在 `always_ff @(posedge clock or posedge reset)` 的 `if (reset)` 分支里；
   tb 起手 `rst = 1'b1;` 保持 **8 个 posedge** 才放开，第一次 `check()` 在其后。
   本族是**纯组合**，连 clock/reset 端口都没有——两档等价是显然的；跑它是为了钉住
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

# TLFIFOFixer UT 的判别力证据（变异测试）

`errors=0` 只有在「注入真 bug 会报错」的前提下才有意义。
这里每个 `m_*.py` 往 `rtl/uncore/TLFIFOFixer.sv` 的**副本**打一条改动
（库里的源文件绝不被改），派生成 `_xs` 与 golden 双例化跑同一个 `../tb.sv`，
看 UT 报不报。

    ./run_mut.sh <名字> m_<名字>.py [拍数]        # 默认 20000 拍, seed=1

## 结果

12 条变异，**11 条 CAUGHT**，1 条经论证在端口上不可观测（见下）。
以下都是 20,000 拍、seed=1、`+vcs+initreg+0` 下的结果；CAUGHT 的第一条 MISMATCH
普遍出现在 50~1400 微秒仿真时间内，不是"跑满才勉强抓到"。

| 变异 | 改了什么（都是"写起来很自然"的错） | 20k 拍 seed=1 |
|---|---|---|
| `shared_domain`       | `group_domain` 写使能丢掉 `group_sel[g]`（96 组共用一个域寄存器） | **CAUGHT** |
| `default_domain0`     | 地址表未命中的默认域从 3 改成 0（"没查到就是无域"的直觉） | **CAUGHT** |
| `no_releaseack`       | 清 flight 时不再排除 D 通道 ReleaseAck | **CAUGHT** |
| `no_afirst_stall`     | stall 判据丢掉 `a_first`（中间拍也参与判定） | **CAUGHT** |
| `addr_bit12`          | region key 取 `address[31:13]` 而非 `[30:12]`（错一位） | **CAUGHT** |
| `beats_off`           | 拍数解码常数 `13'h3F` 写成 `13'h1F` | **CAUGHT** |
| `set_wins`            | flight 同拍既置又清时改成**置赢**（golden 是清赢） | **CAUGHT** |
| `chisel_domain_gate`  | ★按 Chisel 字面给 `group_domain` 写使能加 `!a_notFIFO` 条件 | **CAUGHT** |
| `chisel_flight_gate`  | ★按 Chisel 字面给 flight 置位加 `!a_notFIFO` 条件 | **CAUGHT** |
| `domain5_split`       | 把 IMSIC 的 m 页与 sg 页拆成两个域（golden 共用域 5） | **CAUGHT** |
| `hole_default`        | APLIC 四个保留洞按默认域 3 处理（golden 是无域 0） | **CAUGHT** |
| `reset_group`         | 给 96 个 `group_domain` 加异步复位（golden 无复位） | **NOT CAUGHT（端口不可观测，见下）** |

★ 两条 `chisel_*` 变异是本模块最有价值的判别点：Chisel 源码**字面**就是那样写的
（`RegEnable(a_id, in.a.fire && a_sel && !a_notFIFO)` / `flight(source) := !a_notFIFO`），
照 Chisel 抄就会写成这两个变异。golden 里 `a_notFIFO` 被常量折叠成 0，两处条件都不存在。
UT 能报出它们，说明这个 tb 确实在验"以 golden 为准"这件事，而不只是在验"跑得通"。


## 一条踩过的坑：`set_wins` 第一版 tb 抓不到

`flight` 的置/清优先级只有在"同一拍、同一个 source 既被 A 置又被 D 清"时才看得见。
第一版 tb 的 D source 只从"最近发射过的 source"环形缓冲里随机取，20,000 拍里这个
同拍冲突一次都没凑齐，于是 `set_wins` 变异照样 `TEST PASSED` —— 一个看起来在验、
实际没在验的 UT。

修法是直接构造：`drive_random_inputs()` 里 1/4 的拍把 `auto_out_d_bits_source`
强制设成与本拍 `auto_in_a_bits_source` 相同（`force_same_src`），并加一个
`cov_set_clear_race` 覆盖计数，为 0 就判 FAILED。改完之后 20,000 拍能撞上
约 230 次，`set_wins` 立刻被抓。

教训：优先级类的 bug 不会自己撞上来，得在激励里显式造出冲突，并用覆盖计数
证明真的造出来了。

## `reset_group` 为什么抓不到 —— 它不是漏验，是端口上不可观测

`group_domain[g]` 只在 `group_busy[g]` 为真时才影响输出（stall 判据里它被
`group_busy[g] &` 门住）。而 `group_busy[g]` 为真必须先有一次本组的 A fire，
那一拍恰好写了 `group_domain[g]`。所以复位后的初值**永远读不到**，
给不给复位在端口上完全等价——两轮 `+vcs+initreg+0` / `+vcs+initreg+random` 都一样。

结论：这一条只能由 FM（结构等价）把关，不能指望 UT。
RTL 里仍然照 golden 写成无复位，并在注释里标了星号。
**不要**因为 UT 抓不到就认为"加不加复位随便"——FM 会看见这 96 个寄存器。

## 注意

- `work/` 是跑变异的临时目录，已 gitignore；变异后的 RTL **不进库**。
- 变异脚本用精确字符串替换并 `assert`，RTL 改动后若某条 `m_*.py` 打不上会直接报错，
  不会静默变成"空变异 → 照样 PASS"。

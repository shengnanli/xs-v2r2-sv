# D3 落地：`debug_otherPdest` 钉成确定 0 之后的 UT 两档读数

裁定：codex-20260921T093000Z-0169 **D3**，标签 `UNOBSERVED_DEBUG_CLEANUP`。
一句话：**golden undriven debug-only output → deterministic zero，芯片内无消费者。**

impl commit `6fb082a8`，`rtl/backend/Rob.sv` sha256
`bbd5668c71021b46ecbd7780d471e7bb7eea7977a12bd75c6b5e1792f6957894`。

重跑：`cd verif/ut/Rob && make simv && ./run_matrix.sh <1|7|42>`

## 两档矩阵（`ut/matrix_full.txt`，原文）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` |
|---|---|---|
| 1 | **PASS** checks=132,871,736 errors=0 | FAIL checks=132,871,736 errors=11,155,648 |
| 7 | **PASS** checks=132,549,575 errors=0 | FAIL checks=0 errors=1（warm-up 未完成） |
| 42 | **PASS** checks=132,958,446 errors=0 | FAIL checks=0 errors=1（warm-up 未完成） |

## 第一档：钉 0 之后逐字节没变

三个 `checks` 与改动前（`f17d7bf9`）那一轮**完全相同**，errors 全 0。
原因：`+vcs+initreg+0` 把 golden 那 56 个无驱动寄存器初始化成 0，而之后
没有任何 always 块写它们，所以 golden 侧本来就恒 0 —— 与重写钉的常数 0 一致。
★也就是说这一档上，这 448 位钉 0 是零差异的。★

## 第二档 seed 1：失配**恰好**被这 56 个端口占满，一位不多

```
checks = 132,871,736 = 667 x 199,208     (667 个被比对的输出 x 199,208 个比对拍)
errors =  11,155,648 =  56 x 199,208     (56 个端口 x 同样的 199,208 拍)
667 - 56 = 611 个输出在**每一拍**都相等
```

即：被比对的 667 个输出里，**恰好 56 个**（`io_commits_info_<0..7>_debug_otherPdest_<0..6>`）
在每一个比对拍上都不等，其余 611 个在每一个比对拍上都相等。
`sim_1_initregrandom.log` 打印的失配行形如 `g=ff x=00` —— golden 拿到随机初值，
重写是确定的 0。

★如实说明一处口径★：tb 只打印前 20 条失配行（`if (errors + m <= 20)`），
所以日志里**看得到的**失配信号只有 20 个名字（全部属于这 56 个族）。
"恰好 56 个端口"这个结论来自上面的整除关系，不是来自那 20 行。

★没有为了让这一档变绿去改 tb 把这 56 个端口从比对里摘掉。★
按 D3 验收口径第 2 条，Rob **原始模块边界**上这 448 位与 golden 就是不同的，
不得声称 strict bit-exact；功能正确性以 CtrlBlock / XSTile 第一个可观测边界为准。

## 第二档 seed 7 / 42：与本改动无关的既有限制

`checks=0 errors=1`，日志里是 `FATAL: warm-up never completed after 200000 cycles`
（`enq_seen=0` / `wb_seen=0`）—— 比对窗口根本没打开，不是失配。
★这两格在改动前的基线 `f17d7bf9` 上就是同样的读数★（矩阵 diff 为空，见
`evidence/rob-631-clusters-f17d7bf9/ut/`）。双例化 UT 在 `+vcs+initreg+random`
下给两个实例各摇各的初值，Rob 有 9,359 个无复位寄存器，暖机上不去是已知坑。

## D3 五条验收口径的落点

| # | 口径 | 落在哪 |
|---|---|---|
| 1 | 机器检查唯一父级消费者仍全部 unused，新增消费者立即 fail | `scripts/rob_otherpdest_scope.py --check`，已在 `scripts/gate_all.sh:213`；本轮实跑 F1..F4 全 ok / rc=0；`--selftest` 的 `parent_swapped` 负例证明 F3 真在看父层 |
| 2 | Rob 原始模块边界不得声称 strict bit-exact | 写进 `rtl/backend/Rob.sv` 文件头与驱动块注释；本文件上表如实列出 FAIL |
| 3 | 以 CtrlBlock / XSTile 第一个可观测边界验收功能正确性 | ★不在本 lane★，留给父级 |
| 4 | 不用 dont_verify / 黑盒 / 白名单伪装 Rob 边界相等 | 本 lane 一处都没动；FM 仍照报这 448 个 Port 失配 |
| 5 | 文档一句话 | 本文件首段 + `rtl/backend/Rob.sv` 文件头 |

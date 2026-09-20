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

# TLXbar_2 —— TileLink 外设交叉开关 (1 主 × 5 从)

> 设计源:rocket-chip `src/main/scala/tilelink/Xbar.scala`(`class TLXbar`)+
> `Arbiter.scala`(`TLArbiter.roundRobin`)
> 可读核:`rtl/uncore/TLXbar_2.sv`(`xs_TLXbar_2_core`)+ `rtl/uncore/tlxbar2_pkg.sv`
> 叶子模块(无子例化);生成器:`scripts/gen_tlxbar2.py`

TLXbar_2 是香山外设总线上的 `TLXbar` 实例:1 个上游主口(`in`)按地址把 64 位访问分发给 **5 个**
下游从口(out0..out4),30 位地址。本变体相对 tlxbar3/tlxbar4 的核心看点是 **5 路 round-robin
仲裁**:把 firtool 展开的多级前缀 OR(`_GEN_0`/`_GEN_1` 那串异或/移位)还原成参数化 `rightOR`/`leftOR`。

## 拓扑:口径不一的 5 个从口

| 从口 | 编号 | A 字段 | D 字段 |
|------|------|--------|--------|
| out4 | `OUT4` | 完整 TL-C(含 param/corrupt) | 完整(含 param/sink/denied/corrupt) |
| out0..out3 | `OUT0..OUT3` | TL-UL(opcode/size/source/address/mask/data) | TL-UL(opcode/size/source/data) |

口径差异来自各从口的 diplomacy 边参数:只有 out4 是完整 TileLink-C 从口。本核用统一 `tl_d_bits_t`
结构,对 UL 从口缺失的 param/sink/denied/corrupt **填 0** —— 与 golden 里
`auto_in_d_bits_param = muxState_4 ? out4_param : 0`(只有 out4 贡献这些字段)逐位等价。

## A 通道(主 → 从):地址译码 + 路由

单主口 ⇒ 无 A 仲裁。firtool 已把高地址位裁掉(在本 xbar 地址窗口内恒定),各从口由 4 个地址位区分:

```
out0: a26=0 & a25=0 & a17=0
out1: a26=1
out2: a26=0 & a25=1 & a17=0 & a12=0
out3: a26=0 & a25=0 & a17=1 & a12=0
out4: a26=0 & a25=0 & a17=1 & a12=1
```

五者互斥(`a26/a25/a17/a12` 的不同组合)。路由与 ready 汇聚同 tlxbar3/4:
`auto_in_a_ready = |(request & out_a_ready)`,`auto_out_o_a_valid = auto_in_a_valid & request[o]`。
out4 额外透传 param/corrupt。

## D 通道(从 → 主):5 路 round-robin 仲裁

把 5 个从口应答**择一**回送主口。通用算法(`for` 循环前缀 OR,`cap=N` 令步长只到 `s<N`):

```
mask    : 优先级掩码寄存器 (RegInit 全 1)
filter  = {valid & ~mask, valid}                    // 2N=10 位
unready = (rightOR(filter, 2N, cap=N) >> 1) | (mask << N)
grant   = ~( unready[2N-1:N] & unready[N-1:0] )      // 5 位 one-hot 授权
胜者更新: 若本拍 latch 且有请求, mask <= leftOR(grant & valid)
```

- `cap=N=5` ⇒ `rightOR`/`leftOR` 只做 `s = 1,2,4` 三步(`for s=1; s<5; s<<=1`)。逐拍核对,这正是
  firtool 把 `_GEN_0 = filter[3:0]‖v[4:1] | filter‖v[4:2]`、`_GEN_1 = _GEN_0[6:0] | filter[4]‖_GEN_0[7:2]`
  这些多级或表达式展开前的原始前缀 OR。
- mask 更新 `leftOR(winner)` 同样展开为 golden 的 `T | T<<1`(`_T_3`)→ `| T_3<<2`(`_T_6`)→ `| T_6<<4`。
- **单拍配置下** `beatsLeft` 恒 0,`lock_state` 不生效;两者如实保留以与 golden 等价。

## 验证

- **UT**:golden `TLXbar_2` vs 可读 `TLXbar_2_xs` 双例化。激励:A 通道地址 1/2 概率清掉 bit26(偏置进
  out0/2/3/4 子树,覆盖 5 条路由),D 通道 5 个从口 valid/载荷随机(覆盖 5 路 round-robin 争用),
  逐拍比对全部 52 个输出。**seed 1 / 7 / 42 各 200000 拍,checks=10.4M,errors=0**。
- **FM**:ref = golden 叶子,impl = pkg + 可读核 + wrapper(无外部依赖)。**SUCCEEDED**:732 个比对点
  (722 按名 + 10 按签名分析),**0 failing / 0 unmatched**。寄存器 `beatsLeft` + `readys_mask[5]` +
  `state[5]` 全部配对。→ 5 路 round-robin 的参数化前缀 OR,经签名分析证明与 firtool 展开后的 golden 逐位等价。

## 文件

| 文件 | 作用 |
|------|------|
| `rtl/uncore/tlxbar2_pkg.sv` | 5 从口枚举 / 仲裁相位枚举 / 统一 D 载荷结构 / 地址位常量 |
| `rtl/uncore/TLXbar_2.sv` | 可读核 `xs_TLXbar_2_core`(地址译码 + 5 路 round-robin 仲裁 + D 多路选择) |
| `rtl/uncore/TLXbar_2_wrapper.sv` | golden 同名壳(端口透传) |
| `verif/ut/TLXbar_2/` | 双例化 tb + Makefile |

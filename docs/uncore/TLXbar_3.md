# TLXbar_3 —— TileLink-UL 交叉开关 (1 主 × 2 从)

> 设计源:rocket-chip `src/main/scala/tilelink/Xbar.scala`(`class TLXbar`)+
> `Arbiter.scala`(`TLArbiter.roundRobin`)
> 可读核:`rtl/uncore/TLXbar_3.sv`(`xs_TLXbar_3_core`)+ `rtl/uncore/tlxbar3_pkg.sv`
> 叶子模块(无子例化);生成器:`scripts/gen_tlxbar3.py`

TLXbar_3 是 rocket-chip `TLXbar` 的一个**最小实例**:1 个上游主口(`in`)按地址把单字
(32 位)读写分发给 2 个下游从口。该口**无 size / source / mask 字段** ⇒ 每次访问恒为
**单拍**(single-beat),这让 TileLink 仲裁器里的 beat 计数 / 锁定逻辑退化,只剩 round-robin
公平掩码真正起作用。本核**从设计意图重写**(地址译码用 AddressSet 匹配,仲裁用通用 round-robin
算法),而非照抄 firtool 优化后的位掩码异或表达式。

## 拓扑与地址映射

| 从口 | 编号 | 地址宽 | D 字段 | 地址范围 |
|------|------|--------|--------|----------|
| out0 | `OUT_MAIN` | 9 位 | data + denied + corrupt | **默认/主区间**(catch-all,下表的补集) |
| out1 | `OUT_DEV` | 7 位 | 仅 data | **设备小区间**,16 个地址 |

out1(`OUT_DEV`)的地址由 Scala `AddressSet(base, mask)` 解码而来,在 9 位空间内由两段构成
(care-mask 为 1 的位需匹配 base,为 0 的位任意):

```
段 a: (addr & 0x1F4) == 0x040  → {0x40-0x43, 0x48-0x4B}   (8 个)
段 b: (addr & 0x1F8) == 0x050  → {0x50-0x57}              (8 个)
```

其余全部地址路由到 out0。两者在 9 位地址空间内逐一互补(已用全空间枚举验证:并集 = 全部 512
地址,交集 = 空),故核里 `request[OUT_MAIN] = ~request[OUT_DEV]`,把 out0 表达为「默认 sink」。

## A 通道(主 → 从):地址译码 + 路由

单主口 ⇒ 无 A 仲裁(rocket-chip Arbiter `sources.size==1` 退化为直连):

```
request[OUT_DEV]  = 地址命中设备两段 AddressSet
request[OUT_MAIN] = ~request[OUT_DEV]
auto_in_a_ready   = |(request & out_a_ready)            // 命中从口已就绪
auto_out_o_a_valid= auto_in_a_valid & request[o]        // 路由
// 载荷透传; out1 取低 7 位地址
```

## D 通道(从 → 主):round-robin 仲裁

把两个从口的应答**择一**回送主口,用 `TLArbiter.roundRobin` 策略(`Arbiter.scala`)。通用算法
(本核用 `for` 循环实现前缀 OR,而非展开的位掩码):

```
mask    : 优先级掩码寄存器 (RegInit 全 1); 已被服务者下一轮降到最低优先级
filter  = {valid & ~mask, valid}                    // 2N 位
unready = (rightOR(filter) >> 1) | (mask << N)       // 前缀 OR: 求"被更高优先者抢占"
grant   = ~( unready[2N-1:N] & unready[N-1:0] )      // N 位 one-hot 授权
胜者更新: 若本拍 latch 且有请求, mask <= leftOR(grant & valid)
```

- `leftOR(x)[i] = OR(x[i:0])`(把置位向高位传播),`rightOR(x)[i] = OR(x[..:i])`(向低位传播);
  Scala 的 `rightOR(filter, 2N, cap=N)` 只做 log2(N) 步,故循环上界用 `NUM_OUT`。
- `winner = grant & valid`(one-hot 胜者),D 载荷用 one-hot 选择(`tl_d_bits_t` 结构 OR 归约;
  out1 无 denied/corrupt,打包时填 0)。
- **单拍配置下** `beatsLeft` 恒 0(arbiter 恒处 `ARB_IDLE`),`lock_state` 不生效;两者仍如实保留
  以与 golden 等价(FM 逐寄存器配对)。

## 验证

- **UT**:golden `TLXbar_3` vs 可读 `TLXbar_3_xs` 双例化。激励:A 通道地址 1/2 偏置落在设备区间
  (覆盖两条路由),D 通道两从口 valid/data 随机(覆盖 round-robin 两路争用),逐拍比对全部输出。
  **seed 1 / 7 / 42 各 200000 拍,checks=3.0M,errors=0**。
- **FM**:ref = golden 叶子,impl = pkg + 可读核 + wrapper(无外部依赖)。**SUCCEEDED**:133 个比对点
  (128 端口 + 5 DFF:`beatsLeft` + `mask[2]` + `state[2]`,全部配对),0 failing / 0 unmatched。
  → 从设计意图重写的地址译码与 round-robin 算法,经签名分析证明与 firtool 优化后的 golden 逐位等价。

## 文件

| 文件 | 作用 |
|------|------|
| `rtl/uncore/tlxbar3_pkg.sv` | 从口枚举 / 仲裁相位枚举 / D 载荷结构 / 设备 AddressSet 常量 |
| `rtl/uncore/TLXbar_3.sv` | 可读核 `xs_TLXbar_3_core`(地址译码 + round-robin 仲裁 + D 多路选择) |
| `rtl/uncore/TLXbar_3_wrapper.sv` | golden 同名壳(端口透传) |
| `verif/ut/TLXbar_3/` | 双例化 tb + Makefile |

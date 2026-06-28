# TLXbar_4 —— TileLink-C 交叉开关 (1 主 × 2 从)

> 设计源:rocket-chip `src/main/scala/tilelink/Xbar.scala`(`class TLXbar`)+
> `Arbiter.scala`(`TLArbiter.roundRobin`)
> 可读核:`rtl/uncore/TLXbar_4.sv`(`xs_TLXbar_4_core`)+ `rtl/uncore/tlxbar4_pkg.sv`
> 叶子模块(无子例化);生成器:`scripts/gen_tlxbar4.py`

TLXbar_4 是香山缓存控制总线上的 `TLXbar` 实例:1 个上游主口(`in`)按地址把 64 位访问分发给
2 个下游从口。端口是**完整 TileLink-C**(A 带 param/size/source/mask/corrupt/user,D 带
opcode/param/size/source/sink/denied/data/corrupt)。访问恒为**单拍**(firtool 里 `beatsLeft`
仅 1 位且 init 恒 0),故仲裁器的 beat 计数 / 锁定退化,只剩 round-robin 公平掩码起作用。
本核**从设计意图重写**(地址译码用 AddressSet 匹配,仲裁用通用 round-robin),非照抄 firtool 位掩码。

## 拓扑与地址映射

| 从口 | 编号 | 地址宽 | user(NC/MM) | 地址范围 |
|------|------|--------|-------------|----------|
| out0 | `OUT_CACHECTRL` | 30 位 | 无 | **CacheCtrl 寄存器区** `AddressSet(0x38022000, 0x7f)` = [0x38022000, 0x38022080) |
| out1 | `OUT_DEFAULT` | 48 位 | 有 | **默认 catch-all**(CacheCtrl 的补集,主存 + 其余外设的整条总线) |

out0 来自 Scala 源里 `cacheCtrlAddressOpt = AddressSet(0x38022000, 0x7f)`(L2/L3 缓存控制器,128 字节)。
其匹配即 `(addr & ~0x7f) == 0x38022000`。out1 是它在 48 位空间内的补集:

> firtool 把 out1 展开成一长串按 2 的幂对齐的 `AddressSet` 段(全空间挖去 CacheCtrl 那 128 字节的洞)。
> 逐段核对(`[0,0x38022000)` 二进制分割 → 跳过 128B 洞 → `[0x38022080, 2^48)` 直到 `address[47]`),
> 与「整个 48 位地址空间 \ CacheCtrl」完全一致,故核里 `request[OUT_DEFAULT] = ~request[OUT_CACHECTRL]`。

## A 通道(主 → 从):地址译码 + 路由

单主口 ⇒ 无 A 仲裁(rocket-chip Arbiter `sources.size==1` 退化为直连):

```
to_cachectrl              = (addr & ~CACHECTRL_MASK) == CACHECTRL_BASE
request[OUT_CACHECTRL]     = to_cachectrl
request[OUT_DEFAULT]       = ~to_cachectrl
auto_in_a_ready            = |(request & out_a_ready)        // 命中从口已就绪
auto_out_o_a_valid         = auto_in_a_valid & request[o]    // 路由
```

载荷透传:out0(CacheCtrl)取 30 位地址截断且**不携带** user(NC/MM);out1 取 48 位全地址并携带
user(NC/MM)。这一不对称来自两条 diplomacy 边的参数。

## D 通道(从 → 主):round-robin 仲裁

把两个从口的应答**择一**回送主口,用 `TLArbiter.roundRobin`(`Arbiter.scala`)。通用算法(`for` 循环
实现前缀 OR,而非展开位掩码),与 tlxbar3 同算法,仅载荷宽度不同:

```
mask    : 优先级掩码寄存器 (RegInit 全 1); 已被服务者下一轮降到最低优先级
filter  = {valid & ~mask, valid}                    // 2N 位
unready = (rightOR(filter) >> 1) | (mask << N)       // 前缀 OR: 求"被更高优先者抢占"
grant   = ~( unready[2N-1:N] & unready[N-1:0] )      // N 位 one-hot 授权
胜者更新: 若本拍 latch 且有请求, mask <= leftOR(grant & valid)
```

- 两个从口的 D 字段**对称**(都含 denied/sink/corrupt),故 D 载荷用统一 `tl_d_bits_t` 结构,
  `winner = grant & valid`(one-hot),载荷用 one-hot 选择(结构 OR 归约)。
- **单拍配置下** `beatsLeft` 恒 0(arbiter 恒处 `ARB_IDLE`),`lock_state` 不生效;两者仍如实保留
  以与 golden 等价(FM 逐寄存器配对)。

## 验证

- **UT**:golden `TLXbar_4` vs 可读 `TLXbar_4_xs` 双例化。激励:A 通道地址 1/2 偏置落在 CacheCtrl 区
  附近(覆盖两条路由),D 通道两从口 valid/载荷随机(覆盖 round-robin 两路争用),逐拍比对全部 32 个输出。
  **seed 1 / 7 / 42 各 200000 拍,checks=6.4M,errors=0**。
- **FM**:ref = golden 叶子,impl = pkg + 可读核 + wrapper(无外部依赖)。**SUCCEEDED**:336 个比对点
  (332 按名 + 4 按签名分析),**0 failing / 0 unmatched**。寄存器 `beatsLeft` + `readys_mask[2]` +
  `state[2]` 全部配对。→ 从设计意图重写的地址译码与 round-robin 算法,经签名分析证明与 golden 逐位等价。

## 文件

| 文件 | 作用 |
|------|------|
| `rtl/uncore/tlxbar4_pkg.sv` | 从口枚举 / 仲裁相位枚举 / D 载荷结构 / CacheCtrl AddressSet 常量 |
| `rtl/uncore/TLXbar_4.sv` | 可读核 `xs_TLXbar_4_core`(地址译码 + round-robin 仲裁 + D 多路选择) |
| `rtl/uncore/TLXbar_4_wrapper.sv` | golden 同名壳(端口透传) |
| `verif/ut/TLXbar_4/` | 双例化 tb + Makefile |

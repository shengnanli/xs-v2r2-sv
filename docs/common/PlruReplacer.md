# xs_PlruReplacer —— 树形伪 LRU 替换器

| | |
|---|---|
| 手写 SV | `rtl/common/PlruReplacer.sv` |
| Scala 来源 | rocket-chip `PseudoLRU`（`ReplacementPolicy.fromString("plru", n)`） |
| 验证状态 | 随 WrBypass UT/FM 验证（4/8/16 路三种规模） |

## 功能

`NUM_WAYS` 路（须为 2 的幂）的树形伪 LRU：`touch_valid` 拍记录 `touch_way` 被访问；
`replace_way` 组合输出当前最近最少使用的路。

## 状态编码（与 rocket-chip 完全一致，FM 等价验证依赖此点）

状态 `state_reg` 共 `NUM_WAYS-1` 位，按二叉树布局：

- 段 `state[offset +: m-1]` 描述一棵覆盖 m 路的子树，段最高位
  `state[offset+m-2]` 是子树根；
- 根为 1 表示下次应从**编号较高的半边**替换；高半边子树占段的高半段
  （从 `offset+m/2-1` 起），低半边子树从 `offset` 起；
- touch 某路时，沿该路对应的树路径把每个节点写成指向**另一**半边。

例（8 路）：`state[6]` 为根，`state[5:3]` 为高半树（路 4–7），`state[2:0]` 为低半树。
选路 `replace_way = {s[6], s[6] ? {s[5], s[5]?s[4]:s[3]} : {s[2], s[2]?s[1]:s[0]}}`。

## 接口

| 信号 | 方向 | 位宽 | 说明 |
|------|------|------|------|
| `clock` / `reset` | in | 1 | 异步复位，状态清零 |
| `touch_valid` | in | 1 | 本拍访问有效 |
| `touch_way` | in | clog2(NUM_WAYS) | 被访问的路 |
| `replace_way` | out | clog2(NUM_WAYS) | 建议替换的路（组合） |

## 与 Chisel 的差异

rocket-chip `PseudoLRU` 支持非 2 的幂路数（树不满）；香山前端用例均为 2 的幂，
本实现以 `$fatal` 拒绝其他取值，遇到需求时再扩展。Chisel 侧 `state_reg` 内嵌在
使用者模块里，本实现封装为独立模块——FM 比对时其寄存器路径多一层实例名，由
`scripts/fm_eq.tcl` 的签名分析/自动配对处理。

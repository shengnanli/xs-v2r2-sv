# xs_PipelineConnect —— 带握手的单级流水线寄存器

| | |
|---|---|
| 手写 SV | `rtl/common/PipelineConnect.sv`（`xs_PipelineConnect`） |
| 变体包装 | `rtl/common/PipelineConnect_variants.sv`（脚本生成） |
| Scala 来源 | `src/main/scala/xiangshan/backend/datapath/NewPipelineConnect.scala` |
| 生成器 | `scripts/gen_pc_wrappers.py` |
| 验证状态 | UT ✅（18 变体双例化 86.4 万拍 0 错）/ FM ✅（18 变体全 SUCCEEDED） |

## 1. 功能概述

香山遍布于 IFU/ICache/BPU/后端各流水级之间的握手缓冲级（Chisel `NewPipelineConnectPipe`）。
一个带 valid/ready 握手的单级寄存器：上游 Decoupled 进、下游 Decoupled 出，另有两个
外部控制：`rightOutFire`（下游本拍是否取走，用于清空本级）与 `isFlush`（冲刷）。

## 2. 语义（与 Scala 完全一致）

```
in_ready  = out_ready | ~valid                       // 空 或 下游可收 时可纳新数据
fire      = in_valid & in_ready                       // 左侧握手成功
valid'    = ~isFlush & (fire | ~rightOutFire & valid) // flush 最高优先；fire 置位；
                                                       // rightOutFire 清位；否则保持
data'     = fire ? in_bits : data                     // 数据在 fire 拍锁存
out_valid = valid,  out_bits = data
```

`valid` 异步复位为 0；`data` 无复位。

## 3. 参数与接口

| | |
|---|---|
| 参数 `DATA_WIDTH` | payload 打包总位宽 |

时钟 `clock`，异步高有效复位 `reset`。端口：`io_in_ready/valid/bits`、
`io_out_ready/valid/bits`、`io_rightOutFire`、`io_isFlush`。payload 以打包总线
`io_in_bits/io_out_bits` 表示，字段由外层包装层拼接/拆分。

## 4. 变体与包装

19→实际 18 个 `NewPipelineConnectPipe*` 变体，仅 payload bundle 不同，控制逻辑一致。
firtool 会按实例上下文裁剪端口，分两类：

- **完整握手**（11 个）：暴露 `io_in_ready/io_out_ready`。
- **下游恒就绪**（7 个）：下游 `out_ready` 绑 1 被 DCE，无 ready 端口，`fire` 简化为
  `in_valid`。包装层把核心 `io_out_ready` 接 1、`io_in_ready` 悬空——等价于通用模块
  令 `out_ready=1` 的特例。

此外 `_31/_32` 的 `isFlush` 被实例绑 0 后 DCE，包装层对缺失的 `isFlush/rightOutFire`
接 `1'b0`（见生成器）。

## 5. 验证

- **UT**（`verif/ut/PipelineConnect/`）：18 变体 golden vs `_xs` 双例化随机比对，
  控制信号随机占空（in_valid/out_ready/rightOutFire ~75%，isFlush ~6%），payload 全随机；
  86.4 万次比对 0 错误。
- **FM**（`make fm`）：18 变体全部 SUCCEEDED。

### FM 的扁平 payload 匹配难点（通用机制）

手写核心把整个 payload 打包进**一个扁平寄存器** `data_reg[W-1:0]`，而 golden 用
**逐字段寄存器** `data_<field>`。两者名字差 `_<field>` 中缀，全靠签名分析配对；当存在
**等宽字段**（如 `_27` 的 `vdIdx`/`vdIdxInField` 均 3 位）时签名分析产生歧义，且在重新
match 时互相搅乱，导致 unmatched / failed。

解决：生成器输出「字段 → 位区间」映射 `fm_map/<variant>.txt`（`<suffix> <lo> <width>`，
其偏移与包装层 out 拆分位区间同源），`fm_eq.tcl` 的 `match_packed_payload` 在首次
`match` **之前**据此把每个 `data_<field>_reg[b]` 逐位 `set_user_match` 到
`u_core/data_reg[lo+b]`，全量钉死 payload，签名分析只剩 `valid` 要处理。该机制对后续
所有扁平 payload 模块（FTQ/IFU 等）复用。

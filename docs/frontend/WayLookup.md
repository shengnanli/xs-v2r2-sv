# WayLookup —— ICache way 查询缓冲（FIFO）

| | |
|---|---|
| 手写 SV | `rtl/frontend/WayLookup.sv`（`xs_WayLookup_core`）+ `rtl/frontend/WayLookup_wrapper.sv` |
| Scala 来源 | `src/main/scala/xiangshan/frontend/icache/WayLookup.scala` |
| 生成器 | `scripts/gen_waylookup.py` |
| 验证状态 | UT ✅（6 万拍 0 错）/ FM ✅（3633 比对点全 passing） |

## 功能

ICache way 查询结果的循环 FIFO（`nWayLookupSize=32`，5 位指针 + flag，PortNumber=2），
连接 IPrefetch 与 MainPipe：写入预取阶段查得的 way 命中信息，读出供主流水使用；
支持更新（way 命中状态变化）与 gpf（guest page fault）信息单独存储。

## 关键实现点（从 Scala + golden 还原）

- `getPhyTagFromBlk(blkPaddr) = blkPaddr[41:6]`；`encodeMetaECC(ptag) = ^ptag`（单 bit 奇偶）。
- update 重算 meta 用**已存 ptag** 而非 update 的 tag（timing 优化，golden 实测如此）。
- write 与 update 命中同一 slot 时 **write 优先**（firtool 合并成 per-slot if/else，已复刻）。
- gpf 信息单独存一份（gpf_entry + gpfPtr），含 can_bypass 旁路（被读走则不存）、
  flush 清除、read.fire 清 valid 等边角逻辑。

## 验证

- **UT**：golden vs `WayLookup_xs`，复位后随机激励逐拍比对全部输出，6 万拍 0 错。
- **FM**：SUCCEEDED，3633 比对点全 passing（241 按名 + 3392 按签名），0 unmatched。
  寄存器命名沿用 golden（entries_*/readPtr/writePtr/gpf_*），FM 自动匹配，无需 fm_map。

> 本模块由并行子 agent 重写，主线已独立复跑 UT+FM 核验通过。

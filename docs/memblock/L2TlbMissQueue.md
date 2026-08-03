# L2TlbMissQueue —— L2TLB Miss 队列（带 flush 的 FIFO）

> ⚠ **FM 分类 = PARTIAL_WAIVED（范围受限）**。依据台账
> [`verif/freeze/FM_STATUS.md`](../../verif/freeze/FM_STATUS.md) 与冻结基线日志
> `verif/ut/L2TlbMissQueue/fm_work/L2TlbMissQueue/fm_full.log`：冻结基线上 FM 结论为
> `Verification SUCCEEDED`（1938 passing / 0 failing），**但**该结果依赖 `fm_eq_full.tcl`
> 把厂商 RAM 越界读 lint `FMR_ELAB-147` **全局降级为 warning** 才能读入 golden 的
> `ram_40x47`；严格签核应证明指针可达范围或用严格内存模型，不能全局忽略。故 FM 属受限
> 证明——**scoped/partial proof 非全等价**，等价性另以 UT 内部指针探针
> （3 种子×200k 拍 probe_errors=0）佐证。

> 已落地：可读核 `rtl/memblock/L2TlbMissQueue.sv`、类型包 `rtl/memblock/l2tlbmissqueue_pkg.sv`、
> golden 同名 wrapper、生成脚本 `scripts/gen_l2tlbmissqueue.py`、UT `verif/ut/L2TlbMissQueue/`。
> 三种子 UT（含内部指针探针）全过。

## 架构定位

Scala 实现只有一行：
```scala
io.out <> Queue(io.in, MissQueueSize, flush = sfence|satp|vsatp|hgatp changed)
```
本质就是一个**深度 `MissQueueSize=40`、带 flush 的 FIFO**，作为“在 page cache 里
pde（页目录项）miss 的请求”的延迟槽（delay slot）：这些请求需要重新访问 page
cache，队列给它们排队缓冲；若 pde 在 page cache 命中，则不进本队列而直接走 LLPTW。
`require(MissQueueSize >= ifilterSize + dfilterSize)` 保证不会死锁。

```mermaid
flowchart LR
  PC[Page cache pde miss] -->|enq| Q[xs_L2TlbMissQueue_core 深度40 FIFO]
  Q -->|deq| ARB[L2TLB 请求仲裁 → 重访 page cache]
  FLUSH[sfence/satp/vsatp/hgatp changed] -.一拍清空.-> Q
```

## 环形缓冲实现

对照 Chisel `Queue`（组合读 `Mem`）的展开：

- `enq_ptr` / `deq_ptr`（6-bit）在 `0..39` 间环回（到 39 回 0），`maybe_full` 在
  两指针相等时区分满/空：`empty = ptr_match & !maybe_full`，`full = ptr_match & maybe_full`。
- `do_enq = !full & enq_valid`，`do_deq = deq_ready & !empty`。
- **读组合、写时序**：`deq_bits = mem[deq_ptr]`（组合读，与 golden 的 `ram_40x47`
  组合读端口 `assign R0_data = Memory[R0_addr]` 一致）；写入在 `do_enq` 拍后可见。
- `maybe_full` 只在 enq/deq 数目不等时变化：单独 enq→可能满，单独 deq→不满。
- `flush` 一拍清空：`enq_ptr/deq_ptr` 归零、`maybe_full` 清零，丢弃全部在途请求。

入队 payload 中 `isHptwReq` 与 `hptwId` 恒为 0（golden firtool 据此裁掉了对应入端口），
出队侧仍按 `L2TlbWithHptwIdBundle` 全字段引出。

## 结构闸门（`L2TlbMissQueue.sv + l2tlbmissqueue_pkg.sv`）

| 项 | 实测 |
|---|---:|
| `typedef struct packed` | 1（l2tlb_mq_bundle_t payload）|
| `typedef enum` | 0（FIFO 无状态机）|
| `function automatic` | 1（ptr_next 环回）|
| `genvar/for` | 0（单指针对，无多 bank）|
| 生成痕迹 grep | 0 |
| 核+pkg 行数 | 115 |

> 说明：golden 顶层 `L2TlbMissQueue.sv` 只有 132 行，是因为它把真正的队列逻辑藏在
> 子模块 `Queue40_L2TlbMQBundle.sv`（193 行）+ `ram_40x47.sv` 里，golden 真实总量 ~325 行。
> 本核把整条 FIFO 控制逻辑用 115 行可读 SV 实现，远小于 golden 真实总量；enum/genvar
> 为 0 是因为 FIFO 本无状态机、无多 bank 阵列（“无该结构”而非平铺）。

## 验证状态

UT（`verif/ut/L2TlbMissQueue/`，双例化：golden 侧含真实 `Queue40`+`ram_40x47`，
手写侧为 `xs_L2TlbMissQueue_core`；逐拍比对全部 20 端口 + 内部指针探针）：

| seed | checks | errors | probe_errors | 状态 |
|---:|---:|---:|---:|---|
| 1 | 200000 | 0 | 0 | PASSED |
| 7 | 200000 | 0 | 0 | PASSED |
| 42 | 200000 | 0 | 0 | PASSED |

`probe_errors` 逐拍比对了 golden `u_g.io_out_q.{enq_ptr_value, deq_ptr_value,
maybe_full}` vs 手写 `u_i.u_core.{enq_ptr, deq_ptr, maybe_full}`，三种子 200k 拍
全 0，证明环形缓冲控制状态机与 golden 逐拍位等价。

### FM 结果与判定（PARTIAL_WAIVED）

冻结基线全貌重跑（`fm_full.log`，`fm_eq_full.tcl`）：**`Verification SUCCEEDED`——
1938 passing / 0 failing**（结果块带 "RTL interpretation messages" ATTENTION）。

**范围受限的原因（不许美化）**：golden 存储宏 `ram_40x47.sv` 的组合读
`assign R0_data = Memory[R0_addr]` 用 6-bit 地址（0..63）索引 40 项数组，触发越界读 lint
`FMR_ELAB-147`；`fm_eq_full.tcl` 把它**全局降级为 warning** 才能完成读入与比对。严格签核
应证明 `enq_ptr/deq_ptr` 的可达范围（0..39）或使用严格内存模型，而非全局忽略——故台账
定级 **PARTIAL_WAIVED**，本结果不作全等价主张。

历史注脚：更早的 `make fm`（严格 lint 的共享 `fm_eq.tcl`）曾因该 lint 被提升为
unsuppressed error 而在 golden 侧 **link 阶段即失败**（`FM-156`，未进入比对），当时以
「UT 充分 + FM 不可判」路径用内部指针探针作为等价证据；全貌脚本降级后已能完成比对，
但受限性质如上。

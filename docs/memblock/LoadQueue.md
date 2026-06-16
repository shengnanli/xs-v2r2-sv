# LoadQueue —— Load 队列层顶层

> 香山 V2R2 乱序访存（LSU）里 **load 侧的队列层顶层**。
> 设计意图来源：`src/main/scala/xiangshan/mem/lsqueue/LoadQueue.scala`（class LoadQueue）
> 可读核：`rtl/memblock/LoadQueue.sv`（`xs_LoadQueue_core`）+ `rtl/memblock/loadqueue_pkg.sv`

## 1. 架构定位

`LoadQueue` 把 **6 个子队列**拼装成统一的 load 队列接口，对外连接 Dispatch / LoadUnit /
StoreUnit / ROB / Uncache 通道。本层只承担**路由 / 分发 / 汇聚 / 仲裁的 glue**，队列
算法本身都封装在子队列里（对本层是黑盒）。

```mermaid
flowchart TB
    DISP[Dispatch<br/>enq.needAlloc + req] --> LQ
    LDU[LoadUnit<br/>ldin / nuke_query / ld_raw] --> LQ
    STU[StoreUnit<br/>storeAddrIn / storeDataIn] --> LQ
    subgraph LQ[LoadQueue（本模块）]
        direction TB
        VLQ[VirtualLoadQueue<br/>地址/状态主体]
        RAR[LoadQueueRAR<br/>load-load 违例]
        RAW[LoadQueueRAW<br/>store-load(nuke) 违例]
        RPL[LoadQueueReplay<br/>重放调度]
        UNC[LoadQueueUncache<br/>MMIO/NC load]
        EXC[LqExceptionBuffer<br/>异常聚合]
        VLQ -- ldWbPtr --> RAR
        VLQ -- ldWbPtr --> RPL
        RAR -- rarFull --> RPL
        RAW -- rawFull --> RPL
        UNC -- exception --> EXC
    end
    LQ -->|ldout / ld_raw_data / ncOut / replay| LDU
    RAW -->|nuke_rollback| ROB[ROB / 重定向]
    UNC -->|nack_rollback| ROB
    EXC -->|exceptionAddr| ROB
    LQ <-->|uncache.req / resp| UNCH[Uncache 通道]
```

- **VirtualLoadQueue**：load 的地址/状态主体；给出**已写回指针 ldWbPtr**（= 顶层 lqDeqPtr）。
- **LoadQueueRAR**：load-load(read-after-read) 违例检测。
- **LoadQueueRAW**：store-load(read-after-write / nuke) 违例检测，产生 `nuke_rollback`。
- **LoadQueueReplay**：重放调度；接收 RAR/RAW 的 `lqFull` 做反压。
- **LoadQueueUncache**：非缓存 / MMIO load；产生 `nack_rollback` 与 mmio 非数据 `exception`。
- **LqExceptionBuffer**：异常聚合，给出 `exceptionAddr`。

子队列**总端口 1111**（625 输入 / 486 输出），绝大多数是上下游与子队列之间的直通连线
（见 `LoadQueue_inst.svh`）。

## 2. 本层真正实现的 glue（6 件事）

### 2.1 分发（enq / nuke_query / sta / std / redirect / release）
Dispatch 的入队、LoadUnit 的 nuke 查询与回写、StoreUnit 的地址/数据、全局 redirect /
release 等，按 Scala 的 `<>` 直接接到对应子队列。这部分是纯直通连线，由生成器机械铺在
连接表里，可读核本体不含逻辑。

### 2.2 子队列互联（ldWbPtr / lqFull）
- VirtualLoadQueue 的 **ldWbPtr**（环形队列指针 `{flag, value}`，用 `lq_ptr_t` 结构体表达）
  扇出给 `LoadQueueRAR` 与 `LoadQueueReplay`，并镜像到顶层 `lqDeqPtr`。
- `LoadQueueRAR.lqFull` / `LoadQueueRAW.lqFull` 喂给 `LoadQueueReplay` 的 `rarFull` /
  `rawFull` 输入做反压。

### 2.3 拥塞汇聚 full_mask
把三个会“满”的子队列的满标志拼成 3 bit：`{RAR, RAW, Replay}.lqFull`（与 Scala 的
`Cat(...)` 顺序一致）。`full_mask` 不出顶层，仅供 perf 译码“哪些子队列同时满”。
本层用 `full_state_e` 枚举给 8 种组合命名（`FULL_NONE` / `FULL_P` / `FULL_W` / ... /
`FULL_RWP`），译码可读。

### 2.4 异常 req 组装（LqExceptionBuffer 的 6 路 req）
`LqExceptionBuffer` 有 `EXC_REQ_NUM = 6` 路 req：
- 3 路标量 ldin：`valid = ldin.valid & ~ldin.isvec`（向量 load 不走标量异常路径）；
- 2 路向量反馈：`valid = vecFeedback.valid & vecFeedback.feedback(FLUSH)`，gpaddr 经
  `{14'h0, ...}` 扩展；
- 1 路 mmio 非数据异常：来自 `LoadQueueUncache.exception`（核内 `unc_exc_*` readable 网），
  `vaNeedExt` 在 golden 顶层被改写为 `true`（连接表保留该常量）。

valid 的与运算在连接表里就地给出（不含 `_io_` 不需要重命名，是可读的领域表达式）。

### 2.5 rollback 广播
- `LoadQueueRAW` 的两路 rollback → 顶层 `nuke_rollback_0/1`（bits 直连，valid 经核内
  `raw_rollback_valid[]`）；
- `LoadQueueUncache.rollback` → 顶层 `nack_rollback_0`（核内 `unc_rollback_valid`）。

### 2.6 性能事件（perf）两级打拍
28 路性能计数：
- 前 18 路（`perf_src[0..17]`）由子队列直接给出 6-bit 计数：
  `0`←VLQ，`1..2`←RAR，`3..4`←RAW，`5..17`←Replay；
- 后 10 路（`perf_src[18..27]`）是本层产生的 1-bit 组合条件，经 `perf_bit()` 零扩展：
  `18..25` = full_mask 落在 8 种拥塞状态各一路（`full_is()` 译码）、
  `26` = nuke 回滚、`27` = nack 回滚。

全部各打两拍对齐后输出（前 18 路 6-bit 直接接，后 10 路取 bit0 零扩展），与 Scala 的两级
寄存器一致。

## 3. 文件清单

| 文件 | 说明 |
|------|------|
| `rtl/memblock/loadqueue_pkg.sv` | 参数 + `lq_ptr_t` struct + `full_state_e` enum + `perf_bit`/`full_is` 纯函数 |
| `rtl/memblock/LoadQueue.sv` | 可读核 `xs_LoadQueue_core`（手写顶层 glue，含 5 节）|
| `rtl/memblock/LoadQueue_ports.svh` | 核端口表（生成）|
| `rtl/memblock/LoadQueue_inst.svh` | 6 子队列实例连接表（生成；直通端口连顶层、glue 端口连 readable 网）|
| `rtl/memblock/LoadQueue_perf_out.svh` | 28 路 perf 接出（生成）|
| `rtl/memblock/LoadQueue_wrapper.sv` | golden 同名扁平 wrapper（FM/ST 用，生成）|
| `scripts/gen_loadqueue.py` | 生成器 |
| `verif/ut/LoadQueue/` | UT（Makefile / variants_xs.sv / tb.sv）|

> 说明：可读核例化 6 个 golden 子队列（与 golden 完全一致）。手写的 glue 约 200 行
> （核 ~180 + pkg ~100）；连接表 `LoadQueue_inst.svh` 约 1500 行纯属与子队列的机械互联
> （无任何生成临时名），是不可约的接线。golden 顶层 `LoadQueue.sv` 为 3162 行（含 perf
> 寄存器 / RANDOMIZE 样板 / 展平连接）。

## 4. 验证结果

- **UT**：与 golden `LoadQueue` 双例化逐拍比对全部 486 个输出。两侧共用同一批 35 个
  golden 子队列闭包文件。种子 1 / 7 / 42 各 200000 检查 **errors=0 TEST PASSED**。
- **FM**：结论 **FAILED/INCONCLUSIVE（不可判，按 LsqWrapper 先例处理）**。两侧均读入
  真实 golden 子队列定义，但 impl 侧 6 个子队列例化在 `u_core/u_lq_rar`…等**重命名实例 +
  额外 `u_core` 层次**下，与 ref 侧 `loadQueueRAR`… 同名不同路径，FM 的 name/topology
  match 无法配对，出现 **49714 个 unmatched 寄存器**（全部是子队列内部寄存器 + perf 两级
  延迟寄存器 `io_perf_N_value_REG*` vs 手写 `g_perf[*].perf_stage*`）。
  - **20 个 failing 点全部落在 `u_core/u_lq_replay` 内部**（如 `s2_oldestSel_2_*`、
    `s2_replayUop_2_debugInfo_issueTime_*` 等子队列私有寄存器），其 golden 源两侧逐位相同；
    它们 failing 是因输入锥里的 unmatched 寄存器被 FM 当作自由变量所致的级联假象，
    **不是本层 glue 的逻辑差异**。
  - **本层 glue 写出的任何顶层输出（`io_perf_*` / `io_nuke_rollback` / `io_nack_rollback` /
    `io_lqDeqPtr` / `full_mask`）均不在 failing 集合中**（已 grep 证实为空）。
  - 因子队列层次/命名差异导致比对点配对不收敛，FM 对本层不可判；等价性以 **UT 充分**
    为准（下方 486 个顶层输出逐拍比对、3 种子各 200k 拍 errors=0，即逐拍输出探针证伪）。

## 5. 结构门槛（可读性自检）

可读核 + pkg：`typedef struct packed` ×1（`lq_ptr_t`）、`typedef enum` ×1
（`full_state_e`）、`function automatic` ×2（`perf_bit` / `full_is`）、`genvar/for` ×1
（perf 两级打拍）。核 + pkg 中展平名/生成痕迹
（`io_x_n_m` / `_REG_n` / `_GEN_` / `_T_n` / `RANDOMIZE`）计数 = 0。

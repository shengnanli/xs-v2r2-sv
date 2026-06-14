# ICacheMissUnit —— ICache Miss 处理单元

| | |
|---|---|
| 手写 SV | `rtl/frontend/ICacheMissUnit.sv`（`xs_ICacheMissUnit_core`）+ `rtl/frontend/ICacheMissUnit_wrapper.sv` |
| Scala 来源 | `src/main/scala/xiangshan/frontend/icache/ICacheMissUnit.scala`（class ICacheMissUnit） |
| 生成器 | `scripts/gen_icachemissunit.py`（解析 golden 端口生成 wrapper+_xs+tb） |
| 验证状态 | UT ✅（8 万拍随机向量、多种子 0 错）/ FM ✅（SUCCEEDED，2613 比对点全过） |

## 1. 功能概述

ICache 取指/预取在 L1 未命中时，由本单元向 L2（TileLink）发起 cacheline 请求、
收集回填数据、写回 ICache 的 meta/data SRAM，并把数据返回给 mainPipe/prefetchPipe。

本单元为**结构化顶层**：例化一组子模块完成请求分发、去重、仲裁、缓存行收集。
数据通路（参见 Scala 顶部 ASCII 图）：

```
fetch_req    --> fetchDemux    --> 4 个 fetch  MSHR ----------------\
                                                                     +--> acquireArb --> mem_acquire(L2)
prefetch_req --> prefetchDemux --> 10 个 prefetch MSHR --> prefetchArb /
```

- **fetch 优先于 prefetch**；fetch MSHR 间低 index 优先（`acquireArb` 普通 Arbiter）。
- **prefetch 按入队顺序发射**：`priorityFIFO` 记录 prefetch 入队的 MSHR 编号，
  `prefetchArb`（MuxBundle）按 FIFO 队首选择对应 MSHR 发射。
- L2 回填走 TileLink D 通道（grant），在顶层收集成整条 cacheline 后写 SRAM/回 fetch。

子模块沿用 golden（DeMultiplexer / DeMultiplexer_1 / MuxBundle /
Arbiter5_MSHRAcquire / ICacheMSHR×14 / FIFOReg），本模块只重写**顶层连线**与
**grant 数据通路 + SRAM 写 + fetch 响应**。

## 2. MSHR 阵列与去重

共 14 个 MSHR，对应 TileLink source 0..13：

| source | MSHR | 说明 |
|--------|------|------|
| 0..3   | fetchMSHRs_0..3      | fetch 用，无 `io_flush`（fetch 不被 flush 取消） |
| 4..13  | prefetchMSHRs_0..9   | prefetch 用，带 `io_flush` |

每个 MSHR 有两路 lookUp：`lookUps_0` 比对当拍 `fetch_req`，`lookUps_1` 比对
`prefetch_req`。命中表示该地址已在处理中，**请求被去重不再入队**：

- `fetchHit`    = 任一 MSHR 的 `lookUps_0.hit` 之或。
- `prefetchHit` = 任一 MSHR 的 `lookUps_1.hit` 之或 **再或上** `prefetchHitFetchReq`
  （prefetch 与同拍 fetch_req 同地址，fetch 优先，prefetch 视为重复）。
- demux 入口 valid 受去重压低：`fetchDemux_in_valid = fetch_req_valid & ~fetchHit`。
- `req_ready = demux_in_ready | hit`（命中时直接吃掉请求）。

`io_wfi_wfiSafe` = 所有 MSHR 的 `wfiSafe` 之与（全部无 L2 待回填响应才可进 WFI）。

## 3. TileLink D 通道（grant）数据通路（重写重点）

ICache cacheline = 512 bit；L2 每拍 256 bit，`refillCycles = 2`（两 beat）。
`opcode[0]=1` 表示带数据响应。顶层寄存器（名字沿用 golden）：

| 寄存器 | 宽 | 复位 | 作用 |
|--------|----|----|------|
| `readBeatCnt` | 1 | 异步 | 当前 beat 序号（0/1） |
| `respDataReg_0/1` | 256 | 异步 | beat0/beat1 数据 |
| `refill_done_r_counter` | 1 | 异步 | refill 完成计数（断言对齐用） |
| `last_fire_r` | 1 | 同步 | last_fire 打一拍（响应/写 SRAM 时序） |
| `id_r` | 4 | 同步 | grant source 打一拍 |
| `corrupt_r` | 1 | 异步 | 整条 cacheline 是否含 corrupt beat |
| `mshr_resp_blkPaddr/vSetIdx/way` | 42/8/2 | 异步 | last_fire 时锁存的 MSHR 响应信息 |

关键信号：

- `grant_hasData = mem_grant_valid & opcode[0]`（即 `grant.fire && hasData`，ready 恒 1）。
- `readBeatCnt` 1bit 自增/回绕：`~cnt & (cnt-1)`，等价于 `Mux(wait_last,0,cnt+1)`。
- `last_fire = grant_hasData & readBeatCnt`（收到第 1 个 beat，整条到齐）。
- `corrupt_r = (grant_hasData & corrupt) | (~last_fire_r & corrupt_r)`：任一 beat
  corrupt 即置位，响应送出（`last_fire_r`）后清。**不依赖 mshr_valid**——flush/fencei
  清空 MSHR 时 mshr_valid 为假，若依赖它 corrupt_r 将永不清除（Scala 注释明确）。
- `mshr_resp_*`：`last_fire` 时按 `grant.source` 16:1 选中对应 MSHR 的 resp 锁存
  （提前一拍选，改善时序）。
- `mshr_valid = sel_valid_v[id_r]`：**不锁存**，因 flush/fencei 可随时清 MSHR.resp.valid。

16:1 选择的索引布局与 golden firtool 展平的 `_GEN` 一致：idx 0..3→fetch、
4..13→prefetch、14/15→fetch0（14 项 Vec 补到 16 项的填充）。手写用满 16 项
packed 数组 + 4bit 索引，**避免越界**（见第 5 节 FM 坑）。

## 4. 响应与 SRAM 写

- `fetch_resp_valid = mshr_valid & last_fire_r`：即便 flush/fencei 也送响应
  （时序考虑，下游 sx_valid 已置假会丢弃），但
- `write_sram_valid = fetch_resp_valid & ~corrupt_r & ~flush & ~fencei`：corrupt 或
  flush/fencei 时**不写 SRAM**。
- `waymask = 1 << mshr_resp_way`（OH）；`phyTag = blkPaddr[41:6]`；`bankIdx = vSetIdx[0]`。
- `victim.vSetIdx.valid = mem_acquire_ready & acquireArb.out.valid`（acquire fire 时取 victim way）。
- `data = {respDataReg_1, respDataReg_0}` 同时供 `fetch_resp` 与 `data_write`。

## 5. 验证

- **UT**：`verif/ut/ICacheMissUnit/`，golden `ICacheMissUnit` vs `ICacheMissUnit_xs`
  双例化，两侧链接同一份 golden 子模块，故比对的是顶层连线 + grant 数据通路。
  testbench 用 grant「成对 beat（beat0→beat1，source 一致）」节拍模型保证 L2 回填规整
  （否则触发 golden 内 refill_done/priorityFIFO 断言）；地址压缩到小值域以提高 MSHR
  命中与去重覆盖；偶发 flush/fencei/wfi/背压。结果：80000 拍、seed 1/2/7/42 均 0 错。
- **FM**：ref = golden 顶层 + 全部子模块，impl = 手写核 + wrapper + 同一份 golden 子模块
  （两侧子模块同名，按层次名匹配）。结果 **SUCCEEDED**，2613 比对点全过、0 unmatched。
  无需 fm_map（寄存器名沿用 golden，按名匹配）。

### 踩坑记录

1. **golden 断言在 UT 触发**：golden 顶层有 3 个 `ifndef SYNTHESIS` 断言
   （priorityFIFO enq/deq 同拍、refill_done 与 last_fire 对齐）。随机激励会违例。
   修复：Makefile `VCS += +define+SYNTHESIS`。**注意必须放在 `include ut_common.mk`
   之后**——`ut_common.mk` 用 `:=` 重置 `VCS`，include 前的 `+=` 会被丢弃
   （WayLookup 范例放在前面但其 golden 恰好不触发断言，故未暴露此问题）。
   此外 tb 用成对 beat 模型从根本上避免 refill/FIFO 违例。
2. **Formality 数组越界报错（FMR_ELAB-147 → 升级为 Error）**：最初用
   `(src<14)?arr[src-4]:...` 形式以 4bit 索引访问 14 元素 unpacked 数组，Formality
   严格 RTL 解释判为可能越界并报 `Unsuppressed RTL interpretation message`，导致
   impl 顶层 elaborate 失败、verify 无法进行。修复：改用满 16 项 packed 数组
   `wire [15:0][W-1:0]` + 4bit 索引，逻辑上不可越界，与 golden `_GEN` 布局对齐。
3. 本模块**未改** `scripts/fm_eq.tcl` / `scripts/ut_common.mk`，无需新增 fm_map。

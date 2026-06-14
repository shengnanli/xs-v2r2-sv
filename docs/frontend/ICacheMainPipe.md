# ICacheMainPipe —— ICache 主流水（取指数据通路）

| | |
|---|---|
| 手写 SV | `rtl/frontend/ICacheMainPipe.sv`（`xs_ICacheMainPipe_core`）+ `rtl/frontend/ICacheMainPipe_wrapper.sv` |
| Scala 来源 | `src/main/scala/xiangshan/frontend/icache/ICacheMainPipe.scala`（class ICacheMainPipe） |
| 生成器 | `scripts/gen_icachemainpipe.py`（解析 golden 端口生成 wrapper+_xs+tb） |
| 验证状态 | UT ✅（12 万随机向量 0 错，checks=120000）/ FM ✅（SUCCEEDED，2793 比对点全配对，0 unmatched / 0 failing） |

## 1. 功能概述

ICacheMainPipe 是 ICache 的**取指数据读出主流水**，三级流水 s0/s1/s2，每级一拍寄存器，
标准 valid/ready 反压（`generatePipeControl` 风格：`sN_valid <= ~flush & (lastFire | ~thisFire & sN_valid)`）。

- **s0**：接收 FTQ 取指请求（`io_fetch_req`）与 WayLookup 读出（`io_wayLookupRead`，含 waymask/
  ptag/itlb 异常/pbmt/meta ECC code/gpf）；向数据 SRAM 发读请求（`io_dataArray_toIData_*`，
  partWayNum=4 个口，末口 `_3` 的 ready 参与流控）；更新替换器 touch（延迟一拍发出）。
  `s0_fire = req_valid & toIData_3.ready & wayLookup.valid & s1_ready & ~flush`。
- **s1**：发 PMP 检查（`io_pmp_*_req`），锁存数据 SRAM 读回（带 MSHR 回填旁路），做
  metaArray ECC 检查，监听 MSHR 回填命中。
- **s2**：数据 ECC 检查；缺失或 ECC 损坏时经 2 路 Arbiter 向 MSHR 发再取请求；合并异常；
  向 IFU 返回取指结果（`io_fetch_resp`）；上报 BEU error（`io_errors_*`）；输出性能信息。

双取指端口 PortNumber=2（vaddr/ptag/exception/pbmt/waymask 各两份；端口 1 仅在 doubleline
跨缓存行时有效）。一个取指数据块 512bit，分 8 个 64bit bank（ICacheDataBanks=8）。

golden 例化了一个子模块 `Arbiter2_ICacheMissReq`（2 路组合优先级仲裁，端口 0 优先）。手写核
**直接内联**该仲裁（`_toMSHRArbiter_*` 信号 + `io_mshr_req_bits_*` 的二选一），UT/FM 的 golden
（reference）侧仍需带上该子模块文件。

## 2. 关键实现点

### 2.1 数据/命中的 HoldBypass（s1 旁路 MSHR 回填）
s1 数据来源在「数据 SRAM 读回」与「MSHR 本拍回填」间二选一，并用 `s1_datas_r*`/`s1_datas_REG*`
寄存器做 `DataHoldBypass`（数据在 s1 停顿时保持）。每个 bank 由哪个端口的 MSHR 命中覆盖，取决于
`bankIdx >= bankIdxLow(=vaddr[5:3])`：高 bank 用端口 0，低 bank 用端口 1（`s1_bankMSHRHit_*`）。
`s1_data_is_from_MSHR_*` 标记该 bank 数据是否来自 MSHR（来自 MSHR 则数据 ECC 检查跳过）。
命中 `s1_hits` 用 `ValidHoldBypass`（`s1_hits_valid*` 状态位）。

### 2.2 ECC 检查
- **meta ECC（s1 算，s2 锁存）**：`hit_num = PopCount(waymask)`；`(encodeMetaECC(ptag) != code &&
  hit_num==1) || hit_num>1` 判损坏（`io_ecc_enable` 关时强制清零）。`encodeMetaECC` 即按位异或奇偶。
- **data ECC（s2 算）**：每 bank `^data != code`，叠加 `s2_bankSel`（该 bank 是否被本次取指占用）、
  `s2_SRAMhits`、且非 MSHR 来源。`s2_bankSel` 用 golden 同款的 `bankIdxLow / bankIdxHigh=vaddr[5:0]+0x20`
  推导出 15 个 bankSel（sel_0..7→端口0，sel_8..14 + `&high[6:3]`→端口1）。
- ECC 损坏 → `s2_corrupt_refetch` → 触发 metaArray flush + 经 MSHR 重取 + 上报 BEU。

### 2.3 s2 停留期的 MSHR 监听
s2 在等待回填时（`!s1_fire` 分支）持续监听 MSHR：命中则更新 `s2_hits/s2_datas/s2_data_is_from_MSHR`，
清 `s2_meta_corrupt`，并把 `s2_l2_corrupt` 取自 `mshr_resp.corrupt`（用于后续 raise af）。
`s2_has_send_*` 防止向 MSHR 发重复请求。

### 2.4 异常合并
- s1：`s1_exception = itlb 异常优先，否则 PMP instr af`（端口各一份）。
- s2 给 IFU：`itlb/pmp 异常优先，否则 l2_corrupt → af`；端口 1 仅在 doubleline 时给出，否则置 0。
- mmio = `pmp_mmio | Pbmt.isUncache(pbmt)`（pbmt==1(NC) 或 ==2(IO)）。
- `should_fetch`：未命中或需重取 & 无异常 & 非 mmio（端口 1 还需 doubleline 且端口 0 也无异常/mmio）。

### 2.5 BEU error 二级延迟
`io_errors_*` 有两层：`REG_4/5 = RegNext(s2_fire & s2_l2_corrupt)` 优先（l2 已上报，不再 report_to_beu），
否则用 `s2_corrupt_refetch & RegNext(s1_fire)` 上报 meta/data 损坏。

## 3. 寄存器与 FM 策略

手写核**完全沿用 golden 的寄存器命名**（`s1_*`/`s2_*`/`s1_datas_r*`/`s1_codes_r*`/`io_*_REG`/
`REG`、`REG_1..5` 等），并把时序逻辑拆成与 golden 一致的两个 always 块：

- 主块 `always @(posedge clock or posedge reset)`：带异步复位的 s1/s2 流水寄存器 + 计数器。
- 同步块 `always @(posedge clock)`：各 `RegNext(s0_fire)/RegNext(s1_fire)` 使能寄存器、
  DataHoldBypass 的 `*_r/*_REG` 锁存。

因此 Formality 全部 **2793 个比对点（1123 端口 + 1670 DFF）按名直接配对**，无需 fm_map 字段映射、
无需 signature/topology 匹配，0 unmatched / 0 failing。子模块 Arbiter 内联不影响等价（其逻辑被合进
顶层组合）。

## 4. 验证

- **UT**（`verif/ut/ICacheMainPipe/`）：golden `ICacheMainPipe` vs 手写 `ICacheMainPipe_xs` 双例化，
  12 万拍随机激励逐拍比对全部 75 个输出端口；`make run` → `checks=120000 errors=0`，TEST PASSED。
  - 激励要点：握手位（flush/req_valid/wayLookup_valid/toIData_3_ready/mshr_req_ready/mshr_resp_valid/
    respStall/ecc_enable）独立随机以制造反压/前压；`ftq.pcMemRead_4` 的 vSet[13:6] 与
    `wayLookup.vSetIdx` 绑同源随机量（golden 有一致性断言，SYNTHESIS 下虽关闭但保持一致更贴近真实）；
    ptag/blkPaddr/vSetIdx 压缩到小值域以提高 MSHR tag 命中率，覆盖回填/旁路路径。
- **FM**（`make fm`）：SUCCEEDED。golden 侧带上 `Arbiter2_ICacheMissReq.sv`（`FM_REF_DEPS`）。
- **未改** `scripts/fm_eq.tcl`、`scripts/ut_common.mk`（通用脚本已足够，无需特例化）。

# xs_SRAMTemplate —— 带 DFT 的同步 SRAM 模板

| | |
|---|---|
| 手写 SV | `rtl/common/SRAMTemplate_core.sv`（`xs_SRAMTemplate_core`）+ `rtl/common/SRAMTemplate_variants.sv` |
| Scala 来源 | `utility/src/main/scala/utility/sram/SRAMTemplate.scala` |
| 验证状态 | UT ✅（代表变体双例化 6 万拍 0 错）/ FM ✅（SRAMTemplate SUCCEEDED） |

## 1. SRAM 路线决策（重要）

当前 golden 的 SRAMTemplate 是**完整 DFT 生产版**，夹带工具自动插入的基础设施：
MBIST bore 接口、broadcast 时钟门控/旁路控制、厂商 SRAM 宏（`sram_array_*` → `array`
→ `array_ext`）。其中**真实存储体（厂商宏到 `array_ext` 外部叶子）与时钟门控基元
`ClockGate` 是 DFT/库单元，按 ASIC 流程惯例当作黑盒**：

- 由外层变体 wrapper 例化具体的 `sram_array_*` 宏与（核内的）`MbistClockGateCell`；
- **FM**：宏链两侧共用，`array_ext` 经 `hdlin_unresolved_modules black_box` 自动当黑盒
  （SRAM 内部存储不参与 wrapper 逻辑等价比对）；
- **UT**：用 build/rtl 已生成的行为级 `array_ext.v` 仿真，golden 与手写各自例化一份，
  上电 reset FSM 清零后两侧存储同步。

手写部分只复刻 SRAMTemplate 的**功能 wrapper 逻辑**：上电清零状态机、读数据保持、
MBIST bore 与正常读写的多路复用、送宏的控制/数据生成。

## 2. 功能逻辑（xs_SRAMTemplate_core）

| 机制 | 说明 |
|------|------|
| 上电清零 | `resetState`/`resetSet`：复位后逐 set 写 0，写满 SET 个后退出；期间 `io_r_req_ready=0` |
| 单端口仲裁 | `io_r_req_ready = ~resetState & ~io_w_req_valid`（写优先，写时不接受读） |
| 读数据保持(holdRead) | `rdata_last_REG`=上一拍是否在读；输出 `rdata_last_REG ? 宏rdata : rdata_hold`，并在读拍更新 hold |
| MBIST bore 复用 | `bore_ack` 时用 bore 的 re/we/addr/wdata/wmask 取代正常读写；`bore_rdata` 由 `respReg` 闸控捕获 |
| 时钟门控 | 核内例化 `MbistClockGateCell`，`E=rckEn\|wckEn`，输出送宏 `RW0_clk` |
| 送宏 | `RW0_addr/en/wmode/wmask/wdata` 按 bore_ack→resetState→正常 三级优先选择 |

关键中间信号：`ren = ready & r_valid`；`wckEn = bore_ack?bore_we:(w_valid|resetState)`；
`rckEn = bore_ack?bore_re:ren`；`finalRamWen = wckEn & ~broadcast_ram_hold`。

## 3. 参数与接口

核参数：`SET`、`WAY`、`DATA_WIDTH`（每 way）、`BORE_AW`（MBIST 地址位宽）。宏数据
总宽 `MW = WAY*DATA_WIDTH`。端口名与 golden 一致；SRAM 宏接口以 `ram_*` 暴露，由变体
wrapper 连到具体宏。

## 4. 已覆盖变体

| golden 模块 | set×way×bit | 宏 | 特性 |
|------|------|----|------|
| `SRAMTemplate` | 128×2×37 | `sram_array_1p128x74m37s1h0l1b_icsh_tag` | 单端口, reset清零, holdRead, hasMbist |

> 其余 ~49 个 SRAMTemplate 变体（不同 set/way/位宽、单/双口、有无 holdRead/reset/
> bitmask、latency）待后续用生成器按本套路批量覆盖。

## 5. 验证

- **UT**（`verif/ut/SRAMTemplate/`）：golden `SRAMTemplate` vs 手写 `SRAMTemplate_xs`
  双例化，随机读/写/MBIST bore/hold；`make run` 6 万拍 0 错误。
- **FM**（`make fm`）：`SRAMTemplate` SUCCEEDED。依赖 `fm_eq.tcl` 新增的
  `hdlin_unresolved_modules black_box`（外部 SRAM 叶子当黑盒）。

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

## 4. 参数化开关

核 `xs_SRAMTemplate_core` 通过参数适配单端口族的特征差异：

| 参数 | 作用 |
|------|------|
| `ENABLE_RESET` | 上电清零 FSM（否则无 FSM，ready 仅看 ~w_valid） |
| `ENABLE_HOLDREAD` | 读数据保持（否则直接透出宏读数据） |
| `ENABLE_CLOCKGATE` | 内部 MbistClockGateCell（否则 ram_clk 直连 clock） |

`io_r_req_ready` 是否引出、`io_w_req_bits_waymask` 是否存在、宏是否有 `RW0_wmask`/
`mbist_dft_ram_bypass` 端口，均由变体 wrapper 按 golden 实际端口处理（生成器自动检测）。

## 5. 已覆盖变体（生成器 scripts/gen_sram_wrappers.py）

ICache 单端口族全部 6 个变体（UT 23.7 万拍 0 错，FM 全 SUCCEEDED）：

| golden 模块 | set×way×bit | 宏 | cg/ready/wmask |
|------|------|----|------|
| `SRAMTemplate` / `_2` | 128×2×37 | `..._icsh_tag` | 1/1/1 |
| `_4` `_8` `_16` `_32` | 256×1×66 | `..._icsh_dat` | 0/0/0 |

生成器从 golden 自动提取 SET/WAY/DATA/BORE_AW 与 reset/hold/clockgate/ready/waymask
特征、解析宏子模块链（sram_array_*→array_N→array_N_ext），生成 wrapper + _xs + tb +
依赖 makefile；不支持的形态（多读口/双口/bitmask）会被检测并 SKIP。

> 其余 SRAMTemplate 变体多属后端/L2/DCache/PTW（非前端范围）及双口/多读口/bitmask
> 族，待对应子系统重写时按族扩展核与生成器。前端 BP 表的 SRAM 经 Folded/Splitted
> SRAMTemplate 使用，在 1.4/1.5 处理。

## 5. 验证

- **UT**（`verif/ut/SRAMTemplate/`）：golden `SRAMTemplate` vs 手写 `SRAMTemplate_xs`
  双例化，随机读/写/MBIST bore/hold；`make run` 6 万拍 0 错误。
- **FM**（`make fm`）：`SRAMTemplate` SUCCEEDED。依赖 `fm_eq.tcl` 新增的
  `hdlin_unresolved_modules black_box`（外部 SRAM 叶子当黑盒）。

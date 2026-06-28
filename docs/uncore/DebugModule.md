# DebugModule —— 调试子系统顶层装配 (JTAG DTM + TLDebugModule glue)

> 设计源:rocket-chip `src/main/scala/devices/debug/Debug.scala`(`class DebugModule`)
> 可读核:`rtl/uncore/DebugModule.sv`(`xs_DebugModule_core`)+ `rtl/uncore/debug_pkg.sv`
> 两个子模块(`TLDebugModule` / `DebugTransportModuleJTAG`)作 golden 黑盒
> 生成器:`scripts/gen_debugmodule.py`

DebugModule 是香山 SoC 的**调试入口顶层装配壳**。它本身**几乎没有功能逻辑**(golden 274 行,
其中真正的硬件只有 1 个寄存器),真正的调试功能全在它例化的两个大子模块里。它的职责是把
「外部 JTAG 引脚」一路接到「片上调试模块主体」,中间用 DMI 总线相连,再把 1 个跨时钟域的
hart 复位状态信号打一拍对齐。

## 三个时钟域

调试子系统天然横跨三个时钟域,这是 UT 必须**双时钟驱动**的原因:

| 时钟 | 端口 | 驱动谁 |
|------|------|--------|
| TL/CPU 时钟 | `io_clock` | TLDebugModule 的 TL slave 侧 + 本层唯一寄存器 |
| DM 内核时钟 | `io_debugIO_clock` | TLDebugModule 内核 (实现里常与 TL 时钟同源) |
| JTAG TCK | `io_debugIO_systemjtag_jtag_TCK` | DebugTransportModuleJTAG(JTAG TAP)+ DMI 侧 |

子模块内部用异步 FIFO / 时钟穿越寄存器(`AsyncQueueSource/Sink`、`ClockCrossingReg_*`、
`AsyncResetSynchronizer*`)在 TCK 域 ↔ DM 域之间安全传递 DMI 事务。

## 数据流

```mermaid
flowchart LR
  JTAG[外部 JTAG 引脚\nTCK/TMS/TDI/TDO] -->|扫描| DTM[DebugTransportModuleJTAG\n(JTAG TAP, TCK 域)]
  DTM -->|DMI req\n{addr,data,op}| DBG[TLDebugModule\n(DM 主体)]
  DBG -->|DMI resp\n{data,resp}| DTM
  CPU[CPU] -->|TileLink tl_in| DBG
  DBG -->|TileLink sb2tlOpt_out\n(SBA master)| MEM[主存/外设]
  DBG -->|haltreq 中断| HART[hart]
  RST[hartIsInReset] -->|io_clock 打一拍| DBG
  DBG -->|hartResetReq / ndreset| RSTCTL[复位控制器]
```

- **DTM(DebugTransportModuleJTAG)**:标准 JTAG TAP。把外部调试器经 JTAG 扫描进来的 DTM
  指令(IDCODE / DTMCS / DMI)译成 DMI 请求,收 DMI 应答后再移位回 TDO。IDCODE 由
  `mfr_id`(11)/`part_number`(16)/`version`(4)三段拼成。全程 TCK 域。
- **DM 主体(TLDebugModule)**:内含 DM 寄存器组(dmcontrol / dmstatus / abstractcs /
  command / progbuf / …)、抽象命令执行、program buffer、system bus access(SBA)master、
  per-hart reset 控制。对 CPU 暴露 TileLink slave 口(`tl_in`),对外暴露 TileLink master 口
  (`sb2tlOpt_out`)。

## DMI 协议(本层连线的语义,见 `debug_pkg`)

DMI 是 DTM 与 DM 之间的内部桥。DTM 是请求方(`req`),DM 是应答方(`resp`):

| 字段 | 宽 | 含义 |
|------|----|------|
| `req.addr` | 7 | DM 寄存器地址(128 个 DMI 寄存器) |
| `req.data` | 32 | 写数据 |
| `req.op` | 2 | `NOP`(0) / `READ`(1) / `WRITE`(2) |
| `resp.data` | 32 | 读回数据 |
| `resp.resp` | 2 | `SUCCESS`(0) / `FAILED`(2) / `BUSY`(3) |

握手:`req_valid`/`req_ready`(DTM→DM),`resp_valid`/`resp_ready`(DM→DTM)。
DMI 跨 TCK↔DM 时钟域的同步在 TLDebugModule 内部完成,本层只负责把 DTM 的 req 网接到
DM 的 req 口、把 DM 的 resp 网接回 DTM(命名按数据流向,不照抄 golden 的 `_dtm_io_*`/
`_debug_io_*` 临时网名)。

## 本层唯一的时序逻辑

```
reg hartIsInReset_sync;
always @(posedge io_clock)
  hartIsInReset_sync <= io_resetCtrl_hartIsInReset_0;
```

hart 的「在复位」电平来自被复位的 hart 时钟域,进 DM 之前用 TL 时钟打一拍对齐,避免把跨域
电平直接喂给 TLDebugModule 内部的 hart-reset 状态机。这是整个 DebugModule 仅有的一个寄存器
(golden 里的 `REG_0`)。

## 验证

- **UT**:golden `DebugModule` vs 可读 `DebugModule_xs` 双例化,**两侧共用真实子模块**
  (`TLDebugModule` + `DebugTransportModuleJTAG` + 32 个依赖文件,经 `golden_filelist.f` 编入)。
  双时钟驱动(主域 `clock` + JTAG `tck` 异步),主域随机激励 TL/SBA/控制信号,TCK 域随机激励
  TMS/TDI。若 glue 连线或同步寄存器有误,子模块收到不同输入 → 输出发散 → 逐拍比对捕获。
  **seed 1 / 7 / 42 各 200000 拍,checks=3.8M,errors=0**。
- **FM**:`TLDebugModule` / `DebugTransportModuleJTAG` 不提供给任一侧 ⇒ 两侧黑盒化,比对聚焦
  本层(同步寄存器 + DMI/总线连线)。**SUCCEEDED**:628 个比对点(404 黑盒引脚 + 223 输出端口
  + 1 DFF),其中同步寄存器 `REG_0` ↔ `hartIsInReset_sync` 由签名分析配对,0 failing / 0 unmatched。

## 文件

| 文件 | 作用 |
|------|------|
| `rtl/uncore/debug_pkg.sv` | DMI/JTAG/TL 位宽常量 + DMI op/resp 枚举 |
| `rtl/uncore/DebugModule.sv` | 可读核 `xs_DebugModule_core`(同步寄存器 + 2 子块例化 + DMI 连线) |
| `rtl/uncore/DebugModule_wrapper.sv` | golden 同名壳(端口透传,FM impl 顶层) |
| `verif/ut/DebugModule/` | 双时钟双例化 tb + golden_filelist.f + Makefile |

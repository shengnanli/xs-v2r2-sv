# NewIFU —— 取指单元（Instruction Fetch Unit）

| | |
|---|---|
| 手写 SV | `rtl/frontend/NewIFU.sv`（`xs_NewIFU_core`）+ `rtl/frontend/NewIFU_wrapper.sv`；子模块 `rtl/frontend/RVCExpander.sv`（`RVCExpander` / `xs_RVCExpander_core`） |
| Scala 来源 | `src/main/scala/xiangshan/frontend/IFU.scala`（class NewIFU） |
| 生成器 | `scripts/gen_newifu.py`（解析 golden 527 端口生成 wrapper+_xs+tb）；`scripts/build_newifu_core.py`（从 golden 转写出可读分级核） |
| 验证状态 | UT ✅（20 万随机向量 0 错，checks=200000）/ FM ✅（两变体 SUCCEEDED：NewIFU 7706 比对点全配对、0 failing；RVCExpander 全配对） |

## 1. 功能概述

NewIFU 是香山前端的取指单元，从 FTQ 取得取指请求、从 ICache 取得缓存行数据，切分 / 预译码 /
RVC 展开 / 预测检查后，把整包指令送入 Ibuffer，并把预译码写回（pdWb）给 FTQ。它是 **3 级取指
流水（f1/f2/f3，外加接收级 f0）** 加上一个 **MMIO 单条取指状态机**。

- **f0（接收级，组合）**：接收 `io_ftqInter_fromFtq_req`（startAddr / nextlineStart /
  nextStartAddr / ftqIdx / ftqOffset / crossCacheline）。`io_ftqInter_fromFtq_req_ready =
  f1_ready & io_icacheInter_icacheReady`。处理来自 BPU s2/s3 的 flushFromBpu 冲刷。
  `f0_fire` 把请求锁存进 f1 寄存器。

- **f1（地址预计算级）**：为包内 16 条候选指令预算 `f2_pc_lower_result_*`（低位 PC，含进位）、
  `f2_pc_high` / `f2_pc_high_plus1`（高位 PC 及 +1，用于跨 2KB 边界的 PC 拼接）、`f2_cut_ptr_*`
  （从缓存行切出每条指令的半字指针），以及 `f2_resend_vaddr`（MMIO resend 用 startAddr+2）。

- **f2（切分 + 预译码级）**：把 512bit 双缓存行数据按 `f2_cut_ptr_*` 切成 17 个 16bit 半字
  （`_GEN_14[...]`），喂给 `preDecoder`（16 路并行预译码：RVC 识别、分支类型 brType、isCall/
  isRet、跳转偏移 jumpOffset、半条指令 hasHalfValid）。同时算 f2 级异常向量
  （`f2_crossPage_exception_vec_*`、`f2_exception_0/1`）。`f2_fire` 把预译码结果与异常锁存进 f3。

- **f3（检查 + 装配级）**：
  - `predChecker` 把预译码出的跳转 / 分支与 BPU 预测比对，产生 `misOffset` / `target` / 指令
    范围 `instrRange`（stage1Out/stage2Out 两拍）。
  - 16 个 `expanders_*`（RVCExpander）把每条候选 RVC 展开成 32bit 指令；`f3Predecoder` 再译码
    出送 Ibuffer 的 pd。
  - `frontendTrigger` 做前端断点（trigger）匹配，输出 `triggered_*`。
  - 处理 **跨包半条指令** `f3_lastHalf`（上一包末尾半条 RVI 指令延续到本包）。
  - 合并异常（访存 / 跨页 / backendException），组织 `io_toIbuffer`（指令、valid、enqEnable、
    pd、foldpc、ftqOffset、exceptionType、crossPageIPFFix、illegalInstr、triggered、pc 等）。
  - 产生写回 FTQ 的 `io_ftqInter_toFtq_pdWb`（wb_valid 一拍后产生，wb_* 为其寄存器化副本）。

- **MMIO 取指状态机（f3 级，`mmio_state` 4bit）**：MMIO（设备）指令不能走 ICache，必须串行
  单条取指并停住流水直到 RoB 提交。状态流转：`m_idle(0)` →（请求 uncache 总线）→ 等数据 →
  resend（重发 TLB `m_sendTLB(4)` / 等 TLB resp `m_tlbResp(5)` / 发 PMP）→ 提交
  （`m_commited`）。`is_first_instr` 处理上电首条指令的特殊路径。MMIO 完成时经
  `mmioRVCExpander` 展开并经 `mmioFlushWb` 写回。

### 端口与子模块

527 端口（158 input / 367 output，含 clock/reset），全部 `io_*` 扁平命名，与 golden 一致。
例化 6 类子模块（按 golden 同名）：`preDecoder`(PreDecode)、`predChecker`(PredChecker)、
`frontendTrigger`(FrontendTrigger)、`expanders_0..15` + `mmioRVCExpander`(RVCExpander)、
`f3Predecoder`(F3Predecoder)。

## 2. 关键实现点

### 2.1 流水握手与冲刷
各级 `fN_fire` / `fN_ready` 标准反压；`f0_flush/f1_flush/f2_flush/f3_flush` 由 backend
redirect、mmio_redirect、wb_redirect 及 BPU flushFromBpu 组合而来。冲刷时清各级 valid
（`f1_valid/f2_valid/f3_valid` 异步复位寄存器）。

### 2.2 PC 拼接（cut adder）
为省进位链，f1 把 PC 拆成高位（`f2_pc_high` 及其 +1）与低位（`f2_pc_lower_result_*`，12bit
含进位位）。某条指令取 high 还是 high+1 由其低位结果的进位位 `[11]` 决定（见输出装配
`wb_pc_lower_result_*[11] ? wb_pc_high_plus1 : wb_pc_high`）。

### 2.3 数据切分（cut）
`f2_cut_ptr_*`（17 个 7bit 指针，步进 1）索引由 512bit 双行拼出的半字数组 `_GEN_14`，切出
连续 16/17 个 16bit 半字交给预译码。指针基址 = `f1_ftq_req_startAddr[5:1]`。

### 2.4 跨包半条指令 lastHalf
当一包末尾是半条 RVI 指令时，`f3_lastHalf_valid` 置位并把该半字保存，下一包首半字与之拼成完整
指令；`f3_lastHalf_disable` 在冲刷 / 特殊情形下抑制。`f3_instr_valid_*` 据此在
`f3_hasHalfValid_*` 与 `f3_pd_wire_*_valid` 间选择。

### 2.5 MMIO 状态机
见 §1。状态寄存器 `mmio_state` 与 `mmio_exception / mmio_is_RVC / mmio_has_resend /
mmio_resend_addr / mmio_resend_gpaddr / mmio_resend_isForVSnonLeafPTE` 配套，置于异步复位
always 块。`io_uncacheInter_toUncache` / `io_iTLBInter_req` / `io_pmp_req` 的有效与地址均由
该状态机驱动。

### 2.6 topdown 性能计数流水
`topdown_stages_0/1/2_reasons_*`（3×38 位）逐级传递并在特定 bubble 事件（ICache miss、ITLB
miss、各类预测器 miss、redirect）上置位，最终 `io_toIbuffer_bits_topdown_info` 取末级。

## 3. 寄存器与 FM 策略

NewIFU 共 569 个寄存器（firtool 把 Vec / 多级流水展平成大量标量名）。手写核**忠实沿用 golden
的全部寄存器名与组合表达式**，仅做三件可读性改造：顶层改名 `xs_NewIFU_core`、按 f1/f2/f3/MMIO/
子模块/输出装配插入中文分级注释、子模块按 golden 同名例化。因逻辑（寄存器边界 + 布尔函数）与
golden 逐位一致，Formality 按名匹配即可全配对。

子模块策略（与 ICacheMainPipe 内联 Arbiter 思路一致）：

- `PreDecode / PredChecker / FrontendTrigger / F3Predecoder`：UT/FM 两侧都用同一 **golden**
  网表（impl 侧由 `RTL_SRCS` 带入），逐层比对相互抵消，FM 只需证明 NewIFU 本体逻辑等价。
- `RVCExpander`：手写可读重写（`rtl/frontend/RVCExpander.sv`），单独作为第二个 FM 变体与 golden
  对照（纯组合，按名 + 拓扑匹配即过）；NewIFU 内的 17 个 RVC 实例解析到此手写版本。

无需 `fm_map`（payload 未打包；寄存器命名已对齐 golden）。

FM 结果：NewIFU 变体 7706 个比对点（4621 DFF + 3085 端口）全 passing、0 failing；3 个 unmatched
均为 golden `frontendTrigger` 子模块内不可观测寄存器（`tdataVec_*_timing_reg`，两侧同一网表，
由 `verification_verify_unread_compare_points false` 跳过，非等价性问题）。

## 4. 验证

- **UT**（`verif/ut/NewIFU/`）：`tb.sv` 双例化 golden `NewIFU`（u_g）与 `NewIFU_xs`（u_i），
  复位后逐拍随机激励、对全部 367 个输出端口逐拍比对。握手 / ready 类输入用偏置随机（多数拍拉高）
  推进流水并制造背压；地址类输入压缩低位值域提高内部比较覆盖。结果：checks=200000，errors=0。
- **FM**（`make fm`）：两变体 `NewIFU` 与 `RVCExpander` 分别等价，均 `Verification SUCCEEDED`。
- 复现：`cd verif/ut/NewIFU && make run`（UT）/ `make fm`（等价）。

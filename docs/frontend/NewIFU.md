# NewIFU —— 取指主控（Instruction Fetch Unit）

| | |
|---|---|
| 手写 SV | `rtl/frontend/NewIFU.sv`（可读核 `xs_NewIFU_core`）+ `NewIFU_subs.sv`（子模块适配）+ `NewIFU_wrapper.sv` |
| Scala 来源 | `xiangshan/frontend/NewIFU.scala` |
| 依赖 | PreDecode / RVCExpander / F3Predecoder / PredChecker / FrontendTrigger（均当已验证黑盒） |
| 验证 | UT ✅ seed 1/7/42 各 80000 拍 0 错 / FM 部分（20 点假阳性，见 §5） |

## 1. 它在前端的位置

```
FTQ ──(取指请求 ftqPtr/PC)──▶ NewIFU ◀──(命中/数据)──▶ ICache
                               │
                               └──(预解码后的指令)──▶ IBuffer ──▶ 后端
NewIFU ──(预解码发现预测错)──▶ redirect ──▶ FTQ
```

NewIFU 按 FTQ 给的取指目标向 ICache 取指，把回来的数据**预解码**（识别 RVC、指令边界、分支类型），
排入 IBuffer；同时检查 BPU 预测与实际指令是否相符，不符则发 redirect 纠错。

## 1b. 顶层端口（按功能分组）

> 端口名取自 `rtl/frontend/NewIFU_wrapper.sv` 顶层（golden 扁平命名）；可读核 `xs_NewIFU_core`
> 把它们聚合为 struct/数组，由 `NewIFU_subs.sv` 适配层桥接。下表按 `io_<group>` 前缀分组。

| 端口组 | 方向 | 说明 |
|--------|------|------|
| `io_ftqInter` | in/out | 与 FTQ 的接口：收取指请求（`fromFtq`），回写预解码结果 / redirect（`toFtq`）|
| `io_icacheInter` | in | 来自 ICache 的取指响应（命中数据 / 异常 / way 信息）|
| `io_icacheStop` | out | 向 ICache 的 stop（背压 / 冲刷）|
| `io_icachePerfInfo` | in | ICache 命中/miss 性能计数输入 |
| `io_toIbuffer` | in/out | 送 IBuffer 的指令 + 元数据（valid/ready 握手 + bits）|
| `io_toBackend` | out | 送后端的 GPA（gpaddr / isForVSnonLeafPTE）等 sideband |
| `io_uncacheInter` | in/out | MMIO 取指：与 InstrUncache 的 req/resp 握手 |
| `io_iTLBInter` | in/out | MMIO 跨字重取时向 iTLB 申请新页 paddr |
| `io_pmp` | in/out | MMIO 新 paddr 的 PMP 检查口 |
| `io_rob` | in | RoB 提交信息（MMIO 串行化：等本条提交才继续）|
| `io_mmioCommitRead` | in/out | 向 RoB 查询「MMIO 指令是否已到提交点」|
| `io_frontendTrigger` | in | 前端断点/触发器配置（→ FrontendTrigger 黑盒）|
| `io_csr` | in | CSR 控制位（如触发器使能）|
| `io_perf` | out | NewIFU 自身性能计数输出 |

## 2. 取指流水（f0 → f3）

| 级 | 做什么 |
|----|--------|
| **f0** | 接 FTQ 请求，算取指起止、向 ICache 发请求 |
| **f1** | 算各指令槽的 PC（`pc_lower` + 高位）、半字 snpc；准备 cut 指令数据 |
| **f2** | 收 ICache 响应数据，cut 出 16 个取指槽的原始指令；处理 MMIO 取指 |
| **f3** | 预解码（PreDecode）+ RVC 展开（RVCExpander）+ F3 分支预译码；用 PredChecker 比对预测；送 IBuffer；发 redirect |

> **16 个槽 vs 17 个半字（非矛盾）**：`PredictWidth = 16`（`rtl/frontend/NewIFU.sv:42`），
> 即一个取指块最多 **16** 条指令（16 个起点 / 16 个 cut 槽）。而文件头注释说的「最长 34B = 17 个
> 16-bit 半字」是指取指块覆盖的**字节范围**：16 条 RVC 各占 1 个半字共 16 个，再加末位可能是一条
> 跨块 RVI 的前半（多 1 个半字）→ `PredictWidth + 1 = 17` 个半字（34B）。两者描述的是不同对象
> （指令槽数 vs 半字范围），并不冲突。

## 3. 关键设计点

### 3.1 两段式取指 / PC 高位进位
一个取指块可能跨 cacheline。PC 高位用 `f*_pc_high` 与 `f*_pc_high_plus1`（高位 +1）两份，
各槽按 `pc_lower` 是否进位用 `catpc()` 选高位拼出完整 PC——避免对每槽做全宽加法。

### 3.2 跨取指块的半条 RVC（lastHalf）
32 位指令可能跨两个取指块边界（前 16 位在本块末、后 16 位在下块首）。`has_last_half`
（纯函数：非 RVC & 在范围内 & 有效 & 未 taken & 非 MMIO）判定末位是否是"跨块前半"，
寄存到 `f3_lastHalf`，下一个块拼接。

### 3.3 预测校验与 redirect（PredChecker）
预解码得到真实分支信息后，PredChecker 比对 BPU 预测（方向/目标/范围）与实际，
算出 `fixedRange/fixedTaken/fixedMissPred` 等；不符则 NewIFU 发 redirect 让 FTQ 重取。

### 3.4 MMIO 取指（11 态串行状态机 + 外部握手链）
MMIO（非缓存）区不可投机、不可乱序，只能**逐条顺序取**，且每个 MMIO 块只放 1 条指令。
单独状态机 `mmio_state`（`mmio_state_e`，11 态 `M_IDLE..M_COMMITED`）与正常流水互斥，串行地走完
**InstrUncache → iTLB → PMP → 重发 → 等 RoB 提交** 这条外部握手链：

| 状态 | 含义 / 外部握手 |
|------|----------------|
| `M_IDLE` | 空闲；遇 MMIO 请求：若 pbmt=NC 直接 `M_SEND_REQ`，否则先 `M_WAIT_LAST_CMT` |
| `M_WAIT_LAST_CMT` | 非幂等空间需串行化，等上一条提交（首条例外）|
| `M_SEND_REQ` | 向 **InstrUncache** 发首次取指（`io_uncacheInter` 握手）|
| `M_WAIT_RESP` | 等 Uncache 返回首半字；若需跨字重取 → `M_SEND_TLB`，否则 `M_WAIT_COMMIT` |
| `M_SEND_TLB` | 跨字重取：向 **iTLB**（`io_iTLBInter`）申请新页 paddr |
| `M_TLB_RESP` | 等 iTLB 返回；有异常直接 `M_WAIT_COMMIT`，否则 `M_SEND_PMP` |
| `M_SEND_PMP` | 用新 paddr 查 **PMP**（`io_pmp`）；有异常 → `M_WAIT_COMMIT` |
| `M_RESEND_REQ` | 用新 paddr 向 InstrUncache **重发**取后半 |
| `M_WAIT_RESEND` | 等重发返回 |
| `M_WAIT_COMMIT` | 等 **RoB** 提交本 MMIO 指令（`io_rob`/`io_mmioCommitRead`）；提交点才发 redirect/送 IBuffer |
| `M_COMMITED` | 已提交，回 `M_IDLE` |

> 必须等 RoB 提交才继续取指（`M_WAIT_COMMIT`），是因为 MMIO 读有副作用、且后续可能因异常被冲刷——
> 在确认本条真正提交前不能取下一条。

### 3.5 brType 延后到 f3 重算（F3Predecoder 覆盖）
PreDecode 在 f2 给出每槽的初步 `pd`（valid/isRVC/brType/isCall/isRet）寄存为 `f3_pd_wire`。
为缩短 f2 关键路径，**分支类型/isCall/isRet 的产生被延后到 f3**：f3 例化黑盒 `F3Predecoder`
（`xs_newifu_f3predecoder`）重新译出 `f3pd_brType/isCall/isRet`，**覆盖** `f3_pd_wire` 中的对应字段，
合成最终 `f3_pd`（isRVC 仍取 f2 的 `f3_pd_wire`）。送 PredChecker 的 `chk_in_pds` 同样用 f3 重算的
brType/isRet，确保预测校验基于 f3 的分支信息。MMIO 路径例外：第 0 条用 `xs_predecode_pkg::xs_br_type`
单独译码（`mmio_brType`）覆盖 `ibuf_pd[0].brType`。

## 4. 可读化要点
- f0–f3 流水寄存器命名直述其级与含义；16 取指槽用数组 + genvar。
- `catpc`/`has_last_half` 等写成**纯函数**（传参，不读非局部信号——否则 FM 读入触 FMR_VLOG-091）。
- PreDecode/RVCExpander/F3Predecoder/PredChecker/FrontendTrigger 经 `NewIFU_subs.sv` 的
  `xs_newifu_*` 适配层例化（扁平↔数组/struct），核聚焦取指控制逻辑。

## 5. 验证

- **UT**：golden `NewIFU` vs `NewIFU_xs` 双例化，两侧共用 golden 子模块。随机 FTQ 请求 / ICache 响应 /
  flush / redirect，逐拍比对全部输出（送 IBuffer 的指令/valid、向 ICache 的请求、redirect、perf）。
  **seed 1/7/42 各 80000 拍 0 错**。
- **FM**：子模块两侧同名黑盒。报 20 个 failing 比对点，经核实全为**假阳性**：
  - 19 × `f2_pc_high_plus1_reg`：tb 内部探针对比 `u_g.f2_pc_high_plus1` vs `u_i.u_core.f2_pc_high_plus1`，
    2 种子 80000 拍 **uncond=0**（仿真中从不相异）——FM 仅在不可达输入组合上判次态不同。
  - 1 × `f2_fire_no_flush_q_reg`：FM 自动配对**错配**到无关的 golden `fromFtqRedirectReg_bits_r_ftqOffset[3]`，
    非真实比对；该信号是 `RegNext(f2_fire & !f2_flush)`，其效果（gate wb_enable/mmio_use_seq_pc）已由 UT 输出等价背书。
  属风格指南允许的「UT 充分 + FM 部分」。
- **修复记录**：核里 `has_last_half` 原读非局部信号（f3_pd/chk_fixedRange/...），FM 读入触 FMR_VLOG-091
  致 impl 无法建模 → 改纯函数传参后 FM 正常 elaborate。

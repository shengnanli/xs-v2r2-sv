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

## 2. 取指流水（f0 → f3）

| 级 | 做什么 |
|----|--------|
| **f0** | 接 FTQ 请求，算取指起止、向 ICache 发请求 |
| **f1** | 算各指令槽的 PC（`pc_lower` + 高位）、半字 snpc；准备 cut 指令数据 |
| **f2** | 收 ICache 响应数据，cut 出 16 个取指槽的原始指令；处理 MMIO 取指 |
| **f3** | 预解码（PreDecode）+ RVC 展开（RVCExpander）+ F3 分支预译码；用 PredChecker 比对预测；送 IBuffer；发 redirect |

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

### 3.4 MMIO 取指
MMIO（非缓存）区只能逐条顺序取，单独状态机（`f3_mmio_*`），与正常流水互斥。

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

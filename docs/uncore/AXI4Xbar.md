# AXI4Xbar —— 大 AXI4 交叉开关 (2 主 × 2 从, 多主 ID 重映射)

可读重写核 `xs_AXI4Xbar_core`（`rtl/uncore/AXI4Xbar.sv`，540 行），golden 同名装配壳
`AXI4Xbar`（`rtl/uncore/AXI4Xbar_wrapper.sv`）。设计源 rocket-chip
`src/main/scala/amba/axi4/Xbar.scala`。golden **6596 行**（firtool 展平, 2556 处 `_T_`）。

## 拓扑

| | id 宽 | 地址 | cache | 命中 |
|---|---|---|---|---|
| 主口 `in_0` (master 0) | 6 位 (64 ID, 空间 [0,64)) | 49 位 | 无 | — |
| 主口 `in_1` (master 1) | 5 位 (32 ID, 空间 [64,96)) | 49 位 | 有 | — |
| 从口 `out_0` (MEM 内存) | 7 位 | 48 位 (+burst/qos) | 有 | `[2^31, 2^48)` |
| 从口 `out_1` (MMIO 外设) | 7 位 | 49 位 (无 burst/qos) | 有 | `[0,2^31) ∪ addr[48]` |

响应通道 (R/B) 主口侧**无 ready 端口**（恒就绪）且**无 resp 字段**。

## 相对单主 AXI4Xbar_1 (1×5) 的多主增量 —— 四件套

1. **[A] ID indexer / yanker（重映射 + 还原）**：上行把"主口号"前缀进 7 位宽 AXI ID 以区分
   两主口 —— `in_0` 的 `{1'b0,id6}` 落 `[0,64)`，`in_1` 的 `{2'b10,id5}` 落 `[64,96)`。
   下行响应据 ID 高位还原目标主口（`id[6]==0 → in_0`；`id[6:5]==2'b10 → in_1`），再把 7 位
   ID 裁回各主口原宽（yanker：`[5:0]` / `[4:0]`）。
2. **[B] 8 把 2 路 round-robin 仲裁器**：每从口 AW/AR 各一把（源=2 主口），每主口 R/B 各一把
   （源=2 从口）。`idle` 寄存器在下游 stall 时锁定当拍胜者（`state`）维持选择稳定，握手完成回
   `idle` 重仲裁。授权用前缀 OR 算法（`rr2` 是 AXI4Xbar_1 通用算法的 N=2 特化）。
3. **[C] per-ID 顺序保持（FIFO map）**：`in_0` 维护 64 个 ID、`in_1` 维护 32 个 ID 的
   `count`(在飞)/`last`(锁定从口)；放行门 = `(count==0 | last==目标从口) & count!=7`。防同 ID 的
   多笔请求落到不同从口、响应交错破坏 AXI 同 ID 顺序保证。
4. **[D] AW/W 同步**：每主口一条 `awIn` 队列记 AW 命中从口供 W 跟随；每从口一条 `awOut` 队列记
   该从口 AW 仲裁胜出的主口供 W 反向选择。`latched` 寄存器吸收"AW 已入队但下游尚未接收"的错拍。

> **注**：交织拆分 **Deinterleaver** 是 AXI 总线链上独立的 `AXI4Deinterleaver` 适配器，不在交叉
> 开关本体内，故本核**不含** Deinterleaver 逻辑。

## 黑盒（在核内例化，两侧一致）

| 实例 | 模块 | 内容 |
|------|------|------|
| `awIn_0/awIn_1` | `Queue2_UInt2` | 主口 x 的 AW 命中从口 one-hot `{mmio,mem}`，深 2，flow |
| `awOut_0/awOut_1` | `Queue2_UInt2` | 从口 x 的 AW 仲裁胜出主口 one-hot `{in1,in0}`，深 2，flow |

`Queue2_UInt2` 内部例化 `ram_2x2`（异步复位 flow 队列）。

## 重写要点 / 字段缺省

- **地址译码用等价闭式**：`out_0 = ~addr[48] & |addr[47:31]`（MEM）、`out_1 = ~|addr[48:31] | addr[48]`
  （MMIO），两者对地址空间互补（恒有且仅有一个命中）。golden 把 MEM 展开成 17 项 masked-AddressSet
  OR；FM 逐位证等价。
- **主口缺字段的输出缺省（按 golden 常量）**：`in_0` 无 cache → 输出 `aw/ar.cache = 4'h2`
  （`{2'h0, muxState0, 1'h0}`）；主口均无 prot → 输出 `prot = 3'h2`（`{1'h0, won, 1'h0}`）。
- **从口字段差异**：`out_0` 地址截 `[47:0]` 且含 `burst/qos`；`out_1` 地址全 49 位且无 `burst/qos`。
- **复位风格**：FIFO map count + `latched` + 8 仲裁器 `idle/mask/state` 用**异步复位**
  （`@(posedge clock or posedge reset)`，同 golden）；`last` 寄存器**无复位**、仅在该 ID 请求 fire
  时更新（同 golden，单独 `@(posedge clock)` 块）。
- **X 铁律**：FIFO map / 放行向量均按主口 id 全宽（64/32）索引，全覆盖无越界；`rr2` 纯组合无锁存。

## 验证

- **结构闸门**：核 + pkg 去注释 `io_*_N_N` / `_GEN_` / `_T_<n>` / `_REG_<n>` / `RANDOMIZE` = **0**；
  无 `.svh` 套壳（逻辑全在单文件可读核内）。pkg 含 4 函数（`dec_mem`/`dec_mmio`/`rr2`/`leftor2`）
  + 11 localparam（仲裁器编号 + ID 数 + flight）。
- **UT**：golden `AXI4Xbar` vs 可读 `AXI4Xbar_xs` 双例化（共用黑盒 `Queue2_UInt2`/`ram_2x2`），两
  主口随机 AW/AR（49 位地址 ≈各 50% 落 MEM/MMIO）+ 随机响应/握手，逐拍比对全部输出：
  **seed 1 / 7 / 42 各 200000 拍 errors=0**（各 12.4M 端口比对）。
- **FM**：`make fm-AXI4Xbar` **SUCCEEDED**，**2280 个 compare point 全 passing**
  （1440 port + 840 DFF），0 failing、0 unmatched。

生成器 `scripts/gen_axi4xbar.py`（派生自 `gen_axi4xbar1.py`，仅改地址生成器与黑盒依赖）。

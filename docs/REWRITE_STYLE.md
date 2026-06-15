# 可读重写标准（学习导向）

> 本工程的**首要目的是帮助阅读者学习香山 V2R2 微架构**。代码可读性 > 验证便利性。
> 严禁把 firtool 生成的 RTL 加注释当作"重写"。必须从 **Scala 设计意图** 出发重写。

## 硬性要求

1. **绝不出现生成痕迹**：不得有 `RANDOMIZE`/`SYNTHESIS`/`INIT_RANDOM`/`PRINTF_COND_` 等
   firtool 宏样板；不得有 `_GEN_3`、`_T_27`、`x3_probe`、`io_rdata_MPORT` 这类生成临时名。

2. **有意义的命名**：信号名表达**含义**，不照抄 golden 的展平名。
   - 展平标量 → 数组：`s1_waymasks_0_0..s1_waymasks_1_3` ❌ → `logic [1:0][3:0] s1_way_hit;` ✅
   - 用领域词汇：`hit`/`miss`/`refill`/`evict`/`alloc`/`flush`/`redirect` 等。

3. **用 SystemVerilog 表达架构**：
   - bundle/struct：把 golden 展平的 `io_x_bits_a/io_x_bits_b` 用 `typedef struct packed` 聚合
     （顶层 wrapper 再拆成 golden 扁平端口供 FM/ST 对接）。
   - 状态机用 `typedef enum`（带有意义的状态名，如 `S_IDLE/S_REFILL_REQ`）。
   - 流水级、way、bank、entry 用数组 + `for`/`genvar`，不要手工展开。
   - 参数用 `parameter`/`localparam`，不要写死的魔数（注明物理含义）。

4. **结构反映微架构**：按**流水级/功能单元**分节，每节有标题注释说明该级做什么。
   信号声明靠近使用处、按功能分组。

5. **丰富的中文注释讲"为什么"**：
   - 模块头：功能、在前端的位置、与上下游的关系、关键设计点（为何这么设计）。
   - 每个非平凡逻辑块：解释算法/协议/时序意图（例如"投机栈与提交栈为何分离"、
     "两段式 RVC 边界检测为何在中点打断依赖链"）。
   - 注释解释 **意图与原理**，而非复述代码。

## 验证策略（可读优先，FM 尽量做）

- **正确性第一靠 UT**：golden vs 手写双例化，随机 + 定向激励，逐拍/逐向量比对所有输出。
  可读重写命名/结构与 golden 不同，更要靠充分 UT 保证功能等价。
- **FM 尽量做**：可读代码 FM 靠**签名分析**证等价（不靠名字）。能过就过；
  - 组合逻辑通常签名分析可过；
  - 大状态机若签名分析配不齐，可用 `fm_map`/`set_user_match` 辅助，或接受"UT 充分 + FM 部分/不可判"并在文档注明。
  - **不得为了让 FM 好过而退回照抄 golden 命名**。

## 分层结构（每模块）

- `rtl/<area>/<Module>.sv`：可读核 `xs_<Module>`（或 `xs_<Module>_core`），含 typedef/参数。
- 顶层 wrapper（golden 同名）：把可读核的 struct/数组端口拆成 golden 扁平端口，供 FM 对比与
  ST 替换。wrapper 是**机械的端口适配层**，允许平铺。
- `docs/<area>/<Module>.md`：**学习文档**——架构定位、数据流图（mermaid）、算法/协议说明、
  关键设计点、接口表、验证结果。这是学习的主要载体，要写充分。

## 范例

可读核范例见 `rtl/common/SRAMTemplate_core.sv`、`rtl/frontend/PreDecode.sv`、
`rtl/frontend/InstrMMIOEntry.sv`（命名/结构/注释达标）。后续所有模块对齐或超过此标准。

## ⚠️ 硬性闸门(2026-06-15 加强,违者一律拒收返工)

**根本原则:从设计意图(Scala 源)重新实现,不是读 firtool golden RTL 改变量名。**
- Chisel/Scala 源在 `/home/eda/xs-env/XiangShan/src/main/scala/xiangshan/...`(人写的、有结构有命名)。
  **按 Scala 的结构与意图用 SV 重写**;golden RTL(`golden/chisel-rtl/*.sv`)**只用于 UT/FM 对照验证**。
- "把 golden 的 wire/assign 改个表意名 + 加分节注释" = **转写,不是重写,拒收**。
  (反面教材:LoadUnit 首版 312 wire+469 assign、0 struct/enum/function/genvar、满是 `io_x_10_0`/`_REG_1`
   /手工 acc1/acc2/acc3 链——FM 因结构与 golden 逐位相同而"0 failing",这恰恰证明它是转写。)

**结构硬指标(可读核必须满足,验收逐条 grep)**:
1. `typedef struct packed` > 0（流水级寄存器、条目、bundle 用 struct,不许散落几十个标量 reg）。
2. `typedef enum` > 0（状态、来源选择、cause 等离散量用 enum）。
3. `function automatic` > 0（对齐/选择/编解码/逐字节合并等用纯函数;**byte-mux/移位等禁止手工 accN 链**,用 for/函数）。
4. `genvar`/`for` > 0（多路/多源/多 bank 用 generate,不许手工展开 _0.._N）。
5. 展平名/生成痕迹 = 0:`grep -E "io_[a-z_]+_[0-9]+_[0-9]+|_REG_[0-9]|_GEN_|_T_[0-9]|RANDOMIZE"` 必须为 0
   （注意 `_[0-9]+_[0-9]+` 覆盖**两位数**展平名如 `_10_0`,旧 grep 漏了)。
6. 行数应显著小于 golden(firtool 展平),或有清晰的结构分解;仅压缩 ~10% 基本等于转写。

**复核流程(主线必做)**:① 上述结构 grep ② 读核中段样本人工判断 ③ 多种子 UT(seed 1/7/42) ④ FM。
任一不达标 → 退回,用"从 Scala 重实现 + 结构硬指标"的强 prompt 重做。

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

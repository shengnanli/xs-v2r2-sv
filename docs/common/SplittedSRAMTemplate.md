# SplittedSRAMTemplate —— 分裂式 SRAM（把逻辑 SRAM 拆到多个物理 SRAMTemplate）

| | |
|---|---|
| 手写 SV | `rtl/common/SplittedSRAMTemplate_variants.sv` |
| Scala 来源 | `utility/src/main/scala/utility/sram/SRAMTemplate.scala`（class SplittedSRAMTemplate） |
| 依赖 | [SRAMTemplate](SRAMTemplate.md)（内层，已单独验证） |
| 验证状态 | UT ✅（7 个变体各 4 万拍 0 错）/ FM ✅（内层 SRAMTemplate 当黑盒，全部 SUCCEEDED） |

## 功能

把一个逻辑 SRAM 按 `setSplit×waySplit×dataSplit` 拆到多个物理 `SRAMTemplate` 实例
（FTB/TAGE/ITTAGE 等 BPU 表用，便于物理实现与 bank 化）。每个内层各有独立 MBIST
bore 与 broadcast。本层是**纯结构层**（setSplit=1 时无自身时序逻辑——Chisel 的
ren_vec 寄存器被优化掉），核心工作是 **struct↔扁平位的打包/解包** 与 **拆分维度的路由**。

## 三个拆分维度

| 维度 | 含义 | 体现 |
|------|------|------|
| `waySplit` | 把逻辑「路」分到多个内层（每内层管一部分路） | base：4 路拆成 2 内层×2 路 |
| `dataSplit` | 把每路「数据字」沿位宽切片，分到多个内层 | `_2`：80b 切 8×10b；`_26`：38b 切 2×19b |
| `setSplit` | 把逻辑「set」分到多个内层（带 bank 选择） | 本批次内层均 setSplit=1 |

## 已覆盖变体

| golden | 逻辑（set×way×bit） | 拆分 | 内层 | 看点 |
|------|------|------|------|------|
| `SplittedSRAMTemplate` | 128×4×37（{meta_tag,code}） | waySplit=2 | 2×SRAMTemplate(icsh_tag) | base：way 拆分 + 双 bore |
| `SplittedSRAMTemplate_1` | 128×4×37（同上） | waySplit=2 | 2×SRAMTemplate_2(icsh_tag) | 与 base 同构（另一处例化） |
| `SplittedSRAMTemplate_3` | 256×16×1（TAGE useful） | 不拆（1/1/1） | 1×SRAMTemplate_44(tage_us) | 退化：纯透传 + extra_reset |
| `SplittedSRAMTemplate_4` | 512×2×12（TAGE 表） | 不拆 | 1×SRAMTemplate_45(bp_tage) | struct{valid,tag,ctr}；写 valid 恒 1 |
| `SplittedSRAMTemplate_24` | 128×2×38（ITTAGE） | 不拆 | 1×SRAMTemplate_70(ittage) | 逐位写掩码 flattened_bitmask |
| `SplittedSRAMTemplate_26` | 128×4×38（ITTAGE） | dataSplit=2 | 2×SRAMTemplate_72(ittage) | 数据切片 + bitmask + 双 bore |
| `SplittedSRAMTemplate_2` | 512×4×80（FTB） | dataSplit=8 | 8×SRAMTemplate_36(bp_ftb) | FTB 条目精确 80b 打包切 8×10b |

### 几个关键设计点

- **struct 打包顺序按 golden 物理位序**（不是简单 struct flatten）。例如 FTB 的 80 位
  物理字布局见 `SplittedSRAMTemplate_2` 模块头注释；读写两侧严格一致。
- **写 valid 恒 1**（`_4`/`_24`/`_26` 高半切片）：TAGE/ITTAGE 分配条目即视为有效。
- **逐位写掩码** `flattened_bitmask`（`_24`/`_26`）：内层支持按位写使能，上层把
  `bitmask`（字段级粒度）按 `lane(way,bit)=waymask[way]&bitmask[bit]` 用 genvar 铺开，
  让 ITTAGE 只更新条目的部分字段。`_26` 还要按 dataSplit 把 bitmask 分给两个切片。
- **dataSplit 拼回**：`_26` 的 `target_offset_offset = {hi[6:0], lo[18:6]}`；
  `_2` 把 8 片拼回 80 位再拆字段——都用 genvar 表达切片维度，无手工展开痕迹。

## 未覆盖（内层 SRAMTemplate 未就绪，跳过）

| golden | 内层 | 跳过原因 |
|------|------|------|
| `SplittedSRAMTemplate_23` | SRAMTemplate_64 | 内层变体未就绪 |
| `SplittedSRAMTemplate_29` | SRAMTemplate_78 | 内层变体未就绪 |

## 验证

- **UT**：golden vs `<变体>_xs`，两者均例化 golden 内层 SRAMTemplate（共用），随机
  r/w/bore（含全 1 与随机 bitmask），4 万拍比对所有输出 0 错——验证 Splitted 层的
  way/data 拆分、struct 拆拼、bitmask 铺开、bore 路由。7 个变体均 `checks≈39604, errors=0`。
- **FM**：内层 SRAMTemplate 经 `hdlin_unresolved_modules black_box` 当**已验证黑盒**
  （模块化等价），只比对 Splitted 自身结构连线。7 个变体均 SUCCEEDED。

> 折叠层见 [FoldedSRAMTemplate](FoldedSRAMTemplate.md)（folding 包 Splitted）。

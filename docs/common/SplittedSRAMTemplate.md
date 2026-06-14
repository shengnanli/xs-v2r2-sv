# SplittedSRAMTemplate —— 分裂式 SRAM（把逻辑 SRAM 拆到多个物理 SRAMTemplate）

| | |
|---|---|
| 手写 SV | `rtl/common/SplittedSRAMTemplate_variants.sv` |
| Scala 来源 | `utility/src/main/scala/utility/sram/SRAMTemplate.scala`（class SplittedSRAMTemplate） |
| 依赖 | [SRAMTemplate](SRAMTemplate.md)（内层，已单独验证） |
| 验证状态 | UT ✅（base 变体 4 万拍 0 错）/ FM ✅（内层 SRAMTemplate 当黑盒，SUCCEEDED） |

## 功能

把一个逻辑 SRAM 按 `setSplit×waySplit×dataSplit` 拆到多个物理 `SRAMTemplate` 实例
（FTB/FTQ 用，便于物理实现与 bank 化）。每个内层各有独立 MBIST bore 与 broadcast。

## 已覆盖变体（base）

| golden | 逻辑 | 拆分 | 内层 |
|------|------|------|------|
| `SplittedSRAMTemplate` | 128set×4way×37b（struct{meta_tag[35:0],code}） | waySplit=2，setSplit=1，dataSplit=1 | 2×SRAMTemplate(128×2×37, icsh_tag) |

- way0,1 → `array_0_0_0`；way2,3 → `array_0_1_0`
- 写：waymask[1:0]/[3:2] 分别给两内层；每路数据打包 {meta_tag, code}=37b
- 读：两内层各出 2 路，拆回 {meta_tag[36:1], code[0]}
- 两套 bore（bore→inner0，bore_1→inner1）与 broadcast（sigFromSrams_bore/bore_1）

本变体 setSplit=1，无自身时序逻辑（Chisel 的 ren_vec 寄存器被优化掉），是纯结构层。

## 验证

- **UT**：golden vs `SplittedSRAMTemplate_xs`，两者均例化 golden 内层 SRAMTemplate，
  随机 r/w/bore，4 万拍比对所有输出 0 错——验证 Splitted 层的 way 分配/拆拼/bore 路由。
- **FM**：内层 SRAMTemplate 经 `hdlin_unresolved_modules black_box` 当**已验证黑盒**
  （模块化等价），只比对 Splitted 自身结构连线，SUCCEEDED。

> 其余 Splitted 变体（多读口、setSplit>1 带 bank 选择、不同 struct）及 Folded 层
> （folding 包 Splitted）待 BPU 表重写时按需扩展。

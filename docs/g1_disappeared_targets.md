# 上轮 306 里在 G1 消失的 7 个目标——去向定位

判据分三档，**不把"看起来像"当成"就是"**：
- **纯重编号**：自名与断言行号归一后字节全等 → 可自动改判（已进 `g1_manual_map.tsv`）。
- **同位替换**：父模块相同、接口形状相同、职责相同，但内容有实质差异 → 只登记对应关系，
  必须按新目标重写并独立证明，不得继承旧结论。
- **真消失/合并**：在 G1 例化图里没有对应物，或被并进别的实例 → 从 MAIN 分母移除，
  在 `g1_old_to_new_map.tsv` 记 removed/merged。

| 上轮目标 | G1 去向 | 档位 | 证据 |
|---|---|---|---|
| `CLINT` | **`TIMER`** | 同位替换 | 同一父 `MemMisc` 例化；接口前缀一致（`auto_int_out_0/1`、`auto_in_a_*`）。但内容差 2361 行，且**接口方向翻转**：G0 的 `CLINT` 自己产生时间（`input io_rtcTick`、`output io_time_valid/bits`），G1 的 `TIMER` 改为**接收**时间（`input io_time_valid/bits`）——时间源被移到模块外。属重新设计，须重写。 |
| `FastArbiter_44` | `FastArbiter_43`（RNXbar 内） | 同位替换 | G1 `RNXbar` 例化 `FastArbiter_{26,29,30,35,43,45}`；与 `_44` 差 13 行，diff 全在中间线命名与表达式重排（`_rrSelOH_T_5` → `_rrSelOH_oh_T`），**疑似仅 firtool 命名变化、功能相同**，但未经 FM 证明，先按新目标处理。 |
| `FastArbiter_47` | `FastArbiter_46`（SNXbar 内） | 同位替换 | 同上，差 13 行同类命名变化。 |
| `SRAMTemplate_66` | `SRAMTemplate_68`（SCTable 家族内） | 同位替换 | G1 `SCTable` 例化 `SRAMTemplate_68`；差 202 行，是实质改动（非命名）。 |
| `L1FlagMetaArray_1` | 并入 `L1FlagMetaArray` | 合并 | G1 `DCache` 只例化 `L1FlagMetaArray` 一种，`_1` 变体不复存在。 |
| `PMPChecker_10` | `PMPChecker_12`（MemBlock 内） | 同位替换 | G1 `MemBlock` 例化 `PMPChecker_12`。 |
| `NewPipelineConnectPipe_32` | `NewPipelineConnectPipe_34` / `_35`（MemBlock 内） | 同位替换（一对多） | G1 `MemBlock` 例化 `_34` 与 `_35` 两个变体，原 `_32` 的位置由其中之一承接，具体对应需看例化上下文，尚未逐一确认。 |

## 结论对 MAIN 分母的影响

这 7 个**一律从"老 306 口径"的分母里按 removed 处理**（codex 0141 §58：不保留 G0 已消失
目标）。它们对应的 G1 新目标（TIMER / FastArbiter_43 / FastArbiter_46 / SRAMTemplate_68 /
L1FlagMetaArray / PMPChecker_12 / NewPipelineConnectPipe_34,_35）已经在
`g1_configured_universe.tsv` 的 1884 里，作为**新目标**各自独立计数与证明。

没有任何一个可以继承上轮结论：即使 FastArbiter_44→43 的差异看起来只是中间线改名，
在 FM 证过之前也只是"疑似"。

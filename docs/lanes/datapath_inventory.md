# DataPath lane（agent/datapath）—— child 盘点

基线：main `0cbe4f8c`（含 codex/readable-leaves-15 合入 `9f15cac9`）。golden `G1-canonical/golden-rtl/DataPath.sv` 25,618 行，
2,426 端口（1,040 in / 1,386 out），顶层 1,111 个寄存器 / 9,519 位（不含 child）。Scala 源
`src/main/scala/xiangshan/backend/datapath/DataPath.scala`（+ `regfile/Regfile.scala`、`datapath/RFReadArbiter.scala`、
`datapath/RFWBConflictChecker.scala`）。

直接 child：**62 个实例 / 28 种类型**。状态列取自 `docs/coverage_three_axis.tsv`（第 2/3 列，盘点时刻）。

## 1. 直接 child 表

| child 类型 | 例化数 | golden 行数 | tsv 状态 | 孙级（golden 例化） | 归属 / 处置 |
|---|---:|---:|---|---|---|
| UIntExtractor_27_000011100000000000001010101 | 23 | 95 | MISSING/UNPROVEN（tsv 未重算） | — | **codex 已签**（codex/readable-leaves-15 → main `9f15cac9`，receipt `evidence/45cf2620708e/`）；本 lane 不改，本体证明两侧白盒（ref golden / impl `rtl/backend/UIntExtractor_27_*.sv`） |
| UIntExtractor_27_000000000000001010100000000 | 13 | 94 | 同上 | — | 同上 |
| IntRegFilePart0 | 1 | 7,012 | MISSING/UNPROVEN | — | **intrf lane 负责，本 lane 不碰**；本体证明时若未合入 main：两侧同源 golden 白盒，记条件项 |
| IntRegFilePart1 | 1 | 7,012 | MISSING/UNPROVEN | — | 同上（intrf lane） |
| IntRegFilePart2 | 1 | 7,012 | MISSING/UNPROVEN | — | 同上（intrf lane） |
| IntRegFilePart3 | 1 | 7,012 | MISSING/UNPROVEN | — | 同上（intrf lane） |
| RegCache | 1 | 1,648 | REWRITTEN/PROVEN_DIRECT | RegCacheAgeDetector(_1)/AgeTimer(_1)/DataModule(_1)（PROVEN_IN_CONE） | 已签；本体两侧白盒（impl `rtl/backend/RegCache.sv`） |
| FpRegFilePart0..3 | 4×1 | 3,968 ×4 | MISSING/UNPROVEN | — | 本 lane：族 E |
| VfRegFilePart0..3 | 4×1 | 2,694 ×4 | MISSING/UNPROVEN | — | 本 lane：族 D |
| V0RegFilePart0..1 | 2×1 | 642 ×2 | MISSING/UNPROVEN | — | 本 lane：族 C |
| VlRegFile | 1 | 606 | MISSING/UNPROVEN | — | 本 lane：族 C |
| IntRFReadArbiter | 1 | 594 | MISSING/UNPROVEN | WBArbiter_30 ×4、_33 ×4、_38 ×3 | 本 lane：族 B |
| VfRFReadArbiter | 1 | 515 | MISSING/UNPROVEN | WBArbiter_52 ×3、_55 ×3、_58 ×6 | 本 lane：族 B |
| FpRFReadArbiter | 1 | 495 | MISSING/UNPROVEN | WBArbiter_30 ×4、_38 ×7 | 本 lane：族 B |
| V0RFReadArbiter | 1 | 423 | MISSING/UNPROVEN | WBArbiter_64 ×1、_65 ×1、_66 ×2 | 本 lane：族 B |
| VlRFReadArbiter | 1 | 423 | MISSING/UNPROVEN | WBArbiter_64 ×1、_65 ×1、_66 ×2 | 本 lane：族 B |
| IntRFWBCollideChecker | 1 | 237 | MISSING/UNPROVEN | WBArbiter ×1、_1 ×1、_2 ×2、_3 ×4 | 本 lane：族 A |
| FpRFWBCollideChecker | 1 | 221 | MISSING/UNPROVEN | WBArbiter_2 ×5、_3 ×1 | 本 lane：族 A |
| V0RFWBCollideChecker | 1 | 219 | MISSING/UNPROVEN | WBArbiter_2 ×3、_3 ×3 | 本 lane：族 A |
| VfRFWBCollideChecker | 1 | 219 | MISSING/UNPROVEN | WBArbiter_2 ×3、_3 ×3 | 本 lane：族 A |
| VlRFWBCollideChecker | 1 | 202 | MISSING/UNPROVEN | WBArbiter_3 ×4 | 本 lane：族 A |

例化数合计：23 + 13 + 26（其余每种 1 个）= 62。

孙级 WBArbiter 家族 13 个变体（WBArbiter、_1、_2、_3、_30、_33、_38、_52、_55、_58、_64、_65、_66）
全部 REWRITTEN/PROVEN_DIRECT（`rtl/backend/WBArbiter*.sv`，共享核 `xs_WBArbiter_core`）：本 lane 两侧白盒直接用，不改。
寄存器堆类 child 无孙级（阵列内联在模块里）。

## 2. 本 lane 的顺序（从小到大、从叶子到装配；同构变体 = 参数化核 + 薄 wrapper）

| 族 | 目标 | 性质 | 共享实现 |
|---|---|---|---|
| A | 5 × *RFWBCollideChecker | 纯装配：写回口按 (端口号, 优先级) 分组进 WBArbiter，NoWB 口 ready 恒 1 | 同一份写法，五个文件 |
| B | 5 × *RFReadArbiter | 纯装配：读口按 (端口号, 优先级) 分组进 WBArbiter，NoRD 口 ready 恒 1（Int 另有死 perf 计数，golden 无负载） | 同上 |
| C | V0RegFilePart0/1、VlRegFile | 寄存器堆：Mux1H 写、同步读（地址打一拍）| `xs_Regfile_core`（参数化） |
| D | VfRegFilePart0..3 | 同上 | 同上 |
| E | FpRegFilePart0..3 | 同上 | 同上 |
| — | DataPath 本体 | og0/og1 读寄存器堆、旁路、发射到执行 | 手写核 + 生成 wrapper |

四个 Part 变体（Fp/Vf 各 0..3、V0 0..1）在 golden 里逐字相同，仅模块名不同（`diff` 实测 0 行）。
Int 家族的寄存器堆核由 intrf lane 自建（`xs_IntRegFilePart_core`），本 lane 的 `xs_Regfile_core` 不与之同名。

## 3. 复跑

- 实例表：`awk '/^module DataPath/,/^endmodule/' DataPath.sv | grep -E '^\s+[A-Za-z_]\w*\s+[A-Za-z_]\w*\s*\($' | awk '{print $1}' | sort | uniq -c`
  （在 `/home/eda/xs-env/G1-canonical/golden-rtl` 下）。
- 状态：`grep -P '^<类型>\t' docs/coverage_three_axis.tsv | cut -f1-4`。

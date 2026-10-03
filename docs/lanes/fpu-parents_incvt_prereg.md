# fpu-parents lane · incvt 组（FP_INCVT + 父级 FCVT 重证）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | `agent/fpu-parents` @ `7bcd83397`（认领 commit，main `3f23a91cb` 之上），worktree `/home/eda/xs-env/wt-fpu-parents` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 设计源 | `yunsuan/src/main/scala/yunsuan/vector/VectorConvert/CVT64.scala` class `FP_INCVT` |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify、无黑盒、无 vmucp、无 fm_pins |
| 冲突检查 | codex outbox / codex 分支 rtl diff、全部 worktree 的 claim/prereg、各分支 rtl diff：无人改 FP_INCVT（vectorcvt-tree 等 prereg 只把它列为两侧同源 golden 的 child） |

## 1. FP_INCVT（UT 目录 `verif/ut/FP_INCVT`）

### 1.1 结构与 child 处置

| 目标 | golden 行 | impl 行 | golden `_GEN_`/`_T_` | impl `_GEN_`/`_T_` |
|---|---:|---:|---:|---:|
| FP_INCVT | 1069 | 719 | 284 | 0 |

可读核 `xs_FP_INCVT_core`：§0 第 0 拍（源摆位/解码、指数加数、右移量、fround 掩码量、fcvtmod 移位）→ §1 s1/s2 寄存器
→ §2 第 1 拍公共（指数、规格化左移、ShiftRightJam、两个舍入器）→ §3–§7 五条路径（widen/crossH、narrow/crossL、
fround、fcvtmod、fp→int）→ §8 优先选择。寄存器集合、位宽、复位域与 golden 逐个同名同宽（36 个异步复位 + 6 个不复位），不需要 fm_pins。
child：CLZ_6 / ShiftRightJam / RoundingUnit_3 / RoundingUnit_4，coverage 第 3 列均 PROVEN_DIRECT → 两侧白盒（ref golden / impl 重写件）。

### 1.2 UT（commit `b0bc06810` 的字节；golden 与 `FP_INCVT_xs` 双例化，200k 拍；另 golden 对独立 IEEE oracle）

oracle（tb 内，只用整数算术）：fp→int 用 `cvt_tb_pkg::o_fp2int`；fp→fp（widen/crossH 精确，narrow/crossL 含 ROD、
RISC-V 舍入后判 tiny 的 UF、上溢按 rm 给 Inf/最大有限数）、fround/froundnx、fcvtmod.w.d 三个 oracle 写在 tb 里；
标量→向量未 NaN-box 时 golden 只清 widen/narrow 的 fflags，oracle 同样建模。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=199998 errors=0，oracle 115201/0 PASSED | 同左 PASSED（seed 1 的 random 档退化为全 1） | initreg+1017 PASSED（同上读数） |
| 7  | checks=199998 errors=0，oracle 115156/0 PASSED | PASSED | initreg+7017 PASSED |
| 42 | checks=199998 errors=0，oracle 115799/0 PASSED | PASSED | initreg+42017 PASSED |

覆盖（seed 1，判据写在 tb 里）：oracle 按类 f2i/widen/crossH/narrow/crossL/fround/fcvtmod = 35373/12624/8324/19528/10565/16173/12614；
每类 × rm 0..4 各 ≥1300、narrow/crossL 的 rm=6(ROD) 2719/1458；narrow 非规格 8880 / 上溢 4359（其中最大有限数 2103）/ UF 9057；
f2i NV 16649（有符号负饱和 3499）/ NX 13526；fround NaN 2002 / 原样 4617 / |x|<1 5623 / 正常舍入 3931 / NX 4009；
fcvtmod NV 6166 / NX 5589；未 NaN-box 5084；64 位结果逐位见过 0 和 1。

变异自检（scratch 副本编独立 simv，seed 1 initreg 0，50k 拍；不进库）：

| 变异 | 结果 |
|---|---|
| M1 fcvtmod NX 掩码少减 1 | CAUGHT errors=864 |
| M2 ROD 上溢给 Inf | CAUGHT 225 |
| M3 fround 掩码判 `<64` 改 `<=64` | MISSED —— fracShiftMask==64 只在 \|x\|<1 时出现，那时走 ±0/±1 分支不用掩码；只有非独热 output1H 的全随机事务可能碰到，UT 未命中，归 FM |
| M4 有符号最小值例外去掉 excludeFrac | CAUGHT 88 |
| M5 s1_fpCanonicalNAN 加复位 | MISSED —— 复位域，UT 结构上看不见（CONVENTIONS「UT 与 FM 的分工」），归 FM |
| M6 UF 改「舍入前」判 tiny | CAUGHT 18 |
| M7 非规格源指数按 0 算 | CAUGHT 2 |
| M8 widen f32 尾数错一位 | CAUGHT 1810 |
| M9 右移量饱和到 64 | CAUGHT 1399 |
| M10 narrow 非规格 sticky 去掉 trunSticky | MISSED —— 等价变异：f64 尾数低 29 位在 shamtIn 里本来就会落进 srj_out[39:0] / sticky，trunSticky 冗余 |

复跑：`cd verif/ut/FP_INCVT && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记 `docs/fm_predictions/FP_INCVT.json`）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model FP_INCVT --ut FP_INCVT`）= **494**（425 + 69）。

| 预测项 | 值 |
|---|---|
| constant_reg | **27**：`fflags[3]`（DZ 恒 0）1、`expAdderIn0[12:11]` 2、`shamtIn[11:0]` 12、`fracSrcLeft[11:0]` 12（都是字面常量位） |
| passing | **467**（= 494 − 27） |
| 其余 | failing 0 / unverified 0 / unread 0 / unmatched 六项 0 / 黑盒 0 / dont_verify 无 / SUCCEEDED |

### 1.4 明写可能出错的地方

1. `shamt[10:7]`：shamt ≤ 65，高 4 位恒 0，但要经过比较器才知道，不是字面常量；FM 若也判它常量，constant_reg 31、passing 463。
2. golden 与 impl 寄存器同名，预期名字配对；若出现 unmatched，先查配对再谈 RTL。
3. 本节登记前没做过任何 FM 试跑。

### 1.5 首跑偏离与改登记（★在第二次证明之前提交★）

首跑 `75c1c255e`（vmucp 未开）：native **SUCCEEDED**，passing **462** / failing 0 / unmatched 0 / constant_reg **27**（与 §1.3 预测逐项相同）/
**unread 5** → validator PARTIAL（`strict_unread!=0`）。receipt 留档 `evidence/75c1c255e106/FP_INCVT`
（receipt.json sha256 `475b89ecbe284b0745b95e7c1919ca13c96a76b3112279d3ba6d3b83902ae3b7`）。
★预测漏项，照实记★：§1.3 写了 unread 0，漏了 `fcvtmodTrueExpReg[4:0]`——golden 只读 [10:5]，低 5 位两侧都无读者
（父级 FCVT 的 vmucp 白名单早就记着同一组 5 点）。462 + 27 + 5 = 494 = 模型，余额 0。
5 点全部 matched_nc、同名逐位配对（`unread_points.txt`）。

处置：`verif/fm_target_config/FP_INCVT.tcl` 加 vmucp 白名单条目（依据见文件），`verif/ut/FP_INCVT/Makefile` 开
`FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true`。RTL 不改。

第二次证明的预测：passing **467**（462 + 5，vmucp 实比 5 点）/ constant_reg 27 / unread 0 / failing 0 / unverified 0 /
unmatched 0 / 黑盒 0 / dont_verify 无 / SUCCEEDED。`docs/fm_predictions/FP_INCVT.json` 不动（模型 494 − 467 = 27 = constant_reg）。

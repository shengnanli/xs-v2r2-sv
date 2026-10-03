# pmpchk-vimac-agt-fma lane —— BoothEncoderF64F32F16_3 / VectorFloatFMA 跑前登记

本文件只管本 lane 的第 4 个目标（先 `BoothEncoderF64F32F16_3`，再 `VectorFloatFMA`），由子 agent 维护；
同 lane 另三个目标（PMPChecker 家族 / VIMac64b / ActiveGenerationTable）的登记在 `pmpchk-vimac-agt-fma_prereg.md`。
每个目标 **FM 正式起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 工作树 / 分支 | `/home/eda/xs-env/wt-pmpchk-vimac-agt-fma`，`agent/pmpchk-vimac-agt-fma`（与父 agent 共用，只碰自己的路径） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| Scala | `/home/eda/xs-env/XiangShan/yunsuan/src/main/scala/yunsuan/vector/VectorFloatFMA.scala` |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| 正式证明 | `PROOF_COMMIT=<commit> bash scripts/run_proof.sh <ut> <T> < /dev/null`（工作树里有父 agent 的未提交文件，钉 commit 跑） |

## 1. BoothEncoderF64F32F16_3

### 1.1 结构与子模块处置

- golden 1076 行 / 31 端口，纯组合，0 子模块、0 寄存器。Scala 是 `BoothEncoderF64F32F16(width=53, is_addend_expand_1bit=true)`：
  27 个 Booth-4 数字三种格式共用；f64 一条通道、f32 两条、f16 四条，各通道的加数摆在 107 位里互不重叠的一段。
- 可读核 `rtl/backend/BoothEncoderF64F32F16_3.sv`（252 行，`_GEN_`/`_T_<数字>` 0 命中）：
  `xs_BoothAddendLane #(W, N)`（一条通道：W 位被乘数 + N 个已译码数字 -> N 个 2W+1 位加数，奇/偶宽度的末项各一种写法）
  × 7 个实例（53 / 24×2 / 11×4）+ `xs_BoothEncoderF64F32F16_core`（乘数重排、27 个译码器、按格式选出）+ golden 同名 wrapper。
  另一个变体 `BoothEncoderF64F32F16`（标量 FloatFMA 用，不在本 lane 认领清单里）没有做。
- 无黑盒。

### 1.2 UT（verif/ut/BoothEncoderF64F32F16_3；seed 1/7/42 × initreg 0 / random / `<seed>017`，各 200k 拍）

逐拍比 27 个 107 位加数（2889 位里按结构算出 1338 位三种格式下都是同一个常量，豁免"见过 0/1"；其余 1551 位必须见过 0 和 1）。
九档全部 `checks=5399784 errors=0 cov_fail=0 TEST PASSED`（纯组合，三档 initreg 读数相同是预期的）。
这九档在提交 `58594896` 之前的工作树上跑（`git diff 58594896 -- rtl/backend/BoothEncoderF64F32F16_3.sv verif/ut/BoothEncoderF64F32F16_3` 为空，字节相同）。

覆盖（seed 1 × initreg 0）：f64 65599 拍 / f32 65362 / f16 65791 / 两个格式位同时为 1（fp64 优先）3240；
27 个数字 × {+1, +2, -1, -2} 共 105 个计数（第 26 个数字不可能为负、第 0 个不可能为 +2，这 3 项按结构不设），最小 8560、最大 99866。

复跑：`bash <scratchpad>/pmpchk-vimac-agt-fma/ut9.sh BoothEncoderF64F32F16_3`，或单档
`cd verif/ut/BoothEncoderF64F32F16_3 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。

变异自证（scratchpad，不进库）：结果见文末「对账」。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/BoothEncoderF64F32F16_3.json）

模型：expected = **2889**（寄存器位 0 + 顶层 output 位 27×107 = 2889），`FM_MERGE_DUP=false` 模型适用。

| 项 | 预测 |
|---|---|
| passing | **2889** |
| failing / unverified / aborted / unread | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 0（没有寄存器） |
| 黑盒 / dont_verify | 无 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

无 vmucp、无 fm_pins、无 allow / dead_ref 声明。

### 1.4 明写可能出错的地方

1. **做过一次 lane 内非正式试跑**（提交前的工作树，与 `58594896` 字节相同；`cd verif/ut/BoothEncoderF64F32F16_3 && make fm-BoothEncoderF64F32F16_3 < /dev/null`，
   因工作树 dirty 不出 receipt）：native SUCCEEDED，passing 2889 / failing 0 / unmatched 0。所以上表不是盲测，是"照试跑结果登记"。
2. 2889 个输出位里有 1338 位是常量（两侧同为常量 0/1）。FM 对"两侧都是常量的输出口"仍计比较点（试跑 passing 就是 2889），
   若正式跑里 passing 少了，先查是不是这批常量口的计数口径变了，而不是 RTL。
3. 可读核用了参数化子模块 + `localparam` 非打包数组做通道表（`F32_SIG_LSB[l]` 之类）下标 generate 变量；试跑已证明 FM 能展开。

## 2. VectorFloatFMA

### 2.1 结构与子模块处置

- golden 5582 行 / 13 端口（不含 clock / reset；io_fire / fp_a / fp_b / fp_c / widen_a / widen_b / uop_idx / round_mode / fp_format / op_code /
  res_widening / fp_result / fflags），顶层 301 个寄存器 1326 位；直接 child 三个：
  `BoothEncoderF64F32F16_3`、`CSA3to2`、`CSA_Nto2With3to2MainPipeline`（内含 4×107 位寄存器与 CSA4to2 / CSA3to2）。
- 可读核 `rtl/backend/VectorFloatFMA.sv`（1224 行，`_GEN_`/`_T_<数字>` 0 命中）：
  `xs_VfmaRightShiftSticky` / `xs_VfmaLane`（一条通道：拆操作数、对齐、规格化、舍入，参数化 W）× 7 实例 +
  `xs_VfmaSlotPack`（按格式把通道结果拼进共用寄存器）+ `xs_VectorFloatFMA_core`（共用的 Booth + CSA 阵列、107 位加法、
  三级寄存器）+ golden 同名 wrapper。
- child 处置（两侧白盒，无黑盒、无 dont_verify）：
  - `BoothEncoderF64F32F16_3`：ref = golden，impl = 本仓重写件（本文件 §1 单独签核）；
  - `CSA3to2`：ref = golden，impl = `rtl/backend/CSA3to2.sv`（coverage_three_axis：PROVEN_DIRECT）；
  - `CSA_Nto2With3to2MainPipeline`（+ 内部 `CSA4to2`）：★golden 复用★，本仓无重写件，照 `verif/ut/FMA/Makefile` 先例
    走 `RTL_GOLDEN_DEPS`，两侧同源 elaborate，不设黑盒。
- 钉点：`verif/ut/VectorFloatFMA/fm_pins_pre.tcl`（`scripts/gen_vfma.py --check`，golden 顶层 301 个扁平寄存器 / 1326 位
  一一映射到 `u_core` 与 `g_lane[l].u_lane`，fail-closed 计数，字面 1326）。不钉时非正式试跑 1(1) unmatched
  （`lzd_adder_inv_mask_reg1[140]` <-> `tzd_src_s1_q[23]` 错配），钉后 0(0)。

### 2.2 UT（verif/ut/VectorFloatFMA；seed 1/7/42 × initreg 0 / random / `<seed>017`，各 200k 拍）

逐拍比 io_fp_result / io_fflags（DZ 位恒 0 豁免见 0/1）。激励按"9 op × 3 格式 × 2 加宽 = 54 组合"各自计数，
特殊值偏置（±0 / ±inf / qNaN / sNaN / 次正规 / 边界 / 抵消 / inf*0 / inf-inf），5 种舍入模式 × 3 格式各计数，
每格式 fflags NV/OF/UF/NX 见过 1，7 条通道各 18 项内部状态计数（cov_min 100）。读数见对账。
复跑：`bash <scratchpad>/pmpchk-vimac-agt-fma/ut9.sh VectorFloatFMA`，或单档
`cd verif/ut/VectorFloatFMA && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。

### 2.3 非正式试跑抓到、UT 看不见的失配（已修 `7b655538`，登记前）

试跑 1（`56340f39`，无钉点）：FAILED，passing 483 / failing ≥20（截断）/ unmatched 1(1)。
试跑 2（同字节 + 钉点）：FAILED，passing 643 / failing ≥20（截断）/ unverified 1072 / unmatched 0(0)；
failing 全在 S1 的 `adder_reg1[140..147]`、`lzd_adder_inv_mask_reg1[140..147]`、`tzd_adder_reg1[16..23]` —— 都是 f32_1 通道
c 高段落下的位。根因：golden 的 59 位"c 高段加 1"向量里 f32_1 那一位是 `is_fp32_reg0`（不是 `~is_fp64 & is_fp32`），
而重写核按"在用通道"给；`is_fp64_reg0 / is_fp32_reg0` 不复位、FM 当自由状态，两个同时为 1 时两侧不同。UT 里格式位由
2 位 fp_format 译出、永远互斥，看不见。修法：照 golden，该位只看 is_fp32（文件头怪癖 8）。
试跑 3（修后字节 + 钉点）：match 0(0) unmatched、钉点 1326/1326 全接受，**verify 未跑完**（会话进程崩溃），
所以下表的 failing=0 是修法推断，不是试跑结果。

### 2.4 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/VectorFloatFMA.json）

模型 expected = **1838**（regs 1754 = 顶层 1326 + U_CSAnto2 内 4×107；outs 84 = 64 + 20），`FM_MERGE_DUP=false`。
试跑 2 的 passing + failing + unverified = 643 + 20 + 1072 = 1735 = 1838 − 103，verdict 记 constant_reg = 103：
全部在 golden 复用件 `U_CSAnto2/U_CSA4to2_io_in_{a,b,c,d}_r`（matched.rpt 的 DFF0X 位：26 / 27 / 31 / 28，
即 CSA 树进位加数左移后恒 0 的低位），两侧同一批位。unread_points.txt 为空（0 行）。

| 项 | 预测（正式 run_proof） |
|---|---|
| passing | **1735**（= 1838 − constant_reg 103） |
| failing / unverified / aborted / unread | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 103 |
| 钉点 | 1326 条 set_user_match 全接受（`VFMA_PIN_END ok=1326 bad=0`） |
| 黑盒 / dont_verify | 无 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

无 vmucp、无 allow / dead_ref 声明。

### 2.5 明写可能出错的地方

1. 修后字节没有跑完整的试跑：若正式跑 failing 仍 >0，按失败点定位再修 RTL、重新登记一节（不改本节数字）。
2. constant_reg 103 与 matched.rpt 里 112 个 DFF0X 不等（9 位差额）——verdict 的 103 来自 verify 后的 Not Compared 计数，
   DFF0X 是 match 期的"constrained 0X"标记，后者是前者的超集；对账以 receipt 的 constant_reg 为准。
3. 不复位的格式寄存器还有别的"两位同时为 1"分支（S2/S3 的格式选择）；核里一律按 fp64 > fp32 > f16 优先级写，
   与 golden 的三元链一致，试跑 2 的 failing 列表里没有这类点，但列表是截断的。

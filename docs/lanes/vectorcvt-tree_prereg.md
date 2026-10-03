# vectorcvt-tree lane（agent/vectorcvt-tree）—— 跑前登记

本文件在 FM 起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `f8d3356d`（集成者预建 worktree，认领 commit `f5cfc3cc`） |
| 工作树 | `/home/eda/xs-env/wt-vectorcvt-tree`，分支 `agent/vectorcvt-tree` |
| 被证 RTL commit | `6f573179`（11 个目标的可读核 + wrapper + 8 个 UT 目录） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| Scala 源 | `XiangShan/yunsuan/src/main/scala/yunsuan/vector/VectorConvert/`（CVT16/CVT32/CVT64/Convert/VCVT.scala），`src/main/scala/xiangshan/backend/fu/wrapper/VCVT.scala`（VCVT_8 / VectorCvtTop） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify，无黑盒 |

开工前冲突检查（规范 §0 两条都查了）：codex outbox 最新 0205 与 `codex/*` 分支 rtl 改动都不碰本 lane 的 11 个目标；
全部 worktree 的 `*_claim.md / *_prereg.md` 里只有 `wt-newrtl-next200c` 提到 Rec7Table / Rsqrt7Table（对方的，本 lane 不碰）；
所有分支相对 main 的 rtl 改动里，与本树相关的只有 `agent/newrtl-next200c: rtl/backend/Rec7Table.sv, Rsqrt7Table.sv`，未入 main。

## 1. 目标、文件与子模块处置

| 目标 | golden 行 | impl 文件（行） | UT 目录 | golden 直接 child |
|---|---|---|---|---|
| INT2FP | 268 | rtl/backend/INT2FP.sv（250） | INT2FP | CLZ_6, RoundingUnit_3 |
| Estimate7 | 382 | rtl/backend/Estimate7.sv（345） | Estimate7 | CLZ_6, Rec7Table, Rsqrt7Table |
| CVT64_1 | 236 | rtl/backend/CVT64_1.sv（177） | CVT64_1 | FP_INCVT, INT2FP, Estimate7 |
| VCVT | 113 | rtl/backend/VCVT.sv（39） | CVT64_1 | CVT64_1 |
| CVT32 | 1190 | rtl/backend/CVT32.sv（986） | CVT32 | CLZ_7/9/28×3/29×2/30/31, ShiftRightJam_2/_3, RoundingUnit_8/_9×2, Rec7Table, Rsqrt7Table |
| VCVT_1 | 111 | rtl/backend/VCVT_1.sv（37） | CVT32 | CVT32 |
| CVT16 | 632 | rtl/backend/CVT16.sv（581） | CVT16 | CLZ_7/28×2/30, ShiftRightJam_4, RoundingUnit_11, Rec7Table, Rsqrt7Table |
| VCVT_2 | 111 | rtl/backend/VCVT_2.sv（37） | CVT16 | CVT16 |
| VectorCvt | 256 | rtl/backend/VectorCvt.sv（182） | VectorCvt | VCVT, VCVT_1, VCVT_2×2 |
| VectorCvtTop | 204 | rtl/backend/VectorCvtTop.sv（147） | VectorCvtTop | VectorCvt×2 |
| VCVT_8 | 516 | rtl/backend/VCVT_8.sv（466） | VCVT_8 | VectorCvtTop, Mgu |

代码区 `_GEN_` / `_T_` 全部 0（readability_audit rc=0）。

子模块处置（查 `docs/coverage_three_axis.tsv` 第 3 列）：
- CLZ_* / ShiftRightJam* / RoundingUnit_* / ByteMaskTailGen / UIntToContLow1s/0s / MaskExtractor：PROVEN_DIRECT ⇒ 两侧白盒，ref 读 golden，impl 读本仓重写件。
- FP_INCVT：PROVEN_IN_CONE、无重写件 ⇒ 两侧同源 golden（RTL_GOLDEN_DEPS）。其下 CLZ_6/ShiftRightJam/RoundingUnit_3/_4 在 impl 侧读重写件。
- ★条件项一：Rec7Table / Rsqrt7Table★ 归 agent/newrtl-next200c（未入 main）⇒ 本 lane 两侧同源 golden。对方签核合入 main 后，
  Estimate7 / CVT64_1 / VCVT / CVT32 / VCVT_1 / CVT16 / VCVT_2 / VectorCvt / VectorCvtTop / VCVT_8 十个 receipt 按 STALE 规则重证（impl 改读重写件）。
- ★条件项二：Mgu★ 在 main 里是 REWRITTEN/UNPROVEN；签核 receipt 在 agent/fu-atomics-fpdiv-imsic（`evidence/d09e1997840f/Mgu`），
  未入 main ⇒ VCVT_8 的 impl 侧读本仓 Mgu 重写件（两侧白盒），VCVT_8 的绿以该 receipt 合入为条件。

## 2. UT（双例化 golden vs 重写，逐拍全输出比较）

共享 tb 包 `verif/ut/VectorCvt_common/cvt_tb_pkg.sv`：yunsuan VfcvtType 的 23 条向量 opType × sew（80% 合法组合），
浮点定向池（±0/Inf/qNaN/sNaN/非规格化各档/max-1、max-2 指数/整数敏感指数区/半整数/f32→f16 敏感区/随机），
整数定向池（0/-1/最小/最大/小数/2^k±/f16 上溢边界/随机位长）。
独立数学 oracle（只用整数算术，与被测电路无共享代码）：
- `o_int2fp`：8/16/32/64 位整数 → f16/f32/f64，五种 IEEE 舍入，OF/NX；
- `o_fp2int`：f16/f32/f64 → 8/16/32/64 位有/无符号，RISC-V 饱和与 NV/NX 语义；
- `o_estimate7`：RVV 规范算法 vfrec7 / vfrsqrt7（含非规格化输入规格化、结果非规格化、上溢按 rm）。
f2f（变宽/变窄）无 oracle，只靠双例化。VCVT_8 只做双例化（Mgu 合并语义不写 oracle）。

UT 结果见文末「UT 结果」节（在被证 commit 的字节上跑，FM 起跑前已开跑）。

## 3. 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（merge_dup=false 严格适用）。

| 目标 | 预测 passing | regs + outs |
|---|---|---|
| INT2FP | 245 | 176 + 69 |
| Estimate7 | 259 | 190 + 69 |
| CVT64_1 | 871 | 802 + 69 |
| VCVT | 871 | 802 + 69 |
| CVT32 | 460 | 423 + 37 |
| VCVT_1 | 460 | 423 + 37 |
| CVT16 | 193 | 172 + 21 |
| VCVT_2 | 193 | 172 + 21 |
| VectorCvt | 1662 | 1578 + 84 |
| VectorCvtTop | 3335 | 3167 + 168 |
| VCVT_8 | 5270 | 4474 + 796 |

其余预期：failing 0 / unverified 0 / unmatched 0 / 无黑盒 / SUCCEEDED。
差额预期全部可由 constant_reg + unread 指认，候选（两侧结构对称）：
- INT2FP：fflags[4,3,1] 复位后恒 0；expAdderIn0[0,11,12] 恒 0（不复位）。
- Estimate7：fracSrcLeft[11:0] 恒 0；fflags[1] 恒 0；expAdderIn0[12]、expAdderIn1[12] 不读（golden 只用 12 位和）。
- CVT32：clz_fp32_reg0[7:5] 恒 0；nor_of_exp_reg0[4:1] 恒 1；in_abs_reg0[32] 不读。
- CVT16：fflags0_reg1[14:5] 恒 0、[15] 不读（Scala 把 rec7(-Inf) 档的 fflags 写成 16 位）；out_sign_reg0 恒 0。
- 上层 = 子树之和（VectorCvt 含 CVT64_1×1 + CVT32×1 + CVT16×2，VectorCvtTop ×2）。

若 unread > 0：两侧都是 golden 同名寄存器的同名对称位，按 vmucp standing rule 六条在
`verif/fm_target_config/<T>.tcl` 声明后重证，不另请示；出现 failing 一律先修 RTL 对齐 golden。

## 4. 明写可能出错的地方

1. VCVT_8 的 payload（perfVec/seqNumVec）与 valid 链用数组/struct 写，golden 是平铺名（`perfVec_1_renameTime` /
   `validVecThisFu_1` / `fflagsEnCycle2_r_0`）；FCVT 先例同样写法无钉点配上。若出现 unmatched，先生成 fm_pins_pre.tcl 消名差。
2. 各 CVT 核里寄存器全部用 golden 同名（即 Scala 名），预期按名字直接配上。
3. 本节之前没有做过任何 FM 试跑。

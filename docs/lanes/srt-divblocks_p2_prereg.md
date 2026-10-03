# srt-divblocks lane 第二阶段 —— 跑前登记（SRT16Divint{,_4,_6} → VectorIdiv）

本文件在 **FM 起跑之前**提交 §0–§4；跑完在文末追加，★不修改已提交分节的任何数字★。
第一阶段（SelBlock_v4 / SpecBlock_v4 / IterBlock_v4{,_4,_6} / I8DivNr4）见 `srt-divblocks_prereg.md`。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | `3b2e50dd`（集成者把 main `040f7185` 合入本分支并追加第二阶段认领）；实现 commit `cb613b07` |
| 目标 | `SRT16Divint`、`SRT16Divint_4`、`SRT16Divint_6` → `VectorIdiv` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| 冲突核查 | 全部分支 `diff main...` 的 rtl 无 SRT16Divint*/VectorIdiv；全部 worktree 的 claim 只有本 lane；codex outbox 无相关消息 |
| child 状态 | SRT4qdsCons、IterBlockI8Nr4、CSA3_2_*、SignDec、Conversion* = PROVEN_DIRECT；SelBlock_v4 / SpecBlock_v4 / IterBlock_v4{,_4,_6} / I8DivNr4 = 本 lane 第一阶段签（已合 main `040f7185`） |
| 已签件改动 | **无**——第一阶段 6 个目标的 RTL 字节一个未改（`git diff 040f7185 HEAD -- rtl/backend/{SelBlock_v4,SpecBlock_v4,IterBlock_v4*,I8DivNr4}.sv` 为空） |

## 1. 结构

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` | 子模块（两侧白盒） |
|---|---:|---:|---:|---|
| SRT16Divint | 937 | 874（`rtl/backend/SRT16Divint.sv`，含家族核与三变体的 IterBlock 生成连线） | 0 | SRT4qdsCons、IterBlock_v4 |
| SRT16Divint_4 | 1004 | 44（薄 wrapper，BIT_WIDTH=32） | 0 | SRT4qdsCons、IterBlock_v4_4 |
| SRT16Divint_6 | 1131 | 44（薄 wrapper，BIT_WIDTH=64） | 0 | SRT4qdsCons、IterBlock_v4_6 |
| VectorIdiv | 560 | 315（`rtl/backend/VectorIdiv.sv`） | 0 | I8DivNr4 ×8、SRT16Divint ×4、_4 ×2、_6 ×2（实例名同 golden） |

- `xs_SRT16Divint_core #(BIT_WIDTH)`：§1 状态机 / §2 握手拍扩展取绝对值 / §3 PRE0 前导零与粗规格化 /
  §4 PRE1 规格化、特殊情况、对齐、预算常数 / §5 ITER / §6 POST-OUTPUT。寄存器复用（iterB_reg、iter_q_A/B）照 Scala；
  商位 0 的常数不建寄存器（golden 也没有），只存 4 个非零档 `*_nz_reg`。
- `scripts/gen_srt16divint.py`（带 `--check`）：核内 IterBlock 扁平端口连线（三变体 generate 分支，fail-closed 映射）
  与 `_4/_6` 薄 wrapper；并核对手写的 16 位 wrapper 与 golden 端口表一致。
- VectorIdiv：车道分配表（元素 → 除法器）写成 §2 的操作数选择与 §4 的结果拼接。

## 2. UT（RTL 字节 = `cb613b07`；读数在 §6 追加）

- `verif/ut/SRT16Divint`：三位宽各一对 golden vs `_xs`（整棵子树为重写件），共用 `div_lane.sv`：逐拍对拍 + 独立
  RISC-V 除法 oracle（除零/负数/最小值÷-1/各合法 sew），越界 sew 只对拍；判据每车道 ≥5000 次除法。
- `verif/ut/VectorIdiv`：golden vs `_xs`，逐拍对拍 in_ready/out_valid/128 位商余数 + **按 SEW 分元素的 oracle**
  （n = 8<<sew，逐元素 RISC-V 语义）；握手后输入口立刻换垃圾；判据 ≥3000 条向量且每档 sew ≥500。
- ★驱动时序 bug 已修★：`div_lane.sv` 原先用上一拍的 out_ready 判握手，与 DUT 实际握手错一拍（VectorIdiv UT 首跑时
  车道失步、把忙时乱拉的 in_valid 变成 DUT 真接收的垃圾操作 ⇒ oracle 报错，golden 与重写件两侧一致）。修正后
  第一阶段的 SRT16IterBlocks / I8DivNr4 两个 UT 也用新驱动重跑九档（旧读数的结果比对没有被这个 bug 污染——
  它只会让车道停摆或少查，不会拿错的操作数去查——但吞吐与「ignored_in_valid」计数不准，故重跑）。
- 档位：seed 1/7/42 × `+vcs+initreg+0` / `random` / `<seed>017`，各 200k 拍。

## 3. 证明计划

FM 先**诊断跑**（`make fm-<T> FM_MODE=diagnostic-full`，不进 evidence）看配对与 unread，再按需要补钉点 / vmucp，
补登 §5 后跑 official。理由：SRT16Divint 有 ~150 个寄存器、核里是数组（golden 平铺），VectorIdiv 有 16 个子实例
挂在 `u_core/` 下，名字匹配能否自动配上无法事先判断；第一阶段 I8DivNr4 已证明数组死位需要钉点。

## 4. 跑前预测（★跑完不许改本节★，登记 `docs/fm_predictions/<T>.json`）

| 目标 | expected（regs + outs） | 预测 | 其余 |
|---|---:|---|---|
| SRT16Divint | 1165（1132 + 33） | passing = 1165 − constant_reg，unread **0** | failing / unmatched / 黑盒全 0 |
| SRT16Divint_4 | 1423（1358 + 65） | 同上 | 同上 |
| SRT16Divint_6 | 1937（1808 + 129） | 同上 | 同上 |
| VectorIdiv | 12388（12130 + 258） | unread **32**（8 × I8DivNr4 的 const_d_reg_k[9]），constant_reg = 8×1 + 4×c16 + 2×c32 + 2×c64 | 同上；需钉点 + vmucp 后 passing = 12388 − constant_reg |

constant_reg 的已知下限：每个 SRT16Divint 变体 iter_cons_reg_0/1/3/4 的低 4/3/3/4 位恒 0 = 14 位；另有 SRT4qdsCons
查表在 8 行里恒定的位（例如四张表的值都是 4 的倍数 ⇒ `m[1:0]` 恒 0）经 sel_cons_reg / spec_cons_reg 以及 PRE1 装入的
sel_reg/spec_reg 初值传成常量寄存器位——**没有逐位推算**，以 receipt 的 constant_reg 指认（fm_predict 的对账判据是
差额 = constant_reg + unread）。

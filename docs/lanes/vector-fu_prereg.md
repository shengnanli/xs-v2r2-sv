# vector-fu lane（agent/vector-fu）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `8af07f3f9`（main 上集成者预建 claim） |
| 工作树 | `/home/eda/xs-env/wt-vector-fu`，分支 `agent/vector-fu` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），无 dont_verify |

## 1. VecDataSplitModule（golden 152 行，纯组合叶子）

### 1.1 为什么原有重写件没有 receipt

`rtl/backend/VecDataSplitModule.sv` 来自 `5ccd73c62`（newrtl-next200c「checkpoint recovered readable leaf
implementation」——该 commit 明说只是实现 bring-up checkpoint，不声称 UT/FM 签核）。全仓（含各 worktree）
没有它的 UT 目录、Makefile FM_VARIANTS 条目或任何 evidence/*/VecDataSplitModule。另外它是单个 module
（无 `xs_*_core`），不合单文件规范。本 lane：改成 `xs_VecDataSplitModule_core`（packed 数组按元素宽度重解释）+
golden 同名 wrapper，新建 `verif/ut/VecDataSplitModule`。

### 1.2 UT（9 档 × 200k，commit ab6b77c6d 的字节）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |
| 7  | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |
| 42 | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED | checks=200000 errors=0 PASSED |

oracle_errors=0（独立逐元素取位）；覆盖：全部 30 个输出的每一位都见过 0 和 1（PASS 判据）。
变异自证（scratchpad，5k 拍）：M1 16 位视图第 3 元素接成第 4 元素 ⇒ errors=3125；M2 8 位视图元素反序 ⇒ errors=3506。
纯组合无寄存器，initreg 三档对行为无影响（照规范仍跑）。

复跑：`cd verif/ut/VecDataSplitModule && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/VecDataSplitModule.json）

| 项 | 预测 |
|---|---|
| passing | **512**（寄存器 0 + 输出位 16×8+8×16+4×32+2×64 = 512） |
| failing / unverified / aborted / unread | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| 黑盒 / dont_verify / vmucp | 无 / 无 / 不开 |
| verdict | SUCCEEDED（signoff-strict） |

没有做过任何 FM 试跑。

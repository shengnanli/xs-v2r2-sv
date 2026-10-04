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

## 2. FloatAdderF64Pipeline（golden 334 行；重写 313 行）

### 2.1 结构与子模块处置

- 标量 f64 加法器顶层（FloatAdder 的 f64 通路）：`xs_FloatAdderF64Pipeline_core`（§1 拆字段 / §2 特殊值 / §3 far-close
  两路 / §4 min-max-比较-sgnj-fclass / §5 第 0 拍寄存器 / §6 第 1 拍选择）+ golden 同名 wrapper。
- child：FarPathFloatAdderF64WidenPipeline（evidence/6038c4afbc60）、ClosePathFloatAdderF64WidenPipeline（evidence/5990b596a86b）
  及其闭包全部已签核 → 两侧白盒（ref golden / impl 重写件），无黑盒。
- 寄存器逐个对应 golden 15 个 reg（含两个指数/尾数恒常量的 64 位特殊结果寄存器，整宽照留）。

### 2.2 UT（9 档 × 200k，commit d939ecbb6 的字节）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=199999 errors=0 PASSED | checks=199999 errors=0 PASSED | checks=199999 errors=0 PASSED |
| 7  | checks=199998 errors=0 PASSED | checks=199998 errors=0 PASSED | checks=199998 errors=0 PASSED |
| 42 | checks=199999 errors=0 PASSED | checks=199999 errors=0 PASSED | checks=199999 errors=0 PASSED |

独立 IEEE oracle（fp_add_oracle_pkg + 本目录 fp64_misc_oracle_pkg）全部 oracle_errors=0。覆盖（seed 1 / +0）：
oracle 186956 次，far 55181 / close 14635，NaN 结果 19601 / Inf 结果 1742，NV 6675 / OF 906 / NX 43921，
canonical 标志 a/b 11712/11675，15 个已定义 op 码各 >= 1000，fire=0 拍 50090，输出每位见过 0/1（PASS 判据）。
变异自证见文末对账节（证明起跑后在 scratchpad 跑，不进库）。

复跑：`cd verif/ut/FloatAdderF64Pipeline && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 2.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/FloatAdderF64Pipeline.json）

模型 expected = 1075（golden 闭包寄存器位 1006 = 本体 334 + far 361 + close 311；顶层输出位 69）。
预期 constant reg（不进 passing）共 **131**：
- 本体 126：`float_adder_result_r_1[62:0]`（Inf 结果的指数全 1 / 尾数 0，63 位）+ `float_adder_result_r_2[62:0]`（两零结果低 63 位恒 0）；
- 本体 4：`io_fflags_r_1[3:0]`（非加减类 fflags 低 4 位恒 0）；
- close 子树 1：`U_close_path/U_CS4_io_adder_op1_r_reg[52]`（恒 0 减数 MSB；子树自身签核时 constant_reg=1 即此点）。

vmucp（standing rule 六条，`verif/fm_target_config/FloatAdderF64Pipeline.tcl` + `verif/ut/FloatAdderF64Pipeline/fm_pins.tcl`
字面 3 对）：close 子树两侧对称死位 CS4 op0[52] / CS4 op1[52] / Lshift src[53]，与子树自签核同一组。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| passing | **944**（= 1075 − 131） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 131 |
| 黑盒 / dont_verify | 无 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

没有做过任何 FM 试跑；常量位数按 golden 源码逐个寄存器数出，若 FM 的常量折叠多/少于此，差额在对账节逐位指认。

## 对账（跑完追加）

### A. VecDataSplitModule —— evidence/a29f86c7a27c/VecDataSplitModule

`bash scripts/run_proof.sh VecDataSplitModule VecDataSplitModule < /dev/null`（commit a29f86c7a）：
native SUCCEEDED，passing 512 / failing 0 / unverified 0 / aborted 0 / unread 0，unmatched 全 0，黑盒 0，dont_verify 无。
impl_closure `rtl/backend/VecDataSplitModule.sv` sha256 4c5691e6…（= 提交字节）。
预测 512 vs 实测 512，差 0（`fm_predict.py check VecDataSplitModule` rc=0）。

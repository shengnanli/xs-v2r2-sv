# fpu-parents lane · group adder64（agent/fpu-parents）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | 分支 `agent/fpu-parents`（worktree `/home/eda/xs-env/wt-fpu-parents`，认领 `docs/lanes/fpu-parents_claim.md`）；本 group 的 RTL/UT 提交 `05017d284` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 设计源 | `yunsuan/vector/VectorFloatAdder.scala`（FarPathAdderF64WidenPipeline / ClosePathFloatAdderF64WidenPipeline）、`yunsuan/fpu/FloatAdder.scala`（FloatAdderF32F16MixedPipeline） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify、无黑盒 |
| 冲突检查 | 主 agent 已查：codex outbox / codex 分支 / 全部 worktree claim+prereg / 各分支 rtl diff 无本 group 目标；FAlu UT 无别的分支在改 |

## 1. f64 路径件（UT 目录 `verif/ut/FpAddPathF64W`）

### 1.1 结构与 child 处置

| 目标 | golden 行 | golden `_GEN_`/`_T_` | impl 行 | impl `_GEN_`/`_T_` | child（两侧白盒：ref golden 件 / impl 本仓重写件） |
|---|---:|---:|---:|---:|---|
| FarPathAdderF64WidenPipeline | 126 | 0 | 47 | 0 | 无（叶子） |
| ClosePathFloatAdderF64WidenPipeline | 705 | 323 | 256 | 0 | ClosePathAdder ×3 / ClosePathAdder_2 ×2 / CloseShiftLeftWithMux（均 PROVEN_DIRECT） |

寄存器与 golden 逐位对应（含 golden 的同源多份：选中候选两份、sel_CS4 两份、EA 两份 + EA-1 一份、"下限位命中"存整条 54 位）。

### 1.2 UT（commit `05017d284` 的字节；两目标同一个 tb，golden 与 `<名>_xs` 各自双例化，200k 拍）

独立 oracle（`verif/ut/FpAddPathF64W/fp_add_oracle_pkg.sv`，纯整数算术）：加法器 = (A+B) mod 2^54；close path 在前提域
（指数均非全 1、|Ea−Eb| ≤ 1、rm ∈ 0..4）内 fp_c == round_rm(sign_a·(|a|−|b|))、fflags == {0000,NX}；CS1 == {0,sig_b}−{0,sig_a}。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=799996 errors=0 PASSED | errors=0 PASSED（seed 1 random 档退化为全 1） | initreg+1017 errors=0 PASSED |
| 7  | checks=799996 errors=0 PASSED | errors=0 PASSED | initreg+7017 errors=0 PASSED |
| 42 | checks=799996 errors=0 PASSED | errors=0 PASSED | initreg+42017 errors=0 PASSED |

覆盖（seed 1，判据写在 tb 里）：sel_cs0..4 = 56425/43515/46719/50570/2770；close oracle 比对 132431 次（0 违例）；精确为 0 13781；
非规格数结果 17339；下限位命中 23285；NX 3344；rm 0..4 全出现；每个输出位翻转过（fflags 高 4 位为 golden 字面 0）。
复跑：`cd verif/ut/FpAddPathF64W && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model <T> --ut FpAddPathF64W`）。

| 目标 | 模型 | 预测 constant_reg | 预测 passing | 其余 |
|---|---:|---:|---:|---|
| FarPathAdderF64WidenPipeline | 162（108+54） | 0 | **162** | 无 vmucp、无钉点；unread / failing / unverified / unmatched 0 |
| ClosePathFloatAdderF64WidenPipeline | 434（311+123） | 1（`U_CS4_io_adder_op1_r_reg[52]`，恒 0） | **433** | 钉 3 对（`fm_pins.tcl`，fail-closed）+ vmucp；unread 0 / failing 0 / unmatched 0 |

★登记前做过一次诊断跑（如实记）★：`FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，commit `05017d284`，无钉点、vmucp 关，
不产 receipt：ClosePath native SUCCEEDED passing 431 / failing 0 / unmatched compare 0，3(3) unmatched unread =
op0_r[52] / op1_r[52] / U_Lshift_io_src_r[53]（ref 与 impl 一一对应）。钉点与 vmucp 白名单
（`verif/fm_target_config/ClosePathFloatAdderF64WidenPipeline.tcl`）据此建立。预测 433 的依据：f32 那份
（ClosePathF32WidenF16MixedPipeline）钉上后恒 0 的减数 MSB 被 FM 归回 constant_reg，其余两点 +2。

### 1.4 明写可能出错的地方

1. 若 op1_r[52] 钉上后仍算 passing（不归 constant），passing 将为 434、constant_reg 0——差额仍可指认，照实记。
2. 同源多份寄存器在 merge_dup=false 下应各自成比较点；若 passing 少了恰好双份的位数，是配对问题不是 RTL 问题。

## 2. FloatAdderF32F16MixedPipeline（UT 目录 `verif/ut/FloatAdderF32F16MixedPipeline`）

### 2.1 结构与 child 处置

golden 395 行（`_GEN_`/`_T_` 28）→ impl `rtl/backend/FloatAdderF32F16MixedPipeline.sv` 368 行，`_GEN_`/`_T_` 0。
child：FarPathF32WidenF16MixedPipeline / ClosePathF32WidenF16MixedPipeline（fpaddpath-sqrtblock lane 签核，evidence/1a44b00c0b57）
及其孙子 Adder_2 / FarShiftRightWithMuxInvFirst_2 / FarPathF32WidenF16MixedAdderPipeline / ClosePathF32WidenF16MixedPipelineAdder(_2) /
CloseShiftLeftWithMux_1（PROVEN_DIRECT）→ 全部两侧白盒（ref golden、impl 重写件），无黑盒。顶层寄存器 19 个逐位对应 golden
（含同源双份：`io_fp_c_r`/`io_fflags_r`、`fadd0_result0_r`/`_r_1`（17 位复制）、`fadd0_result1_r`/`_r_1`）。

### 2.2 UT（commit `05017d284` 的字节，200k 拍）

差分（golden vs `_xs`，逐拍比 fp_c / fflags）+ **独立 IEEE oracle**（对照上次 fire 的输入）：fadd/fsub 走 `exact_add`
（五种舍入、NX/OF、NaN/无穷/零特殊值、NV）；fmin/fmax/fminm/fmaxm/feq/flt/fle/fltq/fleq/fsgnj*/fclass 按 RISC-V F/Zfa 语义；
其余 op 结果 0。oracle 显式建模的两条 golden 怪癖（UT 首跑实测发现，照 Scala）：b 为零时结果是整个 32 位 io_fp_a
（f16 时高 16 位不清）；f16 两零相加得 −0 时符号复制 17 份（0xFFFF8000）。

| seed | `+vcs+initreg+0` | `+random` | `+<seed>017` |
|---|---|---|---|
| 1  | checks=199999 errors=0 PASSED | PASSED | PASSED |
| 7  | checks=199999 errors=0 PASSED | PASSED | PASSED |
| 42 | checks=199999 errors=0 PASSED | PASSED | PASSED |

覆盖（seed 1）：oracle 比对 185820；far / close 被选中 52330 / 18806；NV 11286 / OF 1987 / NX 38406；13 个比较类 op 各 ≥ 500；
fp_c 每位、fflags 每位（DZ/UF 为 golden 字面 0）都翻转过。
复跑：`cd verif/ut/FloatAdderF32F16MixedPipeline && make run SEED=<s> INITREG=<0|random|<s>017>`

### 2.3 跑前预测

| 目标 | 模型 | 预测 constant_reg | 预测 passing | 其余 |
|---|---:|---:|---:|---|
| FloatAdderF32F16MixedPipeline | 396（359+37） | 36 | **360** | 钉 4 对 + vmucp；unread 0 / failing 0 / unmatched 0 / 无黑盒 / SUCCEEDED |

★登记前诊断跑（如实记）★：commit `05017d284`，无钉点、vmucp 关：native SUCCEEDED passing 357 / constant_reg 35 /
4(4) unmatched unread（far FS1 `io_result_r_2[0]`、close CS4 op0/op1 MSB、左移源 MSB，ref/impl 一一对应），
与向量那份父级 FloatAdderF32WidenF16MixedPipeline 同一组点。预测：钉 + vmucp 后 3 点实比（+3），恒 0 的 op1 MSB 归 constant_reg（35→36）。

## 3. 变异自检（scratch 镜像树，不进库；每个 20k 拍 seed 1 initreg 0）

14/14 CAUGHT：close lzd 偏一（18082）、下限掩码偏一（1408）、head_is_one 用 >=（1566）、NX 漏 sel_cs4（239）、恰好抵消符号改 RUP（575）、
CS4 减数没右移（239）、far 加法改按位或（17093）、fadd 漏"0 对 1 走 far"项（1）、f16 −0 只复制 1 份（6）、fmin 用 b_greater（896）、
flt 只在 sNaN 置 NV（230）、fclass 次正规/零对调（40）、b 为零时清 f16 高位（97）、is_far_path 用 [7:2]（112）。

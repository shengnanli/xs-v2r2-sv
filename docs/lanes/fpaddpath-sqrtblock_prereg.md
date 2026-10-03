# fpaddpath-sqrtblock lane（agent/fpaddpath-sqrtblock）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3cd470621`（worktree `/home/eda/xs-env/wt-fpaddpath-sqrtblock`，分支 `agent/fpaddpath-sqrtblock`，认领 `docs/lanes/fpaddpath-sqrtblock_claim.md`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 设计源 | `yunsuan/vector/VectorFloatAdder.scala`、`yunsuan/vector/vfsqrt/fpsqrt_r16_block.scala`、`yunsuan/fpu/fqrt/fpsqrt_r16.scala` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify、无黑盒 |
| 冲突检查 | codex outbox 0181 只做过 ClosePath*Adder 叶子（本 lane 的 child，已签）；全部 worktree 的 claim/prereg 与各分支 rtl diff 无本 lane 目标 |

## 1. far / close 两条加法路径（UT 目录 `verif/ut/FpAddPathF32W16`）

### 1.1 结构与 child 处置

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` | child（两侧白盒：ref golden 件 / impl 本仓重写件） |
|---|---:|---:|---:|---|
| FarPathF32WidenF16MixedAdderPipeline | 128 | 66 | 0 | 无 |
| FarPathF32WidenF16MixedPipeline | 327 | 308 | 0 | Adder_2 ×2、FarShiftRightWithMuxInvFirst_2 ×2（均 PROVEN_DIRECT）、FarPathF32WidenF16MixedAdderPipeline ×2（本 lane） |
| ClosePathF32WidenF16MixedPipeline | 477 | 270 | 0 | ClosePathF32WidenF16MixedPipelineAdder ×3 / _2 ×2、CloseShiftLeftWithMux_1（均 PROVEN_DIRECT） |

寄存器与 golden 逐位对应（含 golden 的同源双份：far 的两份 EOP 打拍、close 的两份 sel_CS4 与 LZD 的 5 位 / 8 位两份；
切段加法器的 7 位"进位加数"寄存器高 6 位恒 0 也照抄 7 位宽），所以不需要 fm_pins。

### 1.2 UT（commit `ab8a10acf` 的字节；三目标同一个 tb，golden 与 `<名>_xs` 各自双例化，200k 拍）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=1599992 errors=0 PASSED | 同左 PASSED（注：seed 1 的 random 档退化为全 1） | initreg+1017 errors=0 PASSED |
| 7  | checks=1599992 errors=0 PASSED | errors=0 PASSED | initreg+7017 errors=0 PASSED |
| 42 | checks=1599992 errors=0 PASSED | errors=0 PASSED | initreg+42017 errors=0 PASSED |

覆盖（seed 1，判据写在 tb 里）：close 五选择 sel_cs0..4 = 60129/44151/46531/46971/2217；far 正常不进位/正常进位/溢出不进位/
溢出进位 = 72793/32878/68328/26000；上溢 13292；移位溢出 59388；每个输出位都翻转过（golden 字面 0 的 fflags 位除外）。

复跑：`cd verif/ut/FpAddPathF32W16 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model <T> --ut FpAddPathF32W16`）。

| 目标 | 模型 | 预测 constant_reg | 预测 unread（vmucp 前） | 预测 passing（vmucp 开） |
|---|---:|---:|---:|---:|
| FarPathF32WidenF16MixedAdderPipeline | 57（32+25） | 6（`io_result_r_1[6:1]`） | 0 | **51**，不开 vmucp |
| FarPathF32WidenF16MixedPipeline | 142（96+46） | 12（U_FS0 / U_FS1 各 6） | 1（U_FS1 `io_result_r_2[0]`） | **130** |
| ClosePathF32WidenF16MixedPipeline | 162（100+62） | 4（`U_CS4_io_adder_op1_r[23]`、`EA_sub_value_reg_r_1[7:5]`） | 2（`U_CS4_io_adder_op0_r[23]`、`U_Lshift_io_src_r[24]`） | **158** |

其余：failing 0 / unverified 0 / unmatched 六项 0 / 黑盒 0 / dont_verify 无 / SUCCEEDED。
vmucp 依据与六条判据见 `verif/fm_target_config/{FarPath,ClosePath}F32WidenF16MixedPipeline.tcl`。

### 1.4 明写可能出错的地方

1. 常量寄存器：golden 与 impl 寄存器宽度逐位相同，常量位两侧都有；若 FM 把某侧常量位报成 unmatched，先查配对。
2. 同源双份寄存器在 merge_dup=false 下应各自成比较点；若 passing 少了恰好双份的位数，是配对问题不是 RTL 问题。
3. 本节登记前没做过任何 FM 试跑。

## 对账 §1（far / close 路径）

| 目标 | 证明 commit | 结果 | passing 预测/实测 | constant_reg | unread | unmatched | 黑盒 / dont_verify | receipt sha256 |
|---|---|---|---|---|---|---|---|---|
| FarPathF32WidenF16MixedAdderPipeline | `3e88b302e` | SUCCEEDED | 51 / **51** | 6 | 0 | 0 | 0 / 无 | `a55b013d6a9c0703465bbaee4e10453918f652895c640cf5d64e8bec1d7e7018` |
| FarPathF32WidenF16MixedPipeline | `1a44b00c0` | SUCCEEDED | 130 / **130** | 12 | 0（vmucp 实比 1 点） | 0 | 0 / 无 | `153e69c2cd68c152303e31eb004f98b5d7ee1002bc16e41df0e5900643886293` |
| ClosePathF32WidenF16MixedPipeline | `1a44b00c0` | SUCCEEDED | 158 / **158** | 4 | 0（vmucp 实比 2 点 + 1 常量点） | 0 | 0 / 无 | `a1e0d9fdc4146865d21f20794f05fb3112c3ad8c8fa37fff127f59b9fa9a01b9` |

`python3 scripts/fm_predict.py check` 三目标 rc=0，差额全部被 constant_reg 指认。

★首跑（`3e88b302e`）偏离登记的地方，照实记★：Far/Close 两个本体首跑 PARTIAL（`strict_unread!=0`）——
预登记以为对称死位是 matched unread、开 vmucp 就会比；实测是 **unmatched** unread（firtool 名与重写核字段名不同、
死位又没有扇出签名），vmucp 单开空转（Far passing 129、unread 1；Close passing 156、unread 3、constant_reg 3）。
Close 的第 3 个 unread 是 `U_CS4_io_adder_op1_r_reg[23]`（恒 0 的减数 MSB），预登记把它算在 constant_reg 里。
修法：`verif/ut/FpAddPathF32W16/fm_pins.tcl` 按 $top 字面钉 1 / 3 对（fail-closed，fm.log 回显
`FPADD_PIN_END n=1 expect=1` / `n=3 expect=3`），钉点基线 `docs/pin_call_seq.tsv` 登记两行。钉上之后
Close 的 op1[23] 被 FM 归回 constant_reg（4），passing 与预测逐位相等。vmucp 六条：精确绑定（Far 1 点 / Close 2 个
真死位 + 1 个常量位）/ 双射（钉点 1↔1、3↔3）/ 真比较（Far 129→130 = +1；Close 156→158 = +2，另 1 点转 constant）/
全零 / 无 dont_verify、无 elab147、无黑盒 / tcl 进 sidecar script_closure。首跑 receipt 留档 `evidence/3e88b302e777/`。

复跑：`PROOF_COMMIT=<commit> bash scripts/run_proof.sh FpAddPathF32W16 <T> < /dev/null`

## 2. fpsqrt_r16_block（UT 目录 `verif/ut/fpsqrt_r16_block`）

### 2.1 结构与 child 处置

golden 3575 行（firtool 平铺，`_GEN_`/`_T_` 1386 处）→ impl `rtl/backend/fpsqrt_r16_block.sv` 668 行，`_GEN_`/`_T_` 0。
可读核分三层：`xs_fpsqrt_r16_step`（一级 radix-4：×4 + 段切口、5 候选投机 CSA、on-the-fly 的 Q/QM 候选、
r4_qds_cg 比较常数、按数位 Mux1H）→ `xs_fpsqrt_r16_lane`（s0 r4_qds → step → s1 r4_qds_spec → step → 下一拍余数估计
预算）→ `xs_fpsqrt_r16_block_core`（拆包 4 条 lane、段切口位置、拼包）；golden 同名 wrapper 逐 lane 标量端口 ↔ 数组。
child：r4_qds ×4 / r4_qds_spec ×4 / r4_qds_cg ×40，coverage 第 3 列均 PROVEN_DIRECT → 两侧白盒（ref golden / impl 重写件）。
纯组合，零寄存器，无 fm_pins。

### 2.2 UT（commit `d35151c72` 的字节，200k 次组合调用）

差分（golden vs `_xs`，28 个输出口）+ **独立 oracle**：闭环开方——按 Scala fpsqrt_r16 的初始化公式为每个元素
（f16×4 / f32×2 / f64×1）装初态，把重写件输出喂回迭代 3/6/13 次，再逐元素与 tb 内逐位恢复法的整数平方根
`isqrt(X·2^(F+1))` 对照（余数符号选 Q / QM，且 余数==0 ⇔ 完全平方）。

| seed | `+vcs+initreg+0` | `+random` | `+<seed>017` |
|---|---|---|---|
| 1  | checks=5655565 errors=0 PASSED | 同 PASSED | PASSED |
| 7  | checks=5656681 errors=0 PASSED | 同 PASSED | PASSED |
| 42 | checks=5656172 errors=0 PASSED | 同 PASSED | PASSED |

覆盖（seed 1）：闭环 f16/f32/f64 = 7936/7873/8075 次，oracle 结果取 Q / QM = 34298 / 21267，完全平方 17530；
4 条 lane 的 s0/s1 五个数位全出现；28 个输出逐位翻转（结构恒定位除外：nxt_f_r_c_o[1]、cg 查表恒定位）。
复跑：`cd verif/ut/fpsqrt_r16_block && make run SEED=<s> INITREG=<0|random|<s>017>`

### 2.3 跑前预测

| 目标 | 模型 | 预测 passing | 其余 |
|---|---:|---:|---|
| fpsqrt_r16_block | 413（0 寄存器 + 413 输出位） | **413** | failing / unverified / unmatched / unread 0，constant_reg 0，无黑盒，无 vmucp，SUCCEEDED |

可能出错处：纯组合大锥（4 lane × 2 级 × 5 候选），若 FM 不收敛按规范 30 分钟采样。登记前未做 FM 试跑。

## 3. fpsqrt_r16（UT 目录 `verif/ut/fpsqrt_r16`）

### 3.1 结构与 child 处置

golden 559 行（`_GEN_`/`_T_` 57）→ impl `rtl/backend/fpsqrt_r16.sv` 441 行，`_GEN_`/`_T_` 0。§0 寄存器 / §1 预解码 /
§2 迭代初始化 / §3 child / §4 状态机 / §5 后处理分节；寄存器集合与位宽逐字对齐 golden（与已签的 fpsqrt_vector_r16 同一结构）。
child：lzc、r4_qds_cg（PROVEN_DIRECT）、fpsqrt_r16_block（本 lane §2）连同 r4_qds*，全部两侧白盒。

### 3.2 UT（commit `8a71cf568` 的字节，200k 拍）

差分（start_ready/finish_valid 每拍比，结果/标志在 finish_valid 时比）+ **独立 IEEE oracle**（tb 内逐位恢复法整数平方根，
规格化 + 偶指数 + 按 rm 舍入，特殊值按 IEEE；仅 ±0/+Inf/尾数全 0 的 NX 不比，原因见 tb 头）。

| seed | `+0` | `+random` | `+<seed>017` |
|---|---|---|---|
| 1  | checks=509384 errors=0 PASSED | PASSED | PASSED |
| 7  | checks=509752 errors=0 PASSED | PASSED | PASSED |
| 42 | checks=509616 errors=0 PASSED | PASSED | PASSED |

覆盖（seed 1）：finish 40298，oracle 比对 36139，余数为负 13637，舍入进位溢出 149，flush 打断迭代 1323，非规格数两拍初始化 3459；
3 格式 × 5 rm、9 类操作数 × 3 格式全过门槛；输出逐位翻转。

### 3.3 跑前预测

| 目标 | 模型 | 预测 constant_reg | 预测 passing | 其余 |
|---|---:|---:|---:|---|
| fpsqrt_r16 | 385（314 + 71） | 1（`m_pos_1_for_nxt_cycle_s0_qds_0_q[0]`：cg 表里 m_pos_1 的 bit0 恒 0） | **384** | unread 0 / failing 0 / unmatched 0 / 无黑盒 / SUCCEEDED |

可能出错处：重写件寄存器名与 golden 不同（nr_f_r_7b_q vs nr_f_r_7b_for_nxt_cycle_s0_qds_0_q 等），靠签名配对；若出现 unmatched 先查配对。

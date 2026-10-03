# fpu-parents lane · group adder16（agent/fpu-parents）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3f23a91cb`（worktree `/home/eda/xs-env/wt-fpu-parents`，分支 `agent/fpu-parents`，认领 `docs/lanes/fpu-parents_claim.md`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 设计源 | `yunsuan/vector/VectorFloatAdder.scala` class FarPathF16Pipeline / ClosePathF16Pipeline（exponentWidth=5、significandWidth=11、hasMinMaxCompare=true） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify、无黑盒 |
| 冲突检查 | codex outbox / codex 分支 rtl diff / 全部 worktree claim+prereg 均无这两个目标（见 lane 主报告） |

## 1. far / close 两条 f16 加法路径（UT 目录 `verif/ut/FpAddPathF16`）

### 1.1 结构与 child 处置

| 目标 | golden 行 | golden `_GEN`/`_T_` 行 | impl 行 | impl `_GEN_`/`_T_` | child（两侧白盒：ref golden 件 / impl 本仓重写件） |
|---|---:|---:|---:|---:|---|
| FarPathF16Pipeline | 322 | 28 | 292 | 0 | Adder_18 ×2、FarShiftRightWithMuxInvFirst_18 ×2（PROVEN_DIRECT）、FarPathAdderF16Pipeline ×2（coverage tsv 仍记 UNPROVEN 是台账未刷新；本仓重写件已 SUCCEEDED，evidence/1bf831352049） |
| ClosePathF16Pipeline | 363 | 72 | 251 | 0 | ClosePathAdderF16Pipeline ×3 / _2 ×2、CloseShiftLeftWithMux_9（均 PROVEN_DIRECT） |

寄存器集合与位宽逐位照 golden：far 50 位（含两份同源 EOP 打拍、sticky 原料两份 12 位向量）；close 81 位（含两份 sel_CS4、两份 EA、两份 CS_0123、恒 0 的 CS4 减数 MSB）。
close 钉点 `verif/ut/FpAddPathF16/fm_pins.tcl`（字面 3 对，fail-closed，`docs/pin_call_seq.tsv` 已登记），vmucp 条目 `verif/fm_target_config/ClosePathF16Pipeline.tcl`。

### 1.2 UT（commit `d5b0969b3` 的字节；两目标同一 tb，golden 与 `<名>_xs` 各自双例化，200k 拍）

差分（7 个输出口逐拍比）+ **独立 IEEE binary16 oracle**（tb 内以 2^-24 为单位的精确整数求和 + 按 rm 舍入 + 上溢按 rm 给 Inf/最大有限数）。
oracle 前提照父级 FloatAdderF16Pipeline 的选路（Scala `is_far_path`）：far = 有效相加 / |有效指数差| >= 2 / （差 1 且恰一个指数为 0）；close = 其余有效相减；
两者都要求操作数有限、rm <= 4。★首版按"差 <= 1 就归 close"写，close oracle 在"指数 2 对指数 0"上报 39 条——golden 与重写件一致，
是 close 自身只看指数低两位、父级正因此把这格路由给 far；oracle 前提改照父级选路后为 0★。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=1399993 errors=0 oracle_errors=0 PASSED | 同左 PASSED（seed 1 的 random 档退化为全 1） | initreg+1017 PASSED |
| 7  | checks=1399993 errors=0 oracle_errors=0 PASSED | PASSED | initreg+7017 PASSED |
| 42 | checks=1399993 errors=0 oracle_errors=0 PASSED | PASSED | initreg+42017 PASSED |

覆盖（seed 1 / +0，判据写在 tb 里）：close sel_cs0..4 = 68401/42597/43035/43703/2263；far 正常不进位/正常进位/溢出不进位/溢出进位 =
74566/30808/69326/25299；上溢 10368；移位溢出 48960；oracle 比对 far 89009（上溢 1765、NX 69096、非规格数结果 798）/ close 26505（NX 644、
恰好抵消 2951）；rm 0..4 全出现；每个输出位翻转过（golden 字面 0 的 fflags 位除外）。

变异自检（scratch 副本，20k 拍，不进库）：M1 去掉 far 舍入表的 EOP 项 errors=4761；M2 移位溢出门限 14→15 errors=2（★首版激励漏抓，
补"指数差 11..16、小数只剩最低几位"激励后抓到；指数差恰 15 且小数尾数=1 才区分★）；M3 sticky 选源反了 6925；M4 上溢幅值条件 91；
M7 抵消时 RDN 的 -0 去掉 305；M8 head_is_one 的 > 改 >= 1595；M9 下限掩码错位 954。
未抓到 2 个，均为等价变异：M5 LZD 全零默认值 12→11（全零只发生在 sel_CS4，此时 lzd 不被任何输出读——但它进 lzd_q 寄存器，FM 逐寄存器比会抓）；
M6 CS2 舍入判定加"b 非零"门控（b 指数为 0 时 exp_equal 恒为 1，sel_CS2 不可能成立，组合等价）。

复跑：`cd verif/ut/FpAddPathF16 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model <T> --ut FpAddPathF16`）。

| 目标 | 模型 | 预测 constant_reg | 预测 unread（vmucp 前） | 预测 passing |
|---|---:|---:|---:|---:|
| FarPathF16Pipeline | 125（98+27；98 = 本体 50 + FS0/FS1 各 24） | 0 | 0 | **125**，不开 vmucp |
| ClosePathF16Pipeline | 114（81+33） | 1（`U_CS4_io_adder_op1_r[10]`，恒 0） | 2（`U_CS4_io_adder_op0_r[10]`、`U_Lshift_io_src_r[11]`） | **113**（vmucp 开，钉 3 对） |

其余：failing 0 / unverified 0 / unmatched 六项 0 / 黑盒 0 / dont_verify 无 / SUCCEEDED。

### 1.4 明写可能出错的地方

1. close 的恒 0 位 op1[10]：f32 同构件实测先被报 unread、钉上后归 constant_reg；若本件 FM 把它记成 passing 或 unread，passing 偏 ±1，先查此点。
2. close 的同源双份（CS_0123 两份、EA 两份、sel_CS4 两份）靠签名配对，可能交叉配对——函数相同，交叉也应 passing；
   但 CS_0123 那两份的 bit11 一个死一个活，已钉死死的那份（U_Lshift_io_src_r[11] ↔ cs_selected_q[11]）。
3. far 预测无常量位、无死位；若出现，说明 FS1 的 bit0 链或 sticky 原料有我没看到的 DCE。
4. 本节登记前没做过任何 FM 试跑。

## 对账 §1（证明 commit `114e5cc01`，登记 commit 同一个——登记在先、证明钉在登记 commit 上）

| 目标 | 结果 | 模型 / 预测 / 实测 passing | constant_reg | unread（unread_notcompared） | unmatched（六项） | failing / unverified | 黑盒 / dont_verify / elab147 | receipt.json sha256 |
|---|---|---|---:|---:|---:|---|---|---|
| FarPathF16Pipeline | SUCCEEDED | 125 / 125 / **125**（逐位相等） | 0 | 0 | 0 | 0 / 0 | 0 / 无 / 无 | `0795b6bfb8428220a5f7ad4d6b7088a973ca875e7a57c073cda73bf61fb6b530` |
| ClosePathF16Pipeline | SUCCEEDED | 114 / 113 / **113** | 1 | 0（vmucp 开） | 0 | 0 / 0 | 0 / 无 / 无 | `22f7038b8d7768265b238bb149a4fb246330562ac356d6d2ce4e96c924192661` |

`python3 scripts/fm_predict.py check FarPathF16Pipeline ClosePathF16Pipeline` rc=0（Far 逐位相等；Close 差 1 = constant_reg 1）。
Close 的 constant_reg 1 个：FM 只给计数，逐名归属按 golden 字面（`U_CS4_io_adder_op1_r <= {1'h0, …}`，bit10 恒 0）推定，未另跑诊断取名。
vmucp 六条：精确绑定（钉点回显 `FPADD16_PIN_END top=ClosePathF16Pipeline n=3 expect=3`）/ 双射（3↔3 字面配对）/
真比较（unread_notcompared 0，两个死位 op0[10]、src[11] 进入 passing：113 = 114 − 1 constant）/ 全零 / 无 dont_verify、无 elab147、无黑盒、
无放宽 appvar / `verif/fm_target_config/ClosePathF16Pipeline.tcl` 进 sidecar script_closure（evidence/114e5cc0185f/ClosePathF16Pipeline/sidecar/sourced_002_ClosePathF16Pipeline.tcl）。

receipt：`evidence/114e5cc0185f/{FarPathF16Pipeline,ClosePathF16Pipeline}/`（已 `git add -f`，commit `64105fa3a`）。
复跑：`PROOF_COMMIT=114e5cc01 bash scripts/run_proof.sh FpAddPathF16 <FarPathF16Pipeline|ClosePathF16Pipeline> < /dev/null`
父级 FloatAdderF16Pipeline 为 UNPROVEN（无已签父级，无重证）。

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

## 3. FloatAdderF64WidenPipeline（golden 364 行；重写 365 行）

### 3.1 结构与子模块处置

- 向量 f64 / f32→f64 加宽加法器（VectorFloatAdder 的 64 位 lane）：`xs_FloatAdderF64WidenPipeline_core`（§1 选操作数 /
  §2 特殊值（f32 来源的 0x369 / 0x47F 指数）/ §3 far-close / §4 非加减类 22 个 op / §5 第 0 拍寄存器 / §6 第 1 拍选择）+ wrapper。
- child 同 §2（far / close 及闭包全部已签核，两侧白盒）。寄存器逐个对应 golden 16 个 reg（两个 64 位常量特殊结果寄存器整宽照留）。
- 钉点：`fm_pins_pre.tcl`（匹配前，字面 444 对：本体 16 寄存器 335 位语义名 + close 子树两对同源双份寄存器 109 位，
  依据见 §2 首跑失败的对账 B）+ `fm_pins.tcl`（匹配后，close 死位 3 对，同 §2）。

### 3.2 UT（9 档 × 200k，commit d939ecbb6 的 RTL 字节）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=199999 errors=0 PASSED | checks=199999 errors=0 PASSED | checks=199999 errors=0 PASSED |
| 7  | checks=199998 errors=0 PASSED | checks=199998 errors=0 PASSED | checks=199998 errors=0 PASSED |
| 42 | checks=199999 errors=0 PASSED | checks=199999 errors=0 PASSED | checks=199999 errors=0 PASSED |

独立 IEEE oracle 全部 oracle_errors=0；覆盖（seed 1 / +0）：oracle 152288，far 59040 / close 13941，加宽加法 27630（其中
加宽零操作数 3258、.wv 7087、vfwredosum 7036），NaN 结果 13659 / Inf 结果 3818，NV 8243 / OF 757 / NX 44263，22 个 op 各 >= 1000。
变异（scratchpad，30k 拍）：f32 零指数 0x369→0x36A ⇒ errors=380；vfwredosum 的 b 也加宽 ⇒ 1057；fsum_ore 掩码位换 mask[1] ⇒ 135；
比较符号改用选后操作数 ⇒ 382（oracle 0：向量单元不对加宽格式发比较，差分抓到）；f32 全 1 指数 0x47F→0x47E ⇒ 1613；
★UT 抓不到★：「零操作数直通」去掉 res_widening 门控（200k 拍 errors=0）——非加宽时 a=0 走 far/close 也精确给出 ±b，
推断为输出等价变异；FM 是最终裁判。

### 3.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/FloatAdderF64WidenPipeline.json）

模型 expected = 1076（寄存器 1007 = 本体 335 + far 361 + close 311；输出 69）。预期 constant reg **131**（同 §2：本体
float_adder_result_r_1[62:0] 63 + float_adder_result_r_2[62:0] 63 + io_fflags_r_1[3:0] 4 + close CS4 op1[52] 1）。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| passing | **945**（= 1076 − 131） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 131 |
| 黑盒 / dont_verify | 无 / 无 |
| verdict | SUCCEEDED |

没有做过 FM 试跑（同族 FloatAdderF64Pipeline 的第二个正式 run 在跑，本节登记早于本目标任何证明）。

## 4. FloatDivider（golden 166 行；重写 128 行）

### 4.1 结构与子模块处置

- 标量除法 / 开方单元外壳：`xs_FloatDivider_core`（§1/§2 启动分派与开方器格式码减 1 / §3 握手与结果汇合）+ wrapper；本层无寄存器。
- child：FloatDividerR64（evidence/6038c4afbc60）+ fpsqrt_r16（evidence/44292961f2c0）及其闭包全部已签核 → 两侧白盒，无黑盒。

### 4.2 UT（9 档 × 200k，commit d939ecbb6 的 RTL 字节）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=799990 errors=0 PASSED | checks=799990 errors=0 PASSED | checks=799990 errors=0 PASSED |
| 7  | checks=799990 errors=0 PASSED | checks=799990 errors=0 PASSED | checks=799990 errors=0 PASSED |
| 42 | checks=799998 errors=0 PASSED | checks=799998 errors=0 PASSED | checks=799998 errors=0 PASSED |

（checks = 每拍 4 个输出 × 200k。）独立 IEEE oracle（除法照抄 FloatDividerR64 UT、开方照抄 fpsqrt_r16 UT）全部 oracle_errors=0；
覆盖（seed 1 / +0）：除法 oracle 20595、开方 oracle 24585；除法结果类别 规格/非规格/上溢/NaN/∞/0 = 8627/3054/1647/4639/1270/1358；
标志 NV/DZ/OF/UF/NX = 1568/588/1647/2801/10436；flush 打断 1044、finish 反压 17476、两子单元同时在忙 70442 拍。
★UT 发现的 golden 行为★（照抄、写进 tb 头）：start 分派不看对外 start_ready，除法器在忙时开方器照样能接新运算（反之亦然）。
变异（scratchpad，20k 拍）：开方格式码不减 1 ⇒ errors=15106；start_ready 与改或 ⇒ 10048；结果汇合改优先级 ⇒ 13247；
b 的 canonical 标志接成 a 的 ⇒ 829。

### 4.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/FloatDivider.json）

模型 expected = 751（寄存器 680 = FloatDividerR64 366 + fpsqrt_r16 314；输出 71）。预期 constant reg **30**
（= 两个子单元自签核的 constant_reg 27 + 3，本层不约束它们的任何输入）。vmucp：FloatDividerR64 的 fp_format_onehot_q[2] 1 位
（`verif/fm_target_config/FloatDivider.tcl`，无钉点，预期 FM 按名配上）。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| passing | **721**（= 751 − 30） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 0(0) |
| constant_reg | 30 |
| 黑盒 / dont_verify | 无 / 无 |
| verdict | SUCCEEDED |

没有做过任何 FM 试跑。

## 对账（跑完追加）

### A. VecDataSplitModule —— evidence/a29f86c7a27c/VecDataSplitModule

`bash scripts/run_proof.sh VecDataSplitModule VecDataSplitModule < /dev/null`（commit a29f86c7a）：
native SUCCEEDED，passing 512 / failing 0 / unverified 0 / aborted 0 / unread 0，unmatched 全 0，黑盒 0，dont_verify 无。
impl_closure `rtl/backend/VecDataSplitModule.sv` sha256 4c5691e6…（= 提交字节）。
预测 512 vs 实测 512，差 0（`fm_predict.py check VecDataSplitModule` rc=0）。

### B. FloatAdderF64Pipeline —— 首跑 FAILED（未收录）→ 补「匹配前」钉点后 evidence/56fb4b9ce03f/FloatAdderF64Pipeline

**首跑（commit 9ba6efb8a，evidence/9ba6efb8ae1f，FAILED，不 add）**：native FAILED，passing 875 / failing 20（FM 默认 limit 截断，
「至少 20」）/ unverified 43 / unmatched 125+125，constant_reg 12。unmatched.rpt 逐类：本体常量位 119 对（ref
`float_adder_result_r_1[51:0]`/`_r_2[62:0]`/`io_fflags_r_1[3:0]` 为 DFF0X ↔ impl `s1_inf_result`/`s1_both_zero_result`/`s1_fflags_stage0`
为 DFF0，名字不同、又是常量无签名）+ close 子树两对同源双份寄存器 6 位（golden `U_Lshift_io_src_r[1:0]` / `lshift_result_head_is_one_r_1[1:0]` /
`close_fraction_result_r` / `EA_sub_value_r`，同一 D 输入两份，签名分析分不清）。20 个 failing 全是 `io_fp_c` 位，落在这些未配上寄存器的锥里。
**根因是配对，不是 RTL**：修法 = `verif/ut/FloatAdderF64Pipeline/fm_pins_pre.tcl`（commit 75f0b38a2，字面 443 对：本体 15 寄存器 334 位
按 golden 名 ↔ 语义名、close 两对按各自读者一一对应），RTL 一字未改（impl 闭包 sha 两跑相同：FloatAdderF64Pipeline.sv bb030055…）。
预测（§2.3）登记在首跑之前，未改。

**第二跑（PROOF_COMMIT=56fb4b9ce，`bash scripts/run_proof.sh FloatAdderF64Pipeline FloatAdderF64Pipeline`）**：
native SUCCEEDED，passing **944** / failing 0 / unverified 0 / aborted 0 / unread 0，unmatched 全 0，constant_reg **131**，黑盒 0，
dont_verify 无；钉点 `F64P_PIN_PRE_END n=443 bad=0`、`FADD64TOP_PIN_END n=3`。预测 944 / constant 131 —— 逐项相等；
`fm_predict.py check FloatAdderF64Pipeline`：1075 − 944 = 131 = constant_reg 131，rc=0。
vmucp 六条：(1) 精确绑定 = close 子树 3 点（钉点文件字面 3 对）；(2) 双射 3↔3；(3) 真比较：unread_notcompared 0、
3 点里 CS4 op1[52] 归 constant（含在 131 内）、其余 2 点进 passing（模型 1075 − 131 = 944 恰好全比）；(4) 全零；(5) 无 dont_verify / elab147 /
放宽 appvar / 黑盒；(6) `verif/fm_target_config/FloatAdderF64Pipeline.tcl` 在 sidecar/script_closure.list。
变异（scratchpad，30k 拍，判据 = 失配数）：sgnj 不做 canonical 修正 ⇒ errors=51；fltq 的 NV 改任意 NaN ⇒ 177；
去掉「差 1 且恰一个零指数归 far」 ⇒ 2；两零相加符号用 RUP ⇒ 42；fminm 不判 NaN ⇒ 97；fclass 不看 canonical ⇒ 15（全部 oracle 也同数抓到）。

### C. FloatDivider —— evidence/56fb4b9ce03f/FloatDivider

PROOF_COMMIT=56fb4b9ce，`bash scripts/run_proof.sh FloatDivider FloatDivider`：native SUCCEEDED，passing **721** / failing 0 / unverified 0 /
aborted 0 / unread 0，unmatched 全 0，constant_reg **30**，黑盒 0，dont_verify 无。预测 721 / 30 —— 逐项相等；
`fm_predict.py check FloatDivider`：751 − 721 = 30 = constant_reg 30，rc=0。vmucp 六条：(1) 精确绑定 = FloatDividerR64 的
fp_format_onehot_q[2] 1 位（FM 按名配上，无钉点）；(2) 双射 1↔1；(3) 真比较：unread_notcompared 0，passing 含此点（751 − 30 恰好全比）；
(4) 全零；(5) 无放宽、无黑盒；(6) `verif/fm_target_config/FloatDivider.tcl` 在 script_closure。

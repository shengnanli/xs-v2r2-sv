# fpu-parents lane · bku 组（agent/fpu-parents）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。（同 lane 其它组各有一份 `docs/lanes/fpu-parents_<组>_prereg.md`。）

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3f23a91cb`（worktree `/home/eda/xs-env/wt-fpu-parents`，分支 `agent/fpu-parents`，认领 `docs/lanes/fpu-parents_claim.md`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 设计源 | `src/main/scala/xiangshan/backend/fu/Bku.scala`（CountModule / ClmulModule / MiscModule / HashModule）；func 编码 `xiangshan/package.scala` `object BKUOpType` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify、无黑盒 |
| 冲突检查 | codex outbox 最新 0207 与全部 codex/* 分支 rtl diff 不含本组目标；全部 worktree 的 claim/prereg 里本组模块名只作为父级/孙辈被引用（misc-core_prereg 提到 HashModule 仍两侧同源），无人认领；各分支相对 main 的 rtl diff 无本组文件 |

## 1. Bku 四叶子（UT 目录 `verif/ut/BkuLeaves`）

### 1.1 结构与 child 处置

| 目标 | golden 行（`_GEN`/`_T_` 行） | impl 行 | impl `_GEN_`/`_T_` | 寄存器（golden 位） |
|---|---:|---:|---:|---|
| CountModule | 346（27） | 129 | 0 | funcReg 9 + c2 8×4 + cpopTmp 4×5 = 61 |
| ClmulModule | 255（0） | 95 | 0 | funcReg 9 + mul3 8×128 = 1033 |
| MiscModule | 174（26） | 78 | 0 | io_out_r 64 |
| HashModule | 151（5） | 93 | 0 | io_out_r 64 |

四者都是零子模块的叶子：无 child、无黑盒、impl 闭包只有本仓重写件。寄存器宽度与 golden 逐位对应（CountModule 的
funcReg 照抄 9 位，其中 [8:3] 两侧都无读者）。
可读核要点：CountModule 是前导零二叉归并树（s0 做到 8 位段、s1 归并到 64 位），s1 作用在寄存器 c2 上的归并逐位照抄
Chisel 拼接式（FM 里寄存器值域是任意值，换成"相加"只在合法值域等价——见 §1.2 变异 M8）；ClmulModule 是 GF(2) 乘法
（8 组部分积异或存寄存器，s1 异或成 128 位积按**整 9 位** funcReg 取段）；MiscModule 是 xperm.n/.b 查表；HashModule 是
SHA-256/512 Σ/σ 与 SM3 P0/P1 的循环移位异或。

### 1.2 UT（commit `538c07b90` 的字节；四对同一个 tb，golden 与 `<名>_xs` 双例化，200k 拍）

差分（四个 io_out 每拍比）+ **独立 oracle**（tb 内按 RISC-V 指令语义直接算：逐位数 clz/ctz/popcount、逐位异或的
无进位乘、按下标查表的 xperm、按规范 ROL 写法的 SM3 P0/P1 与 SHA Σ/σ；golden 的输出每拍也必须等于 oracle）。
从第一次 regEnable 起比（全部寄存器 RegEnable 不复位，每次 regEnable 全写）。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=800000 oracle=800000 errors=0 PASSED | 同左 PASSED（seed 1 的 random 档退化为全 1） | initreg+1017 errors=0 PASSED |
| 7  | checks=799996 oracle=799996 errors=0 PASSED | errors=0 PASSED | initreg+7017 errors=0 PASSED |
| 42 | checks=800000 oracle=800000 errors=0 PASSED | errors=0 PASSED | initreg+42017 errors=0 PASSED |

覆盖（seed 1，判据写在 tb 里，cov_fail=0）：clz / ctz 64 位结果 0..64 全 65 种、clzw / ctzw 0..32 全 33 种、cpop 65 种；
clmul / clmulh / clmulr / 其它编码 = 37923 / 37443 / 37371 / 37188；xperm.b 越界字节 334050；hash 十种函数
13570 / 13537 / 13817 / 13623 / 13483 / 13580 / 13415 / 13643 / 20721 / 20536；四个输出逐位见过 0/1（Count 高 57 位结构常 0 只要求见过 0）。

变异自检（scratch 副本改、独立编 simv，不碰工作树；seed 7、20k 拍）：

| 变异 | 结果 |
|---|---|
| M1 clz 两位编码 01→1 改成 10→1 | errors=6462 抓到 |
| M2 clzw/ctzw 选半交换 | errors=3745 抓到 |
| M3 clmulr 判"整 9 位 == 2"改成 funcReg[1] | errors=2121 抓到（越界 func 编码激励起作用） |
| M4 clmulr 取段改成 [127:64] | errors=3941 抓到 |
| M5 xperm.b 越界判据 [7:3] 改 [7:4] | errors=954 抓到 |
| M6 sha512sig1 的 SHR 改 ROR | errors=1242 抓到 |
| M7 sm3 P0/P1 选择交换 | errors=3836 抓到 |
| M8 s1 归并改成"高段全 0 则相加"（只在 c2 合法值域内等价） | **errors=0，UT 结构上看不见**：c2 只会被写入合法计数值；FM 把寄存器当自由变量，覆盖这一类 |
| M9 cpopw 取高 32 位 | errors=2734 抓到 |

复跑：`cd verif/ut/BkuLeaves && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model <T> --ut BkuLeaves`）。

| 目标 | 模型 | 预测 constant_reg | 预测 unread（vmucp 前） | 预测 passing |
|---|---:|---:|---:|---:|
| CountModule | 125（61+64） | 0 | 6（funcReg[8:3]） | **125**（vmucp 开，6 点实比） |
| ClmulModule | 1097（1033+64） | 456（mul3 每组 128 位里只有 [8g+70:8g] 共 71 位可能非 0，8×57） | 0 | **641**，不开 vmucp |
| MiscModule | 128（64+64） | 0 | 0 | **128**，不开 vmucp |
| HashModule | 128（64+64） | 0 | 0 | **128**，不开 vmucp |

其余：failing 0 / unverified 0 / unmatched 0 / 黑盒 0 / dont_verify 无 / SUCCEEDED。
CountModule 钉点：`verif/ut/BkuLeaves/fm_pins_pre.tcl` 整寄存器 funcReg 9 位字面钉（fail-closed，期望回显
`BKULEAVES_PIN_END top=CountModule n=9 expect=9`），基线 `docs/pin_call_seq.tsv` 一行；vmucp 依据 `verif/fm_target_config/CountModule.tcl`。

### 1.4 明写可能出错的地方

1. 重写件寄存器在 `u_core` 层次下、名字是数组（`u_core/c2_reg[3]`、`u_core/mul3_reg[5]`），golden 是平铺名（`c2_3_reg`、
   `mul3_5_reg`）；活位预期靠签名分析配上。若出现 unmatched，先查配对，再考虑扩钉点。
2. ClmulModule 常量位：若 FM 不把 mul3 的常 0 位判成 constant_reg 而是报 unmatched / unread，passing 会偏离 641。
3. CountModule 的 out[63:7] 两侧都是字面 0，按惯例算作 passing 的输出点（在模型 64 个输出位里）。
4. 本节登记前没做过任何 FM 试跑。

## 1.5 已签父级重证：只列不做

| 父级 | 状态 | 为什么本 lane 不做 |
|---|---|---|
| Bku（`verif/ut/Bku`，PROVEN_DIRECT） | 当前四叶子 + CryptoModule 两侧同源 golden（RTL_GOLDEN_DEPS） | `agent/misc-core`（未合入 main，已有 Bku 首跑 receipt）正在改同一个 Makefile（BlockCipherModule 改读重写件、FM_MERGE_DUP=false、开 vmucp）。本 lane 再改会冲突，且两边任一份 receipt 在合并后闭包都会变（STALE）。待 misc-core 合入后，在一个 commit 上把 Count / Clmul / Misc / Hash 四个挪到 impl 侧重证（预期 Bku.tcl 白名单的 countModule[3..8] 死位改由 BkuLeaves 同型钉点配对）。 |
| CryptoModule | MISSING / PROVEN_IN_CONE（未签） | 未签核；且其另一个 child BlockCipherModule 归 misc-core，未合入 main。只列不做。 |

## 对账 §1（证明 commit `f696c5c84`，登记 commit 同为 `f696c5c84`，早于证明；首跑即正式跑，无试跑）

| 目标 | 结果 | 模型 / 预测 / 实测 passing | constant_reg | unread / unmatched / failing / unverified | 黑盒 / dont_verify | receipt sha256 |
|---|---|---|---:|---|---|---|
| CountModule | SUCCEEDED | 125 / 125 / **125** | 0 | 0 / 0 / 0 / 0（vmucp 实比 6 点） | 0 / 无 | `b78d596814b8b0f3419f1bd6df4ade2b5c16c492a1894a6da3d104dcd0b83aa7` |
| ClmulModule | SUCCEEDED | 1097 / 641 / **641** | 456 | 0 / 0 / 0 / 0 | 0 / 无 | `f73ac9ddbcf45d395dac0ba8e2d7473b309e3d9d63199e368a42ef83949d040e` |
| MiscModule | SUCCEEDED | 128 / 128 / **128** | 0 | 0 / 0 / 0 / 0 | 0 / 无 | `701dc56856f19524be7bcb2e69216b6a5e3c33f14ef94dd9aef9c657cafe4460` |
| HashModule | SUCCEEDED | 128 / 128 / **128** | 0 | 0 / 0 / 0 / 0 | 0 / 无 | `d0a5d85ea7348482515f941e83442219fa3cc246a7ec46b2f4b782c8af4ceeb7` |

四个目标 passing 与预测逐位相等；ClmulModule 差额 456 全部被 constant_reg 指认。
`python3 scripts/fm_predict.py check CountModule ClmulModule MiscModule HashModule` rc=0（结论：全部对上）。
receipt 路径 `evidence/f696c5c84a6d/<目标>/receipt.json`（`git add -f`，commit `4e8c8570f`）。

CountModule vmucp 六条（落数）：
1. 精确绑定：恰 funcReg[8:3] 6 点（fm.log 回显 `BKULEAVES_PIN_END top=CountModule n=9 expect=9`）；
2. 双射：诊断跑（vmucp 关、`FM_MODE=diagnostic-full`、不产 receipt）`matched_unread_notcompared_pairs` 恰 6 对，
   `r:/WORK/CountModule/funcReg_reg[k]` ↔ `i:/WORK/CountModule/u_core/funcReg_reg[k]`，k=3..8，非 matched 的 unread 0；
3. 真比较：vmucp 关 passing 119 / unread 6 → 开 passing 125 / unread 0，正好 +6；
4. 全零：failing / unverified / unmatched 0；
5. 无 dont_verify、无 elab147、无放宽 appvar、无黑盒；
6. `verif/fm_target_config/CountModule.tcl` 与 `fm_pins_pre.tcl` 进 sidecar script_closure（sourced_002 / sourced_003）。

补充（变异 M8 的 FM 侧）：把 M8（UT 结构上看不见的 s1 归并"相加"写法）喂给同一个 FM 诊断跑（scratch 副本，不产 receipt）：
FAILED，failing 7（全部 matched），FM 抓到——这一类只能靠 FM 守。

复跑：`PROOF_COMMIT=f696c5c84 bash scripts/run_proof.sh BkuLeaves <CountModule|ClmulModule|MiscModule|HashModule> < /dev/null`

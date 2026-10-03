# fpu-parents lane · fpdiv 组（agent/fpu-parents）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3f23a91cb`（worktree `/home/eda/xs-env/wt-fpu-parents`，分支 `agent/fpu-parents`，认领 `docs/lanes/fpu-parents_claim.md`） |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 设计源 | `yunsuan/fpu/FloatDivider.scala` class fpdiv_r64_block、`yunsuan/vector/VectorFloatDivider.scala` class VectorFloatDividerR64 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify、无黑盒 |
| 冲突检查 | codex outbox 最新 0207 与 codex/* 分支 rtl 改动、全部 worktree 的 claim/prereg、各 agent 分支 rtl diff：无本组目标的认领或改动（只有引用） |

## 1. fpdiv_r64_block（UT 目录 `verif/ut/fpdiv_r64_block`）

### 1.1 结构与 child 处置

golden 412 行（`_GEN_`/`_T_` 32 处）→ impl `rtl/backend/fpdiv_r64_block.sv` 287 行，代码区 `_GEN_`/`_T_` 0。
标量除法器（FloatDividerR64）的迭代块：只有 f64 一条 60 位余数通道（72 位向量的 [71:12]）。可读核
`xs_fpdiv_r64_block_core` 按级分节：§0 商位编码与除数倍数 → §1 s0（200 位共享 CSA 的 f64 字段 + r4_qds_v2）
→ §2 s1（72 位 CSA + 投机 r4_qds_v2_spec）→ §3 s2（投机余数片取自 s0 候选）→ §4 下一拍 6/7 位余数片。
与 Scala 的差别只在读不到的位上（s0 共享 CSA 的 f32/f16 字段填 0、s1 的 f16 通道除数片写成同位的 f64 片、
空操作 mask_zero 省略），文件头逐条说明。
child：CSA3to2_20 ×4 / CSA3to2_24 ×8 / r4_qds_v2 ×1 / r4_qds_v2_spec ×2，coverage 第 3 列均 PROVEN_DIRECT
→ 两侧白盒（ref golden / impl 重写件）。纯组合，零寄存器，无 fm_pins。

### 1.2 UT（commit `7e8337238` 的字节，200k 次组合调用，9 档）

差分（golden vs `fpdiv_r64_block_xs`，7 个输出口逐拍比）+ **独立 oracle**（tb 内整数算术）：
- O1 每拍代数恒等式 `(s_out+c_out) ≡ 64·(s_in+c_in) − (16q0+4q1+q2)·2D (mod 2^60)`，商位须 one-hot
  （随机拍里 qds 查表多命中时跳过并计数）；
- O2 闭环除法：按 golden 预缩放表（9..16/8）与初始余数公式装入真实 f64 尾数，把**重写件**输出喂回迭代 9 次（27 个商位），
  终了要求 `|R| < 2D`、`Q·2D + R == 4^27·X`，并与宽整数除法 floor(4^27·X/2D)（R≥0）/ +1（R<0）逐位核对。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=1400000 errors=0，oracle 214016 次 0 错 PASSED | 同 PASSED（seed 1 的 random 档退化为全 1） | initreg+1017 同 PASSED |
| 7  | checks=1400000 errors=0，oracle 214118 次 0 错 PASSED | 同 PASSED | initreg+7017 同 PASSED |
| 42 | checks=1400049 errors=0，oracle 213956 次 0 错 PASSED | 同 PASSED | initreg+42017 同 PASSED |

覆盖（seed 1，判据写在 tb 里）：s0/s1/s2 各 5 个商位全部 ≥ 2 万次（最少 s0 的 +2：21519）；预缩放 8 档 1390..6020；
被除数尾数 ≥/< 除数 10631/9380；终了余数 ≥0/<0 12482/7529；闭环除法 20011 次；随机拍 qds 多命中 5995 拍（O1 跳过）；
7 个输出逐位翻转（结构恒定位除外：余数低 12 位、carry 通道 bit1）。

变异自检（scratchpad 拷贝施变、独立 simv，seed 7 / 20k 拍，不进库）：M1 s1 负候选 carry 去掉 +1 ⇒ errors 10280 / oracle 8769；
M2 s2 投机余数窗错一位 ⇒ 66081 / 5764；M3 下一拍 8 位除数片错一位 ⇒ 12525 / 2883；M4 s0 余数按 s1 商位选 ⇒ 50683 / 14988；
M5 −D 多加 1 ⇒ 20001 / 12443；M6 7 位余数片取错位 ⇒ 17969 / 5512。6/6 被差分与 oracle 同时抓到。

复跑：`cd verif/ut/fpdiv_r64_block && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/fpdiv_r64_block.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（`python3 scripts/fm_predict.py model fpdiv_r64_block --ut fpdiv_r64_block`）。

| 目标 | 模型 | 预测 passing | 其余 |
|---|---:|---:|---|
| fpdiv_r64_block | 172（0 寄存器 + 172 输出位） | **172** | failing / unverified / unmatched / unread 0，无黑盒，无 vmucp，SUCCEEDED |

可能出错处：输出里有 24 个结构恒 0 位（余数 sum/carry 的低 12 位），同族 fpdiv_r64_block_vector 的先例里常量输出位
照常计入 passing；若这里被 FM 归到别的类别，差额就是这 24 位。登记前未做任何 FM 试跑。

## 对账 §1（fpdiv_r64_block）

| 目标 | 证明 commit | 结果 | 模型 / 预测 / 实测 passing | failing / unverified / unread / unmatched | 黑盒 / dont_verify | receipt sha256 |
|---|---|---|---|---|---|---|
| fpdiv_r64_block | `801a0f5c9` | SUCCEEDED | 172 / 172 / **172**（逐位相等） | 0 / 0 / 0 / 0 | 0 / 无 | `d2d21731979a44e0d6093f6bde5a85aa69b28ef52285751146577230d4025bdb` |

`python3 scripts/fm_predict.py check fpdiv_r64_block` rc=0；24 个结构恒 0 输出位照常计入 passing（与登记的先例一致）。
receipt：`evidence/801a0f5c9e49/fpdiv_r64_block/receipt.json`。
复跑：`PROOF_COMMIT=801a0f5c9 bash scripts/run_proof.sh fpdiv_r64_block fpdiv_r64_block < /dev/null`

## 2. VectorFloatDividerR64（UT 目录 `verif/ut/VectorFloatDividerR64`）

### 2.1 结构与 child 处置

golden 2039 行（`_GEN_`/`_T_` 612 处）→ impl `rtl/backend/VectorFloatDividerR64.sv` 966 行，代码区 `_GEN_`/`_T_` 0（<1500 行，无需导航）。
可读核 `xs_VectorFloatDividerR64_core`：§0 小工具（舍入判定 / 上溢取 ∞ / on-the-fly 商转换 / 预缩放 / 非规格右移量函数）→
§1 状态机 → §2 操作数按格式拆进 4 条通道 → §3 特殊值分类与 PRE_0 锁存 → §4 左规 → §5 指数差 → §6 商/除数寄存器与预缩放 →
§7 迭代核与初始余数打包 → §8 on-the-fly 三级 → §9 收尾（选 Q/Q−1、右移、舍入）→ §10 上溢与 POST_0 结果 → §11 POST_1 结果 →
§12 寄存器写入（各状态项按位或）→ §13 输出与标志。38 个寄存器名与 golden 逐字相同（只多一层 `u_core/`），位宽逐位一致，
复位域照抄（仅 fsm_q 异步复位）；不需要 fm_pins。golden 里 is_vec 恒 1、is_frs* 恒 0，标量通路被 firtool 消掉，文件头写明。
child：ShiftLeftPriorityWithLZDResult ×2 / _6 ×2 / _8 ×4、fpdiv_r64_block_vector ×1（及其 CSA3to2_20/24、r4_qds_v2/_spec）。
coverage 第 3 列：fpdiv_r64_block_vector 等 PROVEN_DIRECT；_6 / _8 表里写 MISSING/UNPROVEN 但**表滞后**——rtl/backend 下已有重写件
（agent/k3-returned，commit 84ab6f364）且有正式 receipt（evidence/1bf831352049/ShiftLeftPriorityWithLZDResult_{6,8}，SUCCEEDED）。
处置 = 全部两侧白盒（ref golden / impl 重写件），无黑盒。

### 2.2 UT（commit `514072c47` 的字节，200k 拍，9 档）

差分：start_ready / finish_valid 每拍比；fpdiv_res / fflags 自 golden 首次进 POST_0 起每拍比（此前读的是不复位寄存器的上电值）。
**独立 IEEE 754 oracle**（tb 内宽整数算术）：每个未被 flush 的合法操作，在 finish_valid 首拍逐元素（f64×1 / f32×2 / f16×4）
算正确舍入商（5 种 rm；rm 5..7 golden 不进位、上溢取最大有限数，按 RTZ 建模）+ 规范 NaN + NV/DZ/OF/UF/NX（UF 按 RISC-V
"舍入后判 tiny"），与重写件输出逐位比。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=799986 errors=0，oracle 17588 次 0 错 PASSED | 同 PASSED（seed 1 的 random 档退化为全 1） | initreg+1017 同 PASSED |
| 7  | checks=799974 errors=0，oracle 17578 次 0 错 PASSED | 同 PASSED | initreg+7017 同 PASSED |
| 42 | checks=799990 errors=0，oracle 17569 次 0 错 PASSED | 同 PASSED | initreg+42017 同 PASSED |

覆盖（seed 1，判据写在 tb 里）：操作 19041 次；3 格式 × 5 rm 每格 1052..1177；非法格式 265 次、f64 的 rm 5..7 673 次；
结果类别 规格/非规格/上溢/NaN/∞/0 = 19428/7256/3710/5728/2586/2560（按元素计）；标志 NV/DZ/OF/UF/NX = 2953/1261/3710/6602/24350；
flush 打断 978 次、finish 反压 6048 拍、f64 除数为 2 的幂 1655 次；fpdiv_res 64 位、fflags 20 位逐位翻转。
（注：第一次 9 档批跑在 30 分钟后台时限处被停，停在 seed 42 的第 1 档；seed 42 三档随后单独重跑，结果如表。）

变异自检（scratchpad 拷贝施变、独立 simv，seed 7 / 20k 拍）：V2 f64 通道初始余数 bit41 的 f16 标志 ⇒ errors 225 / oracle 36；
V3 RMM 判进位用末位 ⇒ 874 / 154；V4 UF 去掉"舍入后没进位"项 ⇒ 108 / 78；V5 f32 通道 2 的幂初值格式条件 ⇒ 34 / 3；
V6 预缩放表 sel=6 少一项 ⇒ 420 / 28；V7 通道 1 标志门控 ⇒ 3166 / 414；V8 Q−1 舍入借用 Q+1 的判据取反 ⇒ 466 / 118。
V1（f64 上溢比较改看全 13 位）未被抓到——**等价变异**：bit12=1（负）时 13 位无符号比较与低 12 位比较同为真，其余情形相同。
7/7 非等价变异全部被差分与 oracle 同时抓到。

复跑：`cd verif/ut/VectorFloatDividerR64 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 2.3 跑前预测（★跑完不许改本节★）

| 目标 | 模型 | 预测 constant_reg | 预测 passing | 其余 |
|---|---:|---:|---:|---|
| VectorFloatDividerR64 | 649（寄存器 563 + 输出 86） | 0 | **649** | unread 0 / failing 0 / unverified 0 / unmatched 0，无黑盒，无 vmucp，SUCCEEDED |

可能出错处：(1) 寄存器名只差 `u_core/` 层次，预期按名配上；若有 unmatched 先查配对。(2) 是否有被 FM 判为常量或 unread 的寄存器位
没有逐位分析过（结构上找不到恒定位；f_r_s/f_r_c 的个别低位可能无读者），若出现，差额应正好等于这些位数。登记前未做任何 FM 试跑。

## 3. 父级重证：FDivSqrt（ArithVecLeaves5，commit `0fb6429ab` 起 impl 读重写件 fpdiv_r64_block）

### 3.1 改动与范围

核实闭包：FDivSqrt → FloatDivider → FloatDividerR64 → **fpdiv_r64_block**（VectorFloatDividerR64 不在 FDivSqrt 闭包里；
VectorFloatDividerR64 的父 VectorFloatDivider / VFDivSqrt 均 UNPROVEN，无已签父级可重证）。
`verif/ut/ArithVecLeaves5/Makefile`：fpdiv_r64_block 从 impl 侧 golden 列表移进 `FDIVSQRT_REWRITTEN`（RTL_SRCS）；其 child
CSA3to2_20/24、r4_qds_v2/_spec 仍两侧同源 golden；`FM_REF_DEPS_FDivSqrt` 不变（ref 全 golden）。
同一 UT 的另 4 个变体 impl 闭包成员随之变化（rtl 字节未变），照 fpaddpath-sqrtblock §4 先例一并重跑。

### 3.2 UT（`0fb6429ab` 字节，9 档）

★UT 限度★：impl 的 FloatDividerR64 是 golden 文件，单一 elaboration 里例化 golden 名 fpdiv_r64_block，UT 回归不到重写件（FM 覆盖）。

| seed | `+0` | `+random` | `+<seed>017` |
|---|---|---|---|
| 1  | checks=5199973 errors=0 PASSED | checks=5199973 errors=0 PASSED（全 1 档） | errors=7 FAILED |
| 7  | checks=5199994 errors=0 PASSED | errors=6 FAILED | errors=6 FAILED |
| 42 | checks=5199991 errors=0 PASSED | errors=5 FAILED | errors=5 FAILED |

★5 档失配全部是基线既有★：失配行全在 `du.res_data`（DivUnit 不复位 payload 寄存器的随机初值，Makefile 注明该 UT 只用常量档）。
在改动前一个 commit `4dd44d242` 的字节（scratch git archive）上复跑这 5 档，MISMATCH 行逐行相同（7/6/6/5/5 行），与本次改动无关。

### 3.3 跑前预测（★跑完不许改本节★）

golden 闭包未变，所以预测 = 上一版 receipt（evidence/f19ef593a8df，fpaddpath-sqrtblock 对账 §4）。

| 目标 | 模型 | 预测 passing | 其余 |
|---|---:|---:|---|
| FDivSqrt | 2082（寄存器 1351 + 输出 731） | **2052**（constant_reg 30） | vmucp 开（白名单 verif/fm_target_config/FDivSqrt.tcl 不变），merge 关，failing / unverified / unread / unmatched 0 |
| Adder_chain_rnd | 85 | **85** | 全 0 |
| DivUnit | 3132 | **3132** | vmucp 开、merge 关，全 0 |
| VIAluDecoder | 12 | **12** | 全 0 |
| VIntAdder64b | 160 | **160** | 全 0 |

可能出错处：fpdiv_r64_block 纯组合，FloatDividerR64 的寄存器集合不变，预期逐位同上一版；若 FDivSqrt 偏离，先查 merge/配对。

## 对账 §2 §3（证明 commit `f0492477b`）

| 目标 | 结果 | 模型 / 预测 / 实测 passing | constant_reg | failing / unverified / unread / unmatched | 黑盒 / dont_verify / vmucp | receipt sha256 |
|---|---|---|---|---|---|---|
| VectorFloatDividerR64 | SUCCEEDED | 649 / 649 / **649**（逐位相等） | 0 | 0 / 0 / 0 / 0 | 0 / 无 / 关 | `44d306054389a47c47db7b6b50db513b31779e0efd59765087a2977eedb28afc` |
| FDivSqrt | SUCCEEDED | 2082 / 2052 / **2052** | 30（与上一版同） | 0 / 0 / 0 / 0 | 0 / 无 / 开（白名单不变） | `8c7d9829315bc2fb87aa07a92c8e7c8f20ed3b04c7270bcb767605205a84137f` |
| Adder_chain_rnd | SUCCEEDED | 85 / 85 / **85** | 0 | 全 0 | 0 / 无 / 关 | `a9eacbb132eca4d86ad672bc8cd83949cd6ffd8e59fb509f1d77af9425419c00` |
| DivUnit | SUCCEEDED | 3132 / 3132 / **3132** | 0 | 全 0 | 0 / 无 / 开 | `43a93a161fc6fbfa1860e14f47c0b9c2a2df1adf8bfb8d6bbf3e77744b118dbe` |
| VIAluDecoder | SUCCEEDED | 12 / 12 / **12** | 0 | 全 0 | 0 / 无 / 关 | `e689eb1916502c3c86a84d81481e0f69c5db14d051cd1bbfafe7dd9d88d68264` |
| VIntAdder64b | SUCCEEDED | 160 / 160 / **160** | 0 | 全 0 | 0 / 无 / 关 | `767804fe01db2471eeb778bda81d200d10224693fb7e793fd59449cbffa559ec` |

`python3 scripts/fm_predict.py check VectorFloatDividerR64 FDivSqrt Adder_chain_rnd DivUnit VIAluDecoder VIntAdder64b fpdiv_r64_block` rc=0
（FDivSqrt 差 30 = constant_reg 30 逐位指认；ArithVecLeaves5 五个目标因 Makefile 的 merge 是 `$(if …)` 表达式，fm_predict 判"模型不适用"，
只给 BOUNDED 判决，预测数字以本节表为准，五个全部与登记相等）。
receipt：`evidence/f0492477b75c/<目标>/receipt.json`。
复跑：`PROOF_COMMIT=f0492477b bash scripts/run_proof.sh VectorFloatDividerR64 VectorFloatDividerR64 < /dev/null`；
`PROOF_COMMIT=f0492477b bash scripts/run_proof.sh ArithVecLeaves5 FDivSqrt Adder_chain_rnd DivUnit VIAluDecoder VIntAdder64b < /dev/null`

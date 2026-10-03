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

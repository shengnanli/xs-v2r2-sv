# leafmix lane（agent/leafmix）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `4728f823`（main，`git worktree add /home/eda/xs-env/wt-leafmix -b agent/leafmix main`） |
| 工作树 | `/home/eda/xs-env/wt-leafmix`，分支 `agent/leafmix` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | FastArbiter_28 → Uncache → VIntMisc64b（三个独立叶子） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |
| codex 冲突 | 第 0 步已查：outbox 最新 codex_0197（50 个 Pmpaddr/Pmaaddr31/ShiftRightJam*/RightShift*）与 18 个 codex/* 分支 diff 均未触及三个目标及其 child（CLZ_*） |

## 1. FastArbiter_28（复用共享核 xs_FastArbiter_core，核未改）

### 1.1 结构

- `utility.FastArbiter(EmptyBundle, 80)` 的单态化，TL2CHICoupledL2 的 `pcrdgrant_arb`：
  MMIOBridge 16 + 4 slice×16 个 MSHR 等 PCrdGrant，命中者拉 valid，ready 即授予。
- golden 端口面：无 bits（载荷 0 位）、无 io_out_ready（例化者写死 true.B，firtool 折掉）。
  wrapper 给核 W=1 常 0 占位载荷、out_bits 悬空、out_ready=1'b1。
- 生成器 `scripts/gen_fastarbiter_28.py`（--check，进 gate_all）fail-closed 核对四处 golden 形状。
- 无子模块、无黑盒。`check_shared_impl_impact` 不适用（共享核未改）。

### 1.2 UT（verif/ut/FastArbiter_28；3 seed × 3 initreg × 200k 拍，commit 34f1a0aa）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | 400k checks errors=0 | errors=0（=全 1 档） | errors=0 |
| 7  | errors=0 | errors=0 | errors=0 |
| 42 | errors=0 | errors=0 | errors=0 |

覆盖（PASS 判据内，各档全满）：轮转命中赢 79/79（第 0 路按构造不可能）、兜底赢 80/80、
各路 ready 取过 0/1、out_valid 取过 0/1。
变异（seed 7 random 30k 拍）：6 个里 4 个 CAUGHT（ready 位错接、valid 位序互换、above_winner 错位、
去掉轮转）；2 个 SURVIVED 且属输出等价的状态变异 —— M2 pendingMask 复位成全 1（复位后
rrGrantMask=0 把它与掉）、M4 pendingMask 不去掉赢家位（赢家位被 rrGrantMask 的"赢家以上"掩掉）。
二者在 FM 的寄存器比较点上必然失配（下一状态函数不同），归 FM。
复跑：`cd verif/ut/FastArbiter_28 && make run SEED=<s> INITREG=<0|random|<s>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/FastArbiter_28.json）

模型 expected = 241（regs 160 = pendingMask 80 + rrGrantMask 80；outs 81 = 80 ready + out_valid）。

| 项 | 预测 |
|---|---|
| passing | **240**（= 241 − constant_reg 1） |
| constant_reg | 1（rrGrantMask_reg[0]，两侧对称） |
| unread（vmucp 后） | 0（pendingMask_reg[0] matched_nc 实比进 passing） |
| failing / unverified / aborted / unmatched / 黑盒 / dont_verify | 全 0 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

可能出错处：W=1 占位载荷与 out_bits 悬空在 impl 侧只产生无扇出的线，预期不产生任何 impl-only 比较点；
若出现 impl 独有 unmatched/unread，先查这里。

## 对账

### FastArbiter_28（run_proof @ bc3a0c0b，evidence/bc3a0c0b69ba/FastArbiter_28）

| 项 | 预测 | 实测 | 差 |
|---|---|---|---|
| native | SUCCEEDED | SUCCEEDED | — |
| passing | 240 | 240 | 0 |
| constant_reg | 1 | 1 | 0 |
| failing / unverified / aborted / unread_notcompared | 0 | 0 / 0 / 0 / 0 | 0 |
| unmatched（ref/impl compare、unread、bbout） | 0 | 全 0 | 0 |
| 黑盒 / dont_verify / elab147 | 无 | 无 / false / false | — |

receipt.json sha256 = `860ebaf0744e514ed2ae599e71c4e04ecd72d9a5f7203261139634e974ea11bb`；
`python3 scripts/fm_predict.py check FastArbiter_28` rc=0（"差额被指认"）。
复跑：`bash scripts/run_proof.sh FastArbiter_28 FastArbiter_28 < /dev/null`

## 2. Uncache（跑前登记，FM 起跑前提交）

### 2.1 结构

- `rtl/memblock/Uncache.sv`：`uncache_pkg`（常量、请求/idResp/结果 struct、优先编码/对齐掩码/Get 掩码函数）+
  手写核 `xs_Uncache_core`（§1 状态 SoA、§2 e0 入队、§3 q0 发出、§4 D、§5 r0 交回、§6 前递、§7 状态更新）+
  文末 GENERATED 区 wrapper（`scripts/gen_uncache.py`，--check，进 gate_all）。
- 无子模块、无黑盒。钉点 `verif/ut/Uncache/fm_pins_pre.tcl`（同一生成器，fail-closed，字面 6757 = golden 寄存器位数）。

### 2.2 UT（verif/ut/Uncache；3 seed × 3 initreg × 200k 拍）

tb 手写 + 生成 DUT 区；合法 TileLink 从设备模型（乱序回 D）；预热 16 项写满后才开比（条目字段不复位）。
覆盖 17 项计数写进 PASS 判据。结果见文末对账（跑完追加）。
复跑：`cd verif/ut/Uncache && make run SEED=<s> INITREG=<0|random|<s>017>`

### 2.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/Uncache.json）

lane 内非正式试跑（commit 9621dbc8，vmucp 关，merge_dup=false）：native SUCCEEDED、passing 7416、failing 0、
unmatched 0、钉点 6757/6757、unread 201（全部 matched_nc，明细见 verif/fm_target_config/Uncache.tcl）。

| 项 | 预测 |
|---|---|
| expected（模型） | 7617（regs 6757 + outs 860） |
| passing | **7617**（= 7416 + 201） |
| constant_reg | 0 |
| unread（vmucp 后） | 0 |
| failing / unverified / aborted / unmatched / 黑盒 / dont_verify | 全 0 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

# MSHRCtl lane（agent/mshrctl）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `3992f2dd`（main，`git worktree add /home/eda/xs-env/wt-mshrctl -b agent/mshrctl main`） |
| 工作树 | `/home/eda/xs-env/wt-mshrctl`，分支 `agent/mshrctl` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| Scala | `XiangShan/coupledL2`（子模块 fb546983 = golden b36a1a2a5 所钉）/ `utility`（2f0743f1），`tl2chi` 版 |
| 目标 | FastArbiter_3/4/5/6/7（child 家族）→ SourceB（child，已有重写件，本 lane 改用重写 FastArbiter_5）→ MSHR（child ×16）→ MSHRCtl（本体） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| codex 冲突 | 第 0 步已查：outbox 最近 60 条与 15 个 codex/* 分支均未触及 MSHR / MSHRCtl / SourceB / FastArbiter_3..7 |

## 1. FastArbiter_3/4/5/6/7（共用核 xs_FastArbiter_core）

### 1.1 结构与子模块处置

- 五者都是 `utility.FastArbiter`（轮转 + 挂起记忆）的单态化：_3 txreq_arb / _4 txrsp_arb /
  _6 source_b_arb / _7 mshr_task_arb 为 MSHRCtl 的 16 路仲裁器，_5 为 SourceB 的 4 路 issueArb。
  G1 与 G0（_4/_5/_7/_8/_6）的差异只有临时线改名与 _3 删了 memAttr_ewa 输入、_7 删了 dataCheckErr。
- 可读核 `rtl/common/xs_FastArbiter_core.sv`（手写，参数 N/W）；五个薄 wrapper 由
  `scripts/gen_fastarbiter_l2.py`（`--check`，已进 gate_all）从 golden 端口表生成；
  golden 里"有输出无输入"的常量字段（qos/size/cacheable/ewa/snpAttr、CompAck、Probe、mshrTask）
  由生成器对 golden 的 `assign` 表达式在 |chosenOH=0/1 两点求值核对（fail-closed）后喂进每一路。
- 无子模块、无黑盒。

### 1.2 UT（verif/ut/FastArbiterL2，五变体同测；seed 1/7/42 × initreg 0/random/<seed>017 × 200k 拍）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | 23.4M checks errors=0 | 23.4M errors=0 | 23.4M errors=0 |
| 7  | 23.4M errors=0 | 23.4M errors=0 | 23.4M errors=0 |
| 42 | 23.4M errors=0 | 23.4M errors=0 | 23.4M errors=0 |

覆盖（写进 PASS 判据，各档全满）：每个变体每一路都"轮转命中赢"（第 0 路按构造不可能，要求 N-1 路）、
都"固定优先级兜底赢"、in_ready 取过 0/1、out_valid 取过 0/1。
复跑：`cd verif/ut/FastArbiterL2 && make run SEED=<s> INITREG=<0|random|<s>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/FastArbiter_<N>.json）

模型：expected = golden 寄存器位（pendingMask + rrGrantMask = 2N）+ 顶层 output 位。

lane 内非正式试跑（commit 7a57e899 同 RTL 字节，vmucp 关，merge_dup 缺省）实测：五者全部
native SUCCEEDED / failing 0 / unmatched 0(0)，passing = expected − 2，Not Compared =
Constant reg 1（rrGrantMask_reg[0]）+ Unread 1（pendingMask_reg[0]，matched_nc，两侧同名）。

正式 run_proof（vmucp 开，`verif/fm_target_config/FastArbiter_<N>.tcl` 按六条写明依据）：

| 目标 | expected | passing 预测 | 差额 = constant_reg | 其余 |
|---|---|---|---|---|
| FastArbiter_3 | 145 | **144** | 1 | failing/unverified/aborted/unread/unmatched 全 0，无黑盒 |
| FastArbiter_4 | 78  | **77**  | 1 | 同上 |
| FastArbiter_5 | 60  | **59**  | 1 | 同上 |
| FastArbiter_6 | 96  | **95**  | 1 | 同上 |
| FastArbiter_7 | 330 | **329** | 1 | 同上 |

vmucp 六条：(1) unread 点 = {pendingMask_reg[0]} 恰 1 位；(2) 1↔1 matched_nc，两侧独占 0；
(3) passing 恰 +1（相对试跑）；(4) failing/unverified/aborted/unmatched 全 0；(5) dont_verify /
elab147 / relaxed_appvars 空、无黑盒；(6) 配置文件进 script_closure、receipt 记 sha256。

### 1.4 明写可能出错的地方

1. merge_dup 由缺省改为 false：仲裁器内无重复寄存器，预期对 passing 无影响；若差出来，先查 merge。
2. 试跑是 vmucp 关、merge 缺省；正式跑两处都变，数字以上表为准。

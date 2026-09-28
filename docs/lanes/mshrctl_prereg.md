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

## 2. SourceB（已有重写件；本 lane 改 child 处置 + waitG 宽度 + 钉点）

### 2.1 改动与子模块处置

- child FastArbiter_5：原先两侧同一份 golden（GOLDEN_REUSE），改为两侧白盒 —— ref golden、
  impl 本 lane 重写件（§1）。
- `probes_waitG` 从 4 位改回 golden 的 7 位（写入 {3'h0, idx}、只读 [3:0]），撤掉
  `verif/dead_ref/SourceB.json`（它声明的是 golden 独有死位；merge_dup=false 下实测 12 位而非 4 位，
  声明已不成立）。
- `verif/ut/SourceB/fm_pins_pre.tcl`（scripts/gen_l2_mshr_pins.py 生成，fail-closed，224 位）：
  golden `probes_<k>_<字段>` ↔ impl `u_core/probes_<字段>_reg[k]`。不钉时 waitG 死位两侧都配不上
  （ref/impl 各 12 个 unmatched unread，实测 commit 3dd22d50 试跑）。
- FM_MERGE_DUP=false（新加，模型适用）。

### 2.2 UT（verif/ut/SourceB；SourceB_xs 例化 FastArbiter_5_xs；3 seed × 3 initreg × 200k）

结果见文末对账（跑完追加）。复跑：`cd verif/ut/SourceB && make run SEED=<s> INITREG=<0|random|<s>017>`

### 2.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/SourceB.json）

模型 expected = 543（regs 232 + outs 311）。lane 内非正式试跑（commit 60257697 前的工作树、钉点与
本节相同，vmucp 开）：passing 530 / constant_reg 13 / unread 0。

| 项 | 预测 |
|---|---|
| passing | **530**（= 543 − constant_reg 13） |
| constant_reg | 13 = issueArb.rrGrantMask[0] 1 + probes_<k>_waitG[6:4] 4×3（恒写 0，两侧对称） |
| unread（vmucp 后） | 0（issueArb.pendingMask[0] 1 位 matched_nc 实比进 passing） |
| failing / unverified / unmatched / 黑盒 / dont_verify | 全 0 / 无 |
| verdict | SUCCEEDED（signoff-strict） |

## 3. MSHR（child ×16）

### 3.1 结构

- `rtl/uncore/MSHR.sv`：package mshr_pkg（编码常量、MetaEntry / MainPipe 任务 struct、odOpGen 等）+
  手写核 xs_MSHR_core（§1 寄存器，与 golden 同名 → FM 按名配对，不需钉点；§2 派生判断；§3 四路发请求，
  六种 MainPipe 任务各拼一份 struct 再按优先级选；§4 状态更新，一个 always_ff 按 Chisel when 顺序写；
  §5 输出；§6 性能/断言影子）+ 生成的端口表与 wrapper（scripts/gen_mshr.py，--check，进 gate）。
- 无子模块、无黑盒。

### 3.2 UT（verif/ut/MSHR；3 seed × 3 initreg × 200k 拍；31M checks/档）

commit 3edb0f92 与 ea8f5e84 的字节上各跑过一轮全矩阵，均 errors=0（ea8f5e84 只改一处函数取位段写法）。
覆盖：21 个 golden 内部判断（release_valid1/2、mp_grant/cbwrdata/probeack/dct、rcompack/wcompack、
嵌套写回两种匹配、doRespData、promoteT、三种写回类型、CMO、事务结束、period、nestedwbData、PCrd 查询）
每档都非 0（seed 42 random 档：事务结束 337 次、probeack 720 拍、dct 846 拍）。
变异自检（scratchpad，30k 拍，seed 7）：10 个里 8 个抓到；**UT 看不见的 2 个**：M5 validCnt 去掉复位、
M9 REG_1 恒 0 —— 两者都是断言专用影子（综合视图无读者），归 FM：vmucp 把它们作为 matched-unread 实比。

### 3.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/MSHR.json）

模型 expected = 1443（regs 655 + outs 788）。lane 内非正式试跑（commit ea8f5e84，vmucp 关，merge_dup 缺省=true）：
native SUCCEEDED passing 1372 / failing 0 / unmatched 0(0)，Constant reg 1，Unread 69（全 matched_nc：
validCnt[63:0]、REG、REG_1..3、state_w_pprobeackfirst）。1443 − 1 − 69 = 1373，与 1372 差 1 ——
推断为 merge_dup 合并了一对重复寄存器（io_msInfo_bits_blockRefill_REG 与 _REG_1 同源同值）。

| 项 | 预测（正式 run_proof：merge_dup=false、vmucp 开） |
|---|---|
| passing | **1442**（= 1443 − constant_reg 1） |
| constant_reg | 1 |
| unread | 0（69 位全部 vmucp 实比） |
| failing / unverified / unmatched / 黑盒 / dont_verify | 全 0 / 无 |
| verdict | SUCCEEDED |

可能出错处：(1) 那 1 个常量寄存器的身份未查明（试跑报告只给计数）——若 constant_reg≠1，差额按 receipt 指认；
(2) 若 merge 关闭后 blockRefill_REG/_REG_1 仍被合并，passing 会是 1441。

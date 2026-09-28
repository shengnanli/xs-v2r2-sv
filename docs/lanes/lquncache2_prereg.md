# LoadQueueUncache lane（agent/lquncache2）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `4728f823`（main，`git worktree add /home/eda/xs-env/wt-lquncache2 -b agent/lquncache2 main`） |
| 工作树 | `/home/eda/xs-env/wt-lquncache2`，分支 `agent/lquncache2` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `PipelineRegModule` / `_1` / `_2`（child，叶子）→ `LoadQueueUncache`（本体）→ 余力：`LqExceptionBuffer` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| codex 冲突 | 第 0 步查过 outbox 最新 0197（Pmpaddr/Pmaaddr/ShiftRightJam/RightShift 共 50 个）与 18 个 codex/* 分支的 rtl 改动：均不含本 lane 目标及其 child |

## 1. PipelineRegModule / _1 / _2（共用核 xs_PipelineRegModule_core）

### 1.1 结构与子模块处置

- Chisel `AddPipelineReg.PipelineRegModule`（MemCommon.scala）：1 个异步复位 valid 位 + 不复位 payload，
  in.fire 写入、out.fire 清空（入优先），isFlush 恒 false 已被 firtool 消掉。
- 三个变体只差 payload 字段表（10 / 182 / 187 字段 = 193 / 1428 / 1567 位）。`scripts/gen_pipelinereg.py`
  生成前对 golden 逐条核对：端口形状、寄存器表（恰 valid + 每字段一个 io_out_bits_r_*）、家族共同语句。
- 叶子：golden 侧 0 子模块，无黑盒。
- 钉点 `verif/ut/PipelineRegModule/fm_pins_pre.tcl`（生成）：golden 每个寄存器位逐位 set_user_match 到
  `u_core/bits_q_reg[k]` / `u_core/valid_q_reg`；fail-closed（逐条数返回值，总数 != 字面整数即 error）。
  期望钉点数 = 寄存器位数：194 / 1429 / 1568。

### 1.2 UT（verif/ut/PipelineRegModule，三变体同 tb；commit 8f5c5900 的字节）

逐拍比全部输出（in_ready / out_valid 从复位撤销起比；payload 在该变体第一次 in 成交后比）；
每 5000 拍一次中途异步复位脉冲（valid 归 0、payload 保持）。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=600000 errors=0 | checks=600000 errors=0 | checks=600000 errors=0 |
| 7  | checks=600000 errors=0 | checks=600000 errors=0 | checks=600000 errors=0 |
| 42 | checks=600000 errors=0 | checks=600000 errors=0 | checks=600000 errors=0 |

（checks = 3 变体 × 200k 拍。）覆盖（seed 1，PipelineRegModule_1）：in_fire 80691 / out_fire 80663 /
同拍进出 48503 / 反压 39318 / 复位脉冲 40；另两变体同量级，tb 对任一为 0 判红。
变异自检（scratchpad，20k 拍，random 档）：M1 in_ready 丢 out_ready ⇒ errors=55011；M2 出优先于入 ⇒ 20742；
M3 payload 加复位 ⇒ 22；M4 valid 改同步复位 ⇒ 21；M5 payload 锁存不看 ready ⇒ 19536。5/5 抓到。

复跑：`cd verif/ut/PipelineRegModule && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/PipelineRegModule*.json）

| 目标 | passing 预测（golden 寄存器位 + 顶层 output 位） | 其余 |
|---|---|---|
| PipelineRegModule   | **389**（194 + 195） | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| PipelineRegModule_1 | **2859**（1429 + 1430） | 同上 |
| PipelineRegModule_2 | **3137**（1568 + 1569） | 同上 |

无 vmucp、无 allow / dead_ref 声明。

### 1.4 明写可能出错的地方

1. 钉点名字形状（`bits_q_reg[k]` / 1 位 golden 寄存器无下标）是按 LoadQueueRAW / FCVT 的已知形状写的，
   没有 FM 试跑过；若有钉点被拒，fail-closed 会让整跑报错而不是静默退回自动匹配。
2. payload 里若有两侧都判为常量的位（本家族没有常量输入），passing 会少恰好 constant_reg 个。
3. 本节没有做过任何 FM 试跑。

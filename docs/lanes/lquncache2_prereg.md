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

## 2. LoadQueueUncache（本体，golden 59,051 行 / 1425 端口）

### 2.1 结构与子模块处置

- 可读核 `rtl/memblock/LoadQueueUncache.sv`：package loadqueueuncache_pkg（配置常量、redirect_t、RobPtr 比较、
  needFlush，及 9 个 bundle 结构体 —— 字段表逐字取 golden 端口表，GENERATED）+ xs_LoadQueueUncache_core
  （§1 s1 HwSort / §2 s2 入队判定 / §3 FreeList 分配与写条目 / §4 条目阵列 / §5 MMIO 独占 + NC 轮转发请求 /
  §6 MMIO 与奇偶组 NC 写回 / §7 释放 / §8 ParallelPriorityMux 异常 / §9 ROB 通知 / §10 满了就回滚，手写）
  + golden 同名 wrapper（GENERATED）。`scripts/gen_lquncache.py`（--check，已登记 gate_all）生成全部 GENERATED 区、
  钉点与 tb；生成前核对 bundle 字段表在各端口表之间逐项相同、每个端口/实例端口恰命中一条接线规则。
- golden 直接 child 23 实例 / 21 种，全部白盒：UncacheEntry×16（PROVEN_DIRECT，xs_UncacheEntry_core）、
  FreeList_6（PROVEN_DIRECT）、RRArbiterInit_11（PROVEN_DIRECT）、PipelineRegModule/_1/_2×3（本 lane §1 签核，
  evidence/48fbfd801873）。无黑盒。
- 钉点 `verif/ut/LoadQueueUncache/fm_pins_pre.tcl`：golden 顶层 651 个寄存器（5037 位）逐位钉到核的结构体数组
  （`s2_req_q_reg[k]\[字段][b]` 等），5 个流水寄存器实例的 payload/valid（6327 位）钉到 `u_core/<实例>/u_core/bits_q_reg`；
  共 **11364** 条，fail-closed。条目 / FreeList / 仲裁器内部不钉（名字只差 u_core 一层）。

### 2.2 UT（verif/ut/LoadQueueUncache；commit 76235b85 的字节）

- 冒烟（跑前）：seed 1 × `+vcs+initreg+0` × 20k 拍：checks=20000 errors=0；覆盖 enq 3654 / 同拍多条入队 332 /
  MMIO 请求 788 / NC 请求 1599 / MMIO 写回 772 / NC 写回 1 口 776、2 口 792 / 回滚 5066 / 异常 2330 / denied 92 /
  条目 flush 2649 / idResp 2592 / resp 2614。
- 激励调试中实测到的两个 **golden 自身的死锁形状**（不是重写的问题，是激励违反了真实环境的约束，已改激励并写进
  tb 文件头）：robIdx 重复 或 mmio/nc 同置 或 pendingPtr 在 MMIO 完成前跳走 ⇒ 多个 MMIO 条目同时进 S_REQ、
  都看到广播的 mmioReq.ready 一起进 S_RESP、只有一条请求真的发出，其余永远等不到 resp。
- 全矩阵（3 seed × {0, random, <seed>017} × 200k）在同一 commit 上**正在跑**，结果记入文末对账，不改本节。

### 2.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/LoadQueueUncache.json）

| 目标 | passing 模型 | 其余 |
|---|---|---|
| LoadQueueUncache | **45241**（fm_predict 模型：闭包寄存器位 + 顶层 output 位 6671） | failing 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |

预期差额（若出现，须由 receipt 的 constant_reg 逐位指认）：
- 16 条目 × {req_uop_flushPipe, req_uop_replayInst} = 32 位：UncacheEntry 单独签核时两侧各 2 个 `Constant reg`；
- pipelineReg_2（ncOut(0)，in_valid 恒 0）的 valid 与 1567 位 payload 可能被判常量（最多 1568 位）。
所以 passing 的可接受区间是 45241 − constant_reg，constant_reg 预计在 {32, 33, 1600} 之一附近；
若差额不能被 constant_reg + unread 精确解释，判红并查。

### 2.4 明写可能出错的地方

1. 结构体数组寄存器的 FM 名字形状（`s2_req_q_reg[0]\[uop_pc][3]`、`mmio_raw_q_reg\[lqData][3]`、
   1 位字段无位下标）照 LoadQueueReplay / InstrUncache matched.rpt 记下的形状写，没有 FM 试跑过；
   若被拒，fail-closed 整跑报错。
2. 条目内部寄存器靠 FM 自动按名配对（多一层 u_core）；LoadQueueRAW 同法已过，但规模大 16 倍。
3. match 规模：闭包约 38570 位寄存器，O(N²) 签名分析若没被钉点/名字消掉会很慢；3 小时不收敛按规范 30 分钟采样。
4. 本节没有做过任何 FM 试跑。

# dcache lane（agent/dcache）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `785649ac`（main，`git worktree add /home/eda/xs-env/wt-dcache -b agent/dcache main`） |
| 工作树 | `/home/eda/xs-env/wt-dcache`，分支 `agent/dcache` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | DCache（golden 23,854 行）的未签核 child → DCache 本体 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |
| codex 冲突 | 第 0 步已查：outbox 最新 codex_0197（50 个 Pmpaddr/Pmaaddr31/ShiftRightJam*/RightShift*）与 18 个 codex/* 分支对 main 的 diff 均未触及本 lane 任何目标及其 child |

## 1. 第一批：小 child（纯组合 / 小状态机）

### 1.1 结构与子模块处置

| 目标 | 重写件 | 说明 | child |
|---|---|---|---|
| Arbiter1_TagWriteReq | rtl/memblock/Arbiter1_TagWriteReq.sv | 单入 Arbiter = 直通 | 无 |
| Arbiter1_L1BankedDataWriteReq | rtl/memblock/Arbiter1_L1BankedDataWriteReq.sv | 同上（数据半边） | 无 |
| Arbiter1_L1BankedDataWriteReqCtrl（×8 例化） | rtl/memblock/Arbiter1_L1BankedDataWriteReqCtrl.sv | 同上（地址半边） | 无 |
| TreeArbiter | rtl/memblock/TreeArbiter.sv | 复用 `xs_FixedPriorityArbiter_core`（核未改）；缺字段填 0 | 无 |
| MissReadyGen | rtl/memblock/MissReadyGen.sv | 逐口 ready = MQ ready & 无更高优先级 valid | 无 |
| PrefetcherMonitor | rtl/memblock/PrefetcherMonitor.sv | 窗口计数 + 开关状态机 | 无 |
| FDPrefetcherMonitor | rtl/memblock/FDPrefetcherMonitor.sv | golden 0 输出 0 寄存器（见 §1.4） | 无 |
| Queue1_RegMapperInput_6 | rtl/memblock/Queue1_RegMapperInput_6.sv | 薄变体，核 `xs_Queue1_RegMapperInput`（rtl/frontend/ICacheCtrlUnit.sv，与 _5 共用，核未改） | 无 |
| CtrlUnit | rtl/memblock/CtrlUnit.sv | 伪错误注入寄存器外设 | Queue1_RegMapperInput_6（本 lane）、NewPipelineConnectPipe_27 ×2（PROVEN_DIRECT）→ 两侧白盒 |
| CounterFilter | rtl/memblock/CounterFilter.sv | 15 项去重 FIFO | 无 |

`xs_FixedPriorityArbiter_core` 要求 NUM_IN>=2，三个单入仲裁器不用核（与已签的 Arbiter1_InsUncacheResp 同法）。

### 1.2 UT（3 seed × 3 initreg × 200k 拍，全部串行）

tb 由各目录 gen.py 生成（共用 `scripts/dual_tb_lib.py`：端口表读 golden、每拍逐位 `!==` 比全部输出、
每个输出位须见过 0/1、各对分支计数闸；不复位数据寄存器用 arm 条件"写过一次后才比"）。

| UT 目录 | 目标 | commit | 9 档结果 |
|---|---|---|---|
| DCacheLeaves | 3×Arbiter1 / TreeArbiter / MissReadyGen / PrefetcherMonitor / FDPrefetcherMonitor | aec7dfd6 | 9/9 checks=11399544 errors=0 cov_fail=0 |
| CtrlUnit | CtrlUnit（+ Queue1 回归对） | aec7dfd6 | 9/9 errors=0 cov_fail=0（checks 6755814..6788782） |
| Queue1_RegMapperInput_6 | Queue1_RegMapperInput_6 | 0354a9ea | 见对账 |
| CounterFilter | CounterFilter | 0354a9ea | 见对账 |

覆盖（seed 42 random 档）：TreeArbiter 各路胜出 68457/44105/30532/23307、无人请求 33591、背压 83555；
MissReadyGen 被压住 25280/12658/6345；PrefetcherMonitor 及时性窗口结束 149、有效性窗口结束 130、
trigger_disable 45、只 late_hit 27、late_miss 压住 late_hit 95、退避恢复 1；
CtrlUnit tag/data 通道 fire 14378/16187、延迟递减 13271、persist 重装 2373、写 ctrl/delay/mask7 1839/1946/1828、
部分字节写 7037、读 12342。
UT 结构上到不了的：PrefetcherMonitor 的 conf_reset（要连续低置信 200000 拍），归 FM。

UT 抓到并已修的真错：PrefetcherMonitor 初稿 `N'(~enable)`（按赋值语境先扩位再取反，得 0x3FFFE 而非 0/1），
seed 1 第 120489 拍 enable 失配。

复跑：`cd verif/ut/<目录> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/*.json）

模型 expected = golden 闭包寄存器位 + 顶层 output 位（merge_dup=false）。

| 目标 | expected | passing 预测 | 其余 |
|---|---|---|---|
| Arbiter1_TagWriteReq | 49 | **49** | failing/unverified/unmatched/unread 全 0，无黑盒，SUCCEEDED |
| Arbiter1_L1BankedDataWriteReq | 521 | **521** | 同上 |
| Arbiter1_L1BankedDataWriteReqCtrl | 53 | **53** | 同上 |
| TreeArbiter | 981 | **981** | 同上 |
| MissReadyGen | 412 | **412** | 同上 |
| PrefetcherMonitor | 96 | **96** | 同上 |
| Queue1_RegMapperInput_6 | 169 | **169** | 同上 |
| CounterFilter | 204 | **204** | 同上 |
| CtrlUnit | 2493 | **2493** | vmucp 开（verif/fm_target_config/CtrlUnit.tcl）：unread 455 → 0；钉点 1040/1040；其余全 0 |

非正式试跑（活动工作树 `make fm-*`，不出 receipt）：CtrlUnit（vmucp 关）2038 + unread 455（钉点前全部
unmatched unread，钉后全部 matched_nc），vmucp 开 2493；Queue1_RegMapperInput_6 169；CounterFilter 204。
其余 6 个未试跑，数字纯按模型。

### 1.4 FDPrefetcherMonitor 与 StorePipe 的处置（不跑 FM）

- **FDPrefetcherMonitor**：golden 在 KunminghuV2Config 下 0 输出、0 寄存器（`io.pf_ctrl := DontCare`，
  全部计数器只供 XSPerf，firtool 全删），FM 无比较点。重写件只保留逐位一致的端口表；
  端口契约 `make -C verif/ut/DCacheLeaves portlint-fdp`；两侧在 UT 里一起 elaborate。
  不列入 FM_VARIANTS，不出 receipt，台账如实保持 UNPROVEN（与 StorePipe 同类）。
- **StorePipe**：仓里已有处置记录——`docs/fm_predictions/StorePipe.json`（model_applicable=false）、
  `docs/closure_symmetry_ledger.tsv`（SPECIAL：golden 为 DCE 塌缩探针壳）、rtl/memblock/StorePipe.sv（NO_OUTPUT，
  wrapper 与 golden 同为 1 输入 0 输出）。照记录办，本 lane 不硬证。

## 对账

（跑完追加）

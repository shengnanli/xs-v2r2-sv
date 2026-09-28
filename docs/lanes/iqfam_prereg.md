# iqfam lane（agent/iqfam）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `4728f823`（main，`git worktree add /home/eda/xs-env/wt-iqfam -b agent/iqfam main`） |
| 工作树 | `/home/eda/xs-env/wt-iqfam`，分支 `agent/iqfam` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 冲突检查 | codex outbox 最新 0197（50 个 Pmpaddr/Pmaaddr/ShiftRight 叶子）与各 `codex/*` 分支 diff 均不含 NewAgeDetector / MultiWakeupQueue / IssueQueue / Scheduler |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

## 1. NewAgeDetector / NewAgeDetector_6（共用核 xs_NewAgeDetector_core）

### 1.1 结构与子模块处置
- Chisel `NewAgeDetector(numEntries=2, numEnq=2, numDeq)`：入队条目区（2 条目）的年龄矩阵，
  只存上三角 1 位 `age_0_1`（异步复位清 0）。golden 均为叶子（0 子模块），无黑盒。
- 可读核 `rtl/backend/xs_NewAgeDetector_core.sv`（参数 NUM_ENTRIES/NUM_DEQ），
  薄 wrapper `NewAgeDetector.sv`（2 发射口）/ `NewAgeDetector_6.sv`（1 发射口），手写。

### 1.2 UT（verif/ut/NewAgeDetector，两变体同测）
见 §3 汇总表（跑完追加）。变异自检（scratchpad，不进库，seed 7 × 20k 拍）：
- M1 次态规则 (1) 加 `& ~enq[i]`（同拍进队时优先级反转）⇒ errors=5640 CAUGHT
- M3 复位值 0→1 ⇒ errors=34 CAUGHT
- M2 去掉时钟使能 ⇒ errors=0 —— **等价变异**（规则 (3) 本就保持原值，使能不改变行为；FM 同样会判等价）

### 1.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/*.json）

| 目标 | passing 预测 | 其余 |
|---|---|---|
| NewAgeDetector   | **5**（1 reg + 4 output 位） | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| NewAgeDetector_6 | **3**（1 reg + 2 output 位） | 同上 |

## 2. MultiWakeupQueue / _2 / _4 / _5（共用核 xs_MultiWakeupQueue_core）

### 2.1 结构与子模块处置
- 核 = 流水之外的那部分：出口冲刷（redirect / ld2Cancel / og0Fail|og1Fail 按 lat）、
  出口 loadDependency 左移、Mux1H 按位或汇合（单流水时直通不看 valid，写使能位恒被 valid 门控）、
  末级 lastConnect（不复位）+ 复制件。
- child：PipeWithFlush / _1 / _6 / _7 / _8 / _9 / _10 / _11，`docs/coverage_three_axis.tsv` 全部 PROVEN_DIRECT。
  处置 = **两侧白盒**（ref golden 同名件，impl `rtl/common/PipeWithFlush*.sv`），实例名与 golden 相同（pipes_i），无黑盒。

### 2.2 变异自检（scratchpad，seed 7 × 20k 拍，全部 CAUGHT）
| 变异 | errors |
|---|---|
| M1 lat=2 不判 og1Fail | 688 |
| M2 Mux1H 改优先级选择 | 1613 |
| M3 出口 loadDependency 不左移 | 912 |
| M4 flushItself 不看 level | 71 |
| M5 单流水也按 valid 清零载荷 | 5876 |
| M6 load 取消读 dep[0] 而非 dep[1] | 311 |

### 2.3 跑前预测（★跑完不许改本节★）

| 目标 | passing 预测（golden 闭包寄存器位 + 顶层 output 位） | 其余 |
|---|---|---|
| MultiWakeupQueue   | **402**（261 + 141） | failing 0 / unverified 0 / unmatched 0 / 无黑盒 / SUCCEEDED |
| MultiWakeupQueue_2 | **212**（106 + 106） | 同上 |
| MultiWakeupQueue_4 | **430**（383 + 47）  | 同上 |
| MultiWakeupQueue_5 | **96**（86 + 10）    | 同上 |

### 2.4 明写可能出错的地方
1. MultiWakeupQueue 的 PipeWithFlush_1 里 `bits_2_loadDependency_k[0]` 恒 0（老化左移），预计 FM 记为
   constant_reg（3 位）→ passing 比模型少 3，差额应被 constant_reg 指认。
   同一 child 里 `bits_1_loadDependency_k[1]` 只移进 bits_2 的高位后又被 `{dep[0],0}` 改写丢弃，
   在本父级可能表现为 unread（两侧对称，child 自身签核时同形）。若出现 unread，按 vmucp 六条处置，不猜。
2. lastConnect 复制件与原件逐位同源，merge_dup=false 下各自成比较点；若 passing 恰好少 90 / 90 的倍数，
   是合并/配对问题而不是 RTL 问题。
3. 本节未做任何 FM 试跑，数字纯按模型登记。

## 3. UT 汇总（跑完追加）

（以下为跑完后追加，§1–§2 未改）

| UT | 字节所在 commit | seed 1 / 7 / 42 × initreg `0` / `random` / `<seed>017`，各 200k 拍 |
|---|---|---|
| NewAgeDetector（2 变体同测） | 15deab32（RTL 同 857e9d0b） | 9 档全部 errors=0 TEST PASSED；checks 197999 / 197905 / 198023 |
| MultiWakeupQueue（4 变体同测） | 1338bdb2（RTL 同 15deab32） | 9 档全部 errors=0 TEST PASSED；checks 196916 / 196793 / 196975 |

覆盖（seed 42, initreg 42017）：MWQ 各变体 deq 有效 44014 / 137964 / 73771 / 36492 拍；出口冲刷杀掉
5818 / – / 13432 / 8839 次；多流水同拍汇合 2504 / – / 11557 / 2099 次；lat=2 出口仅因 ld2Cancel 被杀 1619 次；
中途复位 1016 次（"–" = 该变体结构上无此事件：MWQ_2 只有一条 lat=0 流水）。
NewAgeDetector：两条目同拍进队 ≈59k 拍、canIssue=11 时选 0 号 ≈74k / 选 1 号 ≈25k、中途复位 ≈2k 次。

复跑：`bash <scratchpad>/iqfam/ut9.sh <NewAgeDetector|MultiWakeupQueue>`，
即 `cd verif/ut/<UT> && make run SEED=<s> INITREG=<0|random|<s>017>`。

## 4. 对账（FM，run_proof.sh，证明 commit 1338bdb2，evidence/1338bdb28432/）

| 目标 | 预测 passing | 实测 | failing | unmatched | unread | 黑盒 | dont_verify | verdict |
|---|---|---|---|---|---|---|---|---|
| NewAgeDetector     | 5   | 5   | 0 | 0 | 0 | 0 | 否 | SUCCEEDED |
| NewAgeDetector_6   | 3   | 3   | 0 | 0 | 0 | 0 | 否 | SUCCEEDED |
| MultiWakeupQueue   | 402 | 402 | 0 | 0 | 0 | 0 | 否 | SUCCEEDED |
| MultiWakeupQueue_2 | 212 | 212 | 0 | 0 | 0 | 0 | 否 | SUCCEEDED |
| MultiWakeupQueue_4 | 430 | 430 | 0 | 0 | 0 | 0 | 否 | SUCCEEDED |
| MultiWakeupQueue_5 | 96  | 96  | 0 | 0 | 0 | 0 | 否 | SUCCEEDED |

`python3 scripts/fm_predict.py check <6 个目标>` → 全部逐位相等（差 0）。
§2.4 第 1 条的担心（constant_reg 3 位 / unread）**没有发生**：passing 与模型逐位相等，说明
FM 在本父级里把 PipeWithFlush_1 的那几位也计成了比较点（两侧同构），不是常量寄存器。

## 5. IssueQueue 家族（14 变体，共享核 xs_IssueQueue_core）

### 5.1 结构与子模块处置
- 可读核 `rtl/backend/xs_IssueQueue_core.sv`（手写）：入队翻译/ready、三段选最老（comp>simp>enq）、
  Mux1H、OHToUInt(Chisel 递归二分)、deqDelay 打拍、性能计时器、validCntDeqVec、wakeupToIQ 胶合
  （MWQ lat 查表 / is0Lat / og1 失败冲刷 / 写使能门控；Ldu load 唤醒打拍；VecMem blocked；写回忙表 deqResp.valid）。
- wrapper `rtl/backend/IssueQueue<V>.sv` 由 `scripts/gen_iq.py` 从 golden 端口表与实例连线机械生成（`--check`）；
  规则 fail-closed：子模块输入只许接顶层端口/常量/子模块输出/纯拼接，或胶合规则表里列出的核输出。
- child 全部两侧白盒：Entries<V>（PROVEN）、FuBusyTable*（PROVEN）、MultiWakeupQueue*/NewAgeDetector*（本 lane §1–§4 已签）、
  AgeDetector*（PROVEN）、PipeWithFlush*（PROVEN），以及 golden Entries 内部的 EnqEntry/OthersEntry/EnqPolicy/UIntCompressor
  （ref 侧依赖闭包；impl 侧 Entries 重写是扁平的）。无黑盒。
- FM 钉点 `verif/ut/<V>/fm_pins_pre.tcl`（`gen_fm_pins.py`）：原样复用 Entries<V> 已签核的钉点表加实例前缀，
  另加 IQ 层 validCntDeqVec 打拍寄存器无人读高位的配对；计数 fail-closed。
- vmucp：只在一次未开 vmucp 的诊断跑（diagnostic-full，不产 receipt）经 `vmucp_check.py` 核定
  "unread 全是 matched_nc 且逐对都是钉点"之后，由 `gen_vmucp_cfg.py` 写 `verif/fm_target_config/<V>.tcl`。

### 5.2 IssueQueueAluCsrFenceDiv（canary）跑前预测（★跑完不许改本节★）
- 非正式试跑（全部是 diagnostic-full，不产 receipt，如实列出）：
  (a) 57deb048 字节（核扩展前）、无 vcnt 钉点：native SUCCEEDED，passing 20833 / failing 0 / unmatched compare 0，
      unread 6220 matched_nc + 1(1) unmatched（io_validCntDeqVec_0_REG[5] ↔ vcnt_q[5]）→ 于是补了 vcnt 钉点；
  (b) 821b5475 字节（当前 RTL）：native SUCCEEDED，passing 20833 / failing 0 / unmatched 0 / unread 6221（全 matched_nc，
      vmucp_check：不在钉点表 0、未配对 0）/ constant_reg 12；1851 s，2704 MB。
- 登记（fm_predict model，merge_dup=false）：**27066** = golden 闭包寄存器位 24889 + output 位 2177。
- 预期实测（开 vmucp）：passing = 20833 + 6221 = **27054**，与模型差 12，应恰好被 constant_reg 12 指认；
  failing 0 / unverified 0 / unmatched 0 / unread 0 / 黑盒 0 / 无 dont_verify / SUCCEEDED。
- 变异自检（scratchpad，seed 7 × 5k 拍，`+cmp_all`，全部 CAUGHT）：simp 段不被 comp 屏蔽 82939；入队 ready 不看已发射 60820；
  x0 不翻 zero 47；srcLoadDependency 不左移 85875；OHToUInt 改式 821；deqDelay 负载不看使能 27；validCnt 不减 fire 639；
  issueTime 不 +1 9996；转移请求不看 issued 89854；deq valid 不看 cancelDeq 976。

### 5.3 其余 13 个变体跑前预测（★跑完不许改本节★；每行在该变体 proof 之前提交）

口径同 5.2：登记值 = fm_predict 模型（merge_dup=false）；诊断跑 = diagnostic-full、不产 receipt、未开 vmucp；
开 vmucp 后预期实测 = 诊断 passing + 诊断 unread，与模型之差应恰好被 constant_reg 指认。
其余项预期全部为：failing 0 / unverified 0 / unmatched 0 / unread 0 / 黑盒 0 / 无 dont_verify / SUCCEEDED。

| 目标 | 登记 passing（模型） | 诊断跑 | 预期实测 |
|---|---|---|---|
| IssueQueueAluBrhJmpI2fVsetriwiVsetriwvfI2v | 27502 | 821b5475：passing 21370 / unread 6118（全 matched_nc，全在钉点表）/ constant_reg 14 | **27488**（差 14，应 = constant_reg 14） |
| IssueQueueFaluFmac | 16860 | b3a9f6c8：passing 13641 / unread 3142（全 matched_nc，全在钉点表）/ constant_reg 77 | **16783**（差 77，应 = constant_reg 77） |
| IssueQueueAluMulBkuBrhJmp | 27358 | 834fdd40：passing 21015 / unread 6329（全 matched_nc，全在钉点表）/ constant_reg 14 | **27344**（差 14，应 = constant_reg 14） |

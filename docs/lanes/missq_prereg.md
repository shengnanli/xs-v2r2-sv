# DCache MissQueue lane（agent/missq）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `3992f2dd`（main，`git worktree add /home/eda/xs-env/wt-missq -b agent/missq main`） |
| 工作树 | `/home/eda/xs-env/wt-missq`，分支 `agent/missq` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | 叶子 `Arbiter16_MainPipeReq` → `CMOUnit` → `MissEntry`（×16 例化同一模块）→ 本体 `MissQueue` |
| child 状况 | `docs/coverage_three_axis.tsv`：四者全部 `MISSING/UNPROVEN`；golden MissQueue 的直接 child 只有这三种（16+1+1 实例），无其它子模块 |
| codex 冲突 | 查过 outbox 0176..0195 与 15 个 `codex/*` 分支 diff：无一触及本 lane 目标（codex 只在 Pmaaddr/CSR/算术叶子）。旧消息里的 `L2TlbMissQueue` 是 L2TLB 的另一个模块 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

## 1. Arbiter16_MainPipeReq（golden 842 行 / 272 端口，纯组合）

### 1.1 核与 golden 差异点

- 重写件 `rtl/memblock/Arbiter16_MainPipeReq.sv` = 薄文件，设参例化已签核共享核
  `rtl/frontend/xs_FixedPriorityArbiter_core.sv`（**未改动共享核**）。WIDTH=401，NUM_IN=16。
- 16 路字段集合完全相同（14 个字段），**没有常量字段**（与 Arbiter4 不同：MissEntry 的 miss/probe 常量
  在下游 Arbiter4 里才折叠）。端口表 + 逐路拼包由 `scripts/gen_missq.py` 生成（`--check` 已进 gate_all），
  生成时核对 golden 端口表 == 预期形状（16×16+2+14=272）。

### 1.2 UT（verif/ut/Arbiter16_MainPipeReq，gen.py 生成 tb；3 档 initreg × 3 seed × 200k，串行）

seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`, `+vcs+initreg+<seed>017`} 9/9
`checks=200000 errors=0 cov_fail=0` TEST PASSED（纯组合，initreg 不影响，照规矩跑满）。
覆盖（seed 1）：16 路各自胜出 34308 / 20869 / … / 4034（最少的第 15 路 4034 ≥ COV_MIN=1000）；
无人请求 55743；out_ready=0 100092；每个输出位见过 0 与 1。
tb 分辨力自测（20k 拍）：拼包下标 `k`→`k^1`（相邻两路互换）errors=250278；
`access` 输出或上 `evict_btot` errors=5052。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/Arbiter16_MainPipeReq.json）

| 项 | 预测 |
|---|---|
| passing | **正好 418**（模型 = 0 寄存器 + 418 输出位 = 401 载荷 + out_valid + 16 根 in_ready） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0 |
| 黑盒 | 无 |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / false |

可能出错：无（纯组合、共享核已签核三次）。本节没有做过任何 FM 试跑。

## 2. CMOUnit（golden 231 行 / 20 端口，无子模块）

### 2.1 核与 golden 差异点

- `rtl/memblock/CMOUnit.sv`：`xs_CMOUnit_core`（enum 四状态机 IDLE/SREQ/WRESP/LSQ_RESP + 锁存的请求 +
  denied/corrupt/no_pending + wfiSafe 打拍）+ golden 同名 wrapper（只改名）。`_GEN_`/`_T_` 0。
- 照 golden 端口表：nderr 寄存器 golden 已随 `resp_to_lsq.nderr/address` 输出一起被 DCE，核里不写；
  `req_address` 保留 64 位（Scala CMOReq 原宽），[63:48] 两侧对称死位 → vmucp
  （`verif/fm_target_config/CMOUnit.tcl`，16 对 FM 按名自动配上）。
- 复位域照 golden：state/denied/corrupt/no_pending/wfiSafe 异步复位；req_opcode/req_address 不复位。

### 2.2 UT（verif/ut/CMOUnit；3 档 initreg × 3 seed × 200k，串行）

9/9 `errors=0 cov_fail=0` TEST PASSED（checks=200059/200060/200071，含随机异步复位期间的比较）。
+random 下 req_address 两实例初值不同，tb 暖机＝复位后第一拍强制接一条请求再开比较窗口。
覆盖（seed 1）：req.fire 14546 / A.fire 14524 / D.fire 14504 / resp.fire 14499 / wfiReq 挡 A 39920 /
D 带 denied|corrupt 6390 / 非 WRESP 态来 D 被忽略 35531 / 异步复位 59 次；每个输出位见过 0 和 1
（A opcode 高两位结构恒 1，gen.py 显式豁免 toggle，仍逐位比较）。
tb 分辨力自测（20k 拍）：去掉 A.valid 的 wfiReq 门控 errors=15555；D 收下时不置 no_pending errors=5110；
接新请求不清 denied errors=3222；opcode 3 误映射成 Inval errors=2607。

### 2.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/CMOUnit.json）

| 项 | 预测 |
|---|---|
| passing | **正好 132**（模型 = golden 寄存器 73 + 输出 59） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0 |
| 黑盒 | 无 |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |

lane 内 diagnostic-full 试跑（dirty，未出 receipt）两次：vmucp 关 passing 116 + matched-unread 16；
vmucp 开 passing 132 / failing 0 / unmatched 0。可能出错：无已知风险。

## 3. MissEntry（golden 1,505 行 / 155 端口，无子模块；MissQueue 里 16 份例化同一模块）

### 3.1 核与 golden 差异点

- `rtl/memblock/MissEntry.sv`（1,275 行，`_GEN_`/`_T_` 0）：missentry_pkg（常量、请求/通道结构体、
  命令分类与 ClientMetadata.onAccess 的 grow 表）+ xs_MissEntry_core（§1 接收新请求 / §2 请求与 s_*/w_* 状态
  寄存器，always_ff 严格按 Scala 语句顺序"后写者赢" / §3 A / §4-5 D·E / §6 MainPipe 回填请求 / §7 其它输出 /
  §8 延迟监控 / §9 断言与性能计数寄存器）+ golden 同名 wrapper（端口表与结构体拆装由 `scripts/gen_missq.py`
  生成：每个 golden 端口恰好一条规则、方向位宽逐个核对）。
- 本配置折叠照 golden：nMaxPrefetchEntry=14 ⇒ 能接预取的表项 = id>=2；grant.ready 恒 1；isDirty/miss_dirty 等 DCE。
- 寄存器一一对应：每个请求口一份的 RegNext(primary_fire)（10 个）与 RegNext(id>=2)（5 个）照留；
  §9 死寄存器（REG..REG_7、r/r_3/r_4、last_REG_5..7、refill_finished_last_REG、3 个 64 位 counter）照留。
- FM 钉点 `verif/ut/MissEntry/fm_pins_pre.tcl`（gen_missq.py 生成，229 对逐位写死，`ME_PREPIN_END n=229`）+
  vmucp（`verif/fm_target_config/MissEntry.tcl`）。
- lane 内 diagnostic-full 试跑（dirty，未出 receipt）两次：
  1. 无钉点/无 vmucp：native FAILED passing 4093 / failing 7 / unmatched 10(10) / unread 209（matched_nc 2 +
     unmatched-unread 207(207)）/ constant reg 6 —— failing 全在 10 个未配上的 RegNext(primary_fire) 下游。
  2. 加钉点 + vmucp：native SUCCEEDED passing **4319** / failing 0 / unmatched 0 / constant reg 6。
- constant reg 6 的身份（单独一次 FM match 后 `report_potentially_constant_registers` 实查）：
  `req_q.addr[5:0]` —— 每次写入都是 `{addr[47:6], 6'h0}`，不复位，FM 视为初值后恒 0（golden `req_addr[5:0]` 同）。

### 3.2 UT（verif/ut/MissEntry；3 档 initreg × 3 seed × 200k，串行）

9/9 `errors=0 cov_fail=0` TEST PASSED（checks 200032 / 200042 / 200045）。激励：地址取自 4 行 × 2 alias 的小池（每 2000 拍换池）、
alloc/merge/cancel 随机、Grant/GrantData × size 5/6、MainPipe resp/replay/evict、L2 hint、wfiReq 成段、io_id 每 4000 拍在
{0,1}/{2..15} 交替、随机异步复位；暖机 = store 分配 + 两拍 GrantData，写定所有不复位且输出可见的寄存器后才开比较。
覆盖（seed 1 / initreg 0，全部 ≥ COV_MIN=200）：alloc 35949 / merge load 14401 / merge store 9005 / A.fire 17123（AcquirePerm 1312）/
GrantData 关键字 7883 / 非关键字 31107 / 无数据 Grant 11021 / Grant 与 store 字节合并 14686 / E.fire 19994 / MainPipe 请求 26611 /
replay 10127 / evict 9541 / 释放 9098 / handled 8813 / 可接预取表项 primary_ready 17438 / 非预取表项挡预取 3761 / secondary_ready 1719 /
reject 18146 / query 合并 6827 / query 拒绝 64136 / late prefetch 1423 / probe 阻挡 9036 / replace 阻挡 19871 / refill_to_ldq 22182 /
wfiReq 挡 A 14195 / 前递"只到第一拍" 14591 / 异步复位 32；每个输出位见过 0 和 1（结构恒定位 gen.py 逐个豁免、仍逐位比较）。
tb 分辨力自测（20k 拍，9/9 抓到）：A.valid 去掉"合并 store 时先别发" errors=383；row 下标不按 isKeyword 翻转 35357；
store 字节合并掩码取反 128952；merge 不再保持 isKeyword 16740；reject 去掉 alias 项 1636；无数据 Grant 不再保持数据 7794；
replay/evict 优先级对调 177；可接预取表项 primary_ready 去掉"刚分配"打拍 1471；firstbeat 不按 isKeyword 对调 290。
UT 看不见的：§9 死寄存器（无输出）—— 由 FM vmucp 逐位实比覆盖。

### 3.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/MissEntry.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **4325**（golden 寄存器 1806 + 输出 2519）；实测预计 **4319**，差 6 由 receipt `constant_reg`=6 指认（req_addr[5:0]） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`ME_PREPIN_END MissEntry n=229 expect=229`） |
| 黑盒 | 无 |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |

可能出错：run_proof 在 detached worktree 里跑，钉点叶名若格式不同钉点脚本会 `error` 早退（表现为 FM 早退）。

## 4. MissQueue（本体，golden 9,125 行 / 212 端口；child = 16×MissEntry + CMOUnit + Arbiter16_MainPipeReq）

### 4.1 核与 golden 差异点

- `rtl/memblock/MissQueue.sv`（4,231 行：missqueue_pkg + xs_MissQueue_core 手写约 1,075 行；其余是生成的 wrapper，
  `_GEN_`/`_T_` 0）：核 = 全部胶水（§1 s0 入队判定 / §2 resp 与流水寄存器 / §3 memset 检测 / §4 MSHR 数据前递 /
  §5 D 通道·hint·MainPipe 回应分发 / §6 A 通道（流水寄存器直发 Acquire + 18 路 TLArbiter.lowest）/ §7 E 通道 16 路 /
  §8 refill_info·阻挡·BtoT 占路 / §9 预取统计·WFI·topdown·性能事件·difftest / §10 断言与性能计数死寄存器）。
- 新共享辅助件 `rtl/common/xs_TLArbiterLowest.sv`（rocket-chip TLArbiter.lowest 的可读实现，golden 里内联）。
- wrapper（`scripts/gen_missq.py` 生成，fail-closed）：golden 端口表 + 核 + **与 golden 同名的实例**
  entries_0..15 / cmo_unit / main_pipe_req_arb（子模块内部寄存器路径与 golden 对齐，FM 按名配对）；
  核对 MissQueue 每个输出恰好驱动一次、每个输入至少用一次，三种 child 的每个端口恰好一条连线规则
  （MissEntry 有 9 个输出 golden 父级不读，显式悬空）。
- 子模块两侧白盒：ref = golden MissEntry/CMOUnit/Arbiter16_MainPipeReq，impl = 本 lane 已签核的重写件
  （evidence/6d7db2615dbf、f9f232674f20、bc1ed4b6f3f9）。无黑盒。
- 钉点 `verif/ut/MissQueue/fm_pins_pre.tcl`（4174 对：顶层 TLArbiter state/beatsLeft、性能事件打拍、前递寄存器、
  流水寄存器标志与 addr[5:0] 死位、REG/max_inflight；16 个 MissEntry 各 229 对（同 MissEntry 签核）+ 各 2 对
  在父级才变死的 refill_to_ldq data/error 锁存）+ vmucp（`verif/fm_target_config/MissQueue.tcl`）。
- lane 内 diagnostic-full 试跑（dirty，未出 receipt）：
  1. 无钉点：Matching 后 unmatched compare 159(149)、unmatched unread 3462(3472)，按自己 PID 停掉。
  2. 钉点 4136 对 + vmucp：native SUCCEEDED passing **32571** / failing 0 / unmatched compare 0 /
     unmatched unread 38(38)（= 16×2 个 refill_to_ldq data/error 锁存 + 流水寄存器 addr[5:0]）/ constant reg 10。
     之后补上这 38 对（钉点共 4174 对，本 commit 的文件）。
- constant reg 10 的身份（单独一次 FM：读同一组文件、source 同一份钉点、match 后 `report_potentially_constant_registers`）：
  `entries_0` / `entries_1` 的 prefetch_slot_q[4:0] = RegNext(io_id >= 2)，io_id 在父级接常量 0/1 ⇒ 恒 0（golden 对应
  last_REG..last_REG_4）。

### 4.2 UT（verif/ut/MissQueue；3 档 initreg × 3 seed × 200k，串行）

两侧例化同一份子模块重写件（RTL_GOLDEN_DEPS），只比 MissQueue 胶水。暖机 = 16 个 MSHR 各分配一次 store + 各回两拍 GrantData。
首轮（tb 版本 = 本 commit 之前、仅 store 连发模式不同）9/9 `checks=200033 errors=0 cov_fail=0` TEST PASSED。
覆盖（首轮 seed 1 / initreg 0，全部 ≥ COV_MIN=100）：分配 16572 / 合并进表项 6999 / 合并进流水寄存器 1108 / 拒绝 93195 /
查询不 ready 149966 · ready 50390 / 流水寄存器发 Acquire 7542 / 表项发 Acquire 6352 / CMO 发 A 3769 / CBOAck 3741 / CMO 回 LSQ 3741 /
越界 source 的 Grant not ready 3172 / A 被挡 7508 / E.fire 14795 / 回填请求 fire 29122 / refill_info 14914 / probe 阻挡 39543 /
流水寄存器 replace 阻挡 2681 / BtoT 占路非零 18842 / occupy_fail 12014 / 前递命中 10260 / forward_mshr 159044 / memset 检测 40174 /
difftest 有效 4476 / wfiReq 期间 wfiSafe=1 6929 / 异步复位 33；每个输出位见过 0 和 1（结构恒定位 gen.py 逐个豁免、仍逐位比较）。
tb 分辨力自测（20k 拍）：primary_valid 去掉"只给最低空表项" errors=947054；流水寄存器允许 store 合并 store 28646；
越界 source 当成 ready 13；前递高 8 字节选错 row 478117；A 仲裁第 3 路恒 ready 1070；occupy 门槛 >2→>1 1549；
refill_info.valid 去掉 s2_valid 3025；性能事件 3/4 档边界 56；difftest valid 去掉 refill_done 426；
memset 门槛 8→7：首版 tb 20k 与 200k 都是 0 —— store 连发模式里计数器一路冲过 8、从不停在 7；
tb 改为 store/预取/少量 load 混合后 200k 拍 errors=170988（本 commit 的 tb）。
A 仲裁 beats_left 装载值改 0：errors=0 且**是等价变异**——各路 beats1 = ~opcode[2]，而 CMO（12..14）与
Acquire（6/7）的 opcode[2] 恒 1，本配置下永远装 0（FM 会把这条常量传播证明掉，UT 无从区分）。
UT 看不见的：顶层 REG / max_inflight 与子模块死寄存器 —— 由 FM vmucp 逐位实比覆盖。
本 commit 的 tb 9 档复跑结果在对账节追加。

### 4.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/MissQueue.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **32619**（golden 闭包寄存器 30416 + 输出 2203）；实测预计 **32609**，差 10 由 receipt `constant_reg`=10 指认 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0（`MQ_PREPIN_END MissQueue n=4174 expect=4174`） |
| 黑盒 | 无（三种 child 两侧白盒） |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |

可能出错：新补的 38 对钉点没有在 FM 里单独试过（其中流水寄存器 addr[5:0] 用了结构体成员写法 `pipe_q_reg\[addr]`，
与 MainPipe 钉点同写法；另一次 match-only 运行 `MQ_PREPIN_END n=4174` 已确认 4174 条全部被 FM 接受）。
若 FM 没把它们当 matched-unread 计入，passing 会是 32571（差 38）而不是 32609。

---

# 对账（跑完追加；上文各节未改一字）

## A. Arbiter16_MainPipeReq

| 项 | 值 |
|---|---|
| proof commit | `bc1ed4b6f3f9`（预测登记在同一 commit，早于证明；RTL/UT 在其父 `38852b39`） |
| 证据 | `evidence/bc1ed4b6f3f9/Arbiter16_MainPipeReq/receipt.json` sha256 `c836ebed8a2787117f33e57bf26b93320d42cd2723d8b1c33cabb42c07b63dd4` |
| impl_closure | `rtl/memblock/Arbiter16_MainPipeReq.sv` `f7bf16c1abd39ee8d6839545a49e5d6fd6fd98500146b3f79835b5d819fd3ba3`；`rtl/frontend/xs_FixedPriorityArbiter_core.sv` `e7c8526c…a5618`（未改） |
| 结果 | native SUCCEEDED，passing **418** / failing 0 / unverified 0 / unread_notcompared 0 / unmatched 全 0 / 无黑盒 / signoff-strict / dirty false / fm.log 行首 `Error:` 0 |
| `fm_predict.py check` | 预期 418，实测 418，差 0，「全部对上」 |

复跑：`cd /home/eda/xs-env/wt-missq && PROOF_COMMIT=bc1ed4b6 bash scripts/run_proof.sh Arbiter16_MainPipeReq Arbiter16_MainPipeReq < /dev/null`

## B. CMOUnit

| 项 | 值 |
|---|---|
| proof commit | `f9f232674f20`（预测登记在同一 commit，早于证明；RTL/UT/vmucp 配置在其父 `a9d9f37e`） |
| 证据 | `evidence/f9f232674f20/CMOUnit/receipt.json` sha256 `6552e4431bc7f30ecc313fc64c663fe218a4a15b77f07d640d9398e44632fb17` |
| impl_closure | `rtl/memblock/CMOUnit.sv` `f42240ccf3b6956900de1a89a4e762a0589091dae0b36042b80546a401442b9a` |
| 结果 | native SUCCEEDED，passing **132** / failing 0 / unverified 0 / unread_notcompared 0 / unmatched 全 0 / 无黑盒 / signoff-strict / vmucp true / dirty false / fm.log 行首 `Error:` 0 |
| `fm_predict.py check` | 预期 132，实测 132，差 0，「全部对上」 |

复跑：`cd /home/eda/xs-env/wt-missq && PROOF_COMMIT=f9f23267 bash scripts/run_proof.sh CMOUnit CMOUnit < /dev/null`

## C. MissEntry

| 项 | 值 |
|---|---|
| proof commit | `6d7db2615dbf`（预测登记在同一 commit，早于证明；RTL/UT/钉点/vmucp 在其父 `2afe33a6`）；因工作树里有未跟踪的 MissQueue 在写，用 `PROOF_COMMIT=6d7db261` 钉住 |
| 证据 | `evidence/6d7db2615dbf/MissEntry/receipt.json` sha256 `64174b1f377ed3539537ebc7f8b50bc614678d975fa830b731c7a5ce7883e1e7` |
| impl_closure | `rtl/memblock/MissEntry.sv` `f3443c48a0e8e5769a845ac0744e479bc0cb0dc67cb9ce6ac323baf16bda5a60` |
| 结果 | native SUCCEEDED，passing **4319** / failing 0 / unverified 0 / unread_notcompared 0 / unmatched 全 0 / constant_reg 6 / 无黑盒 / signoff-strict / vmucp true / dirty false / fm.log 行首 `Error:` 0 / `ME_PREPIN_END n=229` |
| `fm_predict.py check` | 模型 4325，实测 4319，差 6 = constant_reg 6，「全部对上」 |

§3.3 的"可能出错"没有发生。

复跑：`cd /home/eda/xs-env/wt-missq && PROOF_COMMIT=6d7db261 bash scripts/run_proof.sh MissEntry MissEntry < /dev/null`；
UT：`cd verif/ut/MissEntry && make run SEED=<1|7|42> INITREG=+vcs+initreg+<0|random|<seed>017>`（串行）。

## D. MissQueue

| 项 | 值 |
|---|---|
| proof commit | `a3f3ce7858c4`（预测登记在同一 commit，早于证明；RTL/UT/钉点/vmucp 在其父 `707e558b`），`PROOF_COMMIT=a3f3ce78` |
| 证据 | `evidence/a3f3ce7858c4/MissQueue/receipt.json` sha256 `e97c389731663482ab9bfcbd9d8642ab71c76cddb28157ff125224d01a4b19d7` |
| impl_closure | `rtl/memblock/MissQueue.sv` `0ba98c0577eb14a16855557ff6a28046b8e990325c54fea2bdca4f616d98c271`；`rtl/common/xs_TLArbiterLowest.sv` `8085498d3f078e687af79046a84714167dd052f23f696361eaef8354e67cd6f2`；子模块 MissEntry.sv / CMOUnit.sv / Arbiter16_MainPipeReq.sv / xs_FixedPriorityArbiter_core.sv 与各自签核时同字节 |
| 结果 | native SUCCEEDED，passing **32609** / failing 0 / unverified 0 / unread_notcompared 0 / unmatched 全 0（含 unread）/ constant_reg 10 / 无黑盒对（black_boxes.rpt 只列出两个 0 实例的参数化模板 xs_FixedPriorityArbiter_core / xs_TLArbiterLowest，与 MainPipe 证据同形）/ signoff-strict / vmucp true / dirty false / fm.log 行首 `Error:` 0 / `MQ_PREPIN_END n=4174` / 606 s、峰值 1623 MB |
| `fm_predict.py check` | 模型 32619，实测 32609，差 10 = constant_reg 10，「全部对上」 |

§4.3 的"可能出错"没有发生（新补的 38 对全部被计入）。

UT 复跑（本 commit 的 tb，9 档串行）：9/9 `errors=0 cov_fail=0` TEST PASSED（checks 200036 / 200037 / 200037）。
★一次基础设施事故，照实记★：复跑的第一档（seed 1 / +0）起初报 errors=170988 —— 与刚跑完的 memset 变异体
200k 拍读数逐位相同。原因：我的变异脚本恢复源文件用了 `cp -p`（保留旧 mtime），于是 make 认为 ut_gen 不旧、没有重编，
这一档跑的是**变异体的 simv**（derive 随后才把正确内容写回 ut_gen，下一档起重编）。ut_common.mk 注释里警告过的
"mtime 倒退"同一类坑。处置：脚本改为恢复后 touch；核对当前 ut_gen/MissQueue.sv 与已提交 RTL 派生结果逐字节相同；
单独重跑该档 → `checks=200036 errors=0 cov_fail=0`（坏日志另存为 sim_1_0.STALE_SIMV.log，不计入）。
覆盖（复跑 seed 1 / +0）：分配 16596 / 合并进表项 7753 / 合并进流水寄存器 1336 / 拒绝 92213 / memset 检测 2173 /
BtoT 占路 20878 / occupy_fail 13946 / difftest 4566 / 异步复位 36（其余量级同 §4.2）。

复跑：`cd /home/eda/xs-env/wt-missq && PROOF_COMMIT=a3f3ce78 bash scripts/run_proof.sh MissQueue MissQueue < /dev/null`；
UT：`cd verif/ut/MissQueue && make run SEED=<1|7|42> INITREG=+vcs+initreg+<0|random|<seed>017>`（串行）。

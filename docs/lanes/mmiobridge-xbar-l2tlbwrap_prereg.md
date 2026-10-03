# agent/mmiobridge-xbar-l2tlbwrap lane —— 跑前登记

基线：认领提交 `789ed728`（main `eb0400b5` 之上）；worktree `/home/eda/xs-env/wt-mmiobridge-xbar-l2tlbwrap`。
本文件在 FM 起跑**之前**提交；跑完只在文末「对账」追加，★不改已提交分节的任何数字★。
口径：全部 `FM_MERGE_DUP=false`、allowlist 空、无 dont_verify、无 vmucp；除 L2TLBWrapper（assembly）外全部 `signoff-strict`。
预测数字 = `python3 scripts/fm_predict.py model <T> --ut <UT>`（golden 闭包寄存器位 + 顶层 output 位），
已 `register` 进 `docs/fm_predictions/<T>.json`，与本文件同一提交。

## 1. 目标、实现与子模块处置

| 目标 | golden 行 | impl | 子模块 / 黑盒 | UT 目录 |
|---|---:|---|---|---|
| MMIOBridgeEntry / _2 / _4 / _8 | 505 ×4 | 共享核 `rtl/uncore/xs_MMIOBridgeEntry_core.sv`（ID_W=1/2/3/4）+ 4 个薄文件 | 无 | MMIOBridgeLeaves |
| Arbiter16_CHIDAT | 646 | 已签核核 `xs_FixedPriorityArbiter_core`（未改）+ `scripts/gen_arbiter_chidat_l2tlb.py` 薄文件 | 无 | MMIOBridgeLeaves |
| Arbiter3_L2TLBImp_Anon | 1505 | 同上（入口 0 缺 10 字段 / 入口 1 缺 1 字段，按 golden 填 0） | 无 | BusArbLeaves |
| BusPerfMonitor | 624 | `scripts/gen_busperfmonitor.py`（综合配置下 97 根直连，生成器断言端口完全配对） | 无 | BusArbLeaves |
| PTWRepeaterNB | 528 | 核 `rtl/mmu/xs_PTWRepeaterNB_core.sv` + `scripts/gen_payload_shells.py` 薄文件 | DelayN_1（PROVEN_DIRECT）两侧白盒：ref golden、impl `rtl/common/DelayN_1.sv` | PTWRepeaterNB |
| skidBufferConnect | 1265 | 核 `rtl/memblock/xs_SkidBuffer_core.sv` + 同一生成器薄文件 | 无 | skidBufferConnect |
| TLXbar_6 | 857 | 手写核 + 新共享件 `rtl/common/xs_TLArbiterRoundRobin.sv` | 无 | TLXbar_6 |
| TLXbar_5 | 1691 | 手写核（结构体端口）+ 同一共享仲裁器 + `scripts/gen_tlxbar5_wrapper.py` 生成 wrapper | 无 | TLXbar_5 |
| L2TLBWrapper | 1018 | `scripts/gen_l2tlbwrapper.py`（端口直通 + 19 路 perf 两拍） | **L2TLB 两侧对称黑盒**（见 §3） | L2TLBWrapper |

`_GEN_`/`_T_` 全部为 0；`scripts/readability_audit.py --quiet` rc=0。

## 2. FM 跑前预测（★跑完不许改本节★）

| 目标 | 预测 passing | 其余 |
|---|---:|---|
| MMIOBridgeEntry | 962（regs 429 + outs 533） | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 |
| MMIOBridgeEntry_2 | 962 | 同上 |
| MMIOBridgeEntry_4 | 962 | 同上 |
| MMIOBridgeEntry_8 | 962 | 同上 |
| Arbiter16_CHIDAT | 371（纯组合） | 同上 |
| Arbiter3_L2TLBImp_Anon | 1120（纯组合） | 同上 |
| BusPerfMonitor | 2719（纯直连） | 同上 |
| PTWRepeaterNB | 628（regs 314 + outs 314） | 同上；fm_pins_pre 312 条（golden 顶层寄存器位，DelayN_1 内部不钉） |
| skidBufferConnect | 3551（regs 1775 + outs 1776） | 同上；fm_pins_pre 1775 条。★可能偏离★：golden 有 ~70 个"入口被钉 0"的常量寄存器（如 dataBuffer_uop_instr），FM 会把它们判 constant_reg 不出比较点，差额应 = receipt 的 constant_reg |
| TLXbar_6 | 564（regs 29 + outs 535） | 同上；无钉点 |
| TLXbar_5 | 4446（regs 64 + outs 4382） | 同上；无钉点（若 matching 卡住再按仲裁器实例生成钉点，届时追记于此） |
| L2TLBWrapper | 5139（模型输出） | assembly；黑盒 = L2TLB ×2（对称）；verdict 预计停在条件绿（L2TLB 无证书） |

### 2.1 已有的非正式观测（如实记账）
- TLXbar_6 在登记前跑过一次 `FM_MODE=diagnostic-full`（工作树 dirty、不产 receipt）：native SUCCEEDED、passing 564、
  failing 0、unmatched 0。所以 TLXbar_6 这一行**不是盲预测**。其余目标登记前没有跑过任何 FM。

## 3. L2TLBWrapper 的条件项（L2TLB 按仓内现状处理）

- 仓内 L2TLB 现状：`verif/ut/L2TLB` 以 `FM_INTERFACE_ONLY` 黑盒 8 个 child、assembly 模式、native SUCCEEDED，
  `verif/allow/L2TLB.json` 故意不填 child 证书 ⇒ L2TLB 自身是**条件绿**（无证书）。
- 本层同样走 assembly：`FM_INTERFACE_ONLY = L2TLB`，ref 侧 golden L2TLB.sv、impl 侧也读 golden L2TLB.sv（只取接口，
  RTL_GOLDEN_DEPS），实例名两侧都是 `ptw` ⇒ 对称黑盒。声明在 `verif/allow/L2TLBWrapper.json`（class green_child，
  child_target L2TLB，**不填 certificate_sha256**）。
- 因此：本层 glue 的 FM 可以 native SUCCEEDED，但最终判定**挂着 L2TLB 一项**；L2TLB 出证后需填证书并重跑本层。
- UT 两侧外壳里都是同一个 golden L2TLB 闭包，比的只是外壳 glue；激励从 `verif/ut/L2TLB/tb.sv` 机械派生；
  双 L2TLB 实例不能用 `+vcs+initreg+random`（两实例各摇初值、与外壳无关地失配），照 L2TLB 先例跑 0 / 1 两档。

## 4. UT 判据

seed 1/7/42 × `+vcs+initreg+0` / `+random` / `+<seed>017`（L2TLBWrapper 为 0 / 1），各 200k 拍 errors=0、覆盖闸 0 失败；
seed 串行。复跑：`cd verif/ut/<UT> && make run SEED=<s> INITREG=<档>`。读数记在对账节。

## 对账（跑后追加）

### 追记（FM 起跑后、对账之前；不改上面任何数字）
- **skidBufferConnect 撤出本 lane**：storeunit-vsplit lane 已签核同名目标并合入 main（c352cf75，SUCCEEDED passing 3267）。
  按集成者裁定合 main 时两文件以 main 为准，本 lane 的 `xs_SkidBuffer_core.sv` / UT gen.py / fm_pins_pre.tcl 删除，
  `gen_payload_shells.py` 只剩 PTWRepeaterNB。§2 里 skidBufferConnect 的预测作废（不对账）；docs/fm_predictions/skidBufferConnect.json 取 main 版本。
  PTWRepeaterNB 不依赖 xs_SkidBuffer_core，不受影响。
- 首批证明（97d5fc20）中 PTWRepeaterNB / skidBufferConnect 在钉点阶段退出（Tcl 把双引号里的 `[N]` 当命令替换），
  修在 17364e53（钉点路径改花括号），PTWRepeaterNB 在修复后的 commit 上重证。

### 对账（2026-10-03）

FM（`scripts/run_proof.sh`，detached clean worktree；`python3 scripts/fm_predict.py check <T>` rc=0）：

| 目标 | 证明 commit | 判决 | passing 预测/实测 | failing / unmatched / 黑盒 / dont_verify |
|---|---|---|---|---|
| MMIOBridgeEntry / _2 / _4 / _8 | 97d5fc20 | SUCCEEDED ×4 | 962 / 962 ×4 | 0 / 0 / 0 / 无 |
| Arbiter16_CHIDAT | 97d5fc20 | SUCCEEDED | 371 / 371 | 0 / 0 / 0 / 无 |
| BusPerfMonitor | 97d5fc20 | SUCCEEDED | 2719 / 2719 | 0 / 0 / 0 / 无 |
| Arbiter3_L2TLBImp_Anon | 97d5fc20 | SUCCEEDED | 1120 / 1120 | 0 / 0 / 0 / 无 |
| TLXbar_6 | 97d5fc20 | SUCCEEDED | 564 / 564 | 0 / 0 / 0 / 无 |
| TLXbar_5 | 97d5fc20 | SUCCEEDED | 4446 / 4446 | 0 / 0 / 0 / 无（无钉点即配上） |
| PTWRepeaterNB | 17364e53 | SUCCEEDED | 628 / 628 | 0 / 0 / 0 / 无（钉点 312/312） |
| L2TLBWrapper | 97d5fc20 | native SUCCEEDED，判定 PARTIAL | 5139 / 5139 | 0 / 0 / L2TLB×2 对称（声明）/ 无；`green_child_certificate_not_in_commit:L2TLB` ⇒ 不出 receipt（与 L2TLB 本体同一处境） |

差额全部为 0。skidBufferConnect 撤出（见上方追记）。

UT（seed 1/7/42 串行，各 200k 拍）：MMIOBridgeLeaves / BusArbLeaves / PTWRepeaterNB / TLXbar_6 / TLXbar_5 各 9 档
（initreg 0 / random / <seed>017）errors=0 cov_fail=0；L2TLBWrapper 6 档（initreg 0 / 1）errors=0，覆盖闸
（a_fire/d_fire/tlb_req/tlb_resp/后半程活着/perf 非零）全过。

变异自检（scratchpad harness，seed 7 / initreg 0 / 20k 拍，16/16 CAUGHT）：
MMIOBridgeEntry 核 5 个（allowRetry 1→0 89k、DBIDRespOrd 漏判 166k、TXDAT 校验极性 80k、RXDAT ready 去 s_txreq 门控 213k、
corrupt 漏 poison 1946 ←余量最薄）；PTWRepeaterNB 2 个（flush 不清 sent 8.7k、resp_ready 恒 1 388k）；
共享仲裁器/TLXbar_6 3 个（mask 不做 leftOR 4.4k、in0 D 回程 source 判据改 [4] 37.7k、缓存控制区掩码 0xFF→0x7F 55k）；
TLXbar_5 4 个（多拍期间不锁 state 473k、A 两拍判据恒 0 172k、E 的 sink→bank 映射反向 29.6k、D 回程 icache/ptw 前缀互换 113k）；
L2TLBWrapper 1 个（perf 少打一拍 20k）。

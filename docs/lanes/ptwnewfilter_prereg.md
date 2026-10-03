# ptwnewfilter lane（agent/ptwnewfilter）—— 跑前登记

本文件在官方 FM（run_proof.sh）起跑之前提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `f8d3356d`（main；worktree 由集成者预建，认领 `61dc899a`） |
| 工作树 | `/home/eda/xs-env/wt-ptwnewfilter`，分支 `agent/ptwnewfilter` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标（按顺序） | `PTWFilterEntry_1`（child）→ `PTWNewFilter`（本体） |
| 冲突检查 | codex outbox 最新 0205（不含本 lane 目标）；claude_0204 第 6 批认领表把 PTWFilterEntry 划给 mmuleaf（已签），PTWFilterEntry_1/PTWNewFilter 无人认领；全部 worktree 的 claim/prereg 只有 newifu-ptwfilter（明写不例化 PTWFilterEntry）与 mmuleaf（明写 _1 不在本 lane）提到；各分支相对 main 的 rtl 改动无本 lane 目标 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| 生成器 | `scripts/gen_ptwnewfilter.py`（带 `--check`）；`verif/ut/PTWNewFilter/gen_tb.py`（带 `--check`） |
| 共享核 | `xs_PTWFilterEntry_core`（rtl/memblock/PTWFilterEntry.sv）**未改一字节**（`git diff main -- rtl/memblock/PTWFilterEntry.sv` 空），PTWFilterEntry 的证书不受影响 |

## 1. PTWFilterEntry_1（golden 1,480 行 / 0 child）

### 1.1 结构

- 与 PTWFilterEntry 同一个 Chisel 类（Repeater.scala class PTWFilterEntry），参数 Width=2 / Size=8 / hasHint=false；
  PTWNewFilter 里 store_filter 与 prefetch_filter 两份实例共用此模块。golden diff 的维度只有：lane 数 4→2、项数 16→8、
  下标 4→3 位、无 hint 端口；Width==2 分支"每 lane 对半分区"与 Width==4 的"每 lane 4 项"通式结果一致。
- 处置：复用核，写薄 wrapper `rtl/memblock/PTWFilterEntry_1.sv`（132 行，代码区 `_GEN_`/`_T_` = 0）：
  `xs_PTWFilterEntry_core #(.W(2), .SIZE(8), .N_HINT(1))`，hint 输出接到 unused_* 线不再使用（纯组合，综合即删；
  不为 0 路 hint 改共享核）。端口表与命中键打包在 GENERATED 区。无子模块、无黑盒。

### 1.2 UT（verif/ut/PTWFilterEntry_1；3 seed × 3 档初值 × 200k 拍，串行，commit 0f8a2684 的 RTL 字节）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=1199790 errors=0 PASS | checks=1199790 errors=0 PASS | (1017) checks=1199790 errors=0 PASS |
| 7  | checks=1199922 errors=0 PASS | checks=1199922 errors=0 PASS | (7017) checks=1199922 errors=0 PASS |
| 42 | checks=1199790 errors=0 PASS | checks=1199790 errors=0 PASS | (42017) checks=1199790 errors=0 PASS |

checks 三档相同是设计如此：比较窗口等 golden 8 项都入过表后才开，之后状态与初值无关。
覆盖（seed 1）：入表 61907 / 已在表 35050 / 同拍同页 10717 / 响应同页 8456 / 分区满 131252 / 发出 65669 / refill 51838 /
一次销多项 3814 / getGpa 14281 / rob_head 53126 / flush 时表非空 1916（任一类为 0 即判 FAILED）。

变异自检（scratchpad 沙箱，不进库；seed 1、initreg 0、40k 拍；基线 checks=239790 errors=0）：
M1 两 lane vpn 拼接对调 CAUGHT(75717) / M2 valididx[3]/[4] 接反 CAUGHT(29842) / M3 SIZE=16 CAUGHT(46523) /
M4 核：分区空项取最小下标 CAUGHT(7936) / M5 getGpa 输出悬空 CAUGHT(39965) / E1 hint_req_full 改不接（等价）errors=0。

复跑：`cd verif/ut/PTWFilterEntry_1 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 lane 内非正式试跑（diagnostic-full，不出证，commit 0f8a2684）

1. 关 vmucp：native SUCCEEDED，passing 388，unread 3 = matched_nc（inflight_counter[2:0]，按名配上）。
2. 开 vmucp（verif/fm_target_config/PTWFilterEntry_1.tcl）：native SUCCEEDED，passing **391**，unread 空。

### 1.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/PTWFilterEntry_1.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **391**（regs 347 + outs 44）；实测预计 **391**，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 / 黑盒 | 全 0 / 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

## 2. PTWNewFilter（golden 819 行 / 5 个 child 实例）

### 2.1 结构与子模块处置

- 可读核 `rtl/memblock/PTWNewFilter.sv`（xs_PTWNewFilter_core + golden 同名 wrapper），784 行，代码区 `_GEN_`/`_T_` = 0。
  分节：§1 flush 延迟（DelayN_1，2 拍）/ §2 PTW 响应打拍（载荷 RegEnable 无复位、valid 每表一份异步复位 RegNext，三份同值照抄）/
  §3 三张过滤表 / §4 3 路轮转仲裁（RRArbiterInit_12）/ §5 回 dtlb 的响应（载荷=打拍寄存器、vector 0/4/6）/
  §6 load hint 打拍（req 与 resp.valid RegNext、resp.bits RegEnable）/ §7 topdown。
- child 全部两侧白盒：PTWFilterEntry（PROVEN_DIRECT）、PTWFilterEntry_1（本 lane §1）、DelayN_1、RRArbiterInit_12（PROVEN_DIRECT）。无黑盒。
- FM「匹配前」钉点 `verif/ut/PTWNewFilter/fm_pins_pre.tcl`（gen_ptwnewfilter.py 生成，fail-closed，字面计数 10）：只钉三张表里的
  inflight_counter（load 4 + store 3 + prefetch 3 位）。依据（实测，不钉时诊断跑）：其余寄存器 FM 全部自己配上（unmatched 0），
  唯独这 10 位两侧都无读者、没有功能签名，落成两侧 unmatched unread，vmucp 证不到。

### 2.2 UT（verif/ut/PTWNewFilter，tb 由 gen_tb.py 生成；逐拍比全部 92 根输出；3 seed × 3 档 × 200k，串行，commit 0f8a2684）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=15590874 errors=0 PASS | checks=15590874 errors=0 PASS | (1017) checks=15590874 errors=0 PASS |
| 7  | checks=15596880 errors=0 PASS | checks=15596880 errors=0 PASS | (7017) checks=15596880 errors=0 PASS |
| 42 | checks=15592044 errors=0 PASS | checks=15592044 errors=0 PASS | (42017) checks=15592044 errors=0 PASS |

覆盖（seed 1，load/store/prefetch）：入表 76549/58841/58509、仲裁发出 39556/39258/39234、refill 59620/46519/46444、
getGpa 24475/23738/23989；两张以上表同时待发 197230、两张以上同拍 refill 47892、flush 时表非空 2168、hint replay_all 5479、
rob_head 85845（任一类为 0 即判 FAILED）。

变异自检（scratchpad 沙箱，不进库；seed 1、initreg 0、40k 拍；基线 checks=3110874 errors=0）：
M1 响应载荷去使能 CAUGHT(520820) / M2 hint.resp.bits 去使能 CAUGHT(29933) / M3 vector store/prefetch 对调 CAUGHT(18726) /
M4 flush 漏 hgatp.changed CAUGHT(56772) / M5 仲裁输入对调 CAUGHT(26309) / M6 topdown 漏 prefetch CAUGHT(1208) /
M7 tlb_resp.valid 只看 load CAUGHT(5433) / M8 hint.req.full 不打拍 CAUGHT(19189) / M9 store 表收错口 CAUGHT(41812) /
M10 表看到未打拍的 resp.valid CAUGHT(90880) / E1 store 表取 load 那份 resp.valid（等价）errors=0 /
**M11 resp_valid_q 异步复位改同步：UT 结构上看不见（复位期间不比）**，FM 侧实证：同沙箱 diagnostic-full → Verification FAILED，failing 3。

复跑：`cd verif/ut/PTWNewFilter && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 2.3 lane 内非正式试跑（diagnostic-full，不出证）

1. 关 vmucp、不钉（commit 0f8a2684）：native SUCCEEDED，passing 2014，unmatched compare 0，unread 10 = 两侧 unmatched unread（上述 inflight_counter）。
2. 钉 + 开 vmucp（工作树，钉点与 config 即本 commit 内容）：native SUCCEEDED，passing **2024**，unread 空，`PNF_PIN_END ok=10 bad=0`。

### 2.4 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/PTWNewFilter.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **2024**（regs 1684 + outs 340）；实测预计 **2024**，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 / 黑盒 | 全 0 / 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |
| 依赖 | PTWFilterEntry_1 须先本 lane 出证（green_child 闸） |

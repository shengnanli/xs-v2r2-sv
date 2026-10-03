# newifu-ptwfilter lane（agent/newifu-ptwfilter）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `65aee3df`（认领 commit，基于 main `3e77f50f`） |
| 工作树 | `/home/eda/xs-env/wt-newifu-ptwfilter`，分支 `agent/newifu-ptwfilter` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `FrontendTrigger` / `PredChecker`（叶子）→ `NewIFU`（本体）→ `PTWFilter` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify，无黑盒 |
| 生成器 | `scripts/gen_newifu_lane.py`（带 `--check`）：只生成 golden 同名 wrapper 与 `fm_pins_pre.tcl`；核全部手写 |

§0 冲突检查（2026-10-02）：codex outbox 最新 `codex_0205`（next-20 叶子，已完成）与全部 `codex/*`、`agent/*`
分支相对 main 的 rtl 改动里，没有 NewIFU / FrontendTrigger / PredChecker / PTWFilter。

## 1. FrontendTrigger（golden 2,195 行，0 child）

### 1.1 结构

- 可读核 `rtl/frontend/FrontendTrigger.sv`：§1 配置寄存器（4 个触发器按字段 SoA 存，全部异步复位）/
  §2 地址比较（高 45 位只比 pc[0] 与 pc[0]+1 两份，逐位置按 carry 二选一）/ §3 链检查 + 动作选择。
- 钉点 `verif/ut/FrontendTrigger/fm_pins_pre.tcl`：28 个 golden 寄存器 / 296 位，规则
  `tdataVec_<j>_<field> -> tdata_<field>_q[j]`、`triggerEnableVec_<j> -> enable_q[j]`。

### 1.2 UT（verif/ut/FrontendTrigger，3 seed × 3 档 × 200k）

跑在与本登记同一个 commit 的字节上；读数见文末「对账」（登记时只有重排版之前那版字节的读数：
9/9 档 checks=3199872 errors=0 cov_fail=0，seed×档 = {1,7,42} × {+0, +random, +<seed>017}）。

变异自检（scratchpad，不进库，各 30k 拍，seed 7 × random）：

| 变异 | 结果 | 说明 |
|---|---|---|
| M1 GE 去掉高位大于 | errors=57211 | 抓到 |
| M2 不按 carry 选高位结果 | errors=17936 | 抓到 |
| M3 链前驱命中条件恒真 | errors=16898 | 抓到 |
| M4 动作优先级对调 | errors=6432 | 抓到 |
| M8 忽略 select | errors=12643 | 抓到 |
| M5 timing_ok 恒真 | errors=0 | **等价变异**：canFire 里已有 `& ~chain[j]`，timing_ok 的 `~chain[j]` 项冗余，且 timing 恒 0 |
| M6 更新时 timing 写 1 | errors=0 | UT 看不见（同上，timing 不影响输出）；**由 FM 兜**：timing 寄存器是比较点，次态不同 |
| M7 enable_q 去掉复位 | errors=0 | UT 看不见（每拍都被输入覆盖，比较窗口在复位之后）；**由 FM 兜**：异步复位结构不同 |

### 1.3 跑前预测（★跑完不许改本节★）

| 项 | 预测 |
|---|---|
| 模型 passing | **360**（寄存器 296 位 + 输出 64 位），`docs/fm_predictions/FrontendTrigger.json` |
| constant_reg | **4**：4 个 `timing` 位（复位 0、更新时也写 0，时序上恒 0），预计 FM 折成常量、不产生比较点 |
| unread（vmucp 开，全部应被提升比较） | 关 vmucp 时应为 56 = `tdata2[63:50]` × 4；开 vmucp 后归 0 |
| 实测 passing 预测 | **356** = 360 − 4 |
| 其余 | failing 0 / unverified 0 / unmatched 0 / 无黑盒 / SUCCEEDED |

可能出错的地方：(1) FM 若不把 timing 判常量，则 passing = 360、constant_reg = 0（差额仍被指认）；
(2) 没做过任何 FM 试跑，钉点路径名（`u_core/tdata_tdata2_q_reg[j][b]`）按 Formality 对 unpacked 数组的
命名规则写的（另做过一次 20 行玩具模块的 `report_matched_points` 探针确认命名形式，不涉及任何目标）。

## 2. PredChecker（golden 1,475 行，0 child，无 reset 端口）

### 2.1 结构

- 可读核 `rtl/frontend/PredChecker.sv`：§1 stage1 漏跳检查与取指范围修正（组合）/ §2 流水寄存器
  （RegEnable(fire_in)，全部不复位）/ §3 stage2 目标检查与结果编码。
- 钉点：195 个 golden 寄存器 / 1799 位，规则 `xxxNext_<i> -> xxx_q[i]`。

### 2.2 UT（verif/ut/PredChecker）

同上，读数见「对账」（重排版之前那版字节：9/9 档 checks=19199232 errors=0 cov_fail=0）。
arm 条件：见过一次 fire_in 之后才比（寄存器不复位）。

变异自检（同上口径）：

| 变异 | 结果 |
|---|---|
| M1 `takenIdx > i` 改 `>=` | errors=46715 |
| M2 jalr 漏跳不排除 ret | errors=3184 |
| M3 截断掩码不含漏跳指令自身 | errors=19770 |
| M4 非指令起点的顺序目标按 +4 | errors=14827 |
| M5 fixedTarget 不看 jal 漏跳 | errors=6813 |
| M6 去掉 fire_in 使能 | errors=265683 |
| M8 targetFault 对 jalr 也查 | errors=237 |
| M9 fixedTaken 不排除 notCFI | errors=3018 |
| M7 faultType 里 jal/jalr 优先级对调 | errors=0，**等价变异**：两者按 brType 互斥 |

### 2.3 跑前预测

| 项 | 预测 |
|---|---|
| 模型 passing | **3495**（寄存器 1799 + 输出 1696） |
| constant_reg / unread | **0 / 0**：所有寄存器都有读者，没有恒定位 |
| 实测 passing 预测 | **3495** |
| 其余 | failing 0 / unverified 0 / unmatched 0 / 无黑盒 / 无 vmucp / SUCCEEDED |

## 3. NewIFU（golden 5,714 行 / 581 端口）

### 3.1 结构与子模块处置

- 可读核 `rtl/frontend/NewIFU.sv`：§0 冲刷/握手 / §1 f0 / §2 f1 / §3 f2 / §4 f3 / §5 MMIO 取指状态机 /
  §6 f3 valid、last half、入 IBuffer / §7 wb 写回 FTQ / §8 TopDown / §9 perf。
- golden 直接 child 21 实例 / 5 种，`docs/coverage_three_axis.tsv`：PreDecode / F3Predecoder / RVCExpander
  = `PROVEN_DIRECT`；PredChecker / FrontendTrigger 本 lane 签核（§1、§2）。处置 = **两侧白盒**：
  ref 读 golden 同名件，impl 读本仓重写件（重写核直接例化各 child 的可读核 `xs_*_core`）。无黑盒。
- 钉点 `verif/ut/NewIFU/fm_pins_pre.tcl`：748 个 golden 寄存器 / **6113 位** = NewIFU 顶层 4018 +
  predChecker 1799 + frontendTrigger 296；每个寄存器恰好命中一条规则、映射单射（生成器 fail-closed）。

### 3.2 UT（verif/ut/NewIFU）

受约束随机（引用 golden 内部状态配 ICache 响应 / ROB 提交 / 重定向，见 `gen.py` 文件头）。
读数见「对账」。登记时已有的读数（重排版之前那版字节）：seed 1 × 3 档、seed 7 × +0 各 200k，
checks≈8.4e7 errors=0 cov_fail=0。

### 3.3 跑前预测

| 项 | 预测 |
|---|---|
| 模型 passing | **9251**（闭包寄存器 6113 + 输出 3138），`docs/fm_predictions/NewIFU.json` |
| unread（关 vmucp 时） + 落在这些族里的 constant | **365** = f3_pd_wire brType/isCall/isRet 64 + f3_perf_info 死位 4 + f2_cut_ptr[6] 17 + f3_jump_offset[63:50] 224 + frontendTrigger tdata2[63:50] 56（依据见 `verif/fm_target_config/NewIFU.tcl`） |
| constant_reg | **9 ～ 25**：timing 4 + `{f2,f3,wb}_pc_lower_result_0[11]` 3（{1'b0, start[10:0]} 的进位位恒 0）+ `f2_cut_ptr_0[6:5]` 2，共 9 个把握大；另 `f2_cut_ptr_1..16[6]` 16 个取决于 FM 是否穿过加法器做常量传播 |
| 实测 passing 预测 | **9242**（constant_reg = 9）；下界 9226（constant_reg = 25） |
| 其余 | failing 0 / unverified 0 / unmatched 0 / 无黑盒 / SUCCEEDED |

### 3.4 明写可能出错的地方

1. 没做过任何 FM 试跑；Matching 是否顺利全靠钉点。child（predChecker / frontendTrigger）的层次名两侧不同
   （`predChecker/` vs `u_core/u_predChecker/`），已一并钉。
2. golden 的 `REG` / `wb_enable_REG`、`mmioFlushWb_valid_REG` / `mmio_redirect_REG`、`REG_1` / `REG_3`
   是三对值恒等的重复寄存器，已关 merge_dup，预期各自一个比较点。
3. PreDecode 的 `pd_0_valid`（恒 1）、`hasHalfValid_0/1`（恒 0/1）在 golden 里没有寄存器，
   重写核同样不建（`f3_pd_valid_q[15:1]`、`f3_hasHalfValid_q[15:2]`）；若建了会出现 impl 侧 unmatched。
4. MMIO 状态寄存器 4 位、状态 12..15 两侧都是"保持"；若 FM 对 enum 做了 don't-care 化简，可能出现失配。

## 4. PTWFilter（golden 2,565 行 / 150 端口；child DelayN_1 ×1）

### 4.1 结构与子模块处置

- 本配置下 PTWFilter 是 ITLB 用的老式 `PTWFilter`（Repeater.scala L441，Width=3 / Size=8 / FenceDelay=2），
  **不例化 PTWFilterEntry**（那是 PTWNewFilter 的 child，归 mmuleaf lane）；唯一 child 是 flush 延迟 `DelayN_1`
  （`docs/coverage_three_axis.tsv`：GOLDEN_REUSE / PROVEN_DIRECT，`rtl/common/DelayN_1.sv` + `xs_DelayN_core`），
  两侧白盒，无黑盒。
- 可读核 `rtl/mmu/PTWFilter.sv`：包内 `ptw_resp_hit`（PtwRespS2.hit 三种 s2xlate 的命中判据）/ §0 flush /
  §1 状态 / §2 回应侧 / §3 请求第 0 拍 / §4 第 1 拍去重入队 / §5 发 L2TLB / §6 队列更新 / §7 回 ITLB。
  L2TLB 回应打一拍的寄存器用一个 packed struct（`ptwResp_q`，字段名 = golden 后缀）。
- 钉点 `verif/ut/PTWFilter/fm_pins_pre.tcl`：顶层 95 个 golden 寄存器 / **759 位**（struct 字段的 FM 对象名形如
  `ptwResp_q_reg[s1_entry_tag][3]`，用 20 行玩具模块探针验过 set_user_match 能配上）；flush_delay 的 2 位交给
  FM 自动配对（DelayN_1 两侧结构不同名：golden REG/REG_1 vs 重写 u_core/g_chain.stage）。

### 4.2 UT（verif/ut/PTWFilter）

受约束随机（回应照 golden 队列项造 tag，见 `gen.py` 文件头）。读数见「对账」。
登记时已有的读数：seed 7 × +random 40k 拍 checks=2636106 errors=0（覆盖闸只差 flush_kills_resp 26<50，200k 拍够）。
注：issue_filtered 路径（要发的项被上一拍回应覆盖）在本激励下几乎到不了，由 FM 兜。

变异自检：见「对账」（登记时正在跑）。

### 4.3 跑前预测

| 项 | 预测 |
|---|---|
| 模型 passing | **1077**（闭包寄存器 761 = 顶层 759 + DelayN_1 2；输出 316），`docs/fm_predictions/PTWFilter.json` |
| constant_reg / unread | **0 / 0**：所有寄存器都有读者（ptwResp 全部字段直通输出；getGpa 经 PriorityMux 输出） |
| 实测 passing 预测 | **1077** |
| 其余 | failing 0 / unverified 0 / unmatched 0 / 无黑盒 / 无 vmucp / SUCCEEDED |

可能出错的地方：(1) 没做过 FM 试跑；(2) flush_delay 内部 2 位靠自动配对；(3) `ptw_resp_hit` 里 allStage 的
level = min(s1,s2) 与 n 的三种组合是最容易抄错的地方，UT 的 hit_allS1 / hit_napot 覆盖项专门盯它。

## 对账

（跑完追加）

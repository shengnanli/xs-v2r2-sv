# bpu-tables lane（agent/bpu-tables）—— 跑前登记

本文件在官方 FM（run_proof.sh）起跑之前提交对应分节；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `3cd47062`（main；worktree 由集成者预建，认领 `7694f580`） |
| 工作树 | `/home/eda/xs-env/wt-bpu-tables`，分支 `agent/bpu-tables` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标（自底向上） | 叶子 `MaxPeriodFibonacciLFSR` / `SCTable` `SCTable_1` `SCTable_2` `SCTable_3` / `RegionWays` → 预测器 `FauFTB` / `ITTage` / `Tage_SC` → 父级 `Composer` 重证 |
| 冲突检查 | codex outbox 最新 0207（不含本 lane 目标；0016 是 7 月 xs-signoff 旧仓的 SCTable 台账消息，与本轮重写无关）；全部 worktree 的 `*_claim.md`/`*_prereg.md` 只有本 lane 的 claim 提到这些名字；各 codex/agent 分支相对 main 的 rtl 改动无本 lane 目标 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |
| 生成器 | `scripts/gen_sctable.py`（SCTable 家族 wrapper，带 `--check`）、`scripts/gen_bpu_stagepc_pins.py`（预测器公共外壳 s2/s3 段 PC 钉点，带 `--check`）；各 UT 的 `gen.py`（tb，带 `--check`，基于 `scripts/dual_tb_lib.py`） |
| 新共享辅助件 | `rtl/common/xs_BpuStagePc.sv`（BasePredictor 公共外壳各级 PC，FauFTB/ITTage/Tage_SC 共用；不对应 golden 模块） |
| UT 档位 | 3 seed（1/7/42）× 3 档初值（`+vcs+initreg+0` / `+vcs+initreg+random` / `+vcs+initreg+<seed>017`）× 200k 拍，串行；复跑 `cd verif/ut/<UT> && make run SEED=<s> INITREG=<0|random|<s>017>` |

## 1. MaxPeriodFibonacciLFSR（golden 223 行 / 0 child）

### 1.1 结构
- `rtl/common/MaxPeriodFibonacciLFSR.sv`（77 行，代码区 `_GEN_`/`_T_` = 0）：参数化核 `xs_MaxPeriodFibonacciLFSR_core`（WIDTH / TAP_MASK / SEED）+ golden 同名 wrapper。
  15 位 Fibonacci 移位链，反馈 = state[13]^state[14]（抽头 {15,14}），异步复位到 seed 1。

### 1.2 UT（verif/ut/MaxPeriodFibonacciLFSR；逐拍比 15 根输出，激励 = 上电复位 + 每拍 1/5000 随机复位）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=2999880 errors=0 PASS | checks=2999880 errors=0 PASS | (1017) checks=2999880 errors=0 PASS |
| 7  | checks=2999880 errors=0 PASS | checks=2999880 errors=0 PASS | (7017) checks=2999880 errors=0 PASS |
| 42 | checks=2999880 errors=0 PASS | checks=2999880 errors=0 PASS | (42017) checks=2999880 errors=0 PASS |

覆盖（seed 1）：复位拍 47、回到 seed 态 48；15 个输出位都见过 0/1。
变异（scratchpad 沙箱，不进库；seed 1 / initreg 0 / 20k 拍；基线 checks=299880 errors=0）：
M1 抽头 13→12 CAUGHT(145220) / M2 seed 1→2 CAUGHT(145705) / M3 异步复位改同步 CAUGHT(18) / M4 输出位 0/1 对调 CAUGHT(19446)。

### 1.3 lane 内非正式试跑（diagnostic-full，不出证，commit 9c608511）
native SUCCEEDED，passing 30，failing 0，unmatched 0，unread 0。

### 1.4 跑前预测（★跑完不许改本节★，docs/fm_predictions/MaxPeriodFibonacciLFSR.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **30**（regs 15 + outs 15）；实测预计 30，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 / 黑盒 | 全 0 / 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / false / false |

## 2. SCTable / SCTable_1 / SCTable_2 / SCTable_3（golden 459 / 465 / 464 / 463 行）

### 2.1 结构与子模块处置
- 一个参数化核 + 4 个薄 wrapper（变体家族规矩）：`rtl/frontend/SCTable.sv`（432 行：package sctable_pkg + `xs_SCTable_core` + SCTable wrapper）、
  `SCTable_1/_2/_3.sv`（各 148 行，只有 wrapper），wrapper 区由 `scripts/gen_sctable.py` 生成（端口 fail-closed 认领、折叠历史位宽 = min(8,HIST_LEN) 断言、
  MBIST 流水名对 golden 核对）。代码区 `_GEN_`/`_T_` = 0。
- 4 档只差 HIST_LEN（0/4/10/16，对应 Parameters.scala SCHistLens）与 MBIST 流水名（MbistPipeSc / _1 / _2 / _3）。
- 核分节：§1 s0 行号/bank/读写冲突、§2 s1 选 bank + 按 pc[1] 换回逻辑分支 + 冲突清零、§3 update 物理路掩码 → 旁路优先取旧值 → 6 位有符号饱和 ±1 → 写 SRAM 与写旁路。
  ★照搬的怪癖★：bank 选择用哈希后的 idx[0]，分支槽换位用未哈希的 pc[1]（HIST_LEN>0 时两者不是同一位）。
- child：SRAMTemplate_68 ×2、WrBypass_33 ×2、MbistPipeSc_N ×1 —— `docs/coverage_three_axis.tsv` 全部 PROVEN_DIRECT ⇒ **两侧白盒**（ref golden，impl 重写件
  `rtl/common/SRAMTemplate_68.sv`+`xs_SRAMTemplate_core.sv`、`rtl/frontend/WrBypass_33.sv`+`WrBypass.sv`+`rtl/common/IndexableCAMTemplate.sv`+`xs_PlruReplacer.sv`、
  `rtl/dft/MbistPipeSc*.sv`+`xs_mbist_pipe_core.sv`）。SRAM 宏链 sram_array_1p128x24m6s1h0l1b_bp_sc / array_5 / MbistClockGateCell / ClockGate 两侧共读 golden；
  唯一黑盒 = 厂商叶子 `array_5_ext`（verif/vendor_boundary.tsv 已审定，两侧同读）。

### 2.2 UT（verif/ut/SCTable，四对同 tb；逐拍比全部 48 根输出 × 4 变体）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=4796616 errors=0 PASS | checks=4796616 errors=0 PASS | (1017) checks=4796616 errors=0 PASS |
| 7  | checks=4796580 errors=0 PASS | checks=4796580 errors=0 PASS | (7017) checks=4796580 errors=0 PASS |
| 42 | checks=4796502 errors=0 PASS | checks=4796502 errors=0 PASS | (42017) checks=4796502 errors=0 PASS |

比较窗口：SRAM 读出保持寄存器与 s1_* 不复位 → 等 golden 两个 bank 各完成过一次读再开比（armed_at ≈ 140）。
覆盖（seed 1，SCTable / _1 / _2 / _3）：冲突清零 74667/75141/74474/74786、旁路命中且有效（br0）70321/21735/20967/21302、
正饱和停住 11855/12602/12825/12864、负饱和停住 11857/12838/12845/12904、bank0 写 74757/62484/74523/77855、bank1 写 74255/87246/74493/71445；全部输出位见过 0/1。
变异（沙箱；seed 1 / initreg 0 / 30k 拍；基线 checks=716616 errors=0）：
M1 读出不按 pc[1] 换回 CAUGHT(112548) / M2 bank 选择用未哈希 pc[1] CAUGHT(84249) / M3 读写冲突不清零 CAUGHT(125020) / M4 旁路不看该路 valid CAUGHT(30660) /
M5 正饱和阈值错 CAUGHT(12845) / M6 折叠不异或 CAUGHT(126282) / M7 写路掩码方向反 CAUGHT(160238) / M8 写旁路用未哈希行号 CAUGHT(47042)。

### 2.3 lane 内非正式试跑（diagnostic-full，关 vmucp，不出证，commit acb4077c）
4 个变体同读数：native SUCCEEDED，passing 1058，failing 0，unmatched 0，unread 65 全部 matched_nc（按名配上）：
s1_pc 未读 49 位 + s1_idx[7:1] 7 位 + MBIST 流水 addrReg[7:0]/addrRdReg[7] 9 位（子模块内两侧对称）。
依据与六条证据见 `verif/fm_target_config/SCTable*.tcl`。

### 2.4 跑前预测（★跑完不许改本节★）

| 项 | SCTable | SCTable_1 | SCTable_2 | SCTable_3 |
|---|---|---|---|---|
| passing | 模型 **1123**，预计 1123 | 1123 / 1123 | 1123 / 1123 | 1123 / 1123 |
| failing / unverified / aborted / unread_nc | 0/0/0/0 | 同 | 同 | 同 |
| unmatched 六项 | 全 0 | 同 | 同 | 同 |
| 黑盒 | 仅 array_5_ext ×2（vendor） | 同 | 同 | 同 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false | 同 | 同 | 同 |

## 3. RegionWays（golden 740 行 / 0 child）

### 3.1 结构
- `rtl/frontend/RegionWays.sv`（206 行，`_GEN_`/`_T_` = 0）：golden 同名 wrapper + `xs_RegionWays_core`（16 项 {valid, region[29:0]} 结构体数组，
  §1 写口选项：命中 → 该项 / 未满 → 最小下标空项 / 满 → 16 路树形 PLRU、§2 读口按指针直读、§3 更新查找口（全相联 + 写旁路）、§4 写）。
  PLRU 用共享辅助件 `rtl/common/xs_PlruReplacer.sv`（未改一字节）。
- UT 抓到并修掉一个仿真敏感性 bug（写核时自己引入）：比较函数直接读模块级表、连续赋值不对表敏感，复位清表时输出不重算 —— 改成表作为实参传入。

### 3.2 UT（verif/ut/RegionWays；逐拍比全部 15 根输出）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=2999880 errors=0 PASS | checks=2999880 errors=0 PASS | (1017) checks=2999880 errors=0 PASS |
| 7  | checks=2999880 errors=0 PASS | checks=2999880 errors=0 PASS | (7017) checks=2999880 errors=0 PASS |
| 42 | checks=2999880 errors=0 PASS | checks=2999880 errors=0 PASS | (42017) checks=2999880 errors=0 PASS |

覆盖（seed 1）：写命中 61716 / 未满填空项 1805 / 满后 PLRU 替换 30136 / 更新口旁路 45364 / 更新口表内命中 158580。
变异（沙箱；seed 1 / initreg 0 / 40k 拍；基线 checks=599880 errors=0）：M1 空项取最大下标 CAUGHT(297415) / M2 更新口不走旁路指针 CAUGHT(2954) /
M3 命中时不 touch PLRU CAUGHT(281461) / M4 旁路不看 write_valid CAUGHT(9319) / M5 命中不回写 region（等价体检）errors=0 /
**M6 PLRU 状态不复位：UT 结构上看不见**（UT 双例化两侧同初值、复位后 PLRU 状态由后续 touch 决定的那部分两侧同步），归 FM 复位域。

### 3.3 lane 内非正式试跑（diagnostic-full，不出证，commit 73faf56b 前的工作树，RegionWays 字节同 73faf56b）
native SUCCEEDED，passing 680，failing 0，unmatched 0，unread 0（结构体数组 regions[k].valid/region 与 golden regions_k_valid/region 按名配上）。

### 3.4 跑前预测（★跑完不许改本节★）

| 项 | 预测 |
|---|---|
| passing | 模型 **680**（regs 511 + outs 169）；预计 680，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 / 黑盒 | 全 0 / 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / false / false |

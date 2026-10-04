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

## 3a. §1–§3 补记（跑前，未改上面任何数字）
- 首次官方 run_proof（钉 `09e35f69`）被可读性闸拒绝：SCTable 生成区标记名含 `_wrapper` 字样（C 类）、RegionWays 模块顺序 wrapper 在前（D 类）。
  修正提交 `1b420e20`（只动注释标记与模块先后，逻辑字节不变），官方证明钉在 `1b420e20`。
- 在 `1b420e20` 的字节上重跑 RegionWays / SCTable 的 UT 3×3，读数与 §2.2 / §3.2 逐格相同（errors=0）。

## 4. FauFTB（golden 6,885 行 / 32 个 FauFTBWay 子实例）

### 4.1 结构与子模块处置
- `rtl/frontend/FauFTB.sv`（741 行，`_GEN_`/`_T_` = 0）：package fauftb_pkg（完整预测结构体、fromFtbEntry 展开函数、32 路 PLRU 选/touch、2 位饱和）
  + `xs_FauFTB_core`（§0 公共外壳 PC / §1 S1 全相联命中 + Mux1H 按位或合成 / §2 meta / §3 u_s0 / §4 u_s1 写路选择与计数器 / §5 PLRU 两次 touch 叠加 / §6 perf）
  + golden 同名 wrapper。用 `frontend_common_pkg.sv` 里的 xs_ftb_pkg（FTB 条目类型、get_target），与共享辅助件 `rtl/common/xs_BpuStagePc.sv`。
- ★照搬的怪癖★：多路同时命中按位或合成（不是优先选择）；PLRU 同拍两次 touch 先叠"上拍预测命中"再叠"本拍写入"；u_bits_meta 存满 516 位只读 [0]；
  uftb_write_pc / s0_fire_next_cycle 只喂断言 / perf 探针（死寄存器照抄）。
- child：FauFTBWay ×32（PROVEN_DIRECT）⇒ 两侧白盒（impl 用 `rtl/frontend/FauFTBWay.sv`）。无黑盒。

### 4.2 UT（verif/ut/FauFTB；逐拍比全部 1669 位输出，在 `73faf56b` 的 RTL 字节上跑，FauFTB 相关 RTL 之后未改）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=19799208 errors=0 PASS | checks=19799208 errors=0 PASS | (1017) checks=19799208 errors=0 PASS |
| 7  | checks=19799208 errors=0 PASS | checks=19799208 errors=0 PASS | (7017) checks=19799208 errors=0 PASS |
| 42 | checks=19799208 errors=0 PASS | checks=19799208 errors=0 PASS | (42017) checks=19799208 errors=0 PASS |

覆盖（seed 1）：预测命中 66527 / 更新命中写回 100683 / 表满走 PLRU 替换 49435 / 计数器饱和停住 4666 / fall-through 非法 62170 / 同拍两次 touch 49866；
结构常量位（目标 bit0、meta[515:6]、perf[5:1]）按结构豁免，其余输出位都见过 0/1。
变异（沙箱；seed 1 / initreg 0 / 30k 拍；基线 checks=2969208 errors=0）：M2 方向取计数器低位 CAUGHT(38588) / M3 fall-through 上界差一 CAUGHT(3948) /
M4 槽 1 更新不看槽 0 CAUGHT(11344) / M5 两次 touch 丢预测那次 CAUGHT(373954) / M6 共享 tailSlot 目标按 20 位 CAUGHT(79136) / M8 计数器复位值 2→1 CAUGHT(192) /
M7 hit 不受 ubtb_enable 门控：30k 拍 errors=0（关使能的阶段没抽到），200k 拍 CAUGHT(39660) /
**M1 多命中按位或改后者覆盖：UT 结构上看不见**（写旁路保证运行时不会多命中），归 FM（状态空间里多命中可达，FM 逐点比）。

### 4.3 lane 内非正式试跑（diagnostic-full，不出证）
1. 关 vmucp、不钉（commit `73faf56b`）：native SUCCEEDED，passing 4694，failing 0，unmatched compare 0；unread = 566 matched_nc
   （u_bits_meta[515:1] 515 + uftb_write_pc 50 + s0_fire_next_cycle 1）+ 400(400) 两侧 unmatched unread（公共外壳 s2/s3 段 PC）。
2. 钉 400（`verif/ut/FauFTB/fm_pins_pre.tcl`，scripts/gen_bpu_stagepc_pins.py 生成，字面计数 400）+ 开 vmucp（verif/fm_target_config/FauFTB.tcl）：
   native SUCCEEDED，passing **5660**，unread 空，`BPU_STAGEPC_PINS: 400 / 400 pinned, 0 missed`。

### 4.4 跑前预测（★跑完不许改本节★，docs/fm_predictions/FauFTB.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **5660**（regs 3991 + outs 1669）；预计 5660，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 / 黑盒 | 全 0 / 无 |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

## 5. ITTage（golden 2,429 行 / child：ITTageTable ×5、RegionWays、MaxPeriodFibonacciLFSR）

### 5.1 结构与子模块处置
- `rtl/frontend/ITTage.sv`（1623 行，`_GEN_`/`_T_` = 0，带本文件导航）：package ittage_pkg（offset / update 口 / meta 结构体，8 位饱和、
  PriorityEncoder(全 0→7)、LowerMask）+ `xs_ITTage_core`（§0 公共外壳 PC / §1 S1 是否查表 / §2 S2 provider·alt 选择、目标拼接、分配候选 /
  §3 S3 打拍与 meta / §4 update 锁存 / §5 更新决策与 tick / §6 各表 update 口）+ golden 同名 wrapper（scripts/gen_bpu_wrappers.py 生成：
  端口表、7 个子实例（实例名同 golden）、透传赋值；每根子模块连线要么是 golden 原样接的顶层口，要么被规则认领，否则拒绝生成）。
- ★照搬的怪癖★：provider/alt 都不足时 first/second 取第 0 张表的数据（ParallelSelectTwo 归并树的结果）；分配 PriorityEncoder 全 0 时为 7；
  各表 update 口的 pc 取未锁存的 io.update.bits.pc；DontCare 字段（分配项 correct/oldCtr、alt 项 u）按 firtool 取值。
- child：ITTageTable/_1.._4（PROVEN_IN_CONE，重写件）、RegionWays / LFSR（本 lane）⇒ 两侧白盒。ITTageTable 的下一层两侧共读 golden；
  厂商叶子 array_6_ext 两侧黑盒（.v 只给 VCS）。
- 写核时修过两处 FM 可见问题：按表号变量下标索引 5 项数组触发 FMR_ELAB-147（改逐表比较选通）；各表 update 口寄存器原为结构体数组，
  改成按字段数组（钉点可写、Matching 不再超时）。

### 5.2 UT（verif/ut/ITTage；逐拍比全部输出 2728 位；在 `35936708` 的 RTL 字节上跑，之后 ITTage 相关 RTL 未改）
后两档初值用 initreg 配置文件（其余随机、厂商 SRAM 行为模型存储钉 0：表项 SRAM 无复位，两实例读"从没写过"的条目时随机值不同 ——
tb 先写后读契约；不钉时 seed 42 random 档开比第一拍 meta 目标位即不同）。

| seed | `+vcs+initreg+0` | random（配置文件） | `<seed>017`（配置文件） |
|---|---|---|---|
| 1  | checks=35656276 errors=0 PASS | checks=35656276 errors=0 PASS | (1017) checks=35656276 errors=0 PASS |
| 7  | checks=35656276 errors=0 PASS | checks=35656276 errors=0 PASS | (7017) checks=35656276 errors=0 PASS |
| 42 | checks=35656276 errors=0 PASS | checks=35656276 errors=0 PASS | (42017) checks=35656276 errors=0 PASS |

比较窗口：前 3000 拍只做不触发表更新的 update，把按各自有效位锁存的 updateMeta_* 灌成确定值；之后等四份 s2_fire 都见过再开比（armed_at=3004）。
覆盖（seed 1）：provider 命中 23805 / alt 命中 22558 / 用 alt 目标 7709 / 区域表命中 95774 / 分配 8725 / 写 RegionWays 8471 / reset_u 33 /
更新 provider 37111 / 更新 alt 2368；结构常量位（meta 高 334 位、alt 表号最高位、pred_cycle bit16+）按结构豁免，其余输出位都见过 0/1。
变异（沙箱；seed 1 / initreg 0 / 40k 拍；基线 checks=6696276 errors=0）：M1 provider 取最短命中 CAUGHT(45175) / M2 不自信也不用 alt CAUGHT(12484) /
M3 忽略 usePCRegion CAUGHT(31168) / M4 tick 方向反 CAUGHT(708) / M5 表更新 pc 用锁存那份 CAUGHT(69657) / M6 分配不用 LFSR CAUGHT(11735) /
M7 alt 项也更新 u CAUGHT(698) / M8 漏 ftbCloseReq CAUGHT(13362)。

### 5.3 lane 内非正式试跑（diagnostic-full，不出证）
1. 不钉（commit `b3760421`）：Matching 30 分钟未结束，按后台时限停掉（未出数）。
2. 钉本层全部 3301 位（`verif/ut/ITTage/fm_pins_pre.tcl`）、关 vmucp（commit `35936708`，array_6_ext 当时两侧读成白盒）：native SUCCEEDED，passing 84846，
   failing 0，unmatched 0，unread 2172 全部 matched_nc（各表 update 口 ghist/pc 高位、update_ghist_r / update_r_pc 未读位、公共外壳 PC 未读位、子模块 MBIST 地址寄存器等）。
3. array_6_ext 改回两侧黑盒 + 开 vmucp（commit `cee28122`）：native SUCCEEDED，passing **10426**，unread 空，`BPU_PINS: 3301 / 3301 pinned`。

### 5.4 跑前预测（★跑完不许改本节★，docs/fm_predictions/ITTage.json）

| 项 | 预测 |
|---|---|
| passing | 模型 **10426**（regs 6402 + outs 2728，另含黑盒引脚）；预计 10426，差 0 |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 / 黑盒 | 全 0 / 仅厂商叶子 array_6_ext（vendor） |
| mode / verdict / vmucp / merge_dup | signoff-strict / SUCCEEDED / true / false |

## 6. Tage_SC（golden 7,767 行 / child：TageTable ×4、TageBTable、MbistPipeTage、SCTable ×4、MaxPeriodFibonacciLFSR ×2）

### 6.1 结构与子模块处置
- `rtl/frontend/Tage_SC.sv`（2517 行，`_GEN_`/`_T_` = 0，带本文件导航）：package tage_sc_pkg（resp / 各表 update 口 / TageMeta 结构体，
  4·5 位饱和、provider 居中值、SC 居中和 sc_sum4、S2 与更新两版 aboveThreshold、LowerMask、PriorityEncoder）+ `xs_Tage_SC_core`
  （§0 公共外壳 / §1 S1 provider·alt·S1 方向·SC 和 / §2 S2 打拍与 tage_enable / §3 SC S2 推翻 / §4 S3 与 meta / §5 update 锁存 /
  §6 TAGE 更新·useAltOnNa·分配·tick / §7 SC 阈值与 SC 更新 / §8 各表 update 口 / §9 perf）+ golden 同名 wrapper（gen_bpu_wrappers.py 生成，
  含 MBIST 子链 childBd_* 直连网的声明，名字与位宽照 golden）。
- ★perf 初值（bug-for-bug，未加复位）★：s2_provideds / s2_providers / s2_providerResps 等只在 s1_fire 时写、无复位，与 golden 一致；
  UT 的比较窗口晚于它们首次写入（见 6.2）。
- ★照搬的怪癖★：provider 都不命中时取第 0 张表；S2/S3 方向输出 = enable & 预测（golden 的 resp_in 里没有这一路）；tage_enable / sc_enable
  打拍寄存器每槽一份；各表 update 口 pc 取未锁存的 io.update.bits.pc；DontCare 字段按 firtool 取值；scTables 4 张同一份更新掩码。
- child：TageTable*（PROVEN_DIRECT）、TageBTable（PROVEN_IN_CONE）、MbistPipeTage（PROVEN_DIRECT）、SCTable* / LFSR（本 lane）⇒ 两侧白盒（impl 重写件）。
  TageTable/TageBTable 的下一层两侧共读 golden，唯 WrBypass 与 WrBypass_33 同住 rtl/frontend/WrBypass.sv，impl 只能有一份定义，故用重写件（PROVEN_DIRECT）。
  厂商叶子 array_2/3/4/5_ext 两侧黑盒。
- 写核时修过的 FM 可见问题：always_ff 里 automatic 临时量被 FM 推成 impl-only 寄存器（new_ctr_reg，改到 always_comb）；各表 update 口 pc/ghist
  从结构体拆成独立数组（钉点可写）。

### 6.2 UT（verif/ut/Tage_SC；逐拍比全部输出；在 `35936708` 的 RTL 字节上跑，之后 Tage_SC 相关 RTL 未改）
后两档初值同 ITTage：initreg 配置文件，厂商 SRAM 行为模型（array_2/3/4/5_ext）存储钉 0。

| seed | `+vcs+initreg+0` | random（配置文件） | `<seed>017`（配置文件） |
|---|---|---|---|
| 1  | checks=6500835 errors=0 PASS | checks=6500835 errors=0 PASS | (1017) checks=6500835 errors=0 PASS |
| 7  | checks=6500835 errors=0 PASS | checks=6500835 errors=0 PASS | (7017) checks=6500835 errors=0 PASS |
| 42 | checks=6500835 errors=0 PASS | checks=6500835 errors=0 PASS | (42017) checks=6500835 errors=0 PASS |

比较窗口：前 3000 拍只做"槽有效但 strong_bias=1"的 update（不触发任何表更新）把 updateMeta_* 灌成确定值；之后等四份 s1_fire 与 s2_fire 都见过
（覆盖 s2_provideds 等 perf 相关无复位寄存器的首次写入）再开比（armed_at=3005）。
覆盖（seed 1）：provider 命中 72502 / 不自信用 alt 26102 / useAltOnNa 计数器更新 12277 / 分配 27617 / tick 涨满 reset_u 204 / SC 推翻 TAGE 66150 /
SC 更新 45703 / 基础表更新 54329；结构常量位（meta 高 372 位、pred_cycle bit16+、perf 高 4 位）按结构豁免。
变异（沙箱；seed 1 / initreg 0 / 40k 拍；基线 checks=1220835 errors=0）：M1 provider 取最短命中 CAUGHT(119178) / M2 不自信也不用 alt CAUGHT(53214) /
M5 useAltOnNa 复位值 8→7 CAUGHT(5670) / M8 分配不用 LFSR CAUGHT(32609) / M9 uMask 不看 altDiffers CAUGHT(5914) /
M6 阈值调整上界差一：40k 拍 errors=0，200k 拍 CAUGHT(1911)。
**UT 结构上看不见、归 FM 的三个**：M3 S2 过阈值不看总和符号（sum>thr-pvdr 已蕴含 sum+pvdr>0，只在 9 位回绕时不同）/
M4 tick 负饱和判据差一（ctr+dist≡127 不变式下等价，FM 逐寄存器比次态函数可见）/ M7 基础表 taken 不门控（只改 mask=0 那一槽的 takens 寄存器，
TageBTable 不读，FM 比该寄存器可见）。

### 6.3 lane 内非正式试跑（diagnostic-full，不出证）
1. 不钉、关 vmucp（commit `92c0dfbf`）：native SUCCEEDED，passing 13146，failing 0，unmatched compare 0；unread = 420 matched_nc +
   2738(2556) unmatched unread（含 impl-only 的 new_ctr_reg 10 位 —— 即上面修掉的 always_ff 临时量）。
2. 钉 2843 位（`verif/ut/Tage_SC/fm_pins_pre.tcl`：公共外壳 s1/s2/s3 PC、modified_reset、各表 update 口 pc/ghist、bt pc）+ 开 vmucp（commit `35936708`）：
   native SUCCEEDED，passing **16112**，failing 0，unmatched 0，unread = 192 条 **仅 ref**：TageTable 子模块 s1_unhashed_idx[48:1] × 4
   （TageTable 自身签核即 PASS_DEAD_REF 的同一死因）→ `verif/dead_ref/Tage_SC.json` 逐条精确枚举；constant_reg 4（两侧 s2_scTableSums 的 bit0：
   4 个奇数之和恒为偶数，FM 判常量不比）。

### 6.4 跑前预测（★跑完不许改本节★，docs/fm_predictions/Tage_SC.json）

| 项 | 预测 |
|---|---|
| passing | 模型 16308（regs 14454 + outs 678 + 黑盒引脚）；预计 **16112**，差 196 = dead_ref unread 192 + constant_reg 4（逐项指认） |
| failing / unverified / aborted | 0 / 0 / 0 |
| unread | 192（全部 ref 侧，= verif/dead_ref/Tage_SC.json） |
| unmatched compare / 黑盒 | 0 / 仅厂商叶子 array_2/3/4/5_ext |
| mode / verdict / vmucp / merge_dup | signoff-strict / **PASS_DEAD_REF** / true / false |

## 6a. §6 补记（跑前，未改上面任何数字）
- §6 的预测登记之后、官方证明之前，Tage_SC 又改了一处（commit `312a5d35`）：核输出 `sc_upd_ghist` 的下标范围由 [0:3] 改 [1:3]
  （第 0 张 SC 表没有 ghist 口，原 [0] 是 256 位无驱动网，FM 报 FM-399 undriven；无扇出，不改任何比对点）。
  官方证明钉在 `312a5d35`；UT 3×3 在 `312a5d35` 字节上重跑，读数与 §6.2 逐格相同（checks=6500835 errors=0 ×9）。

## 7. 集成者追加：ITTageTable / _1 / _2 / _3 / _4、TageBTable（main 上已有重写件、但无有效 receipt）

### 7.1 现状与处置
- 重写件沿用：`rtl/frontend/ITTageTable.sv`（683 行，核 xs_ITTageTable_core + xs_MbistPipeIttage_core + ITTageTable wrapper）与
  `ITTageTable_1..4.sv`（薄 wrapper）、`rtl/frontend/TageBTable.sv`（569 行）；代码区 `_GEN_`/`_T_` = 0；RTL 未改一字节。
- golden 行数：ITTageTable 336 / _1 333 / _2 380 / _3 379 / _4 383 / TageBTable 396。
- 原 UT（scripts/gen_zj_ut.py 全随机端口 tb，只跑 initreg 0）从复位后第一拍就比，random 初值档开比第 5 拍即分叉（读出数据来自不复位的
  SRAM 读出保持寄存器与表项 SRAM —— tb 违反先写后读契约），换成 `verif/ut/ITTageTable/gen_family_tb.py`（dual_tb_lib，带 `--check`，
  一次生成六个 tb）：比较窗口 = 首次读握手后 3 拍；随机初值档用 initreg 配置文件把厂商叶子与 golden SRAM 包装链（两侧同一份 golden 模块）的存储 / 读出保持寄存器钉 0。
- FM 处置调整：TageBTable 由 assembly 改 signoff-strict；ITTageTable 家族的厂商叶子 array_6_ext 由"两侧读成白盒"改回审定的两侧黑盒；
  六个都关 merge_dup（passing 模型严格适用）。子模块（Folded/Splitted SRAM、WrBypass_32/41/43 等）照旧两侧同源 golden；既有钉点（fm_pins.tcl）与 vmucp 依据不变。

### 7.2 UT（在 `34883f55` 的字节上跑；3 seed × 3 档 × 200k，串行）

| 目标 | seed 1（0 / random / 1017） | seed 7（0 / random / 7017） | seed 42（0 / random / 42017） |
|---|---|---|---|
| ITTageTable   | checks=1794663 errors=0 ×3 | checks=1790307 errors=0 ×3 | checks=1798713 errors=0 ×3 |
| ITTageTable_1 | checks=1794663 errors=0 ×3 | checks=1790307 errors=0 ×3 | checks=1798713 errors=0 ×3 |
| ITTageTable_2 | checks=1790073 errors=0 ×3 | checks=1793133 errors=0 ×3 | checks=1798704 errors=0 ×3 |
| ITTageTable_3 | checks=1790073 errors=0 ×3 | checks=1793133 errors=0 ×3 | checks=1798704 errors=0 ×3 |
| ITTageTable_4 | checks=1790073 errors=0 ×3 | checks=1793133 errors=0 ×3 | checks=1798704 errors=0 ×3 |
| TageBTable    | checks=1591712 errors=0 ×3 | checks=1591712 errors=0 ×3 | checks=1591712 errors=0 ×3 |

覆盖（seed 1，initreg 0）：ITTageTable 读握手 98384 / 读命中 42843 / 分配写 49484 / 正确更新 25193 / reset_u 780；ITTageTable_2 99419 / 31614 / 49758 / 25002 / 760；
TageBTable 读握手 97998 / 读有效 111895 / 更新 149106；全部输出位都见过 0/1。
变异（沙箱；seed 1 / initreg 0 / 40k 拍）：ITTageTable_2（基线 350073/0）M1 分配置弱态 2→1 CAUGHT(17704) / M2 旧 ctr 不看写旁路 CAUGHT(4125) /
M3 更新 tag 的 alt 折叠不左移 CAUGHT(93) / M4 清 u 期间写 u 不屏蔽 CAUGHT(7811)；TageBTable（基线 311712/0）M1 冲突不作废 CAUGHT(17259) /
M2 旧值不看写旁路 CAUGHT(20894) / M3 写路掩码不换物理 way CAUGHT(12845)。

### 7.3 lane 内非正式试跑（diagnostic-full，不出证，commit `441642ab` 之前的工作树 = 本节 Makefile）
merge_dup=false：ITTageTable 682 / _1 682 / _2 1014 / _3 1014 / _4 1014 / TageBTable 396，全部 native SUCCEEDED，failing 0，unmatched 0，unread 空，与模型逐个相等。

### 7.4 跑前预测（★跑完不许改本节★，docs/fm_predictions/*.json）

| 目标 | passing（模型 = 预计） | 其余 |
|---|---|---|
| ITTageTable | 682 | failing / unverified / aborted / unread 全 0；unmatched 全 0；黑盒仅 array_6_ext；signoff-strict / SUCCEEDED / vmucp true / merge_dup false |
| ITTageTable_1 | 682 | 同上 |
| ITTageTable_2 | 1014 | 同上 |
| ITTageTable_3 | 1014 | 同上 |
| ITTageTable_4 | 1014 | 同上 |
| TageBTable | 396 | 同上（黑盒仅 array_4_ext） |

# 对账（跑完追加；上面各节未改一字）

| 目标 | proof commit | 证据目录 | 预测 | 实测 passing | 差 | failing/unverified/aborted/unread | unmatched | 黑盒 | verdict | receipt sha256 |
|---|---|---|---|---|---|---|---|---|---|---|
| MaxPeriodFibonacciLFSR | `1b420e20` | evidence/1b420e2033a9/MaxPeriodFibonacciLFSR | 30 | 30 | 0 | 0/0/0/0 | 全 0 | 无 | SUCCEEDED | `5f7909bf254ee8a3dd7e3259ab5647a926e6e783c9d2feb7672df1f6bbd8fb99` |
| RegionWays | `1b420e20` | evidence/1b420e2033a9/RegionWays | 680 | 680 | 0 | 0/0/0/0 | 全 0 | 无 | SUCCEEDED | `efe8e7dcb56d128b8a17c63fb917ae9d98e2e1b8e329106bf93e8f1291426aec` |
| SCTable | `1b420e20` | evidence/1b420e2033a9/SCTable | 1123 | 1123 | 0 | 0/0/0/0 | 全 0 | array_5_ext ×2 | SUCCEEDED | `9f87b5db8c88f47d3205aa11f2c2dfcc7feb300d03a7c2bbb8ff9cec270ff417` |
| SCTable_1 | `1b420e20` | evidence/1b420e2033a9/SCTable_1 | 1123 | 1123 | 0 | 0/0/0/0 | 全 0 | array_5_ext ×2 | SUCCEEDED | `6b22c0738b4d99a4155059e59ca6020569fbc27656bdb0dbca8a68f9944426b6` |
| SCTable_2 | `1b420e20` | evidence/1b420e2033a9/SCTable_2 | 1123 | 1123 | 0 | 0/0/0/0 | 全 0 | array_5_ext ×2 | SUCCEEDED | `a46666b6890e54784b7ce92b8999658108f2c8425011a5cbde8e999652c5e3e1` |
| SCTable_3 | `1b420e20` | evidence/1b420e2033a9/SCTable_3 | 1123 | 1123 | 0 | 0/0/0/0 | 全 0 | array_5_ext ×2 | SUCCEEDED | `f19a86bf5d638b899da9399c0d1057ab6cbd79251214e96c4649a92e44282b8a` |
| FauFTB | `cee28122` | evidence/cee2812229bf/FauFTB | 5660 | 5660 | 0 | 0/0/0/0 | 全 0（钉点 400/400） | 无 | SUCCEEDED | `6ebcd9009708ed7dfef957a6ff840b24f1bdec1dbc8045246dbefa67dff83ed6` |
| ITTage | `68bffe7f` | evidence/68bffe7f2938/ITTage | 10426 | 10426 | 0 | 0/0/0/0 | 全 0（钉点 3301/3301） | array_6_ext | SUCCEEDED | `7124f2523d40ae7390f837eda0f1a2005619daca974fe14e5db37667395d9562` |
| Tage_SC | `312a5d35` | evidence/312a5d3510fb/Tage_SC | 16112（模型 16308） | 16112 | 196 = constant_reg 4 + unread 192 | 0/0/0/192（全 ref，= dead_ref 声明） | 全 0（钉点 2843/2843） | array_2/3/4/5_ext | PASS_DEAD_REF | `a09636ef9b92acc7e6727c186aca3e773dad174f57df7b4894f99a57c38e60ee` |
| ITTageTable | `c6573076` | evidence/c6573076c5ba/ITTageTable | 682 | 682 | 0 | 0/0/0/0 | 全 0 | array_6_ext | SUCCEEDED | `c9d11edd613e120d1b26a134af4808b11973e47e7e19297c8e8f6bdf3281bf4d` |
| ITTageTable_1 | `c6573076` | evidence/c6573076c5ba/ITTageTable_1 | 682 | 682 | 0 | 0/0/0/0 | 全 0 | array_6_ext | SUCCEEDED | `b5076cf84d2117a05d1e4cca0311676f794a7c66c1d9d5683769d461acd7deb9` |
| ITTageTable_2 | `c6573076` | evidence/c6573076c5ba/ITTageTable_2 | 1014 | 1014 | 0 | 0/0/0/0 | 全 0 | array_6_ext | SUCCEEDED | `ba7ff2d3b63602874ec5d152793ffe9fb524b4ba5bb318c11d36cfe8c0c78f47` |
| ITTageTable_3 | `c6573076` | evidence/c6573076c5ba/ITTageTable_3 | 1014 | 1014 | 0 | 0/0/0/0 | 全 0 | array_6_ext | SUCCEEDED | `13955db1f8024bf33c1ce8df9784544eff3a7b3f643c430b45ebc75f401bb8cc` |
| ITTageTable_4 | `c6573076` | evidence/c6573076c5ba/ITTageTable_4 | 1014 | 1014 | 0 | 0/0/0/0 | 全 0 | array_6_ext | SUCCEEDED | `b62fd58065c0d54f26f11aa70b090f953f8fb4283b1b3263d0b24ec890b0f2c6` |
| TageBTable | `c6573076` | evidence/c6573076c5ba/TageBTable | 396 | 396 | 0 | 0/0/0/0 | 全 0 | array_4_ext | SUCCEEDED | `e30d79abc5840e9e8c884d0079cf8a388b09b31b29b920be79f9965036c90411` |

全部 mode = signoff-strict、allowlist 0、dont_verify 无、elab147 无；merge_dup=false；vmucp：SCTable×4 / FauFTB / ITTage / Tage_SC / ITTageTable×5 / TageBTable 为 true（依据见 verif/fm_target_config/<T>.tcl），LFSR / RegionWays 为 false。
`python3 scripts/fm_predict.py check <T>` 全部「对上」（Tage_SC 为「差额被指认：constant_reg 4 + unread 192」）；`python3 scripts/check_lane_receipts.py /home/eda/xs-env/wt-bpu-tables` rc=0。
复跑：`PROOF_COMMIT=<proof commit> bash scripts/run_proof.sh <UT 目录> <T> < /dev/null`（UT 目录：LFSR→MaxPeriodFibonacciLFSR，SCTable_* → SCTable，ITTageTable_k → ITTageTable_k，其余同名）。

## 8. 跑前补记：SCTable 家族 / Tage_SC 重证（commit `fa804162`，上面各节未改一字）
- 全仓 package 作用域闸（scripts/check_pkg_scope.py）报 CROSS_FILE_PACKAGE：sctable_pkg 定义在 SCTable.sv、被 SCTable_1/_2/_3.sv 引用。
  按 CONVENTIONS「独立包文件」例外移到 `rtl/frontend/sctable_pkg.sv`（包内容逐字不变，只是换文件）；SCTable_1/_2/_3 的生成头注释同步改。
- 这让 SCTable×4 与 Tage_SC（以及 Composer）的 impl 闭包字节变化，§对账里它们的 receipt（`1b420e20` / `312a5d35`）随之 STALE。
  在 `fa804162` 上重跑 UT 3×3 与官方证明；预测不变（SCTable×4：1123；Tage_SC：16112 / PASS_DEAD_REF，差 196 = constant_reg 4 + dead_ref 192）。

## 9. Composer 重证（父级；impl 侧三个预测器子树换成重写件）

### 9.1 处置
- `rtl/frontend/Composer.sv` 未改一字节。改的是证明配置（verif/ut/Composer）：
  · FauFTB / Tage_SC / ITTage 及其整棵已签子树（37 个 golden 文件）由"两侧同源 golden"改为两侧白盒（ref golden、impl 重写件 RTL_SRCS）；
    FTB / RAS / DelayN 与 TageTable·ITTageTable·TageBTable 的下一层照旧两侧同源 golden；
  · 厂商叶子 array_1..6_ext 改回审定的两侧黑盒（之前读成白盒；换重写子树后叶子存储阵列在父级规模下配不上，诊断跑 8192 位 unmatched）；
  · 关 merge_dup（passing 模型严格适用）；
  · 钉点：父级原有 601 位（Composer 本层影子 PC）不动；新增 GENERATED(bpu-child-pins) 区 23083 位 = 三个子预测器的规则钉点 +
    子模块自证时 FM 自己给出的寄存器配对（`verif/ut/Composer/child_pairs/*.tsv`，scripts/extract_fm_matched_pairs.py 从与 receipt 同字节的
    子模块 FM 跑的 matched.rpt 抽出）。不加这批时首次诊断跑 18136 个 unmatched compare point（WrBypass CAM、FauFTB 32 路等对称结构签名配不全）；
  · dead_ref：`verif/dead_ref/Composer.json`，192 条 = tage 子树 4 张 TageTable 的 s1_unhashed_idx[48:1]（与 TageTable / Tage_SC 同一死因）；
  · vmucp 依据沿用 verif/fm_target_config/Composer.tcl（未改）。
- UT（verif/ut/Composer）：加 initreg 三档（0 / random / <seed>017；后两档 SRAM 叶子与 golden SRAM 包装链读出保持寄存器钉 0，+warmup=4000）。
  原因：换成重写子树后，未初始化存储读出的 X 在两侧以不同的乐观/悲观方式传播（seed 1 第 5217 拍 s3 br_taken_mask golden=0 / 重写=X），X 不是硬件取值。
  tb 生成器 tools/predictor_composer/gen_ut.py 产物与仓内 tb.sv 已不一致（仓内 tb 早于本 lane 已手改），本 lane 只在仓内 tb.sv 加 +warmup 两处。

### 9.2 UT（在 `05394ca2` 字节上跑，Composer 相关 RTL 之后未改；3 seed × 3 档 × 200k）
| seed | initreg 0 | random | <seed>017 |
|---|---|---|---|
| 1  | checks=58600000 errors=0 hier_errors=0 | checks=57428000 errors=0 | checks=57428000 errors=0 |
| 7  | checks=58600000 errors=0 | checks=57428000 errors=0 | checks=57428000 errors=0 |
| 42 | checks=58600000 errors=0 | checks=57428000 errors=0 | checks=57428000 errors=0 |
（随机档少的 1172000 次 = 前 4000 拍 warmup 不比。）

### 9.3 lane 内非正式试跑（diagnostic-full）
1. 只有规则钉点（commit 174dea29）：native SUCCEEDED 但 18136(18136) unmatched compare point（停掉）。
2. 并入 FM 配对钉点 + 叶子黑盒（commit c3c9307d，merge_dup 默认 true）：SUCCEEDED，passing 41149，failing 0，unmatched 0，unread 192（全 ref），19 分钟。
3. 再关 merge_dup：SUCCEEDED，passing **42060**，unread 192（全 ref），constant_reg 664。

### 9.4 跑前预测（★跑完不许改本节★）
| 项 | 预测 |
|---|---|
| passing | 模型 42916；预计 **42060**，差 856 = constant_reg 664 + dead_ref unread 192 |
| failing / unverified / aborted | 0 / 0 / 0 |
| unread | 192（全 ref，= verif/dead_ref/Composer.json） |
| unmatched compare / 黑盒 | 0 / 仅厂商叶子 array_1..6_ext |
| mode / verdict / vmucp / merge_dup | signoff-strict / PASS_DEAD_REF / true / false |

# 对账（续）：§8 重证与 §9 Composer
| 目标 | proof commit | 证据目录 | 预测 | 实测 passing | 差 | unread | verdict | receipt sha256 |
|---|---|---|---|---|---|---|---|---|
| SCTable | `05394ca2` | evidence/05394ca211f8/SCTable | 1123 | 1123 | 0 | 0 | SUCCEEDED | `b3326f71418cfe02ff8aaecd73d05f9f9f4dc05ec6b8f496ebdee9afae76bbf5` |
| SCTable_1 | `05394ca2` | evidence/05394ca211f8/SCTable_1 | 1123 | 1123 | 0 | 0 | SUCCEEDED | `052044d15511c32d3be2085fd3423c70101083d985d5dcc86fa994607b4bd2c1` |
| SCTable_2 | `05394ca2` | evidence/05394ca211f8/SCTable_2 | 1123 | 1123 | 0 | 0 | SUCCEEDED | `e8315a67d2b67117aa7b6a60e56b30aecffdce82a90c7d18efa0f9fdde24d131` |
| SCTable_3 | `05394ca2` | evidence/05394ca211f8/SCTable_3 | 1123 | 1123 | 0 | 0 | SUCCEEDED | `8b6eeed4a24d774fee365632bec58db7c04b08e732029d8d0028f7cfe69bda20` |
| Tage_SC | `05394ca2` | evidence/05394ca211f8/Tage_SC | 16112 | 16112 | 0（对模型差 196 = constant 4 + unread 192） | 192 ref | PASS_DEAD_REF | `5865de8a9fa0e5dfb9aff7d19aefa927086f0a895ecf46e9ffd6bcbbdfd1e8c5` |
| Composer | `9cc9c9c7` | evidence/9cc9c9c74aac/Composer | 42060 | 42060 | 0（对模型差 856 = constant 664 + unread 192） | 192 ref | PASS_DEAD_REF | `4e84dff35aa0c7be8cd4bdb2eefff6e81a5d8fa2843cd8224ef6b0bbd21f1118` |

上表 SCTable×4 / Tage_SC 取代前一张对账表里 `1b420e20` / `312a5d35` 那几份（sctable_pkg 搬文件后 STALE）。
复跑：`PROOF_COMMIT=9cc9c9c74 bash scripts/run_proof.sh Composer Composer < /dev/null`。

## 10. 钉点静默落空修正与重证（2026-10-04，集成者报；merge main `cdb0e122` 之后）

### 10.1 问题（集成者发现，lane 自查确认）
- ITTage receipt（evidence/68bffe7f2938/ITTage）的 fm.log 有 250 行行首 `Error: Unknown name`：钉点里
  `u_core/upd_tgt_off_q_reg[i][5+位]` / `upd_old_off_q_reg[i][5+位]`（ittage_offset_t 结构体字段按打平位号写）FM 不认，
  FM 实际名是 `upd_tgt_off_q_reg[i]\[offset][位]` / `\[pointer][位]` / `\[usePCRegion]`。
- 钉点模板用 `catch` 计数，而 set_user_match 遇坏名不抛异常只返回 0（CONVENTIONS 已有此条，我写生成器时没照做），于是 3301 次里实生效 3051、
  脚本照样打印 3301/3301。FM 靠签名自己把这 250 位配上了，结论仍 SUCCEEDED，但钉点自证失效。
- 自查其余三份同源钉点（FauFTB / Tage_SC / Composer 的 receipt）：fm.log 行首 Error 均为 0（Composer 子实例区用的是 FM 报告里的原名）。
  但三份模板同样是 catch 计数（Composer 本层 601 位那段手写区也是），一并改。

### 10.2 修法
- `scripts/gen_bpu_stagepc_pins.py`：结构体字段寄存器按 FM 实际名生成；运行期按 set_user_match **返回值**计数（`catch` 只兜底真异常），
  成功数必须等于字面总数否则 error。重新生成四份钉点文件（ITTage 250 行名字变化 + 四份计数模板）。
- `verif/ut/Composer/fm_pins_pre.tcl` 手写区（本层 601 位）同样改为返回值计数；`check_pin_bijection.py` 601↔601 双射不变。
- RTL 未改一字节；UT 不受影响（钉点只进 FM）。

### 10.3 跑前预测（★跑完不许改本节★）
| 目标 | passing | verdict | 钉点打印 | fm.log 行首 Error / Unknown name |
|---|---|---|---|---|
| FauFTB | 5660 | SUCCEEDED | BPU_PINS 400 / 400 | 0 / 0 |
| ITTage | 10426 | SUCCEEDED | BPU_PINS 3301 / 3301 | 0 / 0 |
| Tage_SC | 16112（unread 192 ref = dead_ref） | PASS_DEAD_REF | BPU_PINS 2843 / 2843 | 0 / 0 |
| Composer | 42060（unread 192 ref = dead_ref） | PASS_DEAD_REF | COMPOSER_PINS 601 / 601，BPU_CHILD_PINS 23083 / 23083 | 0 / 0 |
其余项同 §4.4 / §5.4 / §6.4 / §9.4（failing/unverified/aborted 0、unmatched 0、黑盒仅厂商叶子、merge_dup false、vmucp true）。

# 对账（续 2）：§10 重证（proof commit `335a330a`，证据 evidence/335a330a9baa/；§10.3 未改一字）
| 目标 | 预测 → 实测 passing | verdict | 钉点（打印 / fm.log「Set a match」行数） | fm.log 行首 Error / Unknown name | receipt sha256 |
|---|---|---|---|---|---|
| FauFTB | 5660 → 5660 | SUCCEEDED | 400/400 / 400 | 0 / 0 | `f2416cb8551aec4dfa0f907c052e15c4d900e4f102b7ea4b4d19dd69e0316a4e` |
| ITTage | 10426 → 10426 | SUCCEEDED | 3301/3301 / 3301 | 0 / 0 | `4463d24bc528d595b794f51a0b9ea565b1e46349cc239303672841bcf5eeba13` |
| Tage_SC | 16112 → 16112（unread 192 = dead_ref） | PASS_DEAD_REF | 2843/2843 / 2843 | 0 / 0 | `732fcc36226c529285dc4fc41ac5c41a1434cef43a4b34e1f9c5fbeb32533200` |
| Composer | 42060 → 42060（unread 192 = dead_ref） | PASS_DEAD_REF | 601/601 + 23083/23083 / 23684 | 0 / 0 | `87976b3ac62d3f362bf39a560d9aa4e77d680ce51c11aa03db3ab3c248f9490d` |

本表取代此前 cee28122 / 68bffe7f / 05394ca2(Tage_SC) / 9cc9c9c7 四份 receipt（钉点脚本字节变化，按规则 STALE）。fm_predict check 全部对上。
复跑：`PROOF_COMMIT=335a330a9 bash scripts/run_proof.sh <FauFTB|ITTage|Tage_SC|Composer> <同名> < /dev/null`。

## 11. Composer 重证（ClockGate 换本地重写件之后；merge main `37f04051`）
- 问题（集成者报）：codex 0208 把 ClockGate 换成本地重写件 rtl/common/ClockGate.sv（锁存器名 enableLatched），Composer 钉点里
  32 处 impl 侧名字是旧 golden ClockGate 的 `…/rcg/CG/EN_reg`（来自 child_pairs/Tage_SC.tsv，c3c9307d 从旧 Tage_SC 自证 matched.rpt 收割），
  FM 报 32 处 Unknown name，钉点 fail-closed 退出（这正是 §10 加的返回值计数在起作用）。
- 修法：在 HEAD（`37f04051`）上重跑 Tage_SC diagnostic-full（其 impl 闭包 26 个 repo 文件与 main 上 restale-sram 的 Tage_SC receipt
  evidence/68d1a0932a12 逐个 sha256 相等；结论同：SUCCEEDED passing 16112、unread 192、fm.log Unknown name 0），用 scripts/extract_fm_matched_pairs.py
  从这次 matched.rpt 重新收割 `verif/ut/Composer/child_pairs/Tage_SC.tsv`：14262 对，变化恰为这 32 对的 impl 名（EN_reg → enableLatched_reg）；
  重生成 `verif/ut/Composer/fm_pins_pre.tcl`（子实例区仍 23083 位）。FauFTB.tsv / ITTage.tsv 不含 ClockGate 内部名，未动。RTL 未改。
- 跑前预测（★跑完不许改★）：Composer passing **42060**，PASS_DEAD_REF，unread 192（全 ref = verif/dead_ref/Composer.json），failing/unverified/aborted 0，
  unmatched 0，COMPOSER_PINS 601/601、BPU_CHILD_PINS 23083/23083，fm.log 行首 Error / Unknown name = 0 / 0，「Set a match」23684 行。

# 对账（续 3）：§11（§11 未改一字）
Composer：proof commit `be19d6a0`，证据 evidence/be19d6a02dba/Composer；预测 42060 → 实测 42060，PASS_DEAD_REF，unread 192（全 ref = dead_ref），
failing/unverified/aborted/unmatched 0；COMPOSER_PINS 601/601、BPU_CHILD_PINS 23083/23083、fm.log「Set a match」23684 行；行首 Error / Unknown name = 0 / 0；
fm_predict check 对上（差 856 = constant_reg 664 + unread 192）。receipt sha256 `0f746fd628d1a7c11db464c3dca2831272bacd06f9db9b068958716632e8d2a0`。取代 §10 的 Composer receipt（335a330a）。
复跑：`PROOF_COMMIT=be19d6a02 bash scripts/run_proof.sh Composer Composer < /dev/null`。

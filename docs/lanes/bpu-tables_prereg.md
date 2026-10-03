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

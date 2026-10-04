# exeunits lane（agent/exeunits）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `1ce47a77a` 之上的认领 commit `86ef411b5`（`docs/lanes/exeunits_claim.md`） |
| 工作树 | `/home/eda/xs-env/wt-exeunits`，分支 `agent/exeunits` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | 叶子 `VSetRiWvf` / `IntFPToVec` / `CVT64` / `IntToFP_3` → 外壳 `ExeUnit` / `_1` / `_4` / `_5` / `_8` / `_9` / `_10` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| 冲突核对 | codex outbox 最新 0209 与全部 `codex/*` 分支、全部 worktree 的 `*_claim.md` / `*_prereg.md` 逐名 grep：11 个目标名无他人认领 / 改动（k3next20 / newrtl_next20 / vectorcvt-tree 的 prereg 里出现的 IntToFP_3 / ExeUnit_5 / ExeUnit_9 / CVT64 只是「父模块 / 参照」提及，均标 MISSING/UNPROVEN 无人认领） |

UT 统一：`verif/ut/<T>`，tb 由 `scripts/gen_exeunits_ut.py` 从 golden 端口表生成（`--check` 幂等），
双例化 golden vs 重写 `_xs`，**每拍比较全部输出口**（`!==`）；3 seed × 3 档 initreg × 200k 拍，串行；
覆盖门槛写进 PASS 判据（任一不足即 TEST FAILED）。
复跑：`cd verif/ut/<T> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`。

变异自检：`scratchpad/exeunits/mut.py`（沙箱 = rtl 副本，仓库 RTL 不被触碰），seed 7 × random × 20k 拍。

## 1. 叶子四个

### 1.1 结构

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` | 写法 |
|---|---|---|---|---|
| VSetRiWvf | 214 | 208 | 0 | 新核 `xs_VSetRiWvf_core`；复用已签 `vset_pkg`（backend_common_pkg.sv，**未改**）的计算函数；golden 的 VsetModule 两侧语义相同但 impl 不例化（同 VSetRiWi / VSetRvfWvf） |
| IntFPToVec | 218 | 175 | 0 | 新核 `xs_IntFPToVec_core`（fli 三表 + 标量选源 + 复制 / NaN-box / 规范 NaN），FliH/S/D 表为已签重写件两侧白盒 |
| CVT64 | 224 | 183 | 0 | 新核 `xs_CVT64_core`（isVectorCvt=false：只 FP_INCVT + 本层「源非 NaN-box ⇒ 规范 NaN」），寄存器与 golden 同名；与 CVT64_1（向量实例）结构不同，不共核 |
| IntToFP_3 | 309 | 299 | 0 | 新核 `xs_IntToFP_3_core`（valid 链 / 反压链 / 两级使能 / perf payload，写法同已签 FCVT）；IntToFPDataModule 子树全为已签重写件 |

子模块全部两侧白盒（impl 读重写件、ref 读 golden），无黑盒、无同源共享件。

### 1.2 UT（各 3 seed × 3 档 × 200k，全部 errors=0）

| 目标 | seed 1：0 / random / 1017 | seed 7：0 / random / 7017 | seed 42：0 / random / 42017 | 每档 checks |
|---|---|---|---|---|
| VSetRiWvf | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 5,399,946 |
| IntFPToVec | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 4,199,958 |
| IntToFP_3 | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 | 4,199,748 |
| CVT64 | 见 1.2.1 | | | 399,980 |

覆盖（seed 1）：
- VSetRiWvf：vl=0 78452 / vl=VLMAX 13780 / vtype 写 49969 / 非法 69929 / 合法 30053 / 中间 vl 7750；
- IntFPToVec：fli h/s/d 20362/33976/20511，复制且换规范 NaN 11818 / 复制原值 10561 / fmv 40243 / 立即数 53580 / 原样 31225；
- IntToFP_3：fire 133199 / 写回 126042 / 反压 9792 / 转换 66526 / fmv 66673 / f16/f32/f64 43445/43010/43381 / 动态 rm 26470；
- CVT64：规范 NaN（整数目的 / 浮点目的 / fround）19058/9635/7132，f2i 71057 / i2f 36165 / f2f 32523 / fround 24189 / fcvtmod 9434。

1.2.1 CVT64 的寄存器在 UT 跑完后改成与 golden 同名（`2faf43e28`，纯改名，逻辑字节外无改动），9 档在该 commit 上
重跑中，结果与改名前（9/9 errors=0，同上覆盖数）一并在对账里落数。

变异自检：VSetRiWvf 4/4 抓到（M1 vtype 写口判据 8070 / M2 vlmax 未取下界 478 / M3 AVL 选源 172 / M4 非法时 vma 未清 6924）；
IntFPToVec 3/5 抓到（M2 e16 规范 NaN 常数 370 / M4 fli.s 未 NaN-box 3395 / M5 丢 validPipe(0) 5091），
M1（fli 时仍按 isImm 选源）与 M3（fmv 判据丢 ~needDup）**是等价变异**：fli 优先级高于 isImm、needDup 优先级高于 fmv，
被改的项都被更高优先级的分支遮蔽，errors=0 符合预期（FM 同理判等价）；
IntToFP_3 4/4（M1 valid 链加 ready 门控 13386 / M2 第 2 级使能丢 validPipe(1) 2437 / M3 payload 第 1 级不看 ready 11395 /
M4 写回丢 validPipe(2) 1425）；CVT64 在改名后重跑，对账落数。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/<T>.json）

模型 = golden 闭包寄存器位 + 顶层 output 位（merge_dup=false 下严格）。

| 目标 | 模型 expected | 预测 passing | 预测 constant_reg | unread | vmucp | 其余 |
|---|---|---|---|---|---|---|
| VSetRiWvf | 736（0 + 736） | **736** | 0 | 0 | 否 | failing / unverified / unmatched 0，无黑盒，SUCCEEDED |
| IntFPToVec | 791（0 + 791） | **791** | 0 | 0 | 否 | 同上 |
| CVT64 | 572（503 + 69） | **545** | 27 | 5（全 matched_nc，vmucp 开后计入比较） | 是（verif/fm_target_config/CVT64.tcl） | 同上 |
| IntToFP_3 | 2158（1427 + 731） | **2158** | 0 | 0 | 否 | 同上 |

依据：
- CVT64 的 constant_reg 27 取自 FP_INCVT 单独签核（evidence/96363f56a451/FP_INCVT：passing 467 + constant 27 = 模型 494）与
  FCVT 父级（evidence/b8c893dad053/FCVT：constant 27）；CVT64 自己的 78 个寄存器位都不是常量（s2 规范值每一位都能被 u32/u64
  的全 1 置位）。isFpToVecInst 在本实例恒 1，若因此多出常量寄存器，差额会出现在 constant_reg 里、由 fm_predict check 指认。
- IntToFP_3：IntToFPDataModule 单独签核 passing 212 = 模型 212（无常量寄存器），本层寄存器（valid 链 2 + perf/seq payload 2×641）均非常量。
- 无 fm_pins：叶子的寄存器要么与 golden 同名（CVT64），要么是已签 FCVT 同款写法（IntToFP_3 的 vldThisFu / perfVec），预期名字匹配可配上；
  若出现 unmatched，先补 fail-closed 钉点再重跑，并在对账里写明。本节未做任何 FM 试跑。

复跑：`bash scripts/run_proof.sh <T> <T> < /dev/null`（UT 目录名与目标同名）。

## 2. ExeUnit 家族七个外壳

### 2.1 结构（七个变体共用）

- 共享控制核 `rtl/backend/xs_ExeUnit_core.sv`（手写 295 行）：§1 发射握手 + busy（不定延迟外壳）/ §2 inPipe 控制字段
  延迟流水（每级随 robIdx 判冲刷；每个字段只保留到「最晚读它的 FU 级」，即 firtool 删剩的那组寄存器）/ §3 每个 FU 的
  时钟门控使能（确定延迟：随 ready 反压前移的 valid 链 + 收尾一拍；不定延迟：in.fire 置 / out.fire 清）/
  §4 instrAddrTransType 打一拍（每个用到的 FU 一份）/ §5 写回 valid；同文件 `xs_ExeUnit_wbsel` = 写回字段 Mux1H。
- 各变体 wrapper `rtl/backend/ExeUnit_<k>.sv` 与 FM 钉点 `verif/ut/ExeUnit_<k>/fm_pins_pre.tcl` 由
  `scripts/gen_exeunit.py`（`--check` 幂等）从 golden 机械生成，fail-closed：golden 每个寄存器都必须归入核按参数会生成的
  那一个（门控链 / inPipe valid / inPipe 字段 / busy 快照 / att 打拍），inPipe 字段深度必须等于保留规则，每条实例连线与
  每个输出口必须命中已知形状（直连 / 单元素直通 / FU 成员与 valid 一一对应的 Mux1H / io_out_valid / io_in_ready）。
- 子模块（Dispatcher_*、全部 FU 及其子树、ClockGate）均为已签核件，两侧白盒：impl 读重写件（含本 lane 的四个叶子），
  ref 读 golden；无重写件的 PROVEN_IN_CONE 件（CryptoModule / FloatAdder / FloatAdderF64Pipeline /
  FarPathFloatAdderF64WidenPipeline / FPCVT / FloatDivider / FloatDividerR64）两侧同读 golden；ClockGate impl 读
  rtl/common/ClockGate.sv（codex 0208）。**无黑盒。**
- FM 钉点三段：(a) 外壳寄存器 golden 扁平名 ↔ 核 generate 名；(b) 子 FU 签核时用过的钉点（FMA 1636 / FCVT 128 / Bku 18 /
  FAlu 23），用 tclsh 桩真跑原文件取调用序列加实例前缀，条数对 docs/pin_call_seq.tsv；(c) 外壳附加（FAlu 三组「同值两份」
  寄存器 44 条、MulUnit 改读 ArrayMulDataModule 重写件后的 8 个死位），依据写在 gen_exeunit.py `EXTRA_CHILD_PINS`。

| 目标 | golden 行 | impl 行（生成） | `_GEN_`/`_T_` | FU | 钉点条数 |
|---|---|---|---|---|---|
| ExeUnit | 791 | 531 | 0 | Alu / Mul(门控,2) / Bku(门控,2) | 70 |
| ExeUnit_1 | 1859 | 1303 | 0 | brh / jmp（各一份 att 打拍） | 10 |
| ExeUnit_4 | 274 | 215 | 0 | Alu | 0 |
| ExeUnit_5 | 2713 | 1919 | 0 | brh / jmp / i2f(门控,2) / VSetRiWi / VSetRiWvf / i2v | 53 |
| ExeUnit_8 | 1131 | 796 | 0 | Falu(门控,1) / Fcvt(门控,2) / f2v / Fmac(门控,3) | 1920 |
| ExeUnit_9 | 395 | 269 | 0 | Fdiv（不定延迟：busy + uncer 门控） | 11 |
| ExeUnit_10 | 731 | 483 | 0 | Falu(门控,1) / Fmac(门控,3) | 1770 |

### 2.2 诊断跑（如实记）

登记前做过 FM `diagnostic-full`（`FM_FAILING_LIMIT=0`，vmucp 关，不产 receipt）——外壳是大装配件，钉点与 vmucp 白名单
需要先看到 unread / unmatched 集合才能写依据：
1. 首跑七个全 elaborate 失败（FMR_VLOG-091：核里 need_flush 函数读模块级 flush 信号）→ 改成参数传入（`1be1cff99`，纯重构）。
2. ExeUnit_10 首跑 FAILED（failing 66 / unmatched 32）：FAlu 三组「同值两份」寄存器在外壳里扇出签名对称、FM 配不上 →
   按语义整组补 (c) 段钉点后 SUCCEEDED。ExeUnit 首跑 unmatched unread 8+8（MulUnit 的 ArrayMulDataModule 死位，外壳里改读
   重写件后名字不同）→ 按下标规则钉 8 条后全部 matched_nc。
3. 之后的诊断数字即下表「诊断」列；预测 = 诊断 passing + vmucp 打开后计入比较的 unread 数。

### 2.3 UT（3 seed × 3 档 × 200k，tb 自动由 golden 结构推出 FU 名单 / fuType 编码 / 门控 / busy；每拍比全部输出）

激励：fuType 85% 取本外壳某 FU 的编码（其余全随机，多数不命中任何 FU）、valid 60%、out.ready 90%、flush 10%
（robIdx 与 flush robIdx 都落在 0..15，两种冲刷判定都常见）、cg_bore 5% 强开；暖机 5+8×N 拍轮流给每个 FU 发指令。
覆盖（写进判据，每项 > 1000）：每个 FU 收下 / 写回、反压、未命中 FU、冲刷（有 flush 口的）、门控开 / 关（有门控的）、busy。

2.3.A（本批登记）：

| 目标 | 9 档 errors | 每档 checks | 覆盖（seed 1） |
|---|---|---|---|
| ExeUnit_1 | 全 0 | 23,597,522 | in {46070, 46119} / out {51202, 51289} / 反压 10302 / 未命中 17942 |
| ExeUnit_4 | 全 0 | 3,999,740 | in 91736 / out 101704 / 反压 9968 / 未命中 18033 |
| ExeUnit_9 | 全 0 | 4,399,714 | in 26035 / out 25205 / 反压 2630 / 冲刷 12040 / 门控开 105069 关 94915 / busy 149054 |

变异自检（核 `xs_ExeUnit_core.sv`，seed 7 × random × 20k）：ExeUnit_8 上 C1 isAfter 写成 >= 1318 / C2 丢 flushItself 254 /
C4 字段流水跳级 6713 / C5 写回不看 valid 407752 / C6 inPipe 不判冲刷 12416 —— 抓到；C3（门控 en_q 少开收尾一拍）**UT 没抓到**
（errors=0：收尾那拍 FU 内已无在途操作，UT 观测不到；FM 在 ClockGate 白盒里把 E 当比较锥比，由 FM 覆盖）。
ExeUnit_9 上 B1 收下同拍被冲不清 busy 50816 / B2 uncer 清除不看 out.ready 122364 / B3 busy 不拦 Dispatcher 315423 /
B4 在途被冲不清 busy 323783；ExeUnit_1 上 A1 att 位序错 17107 / A2 写回选择恒看第 0 个 FU 174469。
CVT64（§1 补）：改名后重跑 9 档全 0；变异 M1 2949 / M2 446 / M3 100 / M5 625 / M6 100 抓到，M4（第 2 级使能恒开）
UT 抓不到：s2 只从 s1 取值、s1 只在 fire 后变，恒开使能在可达状态下与 fireReg 门控等价（属等价变异，FM 侧不作期望）。

### 2.4 跑前预测（★跑完不许改本节★）—— 2.4.A 本批

| 目标 | 模型 expected | 诊断 passing / constant / unread | 预测 passing | vmucp |
|---|---|---|---|---|
| ExeUnit_1 | 1373（10 + 1363） | 1373 / 0 / 0 | **1373** | 否 |
| ExeUnit_4 | 789（0 + 789） | 789 / 0 / 0 | **789** | 否 |
| ExeUnit_9 | 2158（1363 + 795） | 2127 / 30 / 1 | **2128**（+1） | 是（verif/fm_target_config/ExeUnit_9.tcl） |

其余均为 failing / unverified / unmatched 0、无黑盒、无 dont_verify，SUCCEEDED。

2.3.B / 2.4.B（第二批：ExeUnit_5）

| 目标 | 9 档 errors | 每档 checks | 覆盖（seed 1） |
|---|---|---|---|
| ExeUnit_5 | 全 0 | 27,192,792 | in {15439, 15270, 16929, 15190, 15323, 15378} / out {17109, 16934, 15216, 16878, 16963, 17084} / 反压 9203 / 冲刷 16703 / 未命中 18230 / 门控开 60962 关 139022 |

| 目标 | 模型 expected | 诊断 passing / constant / unread | 预测 passing | vmucp |
|---|---|---|---|---|
| ExeUnit_5 | 3505（1481 + 2024） | 3505 / 0 / 0 | **3505** | 否 |

2.3.C / 2.4.C（第三批：ExeUnit_10）

| 目标 | 9 档 errors | 每档 checks | 覆盖（seed 1） |
|---|---|---|---|
| ExeUnit_10 | 全 0 | 4,799,496 | in {49297, 51250} / out {48014, 43831} / 反压 8086 / 冲刷 16513 / 未命中 18071 / 门控开 275261 关 124713 |

| 目标 | 模型 expected | 诊断 passing / constant / unread | 预测 passing | vmucp |
|---|---|---|---|---|
| ExeUnit_10 | 6501（5641 + 860） | 6224 / 272 / 5 | **6229**（+5） | 是（verif/fm_target_config/ExeUnit_10.tcl） |

2.3.D / 2.4.D（第四批：ExeUnit / ExeUnit_8）

| 目标 | 9 档 errors | 每档 checks | 覆盖（seed 1） |
|---|---|---|---|
| ExeUnit | 全 0 | 3,999,420 | in {30612, 33854, 33823} / out {34086, 30666, 30547} / 反压 8647 / 冲刷 16396 / 未命中 17957 / 门控开 213887 关 186079 |
| ExeUnit_8 | 全 0 | 5,598,964 | in {25372, 25612, 22990, 25639} / out {24356, 23053, 25523, 21917} / 反压 7865 / 冲刷 16568 / 未命中 17940 / 门控开 257107 关 342845 |

| 目标 | 模型 expected | 诊断 passing / constant / unread | 预测 passing | vmucp |
|---|---|---|---|---|
| ExeUnit | 7839（7050 + 789） | 7325 / 487 / 27 | **7352**（+27） | 是（verif/fm_target_config/ExeUnit.tcl） |
| ExeUnit_8 | 8894（7584 + 1310） | 8585 / 299 / 10 | **8595**（+10） | 是（verif/fm_target_config/ExeUnit_8.tcl） |

## 3. 对账（跑后追加；上面各节数字未改）

| 目标 | 证明 commit | 预测 passing | 实测 passing | constant_reg | failing / unverified / unmatched / unread | 黑盒 / dont_verify | 判决 | fm_predict check |
|---|---|---|---|---|---|---|---|---|
| VSetRiWvf | e858f1db696d | 736 | 736 | 0 | 0 / 0 / 0 / 0 | 0 / 否 | SUCCEEDED | 逐位相等 |
| IntFPToVec | e858f1db696d | 791 | 791 | 0 | 0 / 0 / 0 / 0 | 0 / 否 | SUCCEEDED | 逐位相等 |
| CVT64 | e858f1db696d | 545 | 545 | 27 | 0 / 0 / 0 / 0（vmucp 5 点计入比较） | 0 / 否 | SUCCEEDED | 差额 27 = constant_reg 27 |
| IntToFP_3 | e858f1db696d | 2158 | 2158 | 0 | 0 / 0 / 0 / 0 | 0 / 否 | SUCCEEDED | 逐位相等 |
| ExeUnit_1 | 41366b7e2f9c | 1373 | 1373 | 0 | 0 / 0 / 0 / 0 | 0 / 否 | SUCCEEDED | 逐位相等 |
| ExeUnit_4 | 41366b7e2f9c | 789 | 789 | 0 | 0 / 0 / 0 / 0 | 0 / 否 | SUCCEEDED | 逐位相等 |
| ExeUnit_9 | 41366b7e2f9c | 2128 | 2128 | 30 | 0 / 0 / 0 / 0（vmucp 1 点，+1） | 0 / 否 | SUCCEEDED | 差额 30 = constant_reg 30 |
| ExeUnit_5 | f5b39c39e043 | 3505 | 3505 | 0 | 0 / 0 / 0 / 0 | 0 / 否 | SUCCEEDED | 逐位相等 |
| ExeUnit_10 | 21fcdf533a90 | 6229 | 6229 | 272 | 0 / 0 / 0 / 0（vmucp 5 点，+5） | 0 / 否 | SUCCEEDED | 差额 272 = constant_reg 272 |
| ExeUnit | bbd73158a339 | 7352 | 7352 | 487 | 0 / 0 / 0 / 0（vmucp 27 点，+27） | 0 / 否 | SUCCEEDED | 差额 487 = constant_reg 487 |
| ExeUnit_8 | bbd73158a339 | 8595 | 8595 | 299 | 0 / 0 / 0 / 0（vmucp 10 点，+10） | 0 / 否 | SUCCEEDED | 差额 299 = constant_reg 299 |

vmucp 六条：精确绑定（unread 集合与 verif/fm_target_config/<T>.tcl 所列逐点一致，均来自诊断跑）/ 双射（全部 matched_nc，
ref = impl 点数）/ 真比较（passing 恰好 + 点数）/ 全零 / 无 dont_verify、无黑盒、无放宽 appvar / 配置文件进 receipt script_closure。
11 个目标全部 SUCCEEDED，预测与实测零偏差。

## 4. ExeUnit_4 重证（集成者要求：删空钉点文件）—— 跑前登记

`verif/ut/ExeUnit_4/fm_pins_pre.tcl` 是 0 条钉点的空文件，被 main 上 gate_all 的「FM 钉点结构闸」判红（期望数须为正）。
gen_exeunit.py 改为钉点数 0 时不生成该文件（`--check` 要求它不存在），文件已删。receipt 的 pin_scripts 闭包因此变化，重证。
RTL / Makefile 逻辑 / 其余证明输入未变（Makefile 只改注释）。
预测（★跑完不许改★）：passing **789**（模型 789 = 0 + 789），constant_reg 0，failing / unverified / unmatched / unread 0，
无黑盒、无 dont_verify、无钉点，SUCCEEDED。docs/fm_predictions/ExeUnit_4.json 登记不变（expected 789）。

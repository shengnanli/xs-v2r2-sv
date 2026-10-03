# rob-regcache lane —— 跑前登记

本文件在 **FM 起跑之前**提交 §0–§4；跑完在文末追加，★不修改已提交分节的任何数字★。
分两批登记：批 A（Rob 三个子块 + VTypeBuffer + 后端五个数据叶子，本节）；批 B（RegCache 家族六个 +
SRT16DividerDataModule，§B 另行追加，同样早于证明）。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | main `3f23a91c`（分支 `agent/rob-regcache`，认领 `63f7326b`） |
| 实现 commit | 批 A RTL：`c8eca863`（8 个）+ `ac8e9b7e`（VTypeBuffer） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| 冲突核查 | codex outbox 最近 5 条无本 lane 目标；全部 `codex/*` 与其余分支 `diff main...` 的 rtl/verif/ut 无本 lane 目标文件；全部 worktree 的 claim 只有本 lane；prereg 里出现的同名只是别的 lane 把它们当"两侧同源 golden 子模块"引用（cb_decunit、ctrlblock、newrtl_next20、k3next20），不是认领 |
| `divunit-initreg` | 分支相对 main 只改了 `verif/ut/ArithVecLeaves5/{Makefile,tb.sv}`（未提交），未改 rtl；但它与 DivUnit 重证要改的是同一个 Makefile ⇒ DivUnit 重证等它合入 main 再做 |
| ClockGate | **不重写**：仓内先例（`rtl/common/xs_SRAMTemplate_core.sv` 头注释、`MbistClockGateCell_93.sv`、dcache/l2slice prereg）一律把它当"DFT/库单元，golden 同源单元模型两侧共用"；它是锁存器型 ICG 门控基元（`always_latch`），本应走 vendor/库单元边界，但 `verif/vendor_boundary.tsv` 里**没有**它的声明。按任务书停下报告，不硬写 |

## 1. 结构（批 A）

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` | 子模块（两侧白盒） | UT |
|---|---:|---:|---:|---|---|
| CommitStuckCounter | 125 | 65 | 0 | — | RobPtrLeaves |
| RobEnqPtrWrapper | 368 | 159 | 0 | — | RobPtrLeaves |
| NewRobDeqPtrWrapper | 886 | 316 | 0 | — | RobPtrLeaves |
| VTypeBuffer | 1288 | 733 | 0 | SyncDataModuleTemplate__64entry_4（golden 侧再例化 DataModule__16entry_16 ×4）、SnapshotGenerator_1、SnapshotGenerator_2（均 PROVEN_DIRECT 重写件） | VTypeBuffer |
| VsetModule | 125 | 99 | 0 | —（复用 `backend_common_pkg.sv` 的 vset_pkg 函数，未改该文件） | BeDataLeaves |
| strdiedLSNumOfUopTable | 109 | 40 | 0 | — | BeDataLeaves |
| indexedLSNumOfUopTable | 176 | 55 | 0 | — | BeDataLeaves |
| IntToFPDataModule | 200 | 175 | 0 | IntToFP / _1 / _2（及 prenorm、postnorm×3、RoundingUnit×3、LZA、CLZ，全 PROVEN_DIRECT 重写件） | BeDataLeaves |
| AluDataModule | 331 | 30 | 0 | 无例化：wrapper 直接用 `Alu.sv` 的 `xs_Alu_core`（golden 的 11 个小模块在核里是 function；Alu.sv 字节未改） | BeDataLeaves |

## 2. UT（RTL 字节 = `c8eca863` / `ac8e9b7e`；读数在 §6 追加）

双例化 golden vs `<名>_xs`（`scripts/dual_tb_lib.py`），每拍全部输出逐位 `!==`，带输出位 0/1 覆盖闸与定向覆盖计数；
seed 1/7/42 × `+vcs+initreg+0` / `random` / `<seed>017`，各 200k 拍，串行。不复位状态用 arm 条件推迟比较窗口
（VTypeBuffer：64 项存储体全写过 + 快照 4 槽全写过；IntToFPDataModule：两级使能各至少一次）。
CommitStuckCounter 自然计满要 2^21 拍，tb 每 4000 拍把两侧 count 同时 force 到 2^21-32 再放开，让溢出真发生。

## 3. 证明计划

先诊断跑（`make fm-<T> FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，不进 evidence）看配对与 unread，
需要钉点 / vmucp 时补登 §5 后再跑 official（`scripts/run_proof.sh <UT> <T>...`）。

## 4. 跑前预测（★跑完不许改本节★，登记 `docs/fm_predictions/<T>.json`）

| 目标 | expected（regs + outs） | 预测 |
|---|---:|---|
| CommitStuckCounter | 22（21 + 1） | passing 22，unread 0，constant 0 |
| RobEnqPtrWrapper | 108（54 + 54） | passing 108，unread 0 |
| NewRobDeqPtrWrapper | 225（72 + 153） | passing 225，unread 0 |
| VsetModule | 24（0 + 24） | passing 24（io_out_vlmax[0] 恒 0 仍计入 passing） |
| strdiedLSNumOfUopTable | 4 | passing 4 |
| indexedLSNumOfUopTable | 7 | passing 7（高 3 位恒 0 仍计入） |
| IntToFPDataModule | 212（143 + 69） | passing 212，unread 0 |
| AluDataModule | 64 | passing 64 |
| VTypeBuffer | 1520（1496 + 24） | **constant_reg ≥ 9**（commitSize / walkSize / spclWalkSize 的 [6:4] 恒 0）；**unread ≈ 113**（deqPtrVec_1..7 共 49 位 + deqPtrOH 64 位，两侧对称无读者）——需 vmucp；子模块内部若另有死位以 receipt 指认。vmucp 后预测 passing = 1520 − constant_reg |

失配 = 修 RTL 对齐 golden + UT 回归，不找解释去圆。

---

## B. 批 B 跑前登记（RegCache 家族六个 + SRT16DividerDataModule + 两个父级重证；★跑完不许改本节★）

### B.1 结构

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` | 子模块 | UT |
|---|---:|---:|---:|---|---|
| RegCacheDataModule | 818 | 312（家族核 `xs_RegCacheDataModule_core` + wrapper） | 0 | — | RegCacheLeaves |
| RegCacheDataModule_1 | 700 | 221（薄 wrapper） | 0 | — | RegCacheLeaves |
| RegCacheAgeTimer | 1390 | 513（家族核 + wrapper） | 0 | — | RegCacheLeaves |
| RegCacheAgeTimer_1 | 956 | 300（薄 wrapper） | 0 | — | RegCacheLeaves |
| RegCacheAgeDetector | 1356 | 347（家族核 + wrapper） | 0 | — | RegCacheLeaves |
| RegCacheAgeDetector_1 | 763 | 173（薄 wrapper） | 0 | — | RegCacheLeaves |
| SRT16DividerDataModule | 1259 | 560 | 0 | CSA3_2_3956 ×4 / 3960 ×2 / 3962 ×25、RightShifter（PROVEN_DIRECT 重写件，实例名同 golden，处于 generate 块内） | SRT16DividerDataModule |
| RegCache（父级重证） | — | RegCache.sv 不改 | — | impl 侧 6 个子模块由 golden 同源改为读上面 6 个重写件 | RegCache（tb 改由 gen.py 生成，支持九档） |
| DivUnit（父级重证） | — | DivUnit.sv 不改 | — | impl 侧 SRT16DividerDataModule（+CSA/RightShifter）由 golden 同源改为读重写件 | ArithVecLeaves5（main b4d61278 的新 tb） |

UT 过程中发现并修掉的重写件自身 bug（UT 抓到，均在提交前）：
- RegCacheDataModule 越界判据 `raddr < 4'(16)` 在 16 项变体上回绕成 `< 0` ⇒ 恒读第 0 项（改为 int 比较）；
- SRT16DividerDataModule 宽 CSA 的 -q·d 选择写成"读模块变量的 function + 连续赋值"，仿真里函数体内读的
  udNegReg 变化不触发重算（综合语义正确、仿真语义错）⇒ 改 always_comb；同类写法 RegCacheAgeDetector 的
  get_age 一并改成 always_comb 展开完整矩阵。

### B.2 跑前预测（登记 `docs/fm_predictions/<T>.json`）

| 目标 | expected | 预测 |
|---|---:|---|
| RegCacheDataModule | 2528（1040 + 1488） | passing 2528，unread 0（ren 只用于断言，是输入不是比较点） |
| RegCacheDataModule_1 | 2264（780 + 1484） | passing 2264 |
| RegCacheAgeTimer | 160（40 + 120） | passing 160 |
| RegCacheAgeTimer_1 | 98（32 + 66） | passing 98 |
| RegCacheAgeDetector | 136（120 + 16） | passing 136 |
| RegCacheAgeDetector_1 | 78（66 + 12） | passing 78 |
| SRT16DividerDataModule | 1803（1737 + 66） | **unread 6**：aLZCReg[6]、dLZCReg[6]、udNegReg_{0,1,3,4}[67]（与 DivUnit vmucp 白名单同一批死位，两侧对称）→ 拟 vmucp；**constant_reg ≥ 7**：rCarryReg[0]、udNegReg_0[1:0]、udNegReg_1[0]、udNegReg_3[0]、udNegReg_4[1:0]，另有 rud/r2udPmNegReg 里由查表常数位决定的恒定位（未逐位推算，以 receipt 指认）；vmucp 后 passing = 1803 − constant_reg |
| RegCache | 3851（merge_dup=true，模型不适用） | 预测与旧 receipt（evidence/25cdce831a66）同：native SUCCEEDED、passing 3830、failing 0、unread_notcompared 0、ref 侧 unmatched-unread 6 = verif/dead_ref/RegCache.json 声明 ⇒ PASS_DEAD_REF；子模块内部若因数组命名出现 unmatched，诊断跑后补登 |
| DivUnit | 沿用 docs/fm_predictions/DivUnit.json | 预测 passing 3132（vmucp）、unread 0，与现 receipt 同 |

### B.3 补登：SRT16DividerDataModule 诊断跑 → vmucp（official 之前提交；B.2 数字不改）

- 诊断跑（工作树 `make fm-SRT16DividerDataModule FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`，不进 evidence）：
  native SUCCEEDED、passing **1797**、failing 0、unmatched 全 0、unread **6**，全部 matched_nc，恰为 B.2 预测的
  aLZCReg[6] / dLZCReg[6] / udNegReg_{0,1,3,4}[67]（层次 `u_core/` 下同名，FM 自己配上，不需钉点）。
- **对 B.2 的偏差：constant_reg 预测"≥ 7"错，实测 0**——那些恒 0 位（rCarryReg[0]、udNegReg 低位等）FM 照样
  作为 passing 比较点计入（与 srt-divblocks 第一、二阶段同一现象）。差额 1803 − 1797 = 6 = unread，全部指认。
- vmucp 白名单 `verif/fm_target_config/SRT16DividerDataModule.tcl` + UT Makefile `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true`，
  诊断复跑：passing **1803**，unread 0，failing 0。
- **official 复核判据**：SUCCEEDED；passing 1803；failing / unverified / unread / unmatched 全 0；黑盒 0；dont_verify false；
  fm_predict 对账差额 0。
- 批 A 变异自检（scratch 沙箱，seed 1 / initreg 0 / 20k 拍，不进库）：23 个里 22 个 CAUGHT；M22（VTypeBuffer 的
  deqPtrOH 去掉循环回绕）MISSED——deqPtrOH 在 G1 配置下无读者（只喂 XSError），外部不可观测，由 FM 的 vmucp 比较
  deqPtrOH 寄存器覆盖（见 VTypeBuffer 补登）。

### B.4 补登：VTypeBuffer 与 RegCache 诊断跑（official 之前提交；§4 / B.2 数字不改）

**VTypeBuffer**（vmucp=false、未钉点）：native SUCCEEDED、passing 1297、failing 0、constant_reg **9**（与 §4 下限一致：
commitSize/walkSize/spclWalkSize[6:4]）、unread 214 = matched_nc 64（deqPtrOH，§4 已预测）+ unmatched unread 150/150。
§4 预测 unread ≈113 **偏少 101**：deqPtrVec_1..7 的 49 位预测到了但它们是 unmatched（数组 vs 平铺命名），另漏算了
enqPtrVec_1..5 的 flag（5，写地址只用 value）与子模块 SyncDataModuleTemplate__64entry_4 读地址寄存器的半边（96：
bank 内副本只用 [3:0]、读口 bank 选择只用 [5:4]；该子模块单签时这些位是 matched，嵌进父级后因层次多一层 u_core 配不上）。
处置：`verif/ut/VTypeBuffer/fm_pins.tcl` 逐位钉 150 对（字面计数，fail-closed）+ vmucp 白名单
`verif/fm_target_config/VTypeBuffer.tcl`。诊断复跑：`VTB_PINS: 150 / 150 bad=0`、passing **1511**、unread 0、failing 0、
constant_reg 9。差额 1520 − 1511 = 9 = constant_reg，全部指认。
**official 复核判据**：SUCCEEDED、passing 1511、unread/failing/unmatched 全 0、constant_reg 9、fm_predict 差额 = 9 = constant_reg。

**RegCache**（父级重证，impl 改读 6 个重写件，merge_dup 默认，模型不适用）：native SUCCEEDED、passing **3830**、failing 0、
unmatched 0、unread 6 且全部是 ref 侧（= verif/dead_ref/RegCache.json 声明的 6 个 delayToWakeupQueueRCIdx_*[4]），
与旧 receipt evidence/25cdce831a66 逐项相同 ⇒ 预测 official 判 PASS_DEAD_REF。

### B.5 DivUnit 重证（以 main 18359395 为基础；跑前登记）

- 闭包变化：impl 侧 SRT16DividerDataModule（+ CSA3_2_3956/3960/3962、RightShifter）由 golden 同源改为读重写件
  （`verif/ut/ArithVecLeaves5/Makefile` 的 DIVUNIT_REWRITTEN；RTL_GOLDEN_DEPS 去掉 DIVUNIT_DEPS）。DivUnit.sv 字节不改；
  fpu-parents 合入的 fpdiv_r64_block 改动保留。
- 钉点：`fm_pins.tcl` 不改（按叶名配对）；夹具 `fm_pins_fixture.tcl` 的 impl 路径改为 `u_core/u_div/u_core/<leaf>`
  ⇒ pin_call_equiv 调用序列哈希变化（新前提），以本次 receipt 为准 `--update` 基线。
- UT（merge 后，seed 1/7/42 × initreg 0/random/<seed>017）：9/9 PASSED，errors=0，checks 5199966/5199987/5199977，toggled 26/26。
- 预测：与 evidence/f0492477b75c 同——native SUCCEEDED、passing **3132**、failing 0、unread 0（vmucp，6 对钉点）、unmatched 0。

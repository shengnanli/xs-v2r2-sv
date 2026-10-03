# srt-divblocks lane 第三阶段 —— 跑前登记（VIDiv）

本文件在 **FM 起跑之前**提交 §0–§4；跑完在文末追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 | `09da2b26`（集成者把 main `3f23a91c` 合入并追加第三阶段认领）；实现 commit `ad190dab` |
| 目标 | `VIDiv`（向量整数除法 FU 外壳，ExeUnit_17 的 child；ExeUnit_17 本身不做） |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |
| 冲突核查 | 全部分支 `diff main...` 的 rtl 无 VIDiv；全部 worktree claim 只有本 lane |
| child | VectorIdiv（本 lane 第二阶段签）、Mgu（PROVEN_DIRECT，其下 ByteMaskTailGen / UIntToContLow1s / UIntToContLow0s / MaskExtractor）——两侧白盒 |
| 已签件改动 | 无（本阶段只新增 `rtl/backend/VIDiv.sv`） |

## 1. 结构

| 目标 | golden 行 | impl 行 | `_GEN_`/`_T_` |
|---|---:|---:|---:|
| VIDiv | 397 | 343（`rtl/backend/VIDiv.sv`：vidiv_pkg + xs_VIDiv_core + wrapper） | 0 |

核分节：§1 保持旁路（DataHoldBypass）/ §2 RobPtr.needFlush / §3 VectorIdiv / §4 Mgu 与 vl=0 旧值 / §5 出口透传寄存器。
bug-for-bug：掩码先判 VialuFixType.needClearMask（0x84/0x86，对除法 opType 永不命中，照抄）；Mgu vdIdx 取 vuopIdx[2:0]；
fuOpType=0xFF 的非 SYNTHESIS 断言不实现（同 FAlu 口径）。

## 2. UT（`verif/ut/VIDiv`，RTL 字节 = `ad190dab`，读数在 §6 追加）

golden vs `_xs` 逐拍对拍全部出口 + 每次出口握手的独立 oracle：写回数据按 SEW 逐元素（RISC-V 除法语义的商/余数，再按
vl=0 / vstart≥vl / prestart / tail(vta) / 掩掉(vma) / active 合并），透传字段对照发射时的 uop；冲刷用独立 RobPtr 模型判定。
九档：seed 1/7/42 × initreg 0 / random / `<seed>017`，各 200k 拍。

## 3. 证明计划

先诊断跑看配对与 unread（VectorIdiv 子树的 1600 个档位/死位钉点要按 `vidiv/` 前缀重出；外壳的结构体寄存器名需实测），
再按需补钉点 / vmucp，补登 §5 后跑 official。

## 4. 跑前预测（★跑完不许改本节★）

| 目标 | expected | 预测 |
|---|---:|---|
| VIDiv | 13884（regs 13094 + outs 790） | constant_reg **8**（VectorIdiv 子树里 8 个 I8DivNr4 各 1）；unread **100** = VectorIdiv 子树 96 + `outCtrl_r_vpu_vuopIdx[6:3]` 4 位（Mgu 只读低 3 位）；钉点 + vmucp 后 passing **13876**，failing / unmatched / 黑盒 0 |

## 5. 补登（official 签核跑之前提交；§4 数字不改）

诊断跑（工作树 `make fm-VIDiv FM_MODE=diagnostic-full`，不进 evidence）：
1. VectorIdiv 子树钉点按 `vidiv/` ↔ `u_core/vidiv/` 前缀重出（`scripts/gen_srt16divint.py` 生成 `verif/ut/VIDiv/fm_pins_pre.tcl`，
   1600/1600 pinned）：native SUCCEEDED / passing **13776** / failing 0 / unmatched compare 0 / constant **8** / unread **100**
   （96 matched + 4(4) unmatched）——与 §4 预测**逐项相同**：13776 + 8 + 100 = 13884。
   4 个 unmatched 正是预测的 `outCtrl_r_vpu_vuopIdx[6:3]`：golden 平铺名 `outCtrl_r_vpu_vuopIdx_reg[b]` vs 核的打包结构体
   `u_core/outCtrl_r_reg\[vuopIdx][b]`，死位无锥只能靠名字 ⇒ 生成器补这 4 对（共 1604 点）。
2. `verif/fm_target_config/VIDiv.tcl` + Makefile `FM_VERIFY_MATCHED_UNREAD_COMPARE_POINTS = true`，诊断复跑：passing 13876、
   unread 0、failing 0、constant 8，`VIDIV_PINS: 1604 / 1604`。

**official 复核判据**（`bash scripts/run_proof.sh VIDiv VIDiv`）：SUCCEEDED；passing **13876**；failing 0；unread 0；
unmatched 全 0；constant_reg 8；黑盒 0；dont_verify false；fm.log 含 `VIDIV_PINS: 1604 / 1604 points pinned`。
fm_predict 对账：13884 − 13876 = 8 = constant_reg。

## 6. 对账（跑完追加）

### 6.1 UT（RTL 字节 = `ad190dab`，tb = `3878df05`；九档全 TEST PASSED，errors 0）

| seed | initreg 0 / random / `<seed>017`（三档逐字相同） |
|---|---|
| 1 | 对拍 200,000 拍；oracle 14,233 条 uop / 106,698 个元素；冲刷生效 279、未命中 140；只对拍 2,380 |
| 7 | 200,000；14,284 / 108,288；279 / 132；2,382 |
| 42 | 200,000；14,260 / 108,080；254 / 133；2,330 |

覆盖（seed 1）：sew0..3 = 3550/3598/3472/3613 条；vl=0 2603、vstart≥vl 1356；元素级 prestart 5470、tail 置 1 11069 /
保留 10404、掩掉置 1 4672 / 保留 4527、active 41832、除零 8074、最小值÷-1 2414；反压 11219。

★首跑九档 errors 23/19/7（`ad190dab` 上的 tb）——**tb bug，不是 RTL**：生成 uop 时 narrow/dstMask 分支把
「非除法 opType（含 needClearMask 的 0x84/0x86）只对拍」的标记覆盖回「查 oracle」，于是这些 uop 被误送 oracle
（失配全是 fu=0x084/0x086 或随机 opType 的 uop）；golden 与重写件的逐拍对拍一次未失配。修 tb（`3878df05`）后重跑如上表。

### 6.2 变异自检（scratch 沙箱，seed 1 / 20k 拍）：10 个里 8 个 CAUGHT

冲刷 level 项、忙时 robIdx 来源、商/余数选择位、vm、vl=0 保旧值、vdIdx 位段、有符号位、pdest 透传均抓到。
MISSED 2 个：R8 去掉握手拍的保持旁路——只影响 in.fire 那一拍的 Mgu 输入，而那一拍 out_valid 必为 0，UT 只在 valid 时比
写回数据，结构上看不见；FM 对 `io_out_bits_res_data` 端口在所有状态下比较，由 FM 覆盖。R10 去掉 VectorIdiv out_ready 的
valid 门控——VectorIdiv 只在 OUTPUT 态（=valid）用 ready，变异体组合等价，不是漏检。

### 6.3 FM 对账（official，signoff-strict，commit `9193a2e0`）

| 目标 | expected | passing | failing | unread | unmatched | constant | 钉点 | 差额 | receipt |
|---|---:|---:|---:|---:|---:|---:|---|---|---|
| VIDiv | 13884 | 13876 | 0 | 0 | 0 | 8 | 1604/1604 | 8 = constant_reg | `evidence/9193a2e0077d/VIDiv` |

§4 预测（constant 8、unread 100、vmucp 后 passing 13876）逐项命中；`fm_predict.py check VIDiv` 全部对上；
`check_lane_receipts.py` rc=0。

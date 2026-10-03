# csr-l2-leaves lane（agent/csr-l2-leaves）—— 跑前登记

本文件在 **FM 起跑之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `0086b7fc`（集成者预建 worktree + claim） |
| 实现 commit | `b2399952`（16 目标 RTL + 8 个 UT 目录）+ `bbea0bd9`（L2PipelineLeaves4 tb arm 修正，RTL 未动） |
| 工作树 | `/home/eda/xs-env/wt-csr-l2-leaves`，分支 `agent/csr-l2-leaves` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify，无黑盒 |

| UT 目录 | 目标 | child 处理 |
|---|---|---|
| `CsrDebugTime4` | Debug / MieModule / timeModule / XRetPermitModule | 0 子模块叶 |
| `IMSIC_WRAP` | IMSIC_WRAP | child IMSIC（PROVEN_DIRECT）两侧白盒：ref golden IMSIC 闭包，impl 重写 IMSIC/IntFile/IMSICGateWay；AsyncResetSynchronizer* 两侧同源 golden（与 verif/ut/IMSIC 同做法） |
| `FastArbiterL2c` | FastArbiter / FastArbiter_1 / FastArbiter_26 | 0 子模块叶；vmucp 开（见 §3） |
| `L2Cache` | L2Cache | 0 子模块叶（MbistPipeline 单态化） |
| `MbistIntfL2` | MbistIntfL2 | 0 子模块叶 |
| `L2PipelineLeaves4` | Pipeline_2 / _3 / _10 / _11 | child Queue1_PrefetchTrain / Queue1_PrefetchResp / Queue1_UInt32（PROVEN_DIRECT）两侧白盒 |
| `LCredit2Decoupled_2` | LCredit2Decoupled_2 | 0 子模块叶 |
| `AsyncResetSyncPrim_d3_i0` | AsyncResetSynchronizerPrimitiveShiftReg_d3_i0 | 0 子模块叶 |

AsyncResetSynchronizerPrimitiveShiftReg_d3_i0 的边界核实：golden 实例化图从 XSTile 可达
（XSTile→XSCore→Backend→ExuBlock→ExeUnit_7→CSR→IMSIC_WRAP→IMSIC→IMSICGateWay→
AsyncResetSynchronizerShiftReg_w1_d3_i0→本模块）；`docs/g1_boundary_ledger.tsv` 记为
`WORK_REACHABLE / DESIGN`（不是 vendor/宏边界），故照常重写签核。

## 1. 结构

- Debug：可读核 `xs_Debug_core`（五种进 debug 原因 + 4 路 mcontrol6 使能 + 链合法性 + 两级不复位打拍），
  wrapper 展平 tdata1Vec 与两份相同的 tUpdate 字段。
- MieModule：核按中断号向量（复用 `csr_irq_pkg`，不改其内容），三路 sideband（sie/hie/vsie）OR 合并、
  优先于 CSR 写；flop 只在 golden 有寄存器的 11 位上生成。
- timeModule / XRetPermitModule：手写小核 + wrapper。
- IMSIC_WRAP / Pipeline_*：纯例化壳（golden 本身 0 行逻辑），实例名照 golden（`imsic`、`stages_<k>`）。
- FastArbiter / _1 / _26：`scripts/gen_fastarbiter_l2c.py --check` 生成薄壳，核 `rtl/common/xs_FastArbiter_core.sv`
  不改；_26 的 io_chosen 走 FastArbiter_2 的独热捎带法。
- L2Cache：并入 `scripts/gen_mbist_pipe_family.py` 的 EXTRA_MODS（核 `rtl/dft/xs_mbist_pipe_core.sv` 不改）。
- LCredit2Decoupled_2：手写核（CHIDAT flit 打成 struct），非阻塞 15 信用。
- AsyncResetSynchronizerPrimitiveShiftReg_d3_i0：参数化 `xs_AsyncResetSyncShiftReg_core`（DEPTH/INIT）+ wrapper。

## 2. 跑前预测（★跑完不许改本节★；登记见 docs/fm_predictions/*.json）

模型 = golden 寄存器位 + 顶层 output 位（`fm_predict.py model`，merge_dup=false 适用）。

| 目标 | 模型 expected | passing 预测 | 差额指认 | 其余 |
|---|---|---|---|---|
| Debug | 177 (4+173) | 177 | 0 | failing/unverified/unmatched/unread 0，无黑盒，SUCCEEDED |
| MieModule | 86 (11+75) | 86 | 0 | 同上 |
| timeModule | 259 (66+193) | 259 | 0 | 同上 |
| XRetPermitModule | 6 (0+6) | 6 | 0 | 同上 |
| IMSIC_WRAP | 6548 (6376+172) | 5972 | constant_reg 576（与 IMSIC 自身 receipt 逐位相同：eidelivery 等恒 0 寄存器） | 同上 |
| FastArbiter | 112 (8+104) | 111 | constant_reg 1（rrGrantMask[0]）；vmucp 把 pendingMask[0] 收进 passing | 同上 |
| FastArbiter_1 | 18 (8+10) | 17 | 同上 | 同上 |
| FastArbiter_26 | 77 (8+69) | 76 | 同上 | 同上 |
| L2Cache | 1214 (318+896) | 1214 | 0（同核 L2Slice 系 4 个先例全 = 模型） | 同上 |
| MbistIntfL2 | 319 (0+319) | 319 | 0 | 同上 |
| Pipeline_2 | 206 (105+101) | 206 | 0（= Queue1_PrefetchTrain 先例） | 同上 |
| Pipeline_3 | 99 (92+7) | 99 | 0（= Queue1_PrefetchResp 先例） | 同上 |
| Pipeline_10 | 99 (66+33) | 99 | 0 | 同上 |
| Pipeline_11 | 66 (33+33) | 66 | 0（= Queue1_UInt32 先例） | 同上 |
| LCredit2Decoupled_2 | 436 (11+425) | 436 | 0 | 同上 |
| AsyncResetSynchronizerPrimitiveShiftReg_d3_i0 | 4 (3+1) | 4 | 0 | 同上 |

## 3. vmucp

只有 FastArbiter / _1 / _26 开（`verif/fm_target_config/<T>.tcl` 各一份 `fm_target_vmucp_allow`）。
依据：与已签 FastArbiter_2..7 / 28 同核同死位（pendingMask[0]，因 rrGrantMask[0] 按构造恒 0）。
本 lane 是首跑前登记（同构外推），判据：receipt 的 vmucp unread 集合必须恰好是 `pendingMask_reg[0]` 1 个点、
passing 必须正好等于上表；任一不符即停下诊断，不改登记。

## 4. 明写可能出错的地方

1. 名字配不上：Debug 的打拍寄存器（golden `io_out_*_tUpdate_valid_REG(_1)` vs 重写 `frontend_update_q[1:0]`）、
   MieModule 的 `reg_*` vs generate 内 `g_bit[i].g_flop.q`、AsyncReset 的 `sync_0..2` vs `sync[2:0]`、
   LCredit 的计数器名。靠签名分析配；若出 unmatched，补 `fm_pins_pre.tcl` 再证，不动 RTL。
2. IMSIC_WRAP 的 constant_reg 若不是 576，按 receipt 逐项指认（重写 IMSIC 闭包与 IMSIC 自身 receipt 同字节）。
3. timeModule 的 `reg_time` 不复位：FM 用 initreg 无关的寄存器对应，不应受影响；若出 unverified 再诊断。
4. Pipeline_10 两级同型 Queue1_UInt32：两个实例的同名寄存器可能被 FM 交叉配；若出 failing 先查配对。

## 5. 对账（跑后追加；上文未改）

- FM：16/16 signoff-strict SUCCEEDED，failing 0 / unverified 0 / unmatched 0 / 黑盒 0 / dont_verify 无 / fm_pins 无。
  14 个 @2f9bb8a2（evidence/2f9bb8a2b814/*），Pipeline_2/_3 @dbbefb9b（evidence/dbbefb9b09e1/*）。
  `fm_predict.py check` 16 目标 rc=0：12 个逐位相等；IMSIC_WRAP 差 576 = constant_reg 576、FastArbiter/_1/_26 差 1 =
  constant_reg 1，均与登记时写明的指认一致。`check_lane_receipts.py` rc=0。
- ★预测 vs 实测的一处偏差（第 3 节漏登）★：Pipeline_2 / Pipeline_3 首跑 @2f9bb8a2 native SUCCEEDED 但 strict PARTIAL，
  passing 201 / 13，unread 5 / 86 —— 全部是 child 深度 1 队列 ram 里 deq 侧无读者的对称死存储位
  （ram_reg[94..98] / ram_reg[0..85]，两侧 matched_nc 双射，与 child Queue1_PrefetchTrain / Queue1_PrefetchResp
  独立签核时同一组点、同样走 vmucp）。我登记时只按 child 的 passing 填了数，没写到要开 vmucp。
  按 vmucp standing rule 补 `verif/fm_target_config/Pipeline_2.tcl` / `Pipeline_3.tcl`（dbbefb9b）后重证：
  unread 5/86 -> 0，passing 正好 +5 / +86（201->206、13->99），等于第 2 节登记值。首跑 PARTIAL 证据未收录（不是绿）。
- FastArbiter / _1 / _26 的 vmucp 精确绑定（第 3 节判据）：另用 `FM_MODE=diagnostic-full` vmucp 关各跑一次（不出 receipt），
  unread_points 各恰好 1 行 `matched_nc pendingMask_reg[0] <-> u_core/pendingMask_reg[0]`，passing 110/16/75，
  vmucp 开后 111/17/76，正好 +1。
- 第 4 节风险 1（名字配不上）未发生：签名/名字分析全配上，不需要 fm_pins。风险 4（Pipeline_10 交叉配）未发生。
- UT：8 个目录 × seed 1/7/42 × initreg {0, random, <seed>017} = 72 档，每档 200k 拍，全 errors=0、覆盖闸全过。
  L2PipelineLeaves4 首轮 seed42×random / 42017 两档各 2 个失配（Pipeline_10.io_out_bits，cyc 8/9）——tb 的 arm 条件
  在复位期间就满足、而复位中入队不会推进到第二级，第二级存储仍是两侧各自随机初值；属 tb 假失配，RTL 未动，
  arm 加 `!reset`（bbea0bd9）后该目录 9 档全部重跑 errors=0。
- 变异自检（scratchpad 副本，seed 7 / 10k 拍 / initreg 0）：18/18 被抓，含 2 个复位域变异
  （timeModule 去掉控制位异步复位、AsyncReset 同步器异步改同步）。

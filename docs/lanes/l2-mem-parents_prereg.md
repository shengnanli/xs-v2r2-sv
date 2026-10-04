# l2-mem-parents lane（agent/l2-mem-parents）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `8a914fb00`（main 1ce47a77a + 认领 commit） |
| 工作树 | `/home/eda/xs-env/wt-l2-mem-parents`，分支 `agent/l2-mem-parents` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | MMIOBridge / PatternHistoryTable / VBestOffsetPrefetch / PBestOffsetPrefetch / DCacheWrapper / AsyncResetSynchronizerShiftReg_w1_d3_i0 / MbistClockGateCell |
| 口径 | `signoff-strict`（有厂商宏叶子的目标用 `assembly` + allow 声明），`FM_MERGE_DUP=false`，无 dont_verify |
| UT 档位 | seed 1/7/42 × `+vcs+initreg+0` / `+vcs+initreg+random` / `+vcs+initreg+<seed>017`，各 200k 拍，串行 |

## 1. AsyncResetSynchronizerShiftReg_w1_d3_i0（golden 101 行，含 header）

- 纯装配壳：只例化一条 `AsyncResetSynchronizerPrimitiveShiftReg_d3_i0 output_chain`。child PROVEN_DIRECT
  （rtl/uncore/AsyncResetSynchronizerPrimitiveShiftReg_d3_i0.sv），两侧白盒：ref golden 原语，impl 重写原语。0 黑盒。
- 重写 `rtl/uncore/AsyncResetSynchronizerShiftReg_w1_d3_i0.sv`（`_GEN_`/`_T_` = 0）。
- UT `verif/ut/AsyncResetSyncShiftReg_w1_d3_i0`（dual_tb_lib，每 ~50 拍随机异步复位）：9 档全部 checks=199992 errors=0 cov_fail=0。
  覆盖（seed 1 / initreg 0）：q1=92150、in_reset=4077、d_rise=54109。
  变异自检：io_d 取反接入链 ⇒ errors=18517/19992（20k 拍）。
- 预测：passing **4**（3 位同步寄存器 + 1 位输出），failing/unverified/unmatched/unread 全 0，无黑盒，SUCCEEDED。

## 2. MbistClockGateCell（golden 104 行，含 header）

- 同一 Scala 类 `MbistClockGateCell(mcpCtl)` 的 mcpCtl=false 款；mcpCtl=true 款即已签的 MbistClockGateCell_93。
  逻辑只有一行使能选择，不抽公共核（不动已签 _93）。
- child ClockGate：本地共享基元 rtl/common/ClockGate.sv（codex 0208 已签），impl 读本地件、ref 读 golden。0 黑盒。
- UT `verif/ut/MbistClockGateCell`（gen_l2slice_ut.py --both-phases）：9 档全部 checks=400000 errors=0。
  覆盖（seed 1）：mbist_req 99832 拍、dft_cgen 100236 拍。
  变异自检：MBIST 使能去掉 writeen ⇒ errors=1270/40000（20k 拍）。
- 预测：passing **2**（ClockGate 锁存器 1 + 输出 1），其余全 0，SUCCEEDED。与 _93 实测同构（_93 登记 2）。

## 3. PBestOffsetPrefetch（golden 307 行含 header / 37 端口；重写 rtl/l2/PBestOffsetPrefetch.sv 217 行）

- 本体只有一级预取请求寄存器（req_tag/set/needT/source/valid）+ 跨页判断；手写单模块，`_GEN_`/`_T_` = 0。
- child 全部 PROVEN_DIRECT，两侧白盒：DelayQueue（xs_DelayQueue_core）、OffsetScoreTable（xs_OffsetScoreTable_core）、
  RecentRequestTable（xs_RecentRequestTable_core + SRAMTemplate_146 + xs_SRAMTemplate_core）。
  厂商宏 sram_array_1p256x13m13s1h0l1b_l2_pftch_rrt / array_13 两侧同读 golden；叶子 array_13_ext 两侧对称黑盒
  （verif/allow/PBestOffsetPrefetch.json，vendor_boundary 表内 vendor_sram_leaf）⇒ 口径 `assembly`。
- UT `verif/ut/PBestOffsetPrefetch`（dual_tb_lib；训练地址 = 8 页小池子 × 步长流；arm = 首次 train fire 且 SRAM 首读之后 1 拍）：
  9 档全部 errors=0 cov_fail=0（seed 1/7 checks=1797597，seed 42 checks=1797552）。
  覆盖（seed 1 / initreg 0）：train_fire 89159、req_fire 56754、跨页丢弃 10030、禁用丢弃 18762、enable=0 满反压 10689、中途复位 11。
  变异自检（20k 拍，scratchpad，不进库）：M1 跨页不丢 ⇒ errors=1289；M2 train_ready 不看请求寄存器 ⇒ 1601；M3 req fire 不看 enable ⇒ 355。
- **lane 内诊断跑（照实登记）**：`make fm-PBestOffsetPrefetch FM_MODE=diagnostic-full FM_FAILING_LIMIT=0`（关 vmucp、无钉点，未出证）
  native SUCCEEDED、passing 957、failing 0、unmatched compare 0、unread 两侧各 353 位 Unmatched unread：
  delayQueue 16 项 addrNoOffset[41:20]（352 位，RRT 只读写地址 [25:6]）+ rrTable/REG（assert 专用寄存器，1 位）。
  处置：`scripts/gen_l2mp_pins.py` 生成 fm_pins_pre.tcl 逐位钉 353 对（fail-closed，字面 353）+ vmucp
  （verif/fm_target_config/PBestOffsetPrefetch.tcl 六条）。
- 预测：passing **1310**（= fm_predict 模型；= 957 + 353），failing / unverified / unmatched / unread 全 0，
  黑盒仅 array_13_ext 两侧各 1（allow 声明），无 dont_verify，SUCCEEDED。

## 4. VBestOffsetPrefetch（golden 419 行含 header / 50 端口；重写 rtl/l2/VBestOffsetPrefetch.sv 248 行）

- 本体 = s0/s1 两级（s1 一项寄存器）+ 出口 enable 门控，出口全部来自 reqFilter（PrefetchReqBuffer）。手写单模块，`_GEN_`/`_T_` = 0。
- child 全部 PROVEN_DIRECT，两侧白盒：DelayQueue_1、OffsetScoreTable_1、RecentRequestTable_1（+ SRAMTemplate_146）、
  PrefetchReqBuffer（+ RRArbiterInit_14/_15）。黑盒仅 array_13_ext（verif/allow/VBestOffsetPrefetch.json）⇒ `assembly`。
- UT `verif/ut/VBestOffsetPrefetch`（TLB 响应模型：上一拍发 tlb_req 本拍回；mode 1 相位下游不收把 reqFilter 16 项填满；
  arm = 首次 s0 fire、SRAM 首读、首次 tlb_req、reqFilter 16 项都分配过之后 1 拍）：9 档全部 errors=0 cov_fail=0
  （seed 1 checks=2182817，seed 7 1741168，seed 42 1662921）。
  覆盖（seed 1 / initreg 0）：s0_fire 84079、s1 被挡 6851、禁用压 valid 34745、tlb_req 58274、req_fire 13484、enable=0 5976、中途复位 9。
  变异自检（60k 拍）：M2 禁用不压 valid ⇒ errors=96908；M3 偏移零扩展 ⇒ 11996；
  **M1 s1_ready 去掉 ~io_req_valid ⇒ errors=0（UT 抓不到）**：多留一拍的 s1 请求被 reqFilter 的 prev_in_req/表内去重吞掉，
  端口上看不出；FM 比较 s1_req_valid 寄存器的次态，覆盖此差异。
- **lane 内诊断跑**：diagnostic-full（关 vmucp、无钉点）native SUCCEEDED、passing 4067、failing 0、unmatched compare 0，
  Unmatched unread 两侧各 531 位：delayQueue 16 项 addrNoOffset[43:20]（384）+ rrTable/REG（1）+ reqFilter 146 位
  （同 PrefetchReqBuffer 单独签核时那批）；另 matched-unread 6 位 s1_newFullAddr[5:0]。
  处置：gen_l2mp_pins.py 钉 531 对（字面 531）+ vmucp（verif/fm_target_config/VBestOffsetPrefetch.tcl 六条）。
- 预测：passing **4604**（= 模型；= 4067 + 531 + 6），其余全 0，黑盒仅 array_13_ext 两侧各 1，SUCCEEDED。

## 5. MMIOBridge（golden 2673 行 / 184 端口；重写 rtl/uncore/MMIOBridge.sv 2021 行，其中手写核约 100 行）

- 结构：手写胶合核 xs_MMIOBridge_core（§1 选槽：编号最小的空闲槽，全忙兜底槽 15 / §2 读保序：有槽等 ReadReceipt
  时挡所有 ReadNoSnp / §3 RXRSP/RXDAT 按 txnID 分发 / §4 上游 ready）+ golden 同名 wrapper（`scripts/gen_mmiobridge.py`
  生成，带 `--check`；每个 child 端口恰好命中一条规则、每个 wrapper 输出恰好被驱动一次、常量表与 golden 逐项比对、
  每槽 io_id 字面量与 io_pCrd 接线与 golden 实例连线比对）。`_GEN_`/`_T_` = 0。
- child 全部 PROVEN_DIRECT，两侧白盒：MMIOBridgeEntry/_2/_4/_8（xs_MMIOBridgeEntry_core）×16、RRArbiterInit_13、
  Arbiter16_CHIDAT、Arbiter16_TLBundleD（xs_FixedPriorityArbiter_core）。0 黑盒 ⇒ `signoff-strict`。
- UT `verif/ut/MMIOBridge`（dual_tb_lib；RX 的 txnID 3/4 时间挑 golden 侧正在等该通道的槽；16 槽未复位寄存器 0 时刻后
  force 对齐，同 MMIOBridgeLeaves）：9 档全部 checks=22599096 errors=0 cov_fail=0。
  覆盖（seed 1 / initreg 0）：A fire 18414、A 全满 81252、槽 15 被用 8593、D 读回 6932 / 写回 11381、TXREQ 26997、TXDAT 9574、
  读被挡 157477、RXDAT 命中 6934 / 落空 92638、pCrd 查询（槽 9）3434。
  变异自检（20k 拍）：M2 写也被挡 ⇒ errors=883849；M3 rxdat ready 不看 txnID ⇒ 424；
  **M1 全忙时不兜底到槽 15 ⇒ errors=0：等价变异**——槽的 req fire = ready & valid，槽 15 不空闲时 valid 被它忽略，
  端口与状态都看不出差别；FM 同样会判等价（不是 UT 漏洞）。
- **lane 内诊断跑**：diagnostic-full native SUCCEEDED、passing 7794、failing 0、unmatched 0、无 unread、无黑盒、无钉点。
- 预测：passing **7794**（= 模型 regs 6868 + outs 926），其余全 0，无黑盒，SUCCEEDED。

## 6. PatternHistoryTable（golden 3739 行 / 43 端口 / 顶层 218 个寄存器 991 位；重写 rtl/memblock/PatternHistoryTable.sv 821 行，手写核约 450 行）

- 结构：手写核 xs_PatternHistoryTable_core（§1 s0 选择 / §2 s1 读 RAM 与位图对齐 / §3 s2 比较与计数更新 /
  §4 s3 写回、valid、PLRU 与预取位图 / §5 s4 三个预取请求）+ golden 同名 wrapper（`scripts/gen_pht.py` 生成，`--check`）。
  `_GEN_`/`_T_` = 0。
- child 全部已签核，两侧白盒：SRAMTemplate_145（xs_SRAMTemplate_core；其内 MbistClockGateCell 用本 lane §2 的重写件，
  ClockGate 用本地共享基元）、OverrideableQueue / _1、Arbiter3_PfGenReq。厂商宏叶子 array_12_ext 两侧对称黑盒
  （verif/allow/PatternHistoryTable.json）⇒ `assembly`。
- FM「匹配前」钉点 `verif/ut/PatternHistoryTable/fm_pins_pre.tcl`（gen_pht.py 生成）：golden 顶层 218 个寄存器 / 991 位
  逐位钉到 u_core 的同义寄存器（扁平名 vs 数组名），每个 golden 寄存器恰好命中一条规则、单射、字面 991。
- UT `verif/ut/PatternHistoryTable`（dual_tb_lib；pht_index 0..3、tag 6 选 1 让组/tag 撞上；arm = 三种预取请求各发生过
  且 SRAM 读过之后 1 拍；厂商 SRAM 行为模型的存储阵列上电值 0 时刻后对齐）：9 档全部 errors=0 cov_fail=0
  （seed 1 checks=1398579，seed 7 1394547，seed 42 1390879）。
  覆盖（seed 1 / initreg 0）：evict 命中 28393 / 未命中 59940、lookup 命中 4505、单次更新跳过 5488、s1_wait 96938、
  本/下/上区域请求 1169 / 400 / 425、下一区域被挡保持 364、跨页 313、中途复位 12。
  变异自检（40k 拍）：M1 单次更新 0 不 +2 ⇒ 40601；M2 has_been 时照加 ⇒ 17053；M3 不等同组写 ⇒ 147337；
  M4 下一区域请求不保持 ⇒ 364；M5 上一区域不判跨页 ⇒ 28614。
- **lane 内诊断跑**：diagnostic-full（带钉点、关 vmucp）native SUCCEEDED、passing 2166、failing 0、unmatched 0、
  unmatched unread 0、matched-unread 19 = s3_region_vaddr[39:21]（只用 [20:0]）。处置：vmucp
  （verif/fm_target_config/PatternHistoryTable.tcl 六条），不需额外钉点。
- 预测：passing **2185**（= 模型 regs 1809 + outs 218 + 黑盒输入；= 2166 + 19），其余全 0，黑盒仅 array_12_ext 两侧各 1，SUCCEEDED。

## 7. DCacheWrapper（golden 1985 行 / 627 端口 / 本层 80 个寄存器 480 位；重写 rtl/memblock/DCacheWrapper.sv 1328 行，整份生成）

- 结构：`io <> dcache.module.io` + uncacheNode↔cacheCtrlOpt 端口换名直连 + 40 个 perf 计数各打两拍（不复位）。
  与已签的 L2TLBWrapper 同型：整份由 `scripts/gen_dcachewrapper.py`（`--check`）从 golden 端口表生成：wrapper 端口表与
  DCache 端口表换名后逐名逐宽相同、perf 口恰 40 个 6 位、dcache 实例连线与 golden 逐项比对。`_GEN_`/`_T_` = 0。
- child DCache（PROVEN_DIRECT，rtl/memblock/DCache.sv 当前字节；restale-sram lane 正在重证 DCache，本证明白盒读当前字节），
  其子树文件表与 verif/ut/DCache 完全相同（Makefile 照抄）。黑盒 = verif/allow/DCache.json 换根（生成器逐项换、不增不减）：
  厂商叶子 array_7_ext ×32 / array_8_ext ×8（两侧各一份）+ golden 侧被消空的 StorePipe ⇒ `assembly`。
- 钉点 `verif/ut/DCacheWrapper/fm_pins_pre.tcl`：本层 480 位 perf 寄存器 + **原样收割** verif/ut/DCache/fm_pins_pre.tcl
  全部点对（根换成 /WORK/DCacheWrapper/dcache），字面计数 fail-closed。vmucp：verif/fm_target_config/DCacheWrapper.tcl
  （本层无死位，matched-unread 全部来自 DCache 子树、与 DCache 签核同一批）。
- UT `verif/ut/DCacheWrapper`：tb 由 gen.py 从 DCache tb 机械改写（实例换成外壳、端口换名、层次引用多一层 dcache）；
  初值档沿用 DCache 的 0 / glue / glue017（cfg 多两层作用域 tb.u_gold / tb.u_impl）。**本节提交时 9 档正在跑**
  （单档约数十分钟），读数补在文末对账节；FM 与 UT 并行（同一 commit 字节）。
- **未做诊断跑。**
- 预测：passing **82566**（模型 82977 = DCache 模型 82497 + 本层 480；减 constant_reg 411 —— 与 DCache 签核同一批常量寄存器），
  failing / unverified / unmatched / unread 全 0，黑盒对象 84（同 DCache），无 dont_verify，SUCCEEDED。

## 对账（跑完追加）

| 目标 | 证明 commit | 口径 | 预测 passing | 实测 passing | 差 | failing / unverified / unmatched / unread | 黑盒 | receipt.json sha256 |
|---|---|---|---|---|---|---|---|---|
| AsyncResetSynchronizerShiftReg_w1_d3_i0 | 2948215a047b | signoff-strict | 4 | 4 | 0 | 0 / 0 / 0 / 0 | 无 | fe3a27f1ee9c6a79aba4bea56614443f0a176d188540362098d5cfa18e992379 |
| MbistClockGateCell | 2948215a047b | signoff-strict | 2 | 2 | 0 | 0 / 0 / 0 / 0 | 无 | fc95e255df7d36ac56cea9fc49d29ce7e101756b6bf297a59e10a5c9f07c900d |
| PBestOffsetPrefetch | e76a4ff889a2 | assembly + vmucp + 钉 353 | 1310 | 1310 | 0 | 0 / 0 / 0 / 0 | array_13_ext 两侧各 1（allow） | 82af3edf02da5e35db21921e90f8389e2dfa4fcfbda272e472d19804bded34a0 |
| VBestOffsetPrefetch | e76a4ff889a2 | assembly + vmucp + 钉 531 | 4604 | 4604 | 0 | 0 / 0 / 0 / 0 | array_13_ext 两侧各 1（allow） | 169e6ee79c989d02f0724eca44e1237559d052cfa550b2ebf37e6217a1d0b96b |
| MMIOBridge | 0394e97e720c | signoff-strict | 7794 | 7794 | 0 | 0 / 0 / 0 / 0 | 无 | e8d52bd508677b3d5514e2d1209f2faf11581dbd36555649e02411ab29c2e553 |
| PatternHistoryTable | 0394e97e720c | assembly + vmucp + 钉 991 | 2185 | 2185 | 0 | 0 / 0 / 0 / 0 | array_12_ext 两侧各 1（allow） | c8e2204f6afb931d04b484bfa06289fbe9124172244dbbb002f42c29f73e4612 |

- 全部 native SUCCEEDED，无 dont_verify / elab147 / relaxed appvar；钉点运行期计数：PBOP `L2MP_PIN_END ok=353 bad=0`、
  VBOP `ok=531 bad=0`、PHT `PHT_PIN_END ok=991 bad=0`。`python3 scripts/fm_predict.py check <6 个目标>` rc=0（全部逐位相等）；
  `python3 scripts/check_lane_receipts.py /home/eda/xs-env/wt-l2-mem-parents` rc=0。
- 复跑：`TMPDIR=<非 /tmp 目录> PROOF_COMMIT=<上表 commit> bash scripts/run_proof.sh <UT 目录> <目标> < /dev/null`
  （UT 目录：AsyncResetSyncShiftReg_w1_d3_i0 / MbistClockGateCell / PBestOffsetPrefetch / VBestOffsetPrefetch / MMIOBridge / PatternHistoryTable）。
  本 lane 跑证明时根分区（/tmp 所在）只剩 ~900MB，detached worktree 建不出来，故 TMPDIR 指到 /home/eda/xs-env/l2-mem-parents-scratch/tmp。
- UT 复跑：`cd verif/ut/<目录> && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`（DCacheWrapper 用 INITREG=<0|glue|glue017>）。

### DCacheWrapper（证明 commit b491b909e262，assembly + vmucp + 钉 13157）—— **native SUCCEEDED，validator PARTIAL（阻塞，待集成者）**

- UT 9 档（0 / glue / glue017 × seed 1/7/42，各 200k 拍）：全部 checks=199977 errors=0 cov_fail=0，单档约 11 分钟。
  覆盖（seed 1 / initreg 0，DCache tb 原样）：D→MissQueue 41026、ReleaseAck 13489、非法 D 412、Probe 1411、store replay 3592、
  错误上报 16734、l2_hint 5926 等（atomic_resp_mq_only=0、tag_write_unintended=0 为 DCache tb 自身只报告不闸项）。
  变异自检：perf 只打一拍 ⇒ errors=33561（5k 拍）。
- FM 读数：passing **82170**、failing 0、unverified 0、unmatched 0、unread 0（unread_points 空）、constant_reg **807**、
  黑盒对象同 DCache（厂商叶子 + StorePipe），无 dont_verify；钉点运行期 `DCW_PREPIN_END n=13157 expect=13157`。
- 预测 vs 实测：本节登记的预测 passing 82566（假设 constant_reg 仍为 DCache 的 411）**错了 −396**：实测 constant_reg 807 = 411 + 396，
  passing 82170 = 模型 82977 − 807。`fm_predict.py check DCacheWrapper` 判「差额被指认（constant_reg 807 + unread 0）」rc=0；
  但我手算的 82566 是错的预测，多出的 396 个常量寄存器**未逐项指认**（396 = 33 × 12，疑为 33 个 perf 计数在 DCache 子树里是
  时序常量、本层两级各 6 位随之被判常量，未核实）。
- **validator 判 PARTIAL，reason = `assembly_disabled_empty_module_wrong_parent:StorePipe@DCacheWrapper`**：
  scripts/fm_verdict.py 的 DISABLED_EMPTY_MODULES 只批准 StorePipe 以 **DCache 为父**、实例路径 `/WORK/DCache/stu_{0,1}`；
  外壳里路径是 `/WORK/DCacheWrapper/dcache/stu_{0,1}`。这是共享闸脚本的白名单形状问题（只认直接父级），不是 RTL 问题。
  按规范（共享脚本不许 lane 改）停在这里：需集成者让该条目接受「DCache 实例在上层父级里」的路径（MemBlock 将同样踩到），
  之后原样重跑 `TMPDIR=/home/eda/xs-env/tmp-l2memparents PROOF_COMMIT=b491b909e262 bash scripts/run_proof.sh DCacheWrapper DCacheWrapper < /dev/null` 即可。
- receipt：evidence/b491b909e262/DCacheWrapper/receipt.json sha256 16f2764697b8ddab866e4c691c1e86bef1d39c2c179e2f9fddff49fe627c96e8（verdict PARTIAL，留档）。

### DCacheWrapper 重跑（codex 0213 后，证明 commit 844a80f26d1e）—— SUCCEEDED

- 改动：scripts/fm_verdict.py 的 DISABLED_EMPTY_MODULES 改为逐 top 精确绝对路径表（DCache 原 4 对象 + DCacheWrapper/dcache/stu_{0,1} 两侧 4 对象），
  0206 D2 其余条件不变；scripts/test_disabled_empty_module.py 2 正样本 + 28 负测全过（原 P0/N1–N14 不变）。
- FM：native SUCCEEDED，validator SUCCEEDED；passing 82170、failing 0、unverified 0、unmatched 0、unread 0、constant_reg 807、
  黑盒对象 84（同 DCache），无 dont_verify；钉点 13157/13157。
- 守恒：模型 82977 = passing 82170 + constant_reg 807，`fm_predict.py check DCacheWrapper` rc=0。登记时手算的 82566 预测错（−396 常量寄存器），
  按 codex 0213 不要求逐项核实。
- receipt：evidence/844a80f26d1e/DCacheWrapper/receipt.json
  sha256 eee24f52f05c0e94b345cc45d9191349b3c6a5c9367ff2556ddc9d5d4357d7ec

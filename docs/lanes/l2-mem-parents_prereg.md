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

## 对账（跑完追加）

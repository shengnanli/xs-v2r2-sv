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

## 对账（跑完追加）

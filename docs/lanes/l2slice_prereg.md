# L2 Slice child lane（agent/l2slice）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `785649ac`（main，`git worktree add /home/eda/xs-env/wt-l2slice -b agent/l2slice main`） |
| 工作树 | `/home/eda/xs-env/wt-l2slice`，分支 `agent/l2slice` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| Scala | `/home/eda/xs-env/XiangShan/coupledL2/src/main/scala/coupledL2/`（tl2chi/ 下为 CHI 版 Slice/MainPipe/TXDAT/RXSNP；公共件在上层目录） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |
| codex 冲突 | 0197 最新认领 50 叶（Pmpaddr*/Pmaaddr31/ShiftRightJam*/RightShift*），与本 lane 无交集；codex/* 分支无 coupledL2 相关 rtl 改动 |

## 1. L2Slice / L2Slice_1 / L2Slice_2 / L2Slice_3

### 1.1 结构

- `utility.mbist.MbistPipeline` 在 Slice 层的单态化：中间节点，2 个 child（child0 = Directory 层
  L2Directory*，child1 = DataStorage 层 L2DataStorage*）。`scripts/gen_mbist_pipe_family.py --scan-adjacent`
  机器判定四者都能原样套 `rtl/dft/xs_mbist_pipe_core.sv`（IS_NODE=1）；生成器新增 EXTRA_MODS，
  每个 golden 语句套模板 + 读数据归约逐位符号执行（L2Slice 1281 次等）通过后才出薄文件。
- 0 子模块、0 黑盒。唯一不复位寄存器 `pipelineDataOutReg`。

### 1.2 UT（verif/ut/L2Slice，四对同测；commit 2654e066 的字节）

逐拍 4 态比四个变体全部 80 个输出；tb 由 `verif/ut/L2Slice/gen.py` 生成。

| seed | initreg+0 | initreg+random | initreg+<seed>017 |
|---|---|---|---|
| 1  | checks=16000000 errors=0 | errors=0 | errors=0 |
| 7  | errors=0 | errors=0 | errors=0 |
| 42 | errors=0 | errors=0 | errors=0 |

覆盖（seed 1）：各变体 80/80 输出翻转；L2Slice selected(child0)=97578 拍、selected_1=55762、activated=134517。
变异自检（scratch，不进库）：M1 reqReg 改成 activated 才更新 ⇒ errors=47099（20k 拍）CAUGHT；
M2 child1 ID_LO 0x09→0x0A ⇒ elaborate 期 $fatal 拦下。
复跑：`cd verif/ut/L2Slice && make run SEED=<s> INITREG=<0|random|<s>017>`

### 1.3 跑前预测（★跑完不许改本节★）

| 目标 | passing | 其余 |
|---|---|---|
| L2Slice   | **766**（regs 316 + outs 450） | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| L2Slice_1 | **769**（317 + 452） | 同上 |
| L2Slice_2 | **771**（318 + 453） | 同上 |
| L2Slice_3 | **772**（318 + 454） | 同上 |

无 vmucp、无 fm_pins。MbistPipe* 家族 24 变体用同一核已签，预期无意外。
可能出错处：dataInReg 高 33 位只被 child1 读、beReg[7:1] 只被 child0 读——都被读，预期 unread=0。

# wbbyp lane B 部分（agent/wbbyp-b）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。A 部分（WbDataPath 一族）在 agent/wbbyp，另有登记。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `4728f823`（main，`git worktree add /home/eda/xs-env/wt-wbbyp2 -b agent/wbbyp-b main`） |
| 工作树 | `/home/eda/xs-env/wt-wbbyp2`，分支 `agent/wbbyp-b` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `ImmExtractor_2` / `ImmExtractor_37`（child）→ `BypassNetwork`（本体） |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. ImmExtractor_2 / ImmExtractor_37

### 1.1 结构

- 共享核 `xs_imm_extractor_core`（`rtl/backend/ImmExtractor.sv`，已签的 ImmExtractor / ImmExtractor_12 同核）**不改**，
  只新加两个薄 wrapper：
  - `ImmExtractor_2`：DATA_BITS=64，TYPE_EN=0x001E（SB/U/UJ/I，与 golden 四个分支一一对应）。
  - `ImmExtractor_37`：DATA_BITS=128，TYPE_EN=0x3000（VSETVLI/VSETIVLI；高 64 位恒 0）。
- 纯组合，无子模块、无寄存器、无黑盒。共享核字节未动 ⇒ 不触发 check_shared_impl_impact 重证。

### 1.2 UT（verif/ut/ImmExtractorBypass，两变体同测，3 seed × 3 档 × 200k）

逐拍比两个输出；每拍 85% 从 13 种合法类型抽、15% 全随机 4 位（含非法码），imm 混边界值。

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=400000 errors=0 | checks=400000 errors=0 | checks=400000 errors=0 |
| 7  | checks=400000 errors=0 | checks=400000 errors=0 | checks=400000 errors=0 |
| 42 | checks=400000 errors=0 | checks=400000 errors=0 | checks=400000 errors=0 |

覆盖（seed 1，每种使能类型产生非零输出的拍数；任一为 0 即判失败）：
ImmExtractor_2 SB=7530 U=11307 UJ=11052 I=7366；ImmExtractor_37 VSETVLI=5453 VSETIVLI=9367。
（纯组合，三档 initreg 结果逐字相同，符合"无隐藏状态"。）

变异自检（scratchpad 手改、跑完复原）：M1 `_2` 去掉 I 型（TYPE_EN 0x000E）⇒ errors=7366；
M3 `_37` 去掉 VSETVLI（0x2000）⇒ errors=12819。M2（`_37` DATA_BITS 改 64）编译被端口契约闸拦下（未进仿真）。

复跑：`cd verif/ut/ImmExtractorBypass && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/ImmExtractor_{2,37}.json）

| 目标 | passing 预测（模型 = 寄存器位 0 + 顶层 output 位） | 其余 |
|---|---|---|
| ImmExtractor_2  | **64**  | failing 0 / unverified 0 / unmatched 0 / unread 0 / 无黑盒 / SUCCEEDED |
| ImmExtractor_37 | **128** | 同上（高 64 位是常量 0 输出，仍按输出比较点计） |

无 vmucp、无 fm_pins、无 allow/dead_ref 声明。本节未做任何 FM 试跑。

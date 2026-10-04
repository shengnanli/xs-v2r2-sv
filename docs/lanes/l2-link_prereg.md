# l2-link lane（agent/l2-link）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `2139ff76c`（main 上 claim commit；worktree 由集成者预建） |
| 工作树 | `/home/eda/xs-env/wt-l2-link`，分支 `agent/l2-link` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `LCredit2Decoupled_1`（LinkMonitor 的 child）、`TLBuffer_15`、`TLBuffer_13`、`LinkMonitor` |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（fm_predict 模型严格适用），allowlist 空，无 dont_verify |

### 0.1 为什么这几个目标此前没有有效 receipt（查明）

- `docs/receipt_harvest.tsv`：`LCredit2Decoupled_1` / `LinkMonitor` 只有 wt-chi 的 `4a19d583a6ce`/`40ec7fc36bb8`、
  `TLBuffer_13` 只有 wt-mismatch 的 `3e9c6f419205`/`d0d4d30f8bc4`，全标 SUPERSEDED、从未进库
  （harvest 判"台账里已有绿判决、多余一轮"，但那个台账判决来自上一轮，本仓 evidence/ 里一份也没有）。
- `verif/ut/TLBuffer_13/Makefile` 最后一次改动把 `FM_MODE=assembly` 改回 strict、ram 改 inline，
  注释自认"★未经 FM 重跑验证"。
- 三者 impl 侧都直接读 golden 子模块（`RTL_GOLDEN_DEPS` 里的 Queue2_* / LCredit2Decoupled_* 等），
  于是 child 在 `coverage_three_axis` 里记 GOLDEN_REUSE。现在这些 child 都已有本仓重写件并签核
  （Queue2_* / Queue4_CHISNP：evidence/1fda02fae0f1；Decoupled2LCredit{,_1,_2} / LCredit2Decoupled：
  evidence/40ec7fc36bb8；LCredit2Decoupled_2：evidence/2f9bb8a2b814），本 lane 改为**两侧白盒**：
  ref 读 golden，impl 读重写件。只有 ram_* 行为级叶子两侧同源 inline（不是黑盒）。

## 1. LCredit2Decoupled_1（golden 192 行 / 22 端口；LinkMonitor 的 RXRSP 接收端）

### 1.1 结构

- `rtl/uncore/LCredit2Decoupled_1.sv`（commit `4f860869e`）：按已签 `LCredit2Decoupled_2` 的样式重写——
  package（CHIRSP flit 结构体）+ 手写核 `xs_LCredit2Decoupled_1_core`（L-Credit 两计数器 + lcrdv 打拍 + 解包/吞 LCrdReturn）
  + golden 同名薄 wrapper。0 子模块、0 黑盒。`_GEN_`/`_T_` = 0。

### 1.2 UT（verif/ut/LCredit2Decoupled_1，gen.py 生成 tb；200k 拍，每拍比全部 76 个输出位）

| seed | `+vcs+initreg+0` | `+vcs+initreg+random` | `+vcs+initreg+<seed>017` |
|---|---|---|---|
| 1  | checks=3199872 errors=0 | checks=3199872 errors=0 | checks=3199872 errors=0 |
| 7  | checks=3199872 errors=0 | checks=3199872 errors=0 | checks=3199872 errors=0 |
| 42 | checks=3199872 errors=0 | checks=3199872 errors=0 | checks=3199872 errors=0 |

全部 cov_fail=0（每个输出位见过 0/1 + 6 个覆盖计数）。seed 1 覆盖：lcrdv 86290、rsp_out 47374、
LCrdReturn 被吞 22910、同拍发+收 41736、池耗尽 58412、reclaim 10640。
变异（scratchpad，20k 拍，不进库）4/4 被抓：去 out_ready 门控 errors=4007；不吞 LCrdReturn 2173；
池复位 14 errors=1；同拍抵消破坏 5928。

复跑：`cd verif/ut/LCredit2Decoupled_1 && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，docs/fm_predictions/LCredit2Decoupled_1.json）

| 目标 | passing 预测 | 其余 |
|---|---|---|
| LCredit2Decoupled_1 | **87**（寄存器 11 = 5+5+1；输出 76） | failing 0 / unverified 0 / unmatched 全 0 / unread 0 / 无黑盒 / SUCCEEDED |

依据：同构的 LCredit2Decoupled_2 实测 436 = 11 + 425 输出位。无 vmucp、无 fm_pins。没有做过任何 FM 试跑。

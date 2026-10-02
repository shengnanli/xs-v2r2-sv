# beleaf lane（agent/beleaf）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `d5564588`（main，`git worktree add /home/eda/xs-env/wt-beleaf -b agent/beleaf main`） |
| 工作树 | `/home/eda/xs-env/wt-beleaf`，分支 `agent/beleaf` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | VMask → Permutation（含 child slideupVs2VdTable / slidednVs2VdTable）→ Og2ForVector → TopDownMonitor |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |
| codex/kimi 冲突 | 第 0 步已查：outbox 最新 codex_0205（RoundingUnit*/Arbiter*/result-control 7）、claude_0204 第 6 批认领表（beleaf = 本 lane 四目标）、kimi k3next30 清单；26 个 codex/* 分支相对 main 的 diff 均未触及四个目标及 slide*Vs2VdTable |
| Chisel 源 | yunsuan@9559211（= XiangShan b36a1a2a5 的 submodule 指针，工作树 clean）；coupledL2@fb546983；XiangShan `src/main/scala` |

## 1. VMask（golden 2,959 行，0 child）

### 1.1 结构

- `rtl/backend/VMask.sv`：`vmask_pkg`（7 个 opcode 常量）+ 手写核 `xs_VMask_core`
  （§1 stage0 译码/有效掩码 vs2m/本 uop 元素范围；§2 stage1 sbf·sif·sof·first 与前缀 popcount，写 vd_reg；
  §3 stage2 按 vstart/vl/v0/ma/ta 拼输出）+ 手写 wrapper（16 个端口，不需生成器）。
- 寄存器按 Scala 名一一对应（s1 打拍 22 个、vd_reg、s2 打拍 18 个），vs2m_reg_s1 用 128 位向量；
  复位域照 golden：fire_reg_s1 不复位，其余异步复位到 0。
- 无子模块、无黑盒。

### 1.2 UT（verif/ut/VMask；3 seed × 3 initreg × 200k 拍）

逐拍比 io_out_vd（128 位）；opcode 7 个 × SEW 4 档每格 >= 1000 次 fire（写进 PASS 判据），
另有 vstart>=vl / vfirst 无 1 / viota·vid 奇偶 uop / ma / ta 各 >= 1000。结果与变异见文末对账。
复跑：`cd verif/ut/VMask && make run SEED=<1|7|42> INITREG=<0|random|<seed>017>`

### 1.3 跑前预测（★跑完不许改本节★，登记 docs/fm_predictions/VMask.json）

lane 内非正式试跑（commit 0455f4ad，`make fm-VMask`，vmucp 关）：native SUCCEEDED、passing 1027 / failing 0 /
unmatched 0(0)，Not Compared = Constant reg 1 + Unread 120 → strict PARTIAL。
1148 − 1027 = 121 = 120 + 1，全部可指认：
- Unread 120：全是 matched_nc，`vs1_reg_s1_reg[8..127]` 两侧同名配对。Scala 把 vs1 全宽打拍、只读 [7:0]，
  两侧同一批对称死位 → vmucp（`verif/fm_target_config/VMask.tcl`，本 commit 一并加入，Makefile 开 vmucp）。
- Constant reg 1：`ele_cnt_reg_s1[0]`（16>>vsew 恒偶），两侧都标常量。

| 项 | 预测（正式 run_proof，vmucp 开） |
|---|---|
| expected（模型） | 1148（regs 1020 + outs 128） |
| passing | **1147** |
| constant_reg | 1 |
| failing / unverified / aborted / unread_notcompared / unmatched | 0 / 0 / 0 / 0 / 0(0) |
| 黑盒 / dont_verify | 无 |
| verdict | SUCCEEDED（signoff-strict） |

### 1.4 可能出错的地方

1. vmucp 打开后若 passing 不是正好 +120，判红（空转或有额外点）。
2. 本节数字来自一次非正式试跑（上文），不是纯模型推算。

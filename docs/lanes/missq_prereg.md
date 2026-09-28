# DCache MissQueue lane（agent/missq）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `3992f2dd`（main，`git worktree add /home/eda/xs-env/wt-missq -b agent/missq main`） |
| 工作树 | `/home/eda/xs-env/wt-missq`，分支 `agent/missq` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | 叶子 `Arbiter16_MainPipeReq` → `CMOUnit` → `MissEntry`（×16 例化同一模块）→ 本体 `MissQueue` |
| child 状况 | `docs/coverage_three_axis.tsv`：四者全部 `MISSING/UNPROVEN`；golden MissQueue 的直接 child 只有这三种（16+1+1 实例），无其它子模块 |
| codex 冲突 | 查过 outbox 0176..0195 与 15 个 `codex/*` 分支 diff：无一触及本 lane 目标（codex 只在 Pmaaddr/CSR/算术叶子）。旧消息里的 `L2TlbMissQueue` 是 L2TLB 的另一个模块 |
| 口径 | 全部 `signoff-strict`，`FM_MERGE_DUP=false`（模型严格适用），allowlist 空，无 dont_verify |

## 1. Arbiter16_MainPipeReq（golden 842 行 / 272 端口，纯组合）

### 1.1 核与 golden 差异点

- 重写件 `rtl/memblock/Arbiter16_MainPipeReq.sv` = 薄文件，设参例化已签核共享核
  `rtl/frontend/xs_FixedPriorityArbiter_core.sv`（**未改动共享核**）。WIDTH=401，NUM_IN=16。
- 16 路字段集合完全相同（14 个字段），**没有常量字段**（与 Arbiter4 不同：MissEntry 的 miss/probe 常量
  在下游 Arbiter4 里才折叠）。端口表 + 逐路拼包由 `scripts/gen_missq.py` 生成（`--check` 已进 gate_all），
  生成时核对 golden 端口表 == 预期形状（16×16+2+14=272）。

### 1.2 UT（verif/ut/Arbiter16_MainPipeReq，gen.py 生成 tb；3 档 initreg × 3 seed × 200k，串行）

seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`, `+vcs+initreg+<seed>017`} 9/9
`checks=200000 errors=0 cov_fail=0` TEST PASSED（纯组合，initreg 不影响，照规矩跑满）。
覆盖（seed 1）：16 路各自胜出 34308 / 20869 / … / 4034（最少的第 15 路 4034 ≥ COV_MIN=1000）；
无人请求 55743；out_ready=0 100092；每个输出位见过 0 与 1。
tb 分辨力自测（20k 拍）：拼包下标 `k`→`k^1`（相邻两路互换）errors=250278；
`access` 输出或上 `evict_btot` errors=5052。

### 1.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/Arbiter16_MainPipeReq.json）

| 项 | 预测 |
|---|---|
| passing | **正好 418**（模型 = 0 寄存器 + 418 输出位 = 401 载荷 + out_valid + 16 根 in_ready） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0 |
| 黑盒 | 无 |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / false |

可能出错：无（纯组合、共享核已签核三次）。本节没有做过任何 FM 试跑。

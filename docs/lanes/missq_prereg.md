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

## 2. CMOUnit（golden 231 行 / 20 端口，无子模块）

### 2.1 核与 golden 差异点

- `rtl/memblock/CMOUnit.sv`：`xs_CMOUnit_core`（enum 四状态机 IDLE/SREQ/WRESP/LSQ_RESP + 锁存的请求 +
  denied/corrupt/no_pending + wfiSafe 打拍）+ golden 同名 wrapper（只改名）。`_GEN_`/`_T_` 0。
- 照 golden 端口表：nderr 寄存器 golden 已随 `resp_to_lsq.nderr/address` 输出一起被 DCE，核里不写；
  `req_address` 保留 64 位（Scala CMOReq 原宽），[63:48] 两侧对称死位 → vmucp
  （`verif/fm_target_config/CMOUnit.tcl`，16 对 FM 按名自动配上）。
- 复位域照 golden：state/denied/corrupt/no_pending/wfiSafe 异步复位；req_opcode/req_address 不复位。

### 2.2 UT（verif/ut/CMOUnit；3 档 initreg × 3 seed × 200k，串行）

9/9 `errors=0 cov_fail=0` TEST PASSED（checks=200059/200060/200071，含随机异步复位期间的比较）。
+random 下 req_address 两实例初值不同，tb 暖机＝复位后第一拍强制接一条请求再开比较窗口。
覆盖（seed 1）：req.fire 14546 / A.fire 14524 / D.fire 14504 / resp.fire 14499 / wfiReq 挡 A 39920 /
D 带 denied|corrupt 6390 / 非 WRESP 态来 D 被忽略 35531 / 异步复位 59 次；每个输出位见过 0 和 1
（A opcode 高两位结构恒 1，gen.py 显式豁免 toggle，仍逐位比较）。
tb 分辨力自测（20k 拍）：去掉 A.valid 的 wfiReq 门控 errors=15555；D 收下时不置 no_pending errors=5110；
接新请求不清 denied errors=3222；opcode 3 误映射成 Inval errors=2607。

### 2.3 跑前预测（★跑完不许改本节★，登记见 docs/fm_predictions/CMOUnit.json）

| 项 | 预测 |
|---|---|
| passing | **正好 132**（模型 = golden 寄存器 73 + 输出 59） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched 六项 | 全 0 |
| 黑盒 | 无 |
| mode / verdict / vmucp | signoff-strict / SUCCEEDED / true |

lane 内 diagnostic-full 试跑（dirty，未出 receipt）两次：vmucp 关 passing 116 + matched-unread 16；
vmucp 开 passing 132 / failing 0 / unmatched 0。可能出错：无已知风险。

---

# 对账（跑完追加；上文各节未改一字）

## A. Arbiter16_MainPipeReq

| 项 | 值 |
|---|---|
| proof commit | `bc1ed4b6f3f9`（预测登记在同一 commit，早于证明；RTL/UT 在其父 `38852b39`） |
| 证据 | `evidence/bc1ed4b6f3f9/Arbiter16_MainPipeReq/receipt.json` sha256 `c836ebed8a2787117f33e57bf26b93320d42cd2723d8b1c33cabb42c07b63dd4` |
| impl_closure | `rtl/memblock/Arbiter16_MainPipeReq.sv` `f7bf16c1abd39ee8d6839545a49e5d6fd6fd98500146b3f79835b5d819fd3ba3`；`rtl/frontend/xs_FixedPriorityArbiter_core.sv` `e7c8526c…a5618`（未改） |
| 结果 | native SUCCEEDED，passing **418** / failing 0 / unverified 0 / unread_notcompared 0 / unmatched 全 0 / 无黑盒 / signoff-strict / dirty false / fm.log 行首 `Error:` 0 |
| `fm_predict.py check` | 预期 418，实测 418，差 0，「全部对上」 |

复跑：`cd /home/eda/xs-env/wt-missq && PROOF_COMMIT=bc1ed4b6 bash scripts/run_proof.sh Arbiter16_MainPipeReq Arbiter16_MainPipeReq < /dev/null`

## B. CMOUnit

| 项 | 值 |
|---|---|
| proof commit | `f9f232674f20`（预测登记在同一 commit，早于证明；RTL/UT/vmucp 配置在其父 `a9d9f37e`） |
| 证据 | `evidence/f9f232674f20/CMOUnit/receipt.json` sha256 `6552e4431bc7f30ecc313fc64c663fe218a4a15b77f07d640d9398e44632fb17` |
| impl_closure | `rtl/memblock/CMOUnit.sv` `f42240ccf3b6956900de1a89a4e762a0589091dae0b36042b80546a401442b9a` |
| 结果 | native SUCCEEDED，passing **132** / failing 0 / unverified 0 / unread_notcompared 0 / unmatched 全 0 / 无黑盒 / signoff-strict / vmucp true / dirty false / fm.log 行首 `Error:` 0 |
| `fm_predict.py check` | 预期 132，实测 132，差 0，「全部对上」 |

复跑：`cd /home/eda/xs-env/wt-missq && PROOF_COMMIT=f9f23267 bash scripts/run_proof.sh CMOUnit CMOUnit < /dev/null`

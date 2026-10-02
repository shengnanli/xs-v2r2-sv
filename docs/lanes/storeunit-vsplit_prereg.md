# storeunit-vsplit lane（agent/storeunit-vsplit）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `eec71f5c`（集成者预建 worktree + 认领文件） |
| 工作树 | `/home/eda/xs-env/wt-storeunit-vsplit`，分支 `agent/storeunit-vsplit` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标（按序） | `MemTrigger_3` → `StoreUnit` → `VSSplit*`/`VLSplit*` → `VSegmentTrigger`/`VSegmentUnit` |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. MemTrigger_3（golden 338 行，纯组合，无寄存器，无子模块）

### 1.1 核（★改了共享核★）

`rtl/memblock/MemTrigger.sv` 的 `xs_MemTrigger_core` 加 `isCbo` 输入与缓存行比较一支（`cboHit`），
端口 `load` 改名 `rwEnable`；LOAD wrapper（`MemTrigger`）把 `isCbo` 钉 0，逻辑锥不变。
新薄文件 `rtl/memblock/MemTrigger_3.sv`（STORE wrapper：`isPrf` 钉 0，`triggerMask` 悬空）。

`python3 scripts/check_shared_impl_impact.py --file rtl/memblock/MemTrigger.sv` ⇒ 受影响 2 个已签目标：
`MemTrigger`、`LoadUnit`，本 lane 一并重证（预测照搬它们原登记：70 / 18749，不应变）。

### 1.2 UT（跑前已跑）

verif/ut/MemTrigger_3：seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`, `+vcs+initreg+<seed>017`}
= 9/9 `checks=200000 errors=0 uncovered=0`。覆盖桶：每触发器 标量/向量/canFire/链上触发/被选中 ≥1，
cboHit × {EQ,GE,LT} 各 ≥1，三种 action 各 ≥1。
变异体（cbo GE 支 `cacheLineLast`→`cacheLineBase`）：20k 拍 `errors=478` 被抓。
回归 verif/ut/MemTrigger seed 7 两档 `errors=0`，compile.log AOUP=0。

### 1.3 跑前预测（★跑完不许改★）

| 项 | MemTrigger_3 | MemTrigger（重证） | LoadUnit（重证） |
|---|---|---|---|
| passing | **正好 54**（0 寄存器 + 输出 4+50） | 正好 70 | 正好 18749 |
| failing / unverified / aborted / unread_notcompared | 0/0/0/0 | 0/0/0/0 | 0/0/0/0 |
| unmatched | 全 0 | 全 0 | 全 0 |
| 黑盒 | 无 | 无 | 无 |
| verdict | signoff-strict SUCCEEDED | 同 | 同（vmucp=true，constant_reg 11） |

可能出错：核的 `triggerMask` 输出在 MemTrigger_3 里悬空——它是组合输出不是寄存器，不应产生
impl-only 比较点；若 FM 报 impl 侧 unread/unmatched，就把 mask 输出挂参数关掉。

## 对账（跑后追加，不改上面任何数字）

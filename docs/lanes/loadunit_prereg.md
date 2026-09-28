# LoadUnit lane（agent/loadunit）—— 跑前登记

本文件在每个目标 **FM 起跑之前**提交对应分节；跑完在文末「对账」追加，
★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | `975b64e6`（main，`git worktree add /home/eda/xs-env/wt-loadunit -b agent/loadunit 975b64e6`） |
| 工作树 | `/home/eda/xs-env/wt-loadunit`，分支 `agent/loadunit` |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl`（只读） |
| 目标 | `MemTrigger`（LoadUnit 唯一 child，先做）→ `LoadUnit` |
| 变体 | golden 只有一个 `LoadUnit`（MemBlock 里 inner_LoadUnit_0/1/2 三个实例同一模块）；`MemTrigger_3` 属 StoreUnit，不在本 lane |
| 口径 | `signoff-strict`，`FM_MERGE_DUP=false`，allowlist 空，无 dont_verify |

## 1. MemTrigger（golden 284 行，纯组合，无寄存器，无子模块）

### 1.1 核

`rtl/memblock/MemTrigger.sv`：`xs_MemTrigger_core`（4 触发器数组化：标量/向量命中 → 链 →
动作仲裁 → 最小编号回报）+ golden 同名 wrapper（手写打包，43 端口）。

### 1.2 UT（跑前已跑，两档 × 3 seed × 200k）

verif/ut/MemTrigger：seed 1/7/42 × {`+vcs+initreg+0`, `+vcs+initreg+random`} = 6/6
`checks=200000 errors=0`、`uncovered=0` TEST PASSED。GE→GT 变异体 20k 拍内被抓住。

### 1.3 跑前预测（★跑完不许改★）

| 项 | 预测 |
|---|---|
| passing | **正好 70**（模型 = 0 寄存器 + 70 输出位：4+50+16） |
| failing / unverified / aborted / unread_notcompared | 0 / 0 / 0 / 0 |
| unmatched | 全 0（纯组合，只有端口） |
| 黑盒 | 无 |
| mode / verdict | signoff-strict / SUCCEEDED |

可能出错的地方：无寄存器、无常量折叠点，模型不应有差额；若有差额只能来自输出位被 FM 判常量，
receipt 里应能指认。

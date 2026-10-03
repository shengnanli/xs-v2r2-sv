# DCache 本体 lane（agent/dcachebody）—— 跑前登记

本文件在 FM 正式起跑**之前**提交；跑完在文末「对账」追加，★不修改已提交分节的任何数字★。

## 0. 输入

| 项 | 值 |
|---|---|
| 基线 commit | main `d5564588`（`git worktree add /home/eda/xs-env/wt-dcachebody -b agent/dcachebody main`） |
| 冲突检查 | codex outbox 最新 0205（next-20 叶子）/ 0204 / 0199（BankedDataArray 裁定）；codex/* 与 kimi/* 分支均未碰 DCache 及其子树 |
| golden | `/home/eda/xs-env/G1-canonical/golden-rtl/DCache.sv`（23,854 行 / 627 端口 / 376 寄存器 1716 位，只读） |
| 目标 | `DCache`（assembly 口径：两侧白盒整棵子树，唯一黑盒是审定的厂商 SRAM 叶子） |
| Scala | `src/main/scala/xiangshan/cache/dcache/DCacheWrapper.scala` class DCacheImp |

## 1. 结构与子模块处置

- 可读核 `rtl/memblock/DCache.sv`：`dcache_pkg`（常量 / TileLink opcode / 树形 PLRU 两个函数）+
  `xs_DCache_core`（手写，按通道分节 §1 D 通道 / §2 B 通道 / §3 L2 提示 / §4 阵列口胶水 / §5 256×4 路 PLRU /
  §6 MainPipe 回应打拍 / §7 错误上报 / §8 预取统计 / §9 性能事件）+ golden 同名 wrapper。
- wrapper 的端口表、40 个子模块实例（实例名 / 端口顺序同 golden）、核例化、输出 assign 全部由
  `scripts/gen_dcache.py --check` 从 golden 机械生成；规则 fail-closed（每个子模块端口恰好命中一条：
  本层端口 / 子模块输出线 / `/* unused */` / GLUE_IN 表；GLUE_IN / GLUE_OUT 表逐字记 golden 表达式，漂了即失败）。
  `_GEN_`/`_T_` = 0。
- 寄存器全部 SoA（`plru_state[256]`、`perf_q1/q2[40]`、`err_src_*[4]`、`fwd_d_beat_cnt[3]`），
  1716 位与 golden 逐位一一对应（钉点见 §3）。
- 子模块（22 类 / 40 实例）：查 `docs/coverage_three_axis.tsv`，除 StorePipe / FDPrefetcherMonitor 外全部
  `PROVEN_DIRECT`；闭包里的 Arbiter8_MainPipeReq / ProbeEntry / WritebackEntry / WritebackEntry_15 是
  `GOLDEN_REUSE/PROVEN_IN_CONE`（两侧同一份 golden 文件）。处置 = **两侧白盒**：ref 读 golden 闭包 53 个文件
  （`FM_REF_DEPS_DCache`，字面文件名），impl 读重写件（`RTL_GOLDEN_DEPS`）。
- **StorePipe ×2 / FDPrefetcherMonitor**：golden 本配置下 0 输出、0 寄存器（StorePipe 是已知
  EXPLICITLY_UNPROVABLE 死码 stub，`docs/fm_predictions/StorePipe.json`；FDPrefetcherMonitor 已有端口壳重写
  + portlint）。两侧照 golden 例化、照 golden 接线，**不产生任何比较点**；没有为它们加黑盒、没有 dont_verify。
- **黑盒**：只有厂商 SRAM 叶子 `array_7_ext` ×32（BankedDataArray 内）与 `array_8_ext` ×8（DuplicatedTagArray 内），
  不进 FM 源（unresolved = 黑盒）。`verif/allow/DCache.json` 由生成器从两个子模块已审定的 allow 文件逐条收割、
  路径换到 `DCache/<实例名>/` 之下；按 codex 0199 只收子模块顶层之下的实例（辅助 design root 不收），
  字面计数每侧 32 + 8。

## 2. UT（verif/ut/DCache）

双例化 golden `DCache` vs `DCache_xs`，两侧例化同一份子模块重写件，只比本层；逐拍比全部 219 个输出口。
激励：30 行地址池（6 set × 5 tag，> 4 路 → 反复替换写回）、3 条 load 流水、store、原子（LR 加权）、CMO、
L2 模型（Acquire→GrantData/Grant/CBOAck，Release→ReleaseAck，偶发 Probe / denied / corrupt / 非法 opcode 噪声）、
CtrlUnit 伪 ECC 注入。胶水事件覆盖闸见 tb 末尾。
初值档：`0`（全设计 +vcs+initreg+0，全比）、`glue` / `glue017`（`+vcs+initreg+config`：子模块 0、两侧本层随机，
种子 = SEED / SEED017）。**不用全设计 `+vcs+initreg+random`**：子模块两侧同码、各摇各的初值（含 SRAM 阵列内容），
比出来的只是初值噪声（L2TLB lane 实测）；glue 档的本层随机已由 tb 的 `[INITREG]` 行自证（两侧不同、跨种子不同）。
结果见文末对账（跑完追加）。

## 3. FM 钉点（verif/ut/DCache/fm_pins_pre.tcl，gen_dcache.py 生成）

组成：本层胶水 1716（golden 寄存器表逐位、单射、位宽核对）+ 子模块签核时自己的钉点原样收割
（cacheCtrlOpt 1040 / bankedDataArray 4683 / mainPipe 16 / missQueue 4174），合计 11629；fail-closed 计数。
签核时无钉点文件的子模块逐个列在 `CHILD_NO_PINS`，生成器核对它们的 UT 目录里确实没有钉点文件。

## 4. 跑前预测（★跑完不许改本节★）

（本节在 diagnostic 试跑之后、正式 run_proof 之前填写并提交。）

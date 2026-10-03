# agent/newrtl-next20c lane —— 预登记：第四批 20 个可读 CSR 叶目标

基线：xs-v2-sv `main` @ `2787eb13`；worktree `/home/eda/xs-env/wt-newrtl-next20c`；
分支 `agent/newrtl-next20c`。本批排除 Kimi k3next30、Claude/Codex 在途认领、
newrtl-next20 已完成 20 个、newrtl-next20b 已完成 20 个；以下目标逐名核对均
`in_universe=yes`、coverage `MISSING/UNPROVEN`，且无子模块。

## 所有权排除

对冻结 coverage 中 708 个 MISSING/UNPROVEN 名字，对
`.agent-bridge/inbox+outbox` 及所有 worktree `docs/lanes/*.md` 做 `rg -wF` 全量
扫描；命中者全部排除（含历史 G0 提及，从保守处理）。另显式排除前两批 40 个
目标以及 Kimi k3next30 全部 30 个目标。本批 20 个均无命中、无现有正式可读 RTL。
父模块均为未认领的 NewCSR，不修改共享生成器或其他 Agent 文件。

## 精确目标清单（三族）

### 族 H —— PMA 配置 CSR 变体（8），UT `PmaCfgLeaves8`

| # | 模块 | golden 行数 | 子模块 | 预计解锁 |
|---|---|---:|---|---|
| 1 | Pma0cfgModule | 176 | 无 | NewCSR |
| 2 | Pma1cfgModule | 176 | 无 | NewCSR |
| 3 | Pma2cfgModule | 176 | 无 | NewCSR |
| 4 | Pma3cfgModule | 176 | 无 | NewCSR |
| 5 | Pma4cfgModule | 176 | 无 | NewCSR |
| 6 | Pma5cfgModule | 176 | 无 | NewCSR |
| 7 | Pma6cfgModule | 176 | 无 | NewCSR |
| 8 | Pma7cfgModule | 176 | 无 | NewCSR |

同构 PMA cfg 寄存器：共享参数化核 + 8 个薄 wrapper，字段 WARL/锁定行为逐位
按 golden 保留。

### 族 I —— PMP 配置 CSR 变体（8），UT `PmpCfgLeaves8`

| # | 模块 | golden 行数 | 子模块 | 预计解锁 |
|---|---|---:|---|---|
| 9 | Pmp5cfgModule | 160 | 无 | NewCSR |
| 10 | Pmp6cfgModule | 160 | 无 | NewCSR |
| 11 | Pmp7cfgModule | 160 | 无 | NewCSR |
| 12 | Pmp8cfgModule | 160 | 无 | NewCSR |
| 13 | Pmp9cfgModule | 160 | 无 | NewCSR |
| 14 | Pmp10cfgModule | 160 | 无 | NewCSR |
| 15 | Pmp11cfgModule | 160 | 无 | NewCSR |
| 16 | Pmp12cfgModule | 160 | 无 | NewCSR |

与上一批 Pmp0–4cfgModule 结构同构，但本 worktree 从 main 独立创建；本批只新增
5–12 变体，核体与 wrapper 仍按参数化家族表达，禁止复制近似逻辑。

### 族 J —— HPM 计数器 CSR 变体（4），UT `HpmcounterLeaves4`

| # | 模块 | golden 行数 | 子模块 | 预计解锁 |
|---|---|---:|---|---|
| 17 | Hpmcounter3Module | 127 | 无 | NewCSR |
| 18 | Hpmcounter4Module | 127 | 无 | NewCSR |
| 19 | Hpmcounter5Module | 127 | 无 | NewCSR |
| 20 | Hpmcounter6Module | 127 | 无 | NewCSR |

同构 HPM 计数器：共享参数化计数/软件写/抑制核 + 4 个薄 wrapper；复位、写优先级、
抑制和每周期增量必须逐位对齐 golden。

## 验收

- 三族 generator `--check` 幂等；portlint 20/20。
- 双例化差分 UT：6 seeds（1/7/42/100/2026/31337），每 seed ≥200000 拍，errors=0。
- official detached-clean-worktree Formality signoff-strict：20/20 native SUCCEEDED，
  failing/unverified/aborted/unread/unmatched/非必要 blackbox/dont_verify 全零。
- prereg、实现/UT、evidence 分离提交；目标不静默替换；最终工作树 clean。

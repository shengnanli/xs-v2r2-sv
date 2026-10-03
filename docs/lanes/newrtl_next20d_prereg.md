# agent/newrtl-next20d lane —— 预登记：第五批 20 个可读 CSR 叶目标

基线：xs-v2-sv `main` @ `d5564588`；worktree `/home/eda/xs-env/wt-newrtl-next20d`；
分支 `agent/newrtl-next20d`。

本批 20 个目标逐名核对 `in_universe=yes`、coverage `MISSING/UNPROVEN`、无子模块，
父模块均为未认领的 NewCSR。对 `.agent-bridge/inbox+outbox` 及所有 worktree 的
`docs/lanes/*.md` 对 632 个 MISSING/UNPROVEN 名称执行 `rg -wF` 全量所有权扫描；
排除了 Kimi k3next30、Claude/Codex active lane、前四批已登记/完成的 80 个目标。
本批无重叠、无共享核或生成器冲突。

## 精确目标清单（三族）

### 族 K —— PMA 配置 CSR 变体（8），UT `PmaCfgLeaves8b`

| # | 模块 | golden 行数 | 子模块 | 预计解锁 |
|---|---|---:|---|---|
| 1 | Pma8cfgModule | 176 | 无 | NewCSR |
| 2 | Pma9cfgModule | 176 | 无 | NewCSR |
| 3 | Pma10cfgModule | 176 | 无 | NewCSR |
| 4 | Pma11cfgModule | 176 | 无 | NewCSR |
| 5 | Pma12cfgModule | 176 | 无 | NewCSR |
| 6 | Pma13cfgModule | 176 | 无 | NewCSR |
| 7 | Pma14cfgModule | 176 | 无 | NewCSR |
| 8 | Pma15cfgModule | 176 | 无 | NewCSR |

同构 PMA cfg 家族：一个参数化可读核 + 8 个薄 wrapper，保持字段 WARL、锁定字段
和异步复位行为与 golden 完全一致。

### 族 L —— PMP 配置 CSR 变体（8），UT `PmpCfgLeaves8b`

| # | 模块 | golden 行数 | 子模块 | 预计解锁 |
|---|---|---:|---|---|
| 9 | Pmp13cfgModule | 160 | 无 | NewCSR |
| 10 | Pmp14cfgModule | 160 | 无 | NewCSR |
| 11 | Pmp15cfgModule | 160 | 无 | NewCSR |
| 12 | Pmp16cfgModule | 160 | 无 | NewCSR |
| 13 | Pmp17cfgModule | 160 | 无 | NewCSR |
| 14 | Pmp18cfgModule | 160 | 无 | NewCSR |
| 15 | Pmp19cfgModule | 160 | 无 | NewCSR |
| 16 | Pmp20cfgModule | 160 | 无 | NewCSR |

同构 PMP cfg 家族：一个参数化可读核 + 8 个薄 wrapper；R/W/X/A/L 字段、保留组合
和 WARL 语义逐位对齐 golden。

### 族 M —— HPM 计数器 CSR 变体（4），UT `HpmcounterLeaves4b`

| # | 模块 | golden 行数 | 子模块 | 预计解锁 |
|---|---|---:|---|---|
| 17 | Hpmcounter7Module | 127 | 无 | NewCSR |
| 18 | Hpmcounter8Module | 127 | 无 | NewCSR |
| 19 | Hpmcounter9Module | 127 | 无 | NewCSR |
| 20 | Hpmcounter10Module | 127 | 无 | NewCSR |

同构 HPM 家族：一个参数化计数/停止/软件写核 + 4 个薄 wrapper，保留 reset、更新
优先级、debug stop 和 live counter mux 语义。

## 验收

- 三族 generator `--check` 幂等；portlint 20/20。
- 双例化差分 UT：seed 1/7/42/100/2026/31337，每 seed ≥200000 周期，errors=0。
- official detached-clean-worktree Formality signoff-strict：20/20 native SUCCEEDED，
  failing/unverified/aborted/unread/unmatched/非必要 blackbox/dont_verify 全零。
- prereg、实现/UT、evidence 分离提交；目标不静默替换；最终工作树 clean。

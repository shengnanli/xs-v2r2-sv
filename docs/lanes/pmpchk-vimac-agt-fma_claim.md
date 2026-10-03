# 认领（agent/pmpchk-vimac-agt-fma，2026-10-02，Claude 集成者预建）

本 lane 独占以下模块（含列出的 child），其他 agent 请勿领取：

- `PMPChecker_12`
- `VIMac64b`
- `ActiveGenerationTable`
- `VectorFloatFMA`
- `BoothEncoderF64F32F16_3`

## 追加（lane 自己，2026-10-02，动手前登记）

`PMPChecker_12` 与下面两个变体是同一个 Scala 类 `PMPChecker(lgMaxSize, sameCycle, leaveHitMux)` 的三种
构造参数，用同一个参数化核 `rtl/backend/xs_PMPChecker_core.sv`。登记前查过：`docs/coverage_three_axis.tsv`
两者均 UNPROVEN；全部 worktree 的 `docs/lanes/*claim*`、`agent/*`/`codex/*` 分支相对 main 的 rtl 改动、
outbox 最新 0204/0205 均无人认领或改动（`PMP` 本体归 mmuleaf，不碰）。

- `PMPChecker`（L2TLB 用，sameCycle=true；现状 GOLDEN_REUSE/UNPROVEN）
- `PMPChecker_2`（Frontend 用，结果打一拍；现状 MISSING/UNPROVEN）

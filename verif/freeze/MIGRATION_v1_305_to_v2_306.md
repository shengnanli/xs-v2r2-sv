# FM 目标锚点迁移: freeze-v1-305 → freeze-v2-306

## 为何从 305 扩展到 306
Rob(ReorderBuffer, 160条目/8bank)是整个 FM 签核 campaign 的终极 blocker。其 golden
规模(220K 行/3234 端口)使 monolithic strict FM 无法在资源内收敛。故采用 **cone-DCE
partitioned proof**: 把 Rob 的 2343 authored 输出分解为 5 个 canonical 分区
(commit/exception/perf/vecexcp/lsq), 每分区独立 native FM SUCCEEDED RC0, 再由独立
union verifier 证明 5 分区覆盖全 2343 输出(total+disjoint+input-parity+no-drift),
配 16161 completion pin(全 passing)与 co-sim 1/7/42(errors=0)。

Rob 原先在 v1 manifest 中为 UNCONFIGURED(未配置为标准 runner 目标), 故不在冻结
305 锚点内。现 Rob 由 partitioned proof 达成 PARTITIONED_SUCCEEDED, 应计入最终
RTL/FM 覆盖分母 → 建立版本化 306 锚点。

## 版本化(不改写历史 v1)
- **freeze-v1-305** = `verif/freeze/fm_targets.tsv` —— **原样保留不动**(305 目标)。
  historical reconcile: 冻结305 / CONFIGURED305 / Rob UNCONFIGURED / DIFF=0
  (见 reconcile_v1_305_record.txt)。
- **freeze-v2-306** = `verif/freeze/fm_targets_v2_306.tsv` —— v1 精确副本 + 唯一新增
  `Rob\tpartitioned-union\tRob\tpartitioned`。
- **manifest v2** = `scripts/sidecar/manifest_306_v2.json` (schema fm-signoff-manifest-v2-306,
  anchor_ref=freeze-v2-306)。Rob entry: config_status=CONFIGURED, proof_mode=partitioned,
  required_verdict=PARTITIONED_SUCCEEDED, derivative_id=union_record sha
  ca4d1959c9f20144cc99a685f8681fb9a883e6a8747270d736aaaa93e1e1a367, impl_commit 7babaa3c。
  v2 reconcile: 冻结306 / CONFIGURED306 / UNCONFIGURED0 / DIFF=0
  (见 reconcile_v2_306_record.txt)。
- manifest_305.json(v1) 保留不改(Rob 仍 UNCONFIGURED, 对 fm_targets.tsv 305 reconcile DIFF=0)。

## Rob 签核类型: partitioned(非 monolithic)
Rob 明确为 PARTITIONED_SUCCEEDED, 绝不标为 monolithic SUCCEEDED。证据:
- UNION_RECORD.tsv(sha ca4d1959...) + BINDING_MANIFEST.tsv, 存
  `scripts/sidecar/signoff-evidence-partitioned/Rob/`。
- 5 分区 part.{commit,exception,perf,vecexcp,lsq} 全 RC=0 SUCCEEDED; union 覆盖 2343 outputs。
- completion pins manifest sha b62fc181; co-sim receipt seed1/7/42 checks=199959 errors=0。
- impl provenance: 分支 agent/rob-perf-cone @ 7babaa3c(clean tree)。

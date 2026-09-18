#!/usr/bin/env bash
# 台账重算 —— **顺序是有依赖的，别自己排**
#
# 为什么要有这个脚本
# ------------------
# 五个台账生成器彼此有输入依赖。2026-09-18 我按"随手想到的顺序"串行重算，
# 结果 rewrite_coverage.py 刚写完、--check 立刻就红，一度被当成"生成器不幂等"。
# 实际是**顺序错了**：中间跑的 harvest_round_ledger.py 改写了 docs/fm_round_*.tsv，
# 而那正是 rewrite_coverage.py 判"已证"的证据源（rewrite_coverage.py:133 glob 它）。
# 前一份读的是旧的 round 台账，少算了两个目标 92060 行。
#
# 依赖图（实测，grep 各生成器读的 docs/ 输入得来）
# ------------------------------------------------
#   harvest_round_ledger  ──写──>  docs/fm_round_*.tsv  ──读──>  rewrite_coverage
#   hier_map              ──写──>  docs/hier_rebind_map.tsv  ──读──>  perf_rebind
#   perf_rebind           ──写──>  docs/perf_bore_map.tsv    ──读──>  perf_tier
#   check_perf_tier 是纯校验器，不生成，放最后
#
# 必须串行：上一轮并发改同一批表踩过坑。
#
# 用法: bash scripts/recompute_ledgers.sh
set -u
cd "$(dirname "$0")/.."
rc=0

step() {  # step <说明> <命令...>
  echo "=== $1 ==="
  shift
  if ! "$@"; then echo "  ★失败★: $*" >&2; rc=1; fi
}

# ---- 第一层：无 docs/ 输入，可以最先跑 ----
step "round 台账（rewrite_coverage 的证据源）" python3 scripts/harvest_round_ledger.py --out docs/fm_round_20260917.tsv
step "层次重绑映射（perf 链的输入）"           python3 scripts/hier_map.py

# ---- 第二层：依赖第一层 ----
step "perf bore 重绑（读 hier_rebind_map）"    python3 scripts/perf_rebind.py
step "重写覆盖（读 fm_round_*）"               python3 scripts/rewrite_coverage.py

# ---- 第三层：依赖第二层 ----
step "perf 分档台账（读 perf_bore_map）"       python3 scripts/perf_tier.py

echo
echo "=== 逐条复核 ==="
for c in "harvest_round_ledger.py --check --out docs/fm_round_20260917.tsv" \
         "hier_map.py --check" \
         "perf_rebind.py --check" \
         "rewrite_coverage.py --check" \
         "perf_tier.py --check" \
         "check_perf_tier.py"; do
  printf "  %-58s " "$c"
  # shellcheck disable=SC2086
  if python3 scripts/$c >/dev/null 2>&1; then echo PASS; else echo FAIL; rc=1; fi
done

exit $rc

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
# ★2026-09-18 补：这一条本来漏了★
# 漏的后果是真发生过的：d15abdb 那次重算之后 check_coverage_provenance 判据 C 红了
# （9 个 top 有通过 receipt 但 coverage 表里没记 PROVEN_DIRECT），而那次的 commit message
# 写的是"六条闸全绿"—— 那是**本脚本复核清单的六条**，不是 gate_all 的全套。
# 子集口径被当成全套口径，正是本轮反复在补的那个洞，这次发生在闸的计数上。
# coverage_three_axis 只读 universe 与 evidence/，不依赖其他台账的产物，故放第一层。
step "三轴覆盖（证据链闸守的那张表）"          python3 scripts/coverage_three_axis.py

# ---- 第二层：依赖第一层 ----
step "perf bore 重绑（读 hier_rebind_map）"    python3 scripts/perf_rebind.py
step "重写覆盖（读 fm_round_*）"               python3 scripts/rewrite_coverage.py

# ---- 第三层：依赖第二层 ----
step "perf 分档台账（读 perf_bore_map）"       python3 scripts/perf_tier.py

echo
# ★复核清单必须与 gate_all.sh 里的台账类闸保持同步★
# 注意 coverage_three_axis.py **没有 --check 参数**（只有 --universe）——
# 我第一版照着另外五个生成器的接口想当然加了一行 `coverage_three_axis.py --check`，
# 那行永远 FAIL（argparse 直接报 unrecognized arguments）。
# 那张表的新鲜度由 check_coverage_provenance 的判据 B（表头分母 == universe 的
# in_universe=yes）与判据 C（有通过 receipt 的必须已记账）共同守着，够用，
# 所以这里只列它，不列一个不存在的 --check。
# 少列一条，就会出现"本脚本全绿但 gate_all 红"——d15abdb 就是这么发生的。
echo "=== 逐条复核 ==="
for c in "harvest_round_ledger.py --check --out docs/fm_round_20260917.tsv" \
         "hier_map.py --check" \
         "perf_rebind.py --check" \
         "rewrite_coverage.py --check" \
         "perf_tier.py --check" \
         "check_coverage_provenance.py --strict" \
         "check_perf_tier.py"; do
  printf "  %-58s " "$c"
  # shellcheck disable=SC2086
  if python3 scripts/$c >/dev/null 2>&1; then echo PASS; else echo FAIL; rc=1; fi
done

# ★终止标记：只有走到脚本结尾才可能打印这一行★（2026-09-20）
# 判读方只认这一行；没有 LEDGER_RC= 就是「结果不存在」，既不是绿也不是红。
# 与 scripts/gate_all.sh 的 GATE_RC= 同源，见 CONVENTIONS.md
# ★"闸跑完了没有"本身也要有判据★
#
# ★补记两个坑，都是加这一行时现踩的★
# 1) 上次想加没加成：当时这个脚本正在执行，而 bash 按**字节偏移**边读边执行脚本文件，
#    改运行中的脚本会让它从错误的位置继续。这类编辑必须先确认它没在跑。
# 2) 于是写了道 `pgrep -f recompute_ledgers.sh` 的守卫，它**匹配到了自己**：
#    检查命令自己的 cmdline 里就含这个字符串，于是永远报「在跑」、永远不敢改。
#    换 `$$` 排除也没用——外层 bash -c 包装是另一个 PID，cmdline 里同样含那串字。
#    最后按 **argv 精确匹配**（argv[0] 是 bash/sh 且 basename(argv[1]) 等于脚本名）
#    并排除自身进程链才对。★守卫也会有假阳性；加守卫时要连它自己一起验一遍。★
echo "LEDGER_RC=$rc"
exit $rc

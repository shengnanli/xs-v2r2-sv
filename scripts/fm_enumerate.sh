#!/usr/bin/env bash
# 权威 FM target 枚举器(2026-07 签核基础设施)。
# 通过向每个 Makefile 注入打印目标来**展开** FM_VARIANTS(含多行续行/嵌套变量/SRAM·Pipeline
# 多变体),而非按目录名 glob(那样会漏 49 个多变体, 得到错误的 228)。
# 输出 TSV: dir<TAB>makefile<TAB>variant<TAB>kind   到 stdout。
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 去重键 (dir|variant):同一 (目录,变体) 可能被多个 Makefile*(如 Makefile + Makefile.sched)
# 各枚举一次,应算**一个** proof target(否则 305→306 虚高)。LC_ALL=C 稳定排序。
declare -A SEEN
{
for mk in "$ROOT"/verif/ut/*/Makefile*; do
  [ -f "$mk" ] || continue
  d=$(dirname "$mk"); m=$(basename "$d"); mkf=$(basename "$mk")
  out=$(printf '__pv:\n\t@echo "VARS:$(FM_VARIANTS)"\n\t@echo "BB:$(FM_BB_TARGET)"\ninclude %s\n' "$mkf" \
        | timeout 30 make -C "$d" -f - __pv 2>/dev/null)
  vars=$(echo "$out" | sed -n 's/^VARS://p')
  bb=$(echo "$out"   | sed -n 's/^BB://p')
  hascustom=$(grep -qE "^fm:" "$d/$mkf" && echo yes)
  emit() {  # dir makefile variant kind
    local key="$1|$3"
    [ -n "${SEEN[$key]:-}" ] && return
    SEEN[$key]=1
    printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4"
  }
  if [ -n "$(echo $vars)" ]; then
    for v in $vars; do emit "$m" "$mkf" "$v" variant; done
  elif [ -n "$(echo $bb)" ] || grep -qE "^fmbb:" "$d/$mkf"; then
    emit "$m" "$mkf" "$m" fmbb
  elif [ -n "$hascustom" ]; then
    emit "$m" "$mkf" "$m" custom
  fi
done
} | LC_ALL=C sort

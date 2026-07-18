#!/usr/bin/env bash
# 权威 FM target 枚举器(2026-07 签核基础设施)。
# 通过向每个 Makefile 注入打印目标来**展开** FM_VARIANTS(含多行续行/嵌套变量/SRAM·Pipeline
# 多变体),而非按目录名 glob(那样会漏 49 个多变体, 得到错误的 228)。
# 输出 TSV: dir<TAB>makefile<TAB>variant<TAB>kind   到 stdout。
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for mk in "$ROOT"/verif/ut/*/Makefile*; do
  [ -f "$mk" ] || continue
  d=$(dirname "$mk"); m=$(basename "$d"); mkf=$(basename "$mk")
  out=$(printf '__pv:\n\t@echo "VARS:$(FM_VARIANTS)"\n\t@echo "BB:$(FM_BB_TARGET)"\ninclude %s\n' "$mkf" \
        | timeout 30 make -C "$d" -f - __pv 2>/dev/null)
  vars=$(echo "$out" | sed -n 's/^VARS://p')
  bb=$(echo "$out"   | sed -n 's/^BB://p')
  hascustom=$(grep -qE "^fm:" "$d/$mkf" && echo yes)
  if [ -n "$(echo $vars)" ]; then
    for v in $vars; do printf '%s\t%s\t%s\tvariant\n' "$m" "$mkf" "$v"; done
  elif [ -n "$(echo $bb)" ] || grep -qE "^fmbb:" "$d/$mkf"; then
    printf '%s\t%s\t%s\tfmbb\n' "$m" "$mkf" "$m"
  elif [ -n "$hascustom" ]; then
    printf '%s\t%s\t%s\tcustom\n' "$m" "$mkf" "$m"
  fi
done

#!/usr/bin/env bash
# FM 全貌重跑驱动(FM 审计 2026-07)—— 对指定模块用 scripts/fm_eq_full.tcl 重跑,
# 获得 failing 全貌(limit 调大, 不再被默认 20 截断)。
#
# 不改任何共享脚本: 用 `make -n fm` 提取各模块 Makefile 将执行的 fm_shell 命令,
# 把 tcl 换成 fm_eq_full.tcl、日志写 fm_full.log、work_path 加 _full 后缀,
# 历史 fm.log / fm_work/<var>/ 原样保留。
#
# 用法: scripts/fm_rerun_full.sh <verif/ut 下模块目录名>...
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for M in "$@"; do
  d="$ROOT/verif/ut/$M"
  [ -d "$d" ] || { echo "[$M] SKIP: 无 verif/ut/$M"; continue; }
  cd "$d" || continue
  # 提取 make fm 将执行的 fm_shell 命令(可能多个变体, 每变体一行)
  # recipe 用反斜杠续行, 先合并成单行再取含 fm_shell 的完整命令
  make -n fm 2>/dev/null | sed -e ':a' -e '/\\$/{N;s/\\\n//;ba}' | grep "fm_shell" | while IFS= read -r cmd; do
    var=$(echo "$cmd" | grep -oE 'work_path fm_work/[^ ]+' | head -1 | cut -d/ -f2)
    [ -z "$var" ] && { echo "[$M] SKIP: 解析不到变体名"; continue; }
    mkdir -p "fm_work/$var"
    new=$(echo "$cmd" \
      | sed -e "s|scripts/fm_eq.tcl|scripts/fm_eq_full.tcl|g" \
            -e "s|fm_work/$var/fm.log|fm_work/$var/fm_full.log|g" \
            -e "s|-work_path fm_work/$var |-work_path fm_work/${var}_full |")
    pin=""
    [ -f "$d/fm_pins_pre.tcl" ] && pin="FM_PIN_PRE_TCL=$d/fm_pins_pre.tcl "
    [ -f "$d/fm_pins.tcl" ] && pin="${pin}FM_PIN_TCL=$d/fm_pins.tcl "
    echo "[$M/$var] running (full-limit)${pin:+ +pins}..."
    bash -c "$pin$new" >/dev/null 2>&1
    log="fm_work/$var/fm_full.log"
    r=$(grep -oE "FM_RESULT: Verification (SUCCEEDED|FAILED)" "$log" 2>/dev/null | tail -1 | awk '{print $3}')
    f=$(tac "$log" 2>/dev/null | grep -m1 -oE "[0-9]+ Failing compare points" | awk '{print $1}')
    u=$(tac "$log" 2>/dev/null | grep -m1 -oE "[0-9]+ Unverified compare points" | awk '{print $1}')
    p=$(tac "$log" 2>/dev/null | grep -m1 -oE "[0-9]+ Passing compare points" | awk '{print $1}')
    echo "RESULT $M/$var ${r:-NO_RESULT} passing=${p:-?} failing=${f:-?} unverified=${u:-?}"
  done
done

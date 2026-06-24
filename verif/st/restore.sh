#!/usr/bin/env bash
# =============================================================================
# restore.sh —— 还原被 substitute.sh 替换的 golden RTL。
#   把 $NOOP_HOME/build/rtl/<M>.sv.golden 还原回 <M>.sv, 删除备份。
#
# 用法:
#   verif/st/restore.sh <模块名>      # 还原单个模块
#   verif/st/restore.sh --all         # 还原所有存在 .golden 备份的模块
#   verif/st/restore.sh --list        # 只列出当前被替换(有 .golden 备份)的模块
# =============================================================================
set -euo pipefail

NOOP_HOME="${NOOP_HOME:-/home/eda/xs-env/XiangShan}"
BUILD_RTL="$NOOP_HOME/build/rtl"
log() { echo "[restore] $*" >&2; }
die() { echo "[restore] ERROR: $*" >&2; exit 1; }

[[ -d "$BUILD_RTL" ]] || die "build/rtl not found: $BUILD_RTL (set NOOP_HOME)"

restore_one() {
  local m="$1"
  local tgt="$BUILD_RTL/${m}.sv"
  local bak="$tgt.golden"
  [[ -f "$bak" ]] || { log "no backup for $m ($bak missing); skip"; return 1; }
  mv -f "$bak" "$tgt"
  log "restored golden -> $tgt"
}

case "${1:-}" in
  --list)
    log "currently substituted modules (have .golden backup):"
    find "$BUILD_RTL" -name '*.sv.golden' -printf '  %f\n' | sed 's/\.sv\.golden$//' >&2
    ;;
  --all)
    n=0
    while IFS= read -r bak; do
      m="$(basename "$bak" .sv.golden)"
      restore_one "$m" && n=$((n+1))
    done < <(find "$BUILD_RTL" -name '*.sv.golden')
    log "restored $n module(s)."
    ;;
  ""|-h|--help)
    sed -n '2,14p' "$0"
    ;;
  *)
    restore_one "$1"
    ;;
esac

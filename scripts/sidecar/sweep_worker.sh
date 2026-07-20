#!/usr/bin/env bash
# 并行 sweep 单目标 worker(被 xargs -P 调用)。run_signoff_target 已自含 provenance。
# no-clobber: 已有完整证据跳过。终态记入 sweep_progress.log。
set -u
SC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M="$SC/manifest_305.json"
TGT=$1; TMO=${SWEEP_TMO:-900}
ED="$SC/signoff-evidence/$TGT"
LOG="$SC/sweep_progress.log"

[ -f "$ED/RESULT.txt" ] && [ -f "$ED/COMPLETE" ] && exit 0
rm -rf "$ED" "$ED.staging" 2>/dev/null

bash "$SC/run_signoff_target.sh" "$M" "$TGT" "$TMO" >/dev/null 2>&1
rc=$?
if [ -f "$ED/RESULT.txt" ]; then
  RL=$(grep -m1 "^SIGNOFF_RESULT\|^TARGET" "$ED/RESULT.txt" 2>/dev/null)
  G=$(echo "$RL" | grep -oE "measured=[A-Z_]*" | cut -d= -f2)
  [ -z "$G" ] && G=$(echo "$RL" | grep -oE "TIMEOUT|NO_NATIVE_FACTS|INFRA[_A-Z]*|worktree" | head -1)
  G=${G:-ERROR}
else
  G="ERROR(rc=$rc)"
fi
printf '%s\t%s\n' "$TGT" "$G" >> "$LOG"

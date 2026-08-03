#!/usr/bin/env bash
# 全量 FM sweep(冻结基线): 对每个 FM 目标跑统一入口 make fm, 记录终态判定。
# 并发3 + 内存守卫15G + 每任务超时40min。结果 machine-readable 写 verif/freeze/fm_sweep.tsv
ROOT=/home/eda/xs-env/xs-v2r2-sv
OUT=$ROOT/verif/freeze/fm_sweep.tsv
LOCK=/tmp/fm_sweep
mkdir -p "$LOCK"
[ -f "$OUT" ] || echo -e "module\tverdict\tfailing\tunverified\tseconds" > "$OUT"
sed -i '/^FM_SWEEP_DONE/d' "$OUT" 2>/dev/null
DONE=$(mktemp); awk -F'\t' 'NR>1{print $1}' "$OUT" 2>/dev/null | sort -u > "$DONE"
targets=()
for mk in "$ROOT"/verif/ut/*/Makefile; do
  m=$(basename "$(dirname "$mk")")
  grep -qE "FM_VARIANTS *= *[A-Za-z]|FM_BB_TARGET|^fmbb:|^fm:" "$mk" 2>/dev/null && targets+=("$m")
done
run_one() {
  local m=$1 d="$ROOT/verif/ut/$1"
  cd "$d" || return
  local t0=$SECONDS
  timeout 2400 make fm >/tmp/fm_sweep/$m.out 2>&1
  local rc=$?
  local log=$(ls fm_work/*/fm.log 2>/dev/null | head -1)
  local v="ERROR" f="?" u="?"
  if [ $rc -eq 124 ]; then v="TIMEOUT"
  elif grep -q "Verification SUCCEEDED" /tmp/fm_sweep/$m.out fm_work/*/fm.log 2>/dev/null; then v="SUCCEEDED"
  elif grep -q "Verification WAIVED" /tmp/fm_sweep/$m.out fm_work/*/fm.log 2>/dev/null; then v="WAIVED"
  elif grep -q "未证明任何东西\|ERROR($m)" /tmp/fm_sweep/$m.out 2>/dev/null; then v="NO_FM_TARGET"
  elif grep -q "Verification FAILED\|NOT RUN" /tmp/fm_sweep/$m.out fm_work/*/fm.log 2>/dev/null; then v="FAILED"
  fi
  [ -n "$log" ] && { f=$(tac "$log"|grep -m1 -oE "[0-9]+ Failing compare points"|awk '{print $1}'); u=$(tac "$log"|grep -m1 -oE "[0-9]+ Unverified compare points"|awk '{print $1}'); }
  echo -e "$m\t$v\t${f:-?}\t${u:-?}\t$((SECONDS-t0))" >> "$OUT"
}
export -f run_one; export ROOT
for m in "${targets[@]}"; do
  grep -qxF "$m" "$DONE" 2>/dev/null && continue
  while true; do
    avail=$(free -g|awk '/^Mem:/{print $7}'); running=$(jobs -rp|wc -l)
    [ "$avail" -ge 15 ] && [ "$running" -lt 6 ] && break; sleep 20
  done
  run_one "$m" &
  sleep 3
done
wait
echo "FM_SWEEP_DONE $(date)" >> "$OUT"

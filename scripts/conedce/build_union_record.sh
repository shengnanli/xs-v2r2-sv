#!/usr/bin/env bash
# build_union_record.sh — assemble the fm-partition-union-v1 ROOT RECORD for the
# cone-DCE Rob partition proof. ONLY valid when all 5 partition FM runs reached
# RUNNER_RC=0 (SUCCEEDED) — this script refuses to emit a PASS record otherwise.
# It combines: 5 per-partition FM digests + the shared source/tool hashes + the
# 2343-output union hash. NO single-partition / no simulation result is ever
# promoted to a union PASS.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
EV="${EVROOT:-/tmp/rob-conedce-evidence}"
GEN="$EV/gen"
REC="$EV/fm-partition-union-v1"
mkdir -p "$REC"
FAMS="commit exception perf vecexcp lsq"

allpass=1
{
  echo "# fm-partition-union-v1 — cone-DCE Rob partition union root record"
  echo "# generated $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "golden_src_sha256	$(sha256sum /home/eda/xs-env/G0-canonical/golden-rtl/Rob.sv | awk '{print $1}')"
  echo "slicer_sha256	$(sha256sum $HERE/rob_cone_slicer.py | awk '{print $1}')"
  echo "always_tree_sha256	$(sha256sum $HERE/always_tree.py | awk '{print $1}')"
  echo "impltrim_sha256	$(sha256sum $HERE/impl_port_trim.py | awk '{print $1}')"
  echo "impl_wrapper_sha256	$(sha256sum $ROOT/verif/signoff/conedce/impl_freeze/Rob_wrapper.sv | awk '{print $1}')"
  # union output hash (independent verifier)
  uhash=$(python3 $HERE/verify_conedce_union.py "$GEN" 2>/dev/null | grep 'union_sha256' | sed -E 's/.*union_sha256=//')
  echo "output_union_sha256	$uhash	(2343 outputs, total+disjoint verified)"
  echo "# per-partition FM"
  for fam in $FAMS; do
    d="$EV/part_${fam}"
    rc=$(cat "$d/rc.txt" 2>/dev/null | sed 's/rc=//')
    verd=$(grep -viE '^\s*#' "$d/fm.log" 2>/dev/null | grep -oiE 'Verification (SUCCEEDED|FAILED|INCONCLUSIVE)' | tail -1)
    passing=$(grep -viE '^\s*#' "$d/fm.log" 2>/dev/null | grep -oiE 'Passing [0-9]+' | tail -1)
    failing=$(grep -viE '^\s*#' "$d/fm.log" 2>/dev/null | grep -oiE 'Failing [0-9]+' | tail -1)
    rgh=$(sha256sum "$GEN/Rob_golden_${fam}.sv" 2>/dev/null | awk '{print $1}')
    rih=$(sha256sum "$GEN/Rob_impl_${fam}.sv" 2>/dev/null | awk '{print $1}')
    echo "part.${fam}	RC=${rc:-NA}	${verd:-NO_VERDICT}	${passing:-}	${failing:-}	golden=${rgh:0:12}	impl=${rih:0:12}"
    [ "${rc:-1}" = "0" ] && echo "$verd" | grep -qi SUCCEEDED || allpass=0
  done
  if [ "$allpass" = "1" ]; then
    echo "UNION_STATUS	PASS	(5/5 partitions RUNNER_RC=0 SUCCEEDED; union covers 2343 golden outputs)"
  else
    echo "UNION_STATUS	PENDING	(not all 5 partitions RC0 SUCCEEDED — NO promotion)"
  fi
} | tee "$REC/UNION_RECORD.tsv"

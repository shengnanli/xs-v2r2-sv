#!/usr/bin/env bash
# regen_check.sh — DETERMINISM gate: two clean regenerations must be
# byte-identical (all 12 derivatives + manifest). Proves the cone-DCE generator
# is a pure function of its locked inputs.
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
A="$(mktemp -d /tmp/rob-conedce-regenA.XXXX)"
B="$(mktemp -d /tmp/rob-conedce-regenB.XXXX)"
bash "$HERE/gen_all.sh" "$A" >/dev/null
bash "$HERE/gen_all.sh" "$B" >/dev/null
rc=0
for f in Rob_golden_commit.sv Rob_golden_exception.sv Rob_golden_perf.sv \
         Rob_golden_vecexcp.sv Rob_golden_lsq.sv Rob_golden_robdeqgroup.sv \
         Rob_impl_commit.sv Rob_impl_exception.sv Rob_impl_perf.sv \
         Rob_impl_vecexcp.sv Rob_impl_lsq.sv Rob_impl_robdeqgroup.sv; do
  ha=$(sha256sum "$A/$f" | awk '{print $1}')
  hb=$(sha256sum "$B/$f" | awk '{print $1}')
  if [ "$ha" = "$hb" ]; then
    echo "IDENTICAL  $f  $ha"
  else
    echo "DIFFER     $f  A=$ha B=$hb"; rc=1
  fi
done
# manifest (excluding its own path-independent content) must match too
if diff -q "$A/conedce_manifest.tsv" "$B/conedce_manifest.tsv" >/dev/null; then
  echo "IDENTICAL  conedce_manifest.tsv"
else
  echo "DIFFER     conedce_manifest.tsv"; rc=1
fi
rm -rf "$A" "$B"
if [ $rc -eq 0 ]; then echo "REGEN_DETERMINISM: PASS (2 clean runs byte-identical)"; else echo "REGEN_DETERMINISM: FAIL"; fi
exit $rc

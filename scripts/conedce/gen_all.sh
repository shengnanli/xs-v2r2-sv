#!/usr/bin/env bash
# gen_all.sh — deterministic generator for ALL 5 cone-DCE Rob partition
# derivatives (ref reduced golden + impl reduced wrapper) + hashes manifest.
#
# Pure function of: frozen golden Rob (hash-checked), frozen impl integration
# artifacts (freeze refreshed from the codex-0107 fixed core+wrapper, commit
# 39c69219 chain; impl_freeze MUST equal rtl/backend at the same commit —
# enforced by the drift gate below), the locked cone-slicer / port-trimmer, and
# the union-verified per-partition output lists. No timestamps in outputs =>
# two clean runs are byte-identical (verified by regen_check.sh).
set -eu
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"          # /tmp/rob-conedce
G="/home/eda/xs-env/G0-canonical/golden-rtl"
GOLDEN="$G/Rob.sv"
GOLDEN_SHA="c3f1aa603afb25d5b40472a52c8a1fd50f420ffe0273faf1abe1f9ac89c89428"
IMPL_WRAP="$ROOT/verif/signoff/conedce/impl_freeze/Rob_wrapper.sv"
OUT="${1:-/tmp/rob-conedce-evidence/gen}"
OUTLIST="$ROOT/verif/signoff/conedce/outlists"

# --- integrity gate: frozen golden hash must match ---
got=$(sha256sum "$GOLDEN" | awk '{print $1}')
if [ "$got" != "$GOLDEN_SHA" ]; then
  echo "FATAL: golden Rob hash mismatch: got $got expected $GOLDEN_SHA" >&2
  exit 2
fi

# --- drift gate (codex 0108 前置1): impl_freeze must be byte-identical to the
#     committed rtl/backend sources of the SAME commit. Kills hand-carried-RTL
#     drift: the generator input IS the authoritative committed wrapper. ---
for f in Rob.sv Rob_wrapper.sv rob_pkg.sv rob_lsq_deep_outputs.sv \
         Rob_difftest_stubs.sv Rob_blackbox_stubs.sv; do
  if ! cmp -s "$ROOT/verif/signoff/conedce/impl_freeze/$f" "$ROOT/rtl/backend/$f"; then
    echo "FATAL: impl_freeze/$f drifted from rtl/backend/$f (re-freeze required)" >&2
    exit 2
  fi
done

mkdir -p "$OUT"
MAN="$OUT/conedce_manifest.tsv"
: > "$MAN"
printf "# cone-DCE derivative manifest (deterministic)\n" >> "$MAN"
printf "# golden_src_sha256\t%s\n" "$GOLDEN_SHA" >> "$MAN"
printf "# impl_wrapper_sha256\t%s\n" "$(sha256sum "$IMPL_WRAP" | awk '{print $1}')" >> "$MAN"
printf "# slicer_sha256\t%s\n" "$(sha256sum "$HERE/rob_cone_slicer.py" | awk '{print $1}')" >> "$MAN"
printf "# always_tree_sha256\t%s\n" "$(sha256sum "$HERE/always_tree.py" | awk '{print $1}')" >> "$MAN"
printf "# impltrim_sha256\t%s\n" "$(sha256sum "$HERE/impl_port_trim.py" | awk '{print $1}')" >> "$MAN"
printf "# fam\treduced_golden_sha256\treduced_impl_sha256\n" >> "$MAN"

for fam in commit exception perf vecexcp lsq; do
  python3 "$HERE/rob_cone_slicer.py" --src "$GOLDEN" --module Rob \
     --outputs "$OUTLIST/$fam.txt" --keep-name Rob \
     --out "$OUT/Rob_golden_${fam}.sv" --report "$OUT/report_golden_${fam}.json" >/dev/null
  python3 "$HERE/impl_port_trim.py" --src "$IMPL_WRAP" --module Rob \
     --outputs "$OUTLIST/$fam.txt" \
     --out "$OUT/Rob_impl_${fam}.sv" --report "$OUT/report_impl_${fam}.json" >/dev/null
  rg=$(sha256sum "$OUT/Rob_golden_${fam}.sv" | awk '{print $1}')
  ri=$(sha256sum "$OUT/Rob_impl_${fam}.sv" | awk '{print $1}')
  printf "%s\t%s\t%s\n" "$fam" "$rg" "$ri" >> "$MAN"
done
echo "[gen_all] wrote 5 reduced-golden + 5 reduced-impl to $OUT"
echo "[gen_all] manifest: $MAN"
cat "$MAN"

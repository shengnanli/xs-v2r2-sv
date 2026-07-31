#!/usr/bin/env bash
# Negative tests for the StorePipe target-scoped semantic-surface WRAPPER
# (codex_0092 §1.4).  Every case MUST fail-closed (non-zero / ERROR).
# Two independent layers are exercised per case:
#   A) source-verified classifier (derive_surface.py --check): re-derives the
#      excluded set from the committed .module.fir (FIRRTL last-connect-wins) and
#      the derivative port widths, and asserts the committed wrappers == render.
#      Catches: over-exclude, under-exclude, rename, source-now-defined, width drift.
#   B) runner hash-binding (semantic_surface_{ref,impl}_sha256 in the committed
#      ledger): any wrapper-byte tamper is rejected before FM runs.  Simulated
#      here exactly as run_signoff_target.sh does over committed bytes.
#
# The point of B) is codex's hard requirement: the runner accepts ONLY the
# committed derivative-id + exact per-wrapper hashes -- no generic "exclude any
# point" / "swap any top" knob.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DERIVE="$HERE/derive_surface.py"
FIR="$HERE/StorePipe.module.fir"
SURF_JSON="$HERE/observable_surface.json"
REF_SV="$HERE/StorePipe_ref_surface.sv"
IMPL_SV="$HERE/StorePipe_impl_surface.sv"
LEDGER="$HERE/LEDGER.tsv"
PASS=0; FAIL=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

lval() { awk -F'\t' -v k="$1" '$1==k{print $2; exit}' "$LEDGER"; }
REF_SHA=$(lval semantic_surface_ref_sha256)
IMPL_SHA=$(lval semantic_surface_impl_sha256)

expect_error() { # <name> <rc> <log>
  local name="$1" rc="$2" log="$3"
  if [ "$rc" -ne 0 ]; then
    echo "  PASS(neg) $name -> fail-closed rc=$rc"
    grep -aoE "SURFACE_ERROR[^\"]*|SEMANTIC_SURFACE_[A-Z_]*" "$log" 2>/dev/null | head -1 | sed 's/^/         msg: /'
    PASS=$((PASS+1))
  else
    echo "  *** FAIL(neg) $name -> ACCEPTED (rc=0) -- did not fail-closed!"
    FAIL=$((FAIL+1))
  fi
}

# Runner hash-bind check: rejection == mutated wrapper sha != committed ledger sha.
expect_hash_reject() { # <name> <mutated_file> <ledger_sha>
  local name="$1" got want="$3"
  got=$(sha256sum "$2" | cut -d' ' -f1)
  if [ "$got" != "$want" ]; then
    echo "  PASS(neg) $name -> runner would reject (sha ${got:0:12}.. != ledger ${want:0:12}..)"
    PASS=$((PASS+1))
  else
    echo "  *** FAIL(neg) $name -> sha matches ledger, runner would ACCEPT tampered wrapper!"
    FAIL=$((FAIL+1))
  fi
}

echo "== baseline positive: committed wrappers match source =="
if python3 "$DERIVE" "$HERE" --check > "$WORK/pos.log" 2>&1; then
  echo "  ok: $(grep -a SURFACE_OK "$WORK/pos.log")"
else echo "  *** baseline broken"; cat "$WORK/pos.log"; FAIL=$((FAIL+1)); fi
echo

# ---- NEG-1: OVER-exclude (>14): drop a source-DEFINED output from the surface --
# Simulate excluding a 15th leaf: remove io_miss_req_bits_cancel (DEFINED) from
# the surface port list of the ref wrapper (as if the generator excluded it).
echo "== NEG-1: over-exclude (a 15th, source-DEFINED leaf pulled off surface) =="
cp -r "$HERE" "$WORK/over"; rm -rf "$WORK/over/__pycache__"
sed -i '/output  io_miss_req_bits_cancel,/d' "$WORK/over/StorePipe_ref_surface.sv"
python3 "$DERIVE" "$WORK/over" --check > "$WORK/over.log" 2>&1
expect_error "over-exclude(classifier)" "$?" "$WORK/over.log"
expect_hash_reject "over-exclude(hash-bind)" "$WORK/over/StorePipe_ref_surface.sv" "$REF_SHA"
echo

# ---- NEG-2: UNDER-exclude (<14): re-export one of the 14 undefined leaves ------
echo "== NEG-2: under-exclude (re-export io_miss_req_bits_amo_cmp onto surface) =="
cp -r "$HERE" "$WORK/under"; rm -rf "$WORK/under/__pycache__"
# turn the excluded amo_cmp internal wire into a surface output port
sed -i 's|  wire \[127:0\] io_miss_req_bits_amo_cmp; // UNSPECIFIED_BY_SOURCE: off surface||' "$WORK/under/StorePipe_ref_surface.sv"
sed -i 's|  output  io_error_bits_report_to_beu|  output  [127:0] io_miss_req_bits_amo_cmp,\n  output  io_error_bits_report_to_beu|' "$WORK/under/StorePipe_ref_surface.sv"
python3 "$DERIVE" "$WORK/under" --check > "$WORK/under.log" 2>&1
expect_error "under-exclude(classifier)" "$?" "$WORK/under.log"
expect_hash_reject "under-exclude(hash-bind)" "$WORK/under/StorePipe_ref_surface.sv" "$REF_SHA"
echo

# ---- NEG-3: RENAME (a surface port name drifts) --------------------------------
echo "== NEG-3: rename a surface port in the impl wrapper =="
cp -r "$HERE" "$WORK/rename"; rm -rf "$WORK/rename/__pycache__"
sed -i 's/io_miss_req_bits_source/io_miss_req_bits_sourceX/g' "$WORK/rename/StorePipe_impl_surface.sv"
python3 "$DERIVE" "$WORK/rename" --check > "$WORK/rename.log" 2>&1
expect_error "rename(classifier)" "$?" "$WORK/rename.log"
expect_hash_reject "rename(hash-bind)" "$WORK/rename/StorePipe_impl_surface.sv" "$IMPL_SHA"
echo

# ---- NEG-4: SOURCE no longer invalidate-only -----------------------------------
# Inject a `connect` of one of the 14 excluded leaves AFTER its invalidate in a
# copy of the module FIRRTL.  The classifier now derives 13 UNSPECIFIED, so the
# (unchanged) wrappers (which still exclude 14) no longer match source -> reject.
echo "== NEG-4: a leaf becomes source-connect-defined (FIRRTL) =="
cp -r "$HERE" "$WORK/srcdef"; rm -rf "$WORK/srcdef/__pycache__"
python3 - "$WORK/srcdef/StorePipe.module.fir" <<'PY'
import sys,re
p=sys.argv[1]; lines=open(p,encoding="utf-8").read().splitlines(keepends=True)
out=[]; done=False
for ln in lines:
    out.append(ln)
    if not done and re.match(r'\s*invalidate\s+io\.replace_access\.bits\.set', ln):
        indent=re.match(r'(\s*)',ln).group(1)
        out.append(indent+"connect io.miss_req.bits.amo_mask, UInt<16>(0h0) @[injected negtest]\n")
        done=True
open(p,"w",encoding="utf-8").write("".join(out)); print("injected:",done)
PY
python3 "$DERIVE" "$WORK/srcdef" --check > "$WORK/srcdef.log" 2>&1
expect_error "source-now-defined(classifier)" "$?" "$WORK/srcdef.log"
# assert the classifier now derives 13 and amo_mask left the excluded set:
python3 - "$WORK/srcdef/StorePipe.module.fir" "$DERIVE" <<'PY' > "$WORK/srcdef_n.log" 2>&1
import sys,importlib.util
firp,drv=sys.argv[1],sys.argv[2]
spec=importlib.util.spec_from_file_location("ds",drv); m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
leaves=m.firrtl_unspecified_leaves(firp)
print("derived_now=%d amo_mask_excluded=%s"%(len(leaves),"io_miss_req_bits_amo_mask" in leaves))
sys.exit(0 if (len(leaves)==13 and "io_miss_req_bits_amo_mask" not in leaves) else 1)
PY
if [ $? -eq 0 ]; then echo "  ok: classifier re-derived 13 (amo_mask left surface): $(cat "$WORK/srcdef_n.log")"; else echo "  *** classifier did not re-derive 13"; cat "$WORK/srcdef_n.log"; FAIL=$((FAIL+1)); fi
rm -rf "$WORK"/*/__pycache__ 2>/dev/null
echo

echo "=========================================================="
echo "NEG-TEST SUMMARY: PASS(fail-closed)=$PASS  FAIL(accepted)=$FAIL"
[ "$FAIL" -eq 0 ] && { echo "ALL NEGATIVE TESTS FAIL-CLOSED (ERROR) AS REQUIRED"; exit 0; } || { echo "SOME NEGATIVE TEST WAS ACCEPTED -- SURFACE NOT HARD-BOUND"; exit 1; }

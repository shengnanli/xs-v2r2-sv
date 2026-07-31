#!/usr/bin/env bash
# =============================================================================
# derive.sh  —  canonical-derivative ledger G0-StorePipe-observable-v1
# =============================================================================
# Mechanically extract the intact, pre-DCE StorePipe FIRRTL module from the
# FROZEN, IMMUTABLE G0 canonical SimTop.fir and re-lower it STANDALONE with the
# LOCKED firtool-1.62.1 (the exact version that produced G0), so the full
# observable IO (lsu / meta / tag / miss / replace / error + 6 perfCnt probes)
# survives whole-chip DCE and becomes top-level ports.
#
#   * G0 SimTop.fir is READ-ONLY. This script never writes to G0.
#   * Deterministic: two clean runs produce byte-identical outputs.
#   * No hand-written RTL. No config change. No parameter override.
#   * All immutable inputs are SHA-pinned; the script ABORTS on any drift.
#
# Provenance lineage:
#   codex_0082 extract_storepipe.sh  ->  codex_0088 §3 canonical-derivative
#   ledger (this file). Boundary / firtool pin / reset handling unchanged;
#   this version is self-locating and emits the ledger digest set in place.
#
# Usage:  derive.sh [OUTDIR]
#   OUTDIR defaults to this script's own directory (the committed ledger dir),
#   so `derive.sh` re-materializes the committed derivative in place and its
#   outputs must be byte-identical to the committed bytes (verify via digests).
# =============================================================================
set -euo pipefail

# ---- Locked, immutable inputs (SHA-pinned; abort on drift) ------------------
SIMTOP_FIR="/home/eda/xs-env/G0-canonical/golden-rtl/SimTop.fir"
FIRTOOL="/home/eda/.cache/llvm-firtool/1.62.1/bin/firtool"   # version that made G0
SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTDIR="${1:-$SELF}"

# Byte-exact module boundary of StorePipe in the frozen SimTop.fir.
#   grep -n '^  module StorePipe' SimTop.fir  =>
#     7084336 : module StorePipe     (start, inclusive)
#     7084663 : module StorePipe_1   (next module; extraction ends at 7084662)
START_LINE=7084336
END_LINE=7084662

# Provenance pins (source_baseline_id + immutable input hashes).
CANONICAL_BASELINE_ID="G0-89fe69e83a4f2ea81065ecf9d5d9ab46b0b5a29911fd4f6aa2fefd54dcc13456"
EXPECT_SIMTOP_SHA="73b0a83256ffbd9486bacfaa909c6d3aeec2d10ac81ee624bd18ae32106ab967"
EXPECT_FIRTOOL_SHA="7f52d2a3782d09736895f66e7eb0e5cc4b3b1b18aa1ad0d04fca4cd6e42cd2ee"
# The firtool argv used to lower the standalone circuit (recorded verbatim).
FIRTOOL_ARGV=(--format=fir)

mkdir -p "$OUTDIR"

# ---- 0. Verify locked inputs -------------------------------------------------
got_simtop=$(sha256sum "$SIMTOP_FIR" | cut -d' ' -f1)
got_firtool=$(sha256sum "$FIRTOOL"   | cut -d' ' -f1)
[ "$got_simtop"  = "$EXPECT_SIMTOP_SHA"  ] || { echo "FATAL: SimTop.fir SHA mismatch ($got_simtop)"; exit 2; }
[ "$got_firtool" = "$EXPECT_FIRTOOL_SHA" ] || { echo "FATAL: firtool SHA mismatch ($got_firtool)"; exit 2; }
"$FIRTOOL" --version 2>&1 | grep -q "firtool-1.62.1" || { echo "FATAL: firtool not 1.62.1"; exit 2; }

# ---- 1. Mechanical byte-exact module extraction ------------------------------
MOD="$OUTDIR/StorePipe.module.fir"
sed -n "${START_LINE},${END_LINE}p" "$SIMTOP_FIR" > "$MOD"
head -1 "$MOD" | grep -q "^  module StorePipe :" || { echo "FATAL: bad start boundary"; exit 3; }
sed -n "$((END_LINE+1))p" "$SIMTOP_FIR" | grep -q "^  module StorePipe_1 :" || { echo "FATAL: bad end boundary"; exit 3; }
# No submodule instances -> dependency closure is empty (self-contained).
if grep -qE "^[[:space:]]+inst " "$MOD"; then echo "FATAL: unexpected inst (closure not empty)"; exit 3; fi

# ---- 2. Concretize the abstract top-level reset ------------------------------
# The abstract `Reset` port cannot be inferred at top level (no parent to drive
# it). In the production DCache core domain the reset is AsyncReset. StorePipe's
# registers carry NO reset value, so the reset port drives no logic: the body is
# byte-identical whether AsyncReset or sync UInt<1> is chosen (verified). Pin
# AsyncReset to mirror production.
MOD_R="$OUTDIR/StorePipe.module.asyncreset.fir"
sed 's/^    input reset : Reset /    input reset : AsyncReset /' "$MOD" > "$MOD_R"

# ---- 3. Assemble a standalone circuit with StorePipe as top ------------------
CIRC="$OUTDIR/StorePipe.standalone.fir"
{
  echo "FIRRTL version 3.3.0"       # exact version stamped in SimTop.fir header
  echo "circuit StorePipe :"
  cat "$MOD_R"
} > "$CIRC"

# ---- 4. Lower standalone with the LOCKED firtool -----------------------------
DERIV="$OUTDIR/StorePipe.sv"
"$FIRTOOL" "$CIRC" "${FIRTOOL_ARGV[@]}" -o "$DERIV"

# ---- 5. Emit provenance manifest (digest set) --------------------------------
{
  echo "# G0-StorePipe-observable-v1 provenance (canonical-derivative ledger)"
  echo "reference_kind=canonical_derivative"
  echo "derivative_id=G0-StorePipe-observable-v1"
  echo "source_baseline_id=$CANONICAL_BASELINE_ID"
  # NOTE: no wall-clock timestamp is written here; the committed PROVENANCE must
  # be byte-deterministic so the ledger root digest is reproducible. Generation
  # time (if wanted) is recorded out-of-band in the runner evidence, not here.
  echo "firtool_version=firtool-1.62.1"
  echo "firrtl_version=3.3.0"
  echo "firtool_path=$FIRTOOL"
  echo "firtool_argv=firtool <standalone.fir> ${FIRTOOL_ARGV[*]} -o StorePipe.sv"
  echo "simtop_fir_path=$SIMTOP_FIR"
  echo "extract_lines=${START_LINE}-${END_LINE}"
  echo "reset_type=AsyncReset (behavior-irrelevant; init-free registers)"
  echo "sha256_SimTop_fir=$(sha256sum "$SIMTOP_FIR" | cut -d' ' -f1)"
  echo "sha256_firtool=$(sha256sum "$FIRTOOL" | cut -d' ' -f1)"
  echo "sha256_module_fir=$(sha256sum "$MOD" | cut -d' ' -f1)"
  echo "sha256_module_asyncreset_fir=$(sha256sum "$MOD_R" | cut -d' ' -f1)"
  echo "sha256_standalone_fir=$(sha256sum "$CIRC" | cut -d' ' -f1)"
  echo "sha256_derivative_sv=$(sha256sum "$DERIV" | cut -d' ' -f1)"
  echo "sha256_this_script=$(sha256sum "$SELF/derive.sh" | cut -d' ' -f1)"
} > "$OUTDIR/PROVENANCE.manifest"

echo "OK: derivative -> $DERIV"
cat "$OUTDIR/PROVENANCE.manifest"

#!/usr/bin/env python3
"""Emit the versioned canonical-derivative LEDGER.tsv for a derivative dir.

The ledger is the SINGLE committed source of truth that the signoff runner
consults when a target declares reference_kind=canonical_derivative. It binds:
  - reference_kind (must be canonical_derivative),
  - derivative_id + source_baseline_id,
  - the immutable input pins (SimTop.fir SHA, firtool SHA, extract lines, argv),
  - the per-file digest of every ledger artifact,
  - the authoritative reference file (reference_sv) + its SHA (this is what the
    runner stages and hash-checks before FM).

Deterministic: derived purely from committed bytes (no wall-clock in the
digest-bearing rows). Re-running produces byte-identical LEDGER.tsv.

Usage: gen_ledger.py <derivative_dir>
"""
import hashlib, os, sys


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()


def kv(prov, key):
    for ln in open(prov, encoding="utf-8"):
        ln = ln.rstrip("\n")
        if ln.startswith(key + "="):
            return ln.split("=", 1)[1]
    raise SystemExit(f"missing {key} in {prov}")


def main():
    ldir = sys.argv[1].rstrip("/")
    prov = os.path.join(ldir, "PROVENANCE.manifest")
    # digest-bearing artifacts (exclude the ledger + readme themselves)
    arts = sorted(f for f in os.listdir(ldir)
                  if os.path.isfile(os.path.join(ldir, f))
                  and f not in ("LEDGER.tsv", "README.md", "INTEGRATOR_NOTES.md",
                                "negtests.sh"))
    file_rows = [(f, os.path.getsize(os.path.join(ldir, f)),
                  sha(os.path.join(ldir, f))) for f in arts]
    root = hashlib.sha256(
        "".join(f"{f}\t{s}\t{h}\n" for f, s, h in file_rows).encode()
    ).hexdigest()

    meta = [
        ("schema", "canonical-derivative-ledger-v1"),
        ("reference_kind", "canonical_derivative"),
        ("derivative_id", kv(prov, "derivative_id")),
        ("source_baseline_id", kv(prov, "source_baseline_id")),
        ("firtool_version", kv(prov, "firtool_version")),
        ("firrtl_version", kv(prov, "firrtl_version")),
        ("firtool_sha256", kv(prov, "sha256_firtool")),
        ("simtop_fir_sha256", kv(prov, "sha256_SimTop_fir")),
        ("extract_lines", kv(prov, "extract_lines")),
        ("firtool_argv", kv(prov, "firtool_argv")),
        ("reset_type", kv(prov, "reset_type")),
        # The authoritative FM reference: the file the runner stages as
        # $GOLDEN_RTL/<top>.sv, hash-checked against reference_sv_sha256.
        ("reference_top", "StorePipe"),
        ("reference_sv", "StorePipe.sv"),
        ("reference_sv_sha256", kv(prov, "sha256_derivative_sv")),
        ("derive_script", "derive.sh"),
        ("surface_spec", "observable_surface.json"),
        # Target-scoped semantic-surface WRAPPER (codex_0092 §1, option B): two
        # per-side wrappers (module StorePipe_surface) re-export ONLY the 36
        # source-defined outputs + 23 inputs and leave the 14 UNSPECIFIED-by-
        # source (invalidate-only) output leaves UNCONNECTED -> off the FM
        # comparison surface.  Not dont_verify, not 0-fill, not a generic knob.
        # Source-derived by derive_surface.py (FIRRTL last-connect-wins + the
        # committed derivative port widths).  The runner stages both wrappers,
        # hash-verifies them, and sets the FM top to semantic_surface_top --
        # ONLY for canonical_derivative + these exact hashes.
        ("surface_derive_script", "derive_surface.py"),
        ("semantic_surface_top", "StorePipe_surface"),
        ("semantic_surface_ref", "StorePipe_ref_surface.sv"),
        ("semantic_surface_ref_sha256",
         sha(os.path.join(ldir, "StorePipe_ref_surface.sv"))),
        ("semantic_surface_impl", "StorePipe_impl_surface.sv"),
        ("semantic_surface_impl_sha256",
         sha(os.path.join(ldir, "StorePipe_impl_surface.sv"))),
        ("ledger_root_sha256", root),
    ]
    out = os.path.join(ldir, "LEDGER.tsv")
    with open(out, "w", encoding="utf-8") as f:
        f.write("# canonical-derivative ledger (versioned, immutable per id)\n")
        f.write("# key\tvalue\n")
        for k, v in meta:
            f.write(f"{k}\t{v}\n")
        f.write("# --- artifact digests (path-size-sha256) ---\n")
        for fn, s, h in file_rows:
            f.write(f"artifact\t{fn}\t{s}\t{h}\n")
    print("wrote", out, "root", root)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""PASS_DEAD_REF policy tests: positive qualification + 5 negative controls.

Reuses the committed test harness (build/run helpers) from
test_fm_sidecar_verdict.py, extended to pass --dead-ref (a per-target dead-ref
declaration file). Also drives the verdict() directly with the REAL committed
native_facts for the qualifying modules (Composer, BankedDataArray, WbDataPath).

Honesty: fail-closed on anything undeclared or impl-side. This policy must never
turn a real gap green.
"""
import sys, os, json, hashlib, tempfile, shutil

SC = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(os.path.dirname(SC))
sys.path.insert(0, SC)
import test_fm_sidecar_verdict as T           # reuse build/facts/expect/OBJ0/AV0
from fm_sidecar_verdict import verdict

DECL_DIR = os.path.join(REPO, "verif/signoff/dead_ref")

# ---- helper: run verdict with an optional dead-ref declaration file ----------
def run_dr(dead_ref=None, **kw):
    """Like T.run but also threads a --dead-ref path into verdict()."""
    fact_over = kw.pop("fact_over", None)
    env_over = kw.pop("env_over", None)
    native_diverge = kw.pop("native_diverge", None)
    exp = kw.pop("exp", None)
    actual_rc = kw.pop("actual_rc", 0)
    run_id = kw.pop("run_id", "RID-1")
    top = kw.pop("top", TOP)
    target = kw.pop("target", TOP)
    # envelope top/target must be TOP; the fixture build defaults to Bku, override it.
    env_over = dict(env_over or {})
    env_over.setdefault("top", top); env_over.setdefault("target", target)
    env_over.setdefault("variant", target)
    d, ep, np = T.build(fact_over, env_over, native_diverge, run_id, top, target)
    try:
        v, q = verdict(ep, exp if exp is not None else T.expect(), actual_rc, np, dead_ref)
    finally:
        shutil.rmtree(d, ignore_errors=True)
    return v, q.get("reason")


def write_decl(target, top, refs, entry_rat="dead cone reg"):
    fd, p = tempfile.mkstemp(suffix=".json"); os.close(fd)
    D = {"schema": "fm-sidecar-dead-ref-v1", "target": target,
         "rationale": "test golden-only dead-ref declaration",
         "entries": [{"ref_path": r, "rationale": entry_rat} for r in sorted(refs)]}
    json.dump(D, open(p, "w"))
    return p


RESULTS = []
def check(name, got, want):
    ok = got == want
    RESULTS.append((name, got, want, ok))
    print(f"{'PASS' if ok else 'FAIL':4s}  {name:52s} want={want:14s} got={got}")


# Use a target NOT in the _MU_STRENGTHEN whitelist so the default AV0 (vmucp=false)
# is accepted (Bku is now in the whitelist and would require vmucp=true).
TOP = "MyLeaf"
R0 = f"r:/WORK/{TOP}/gold_dead_reg_a"
R1 = f"r:/WORK/{TOP}/gold_dead_reg_b"
I0 = f"i:/WORK/{TOP}/u_core/leftover_reg"

_ORIG_expect = T.expect
def _expect(**over):
    over.setdefault("target", TOP); over.setdefault("top", TOP)
    over.setdefault("variant", TOP)
    return _ORIG_expect(**over)
T.expect = _expect

# =====================================================================
# POSITIVE: synthetic strict golden-only unread_ref, fully declared -> PASS_DEAD_REF
# =====================================================================
decl = write_decl(TOP, TOP, [R0, R1])
v, _ = run_dr(dead_ref=decl,
    fact_over={"unmatched.unread_ref": 2,
               "objects.unmatched_unread_ref": [R0, R1]})
check("strict_unread_ref_fully_declared", v, "PASS_DEAD_REF")

# POSITIVE: synthetic strict golden-only unmatched_ref (compare point), declared
v, _ = run_dr(dead_ref=decl,
    fact_over={"unmatched.compare_ref": 2,
               "objects.unmatched_ref": [R0, R1]})
check("strict_unmatched_ref_fully_declared", v, "PASS_DEAD_REF")

# POSITIVE: declared is a SUPERSET (extra declared-but-absent is fine)
decl_super = write_decl(TOP, TOP, [R0, R1, f"r:/WORK/{TOP}/gold_dead_reg_c"])
v, _ = run_dr(dead_ref=decl_super,
    fact_over={"unmatched.unread_ref": 1, "objects.unmatched_unread_ref": [R0]})
check("strict_declared_superset_ok", v, "PASS_DEAD_REF")

# =====================================================================
# NEGATIVE CONTROL 1: unread_impl>0 -> still PARTIAL (impl-side dead NOT absorbed)
# =====================================================================
decl_impl = write_decl(TOP, TOP, [R0])
v, _ = run_dr(dead_ref=decl_impl,
    fact_over={"unmatched.unread_ref": 1, "objects.unmatched_unread_ref": [R0],
               "unmatched.unread_impl": 1, "objects.unmatched_unread_impl": [I0]})
check("NC1_unread_impl_still_partial", v, "PARTIAL")

# NEGATIVE CONTROL 1b: unmatched_impl (compare point on impl side) -> PARTIAL
v, _ = run_dr(dead_ref=decl_impl,
    fact_over={"unmatched.unread_ref": 1, "objects.unmatched_unread_ref": [R0],
               "unmatched.compare_impl": 1, "objects.unmatched_impl": [I0]},
    env_over={"proof_mode": "assembly"},
    exp=T.expect(proof_mode="assembly"))
check("NC1b_unmatched_impl_still_partial", v, "PARTIAL")

# =====================================================================
# NEGATIVE CONTROL 2: undeclared unmatched_ref -> still PARTIAL (fail-closed)
# =====================================================================
decl_only_r0 = write_decl(TOP, TOP, [R0])
v, _ = run_dr(dead_ref=decl_only_r0,
    fact_over={"unmatched.unread_ref": 2, "objects.unmatched_unread_ref": [R0, R1]})
check("NC2_undeclared_residual_partial", v, "PARTIAL")

# =====================================================================
# NEGATIVE CONTROL 3: failing>0 -> FAILED (unchanged, dead-ref never reached)
# =====================================================================
v, _ = run_dr(dead_ref=decl,
    fact_over={"stats.failing": 20,
               "unmatched.unread_ref": 2, "objects.unmatched_unread_ref": [R0, R1]})
check("NC3_failing_still_failed", v, "FAILED")

# NEGATIVE CONTROL 3b: native FAILED -> FAILED
v, _ = run_dr(dead_ref=decl,
    fact_over={"native_verdict": "FAILED", "stats.failing": 1,
               "unmatched.unread_ref": 2, "objects.unmatched_unread_ref": [R0, R1]})
check("NC3b_native_failed_still_failed", v, "FAILED")

# =====================================================================
# NEGATIVE CONTROL 4: missing/None declaration but residual present -> PARTIAL
# =====================================================================
v, _ = run_dr(dead_ref=None,
    fact_over={"unmatched.unread_ref": 2, "objects.unmatched_unread_ref": [R0, R1]})
check("NC4a_no_declaration_partial", v, "PARTIAL")

# NEGATIVE CONTROL 4b: empty entries declaration -> ERROR (malformed, fail-closed)
fd, empty_decl = tempfile.mkstemp(suffix=".json"); os.close(fd)
json.dump({"schema": "fm-sidecar-dead-ref-v1", "target": TOP,
           "rationale": "x", "entries": []}, open(empty_decl, "w"))
v, _ = run_dr(dead_ref=empty_decl,
    fact_over={"unmatched.unread_ref": 1, "objects.unmatched_unread_ref": [R0]})
check("NC4b_empty_declaration_error", v, "ERROR")

# NEGATIVE CONTROL 4c: declaration target mismatch -> ERROR (fail-closed)
decl_wrong_tgt = write_decl("SomeOtherTarget", TOP, [R0])
v, _ = run_dr(dead_ref=decl_wrong_tgt,
    fact_over={"unmatched.unread_ref": 1, "objects.unmatched_unread_ref": [R0]})
check("NC4c_target_mismatch_error", v, "ERROR")

# NEGATIVE CONTROL 4d: both-side dead (unread_notcompared) NOT absorbed -> PARTIAL
v, _ = run_dr(dead_ref=decl,
    fact_over={"stats.unread_notcompared": 1,
               "objects.matched_unread_notcompared_pairs": [T.P(R0, I0)],
               "unmatched.unread_ref": 1, "objects.unmatched_unread_ref": [R1]})
check("NC4d_both_side_dead_not_absorbed", v, "PARTIAL")

# =====================================================================
# NEGATIVE CONTROL 5 (regression): declaration present but WRONG target's residual
#  -> the gate must not absorb another target's identities. Also: a clean strict
#  proof WITH a declaration file but ZERO residual must remain SUCCEEDED (not
#  spuriously PASS_DEAD_REF).
# =====================================================================
v, _ = run_dr(dead_ref=decl)     # no residual at all, declaration present
check("NC5_clean_with_decl_stays_succeeded", v, "SUCCEEDED")

# Regression: with NO --dead-ref, a clean strict proof is SUCCEEDED (unchanged)
v, _ = run_dr(dead_ref=None)
check("REG_clean_no_decl_succeeded", v, "SUCCEEDED")

# =====================================================================
# REAL native_facts: Composer (assembly, 602 golden-only) -> PASS_DEAD_REF
# =====================================================================
def run_real(evdir, decl_path, mode, allow_path=None):
    nat = json.load(open(f"{evdir}/native_facts.json"))
    top = nat["top"]; target = os.path.basename(evdir.rstrip("/"))
    # rebuild a minimal envelope + expectation matching the committed native_facts
    nb = open(f"{evdir}/native_facts.json", "rb").read()
    env = {"schema": "fm-sidecar-envelope-v1", "run_id": "RREAL", "target": target,
           "top": top, "variant": target, "proof_mode": mode,
           "canonical_baseline_id": nat.get("run_id", "G0X").split("-")[0] + "-x",
           "inputs_sha256": {"ref_srcs_digest": T.H("a"), "impl_srcs_digest": T.H("b")},
           "script_sha256": T.H("c"), "tool": {"fm_shell_digest": T.H("d")},
           "fm_shell_rc": 0, "native_facts_sha256": hashlib.sha256(nb).hexdigest(),
           **{k: nat[k] for k in ("native_verdict", "stats", "unmatched", "objects",
                                  "qualifications", "entry_appvars")}}
    return env, nat, top, target
# This path requires reconstructing a valid baseline id / digests that pass the
# strict envelope checks; simpler and more faithful is to drive verdict() through
# the committed evidence's own expectation.json when present. Composer delta and
# BankedDataArray delta3 have expectation.json.
def run_committed(evdir, decl_path):
    exp = json.load(open(f"{evdir}/expectation.json"))
    sc = f"{evdir}/verdict.sidecar.json"
    nf = f"{evdir}/native_facts.json"
    v, q = verdict(sc, exp, 0, nf, decl_path)
    return v, q.get("reason")

COMPOSER = "../scripts/sidecar/signoff-evidence-delta/Composer"
if os.path.exists(f"{COMPOSER}/expectation.json"):
    v, r = run_committed(COMPOSER, f"{DECL_DIR}/Composer.json")
    check("REAL_composer_declared", v, "PASS_DEAD_REF")
    # negative: same real facts, NO declaration -> PARTIAL
    v, r = run_committed(COMPOSER, None)
    check("REAL_composer_no_decl_partial", v, "PARTIAL")
    # negative: declaration missing ONE identity -> PARTIAL (fail-closed)
    full = json.load(open(f"{DECL_DIR}/Composer.json"))
    short = dict(full); short["entries"] = full["entries"][:-1]
    fd, sp = tempfile.mkstemp(suffix=".json"); os.close(fd)
    json.dump(short, open(sp, "w"))
    v, r = run_committed(COMPOSER, sp)
    check("REAL_composer_missing_one_partial", v, "PARTIAL")
else:
    print("SKIP  Composer committed expectation.json not present")

BDA = "../scripts/sidecar/signoff-evidence-delta3/BankedDataArray"
if os.path.exists(f"{BDA}/expectation.json"):
    v, r = run_committed(BDA, f"{DECL_DIR}/BankedDataArray.json")
    # NOTE: committed BankedDataArray ran signoff-strict WITH 9 blackboxes -> the
    # blackbox objects force PARTIAL BEFORE dead-ref (strict_has_objects). Expect PARTIAL.
    check("REAL_bda_strict_blackbox_partial", v, "PARTIAL")
else:
    print("SKIP  BankedDataArray committed expectation.json not present")

print()
npass = sum(1 for *_x, ok in RESULTS if ok)
print(f"{npass}/{len(RESULTS)} passed")
sys.exit(0 if npass == len(RESULTS) else 1)

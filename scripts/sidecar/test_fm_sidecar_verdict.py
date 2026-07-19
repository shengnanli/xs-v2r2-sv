#!/usr/bin/env python3
"""FM sidecar validator 负向测试(2026-07-19 五审 v5, **累计**: v2/v3/v4 全回归 + v5 新对抗)。"""
import sys, os, json, hashlib, tempfile, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_sidecar_verdict import verdict, strict_load, Bad

BID = "G0-89fe69e83a4f2ea81065ecf9d5d9ab46b0b5a29911fd4f6aa2fefd54dcc13456"
H = lambda c: c * 64
TOP = "Bku"
R0, R1 = f"r:/WORK/{TOP}/inner_a", f"r:/WORK/{TOP}/inner_b"
I0, I1 = f"i:/WORK/{TOP}/u_core/a", f"i:/WORK/{TOP}/u_core/b"

def T(i, r, m):  # pair triple
    return {"id": i, "ref_path": r, "impl_path": m}

def expect(**over):
    e = {"run_id": "RID-1", "target": TOP, "top": TOP, "variant": TOP,
         "proof_mode": "signoff-strict", "canonical_baseline_id": BID,
         "ref_digest": H("a"), "impl_digest": H("b"), "script_digest": H("c"),
         "tool_digest": H("d"),
         "allow": {"blackbox": [], "interface_only": [], "unmatched": []}}
    for k, v in over.items():
        if k == "allow" and isinstance(v, dict):
            e["allow"] = {**e["allow"], **v}
        else:
            e[k] = v
    return e

def facts(**over):
    f = {"native_verdict": "SUCCEEDED",
         "stats": {"passing": 2055, "failing": 0, "unverified": 0, "aborted": 0, "unread_notcompared": 0},
         "unmatched": {"compare_ref": 0, "compare_impl": 0, "unread_ref": 0, "unread_impl": 0,
                       "bbout_ref": 0, "bbout_impl": 0},
         "objects": {"blackbox": [], "interface_only": [], "unmatched": []},
         "qualifications": {"dont_verify_objects": [], "elab147": [], "relaxed_appvars": []}}
    for k, v in over.items():
        if "." in k:
            a, b = k.split("."); f[a] = dict(f[a]); f[a][b] = v
        else:
            f[k] = v
    return f

def build(fact_over=None, env_over=None, native_diverge=None, run_id="RID-1", top=TOP,
          raw_env=None):
    d = tempfile.mkdtemp()
    fx = facts(**(fact_over or {}))
    nat = {"schema": "fm-sidecar-native-v1", "run_id": run_id, "top": top, **fx}
    np = os.path.join(d, "native_facts.json")
    json.dump(nat, open(np, "w"))
    nat_sha = hashlib.sha256(open(np, "rb").read()).hexdigest()
    env_fx = facts(**(fact_over or {}))
    for k, v in (native_diverge or {}).items():
        if "." in k:
            a, b = k.split("."); env_fx[a] = dict(env_fx[a]); env_fx[a][b] = v
        else:
            env_fx[k] = v
    env = {"schema": "fm-sidecar-envelope-v1", "run_id": run_id, "target": TOP, "top": top,
           "variant": TOP, "proof_mode": "signoff-strict", "canonical_baseline_id": BID,
           "inputs_sha256": {"ref_srcs_digest": H("a"), "impl_srcs_digest": H("b")},
           "script_sha256": H("c"), "tool": {"fm_shell_digest": H("d")},
           "fm_shell_rc": 0, "native_facts_sha256": nat_sha, **env_fx}
    for k, v in (env_over or {}).items():
        if "." in k:
            a, b = k.split("."); env[a] = dict(env[a]); env[a][b] = v
        else:
            env[k] = v
    ep = os.path.join(d, "verdict.sidecar.json")
    if raw_env is not None:
        open(ep, "w").write(raw_env)
    else:
        json.dump(env, open(ep, "w"))
    return d, ep, np

def run(fact_over=None, env_over=None, native_diverge=None, exp=None, actual_rc=0,
        run_id="RID-1", top=TOP, drop_native=False, corrupt_native_sha=False,
        raw_env=None, symlink_env=False):
    d, ep, np = build(fact_over, env_over, native_diverge, run_id, top, raw_env)
    if corrupt_native_sha:
        open(np, "a").write(" ")
    if drop_native:
        os.unlink(np)
    path = ep
    if symlink_env:
        lp = ep + ".lnk"; os.symlink(ep, lp); path = lp
    try:
        v, q = verdict(path, exp if exp is not None else expect(), actual_rc, np)
    finally:
        shutil.rmtree(d, ignore_errors=True)
    return v, q.get("reason")

CASES = []
def C(name, want, **kw):
    CASES.append((name, want, kw))

# ================= 正样本 =================
C("strict_clean_success", "SUCCEEDED")

# ================= v5 新对抗 =================
# 交叉配对: 同样的 ref/impl 全集, 配对关系错(r0→i1, r1→i0)
GOOD_PAIRS = [T("A", R0, I0), T("B", R1, I1)]
CROSS_PAIRS = [T("A", R0, I1), T("B", R1, I0)]
def asm_pairs(pairs):
    return dict(fact_over={"unmatched.compare_ref": 2, "unmatched.compare_impl": 2,
                           "objects.unmatched": pairs,
                           "objects.interface_only": [T("A", R0, I0)]},
                env_over={"proof_mode": "assembly"})
AEXP2 = expect(proof_mode="assembly",
               allow={"unmatched": GOOD_PAIRS, "interface_only": [T("A", R0, I0)]})
C("asm_correct_pairs", "SUCCEEDED", **asm_pairs(GOOD_PAIRS), exp=AEXP2)
C("asm_crossed_pairs", "PARTIAL", **asm_pairs(CROSS_PAIRS), exp=AEXP2)
# interface_only impl_path 错
C("iface_wrong_impl", "PARTIAL",
  fact_over={"unmatched.compare_ref": 2, "unmatched.compare_impl": 2,
             "objects.unmatched": GOOD_PAIRS,
             "objects.interface_only": [T("A", R0, I1)]},
  env_over={"proof_mode": "assembly"}, exp=AEXP2)
# namespace 互换: ref_path 用 i:/, impl_path 用 r:/(类型层直接拒)
C("namespace_swap", "ERROR",
  fact_over={"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
             "objects.unmatched": [T("A", I0, R0)]},
  env_over={"proof_mode": "assembly"}, exp=AEXP2)
# 错误 top 的 namespace(路径不含本次 top)
C("namespace_wrong_top", "ERROR",
  fact_over={"objects.interface_only": [T("A", "r:/WORK/Other/x", "i:/WORK/Other/y")]},
  env_over={"proof_mode": "assembly"}, exp=AEXP2)
# Unicode 格式字符(零宽空格)混入 id
C("unicode_zwsp_id", "ERROR",
  fact_over={"objects.interface_only": [T("A​", R0, I0)]},
  env_over={"proof_mode": "assembly"}, exp=AEXP2)
# TOCTOU 面: envelope 是 symlink(O_NOFOLLOW 单开即拒)
C("symlink_envelope", "ERROR", symlink_env=True)

# ================= v4 回归 =================
C("token_trailing_newline", "ERROR", env_over={"target": "Bku\n"}, exp=expect(target="Bku\n"))
C("native_env_mismatch_verdict", "ERROR",
  fact_over={"native_verdict": "FAILED", "stats.failing": 20},
  native_diverge={"native_verdict": "SUCCEEDED", "stats.failing": 0})
C("native_env_mismatch_stats", "ERROR", native_diverge={"stats.passing": 9999})
C("native_sha_mismatch", "ERROR", corrupt_native_sha=True)
C("native_missing", "ERROR", drop_native=True)
C("inputs_null", "ERROR", env_over={"inputs_sha256": None})
C("stats_null", "ERROR", env_over={"stats": None})

# ================= v3 回归 =================
C("asm_count_asym_compare", "PARTIAL",
  fact_over={"unmatched.compare_ref": 5, "unmatched.compare_impl": 0,
             "objects.unmatched": GOOD_PAIRS, "objects.interface_only": [T("A", R0, I0)]},
  env_over={"proof_mode": "assembly"}, exp=AEXP2)
C("asm_count_asym_bbout", "PARTIAL",
  fact_over={"unmatched.bbout_ref": 5, "unmatched.bbout_impl": 0,
             "objects.blackbox": [T("A", R0, I0)]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly", allow={"blackbox": [T("A", R0, I0)]}))
C("both_empty_target", "ERROR", env_over={"target": ""}, exp=expect(target=""))
C("both_traversal_variant", "ERROR", env_over={"variant": "../../evil"},
  exp=expect(variant="../../evil"))
C("both_int_runid", "ERROR", env_over={"run_id": 5}, exp=expect(run_id=5))
C("strict_expect_with_allowlist", "ERROR",
  exp=expect(allow={"blackbox": [T("A", R0, I0)]}))
C("asm_count_only_no_objects", "PARTIAL",
  fact_over={"unmatched.compare_ref": 5, "unmatched.compare_impl": 5},
  env_over={"proof_mode": "assembly"}, exp=AEXP2)

# ================= v2 回归 =================
C("fake_baseline", "ERROR", env_over={"canonical_baseline_id": "G0-FAKE"})
C("bool_as_int", "ERROR", env_over={"fm_shell_rc": False, "stats.passing": True})
C("wrong_run_id", "ERROR", env_over={"run_id": "OLD"})
C("wrong_top_env", "ERROR", env_over={"top": "Xxx"}, run_id="RID-1")
C("wrong_variant", "ERROR", env_over={"variant": "Xxx"})
C("ref_digest_mismatch", "ERROR", env_over={"inputs_sha256.ref_srcs_digest": H("f")})
C("script_digest_mismatch", "ERROR", env_over={"script_sha256": H("f")})
C("tool_digest_mismatch", "ERROR", env_over={"tool.fm_shell_digest": H("f")})
C("mode_mismatch", "ERROR", env_over={"proof_mode": "assembly"})
C("actual_rc_nonzero", "ERROR", actual_rc=134)
C("selfreport_rc_nonzero", "ERROR", env_over={"fm_shell_rc": 137}, actual_rc=137)
C("rc_disagree", "ERROR", env_over={"fm_shell_rc": 0}, actual_rc=1)
C("empty_proof", "ERROR", fact_over={"stats.passing": 0})
C("success_but_failing", "FAILED", fact_over={"stats.failing": 20})
C("missing_field_stats", "ERROR", env_over={"stats": "DROP"})
C("bad_schema", "ERROR", env_over={"schema": "wrong"})
C("native_failed", "FAILED", fact_over={"native_verdict": "FAILED", "stats.failing": 5})
C("native_notrun", "UNRUN", fact_over={"native_verdict": "NOT_RUN"})
C("dup_keys_env", "ERROR", raw_env='{"schema":"fm-sidecar-envelope-v1","schema":"x"}')
C("nan_env", "ERROR", raw_env='{"schema":"fm-sidecar-envelope-v1","x":NaN}')
C("neg_count", "ERROR", fact_over={"stats.passing": -5})
C("uppercase_hash", "ERROR", env_over={"script_sha256": "A" * 64})
C("short_hash", "ERROR", env_over={"script_sha256": "a" * 63})
C("qual_unsorted", "ERROR", fact_over={"qualifications.dont_verify_objects": ["z", "a"]})
C("qual_dup", "ERROR", fact_over={"qualifications.dont_verify_objects": ["a", "a"]})
C("qual_empty_str", "ERROR", fact_over={"qualifications.dont_verify_objects": [""]})
C("elab147_bool", "ERROR", fact_over={"qualifications.elab147": True})
C("toplevel_list_env", "ERROR", raw_env='[1,2]')

# ================= strict qualification 回归 =================
C("strict_unread_nc", "PARTIAL", fact_over={"stats.unread_notcompared": 1})
C("strict_unread_um", "PARTIAL", fact_over={"unmatched.unread_impl": 19})
C("strict_blackbox_obj", "PARTIAL", fact_over={"objects.blackbox": [T("A", R0, I0)]})
C("strict_dontverify", "PARTIAL", fact_over={"qualifications.dont_verify_objects": ["io_x"]})
C("strict_elab147", "PARTIAL", fact_over={"qualifications.elab147": ["ram_40x47"]})
C("strict_relaxed_appvar", "PARTIAL", fact_over={"qualifications.relaxed_appvars": ["verify_unread"]})
C("strict_interface_only", "PARTIAL", fact_over={"objects.interface_only": [T("A", R0, I0)]})

# ================= shadow / diagnostic =================
C("shadow_only", "SHADOW_CHECK", env_over={"proof_mode": "shadow"}, exp=expect(proof_mode="shadow"))
C("diagnostic_never", "DIAGNOSTIC", env_over={"proof_mode": "diagnostic-full"},
  exp=expect(proof_mode="diagnostic-full"))

def main():
    npass = 0; total = 0
    for name, want, kw in CASES:
        eo = kw.get("env_over")
        if eo and eo.get("stats") == "DROP":  # missing field 特例
            kw = dict(kw)
            kw["raw_env"] = None
            d, ep, np = build()
            env = json.load(open(ep))
            del env["stats"]
            json.dump(env, open(ep, "w"))
            try:
                v, q = verdict(ep, expect(), 0, np)
                got, reason = v, q.get("reason")
            except Exception as e:
                got, reason = f"EXC:{type(e).__name__}", None
            shutil.rmtree(d, ignore_errors=True)
        else:
            try:
                got, reason = run(**kw)
            except Exception as e:
                got, reason = f"EXC:{type(e).__name__}", None
        ok = got == want
        npass += ok; total += 1
        print(f"{'PASS' if ok else 'FAIL'}  {name:32s} want={want:12s} got={got}"
              + ("" if ok else f"  reason={reason}"))
    # 补充: expectation dup-key strict_load 拒
    fd, p = tempfile.mkstemp(); os.close(fd)
    open(p, "w").write('{"a":1,"a":2}')
    try:
        strict_load(p); dup_ok = False
    except Bad:
        dup_ok = True
    except Exception:
        dup_ok = False
    os.unlink(p)
    npass += dup_ok; total += 1
    print(f"{'PASS' if dup_ok else 'FAIL'}  expectation_dup_keys              want=Bad got={'Bad' if dup_ok else 'accepted'}")
    # 非 SUCCEEDED 全带非 None reason
    for want_v, kw in (("FAILED", dict(fact_over={"stats.failing": 20})),
                       ("UNRUN", dict(fact_over={"native_verdict": "NOT_RUN"})),
                       ("SHADOW_CHECK", dict(env_over={"proof_mode": "shadow"}, exp=expect(proof_mode="shadow"))),
                       ("DIAGNOSTIC", dict(env_over={"proof_mode": "diagnostic-full"}, exp=expect(proof_mode="diagnostic-full")))):
        got_v, reason = run(**kw)
        ok = got_v == want_v and reason is not None
        npass += ok; total += 1
        print(f"{'PASS' if ok else 'FAIL'}  reason_not_none_{want_v:14s} got={got_v} reason={reason}")
    print(f"\n{npass}/{total} passed")
    sys.exit(0 if npass == total else 1)

if __name__ == "__main__":
    main()

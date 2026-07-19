#!/usr/bin/env python3
"""FM sidecar validator 负向测试(2026-07-19 四审 v4)。
新增: token 尾换行 / native_facts 密码学绑定 / 显式 {id,ref_path,impl_path} 映射 /
畸形输入鲁棒 / 全 verdict 非 None reason。"""
import sys, os, json, hashlib, tempfile, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_sidecar_verdict import verdict, strict_load, Bad

BID = "G0-89fe69e83a4f2ea81065ecf9d5d9ab46b0b5a29911fd4f6aa2fefd54dcc13456"
H = lambda c: c * 64
RREF = "r:/WORK/Backend/inner_sub"
RIMP = "i:/WORK/Backend/u_core/sub"

def amap(i="Sub", r=RREF, m=RIMP):
    return {"id": i, "ref_path": r, "impl_path": m}

def expect(**over):
    e = {"run_id": "RID-1", "target": "Bku", "top": "Bku", "variant": "Bku",
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
         "objects": {"blackbox_ref": [], "blackbox_impl": [], "interface_only": [],
                     "unmatched_ref": [], "unmatched_impl": []},
         "qualifications": {"dont_verify_objects": [], "elab147": [], "relaxed_appvars": []}}
    for k, v in over.items():
        if "." in k:
            a, b = k.split("."); f[a] = dict(f[a]); f[a][b] = v
        else:
            f[k] = v
    return f

def build(fact_over=None, env_over=None, native_diverge=None, run_id="RID-1", top="Bku"):
    """产 native_facts 文件 + envelope 文件(sha 正确绑定, 除非 native_diverge 指定)。"""
    d = tempfile.mkdtemp()
    fx = facts(**(fact_over or {}))
    nat = {"schema": "fm-sidecar-native-v1", "run_id": run_id, "top": top, **fx}
    np = os.path.join(d, "native_facts.json")
    json.dump(nat, open(np, "w"))
    nat_sha = hashlib.sha256(open(np, "rb").read()).hexdigest()
    env_fx = facts(**(fact_over or {}))
    if native_diverge:  # envelope 与 native 分叉(runner 合并错场景)
        for k, v in native_diverge.items():
            if "." in k:
                a, b = k.split("."); env_fx[a] = dict(env_fx[a]); env_fx[a][b] = v
            else:
                env_fx[k] = v
    env = {"schema": "fm-sidecar-envelope-v1", "run_id": run_id, "target": "Bku", "top": top,
           "variant": "Bku", "proof_mode": "signoff-strict", "canonical_baseline_id": BID,
           "inputs_sha256": {"ref_srcs_digest": H("a"), "impl_srcs_digest": H("b")},
           "script_sha256": H("c"), "tool": {"fm_shell_digest": H("d")},
           "fm_shell_rc": 0, "native_facts_sha256": nat_sha, **env_fx}
    for k, v in (env_over or {}).items():
        if "." in k:
            a, b = k.split("."); env[a] = dict(env[a]); env[a][b] = v
        else:
            env[k] = v
    ep = os.path.join(d, "verdict.sidecar.json")
    json.dump(env, open(ep, "w"))
    return d, ep, np

def run(fact_over=None, env_over=None, native_diverge=None, exp=None, actual_rc=0,
        run_id="RID-1", top="Bku", drop_native=False, corrupt_native_sha=False):
    d, ep, np = build(fact_over, env_over, native_diverge, run_id, top)
    if corrupt_native_sha:
        open(np, "a").write(" ")   # native 文件被改, sha 不再匹配
    if drop_native:
        os.unlink(np)
    try:
        v, q = verdict(ep, exp if exp is not None else expect(), actual_rc, np)
    finally:
        shutil.rmtree(d, ignore_errors=True)
    return v, q.get("reason")

CASES = []
def C(name, want, **kw):
    CASES.append((name, want, kw))

# ===== 正样本 =====
C("strict_clean_success", "SUCCEEDED")

# ===== 四审新假绿 =====
# 1. token 尾换行(两侧同值)
C("token_trailing_newline", "ERROR",
  env_over={"target": "Bku\n"}, exp=expect(target="Bku\n"))
C("allow_id_trailing_newline", "ERROR",
  exp=expect(proof_mode="assembly",
             allow={"unmatched": [{"id": "Sub\n", "ref_path": RREF, "impl_path": RIMP}]}),
  env_over={"proof_mode": "assembly"})
# 2. native FAILED + envelope SUCCEEDED(runner 合并错)→ ERROR
C("native_env_mismatch_verdict", "ERROR",
  fact_over={"native_verdict": "FAILED", "stats.failing": 20},
  native_diverge={"native_verdict": "SUCCEEDED", "stats.failing": 0})
# native stats 分叉
C("native_env_mismatch_stats", "ERROR",
  native_diverge={"stats.passing": 9999})
# native_facts sha 不匹配(文件被改)
C("native_sha_mismatch", "ERROR", corrupt_native_sha=True)
# native 文件缺失
C("native_missing", "ERROR", drop_native=True)

# ===== 畸形输入鲁棒(不抛异常)=====
C("inputs_null", "ERROR", env_over={"inputs_sha256": None})
C("stats_null", "ERROR", env_over={"stats": None})
# 顶层 list 的 envelope
def _run_toplevel_list():
    d = tempfile.mkdtemp()
    ep = os.path.join(d, "e.json"); np = os.path.join(d, "n.json")
    json.dump([1, 2], open(ep, "w")); json.dump({}, open(np, "w"))
    try:
        v, q = verdict(ep, expect(), 0, np)
    except Exception as e:
        return f"EXC:{type(e).__name__}", None
    finally:
        shutil.rmtree(d, ignore_errors=True)
    return v, q.get("reason")

# ===== 三审假绿回归 =====
C("asm_count_asym_compare", "PARTIAL",
  fact_over={"unmatched.compare_ref": 5, "unmatched.compare_impl": 0,
             "objects.unmatched_ref": [RREF], "objects.unmatched_impl": [RIMP],
             "objects.interface_only": [RREF]},
  env_over={"proof_mode": "assembly"},
  exp=expect(proof_mode="assembly",
             allow={"interface_only": [amap()], "unmatched": [amap()]}))
C("both_empty_target", "ERROR", env_over={"target": ""}, exp=expect(target=""))
C("strict_expect_with_allowlist", "ERROR", exp=expect(allow={"blackbox": [amap()]}))

# ===== v2 假绿回归 =====
C("fake_baseline", "ERROR", env_over={"canonical_baseline_id": "G0-FAKE"})
C("bool_as_int", "ERROR", env_over={"fm_shell_rc": False, "stats.passing": True})
C("wrong_run_id", "ERROR", env_over={"run_id": "OLD"})
C("actual_rc_nonzero", "ERROR", actual_rc=134)
C("rc_disagree", "ERROR", env_over={"fm_shell_rc": 0}, actual_rc=1)
C("empty_proof", "ERROR", fact_over={"stats.passing": 0})
C("success_but_failing", "FAILED", fact_over={"stats.failing": 20})
C("native_failed", "FAILED", fact_over={"native_verdict": "FAILED", "stats.failing": 5})
C("native_notrun", "UNRUN", fact_over={"native_verdict": "NOT_RUN"})

# ===== strict qualification =====
C("strict_unread_nc", "PARTIAL", fact_over={"stats.unread_notcompared": 1})
C("strict_blackbox_obj", "PARTIAL", fact_over={"objects.blackbox_impl": [RIMP]})
C("strict_dontverify", "PARTIAL", fact_over={"qualifications.dont_verify_objects": ["io_x"]})
C("strict_elab147", "PARTIAL", fact_over={"qualifications.elab147": ["ram_40x47"]})
C("strict_interface_only", "PARTIAL", fact_over={"objects.interface_only": [RREF]})

# ===== assembly 显式映射 =====
AEXP = expect(proof_mode="assembly",
              allow={"interface_only": [amap()], "unmatched": [amap()]})
C("asm_mapped_success", "SUCCEEDED",
  fact_over={"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
             "objects.unmatched_ref": [RREF], "objects.unmatched_impl": [RIMP],
             "objects.interface_only": [RREF]},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
C("asm_wrong_ref_path", "PARTIAL",
  fact_over={"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
             "objects.unmatched_ref": ["r:/WORK/Backend/rogue"], "objects.unmatched_impl": [RIMP],
             "objects.interface_only": [RREF]},
  env_over={"proof_mode": "assembly"}, exp=AEXP)
C("asm_count_only_no_objects", "PARTIAL",
  fact_over={"unmatched.compare_ref": 5, "unmatched.compare_impl": 5},
  env_over={"proof_mode": "assembly"}, exp=AEXP)

# ===== shadow / diagnostic =====
C("shadow_only", "SHADOW_CHECK", env_over={"proof_mode": "shadow"},
  exp=expect(proof_mode="shadow"))
C("diagnostic_never", "DIAGNOSTIC", env_over={"proof_mode": "diagnostic-full"},
  exp=expect(proof_mode="diagnostic-full"))

def main():
    npass = 0; total = 0
    for name, want, kw in CASES:
        kw.pop("fact_over", None) if kw.get("fact_over") == {"proof_mode": None} else None
        fo = kw.pop("fact_over", None)
        if fo and fo.get("proof_mode", "x") is None:
            fo.pop("proof_mode")
        try:
            got, reason = run(fact_over=fo, **kw)
        except Exception as e:
            got, reason = f"EXC:{type(e).__name__}", None
        ok = got == want
        npass += ok; total += 1
        print(f"{'PASS' if ok else 'FAIL'}  {name:32s} want={want:12s} got={got}"
              + ("" if ok else f"  reason={reason}"))
    # 顶层 list 鲁棒
    got, _ = _run_toplevel_list()
    ok = got == "ERROR"; npass += ok; total += 1
    print(f"{'PASS' if ok else 'FAIL'}  toplevel_list_envelope           want=ERROR        got={got}")
    # 全部非 SUCCEEDED verdict 必须带非 None reason
    checks = [
        ("FAILED", run(fact_over={"stats.failing": 20})),
        ("UNRUN", run(fact_over={"native_verdict": "NOT_RUN"})),
        ("SHADOW_CHECK", run(env_over={"proof_mode": "shadow"}, exp=expect(proof_mode="shadow"))),
        ("DIAGNOSTIC", run(env_over={"proof_mode": "diagnostic-full"}, exp=expect(proof_mode="diagnostic-full"))),
    ]
    for want_v, (got_v, reason) in checks:
        ok = got_v == want_v and reason is not None
        npass += ok; total += 1
        print(f"{'PASS' if ok else 'FAIL'}  reason_not_none_{want_v:14s} got={got_v} reason={reason}")
    print(f"\n{npass}/{total} passed")
    sys.exit(0 if npass == total else 1)

if __name__ == "__main__":
    main()

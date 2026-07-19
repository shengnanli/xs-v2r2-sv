#!/usr/bin/env python3
"""FM sidecar validator 负向测试(2026-07-19 三审 v3)。
含三审独立复现的 6 条新假绿(assembly 数量不对称/身份格式/strict 带 allowlist/symlink/dup-key)。"""
import sys, os, json, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_sidecar_verdict import verdict, strict_load, Bad

BID = "G0-89fe69e83a4f2ea81065ecf9d5d9ab46b0b5a29911fd4f6aa2fefd54dcc13456"
H = lambda c: c * 64

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

def good(**over):
    s = {
        "schema": "fm-sidecar-envelope-v1", "run_id": "RID-1", "target": "Bku", "top": "Bku",
        "variant": "Bku", "proof_mode": "signoff-strict", "canonical_baseline_id": BID,
        "inputs_sha256": {"ref_srcs_digest": H("a"), "impl_srcs_digest": H("b")},
        "script_sha256": H("c"), "tool": {"fm_shell_digest": H("d")},
        "fm_shell_rc": 0, "native_verdict": "SUCCEEDED",
        "stats": {"passing": 2055, "failing": 0, "unverified": 0, "aborted": 0, "unread_notcompared": 0},
        "unmatched": {"compare_ref": 0, "compare_impl": 0, "unread_ref": 0, "unread_impl": 0,
                      "bbout_ref": 0, "bbout_impl": 0},
        "objects": {"blackbox_ref": [], "blackbox_impl": [], "interface_only": [],
                    "unmatched_ref": [], "unmatched_impl": []},
        "qualifications": {"dont_verify_objects": [], "elab147": [], "relaxed_appvars": []},
    }
    for k, v in over.items():
        if "." in k:
            a, b = k.split("."); s[a] = dict(s[a]); s[a][b] = v
        else:
            s[k] = v
    return s

def run(sc, exp=None, actual_rc=0, raw=None, symlink=False):
    fd, p = tempfile.mkstemp(suffix=".json"); os.close(fd)
    if raw is not None:
        open(p, "w").write(raw)
    else:
        json.dump(sc, open(p, "w"))
    path = p
    if symlink:
        lp = p + ".lnk"
        os.symlink(p, lp); path = lp
    r = verdict(path, expectation=exp if exp is not None else expect(), actual_rc=actual_rc)
    if symlink: os.unlink(lp)
    os.unlink(p)
    return r[0], r[1].get("reason")

CASES = []
def C(name, want, sc=None, **kw):
    CASES.append((name, sc, want, kw))

# ===== 正样本 =====
C("strict_clean_success", "SUCCEEDED", good())

# ===== 三审 6 条新假绿(必须拒)=====
# 1. assembly 对象完全对称但数量不对称 compare 5(0)
C("asm_objsym_count_asym_compare", "PARTIAL",
  good(proof_mode="assembly",
       **{"unmatched.compare_ref": 5, "unmatched.compare_impl": 0,
          "objects.unmatched_ref": ["Sub"], "objects.unmatched_impl": ["Sub"],
          "objects.interface_only": ["Sub"]}),
  exp=expect(proof_mode="assembly", allow={"interface_only": ["Sub"], "unmatched": ["Sub"]}))
# 2. 黑盒对象对称但 bbout 5(0)
C("asm_objsym_count_asym_bbout", "PARTIAL",
  good(proof_mode="assembly",
       **{"unmatched.bbout_ref": 5, "unmatched.bbout_impl": 0,
          "objects.blackbox_ref": ["Ram"], "objects.blackbox_impl": ["Ram"]}),
  exp=expect(proof_mode="assembly", allow={"blackbox": ["Ram"]}))
# 3a. sidecar+expectation 同用空 target
C("both_empty_target", "ERROR", good(target=""), exp=expect(target=""))
# 3b. 同用路径遍历 variant
C("both_traversal_variant", "ERROR", good(variant="../../evil"), exp=expect(variant="../../evil"))
# 3c. 同用整数 run_id/baseline
C("both_int_runid", "ERROR", good(run_id=5, canonical_baseline_id=7),
  exp=expect(run_id=5, canonical_baseline_id=7))
# 4. strict expectation 带非空 allow_objects
C("strict_expect_with_allowlist", "ERROR", good(),
  exp=expect(allow={"blackbox": ["X"]}))
# 5. sidecar 路径是 symlink
C("sidecar_symlink", "ERROR", good(), symlink=True)
# 6. expectation 重复键(strict_load 层, 单测见 main 尾部)

# ===== v2 保留的假绿(回归)=====
C("wrong_target_empty_inputs", "ERROR",
  good(target="Evil", variant="Evil", script_sha256="notahash",
       **{"inputs_sha256.ref_srcs_digest": ""}))
C("fake_baseline", "ERROR", good(canonical_baseline_id="G0-FAKE"))
C("passing_nan", "ERROR", raw=json.dumps(good()).replace('2055', 'NaN'))
C("bool_as_int", "ERROR", good(fm_shell_rc=False, **{"stats.passing": True}))
C("assembly_count_only_no_objects", "PARTIAL",
  good(proof_mode="assembly", **{"unmatched.compare_ref": 5, "unmatched.compare_impl": 5}),
  exp=expect(proof_mode="assembly", allow={"unmatched": ["Sub"], "interface_only": ["Sub"]}))

# ===== 强类型 =====
C("dup_keys_sidecar", "ERROR", raw='{"schema":"fm-sidecar-envelope-v1","schema":"x"}')
C("neg_count", "ERROR", good(**{"stats.passing": -5}))
C("uppercase_hash", "ERROR", good(script_sha256="A"*64))
C("short_hash", "ERROR", good(script_sha256="a"*63))
C("objects_unsorted", "ERROR", good(**{"objects.blackbox_impl": ["Z", "A"]}))
C("objects_dup", "ERROR", good(**{"objects.blackbox_impl": ["A", "A"]}))
C("objects_empty_str", "ERROR", good(**{"objects.blackbox_impl": [""]}))
C("elab147_bool", "ERROR", good(**{"qualifications.elab147": True}))

# ===== expectation 精确相等 =====
C("wrong_run_id", "ERROR", good(run_id="OLD"))
C("wrong_top", "ERROR", good(top="X"))
C("wrong_variant", "ERROR", good(variant="X"))
C("ref_digest_mismatch", "ERROR", good(**{"inputs_sha256.ref_srcs_digest": H("f")}))
C("script_digest_mismatch", "ERROR", good(script_sha256=H("f")))
C("tool_digest_mismatch", "ERROR", good(**{"tool.fm_shell_digest": H("f")}))
C("mode_mismatch", "ERROR", good(proof_mode="assembly"))

# ===== rc 交叉 =====
C("actual_rc_nonzero", "ERROR", good(), actual_rc=134)
C("selfreport_rc_nonzero", "ERROR", good(fm_shell_rc=137), actual_rc=137)
C("rc_disagree", "ERROR", good(fm_shell_rc=0), actual_rc=1)

# ===== native / 数字 =====
C("empty_proof", "ERROR", good(**{"stats.passing": 0}))
C("success_but_failing", "FAILED", good(**{"stats.failing": 20}))
C("missing_field", "ERROR", {k: v for k, v in good().items() if k != "stats"})
C("bad_schema", "ERROR", good(schema="wrong"))
C("native_failed", "FAILED", good(native_verdict="FAILED", **{"stats.failing": 5}))
C("native_notrun", "UNRUN", good(native_verdict="NOT_RUN"))

# ===== strict qualification =====
C("strict_unread_nc", "PARTIAL", good(**{"stats.unread_notcompared": 1}))
C("strict_unread_um", "PARTIAL", good(**{"unmatched.unread_impl": 19}))
C("strict_blackbox_obj", "PARTIAL", good(**{"objects.blackbox_impl": ["FooRAM"]}))
C("strict_dontverify", "PARTIAL", good(**{"qualifications.dont_verify_objects": ["io_x"]}))
C("strict_elab147", "PARTIAL", good(**{"qualifications.elab147": ["ram_40x47"]}))
C("strict_relaxed_appvar", "PARTIAL", good(**{"qualifications.relaxed_appvars": ["verify_unread"]}))
C("strict_interface_only", "PARTIAL", good(**{"objects.interface_only": ["Sub"]}))

# ===== assembly 分类 allowlist =====
def asm(**o): return good(proof_mode="assembly", **o)
AEXP = expect(proof_mode="assembly", allow={"interface_only": ["Sub"], "unmatched": ["Sub"]})
C("asm_symmetric_declared", "SUCCEEDED",
  asm(**{"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
         "objects.unmatched_ref": ["Sub"], "objects.unmatched_impl": ["Sub"],
         "objects.interface_only": ["Sub"]}), exp=AEXP)
C("asm_multipin_one_object", "SUCCEEDED",
  asm(**{"unmatched.compare_ref": 2, "unmatched.compare_impl": 2,
         "objects.unmatched_ref": ["Sub"], "objects.unmatched_impl": ["Sub"],
         "objects.interface_only": ["Sub"]}), exp=AEXP)
C("asm_obj_asym", "PARTIAL",
  asm(**{"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
         "objects.unmatched_ref": ["Sub"], "objects.unmatched_impl": ["Other"],
         "objects.interface_only": ["Sub"]}), exp=AEXP)
C("asm_undeclared_object", "PARTIAL",
  asm(**{"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
         "objects.unmatched_ref": ["Rogue"], "objects.unmatched_impl": ["Rogue"],
         "objects.interface_only": ["Rogue"]}), exp=AEXP)
# 类别互换: 把黑盒对象放进 unmatched 类别 → 与分类 allowlist 不符 → PARTIAL
C("asm_category_swap", "PARTIAL",
  asm(**{"unmatched.bbout_ref": 1, "unmatched.bbout_impl": 1,
         "objects.blackbox_ref": ["Sub"], "objects.blackbox_impl": ["Sub"],
         "objects.interface_only": ["Sub"]}), exp=AEXP)  # allow.blackbox 为空

# ===== shadow / diagnostic =====
C("shadow_only", "SHADOW_CHECK", good(proof_mode="shadow"), exp=expect(proof_mode="shadow"))
C("diagnostic_never", "DIAGNOSTIC", good(proof_mode="diagnostic-full"),
  exp=expect(proof_mode="diagnostic-full"))

def main():
    npass = 0
    for name, sc, want, kw in CASES:
        try:
            got, reason = run(sc, **kw)
        except Exception as e:
            got, reason = f"EXC:{type(e).__name__}", None
        ok = got == want
        npass += ok
        print(f"{'PASS' if ok else 'FAIL'}  {name:34s} want={want:12s} got={got}"
              + ("" if ok else f"  reason={reason}"))
    # 6. expectation 重复键: strict_load 必须拒
    import tempfile as tf
    fd, p = tf.mkstemp(); os.close(fd)
    open(p, "w").write('{"run_id":"A","run_id":"B"}')
    try:
        strict_load(p); dup_ok = False
    except Bad:
        dup_ok = True
    except Exception:
        dup_ok = False
    os.unlink(p)
    npass += dup_ok
    print(f"{'PASS' if dup_ok else 'FAIL'}  expectation_dup_keys_strict_load    want=Bad          got={'Bad' if dup_ok else 'accepted'}")
    total = len(CASES) + 1
    # reason 覆盖回归: PARTIAL 必须带非 None reason
    got, reason = run(good(**{"stats.unread_notcompared": 1}))
    r_ok = got == "PARTIAL" and reason is not None
    npass += r_ok
    total += 1
    print(f"{'PASS' if r_ok else 'FAIL'}  partial_reason_not_none             want=nonNone      got={reason}")
    print(f"\n{npass}/{total} passed")
    sys.exit(0 if npass == total else 1)

if __name__ == "__main__":
    main()

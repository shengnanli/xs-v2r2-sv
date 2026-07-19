#!/usr/bin/env python3
"""FM sidecar validator 负向测试(2026-07-19 二审, 测试先行)。
validator 接收 (sidecar_path, expectation, actual_rc):
 - expectation = 外部权威 manifest(run_id/target/top/variant/proof_mode/baseline/
   ref_digest/impl_digest/script_digest/tool_digest/allow_objects), 每项精确相等。
 - actual_rc = runner 获取的**真实进程 rc**(不信 sidecar 自报 rc)。
 - sidecar 强类型: 拒 NaN/Inf/dup-key/bool-as-int/非64hex/无序或重复对象。
"""
import sys, os, json, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_sidecar_verdict import verdict

BID = "G0-89fe69e83a4f2ea81065ecf9d5d9ab46b0b5a29911fd4f6aa2fefd54dcc13456"
H = lambda c: c * 64  # 64-hex

def expect(**over):
    e = {"run_id": "RID-1", "target": "Bku", "top": "Bku", "variant": "Bku",
         "proof_mode": "signoff-strict", "canonical_baseline_id": BID,
         "ref_digest": H("a"), "impl_digest": H("b"), "script_digest": H("c"),
         "tool_digest": H("d"), "allow_objects": []}
    e.update(over); return e

def good(**over):
    s = {
        "schema": "fm-sidecar-v1", "run_id": "RID-1", "target": "Bku", "top": "Bku",
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

def run(sc, exp=None, actual_rc=0, raw=None):
    fd, p = tempfile.mkstemp(suffix=".json"); os.close(fd)
    if raw is not None:
        open(p, "w").write(raw)
    else:
        json.dump(sc, open(p, "w"))
    r = verdict(p, expectation=exp or expect(), actual_rc=actual_rc)
    os.unlink(p)
    return r[0]

CASES = []
def C(name, want, sc=None, **kw):
    CASES.append((name, sc, want, kw))

# 正样本
C("strict_clean_success", "SUCCEEDED", good())

# ===== 审查复现的 5 条假绿(必须转 ERROR/PARTIAL)=====
# 1. target/variant 错误, inputs/tool 空, script 非 hash —— expectation 精确相等应拒
C("wrong_target_empty_inputs", "ERROR",
  good(target="Evil", variant="Evil", script_sha256="notahash",
       **{"inputs_sha256.ref_srcs_digest": ""}))
# 2. sidecar 写假 baseline(expectation 权威, 必拒)
C("fake_baseline", "ERROR", good(canonical_baseline_id="G0-FAKE"))
# 3. passing = NaN
C("passing_nan", "ERROR", raw='{"x":1}'.replace('{"x":1}', json.dumps(good()).replace('2055', 'NaN')))
# 4. fm_shell_rc=false, passing=true(bool 混入)
C("bool_as_int", "ERROR", good(fm_shell_rc=False, **{"stats.passing": True}))
# 5. assembly 只有对称数量 5/5, 无任何对象身份
C("assembly_count_only_no_objects", "PARTIAL",
  good(proof_mode="assembly", **{"unmatched.compare_ref": 5, "unmatched.compare_impl": 5}),
  exp=expect(proof_mode="assembly", allow_objects=["Sub"]))

# ===== 强类型 =====
C("dup_keys", "ERROR", raw='{"schema":"fm-sidecar-v1","schema":"x"}')
C("infinity", "ERROR", raw=json.dumps(good()).replace('0', 'Infinity', 1) if False else
  json.dumps(good())[:-1] + ',"extra":Infinity}')
C("neg_count", "ERROR", good(**{"stats.passing": -5}))
C("elab147_not_list", "ERROR", good(**{"qualifications.elab147": True}))  # 现在 elab147 是对象列表
C("uppercase_hash", "ERROR", good(script_sha256="A"*64))
C("short_hash", "ERROR", good(script_sha256="a"*63))
C("objects_unsorted", "ERROR", good(**{"objects.blackbox_impl": ["Z", "A"]}))
C("objects_dup", "ERROR", good(**{"objects.blackbox_impl": ["A", "A"]}))
C("objects_empty_str", "ERROR", good(**{"objects.blackbox_impl": [""]}))

# ===== expectation 精确相等 =====
C("wrong_run_id", "ERROR", good(run_id="OLD"))
C("wrong_top", "ERROR", good(top="X"))
C("wrong_variant", "ERROR", good(variant="X"))
C("ref_digest_mismatch", "ERROR", good(**{"inputs_sha256.ref_srcs_digest": H("f")}))
C("script_digest_mismatch", "ERROR", good(script_sha256=H("f")))
C("tool_digest_mismatch", "ERROR", good(**{"tool.fm_shell_digest": H("f")}))
C("mode_mismatch", "ERROR", good(proof_mode="assembly"))

# ===== rc 交叉(真实进程 rc, 不信自报)=====
C("actual_rc_nonzero", "ERROR", good(), actual_rc=134)              # 自报0但真实134
C("selfreport_rc_nonzero", "ERROR", good(fm_shell_rc=137), actual_rc=137)
C("rc_disagree", "ERROR", good(fm_shell_rc=0), actual_rc=1)         # 自报≠真实

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
C("strict_blackbox", "PARTIAL", good(**{"objects.blackbox_impl": ["FooRAM"]},
                                     **{"unmatched.bbout_impl": 3}))
C("strict_dontverify", "PARTIAL", good(**{"qualifications.dont_verify_objects": ["io_x"]}))
C("strict_elab147", "PARTIAL", good(**{"qualifications.elab147": ["ram_40x47"]}))
C("strict_relaxed_appvar", "PARTIAL", good(**{"qualifications.relaxed_appvars": ["verify_unread"]}))
C("strict_interface_only_nonempty", "PARTIAL", good(**{"objects.interface_only": ["Sub"]}))

# ===== assembly 对象身份 =====
def asm(**o):
    return good(proof_mode="assembly", **o)
C("assembly_symmetric_declared", "SUCCEEDED",
  asm(**{"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
         "objects.unmatched_ref": ["Sub"], "objects.unmatched_impl": ["Sub"],
         "objects.interface_only": ["Sub"]}),
  exp=expect(proof_mode="assembly", allow_objects=["Sub"]))
C("assembly_asymmetric_objects", "PARTIAL",
  asm(**{"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
         "objects.unmatched_ref": ["Sub"], "objects.unmatched_impl": ["Other"],
         "objects.interface_only": ["Sub"]}),
  exp=expect(proof_mode="assembly", allow_objects=["Sub"]))
C("assembly_undeclared_object", "PARTIAL",
  asm(**{"unmatched.compare_ref": 1, "unmatched.compare_impl": 1,
         "objects.unmatched_ref": ["Rogue"], "objects.unmatched_impl": ["Rogue"],
         "objects.interface_only": ["Rogue"]}),
  exp=expect(proof_mode="assembly", allow_objects=["Sub"]))
# 合法: 一个声明黑盒 Sub 拥有多个(2)未配对引脚, 对象身份==allowlist → SUCCEEDED
C("assembly_multipin_one_object", "SUCCEEDED",
  asm(**{"unmatched.compare_ref": 2, "unmatched.compare_impl": 2,
         "objects.unmatched_ref": ["Sub"], "objects.unmatched_impl": ["Sub"],
         "objects.interface_only": ["Sub"]}),
  exp=expect(proof_mode="assembly", allow_objects=["Sub"]))
# count>0 但对象身份缺失(只有数量) → PARTIAL(已由 assembly_count_only_no_objects 覆盖, 此处再钉)
C("assembly_count_without_object", "PARTIAL",
  asm(**{"unmatched.compare_ref": 2, "unmatched.compare_impl": 2,
         "objects.interface_only": ["Sub"]}),  # unmatched_ref/impl 空 → bool 不一致
  exp=expect(proof_mode="assembly", allow_objects=["Sub"]))

# ===== shadow / diagnostic =====
C("shadow_only", "SHADOW_CHECK", good(proof_mode="shadow"),
  exp=expect(proof_mode="shadow"))
C("diagnostic_never", "DIAGNOSTIC", good(proof_mode="diagnostic-full"),
  exp=expect(proof_mode="diagnostic-full"))

def main():
    npass = 0
    for name, sc, want, kw in CASES:
        try:
            got = run(sc, **kw)
        except Exception as e:
            got = f"EXC:{type(e).__name__}"
        ok = got == want
        npass += ok
        print(f"{'PASS' if ok else 'FAIL'}  {name:34s} want={want:12s} got={got}")
    print(f"\n{npass}/{len(CASES)} passed")
    sys.exit(0 if npass == len(CASES) else 1)

if __name__ == "__main__":
    main()

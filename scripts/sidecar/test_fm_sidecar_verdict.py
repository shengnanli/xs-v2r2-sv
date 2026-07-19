#!/usr/bin/env python3
"""FM sidecar validator 负向测试(2026-07-19, 测试先行)。覆盖审查要求的全部场景。
sidecar 是机器可读 JSON(Tcl 原子写), validator 只读它, 不 grep 人读日志。"""
import sys, os, json, tempfile
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fm_sidecar_verdict import verdict

BID = "G0-89fe69e83a4f2ea81065ecf9d5d9ab46b0b5a29911fd4f6aa2fefd54dcc13456"

def good(**over):
    """一个合法 strict SUCCEEDED sidecar, 用 over 覆盖字段做负向变体。"""
    s = {
        "schema": "fm-sidecar-v1", "run_id": "RID-1", "target": "Bku", "top": "Bku",
        "variant": "Bku", "proof_mode": "signoff-strict", "canonical_baseline_id": BID,
        "inputs_sha256": {"ref_srcs_digest": "a"*64, "impl_srcs_digest": "b"*64},
        "script_sha256": "c"*64, "tool": {"fm_shell_version": "V-2023.12-SP3"},
        "fm_shell_rc": 0, "native_verdict": "SUCCEEDED",
        "stats": {"passing": 2055, "failing": 0, "unverified": 0, "aborted": 0, "unread_notcompared": 0},
        "unmatched": {"compare_ref": 0, "compare_impl": 0, "unread_ref": 0, "unread_impl": 0,
                      "bbout_ref": 0, "bbout_impl": 0},
        "qualifications": {"dont_verify_objects": [], "elab147": False,
                           "blackbox_objects": [], "interface_only": []},
    }
    for k, v in over.items():
        if "." in k:
            a, b = k.split("."); s[a] = dict(s[a]); s[a][b] = v
        else:
            s[k] = v
    return s

def run(sc, expected_run_id="RID-1", expected_top=None, mode=None, allow=None, baseline=BID):
    fd, p = tempfile.mkstemp(suffix=".json"); os.close(fd)
    json.dump(sc, open(p, "w"))
    r = verdict(p, expected_run_id=expected_run_id, expected_top=expected_top,
                expected_mode=mode, allow_objects=allow, baseline_id=baseline)
    os.unlink(p)
    return r[0]

CASES = []
def C(name, sc_or_none, want, **kw):
    CASES.append((name, sc_or_none, want, kw))

# 正样本
C("strict_clean_success", good(), "SUCCEEDED")
# 旧日志 / run_id 不匹配
C("wrong_run_id", good(run_id="OLD-999"), "ERROR")
# wrong top
C("wrong_top", good(top="EvilMod"), "ERROR", expected_top="Bku")
# 空证明 passing=0
C("empty_proof", good(**{"stats.passing": 0}), "ERROR")
# 成功 marker 但 failing>0(native SUCCEEDED 矛盾)
C("success_but_failing", good(**{"stats.failing": 20}), "FAILED")
# fm_shell 非零 rc
C("nonzero_rc", good(fm_shell_rc=137), "ERROR")
# 缺字段(截断 sidecar)
C("missing_field", {k: v for k, v in good().items() if k != "stats"}, "ERROR")
# schema 错
C("bad_schema", good(schema="wrong"), "ERROR")
# native FAILED
C("native_failed", good(native_verdict="FAILED", **{"stats.failing": 5}), "FAILED")
# native NOT_RUN
C("native_notrun", good(native_verdict="NOT_RUN"), "UNRUN")
# unread(not-compared)非 0 → strict PARTIAL
C("strict_unread_nc", good(**{"stats.unread_notcompared": 1}), "PARTIAL")
# unmatched-unread 两侧 → strict PARTIAL
C("strict_unread_um", good(**{"unmatched.unread_impl": 19}), "PARTIAL")
# unresolved blackbox(strict 拒)
C("strict_blackbox", good(**{"qualifications.blackbox_objects": ["FooRAM"]}), "PARTIAL")
# 未声明 dont-verify
C("strict_dontverify", good(**{"qualifications.dont_verify_objects": ["io_x"]}), "PARTIAL")
# ELAB147
C("strict_elab147", good(**{"qualifications.elab147": True}), "PARTIAL")
# 非对称 assembly 5(0) 即便声明配额
C("assembly_asymmetric", good(proof_mode="assembly",
    **{"unmatched.compare_ref": 5, "unmatched.compare_impl": 0}), "PARTIAL", mode="assembly", allow=["Sub"])
# assembly 对称且声明对象 → SUCCEEDED
C("assembly_symmetric_declared", good(proof_mode="assembly",
    **{"unmatched.compare_ref": 5, "unmatched.compare_impl": 5,
       "qualifications.interface_only": ["Sub"]}), "SUCCEEDED", mode="assembly", allow=["Sub"])
# assembly 有未声明 blackbox → PARTIAL
C("assembly_undeclared_bb", good(proof_mode="assembly",
    **{"qualifications.blackbox_objects": ["Undeclared"]}), "PARTIAL", mode="assembly", allow=["Sub"])
# shadow 一律 SHADOW_CHECK(即便数字完美)
C("shadow_only", good(proof_mode="shadow"), "SHADOW_CHECK", mode="shadow")
# diagnostic 永不 signoff
C("diagnostic_never", good(proof_mode="diagnostic-full"), "DIAGNOSTIC", mode="diagnostic-full")
# proof_mode 与 expected_mode 不符 → ERROR(防误升级)
C("mode_mismatch", good(proof_mode="assembly"), "ERROR", mode="signoff-strict")
# canonical baseline 不符 → ERROR
C("wrong_baseline", good(canonical_baseline_id="G0-OTHER"), "ERROR")
# 成功后 fatal(native SUCCEEDED 但 rc 非零, 双轨捕获)
C("success_then_fatal", good(fm_shell_rc=134), "ERROR")

def main():
    npass = 0
    for name, sc, want, kw in CASES:
        try:
            got = run(sc, **kw)
        except Exception as e:
            got = f"EXC:{e}"
        ok = got == want
        npass += ok
        print(f"{'PASS' if ok else 'FAIL'}  {name:30s} want={want:12s} got={got}")
    print(f"\n{npass}/{len(CASES)} passed")
    sys.exit(0 if npass == len(CASES) else 1)

if __name__ == "__main__":
    main()

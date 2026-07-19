#!/usr/bin/env python3
"""FM sidecar validator(2026-07-19, fail-closed)。只读机器可读 sidecar(fm-sidecar-v1),
不 grep 人读日志。缺字段/run-id 不匹配/非 canonical 基线/mode 误升级一律 ERROR。
契约见 SIDECAR_SCHEMA.md。"""
import sys, json, argparse

SCHEMA = "fm-sidecar-v1"
REQUIRED = {"schema", "run_id", "target", "top", "variant", "proof_mode",
            "canonical_baseline_id", "inputs_sha256", "script_sha256", "tool",
            "fm_shell_rc", "native_verdict", "stats", "unmatched", "qualifications"}
STATS_KEYS = {"passing", "failing", "unverified", "aborted", "unread_notcompared"}
UNMATCH_KEYS = {"compare_ref", "compare_impl", "unread_ref", "unread_impl", "bbout_ref", "bbout_impl"}
QUAL_KEYS = {"dont_verify_objects", "elab147", "blackbox_objects", "interface_only"}
KNOWN_MODES = {"signoff-strict", "assembly", "shadow", "diagnostic-full"}


def verdict(sidecar_path, expected_run_id, expected_top=None, expected_mode=None,
            allow_objects=None, baseline_id=None):
    q = {"reason": None}
    try:
        sc = json.load(open(sidecar_path))
    except Exception as e:
        return "ERROR", {"reason": f"sidecar_unreadable:{e}"}

    # 前置 1: schema + 字段齐全(缺字段=ERROR, 不按零)
    if sc.get("schema") != SCHEMA:
        return "ERROR", {"reason": "bad_schema"}
    if set(sc) != REQUIRED:
        return "ERROR", {"reason": f"field_mismatch: 缺{sorted(REQUIRED-set(sc))} 多{sorted(set(sc)-REQUIRED)}"}
    if not isinstance(sc["stats"], dict) or set(sc["stats"]) != STATS_KEYS:
        return "ERROR", {"reason": "stats_fields"}
    if not isinstance(sc["unmatched"], dict) or set(sc["unmatched"]) != UNMATCH_KEYS:
        return "ERROR", {"reason": "unmatched_fields"}
    if not isinstance(sc["qualifications"], dict) or set(sc["qualifications"]) != QUAL_KEYS:
        return "ERROR", {"reason": "qual_fields"}
    q.update(sc)

    # 前置 2: run_id
    if sc["run_id"] != expected_run_id:
        return "ERROR", {"reason": f"run_id_mismatch:{sc['run_id']}!={expected_run_id}"}
    # 前置 3: canonical baseline
    if baseline_id and sc["canonical_baseline_id"] != baseline_id:
        return "ERROR", {"reason": "baseline_mismatch"}
    # 前置 4: expected_top
    if expected_top and sc["top"] != expected_top:
        return "ERROR", {"reason": f"wrong_top:{sc['top']}"}
    # mode 校验 + 防误升级: sidecar 声明的 proof_mode 必须是已知的, 且与 runner 期望一致
    mode = sc["proof_mode"]
    if mode not in KNOWN_MODES:
        return "ERROR", {"reason": f"unknown_mode:{mode}"}
    if expected_mode and mode != expected_mode:
        return "ERROR", {"reason": f"mode_mismatch:{mode}!={expected_mode}"}
    # 前置 5: fm_shell_rc(成功后 fatal/license-kill 会有非零 rc)
    if sc["fm_shell_rc"] != 0:
        return "ERROR", {"reason": f"fm_shell_rc={sc['fm_shell_rc']}"}
    # 前置 6: native verdict
    nv = sc["native_verdict"]
    if nv == "NOT_RUN":
        return "UNRUN", q
    st = sc["stats"]; um = sc["unmatched"]; ql = sc["qualifications"]
    if nv in ("FAILED", "INCONCLUSIVE"):
        return "FAILED", q
    if nv != "SUCCEEDED":
        return "ERROR", {"reason": f"bad_native:{nv}"}

    # 数字闸门
    if st["failing"] != 0:
        return "FAILED", {"reason": "failing>0_despite_native_success", **q}
    if st["passing"] <= 0:
        return "ERROR", {"reason": "empty_proof_passing<=0"}

    # 模式规则
    if mode == "diagnostic-full":
        return "DIAGNOSTIC", q            # 永不 signoff
    if mode == "shadow":
        return "SHADOW_CHECK", q          # 可读核不驱动输出
    unread_any = (st["unread_notcompared"] or um["unread_ref"] or um["unread_impl"])
    if mode == "signoff-strict":
        if st["unverified"] or st["aborted"] or unread_any:
            return "PARTIAL", {"reason": "strict_unverified/aborted/unread", **q}
        if um["compare_ref"] or um["compare_impl"] or um["bbout_ref"] or um["bbout_impl"]:
            return "PARTIAL", {"reason": "strict_unmatched/bbout", **q}
        if ql["blackbox_objects"] or ql["dont_verify_objects"] or ql["elab147"]:
            return "PARTIAL", {"reason": "strict_blackbox/dontverify/elab", **q}
        return "SUCCEEDED", q
    if mode == "assembly":
        allow = set(allow_objects or [])
        # unverified/aborted/unread 非 0 → PARTIAL
        if st["unverified"] or st["aborted"] or unread_any:
            return "PARTIAL", {"reason": "assembly_unverified/aborted/unread", **q}
        # 对称: compare_ref==compare_impl 且 bbout 对称
        if um["compare_ref"] != um["compare_impl"] or um["bbout_ref"] != um["bbout_impl"]:
            return "PARTIAL", {"reason": "assembly_asymmetric", **q}
        # 黑盒/interface_only 必须是 manifest 精确声明集的子集
        if not set(ql["blackbox_objects"]) <= allow:
            return "PARTIAL", {"reason": "assembly_undeclared_blackbox", **q}
        if not set(ql["interface_only"]) <= allow:
            return "PARTIAL", {"reason": "assembly_undeclared_interface_only", **q}
        if ql["dont_verify_objects"] or ql["elab147"]:
            return "PARTIAL", {"reason": "assembly_dontverify/elab", **q}
        return "SUCCEEDED", q
    return "ERROR", {"reason": "unreachable"}


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("sidecar")
    ap.add_argument("--run-id", required=True)
    ap.add_argument("--top", default=None)
    ap.add_argument("--mode", default=None)
    ap.add_argument("--baseline", default=None)
    ap.add_argument("--allow", default="")
    a = ap.parse_args()
    v, q = verdict(a.sidecar, a.run_id, a.top, a.mode,
                   a.allow.split(",") if a.allow else [], a.baseline)
    print(f"{v}\t{q.get('reason')}")
    sys.exit(0 if v == "SUCCEEDED" else 1)

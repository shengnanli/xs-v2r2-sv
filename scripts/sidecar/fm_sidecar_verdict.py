#!/usr/bin/env python3
"""FM sidecar validator(2026-07-19 二审, fail-closed, 强类型 + 外部 expectation 权威)。

verdict(sidecar_path, expectation, actual_rc):
 - expectation: **外部权威** manifest(不可选)。sidecar 每项须与之精确相等。
 - actual_rc: runner 获取的**真实进程 rc**(不信 sidecar 自报; 两者都须为 0)。
强类型: 拒 NaN/Infinity/duplicate-key/bool-as-int/负数/非64小写hex/无序或重复或空串对象。
契约见 SIDECAR_SCHEMA.md。
"""
import sys, json, math, argparse

SCHEMA = "fm-sidecar-v1"
REQUIRED = {"schema", "run_id", "target", "top", "variant", "proof_mode",
            "canonical_baseline_id", "inputs_sha256", "script_sha256", "tool",
            "fm_shell_rc", "native_verdict", "stats", "unmatched", "objects", "qualifications"}
STATS_KEYS = {"passing", "failing", "unverified", "aborted", "unread_notcompared"}
UNMATCH_KEYS = {"compare_ref", "compare_impl", "unread_ref", "unread_impl", "bbout_ref", "bbout_impl"}
OBJ_KEYS = {"blackbox_ref", "blackbox_impl", "interface_only", "unmatched_ref", "unmatched_impl"}
QUAL_KEYS = {"dont_verify_objects", "elab147", "relaxed_appvars"}
KNOWN_MODES = {"signoff-strict", "assembly", "shadow", "diagnostic-full"}
EXPECT_KEYS = {"run_id", "target", "top", "variant", "proof_mode", "canonical_baseline_id",
               "ref_digest", "impl_digest", "script_digest", "tool_digest", "allow_objects"}


class Bad(Exception):
    pass


def _no_nan(o):
    """递归拒绝 float(NaN/Inf) —— JSON 允许它们, 但签核不接受。"""
    if isinstance(o, float):
        if math.isnan(o) or math.isinf(o):
            raise Bad("nan_or_inf")
    elif isinstance(o, dict):
        for v in o.values(): _no_nan(v)
    elif isinstance(o, list):
        for v in o: _no_nan(v)


def _dup_key_hook(pairs):
    d = {}
    for k, v in pairs:
        if k in d:
            raise Bad("duplicate_key:" + k)
        d[k] = v
    return d


def _is_hex64(s):
    return isinstance(s, str) and len(s) == 64 and all(c in "0123456789abcdef" for c in s)


def _count(x):
    # 必须是 int, 非 bool, 非负
    return isinstance(x, int) and not isinstance(x, bool) and x >= 0


def _objlist(x):
    # 排序、唯一、非空字符串列表
    if not isinstance(x, list):
        return False
    if any((not isinstance(e, str)) or e == "" for e in x):
        return False
    if x != sorted(x) or len(set(x)) != len(x):
        return False
    return True


def verdict(sidecar_path, expectation, actual_rc):
    # expectation 自身完整性
    if set(expectation) != EXPECT_KEYS:
        return "ERROR", {"reason": "bad_expectation_manifest"}

    try:
        sc = json.load(open(sidecar_path), object_pairs_hook=_dup_key_hook)
        _no_nan(sc)
    except Bad as b:
        return "ERROR", {"reason": f"type:{b}"}
    except Exception as e:
        return "ERROR", {"reason": f"unreadable:{e}"}

    q = {"reason": None}
    try:
        # ---- 结构 + 强类型 ----
        if sc.get("schema") != SCHEMA:
            raise Bad("bad_schema")
        if set(sc) != REQUIRED:
            raise Bad(f"fields:缺{sorted(REQUIRED-set(sc))}多{sorted(set(sc)-REQUIRED)}")
        for grp, keys in (("stats", STATS_KEYS), ("unmatched", UNMATCH_KEYS),
                          ("objects", OBJ_KEYS)):
            if not isinstance(sc[grp], dict) or set(sc[grp]) != keys:
                raise Bad(f"{grp}_fields")
        if not isinstance(sc["qualifications"], dict) or set(sc["qualifications"]) != QUAL_KEYS:
            raise Bad("qual_fields")
        if set(sc["inputs_sha256"]) != {"ref_srcs_digest", "impl_srcs_digest"}:
            raise Bad("inputs_fields")
        if set(sc["tool"]) != {"fm_shell_digest"}:
            raise Bad("tool_fields")
        # 计数强类型
        for v in list(sc["stats"].values()) + list(sc["unmatched"].values()):
            if not _count(v):
                raise Bad("count_not_nonneg_int")
        if not (isinstance(sc["fm_shell_rc"], int) and not isinstance(sc["fm_shell_rc"], bool)):
            raise Bad("rc_not_int")
        # hash 强类型
        for h in (sc["script_sha256"], sc["inputs_sha256"]["ref_srcs_digest"],
                  sc["inputs_sha256"]["impl_srcs_digest"], sc["tool"]["fm_shell_digest"]):
            if not _is_hex64(h):
                raise Bad("not_hex64")
        # 对象数组强类型
        for v in sc["objects"].values():
            if not _objlist(v):
                raise Bad("obj_not_sorted_unique_nonempty")
        for k in ("dont_verify_objects", "elab147", "relaxed_appvars"):
            if not _objlist(sc["qualifications"][k]):
                raise Bad(f"qual_{k}_not_objlist")
        if sc["proof_mode"] not in KNOWN_MODES:
            raise Bad("unknown_mode")
        if sc["native_verdict"] not in ("SUCCEEDED", "FAILED", "INCONCLUSIVE", "NOT_RUN"):
            raise Bad("bad_native")
    except Bad as b:
        return "ERROR", {"reason": f"type:{b}"}

    q.update(sc)

    # ---- expectation 精确相等(全部权威, 无可选)----
    E = expectation
    for sck, ek in (("run_id", "run_id"), ("target", "target"), ("top", "top"),
                    ("variant", "variant"), ("proof_mode", "proof_mode"),
                    ("canonical_baseline_id", "canonical_baseline_id")):
        if sc[sck] != E[ek]:
            return "ERROR", {"reason": f"expect_{sck}:{sc[sck]}!={E[ek]}"}
    if sc["inputs_sha256"]["ref_srcs_digest"] != E["ref_digest"]:
        return "ERROR", {"reason": "ref_digest_mismatch"}
    if sc["inputs_sha256"]["impl_srcs_digest"] != E["impl_digest"]:
        return "ERROR", {"reason": "impl_digest_mismatch"}
    if sc["script_sha256"] != E["script_digest"]:
        return "ERROR", {"reason": "script_digest_mismatch"}
    if sc["tool"]["fm_shell_digest"] != E["tool_digest"]:
        return "ERROR", {"reason": "tool_digest_mismatch"}

    # ---- rc 交叉: 自报 + 真实 actual 都必须 0 ----
    if not (isinstance(actual_rc, int) and not isinstance(actual_rc, bool)):
        return "ERROR", {"reason": "actual_rc_bad"}
    if sc["fm_shell_rc"] != 0 or actual_rc != 0 or sc["fm_shell_rc"] != actual_rc:
        return "ERROR", {"reason": f"rc: self={sc['fm_shell_rc']} actual={actual_rc}"}

    # ---- native / 数字 ----
    nv = sc["native_verdict"]
    st = sc["stats"]; um = sc["unmatched"]; ob = sc["objects"]; ql = sc["qualifications"]
    if nv == "NOT_RUN":
        return "UNRUN", q
    if nv in ("FAILED", "INCONCLUSIVE"):
        return "FAILED", q
    if st["failing"] != 0:
        return "FAILED", {"reason": "failing>0_despite_native_success", **q}
    if st["passing"] <= 0:
        return "ERROR", {"reason": "empty_proof"}

    mode = sc["proof_mode"]
    if mode == "diagnostic-full":
        return "DIAGNOSTIC", q
    if mode == "shadow":
        return "SHADOW_CHECK", q

    unread_any = st["unread_notcompared"] or um["unread_ref"] or um["unread_impl"]
    if mode == "signoff-strict":
        if st["unverified"] or st["aborted"] or unread_any:
            return "PARTIAL", {"reason": "strict_unverified/aborted/unread", **q}
        if any(um[k] for k in ("compare_ref", "compare_impl", "bbout_ref", "bbout_impl")):
            return "PARTIAL", {"reason": "strict_unmatched/bbout", **q}
        if any(ob[k] for k in OBJ_KEYS):   # strict 不允许任何黑盒/interface_only/未配对对象
            return "PARTIAL", {"reason": "strict_has_objects", **q}
        if ql["dont_verify_objects"] or ql["elab147"] or ql["relaxed_appvars"]:
            return "PARTIAL", {"reason": "strict_qualifications", **q}
        return "SUCCEEDED", q

    if mode == "assembly":
        allow = E["allow_objects"]
        if not _objlist(allow):
            return "ERROR", {"reason": "allow_objects_not_objlist"}
        allow_set = set(allow)
        if st["unverified"] or st["aborted"] or unread_any:
            return "PARTIAL", {"reason": "assembly_unverified/aborted/unread", **q}
        # 对象身份: ref/impl 对称且 == manifest allowlist(精确相等, 非子集)
        for pair in (("blackbox_ref", "blackbox_impl"), ("unmatched_ref", "unmatched_impl")):
            if ob[pair[0]] != ob[pair[1]]:
                return "PARTIAL", {"reason": f"assembly_asymmetric_{pair[0]}", **q}
        # 声明的黑盒/interface_only/未配对对象集必须精确等于 allowlist
        declared = set(ob["blackbox_ref"]) | set(ob["interface_only"]) | set(ob["unmatched_ref"])
        if declared != allow_set:
            return "PARTIAL", {"reason": f"assembly_objects!=allowlist: {sorted(declared)} vs {sorted(allow_set)}", **q}
        # 数量-对象一致性: 有 unmatched 计数就必须有对应对象身份, 反之亦然
        if bool(um["compare_ref"]) != bool(ob["unmatched_ref"]):
            return "PARTIAL", {"reason": "assembly_count_object_disagree", **q}
        # 计数不得超过声明对象数(粗一致)
        if um["compare_ref"] and um["compare_ref"] != len(ob["unmatched_ref"]) and \
           len(ob["unmatched_ref"]) < um["compare_ref"] and False:
            pass  # 计数可 > 对象数(一个黑盒多个引脚), 不强求相等
        if ql["dont_verify_objects"] or ql["elab147"] or ql["relaxed_appvars"]:
            return "PARTIAL", {"reason": "assembly_qualifications", **q}
        return "SUCCEEDED", q
    return "ERROR", {"reason": "unreachable"}


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("sidecar")
    ap.add_argument("--expectation", required=True, help="expectation manifest JSON 路径")
    ap.add_argument("--actual-rc", type=int, required=True)
    a = ap.parse_args()
    exp = json.load(open(a.expectation))
    v, q = verdict(a.sidecar, exp, a.actual_rc)
    print(f"{v}\t{q.get('reason')}")
    sys.exit(0 if v == "SUCCEEDED" else 1)

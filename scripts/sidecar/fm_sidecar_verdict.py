#!/usr/bin/env python3
"""FM sidecar validator(2026-07-19 三审 v3, fail-closed)。

三审修复:
 1. assembly 强制 **数量对称**(compare_ref==compare_impl, bbout_ref==bbout_impl)+ 对象对称
    + 数量-对象证据一致(v2 重写时数量对称检查丢失 → 5/0 假绿, 已堵)。
 2. expectation 用**同样的严格 loader**(拒 dup-key/NaN)+ 身份字段强类型格式
    (非空 str、安全 token、无路径分隔/遍历);strict/shadow/diagnostic 的 allowlist 必须为空。
 3. sidecar/expectation 路径 lstat 拒 symlink/特殊文件。
 4. 双 schema: Tcl 原子写 native_facts.json;runner 取真实 rc 后原子写最终 envelope
    (本 validator 校验的是 envelope, 字段含 native_facts 全部内容 + fm_shell_rc)。
 5. allowlist **按资格类别**声明 {blackbox, interface_only, unmatched};对象名为 canonical
    (r:/WORK|i:/WORK 前缀剥除后的模块名, 由 emitter 归一, validator 做 token 格式校验)。
 6. reason 覆盖 bug 修复(一律 {**q, "reason": ...}, 不再被 q 里的 None 盖掉)。
"""
import sys, os, json, math, re, stat, argparse

SCHEMA = "fm-sidecar-envelope-v1"
REQUIRED = {"schema", "run_id", "target", "top", "variant", "proof_mode",
            "canonical_baseline_id", "inputs_sha256", "script_sha256", "tool",
            "fm_shell_rc", "native_verdict", "stats", "unmatched", "objects", "qualifications"}
STATS_KEYS = {"passing", "failing", "unverified", "aborted", "unread_notcompared"}
UNMATCH_KEYS = {"compare_ref", "compare_impl", "unread_ref", "unread_impl", "bbout_ref", "bbout_impl"}
OBJ_KEYS = {"blackbox_ref", "blackbox_impl", "interface_only", "unmatched_ref", "unmatched_impl"}
QUAL_KEYS = {"dont_verify_objects", "elab147", "relaxed_appvars"}
KNOWN_MODES = {"signoff-strict", "assembly", "shadow", "diagnostic-full"}
EXPECT_KEYS = {"run_id", "target", "top", "variant", "proof_mode", "canonical_baseline_id",
               "ref_digest", "impl_digest", "script_digest", "tool_digest", "allow"}
ALLOW_KEYS = {"blackbox", "interface_only", "unmatched"}
# 身份 token: 非空、无路径分隔/遍历/空白/控制符
_TOKEN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.\-]*$")


class Bad(Exception):
    pass


def _no_nan(o):
    if isinstance(o, float):
        if math.isnan(o) or math.isinf(o):
            raise Bad("nan_or_inf")
    elif isinstance(o, dict):
        for v in o.values(): _no_nan(v)
    elif isinstance(o, list):
        for v in o: _no_nan(v)


def _dup_hook(pairs):
    d = {}
    for k, v in pairs:
        if k in d:
            raise Bad("duplicate_key:" + k)
        d[k] = v
    return d


def strict_load(path):
    """严格 JSON 读取: lstat 拒 symlink/特殊文件 + dup-key + NaN/Inf。sidecar 与 expectation 共用。"""
    st = os.lstat(path)
    if not stat.S_ISREG(st.st_mode):
        raise Bad("not_regular_file(symlink/special)")
    o = json.load(open(path), object_pairs_hook=_dup_hook)
    _no_nan(o)
    return o


def _is_hex64(s):
    return isinstance(s, str) and len(s) == 64 and all(c in "0123456789abcdef" for c in s)


def _count(x):
    return isinstance(x, int) and not isinstance(x, bool) and x >= 0


def _token(x):
    return isinstance(x, str) and bool(_TOKEN.match(x)) and ".." not in x


def _objlist(x):
    if not isinstance(x, list):
        return False
    if any(not _token(e) for e in x):
        return False
    return x == sorted(x) and len(set(x)) == len(x)


def validate_expectation(E):
    """expectation 强类型(同等严格)。返回 None 或错误串。"""
    if not isinstance(E, dict) or set(E) != EXPECT_KEYS:
        return "expect_keys"
    for k in ("run_id", "target", "top", "variant", "canonical_baseline_id"):
        if not _token(E[k]):
            return f"expect_{k}_not_token"
    if E["proof_mode"] not in KNOWN_MODES:
        return "expect_bad_mode"
    for k in ("ref_digest", "impl_digest", "script_digest", "tool_digest"):
        if not _is_hex64(E[k]):
            return f"expect_{k}_not_hex64"
    A = E["allow"]
    if not isinstance(A, dict) or set(A) != ALLOW_KEYS:
        return "expect_allow_keys"
    for k in ALLOW_KEYS:
        if not _objlist(A[k]):
            return f"expect_allow_{k}_not_objlist"
    # strict/shadow/diagnostic: allowlist 必须为空
    if E["proof_mode"] != "assembly" and any(A[k] for k in ALLOW_KEYS):
        return "expect_allowlist_must_be_empty_for_" + E["proof_mode"]
    return None


def verdict(sidecar_path, expectation, actual_rc):
    q = {}
    err = validate_expectation(expectation)
    if err:
        return "ERROR", {"reason": err}
    E = expectation

    try:
        sc = strict_load(sidecar_path)
    except Bad as b:
        return "ERROR", {"reason": f"sidecar:{b}"}
    except Exception as e:
        return "ERROR", {"reason": f"sidecar_unreadable:{type(e).__name__}"}

    try:
        if sc.get("schema") != SCHEMA:
            raise Bad("bad_schema")
        if set(sc) != REQUIRED:
            raise Bad(f"fields:缺{sorted(REQUIRED - set(sc))}多{sorted(set(sc) - REQUIRED)}")
        for grp, keys in (("stats", STATS_KEYS), ("unmatched", UNMATCH_KEYS), ("objects", OBJ_KEYS)):
            if not isinstance(sc[grp], dict) or set(sc[grp]) != keys:
                raise Bad(f"{grp}_fields")
        if not isinstance(sc["qualifications"], dict) or set(sc["qualifications"]) != QUAL_KEYS:
            raise Bad("qual_fields")
        if set(sc["inputs_sha256"]) != {"ref_srcs_digest", "impl_srcs_digest"}:
            raise Bad("inputs_fields")
        if set(sc["tool"]) != {"fm_shell_digest"}:
            raise Bad("tool_fields")
        # 身份字段 token 格式(空 target/../../variant/整数 run_id 均拒, 与 expectation 同规)
        for k in ("run_id", "target", "top", "variant", "canonical_baseline_id"):
            if not _token(sc[k]):
                raise Bad(f"{k}_not_token")
        for v in list(sc["stats"].values()) + list(sc["unmatched"].values()):
            if not _count(v):
                raise Bad("count_not_nonneg_int")
        if not (isinstance(sc["fm_shell_rc"], int) and not isinstance(sc["fm_shell_rc"], bool)):
            raise Bad("rc_not_int")
        for h in (sc["script_sha256"], sc["inputs_sha256"]["ref_srcs_digest"],
                  sc["inputs_sha256"]["impl_srcs_digest"], sc["tool"]["fm_shell_digest"]):
            if not _is_hex64(h):
                raise Bad("not_hex64")
        for v in sc["objects"].values():
            if not _objlist(v):
                raise Bad("obj_not_objlist")
        for k in QUAL_KEYS:
            if not _objlist(sc["qualifications"][k]):
                raise Bad(f"qual_{k}_not_objlist")
        if sc["proof_mode"] not in KNOWN_MODES:
            raise Bad("unknown_mode")
        if sc["native_verdict"] not in ("SUCCEEDED", "FAILED", "INCONCLUSIVE", "NOT_RUN"):
            raise Bad("bad_native")
    except Bad as b:
        return "ERROR", {"reason": f"type:{b}"}

    q.update(sc)

    # ---- expectation 精确相等 ----
    for k in ("run_id", "target", "top", "variant", "proof_mode", "canonical_baseline_id"):
        if sc[k] != E[k]:
            return "ERROR", {**q, "reason": f"expect_{k}:{sc[k]}!={E[k]}"}
    if sc["inputs_sha256"]["ref_srcs_digest"] != E["ref_digest"]:
        return "ERROR", {**q, "reason": "ref_digest_mismatch"}
    if sc["inputs_sha256"]["impl_srcs_digest"] != E["impl_digest"]:
        return "ERROR", {**q, "reason": "impl_digest_mismatch"}
    if sc["script_sha256"] != E["script_digest"]:
        return "ERROR", {**q, "reason": "script_digest_mismatch"}
    if sc["tool"]["fm_shell_digest"] != E["tool_digest"]:
        return "ERROR", {**q, "reason": "tool_digest_mismatch"}

    # ---- rc 交叉 ----
    if not (isinstance(actual_rc, int) and not isinstance(actual_rc, bool)):
        return "ERROR", {**q, "reason": "actual_rc_bad"}
    if sc["fm_shell_rc"] != 0 or actual_rc != 0 or sc["fm_shell_rc"] != actual_rc:
        return "ERROR", {**q, "reason": f"rc:self={sc['fm_shell_rc']} actual={actual_rc}"}

    # ---- native / 数字 ----
    nv = sc["native_verdict"]
    st = sc["stats"]; um = sc["unmatched"]; ob = sc["objects"]; ql = sc["qualifications"]
    if nv == "NOT_RUN":
        return "UNRUN", q
    if nv in ("FAILED", "INCONCLUSIVE"):
        return "FAILED", q
    if st["failing"] != 0:
        return "FAILED", {**q, "reason": "failing>0_despite_native_success"}
    if st["passing"] <= 0:
        return "ERROR", {**q, "reason": "empty_proof"}

    mode = sc["proof_mode"]
    if mode == "diagnostic-full":
        return "DIAGNOSTIC", q
    if mode == "shadow":
        return "SHADOW_CHECK", q

    unread_any = st["unread_notcompared"] or um["unread_ref"] or um["unread_impl"]
    quals_any = ql["dont_verify_objects"] or ql["elab147"] or ql["relaxed_appvars"]

    if mode == "signoff-strict":
        if st["unverified"] or st["aborted"] or unread_any:
            return "PARTIAL", {**q, "reason": "strict_unverified/aborted/unread"}
        if any(um[k] for k in ("compare_ref", "compare_impl", "bbout_ref", "bbout_impl")):
            return "PARTIAL", {**q, "reason": "strict_unmatched/bbout"}
        if any(ob[k] for k in OBJ_KEYS):
            return "PARTIAL", {**q, "reason": "strict_has_objects"}
        if quals_any:
            return "PARTIAL", {**q, "reason": "strict_qualifications"}
        return "SUCCEEDED", q

    # assembly
    A = E["allow"]
    if st["unverified"] or st["aborted"] or unread_any:
        return "PARTIAL", {**q, "reason": "assembly_unverified/aborted/unread"}
    # ① 数量对称(三审修复: v2 丢了)
    if um["compare_ref"] != um["compare_impl"]:
        return "PARTIAL", {**q, "reason": f"assembly_count_asym_compare:{um['compare_ref']}({um['compare_impl']})"}
    if um["bbout_ref"] != um["bbout_impl"]:
        return "PARTIAL", {**q, "reason": f"assembly_count_asym_bbout:{um['bbout_ref']}({um['bbout_impl']})"}
    # ② 对象对称
    if ob["unmatched_ref"] != ob["unmatched_impl"]:
        return "PARTIAL", {**q, "reason": "assembly_obj_asym_unmatched"}
    if ob["blackbox_ref"] != ob["blackbox_impl"]:
        return "PARTIAL", {**q, "reason": "assembly_obj_asym_blackbox"}
    # ③ 数量-对象证据一致(有计数须有对象身份, 反之亦然)
    if bool(um["compare_ref"]) != bool(ob["unmatched_ref"]):
        return "PARTIAL", {**q, "reason": "assembly_compare_count_object_disagree"}
    if bool(um["bbout_ref"]) != bool(ob["blackbox_ref"]):
        return "PARTIAL", {**q, "reason": "assembly_bbout_count_object_disagree"}
    # ④ 分类 allowlist 精确相等(非子集、类别不可互换)
    if set(ob["blackbox_ref"]) != set(A["blackbox"]):
        return "PARTIAL", {**q, "reason": "assembly_blackbox!=allow.blackbox"}
    if set(ob["interface_only"]) != set(A["interface_only"]):
        return "PARTIAL", {**q, "reason": "assembly_interface_only!=allow.interface_only"}
    if set(ob["unmatched_ref"]) != set(A["unmatched"]):
        return "PARTIAL", {**q, "reason": "assembly_unmatched!=allow.unmatched"}
    if quals_any:
        return "PARTIAL", {**q, "reason": "assembly_qualifications"}
    return "SUCCEEDED", q


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("sidecar")
    ap.add_argument("--expectation", required=True)
    ap.add_argument("--actual-rc", type=int, required=True)
    a = ap.parse_args()
    try:
        exp = strict_load(a.expectation)   # 三审: expectation 同样严格 loader(dup-key/NaN/symlink)
    except Exception as e:
        print(f"ERROR\texpectation_load:{e}")
        sys.exit(1)
    v, q = verdict(a.sidecar, exp, a.actual_rc)
    print(f"{v}\t{q.get('reason')}")
    sys.exit(0 if v == "SUCCEEDED" else 1)

#!/usr/bin/env python3
"""FM sidecar validator(2026-07-19 四审 v4, fail-closed)。

四审修复:
 1. token 用 **fullmatch**(re.match 的 $ 在尾换行前匹配 → "Bku\\n" 假绿, 已堵);
    显式拒一切控制字符。
 2. **native_facts 密码学绑定**: envelope 增 native_facts_sha256; validator 接收 native-facts
    文件路径, strict-load + 重算 SHA 对 envelope 声称值; 校验 native schema/run_id/top;
    native 的 verdict/stats/unmatched/objects/qualifications 与 envelope **逐项一致**
    (runner 读错/覆盖/合并错 native facts → ERROR)。原始 native facts 只读保留。
 3. 对象映射显式化: expectation.allow 各类别为 [{id, ref_path, impl_path}] 映射
    (emitter 不猜模块名, 多实例不折叠); sidecar objects 保留 **raw path**。
 4. 鲁棒: 顶层 list/inputs=null 等畸形 → ERROR(不抛未捕获异常)。
 5. 所有非 SUCCEEDED verdict 都带非 None reason(含 FAILED/UNRUN/SHADOW/DIAGNOSTIC)。
"""
import sys, os, json, math, re, stat, hashlib, argparse

ENV_SCHEMA = "fm-sidecar-envelope-v1"
NAT_SCHEMA = "fm-sidecar-native-v1"
ENV_REQUIRED = {"schema", "run_id", "target", "top", "variant", "proof_mode",
                "canonical_baseline_id", "inputs_sha256", "script_sha256", "tool",
                "fm_shell_rc", "native_verdict", "stats", "unmatched", "objects",
                "qualifications", "native_facts_sha256"}
NAT_REQUIRED = {"schema", "run_id", "top", "native_verdict", "stats", "unmatched",
                "objects", "qualifications"}
STATS_KEYS = {"passing", "failing", "unverified", "aborted", "unread_notcompared"}
UNMATCH_KEYS = {"compare_ref", "compare_impl", "unread_ref", "unread_impl", "bbout_ref", "bbout_impl"}
OBJ_KEYS = {"blackbox_ref", "blackbox_impl", "interface_only", "unmatched_ref", "unmatched_impl"}
QUAL_KEYS = {"dont_verify_objects", "elab147", "relaxed_appvars"}
KNOWN_MODES = {"signoff-strict", "assembly", "shadow", "diagnostic-full"}
EXPECT_KEYS = {"run_id", "target", "top", "variant", "proof_mode", "canonical_baseline_id",
               "ref_digest", "impl_digest", "script_digest", "tool_digest", "allow"}
ALLOW_KEYS = {"blackbox", "interface_only", "unmatched"}
MAP_KEYS = {"id", "ref_path", "impl_path"}
_TOKEN = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.\-]*")


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
    st = os.lstat(path)
    if not stat.S_ISREG(st.st_mode):
        raise Bad("not_regular_file")
    o = json.load(open(path), object_pairs_hook=_dup_hook)
    _no_nan(o)
    return o


def _sha_file(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""):
            h.update(c)
    return h.hexdigest()


def _is_hex64(s):
    return isinstance(s, str) and len(s) == 64 and all(c in "0123456789abcdef" for c in s)


def _count(x):
    return isinstance(x, int) and not isinstance(x, bool) and x >= 0


def _no_ctrl(s):
    return isinstance(s, str) and all(ord(c) >= 32 and ord(c) != 127 for c in s)


def _token(x):
    # 四审: fullmatch(re.match 的 $ 在尾 \n 前匹配)+ 拒控制符
    return isinstance(x, str) and _no_ctrl(x) and bool(_TOKEN.fullmatch(x)) and ".." not in x


def _pathstr(x):
    # raw path: 非空、无控制符(允许 / : [ ] 等 FM 路径字符)
    return isinstance(x, str) and x != "" and _no_ctrl(x)


def _objlist(x, elem=_token):
    if not isinstance(x, list):
        return False
    if any(not elem(e) for e in x):
        return False
    return x == sorted(x) and len(set(x)) == len(x)


def validate_expectation(E):
    try:
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
        for cat in ALLOW_KEYS:
            maps = A[cat]
            if not isinstance(maps, list):
                return f"expect_allow_{cat}_not_list"
            ids = []
            for m in maps:
                if not isinstance(m, dict) or set(m) != MAP_KEYS:
                    return f"expect_allow_{cat}_map_keys"
                if not _token(m["id"]) or not _pathstr(m["ref_path"]) or not _pathstr(m["impl_path"]):
                    return f"expect_allow_{cat}_map_types"
                ids.append(m["id"])
            if ids != sorted(ids) or len(set(ids)) != len(ids):
                return f"expect_allow_{cat}_ids_not_sorted_unique"
        if E["proof_mode"] != "assembly" and any(A[k] for k in ALLOW_KEYS):
            return "expect_allowlist_must_be_empty_for_" + E["proof_mode"]
        return None
    except Exception as e:
        return f"expect_malformed:{type(e).__name__}"


def _validate_facts_block(sc, where):
    """stats/unmatched/objects/qualifications 结构与强类型(envelope 与 native 共用)。"""
    for grp, keys in (("stats", STATS_KEYS), ("unmatched", UNMATCH_KEYS), ("objects", OBJ_KEYS)):
        if not isinstance(sc[grp], dict) or set(sc[grp]) != keys:
            raise Bad(f"{where}_{grp}_fields")
    if not isinstance(sc["qualifications"], dict) or set(sc["qualifications"]) != QUAL_KEYS:
        raise Bad(f"{where}_qual_fields")
    for v in list(sc["stats"].values()) + list(sc["unmatched"].values()):
        if not _count(v):
            raise Bad(f"{where}_count_not_nonneg_int")
    for v in sc["objects"].values():
        if not _objlist(v, elem=_pathstr):        # objects 是 raw path 列表
            raise Bad(f"{where}_obj_not_objlist")
    for k in QUAL_KEYS:
        if not _objlist(sc["qualifications"][k], elem=_pathstr):
            raise Bad(f"{where}_qual_{k}_not_objlist")
    if sc["native_verdict"] not in ("SUCCEEDED", "FAILED", "INCONCLUSIVE", "NOT_RUN"):
        raise Bad(f"{where}_bad_native")


def verdict(sidecar_path, expectation, actual_rc, native_facts_path):
    q = {}
    err = validate_expectation(expectation)
    if err:
        return "ERROR", {"reason": err}
    E = expectation

    # ---- envelope ----
    try:
        sc = strict_load(sidecar_path)
        if not isinstance(sc, dict):
            raise Bad("envelope_not_object")
        if sc.get("schema") != ENV_SCHEMA:
            raise Bad("bad_schema")
        if set(sc) != ENV_REQUIRED:
            raise Bad(f"fields:缺{sorted(ENV_REQUIRED - set(sc))}多{sorted(set(sc) - ENV_REQUIRED)}")
        for k in ("run_id", "target", "top", "variant", "canonical_baseline_id"):
            if not _token(sc[k]):
                raise Bad(f"{k}_not_token")
        if sc["proof_mode"] not in KNOWN_MODES:
            raise Bad("unknown_mode")
        if not isinstance(sc["inputs_sha256"], dict) or \
           set(sc["inputs_sha256"]) != {"ref_srcs_digest", "impl_srcs_digest"}:
            raise Bad("inputs_fields")
        if not isinstance(sc["tool"], dict) or set(sc["tool"]) != {"fm_shell_digest"}:
            raise Bad("tool_fields")
        for h in (sc["script_sha256"], sc["inputs_sha256"]["ref_srcs_digest"],
                  sc["inputs_sha256"]["impl_srcs_digest"], sc["tool"]["fm_shell_digest"],
                  sc["native_facts_sha256"]):
            if not _is_hex64(h):
                raise Bad("not_hex64")
        if not (isinstance(sc["fm_shell_rc"], int) and not isinstance(sc["fm_shell_rc"], bool)):
            raise Bad("rc_not_int")
        _validate_facts_block(sc, "env")
    except Bad as b:
        return "ERROR", {"reason": f"type:{b}"}
    except Exception as e:
        return "ERROR", {"reason": f"envelope_malformed:{type(e).__name__}"}

    q.update(sc)

    # ---- native facts 密码学绑定(四审)----
    try:
        nat_sha = _sha_file(native_facts_path)
        if nat_sha != sc["native_facts_sha256"]:
            return "ERROR", {**q, "reason": "native_facts_sha_mismatch"}
        nat = strict_load(native_facts_path)
        if not isinstance(nat, dict):
            raise Bad("native_not_object")
        if nat.get("schema") != NAT_SCHEMA:
            raise Bad("native_bad_schema")
        if set(nat) != NAT_REQUIRED:
            raise Bad("native_fields")
        if not _token(nat["run_id"]) or not _token(nat["top"]):
            raise Bad("native_identity")
        _validate_facts_block(nat, "nat")
    except Bad as b:
        return "ERROR", {**q, "reason": f"native:{b}"}
    except Exception as e:
        return "ERROR", {**q, "reason": f"native_malformed:{type(e).__name__}"}
    # native ↔ envelope 逐项一致
    if nat["run_id"] != sc["run_id"] or nat["top"] != sc["top"]:
        return "ERROR", {**q, "reason": "native_envelope_identity_mismatch"}
    for grp in ("native_verdict", "stats", "unmatched", "objects", "qualifications"):
        if nat[grp] != sc[grp]:
            return "ERROR", {**q, "reason": f"native_envelope_mismatch:{grp}"}

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
        return "UNRUN", {**q, "reason": "native_not_run"}
    if nv in ("FAILED", "INCONCLUSIVE"):
        return "FAILED", {**q, "reason": f"native_{nv.lower()}"}
    if st["failing"] != 0:
        return "FAILED", {**q, "reason": "failing>0_despite_native_success"}
    if st["passing"] <= 0:
        return "ERROR", {**q, "reason": "empty_proof"}

    mode = sc["proof_mode"]
    if mode == "diagnostic-full":
        return "DIAGNOSTIC", {**q, "reason": "diagnostic_mode_never_signoff"}
    if mode == "shadow":
        return "SHADOW_CHECK", {**q, "reason": "shadow_core_not_driving_outputs"}

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

    # assembly(显式 {id, ref_path, impl_path} 映射)
    A = E["allow"]
    if st["unverified"] or st["aborted"] or unread_any:
        return "PARTIAL", {**q, "reason": "assembly_unverified/aborted/unread"}
    if um["compare_ref"] != um["compare_impl"]:
        return "PARTIAL", {**q, "reason": f"assembly_count_asym_compare:{um['compare_ref']}({um['compare_impl']})"}
    if um["bbout_ref"] != um["bbout_impl"]:
        return "PARTIAL", {**q, "reason": f"assembly_count_asym_bbout:{um['bbout_ref']}({um['bbout_impl']})"}
    if bool(um["compare_ref"]) != bool(ob["unmatched_ref"]) or bool(um["compare_ref"]) != bool(ob["unmatched_impl"]):
        return "PARTIAL", {**q, "reason": "assembly_compare_count_object_disagree"}
    if bool(um["bbout_ref"]) != bool(ob["blackbox_ref"]) or bool(um["bbout_ref"]) != bool(ob["blackbox_impl"]):
        return "PARTIAL", {**q, "reason": "assembly_bbout_count_object_disagree"}
    # 映射精确: sidecar raw ref/impl 路径集 == allow 各类别映射的 ref_path/impl_path 集
    def _paths(cat, side):
        return sorted(m[side] for m in A[cat])
    if ob["blackbox_ref"] != _paths("blackbox", "ref_path") or \
       ob["blackbox_impl"] != _paths("blackbox", "impl_path"):
        return "PARTIAL", {**q, "reason": "assembly_blackbox_paths!=allow"}
    if ob["unmatched_ref"] != _paths("unmatched", "ref_path") or \
       ob["unmatched_impl"] != _paths("unmatched", "impl_path"):
        return "PARTIAL", {**q, "reason": "assembly_unmatched_paths!=allow"}
    if ob["interface_only"] != _paths("interface_only", "ref_path"):
        return "PARTIAL", {**q, "reason": "assembly_interface_only!=allow"}
    if quals_any:
        return "PARTIAL", {**q, "reason": "assembly_qualifications"}
    return "SUCCEEDED", q


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("sidecar")
    ap.add_argument("--native-facts", required=True)
    ap.add_argument("--expectation", required=True)
    ap.add_argument("--actual-rc", type=int, required=True)
    a = ap.parse_args()
    try:
        exp = strict_load(a.expectation)
    except Exception as e:
        print(f"ERROR\texpectation_load:{e}")
        sys.exit(1)
    v, q = verdict(a.sidecar, exp, a.actual_rc, a.native_facts)
    print(f"{v}\t{q.get('reason')}")
    sys.exit(0 if v == "SUCCEEDED" else 1)

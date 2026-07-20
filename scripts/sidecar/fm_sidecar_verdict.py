#!/usr/bin/env python3
"""FM sidecar validator(2026-07-20 九审 v9, fail-closed)。

observed-facts 模型(六审): native facts 只装 Formality 实际返回的观察事实;
report_matched_points 是唯一 pair 来源; id/waiver-pair 属 expectation policy。

九审(3A.2 审定四补丁):
 - objects 扩到 21 字段(3 pair 列表 + 9×2 独立 path 集合, 含 empty_blackbox/bbin/pi/
   unread/dont_verify 原始集合); allow 增 empty_blackbox 类。
 - 计数=列表 llength 派生, 4 组单位绑定(compare/unread/unread_notcompared/bbout), 模式无关。
 - BBOUT/BBIN/PI zero-only(不被 allow.unmatched 吸收, 对称也 PARTIAL)。
 - pair 三类分类(iface/unresolved/empty), 重叠/混类/未知/单端 → ERROR; 分类 pair 集与
   policy 各自精确相等。
 - entry_appvars 三方绑定 + 冻结执行语义(unread=false / unresolved=black_box /
   strict 下 interface_only 必空)。
 - native FAILED 最高优先级, 无 WAIVED 升级通道(管理豁免归独立 ledger, 不算通过)。
详细契约见 SIDECAR_SCHEMA.md(v7)。
"""
import sys, os, json, math, re, stat, hashlib, argparse, unicodedata

ENV_SCHEMA = "fm-sidecar-envelope-v1"
NAT_SCHEMA = "fm-sidecar-native-v1"
ENV_REQUIRED = {"schema", "run_id", "target", "top", "variant", "proof_mode",
                "canonical_baseline_id", "inputs_sha256", "script_sha256", "tool",
                "fm_shell_rc", "native_verdict", "stats", "unmatched", "objects",
                "qualifications", "entry_appvars", "native_facts_sha256"}
NAT_REQUIRED = {"schema", "run_id", "top", "native_verdict", "stats", "unmatched",
                "objects", "qualifications", "entry_appvars"}
STATS_KEYS = {"passing", "failing", "unverified", "aborted", "unread_notcompared"}
UNMATCH_KEYS = {"compare_ref", "compare_impl", "unread_ref", "unread_impl", "bbout_ref", "bbout_impl"}
# 九审(3A.2 审定补丁1): 观察对象扩到 21 字段——3 类原生 pair + 3 类黑盒实例两侧 +
# 默认主集/unread/dont_verify/bbox_output/bbox_input/primary_input 两侧原始集合。
PAIR_OBJ_KEYS = {"matched_blackbox_pairs", "matched_unread_notcompared_pairs",
                 "matched_dont_verify_pairs"}
REF_OBJ_KEYS = {"interface_only_ref", "unresolved_blackbox_ref", "empty_blackbox_ref",
                "unmatched_ref", "unmatched_unread_ref", "unmatched_dont_verify_ref",
                "unmatched_bbox_output_ref", "unmatched_bbox_input_ref",
                "unmatched_primary_input_ref"}
IMPL_OBJ_KEYS = {"interface_only_impl", "unresolved_blackbox_impl", "empty_blackbox_impl",
                 "unmatched_impl", "unmatched_unread_impl", "unmatched_dont_verify_impl",
                 "unmatched_bbox_output_impl", "unmatched_bbox_input_impl",
                 "unmatched_primary_input_impl"}
OBJ_KEYS = PAIR_OBJ_KEYS | REF_OBJ_KEYS | IMPL_OBJ_KEYS
# 九审(补丁1): BBOUT/BBIN/PI 一律 zero-only, 不被 generic allow.unmatched 吸收
ZERO_ONLY_KEYS = ("unmatched_bbox_output_ref", "unmatched_bbox_output_impl",
                  "unmatched_bbox_input_ref", "unmatched_bbox_input_impl",
                  "unmatched_primary_input_ref", "unmatched_primary_input_impl")
QUAL_KEYS = {"dont_verify_objects", "elab147", "relaxed_appvars"}
KNOWN_MODES = {"signoff-strict", "assembly", "shadow", "diagnostic-full"}
EXPECT_KEYS = {"run_id", "target", "top", "variant", "proof_mode", "canonical_baseline_id",
               "ref_digest", "impl_digest", "script_digest", "tool_digest",
               "entry_appvars", "allow"}
ALLOW_KEYS = {"unresolved_blackbox", "interface_only", "empty_blackbox", "unmatched"}
# 九审(补丁3): 入口 appvars 完整有效值明文绑定, native/envelope/expectation 三方一致。
# unread=false 与 unresolved=black_box 是 305 统一冻结执行语义; merge/interface_only 按目标绑定。
APPVAR_KEYS = {"verification_verify_unread_compare_points", "hdlin_unresolved_modules",
               "hdlin_interface_only", "verification_merge_duplicated_registers"}
MAP_KEYS = {"id", "ref_path", "impl_path"}
PAIR_KEYS = {"ref_path", "impl_path"}
_TOKEN = re.compile(r"[A-Za-z0-9][A-Za-z0-9_.\-]*")
MAX_JSON_BYTES = 64 << 20


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


def safe_read_bytes(path):
    """六审: O_NONBLOCK(FIFO 不阻塞挂死)+O_NOFOLLOW(symlink 拒)+同 fd fstat 只读 regular+大小上限。"""
    flags = (os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_CLOEXEC", 0)
             | getattr(os, "O_NONBLOCK", 0))
    try:
        fd = os.open(path, flags)
    except OSError as e:
        raise Bad(f"open_fail:{e.errno}")
    try:
        st = os.fstat(fd)
        if not stat.S_ISREG(st.st_mode):
            raise Bad("not_regular_file")
        if st.st_size > MAX_JSON_BYTES:
            raise Bad("file_too_large")
        chunks = []
        while True:
            b = os.read(fd, 1 << 20)
            if not b:
                break
            chunks.append(b)
        return b"".join(chunks)
    finally:
        os.close(fd)


def strict_parse(buf):
    o = json.loads(buf.decode("utf-8"), object_pairs_hook=_dup_hook)
    _no_nan(o)
    return o


def strict_load(path):
    return strict_parse(safe_read_bytes(path))


def _is_hex64(s):
    return isinstance(s, str) and len(s) == 64 and all(c in "0123456789abcdef" for c in s)


def _count(x):
    return isinstance(x, int) and not isinstance(x, bool) and x >= 0


def _no_ctrl(s):
    return isinstance(s, str) and all(
        ord(c) >= 32 and ord(c) != 127 and unicodedata.category(c) not in ("Cc", "Cf")
        for c in s)


def _token(x):
    return isinstance(x, str) and _no_ctrl(x) and bool(_TOKEN.fullmatch(x)) and ".." not in x


def _refpath(x, top):
    # 六审: 必须**严格在 top 之下**(禁抽象 top 自身作对象)
    return isinstance(x, str) and _no_ctrl(x) and x.startswith(f"r:/WORK/{top}/") and len(x) > len(f"r:/WORK/{top}/")


def _implpath(x, top):
    return isinstance(x, str) and _no_ctrl(x) and x.startswith(f"i:/WORK/{top}/") and len(x) > len(f"i:/WORK/{top}/")


def _pathlist(x, top, side):
    chk = _refpath if side == "ref" else _implpath
    if not isinstance(x, list):
        return "not_list"
    if any(not chk(e, top) for e in x):
        return "bad_path"
    if x != sorted(x) or len(set(x)) != len(x):
        return "not_sorted_unique"
    return None


def _pairlist(x, top):
    if not isinstance(x, list):
        return "not_list"
    seen = set()
    for m in x:
        if not isinstance(m, dict) or set(m) != PAIR_KEYS:
            return "pair_keys"
        if not _refpath(m["ref_path"], top) or not _implpath(m["impl_path"], top):
            return "pair_path"
        t = (m["ref_path"], m["impl_path"])
        if t in seen:
            return "pair_dup"
        seen.add(t)
    keys = [(m["ref_path"], m["impl_path"]) for m in x]
    if keys != sorted(keys):
        return "pair_not_sorted"
    return None


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
        gid = {}          # 跨类别: 同 id 必须同 pair
        gref, gimpl = {}, {}   # 七审全局一致: ref→(impl,id) / impl→(ref,id) 必须唯一映射
        # (同id同pair跨类别复用合法, 如 interface_only 实例与其 unmatched 点)
        for cat in ALLOW_KEYS:
            maps = A[cat]
            if not isinstance(maps, list):
                return f"expect_allow_{cat}_not_list"
            ids, refs, impls = [], [], []
            for m in maps:
                if not isinstance(m, dict) or set(m) != MAP_KEYS:
                    return f"expect_allow_{cat}_map_keys"
                if not _token(m["id"]):
                    return f"expect_allow_{cat}_id"
                if not _refpath(m["ref_path"], E["top"]) or not _implpath(m["impl_path"], E["top"]):
                    return f"expect_allow_{cat}_path"
                ids.append(m["id"]); refs.append(m["ref_path"]); impls.append(m["impl_path"])
                pair = (m["ref_path"], m["impl_path"])
                if m["id"] in gid and gid[m["id"]] != pair:
                    return f"expect_id_conflict:{m['id']}"
                gid[m["id"]] = pair
                # 七审全局一致: 同 ref 全局只能映射一个 (impl,id); 同 impl 同理。
                # 拒: 同 ref 两 impl(跨类别)、同一 pair 两个 id; 允许: 同 id 同 pair 跨类别复用。
                rk = (m["impl_path"], m["id"])
                if m["ref_path"] in gref and gref[m["ref_path"]] != rk:
                    return f"expect_global_ref_conflict:{m['ref_path']}"
                gref[m["ref_path"]] = rk
                ik = (m["ref_path"], m["id"])
                if m["impl_path"] in gimpl and gimpl[m["impl_path"]] != ik:
                    return f"expect_global_impl_conflict:{m['impl_path']}"
                gimpl[m["impl_path"]] = ik
            # 六审双射: id/ref/impl 各自唯一
            if ids != sorted(ids) or len(set(ids)) != len(ids):
                return f"expect_allow_{cat}_ids_not_unique_sorted"
            if len(set(refs)) != len(refs):
                return f"expect_allow_{cat}_refs_not_unique"
            if len(set(impls)) != len(impls):
                return f"expect_allow_{cat}_impls_not_unique"
        if E["proof_mode"] != "assembly" and any(A[k] for k in ALLOW_KEYS):
            return "expect_allowlist_must_be_empty_for_" + E["proof_mode"]
        av = E["entry_appvars"]
        if not isinstance(av, dict) or set(av) != APPVAR_KEYS:
            return "expect_entry_appvars_fields"
        for v in av.values():
            if not (isinstance(v, str) and len(v) < 4096 and _no_ctrl(v)):
                return "expect_entry_appvars_value"
        return None
    except Exception as e:
        return f"expect_malformed:{type(e).__name__}"


def _validate_facts_block(sc, where, top):
    for grp, keys in (("stats", STATS_KEYS), ("unmatched", UNMATCH_KEYS)):
        if not isinstance(sc[grp], dict) or set(sc[grp]) != keys:
            raise Bad(f"{where}_{grp}_fields")
    ob = sc["objects"]
    if not isinstance(ob, dict) or set(ob) != OBJ_KEYS:
        raise Bad(f"{where}_objects_fields")
    for k in sorted(PAIR_OBJ_KEYS):
        err = _pairlist(ob[k], top)
        if err:
            raise Bad(f"{where}_{k}:{err}")
    for k in sorted(REF_OBJ_KEYS):
        err = _pathlist(ob[k], top, "ref")
        if err:
            raise Bad(f"{where}_{k}:{err}")
    for k in sorted(IMPL_OBJ_KEYS):
        err = _pathlist(ob[k], top, "impl")
        if err:
            raise Bad(f"{where}_{k}:{err}")
    av = sc["entry_appvars"]
    if not isinstance(av, dict) or set(av) != APPVAR_KEYS:
        raise Bad(f"{where}_entry_appvars_fields")
    for v in av.values():
        if not (isinstance(v, str) and len(v) < 4096 and _no_ctrl(v)):
            raise Bad(f"{where}_entry_appvars_value")
    if not isinstance(sc["qualifications"], dict) or set(sc["qualifications"]) != QUAL_KEYS:
        raise Bad(f"{where}_qual_fields")
    for v in list(sc["stats"].values()) + list(sc["unmatched"].values()):
        if not _count(v):
            raise Bad(f"{where}_count_not_nonneg_int")
    for k in QUAL_KEYS:
        x = sc["qualifications"][k]
        if not (isinstance(x, list) and all(isinstance(e, str) and e != "" and _no_ctrl(e) for e in x)
                and x == sorted(x) and len(set(x)) == len(x)):
            raise Bad(f"{where}_qual_{k}_not_objlist")
    if sc["native_verdict"] not in ("SUCCEEDED", "FAILED", "INCONCLUSIVE", "NOT_RUN"):
        raise Bad(f"{where}_bad_native")


def verdict(sidecar_path, expectation, actual_rc, native_facts_path):
    q = {}
    err = validate_expectation(expectation)
    if err:
        return "ERROR", {"reason": err}
    E = expectation

    try:
        sc = strict_parse(safe_read_bytes(sidecar_path))
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
        _validate_facts_block(sc, "env", sc["top"])
    except Bad as b:
        return "ERROR", {"reason": f"type:{b}"}
    except Exception as e:
        return "ERROR", {"reason": f"envelope_malformed:{type(e).__name__}"}

    q.update(sc)

    try:
        nat_buf = safe_read_bytes(native_facts_path)
        if hashlib.sha256(nat_buf).hexdigest() != sc["native_facts_sha256"]:
            return "ERROR", {**q, "reason": "native_facts_sha_mismatch"}
        nat = strict_parse(nat_buf)
        if not isinstance(nat, dict):
            raise Bad("native_not_object")
        if nat.get("schema") != NAT_SCHEMA:
            raise Bad("native_bad_schema")
        if set(nat) != NAT_REQUIRED:
            raise Bad("native_fields")
        if not _token(nat["run_id"]) or not _token(nat["top"]):
            raise Bad("native_identity")
        _validate_facts_block(nat, "nat", nat["top"])
    except Bad as b:
        return "ERROR", {**q, "reason": f"native:{b}"}
    except Exception as e:
        return "ERROR", {**q, "reason": f"native_malformed:{type(e).__name__}"}
    if nat["run_id"] != sc["run_id"] or nat["top"] != sc["top"]:
        return "ERROR", {**q, "reason": "native_envelope_identity_mismatch"}
    for grp in ("native_verdict", "stats", "unmatched", "objects", "qualifications",
                "entry_appvars"):
        if nat[grp] != sc[grp]:
            return "ERROR", {**q, "reason": f"native_envelope_mismatch:{grp}"}

    for k in ("run_id", "target", "top", "variant", "proof_mode", "canonical_baseline_id"):
        if sc[k] != E[k]:
            return "ERROR", {**q, "reason": f"expect_{k}:{sc[k]}!={E[k]}"}
    # 九审(补丁3): entry appvars 三方一致(native==envelope 已在上组查过)+ 冻结执行语义
    av = sc["entry_appvars"]
    if av != E["entry_appvars"]:
        return "ERROR", {**q, "reason": "entry_appvars!=expectation"}
    if av["verification_verify_unread_compare_points"] != "false":
        return "ERROR", {**q, "reason": "frozen_semantics:verify_unread_must_be_false"}
    if av["hdlin_unresolved_modules"] != "black_box":
        return "ERROR", {**q, "reason": "frozen_semantics:unresolved_must_be_black_box"}
    if av["verification_merge_duplicated_registers"] not in ("true", "false"):
        return "ERROR", {**q, "reason": "entry_appvars:merge_dup_not_bool"}
    if sc["proof_mode"] in ("signoff-strict", "shadow") and av["hdlin_interface_only"] != "":
        return "ERROR", {**q, "reason": "strict_interface_only_appvar_nonempty"}
    if sc["inputs_sha256"]["ref_srcs_digest"] != E["ref_digest"]:
        return "ERROR", {**q, "reason": "ref_digest_mismatch"}
    if sc["inputs_sha256"]["impl_srcs_digest"] != E["impl_digest"]:
        return "ERROR", {**q, "reason": "impl_digest_mismatch"}
    if sc["script_sha256"] != E["script_digest"]:
        return "ERROR", {**q, "reason": "script_digest_mismatch"}
    if sc["tool"]["fm_shell_digest"] != E["tool_digest"]:
        return "ERROR", {**q, "reason": "tool_digest_mismatch"}

    if not (isinstance(actual_rc, int) and not isinstance(actual_rc, bool)):
        return "ERROR", {**q, "reason": "actual_rc_bad"}
    if sc["fm_shell_rc"] != 0 or actual_rc != 0 or sc["fm_shell_rc"] != actual_rc:
        return "ERROR", {**q, "reason": f"rc:self={sc['fm_shell_rc']} actual={actual_rc}"}

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

    # ---- 九审(补丁2) 计数=列表 llength 派生值, 单位绑定(模式无关, 不一致即拒) ----
    # 冻结查询: matched -not_compared -status unread / unmatched -r|-i -status unread。
    # 仅 -status unread 不稳定: verify_unread=true 会话里它返回已验证通过的 20 对,
    # 不能再称 Not-Compared(3A.2 实证)。
    if um["compare_ref"] != len(ob["unmatched_ref"]) or \
       um["compare_impl"] != len(ob["unmatched_impl"]):
        return "PARTIAL", {**q, "reason": "count_list_mismatch:compare"}
    if um["unread_ref"] != len(ob["unmatched_unread_ref"]) or \
       um["unread_impl"] != len(ob["unmatched_unread_impl"]):
        return "PARTIAL", {**q, "reason": "count_list_mismatch:unread"}
    if st["unread_notcompared"] != len(ob["matched_unread_notcompared_pairs"]):
        return "PARTIAL", {**q, "reason": "count_list_mismatch:unread_notcompared"}
    if um["bbout_ref"] != len(ob["unmatched_bbox_output_ref"]) or \
       um["bbout_impl"] != len(ob["unmatched_bbox_output_impl"]):
        return "PARTIAL", {**q, "reason": "count_list_mismatch:bbout"}
    # ---- 九审(补丁1) BBOUT/BBIN/PI zero-only(两模式一律; 决定3 推广) ----
    # 非零一律 PARTIAL: Formality 不为这些点提供原生 pair, 不得人工配对/被 allow.unmatched 吸收。
    for k in ZERO_ONLY_KEYS:
        if ob[k]:
            return "PARTIAL", {**q, "reason": f"zero_only:{k}"}

    unread_any = st["unread_notcompared"] or um["unread_ref"] or um["unread_impl"]
    # 九审: dont_verify 观察对象(pair 与两侧点集)一律按 qualification 处理(v1 无 policy 通道)
    quals_any = (ql["dont_verify_objects"] or ql["elab147"] or ql["relaxed_appvars"]
                 or ob["matched_dont_verify_pairs"]
                 or ob["unmatched_dont_verify_ref"] or ob["unmatched_dont_verify_impl"])

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

    # ---- assembly(六审: observed facts vs expectation policy 投影)----
    A = E["allow"]
    if st["unverified"] or st["aborted"] or unread_any:
        return "PARTIAL", {**q, "reason": "assembly_unverified/aborted/unread"}
    if um["compare_ref"] != um["compare_impl"]:
        return "PARTIAL", {**q, "reason": f"assembly_count_asym_compare:{um['compare_ref']}({um['compare_impl']})"}
    # 决定2(3A.1 审定)+九审补丁1: matched pairs 保留为唯一原生观察事实, validator 按独立
    # 采集的 black-box 实例集合分三类(iface/unresolved/empty)。类别重叠/混类/未知类/仅一端
    # 命中 → ERROR(observed facts 不自洽, 先于 policy 比对)。实证锚: NewIFU 21 pair↔21+21
    # iface 实例、IMSIC 8 pair↔8+8 'u' 实例、DCacheWrapper 1 pair↔1+1 'e' 实例。
    # 其余 flag(s/ut/cp/ir/f/m)在 emitter 解析层直接 ERROR, 不产 native facts(schema 契约)。
    ir, ii = set(ob["interface_only_ref"]), set(ob["interface_only_impl"])
    ur, ui = set(ob["unresolved_blackbox_ref"]), set(ob["unresolved_blackbox_impl"])
    er, ei = set(ob["empty_blackbox_ref"]), set(ob["empty_blackbox_impl"])
    if (ir & ur) or (ir & er) or (ur & er) or (ii & ui) or (ii & ei) or (ui & ei):
        return "ERROR", {**q, "reason": "assembly_bb_instance_category_overlap"}
    def _cls(x, a, b, c):
        return "i" if x in a else "u" if x in b else "e" if x in c else None
    p_iface, p_unres, p_empty = [], [], []
    for m in ob["matched_blackbox_pairs"]:
        r, i = m["ref_path"], m["impl_path"]
        cr, ci = _cls(r, ir, ur, er), _cls(i, ii, ui, ei)
        if cr is None or ci is None or cr != ci:
            return "ERROR", {**q, "reason": "assembly_pair_class_unknown_or_mixed"}
        {"i": p_iface, "u": p_unres, "e": p_empty}[cr].append((r, i))
    # 观察集合 == expectation 映射的投影(独立集合, 不含推测 pair)
    def proj(cat, side):
        return sorted(m[side] for m in A[cat])
    if ob["unmatched_ref"] != proj("unmatched", "ref_path") or \
       ob["unmatched_impl"] != proj("unmatched", "impl_path"):
        return "PARTIAL", {**q, "reason": "assembly_unmatched_observed!=policy"}
    if ob["interface_only_ref"] != proj("interface_only", "ref_path") or \
       ob["interface_only_impl"] != proj("interface_only", "impl_path"):
        return "PARTIAL", {**q, "reason": "assembly_interface_only_observed!=policy"}
    if ob["unresolved_blackbox_ref"] != proj("unresolved_blackbox", "ref_path") or \
       ob["unresolved_blackbox_impl"] != proj("unresolved_blackbox", "impl_path"):
        return "PARTIAL", {**q, "reason": "assembly_unresolved_bb_observed!=policy"}
    if ob["empty_blackbox_ref"] != proj("empty_blackbox", "ref_path") or \
       ob["empty_blackbox_impl"] != proj("empty_blackbox", "impl_path"):
        return "PARTIAL", {**q, "reason": "assembly_empty_bb_observed!=policy"}
    # 分类后的 pair 集分别与对应 policy 精确相等(堵"实例正确但 matched pair 为空仍
    # SUCCEEDED"假绿; 空列表绕过继续堵死; empty 类同权处理)
    for got, cat in ((p_iface, "interface_only"), (p_unres, "unresolved_blackbox"),
                     (p_empty, "empty_blackbox")):
        if sorted(got) != sorted((m["ref_path"], m["impl_path"]) for m in A[cat]):
            return "PARTIAL", {**q, "reason": f"assembly_{cat}_pairs!=policy"}
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

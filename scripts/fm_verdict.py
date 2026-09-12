#!/usr/bin/env python3
"""Fail-closed FM 判定解析器(2026-07 签核基础设施, 二审后全 P0 修订版)。

替代旧 `grep "Verification SUCCEEDED"` 的**系统性假绿灯**(Formality 回显整个 Tcl 脚本,
未锚定 grep 命中未执行分支的 puts)。本解析器 fail-closed:任何不满足全部条件的一律非-SUCCEEDED。

verdict(log, make_rc, mode, expected_top=None, allowlist=None) -> (verdict, quals)
verdict ∈ {SUCCEEDED, FAILED, WAIVED, PARTIAL, SHADOW_CHECK, DIAGNOSTIC, UNRUN, ERROR}

修订覆盖二审列出的全部 P0:
 P0-1 mode 校验:未知/拼错 mode → ERROR;diagnostic-full 永不 SUCCEEDED;shadow 只 SHADOW_CHECK。
 P0-2 assembly allowlist:unmatched 超出声明的对称黑盒配额 → PARTIAL。
 P0-3 CLI 退出码:非 SUCCEEDED 时进程非零退出(见 __main__)。
 P0-4 交叉检查 Formality 原生 verdict(非 FM_RESULT 前缀的 "Verification FAILED/INCONCLUSIVE")。
 P0-5 校验 expected_top:marker 的 "for <top>" 必须匹配,否则 WrongTop → ERROR。
 P0-6 捕获 dont-verify / ELAB-147 / blackbox 作 qualification;strict 拒绝未声明者。
 P0-7 只解析**最后一个** "Matched Compare Points" 汇总表(防较早短格式覆盖终态)。
 P0-8 汇总表缺失 → ERROR(不按零处理);表内某类别缺失才视为 0。
 P0-9 freshness:要求 run 元数据(input_hash/baseline)绑定,不匹配 → 标记 stale。
"""
import json
import os
import re

KNOWN_MODES = {"signoff-strict", "assembly", "diagnostic-full", "shadow"}

# 行首锚定的、脚本实际 emit 的最终 marker(Tcl 回显的源码行有前导空白, 不会行首匹配)。
_MARKER = re.compile(r'^FM_RESULT: Verification (SUCCEEDED|WAIVED|FAILED)\b[^\n]*?(?:for (\S+))?\s*$', re.M)
# Formality **原生** verdict(独立行, 无 FM_RESULT 前缀)——交叉检查用。
_NATIVE = re.compile(r'^\s*Verification (SUCCEEDED|FAILED|INCONCLUSIVE)\s*$', re.M)
_NOTRUN = re.compile(r'Verification NOT RUN|reference design .* is a black box|FM-081', re.M)

# 最后一个 "Matched Compare Points ... TOTAL" 汇总表块。
_TABLE_HDR = re.compile(r'Matched Compare Points.*?TOTAL', re.S)

# 表内类别行,末列 TOTAL 为总数。
_ROW = {
    "passing":    re.compile(r'^\s*Passing \(equivalent\)\s+(?:\d+\s+)*(\d+)\s*$', re.M),
    "failing":    re.compile(r'^\s*Failing \(not equivalent\)\s+(?:\d+\s+)*(\d+)\s*$', re.M),
    "unverified": re.compile(r'^\s*Unverified\s+(?:\d+\s+)*(\d+)\s*$', re.M),
    "aborted":    re.compile(r'^\s*Aborted\s+(?:\d+\s+)*(\d+)\s*$', re.M),
    "unread_nc":  re.compile(r'^\s*Unread\s+(?:\d+\s+)*(\d+)\s*$', re.M),
}
# 未配对报告(在表外),R(I) 两侧任一非 0 即未完全配对。
_UNMATCH_CP = re.compile(r'(\d+)\((\d+)\)\s+Unmatched \S+ compare points', re.M)
_UNREAD_UM  = re.compile(r'(\d+)\((\d+)\)\s+Unmatched \S+ unread points', re.M)
# black-box outputs 未配对(存在黑盒的精确信号,区别于 app_var 名回显)。
_BBOUT      = re.compile(r'(\d+)\((\d+)\)\s+Unmatched \S+ (?:primary inputs, )?black-box outputs', re.M)

# qualification 痕迹
_DONTVERIFY = re.compile(r'set_dont_verify_points|Don\'t verify', re.M)
_ELAB147    = re.compile(r'FMR_ELAB-147', re.M)


def _last_table(text):
    """返回最后一个汇总表块的文本(从最后一个表头到其后 '*****' 或文本末)。缺失返回 None。"""
    hdrs = list(_TABLE_HDR.finditer(text))
    if not hdrs:
        return None
    start = hdrs[-1].start()
    tail = text[start:]
    end = tail.find('*****')
    return tail if end < 0 else tail[:end]


def _row_int(tbl, key):
    m = None
    for mt in _ROW[key].finditer(tbl):
        m = int(mt.group(1))
    return m


def _unmatch_pair(text, pat):
    """取最后一次 R(I) 匹配的 (ref, impl) 元组;找不到返回 (None, None)。"""
    r = i = None
    for mt in pat.finditer(text):
        r, i = int(mt.group(1)), int(mt.group(2))
    return r, i


def _unmatch_max(text, pat):
    val = None
    for mt in pat.finditer(text):
        val = max(int(mt.group(1)), int(mt.group(2)))
    return val




# --- assembly 精确黑盒集合策略（codex 0139 §3.3：禁止纯数字配额）-------------
# 三类抽象边界，判定强度不同：
#   vendor_macro      厂商硬宏叶子（array_*_ext 等 .v 行为模型）——两侧同源，无条件允许
#   green_child       独立目标且已在台账通过——条件允许，须写明 child 目标名
#   golden_logic_reuse 直接复用 golden 功能逻辑当黑盒——**NO-GO**，必须独立证明后才可引用
ALLOWED_BBOX_CLASSES = {'vendor_macro', 'green_child'}


def _hier_key(path):
    """把黑盒实例路径归一到可跨两侧比对的层次键：
    去掉容器前缀（r:/i:）与 /WORK/<top>，并**抹掉 wrapper 自身的 u_core 层**
    （impl 侧 wrapper 例化可读核，天然多一级；ref 侧没有）。
    结果是"这个黑盒挂在设计里的哪个位置"，两侧应完全一致。"""
    s = re.sub(r'^[ri]:/WORK/[^/]+/?', '', path)
    s = re.sub(r'(^|/)u_core(/|$)', r'\1', s)
    return s.strip('/')


def _child_receipts():
    """green_child 背书来源：**受接受 runner 产出的 child receipt 索引**
    （docs/receipt_index.tsv，由 build_receipt_index.py 从 evidence/ 机械派生）。
    codex 0140 P0-3：不得用 WORKING 文本台账自证——那会让父子依赖循环自证。"""
    import pathlib as _pl
    _home = _pl.Path(os.environ.get('XSSV_INDEX_HOME') or os.environ.get('XSSV_HOME')
                     or _pl.Path(__file__).resolve().parent.parent)
    sys.path.insert(0, str(_pl.Path(__file__).resolve().parent))
    import build_receipt_index
    return build_receipt_index.load(_home)


def _assembly_bbox_check(observed, attrs, decl, expect_canonical=None,
                         expect_impl_commit=None):
    """观测黑盒集合须与声明**精确相等**，且每条类别合法、ref/impl 成对。
    返回 True 或失败原因串。"""
    if decl is None:
        return 'assembly_no_allow_decl(须 verif/allow/<top>.json 逐对象声明)'
    declared = {}
    for e in decl.get('objects', []):
        try:
            declared[(e['side'], e['design'], e['path'])] = e
        except KeyError:
            return 'assembly_allow_entry_missing_field'
    if observed != set(declared):
        extra = observed - set(declared)
        missing = set(declared) - observed
        det = ''
        if extra:
            det = ',observed_not_declared=' + sorted(extra)[0][2]
        elif missing:
            det = ',declared_not_observed=' + sorted(missing)[0][2]
        return f'assembly_bbox_set_mismatch:extra={len(extra)},missing={len(missing)}{det}'
    bad_cls = sorted({e.get('class', '?') for e in declared.values()} - ALLOWED_BBOX_CLASSES)
    if bad_cls:
        return f'assembly_bbox_class_not_allowed:{",".join(bad_cls)}'
    # 对称性：按**设计名的实例条数**两侧相等。
    # 为什么不比实例路径：可读核用 generate-for 数组（g_bank[0].table_bank）取代 golden
    # 的展平副本（table_banks_0），实例名本就应该不同——那正是本工程要的可读性改进。
    # 防"两侧共同黑盒错逻辑"的实际约束来自另外三条：①观测集合须与**已提交的**声明
    # 精确相等（任何新增/改名/改路径的黑盒都会打破）；②类别门控（厂商宏无条件，
    # green_child 须有独立已绿目标背书，golden_logic_reuse 直接 NO-GO）；
    # ③green_child 的 child 必须在归一化台账里确为通过。
    from collections import Counter
    ref_cnt = Counter(d for s, d, _ in declared if s == 'r')
    impl_cnt = Counter(d for s, d, _ in declared if s == 'i')
    if ref_cnt != impl_cnt:
        diff = sorted(set(ref_cnt) ^ set(impl_cnt)) or \
            sorted(d for d in ref_cnt if ref_cnt[d] != impl_cnt.get(d))
        return f'assembly_bbox_not_symmetric:{diff[0]}(ref={ref_cnt.get(diff[0], 0)},impl={impl_cnt.get(diff[0], 0)})'
    for k, e in declared.items():
        if e.get('class') == 'green_child':
            ct = e.get('child_target')
            if not ct:
                return f'assembly_green_child_without_target:{k[1]}'
            idx = _child_receipts()
            cr = idx.get(ct)
            if cr is None:
                return f'assembly_green_child_no_receipt:{ct}'
            if cr['verdict'] not in ('SUCCEEDED', 'PASS_DEAD_REF'):
                return f'assembly_green_child_receipt_not_pass:{ct}={cr["verdict"]}'
            if cr['provisional'] != 'false':
                return f'assembly_green_child_receipt_provisional:{ct}'
            if expect_canonical and cr['canonical_id'] != expect_canonical:
                return (f'assembly_green_child_canonical_mismatch:{ct}='
                        f'{cr["canonical_id"][:16]}')
            # child 必须证在父之前（或同一 commit）的 committed 字节上：
            # 要求 child.impl_commit 是父 commit 的祖先或同一个。
            # 不要求"同一 commit"——否则每加一条声明都会让先前的 child 证据失效，
            # 形成无法收敛的循环；也不比 receipt 文件摘要（重跑必变，纯噪声）。
            # 真正的字节一致性由 make_receipt 逐文件比对共享闭包完成（见该脚本）。
            if expect_impl_commit and cr['impl_commit'] != expect_impl_commit:
                import subprocess as _sp
                anc = _sp.run(['git', 'merge-base', '--is-ancestor',
                               cr['impl_commit'], expect_impl_commit],
                              cwd=os.environ.get('XSSV_HOME') or
                              os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                              stdout=_sp.DEVNULL, stderr=_sp.DEVNULL).returncode
                if anc != 0:
                    return (f'assembly_green_child_commit_not_ancestor:{ct}='
                            f'{cr["impl_commit"][:12]}')
    return True


def _dead_ref_check(q, decl, unread_points, assembly=False):
    """PASS_DEAD_REF 六条件(全满足才返回 True, 否则返回失败原因串)。
    decl = 声明 json(entries[].ref_path); unread_points = fm_eq.tcl 导出的实际未读点。"""
    if q.get("failing") not in (0, None):
        return "dead_ref_failing!=0"
    dims = ("unverified", "aborted") if assembly else ("unverified", "unmatched", "aborted")
    for k in dims:
        if q.get(k) not in (0, None):
            return f"dead_ref_{k}!=0"
    if not assembly and q.get("blackbox_out"):
        return "dead_ref_has_blackbox"
    if q["dont_verify"] or q["elab147"]:
        return "dead_ref_has_dontverify_or_elab147"
    if not assembly and q.get("unmatched_impl"):
        return f"dead_ref_impl_not_clean:{q['unmatched_impl']}"
    if unread_points is None:
        return "dead_ref_no_unread_points_file(须 fm_eq.tcl 导出)"
    obs_ref = {p for kind, p in unread_points if kind == "ref"}
    obs_other = {(k, p) for k, p in unread_points if k != "ref"}
    if obs_other:
        return f"dead_ref_nonref_unread:{len(obs_other)}"
    declared = {e["ref_path"] for e in decl.get("entries", [])}
    if obs_ref != declared:
        extra, missing = obs_ref - declared, declared - obs_ref
        return (f"dead_ref_set_mismatch:extra={len(extra)},missing={len(missing)}"
                + (f",e.g.{sorted(extra)[0]}" if extra else ""))
    q["dead_ref_points"] = len(declared)
    return True


def verdict(log_text, make_rc=0, mode="signoff-strict", expected_top=None, allowlist=0,
            dead_ref_decl=None, unread_points=None, bbox_obs=None, bbox_attrs=None,
            allow_decl=None, expect_canonical=None, expect_impl_commit=None):
    q = {"passing": None, "failing": None, "unverified": None, "unmatched": None, "aborted": None,
         "unread": None, "blackbox_out": None, "markers": 0, "make_rc": make_rc, "mode": mode,
         "native": None, "top": None, "dont_verify": bool(_DONTVERIFY.search(log_text)),
         "elab147": bool(_ELAB147.search(log_text)), "reason": None}

    # P0-1: mode 校验
    if mode not in KNOWN_MODES:
        q["reason"] = f"unknown_mode:{mode}"
        return "ERROR", q
    # P0-3 前置: make 非零 → ERROR
    if make_rc != 0:
        q["reason"] = "make_rc_nonzero"
        return "ERROR", q

    marks = _MARKER.findall(log_text)     # [(verdict, top), ...]
    q["markers"] = len(marks)
    if q["markers"] == 0:
        if _NOTRUN.search(log_text):
            return "UNRUN", q
        q["reason"] = "no_marker"
        return "ERROR", q
    if q["markers"] > 1:
        q["reason"] = "multiple_markers"    # 拼接历史/多variant → 不可信
        return "ERROR", q
    final, top = marks[0]
    q["top"] = top or None

    # P0-5 + 对抗: expected_top 校验。给了 expected_top 但 marker 无 top(无法确认是本模块)
    # 或不匹配 → ERROR(不得因 marker 缺 top 而跳过校验)。
    if expected_top:
        if not top:
            q["reason"] = "expected_top_but_marker_has_no_top"
            return "ERROR", q
        if top != expected_top:
            q["reason"] = f"wrong_top:{top}!={expected_top}"
            return "ERROR", q

    # P0-4: 交叉检查 Formality 原生 verdict
    natives = _NATIVE.findall(log_text)
    q["native"] = natives[-1] if natives else None
    if q["native"] in ("FAILED", "INCONCLUSIVE") and final == "SUCCEEDED":
        q["reason"] = f"native_{q['native']}_vs_marker_SUCCEEDED"
        return "FAILED", q

    # WAIVED / FAILED marker 直接归类
    if final == "WAIVED":
        return "WAIVED", q
    if final == "FAILED":
        return "FAILED", q

    # final == SUCCEEDED: 必须过全部数字闸门
    # P0-7 + P0-8: 只认最后一个汇总表;表缺失 → ERROR
    tbl = _last_table(log_text)
    if tbl is None:
        q["reason"] = "no_summary_table"
        return "ERROR", q
    q["passing"]    = _row_int(tbl, "passing")
    q["failing"]    = _row_int(tbl, "failing")
    q["unverified"] = _row_int(tbl, "unverified")
    q["aborted"]    = _row_int(tbl, "aborted")
    _nc = _row_int(tbl, "unread_nc")
    _umr, _umi = _unmatch_pair(log_text, _UNREAD_UM)
    q["unread"]    = max([x for x in (_nc, _umr, _umi) if x is not None], default=None)
    umr, umi = _unmatch_pair(log_text, _UNMATCH_CP)
    q["unmatched_ref"], q["unmatched_impl"] = umr, umi
    q["unmatched"] = max([x for x in (umr, umi) if x is not None], default=None)
    bbr, bbi = _unmatch_pair(log_text, _BBOUT)
    q["blackbox_out"] = max([x for x in (bbr, bbi) if x is not None], default=None)

    if q["failing"] is None:
        q["reason"] = "failing_row_missing"   # 表在但没 Failing 行 → 不确定, fail-closed
        return "ERROR", q
    if q["failing"] != 0:
        q["reason"] = "success_marker_but_failing>0"
        return "FAILED", q
    # 对抗: 空证明(passing=0)不得判绿——没有任何等价点被证明。
    if not q["passing"]:
        q["reason"] = "empty_proof_passing=0"
        return "ERROR", q

    # P0-1: 模式语义
    if mode == "diagnostic-full":
        return "DIAGNOSTIC", q                # 永不 signoff
    if mode == "shadow":
        return "SHADOW_CHECK", q              # 可读核不驱动输出, 只伴随比对
    if mode == "assembly":
        # P0-2 + 对抗: assembly 只允许**对称**黑盒(ref==impl)且总数在 allowlist 内。
        # 非对称如 5(0) 说明一侧多出未配对点(缺依赖/端口不齐), 即便 ≤allowlist 也拒绝。
        if (umr or 0) != (umi or 0):
            q["reason"] = f"assembly_asymmetric_unmatched:{umr}({umi})"
            return "PARTIAL", q
        if (q["unmatched"] or 0) > allowlist:
            q["reason"] = f"assembly_unmatched>{allowlist}:{q['unmatched']}"
            return "PARTIAL", q
        # 精确黑盒集合（唯一签核依据；数字配额只作为上面的粗筛）
        if bbox_obs is None:
            q["reason"] = "assembly_no_bbox_report(须 fm_eq.tcl 导出 black_boxes.rpt)"
            return "PARTIAL", q
        bb = _assembly_bbox_check(bbox_obs, bbox_attrs or {}, allow_decl,
                                  expect_canonical, expect_impl_commit)
        if bb is not True:
            q["reason"] = bb
            return "PARTIAL", q
        q["bbox_objects"] = len(bbox_obs)
        for k in ("unverified", "aborted"):
            if q.get(k) not in (0, None):
                q["reason"] = f"assembly_{k}!=0"
                return "PARTIAL", q
        if q.get("unread"):
            # 同 strict: 唯一残余是 golden 侧 cone-dead 未读点且与声明精确相等 ⇒ PASS_DEAD_REF
            if dead_ref_decl is None:
                q["reason"] = "assembly_unread!=0"
                return "PARTIAL", q
            dr = _dead_ref_check(q, dead_ref_decl, unread_points, assembly=True)
            if dr is True:
                return "PASS_DEAD_REF", q
            q["reason"] = dr
            return "PARTIAL", q
        return "SUCCEEDED", q
    # signoff-strict: 全部质保维为 0 + 无任何黑盒(strict-replacement 不允许子模块抽象)。
    # 例外 PASS_DEAD_REF: 唯一残余是 **golden 侧 cone-dead 未读点**(impl 干净),
    # 且观测集合与声明文件**精确相等**(多一条/少一条/换一条都退 PARTIAL)。
    # 不是 waiver: 声明逐条列出 ref_path, FM 仍证明了全部可达点等价。
    if dead_ref_decl is not None and q.get("unread"):
        dr = _dead_ref_check(q, dead_ref_decl, unread_points)
        if dr is True:
            return "PASS_DEAD_REF", q
        q["reason"] = dr
        return "PARTIAL", q
    for k in ("unverified", "unmatched", "aborted", "unread"):
        if q.get(k) not in (0, None):
            q["reason"] = f"strict_{k}!=0"
            return "PARTIAL", q
    if q.get("blackbox_out"):
        q["reason"] = "strict_has_blackbox"    # 未声明黑盒 → 非纯替换
        return "PARTIAL", q
    if q["dont_verify"] or q["elab147"]:
        q["reason"] = "strict_has_dontverify_or_elab147"
        return "PARTIAL", q
    return "SUCCEEDED", q


if __name__ == "__main__":
    import sys, json, argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("log"); ap.add_argument("--rc", type=int, default=0)
    ap.add_argument("--mode", default="signoff-strict")
    ap.add_argument("--top", default=None)
    ap.add_argument("--allowlist", type=int, default=0)
    ap.add_argument("--dead-ref", default=None,
                    help="PASS_DEAD_REF 声明 json(entries[].ref_path 精确枚举)")
    ap.add_argument("--unread-points", default=None,
                    help="fm_eq.tcl 导出的 unread_points.txt")
    ap.add_argument("--bbox-report", default=None,
                    help="fm_eq.tcl 导出的 black_boxes.rpt（assembly 必需）")
    ap.add_argument("--allow", default=None,
                    help="assembly 黑盒精确声明 verif/allow/<top>.json")
    ap.add_argument("--canonical-id", default=None,
                    help="本次 G1 canonical ID；green_child 的 child receipt 必须同源")
    ap.add_argument("--impl-commit", default=None,
                    help="本次 impl commit；green_child 必须在同一 committed 树上被证明")
    a = ap.parse_args()
    txt = open(a.log).read()
    decl = None
    if a.dead_ref and os.path.exists(a.dead_ref):
        with open(a.dead_ref) as f:
            decl = json.load(f)
    pts = None
    if a.unread_points and os.path.exists(a.unread_points):
        pts = []
        with open(a.unread_points) as f:
            for ln in f:
                if "\t" in ln:
                    k, p = ln.rstrip("\n").split("\t", 1)
                    pts.append((k, p))
    bbox_obs = bbox_attrs = None
    if a.bbox_report and os.path.exists(a.bbox_report):
        sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
        import bbox_parse
        try:
            bbox_obs, bbox_attrs = bbox_parse.normalize(
                bbox_parse.parse(open(a.bbox_report).read()))
        except bbox_parse.BBoxParseError as e:
            print("ERROR\t" + json.dumps({"reason": f"bbox_parse:{e}"}, ensure_ascii=False))
            sys.exit(1)
    allow_decl = None
    if a.allow and os.path.exists(a.allow):
        with open(a.allow) as f:
            allow_decl = json.load(f)
    v, q = verdict(txt, a.rc, a.mode, a.top, a.allowlist, decl, pts,
                   bbox_obs, bbox_attrs, allow_decl, a.canonical_id, a.impl_commit)
    print(v + "\t" + json.dumps(q, ensure_ascii=False))
    # P0-3: 只有 SUCCEEDED 退 0；其余非零(签核 CI fail-closed)。
    # PASS_DEAD_REF 例外：仅当调用方显式给了 --dead-ref 声明文件(即该目标已被审计、
    # 声明已提交)时才算通过——没有声明的 unread 一律非零退出，不会被静默放行。
    sys.exit(0 if v == "SUCCEEDED" or (v == "PASS_DEAD_REF" and a.dead_ref) else 1)

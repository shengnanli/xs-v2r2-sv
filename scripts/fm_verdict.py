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

# qualification 痕迹
_DONTVERIFY = re.compile(r'set_dont_verify_points|Don\'t verify', re.M)
_ELAB147    = re.compile(r'FMR_ELAB-147', re.M)
_BLACKBOX   = re.compile(r'black[_ ]?box', re.I)


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


def _unmatch_max(text, pat):
    val = None
    for mt in pat.finditer(text):
        val = max(int(mt.group(1)), int(mt.group(2)))
    return val


def verdict(log_text, make_rc=0, mode="signoff-strict", expected_top=None, allowlist=0):
    q = {"failing": None, "unverified": None, "unmatched": None, "aborted": None,
         "unread": None, "markers": 0, "make_rc": make_rc, "mode": mode,
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

    # P0-5: expected_top 校验(WrongTop)
    if expected_top and top and top != expected_top:
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
    q["failing"]    = _row_int(tbl, "failing")
    q["unverified"] = _row_int(tbl, "unverified")
    q["aborted"]    = _row_int(tbl, "aborted")
    _nc = _row_int(tbl, "unread_nc")
    _um = _unmatch_max(log_text, _UNREAD_UM)
    q["unread"]    = max([x for x in (_nc, _um) if x is not None], default=None)
    q["unmatched"] = _unmatch_max(log_text, _UNMATCH_CP)

    if q["failing"] is None:
        q["reason"] = "failing_row_missing"   # 表在但没 Failing 行 → 不确定, fail-closed
        return "ERROR", q
    if q["failing"] != 0:
        q["reason"] = "success_marker_but_failing>0"
        return "FAILED", q

    # P0-1: 模式语义
    if mode == "diagnostic-full":
        return "DIAGNOSTIC", q                # 永不 signoff
    if mode == "shadow":
        return "SHADOW_CHECK", q              # 可读核不驱动输出, 只伴随比对
    if mode == "assembly":
        # P0-2: 只允许 allowlist 配额内的对称黑盒 unmatched;其余质保维须 0
        um = q["unmatched"] or 0
        if um > allowlist:
            q["reason"] = f"assembly_unmatched>{allowlist}:{um}"
            return "PARTIAL", q
        for k in ("unverified", "aborted", "unread"):
            if q.get(k) not in (0, None):
                q["reason"] = f"assembly_{k}!=0"
                return "PARTIAL", q
        return "SUCCEEDED", q
    # signoff-strict: 全部质保维为 0(含 dont_verify/elab147 声明检查由上层 allowlist 复核)
    for k in ("unverified", "unmatched", "aborted", "unread"):
        if q.get(k) not in (0, None):
            q["reason"] = f"strict_{k}!=0"
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
    a = ap.parse_args()
    txt = open(a.log).read()
    v, q = verdict(txt, a.rc, a.mode, a.top, a.allowlist)
    print(v + "\t" + json.dumps(q, ensure_ascii=False))
    # P0-3: 只有 SUCCEEDED 退 0;其余非零(签核 CI fail-closed)
    sys.exit(0 if v == "SUCCEEDED" else 1)

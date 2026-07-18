#!/usr/bin/env python3
"""Fail-closed FM 判定解析器(2026-07 签核基础设施)。

替代此前 `grep "Verification SUCCEEDED"` 的**系统性假绿灯 bug**:Formality 日志会**回显整个
Tcl 脚本**(含未执行分支里的 `puts "...SUCCEEDED..."`),未锚定的 grep 会把真 FAILED 判成绿。

本解析器 **fail-closed**:任何不满足全部条件的情况一律非-SUCCEEDED。判定一个 fresh 日志:

  verdict(log_text, make_rc, mode) -> (verdict, quals)

verdict ∈ {SUCCEEDED, FAILED, WAIVED, UNRUN, ERROR}
quals   = dict(failing, unverified, unmatched, aborted, notrun, markers...)

SUCCEEDED 的**全部**必要条件:
  1. make_rc == 0
  2. 日志里**恰好一个**行首锚定的最终 marker `^FM_RESULT: Verification ...`
  3. 该 marker 是 SUCCEEDED(WAIVED 单独归类,绝不算 SUCCEEDED)
  4. failing == 0
  5. mode=signoff-strict 时: unverified==0 且 unmatched==0 且 aborted==0
     (mode=assembly 允许 manifest 声明的对称黑盒→由上层按 allowlist 复核, 本层仍要求 failing==0)
本解析器只读**传入的单个 fresh 日志文本**,不搜历史日志、不看别的 variant。
"""
import re

# 只认行首锚定的、脚本实际 emit 的最终结果行(Tcl 回显的源码行有前导空白, 不会行首匹配)。
_MARKER = re.compile(r'^FM_RESULT: Verification (SUCCEEDED|WAIVED|FAILED)\b.*$', re.M)
# FM 统计表行,末列 TOTAL 为总数(如 "Failing (not equivalent)  20 0 0 0 0 0 0  20");
# 兼容 report_failing_points 的 "N Failing compare points" 短格式。
_FAILING_TOT = re.compile(r'^\s*Failing \(not equivalent\)\s+(?:\d+\s+)*(\d+)\s*$', re.M)
_FAILING_CP  = re.compile(r'(\d+)\s+Failing compare points', re.M)
# Unverified 表格行(无 "(not equivalent)" 后缀),末列 TOTAL;或短格式。
_UNVER_TOT   = re.compile(r'^\s*Unverified\s+(?:\d+\s+)*(\d+)\s*$', re.M)
_UNVER_CP    = re.compile(r'(\d+)\s+Unverified compare points', re.M)
# Unmatched: "R(I) Unmatched reference(implementation) compare points" —— R=ref侧, I=impl侧。
# 任一侧非 0 都是未完全配对(如 XSCore "0(31196)" = impl 有 31196 点没参与验证 = PARTIAL)。
_UNMATCH_CP  = re.compile(r'(\d+)\((\d+)\)\s+Unmatched \S+ compare points', re.M)
_ABORT_TOT   = re.compile(r'^\s*Aborted\s+(?:\d+\s+)*(\d+)\s*$', re.M)
_ABORT_CP    = re.compile(r'(\d+)\s+Aborted compare points', re.M)
# Unread(P0):fm_eq.tcl 设 verification_verify_unread_compare_points=false → 跳过 unread 点的验证。
# 两类都要计入 strict qualification:①"Not Compared / Unread" 表格行(配对了但没验),末列 TOTAL;
# ②"R(I) Unmatched ... unread points"(未配对 unread)。
_UNREAD_NC   = re.compile(r'^\s*Unread\s+(?:\d+\s+)*(\d+)\s*$', re.M)
_UNREAD_UM   = re.compile(r'(\d+)\((\d+)\)\s+Unmatched \S+ unread points', re.M)
_NOTRUN      = re.compile(r'Verification NOT RUN|reference design .* is a black box|FM-081', re.M)


def _last_int(pats, text):
    """取最后一次出现的整数(FM 会多次打印, 末次为终态)。找不到返回 None。
    对多捕获组(如 Unmatched 的 R(I))取该次匹配所有组的最大值。"""
    val = None
    for pat in pats:
        for mt in pat.finditer(text):
            val = max(int(g) for g in mt.groups() if g is not None)
    return val


def verdict(log_text, make_rc=0, mode="signoff-strict"):
    q = {"failing": None, "unverified": None, "unmatched": None,
         "aborted": None, "unread": None, "markers": 0, "make_rc": make_rc, "mode": mode}

    markers = _MARKER.findall(log_text)
    marker_lines = _MARKER.findall(log_text)  # 值(SUCCEEDED/WAIVED/FAILED)
    q["markers"] = len(marker_lines)

    q["failing"]    = _last_int([_FAILING_TOT, _FAILING_CP], log_text)
    q["unverified"] = _last_int([_UNVER_TOT, _UNVER_CP], log_text)
    q["unmatched"]  = _last_int([_UNMATCH_CP], log_text)
    q["aborted"]    = _last_int([_ABORT_TOT, _ABORT_CP], log_text)
    # unread 取两类的最大(Not-Compared-Unread 与 Unmatched-unread 任一非 0 都是未验证点)
    _nc = _last_int([_UNREAD_NC], log_text)
    _um = _last_int([_UNREAD_UM], log_text)
    q["unread"] = max([x for x in (_nc, _um) if x is not None], default=None)

    # --- fail-closed 判定链 ---
    # make 非零 → 一律 ERROR(即便日志看似成功)
    if make_rc != 0:
        return "ERROR", q
    # 无 marker → 可能被杀/超时/link 失败
    if q["markers"] == 0:
        if _NOTRUN.search(log_text):
            return "UNRUN", q
        return "ERROR", q
    # 多个最终 marker → 日志不干净(拼接了历史/多 variant),不可信
    if q["markers"] > 1:
        return "ERROR", q
    final = marker_lines[0]
    if final == "WAIVED":
        return "WAIVED", q          # 绝不升级为 SUCCEEDED
    if final == "FAILED":
        return "FAILED", q
    # final == SUCCEEDED: 还必须过数字闸门
    if q["failing"] not in (0, None):   # failing>0 而标 SUCCEEDED = 假绿, 打回
        return "FAILED", q
    if q["failing"] is None:
        # 有 SUCCEEDED marker 但没有 report 统计行 → 无法确认 failing=0, fail-closed
        return "ERROR", q
    if mode == "signoff-strict":
        # strict replacement 要求全部质保维为 0:unverified/unmatched/aborted/unread。
        # unread 尤其关键——fm_eq.tcl 禁验 unread 点,它们"配对了但没验证",strict 不能放过。
        for k in ("unverified", "unmatched", "aborted", "unread"):
            if q.get(k) not in (0, None):
                q["strict_reject"] = k
                return "PARTIAL", q     # 有未验/未配对/未读 → 非 strict-clean
    return "SUCCEEDED", q


if __name__ == "__main__":
    import sys, json
    txt = open(sys.argv[1]).read() if len(sys.argv) > 1 else sys.stdin.read()
    rc = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    mode = sys.argv[3] if len(sys.argv) > 3 else "signoff-strict"
    v, q = verdict(txt, rc, mode)
    print(v + "\t" + json.dumps(q))

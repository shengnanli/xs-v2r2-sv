#!/usr/bin/env python3
# analyze_family_points.py — 从 FM matched/unmatched 报告统计 commit-state family
# (valid/uopNum/stdWritebacked)相关的 golden 比较点(compare points)的匹配情况。
# 用于 packed vs SoA 家族隔离 A/B: 该 family 的 matched/unmatched golden DFF 点数。
import re, sys, json

FAMILY_SUF = ("valid", "uopNum", "stdWritebacked")


def count_family(rpt_path):
    """统计报告里 robEntries_<N>_<family> golden(Ref)点数。"""
    per = {s: 0 for s in FAMILY_SUF}
    total_lines = 0
    if not rpt_path:
        return per, 0
    try:
        txt = open(rpt_path).read()
    except FileNotFoundError:
        return per, 0
    for ln in txt.splitlines():
        m = re.search(r'robEntries_(\d+)_(valid|uopNum|stdWritebacked)\b', ln)
        if m and ('r:' in ln or 'Ref' in ln or 'robEntries' in ln):
            per[m.group(2)] += 1
            total_lines += 1
    return per, total_lines


def main():
    matched = sys.argv[1] if len(sys.argv) > 1 else None
    unmatched = sys.argv[2] if len(sys.argv) > 2 else None
    label = sys.argv[3] if len(sys.argv) > 3 else "run"
    m_per, m_tot = count_family(matched)
    u_per, u_tot = count_family(unmatched)
    out = {
        "label": label,
        "family_matched": m_per, "family_matched_total": m_tot,
        "family_unmatched": u_per, "family_unmatched_total": u_tot,
    }
    print(json.dumps(out, indent=2))


if __name__ == "__main__":
    main()

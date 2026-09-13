#!/usr/bin/env python3
"""audit_vs_observed.py —— expected（本目录独立生成）× observed（历史 black_boxes.rpt）
对照表。**只作候选审计表**（codex 0150 明确允许这一用途）：差异一律如实列出，
绝不反过来改 expected 去迁就 observed。

observed 来自主树 evidence/<commit>/<target>/black_boxes.rpt（历史诊断证据，
codex 0148 已裁定旧 189 批 receipt 不得 bank）。
"""
import glob, json, os, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(REPO / 'scripts'))
sys.path.insert(0, str(HERE))
import bbox_parse

MAIN = pathlib.Path('/home/eda/xs-env/xs-v2-sv')
sets = json.load(open(HERE / 'expected_sets.json'))
rows = []
for t in sorted(sets):
    exp = {(s, d, p) for s, d, p in sets[t]['objects']}
    reps = sorted(glob.glob(str(MAIN / 'evidence' / '*' / t / 'black_boxes.rpt')))
    if not reps:
        print(f'### {t}: expected={len(exp)}  observed=<无历史报告>')
        rows.append((t, len(exp), None, None, None))
        continue
    for rp in reps:
        commit = pathlib.Path(rp).parent.parent.name
        try:
            obs = {(s, d, p) for s, a, d, p in bbox_parse.parse(open(rp).read())}
        except Exception as e:
            print(f'### {t} @{commit}: 报告解析失败 {e}')
            continue
        extra = obs - exp
        missing = exp - obs
        verdict = 'EQUAL' if not extra and not missing else 'DIFF'
        print(f'### {t} @{commit}: expected={len(exp)} observed={len(obs)} -> {verdict}')
        for x in sorted(extra):
            print(f'    observed_not_expected  {x[0]} {x[1]:28} {x[2]}')
        for x in sorted(missing):
            print(f'    expected_not_observed  {x[0]} {x[1]:28} {x[2]}')
        rows.append((t, len(exp), commit, len(obs), verdict))
print()
print('target\texpected_n\tevidence_commit\tobserved_n\tverdict')
for r in rows:
    print('\t'.join('' if x is None else str(x) for x in r))

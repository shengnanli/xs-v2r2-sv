#!/usr/bin/env python3
"""从 18 个 UT 目录的 sim 日志里机械读出 checks/errors，生成对账表。"""
import pathlib, re, sys
R = pathlib.Path('/home/eda/xs-env/wt-othersent')
mods = sorted(p.stem for p in (R/'rtl/backend').glob('OthersEntry*.sv'))
rows, bad = [], 0
for m in mods:
    d = R/'verif/ut'/m
    rec = {}
    for tag, pat in (('random', 'sim_%d.log'), ('initreg0', 'sim_ir0_%d.log')):
        for s in (1, 7, 42):
            f = d/(pat % s)
            if not f.exists():
                rec[(tag, s)] = 'MISSING'; bad += 1; continue
            t = f.read_text(errors='replace')
            mm = re.search(r'checks=(\d+), errors=(\d+)', t)
            ok = 'TEST PASSED' in t
            if not mm or not ok:
                rec[(tag, s)] = 'NO-PASS'; bad += 1; continue
            rec[(tag, s)] = (int(mm.group(1)), int(mm.group(2)))
            if int(mm.group(2)) != 0:
                bad += 1
    rows.append((m, rec))
print('| 变体 | 档 | seed1 checks/errors | seed7 checks/errors | seed42 checks/errors |')
print('|---|---|---|---|---|')
for m, rec in rows:
    for tag in ('random', 'initreg0'):
        cells = []
        for s in (1, 7, 42):
            v = rec[(tag, s)]
            cells.append(v if isinstance(v, str) else '%d / **%d**' % v)
        print('| `%s` | %s | %s |' % (m, tag, ' | '.join(cells)))
print()
print('不合格项：%d' % bad)
sys.exit(1 if bad else 0)

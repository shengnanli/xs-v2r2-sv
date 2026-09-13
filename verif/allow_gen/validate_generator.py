#!/usr/bin/env python3
"""对 52 份**已被接受**的 verif/allow/*.json 做生成器交叉校验：
用纯设计源派生的 expected set 与它们逐条比对。全等即证明生成器口径正确，
之后才允许把它用到没有声明的目标上。"""
import glob, json, os, pathlib, re, subprocess, sys
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gen_expected
REPO = HERE.parent.parent

# UT 目录 -> 变体表（从 Makefile 读，不手抄）
pairs = []
for mk in sorted(glob.glob(str(REPO / 'verif/ut/*/Makefile'))):
    t = open(mk).read().replace('\\\n', ' ')
    m = re.search(r'^FM_MODE\s*[:?]?=\s*(\S+)', t, re.M)
    if not m or m.group(1) != 'assembly':
        continue
    d = os.path.dirname(mk)
    v = re.search(r'^FM_VARIANTS\s*[:?]?=\s*(.*)$', t, re.M)
    for x in (v.group(1).split() if v else [os.path.basename(d)]):
        pairs.append((d, x))

ok = bad = noallow = 0
for d, t in pairs:
    af = REPO / 'verif' / 'allow' / f'{t}.json'
    r = gen_expected.build(d, t)
    exp = {(s, dg, p) for s, dg, p in r['objects']}
    if r.get('errors'):
        print(f'[ELAB-ERR] {t:26} {r["errors"]}')
        bad += 1
        continue
    if not af.exists():
        noallow += 1
        print(f'[NO-ALLOW] {t:26} expected={len(exp):3}  warn={r["warnings"] or ""}')
        continue
    acc = {(o['side'], o['design'], o['path']) for o in json.load(af.open())['objects']}
    if exp == acc:
        ok += 1
        print(f'[MATCH   ] {t:26} n={len(exp)}')
    else:
        bad += 1
        print(f'[MISMATCH] {t:26} expected={len(exp)} accepted={len(acc)}')
        for x in sorted(exp - acc):
            print('            +exp_only', x[2])
        for x in sorted(acc - exp):
            print('            -acc_only', x[2])
        if r['warnings']:
            print('            warn:', r['warnings'])
print(f'\n== MATCH {ok} / MISMATCH {bad} / NO-ALLOW {noallow} ==')

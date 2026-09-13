#!/usr/bin/env python3
"""对缺 allow 声明的 assembly 目标产出 expected set 审计表（阶段 1 交付物）。"""
import collections, glob, json, os, pathlib, re, sys
HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import gen_expected
REPO = HERE.parent.parent
reg = gen_expected.vendor_registry()

pairs = []
for mk in sorted(glob.glob(str(REPO / 'verif/ut/*/Makefile'))):
    t = open(mk).read().replace('\\\n', ' ')
    m = re.search(r'^FM_MODE\s*[:?]?=\s*(\S+)', t, re.M)
    if not m or m.group(1) != 'assembly':
        continue
    d = os.path.dirname(mk)
    v = re.search(r'^FM_VARIANTS\s*[:?]?=\s*(.*)$', t, re.M)
    for x in (v.group(1).split() if v else [os.path.basename(d)]):
        if not (REPO / 'verif' / 'allow' / f'{x}.json').exists():
            pairs.append((d, x))

allres = {}
for d, t in pairs:
    r = gen_expected.build(d, t)
    allres[t] = r
    rc = collections.Counter(dg for s, dg, _ in r['objects'] if s == 'r')
    ic = collections.Counter(dg for s, dg, _ in r['objects'] if s == 'i')
    known = {dg for dg in set(rc) | set(ic) if dg in reg}
    unk = sorted({dg for dg in set(rc) | set(ic) if dg not in reg})
    sym = 'SYMMETRIC' if rc == ic else 'ASYMMETRIC'
    print(f'--- {t}  (utdir={os.path.basename(d)})  n={len(r["objects"])}  {sym}')
    if r.get('errors'):
        print('    ELAB-ERROR:', r['errors'])
    for dg in sorted(set(rc) | set(ic)):
        tag = 'A1 vendor_macro(registry)' if dg in reg else '**NOT-IN-REGISTRY**'
        print(f'    {dg:44} ref={rc.get(dg,0):3} impl={ic.get(dg,0):3}  {tag}')
    if r['warnings']:
        print('    warn:', r['warnings'])
json.dump({k: {'objects': v['objects'], 'warnings': v['warnings'],
               'errors': v.get('errors', []),
               'ref_files': v['ref_files'], 'impl_files': v['impl_files'],
               'utdir': v['utdir']}
           for k, v in allres.items()},
          open(HERE / 'expected_sets.json', 'w'), ensure_ascii=False, indent=1)
print('\n-> verif/allow_gen/expected_sets.json')

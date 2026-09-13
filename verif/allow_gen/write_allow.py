#!/usr/bin/env python3
"""write_allow.py —— 把**独立生成**的 expected set 落成 verif/allow/<top>.json。

输入 = verif/allow_gen/expected_sets.json（由 report_expected.py 从设计源 +
elaboration 元数据产生，未读任何 FM 产物）。
分类 = verif/vendor_boundary.tsv（冻结 registry）自动归 vendor_macro；
       registry 外的一律拒绝落盘（不为迁就 observed 扩表，codex 0148 A1）。
输出 schema/字段/排序与 scripts/declare_allow.py 完全一致（该脚本此处只当格式基准）。
"""
import json, pathlib, sys
HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(HERE))
import gen_expected

CANON = pathlib.Path('/home/eda/xs-env/G1-canonical/CANONICAL_ID.txt').read_text().strip()
reg = gen_expected.vendor_registry()
sets = json.load(open(HERE / 'expected_sets.json'))

targets = sys.argv[1:]
for t in targets:
    r = sets[t]
    if r.get('errors'):
        sys.exit(f'{t}: expected set 有 elaboration 错误，拒绝落盘: {r["errors"]}')
    ents = []
    for side, design, path in r['objects']:
        if design not in reg:
            sys.exit(f'{t}: {design} 不在冻结 registry —— 拒绝落盘（本批不得扩表）')
        ents.append((side, 'u', design, path))
    objs = [{'side': s, 'design': d, 'path': p, 'attrs': a, 'class': 'vendor_macro'}
            for s, a, d, p in sorted(ents)]
    out = REPO / 'verif' / 'allow' / f'{t}.json'
    out.write_text(json.dumps({
        'schema': 'xs-v2-sv-allow-v1',
        'target': t,
        'baseline': CANON,
        'objects': objs,
    }, ensure_ascii=False, indent=1))
    print(f'{t}: 声明 {len(objs)} 个黑盒对象 -> {out.relative_to(REPO)}')

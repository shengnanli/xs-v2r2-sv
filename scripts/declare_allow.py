#!/usr/bin/env python3
"""declare_allow.py —— 由实跑观测生成 assembly 黑盒精确声明（逐对象/逐路径/逐类别）。

codex 0139 §3.3：assembly 不得再用数字配额。本声明逐条列出黑盒实例，判定时
观测集合须与声明**精确相等**，且每条必须归入允许类别：
  vendor_macro  厂商硬宏叶子（array_*_ext 等 .v 行为模型，两侧同源）——无条件允许
  green_child   独立目标且已在台账通过——须填 child_target
  golden_logic_reuse —— NO-GO，声明成这一类会被判 PARTIAL（必须先独立证明）

vendor_macro 由文件名规则自动归类（*_ext）；其余一律要求 --class/--child 显式指定，
不允许脚本替人判断。

用法: declare_allow.py <top> --report <black_boxes.rpt>
        [--class <design>=<类别>[:<child_target>] ...]
"""
import argparse, json, os, pathlib, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bbox_parse

NEW = pathlib.Path('/home/eda/xs-env/xs-v2-sv')

ap = argparse.ArgumentParser()
ap.add_argument('top')
ap.add_argument('--report', required=True)
ap.add_argument('--class', dest='cls', nargs='*', default=[])
a = ap.parse_args()

manual = {}
for spec in a.cls:
    d, _, rest = spec.partition('=')
    c, _, child = rest.partition(':')
    manual[d] = (c, child or None)

ents = bbox_parse.parse(open(a.report).read())
objs = []
for side, attrs, design, path in sorted(ents):
    if design in manual:
        cls, child = manual[design]
    elif design.endswith('_ext'):
        cls, child = 'vendor_macro', None
    else:
        sys.exit(f'ERROR: {design} 非厂商宏叶子，须用 --class {design}=green_child:<目标> '
                 f'或 --class {design}=golden_logic_reuse 显式声明（后者会被判 PARTIAL）')
    e = {'side': side, 'design': design, 'path': path, 'attrs': attrs, 'class': cls}
    if child:
        e['child_target'] = child
    objs.append(e)

out = NEW / 'verif' / 'allow' / f'{a.top}.json'
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(json.dumps({
    'schema': 'xs-v2-sv-allow-v1',
    'target': a.top,
    'baseline': (NEW.parent / 'G1-canonical' / 'CANONICAL_ID.txt').read_text().strip(),
    'objects': objs,
}, ensure_ascii=False, indent=1))
print(f'{a.top}: 声明 {len(objs)} 个黑盒对象 -> {out.relative_to(NEW)}')

#!/usr/bin/env python3
"""declare_allow.py —— 由实跑观测生成 assembly 黑盒精确声明（逐对象/逐路径/逐类别）。

codex 0139 §3.3：assembly 不得再用数字配额。本声明逐条列出黑盒实例，判定时
观测集合须与声明**精确相等**，且每条必须归入允许类别：
  vendor_macro  厂商硬宏叶子（.v 行为模型，两侧同源）——须**逐条**在
                verif/vendor_boundary.tsv 审定入表，按表内精确模块名放行
  green_child   独立目标且已在台账通过——须填 child_target
  golden_logic_reuse —— NO-GO，声明成这一类会被判 PARTIAL（必须先独立证明）

vendor_macro **只按 verif/vendor_boundary.tsv 的精确模块名**自动归类，且该表逐条绑定
端口签名/深度/mask 粒度/时钟语义/body hash；★禁止按 `*_ext` 等名字形状批量放行★
（codex 0153 D67）——名字像存储宏而内含功能逻辑的模块正是本规则要挡的东西。
表外一律要求 --class/--child 显式指定，不允许脚本替人判断。
负例见 scripts/test_ext_registry_negative.py（合成带 FSM 的假 `_ext`，实测被拒）。

用法: declare_allow.py <top> --report <black_boxes.rpt>
        [--class <design>=<类别>[:<child_target>] ...]
"""
import argparse, json, os, pathlib, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bbox_parse

import os
_HERE = pathlib.Path(__file__).resolve().parent
NEW = pathlib.Path(os.environ.get('XSSV_HOME') or _HERE.parent)

ap = argparse.ArgumentParser()
ap.add_argument('top')
ap.add_argument('--report', required=True)
ap.add_argument('--class', dest='cls', nargs='*', default=[])
a = ap.parse_args()

# codex 0142 §50：禁止自动批准。自动归类只对**已审定并提交**的厂商边界名单生效
# （verif/vendor_boundary.tsv），表外一律要求逐条显式 --class。
VENDOR = set()
vb = NEW / 'verif' / 'vendor_boundary.tsv'
if vb.exists():
    for _l in vb.read_text().splitlines():
        if _l.startswith('#') or not _l.strip():
            continue
        VENDOR.add(_l.split('\t')[0])

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
    elif design in VENDOR:
        cls, child = 'vendor_macro', None
    else:
        sys.exit(f'ERROR: {design} 不在已审定的厂商边界名单（verif/vendor_boundary.tsv）。'
                 f'须逐条人工分类：--class {design}=green_child:<已证目标>，'
                 f'或先把它审定进厂商边界名单，'
                 f'或 --class {design}=golden_logic_reuse（NO-GO，会被判 PARTIAL）')
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

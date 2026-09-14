#!/usr/bin/env python3
"""declare_allow.py —— 由实跑观测生成 assembly 黑盒精确声明（逐对象/逐路径/逐类别）。

codex 0139 §3.3：assembly 不得再用数字配额。本声明逐条列出黑盒实例，判定时
观测集合须与声明**精确相等**，且每条必须归入允许类别：
  vendor_macro  厂商硬宏叶子（.v 行为模型，两侧同源）——须**逐条**在
                verif/vendor_boundary.tsv 审定入表，按表内精确模块名放行
  APPROVED_MEMORY_MACRO_MODEL  逐条审定的存储宏行为模型（D67 的 array_*_ext 六条、
                0158 §1 的 firtool ram_* 若干）——同样只按表内精确模块名放行；
                自动归类用的是表里那条的 **kind**，不是一律 vendor_macro
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

# ★克隆位置不该是承重结构★（2026-09-14）
# 此前 baseline 取 `NEW.parent / 'G1-canonical' / CANONICAL_ID.txt`，即按**仓库父目录**
# 解析 golden。于是把仓库克隆到别处（哪怕只是为了在 clean clone 里跑一遍测试）就炸在
# FileNotFoundError，且 XSSV_HOME 绕不开 —— 它设的是 NEW，代码取的是 NEW.parent。
# 改成绝对默认 + 可覆盖 flag，与 scripts/boundary_ledger.py 的 --canonical-id 一致。
DEFAULT_CANONICAL_ID = '/home/eda/xs-env/G1-canonical/CANONICAL_ID.txt'

ap = argparse.ArgumentParser()
ap.add_argument('top')
ap.add_argument('--report', required=True)
ap.add_argument('--class', dest='cls', nargs='*', default=[])
ap.add_argument('--canonical-id', default=DEFAULT_CANONICAL_ID,
                help='G1 canonical ID 文件；默认绝对路径，故克隆位置无关。')
a = ap.parse_args()

# codex 0142 §50：禁止自动批准。自动归类只对**已审定并提交**的厂商边界名单生效
# （verif/vendor_boundary.tsv），表外一律要求逐条显式 --class。
# 自动归类**用表里那条的 kind**，不是一律 vendor_macro（codex 0158 §1）：
#   kind=vendor_sram_leaf              -> class vendor_macro（D60 的 20 条 SRAM 编译器叶子）
#   kind=APPROVED_MEMORY_MACRO_MODEL   -> class 同名（D67 的 6 条 + 0158 §1 的 ram_*）
# 两个 class 在 fm_verdict.ALLOWED_BBOX_CLASSES 里都是无条件允许，所以这不改变**判定强度**；
# 改的是**声明的真实性** —— firtool 行为级 RAM 模型不是厂商 SRAM 编译器叶子，
# 写成 vendor_macro 是把证据写错，而证据写错正是本工程反复踩到的那类坑。
_KIND2CLASS = {'vendor_sram_leaf': 'vendor_macro',
               'APPROVED_MEMORY_MACRO_MODEL': 'APPROVED_MEMORY_MACRO_MODEL'}
VENDOR = {}
vb = NEW / 'verif' / 'vendor_boundary.tsv'
if vb.exists():
    for _l in vb.read_text().splitlines():
        if _l.startswith('#') or not _l.strip():
            continue
        _f = _l.split('\t')
        _k = _f[1] if len(_f) > 1 else ''
        if _k not in _KIND2CLASS:
            # fail-closed：表里出现本脚本不认识的 kind，不许猜一个 class 出来。
            sys.exit(f'ERROR: verif/vendor_boundary.tsv 里 {_f[0]} 的 kind={_k!r} '
                     f'本脚本不认识（已知 {sorted(_KIND2CLASS)}）——拒绝自动归类')
        VENDOR[_f[0]] = _KIND2CLASS[_k]

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
        cls, child = VENDOR[design], None
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
    'baseline': pathlib.Path(a.canonical_id).read_text().strip(),
    'objects': objs,
}, ensure_ascii=False, indent=1))
print(f'{a.top}: 声明 {len(objs)} 个黑盒对象 -> {out.relative_to(NEW)}')

#!/usr/bin/env python3
"""gen_expected.py —— 独立生成 assembly expected 黑盒集合（codex 0150 阶段 1）。

**输入来源（三样，全部与 FM 运行结果无关）**：
  1. 设计源：GOLDEN_RTL/*.sv（ref 侧）与 rtl/**/*.sv（impl 侧）——用 sv_hier.py
     解析 module/instance 层次图；
  2. elaboration 元数据：verif/ut/<dir>/Makefile 的 FM_REF_SRCS / FM_IMPL_SRCS
     构成（= GOLDEN_RTL/<top>.sv + FM_REF_DEPS_<top>；RTL_SRCS + RTL_GOLDEN_DEPS），
     由 `make` 自己展开，不手抄；
  3. 已审冻结 registry：verif/vendor_boundary.tsv（分类用，不用于产生集合）。

**绝不读** fm_work/**/black_boxes.rpt、native_facts.json、fm.log。

expected 定义：从 top 出发按层次图 DFS，遇到**不在该侧 elaboration 文件集里定义
的模块类型**即为该侧未解析黑盒（attrs='u'），记其实例路径。
"""
import json
import os
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent.parent
sys.path.insert(0, str(HERE))
import sv_elab  # noqa: E402

MARK = '@@'


def make_vars(utdir, target):
    """用 make 自己展开 elaboration 变量（不执行任何配方）。"""
    expr = (f'xsprint: ; @echo "{MARK}GOLDEN_RTL{MARK}$(GOLDEN_RTL)"; '
            f'echo "{MARK}REF{MARK}$(GOLDEN_RTL)/{target}.sv '
            f'$(addprefix $(GOLDEN_RTL)/,$(FM_REF_DEPS_{target}))"; '
            f'echo "{MARK}IMPL{MARK}$(abspath $(RTL_SRCS) $(RTL_GOLDEN_DEPS))"; '
            f'echo "{MARK}MODE{MARK}$(FM_MODE)"; '
            f'echo "{MARK}VARIANTS{MARK}$(FM_VARIANTS)"; '
            f'echo "{MARK}IFONLY{MARK}$(FM_INTERFACE_ONLY)"')
    p = subprocess.run(['make', '--eval=' + expr, 'xsprint'], cwd=utdir,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       universal_newlines=True)
    out = {}
    for ln in p.stdout.splitlines():
        if ln.startswith(MARK):
            k, _, v = ln[len(MARK):].partition(MARK)
            out[k] = v.split()
    if 'REF' not in out:
        raise SystemExit(f'make 展开失败 {utdir}:\n{p.stdout}\n{p.stderr}')
    return out


def vendor_registry():
    reg = {}
    for ln in (REPO / 'verif' / 'vendor_boundary.tsv').read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.split('\t')
        reg[f[0]] = {'kind': f[1] if len(f) > 1 else '', 'rationale': f[2] if len(f) > 2 else ''}
    return reg


def build(utdir, target):
    v = make_vars(utdir, target)
    ref_files = [f for f in v['REF'] if os.path.exists(f)]
    ref_missing = [f for f in v['REF'] if not os.path.exists(f)]
    impl_files = [f for f in v['IMPL'] if os.path.exists(f)]
    impl_missing = [f for f in v['IMPL'] if not os.path.exists(f)]

    err = []
    try:
        ru, rdup = sv_elab.load_universe(ref_files)
        rb, rw = sv_elab.enumerate_blackboxes(target, ru, 'r')
    except sv_elab.ElabError as e:
        ru, rdup, rb, rw = {}, [], [], []
        err.append(f'ref:{e}')
    try:
        iu, idup = sv_elab.load_universe(impl_files)
        ib, iw = sv_elab.enumerate_blackboxes(target, iu, 'i')
    except sv_elab.ElabError as e:
        iu, idup, ib, iw = {}, [], [], []
        err.append(f'impl:{e}')
    return {
        'target': target, 'utdir': utdir, 'mode': v.get('MODE', ['?'])[0],
        'ref_files': ref_files, 'impl_files': impl_files,
        'ref_missing': ref_missing, 'impl_missing': impl_missing,
        'ref_dup': rdup, 'impl_dup': idup,
        'objects': sorted(rb) + sorted(ib),
        'warnings': ['ref:' + w for w in rw] + ['impl:' + w for w in iw],
        'errors': err,
    }


def to_allow(res, classify):
    reg = vendor_registry()
    objs, unknown = [], []
    for side, design, path in res['objects']:
        if design in reg:
            cls, child = 'vendor_macro', None
        elif design in classify:
            cls, child = classify[design]
        else:
            unknown.append(design)
            cls, child = None, None
        e = {'side': side, 'design': design, 'path': path, 'attrs': 'u',
             'class': cls}
        if child:
            e['child_target'] = child
        objs.append(e)
    return objs, sorted(set(unknown))


if __name__ == '__main__':
    utdir, target = sys.argv[1], sys.argv[2]
    r = build(utdir, target)
    print(json.dumps(r, ensure_ascii=False, indent=1))

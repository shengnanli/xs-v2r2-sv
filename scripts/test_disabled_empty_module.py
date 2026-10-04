#!/usr/bin/env python3
"""test_disabled_empty_module.py —— fm_verdict 的 disabled_empty_module 类别正/负测（codex 0206 D2）。

只批准 KunminghuV2 配置下 DCache 的 stu_0/stu_1 两个 StorePipe 空壳。每条负测都必须判红：
  N1 golden sha256 不符            N2 多一个实例（stu_2）        N3 少一个实例（两侧都缺 stu_1）
  N4 impl 模块有寄存器/always      N5 impl 模块有 output 驱动    N6 impl 模块例化了子模块
  N7 别的 design 名（LoadPipe）    N8 StorePipe 是 u（unresolved）而非 FM 自动 empty
  N9 混进别的 unresolved 黑盒冒充本类别                         N10 父级不是 DCache
  N11 父级 unmatched≠0             N12 父级 native 不是 SUCCEEDED  N13 父级有 dont_verify
  N14 golden 侧有 output 口（直接测模块正文判据，sha 闸之外的第二道）
正样本 P0：真实 golden 文件 + 本仓 HEAD 的 rtl/memblock/StorePipe.sv 必须通过。
用法: python3 scripts/test_disabled_empty_module.py
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import fm_verdict as F  # noqa: E402

REPO = os.path.dirname(HERE)
G1 = os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical'
GOLD = open(os.path.join(G1, 'golden-rtl', 'StorePipe.sv'), 'rb').read().decode()
IMPL = subprocess.check_output(['git', '-C', REPO, 'show', 'HEAD:rtl/memblock/StorePipe.sv']).decode()


def ents(top='DCache', design='StorePipe', insts=('stu_0', 'stu_1'), attr='e'):
    keys = {(sd, design, f'{sd}:/WORK/{top}/{i}') for sd in ('r', 'i') for i in insts}
    return keys, {k: attr for k in keys}


def decl_of(keys, cls='disabled_empty_module'):
    return {'objects': [{'side': s, 'design': d, 'path': p, 'attrs': 'e', 'class': cls}
                        for s, d, p in sorted(keys)]}


def clean_q():
    return {'native': 'SUCCEEDED', 'failing': 0, 'unmatched': 0, 'unverified': None,
            'aborted': None, 'blackbox_out': 0, 'dont_verify': False, 'elab147': False}


def run(keys, attrs, top='DCache', q=None, gold=GOLD, impl=IMPL, design='StorePipe'):
    return F._assembly_bbox_check(set(keys), attrs, decl_of(keys), top=top,
                                  q=clean_q() if q is None else q,
                                  _inject={'golden_text': {design: gold},
                                           'impl_text': {design: impl}})


def main():
    cases = []
    k, a = ents()
    cases.append(('P0 真实 StorePipe×2/侧', run(k, a), True))
    cases.append(('N1 golden sha 不符', run(k, a, gold=GOLD + '\n'), False))
    k2, a2 = ents(insts=('stu_0', 'stu_1', 'stu_2'))
    cases.append(('N2 多一个实例', run(k2, a2), False))
    k3, a3 = ents(insts=('stu_0',))
    cases.append(('N3 少一个实例', run(k3, a3), False))
    reg_impl = IMPL.replace('  wire io_lsu_req_valid_probe = io_lsu_req_valid;',
                            '  logic r;\n  always_ff @(posedge io_lsu_req_valid) r <= ~r;')
    assert reg_impl != IMPL
    cases.append(('N4 impl 有寄存器', run(k, a, impl=reg_impl), False))
    out_impl = IMPL.replace('  input io_lsu_req_valid\n);',
                            '  input io_lsu_req_valid,\n  output io_x\n);\n  assign io_x = io_lsu_req_valid;')
    assert out_impl != IMPL
    cases.append(('N5 impl 有输出驱动', run(k, a, impl=out_impl), False))
    inst_impl = IMPL.replace('  wire io_lsu_req_valid_probe = io_lsu_req_valid;',
                             '  Foo u_foo (.a(io_lsu_req_valid));')
    cases.append(('N6 impl 例化子模块', run(k, a, impl=inst_impl), False))
    k7, a7 = ents(design='LoadPipe')
    cases.append(('N7 别的 design 名', run(k7, a7, design='LoadPipe'), False))
    k8, a8 = ents(attr='u')
    cases.append(('N8 unresolved 非 empty', run(k8, a8), False))
    k9, a9 = ents()
    extra = {('r', 'Foo', 'r:/WORK/DCache/foo'), ('i', 'Foo', 'i:/WORK/DCache/foo')}
    k9 = k9 | extra
    a9.update({x: 'u' for x in extra})
    cases.append(('N9 混进别的 unresolved 黑盒', F._assembly_bbox_check(
        set(k9), a9, decl_of(k9), top='DCache', q=clean_q(),
        _inject={'golden_text': {'StorePipe': GOLD, 'Foo': GOLD},
                 'impl_text': {'StorePipe': IMPL, 'Foo': IMPL}}), False))
    k10, a10 = ents(top='MainPipe')
    cases.append(('N10 父级不是 DCache', run(k10, a10, top='MainPipe'), False))
    q = clean_q(); q['unmatched'] = 1
    cases.append(('N11 父级 unmatched=1', run(k, a, q=q), False))
    q = clean_q(); q['native'] = 'FAILED'
    cases.append(('N12 父级 native FAILED', run(k, a, q=q), False))
    q = clean_q(); q['dont_verify'] = True
    cases.append(('N13 父级有 dont_verify', run(k, a, q=q), False))
    gout = F._empty_module_problem(F._module_text(
        GOLD.replace('  input io_lsu_req_valid\n);', '  input io_lsu_req_valid,\n  output o\n);'),
        'StorePipe'))
    cases.append(('N14 golden 正文有 output', gout or True, False))
    fails = []
    for name, r, want in cases:
        ok = (r is True) == want
        print(f'  {name:28s} {"ok" if ok else "★FAIL★"}  {r}')
        if not ok:
            fails.append(name)
    if fails:
        print(f'test_disabled_empty_module: ★{len(fails)} 条不过★ {fails}')
        return 1
    print(f'test_disabled_empty_module: 全过（1 正样本 + {len(cases) - 1} 负测）')
    return 0


if __name__ == '__main__':
    sys.exit(main())

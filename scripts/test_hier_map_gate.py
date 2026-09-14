#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_hier_map_gate.py —— 层次重绑那套东西的负测（快，不扫 golden）。

「闸跑了且退出 0」不等于「它会响」。层次重绑表的闸（hier_map.py --check）要扫
1.8 GB golden，不适合在负测里反复跑；但它依赖的几件判定逻辑都是纯函数，可以
逐条给一个病、要求它当场红：

  1. 例化解析器（hier_reach）：参数化例化 `X #(...) u (`、generate 块路径
     `g_x[i].u`、注释里的假例化、字符串里的假例化 —— 各来一条。
  2. firtool 编号后缀 → generate 下标（suffix_index）：族里缺号就必须**不给答案**
     （宁可 GEN_SITE_UNINDEXED，也不能猜一个下标出来让探针默默探错地方）。
  3. 下标算术（subst_index）：`{i+2}` 要对；不认识的表达式要炸而不是静默。
  4. 声明表语法校验（validate）：INSTANCE 写 `-`、INLINE 写了模块名、
     内联没写信号、evidence 空 —— 四种病各要红。
  5. 路径翻译（hier_xlate.translate）：OK / REMAP / INLINED / 信号末段四种判定。
"""
from __future__ import print_function

import pathlib
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import hier_reach as HR                                             # noqa: E402
import hier_map as HM                                               # noqa: E402
import hier_xlate as HX                                             # noqa: E402

fails = []


def ck(cond, what):
    if not cond:
        fails.append(what)


def expect_die(fn, what):
    try:
        fn()
    except SystemExit:
        return
    except Exception as e:                                          # noqa: BLE001
        fails.append('%s: 抛了 %r 而不是 SystemExit' % (what, e))
        return
    fails.append('%s: 本该报错却静静通过了' % what)


# ---------------------------------------------------------------- 1. 解析器
SRC = '''
module Top;
  Child plain_inst (
    .a(a)
  );
  Param #(.W(4), .D(2)) param_inst (
    .a(a)
  );
  generate
    for (genvar i = 0; i < 2; i++) begin : g_loop
      Leaf u_leaf (
        .a(a)
      );
    end
  endgenerate
  if (1) begin : g_if
    Leaf u_in_if (.a(a));
  end
  // Ghost fake_comment (
  /* Ghost fake_block ( */
  wire [7:0] s = "Ghost fake_string (";
endmodule
'''


def test_parser():
    with tempfile.TemporaryDirectory() as d:
        f = pathlib.Path(d) / 'Top.sv'
        f.write_text(SRC)
        got = dict((n, ks) for n, ks in HR.scan_impl(f))
        ks = got.get('Top', [])
        m = {i: (t, p) for t, i, p in ks}
        ck('plain_inst' in m and m['plain_inst'][0] == 'Child', '普通例化没认出来')
        ck('param_inst' in m and m['param_inst'][0] == 'Param', '参数化例化没认出来')
        ck(m.get('u_leaf', ('', ''))[1] == 'g_loop[i].u_leaf',
           'generate-for 的层次路径不对: %r' % (m.get('u_leaf'),))
        ck(m.get('u_in_if', ('', ''))[1] == 'g_if.u_in_if',
           'generate-if 的层次路径不对: %r' % (m.get('u_in_if'),))
        ck(not any(t == 'Ghost' for t, _i, _p in ks),
           '注释/字符串里的假例化被当真了: %r' % ks)


# ------------------------------------------------- 2/3. 下标推导与算术
def test_index():
    fam = ['gw', 'gw_1', 'gw_2']
    ck(HM.suffix_index('gw', fam) == 0, '无后缀应当是 0')
    ck(HM.suffix_index('gw_2', fam) == 2, '后缀 2 应当是 2')
    ck(HM.suffix_index('gw_2', ['gw', 'gw_2']) is None,
       '族里缺号（缺 gw_1）时必须不给答案')
    ck(HM.suffix_index('gw', ['gw']) is None, '单元素族不足以确立编号约定')
    ck(HM.subst_index('g[{i}].u', 3) == 'g[3].u', '{i} 代入错了')
    ck(HM.subst_index('g[{i+4}].u', 3) == 'g[7].u', '{i+4} 算错了')
    expect_die(lambda: HM.subst_index('g[{j*2}].u', 1), '不认识的下标表达式')


# ------------------------------------------------------- 4. 声明表语法
def _decl(**kw):
    d = dict(owner='O', golden_child='C', golden_inst_re='c', impl_path='u_core',
             impl_module='xs_C', kind='INSTANCE', signals='', evidence='e')
    d.update(kw)
    return [d]


def test_validate():
    HM.validate(_decl())                                   # 合法的不许报
    HM.validate(_decl(kind='INLINE', impl_module='-', signals='q'))
    expect_die(lambda: HM.validate(_decl(impl_module='-')), 'INSTANCE 行 impl_module=-')
    expect_die(lambda: HM.validate(_decl(kind='INLINE', signals='q')), 'INLINE 行写了模块名')
    expect_die(lambda: HM.validate(_decl(kind='INLINE', impl_module='-')), 'INLINE 行没写信号')
    expect_die(lambda: HM.validate(_decl(evidence='')), 'evidence 为空')
    expect_die(lambda: HM.validate(_decl(kind='MAGIC')), '不认识的 kind')


# --------------------------------------------------------- 5. 路径翻译
class _G(object):
    slot = {('XSTop', 'a'): 'P', ('P', 'kid'): 'K', ('XSTop', 'z'): 'Q',
            ('XSTop', 'w'): 'W'}   # W 不在 map 里 = 本轮没被重写


def test_xlate():
    rows = {
        ('P', 'kid'): dict(owner='P', golden_path='kid', golden_child='K',
                           **{'class': 'GEN_SITE'}, impl_path='u_core.g[2].u_k',
                           impl_module='xs_K', impl_signals='', resolve='x', evidence=''),
        ('Q', 'gone'): dict(owner='Q', golden_path='gone', golden_child='G',
                            **{'class': 'INLINE'}, impl_path='u_core',
                            impl_module='-', impl_signals='sig_a', resolve='x', evidence=''),
    }
    v, p, _w, _s = HX.translate(['w'], _G, rows)
    ck((v, p) == ('OK', 'w'), '未重写路径应当原样 OK, 实得 %r' % ((v, p),))
    v, p, _w, _s = HX.translate(['a', 'kid'], _G, rows)
    ck((v, p) == ('REMAP', 'a.u_core.g[2].u_k'), 'REMAP 错了: %r' % ((v, p),))
    v, p, _w, sig = HX.translate(['z', 'gone'], _G, rows)
    ck((v, sig) == ('INLINED', 'sig_a'), 'INLINED 错了: %r' % ((v, sig),))
    v, p, mod, _s = HX.translate(['a', 'sig_name'], _G, rows)
    ck(v == 'SIGNAL_IN_REWRITTEN' and mod == 'P',
       '重写模块里的信号末段判错: %r' % ((v, mod),))
    v, p, mod, _s = HX.translate(['w', 'sig_name'], _G, rows)
    ck(v == 'SIGNAL_TAIL_OK', '未重写模块里的信号末段判错: %r' % (v,))


def main():
    for f in (test_parser, test_index, test_validate, test_xlate):
        f()
    if fails:
        print('test_hier_map_gate: %d 条不过：' % len(fails))
        for x in fails:
            print('  - ' + x)
        return 1
    print('test_hier_map_gate: 全部负测按预期红/绿')
    return 0


if __name__ == '__main__':
    sys.exit(main())

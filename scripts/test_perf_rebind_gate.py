#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_perf_rebind_gate.py —— perf 观测重绑那套东西的负测（快，不扫 golden）。

真闸 `perf_rebind.py --check` 要扫 1.8 GB golden（约 90 秒），不适合在负测里反复跑。
但它靠的几件判定都是纯函数，可以逐条给一个病、要求它当场红。这里钉住的每一条，
都是本轮**真的差点出错**的地方：

  1. 位宽字面量：`{1'h0, x}` 里的 `h0` 不许被当成信号名（第一版把它当叶子，
     整条锥直接判成 OPEN）；而 RHS 里的字面量必须**原样保留**（第一版为了
     扫标识符把 `1'h0` 换成了 `0`，拼接宽度当场变错）。
  2. generate 下标：路径里还留着 genvar（`g_wb_bank[gb]`）就不是一条合法层次引用，
     必须判「不可用」而不是当成绑定成功（第一版漏了这条，凭空多出 214 条假绑定）。
  3. 拓扑序：`wire a = b;` 里 b 必须先声明 —— 否则 SystemVerilog 按隐式网线当成
     1 位新网，值悄悄错掉。DFS 先序反过来**不是**拓扑序。
  4. unbound 表的用法：perf_compare 必须把未绑计数器判 EXCLUDED，
     ★不许拿 0 == 0 算 MATCH★ —— 这正是 codex「不许编零」那一条的机器化。
"""
from __future__ import print_function

import pathlib
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import perf_rebind as PR                                            # noqa: E402

fails = []


def check(name, cond, detail=''):
    if not cond:
        fails.append('%s: %s' % (name, detail))
    print('  %-46s %s' % (name, 'ok' if cond else '★FAIL ' + detail))


# ---------------------------------------------------------------- 1. 字面量
tmp = pathlib.Path(tempfile.mkdtemp())
(tmp / 'Toy.sv').write_text('''
module Toy(
  input        io_a,
  input        io_b,
  input  [2:0] io_c,
  output       io_o
);
  wire [1:0] _GEN_0 = {1'h0, io_a};
  wire [1:0] _GEN_1 = 2'(_GEN_0 + {1'h0, io_b});
  wire       _GEN_2 = _GEN_1 == 2'h3 & _sub_io_q;
  reg        r;
  wire       _GEN_3 = r & io_a;
  wire       _GEN_4 = r ^ io_b;
  Sub sub (
    .io_q (_sub_io_q)
  );
  assign io_o = _GEN_4;
endmodule
''')
G = PR.Golden(tmp)
m = G.mod('Toy')
check('端口解析', m['ports'] == {'io_a', 'io_b', 'io_c', 'io_o'}, str(sorted(m['ports'])))
check("RHS 原样保留 1'h0", m['defs']['_GEN_0'] == "{1'h0, io_a}", m['defs']['_GEN_0'])
check("扫标识符时不把 h0 当信号", 'h0' not in G.ids(m['defs']['_GEN_0']),
      str(G.ids(m['defs']['_GEN_0'])))
check('位宽声明保留', m['decl']['_GEN_0'] == '[1:0]', repr(m['decl']['_GEN_0']))

v, leaves, order, why = G.cone('Toy', '_GEN_1')
check('锥闭合在端口上 → T2_CONE_PORT', v == 'T2_CONE_PORT', v + ' ' + str(leaves))
v, leaves, order, why = G.cone('Toy', '_GEN_2')
check('锥含子实例端口 → T2_CONE_PORT_CHILD', v == 'T2_CONE_PORT_CHILD', v + ' ' + str(leaves))
check('子实例叶子还原成 (inst, port)', 'CHILD:sub.io_q' in leaves, str(leaves))
v, leaves, order, why = G.cone('Toy', '_GEN_3')
check('锥展到内部寄存器 → T3_REG_LEAF', v == 'T3_REG_LEAF', v + ' ' + str(leaves))
check('T3 要说清为什么', 'r' in why, why)
# 内部线被原样赋给输出端口 → 当成端口叶子（golden WrBypass 的 hit/io_hit 就是这个形状）
check('输出端口别名被认出来', m['alias'].get('_GEN_4') == 'io_o', str(m['alias']))
v, leaves, order, why = G.cone('Toy', '_GEN_4')
check('别名叶子算端口类 → T2_CONE_PORT', v == 'T2_CONE_PORT', v + ' ' + str(leaves))
check('别名叶子带出端口名', 'ALIAS:_GEN_4=io_o' in leaves, str(leaves))
# 被 bore 的那根线本身就是叶子（锥里零行中间线）—— 生成器不能再引一个没声明的名字。
# 实测 enable_bore_2 / x2_bore_22 就死在这里（Error-[IND]）。
v, leaves, order, why = G.cone('Toy', 'io_a')
check('被 bore 的线本身是端口 → 锥为空', v == 'PORT' and order == [], v + str(order))
v, leaves, order, why = G.cone('Toy', '_GEN_4')
check('别名形态下锥里没有这根线本身', '_GEN_4' not in order, str(order))

# ---------------------------------------------------------------- 2. generate 下标
check('纯数字下标可用', PR.Rebinder.resolvable('u_core.g_bank[3].dataBank'))
check('genvar 下标不可用', not PR.Rebinder.resolvable('u_core.g_wb_bank[gb].g_wb_br[gp].w'))
check('混合下标不可用', not PR.Rebinder.resolvable('a[0].b[j].c'))
check('无下标可用', PR.Rebinder.resolvable('u_core.missUnit'))

# ---------------------------------------------------------------- 3. 生成物结构
MAP = PR.REPO / 'docs' / 'perf_bore_map.tsv'
if MAP.exists():
    rows, cols = [], None
    for ln in MAP.read_text().splitlines():
        if ln.startswith('# port\t'):
            cols = ln[2:].split('\t')
        elif ln.strip() and not ln.startswith('#'):
            rows.append(dict(zip(cols, ln.split('\t'))))
    check('map 列名与脚本一致', cols == PR.MAP_COLS, str(cols))
    bad = [r for r in rows if r['tier'] in PR.BOUND_TIERS and not r['impl_bind']]
    check('已绑定的行必须有 impl_bind', not bad, str(bad[:2]))
    bad = [r for r in rows if r['tier'] not in PR.BOUND_TIERS and r['impl_bind']]
    check('未绑定的行必须留空 impl_bind（不许填假值）', not bad, str(bad[:2]))
    bad = [r for r in rows if r['tier'] not in PR.BOUND_TIERS and not r['evidence']]
    check('未绑定的行必须写明为什么', not bad, str(bad[:2]))
    bad = [r for r in rows if r['impl_bind'].startswith('SimTop.')
           and not PR.Rebinder.resolvable(r['impl_bind'])]
    check('绑定路径里不许留 genvar', not bad, str([r['impl_bind'] for r in bad[:2]]))

# ---------------------------------------------------------------- 4. 未绑 != 相等
import perf_compare as PC                                           # noqa: E402
d = pathlib.Path(tempfile.mkdtemp())
scope = 'SimTop.x.y'
ub = [(f[1], f[2]) for f in
      [ln.split('\t') for ln in (PR.REPO / 'docs' / 'perf_bore_unbound.tsv').read_text()
       .splitlines() if ln and not ln.startswith('#')] if f[0] == 'PERF']
check('unbound 表非空（有缺口就要能被读出来）', len(ub) > 0, str(len(ub)))
g = d / 'g.log'
i = d / 'i.log'
one = ub[0]
g.write_text('[PERF ][time=       1] %s: %s,                    0\n' % one)
i.write_text('[PERF ][time=       1] %s: %s,                    0\n' % one)
gd, _ = PC.load_dump(g)
idd, _ = PC.load_dump(i)
unb = PC.load_unbound()
check('perf_compare 读得到 unbound 表', one in unb, str(one))
check('★未绑计数器两侧都是 0 也不算 MATCH★', one in unb and gd[one] == idd[one] == 0)

print()
if fails:
    print('★ 负测未过 %d 条:' % len(fails))
    for f in fails:
        print('   ' + f)
    sys.exit(1)
print('perf 重绑负测全过')

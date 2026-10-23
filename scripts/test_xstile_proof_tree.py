#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""xstile_proof_tree.py 的正反测（合成环境，秒级）。

判据本身（validate_certificate_current / validate_child_certificate / validate_impl_golden_certified）
不在这里测——树脚本只委托它们；这里测的是**建树与阻塞判定的接线**：
  正例：全部有效 → 0 阻塞、0 unbound；共享子证明只展开一次。
  反例：green_child 无效 / impl_golden 子证书本身不 current-valid（cv-recur 要堵的那个洞，树要独立看见）/
        impl_golden 不是 FM target / 白盒件交付源与父证明 impl 不一致 / 交付件无证明绑定 /
        disabled_empty_module 交付件带 output / 未知黑盒类别。

真仓冒烟（约 3 分钟）：XTR_REAL=1 python3 scripts/test_xstile_proof_tree.py
"""
import copy
import os
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import xstile_proof_tree as T  # noqa: E402


def cert(target, impl=(), golden=(), allow=None, mode='assembly'):
    """impl: [(path, kind)]；golden: [basename]"""
    return {'target': target, 'variant': target, 'proof_mode': mode, 'result_sha256': target,
            'input_closure': {
                'impl': [{'path': p, 'kind': k, 'sha256': 'S_' + os.path.basename(p)} for p, k in impl],
                'golden': [{'path': 'golden-rtl/' + g, 'kind': 'golden', 'sha256': 'S_' + g} for g in golden]},
            '_allow': allow or {'objects': []}}


def gc(design, sha='SHA'):
    return [{'class': 'green_child', 'design': design, 'child_target': design, 'certificate_sha256': sha,
             'side': s, 'path': '%s:/WORK/x/%s' % (s, design), 'attrs': 'i'} for s in ('r', 'i')]


def bbo(design, cls):
    return [{'class': cls, 'design': design, 'side': s, 'path': '%s:/WORK/x/%s' % (s, design), 'attrs': 'u'}
            for s in ('r', 'i')]


class Fake(object):
    """certs: {t: doc}；bad_cv: {t: reason}；bad_child: {t: reason}；bad_edge: {(parent, mod): reason}
    wb: {parent: [(m, resolved)]}；reach: {t: {m: path}}；srcmap: {m: (kind, src, sha)}"""

    def __init__(self, certs, targets=None, mc=(), wb=None, reach=None, srcmap=None,
                 bad_cv=None, bad_child=None, bad_edge=None, outputs=()):
        self.certs = certs
        self.targets = set(targets if targets is not None else certs)
        self.mc = set(mc)
        self.wb = wb or {}
        self.reach = reach or {}
        self.srcmap = srcmap
        self.bad_cv, self.bad_child, self.bad_edge = bad_cv or {}, bad_child or {}, bad_edge or {}
        self.outputs = set(outputs)
        self.calls = []

    def cert(self, t):
        if t in self.certs:
            return self.certs[t], 'blob', None
        return None, None, 'certificate_not_in_commit:%s' % t

    def allow(self, doc):
        return doc['_allow'], None

    def is_target(self, t):
        return t in self.targets

    def is_mc(self, m):
        return m in self.mc

    def mc_chain(self, m):
        return [m + '_ext'] if m in self.mc else []

    def incore(self, t):
        return True

    def whitebox(self, doc, cut):
        return [x for x in self.wb.get(doc['target'], []) if x[0] not in cut]

    def cv_cert(self, t, doc):
        self.calls.append(('cv', t))
        return self.bad_cv.get(t, True)

    def cv_child(self, t, sha):
        self.calls.append(('child', t))
        if t not in self.certs:
            return 'green_child_certificate_not_in_commit:%s' % t
        return self.bad_child.get(t, self.bad_cv.get(t, True))

    def impl_golden_edge(self, parent, doc, e):
        mod = os.path.basename(e['path'])[:-3]
        return self.bad_edge.get((parent, mod), True)

    def delivered(self, t):
        if self.srcmap is None:
            return 'n/a'
        return self.srcmap.get(t)

    def delivered_all(self):
        return dict(self.srcmap or {})

    def has_outputs(self, path, module):
        return module in self.outputs

    def impl_reach(self, doc, cut, through_golden=False):
        return self.reach.get(doc['target'], {doc['target']: 'rtl/%s.sv' % doc['target']})


def good_world():
    """XSTile ─bb→ Core（共享）, L2 ─bb→ Core（同一子证明，第二次不再展开）
       Core ─impl_golden→ Leaf（FM target 有证书）, ram_x（MC）；Core 白盒 Sub；L2 黑盒 sram（vendor_macro）"""
    certs = {
        'XSTile': cert('XSTile', impl=[('rtl/XSTile.sv', 'repo')], golden=['XSTile.sv'],
                       allow={'objects': gc('Core') + gc('L2')}),
        'L2': cert('L2', impl=[('rtl/L2.sv', 'repo')], golden=['L2.sv'],
                   allow={'objects': gc('Core') + bbo('sram', 'vendor_macro')}),
        'Core': cert('Core', impl=[('rtl/Core.sv', 'repo'), ('rtl/Sub.sv', 'repo'),
                                   ('golden-rtl/Leaf.sv', 'golden'), ('golden-rtl/ram_x.sv', 'golden')],
                     golden=['Core.sv', 'Sub.sv', 'Leaf.sv', 'ram_x.sv'], mode='signoff-strict'),
        'Leaf': cert('Leaf', impl=[('rtl/Leaf.sv', 'repo')], golden=['Leaf.sv'], mode='signoff-strict'),
    }
    srcmap = {'XSTile': ('RTL', 'rtl/XSTile.sv', '-'), 'L2': ('RTL', 'rtl/L2.sv', '-'),
              'Core': ('RTL', 'rtl/Core.sv', '-'), 'Sub': ('RTL', 'rtl/Sub.sv', '-'),
              'Leaf': ('RTL', 'rtl/Leaf.sv', '-'), 'ram_x': ('MEMORY_MODEL', '$G1/ram_x.sv', 'S_ram_x.sv')}
    reach = {'Core': {'Core': 'rtl/Core.sv', 'Sub': 'rtl/Sub.sv', 'Leaf': 'golden-rtl/Leaf.sv',
                      'ram_x': 'golden-rtl/ram_x.sv'}}
    return dict(certs=certs, mc=['ram_x'], wb={'Core': [('Sub', True)]}, reach=reach, srcmap=srcmap)


def run(**kw):
    env = Fake(**kw)
    nodes = T.build_tree(env, 'XSTile')
    s, blockers = T.summarize(nodes)
    return env, nodes, blockers, T.build_tree.unbound


def rows(nodes, target):
    return [n for n in nodes if n.target == target]


class TestTree(unittest.TestCase):
    def test_good_world_closes(self):
        env, nodes, blockers, unbound = run(**good_world())
        self.assertEqual(blockers, [], [n.row() for n in blockers])
        self.assertEqual(unbound, [])
        self.assertEqual({n.edge for n in rows(nodes, 'Core')}, {'blackbox-child'})
        self.assertEqual(rows(nodes, 'Leaf')[0].coverage, 'DIRECT')
        self.assertEqual(rows(nodes, 'ram_x')[0].coverage, 'MC_MODEL')
        self.assertEqual(rows(nodes, 'ram_x_ext')[0].edge, 'mc-chain')
        self.assertEqual(rows(nodes, 'Sub')[0].coverage, 'WB_IN_PARENT')
        self.assertTrue(rows(nodes, 'Sub')[0].delivered.startswith('ok:'))
        self.assertEqual(rows(nodes, 'sram')[0].coverage, 'MC_MODEL(vendor_macro)')
        # Core 被 XSTile 与 L2 两处声明：两行，但只展开一次（Leaf 只出现一行）
        self.assertEqual(len(rows(nodes, 'Core')), 2)
        self.assertEqual(len(rows(nodes, 'Leaf')), 1)
        self.assertEqual(rows(nodes, 'Leaf')[0].delivered, 'parent_rtl_instantiates;ok:rtl/Leaf.sv')

    def test_green_child_invalid_blocks(self):
        w = good_world()
        env, nodes, blockers, _ = run(bad_child={'L2': 'green_child_closure_changed:L2:rtl/L2.sv'}, **w)
        self.assertEqual([(n.target, n.edge) for n in blockers], [('L2', 'blackbox-child')])
        # L2 失效后其下黑盒仍列出（看得见树），sram 不另算阻塞
        self.assertEqual(rows(nodes, 'sram')[0].blocking, 'no')

    def test_impl_golden_child_not_current_blocks_even_if_edge_ok(self):
        """cv-recur 要堵的洞：validate_impl_golden_certified 旧版只看格式/verdict/golden 字节就放行（edge=True），
        子证书本身却不 current-valid。树对子证书独立调用 validate_certificate_current，必须看见。"""
        env, nodes, blockers, _ = run(bad_cv={'Leaf': 'green_child_script_closure_changed:Leaf:scripts/fm_eq.tcl'},
                                      **good_world())
        self.assertEqual([(n.target, n.edge) for n in blockers], [('Leaf', 'impl_golden')])
        self.assertIn('script_closure_changed', blockers[0].cv)

    def test_impl_golden_edge_reason_reported(self):
        env, nodes, blockers, _ = run(bad_edge={('Core', 'Leaf'): 'green_child_impl_golden_bytes_mismatch:x'},
                                      **good_world())
        self.assertEqual(len(blockers), 1)
        self.assertTrue(blockers[0].cv.startswith('edge:green_child_impl_golden_bytes_mismatch'))

    def test_impl_golden_not_fm_target_blocks(self):
        w = good_world()
        env, nodes, blockers, _ = run(targets=set(w['certs']) - {'Leaf'}, **w)
        self.assertEqual([(n.target, n.cv) for n in blockers], [('Leaf', 'not_fm_target')])

    def test_mc_edge_invalid_blocks_with_chain(self):
        env, nodes, blockers, _ = run(bad_edge={('Core', 'ram_x'): 'green_child_impl_golden_mc_not_shared:Core:ram_x'},
                                      **good_world())
        self.assertEqual(sorted(n.target for n in blockers), ['ram_x', 'ram_x_ext'])

    def test_whitebox_delivered_mismatch_blocks(self):
        w = good_world()
        w['srcmap']['Sub'] = ('RTL', 'rtl/other/Sub.sv', '-')
        env, nodes, blockers, unbound = run(**w)
        self.assertEqual([n.target for n in blockers], ['Sub'])
        self.assertIn('src_mismatch', blockers[0].delivered)
        self.assertEqual([u[0] for u in unbound], ['Sub'])

    def test_whitebox_flattened_is_not_blocking(self):
        w = good_world()
        w['reach']['Core'] = {'Core': 'rtl/Core.sv', 'Leaf': 'golden-rtl/Leaf.sv', 'ram_x': 'golden-rtl/ram_x.sv'}
        del w['srcmap']['Sub']
        env, nodes, blockers, unbound = run(**w)
        self.assertEqual(blockers, [])
        self.assertEqual(rows(nodes, 'Sub')[0].delivered, 'flattened_in_parent_impl')

    def test_delivered_but_unproved_is_unbound(self):
        w = good_world()
        w['srcmap']['Ghost'] = ('RTL', 'rtl/Ghost.sv', '-')
        env, nodes, blockers, unbound = run(**w)
        self.assertEqual([u[0] for u in unbound], ['Ghost'])

    def test_unknown_blackbox_class_blocks(self):
        w = good_world()
        w['certs']['L2']['_allow']['objects'] += bbo('weird', 'mystery_class')
        env, nodes, blockers, _ = run(**w)
        self.assertEqual([n.target for n in blockers], ['weird'])

    def test_empty_module_with_outputs_blocks(self):
        w = good_world()
        w['certs']['L2']['_allow']['objects'] += bbo('Stub', 'disabled_empty_module')
        w['srcmap']['Stub'] = ('RTL', 'rtl/Stub.sv', '-')
        env, nodes, blockers, unbound = run(**w)
        self.assertEqual(blockers, [])
        self.assertEqual(unbound, [])                       # 输入空壳按声明接受
        env, nodes, blockers, unbound = run(outputs=['Stub'], **copy.deepcopy(w))
        self.assertEqual([n.target for n in blockers], ['Stub'])

    def test_root_missing(self):
        nodes = T.build_tree(Fake(certs={}), 'XSTile')
        self.assertEqual(nodes[0].blocking, 'yes')


@unittest.skipUnless(os.environ.get('XTR_REAL'), '真仓冒烟：XTR_REAL=1')
class TestReal(unittest.TestCase):
    def test_head(self):
        env = T.RealEnv('HEAD')
        nodes = T.build_tree(env, 'XSTile')
        self.assertEqual(nodes[0].target, 'XSTile')
        self.assertEqual(nodes[0].cert, 'yes')
        # 树覆盖 XSTile 例化闭包（docs/xstile_closure.tsv）的每个模块
        self.assertTrue(env.tile <= {n.target for n in nodes}, sorted(env.tile - {n.target for n in nodes})[:5])


if __name__ == '__main__':
    unittest.main(verbosity=2)

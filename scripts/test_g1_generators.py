#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_g1_generators.py —— 两个 universe 生成器的负测（codex 0151 D58）。

## 夹具刻意复刻真实事故

`SyncDataModuleTemplate__64entry` 家族在 G1 里整体后移一位。夹具把它缩到三个模块：

    G0: Top 例化 (a=Leaf_1, b=Leaf_2)     Leaf_1 两端口   Leaf_2 三端口
    G1: Top 例化 (a=Leaf_2, b=Leaf_3)     Leaf_2 两端口   Leaf_3 三端口
                                          ★G1 里还有一个同名的 Leaf_1，四端口，
                                            是**另一个**设计元素★

于是「同名」是一个**随时可取、但是错的**答案。正确答案只有槽位判据给得出：
共有槽位 `(Top,a)` 在 G1 里放的是 `Leaf_2`。

而且 **G0.Leaf_1 与 G1.Leaf_2 端口数相同（都是 2）** —— 这正是真实事故里
"任何比端口总数的闸都看不见"的那个性质，夹具必须保留它，
`test_00_fixture_really_reproduces_the_accident` 就是在守这条前提。

## 本工程踩过的「测试假通过」坑，这里逐条堵死

1. **前置门挡掉断言却报 PASS**：每条负测都先跑一次正控（干净夹具下该断言成立），
   一失一得成对出现，才证明夹具确实走到了被测判据。
2. **只看退出码 = 没牙齿**：断言落在**输出内容**上（映射的具体值 / 状态的具体值），
   退出码只作附加断言。
3. **反测崩溃的退出码与"抓到了"都是 1**：每次运行都断言 stderr 无 `Traceback`。
4. **判据被换成假货也能全绿**：`TestHarnessHasTeeth` 把解析器换成"同名优先"的
   假货，要求本套测试**必须挂**。

跑法：  python3 scripts/test_g1_generators.py
"""
from __future__ import print_function

import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import g1_slotmap as SM                                            # noqa: E402

G0_FILES = {
    'Top.sv': 'module Top(\n  input  clock,\n  input  reset\n);\n'
              '  Leaf_1 a (\n    .clock (clock)\n  );\n'
              '  Leaf_2 b (\n    .clock (clock)\n  );\nendmodule\n',
    # 刻意让模块体与 G1 的对应物不同：否则「字节全等重编号」判据也成立，
    # 标签会是 renumbered。夹具要的是「答案只能来自槽位判据」。
    'Leaf_1.sv': 'module Leaf_1(\n  input  clock,\n  output out\n);\n'
                 '  wire g0_only = clock;\nendmodule\n',
    'Leaf_2.sv': 'module Leaf_2(\n  input  clock,\n  input  reset,\n'
                 '  output out\n);\n  wire g0_only = clock;\nendmodule\n',
}

G1_FILES = {
    'Top.sv': 'module Top(\n  input  clock,\n  input  reset\n);\n'
              '  Leaf_2 a (\n    .clock (clock)\n  );\n'
              '  Leaf_3 b (\n    .clock (clock)\n  );\nendmodule\n',
    # ★同名陷阱★：G1 也有 Leaf_1，但它是另一个设计元素，且没被 Top 例化。
    'Leaf_1.sv': 'module Leaf_1(\n  input  clock,\n  input  reset,\n'
                 '  input  extra,\n  output out\n);\nendmodule\n',
    'Leaf_2.sv': 'module Leaf_2(\n  input  clock,\n  output out\n);\nendmodule\n',
    'Leaf_3.sv': 'module Leaf_3(\n  input  clock,\n  input  reset,\n'
                 '  output out\n);\nendmodule\n',
}

TARGETS = ['Top', 'Leaf_1', 'Leaf_2']

# ★receipt 只存在于老名 Leaf_1 名下★。正确映射 Leaf_1→Leaf_2 之后，
# Leaf_2 没有任何 receipt，状态必须是 NOT_STARTED。
RECEIPT_INDEX = (
    '# target\tverdict\tcanonical_id\timpl_commit\tprovisional\tsha\tpath\n'
    'Leaf_1\tSUCCEEDED\tTESTCID\tabcdef123456\tfalse\tdeadbeef\t'
    'evidence/abcdef123456/Leaf_1/receipt.json\n')


def build_fixture(root):
    root = pathlib.Path(root)
    for tag, files in (('g0', G0_FILES), ('g1', G1_FILES)):
        d = root / tag
        d.mkdir(parents=True)
        for n, t in files.items():
            (d / n).write_text(t)
    docs = root / 'repo' / 'docs'
    docs.mkdir(parents=True)
    (docs / 'g0g1_delta.tsv').write_text(
        '# old\tx\tclass\n' + ''.join('%s\t-\tREWRITE_S\n' % t for t in TARGETS))
    (docs / 'fastlane_ledger.tsv').write_text('# target\tstatus\tnote\n')
    (docs / 'receipt_index.tsv').write_text(RECEIPT_INDEX)
    (root / 'manifest.json').write_text(
        json.dumps({'entries': [{'target': t} for t in TARGETS]}))
    (root / 'cid.txt').write_text('TESTCID\n')
    # 另一个"主树"哨兵：任何脚本都不许写到它里面
    other = root / 'other_repo' / 'docs'
    other.mkdir(parents=True)
    (other / 'g1_universe.tsv').write_text('SENTINEL\n')
    return root


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix='g1gen-')
        self.root = build_fixture(self.tmp)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def run_gen(self, script, *extra):
        cmd = [sys.executable, str(HERE / script),
               '--repo', str(self.root / 'repo'),
               '--g0', str(self.root / 'g0'),
               '--g1', str(self.root / 'g1'),
               '--manifest', str(self.root / 'manifest.json')] + list(extra)
        if script == 'g1_universe.py':
            cmd += ['--canonical-id', str(self.root / 'cid.txt')]
        else:
            cmd += ['--root', 'Top', '--alt-root', 'Top']
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             universal_newlines=True)
        out, err = p.communicate()
        # 坑 3：崩溃的退出码和"抓到了"一样，必须区分开
        self.assertNotIn('Traceback', err, '生成器崩溃了:\n%s' % err)
        return p.returncode, out, err

    def rows(self, name='g1_universe.tsv'):
        p = self.root / 'repo' / 'docs' / name
        out = {}
        for ln in p.read_text().splitlines():
            if ln.startswith('#') or not ln.strip():
                continue
            f = ln.split('\t')
            out[f[0]] = f
        return out


# ====================================================================
# 0. 正控 + 夹具前提：夹具必须真的复刻了事故，否则后面全是空断言
# ====================================================================
class TestFixturePremises(Base):

    def test_00_fixture_really_reproduces_the_accident(self):
        """守住三条前提。任何一条不成立，本套负测就退化成空断言。"""
        g0 = SM.Baseline(str(self.root / 'g0'), 'G0')
        g1 = SM.Baseline(str(self.root / 'g1'), 'G1')
        # (1)「同名」是个随时可取的答案 —— G1 里确实有 Leaf_1
        self.assertIn('Leaf_1', g1.ports,
                      'G1 里没有同名 Leaf_1，夹具就构不成同名陷阱')
        # (2) 同名的那个是**另一个**设计元素
        self.assertNotEqual(g0.ports['Leaf_1'], g1.ports['Leaf_1'])
        # (3) ★正确映射下两侧端口数相同★——比端口总数的闸在这里恒等通过
        self.assertEqual(g0.ports['Leaf_1'], g1.ports['Leaf_2'],
                         '正确映射两侧端口数不同的话，就证明不了"端口数看不见它"')
        self.assertEqual(g0.ports['Leaf_2'], g1.ports['Leaf_3'])

    def test_01_clean_fixture_generates_and_conserves(self):
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        self.assertIn('守恒检查: PASS', out)
        rc, out, _ = self.run_gen('g1_configured_universe.py')
        self.assertEqual(rc, 0, out)


# ====================================================================
# D58-1 槽位/manual 优先于 same-name
# ====================================================================
class TestSlotBeatsSameName(Base):

    def test_slot_criterion_wins_over_available_same_name(self):
        """★D58 第一条★ G1 里有同名 Leaf_1 可选，但槽位判据说是 Leaf_2。"""
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        r = self.rows()
        self.assertEqual(r['Leaf_1'][1], 'Leaf_2',
                         '同名 Leaf_1 赢了槽位判据 —— 这正是串位事故的根因')
        self.assertEqual(r['Leaf_2'][1], 'Leaf_3')
        self.assertEqual(r['Leaf_1'][2], 'slot_map')

    def test_both_generators_agree_on_the_same_mapping(self):
        """两个生成器曾经各写各的，产出过同一个 G1 模块被两个 old 认领的台账。"""
        self.run_gen('g1_universe.py')
        self.run_gen('g1_configured_universe.py')
        a = dict((k, v[1]) for k, v in self.rows('g1_universe.tsv').items())
        b = dict((k, v[1]) for k, v in self.rows('g1_old_to_new_map.tsv').items())
        self.assertEqual(a, b, '两份台账对同一批 old→new 给出了不同答案')
        self.assertEqual(len(set(b.values())), len(b), '有 G1 模块被两个 old 认领')

    def test_manual_map_beats_same_name_when_slot_is_silent(self):
        """槽位沉默时，登记过的人工映射也必须赢过同名。"""
        # 去掉 Top 对 b 的例化 => Leaf_2 在 G0 侧没有槽位，槽位判据沉默
        p = self.root / 'g0' / 'Top.sv'
        p.write_text(p.read_text().replace(
            '  Leaf_2 b (\n    .clock (clock)\n  );\n', ''))
        docs = self.root / 'repo' / 'docs'
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(self.rows()['Leaf_2'][1], 'Leaf_2',
                         '前提：没有人工映射时应退回同名 —— 否则下面证不了"赢过同名"')
        (docs / 'g1_manual_map.tsv').write_text(
            '# old\tnew\treason\nLeaf_2\tLeaf_3\t人工核对过\n')
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        self.assertEqual(self.rows()['Leaf_2'][1], 'Leaf_3',
                         '人工映射没有赢过同名')


# ====================================================================
# D58-2 禁止 status.get(old) or status.get(new) 串 receipt
# ====================================================================
class TestNoReceiptCrossWiring(Base):

    def test_receipt_of_old_name_is_not_inherited_by_the_new_target(self):
        """★D58 第二条 / 事故本体★
        receipt 只存在于老名 Leaf_1 名下。映射改判到 Leaf_2 之后，
        Leaf_2 没有实现、没有 UT、没有 receipt —— 状态必须是 NOT_STARTED。"""
        rc, out, _ = self.run_gen('g1_universe.py', '--report-dropped')
        self.assertEqual(rc, 0, out)
        r = self.rows()
        self.assertEqual(r['Leaf_1'][1], 'Leaf_2')
        self.assertEqual(r['Leaf_1'][4], 'NOT_STARTED',
                         '★Leaf_2 继承了 Leaf_1 的 receipt —— 串位没修好★')
        self.assertNotIn('/Leaf_1/receipt.json', r['Leaf_1'][5],
                         'note 里还挂着别人的 receipt 路径')
        self.assertNotIn('evidence/', r['Leaf_1'][5],
                         'note 里还引用着 evidence 路径')
        self.assertIn('Leaf_1 → Leaf_2  老名状态 REVALIDATED_PASS 已丢弃', out,
                      '丢弃了老名状态却没有逐条报告 —— 静默丢弃同样不可接受')

    def test_receipt_under_the_new_name_is_still_honored(self):
        """对照组：receipt 记在 G1 名下时必须照常生效。
        没有这一条，上一条可能只是"所有 receipt 都被忽略了"。"""
        (self.root / 'repo' / 'docs' / 'receipt_index.tsv').write_text(
            RECEIPT_INDEX.replace('Leaf_1\tSUCCEEDED', 'Leaf_2\tSUCCEEDED')
                         .replace('/Leaf_1/', '/Leaf_2/'))
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        self.assertEqual(self.rows()['Leaf_1'][4], 'REVALIDATED_PASS',
                         'receipt 记在 G1 名下却没生效（假阴性）')


# ====================================================================
# D58-3 显式 --repo，禁止硬编码并写主树
# ====================================================================
class TestRepoIsExplicit(Base):

    def test_no_hardcoded_main_tree_path_in_sources(self):
        """源码里出现主树路径字面量 = 随时可能写错树。"""
        import ast
        for s in ('g1_universe.py', 'g1_configured_universe.py',
                  'g1_slotmap.py', 'boundary_ledger.py'):
            tree = ast.parse((HERE / s).read_text())
            # 按**节点身份**跳过模块 docstring（不能按文本比，
            # ast.get_docstring 会做 dedent，比出来永远不等）
            docnode = None
            if tree.body and isinstance(tree.body[0], ast.Expr):
                docnode = tree.body[0].value
            bad = []
            for node in ast.walk(tree):
                if node is docnode:
                    continue
                v = getattr(node, 's', None)
                if v is None and isinstance(getattr(node, 'value', None), str):
                    v = node.value
                if isinstance(v, str) and '/home/eda/xs-env/xs-v2-sv' in v:
                    bad.append(v[:120])
            # 模块 docstring 里复述「修之前是硬编码的」是允许的；
            # 可执行字面量里出现主树路径则一律不许。
            self.assertEqual(bad, [], '%s 的可执行字面量里仍有主树路径: %s' % (s, bad))

    def test_writes_only_under_the_given_repo(self):
        sentinel = self.root / 'other_repo' / 'docs' / 'g1_universe.tsv'
        before = sentinel.read_text()
        self.run_gen('g1_universe.py')
        self.run_gen('g1_configured_universe.py')
        self.assertEqual(sentinel.read_text(), before,
                         '★生成器写到了 --repo 之外的目录★')
        self.assertTrue((self.root / 'repo' / 'docs' / 'g1_universe.tsv').exists())

    def test_xssv_home_does_not_override_explicit_repo(self):
        """显式 --repo 必须压过环境变量，否则并行 worktree 会互相覆盖。"""
        env = dict(os.environ, XSSV_HOME=str(self.root / 'other_repo'))
        cmd = [sys.executable, str(HERE / 'g1_universe.py'),
               '--repo', str(self.root / 'repo'),
               '--g0', str(self.root / 'g0'), '--g1', str(self.root / 'g1'),
               '--manifest', str(self.root / 'manifest.json'),
               '--canonical-id', str(self.root / 'cid.txt')]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             universal_newlines=True, env=env)
        out, err = p.communicate()
        self.assertNotIn('Traceback', err, err)
        self.assertEqual(p.returncode, 0, out + err)
        self.assertEqual(
            (self.root / 'other_repo' / 'docs' / 'g1_universe.tsv').read_text(),
            'SENTINEL\n', '★XSSV_HOME 压过了显式 --repo★')


# ====================================================================
# D58-4 重跑结果必须与冻结 TSV 字节一致
# ====================================================================
class TestIdempotent(Base):

    def test_second_run_is_byte_identical(self):
        for s in ('g1_configured_universe.py', 'g1_universe.py'):
            self.run_gen(s)
        d = self.root / 'repo' / 'docs'
        snap = dict((p.name, p.read_bytes()) for p in sorted(d.glob('g1_*.tsv')))
        snap['ledger_normalized.tsv'] = (d / 'ledger_normalized.tsv').read_bytes()
        for s in ('g1_configured_universe.py', 'g1_universe.py'):
            self.run_gen(s)
        for n, b in snap.items():
            self.assertEqual((d / n).read_bytes(), b, '%s 第二次重跑结果变了' % n)

    def test_check_mode_catches_a_hand_edit(self):
        self.run_gen('g1_configured_universe.py')
        self.run_gen('g1_universe.py')
        rc, out, _ = self.run_gen('g1_universe.py', '--check')
        self.assertEqual(rc, 0, '正控：未改动时 --check 应通过\n%s' % out)
        self.assertIn('幂等 PASS', out)
        p = self.root / 'repo' / 'docs' / 'g1_universe.tsv'
        t = p.read_text()
        old = 'Leaf_1\tLeaf_2\tslot_map'
        self.assertIn(old, t, '夹具改写目标不存在，负测没打到点上')
        p.write_text(t.replace(old, 'Leaf_1\tLeaf_1\tsame_name'))
        rc, out, _ = self.run_gen('g1_universe.py', '--check')
        self.assertEqual(rc, 1, '手工改了台账，--check 却放行了\n%s' % out)
        self.assertIn('幂等 FAIL', out)


# ====================================================================
# 元测试：证明这套负测本身有牙齿
# ====================================================================
class TestHarnessHasTeeth(Base):

    def test_a_same_name_first_resolver_fails_this_suite(self):
        """把解析器换成修复前的"同名优先"，本套的核心断言必须挂。
        这条防的是「负测其实什么都没断言」。"""
        g0 = SM.Baseline(str(self.root / 'g0'), 'G0')
        g1 = SM.Baseline(str(self.root / 'g1'), 'G1')

        class SameNameFirst(SM.Resolver):
            def resolve(self, old):                      # 修复前的顺序
                if old in self.g1.ports:
                    return old, 'same_name', 'same_name'
                return SM.Resolver.resolve(self, old)

        bad = SameNameFirst(g0, g1, str(self.root / 'g0'), str(self.root / 'g1'))
        good = SM.Resolver(g0, g1, str(self.root / 'g0'), str(self.root / 'g1'))
        self.assertEqual(good.resolve('Leaf_1')[0], 'Leaf_2')
        self.assertEqual(bad.resolve('Leaf_1')[0], 'Leaf_1',
                         '假货没有复现"同名优先"，这条元测试就没意义')
        with self.assertRaises(AssertionError):
            self.assertEqual(bad.resolve('Leaf_1')[0], 'Leaf_2')

    def test_port_count_gate_would_not_have_caught_it(self):
        """★为什么必须用指纹而不是端口总数★
        正确映射 Leaf_1→Leaf_2 与错误映射 Leaf_1→Leaf_1 里，
        前者端口数相等、后者不等 —— 但真实事故（_4→_5）两种都相等。
        这里直接验证：光看端口数**给不出**唯一答案。"""
        g0 = SM.Baseline(str(self.root / 'g0'), 'G0')
        g1 = SM.Baseline(str(self.root / 'g1'), 'G1')
        n = g0.ports['Leaf_1']
        same_count = sorted(k for k, v in g1.ports.items() if v == n)
        self.assertGreater(len(same_count), 0)
        # 端口数只能给候选集；指纹才能定身份
        self.assertNotEqual(g0.fp_hash('Leaf_1'), g1.fp_hash('Leaf_1'),
                            '同名的两个应当指纹不同')
        self.assertEqual(g0.fp_hash('Leaf_1'), g1.fp_hash('Leaf_2'),
                         '正确映射两侧指纹应当相同')


if __name__ == '__main__':
    unittest.main(verbosity=2)

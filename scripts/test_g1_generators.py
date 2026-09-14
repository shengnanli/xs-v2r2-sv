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
import proof_certificate as PC                                     # noqa: E402

#: 夹具 POLICY。freeze_commit 由各测试自己填 —— 为 None 时任何证书都不得放行。
FIXTURE_FREEZE = 'a' * 40


def policy_doc(freeze_commit=FIXTURE_FREEZE):
    return {
        'schema': PC.POLICY_SCHEMA,
        'freeze_commit': freeze_commit,
        'qualifying_verdicts': ['SUCCEEDED', 'PASS_DEAD_REF'],
        'tool': {'name': 'fm_shell', 'version': 'V-2023.12-SP3', 'build': '8868332'},
        'pinned_entry_appvars': {'hdlin_unresolved_modules': 'black_box'},
        'script_closure_files': ['scripts/fm_eq.tcl'],
        'g1_canonical_id': 'G1-testcid',
    }


def make_certificate(target, impl_commit=FIXTURE_FREEZE, verdict='SUCCEEDED'):
    """造一份**能通过 proof_certificate.validate_document 的**证书。

    正控用。没有它，"证书让它变绿"这一条就只能靠"没变绿"来证，
    而"全都没变绿"同样能让负测通过 —— 那就是典型的假通过。
    """
    h = lambda c: c * 64                                          # noqa: E731
    golden = [{'path': 'G/%s.sv' % target, 'kind': 'golden', 'sha256': h('1')}]
    impl = [{'path': 'rtl/%s.sv' % target, 'kind': 'repo', 'sha256': h('2')}]
    script = [{'path': 'scripts/fm_eq.tcl', 'kind': 'repo', 'sha256': h('3')}]
    cfg = {'fm_mode': 'signoff-strict', 'allowlist': None}
    native = {'native_verdict': verdict, 'passing': 1, 'failing': 0}
    doc = {
        'schema': PC.CERT_SCHEMA, 'target': target, 'variant': target,
        'ut_dir': target, 'verdict': verdict, 'proof_mode': 'signoff-strict',
        'provisional': False, 'impl_worktree_dirty': False,
        'impl_commit': impl_commit, 'proof_commit': impl_commit,
        'proof_worktree_digest': h('4'), 'g1_canonical_id': 'G1-testcid',
        'g1_manifest_sha256': h('5'),
        'tool': {'name': 'fm_shell', 'version': 'V-2023.12-SP3',
                 'build': '8868332', 'fm_shell_rc': 0},
        'proof_config': cfg, 'proof_config_sha256': PC.canon_digest(cfg),
        'input_closure': {'golden': golden, 'impl': impl,
                          'golden_sha256': PC.closure_digest(golden),
                          'impl_sha256': PC.closure_digest(impl),
                          'repo_impl_files': 1},
        'script_closure': {'entries': script,
                           'sha256': PC.closure_digest(script)},
        'native_facts_sha256': h('6'), 'native_result': native,
        'result_sha256': PC.canon_digest({'verdict': verdict,
                                          'native_result': native}),
        'receipt_sha256': h('7'), 'evidence_retention': 'attestation_only',
        'evidence_archive': None,
        'reproduce': {'command': 'make -C verif/ut/%s fm-%s' % (target, target)},
        'generated_at': '2026-01-01T00:00:00Z',
        'generator': {'script': 'scripts/make_proof_certificate.py', 'version': 1,
                      'source_evidence_dir': 'evidence/test'},
        'run_id': 'test-run',
    }
    errs = PC.validate_document(doc)
    assert not errs, '夹具证书自己就不合法，正控无效: %s' % errs[:3]
    return doc

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
    # ★证书目录 + git★：proof status 只认 tracked 证书（codex 0153 D66），
    # 判定 trackedness 要 `git ls-files`，所以夹具必须是个真 git 仓库。
    certs = root / 'repo' / 'verif' / 'proof_certificates'
    certs.mkdir(parents=True)
    (certs / 'POLICY.json').write_text(json.dumps(policy_doc(), indent=1))
    git_init(root / 'repo')
    # 另一个"主树"哨兵：任何脚本都不许写到它里面
    other = root / 'other_repo' / 'docs'
    other.mkdir(parents=True)
    (other / 'g1_universe.tsv').write_text('SENTINEL\n')
    return root


def git_init(repo):
    env = dict(os.environ, GIT_AUTHOR_NAME='t', GIT_AUTHOR_EMAIL='t@t',
               GIT_COMMITTER_NAME='t', GIT_COMMITTER_EMAIL='t@t')
    for args in (['init', '-q'], ['add', '-A'],
                 ['commit', '-q', '-m', 'fixture']):
        subprocess.run(['git'] + args, cwd=str(repo), env=env,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)


def git_add(repo, *paths):
    """把文件加进 index 并提交 —— 只有这样 `git ls-files` 才认它。"""
    env = dict(os.environ, GIT_AUTHOR_NAME='t', GIT_AUTHOR_EMAIL='t@t',
               GIT_COMMITTER_NAME='t', GIT_COMMITTER_EMAIL='t@t')
    subprocess.run(['git', 'add', '--'] + list(paths), cwd=str(repo), env=env,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    subprocess.run(['git', 'commit', '-q', '-m', 'add'], cwd=str(repo), env=env,
                   stdout=subprocess.PIPE, stderr=subprocess.PIPE)


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
            # --root 现在两边都要：obligation 列按 configured universe 的 scope 判
            cmd += ['--canonical-id', str(self.root / 'cid.txt'), '--root', 'Top']
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
# D58-2 / D66  proof status 只按 g1_name 取，且只认 tracked 证书
# ====================================================================
class TestNoCertificateCrossWiring(Base):
    """串位事故在 D66 之后的形态：证书挂在**老名**下。

    老形态是 receipt 串位（`status.get(old) or status.get(new)`）。D66 把状态来源
    换成 tracked 证书之后，同一个错误会以"老名下的证书被新 target 继承"重现，
    所以这组负测跟着搬到证书上，并且**保留正控**：证书记在 G1 名下时必须真的变绿。
    没有正控，"全都没变绿"也能让负测通过 —— 那就是假通过。
    """

    def _put_cert(self, name, **kw):
        d = self.root / 'repo' / 'verif' / 'proof_certificates'
        f = d / ('%s.json' % name)
        f.write_text(json.dumps(make_certificate(name, **kw), indent=1))
        return f

    def test_certificate_of_old_name_is_not_inherited_by_the_new_target(self):
        """★事故本体★ 证书只存在于老名 Leaf_1 名下。映射改判到 Leaf_2 之后，
        Leaf_2 没有实现、没有 UT、没有证书 —— proof_status 必须是 UNVERIFIED。"""
        self._put_cert('Leaf_1')
        git_add(self.root / 'repo', 'verif/proof_certificates/Leaf_1.json')
        rc, out, _ = self.run_gen('g1_universe.py', '--report-dropped')
        self.assertEqual(rc, 0, out)
        r = self.rows()
        self.assertEqual(r['Leaf_1'][1], 'Leaf_2')
        self.assertEqual(r['Leaf_1'][5], 'UNVERIFIED',
                         '★Leaf_2 继承了 Leaf_1 的证书 —— 串位没修好★')
        self.assertNotIn('Leaf_1.json', r['Leaf_1'][6],
                         'note 里还挂着别人的证书路径')
        self.assertIn('Leaf_1 → Leaf_2  老名证书状态 VERIFIED 已丢弃', out,
                      '丢弃了老名状态却没有逐条报告 —— 静默丢弃同样不可接受')

    def test_certificate_under_the_new_name_is_honored(self):
        """★正控★ 证书记在 G1 名下时必须真的变 VERIFIED。

        没有这一条，上一条可能只是"所有证书都被忽略了"。"""
        self._put_cert('Leaf_2')
        git_add(self.root / 'repo', 'verif/proof_certificates/Leaf_2.json')
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        r = self.rows()
        self.assertEqual(r['Leaf_1'][5], 'VERIFIED',
                         '证书记在 G1 名下却没生效（假阴性：正控失效，负测无意义）')
        self.assertIn('Leaf_2.json', r['Leaf_1'][6])

    def test_untracked_certificate_does_not_turn_green(self):
        """往工作树里丢一份证书而不 git add —— 必须仍是 UNVERIFIED。"""
        self._put_cert('Leaf_2')                       # ★刻意不 git add★
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        self.assertEqual(self.rows()['Leaf_1'][5], 'UNVERIFIED',
                         '★untracked 证书把它转绿了 —— trackedness 闸没生效★')

    def test_null_freeze_commit_refuses_to_release(self):
        """POLICY.freeze_commit 为 null 时，合格证书也不得放行（fail-closed）。"""
        d = self.root / 'repo' / 'verif' / 'proof_certificates'
        (d / 'POLICY.json').write_text(json.dumps(policy_doc(None), indent=1))
        self._put_cert('Leaf_2')
        git_add(self.root / 'repo', 'verif/proof_certificates')
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        self.assertEqual(self.rows()['Leaf_1'][5], 'CERT_REJECTED',
                         'freeze_commit=null 却放行了')

    def test_impl_commit_not_matching_freeze_commit_is_rejected(self):
        """证书钉的 impl_commit 不是 freeze_commit —— 拒绝。"""
        self._put_cert('Leaf_2', impl_commit='b' * 40)
        git_add(self.root / 'repo', 'verif/proof_certificates/Leaf_2.json')
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        self.assertEqual(self.rows()['Leaf_1'][5], 'CERT_REJECTED')

    def test_corrupt_certificate_is_loud_not_silently_unverified(self):
        """坏证书必须响成 CERT_INVALID，不能静默塌成"没有证书"。"""
        d = self.root / 'repo' / 'verif' / 'proof_certificates'
        (d / 'Leaf_2.json').write_text('{"schema": "wrong"}')
        git_add(self.root / 'repo', 'verif/proof_certificates/Leaf_2.json')
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        self.assertEqual(self.rows()['Leaf_1'][5], 'CERT_INVALID',
                         '坏证书被当成了"没有证书" —— 仓库缺陷被静默了')


# ====================================================================
# D66  status 与 universe 解耦：untracked evidence 不得影响冻结字节
# ====================================================================
class TestFrozenBytesIndependentOfUntrackedEvidence(Base):
    """★D66 的验收本体★

    `docs/receipt_index.tsv` 与 `evidence/` 都在 .gitignore 里。冻结表的字节
    只要依赖它们，clean clone 就复现不出来 —— 实测主树 118 行 REVALIDATED_PASS
    在 clean worktree 里变 0 行，`--check` 直接幂等 FAIL。
    """

    def test_receipt_index_does_not_change_a_single_byte(self):
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        with_ri = (self.root / 'repo' / 'docs' / 'g1_universe.tsv').read_bytes()
        norm_ri = (self.root / 'repo' / 'docs' / 'ledger_normalized.tsv').read_bytes()
        # 前提：夹具的 receipt_index 里确实有一条"看起来完美"的通过记录
        self.assertIn('SUCCEEDED',
                      (self.root / 'repo' / 'docs' / 'receipt_index.tsv').read_text())
        (self.root / 'repo' / 'docs' / 'receipt_index.tsv').unlink()
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        self.assertEqual(
            with_ri,
            (self.root / 'repo' / 'docs' / 'g1_universe.tsv').read_bytes(),
            '★删掉 untracked 的 receipt_index 改变了冻结表字节 —— 解耦没做到★')
        self.assertEqual(
            norm_ri,
            (self.root / 'repo' / 'docs' / 'ledger_normalized.tsv').read_bytes())

    def test_no_receipt_index_means_unverified_not_error(self):
        """clean clone 里没有 receipt_index —— 正确结果是 UNVERIFIED，不是报错。"""
        (self.root / 'repo' / 'docs' / 'receipt_index.tsv').unlink()
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        for k, f in self.rows().items():
            self.assertEqual(f[5], 'UNVERIFIED', '%s 不是 UNVERIFIED' % k)

    def test_receipt_report_is_opt_in_and_separate(self):
        """--receipt-report 只写独立报告，冻结字节一个都不许变。"""
        self.run_gen('g1_universe.py')
        before = (self.root / 'repo' / 'docs' / 'g1_universe.tsv').read_bytes()
        rep = self.root / 'hist.tsv'
        rc, out, _ = self.run_gen('g1_universe.py', '--receipt-report', str(rep))
        self.assertEqual(rc, 0, out)
        self.assertTrue(rep.exists(), '--receipt-report 没写出报告')
        self.assertIn('诊断', rep.read_text())
        self.assertEqual(before,
                         (self.root / 'repo' / 'docs' / 'g1_universe.tsv').read_bytes(),
                         '历史报告改动了冻结表字节')

    def test_obligation_column_is_derived_from_scope(self):
        """obligation 由 scope 机械推出：Leaf_1 在 G1 里不被 Top 可达 → OUT_OF_SCOPE。"""
        rc, out, _ = self.run_gen('g1_universe.py')
        self.assertEqual(rc, 0, out)
        r = self.rows()
        self.assertEqual(r['Top'][4], 'REQUIRED')
        # Leaf_2 的映射目标 Leaf_3 被 Top 例化 ⇒ 在 universe 内
        self.assertEqual(r['Leaf_2'][4], 'REQUIRED')
        self.assertIn('REQUIRED', out)


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
               '--canonical-id', str(self.root / 'cid.txt'), '--root', 'Top']
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

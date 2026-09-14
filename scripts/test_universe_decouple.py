#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_universe_decouple.py —— D66/D69/D70 三条新判据的负测。

每条新判据都配**必失败样本 + 干净夹具的 PASS 对照**。本工程有过多次"测试假通过"，
这里逐条堵：

 1. **断言被前置门挡掉却报 PASS**：负测先跑一次干净夹具确认该判据在 PASS 状态，
    再注入缺陷确认转 FAIL。一失一得成对出现，才证明确实走到了被测判据。
 2. **退出码不够**：每条都同时断言**退出码**与**关键字**。
 3. **反测崩溃与"抓到了"都是 1**：每次运行都断言 stderr 里没有 `Traceback`，
    且 check_closure_symmetry 的自身异常有独立退出码 3（INTERNAL_ERROR）。
 4. **管道后的 `$?` 是最后一条命令的**：本文件全部用 subprocess 直接取 returncode，
    不经 shell 管道。

覆盖：
    D66  proof_status 只由 tracked 证书派生；obligation 由 scope 派生；两列都不许手写
    D70  FM target 全集用 make 权威求值；缺陷模型 248 vs 权威 272；分类断言对账
    D69  源清单对账（两侧过近似黑盒集皆空 ⇒ 对称），且 UNKNOWN 绝不等价于 clean

跑法：  python3 scripts/test_universe_decouple.py
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
import fm_target_universe as FTU                                   # noqa: E402
import proof_status as PS                                          # noqa: E402
REPO = HERE.parent


def run(cmd, cwd=None):
    p = subprocess.Popen([str(c) for c in cmd], stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, universal_newlines=True,
                         cwd=str(cwd) if cwd else None)
    out, err = p.communicate()
    return p.returncode, out, err


class NoCrash(unittest.TestCase):
    def sh(self, cmd, cwd=None):
        rc, out, err = run(cmd, cwd)
        # 坑：反测崩溃的 traceback 退出码与"抓到了"都是 1，必须分开
        self.assertNotIn('Traceback', err,
                         '脚本自己崩了（不是检查结论）:\n%s' % err)
        return rc, out, err


# ======================================================================
# D70  make 权威求值
# ======================================================================
class TestMakeAuthoritative(NoCrash):

    def test_make_and_regex_agree_on_this_commit(self):
        """★干净对照★ 两个引擎在本 commit 上必须完全一致。

        这条同时是下面 EngineDisagree 负测的前提：如果两个引擎本来就不一致，
        '注入分歧后报错' 就证明不了任何东西。
        """
        commit = self.sh(['git', 'rev-parse', 'HEAD'], REPO)[1].strip()
        mk, _ = FTU.targets_at_make(str(REPO), commit)
        rx, unres = FTU.targets_at_regex(str(REPO), commit)
        self.assertEqual(unres, [], '正则引擎有未展开 token')
        self.assertEqual(set(mk), set(rx),
                         '两引擎对同一 commit 给出不同 target 全集')
        self.assertGreater(len(mk), 200, 'target 全集小得不像话，夹具/仓库不对')

    def test_the_two_named_targets_are_fm_targets(self):
        """★D70 点名的两个★ 必须被权威求值认成 FM target。"""
        commit = self.sh(['git', 'rev-parse', 'HEAD'], REPO)[1].strip()
        mk, _ = FTU.targets_at_make(str(REPO), commit)
        self.assertIn('MbistPipeIcacheTag', mk)
        self.assertEqual(sorted(mk['MbistPipeIcacheTag']), ['MbistPipe'])
        self.assertIn('ICacheMissUnit', mk)
        self.assertEqual(sorted(mk['ICacheMissUnit']), ['ICacheMissUnit'])

    def test_defect_model_reproduces_the_248_vs_272_delta(self):
        """★缺陷模型必须仍然复现事故★

        它是"未展开 make 变量"这类事故的 oracle。哪天有人把
        verif/ut/MbistPipe/Makefile 的 `:=` 改成 `=`，这条会红 —— 那时要确认
        的是"事故形态变了"，不是把断言改掉。
        """
        commit = self.sh(['git', 'rev-parse', 'HEAD'], REPO)[1].strip()
        auth, _ = FTU.targets_at_make(str(REPO), commit)
        bad = FTU.targets_at_defect_model(str(REPO), commit)
        missed = sorted(set(auth) - set(bad))
        self.assertEqual(len(auth), 272, '权威 target 全集变了')
        self.assertEqual(len(bad), 248, '缺陷模型的结果变了')
        self.assertEqual(len(missed), 24)
        self.assertIn('MbistPipeIcacheTag', missed,
                      '★事故本体不再复现，这条负测已经失去意义★')
        self.assertTrue(all(m.startswith('MbistPipe') for m in missed))
        # 反向：缺陷模型不许多出东西（多出来是另一类事故，不该被这条掩盖）
        self.assertEqual(sorted(set(bad) - set(auth)), [])

    def test_engine_disagreement_is_fail_closed(self):
        """★必失败样本★ 两引擎不一致时必须抛 EngineDisagree，绝不挑一个当答案。"""
        commit = self.sh(['git', 'rev-parse', 'HEAD'], REPO)[1].strip()
        # 干净对照：不注入时 targets_at 正常返回
        t, _ = FTU.targets_at(str(REPO), commit)
        self.assertGreater(len(t), 200)
        orig = FTU.targets_at_regex
        try:
            FTU.targets_at_regex = lambda r, c: ({'OnlyRegexKnowsMe': ['x']}, [])
            with self.assertRaises(FTU.EngineDisagree) as cm:
                FTU.targets_at(str(REPO), commit)
            self.assertIn('不一致', str(cm.exception))
        finally:
            FTU.targets_at_regex = orig

    def test_no_second_fm_variants_parser_in_repo(self):
        """★根因防复发★ 仓库里不许再出现第二份 FM_VARIANTS 正则解析。

        `scripts/bulk_revalidate.py` 就是这么漂掉 24 个 target 的。
        允许的只有 fm_target_universe.py 自己（含它刻意保留的缺陷模型）。

        ★按 AST 找**真正被编译的正则**，不按文本 grep★：docstring 与注释里
        引用旧正则是在记录事故，不是在用它。按文本 grep 会把"把事故写进文档"
        本身判成事故 —— 实测本条第一版就是这么假红的。
        """
        import ast as _ast
        allowed = {'fm_target_universe.py'}
        offenders = []
        for f in sorted((REPO / 'scripts').glob('*.py')):
            if f.name in allowed or f.name.startswith('test_'):
                continue
            try:
                tree = _ast.parse(f.read_text(errors='replace'))
            except SyntaxError:
                continue
            for node in _ast.walk(tree):
                if not isinstance(node, _ast.Call):
                    continue
                fn = node.func
                if not (isinstance(fn, _ast.Attribute)
                        and fn.attr in ('search', 'compile', 'finditer',
                                        'match', 'findall')
                        and isinstance(fn.value, _ast.Name) and fn.value.id == 're'):
                    continue
                for arg in node.args[:1]:
                    if isinstance(arg, _ast.Str) and 'FM_VARIANTS' in arg.s:
                        offenders.append('%s:%d' % (f.name, node.lineno))
        self.assertEqual(offenders, [],
                         '又出现了第二份 FM_VARIANTS 解析器（真代码，不是注释）: %s'
                         % offenders)

    def test_the_parser_detector_actually_has_teeth(self):
        """★检测器自身的正控★ 造一份真的坏解析器，检测器必须抓到它。

        没有这一条，上一条可能只是"AST 走法写错了，永远找不到任何东西"。
        """
        import ast as _ast
        src = ("import re\n"
               "def f(txt):\n"
               "    return re.search(r'^FM_VARIANTS\\s*=\\s*(.*)$', txt, re.M)\n")
        tree = _ast.parse(src)
        hits = []
        for node in _ast.walk(tree):
            if isinstance(node, _ast.Call) and isinstance(node.func, _ast.Attribute) \
                    and node.func.attr in ('search', 'compile', 'finditer',
                                           'match', 'findall') \
                    and isinstance(node.func.value, _ast.Name) \
                    and node.func.value.id == 're':
                for arg in node.args[:1]:
                    if isinstance(arg, _ast.Str) and 'FM_VARIANTS' in arg.s:
                        hits.append(node.lineno)
        self.assertEqual(len(hits), 1,
                         '★检测器抓不到一份明摆着的坏解析器 —— 上一条是空断言★')

    def test_bulk_revalidate_now_sees_all_272(self):
        """★对照★ 修完之后 bulk_revalidate 必须看到全部 272 个。"""
        sys.path.insert(0, str(REPO / 'scripts'))
        import bulk_revalidate as B
        d = B.ut_dirs()
        self.assertEqual(len(d), 272)
        self.assertIn('MbistPipeIcacheTag', d)


# ======================================================================
# D70  分类断言对账
# ======================================================================
class TestClassificationAudit(NoCrash):
    SCRIPT = HERE / 'child_target_closure.py'

    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix='ctc-')
        self.repo = pathlib.Path(self.tmp) / 'repo'
        # 用真仓库做底（需要真 Makefile 与真 G1），只把分类表换掉
        shutil.copytree(REPO / 'verif' / 'allow_gen',
                        self.repo / 'verif' / 'allow_gen')

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _audit(self, classification_text=None):
        cls = REPO / 'verif' / 'allow_gen' / 'classification.tsv'
        backup = cls.read_text()
        try:
            if classification_text is not None:
                cls.write_text(classification_text)
            return self.sh([sys.executable, self.SCRIPT, '--repo', REPO, '--audit'])
        finally:
            cls.write_text(backup)

    def test_clean_repo_passes_audit(self):
        """★干净对照★ 改好之后，仓库现状必须 AUDIT PASS。"""
        rc, out, _ = self._audit()
        self.assertEqual(rc, 0, out)
        self.assertIn('AUDIT PASS', out)

    def test_false_not_fm_target_claim_is_caught(self):
        """★必失败样本★ 谎称一个真 target"不是 FM target" → 必须 FAIL。"""
        cls = REPO / 'verif' / 'allow_gen' / 'classification.tsv'
        lines = cls.read_text().split('\n')
        for i, ln in enumerate(lines):
            f = ln.split('\t')
            if len(f) >= 8 and f[0] == 'ICacheMetaArray':
                f[7] = 'MbistPipeIcacheTag 不是 FM target'
                lines[i] = '\t'.join(f)
        rc, out, _ = self._audit('\n'.join(lines))
        self.assertEqual(rc, 1, '假断言没被判 FAIL:\n%s' % out)
        self.assertIn('AUDIT FAIL', out)
        self.assertIn('MbistPipeIcacheTag', out)

    def test_true_not_fm_target_claim_is_not_a_false_positive(self):
        """★对照组★ 真的不是 target 的那些，断言必须被放行。

        没有这一条，上一条可能只是"凡出现『不是 FM target』就报错"。
        """
        cls = REPO / 'verif' / 'allow_gen' / 'classification.tsv'
        lines = cls.read_text().split('\n')
        for i, ln in enumerate(lines):
            f = ln.split('\t')
            if len(f) >= 8 and f[0] == 'ICacheMetaArray':
                f[7] = 'ICacheMainPipe 不是 FM target'   # 确实不是
                lines[i] = '\t'.join(f)
        rc, out, _ = self._audit('\n'.join(lines))
        self.assertEqual(rc, 0, '真断言被误判成假断言（假阳性）:\n%s' % out)
        self.assertIn('AUDIT PASS', out)

    def test_a2_no_target_count_is_nine(self):
        """★D70 盯的那个数★ A2 且无 FM target 的 child = 9（原为 11）。"""
        rc, out, _ = self.sh([sys.executable, self.SCRIPT, '--repo', REPO])
        self.assertEqual(rc, 0, out)
        self.assertIn('A2（green_child 候选）且无 FM target = 9', out)
        self.assertNotIn('MbistPipeIcacheTag', out.split('★')[-1])

    def test_generated_table_marks_the_two_as_unverified_not_no_target(self):
        """两者必须是「已有 target、尚无证书」的 UNVERIFIED，不是 NO_FM_TARGET。"""
        tsv = REPO / 'docs' / 'child_target_closure.tsv'
        rows = {}
        for ln in tsv.read_text().splitlines():
            if ln.startswith('#') or not ln.strip():
                continue
            f = ln.split('\t')
            rows[f[0]] = f
        for name in ('MbistPipeIcacheTag', 'ICacheMissUnit'):
            self.assertIn(name, rows)
            self.assertEqual(rows[name][2], 'YES', '%s 仍被记成没有 target' % name)
            self.assertEqual(rows[name][4], PS.UNVERIFIED)
            self.assertEqual(rows[name][5], 'HAS_TARGET_UNVERIFIED')


# ======================================================================
# D66  冻结表的两列不许手写
# ======================================================================
class TestFrozenColumnsCannotBeForged(NoCrash):
    """C2(f)/(g)：obligation 与 proof_status 都必须能被重算出来。

    这两条是"解耦"的机器闸。没有它们，解耦只是把旧绿换了个列名接着写。
    """
    SCRIPT = HERE / 'check_universe_freeze.py'

    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix='frz-')
        self.repo = pathlib.Path(self.tmp)
        self.uni = REPO / 'docs' / 'g1_universe.tsv'
        self.backup = self.uni.read_text()

    def tearDown(self):
        self.uni.write_text(self.backup)
        shutil.rmtree(self.tmp, ignore_errors=True)

    def _c2(self):
        return self.sh([sys.executable, self.SCRIPT, '--repo', REPO,
                        '--only', 'C2'])

    def test_clean_repo_passes_c2(self):
        """★干净对照★"""
        rc, out, _ = self._c2()
        self.assertEqual(rc, 0, out)
        self.assertIn('C2 CONSERVATION', out)
        self.assertNotIn('★FAIL★', out)

    def test_forged_proof_status_is_caught(self):
        """★必失败样本★ 手工把一行改成 VERIFIED —— 证书不在，必须响。"""
        lines = self.backup.split('\n')
        hit = False
        for i, ln in enumerate(lines):
            if ln.startswith('#') or not ln.strip():
                continue
            f = ln.split('\t')
            if len(f) >= 7 and f[5] == PS.UNVERIFIED:
                f[5] = PS.VERIFIED
                lines[i] = '\t'.join(f)
                hit = True
                break
        self.assertTrue(hit, '找不到可改的 UNVERIFIED 行，夹具失效')
        self.uni.write_text('\n'.join(lines))
        rc, out, _ = self._c2()
        self.assertEqual(rc, 1, '伪造的 VERIFIED 没被抓到:\n%s' % out)
        self.assertIn('★状态不得手写★', out)

    def test_forged_obligation_is_caught(self):
        """★必失败样本★ 把一个 REQUIRED 偷偷改成 OUT_OF_SCOPE。"""
        lines = self.backup.split('\n')
        hit = False
        for i, ln in enumerate(lines):
            if ln.startswith('#') or not ln.strip():
                continue
            f = ln.split('\t')
            if len(f) >= 7 and f[4] == 'REQUIRED':
                f[4] = 'OUT_OF_SCOPE'
                lines[i] = '\t'.join(f)
                hit = True
                break
        self.assertTrue(hit)
        self.uni.write_text('\n'.join(lines))
        rc, out, _ = self._c2()
        self.assertEqual(rc, 1, '伪造的 obligation 没被抓到:\n%s' % out)
        self.assertIn('但按 configured universe 的 scope 应为', out)

    def test_unknown_status_token_is_rejected(self):
        """★必失败样本★ 冻结表里出现不认识的状态名不许被静默放过。"""
        lines = self.backup.split('\n')
        for i, ln in enumerate(lines):
            if ln.startswith('#') or not ln.strip():
                continue
            f = ln.split('\t')
            if len(f) >= 7:
                f[5] = 'TOTALLY_GREEN'
                lines[i] = '\t'.join(f)
                break
        self.uni.write_text('\n'.join(lines))
        rc, out, _ = self._c2()
        self.assertEqual(rc, 1, out)
        self.assertIn("proof_status='TOTALLY_GREEN'", out.replace('"', "'"))


# ======================================================================
# D66  proof_status 模块自身
# ======================================================================
class TestProofStatusModule(NoCrash):

    def test_repo_without_certificates_is_unverified_not_error(self):
        """clean clone 的正确答案是 UNVERIFIED，不是报错、不是塌陷。"""
        smap = PS.status_map(REPO)
        self.assertEqual(smap, {}, '仓库里现在有 tracked 证书了？')
        self.assertEqual(PS.status_of(smap, 'Anything')[0], PS.UNVERIFIED)

    def test_policy_missing_is_fail_closed(self):
        """★必失败样本★ 没有 POLICY.json 不等于放行。"""
        tmp = tempfile.mkdtemp(prefix='nopol-')
        try:
            with self.assertRaises(PS.PolicyError):
                PS.status_map(tmp)
        finally:
            shutil.rmtree(tmp, ignore_errors=True)

    def test_proven_set_is_exactly_verified(self):
        """任何闸都必须按 PROVEN 判。它一旦被放宽，这条先红。"""
        self.assertEqual(set(PS.PROVEN), {PS.VERIFIED})
        self.assertNotIn(PS.CERT_REJECTED, PS.PROVEN)
        self.assertNotIn(PS.CERT_INVALID, PS.PROVEN)
        self.assertNotIn(PS.UNVERIFIED, PS.PROVEN)


# ======================================================================
# D69  源清单对账
# ======================================================================
class TestClosureInventory(NoCrash):
    SCRIPT = HERE / 'check_closure_symmetry.py'

    def test_icachemissunit_closure_unknown_is_closed(self):
        """★D69 点名★ ICacheMissUnit 必须在 official run 前关掉 closure unknown。"""
        rc, out, _ = self.sh([sys.executable, self.SCRIPT,
                              '--only', 'ICacheMissUnit', '--inventory'])
        self.assertEqual(rc, 0, out)
        self.assertIn('SYMMETRIC_BY_INVENTORY=1', out)
        self.assertNotIn('ERROR=', out)

    def test_without_inventory_it_is_still_honestly_unknown(self):
        """★对照组★ 不开 --inventory 时它仍是 ERROR。

        没有这一条，上一条可能只是"这个 target 本来就一直是绿的"。
        """
        rc, out, _ = self.sh([sys.executable, self.SCRIPT,
                              '--only', 'ICacheMissUnit'])
        self.assertEqual(rc, 1, out)
        self.assertIn('ERROR', out)
        self.assertIn('$bits', out)

    def test_inventory_never_reports_symmetric_when_overapprox_nonempty(self):
        """★UNKNOWN 绝不等价于 clean★

        把 impl 侧的一个依赖文件从 make 展开结果里拿掉，过近似黑盒集就非空，
        必须落 INVENTORY_UNKNOWN 而**不是** CLOSED。
        """
        import check_closure_symmetry as CCS
        utdir = REPO / 'verif' / 'ut' / 'ICacheMissUnit'
        # 干净对照
        good = CCS.inventory_check(utdir, 'ICacheMissUnit')
        self.assertEqual(good['inventory'], CCS.INV_CLOSED, good['inventory_detail'])
        orig = CCS.make_vars

        def crippled(ut, target):
            v = dict(orig(ut, target))
            v['IMPL'] = [f for f in v['IMPL'] if 'ICacheMSHR_1.sv' not in f]
            return v
        try:
            CCS.make_vars = crippled
            bad = CCS.inventory_check(utdir, 'ICacheMissUnit')
        finally:
            CCS.make_vars = orig
        self.assertEqual(bad['inventory'], CCS.INV_UNKNOWN,
                         '少读了一个提供者却还判 CLOSED —— 判据是假的')
        self.assertIn('ICacheMSHR_1', str(bad['overapprox_bbox']['impl']))

    def test_internal_error_has_its_own_exit_code(self):
        """脚本自身异常必须是退出码 3，与"抓到了"的 1 分开。"""
        import check_closure_symmetry as CCS
        self.assertEqual(CCS.EXIT_INTERNAL, 3)
        self.assertEqual(CCS.EXIT_VIOLATION, 1)
        self.assertEqual(CCS.EXIT_USAGE, 2)

    def _ledger_rows(self, seed, bypass_pin=False):
        """跑一次单 target 台账，返回数据行。

        bypass_pin=True 时用 import+main() 调用，绕过 __main__ 里的种子自钉 ——
        用来证明"输出确实对 hash 种子敏感"，即那道自钉不是摆设。
        """
        out = pathlib.Path(tempfile.mkdtemp(prefix='led-')) / 'l.tsv'
        env = dict(os.environ, PYTHONHASHSEED=str(seed))
        if bypass_pin:
            cmd = [sys.executable, '-c',
                   'import sys; sys.path.insert(0, %r); '
                   'import check_closure_symmetry as C; '
                   'sys.exit(C.main(sys.argv[1:]))' % str(HERE),
                   '--only', 'TageTable', '--jobs', '8', '--inventory',
                   '--closure-ledger', str(out)]
        else:
            cmd = [sys.executable, str(self.SCRIPT), '--only', 'TageTable',
                   '--jobs', '8', '--inventory', '--closure-ledger', str(out)]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             universal_newlines=True, env=env)
        _o, err = p.communicate()
        self.assertNotIn('Traceback', err, err)
        rows = [ln for ln in out.read_text().splitlines()
                if ln and not ln.startswith('#')]
        self.assertTrue(rows, '台账没有数据行，断言会退化成空断言')
        shutil.rmtree(out.parent, ignore_errors=True)
        return rows

    def test_ledger_is_byte_reproducible(self):
        """★本轮实测到的真事故★ 生成物必须字节可复现。

        sv_elab 报"未知标识符"时取的是无序容器里的第一个名字，Python 默认对 str
        做 hash 随机化 ⇒ 同一输入两次运行 detail 文本不同（TageTable_2/_3 在
        `_unsupported` 与真实信号名之间来回跳，jobs=1 也复现）。
        入口 `_pin_hash_seed()` 把种子钉成 0；这条守住它。
        """
        a = self._ledger_rows(0)
        b = self._ledger_rows(0)
        self.assertEqual(a, b, '同一输入两次运行台账不一致 —— 生成物不可复现')

    def test_the_seed_pin_is_load_bearing_not_a_noop(self):
        """★对照组★ 绕过自钉后，不同 hash 种子必须给出不同输出。

        没有这一条，上一条可能只是"这个 target 本来就稳定"，
        那道 PYTHONHASHSEED 自钉就成了自我安慰。
        """
        a = self._ledger_rows(0, bypass_pin=True)
        b = self._ledger_rows(12345, bypass_pin=True)
        self.assertNotEqual(
            a, b,
            '换 hash 种子输出没变 —— 要么事故形态变了、要么这条测试已失去意义，'
            '必须先确认再改断言')

    def test_entry_point_actually_pins_the_seed(self):
        """自钉必须真的在入口被调用，而不只是定义了一个没人用的函数。"""
        src = (HERE / 'check_closure_symmetry.py').read_text()
        self.assertIn('_pin_hash_seed()', src.split("if __name__ == '__main__':")[1],
                      '__main__ 里没有调用 _pin_hash_seed()')

    def test_bind_makes_the_overapproximation_invalid(self):
        """★必失败样本★ `bind` 会在语法可见的例化之外挂实例 ——
        "语法例化是过近似"这个前提不成立，必须拒绝下结论而不是照旧判 CLOSED。"""
        import check_closure_symmetry as CCS
        tmp = tempfile.mkdtemp(prefix='bind-')
        try:
            f = pathlib.Path(tmp) / 'M.sv'
            f.write_text('module M(input clock);\nendmodule\n'
                         'bind M Checker chk (.*);\n')
            with self.assertRaises(RuntimeError) as cm:
                CCS._provider_inventory([str(f)])
            self.assertIn('bind', str(cm.exception))
        finally:
            shutil.rmtree(tmp, ignore_errors=True)


if __name__ == '__main__':
    unittest.main(verbosity=2)

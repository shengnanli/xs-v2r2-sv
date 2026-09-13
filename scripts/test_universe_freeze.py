#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_universe_freeze.py —— check_universe_freeze.py 的负测。

## 本工程踩过的「测试假通过」坑，这里逐条堵死

1. **断言被前置门挡掉却报 PASS**：夹具在到达被测判据之前就挂了（解析失败、
   文件缺失），检查器返回 2 或提前 return，测试只看"非 0"就报"抓到了"。
   → 每条负测都用 `--only <该条>` 跑，并且**先跑一遍干净夹具**确认同一条 `--only`
     下是 PASS/退出 0。一失一得成对出现，才证明夹具确实走到了被测判据。
2. **按退出码判 = 没牙齿**（历史上 VCS 对 `$fatal` 返回 0 就是这么骗过去的）。
   → 不只看退出码：必须在 stdout 里看到**那一条**被标 `★FAIL★`，并且失败原因
     里含预期关键字。退出码只作为附加断言。
3. **反测崩溃的 traceback 退出码与"抓到了"一样**（都是 1）。
   → 每次运行都断言 stderr 里没有 `Traceback`；且断言 stdout 里出现了正常的
     报表头（`FREEZE BLOCKED` / `FREEZE OK`）——崩溃时这两样都不会有。
4. **检查器恒失败也能让所有负测变绿**。
   → `test_00_clean_fixture_passes_everything` 要求干净夹具**五条全绿、退出 0**。
     恒失败的检查器过不了这一条。
5. **检查器恒通过也能让正测变绿**。
   → 每条负测都要求恰好那一条 FAIL。恒通过的检查器过不了任何一条负测。

跑法：  python3 scripts/test_universe_freeze.py         （-v 看每条）
"""
from __future__ import print_function

import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
CHECKER = HERE / 'check_universe_freeze.py'

# ---------------------------------------------------------------- 夹具
# 一个微型的两基线世界。刻意做成「名字平移」——G0 的 Leaf_1 在 G1 里叫 Leaf_2，
# G0 的 Leaf_2 在 G1 里叫 Leaf_3——即真实工程里最毒的那类重编号。

G0_FILES = {
    'Top.sv': """module Top(
  input  clock,
  input  reset
);
  Leaf_1 a (
    .clock (clock)
  );
  Leaf_2 b (
    .clock (clock)
  );
endmodule
""",
    'Leaf_1.sv': """module Leaf_1(
  input  clock,
  output out
);
endmodule
""",
    'Leaf_2.sv': """module Leaf_2(
  input  clock,
  input  reset,
  output out
);
endmodule
""",
}

G1_FILES = {
    'Top.sv': """module Top(
  input  clock,
  input  reset
);
  Leaf_2 a (
    .clock (clock)
  );
  Leaf_3 b (
    .clock (clock)
  );
endmodule
""",
    'Leaf_2.sv': """module Leaf_2(
  input  clock,
  output out
);
endmodule
""",
    'Leaf_3.sv': """module Leaf_3(
  input  clock,
  input  reset,
  output out
);
endmodule
""",
    'Extra_ext.sv': """module Extra_ext(
  input  clock
);
endmodule
""",
}

UNIVERSE_TSV = """# G1 主 universe 对账
# old_target\tg1_name\tresolve\tdelta_class\tstatus\tnote
Top\tTop\tsame_name\tTRIVIAL\tNOT_STARTED\t
Leaf_1\tLeaf_2\tslot_map\tREWRITE_S\tNOT_STARTED\t
Leaf_2\tLeaf_3\tslot_map\tREWRITE_S\tWORKING_PASS\t
"""

OLD2NEW_TSV = """# old306 → G1 守恒映射
# old_target\tg1_name\tdisposition\tin_universe
Top\tTop\tsame_name\tyes
Leaf_1\tLeaf_2\tslot_map\tyes
Leaf_2\tLeaf_3\tslot_map\tyes
"""

CONFIG_TSV = """# G1 configured target universe
# module\tin_universe\tsource
Extra_ext\tno\texcluded:vendor_macro_leaf
Leaf_2\tyes\tfrom_old_306
Leaf_3\tyes\tfrom_old_306
Top\tyes\tfrom_old_306
"""

NORM_TSV = """# 台账归一化
# target\tbucket\tstatus\tnote
Leaf_3\tMAIN\tWORKING_PASS\tfixture
"""

EVIDENCE_TSV = """# 槽位判据重算证据
# old_target\tg1_name\tcriterion\tg0_ports\tg1_ports\tg0_slots\tg1_slots\tnote
Leaf_1\tLeaf_2\tsite\t2\t2\tTop.a\tTop.a\t
Leaf_2\tLeaf_3\tsite\t3\t3\tTop.b\tTop.b\t
Top\t-\tUNRESOLVED\t2\t-\t(无例化点)\t-\t顶层, 两侧都没有例化点, 槽位判据不给答案
"""

RTL_FILES = {
    'Leaf_3.sv': """module Leaf_3(
  input  clock,
  input  reset,
  output out
);
endmodule
""",
    'xs_leaf_core.sv': """module xs_leaf_core(
  input  clock
);
endmodule
""",
}


def build_fixture(root):
    root = pathlib.Path(root)
    for tag, files in (('g0', G0_FILES), ('g1', G1_FILES)):
        d = root / tag
        d.mkdir(parents=True)
        for n, t in files.items():
            (d / n).write_text(t)
    d = root / 'repo' / 'docs'
    d.mkdir(parents=True)
    (d / 'g1_universe.tsv').write_text(UNIVERSE_TSV)
    (d / 'g1_old_to_new_map.tsv').write_text(OLD2NEW_TSV)
    (d / 'g1_configured_universe.tsv').write_text(CONFIG_TSV)
    (d / 'ledger_normalized.tsv').write_text(NORM_TSV)
    (d / 'g1_slot_map_evidence.tsv').write_text(EVIDENCE_TSV)
    r = root / 'repo' / 'rtl' / 'sub'
    r.mkdir(parents=True)
    for n, t in RTL_FILES.items():
        (r / n).write_text(t)
    return root


class Result(object):
    def __init__(self, rc, out, err):
        self.rc, self.out, self.err = rc, out, err

    def verdict(self, check):
        """从报表里取某一条的结论。取不到 → None（说明根本没跑到报表）。"""
        for ln in self.out.splitlines():
            if ln.startswith(check + ' '):
                if '★FAIL★' in ln:
                    return 'FAIL'
                if ln.rstrip().endswith('PASS'):
                    return 'PASS'
                if ln.rstrip().endswith('SKIPPED'):
                    return 'SKIPPED'
        return None

    def reasons(self, check):
        out, grab = [], False
        for ln in self.out.splitlines():
            if ln.startswith(check + ' '):
                grab = '★FAIL★' in ln
                continue
            if grab:
                if ln.startswith('    - '):
                    out.append(ln[6:])
                else:
                    grab = False
        return out


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp(prefix='ufz-')
        self.root = build_fixture(self.tmp)

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    # ---- 运行 + 三条"没牙齿检测"的通用断言 ----------------------------
    def run_check(self, *extra):
        cmd = [sys.executable, str(CHECKER),
               '--repo', str(self.root / 'repo'),
               '--g0', str(self.root / 'g0'),
               '--g1', str(self.root / 'g1')] + list(extra)
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             universal_newlines=True)
        out, err = p.communicate()
        r = Result(p.returncode, out, err)
        # 坑 3：崩溃的退出码和"抓到了"一样，必须能区分开
        self.assertNotIn('Traceback', err,
                         '检查器崩溃了（不是"抓到了"）:\n%s' % err)
        return r

    def doc(self, name):
        return self.root / 'repo' / 'docs' / name

    def sub(self, name, old, new, expect=1):
        p = self.doc(name)
        t = p.read_text()
        self.assertIn(old, t, '夹具改写目标不存在，负测没打到点上: %r' % old)
        self.assertEqual(t.count(old), expect,
                         '夹具改写目标出现 %d 次（期望 %d），改写会误伤'
                         % (t.count(old), expect))
        p.write_text(t.replace(old, new))

    def assert_caught(self, r, check, keyword, others_ok=()):
        """恰好这一条 FAIL，原因里含预期关键字，而且不是崩溃出来的。"""
        self.assertEqual(r.verdict(check), 'FAIL',
                         '%s 没被判 FAIL。完整报表:\n%s\nstderr:\n%s'
                         % (check, r.out, r.err))
        why = '\n'.join(r.reasons(check))
        self.assertIn(keyword, why,
                      '%s 判了 FAIL 但原因里没有预期关键字 %r。实际原因:\n%s'
                      % (check, keyword, why))
        self.assertIn('FREEZE BLOCKED', r.out, '报表尾行缺失，可能没跑完')
        self.assertEqual(r.rc, 1, '应以 1 退出（1=检查未通过）')
        for c in others_ok:
            self.assertEqual(r.verdict(c), 'PASS',
                             '%s 本不该受影响，却是 %s' % (c, r.verdict(c)))


# ====================================================================
# 0. 正控：干净夹具必须五条全绿。检查器若恒失败，这条就挂——负测才有意义。
# ====================================================================
class TestCleanFixture(Base):

    def test_00_clean_fixture_passes_everything(self):
        r = self.run_check()
        self.assertEqual(r.rc, 0, '干净夹具没过:\n%s\n%s' % (r.out, r.err))
        self.assertIn('FREEZE OK', r.out)
        for c in ('C1', 'C2', 'C3', 'C4', 'C5'):
            self.assertEqual(r.verdict(c), 'PASS', '%s 在干净夹具上不是 PASS' % c)

    def test_01_each_check_individually_passes_when_clean(self):
        """每条 --only 单独跑也必须 PASS——这是后面每条负测「夹具确实走到了
        被测判据」的对照组：同一条 --only，干净=PASS / 变异=FAIL。"""
        for c in ('C1', 'C2', 'C3', 'C4', 'C5'):
            r = self.run_check('--only', c)
            self.assertEqual(r.verdict(c), 'PASS',
                             '%s 单跑干净夹具不是 PASS:\n%s' % (c, r.out))
            self.assertEqual(r.rc, 0)


# ====================================================================
# C1 OWNER_UNIQUE
# ====================================================================
class TestOwnerUnique(Base):

    def test_two_old_targets_claim_same_g1_target(self):
        # Leaf_1 已经认领 Leaf_2；把 Leaf_2 的映射也改成 Leaf_2 → 撞车
        self.sub('g1_universe.tsv', 'Leaf_2\tLeaf_3\tslot_map', 'Leaf_2\tLeaf_2\tslot_map')
        self.sub('g1_old_to_new_map.tsv', 'Leaf_2\tLeaf_3\tslot_map', 'Leaf_2\tLeaf_2\tslot_map')
        r = self.run_check('--only', 'C1')
        self.assert_caught(r, 'C1', '被 2 个 old_target 同时认领')
        self.assertIn('Leaf_2', '\n'.join(r.reasons('C1')))

    def test_one_old_target_appears_on_two_rows(self):
        p = self.doc('g1_universe.tsv')
        p.write_text(p.read_text() + 'Leaf_1\tLeaf_2\tslot_map\tREWRITE_S\tNOT_STARTED\t\n')
        r = self.run_check('--only', 'C1')
        self.assert_caught(r, 'C1', '出现在两行')

    def test_duplicate_row_is_not_excused_by_being_identical(self):
        """两行逐字相同也不算"没冲突"——C3 必须报重复行。"""
        p = self.doc('g1_universe.tsv')
        p.write_text(p.read_text() + 'Leaf_1\tLeaf_2\tslot_map\tREWRITE_S\tNOT_STARTED\t\n')
        r = self.run_check('--only', 'C3')
        self.assert_caught(r, 'C3', '逐字重复')


# ====================================================================
# C3 NO_DUPLICATE（含两份台账互相矛盾）
# ====================================================================
class TestNoDuplicate(Base):

    def test_two_ledgers_disagree_on_same_old_target(self):
        self.sub('g1_old_to_new_map.tsv', 'Leaf_1\tLeaf_2\tslot_map', 'Leaf_1\tTop\tslot_map')
        r = self.run_check('--only', 'C3')
        self.assert_caught(r, 'C3', '不一致')

    def test_old_target_sets_differ_between_ledgers(self):
        p = self.doc('g1_old_to_new_map.tsv')
        p.write_text(p.read_text() + 'Ghost\tLeaf_2\tsame_name\tyes\n')
        r = self.run_check('--only', 'C3')
        self.assert_caught(r, 'C3', 'old_target 集合不同')


# ====================================================================
# C4 NO_DANGLING
# ====================================================================
class TestNoDangling(Base):

    def test_map_to_nonexistent_g1_module(self):
        self.sub('g1_universe.tsv', 'Leaf_1\tLeaf_2\t', 'Leaf_1\tNoSuchModule\t')
        self.sub('g1_old_to_new_map.tsv', 'Leaf_1\tLeaf_2\t', 'Leaf_1\tNoSuchModule\t')
        r = self.run_check('--only', 'C4')
        self.assert_caught(r, 'C4', '没有这个模块')
        self.assertIn('NoSuchModule', '\n'.join(r.reasons('C4')))

    def test_marked_gone_but_module_really_exists(self):
        # Leaf_2 在 G1 golden 里确实存在，却标 gone_in_g1
        self.sub('g1_universe.tsv', 'Leaf_2\tLeaf_3\tslot_map', 'Leaf_2\t-\tgone_in_g1')
        self.sub('g1_old_to_new_map.tsv', 'Leaf_2\tLeaf_3\tslot_map', 'Leaf_2\t-\tremoved_in_g1')
        r = self.run_check('--only', 'C4')
        self.assert_caught(r, 'C4', '确实存在同名模块')

    def test_dash_target_without_gone_disposition(self):
        self.sub('g1_universe.tsv', 'Leaf_1\tLeaf_2\tslot_map', 'Leaf_1\t-\tslot_map')
        self.sub('g1_old_to_new_map.tsv', 'Leaf_1\tLeaf_2\tslot_map', 'Leaf_1\t-\tslot_map')
        r = self.run_check('--only', 'C4')
        self.assert_caught(r, 'C4', '没标 gone/removed')


# ====================================================================
# C2 CONSERVATION —— 无法归类的残余
# ====================================================================
class TestConservation(Base):

    def test_golden_module_missing_from_configured_universe(self):
        """G1 golden 里有、configured_universe 里既没计入也没排除 = 残余。"""
        self.sub('g1_configured_universe.tsv', 'Leaf_2\tyes\tfrom_old_306\n', '')
        r = self.run_check('--only', 'C2')
        self.assert_caught(r, 'C2', '无法归类的残余')
        self.assertIn('Leaf_2', '\n'.join(r.reasons('C2')))

    def test_rtl_module_matching_no_golden_and_no_naming_convention(self):
        d = self.root / 'repo' / 'rtl' / 'sub'
        (d / 'WeirdThing.sv').write_text('module WeirdThing(\n  input clock\n);\nendmodule\n')
        r = self.run_check('--only', 'C2')
        self.assert_caught(r, 'C2', '无法归类的残余')
        self.assertIn('WeirdThing', '\n'.join(r.reasons('C2')))

    def test_internal_core_naming_is_accepted_not_a_false_positive(self):
        """xs_ 前缀的内部件不该被误报——否则 C2 就是个只会喊狼来了的检查。"""
        d = self.root / 'repo' / 'rtl' / 'sub'
        (d / 'xs_another_core.sv').write_text(
            'module xs_another_core(\n  input clock\n);\nendmodule\n')
        r = self.run_check('--only', 'C2')
        self.assertEqual(r.verdict('C2'), 'PASS',
                         '合法内部件被误判成残余:\n%s' % '\n'.join(r.reasons('C2')))

    def test_source_column_out_of_sync_with_mapping(self):
        self.sub('g1_configured_universe.tsv', 'Leaf_3\tyes\tfrom_old_306',
                 'Leaf_3\tyes\tnew_target')
        r = self.run_check('--only', 'C2')
        self.assert_caught(r, 'C2', '按台账映射应为')

    def test_ledger_normalized_bucket_out_of_sync(self):
        self.sub('ledger_normalized.tsv', 'Leaf_3\tMAIN\t', 'Leaf_3\tAUX\t')
        r = self.run_check('--only', 'C2')
        self.assert_caught(r, 'C2', '应为 MAIN')

    def test_ledger_normalized_target_outside_universe(self):
        p = self.doc('ledger_normalized.tsv')
        p.write_text(p.read_text() + 'Nowhere\tAUX\tWORKING_PASS\tfixture\n')
        r = self.run_check('--only', 'C2')
        self.assert_caught(r, 'C2', '不在 G1 universe 里，无法归类')


# ====================================================================
# C5 SLOT_CONSISTENT —— 身份判据。C1..C4 全绿也可能整体错，这条才看得见。
# ====================================================================
class TestSlotConsistent(Base):

    def test_name_based_mapping_that_slot_criterion_refutes(self):
        """把 Leaf_1 按"同名"映射到 G1 的 Leaf_1……G1 没有 Leaf_1，
        所以改成最毒的那种：Leaf_2 → Leaf_2（同名，端口表也不同但台账不看）。
        C1/C3/C4 全都看不见，只有槽位判据能抓。"""
        self.sub('g1_universe.tsv', 'Leaf_2\tLeaf_3\tslot_map', 'Leaf_2\tLeaf_2\tsame_name')
        self.sub('g1_old_to_new_map.tsv', 'Leaf_2\tLeaf_3\tslot_map', 'Leaf_2\tLeaf_2\tsame_name')
        # 先证明这个错误确实躲过了 C4（零悬挂）——Leaf_2 在 G1 里是存在的
        r4 = self.run_check('--only', 'C4')
        self.assertEqual(r4.verdict('C4'), 'PASS',
                         '这个夹具本该躲过 C4，否则证明不了 C5 的必要性')
        r = self.run_check('--only', 'C5')
        self.assert_caught(r, 'C5', '槽位判据(site)说是 Leaf_3')

    def test_unresolved_row_without_documented_reason_is_fail_closed(self):
        """★沉默不等于通过★：槽位判不准的行，证据表里没登记留白理由就必须 FAIL。"""
        self.sub('g1_slot_map_evidence.tsv',
                 'Top\t-\tUNRESOLVED\t2\t-\t(无例化点)\t-\t顶层, 两侧都没有例化点, 槽位判据不给答案\n', '')
        r = self.run_check('--only', 'C5')
        self.assert_caught(r, 'C5', '证据表里没有登记留白理由')

    def test_evidence_table_drifted_from_recomputation(self):
        self.sub('g1_slot_map_evidence.tsv', 'Leaf_1\tLeaf_2\tsite\t2\t2',
                 'Leaf_1\tTop\tsite\t2\t2')
        r = self.run_check('--only', 'C5')
        self.assert_caught(r, 'C5', '重算是')

    def test_evidence_port_count_lies(self):
        self.sub('g1_slot_map_evidence.tsv', 'Leaf_1\tLeaf_2\tsite\t2\t2',
                 'Leaf_1\tLeaf_2\tsite\t2\t99')
        r = self.run_check('--only', 'C5')
        self.assert_caught(r, 'C5', '端口=99')

    def test_evidence_claims_unresolved_but_recomputation_answers(self):
        self.sub('g1_slot_map_evidence.tsv', 'Leaf_1\tLeaf_2\tsite\t2\t2\tTop.a\tTop.a\t',
                 'Leaf_1\t-\tUNRESOLVED\t2\t-\tTop.a\t-\t硬编的假留白')
        r = self.run_check('--only', 'C5')
        self.assert_caught(r, 'C5', '留白已经不成立')


# ====================================================================
# 解析失败 —— fail-closed，必须 2，且不许静默跳过
# ====================================================================
class TestFailClosed(Base):

    def _expect_rc2(self, r, keyword):
        self.assertEqual(r.rc, 2,
                         '解析失败必须以 2 退出（实际 %d）。stdout:\n%s\nstderr:\n%s'
                         % (r.rc, r.out, r.err))
        self.assertIn(keyword, r.err, '错误信息里没有 %r，实际:\n%s' % (keyword, r.err))
        self.assertNotIn('PASS', r.out,
                         '解析失败却打印了 PASS —— 这就是静默跳过')

    def test_golden_module_without_endmodule(self):
        p = self.root / 'g1' / 'Leaf_3.sv'
        p.write_text('module Leaf_3(\n  input clock\n);\n')      # 少 endmodule
        self._expect_rc2(self.run_check(), '没有 endmodule')

    def test_tsv_row_with_too_few_columns(self):
        p = self.doc('g1_universe.tsv')
        p.write_text(p.read_text() + 'Broken\tLeaf_2\n')
        self._expect_rc2(self.run_check(), '列数')

    def test_missing_input_file(self):
        self.doc('g1_slot_map_evidence.tsv').unlink()
        self._expect_rc2(self.run_check(), '不存在')

    def test_missing_golden_dir(self):
        r = self.run_check('--g1', str(self.root / 'nope'))
        self._expect_rc2(r, 'golden 目录不存在')

    def test_empty_ledger_is_not_a_pass(self):
        """空台账最容易"没发现问题就放行"。"""
        self.doc('g1_universe.tsv').write_text('# 只有表头\n')
        self._expect_rc2(self.run_check(), '一行数据都没有')

    def test_duplicate_module_in_golden(self):
        (self.root / 'g1' / 'Dup.sv').write_text(
            'module Leaf_3(\n  input clock\n);\nendmodule\n')
        self._expect_rc2(self.run_check(), '同名模块出现多次')


# ====================================================================
# 元测试：证明这套负测本身有牙齿
# ====================================================================
class TestHarnessHasTeeth(Base):

    def test_a_gutted_checker_fails_the_negative_tests(self):
        """把检查器换成"永远说 PASS"的假货，负测必须挂。
        这条防的是「负测其实什么都没断言」。"""
        fake = self.root / 'fake_checker.py'
        fake.write_text(
            'import sys\n'
            'print("C1 OWNER_UNIQUE   x                              PASS")\n'
            'print("FREEZE OK: 1 项全部满足")\n'
            'sys.exit(0)\n')
        self.sub('g1_universe.tsv', 'Leaf_2\tLeaf_3\tslot_map', 'Leaf_2\tLeaf_2\tslot_map')
        cmd = [sys.executable, str(fake)]
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                             universal_newlines=True)
        out, err = p.communicate()
        r = Result(p.returncode, out, err)
        with self.assertRaises(AssertionError):
            self.assert_caught(r, 'C1', '被 2 个 old_target 同时认领')

    def test_a_checker_that_always_fails_would_break_the_positive_control(self):
        """把检查器换成"永远说 FAIL"的假货，正控必须挂。
        这条防的是「检查器恒失败，所有负测虚假变绿」。"""
        fake = self.root / 'fake_checker.py'
        fake.write_text(
            'import sys\n'
            'print("C1 OWNER_UNIQUE   x                              \\u2605FAIL\\u2605 (1)")\n'
            'print("    - 什么都没查就说不行")\n'
            'print("FREEZE BLOCKED: 1/1 项不满足")\n'
            'sys.exit(1)\n')
        p = subprocess.Popen([sys.executable, str(fake)], stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, universal_newlines=True)
        out, err = p.communicate()
        r = Result(p.returncode, out, err)
        self.assertEqual(r.verdict('C1'), 'FAIL')
        # 正控要求干净夹具下 C1 = PASS，恒 FAIL 的检查器过不了
        with self.assertRaises(AssertionError):
            self.assertEqual(r.verdict('C1'), 'PASS')


if __name__ == '__main__':
    if not CHECKER.exists():
        sys.stderr.write('找不到被测脚本: %s\n' % CHECKER)
        sys.exit(2)
    unittest.main(verbosity=2)

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_proven_in_cone.py —— incl_cone 核验名单（scripts/proven_in_cone.py R1-R10）的正反测。

codex 0238 裁定 2：incore_golden_lines_proven_incl_cone 只许计「那次 run 里真被例化、
impl 侧选了可读 RTL、没被黑盒、在验证范围内」的模块；验不了的只能是候选。
一道只会放行的复核和没有复核一样，所以每条判据都要有一个**单点变异必须打红**的反例：

  正例  合成父级 run 全部证据齐 → COUNTED
        真仓 Rob@CtrlBlock(9df1c6fb0545) → R1/R2/R4/R5/R7/R8/R9 对真文件全过
  反例  R1 receipt 未跟踪 / 字节被换        R2 verdict FAILED / top 不符
        R3 parent 不是当前 proven           R4 impl 字节变了 / impl_closure 里是 golden 来源
        R5 golden sha 不符                   R6 impl 文件里没有该 module / 没过 floor
        R7 black_boxes.rpt 列了它            R8 那次 run 的 allow 把它声明为黑盒 / allow sha 不符
        R9 fm.log 只有一侧 elaborate         R10 它自己已是直接 proven（不许重复计）
        status=CANDIDATE → 只列不计          重复行 → 第二行不计
"""
import copy
import hashlib
import json
import pathlib
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'scripts'))
import proven_in_cone as P  # noqa: E402

FAILS = []
N = [0]


def ck(name, ok, detail=''):
    N[0] += 1
    print('  [%s] %s%s' % ('OK' if ok else 'FAIL', name, ('  ' + detail) if detail else ''))
    if not ok:
        FAILS.append(name)


def sha(b):
    return hashlib.sha256(b).hexdigest()


BB_CLEAN = ('Type  Design Name\n----  ----------\n'
            'i      mem_160x2\n\n       Instances : 1 of 1\n')
LOG_OK = ("Loading verilog file '/g1/golden-rtl/M.sv'\n"
          'Status:   Elaborating design M   ...  \n'
          "Loading verilog file '/tmp/sb/rtl/x/M.sv'\n"
          'Status:   Elaborating design M   ...  \n')


class Fixture:
    def __init__(self, root):
        self.root = pathlib.Path(root)
        self.rtl = b'module M(input a, output b);\n  assign b = ~a;\nendmodule\n'
        self.allow = json.dumps({'objects': [{'design': 'mem_160x2'}]}).encode()
        self.bb = BB_CLEAN
        self.log = LOG_OK
        self.receipt = {
            'top': 'P', 'verdict': 'PASS_DEAD_REF', 'provisional': False,
            'impl_worktree_dirty': False, 'impl_commit': 'c0ffee',
            'impl_closure': [{'path': 'rtl/x/M.sv', 'kind': 'repo', 'sha256': sha(self.rtl)}],
            'golden_closure': [{'path': 'golden-rtl/M.sv', 'kind': 'golden', 'sha256': 'g' * 64}],
            'proof_config': {'declarations': {'allow': {'path': 'verif/allow/P.json',
                                                        'sha256': sha(self.allow)}}},
        }
        self.proven = {'P'}
        self.written = {'M'}
        self.tracked = {'evidence/c1/P/receipt.json'}
        self.status = 'VERIFIED'
        self.extra_rows = []
        self.rsha_override = None

    def write(self):
        r = self.root
        (r / 'rtl' / 'x').mkdir(parents=True, exist_ok=True)
        (r / 'rtl' / 'x' / 'M.sv').write_bytes(self.rtl)
        d = r / 'evidence' / 'c1' / 'P'
        d.mkdir(parents=True, exist_ok=True)
        rb = json.dumps(self.receipt).encode()
        (d / 'receipt.json').write_bytes(rb)
        (d / 'black_boxes.rpt').write_text(self.bb)
        (d / 'fm.log').write_text(self.log)
        row = ['M', 'P', 'evidence/c1/P/receipt.json', self.rsha_override or sha(rb),
               'rtl/x/M.sv', sha(self.rtl0), 'golden-rtl/M.sv', 'g' * 64,
               self.status, 'synthetic']
        lines = ['# header', '\t'.join(row)] + ['\t'.join(row)] * len(self.extra_rows)
        (r / 'tbl.tsv').write_text('\n'.join(lines) + '\n')

    def run(self):
        self.write()
        allow = self.allow
        gs = lambda c, p: allow if (c, p) == ('c0ffee', 'verif/allow/P.json') else None
        return P.verified(self.root, self.proven, self.written, table=self.root / 'tbl.tsv',
                          tracked=self.tracked, git_show=gs)


def case(name, mutate, expect_counted, expect_rule=None):
    with tempfile.TemporaryDirectory(prefix='pic-', dir=str(REPO.parent)) as tmp:
        f = Fixture(tmp)
        f.rtl0 = f.rtl
        mutate(f)
        counted, notes = f.run()
        got = 'M' in counted
        why = ' | '.join('%s:%s' % (s, w) for _, s, w in notes)
        ok = got == expect_counted and (expect_rule is None or expect_rule in why)
        ck(name, ok, why)


def m_none(f):
    pass


def m_untracked(f):
    f.tracked = set()


def m_receipt_sha(f):
    f.rsha_override = '0' * 64


def m_failed(f):
    f.receipt['verdict'] = 'FAILED'


def m_top(f):
    f.receipt['top'] = 'Q'


def m_parent_not_proven(f):
    f.proven = set()


def m_impl_changed(f):
    f.rtl = f.rtl + b'// edited\n'
    f.receipt['impl_closure'][0]['sha256'] = sha(f.rtl0)


def m_impl_golden(f):
    f.receipt['impl_closure'].append({'path': 'golden-rtl/M.sv', 'kind': 'golden',
                                      'sha256': 'g' * 64})


def m_golden_sha(f):
    f.receipt['golden_closure'][0]['sha256'] = 'h' * 64


def m_no_module(f):
    f.rtl = b'module Other;\nendmodule\n'
    f.rtl0 = f.rtl
    f.receipt['impl_closure'][0]['sha256'] = sha(f.rtl)


def m_not_written(f):
    f.written = set()


def m_bb(f):
    f.bb = BB_CLEAN + 'e *    M\n\n       Instances : 1\n'


def m_allow_bb(f):
    f.allow = json.dumps({'objects': [{'design': 'M'}]}).encode()
    f.receipt['proof_config']['declarations']['allow']['sha256'] = sha(f.allow)


def m_allow_sha(f):
    f.receipt['proof_config']['declarations']['allow']['sha256'] = '1' * 64


def m_one_side(f):
    f.log = LOG_OK.split("Loading verilog file '/tmp")[0]


def m_already_direct(f):
    f.proven = {'P', 'M'}


def m_candidate(f):
    f.status = 'CANDIDATE'


def m_dup(f):
    f.extra_rows = [1]


def t_synthetic():
    case('正例 合成父级 run 证据齐 → COUNTED', m_none, True)
    case('反例 R1 receipt 未跟踪', m_untracked, False, 'R1')
    case('反例 R1 receipt 字节被换', m_receipt_sha, False, 'R1')
    case('反例 R2 verdict FAILED', m_failed, False, 'R2')
    case('反例 R2 top 不符', m_top, False, 'R2')
    case('反例 R3 parent 不是当前 proven', m_parent_not_proven, False, 'R3')
    case('反例 R4 impl 字节已改（STALE）', m_impl_changed, False, 'R4')
    case('反例 R4 impl 侧另有 golden 来源', m_impl_golden, False, 'R4')
    case('反例 R5 golden sha 不符', m_golden_sha, False, 'R5')
    case('反例 R6 impl 文件里没有该 module', m_no_module, False, 'R6')
    case('反例 R6 没过 rewritten_floor', m_not_written, False, 'R6')
    case('反例 R7 black_boxes.rpt 列了它', m_bb, False, 'R7')
    case('反例 R8 那次 run 的 allow 声明它为黑盒', m_allow_bb, False, 'R8')
    case('反例 R8 allow sha 与 receipt 不符', m_allow_sha, False, 'R8')
    case('反例 R9 fm.log 只有 ref 一侧', m_one_side, False, 'R9')
    case('反例 R10 已是直接 proven 不重复计', m_already_direct, False, 'R10')
    case('反例 CANDIDATE 只列不计', m_candidate, False, '非 VERIFIED')
    case('正例+反例 重复行只计一次', m_dup, True, '重复行')


def t_real_rob():
    """真仓：Rob 那一行对真 receipt / black_boxes.rpt / fm.log / allow@commit 复核。
    R3/R6/R10 依赖的 proven/written 集要跑 classify_rtl（分钟级），这里用最小集代入，
    真值由 rewrite_coverage.py --check（台账幂等闸）守。"""
    import subprocess
    tracked = set(subprocess.check_output(
        ['git', '-C', str(REPO), 'ls-files', 'evidence/*/receipt.json'],
        universal_newlines=True).split())
    counted, notes = P.verified(REPO, {'CtrlBlock'}, {'Rob'}, tracked=tracked)
    why = ' | '.join('%s:%s:%s' % n for n in notes)
    ck('真仓 Rob@CtrlBlock 复核全过', counted.get('Rob') == 'CtrlBlock', why)
    rows = P.load_table(REPO / P.TABLE)
    rob = [r for r in rows if r['module'] == 'Rob']
    ck('真仓 名单里 Rob 只有一行', len(rob) == 1)
    if rob:
        bad = copy.deepcopy(rob[0])
        bad['impl_sha256'] = '0' * 64
        w = P.verify_row(bad, REPO, tracked, {'CtrlBlock'}, {'Rob'})
        ck('真仓 反例 改 impl sha → R4 打红', bool(w) and w.startswith('R4'), str(w))
        bad = copy.deepcopy(rob[0])
        bad['module'] = 'NewRobDeqPtrWrapper'
        w = P.verify_row(bad, REPO, tracked, {'CtrlBlock'}, {'NewRobDeqPtrWrapper'})
        ck('真仓 反例 impl 侧用 golden 的 Rob child 不许冒充', bool(w), str(w))


def main():
    t_synthetic()
    t_real_rob()
    print('test_proven_in_cone: %d 条，失败 %d' % (N[0], len(FAILS)))
    return 1 if FAILS else 0


if __name__ == '__main__':
    sys.exit(main())

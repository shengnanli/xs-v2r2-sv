#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""test_cv_recursion.py —— impl 侧挂 golden 的子证书必须**自身 current-valid**（codex 0244 A 窄修）的正反测。

# 守的是什么

`validate_impl_golden_certified` 原先对 impl 闭包里挂的 golden 子模块，只验子证书格式 / verdict /
golden 字节，再递归看子证书的 golden 依赖——**没核子证书自身是否 current-valid**：子 RTL、子执行脚本
（per-target 配置）变了照样放行；递归靠 `_seen`「开始访问即当通过」，环也被静默吞掉。
修后：每条证书边都交给公共核心 `validate_certificate_current`，访问状态与 green_child 嵌套共用：
visiting 栈判环、done-ok memo 只缓存完整通过。

夹具：自带 git 历史的最小仓库；每个目标 X 有 rtl/X.sv、golden-rtl/X.sv、verif/ut/X/Makefile、证书；
「X 的 impl 闭包挂 golden-rtl/Y.sv」= 一条 X→Y 证书边（按名字，不按 sha，所以能造环）。
判据本体 = proof_certificate.validate_certificate_current(parent, 'T', doc)。

  P1 菱形 T→{A,B}→C（合法共享子依赖）       -> 放行，且 C 只真正判一次（done-ok 命中）
  N1 子 RTL 变（rtl/C.sv）                   -> 拒（impl_golden_not_current … closure_changed:C）
  N2 子执行脚本变（C 独有的 per-target tcl） -> 拒（impl_golden_not_current … script_closure_changed:C）
  N3 递归成环 T→A→B→A                        -> 拒（impl_golden_cycle）
  N4 自环 T→A→A                              -> 拒（impl_golden_cycle）
  元负例 SABOTAGE_CVR=1：把子证书 current-valid 判定换成无条件放行 -> N1 / N2 必须转绿（负测有分辨力）

用法:
    python3 scripts/test_cv_recursion.py
    SABOTAGE_CVR=1 python3 scripts/test_cv_recursion.py
"""
import hashlib
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import proof_certificate as PC                              # noqa: E402
import fm_target_universe as FTU                            # noqa: E402

SABOTAGE = os.environ.get('SABOTAGE_CVR') == '1'
CANON = 'G1-fixture-canonical-cvrecur-0000000000000000000000000000000000'
FM_EQ = '# fake fm_eq.tcl\n'
EMIT = '# fake emit\n'
TARGETS = ['A', 'B', 'C', 'T']
TCFG = 'verif/fm_target_config'
FAILS, N, TMP = [], [0], []


def sha(b):
    return hashlib.sha256(b).hexdigest()


def sh(cwd, *a):
    p = subprocess.run(list(a), cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if p.returncode:
        raise RuntimeError(p.stdout.decode())
    return p.stdout.decode().strip()


def ck(name, got, want):
    """want=True ⇒ 必须放行；want=str 或 tuple(str) ⇒ 必须拒且原因串含全部关键字。"""
    N[0] += 1
    if want is True:
        ok = got is True
    else:
        kws = (want,) if isinstance(want, str) else want
        ok = isinstance(got, str) and all(k in got for k in kws)
    print('  [%s] %-44s %s' % ('OK' if ok else 'FAIL', name, str(got)[:150]))
    if not ok:
        FAILS.append(name)
    return ok


class Tree(object):
    """edges={X: [Y, ...]}：X 的 impl 闭包挂 golden-rtl/Y.sv。
    tcfg=[X, ...]：X 有自己的 per-target 配置 verif/fm_target_config/X.tcl（记进 X 的脚本闭包）。
    post=fn(tree)：证书提交之后的 C3 突变。"""

    def __init__(self, edges, tcfg=(), post=None):
        self.root = pathlib.Path(tempfile.mkdtemp(prefix='xsv2-cvr-'))
        TMP.append(self.root)
        self.repo_dir = self.root / 'repo'
        self.g1 = self.root / 'G1'
        (self.g1 / 'golden-rtl').mkdir(parents=True)
        self.repo_dir.mkdir()
        self.gold = {t: ('module %s; endmodule // golden\n' % t).encode() for t in TARGETS}
        for t, b in self.gold.items():
            (self.g1 / 'golden-rtl' / ('%s.sv' % t)).write_bytes(b)
        (self.g1 / 'MANIFEST.tsv').write_text(
            ''.join('%s\t%d\t%s.sv\n' % (sha(b), len(b), t) for t, b in self.gold.items()))
        self.w('scripts/fm_eq.tcl', FM_EQ)
        self.w('scripts/sidecar/fm_native_emit.tcl', EMIT)
        self.w('scripts/ut_common.mk', '# placeholder\n')
        for t in TARGETS:
            self.w('rtl/%s.sv' % t, 'module %s; endmodule\n' % t)
            self.w('verif/ut/%s/Makefile' % t, 'MODULE = %s\nFM_VARIANTS = %s\n' % (t, t))
        for t in tcfg:
            self.w('%s/%s.tcl' % (TCFG, t), '# per-target config %s\n' % t)
        self.git_commit('C1')
        self.c1 = self.head()
        for t in TARGETS:
            self.cert(t, edges.get(t, []), t in tcfg)
        pol = {'schema': PC.POLICY_SCHEMA, 'freeze_commit': None,
               'qualifying_verdicts': ['SUCCEEDED', 'PASS_DEAD_REF'],
               'tool': {'name': 'fm_shell', 'version': 'V', 'build': 'B'},
               'pinned_entry_appvars': {'hdlin_unresolved_modules': 'black_box', 'hdlin_interface_only': ''},
               'script_closure_files': ['scripts/fm_eq.tcl', 'scripts/sidecar/fm_native_emit.tcl'],
               'target_config_dir': TCFG, 'g1_canonical_id': CANON}
        self.w(PC.POLICY_PATH, json.dumps(pol, indent=1, sort_keys=True) + '\n')
        self.git_commit('C2')
        if post:
            post(self)
            self.git_commit('C3')
        self.parent = self.head()
        self.repo = PC.Repo(self.repo_dir)

    def w(self, rel, text):
        p = self.repo_dir / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def head(self):
        return sh(self.repo_dir, 'git', 'rev-parse', 'HEAD')

    def git_commit(self, msg):
        if not (self.repo_dir / '.git').exists():
            sh(self.repo_dir, 'git', 'init', '-q')
            sh(self.repo_dir, 'git', 'config', 'user.email', 'f@t')
            sh(self.repo_dir, 'git', 'config', 'user.name', 'f')
        sh(self.repo_dir, 'git', 'add', '-A')
        sh(self.repo_dir, 'git', 'commit', '-q', '-m', msg)

    def cert(self, t, kids, has_tcfg):
        impl = [{'path': 'rtl/%s.sv' % t, 'kind': 'repo',
                 'sha256': sha(('module %s; endmodule\n' % t).encode())}]
        for k in kids:
            impl.append({'path': 'golden-rtl/%s.sv' % k, 'kind': 'golden', 'sha256': sha(self.gold[k])})
        golden = [{'path': 'golden-rtl/%s.sv' % t, 'kind': 'golden', 'sha256': sha(self.gold[t])}]
        scripts = [{'path': 'scripts/fm_eq.tcl', 'kind': 'repo', 'sha256': sha(FM_EQ.encode())},
                   {'path': 'scripts/sidecar/fm_native_emit.tcl', 'kind': 'repo', 'sha256': sha(EMIT.encode())}]
        if has_tcfg:
            p = '%s/%s.tcl' % (TCFG, t)
            scripts.append({'path': p, 'kind': 'repo', 'sha256': sha((self.repo_dir / p).read_bytes())})
        cfg = {'fm_mode': 'signoff-strict', 'declarations': {},
               'entry_appvars_readback': {'hdlin_unresolved_modules': 'black_box', 'hdlin_interface_only': ''}}
        native = {'native_verdict': 'SUCCEEDED', 'stats': {'passing': 1}}
        doc = {'schema': PC.CERT_SCHEMA, 'target': t, 'variant': t, 'ut_dir': t, 'verdict': 'SUCCEEDED',
               'proof_mode': 'signoff-strict', 'provisional': False, 'impl_worktree_dirty': False,
               'impl_commit': self.c1, 'proof_commit': self.c1, 'proof_worktree_digest': sha(b'w'),
               'g1_canonical_id': CANON, 'g1_manifest_sha256': sha((self.g1 / 'MANIFEST.tsv').read_bytes()),
               'run_id': t, 'tool': {'name': 'fm_shell', 'version': 'V', 'build': 'B', 'fm_shell_rc': 0},
               'proof_config': cfg, 'proof_config_sha256': PC.canon_digest(cfg),
               'input_closure': {'golden': golden, 'impl': impl, 'golden_sha256': PC.closure_digest(golden),
                                 'impl_sha256': PC.closure_digest(impl), 'repo_impl_files': 1},
               'script_closure': {'entries': scripts, 'sha256': PC.closure_digest(scripts)},
               'native_facts_sha256': sha(b'n'), 'native_result': native,
               'result_sha256': PC.canon_digest({'verdict': 'SUCCEEDED', 'native_result': native}),
               'receipt_sha256': sha(b'r'), 'evidence_retention': 'attestation_only', 'evidence_archive': None,
               'reproduce': {'command': 'x'}, 'generated_at': '2026-10-23T00:00:00Z',
               'generator': {'script': 'scripts/make_proof_certificate.py', 'version': 1,
                             'source_evidence_dir': 'evidence/x/%s' % t}}
        self.w('verif/proof_certificates/%s.json' % t, json.dumps(doc, indent=1, sort_keys=True) + '\n')

    def judge(self, root='T'):
        pol, perr = PC.load_policy(self.repo, self.parent)
        if perr:
            return perr
        tmap, unres = FTU.targets_at(str(self.repo_dir), self.parent)
        doc, _b, err = PC.load_certificate(self.repo, self.parent, root)
        if err:
            return err
        return PC.validate_certificate_current(self.repo, self.parent, root, doc, expect_canonical=CANON,
                                               policy=pol, fm_targets=tmap, fm_targets_unresolved=unres,
                                               g1_root=str(self.g1))


DIAMOND = {'T': ['A', 'B'], 'A': ['C'], 'B': ['C']}


def main():
    if shutil.which('git') is None:
        print('SKIP: 无 git')
        return 2
    if SABOTAGE:
        PC._validate_cert_node = lambda repo, pc, target, gdoc, *a, **k: (True, gdoc.get('external_dependency'))
        print('=== SABOTAGE_CVR：子证书 current-valid 判定被换成无条件放行，N1 / N2 应当转绿 ===')

    # P1：菱形，且 C 只被公共核心判一次（第二条边走 done-ok 缓存）
    calls = []
    real = PC.validate_certificate_current

    def counting(repo, pc, child, doc, **kw):
        calls.append(child)
        return real(repo, pc, child, doc, **kw)
    PC.validate_certificate_current = counting
    try:
        r = Tree(DIAMOND).judge()
    finally:
        PC.validate_certificate_current = real
    ck('P1 菱形共享子依赖 -> 放行', r, True)
    if not SABOTAGE:
        ck('P1b 共享子 C 只判一次（done-ok 命中）',
           True if calls.count('C') == 1 and calls.count('A') == 1 and calls.count('B') == 1
           else 'calls=%r' % calls, True)

    ck('N1 子 RTL 变 -> 拒',
       Tree(DIAMOND, post=lambda tr: tr.w('rtl/C.sv', 'module C; wire x; endmodule\n')).judge(),
       ('impl_golden_not_current', 'closure_changed:C'))
    ck('N2 子执行脚本变 -> 拒',
       Tree(DIAMOND, tcfg=['C'],
            post=lambda tr: tr.w('%s/C.tcl' % TCFG, '# per-target config C CHANGED\n')).judge(),
       ('impl_golden_not_current', 'script_closure_changed:C'))
    ck('N3 递归成环 T->A->B->A -> 拒',
       Tree({'T': ['A'], 'A': ['B'], 'B': ['A']}).judge(), 'impl_golden_cycle:T->A->B->A')
    ck('N4 自环 T->A->A -> 拒', Tree({'T': ['A'], 'A': ['A']}).judge(), 'impl_golden_cycle:T->A->A')
    # 对照：N2 的突变只碰 C 自己的脚本 —— 单独判 C 也必须拒，单独判不含 C 的根必须放行（突变确实局部）
    t2 = Tree(DIAMOND, tcfg=['C'], post=lambda tr: tr.w('%s/C.tcl' % TCFG, '# changed\n'))
    ck('N2b 同一突变下 C 自身 -> 拒', t2.judge('C'), 'script_closure_changed:C')

    for d in TMP:
        shutil.rmtree(str(d), ignore_errors=True)
    expect_n = 6 if SABOTAGE else 7
    print('test_cv_recursion: %d 条，失败 %d %s' % (N[0], len(FAILS), FAILS if FAILS else ''))
    if N[0] != expect_n:
        print('★断言条数 %d != %d —— 有用例被跳过，判失败★' % (N[0], expect_n))
        return 1
    if SABOTAGE:
        if not {'N1 子 RTL 变 -> 拒', 'N2 子执行脚本变 -> 拒'} <= set(FAILS):
            print('★★ SABOTAGE 没被抓到 —— N1 / N2 没有分辨力，判失败 ★★')
            return 1
        print('SABOTAGE 被抓到（N1 / N2 如期变红）：本次的"红"是预期结果')
        return 0
    return 1 if FAILS else 0


if __name__ == '__main__':
    sys.exit(main())

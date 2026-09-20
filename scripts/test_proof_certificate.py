#!/usr/bin/env python3
"""证明证书机制（codex 0157 D57）的负测。

# 为什么这份测试写成这样

本工程有多次「测试假通过」的教训：
  * 断言被**更早的门**挡掉 —— 三条负测全被 dirty 门拦下，测试却报 PASS；
  * VCS 对 `$fatal` 返回**退出码 0**；
  * 反测崩溃的 traceback 退出码（1）与「抓到了」的退出码（1）长得一模一样。

所以这里每条负测都遵守三条纪律：

  A. **配对的阳性对照**。每条负测都先跑一遍"只差这一处突变"的干净夹具，
     必须返回 True。阳性对照一旦不过，就说明夹具根本没走到被测判据，
     测试**判 FAIL 并明说"fixture never reached the judgement"**，而不是
     偷偷把"被更早的门拦下"当成"抓到了"。
  B. **断言具体原因关键字**，不是"只要不是 True 就算过"。
  C. **异常算 FAIL 不算 PASS**；并且末尾断言**实际跑过的断言条数**，
     少跑一条（被 skip / 被 return 提前退出）就整体非零退出。

# 夹具是构造的，被测代码是真的

这些夹具（临时 git 仓库、假 RTL、假证书）全部是**构造**出来的 —— FM 冻结中，
真证书要等 freeze commit 之后由 integrator 从 clean official run 生成。
但被测的判据全部是**生产代码本体**：`proof_certificate.validate_document` /
`validate_child_certificate` / `fm_verdict.verdict` / `make_proof_certificate.build_certificate`。
唯一一处用到真实数据的是端到端那条：它喂的是仓库里 tracked 的真实 Formality 日志
`evidence/14e6b7798157/WrBypass/fm.log`。

用法: python3 scripts/test_proof_certificate.py [-v]
"""
import hashlib
import importlib.util
import json
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
HOME = HERE.parent
sys.path.insert(0, str(HERE))

import proof_certificate as PC                              # noqa: E402
import make_proof_certificate as MPC                        # noqa: E402

_spec = importlib.util.spec_from_file_location('fm_verdict', HERE / 'fm_verdict.py')
FV = importlib.util.module_from_spec(_spec)
sys.modules['fm_verdict'] = FV
_spec.loader.exec_module(FV)

REAL_FM_LOG = HOME / 'evidence' / '14e6b7798157' / 'WrBypass' / 'fm.log'

VERBOSE = '-v' in sys.argv
PASSES, FAILURES, NOTES = [], [], []
_TMPDIRS = []

#: 实际会跑到的断言条数。少一条 = 有测试被跳过/提前 return，整体判失败。
#: 改测试时必须同步改这个数字（这正是它的用途：逼你意识到少跑了）。
EXPECTED_ASSERTIONS = 77


def check(name, cond, detail=''):
    if cond:
        PASSES.append(name)
        if VERBOSE:
            print('  ok   %s' % name)
    else:
        FAILURES.append('%s: %s' % (name, detail))
        print('  FAIL %s: %s' % (name, detail))


def expect_reason(name, got, keyword):
    """负测的标准断言：必须**失败**，且失败原因含预期关键字。

    `got is True` 分开报，因为"放行了"和"以别的原因失败了"是两种完全不同的 bug。
    """
    if got is True:
        check(name, False, 'ACCEPTED（放行了！）—— 期望含关键字 %r' % keyword)
        return
    ok = isinstance(got, str) and keyword in got
    check(name, ok, 'reason=%r 不含期望关键字 %r' % (got, keyword))
    if ok and VERBOSE:
        print('       reason: %s' % got)
    NOTES.append('%-52s -> %s' % (name, got))


# ---------------------------------------------------------------------------
# 夹具
# ---------------------------------------------------------------------------
FM_EQ_TCL = '# fake fm_eq.tcl for fixture\nputs "hi"\n'
EMIT_TCL = '# fake fm_native_emit.tcl for fixture\n'
CHILD_SRC = {
    'rtl/common/xs_child_core.sv': 'module xs_child_core; endmodule\n',
    'rtl/common/ChildLeaf.sv': 'module ChildLeaf; xs_child_core u_core(); endmodule\n',
}
GOLDEN_FILES = {'ChildLeaf.sv': 'module ChildLeaf; endmodule // golden\n'}

CANON = 'G1-fixture-canonical-0000000000000000000000000000000000000000'


def sh(cwd, *args):
    p = subprocess.run(list(args), cwd=str(cwd), stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT)
    if p.returncode != 0:
        raise RuntimeError('git 失败: %s\n%s' % (' '.join(args),
                                                p.stdout.decode('utf-8', 'replace')))
    return p.stdout.decode('utf-8', 'replace').strip()


def _sha(b):
    return hashlib.sha256(b).hexdigest()


class Fixture(object):
    """一个自带 git 历史的最小仓库 + 一份 G1 目录。

    历史：
      C1  RTL / 脚本 / Makefile / child 的 allow 声明   ← 证书绑定在这个 commit（= freeze commit）
      C2  加入 POLICY.json / ChildLeaf.json / 父 allow  ← 父 proof 在这个 commit 上跑
      C3  （可选）突变，用来测"child 源在父 commit 下变了"
    """

    def __init__(self, cert_mutate=None, policy_mutate=None, allow_mutate=None,
                 commit_cert=True, child_is_fm_target=True, post_commit=None,
                 golden_mutate=None):
        self.root = pathlib.Path(tempfile.mkdtemp(prefix='xsv2-certtest-'))
        _TMPDIRS.append(self.root)
        self.repo_dir = self.root / 'repo'
        self.g1 = self.root / 'G1-canonical'
        self.repo_dir.mkdir()
        (self.g1 / 'golden-rtl').mkdir(parents=True)
        for n, t in GOLDEN_FILES.items():
            (self.g1 / 'golden-rtl' / n).write_text(t)
        (self.g1 / 'CANONICAL_ID.txt').write_text(CANON + '\n')
        man = ''.join('%s\t%d\t%s\n' % (_sha(t.encode()), len(t), n)
                      for n, t in GOLDEN_FILES.items())
        if golden_mutate:
            man = golden_mutate(man)
        (self.g1 / 'MANIFEST.tsv').write_text(man)

        # ---- C1 ----
        self._w('scripts/fm_eq.tcl', FM_EQ_TCL)
        self._w('scripts/sidecar/fm_native_emit.tcl', EMIT_TCL)
        for p, t in CHILD_SRC.items():
            self._w(p, t)
        self._w('verif/ut/ChildLeaf/Makefile',
                'MODULE = ChildLeaf\nFM_VARIANTS = %s\n'
                % ('ChildLeaf' if child_is_fm_target else 'SomethingElse'))
        self._w('verif/ut/ParentAsm/Makefile', 'MODULE = ParentAsm\nFM_VARIANTS = ParentAsm\n')
        # ★必须有这个文件★（2026-09-13）：D70 之后 target 全集改由 **make 引擎**权威求值，
        # 而 fm_target_universe.targets_at_make() 会 `git archive` 出含 scripts/ut_common.mk
        # 的临时树；夹具缺它 → MakeUnavailable → 退回 regex 并把原因记进 unresolved →
        # 判定走保守分支 `..._target_universe_unresolved` 而非 `..._not_fm_target`。
        # 两者都是 fail-closed 的拒绝，但前者是「判不出」、后者是「判定它不是 target」——
        # 本测试要守的正是后者那条判据，夹具不能让它降级。（真实仓库上实测
        # targets=272 / unresolved=0，所以这只是夹具上下文问题，不是功能退化。）
        self._w('scripts/ut_common.mk',
                '# 夹具占位：make 引擎 git archive 需要此文件存在\n')
        self._w('verif/dead_ref/ChildLeaf.json',
                json.dumps({'entries': [{'ref_path': 'r:/WORK/ChildLeaf/dead'}]}) + '\n')
        sh(self.repo_dir, 'git', 'init', '-q')
        sh(self.repo_dir, 'git', 'config', 'user.email', 'fixture@test')
        sh(self.repo_dir, 'git', 'config', 'user.name', 'fixture')
        sh(self.repo_dir, 'git', 'add', '-A')
        sh(self.repo_dir, 'git', 'commit', '-q', '-m', 'C1')
        self.c1 = sh(self.repo_dir, 'git', 'rev-parse', 'HEAD')

        # ---- 证书（绑定 C1） ----
        cert = self._build_cert()
        if cert_mutate:
            cert = cert_mutate(cert) or cert
        self.cert_body = json.dumps(cert, ensure_ascii=False, indent=1, sort_keys=True) + '\n'
        self.cert_sha = _sha(self.cert_body.encode('utf-8'))
        self.cert = cert
        self._w('verif/proof_certificates/ChildLeaf.json', self.cert_body)

        pol = {
            'schema': PC.POLICY_SCHEMA,
            'freeze_commit': self.c1,
            'qualifying_verdicts': ['SUCCEEDED', 'PASS_DEAD_REF'],
            'tool': {'name': 'fm_shell', 'version': 'V-2023.12-SP3', 'build': '8868332'},
            'pinned_entry_appvars': {'hdlin_unresolved_modules': 'black_box'},
            'script_closure_files': ['scripts/fm_eq.tcl',
                                     'scripts/sidecar/fm_native_emit.tcl'],
            'target_config_dir': 'verif/fm_target_config',
            'g1_canonical_id': CANON,
        }
        if policy_mutate:
            pol = policy_mutate(pol) or pol
        self.policy_body = json.dumps(pol, ensure_ascii=False, indent=1, sort_keys=True) + '\n'
        self._w('verif/proof_certificates/POLICY.json', self.policy_body)

        allow = {
            'schema': 'xs-v2-sv-allow-v1', 'target': 'ParentAsm', 'baseline': self.c1,
            'objects': [
                {'side': 'r', 'design': 'ChildLeaf', 'path': 'r:/WORK/ParentAsm/u_child',
                 'class': 'green_child', 'child_target': 'ChildLeaf',
                 'certificate_sha256': self.cert_sha},
                {'side': 'i', 'design': 'ChildLeaf', 'path': 'i:/WORK/ParentAsm/u_child',
                 'class': 'green_child', 'child_target': 'ChildLeaf',
                 'certificate_sha256': self.cert_sha},
            ],
        }
        if allow_mutate:
            allow = allow_mutate(allow) or allow
        self.allow = allow
        self._w('verif/allow/ParentAsm.json',
                json.dumps(allow, ensure_ascii=False, indent=1, sort_keys=True) + '\n')

        # ---- C2 ----
        if commit_cert:
            sh(self.repo_dir, 'git', 'add', '-A')
        else:
            # 证书只躺在工作树里，没进 commit —— 专测"本地放一份就想转绿"
            sh(self.repo_dir, 'git', 'add', 'verif/proof_certificates/POLICY.json',
               'verif/allow/ParentAsm.json')
        sh(self.repo_dir, 'git', 'commit', '-q', '-m', 'C2')
        self.c2 = sh(self.repo_dir, 'git', 'rev-parse', 'HEAD')

        # ---- C3（可选突变）----
        if post_commit:
            post_commit(self)
            sh(self.repo_dir, 'git', 'add', '-A')
            sh(self.repo_dir, 'git', 'commit', '-q', '-m', 'C3')
            self.c3 = sh(self.repo_dir, 'git', 'rev-parse', 'HEAD')
            self.parent_commit = self.c3
        else:
            self.c3 = None
            self.parent_commit = self.c2
        self.repo = PC.Repo(self.repo_dir)

    def _w(self, rel, text):
        p = self.repo_dir / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def _build_cert(self):
        impl = [{'path': p, 'kind': 'repo', 'sha256': _sha(t.encode())}
                for p, t in sorted(CHILD_SRC.items())]
        gold = [{'path': 'golden-rtl/%s' % n, 'kind': 'golden', 'sha256': _sha(t.encode())}
                for n, t in sorted(GOLDEN_FILES.items())]
        scripts = [
            {'path': 'scripts/fm_eq.tcl', 'kind': 'repo', 'sha256': _sha(FM_EQ_TCL.encode())},
            {'path': 'scripts/sidecar/fm_native_emit.tcl', 'kind': 'repo',
             'sha256': _sha(EMIT_TCL.encode())},
        ]
        dr_path = 'verif/dead_ref/ChildLeaf.json'
        dr_bytes = (self.repo_dir / dr_path).read_bytes()
        cfg = {
            'fm_mode': 'signoff-strict',
            'fm_allowlist_numeric_prefilter': '0',
            'verify_matched_unread_compare_points': 'false',
            'pin_scripts': {},
            'declarations': {'dead_ref': {'path': dr_path, 'sha256': _sha(dr_bytes)}},
            'entry_appvars_readback': {'hdlin_unresolved_modules': 'black_box',
                                       'hdlin_interface_only': ''},
        }
        native = {'native_verdict': 'SUCCEEDED',
                  'stats': {'passing': 124, 'failing': 0, 'unverified': 0,
                            'aborted': 0, 'unread_notcompared': 0},
                  'unmatched': {'compare_ref': 0, 'compare_impl': 0}}
        man_sha = _sha((self.g1 / 'MANIFEST.tsv').read_bytes())
        doc = {
            'schema': PC.CERT_SCHEMA, 'target': 'ChildLeaf', 'variant': 'ChildLeaf',
            'ut_dir': 'ChildLeaf', 'verdict': 'SUCCEEDED', 'proof_mode': 'signoff-strict',
            'provisional': False, 'impl_worktree_dirty': False,
            'impl_commit': self.c1, 'proof_commit': self.c1,
            'proof_worktree_digest': _sha(b'fixture-worktree'),
            'g1_canonical_id': CANON, 'g1_manifest_sha256': man_sha,
            'run_id': 'ChildLeaf-fixture', 'tool': {
                'name': 'fm_shell', 'version': 'V-2023.12-SP3',
                'platform': 'linux64', 'build': '8868332', 'fm_shell_rc': 0},
            'proof_config': cfg, 'proof_config_sha256': PC.canon_digest(cfg),
            'input_closure': {
                'golden': gold, 'impl': impl,
                'golden_sha256': PC.closure_digest(gold),
                'impl_sha256': PC.closure_digest(impl),
                'repo_impl_files': len(impl)},
            'script_closure': {'entries': scripts, 'sha256': PC.closure_digest(scripts)},
            'native_facts_sha256': _sha(json.dumps(native).encode()),
            'native_result': native,
            'result_sha256': PC.canon_digest({'verdict': 'SUCCEEDED',
                                              'native_result': native}),
            'receipt_sha256': _sha(b'fixture-receipt'),
            'evidence_retention': 'attestation_only', 'evidence_archive': None,
            'reproduce': {'command': 'PROOF_COMMIT=%s scripts/run_proof.sh ChildLeaf ChildLeaf'
                                     % self.c1},
            'generated_at': '2026-09-13T00:00:00Z',
            'generator': {'script': MPC.GENERATOR_PATH, 'version': 1,
                          'source_evidence_dir': 'evidence/fixture/ChildLeaf'},
        }
        return doc

    def judge(self, declared_sha=None, parent_commit=None, canonical=CANON):
        """跑被测判据本体。"""
        pol, perr = PC.load_policy(self.repo, parent_commit or self.parent_commit)
        if perr:
            return perr
        import fm_target_universe as FTU
        tmap, unresolved = FTU.targets_at(str(self.repo_dir),
                                          parent_commit or self.parent_commit)
        sha = self.cert_sha if declared_sha is None else declared_sha
        if declared_sha is None:
            # 用 allow 里真正写着的那个值（突变过 allow 的夹具要走它）
            for o in self.allow['objects']:
                if o.get('class') == 'green_child':
                    sha = o.get('certificate_sha256')
                    break
        return PC.validate_child_certificate(
            self.repo, parent_commit or self.parent_commit, 'ChildLeaf', sha,
            expect_canonical=canonical, policy=pol, fm_targets=tmap,
            fm_targets_unresolved=unresolved, g1_root=str(self.g1))


def control(name, **kw):
    """阳性对照：同一套夹具、不加突变，必须放行。不放行 = 夹具没走到判据。"""
    f = Fixture(**kw)
    r = f.judge()
    if r is not True:
        check(name + '[CONTROL]', False,
              'fixture never reached the judgement —— 干净夹具就被拒了: %r' % r)
        return None
    check(name + '[CONTROL]', True)
    return f


# ===========================================================================
# 一、schema 层负测
# ===========================================================================
def test_schema_missing_field():
    f = Fixture()
    for field in ('impl_commit', 'script_closure', 'input_closure', 'tool'):
        doc = json.loads(json.dumps(f.cert))
        doc.pop(field)
        errs = PC.validate_document(doc)
        hit = [e for e in errs if e.startswith('cert_missing_field:' + field)]
        check('schema:missing_field:%s' % field, bool(hit),
              'errs=%r' % errs[:4])
        NOTES.append('%-52s -> %s' % ('schema:missing_field:' + field,
                                      hit[0] if hit else errs[:2]))
    # 阳性对照：不删字段必须干净
    check('schema:missing_field[CONTROL]', PC.validate_document(f.cert) == [],
          'errs=%r' % PC.validate_document(f.cert)[:4])


def test_schema_archive_claim_without_hash():
    """★D57 明写：无 archive 时证书只可作可复跑 attestation，
    不得声称 clean clone 含完整历史原件。★"""
    f = Fixture()
    doc = json.loads(json.dumps(f.cert))
    doc['evidence_retention'] = 'archived'          # 声称有原件
    doc['evidence_archive'] = None                  # 却没有 archive hash
    errs = PC.validate_document(doc)
    expect_reason('schema:archive_claim_without_hash',
                  errs[0] if errs else True, 'cert_archive_claim_without_hash')

    doc2 = json.loads(json.dumps(f.cert))
    doc2['evidence_retention'] = 'archived'
    doc2['evidence_archive'] = {'sha256': 'zz', 'name': 'a.tar', 'size': 1}
    errs2 = PC.validate_document(doc2)
    expect_reason('schema:archive_claim_bad_hash',
                  errs2[0] if errs2 else True, 'cert_archive_claim_without_hash')

    doc3 = json.loads(json.dumps(f.cert))
    doc3['evidence_archive'] = {'sha256': 'a' * 64, 'name': 'a.tar', 'size': 1}
    errs3 = PC.validate_document(doc3)                # retention 仍是 attestation_only
    expect_reason('schema:archive_hash_without_claim',
                  errs3[0] if errs3 else True, 'cert_archive_hash_without_claim')

    doc4 = json.loads(json.dumps(f.cert))
    doc4['evidence_retention'] = 'archived'
    doc4['evidence_archive'] = {'sha256': 'b' * 64, 'name': 'ev.tar.zst', 'size': 99}
    check('schema:archive_claim_with_hash[CONTROL]', PC.validate_document(doc4) == [],
          'errs=%r' % PC.validate_document(doc4)[:3])


def test_schema_self_digest():
    f = Fixture()
    doc = json.loads(json.dumps(f.cert))
    doc['input_closure']['impl'][0]['sha256'] = 'c' * 64   # 改闭包但不改摘要
    errs = PC.validate_document(doc)
    expect_reason('schema:closure_vs_digest_mismatch',
                  errs[0] if errs else True,
                  'cert_self_digest_mismatch:input_closure.impl_sha256')

    # 闭包里一条 repo 条目都没有 = 没法在别的 commit 上复算 = 没有组合性保证。
    # 诚实地写 repo_impl_files=0 → 字段闸拦下。
    doc2 = json.loads(json.dumps(f.cert))
    doc2['input_closure']['impl'] = [
        e for e in doc2['input_closure']['impl'] if e['kind'] != 'repo']
    doc2['input_closure']['impl_sha256'] = PC.closure_digest(doc2['input_closure']['impl'])
    doc2['input_closure']['repo_impl_files'] = 0
    errs2 = PC.validate_document(doc2)
    expect_reason('schema:no_repo_closure_entry_honest', errs2[0] if errs2 else True,
                  'cert_bad_field:input_closure.repo_impl_files')
    # 谎报 repo_impl_files（想骗过上面那条）→ 自洽闸拦下。
    doc3 = json.loads(json.dumps(doc2))
    doc3['input_closure']['repo_impl_files'] = 2
    errs3 = PC.validate_document(doc3)
    expect_reason('schema:no_repo_closure_entry_lied', errs3[0] if errs3 else True,
                  'cert_self_digest_mismatch:input_closure.repo_impl_files')


# ===========================================================================
# 二、D57 五条的负测（全部配阳性对照）
# ===========================================================================
def test_cert_not_in_commit():
    """★最容易被绕的一条：本地放一份证书就想转绿。★"""
    f = control('cert_in_commit')
    if f is None:
        return
    g = Fixture(commit_cert=False)
    # 证书文件确实躺在工作树里（不是"忘了写"）
    check('not_in_commit:file_exists_in_worktree',
          (g.repo_dir / 'verif/proof_certificates/ChildLeaf.json').exists(),
          '夹具没写出证书文件，测的就不是这条了')
    expect_reason('D57-1:certificate_not_in_commit', g.judge(),
                  'green_child_certificate_not_in_commit')


def test_cert_sha_binding():
    f = control('cert_sha_binding')
    if f is None:
        return
    expect_reason('D57-1:certificate_sha_mismatch', f.judge(declared_sha='d' * 64),
                  'green_child_certificate_sha_mismatch')
    g = Fixture(allow_mutate=lambda a: (
        [o.pop('certificate_sha256', None) for o in a['objects']], a)[1])
    expect_reason('D57-1:declaration_without_certificate_sha256', g.judge(),
                  'green_child_declaration_without_certificate_sha256')


def test_verdict_not_qualifying():
    for bad in ('PARTIAL', 'SHADOW_CHECK', 'FAILED', 'WAIVED', 'DIAGNOSTIC'):
        g = Fixture(cert_mutate=lambda d, b=bad: d.update({'verdict': b}) or _refresh(d))
        expect_reason('D57-2:verdict_not_qualifying:%s' % bad, g.judge(),
                      'green_child_verdict_not_qualifying')
    h = control('verdict_qualifying')
    if h is None:
        return


def _refresh(d):
    """突变 verdict 后把自洽摘要重算——否则会先被 schema 自洽闸拦下，
    测到的就不是"verdict 不合格"而是"摘要对不上"了（典型的假通过来源）。"""
    d['result_sha256'] = PC.canon_digest({'verdict': d['verdict'],
                                          'native_result': d['native_result']})
    return d


def test_child_source_changed_at_parent_commit():
    """★D57 第 3/4 条的核心：child 源在父 commit 下变了 ⇒ 证书失效。★"""
    f = control('source_unchanged')
    if f is None:
        return

    def mutate(fx):
        (fx.repo_dir / 'rtl/common/xs_child_core.sv').write_text(
            'module xs_child_core; wire changed; endmodule\n')
    g = Fixture(post_commit=mutate)
    check('source_changed:parent_is_c3', g.parent_commit == g.c3, 'parent=%s' % g.parent_commit)
    # 同一份证书在 C2 上还成立（证明夹具本身没问题），在 C3 上必须失效
    check('source_changed:still_valid_at_c2', g.judge(parent_commit=g.c2) is True,
          'C2 上就该是有效的: %r' % g.judge(parent_commit=g.c2))
    expect_reason('D57-3:closure_changed_at_parent', g.judge(),
                  'green_child_closure_changed')

    def rm(fx):
        (fx.repo_dir / 'rtl/common/xs_child_core.sv').unlink()
    h = Fixture(post_commit=rm)
    expect_reason('D57-3:closure_missing_at_parent', h.judge(),
                  'green_child_closure_missing_at_parent')


def test_cert_closure_does_not_match_child():
    """证书里写的闭包和 child 实际字节不符（把 sha 改成别的、摘要也一并改，
    骗过 schema 自洽闸）⇒ 必须被父 commit 上的复算抓住。"""
    f = control('closure_matches')
    if f is None:
        return

    def mutate(d):
        d['input_closure']['impl'][0]['sha256'] = 'e' * 64
        d['input_closure']['impl_sha256'] = PC.closure_digest(d['input_closure']['impl'])
        return d
    g = Fixture(cert_mutate=mutate)
    check('closure_mismatch:passes_schema', PC.validate_document(g.cert) == [],
          '夹具没骗过 schema 闸，测的就不是复算了: %r' % PC.validate_document(g.cert)[:3])
    expect_reason('D57-3:cert_closure_not_actual_bytes', g.judge(),
                  'green_child_closure_changed')


def test_script_closure_changed():
    """工具脚本（fm_eq.tcl）改了一个字节 ⇒ 证书失效（D57 第 4 条"工具策略改变"）。"""
    f = control('script_unchanged')
    if f is None:
        return

    def mutate(fx):
        (fx.repo_dir / 'scripts/fm_eq.tcl').write_text(FM_EQ_TCL + '# tampered\n')
    g = Fixture(post_commit=mutate)
    expect_reason('D57-4:script_closure_changed', g.judge(),
                  'green_child_script_closure_changed')

    def drop(d):
        d['script_closure']['entries'] = [
            e for e in d['script_closure']['entries'] if 'fm_eq' in e['path']]
        d['script_closure']['sha256'] = PC.closure_digest(d['script_closure']['entries'])
        return d
    h = Fixture(cert_mutate=drop)
    expect_reason('D57-4:script_closure_incomplete', h.judge(),
                  'green_child_script_closure_incomplete')


def test_tool_and_appvar_policy():
    f = control('tool_policy_ok')
    if f is None:
        return
    g = Fixture(policy_mutate=lambda p: p['tool'].update({'version': 'W-2025.06'}) or p)
    expect_reason('D57-4:tool_policy_mismatch', g.judge(),
                  'green_child_tool_policy_mismatch')
    h = Fixture(policy_mutate=lambda p: p.update(
        {'pinned_entry_appvars': {'hdlin_unresolved_modules': 'error'}}) or p)
    expect_reason('D57-4:appvar_policy_mismatch', h.judge(),
                  'green_child_appvar_policy_mismatch')


def test_target_config_added():
    """★fm_eq.tcl 拆分带出来的新缝★：证书没记 per-target 配置，而父 commit 上补了一份。

    2026-09-20 把 vmucp 白名单与目标专属 appvar 从 scripts/fm_eq.tcl 搬进
    verif/fm_target_config/<top>.tcl。文件**存在**时由 sidecar 快照进 script_closure，
    3b 会逐字节复算；难的是**不存在**那一侧 —— 证书里没有这条记录，
    "没记" 不能推出 "没有"。若不补这一条，给某个 child 事后补一份配置
    （开 vmucp、改 appvar）之后，它证书里每个 sha256 都还对得上，证明语义却已经变了。
    """
    f = control('target_config_absent')
    if f is None:
        return
    g = Fixture(post_commit=lambda fx: fx._w(
        'verif/fm_target_config/ChildLeaf.tcl',
        '# 事后补的 per-target 配置\nfm_target_vmucp_allow\n'))
    expect_reason('D57-4:target_config_added', g.judge(),
                  'green_child_target_config_added')


def test_declaration_changed():
    """child 自己的 dead_ref 声明在父 commit 下被改 ⇒ 配置变了 ⇒ 证书失效。"""
    f = control('declaration_unchanged')
    if f is None:
        return

    def mutate(fx):
        (fx.repo_dir / 'verif/dead_ref/ChildLeaf.json').write_text(
            json.dumps({'entries': [{'ref_path': 'r:/WORK/ChildLeaf/other'}]}) + '\n')
    g = Fixture(post_commit=mutate)
    expect_reason('D57-4:declaration_changed', g.judge(), 'green_child_declaration_changed')


def test_canonical_and_freeze_commit():
    f = control('canonical_ok')
    if f is None:
        return
    expect_reason('D57-4:canonical_mismatch', f.judge(canonical='G1-something-else'),
                  'green_child_canonical_mismatch')
    g = Fixture(policy_mutate=lambda p: p.update({'freeze_commit': None}) or p)
    expect_reason('D57-5:policy_no_freeze_commit', g.judge(),
                  'green_child_policy_no_freeze_commit')
    h = Fixture(policy_mutate=lambda p: p.update({'freeze_commit': 'f' * 40}) or p)
    expect_reason('D57-5:not_freeze_commit', h.judge(), 'green_child_not_freeze_commit')


def test_no_fm_target_child():
    """★D57 尾条：11 个没有 FM target 的 child 不能使用 green_child。★"""
    f = control('fm_target_ok')
    if f is None:
        return
    g = Fixture(child_is_fm_target=False)
    expect_reason('D57-tail:not_fm_target', g.judge(), 'green_child_not_fm_target')


def test_no_commit_context_and_missing_policy():
    f = control('commit_context_ok')
    if f is None:
        return
    import fm_target_universe as FTU
    tmap, unres = FTU.targets_at(str(f.repo_dir), f.parent_commit)
    pol, _ = PC.load_policy(f.repo, f.parent_commit)
    expect_reason('D57-1:no_commit_context',
                  PC.validate_child_certificate(f.repo, None, 'ChildLeaf', f.cert_sha,
                                                policy=pol, fm_targets=tmap,
                                                fm_targets_unresolved=unres),
                  'green_child_no_commit_context')
    expect_reason('D57-4:policy_missing',
                  PC.validate_child_certificate(f.repo, f.parent_commit, 'ChildLeaf',
                                                f.cert_sha, expect_canonical=CANON,
                                                policy=None, fm_targets=tmap,
                                                fm_targets_unresolved=unres),
                  'green_child_policy_missing')


def test_old_untracked_receipt_index_cannot_turn_green():
    """★D57：旧 untracked receipt/index 不得自动转换成 green。★

    夹具里放一份"看起来完美"的 docs/receipt_index.tsv（target 通过、非 provisional），
    但**不放证书**。必须仍然拒绝。
    """
    f = Fixture(commit_cert=False)
    (f.repo_dir / 'verif/proof_certificates/ChildLeaf.json').unlink()
    (f.repo_dir / 'docs').mkdir(exist_ok=True)
    (f.repo_dir / 'docs/receipt_index.tsv').write_text(
        '# derived\nChildLeaf\tSUCCEEDED\t%s\t%s\tfalse\t%s\tevidence/x/ChildLeaf/receipt.json\n'
        % (CANON, f.c1, 'a' * 64))
    expect_reason('D57:legacy_index_does_not_turn_green', f.judge(),
                  'green_child_certificate_not_in_commit')


# ===========================================================================
# 三、端到端：真实 Formality 日志 + fm_verdict.verdict()
# ===========================================================================
def _bbox_from_allow(allow):
    return {(o['side'], o['design'], o['path']) for o in allow['objects']}


def _run_verdict(f, log_text, impl_commit):
    env_home, env_g1 = os.environ.get('XSSV_HOME'), os.environ.get('G1_CANONICAL')
    os.environ['XSSV_HOME'] = str(f.repo_dir)
    os.environ['G1_CANONICAL'] = str(f.g1)
    try:
        return FV.verdict(log_text, 0, 'assembly', 'WrBypass', 0, None, None,
                          _bbox_from_allow(f.allow), {}, f.allow, CANON, impl_commit)
    finally:
        for k, v in (('XSSV_HOME', env_home), ('G1_CANONICAL', env_g1)):
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v


def test_end_to_end_fm_verdict():
    """喂**真实**的 tracked Formality 日志，走完整 fm_verdict.verdict(assembly)。

    这条证明的是"接线真的通了"：证书判据确实长在签核主路径上，
    而不是一个没人调用的库函数。
    """
    if not REAL_FM_LOG.exists():
        check('e2e:real_log_present', False, '缺 %s' % REAL_FM_LOG)
        return
    log = REAL_FM_LOG.read_text(errors='replace')
    check('e2e:real_log_present', True)

    f = Fixture()
    v, q = _run_verdict(f, log, f.parent_commit)
    check('e2e:valid_certificate_gives_SUCCEEDED', v == 'SUCCEEDED',
          'v=%s reason=%r' % (v, q.get('reason')))
    NOTES.append('%-52s -> %s (bbox_objects=%s)'
                 % ('e2e:valid_certificate', v, q.get('bbox_objects')))

    g = Fixture(commit_cert=False)
    v2, q2 = _run_verdict(g, log, g.parent_commit)
    check('e2e:uncommitted_certificate_gives_PARTIAL', v2 == 'PARTIAL',
          'v=%s' % v2)
    expect_reason('e2e:uncommitted_certificate_reason', q2.get('reason') or True,
                  'assembly_green_child_certificate_not_in_commit')

    h = Fixture(child_is_fm_target=False)
    v3, q3 = _run_verdict(h, log, h.parent_commit)
    check('e2e:not_fm_target_gives_PARTIAL', v3 == 'PARTIAL', 'v=%s' % v3)
    expect_reason('e2e:not_fm_target_reason', q3.get('reason') or True,
                  'assembly_green_child_not_fm_target')

    k = Fixture()
    v4, q4 = _run_verdict(k, log, None)              # 不传 --impl-commit
    check('e2e:no_impl_commit_gives_PARTIAL', v4 == 'PARTIAL', 'v=%s' % v4)
    expect_reason('e2e:no_impl_commit_reason', q4.get('reason') or True,
                  'assembly_green_child_no_commit_context')


# ===========================================================================
# 四、生成器负测
# ===========================================================================
def _evidence_dir(fx, verdict='SUCCEEDED', drop_kind=False, break_closure=False,
                  no_sidecar=False, bad_run_context=False, no_script_closure=False):
    ev_root = fx.root / 'evidence' / fx.c1[:12]
    d = ev_root / 'ChildLeaf'
    (d / 'sidecar').mkdir(parents=True, exist_ok=True)
    impl = [{'path': p, 'kind': 'repo', 'sha256': _sha(t.encode())}
            for p, t in sorted(CHILD_SRC.items())]
    if drop_kind:
        for e in impl:
            e.pop('kind')
    if break_closure:
        impl[0]['sha256'] = 'f' * 64
    rec = {
        'schema': 'xs-v2-sv-receipt-v1', 'top': 'ChildLeaf', 'run_id': 'rid-1',
        'g1_canonical_id': CANON,
        'golden_closure': [{'path': 'golden-rtl/ChildLeaf.sv', 'kind': 'golden',
                            'sha256': _sha(GOLDEN_FILES['ChildLeaf.sv'].encode())}],
        'impl_closure': impl, 'impl_commit': fx.c1,
        'impl_worktree_dirty': False, 'provisional': False,
        'proof_config': {'fm_mode': 'signoff-strict',
                         'entry_appvars_readback': {'hdlin_unresolved_modules': 'black_box'}},
        'fm_shell_rc': 0, 'verdict': verdict, 'verdict_detail': {},
    }
    (d / 'receipt.json').write_text(json.dumps(rec, ensure_ascii=False, indent=1))
    (d / 'MAKE_RC').write_text('0\n')
    (d / 'fm.log').write_text(
        '\n     Formality (R)\n     Version V-2023.12-SP3 for linux64 - Apr 13, 2024\n'
        'Build: 8868332\nHostname: fixture\n')
    if not no_sidecar:
        (d / 'sidecar' / 'native_facts.json').write_text(json.dumps(
            {'schema': 'fm-sidecar-native-v1', 'run_id': 'rid-1', 'top': 'ChildLeaf',
             'native_verdict': 'SUCCEEDED',
             'stats': {'passing': 1, 'failing': 0}, 'unmatched': {}}))
    if not no_script_closure:
        (d / 'sidecar' / 'script_closure.list').write_text(
            '/tmp/wt/scripts/fm_eq.tcl\tsourced_000.tcl\t%s\n'
            '/tmp/wt/scripts/sidecar/fm_native_emit.tcl\tsourced_001.tcl\t%s\n'
            % (_sha(FM_EQ_TCL.encode()), _sha(EMIT_TCL.encode())))
    dg = 'd' * 64
    ctx = ('commit\t%s\nhead_before\t%s\nhead_after\t%s\n'
           'worktree_digest_before\t%s\nworktree_digest_after\t%s\ntargets\tChildLeaf\n'
           % (fx.c1, fx.c1, fx.c1 if not bad_run_context else fx.c2, dg, dg))
    (ev_root / 'RUN_CONTEXT.tsv').write_text(ctx)
    return d


def _gen(fx, evdir, **kw):
    """跑生成器，把 die() 的 SystemExit 变成可断言的字符串。"""
    err = []
    old = MPC.die

    def cap(msg):
        err.append(msg)
        raise SystemExit(1)
    MPC.die = cap
    try:
        doc = MPC.build_certificate(fx.repo_dir, evdir, g1_root=str(fx.g1), **kw)
        return doc, None
    except SystemExit:
        return None, (err[0] if err else 'SystemExit(no message)')
    finally:
        MPC.die = old


def test_generator_negatives():
    fx = Fixture()
    doc, err = _gen(fx, _evidence_dir(fx))
    check('gen[CONTROL]:clean_evidence_produces_certificate', doc is not None,
          'err=%r' % err)
    if doc is not None:
        check('gen[CONTROL]:certificate_passes_schema', PC.validate_document(doc) == [],
              'errs=%r' % PC.validate_document(doc)[:3])
        check('gen[CONTROL]:script_closure_relativized',
              sorted(e['path'] for e in doc['script_closure']['entries']) ==
              ['scripts/fm_eq.tcl', 'scripts/sidecar/fm_native_emit.tcl'],
              'entries=%r' % doc['script_closure']['entries'])
        check('gen[CONTROL]:retention_is_attestation_only',
              doc['evidence_retention'] == 'attestation_only' and
              doc['evidence_archive'] is None, 'doc=%r' % doc['evidence_retention'])

    fx1 = Fixture()
    _, e1 = _gen(fx1, _evidence_dir(fx1, verdict='PARTIAL'))
    expect_reason('gen:verdict_not_qualifying', e1 or True, '不在合格集合')
    fx2 = Fixture()
    _, e2 = _gen(fx2, _evidence_dir(fx2, drop_kind=True))
    expect_reason('gen:old_format_receipt_rejected', e2 or True, '老格式')
    fx3 = Fixture()
    _, e3 = _gen(fx3, _evidence_dir(fx3, break_closure=True))
    expect_reason('gen:closure_selfcheck_at_impl_commit', e3 or True, '生成时自检失败')
    fx4 = Fixture()
    _, e4 = _gen(fx4, _evidence_dir(fx4, no_sidecar=True))
    expect_reason('gen:missing_sidecar', e4 or True, 'native_facts.json 缺失')
    fx5 = Fixture()
    _, e5 = _gen(fx5, _evidence_dir(fx5, no_script_closure=True))
    expect_reason('gen:missing_script_closure', e5 or True, 'script_closure.list 缺失')
    fx6 = Fixture()
    _, e6 = _gen(fx6, _evidence_dir(fx6, bad_run_context=True))
    expect_reason('gen:run_context_head_moved', e6 or True, 'head 在跑期间变了')
    fx7 = Fixture()
    _, e7 = _gen(fx7, _evidence_dir(fx7), archive=str(fx7.root / 'nope.tar.zst'))
    expect_reason('gen:archive_path_missing', e7 or True, '不得凭空声称留有完整原件')
    fx8 = Fixture(child_is_fm_target=False)
    _, e8 = _gen(fx8, _evidence_dir(fx8))
    expect_reason('gen:not_fm_target_no_certificate', e8 or True, '不是 FM target')

    # archive 正路：给一个真文件 → retention=archived + 有 hash
    fx9 = Fixture()
    arc = fx9.root / 'ev.tar.zst'
    arc.write_bytes(b'fake archive bytes')
    doc9, e9 = _gen(fx9, _evidence_dir(fx9), archive=str(arc))
    check('gen[CONTROL]:archive_recorded',
          doc9 is not None and doc9['evidence_retention'] == 'archived'
          and doc9['evidence_archive']['sha256'] == _sha(b'fake archive bytes'),
          'err=%r doc=%r' % (e9, doc9 and doc9.get('evidence_archive')))


# ===========================================================================
# 五、仓库里已提交的 POLICY / schema 自检
# ===========================================================================
def test_repo_policy_and_schema_are_valid():
    pol_p = HOME / PC.POLICY_PATH
    check('repo:POLICY.json_exists', pol_p.exists(), str(pol_p))
    if pol_p.exists():
        errs = PC.validate_policy(json.loads(pol_p.read_text()))
        check('repo:POLICY.json_valid', errs == [], 'errs=%r' % errs)
        pol = json.loads(pol_p.read_text())
        if pol.get('freeze_commit') is None:
            NOTES.append('%-52s -> %s' % ('repo:POLICY.freeze_commit',
                                          'null（未冻结；此状态下 green_child 一律拒绝放行）'))
    sp = HOME / PC.CERT_DIR / 'schema-v1.json'
    check('repo:schema-v1.json_exists', sp.exists(), str(sp))
    if sp.exists():
        sj = json.loads(sp.read_text())
        check('repo:schema-v1.json_in_sync_with_code',
              [f['field'] for f in sj['required_fields']] ==
              [d for d, _c, _x, _y in PC.FIELD_SPEC],
              'schema-v1.json 与 FIELD_SPEC 不同步（重跑 --dump-schema）')


SABOTAGE = os.environ.get('XSSV_CERT_TEST_SABOTAGE') or ''


def _sabotage():
    """★把被测判据换成"永远放行"，用来证明这套负测**真的在测东西**。★

    这是对"测试假通过"的直接反制：如果把 validator 换成恒 True 之后负测还是全绿，
    那说明负测根本没在看 validator 的结论。带 XSSV_CERT_TEST_SABOTAGE=<which> 跑，
    期望是**必须变红**；变绿反而是这套测试的 bug。

      XSSV_CERT_TEST_SABOTAGE=child   validate_child_certificate 恒 True
      XSSV_CERT_TEST_SABOTAGE=schema  validate_document 恒 []
      XSSV_CERT_TEST_SABOTAGE=all     两个都换
    """
    if SABOTAGE in ('child', 'all'):
        PC.validate_child_certificate = lambda *a, **k: True
    if SABOTAGE in ('schema', 'all'):
        PC.validate_document = lambda *a, **k: []


def main():
    if shutil.which('git') is None:
        print('SKIP: 没有 git')
        return 2
    if SABOTAGE:
        print('★SABOTAGE=%s —— 被测判据已被换成恒放行；本次运行**必须变红**' % SABOTAGE)
        _sabotage()
    tests = [v for k, v in sorted(globals().items())
             if k.startswith('test_') and callable(v)]
    print('运行 %d 组测试（每组含阳性对照）' % len(tests))
    for t in tests:
        if VERBOSE:
            print('- %s' % t.__name__)
        try:
            t()
        except Exception as e:                              # noqa: BLE001
            import traceback
            FAILURES.append('%s: EXCEPTION %r' % (t.__name__, e))
            print('  FAIL %s: EXCEPTION' % t.__name__)
            traceback.print_exc()
    for d in _TMPDIRS:
        shutil.rmtree(str(d), ignore_errors=True)

    total = len(PASSES) + len(FAILURES)
    print('\n--- 负测实际原因串（供报告引用） ---')
    for n in NOTES:
        print('  ' + n)
    print('\nassertions run=%d  passed=%d  failed=%d  (expected=%d)'
          % (total, len(PASSES), len(FAILURES), EXPECTED_ASSERTIONS))
    rc = 0
    if FAILURES:
        print('FAILED:')
        for f in FAILURES:
            print('  ' + f)
        rc = 1
    if total != EXPECTED_ASSERTIONS:
        # ★防"测试被悄悄跳过还报 PASS"：条数对不上一律非零退出。
        print('★断言条数 %d != 预期 %d —— 有测试被跳过或提前 return，'
              '整体判失败（改测试请同步改 EXPECTED_ASSERTIONS）' % (total, EXPECTED_ASSERTIONS))
        rc = 1
    if SABOTAGE:
        if rc == 0:
            print('★★ SABOTAGE 没被抓到 —— 这套负测是瞎的，判失败 ★★')
            return 1
        print('SABOTAGE 被抓到（如期变红）：本次的"红"是**预期结果**')
        return 0
    print('ALL OK' if rc == 0 else 'NOT OK')
    return rc


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""test_proof_certificate_nested.py —— 嵌套 green_child 证书树的正负测（codex 0224 §4）。

夹具：一个自带 git 历史的最小仓库，三层证书 T（根）→ M（中）→ {LA, LB}（叶）。
  * LA / LB：普通叶子证书，无 allow；
  * M：allow 把 LA、LB 两侧声明为 green_child（写死各自证书 sha），hdlin_interface_only 回读 = "LA LB"；
  * T：allow 把 M 声明为 green_child，回读 = "M"。
判据本体 = proof_certificate.validate_certificate_current(root_parent, 'T', doc)（递归进 M、LA、LB）。

正例：P0 干净树通过；P1 回读乱序（"LB LA"）通过；P2 两条分支共享同一孙级 LA 时 memo 命中、只复算一次、结果一致；
      P3 叶子带 MC 契约且 M / T 逐层记 external_dependency 时通过。
负例（必须红，按关键字断言）：
  A1 回读比声明多一个 design          A2 少一个          A3 重复项          A4 非简单名字
  N1 孙级证书 blob 被替换（allow sha 未改）           N2 allow 里写伪造 sha
  N3 孙级证书 target 与声明不符                        N4 孙级 RTL 变          N5 fm_eq.tcl 变
  N6 孙级 target-config 新增                           N7 孙级自身声明（dead_ref）变
  N8 孙级 verdict 不合格                               N9 A→B→A 环（LA 的 allow 又声明 M）
  N10 超过深度上限                                      N11 孙级 MC 登记表行被改
  N12 无 green_child 的普通证书回读非空                N13 叶子带 MC 而中层没记 external_dependency（传播缺失）
  N14 同一 design 的 r/i 两条声明了不同 sha
用法：python3 scripts/test_proof_certificate_nested.py
"""
import copy
import hashlib
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
import fm_target_universe as FTU                            # noqa: E402

CANON = 'G1-fixture-canonical-nested-000000000000000000000000000000000000'
FM_EQ = '# fake fm_eq.tcl\n'
EMIT = '# fake emit\n'
TARGETS = ['LA', 'LB', 'M', 'N', 'T']
G1REAL = pathlib.Path(os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical') / 'golden-rtl'
FAILS, RUN = [], [0]
TMP = []


def sha(b):
    return hashlib.sha256(b).hexdigest()


def sh(cwd, *a):
    p = subprocess.run(list(a), cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if p.returncode:
        raise RuntimeError(p.stdout.decode())
    return p.stdout.decode().strip()


def chk(name, got, want):
    RUN[0] += 1
    ok = (got is True) if want is True else (isinstance(got, str) and want in got)
    print('  %-46s %s  %s' % (name, 'ok' if ok else '★FAIL★', str(got)[:120]))
    if not ok:
        FAILS.append(name)


class Tree(object):
    """hooks：dict，可含
       readback={target: str}        hdlin_interface_only 回读
       allow_mut={target: fn(allow)} 在写 allow 前改它（拿得到真实 sha）
       cert_mut={target: fn(doc)}    在写证书前改它
       mc=True                       LA 的 impl 闭包挂真实 MC 模型 ram_16x25（并把真实登记表放进仓库）
       ed={target: value}            强制 external_dependency
       shape='TM'|'TMN'              T 下面只挂 M，或 M 与 N（N 也挂 LA）
       post=fn(tree)                 C3 突变"""

    def __init__(self, **h):
        self.h = h
        self.root = pathlib.Path(tempfile.mkdtemp(prefix='xsv2-nest-'))
        TMP.append(self.root)
        self.repo_dir = self.root / 'repo'
        self.g1 = self.root / 'G1'
        (self.g1 / 'golden-rtl').mkdir(parents=True)
        self.repo_dir.mkdir()
        gold = {'%s.sv' % t: ('module %s; endmodule // golden\n' % t).encode() for t in TARGETS}
        if h.get('mc'):
            gold['ram_16x25.sv'] = (G1REAL / 'ram_16x25.sv').read_bytes()
        for n, b in gold.items():
            (self.g1 / 'golden-rtl' / n).write_bytes(b)
        (self.g1 / 'MANIFEST.tsv').write_text(''.join('%s\t%d\t%s\n' % (sha(b), len(b), n) for n, b in gold.items()))
        self.gold = gold
        self.w('scripts/fm_eq.tcl', FM_EQ)
        self.w('scripts/sidecar/fm_native_emit.tcl', EMIT)
        self.w('scripts/ut_common.mk', '# placeholder\n')
        for t in TARGETS:
            self.w('rtl/%s.sv' % t, 'module %s; endmodule\n' % t)
            self.w('verif/ut/%s/Makefile' % t, 'MODULE = %s\nFM_VARIANTS = %s\n' % (t, t))
        self.w('verif/dead_ref/LB.json', json.dumps({'entries': []}) + '\n')
        if h.get('mc'):
            for rel in ('verif/mc_memory_registry.tsv', 'verif/vendor_boundary.tsv'):
                self.w(rel, (HOME / rel).read_text())
        sh(self.repo_dir, 'git', 'init', '-q')
        sh(self.repo_dir, 'git', 'config', 'user.email', 'f@t')
        sh(self.repo_dir, 'git', 'config', 'user.name', 'f')
        sh(self.repo_dir, 'git', 'add', '-A')
        sh(self.repo_dir, 'git', 'commit', '-q', '-m', 'C1')
        self.c1 = sh(self.repo_dir, 'git', 'rev-parse', 'HEAD')
        # 证书自底向上
        shape = h.get('shape', 'TM')
        self.sha = {}
        self.cert('LA', [])
        self.cert('LB', [], dead_ref=True)
        self.cert('M', ['LA', 'LB'])
        if shape == 'TMN':
            self.cert('N', ['LA'])
            self.cert('T', ['M', 'N'])
        else:
            self.cert('T', ['M'])
        pol = {'schema': PC.POLICY_SCHEMA, 'freeze_commit': None,
               'qualifying_verdicts': ['SUCCEEDED', 'PASS_DEAD_REF'],
               'tool': {'name': 'fm_shell', 'version': 'V', 'build': 'B'},
               'pinned_entry_appvars': {'hdlin_unresolved_modules': 'black_box', 'hdlin_interface_only': ''},
               'script_closure_files': ['scripts/fm_eq.tcl', 'scripts/sidecar/fm_native_emit.tcl'],
               'target_config_dir': 'verif/fm_target_config', 'g1_canonical_id': CANON}
        self.w(PC.POLICY_PATH, json.dumps(pol, indent=1, sort_keys=True) + '\n')
        sh(self.repo_dir, 'git', 'add', '-A')
        sh(self.repo_dir, 'git', 'commit', '-q', '-m', 'C2')
        self.parent = sh(self.repo_dir, 'git', 'rev-parse', 'HEAD')
        if h.get('post'):
            h['post'](self)
            sh(self.repo_dir, 'git', 'add', '-A')
            sh(self.repo_dir, 'git', 'commit', '-q', '-m', 'C3')
            self.parent = sh(self.repo_dir, 'git', 'rev-parse', 'HEAD')
        self.repo = PC.Repo(self.repo_dir)

    def w(self, rel, text):
        p = self.repo_dir / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(text)

    def cert(self, t, kids, dead_ref=False):
        h = self.h
        decls = {}
        if kids:
            objs = []
            for k in kids:
                for side in ('r', 'i'):
                    objs.append({'side': side, 'design': k, 'path': '%s:/WORK/%s/u_%s' % (side, t, k),
                                 'attrs': 'i', 'class': 'green_child', 'child_target': k,
                                 'certificate_sha256': self.sha[k]})
            allow = {'schema': 'xs-v2-sv-allow-v1', 'target': t, 'objects': objs}
            if h.get('allow_mut', {}).get(t):
                allow = h['allow_mut'][t](allow, self) or allow
            body = json.dumps(allow, indent=1, sort_keys=True) + '\n'
            self.w('verif/allow/%s.json' % t, body)
            decls['allow'] = {'path': 'verif/allow/%s.json' % t, 'sha256': sha(body.encode())}
        if dead_ref:
            p = 'verif/dead_ref/%s.json' % t
            decls['dead_ref'] = {'path': p, 'sha256': sha((self.repo_dir / p).read_bytes())}
        rb = h.get('readback', {}).get(t, ' '.join(kids))
        impl = [{'path': 'rtl/%s.sv' % t, 'kind': 'repo',
                 'sha256': sha(('module %s; endmodule\n' % t).encode())}]
        golden = [{'path': 'golden-rtl/%s.sv' % t, 'kind': 'golden', 'sha256': sha(self.gold['%s.sv' % t])}]
        ed = None
        if h.get('mc') and t == 'LA':
            e = {'path': 'golden-rtl/ram_16x25.sv', 'kind': 'golden', 'sha256': sha(self.gold['ram_16x25.sv'])}
            impl.append(dict(e))
            golden.append(dict(e))
            ed = PC.EXTERNAL_DEPENDENCY_MC
        if h.get('mc') and t in ('M', 'T'):
            ed = PC.EXTERNAL_DEPENDENCY_MC
        if t in h.get('ed', {}):
            ed = h['ed'][t]
        scripts = [{'path': 'scripts/fm_eq.tcl', 'kind': 'repo', 'sha256': sha(FM_EQ.encode())},
                   {'path': 'scripts/sidecar/fm_native_emit.tcl', 'kind': 'repo', 'sha256': sha(EMIT.encode())}]
        cfg = {'fm_mode': 'assembly' if kids else 'signoff-strict', 'declarations': decls,
               'entry_appvars_readback': {'hdlin_unresolved_modules': 'black_box', 'hdlin_interface_only': rb}}
        native = {'native_verdict': 'SUCCEEDED', 'stats': {'passing': 1}}
        doc = {'schema': PC.CERT_SCHEMA, 'target': t, 'variant': t, 'ut_dir': t, 'verdict': 'SUCCEEDED',
               'proof_mode': cfg['fm_mode'], 'provisional': False, 'impl_worktree_dirty': False,
               'impl_commit': self.c1, 'proof_commit': self.c1, 'proof_worktree_digest': sha(b'w'),
               'g1_canonical_id': CANON, 'g1_manifest_sha256': sha((self.g1 / 'MANIFEST.tsv').read_bytes()),
               'run_id': t, 'tool': {'name': 'fm_shell', 'version': 'V', 'build': 'B', 'fm_shell_rc': 0},
               'proof_config': cfg, 'proof_config_sha256': PC.canon_digest(cfg),
               'input_closure': {'golden': golden, 'impl': impl, 'golden_sha256': PC.closure_digest(golden),
                                 'impl_sha256': PC.closure_digest(impl),
                                 'repo_impl_files': sum(1 for e in impl if e['kind'] == 'repo')},
               'script_closure': {'entries': scripts, 'sha256': PC.closure_digest(scripts)},
               'native_facts_sha256': sha(b'n'), 'native_result': native,
               'result_sha256': PC.canon_digest({'verdict': 'SUCCEEDED', 'native_result': native}),
               'receipt_sha256': sha(b'r'), 'evidence_retention': 'attestation_only', 'evidence_archive': None,
               'reproduce': {'command': 'x'}, 'generated_at': '2026-10-05T00:00:00Z',
               'generator': {'script': 'scripts/make_proof_certificate.py', 'version': 1,
                             'source_evidence_dir': 'evidence/x/%s' % t}}
        if ed:
            doc['external_dependency'] = ed
        if h.get('cert_mut', {}).get(t):
            doc = h['cert_mut'][t](doc) or doc
            doc['proof_config_sha256'] = PC.canon_digest(doc['proof_config'])
            doc['result_sha256'] = PC.canon_digest({'verdict': doc['verdict'], 'native_result': doc['native_result']})
        body = json.dumps(doc, indent=1, sort_keys=True) + '\n'
        self.w('verif/proof_certificates/%s.json' % t, body)
        self.sha[t] = sha(body.encode())

    def judge(self, memo=None):
        pol, perr = PC.load_policy(self.repo, self.parent)
        if perr:
            return perr
        tmap, unres = FTU.targets_at(str(self.repo_dir), self.parent)
        doc, _b, err = PC.load_certificate(self.repo, self.parent, 'T')
        if err:
            return err
        return PC.validate_certificate_current(self.repo, self.parent, 'T', doc, expect_canonical=CANON,
                                               policy=pol, fm_targets=tmap, fm_targets_unresolved=unres,
                                               g1_root=str(self.g1), _memo=memo)


def main():
    if shutil.which('git') is None:
        print('SKIP: 无 git')
        return 2
    chk('P0 干净三层树', Tree().judge(), True)
    chk('P1 回读乱序', Tree(readback={'M': 'LB LA'}).judge(), True)
    chk('A1 回读多一个 design', Tree(readback={'M': 'LA LB LX'}).judge(), 'interface_only_not_declared_set')
    chk('A2 回读少一个 design', Tree(readback={'M': 'LA'}).judge(), 'interface_only_not_declared_set')
    chk('A3 回读重复项', Tree(readback={'M': 'LA LA LB'}).judge(), 'interface_only_duplicate')
    chk('A4 回读非简单名字', Tree(readback={'M': '{LA LB}'}).judge(), 'interface_only_unparsable')
    chk('N12 普通证书回读非空', Tree(readback={'LA': 'Foo'}).judge(), 'interface_only_not_declared_set')

    def replace_blob(tr):
        d = json.loads((tr.repo_dir / 'verif/proof_certificates/LA.json').read_text())
        d['generated_at'] = '2026-10-06T00:00:00Z'
        tr.w('verif/proof_certificates/LA.json', json.dumps(d, indent=1, sort_keys=True) + '\n')
    chk('N1 孙级证书 blob 被替换', Tree(post=replace_blob).judge(), 'nested_certificate_sha_mismatch')

    def forge(allow, tr):
        for o in allow['objects']:
            if o['design'] == 'LA':
                o['certificate_sha256'] = 'f' * 64
    chk('N2 allow 写伪造 sha', Tree(allow_mut={'M': forge}).judge(), 'nested_certificate_sha_mismatch')
    chk('N3 孙级证书 target 不符', Tree(cert_mut={'LA': lambda d: d.update({'target': 'LB'}) or d}).judge(),
        'nested_target_mismatch')
    chk('N4 孙级 RTL 变', Tree(post=lambda tr: tr.w('rtl/LA.sv', 'module LA; wire x; endmodule\n')).judge(),
        'closure_changed:LA')
    chk('N5 fm_eq.tcl 变', Tree(post=lambda tr: tr.w('scripts/fm_eq.tcl', FM_EQ + '#x\n')).judge(),
        'script_closure_changed')
    chk('N6 孙级 target-config 新增',
        Tree(post=lambda tr: tr.w('verif/fm_target_config/LA.tcl', 'fm_target_vmucp_allow\n')).judge(),
        'target_config_added:LA')
    chk('N7 孙级自身声明变', Tree(post=lambda tr: tr.w('verif/dead_ref/LB.json', '{"entries": [1]}\n')).judge(),
        'declaration_changed:LB')
    chk('N8 孙级 verdict 不合格', Tree(cert_mut={'LA': lambda d: d.update({'verdict': 'PARTIAL'}) or d}).judge(),
        'verdict_not_qualifying:LA')

    def cyc(tr):
        # LA 改成"有 allow、把 M 声明为 green_child"（sha 随便写——判环在核 sha 之前）
        allow = {'schema': 'xs-v2-sv-allow-v1', 'target': 'LA', 'objects': [
            {'side': s, 'design': 'M', 'path': '%s:/WORK/LA/u_M' % s, 'attrs': 'i', 'class': 'green_child',
             'child_target': 'M', 'certificate_sha256': 'a' * 64} for s in ('r', 'i')]}
        return allow
    t9 = Tree()
    # 直接改 LA 证书绑定一份含 M 的 allow，需要重建 LA → M → T 的 sha 链：用 hooks 在构造期完成
    t9 = Tree(cert_mut={'LA': lambda d: _bind_allow(d, cyc)}, readback={'LA': 'M'})
    chk('N9 A→B→A 环', t9.judge(), 'nested_cycle')
    old = PC.MAX_NEST_DEPTH
    PC.MAX_NEST_DEPTH = 2
    try:
        chk('N10 超过深度上限', Tree().judge(), 'nested_too_deep')
    finally:
        PC.MAX_NEST_DEPTH = old

    # P2：T → {M, N}，M 与 N 都挂 LA；memo 命中、LA 只真正加载/复算一次，结果一致
    calls = []
    real = PC.load_certificate

    def counting(repo, commit, target):
        calls.append(target)
        return real(repo, commit, target)
    PC.load_certificate = counting
    try:
        memo = {}
        r = Tree(shape='TMN').judge(memo=memo)
    finally:
        PC.load_certificate = real
    chk('P2 共享孙级 memo 命中且结果一致',
        True if (r is True and calls.count('LA') == 1 and any(k[1] == 'LA' for k in memo)) else
        'r=%r LA_loads=%d' % (r, calls.count('LA')), True)

    chk('P3 叶子 MC 契约逐层传播', Tree(mc=True).judge(), True)

    def mc_mut(tr):
        p = tr.repo_dir / 'verif/mc_memory_registry.tsv'
        lines = p.read_text().splitlines()
        out = []
        for ln in lines:
            c = ln.split('\t')
            if c[0] == 'ram_16x25':
                c[5] = '32'
            out.append('\t'.join(c))
        p.write_text('\n'.join(out) + '\n')
    chk('N11 孙级 MC 登记表行被改', Tree(mc=True, post=mc_mut).judge(), 'mc_invalid')
    chk('N13 中层漏记 MC 传播', Tree(mc=True, ed={'M': None}).judge(), 'external_dependency_missing:M')

    def split_sha(allow, tr):
        for o in allow['objects']:
            if o['design'] == 'LA' and o['side'] == 'i':
                o['certificate_sha256'] = 'b' * 64
    chk('N14 同 design r/i 声明不同 sha', Tree(allow_mut={'M': split_sha}).judge(), 'nested_sha_inconsistent')

    for d in TMP:
        shutil.rmtree(str(d), ignore_errors=True)
    print('test_proof_certificate_nested: %d 条，%s' % (RUN[0], '全过' if not FAILS else '★%d 条不过★ %s' % (len(FAILS), FAILS)))
    return 1 if FAILS or RUN[0] != 22 else 0


def _bind_allow(doc, mk):
    """把一份 allow 绑进证书的 declarations（N9 用）：allow 文件由 _post_write 在 C1 之后写入同一 commit。"""
    allow = mk(None)
    body = json.dumps(allow, indent=1, sort_keys=True) + '\n'
    _PENDING.append(('verif/allow/LA.json', body))
    doc['proof_config']['declarations']['allow'] = {'path': 'verif/allow/LA.json', 'sha256': sha(body.encode())}
    return doc


_PENDING = []
_orig_w_cert = Tree.cert


def _cert_with_pending(self, t, kids, dead_ref=False):
    _orig_w_cert(self, t, kids, dead_ref=dead_ref)
    while _PENDING:
        rel, body = _PENDING.pop()
        self.w(rel, body)


Tree.cert = _cert_with_pending


if __name__ == '__main__':
    sys.exit(main())

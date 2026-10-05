#!/usr/bin/env python3
"""make_proof_certificate.py —— 从**一次 clean official run** 生成 tracked 证明证书。

codex 0157 D57：`evidence/` 继续不入 Git，改由 `verif/proof_certificates/<target>.json`
这份紧凑、tracked、reviewed 的证书承担 `green_child` 背书，并由 freeze commit 绑定。

输入 = `scripts/run_proof.sh` 产出的证据目录：

    <EVIDENCE_ROOT>/RUN_CONTEXT.tsv          ← commit / worktree 前后摘要
    <EVIDENCE_ROOT>/<target>/receipt.json
    <EVIDENCE_ROOT>/<target>/fm.log          ← 工具版本 banner
    <EVIDENCE_ROOT>/<target>/MAKE_RC
    <EVIDENCE_ROOT>/<target>/sidecar/native_facts.json
    <EVIDENCE_ROOT>/<target>/sidecar/script_closure.list

输出 = `verif/proof_certificates/<target>.json`（紧凑，不含原始日志）。

# 这个生成器**拒绝**做的事

* 不接受 dirty / provisional 的 receipt；
* 不接受非合格 verdict（只有 SUCCEEDED / PASS_DEAD_REF）；
* 不接受老格式 receipt（impl_closure 条目缺 `kind`，或全是绝对路径）——
  那种 receipt 没法在别的 commit 上用 `git show` 复算，等于没有组合性保证；
  实测 1035 份历史 receipt 里有 37 份是这种；
* 不接受 RUN_CONTEXT 前后摘要不一致、或 commit 与 receipt.impl_commit 不符；
* **生成时就用 `git show <impl_commit>:<path>` 把 impl 闭包重算一遍**，对不上直接拒。
  这条是刻意的：证书出厂时就必须满足它自己将来被校验的那条判据。
* 不接受 `--archive` 指向不存在的文件；没给 `--archive` 就只能是
  `evidence_retention=attestation_only`，证书不会声称留有完整原件。

# 用法

    # 冻结后，integrator 在 clean official run 的证据上逐个生成
    python3 scripts/make_proof_certificate.py \\
        --evidence evidence/<commit12>/WrBypass --repo . \\
        [--archive releases/evidence-<commit12>.tar.zst]

    # 把证书 sha256 回填进引用它的 allow 声明（green_child 必须精确引用）
    python3 scripts/make_proof_certificate.py --repo . \\
        --stamp-allow verif/allow/TageTable.json ...
"""
import argparse
import datetime
import hashlib
import json
import os
import pathlib
import re
import sys

_HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE))
import proof_certificate as PC                              # noqa: E402
import fm_target_universe as FTU                            # noqa: E402

GENERATOR_VERSION = 1
GENERATOR_PATH = 'scripts/make_proof_certificate.py'

_VER = re.compile(r'^\s*Version (\S+) for (\S+)', re.M)
_BUILD = re.compile(r'^Build:\s*(\S+)\s*$', re.M)


def die(msg):
    sys.stderr.write('ERROR: %s\n' % msg)
    sys.exit(1)


def _sha_bytes(b):
    return hashlib.sha256(b).hexdigest()


def _read_run_context(evid_target_dir):
    """RUN_CONTEXT.tsv 在证据根（run_proof.sh 每批写一份），不是每目标一份。"""
    p = pathlib.Path(evid_target_dir).parent / 'RUN_CONTEXT.tsv'
    if not p.exists():
        return None, 'RUN_CONTEXT.tsv 缺失（%s）—— 非 run_proof.sh 产出的证据，拒绝' % p
    ctx = {}
    for ln in p.read_text().splitlines():
        if '\t' in ln:
            k, v = ln.split('\t', 1)
            ctx[k] = v.strip()
    need = ('commit', 'head_before', 'head_after',
            'worktree_digest_before', 'worktree_digest_after')
    for k in need:
        if k not in ctx:
            return None, 'RUN_CONTEXT.tsv 缺字段 %s' % k
    if ctx['head_before'] != ctx['head_after']:
        return None, 'RUN_CONTEXT: head 在跑期间变了 —— 证据作废'
    if ctx['worktree_digest_before'] != ctx['worktree_digest_after']:
        return None, 'RUN_CONTEXT: worktree 摘要在跑期间变了 —— 证据作废'
    if ctx['commit'] != ctx['head_before']:
        return None, 'RUN_CONTEXT: commit != head_before'
    return ctx, None


def _rel_to_repo(p, repo_path):
    try:
        return str(pathlib.Path(p).resolve().relative_to(pathlib.Path(repo_path).resolve()))
    except ValueError:
        return str(p)


def _relativize_script(repo, commit, abs_path, sha):
    """script_closure.list 记的是 proof worktree 里的**绝对路径**
    （如 /tmp/xsv2-proof-XXXX/scripts/fm_eq.tcl）。worktree 跑完就删，路径无意义。

    这里按"内容验证"的方式相对化：从最长后缀往短试，取第一个在 <commit> 下存在
    **且字节 sha256 与记录相符**的仓库路径。因为要求 sha 相符，这不是"猜路径"——
    猜错的路径根本过不了这一关；过了就说明确实是那个 tracked 文件。
    """
    parts = [p for p in str(abs_path).split('/') if p]
    for i in range(len(parts)):
        cand = '/'.join(parts[i:])
        blob = repo.show(commit, cand)
        if blob is not None and _sha_bytes(blob) == sha:
            return cand, 'repo'
    return str(abs_path), 'external'


def build_certificate(repo_path, evidence_dir, archive=None, g1_root=None,
                      policy_path=None, now=None):
    repo_path = pathlib.Path(repo_path).resolve()
    ev = pathlib.Path(evidence_dir).resolve()
    target = ev.name
    repo = PC.Repo(repo_path)
    if not repo.available():
        die('%s 不是 git 仓库' % repo_path)

    rp = ev / 'receipt.json'
    if not rp.exists():
        die('%s 没有 receipt.json' % ev)
    raw = rp.read_bytes()
    rec = json.loads(raw.decode('utf-8'))

    if rec.get('schema') != 'xs-v2-sv-receipt-v1':
        die('receipt schema 不认识: %r' % rec.get('schema'))
    if rec.get('top') != target:
        die('receipt.top=%r 与证据目录名 %r 不符' % (rec.get('top'), target))
    if rec.get('verdict') not in PC.QUALIFYING_VERDICTS:
        die('verdict=%r 不在合格集合 %s —— 不得出证书'
            % (rec.get('verdict'), list(PC.QUALIFYING_VERDICTS)))
    if rec.get('provisional') or rec.get('impl_worktree_dirty'):
        die('receipt 是 provisional/dirty —— 不得出证书')
    if int(rec.get('fm_shell_rc', 1)) != 0:
        die('fm_shell_rc=%s != 0' % rec.get('fm_shell_rc'))

    mrc = ev / 'MAKE_RC'
    if mrc.exists() and mrc.read_text().strip() not in ('0',):
        die('MAKE_RC=%s != 0 —— 这次 run 本身没成功' % mrc.read_text().strip())

    ctx, err = _read_run_context(ev)
    if err:
        die(err)
    impl_commit = rec.get('impl_commit', '')
    if ctx['commit'] != impl_commit:
        die('RUN_CONTEXT.commit=%s != receipt.impl_commit=%s'
            % (ctx['commit'][:12], impl_commit[:12]))
    if repo.rev_parse(impl_commit) != impl_commit:
        die('impl_commit %s 在本仓解析不到 —— 证书必须绑定本仓真实 commit' % impl_commit[:12])

    # --- 闭包：老格式（缺 kind / 绝对路径）直接拒 ---------------------------
    impl_cl = rec.get('impl_closure') or []
    gold_cl = rec.get('golden_closure') or []
    for e in impl_cl:
        if 'kind' not in e:
            die('receipt 是老格式（impl_closure 条目无 kind），无法在别的 commit 上复算 —— 拒绝')
    n_repo = sum(1 for e in impl_cl if e.get('kind') == 'repo')
    if n_repo == 0:
        die('impl 闭包里没有 kind==repo 的条目 —— 无法建立组合性保证，拒绝')
    for e in gold_cl:
        e.setdefault('kind', 'golden')

    ok, changed, missing = PC.recompute_closure_at(repo, impl_commit, impl_cl)
    if missing or changed:
        die('生成时自检失败：impl 闭包在 %s 下对不上（缺失=%s 改动=%s）'
            % (impl_commit[:12], missing[:2], changed[:2]))

    # --- sidecar ----------------------------------------------------------
    sc = ev / 'sidecar' / 'native_facts.json'
    if not sc.exists():
        die('sidecar/native_facts.json 缺失 —— 拒绝出证书')
    facts_raw = sc.read_bytes()
    facts = json.loads(facts_raw.decode('utf-8'))
    if facts.get('run_id') != rec.get('run_id'):
        die('sidecar run_id=%r != receipt run_id=%r' % (facts.get('run_id'), rec.get('run_id')))
    if facts.get('native_verdict') != 'SUCCEEDED':
        die('native_verdict=%r —— 只有 native SUCCEEDED 才出证书' % facts.get('native_verdict'))

    scl = ev / 'sidecar' / 'script_closure.list'
    if not scl.exists():
        die('sidecar/script_closure.list 缺失 —— 无 script closure hash，拒绝出证书')
    script_entries = []
    for ln in scl.read_text().splitlines():
        c = ln.rstrip('\n').split('\t')
        if len(c) != 3:
            continue
        abs_p, _snap, sha = c
        rel, kind = _relativize_script(repo, impl_commit, abs_p, sha)
        script_entries.append({'path': rel, 'kind': kind, 'sha256': sha})
    if not script_entries:
        die('script_closure.list 为空 —— 拒绝')

    # --- 工具版本 ---------------------------------------------------------
    log = ev / 'fm.log'
    if not log.exists():
        die('fm.log 缺失 —— 无法绑定工具版本')
    head = log.read_text(errors='replace')[:8000]
    mv, mb = _VER.search(head), _BUILD.search(head)
    if not mv or not mb:
        die('fm.log 里解析不到 Formality 版本 / Build —— 拒绝（不许用 "unknown" 占位）')
    tool = {'name': 'fm_shell', 'version': mv.group(1), 'platform': mv.group(2),
            'build': mb.group(1), 'fm_shell_rc': int(rec.get('fm_shell_rc', 0))}

    # --- G1 ---------------------------------------------------------------
    g1 = pathlib.Path(g1_root or os.environ.get('G1_CANONICAL')
                      or '/home/eda/xs-env/G1-canonical')
    man = g1 / 'MANIFEST.tsv'
    if not man.exists():
        die('G1 MANIFEST.tsv 不存在（%s）—— 无法绑定 golden manifest hash' % man)
    g1_manifest_sha = _sha_bytes(man.read_bytes())

    # --- ut_dir（从该 commit 的 Makefile 反查，不手填）-----------------------
    try:
        tmap, unresolved = FTU.targets_at(str(repo_path), impl_commit)
    except FTU.GitError as e:
        die('无法在 %s 上重建 FM target 全集: %s' % (impl_commit[:12], e))
    if target not in tmap:
        die('%s 在 commit %s 下不是任何 UT 的 FM_VARIANTS 成员 —— '
            '不是 FM target 就不该有证书' % (target, impl_commit[:12]))
    ut_dir = tmap[target][0]

    proof_config = dict(rec.get('proof_config') or {})
    native_result = {'native_verdict': facts.get('native_verdict'),
                     'stats': facts.get('stats'),
                     'unmatched': facts.get('unmatched')}

    arc = None
    retention = 'attestation_only'
    if archive:
        ap = pathlib.Path(archive)
        if not ap.exists():
            die('--archive %s 不存在 —— 不得凭空声称留有完整原件' % ap)
        arc = {'name': ap.name, 'sha256': _sha_bytes(ap.read_bytes()),
               'size': ap.stat().st_size, 'algo': ''.join(ap.suffixes)[1:] or 'raw'}
        retention = 'archived'

    doc = {
        'schema': PC.CERT_SCHEMA,
        'target': target,
        'variant': rec.get('top'),
        'ut_dir': ut_dir,
        'verdict': rec.get('verdict'),
        'proof_mode': proof_config.get('fm_mode'),
        'provisional': bool(rec.get('provisional')),
        'impl_worktree_dirty': bool(rec.get('impl_worktree_dirty')),
        'impl_commit': impl_commit,
        'proof_commit': ctx['commit'],
        'proof_worktree_digest': ctx['worktree_digest_before'],
        'g1_canonical_id': rec.get('g1_canonical_id'),
        'g1_manifest_sha256': g1_manifest_sha,
        'run_id': rec.get('run_id'),
        'tool': tool,
        'proof_config': proof_config,
        'proof_config_sha256': PC.canon_digest(proof_config),
        'input_closure': {
            'golden': gold_cl,
            'impl': impl_cl,
            'golden_sha256': PC.closure_digest(gold_cl),
            'impl_sha256': PC.closure_digest(impl_cl),
            'repo_impl_files': n_repo,
        },
        'script_closure': {
            'entries': script_entries,
            'sha256': PC.closure_digest(script_entries),
        },
        'native_facts_sha256': _sha_bytes(facts_raw),
        'native_result': native_result,
        'result_sha256': PC.canon_digest({'verdict': rec.get('verdict'),
                                          'native_result': native_result}),
        'receipt_sha256': _sha_bytes(raw),
        'evidence_retention': retention,
        'evidence_archive': arc,
        'reproduce': {
            'command': ('PROOF_COMMIT=%s scripts/run_proof.sh %s %s'
                        % (impl_commit, ut_dir, target)),
            'env': {'G1_CANONICAL': str(g1),
                    'note': '需 G1 golden 与 g1_canonical_id/g1_manifest_sha256 相符'},
        },
        'generated_at': (now or datetime.datetime.utcnow()).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'generator': {
            'script': GENERATOR_PATH,
            'version': GENERATOR_VERSION,
            # 路径一律记 repo-relative（绝对路径把生成机器的 /tmp 钉进了 tracked 文件，
            # 换台机器就成了死线索）。仓库外的证据目录才退回绝对路径。
            'source_evidence_dir': _rel_to_repo(ev, repo_path),
            'run_context_worktree_digest': ctx['worktree_digest_before'],
        },
    }

    # codex 0222 §4：impl 闭包里挂已登记 MC 存储契约对象 ⇒ external_dependency=MC_MEMORY_CONTRACT
    # （登记表取自本仓 HEAD 的 committed 字节；validator 在父 commit 上按同一张表复算并要求一致）
    mc_blob = PC.Repo(repo_path).show('HEAD', PC.MC_REGISTRY_PATH)
    if mc_blob is not None:
        import mc_memory_registry as _MC
        mc_objs = _MC.mc_objects_in_closure(impl_cl, reg=_MC.parse_registry_text(mc_blob.decode('utf-8')))
        if mc_objs:
            doc['external_dependency'] = PC.EXTERNAL_DEPENDENCY_MC
            doc['mc_memory_objects'] = mc_objs

    errs = PC.validate_document(doc)
    if errs:
        die('生成的证书没过自己的 schema：%s' % '; '.join(errs[:5]))

    if policy_path:
        pol = json.loads(pathlib.Path(policy_path).read_text())
        perrs = PC.validate_policy(pol)
        if perrs:
            die('POLICY.json 无效: %s' % perrs[0])
        if doc['tool']['version'] != pol['tool']['version'] or \
                doc['tool']['build'] != pol['tool']['build']:
            die('工具版本 %s/%s 与 POLICY %s/%s 不符 —— 拒绝出证书'
                % (doc['tool']['version'], doc['tool']['build'],
                   pol['tool']['version'], pol['tool']['build']))
    return doc


def write_certificate(repo_path, doc, out_dir=None):
    d = pathlib.Path(out_dir or (pathlib.Path(repo_path) / PC.CERT_DIR))
    d.mkdir(parents=True, exist_ok=True)
    out = d / ('%s.json' % doc['target'])
    # 序列化方式固定：sha256 是对**文件字节**取的，格式一变 sha 就变，
    # allow 里的 certificate_sha256 也就对不上了。indent=1 + 尾随换行，与仓库其余 json 一致。
    body = json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True) + '\n'
    tmp = d / ('%s.json.tmp' % doc['target'])
    tmp.write_text(body)
    os.replace(str(tmp), str(out))
    return out, hashlib.sha256(body.encode('utf-8')).hexdigest()


def stamp_allow(repo_path, allow_files):
    """把 `verif/proof_certificates/<child>.json` 的**文件字节** sha256 回填到
    allow 里每条 green_child 的 `certificate_sha256`。

    D57：「green_child 声明必须精确引用 child target + certificate SHA-256」。
    """
    repo_path = pathlib.Path(repo_path)
    rc = 0
    for f in allow_files:
        p = pathlib.Path(f)
        doc = json.loads(p.read_text())
        n = 0
        for o in doc.get('objects', []):
            if o.get('class') != 'green_child':
                continue
            ct = o.get('child_target')
            if not ct:
                sys.stderr.write('ERROR: %s 有 green_child 无 child_target\n' % f)
                rc = 1
                continue
            cp = repo_path / PC.CERT_DIR / ('%s.json' % ct)
            if not cp.exists():
                sys.stderr.write('ERROR: %s 引用的 child %s 没有证书 %s\n' % (f, ct, cp))
                rc = 1
                continue
            o['certificate_sha256'] = hashlib.sha256(cp.read_bytes()).hexdigest()
            n += 1
        p.write_text(json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True) + '\n')
        print('stamped %s: %d 条 green_child' % (f, n))
    return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', default=os.environ.get('XSSV_HOME') or str(_HERE.parent))
    ap.add_argument('--evidence', default=None,
                    help='一次 clean official run 的 <EVIDENCE_ROOT>/<target> 目录')
    ap.add_argument('--archive', default=None,
                    help='原始 evidence 的 hash-addressed release archive 文件')
    ap.add_argument('--g1', default=None)
    ap.add_argument('--policy', default=None, help='校验工具版本是否与 POLICY.json 一致')
    ap.add_argument('--out-dir', default=None)
    ap.add_argument('--print-only', action='store_true')
    ap.add_argument('--stamp-allow', nargs='*', default=None)
    a = ap.parse_args()

    if a.stamp_allow is not None:
        return stamp_allow(a.repo, a.stamp_allow)
    if not a.evidence:
        ap.print_help()
        return 2
    doc = build_certificate(a.repo, a.evidence, a.archive, a.g1, a.policy)
    if a.print_only:
        print(json.dumps(doc, ensure_ascii=False, indent=1, sort_keys=True))
        return 0
    out, sha = write_certificate(a.repo, doc, a.out_dir)
    print('certificate: %s\n  target=%s verdict=%s mode=%s impl_commit=%s\n'
          '  sha256=%s\n  retention=%s  repo_impl_files=%d  script_files=%d'
          % (out, doc['target'], doc['verdict'], doc['proof_mode'],
             doc['impl_commit'][:12], sha, doc['evidence_retention'],
             doc['input_closure']['repo_impl_files'],
             len(doc['script_closure']['entries'])))
    return 0


if __name__ == '__main__':
    sys.exit(main())

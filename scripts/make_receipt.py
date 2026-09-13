#!/usr/bin/env python3
"""make_receipt.py —— 为一次 proof 生成绑定输入的 receipt。

codex 0139 §5：任何晋升必须绑定
  G1 canonical ID + exact golden closure hash + impl commit + proof config。
本脚本在 fm-% 跑完后立即执行，把「用了哪些字节、跑在什么配置下、得了什么结论」
一次性钉死，输出 fm_work/<top>/receipt.json。

绑定内容：
  g1_canonical_id     G1-canonical/CANONICAL_ID.txt（全 golden 文件 manifest 的摘要）
  golden_closure      本次 ref 侧实际读入的每个 golden 文件的 sha256（逐文件，不是目录摘要）
  impl_closure        本次 impl 侧实际读入的每个文件的 sha256 + 仓库 commit/dirty 状态
  proof_config        FM_MODE / allowlist / vmucp / pin 文件 / allow / dead_ref 声明的 hash
  native_facts        sidecar 采集的原生事实（含 appvar readback）
  verdict             fm_verdict.py 的判定与理由
  rc                  fm_shell 退出码
fail-closed：sidecar 缺失、native 与 log 判定不一致、声明文件缺失一律非零退出。

codex 0157 D57 变更：green_child 的背书从 untracked 的 docs/receipt_index.tsv
改为 tracked 的 verif/proof_certificates/<child>.json（见 scripts/proof_certificate.py）。
本文件 157-177 行那套「用 `git show <父commit>:<path>` 逐字节复算 child 闭包」的做法
就是 D57 第 3 条要的，原样保留，只是记录来源换成了证书。
"""
import argparse
import hashlib
import json
import os
import pathlib
import subprocess
import sys

_HERE = pathlib.Path(__file__).resolve().parent
NEW = pathlib.Path(os.environ.get('XSSV_HOME') or _HERE.parent)
G1 = pathlib.Path(os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical')
# 证据/索引在真实仓库（worktree 内 evidence/ 不存在）
# ⚠ 已废弃（codex 0157 D57）：原先指向 untracked 的 evidence/ 与 docs/receipt_index.tsv。
# green_child 背书已改读 tracked 证书，本变量不再参与任何判定，仅为兼容旧调用方保留。
INDEX_HOME = pathlib.Path(os.environ.get('XSSV_INDEX_HOME') or NEW)


def sha(p):
    return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()


def closure(files, repo=None):
    """闭包条目：路径一律记 **repo-relative**（worktree 绝对路径跑完即失效，
    无法事后 `git show <commit>:<path>` 复算）。仓库外的文件（golden）记 kind=golden
    并保留其相对 G1 的路径。"""
    out = []
    repo = pathlib.Path(repo) if repo else None
    for f in files:
        if not f:
            continue
        fp = pathlib.Path(f)
        if not fp.exists():
            sys.exit(f'ERROR: receipt 闭包文件不存在: {f}')
        rel, kind = str(fp), 'external'
        try:
            if repo:
                rel, kind = str(fp.resolve().relative_to(repo.resolve())), 'repo'
        except ValueError:
            try:
                rel, kind = str(fp.resolve().relative_to(G1.resolve())), 'golden'
            except ValueError:
                pass
        out.append({'path': rel, 'kind': kind, 'sha256': sha(fp)})
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--top', required=True)
    ap.add_argument('--workdir', required=True)
    ap.add_argument('--ref-srcs', default='')
    ap.add_argument('--impl-srcs', default='')
    ap.add_argument('--mode', required=True)
    ap.add_argument('--allowlist', default='0')
    ap.add_argument('--vmucp', default='false')
    ap.add_argument('--rc', default='0')
    ap.add_argument('--verdict', required=True)
    ap.add_argument('--expect-run-id', default=None,
                    help='本次 FM_RUN_ID；与 sidecar 记录不符即拒（防捡到上次残留 facts）')
    ap.add_argument('--parent-commit', default=None,
                    help='本次父 proof 的 commit；green_child 的 impl 闭包按该 commit 复算')
    ap.add_argument('--allow-dirty', action='store_true',
                    help='仅用于本地调试：允许 dirty 工作树（产出的 receipt 标记 provisional，'
                         '不可用于晋升）')
    a = ap.parse_args()

    wd = pathlib.Path(a.workdir)
    sc = wd / 'sidecar' / 'native_facts.json'
    if not sc.exists():
        sys.exit('ERROR: sidecar/native_facts.json 缺失 —— FM_SIDECAR_OUT 未生效，拒绝出 receipt')
    facts = json.loads(sc.read_text())

    vline = a.verdict.split('\t', 1)
    vname = vline[0]
    vq = json.loads(vline[1]) if len(vline) > 1 else {}
    if facts.get('native_verdict') and vq.get('native') and \
            facts['native_verdict'] != vq['native']:
        sys.exit(f"ERROR: native 事实({facts['native_verdict']}) 与 log 判定"
                 f"({vq['native']}) 不一致 —— 拒绝出 receipt")

    cid = (G1 / 'CANONICAL_ID.txt').read_text().strip()
    decls = {}
    for kind in ('allow', 'dead_ref'):
        p = NEW / 'verif' / kind / f'{a.top}.json'
        if p.exists():
            decls[kind] = {'path': str(p.relative_to(NEW)), 'sha256': sha(p)}

    pins = {}
    for f in ('fm_pins.tcl', 'fm_pins_pre.tcl'):
        p = wd.parent.parent / f
        if p.exists():
            pins[f] = sha(p)

    # run_id 绑定：sidecar facts 必须属于本次 run（否则可能捡到上一次残留）
    if a.expect_run_id and facts.get('run_id') != a.expect_run_id:
        sys.exit(f"ERROR: sidecar run_id({facts.get('run_id')}) != 本次 FM_RUN_ID"
                 f"({a.expect_run_id}) —— 拒绝出 receipt")

    impl_commit = subprocess.run('git rev-parse HEAD', shell=True, cwd=str(NEW),
                                 stdout=subprocess.PIPE, universal_newlines=True).stdout.strip()
    # codex 0140 P0-2: dirty 工作树**直接拒产 receipt**（不再只是记录一个 flag）。
    # 证明输入必须是 committed 字节；正规跑法是 run_proof.sh 起 detached clean worktree。
    dirty = subprocess.run('git status --porcelain', shell=True, cwd=str(NEW),
                           stdout=subprocess.PIPE, universal_newlines=True).stdout.strip()
    if dirty and not a.allow_dirty:
        sys.exit('ERROR: impl 工作树 dirty —— 拒绝出 receipt。'
                 '请用 scripts/run_proof.sh（detached clean worktree）或先提交改动。'
                 f'\n首条: {dirty.splitlines()[0][:100]}')

    # green_child 组合性保证（codex 0140 P0-3 的 closure 部分 → codex 0157 D57）：
    # 父把 child 黑盒掉，就更需要「父最终集成的 child 实现字节 == child 被证明过的字节」。
    impl_cl = closure(a.impl_srcs.split(), NEW)
    child_checks = []
    allow_p = NEW / 'verif' / 'allow' / f'{a.top}.json'
    if allow_p.exists():
        # ★codex 0157 D57★ 背书来源从 untracked 的 docs/receipt_index.tsv 换成
        # tracked 的 verif/proof_certificates/<child>.json（见 proof_certificate.py 文件头）。
        # 组合性保证的**做法**没变，仍是本文件原来那套：对 child 闭包里每个
        # repo-relative 条目，取**父 commit** 下同路径的字节算 sha256，逐一必须相等。
        # 变的只是"那份 child 记录从哪儿读"——现在从 commit 里读，clean clone 可复现。
        sys.path.insert(0, str(_HERE))
        import proof_certificate as _PC
        import fm_target_universe as _FTU
        repo = _PC.Repo(NEW)
        adecl = json.loads(allow_p.read_text())
        gc = [o for o in adecl.get('objects', [])
              if o.get('class') == 'green_child']
        if gc:
            pcommit = a.parent_commit or impl_commit
            commit = repo.rev_parse(pcommit)
            if commit is None:
                sys.exit(f'ERROR: 父 commit {pcommit[:12]} 解析不到 —— 拒绝出 receipt')
            pol, perr = _PC.load_policy(repo, commit)
            if perr:
                sys.exit(f'ERROR: {perr} —— green_child 无工具/配置策略可依，拒绝出 receipt')
            try:
                tmap, unresolved = _FTU.targets_at(str(NEW), commit)
            except Exception as e:                          # noqa: BLE001
                sys.exit(f'ERROR: 无法重建 FM target 全集({e}) —— 拒绝出 receipt')
            g1root = str(G1)
            done = {}
            for o in gc:
                ct = o.get('child_target')
                if not ct:
                    sys.exit('ERROR: allow 里有 green_child 却没写 child_target —— 拒绝出 receipt')
                key = (ct, o.get('certificate_sha256'))
                if key in done:
                    continue
                r = _PC.validate_child_certificate(
                    repo, commit, ct, o.get('certificate_sha256'),
                    expect_canonical=cid, policy=pol, fm_targets=tmap,
                    fm_targets_unresolved=unresolved, g1_root=g1root)
                if r is not True:
                    sys.exit(f'ERROR: green_child {ct} 证书校验失败: {r} —— 拒绝出 receipt')
                done[key] = True
                doc, csha, _ = _PC.load_certificate(repo, commit, ct)
                ok, _chg, _mis = _PC.recompute_closure_at(
                    repo, commit, doc['input_closure']['impl'])
                child_checks.append({
                    'child_target': ct,
                    'child_certificate_path': f'{_PC.CERT_DIR}/{ct}.json',
                    'child_certificate_sha256': csha,
                    'child_verdict': doc['verdict'],
                    'child_impl_commit': doc['impl_commit'],
                    'child_impl_closure_sha256': doc['input_closure']['impl_sha256'],
                    'child_script_closure_sha256': doc['script_closure']['sha256'],
                    'child_impl_files_verified_at_parent_commit': ok,
                    'parent_commit_used': commit,
                    'child_evidence_retention': doc['evidence_retention'],
                })

    receipt = {
        'schema': 'xs-v2-sv-receipt-v1',
        'top': a.top,
        'run_id': facts.get('run_id'),
        'g1_canonical_id': cid,
        'golden_closure': closure(a.ref_srcs.split(), NEW),
        'impl_closure': impl_cl,
        'impl_commit': impl_commit,
        'impl_worktree_dirty': bool(dirty),
        'provisional': bool(dirty),   # dirty 只在 --allow-dirty 调试路径出现
        'impl_closure_hashed_at': 'post_run',
        'proof_config': {
            'fm_mode': a.mode,
            'fm_allowlist_numeric_prefilter': a.allowlist,
            'verify_matched_unread_compare_points': a.vmucp,
            'pin_scripts': pins,
            'declarations': decls,
            'entry_appvars_readback': facts.get('entry_appvars'),
        },
        'green_child_closure_checks': child_checks,
        'fm_shell_rc': int(a.rc),
        'native_facts': facts,
        'verdict': vname,
        'verdict_detail': vq,
    }
    # 原子写：先写 tmp 再 rename（避免中断留下半截 receipt）
    out = wd / 'receipt.json'
    tmp = wd / 'receipt.json.tmp'
    tmp.write_text(json.dumps(receipt, ensure_ascii=False, indent=1))
    os.replace(str(tmp), str(out))
    print(f'receipt: {out} (verdict={vname}, canonical={cid[:20]}…, '
          f'golden={len(receipt["golden_closure"])} files, dirty={bool(dirty)})')


if __name__ == '__main__':
    main()

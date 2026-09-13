#!/usr/bin/env python3
"""green_child_migration.py —— 逐条评估每一条 green_child 声明向证书机制的迁移状态。

回答的是 codex 0157 D57 落地后必须逐条回答的三个问题：

  1. 这条声明引用的 child **是不是 FM target**？
     不是 → 它永远拿不到证书，必须改走「两侧 inline elaborate」或「新增 AUX leaf target
     并正式证明」。**不得用 allow 绕过。**
  2. 它在**当前提交**下有没有 tracked 证书、allow 里有没有写 certificate_sha256？
  3. （advisory）本地 `evidence/` 里最新那份 receipt 是什么结论、它的 impl 闭包在
     当前 commit 下还成不成立？—— 这一栏**只是预判**，不是背书：
     D57 明令「旧 untracked receipt/index 不得自动转换成 green」。

用法:
    python3 scripts/green_child_migration.py [--commit HEAD] [--repo .] [--tsv out.tsv]
    python3 scripts/green_child_migration.py --prospective verif/allow_gen/classification.tsv
"""
import argparse
import collections
import hashlib
import json
import os
import pathlib
import sys

_HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(_HERE))
import proof_certificate as PC                              # noqa: E402
import fm_target_universe as FTU                            # noqa: E402


def _newest_receipt(repo_root, target):
    """本地 evidence/ 里该 target 最新（按 commit 时间）的一份 receipt。advisory only。"""
    import subprocess
    cands = list(pathlib.Path(repo_root).glob('evidence/*/%s/receipt.json' % target))
    best = None
    for p in cands:
        try:
            d = json.loads(p.read_text())
        except Exception:                                   # noqa: BLE001
            continue
        c = d.get('impl_commit', '')
        r = subprocess.run(['git', 'show', '-s', '--format=%ct', c], cwd=str(repo_root),
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                           universal_newlines=True)
        try:
            t = int(r.stdout.strip())
        except ValueError:
            t = -1
        if best is None or t > best[0]:
            best = (t, p, d)
    return (best[1], best[2]) if best else (None, None)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', default=os.environ.get('XSSV_HOME') or str(_HERE.parent))
    ap.add_argument('--commit', default='HEAD')
    ap.add_argument('--tsv', default=None)
    ap.add_argument('--no-evidence', action='store_true',
                    help='不看本地 evidence/（clean clone 下的真实视角）')
    a = ap.parse_args()

    repo = PC.Repo(a.repo)
    commit = repo.rev_parse(a.commit)
    if commit is None:
        print('ERROR: 无法解析 %s' % a.commit, file=sys.stderr)
        return 2
    tmap, unresolved = FTU.targets_at(a.repo, commit)

    # 遍历该 commit 下所有 tracked allow 文件
    import subprocess
    names = subprocess.run(['git', 'ls-tree', '-r', '--name-only', commit, 'verif/allow/'],
                           cwd=a.repo, stdout=subprocess.PIPE,
                           universal_newlines=True).stdout.split()
    rows = []
    for f in sorted(n for n in names if n.endswith('.json')):
        blob = repo.show(commit, f)
        if blob is None:
            continue
        try:
            d = json.loads(blob.decode('utf-8'))
        except Exception:                                   # noqa: BLE001
            continue
        parent = d.get('target') or pathlib.Path(f).stem
        for i, o in enumerate(d.get('objects', [])):
            if o.get('class') != 'green_child':
                continue
            ct = o.get('child_target') or ''
            rows.append({
                'parent': parent, 'allow_file': f, 'idx': i,
                'side': o.get('side'), 'design': o.get('design'), 'path': o.get('path'),
                'child': ct,
                'is_fm_target': 'YES' if ct in tmap else 'NO',
                'ut_dir': ','.join(tmap.get(ct, [])) or '-',
                'has_cert_sha_in_allow': 'YES' if o.get('certificate_sha256') else 'NO',
            })

    # child 级别的信息只算一次
    children = sorted({r['child'] for r in rows})
    cinfo = {}
    for ct in children:
        doc, sha, err = PC.load_certificate(repo, commit, ct)
        info = {'cert': 'PRESENT' if doc else 'ABSENT', 'cert_sha': sha or '-',
                'cert_err': err or '-'}
        if not a.no_evidence:
            rp, rec = _newest_receipt(a.repo, ct)
            if rec is None:
                info['ev_receipt'] = 'NONE'
                info['ev_verdict'] = '-'
                info['ev_closure_at_commit'] = '-'
            else:
                info['ev_receipt'] = str(rp)
                info['ev_verdict'] = rec.get('verdict', '?')
                cl = [e for e in rec.get('impl_closure', []) if e.get('kind') == 'repo']
                if not cl:
                    info['ev_closure_at_commit'] = 'NO_REPO_ENTRIES(老格式)'
                else:
                    ok, chg, mis = PC.recompute_closure_at(repo, commit, cl)
                    info['ev_closure_at_commit'] = (
                        'MATCH(%d)' % ok if not chg and not mis
                        else 'STALE(ok=%d,changed=%d,missing=%d)' % (ok, len(chg), len(mis)))
        cinfo[ct] = info

    for r in rows:
        r.update(cinfo[r['child']])
        if r['is_fm_target'] == 'NO':
            r['verdict'] = 'BLOCKED_NOT_FM_TARGET(须 inline elaborate 或新建 AUX target)'
        elif r['cert'] == 'PRESENT' and r['has_cert_sha_in_allow'] == 'YES':
            r['verdict'] = 'READY(待 validator 在 freeze commit 上复算)'
        elif r['cert'] == 'PRESENT':
            r['verdict'] = 'NEEDS_ALLOW_STAMP(证书在，allow 缺 certificate_sha256)'
        else:
            r['verdict'] = 'NEEDS_CLEAN_RERUN_THEN_CERT'

    cols = ['parent', 'child', 'is_fm_target', 'ut_dir', 'cert', 'has_cert_sha_in_allow',
            'ev_verdict', 'ev_closure_at_commit', 'verdict', 'allow_file', 'side', 'path']
    cols = [c for c in cols if any(c in r for r in rows)]
    out = ['# green_child 迁移评估 repo=%s commit=%s' % (a.repo, commit),
           '# FM target 全集=%d（unresolved=%d）；green_child 声明=%d 条，涉及 child %d 个'
           % (len(tmap), len(unresolved), len(rows), len(children)),
           '\t'.join(cols)]
    for r in rows:
        out.append('\t'.join(str(r.get(c, '-')) for c in cols))
    text = '\n'.join(out) + '\n'
    if a.tsv:
        pathlib.Path(a.tsv).write_text(text)
        print('wrote %s (%d 条) sha256=%s'
              % (a.tsv, len(rows), hashlib.sha256(text.encode()).hexdigest()))
    else:
        sys.stdout.write(text)

    agg = collections.Counter((r['child'], r['verdict']) for r in rows)
    sys.stderr.write('\n--- 按 child 汇总 ---\n')
    for (c, v), n in sorted(agg.items()):
        sys.stderr.write('%4d 条  %-24s %s\n' % (n, c, v))
    return 0


if __name__ == '__main__':
    sys.exit(main())

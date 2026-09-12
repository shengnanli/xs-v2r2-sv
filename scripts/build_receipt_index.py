#!/usr/bin/env python3
"""build_receipt_index.py —— 由证据目录里的 receipt 机械派生索引（codex 0140 P0-3）。

green_child 不能拿 WORKING 文本台账自证（会形成父子循环自证）。本索引只收
**受接受 runner（run_proof.sh，clean worktree）产出**的 receipt，字段全部来自 receipt
本身，不接受人工录入：

  target  verdict  canonical_id  impl_commit  provisional  receipt_sha256  path

冲突处理：同一 target 出现多份 receipt 时，若 (verdict, canonical, impl_commit) 不一致
则标 CONFLICT 并非零退出——不允许"挑一份好看的"。
"""
import hashlib
import json
import os
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = pathlib.Path(os.environ.get('XSSV_HOME') or HERE.parent)
PASS = {'SUCCEEDED', 'PASS_DEAD_REF'}


def main():
    root = REPO / 'evidence'
    rows, byt = {}, {}
    conflicts = []
    for rp in sorted(root.rglob('receipt.json')) if root.exists() else []:
        r = json.loads(rp.read_text())
        t = r['top']
        rec = {
            'target': t,
            'verdict': r.get('verdict', '?'),
            'canonical_id': r.get('g1_canonical_id', ''),
            'impl_commit': r.get('impl_commit', ''),
            'provisional': str(bool(r.get('provisional') or r.get('impl_worktree_dirty'))).lower(),
            'receipt_sha256': hashlib.sha256(rp.read_bytes()).hexdigest(),
            'path': str(rp.relative_to(REPO)),
        }
        key = (rec['verdict'], rec['canonical_id'], rec['impl_commit'], rec['provisional'])
        if t in byt and byt[t] != key:
            conflicts.append(t)
        byt[t] = key
        rows[t] = rec

    out = REPO / 'docs' / 'receipt_index.tsv'
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open('w') as f:
        f.write('# 由 evidence/**/receipt.json 机械派生（build_receipt_index.py）；禁止手工编辑\n')
        f.write('# target\tverdict\tcanonical_id\timpl_commit\tprovisional\treceipt_sha256\tpath\n')
        for t in sorted(rows):
            r = rows[t]
            f.write('\t'.join([r['target'], r['verdict'], r['canonical_id'], r['impl_commit'],
                               r['provisional'], r['receipt_sha256'], r['path']]) + '\n')
    npass = sum(1 for r in rows.values() if r['verdict'] in PASS and r['provisional'] == 'false')
    print(f'receipt 索引: {len(rows)} 个 target，其中可作 green_child 背书的 {npass} 个 -> '
          f'{out.relative_to(REPO)}')
    if conflicts:
        print('★冲突（同 target 多份 receipt 关键字段不一致）:', ' '.join(sorted(set(conflicts))))
        return 1
    return 0


def load(repo=None):
    """供 fm_verdict 使用：{target: rec}"""
    repo = pathlib.Path(repo or REPO)
    f = repo / 'docs' / 'receipt_index.tsv'
    out = {}
    if not f.exists():
        return out
    for ln in f.read_text().splitlines():
        if ln.startswith('#') or not ln.strip():
            continue
        c = ln.split('\t')
        if len(c) >= 7:
            out[c[0]] = {'verdict': c[1], 'canonical_id': c[2], 'impl_commit': c[3],
                         'provisional': c[4], 'receipt_sha256': c[5], 'path': c[6]}
    return out


if __name__ == '__main__':
    sys.exit(main())

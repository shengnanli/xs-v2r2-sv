#!/usr/bin/env python3
"""build_receipt_index.py —— 由证据目录里的 receipt 机械派生索引（codex 0140 P0-3）。

★codex 0157 D57 起，本索引**不再是权威输入**★
`evidence/` 与本脚本产出的 `docs/receipt_index.tsv` 都在 .gitignore 里，clean clone /
clean freeze 下必然为空；用它做 green_child 背书等于「冻结当天所有已绿目标一起翻红」。
green_child 的权威来源改成 tracked 的 `verif/proof_certificates/<target>.json`
（见 scripts/proof_certificate.py）。本脚本保留为**本地可再生的审计索引**：
看某个 target 跑过几次、有没有冲突、哪一份最新，都还靠它。
`load()` 已无生产调用方（fm_verdict / make_receipt 都已迁走）。

green_child 不能拿 WORKING 文本台账自证（会形成父子循环自证）。本索引只收
**受接受 runner（run_proof.sh，clean worktree）产出**的 receipt，字段全部来自 receipt
本身，不接受人工录入：

  target  verdict  canonical_id  impl_commit  provisional  receipt_sha256  path

冲突处理：
  - 同一 (target, impl_commit) 下两份 receipt 的关键字段不一致 → CONFLICT，非零退出
    （同一份字节不可能有两种结论，出现即证据被污染）；
  - 不同 impl_commit 的多份 receipt 是正常的重跑历史：取 **commit 时间最新的一份**，
    并在输出里记 superseded 份数，便于审计。
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
    import subprocess

    def commit_time(c):
        if not c:
            return -1
        p = subprocess.run(['git', 'show', '-s', '--format=%ct', c], cwd=str(REPO),
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                           universal_newlines=True)
        try:
            return int(p.stdout.strip())
        except ValueError:
            return -1

    rows, bykey = {}, {}
    conflicts, superseded = [], 0
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
        # 同一份字节（同 impl_commit）下结论必须唯一
        k = (t, rec['impl_commit'])
        sig = (rec['verdict'], rec['canonical_id'], rec['provisional'])
        if k in bykey and bykey[k] != sig:
            conflicts.append(f'{t}@{rec["impl_commit"][:12]}')
        bykey[k] = sig
        # 跨 commit 取最新。
        # ⚠ 已知局限（2026-09-12 诊断）：钉住 PROOF_COMMIT 的批跑里，若有人在更新的
        # commit 上重跑了某个 child 且该 commit 动过它的源文件，会**伪失效**所有钉住的
        # 父目标——哪怕 evidence/ 里就躺着一份与钉住 commit 字节相符的 receipt。
        # 正解是选择时优先 impl_commit == parent_commit；需要把 parent 传进来，
        # 属接口变更，留给 reviewer 裁定后再做。当前先记录。
        if t in rows:
            if commit_time(rec['impl_commit']) >= commit_time(rows[t]['impl_commit']):
                superseded += 1
                rows[t] = rec
            else:
                superseded += 1
        else:
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
    print(f'receipt 索引: {len(rows)} 个 target（取各自最新 commit；被取代 {superseded} 份），'
          f'其中可作 green_child 背书的 {npass} 个 -> {out.relative_to(REPO)}')
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

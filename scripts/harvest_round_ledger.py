#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""harvest_round_ledger.py —— 从**已提交的 receipt** 机械生成一份 round 台账。

## 为什么要有它

round 台账（docs/fm_round_<日期>.tsv）是 rewrite_coverage.py 的 proven 口径的
唯一输入之一。此前它是**手写**的：谁签核了一个目标，就手动去加一行。
手写台账有两个必然的病——

  · 漏记：写了但忘了加行 -> proven 虚低（2026-09-17 之前 round 台账还被写死成
    一份，新一轮签核直接记不上账，见 7134137）
  · 错记：行里的数字与 receipt 对不上，而台账才是被别人引用的那一份

两个病的根子是同一个：**台账与证据之间隔着一个人**。这个脚本把那个人去掉——
台账逐行从 receipt.json 生成，跑一次就能复算，对不上就是对不上。

## 口径（只认已提交的字节）

  · 只扫 `git ls-files evidence/*/receipt.json`，未提交的 receipt 不算数
    （未提交 = 没有绑到任何 commit，明天就可能变）
  · 只收 verdict ∈ {SUCCEEDED, PASS_DEAD_REF}
  · 同一个 top 有多份 receipt 时，取 **commit 最新**的那份；若数字不一致，
    在 note 里标出来而不是悄悄挑一个
  · impl_worktree_dirty=true 的一律**跳过并报警**——dirty 的 receipt
    记录的是"跑的是工作树、记的是 HEAD"，不能当证据

用法:
  python3 scripts/harvest_round_ledger.py --out docs/fm_round_20260917.tsv
  python3 scripts/harvest_round_ledger.py --check --out docs/fm_round_20260917.tsv
"""
import argparse
import json
import pathlib
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
OK_VERDICTS = ('SUCCEEDED', 'PASS_DEAD_REF')


def committed_receipts():
    out = subprocess.run(['git', '-C', str(REPO), 'ls-files', 'evidence/*/receipt.json'],
                         stdout=subprocess.PIPE, check=True).stdout.decode()
    return [l for l in out.splitlines() if l.strip()]


def commit_time(rev):
    r = subprocess.run(['git', '-C', str(REPO), 'show', '-s', '--format=%ct', rev],
                       stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    try:
        return int(r.stdout.decode().strip())
    except ValueError:
        return -1


def harvest():
    rows, warns = {}, []
    for rel in committed_receipts():
        try:
            d = json.loads((REPO / rel).read_text(encoding='utf-8', errors='replace'))
        except Exception as e:                                   # noqa: BLE001
            warns.append('%s 读不出来: %r' % (rel, e))
            continue
        top = d.get('top') or d.get('verdict_detail', {}).get('top')
        verdict = d.get('verdict')
        if not top or verdict not in OK_VERDICTS:
            continue
        if d.get('impl_worktree_dirty'):
            warns.append('%s (%s) impl_worktree_dirty=true，跳过' % (rel, top))
            continue
        q = d.get('verdict_detail', {})
        commit = (d.get('impl_commit') or '')[:12]
        cur = {
            'top': top, 'verdict': verdict, 'commit': commit,
            'passing': q.get('passing'), 'failing': q.get('failing'),
            'unmatched': q.get('unmatched'), 'unread': q.get('unread'),
            'constant_reg': q.get('constant_reg'),
            'mode': (d.get('proof_config') or {}).get('fm_mode'),
            'vmucp': (d.get('proof_config') or {}).get('verify_matched_unread_compare_points'),
            'path': rel, 'ct': commit_time(d.get('impl_commit') or 'HEAD'),
        }
        prev = rows.get(top)
        if prev is None:
            rows[top] = cur
        else:
            differ = any(prev[k] != cur[k] for k in ('passing', 'failing', 'unmatched'))
            keep, drop = (cur, prev) if cur['ct'] >= prev['ct'] else (prev, cur)
            if differ:
                warns.append('%s 有多份 receipt 且数字不一致：取较新的 %s(p%s)，另一份 %s(p%s)'
                             % (top, keep['commit'], keep['passing'],
                                drop['commit'], drop['passing']))
            rows[top] = keep
    return rows, warns


def render(rows):
    out = ['# 机械生成，勿手改：python3 scripts/harvest_round_ledger.py --out <此文件>',
           '# 只收已提交、impl_worktree_dirty=false、verdict ∈ {SUCCEEDED, PASS_DEAD_REF} 的 receipt',
           'target\tverdict\tnote']
    for top in sorted(rows):
        r = rows[top]
        note = ('p%s f%s um%s unread=%s const_reg=%s mode=%s vmucp=%s @%s %s'
                % (r['passing'], r['failing'], r['unmatched'], r['unread'],
                   r['constant_reg'], r['mode'], r['vmucp'], r['commit'], r['path']))
        out.append('%s\t%s\t%s' % (top, r['verdict'], note))
    return '\n'.join(out) + '\n'


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--out', required=True)
    ap.add_argument('--check', action='store_true', help='只比对，不写；不一致则非零退出')
    a = ap.parse_args()

    rows, warns = harvest()
    for w in warns:
        print('WARN: ' + w, file=sys.stderr)
    if not rows:
        print('harvest_round_ledger: 一份合格 receipt 都没扫到 —— 拒绝写出空台账',
              file=sys.stderr)
        return 2

    text = render(rows)
    p = pathlib.Path(a.out)
    if not p.is_absolute():
        p = REPO / p
    if a.check:
        old = p.read_text(encoding='utf-8') if p.exists() else ''
        if old != text:
            print('harvest_round_ledger --check: %s 与 receipt 不一致（重跑本脚本）' % a.out,
                  file=sys.stderr)
            return 1
        print('harvest_round_ledger --check: 逐字节一致（%d 个目标）' % len(rows))
        return 0
    p.write_text(text, encoding='utf-8')
    print('harvest_round_ledger: 写出 %s，%d 个目标' % (a.out, len(rows)))
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""合并 lane 分支前后用：找出 lane worktree 里**已产出但没进版本库**的 receipt。

★为什么需要这道闸★（2026-09-20 实测到的系统性低计）

evidence/ 被 .gitignore 忽略是**设计如此**（codex D66：证据不进 git）。
后果是每一份 receipt 要进库都得显式 `git add -f`。于是出现这种情况：

  lane 把 6 个 VEC 变体跑成 SUCCEEDED -> 合并它的分支 ->
  written 涨了 9793 行，★proven 一行没涨★

因为 receipt 只存在于 lane 自己的 worktree，main 的 harvest 根本看不见。
台账不是算错了，是**它能看见的证据里确实没有那 6 个**。

这种漏是静默的：合并成功、闸全绿、数字也在涨，只有 proven 与 written 的
差额在慢慢拉开，而没有任何一条输出会说「你漏收了 receipt」。
—— 又一次「缺失与否定在输出里长得一模一样」，所以要有一道**正面清点**。

用法:
    python3 scripts/check_lane_receipts.py /home/eda/xs-env/wt-<lane>
    python3 scripts/check_lane_receipts.py --all      # 扫所有 worktree

退出码: 0 = 没有未收录的 receipt；1 = 有（列出来，由集成者决定收哪些）。
本闸**只报告不自动收**：哪一份是"同前提"的权威证据要人判断
（见 CONVENTIONS ★别把不同前提下产出的结果并列成一张表★ ——
 同一批目标可能有好几轮 receipt，只有同一 commit 上重出的那一份能横向并列）。
"""
# ★本机是 Python 3.6：subprocess.run 没有 capture_output（3.7 才有）。★
# 今天已经被它坑过一次（等待链打印了「开始重算」然后当场崩掉）。
import json, os, subprocess, sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def tracked_receipt_dirs():
    out = subprocess.run(['git', 'ls-files', 'evidence/'], cwd=REPO,
                         stdout=subprocess.PIPE).stdout.decode()
    return {p.split('/')[1] for p in out.splitlines() if p.count('/') >= 1}


def green(receipt):
    try:
        j = json.load(open(receipt))
    except Exception:
        return None
    v = j.get('verdict') or (j.get('verdict_detail') or {}).get('native')
    return v if v in ('SUCCEEDED', 'PASS', 'PASS_DEAD_REF', 'SIGNOFF_PASS') else None


def scan(wt, tracked):
    ev = os.path.join(wt, 'evidence')
    if not os.path.isdir(ev):
        return []
    rows = []
    for run in sorted(os.listdir(ev)):
        rundir = os.path.join(ev, run)
        if not os.path.isdir(rundir):
            continue
        for tgt in sorted(os.listdir(rundir)):
            rc = os.path.join(rundir, tgt, 'receipt.json')
            if not os.path.isfile(rc):
                continue
            v = green(rc)
            if v and run not in tracked:
                rows.append((run, tgt, v))
    return rows


def main(argv):
    tracked = tracked_receipt_dirs()
    if argv and argv[0] == '--all':
        wts = [l.split()[0] for l in subprocess.run(
            ['git', 'worktree', 'list'], cwd=REPO,
            stdout=subprocess.PIPE).stdout.decode().splitlines()]
    elif argv:
        wts = argv
    else:
        print(__doc__.split('用法:')[1].strip())
        return 2

    total = []
    for wt in wts:
        if os.path.abspath(wt) == os.path.abspath(REPO):
            continue           # 主 worktree 自己不算 lane
        rows = scan(wt, tracked)
        if rows:
            print('=== %s ★%d 份绿 receipt 未进版本库★' % (wt, len(rows)))
            byrun = {}
            for run, tgt, v in rows:
                byrun.setdefault(run, []).append('%s(%s)' % (tgt, v))
            for run, tgts in sorted(byrun.items()):
                print('  evidence/%s  %d 个: %s' % (run, len(tgts), ' '.join(tgts[:8])
                                                    + (' …' if len(tgts) > 8 else '')))
            total += rows

    if not total:
        print('check_lane_receipts: 扫了 %d 个 worktree，没有未收录的绿 receipt' % len(wts))
        return 0
    print()
    print('★合计 %d 份绿 receipt 只在 lane worktree 里，台账看不见。★' % len(total))
    print('收录方式:  git add -f evidence/<run>')
    print('★先判断哪一份是同前提的权威证据，不要把几轮 receipt 一起收。★')
    return 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

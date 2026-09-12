#!/usr/bin/env python3
"""bulk_revalidate.py —— 批量在 clean worktree 上复验并出 receipt（codex 0141 §46）。

先批的是**无 green_child 依赖**的目标：strict / PASS_DEAD_REF / 仅厂商宏 assembly。
带 green_child 的父目标等组合性绑定跑通后再入批（本轮已具备，但仍按 codex 次序后放）。

分组依据（机器判定，不靠人工分类）：
  - 目标所属 UT 目录的 Makefile 里 FM_MODE；
  - 若有 verif/allow/<t>.json，检查其 objects 的 class 集合：
      全 vendor_macro → 无依赖，本批可跑；
      含 green_child   → 有依赖，推迟；
      无 allow 但 assembly → 先跑一次拿黑盒报告，再据实生成声明（不自动放行）。
用法:
  bulk_revalidate.py --plan              只打印分组
  bulk_revalidate.py --run [--jobs N]    实际跑（每目标独立 clean worktree）
"""
import argparse
import json
import os
import pathlib
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

REPO = pathlib.Path(__file__).resolve().parent.parent


def ut_dirs():
    """{target: ut_dir}，从各 UT Makefile 的 FM_VARIANTS 解析。"""
    out = {}
    for mk in sorted((REPO / 'verif' / 'ut').glob('*/Makefile')):
        txt = re.sub(r'\\\n', ' ', mk.read_text())
        m = re.search(r'^FM_VARIANTS\s*=\s*(.*)$', txt, re.M)
        mode = re.search(r'^FM_MODE\s*[:?]?=\s*(\S+)', txt, re.M)
        if not m:
            continue
        for t in m.group(1).split():
            out[t] = (mk.parent.name, (mode.group(1) if mode else 'signoff-strict'))
    return out


def classify():
    groups = {'no_dep': [], 'needs_allow': [], 'has_green_child': []}
    for t, (d, mode) in sorted(ut_dirs().items()):
        ap = REPO / 'verif' / 'allow' / f'{t}.json'
        if mode == 'assembly':
            if not ap.exists():
                groups['needs_allow'].append((t, d))
                continue
            classes = {o.get('class') for o in json.loads(ap.read_text()).get('objects', [])}
            if 'green_child' in classes:
                groups['has_green_child'].append((t, d))
            else:
                groups['no_dep'].append((t, d))
        else:
            groups['no_dep'].append((t, d))
    return groups


def run_one(args):
    t, d, evid = args
    env = dict(os.environ, EVIDENCE_ROOT=evid)
    p = subprocess.run(['bash', str(REPO / 'scripts' / 'run_proof.sh'), d, t],
                       env=env, cwd=str(REPO), stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, universal_newlines=True)
    verdict = '?'
    for ln in p.stdout.splitlines():
        m = re.match(r'^(SUCCEEDED|PASS_DEAD_REF|PARTIAL|FAILED|ERROR)\t', ln)
        if m:
            verdict = m.group(1)
    print(f'[{verdict:14s}] {t} (rc={p.returncode})', flush=True)
    return t, verdict, p.returncode


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--plan', action='store_true')
    ap.add_argument('--run', action='store_true')
    ap.add_argument('--jobs', type=int, default=6)
    ap.add_argument('--limit', type=int, default=0)
    a = ap.parse_args()

    g = classify()
    print(f"无依赖可直接复验: {len(g['no_dep'])}")
    print(f"assembly 但缺 allow 声明（须先补声明，不自动放行）: {len(g['needs_allow'])}"
          + ('  ' + ' '.join(t for t, _ in g['needs_allow'][:10]) if g['needs_allow'] else ''))
    print(f"含 green_child 依赖（后批）: {len(g['has_green_child'])}"
          + ('  ' + ' '.join(t for t, _ in g['has_green_child'][:10]) if g['has_green_child'] else ''))
    if a.plan or not a.run:
        return 0

    head = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=str(REPO),
                          stdout=subprocess.PIPE, universal_newlines=True).stdout.strip()
    evid = str(REPO / 'evidence' / head[:12])
    todo = g['no_dep'][:a.limit] if a.limit else g['no_dep']
    print(f'== 复验 {len(todo)} 个目标（commit {head[:12]}, jobs={a.jobs}）==', flush=True)
    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        rows = list(ex.map(run_one, [(t, d, evid) for t, d in todo]))
    from collections import Counter
    print('汇总:', dict(Counter(v for _, v, _ in rows).most_common()))
    bad = [t for t, v, rc in rows if v not in ('SUCCEEDED', 'PASS_DEAD_REF') or rc != 0]
    if bad:
        print('未通过:', ' '.join(bad))
    return 0


if __name__ == '__main__':
    sys.exit(main())

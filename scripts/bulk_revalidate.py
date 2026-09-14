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

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import fm_target_universe as FTU                                   # noqa: E402


def _rev(rev):
    """rev -> 40-hex commit。解析不了就 fail-closed（不猜 HEAD）。"""
    p = subprocess.run(['git', 'rev-parse', rev + '^{commit}'], cwd=str(REPO),
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if p.returncode != 0:
        raise SystemExit('无法解析 commit %r' % rev)
    return p.stdout.decode().strip()

REPO = pathlib.Path(__file__).resolve().parent.parent


def ut_dirs(commit='HEAD'):
    """{target: (ut_dir, fm_mode)} —— target 全集由 **make 权威求值**给出。

    ★这里原先自己写了一份正则★（codex 0153 D70 点名的那处）：

        m = re.search(r'^FM_VARIANTS\\s*=\\s*(.*)$', txt, re.M)

    三处不到位：`\\s*=` 匹配不上 `:=`、不展开 `$(VARIANTS)`、`re.search` 只取
    第一处赋值。实测后果：**248 个 target 而不是 272**，整个 MbistPipe 家族
    24 个变体（含 MbistPipeIcacheTag）凭空消失 —— 机器 diff 见
    `docs/fm_target_universe_defect_diff.tsv`。被漏掉的 target 在这里表现为
    "批量复验永远轮不到它"，在 verif/allow_gen/classification.tsv 里表现为
    "根本不是任何 UT 的 FM target ⇒ 永远无法变绿"。

    现在统一走 scripts/fm_target_universe.py（make 权威 + 正则交叉校验），
    本文件不再持有第二份解析。FM_MODE 仍按目录取，它不参与"谁是 target"的判定。
    """
    tmap, unresolved = FTU.targets_at(str(REPO), _rev(commit))
    if unresolved:
        raise SystemExit('FM target 全集未完全展开（fail-closed）: %s'
                         % ' '.join(unresolved[:5]))
    out = {}
    for t, dirs in tmap.items():
        d = sorted(dirs)[0]
        mk = REPO / 'verif' / 'ut' / d / 'Makefile'
        mode = None
        if mk.exists():
            mode = re.search(r'^FM_MODE\s*[:?]?=\s*(\S+)', mk.read_text(), re.M)
        out[t] = (d, (mode.group(1) if mode else 'signoff-strict'))
    return out


def ledger_status():
    st = {}
    f = REPO / 'docs' / 'fastlane_ledger.tsv'
    if f.exists():
        for ln in f.read_text().splitlines():
            if ln.startswith('#') or not ln.strip():
                continue
            c = ln.split('\t')
            st[c[0]] = c[1]
    return st


def classify():
    # 只复验"已迁到 G1 且此前通过"的目标。RTL 还没迁的 REWRITE_TODO/SPECIAL 等
    # 必然 FM FAILED——那不是回归，把它们混进批跑只会淹没真信号。
    st = ledger_status()
    groups = {'no_dep': [], 'needs_allow': [], 'has_green_child': [], 'not_candidate': []}
    for t, (d, mode) in sorted(ut_dirs().items()):
        if not st.get(t, '').startswith('WORKING_'):
            groups['not_candidate'].append((t, d))
            continue
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
    # 并发默认 16（用户指示）。依据是实测而非估计：676 次 FM 的峰值内存中位 867 MB、
    # 90 分位 869 MB、最大 1455 MB（AXI4Deinterleaver），只有 2 次超过 1.2 GB。
    # 16 × 1.5 GB ≈ 24 GB，本机 125 GB（可用 90+ GB）宽裕；32 核跑 16 个基本单线程的
    # FM 也不挤。license 9999 席不是约束。
    # 例外：整芯片级目标（如 XSTop 全量 elaborate 实测 9.6 GB）必须单独串行，
    # 不要混进批跑——上轮 OOM 事故正是 63k 行大模块并发造成的。
    ap.add_argument('--jobs', type=int, default=16)
    ap.add_argument('--limit', type=int, default=0)
    ap.add_argument('--collect-allow', action='store_true',
                    help='跑 needs_allow 组以采集黑盒报告（判定会是 PARTIAL）')
    ap.add_argument('--with-children', action='store_true',
                    help='把含 green_child 依赖的父目标一并纳入（组合性绑定已就绪后可用）')
    a = ap.parse_args()

    g = classify()
    print(f"无依赖可直接复验: {len(g['no_dep'])}")
    print(f"assembly 但缺 allow 声明（须先补声明，不自动放行）: {len(g['needs_allow'])}"
          + ('  ' + ' '.join(t for t, _ in g['needs_allow'][:10]) if g['needs_allow'] else ''))
    print(f"非复验对象（RTL 未迁 G1 / 非 WORKING 态）: {len(g['not_candidate'])}")
    print(f"含 green_child 依赖: {len(g['has_green_child'])}"
          + ('  ' + ' '.join(t for t, _ in g['has_green_child'][:10]) if g['has_green_child'] else ''))
    if a.plan or not a.run:
        return 0

    head = subprocess.run(['git', 'rev-parse', 'HEAD'], cwd=str(REPO),
                          stdout=subprocess.PIPE, universal_newlines=True).stdout.strip()
    evid = str(REPO / 'evidence' / head[:12])
    if a.collect_allow:
        # 先跑一遍 needs_allow 组：判定必然 PARTIAL（缺声明），但会产出 black_boxes.rpt，
        # 据此生成精确声明后再正式复验。不自动放行——声明内容仍须是观测到的真实对象集。
        g = dict(g, no_dep=g['needs_allow'], has_green_child=[])

    # 顺序依赖：green_child 父目标必须**在其 child 之后**跑，且跑之前刷新 receipt 索引。
    # 否则父会拿到旧 child receipt——若 child 源文件在此期间变过（哪怕只是注释），
    # 组合性检查会正确地判该 receipt 失效，父就白跑一次。
    phase1 = g['no_dep'] if not a.limit else g['no_dep'][:a.limit]
    phase2 = g['has_green_child'] if a.with_children else []
    rows = []
    for phase_name, batch in (('无依赖', phase1), ('含 green_child 依赖', phase2)):
        if not batch:
            continue
        print(f'== 阶段「{phase_name}」：{len(batch)} 个（commit {head[:12]}, '
              f'jobs={a.jobs}）==', flush=True)
        with ThreadPoolExecutor(max_workers=a.jobs) as ex:
            rows += list(ex.map(run_one, [(t, d, evid) for t, d in batch]))
        # 刷新索引，让下一阶段的父目标看到本阶段新出的 child receipt
        subprocess.run([sys.executable, str(REPO / 'scripts' / 'build_receipt_index.py')],
                       cwd=str(REPO), stdout=subprocess.DEVNULL)
    from collections import Counter
    print('汇总:', dict(Counter(v for _, v, _ in rows).most_common()))
    bad = [t for t, v, rc in rows if v not in ('SUCCEEDED', 'PASS_DEAD_REF') or rc != 0]
    if bad:
        print('未通过:', ' '.join(bad))
    return 0


if __name__ == '__main__':
    sys.exit(main())

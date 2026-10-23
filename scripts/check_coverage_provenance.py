#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""闸：`docs/coverage_three_axis.tsv` 宣称的每一条证明，都必须能从**版本库**复现。

为什么要有这道闸
----------------
2026-09-18 实测，这张表当时的状态是：

    轴2 标 PROVEN_DIRECT 的 top      133 个
    其中在版本库里找得到通过 receipt  34 个
    ★找不到的                        99 个★
    有通过 receipt 但表里没记         38 个

那 99 个不是"证明不存在"—— 它们的 evidence 全都躺在主 worktree 的磁盘上
（`evidence/` 下当时有 1339 份 receipt，而 tracked 的只有 77 份）。根子是
`evidence/` 在 `.gitignore` 里，必须 `git add -f` 才进得去，而没人系统地做这件事。

后果很具体：**clean clone 复现不了台账宣称的绝大多数证明**。台账说"已证 133 个"，
但别人（和未来的你）拿到这个仓库只能核实 34 个。这不是数字不准，是**证据链断了**。

修法分两半，缺一不可：
  (1) 把磁盘上已有的 99 份 evidence `git add -f` 补进库（一次性，9.6 MB）
  (2) 就是这道闸 —— 不然下次照样悄悄烂掉

第二条尤其要紧：出事前**全仓 grep 不到任何 Makefile / CI / 脚本会校验这张表的新鲜度**，
`check_closure_symmetry.py` 只在注释里提过它一次。两张表脱节 6 天没人发现，
是因为**没有任何机制能发现**。

判据
----
A  表里每个标 PROVEN_DIRECT 的 top，版本库里必须有一份 verdict 属于
   {SUCCEEDED, PASS_DEAD_REF, SIGNOFF_PASS} 的 tracked receipt。
   （反向不查 —— 有 receipt 但表里没记，是表陈旧，由生成器幂等闸管，
     不是证据链问题，见 --strict）
C  （--strict）universe 内每个有 tracked 通过 receipt 的 top，表里必须**记过账**：
   ★ledger-cv（2026-10-19）起★ 记账 ≠ PROVEN_DIRECT —— 证明不 current-valid 的根按用户批准的口径
   记 PROVEN_IN_CONE(superseded_by) 或不 proven，生成器在第 6 列 proof_status 写明
   current_valid:… / superseded_by=… / not_current:…。所以 C 认「formal=PROVEN_DIRECT，
   或 proof_status 非 -」为记过账；proof_status 为 - 而又不是 PROVEN_DIRECT ⇒ 表陈旧，照旧判红。
D  有第 6 列时：formal=PROVEN_DIRECT ⟺ proof_status 以 current_valid: 开头（防手改一侧）。
B  表头声明的分母必须等于 `docs/g1_configured_universe.tsv` 里 in_universe=yes 的行数。
   表头写的是生成那天的真实分母（生成器用 f'…共 {len(uni)}'），universe 一重算它就过期。

用法:
    python3 scripts/check_coverage_provenance.py           # 判据 A + B
    python3 scripts/check_coverage_provenance.py --strict  # 再加：有 receipt 必须进表
退出码 0 = 通过。
"""
import argparse
import io
import json
import os
import re
import subprocess
import sys

PASS_VERDICTS = ('SUCCEEDED', 'PASS_DEAD_REF', 'SIGNOFF_PASS')
COVERAGE = 'docs/coverage_three_axis.tsv'
UNIVERSE = 'docs/g1_configured_universe.tsv'


def _sh(cmd):
    return subprocess.check_output(cmd).decode('utf-8', 'replace')


def proven_tops():
    """表里标 PROVEN_DIRECT 的 top 集合，以及表头声明的分母。

    ★两张 docs 表都是**无表头** TSV，列名写在 `#` 注释里★，所以只能按**位置**解析。
    用 csv.DictReader 会把第一行数据当成表头吃掉 —— 我第一版就是这么写错的。
    coverage 的列： module \t rewrite_coverage \t formal_coverage \t impl_file
    """
    header_n = None
    tops = set()
    global RECORDED, MISMATCH
    RECORDED, MISMATCH = set(), []
    with io.open(COVERAGE, encoding='utf-8') as f:
        for line in f:
            if line.startswith('#'):
                m = re.search(r'共\s*(\d+)', line)
                if m and header_n is None:
                    header_n = int(m.group(1))
                continue
            parts = line.rstrip('\n').split('\t')
            if len(parts) < 3 or not parts[0]:
                continue
            if parts[2].strip() == 'PROVEN_DIRECT':
                tops.add(parts[0])
                RECORDED.add(parts[0])
            if len(parts) >= 6:
                pst = parts[5].strip()
                if pst != '-':
                    RECORDED.add(parts[0])
                if (parts[2].strip() == 'PROVEN_DIRECT') != pst.startswith('current_valid:'):
                    MISMATCH.append((parts[0], parts[2].strip(), pst))
    return tops, header_n


RECORDED, MISMATCH = set(), []


def tracked_passing_tops():
    """版本库里 verdict 通过的 top 集合（只看 tracked，不看磁盘）。"""
    ok = set()
    for p in _sh(['git', 'ls-files', 'evidence/*/receipt.json']).split():
        try:
            d = json.load(io.open(p, encoding='utf-8'))
        except Exception:
            continue
        if d.get('verdict') in PASS_VERDICTS and d.get('top'):
            ok.add(d['top'])
    return ok


def universe_yes_set():
    """in_universe=yes 的模块名集合。"""
    out = set()
    with io.open(UNIVERSE, encoding='utf-8') as f:
        for line in f:
            if line.startswith('#'):
                continue
            parts = line.rstrip('\n').split('\t')
            if len(parts) >= 2 and parts[1].strip() == 'yes':
                out.add(parts[0])
    return out


def universe_yes():
    """universe 里 in_universe=yes 的行数。同样是无表头 TSV：
    module \t yes|no \t reason
    """
    n = 0
    with io.open(UNIVERSE, encoding='utf-8') as f:
        for line in f:
            if line.startswith('#'):
                continue
            parts = line.rstrip('\n').split('\t')
            if len(parts) >= 2 and parts[1].strip() == 'yes':
                n += 1
    return n


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--strict', action='store_true',
                    help='额外要求：有通过 receipt 的 top 必须已记进表')
    a = ap.parse_args()

    proven, header_n = proven_tops()
    ok = tracked_passing_tops()
    yes = universe_yes()

    bad = False

    # --- 判据 A：证据链 ---
    orphan = sorted(proven - ok)
    if orphan:
        bad = True
        print('check_coverage_provenance: 判据 A 失败 —— %d 个 PROVEN_DIRECT '
              '在版本库里找不到通过 receipt' % len(orphan), file=sys.stderr)
        for t in orphan[:10]:
            print('    %s' % t, file=sys.stderr)
        if len(orphan) > 10:
            print('    ...还有 %d 个' % (len(orphan) - 10), file=sys.stderr)
        print('  修法：先确认它们的 evidence 是不是躺在磁盘上没进库', file=sys.stderr)
        print('        （evidence/ 在 .gitignore 里，要 git add -f），', file=sys.stderr)
        print('        真没有就得重跑 scripts/run_proof.sh 出证。', file=sys.stderr)
    else:
        print('check_coverage_provenance: 判据 A OK —— %d 个 PROVEN_DIRECT 全部'
              '有 tracked 通过 receipt' % len(proven))

    # --- 判据 B：分母新鲜度 ---
    if header_n is None:
        bad = True
        print('check_coverage_provenance: 判据 B 失败 —— 表头里读不到分母', file=sys.stderr)
    elif header_n != yes:
        bad = True
        print('check_coverage_provenance: 判据 B 失败 —— 表头分母 %d != universe '
              'in_universe=yes %d' % (header_n, yes), file=sys.stderr)
        print('  表头写的是生成那天的真实分母，universe 一重算它就过期。', file=sys.stderr)
        print('  修法：python3 scripts/coverage_three_axis.py 重跑。', file=sys.stderr)
    else:
        print('check_coverage_provenance: 判据 B OK —— 分母 %d 与 universe 一致' % yes)

    # --- 判据 C（--strict）：有证据必须记账 ---
    if a.strict:
        # ★只查 in_universe=yes 的★：universe 之外的目标（如 DelayReg×11 是
        # excluded:simtop_only，只被 SimTop 下的 GatewayEndpoint 例化、在 XSTop 根之外）
        # 本来就不在这张表里，有 receipt 而无表行是正常的，不是漏记。
        # 我的第一版没做这个过滤，把 11 个 DelayReg 误报成漏记了。
        unrecorded = sorted((ok - RECORDED) & universe_yes_set())
        if unrecorded:
            bad = True
            print('check_coverage_provenance: 判据 C 失败 —— %d 个 top 有通过 receipt '
                  '但表里没记账（既非 PROVEN_DIRECT，proof_status 也是 -）' % len(unrecorded), file=sys.stderr)
            for t in unrecorded[:10]:
                print('    %s' % t, file=sys.stderr)
            if len(unrecorded) > 10:
                print('    ...还有 %d 个' % (len(unrecorded) - 10), file=sys.stderr)
            print('  修法：python3 scripts/coverage_three_axis.py 重跑。', file=sys.stderr)
        else:
            print('check_coverage_provenance: 判据 C OK —— 没有漏记的通过 receipt')

    # --- 判据 D：formal 与 proof_status 一致 ---
    if MISMATCH:
        bad = True
        print('check_coverage_provenance: 判据 D 失败 —— %d 行 formal_coverage 与 proof_status 不一致'
              '（PROVEN_DIRECT ⟺ current_valid:）' % len(MISMATCH), file=sys.stderr)
        for m in MISMATCH[:10]:
            print('    %s\t%s\t%s' % m, file=sys.stderr)
        print('  修法：python3 scripts/coverage_three_axis.py 重跑（别手改表）。', file=sys.stderr)

    return 1 if bad else 0


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    sys.exit(main())

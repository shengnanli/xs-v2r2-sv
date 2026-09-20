#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""闸：EDA 工具的派生态（scratch）不许进版本控制。

为什么要有这道闸（.gitignore 不够）
----------------------------------
`.gitignore` 只拦**未跟踪**的新文件。一旦某个产物在规则加上去之前就已经
`git add` 了，ignore 对它完全无效，它会一直留在库里——仓库根的 `FM_INFO/`
就是这么活下来的（53 KB，9 个文件，`/FM_INFO*/` 规则是它进库之后才写的）。
所以必须有一道**对着已跟踪文件列表**跑的闸。

它拦的是什么（两次真实事故）
----------------------------
1. 2026-09-12 仓库根的 FM_WORK/FM_INFO/formality.log 进库 → 任何 FM 一跑
   仓库就 dirty → run_proof.sh 的 clean-worktree 前提被破 → 批跑连环失败。
   当时的修法是往 .gitignore 加**带根锚的**规则，治了症状。
2. 2026-09-18 agent/entries-v2 往 verif/ut/EntriesAluCsrFenceDiv/ 下建了
   fm_diag, fm_diag2..7 共 8 个 FM 诊断工作目录，`git add -A` 全扫进来：
       994807 行 / 77.8 MB，占该分支插入行数的 86.4%
   第 1 次加的规则一条都没拦住，因为它们按**固定深度**写死：
   `verif/ut/*/fm_shell_command.log*` 只管 UT 目录直下，而这些文件深了一层。

所以本闸按**名字**判，不按路径深度判。

判据：`git ls-files` 里不许出现 SCRATCH_NAMES / SCRATCH_SUFFIXES 命中的路径。

例外：`evidence/` 下的**证据**是有意提交的（run_proof.sh 产出，靠 `git add -f`
越过 .gitignore）。证据里的 fm.log / black_boxes.rpt / sidecar/ 是签核凭据，
不是 scratch —— 区别在于证据按 commit 归档、可复现、被 receipt 摘要覆盖，
而 scratch 是工具随手写的中间态。故 evidence/ 整个目录豁免。

用法:
    python3 scripts/check_no_tool_scratch.py            # 查当前索引
    python3 scripts/check_no_tool_scratch.py --rev main # 查某个 ref 的树
    python3 scripts/check_no_tool_scratch.py --stat     # 顺带打印体量
退出码 0 = 干净。
"""
import argparse
import os
import subprocess
import sys

# 目录名（整段路径里只要有一段等于/前缀匹配它，就算 scratch）
SCRATCH_DIRS = (
    'FM_INFO',      # Formality 会话信息转储
    'FM_WORK',      # Formality 工作目录（含带后缀的 FM_WORK2 等）
    'fm_work',
    'fm_diag',      # 人手起的诊断工作目录：fm_diag, fm_diag2, fm_diag4_sidecar ...
    'csrc',         # VCS
    'verdiLog',
    'neg_build',
    '__pycache__',
)
# 文件名前缀
SCRATCH_FILE_PREFIXES = (
    'fm_shell_command.log',
    'formality.log',
    'formality_svf.log',
    'novas.',
    'ucli.key',
    'vc_hdrs.h',
    'default.svf',
)
SCRATCH_SUFFIXES = ('.daidir', '.fsdb', '.pyc')
# 备份副本：变异 harness / 手工改 RTL 前 `cp` 出来的原件快照。
# 第 3 例（2026-09-20，Sbuffer lane）：verif/ut/Sbuffer/.mutants.orig.sv 被
# 一次 WIP 抢救提交（cf002ce8）连带 `git add` 进库 —— 它是 mutants.sh 的
# `cp "$SRC" "$BAK"` 产物，是 rtl/memblock/Sbuffer.sv 的**逐字节副本**（3843 行）。
# 危害不是体积，是它**会和源文件分叉**：源文件一改它就成了过期的第二份真相，
# 而它的名字看起来像"原件"，grep 到它的人会以为读的是当前 RTL。
# 上面两条前缀/后缀名单都没覆盖它（不是 fm_*、不是 *.log、不是 *.daidir），
# 所以补这一条。判据按**文件名后缀**而不是路径，与本闸其余部分一致。
SCRATCH_BACKUP_SUFFIXES = ('.orig.sv', '.orig.v', '.bak', '.sv.bak', '.orig')

# 有意提交、不算 scratch 的前缀
EXEMPT_PREFIXES = ('evidence/',)


def is_scratch(path):
    if path.startswith(EXEMPT_PREFIXES):
        return None
    parts = path.split('/')
    for seg in parts[:-1]:
        # 目录段本身就是 VCS 的 *.daidir 库树
        if seg.endswith('.daidir'):
            return 'scratch 目录 *.daidir/'
        for d in SCRATCH_DIRS:
            if seg == d:
                return 'scratch 目录 %s/' % d
            # 带后缀的变体：FM_WORK2/ fm_diag7/ fm_diag4_sidecar/ 都要算上。
            # ★但 fm_diagram/ 这种正经名字不许误伤★ —— 区别在于 `fm_diag` 之后
            # 紧跟的是数字还是字母：工具/人手起的编号目录一定是 名字+数字[+任意]，
            # 而正常单词是 名字+字母。这条边界由 test_no_tool_scratch_gate.py 的
            # 反向用例（fm_diagram/、fm_diagnostics_spec.md）钉住。
            if seg.startswith(d) and seg[len(d):len(d) + 1].isdigit():
                return 'scratch 目录 %s/（%s 的编号变体）' % (seg, d)
    base = parts[-1]
    for p in SCRATCH_FILE_PREFIXES:
        if base.startswith(p):
            return 'scratch 文件 %s*' % p
    for s in SCRATCH_SUFFIXES:
        if base.endswith(s):
            return 'scratch 后缀 %s' % s
    for s in SCRATCH_BACKUP_SUFFIXES:
        if base.endswith(s):
            return 'scratch 备份副本 %s（工具/手工 cp 出来的原件快照，会与源文件分叉）' % s
    return None


def tracked(rev):
    if rev:
        cmd = ['git', 'ls-tree', '-r', '--name-only', rev]
    else:
        cmd = ['git', 'ls-files']
    out = subprocess.check_output(cmd).decode('utf-8', 'replace')
    return [l for l in out.splitlines() if l]


def blob_size(rev, path):
    ref = ('%s:%s' % (rev, path)) if rev else (':%s' % path)
    try:
        out = subprocess.check_output(['git', 'cat-file', '-s', ref],
                                      stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        return 0
    return int(out.decode().strip())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--rev', default=None, help='查某个 ref 的树，默认查当前索引')
    ap.add_argument('--stat', action='store_true', help='打印命中文件的体量')
    a = ap.parse_args()

    hits = []
    for path in tracked(a.rev):
        why = is_scratch(path)
        if why:
            hits.append((path, why))

    if not hits:
        where = a.rev or '当前索引'
        print('check_no_tool_scratch: OK —— %s 里没有工具派生态' % where)
        return 0

    by_reason = {}
    for path, why in hits:
        by_reason.setdefault(why, []).append(path)

    print('check_no_tool_scratch: 失败 —— %d 个工具派生态被跟踪了' % len(hits),
          file=sys.stderr)
    total = 0
    for why in sorted(by_reason):
        paths = by_reason[why]
        print('  %s  (%d 个)' % (why, len(paths)), file=sys.stderr)
        for p in sorted(paths)[:5]:
            print('      %s' % p, file=sys.stderr)
        if len(paths) > 5:
            print('      ...还有 %d 个' % (len(paths) - 5), file=sys.stderr)
        if a.stat:
            total += sum(blob_size(a.rev, p) for p in paths)
    if a.stat:
        print('  合计 %.1f MB' % (total / 1048576.0), file=sys.stderr)
    print('', file=sys.stderr)
    print('修法：git rm -r --cached <路径>，并确认 .gitignore 里有**不带路径锚**的',
          file=sys.stderr)
    print('      按名规则（带根锚的 /FM_INFO/ 只管仓库根，挡不住深一层的同名目录）。',
          file=sys.stderr)
    return 1


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    sys.exit(main())

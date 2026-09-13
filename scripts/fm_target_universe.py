#!/usr/bin/env python3
"""fm_target_universe.py —— 在**某个 commit 的字节上**算出 FM target 全集。

为什么需要它（codex 0157 D57 最后一条）：
    「11 个没有 FM target 的 child 不能使用 green_child」。
「是不是 FM target」的唯一权威定义在 `scripts/ut_common.mk` 的 `fm-%` 配方里：

    fm-%:
        @case " $(strip $(FM_VARIANTS)) " in *" $* "*) ;; *) ... exit 1;; esac

即 **target ∈ 某个 `verif/ut/<dir>/Makefile` 的 `FM_VARIANTS`**，否则 `make fm-<t>`
直接拒绝出 receipt。本模块就按这条定义，从 `git show <commit>:verif/ut/*/Makefile`
读**被提交的字节**（不是工作树），机械地重建这个集合。

不另立一张"权威 target 表"是刻意的：多一张表就多一处可以和真实配方漂移的地方。
唯一输入就是那 100+ 份 Makefile 自己。

用法:
    python3 scripts/fm_target_universe.py [--commit HEAD] [--repo .] [--check NAME...]
"""
import argparse
import os
import pathlib
import re
import subprocess
import sys

_VARLINE = re.compile(r'^FM_VARIANTS\s*[:+?]?=\s*(.*)$', re.M)
_ASSIGN = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*)\s*[:+?]?=\s*(.*)$', re.M)
_REF = re.compile(r'\$[({]([A-Za-z_][A-Za-z0-9_]*)[)}]')
_CONT = re.compile(r'\\\n')
_MAX_EXPAND = 8


def _expand(text, value):
    """把 `FM_VARIANTS := $(VARIANTS)` 这类**单层变量间接**在同一份 Makefile 内展开。

    只展开形如 `$(NAME)` / `${NAME}` 的朴素变量引用（本仓真实用例：
    verif/ut/MbistPipe/Makefile `FM_VARIANTS := $(VARIANTS)`）。
    `$(addprefix ...)` 之类的 make 函数调用**故意不实现**——展开不了就留着，
    由调用方按 unresolved 处理（fail-closed），绝不假装展开成功。
    """
    env = {}
    for m in _ASSIGN.finditer(text):
        env.setdefault(m.group(1), m.group(2))
    for _ in range(_MAX_EXPAND):
        if '$' not in value:
            break
        new = _REF.sub(lambda m: env.get(m.group(1), m.group(0)), value)
        if new == value:
            break
        value = new
    return value


class GitError(RuntimeError):
    pass


def _git(repo, args, binary=False):
    p = subprocess.run(['git'] + args, cwd=str(repo), stdout=subprocess.PIPE,
                       stderr=subprocess.PIPE)
    if p.returncode != 0:
        return None
    return p.stdout if binary else p.stdout.decode('utf-8', 'replace')


def makefile_paths(repo, commit):
    out = _git(repo, ['ls-tree', '-r', '--name-only', commit, 'verif/ut/'])
    if out is None:
        raise GitError('git ls-tree 失败: commit=%s repo=%s' % (commit, repo))
    return [ln for ln in out.splitlines() if ln.endswith('/Makefile')]


def targets_at(repo, commit):
    """{target: [ut_dir, ...]} —— 该 commit 下所有 FM_VARIANTS 的并集。

    fail-closed：git 不可用 / 仓库里一个 Makefile 都没有 → 抛 GitError，
    绝不返回空集合当"没有 target"用（那会把 not_fm_target 判据变成 fail-open）。
    """
    mks = makefile_paths(repo, commit)
    if not mks:
        raise GitError('commit %s 下 verif/ut/ 没有任何 Makefile —— 拒绝把空集当 target 全集'
                       % commit[:12])
    out, unresolved = {}, []
    for mk in mks:
        blob = _git(repo, ['show', '%s:%s' % (commit, mk)], binary=True)
        if blob is None:
            continue
        txt = _CONT.sub(' ', blob.decode('utf-8', 'replace'))
        ut_dir = mk.split('/')[-2]
        for m in _VARLINE.finditer(txt):
            for t in _expand(txt, m.group(1)).split():
                if '$' in t:
                    unresolved.append('%s:%s' % (mk, t))
                    continue
                out.setdefault(t, [])
                if ut_dir not in out[t]:
                    out[t].append(ut_dir)
    if not out:
        raise GitError('commit %s 下没解析出任何 FM_VARIANTS' % commit[:12])
    return out, unresolved


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', default=os.environ.get('XSSV_HOME') or
                    str(pathlib.Path(__file__).resolve().parent.parent))
    ap.add_argument('--commit', default='HEAD')
    ap.add_argument('--check', nargs='*', default=None,
                    help='逐个报告这些名字是否 FM target；任一不是 → 非零退出')
    a = ap.parse_args()
    commit = _git(a.repo, ['rev-parse', a.commit + '^{commit}'])
    if commit is None:
        print('ERROR: 无法解析 commit %s' % a.commit, file=sys.stderr)
        return 2
    commit = commit.strip()
    try:
        t, unresolved = targets_at(a.repo, commit)
    except GitError as e:
        print('ERROR: %s' % e, file=sys.stderr)
        return 2
    if unresolved:
        print('# WARN 未能展开的 FM_VARIANTS token %d 条: %s'
              % (len(unresolved), ' '.join(unresolved[:5])), file=sys.stderr)
    if a.check is None:
        print('# repo=%s commit=%s FM targets=%d unresolved=%d'
              % (a.repo, commit, len(t), len(unresolved)))
        for k in sorted(t):
            print('%s\t%s' % (k, ','.join(t[k])))
        return 0
    bad = 0
    for n in a.check:
        if n in t:
            print('%-46s FM_TARGET\tut=%s' % (n, ','.join(t[n])))
        elif unresolved:
            print('%-46s UNKNOWN(target 全集未完全展开，不得据此判 NOT_FM_TARGET)' % n)
            bad += 1
        else:
            print('%-46s NOT_FM_TARGET' % n)
            bad += 1
    return 1 if bad else 0


if __name__ == '__main__':
    sys.exit(main())

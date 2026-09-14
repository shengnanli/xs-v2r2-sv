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

## ★make 权威求值★（codex 0153 D70）

`fm-%` 的守卫是 **shell 对 make 已展开字符串做子串匹配**：

    @case " $(strip $(FM_VARIANTS)) " in *" $* "*) ;; *) ... exit 1;; esac

所以"谁是 target"这个问题的**唯一权威求值器就是 make 自己**。正则永远只是近似：
实测本仓 `verif/ut/MbistPipe/Makefile:31` 是 `FM_VARIANTS := $(VARIANTS)`，
不展开变量的解析器会漏掉整整 24 个变体（248 vs 272，见
`docs/fm_target_universe_diff.tsv`）；而 `scripts/bulk_revalidate.py` 里那份
`^FM_VARIANTS\s*=` 连 `:=` 都不匹配。

本模块因此提供两个引擎：

  make    在 `git archive <commit>` 展开出的**临时树**里，逐个 UT 目录跑
          `make --eval='<goal>: ; @printf ...' <goal>`，由 make 自己展开。
          既是权威，又仍然只看**被提交的字节**（不是工作树）。
  regex   原来的轻量解析（保留：make 不可用时要有东西可用）。

默认 `--engine both`：两个引擎都算，**结果不一致就 fail-closed**（退出码 2），
把"正则悄悄漂了"变成一定会响的事故。绝不取其中一个当答案而把分歧咽掉。

★只跑打印用的显式 goal★。UT Makefile 的默认 goal 是 ut_common.mk 的 `portlint`，
它会真的去调 `port_contract_lint.py`；goal 名也不能以 `fm-` 开头（会撞上 `fm-%`
模式规则）。parse 期唯一会执行的外部命令是 ut_common.mk:119 的 `date` 与
`git rev-parse`（两者都是只读且已 `||` 兜底）。

用法:
    python3 scripts/fm_target_universe.py [--commit HEAD] [--repo .] [--check NAME...]
    python3 scripts/fm_target_universe.py --engine make
    python3 scripts/fm_target_universe.py --diff-engines --tsv docs/fm_target_universe_diff.tsv
"""
import argparse
import hashlib
import concurrent.futures as _fut
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

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


def targets_at_regex(repo, commit):
    """★regex 引擎★ {target: [ut_dir, ...]} —— 该 commit 下所有 FM_VARIANTS 的并集。

    近似求值，保留作 make 不可用时的退路与交叉校验的一侧。
    已知近似不到位的形态见模块 docstring（`$(addprefix)`、`::=`、行内注释、
    同名变量后续重定义…）。

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


# --------------------------------------------------------------------------
# make 引擎 —— 让 make 自己回答"谁是 target"（codex 0153 D70）
# --------------------------------------------------------------------------
#: 打印用的 goal 名。**不能以 `fm-` 开头**（会撞 ut_common.mk 的 `fm-%` 模式规则），
#: 也不能撞任何真实 target —— 撞上就会去跑真配方。
_PRINT_GOAL = 'xs__print_fm_variants__'
#: 分隔符：make 回显的整行以它开头，把 make 自己的噪声（"make: Entering…"）滤掉。
_MARK = '@@FMV@@'


class MakeUnavailable(RuntimeError):
    """make 引擎跑不起来。**不是**"没有 target"，调用方必须 fail-closed。"""


def _export_tree(repo, commit, dest):
    """把 commit 的 verif/ut 与 scripts/ut_common.mk 展开到 dest。

    ★仍然只看被提交的字节★ —— 与 regex 引擎口径一致。直接在工作树上跑 make
    会让"某个 commit 下的 target 全集"变成"此刻工作树里的 target 全集"，
    两者在脏树下不同，而这个函数的全部意义就是可复算。
    """
    paths = ['verif/ut', 'scripts/ut_common.mk']
    ar = subprocess.run(['git', 'archive', '--format=tar', commit] + paths,
                        cwd=str(repo), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if ar.returncode != 0:
        raise MakeUnavailable('git archive 失败: %s'
                              % ar.stderr.decode('utf-8', 'replace').strip()[:200])
    tr = subprocess.run(['tar', '-x', '-C', str(dest)], input=ar.stdout,
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if tr.returncode != 0:
        raise MakeUnavailable('tar 解包失败: %s'
                              % tr.stderr.decode('utf-8', 'replace').strip()[:200])


def _make_one(utdir):
    """跑一次 make，取回该 UT 目录展开后的 FM_VARIANTS。

    返回 (ut_dir_name, [target…]) 或抛 MakeUnavailable。
    """
    expr = ('%s: ; @printf "%s%%s\\n" "$(strip $(FM_VARIANTS))"'
            % (_PRINT_GOAL, _MARK))
    p = subprocess.run(['make', '--no-print-directory', '--eval=' + expr, _PRINT_GOAL],
                       cwd=str(utdir), stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       universal_newlines=True)
    if p.returncode != 0:
        raise MakeUnavailable('%s: make rc=%d: %s'
                              % (utdir.name, p.returncode,
                                 (p.stderr or p.stdout).strip()[:200]))
    hits = [ln[len(_MARK):] for ln in p.stdout.splitlines() if ln.startswith(_MARK)]
    if len(hits) != 1:
        raise MakeUnavailable('%s: make 回报了 %d 行（期望恰好 1 行）—— 无法判定'
                              % (utdir.name, len(hits)))
    return utdir.name, hits[0].split()


#: 进程内缓存。`proof_certificate.validate_child_certificate` 每验一个 child 就要
#: 问一次 target 全集；make 引擎每次要 git archive + 127 个 make 进程。同一个
#: (repo, commit) 的答案在一次进程里不会变，算一次就够。
_MAKE_CACHE = {}


def targets_at_make(repo, commit, jobs=8):
    """★make 引擎（权威）★ {target: [ut_dir, ...]}。

    先把 commit 展开到临时树，再逐个 UT 目录让 make 展开 `FM_VARIANTS`。
    任何一个目录跑不出来就整体 fail-closed —— 半份 target 全集比没有更危险，
    它会让 `not_fm_target` 这条判据对缺掉的那部分变成假阴性。
    """
    key = (str(repo), commit)
    if key in _MAKE_CACHE:
        cached = _MAKE_CACHE[key]
        if isinstance(cached, MakeUnavailable):
            raise cached
        return dict(cached), []
    try:
        out = _targets_at_make_uncached(repo, commit, jobs)
    except MakeUnavailable as e:
        _MAKE_CACHE[key] = e            # 失败也缓存：别在 heavy 流程里反复重试
        raise
    _MAKE_CACHE[key] = out
    return dict(out), []


def _targets_at_make_uncached(repo, commit, jobs):
    if shutil.which('make') is None:
        raise MakeUnavailable('PATH 里没有 make')
    tmp = tempfile.mkdtemp(prefix='fmtu-')
    try:
        _export_tree(repo, commit, tmp)
        root = pathlib.Path(tmp) / 'verif' / 'ut'
        if not root.is_dir():
            raise MakeUnavailable('commit %s 下没有 verif/ut' % commit[:12])
        utdirs = sorted(d for d in root.iterdir() if (d / 'Makefile').is_file())
        if not utdirs:
            raise MakeUnavailable('commit %s 下 verif/ut 没有任何 Makefile —— '
                                  '拒绝把空集当 target 全集' % commit[:12])
        out, errs = {}, []
        with _fut.ThreadPoolExecutor(max_workers=max(1, jobs)) as ex:
            for fut in [ex.submit(_make_one, d) for d in utdirs]:
                try:
                    name, ts = fut.result()
                except MakeUnavailable as e:
                    errs.append(str(e))
                    continue
                for tgt in ts:
                    out.setdefault(tgt, [])
                    if name not in out[tgt]:
                        out[tgt].append(name)
        if errs:
            raise MakeUnavailable('%d 个 UT 目录展开失败（fail-closed）: %s'
                                  % (len(errs), ' | '.join(errs[:3])))
        if not out:
            raise MakeUnavailable('commit %s 下 make 没展开出任何 FM_VARIANTS'
                                  % commit[:12])
        return out
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


class EngineDisagree(RuntimeError):
    """两个引擎给出不同的 target 全集。**绝不挑一个当答案**，一律 fail-closed。"""


def diff_engines(repo, commit):
    """返回 (make_map, regex_map, [(target, in_make, in_regex)…])，供机器 diff。"""
    mk, _ = targets_at_make(repo, commit)
    rx, rx_unres = targets_at_regex(repo, commit)
    rows = []
    for tgt in sorted(set(mk) | set(rx)):
        a, b = tgt in mk, tgt in rx
        if a != b or sorted(mk.get(tgt, [])) != sorted(rx.get(tgt, [])):
            rows.append((tgt, ','.join(sorted(mk.get(tgt, []))) or '-',
                         ','.join(sorted(rx.get(tgt, []))) or '-'))
    return mk, rx, rows, rx_unres


def targets_at(repo, commit, engine='both'):
    """{target: [ut_dir, ...]}, [unresolved…] —— 默认 **make 权威 + regex 交叉校验**。

    engine='make'   只用 make（权威）
    engine='regex'  只用正则（退路；与本函数的历史行为一致）
    engine='both'   两个都算；**不一致就抛 EngineDisagree**（fail-closed）。
                    make 跑不起来时**退到 regex 并把原因放进 unresolved**——
                    调用方（proof_certificate.validate_child_certificate）见到
                    非空 unresolved 就不再下 NOT_FM_TARGET 的结论，也不放行。
    """
    if engine == 'regex':
        return targets_at_regex(repo, commit)
    if engine == 'make':
        return targets_at_make(repo, commit)
    if engine != 'both':
        raise ValueError('unknown engine: %r' % engine)
    rx, rx_unres = targets_at_regex(repo, commit)
    try:
        mk, _ = targets_at_make(repo, commit)
    except MakeUnavailable as e:
        # 退到 regex，但**把降级本身记成 unresolved**：宁可让调用方判不准，
        # 也不让它拿近似结果去下 NOT_FM_TARGET 这种放行/拦截的硬结论。
        return rx, rx_unres + ['make_engine_unavailable:%s' % e]
    if set(mk) != set(rx):
        only_mk = sorted(set(mk) - set(rx))
        only_rx = sorted(set(rx) - set(mk))
        raise EngineDisagree(
            'make 与 regex 的 target 全集不一致（make=%d regex=%d）：'
            '仅 make 有 %s；仅 regex 有 %s'
            % (len(mk), len(rx), only_mk[:8], only_rx[:8]))
    return mk, rx_unres


# --------------------------------------------------------------------------
# 缺陷模型（D70 的 248→272 机器 diff 的可复算一侧）
# --------------------------------------------------------------------------
#: ★这是一份**故意保留的坏解析器**★，不是给人用的，是给回归用的 oracle。
#: 它逐字复刻 scripts/bulk_revalidate.py 在 292fbb8 之前的那份解析：
#:     m = re.search(r'^FM_VARIANTS\s*=\s*(.*)$', txt, re.M)
#: 三处不到位，每一处都能独立造成假阴性：
#:   1. `\s*=` 匹配不上 `:=` → verif/ut/MbistPipe/Makefile:31
#:      `FM_VARIANTS := $(VARIANTS)` 整份文件被跳过（24 个变体凭空消失）；
#:   2. 不做变量展开 → 就算匹配上了，拿到的也是字面量 `$(VARIANTS)`；
#:   3. `re.search` 只取第一处赋值（本仓暂无多次赋值，但这是同类事故的下一步）。
#: 后果实测：248 vs 272。`MbistPipeIcacheTag` 因此被 verif/allow_gen/
#: classification.tsv 记成"根本不是任何 UT 的 FM target ⇒ 永远无法变绿"。
_DEFECT_VARLINE = re.compile(r'^FM_VARIANTS\s*=\s*(.*)$', re.M)
DEFECT_MODEL_SOURCE = 'scripts/bulk_revalidate.py:34 (pre-fix)'


def targets_at_defect_model(repo, commit):
    """用**缺陷模型**算一遍 target 全集。只供 --defect-diff 与回归使用。"""
    mks = makefile_paths(repo, commit)
    if not mks:
        raise GitError('commit %s 下 verif/ut 没有任何 Makefile' % commit[:12])
    out = {}
    for mk in mks:
        blob = _git(repo, ['show', '%s:%s' % (commit, mk)], binary=True)
        if blob is None:
            continue
        txt = _CONT.sub(' ', blob.decode('utf-8', 'replace'))
        m = _DEFECT_VARLINE.search(txt)
        if not m:
            continue
        for tgt in m.group(1).split():
            out.setdefault(tgt, []).append(mk.split('/')[-2])
    return out


DEFECT_HDR = [
    '# FM target 全集：**权威 make 求值** vs **缺陷模型**（codex 0153 D70 要的机器 diff）',
    '# scripts/fm_target_universe.py --defect-diff 生成；禁止手工编辑。',
    '# 缺陷模型 = %s，逐字复刻的坏正则；' % DEFECT_MODEL_SOURCE,
    '#   它匹配不上 `:=`、不展开 `$(VARIANTS)`、只取第一处赋值。',
    '# 这不是"两种同样合理的口径"：`fm-%` 守卫对 make 已展开的字符串做子串匹配，',
    '#   所以 make 那一栏是唯一权威，缺陷模型那一栏每一行都是**假阴性**。',
    '# 每一行都曾让一个真实存在的 FM target 被判成"不是 target"，进而让引用它的',
    '#   child 在 verif/allow_gen/classification.tsv 里被记成"永远无法变绿"。',
    '# target\tut_dirs_authoritative\tseen_by_defect_model',
]


def makefiles_digest(repo, commit):
    """所有被读入的 Makefile 字节的摘要。

    ★不要把 commit 写进生成物★：artifact 自己一旦被提交，commit 就变了，
    `--check` 幂等闸从此永远不可能通过（本轮实测踩过）。真正标识这份结论的
    是**输入字节**，不是产出它的那个提交。
    """
    h = hashlib.sha256()
    paths = sorted(makefile_paths(repo, commit)) + ['scripts/ut_common.mk']
    for path in paths:
        blob = _git(repo, ['show', '%s:%s' % (commit, path)], binary=True)
        if blob is None:
            continue
        h.update(path.encode())
        h.update(b'\0')
        h.update(hashlib.sha256(blob).hexdigest().encode())
        h.update(b'\n')
    return h.hexdigest()


DIFF_HDR = [
    '# FM target 全集：make 权威求值 vs 轻量正则（scripts/fm_target_universe.py',
    '#   --diff-engines 生成；禁止手工编辑）。codex 0153 D70。',
    '# "谁是 FM target" 的权威定义是 scripts/ut_common.mk 的 `fm-%` 守卫，它对',
    '#   **make 已展开的字符串**做子串匹配 —— 所以唯一权威的求值器就是 make 自己。',
    '# engine=make  : git archive <commit> 出临时树后逐目录 `make --eval` 展开',
    '# engine=regex : 轻量正则近似（退路）',
    '# ★两栏不同即事故★：正则漂了而没人发现，not_fm_target 这条判据就会给出',
    '#   假阴性（"它不是 target" → 逼着本来可以出证书的 child 去走 allow 绕过）。',
    '# target\tut_dirs_make\tut_dirs_regex\tverdict',
]


def _emit_diff(repo, commit, rows, mk, rx, rx_unres, path):
    lines = list(DIFF_HDR)
    lines.insert(len(DIFF_HDR) - 1,
                 '# makefiles_sha256=%s  make=%d  regex=%d  regex_unresolved=%d  分歧=%d'
                 % (makefiles_digest(repo, commit), len(mk), len(rx),
                    len(rx_unres), len(rows)))
    for tgt, a, b in rows:
        lines.append('%s\t%s\t%s\t%s'
                     % (tgt, a, b, 'ONLY_MAKE' if b == '-' else
                        ('ONLY_REGEX' if a == '-' else 'UT_DIR_DIFF')))
    txt = '\n'.join(lines) + '\n'
    pathlib.Path(path).write_text(txt)
    return txt


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--repo', default=os.environ.get('XSSV_HOME') or
                    str(pathlib.Path(__file__).resolve().parent.parent))
    ap.add_argument('--commit', default='HEAD')
    ap.add_argument('--engine', choices=('make', 'regex', 'both'), default='both',
                    help='make=权威求值（D70）；regex=轻量近似；'
                         'both=两个都算，不一致就 fail-closed（默认）')
    ap.add_argument('--jobs', type=int, default=8)
    ap.add_argument('--check', nargs='*', default=None,
                    help='逐个报告这些名字是否 FM target；任一不是 → 非零退出')
    ap.add_argument('--diff-engines', action='store_true',
                    help='把 make 与 regex 的分歧写成机器 diff')
    ap.add_argument('--defect-diff', action='store_true',
                    help='把权威 make 求值与**缺陷模型**（未展开 make 变量的坏正则）'
                         '的差写成机器 diff —— D70 的 248→272')
    ap.add_argument('--tsv', default=None,
                    help='--diff-engines 的输出文件（默认打到 stdout）')
    a = ap.parse_args()
    commit = _git(a.repo, ['rev-parse', a.commit + '^{commit}'])
    if commit is None:
        print('ERROR: 无法解析 commit %s' % a.commit, file=sys.stderr)
        return 2
    commit = commit.strip()

    if a.defect_diff:
        try:
            auth, _ = targets_at_make(a.repo, commit)
            bad = targets_at_defect_model(a.repo, commit)
        except (GitError, MakeUnavailable) as e:
            print('ERROR: %s' % e, file=sys.stderr)
            return 2
        missed = sorted(set(auth) - set(bad))
        spurious = sorted(set(bad) - set(auth))
        lines = list(DEFECT_HDR)
        lines.insert(len(DEFECT_HDR) - 1,
                     '# makefiles_sha256=%s  权威=%d  缺陷模型=%d  被漏掉=%d  多出来=%d'
                     % (makefiles_digest(a.repo, commit), len(auth), len(bad),
                        len(missed), len(spurious)))
        for tgt in missed:
            lines.append('%s\t%s\tMISSED' % (tgt, ','.join(sorted(auth[tgt]))))
        for tgt in spurious:
            lines.append('%s\t-\tSPURIOUS' % tgt)
        txt = '\n'.join(lines) + '\n'
        pathlib.Path(a.tsv or '/dev/stdout').write_text(txt)
        if a.tsv:
            import hashlib
            print('wrote %s  sha256=%s  权威 %d vs 缺陷模型 %d（漏 %d / 多 %d）'
                  % (a.tsv, hashlib.sha256(txt.encode()).hexdigest(),
                     len(auth), len(bad), len(missed), len(spurious)))
        return 0

    if a.diff_engines:
        try:
            mk, rx, rows, rx_unres = diff_engines(a.repo, commit)
        except (GitError, MakeUnavailable) as e:
            print('ERROR: %s' % e, file=sys.stderr)
            return 2
        txt = _emit_diff(a.repo, commit, rows, mk, rx, rx_unres,
                         a.tsv or '/dev/stdout')
        if a.tsv:
            import hashlib
            print('wrote %s  sha256=%s  分歧 %d 条'
                  % (a.tsv, hashlib.sha256(txt.encode()).hexdigest(), len(rows)))
        # 分歧本身就是事故 → 非零
        return 1 if rows else 0

    try:
        t, unresolved = targets_at(a.repo, commit, engine=a.engine)
    except EngineDisagree as e:
        print('ERROR(engine_disagree): %s' % e, file=sys.stderr)
        print('  机器 diff: python3 scripts/fm_target_universe.py --diff-engines '
              '--tsv docs/fm_target_universe_diff.tsv', file=sys.stderr)
        return 2
    except (GitError, MakeUnavailable) as e:
        print('ERROR: %s' % e, file=sys.stderr)
        return 2
    if unresolved:
        print('# WARN 未能展开的 FM_VARIANTS token %d 条: %s'
              % (len(unresolved), ' '.join(unresolved[:5])), file=sys.stderr)
    if a.check is None:
        print('# repo=%s commit=%s engine=%s FM targets=%d unresolved=%d'
              % (a.repo, commit, a.engine, len(t), len(unresolved)))
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

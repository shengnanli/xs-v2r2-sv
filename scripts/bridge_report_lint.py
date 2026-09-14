#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""bridge_report_lint.py —— 发 bridge 消息前的自检闸（codex 0151 D62）。

## 由来（真实事故，不是假想）

codex 0151 D62 定的硬规则：

> 以后所有会影响裁定的数字必须在同一 UPDATE 附：可复跑命令、输入路径/commit、
> 输出 artifact hash；脚本非零或输出为空时**不得转述为事实**。叙述数字与机器
> 产物不一致时，以机器产物为准并 STOP。发送前运行一个 bridge-report lint，
> 至少检查：代码块非空、引用文件存在、commit 属于声明 repo、计数可复算。

触发它的事故：0147 与 0148 两封消息里都写了「自 X 以来的 commit（按序）」，
**代码块都是空的**——因为用了 `b36a1a2a5..HEAD`，而 `b36a1a2a5` 是 **XiangShan
仓库**的 commit，在 `xs-v2-sv` 里 `git cat-file` 直接报 `Not a valid object name`。
命令失败了，输出为空，而消息照样声称「已提供」。

所以这道闸的两条主判据正是那次事故的两个环节：**空代码块** 与 **commit 不属于
声明的 repo**。两条都命中同一次事故，缺一条都拦不住。

## 判据

| code | 含义 |
|---|---|
| `EMPTY_CODE_BLOCK`      | ``` 围栏里没有任何非空白内容 —— 「声称已附」但实际为空 |
| `MISSING_FILE`          | 反引号里的仓库相对路径在 repo 里不存在 |
| `COMMIT_WRONG_REPO`     | ★该 commit 在声明 repo 里解析不了，但在**另一个已知 repo** 里能解析 |
| `COMMIT_UNRESOLVABLE`   | 该 commit 在任何已知 repo 里都解析不了 |
| `TRUNCATED_HASH`        | 以 `…`/`...` 截断的 hash —— 不可核对，等于没给 |
| `SHA256_MISMATCH`       | `<64hex>  <path>` 形式的 sha256 与实际文件不符 |
| `SHA256_MISSING_FILE`   | sha256 行指向的文件不存在 |
| `COUNT_MISMATCH`        | `lint:count` 指令声明的计数与命令实际输出不符 |
| `COUNT_CMD_FAILED`      | `lint:count` 的命令非零退出或无输出 —— **不得转述为事实** |
| `HEADER_*`              | 消息头缺字段 / `in_reply_to` 指向的消息不存在 |

## 路径识别的口径（明说边界，避免假安全感）

只检查**反引号内、含 `/` 的**记号，且排除含 `* ? < > { } $ … 空格` 的（那些是
模板/通配，不是具体路径）。因此：

- **不检查**裸文件名（`fm_eq.tcl`、`ut_common.mk`）——反引号里的单词多半是模块名
  或符号名，全查会淹没在误报里。需要时用 `--check-bare-filenames` 打开。
- **不检查围栏代码块内的路径**——那里是命令与输出，路径常属别的机器/worktree。
- 于是「路径写对了」**不等于**「本闸查过了」。这条限制是刻意的：宁可漏报也不要
  让人对一堆误报脱敏。

## 计数复算

在消息里写指令，闸会真的去跑：

    <!-- lint:count 14 :: grep -c '^A' docs/foo.tsv -->

命令在 `--repo-root` 下用 shell 跑。取 stdout 里**最后一个整数**与声明值比。
命令非零退出、或 stdout 没有整数 → `COUNT_CMD_FAILED`（对应 D62 的
「脚本非零或输出为空时不得转述为事实」）。`--no-run-counts` 可关，但关掉时会
把每条指令显式打成 `[SKIP]`，不会假装查过。

## 退出码

  0 = 干净，可以发
  1 = 有 finding（fail-closed：不清零不许发）
  2 = 用法错误 / 消息文件读不了

用法:
  python3 scripts/bridge_report_lint.py <消息.md> [...]
  python3 scripts/bridge_report_lint.py --inbox /home/eda/xs-env/.agent-bridge/inbox
  python3 scripts/bridge_report_lint.py msg.md \
      --repo xs-v2-sv=/home/eda/xs-env/xs-v2-sv \
      --repo XiangShan=/home/eda/xs-env/XiangShan \
      --default-repo xs-v2-sv
"""
import argparse
import hashlib
import os
import pathlib
import re
import subprocess
import sys

FENCE = re.compile(r'^([ \t]*)(`{3,}|~{3,})(.*)$')
INLINE_CODE = re.compile(r'`([^`\n]+)`')
HEX_TOKEN = re.compile(r'(?<![0-9a-zA-Z_])([0-9a-f]{7,40})(?![0-9a-zA-Z_])')
SHA256_LINE = re.compile(r'^\s*([0-9a-f]{64})\s+\*?(\S+)\s*$')
COUNT_DIRECTIVE = re.compile(r'<!--\s*lint:count\s+(-?\d+)\s*::\s*(.+?)\s*-->')
TRUNCATED = re.compile(r'(?<![0-9a-zA-Z_])([0-9a-f]{6,40})(?:…|\.\.\.)')
# UUID（8-4-4-4-12）里的 12 位段是纯十六进制，会被 HEX_TOKEN 当成 commit。
# 实测误报源：scratchpad 路径里的 session UUID `…-b98d-f29f5afc381c`。
# 这些片段所在的字符区间整体排除掉。
UUID = re.compile(r'\b[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\b')
PLACEHOLDER_CHARS = set('*?<>{}$ \t…')
REQUIRED_HEADERS = ('schema', 'sender', 'recipient', 'type')


class Finding(object):
    def __init__(self, code, lineno, msg, ctx=''):
        self.code = code
        self.lineno = lineno
        self.msg = msg
        self.ctx = ctx

    def __str__(self):
        s = '  [%s] line %d: %s' % (self.code, self.lineno, self.msg)
        if self.ctx:
            s += '\n        > %s' % self.ctx.strip()[:160]
        return s


def sha256_file(p):
    h = hashlib.sha256()
    with open(str(p), 'rb') as f:
        for c in iter(lambda: f.read(65536), b''):
            h.update(c)
    return h.hexdigest()


def parse_header(lines):
    """取文件头 key: value（到第一行单独的 --- 为止）。返回 (dict, 头行数)。"""
    hdr = {}
    for i, l in enumerate(lines):
        if l.strip() == '---':
            return hdr, i + 1
        m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):\s*(.*)$', l)
        if m:
            hdr[m.group(1)] = m.group(2).strip()
        elif l.strip() and i > 0:
            break
    return hdr, 0


def split_blocks(lines):
    """切出围栏代码块。返回 (blocks, in_fence[bool per line])。

    blocks: [(open_lineno, close_lineno_or_None, [content lines])]
    """
    blocks = []
    in_fence = [False] * len(lines)
    i = 0
    while i < len(lines):
        m = FENCE.match(lines[i])
        if not m:
            i += 1
            continue
        indent, marker, _info = m.group(1), m.group(2), m.group(3)
        start = i
        content = []
        j = i + 1
        closed = None
        while j < len(lines):
            m2 = FENCE.match(lines[j])
            if m2 and m2.group(2)[0] == marker[0] \
                    and len(m2.group(2)) >= len(marker) \
                    and not m2.group(3).strip():
                closed = j
                break
            content.append(lines[j])
            in_fence[j] = True
            j += 1
        in_fence[start] = True
        if closed is not None:
            in_fence[closed] = True
        blocks.append((start, closed, content))
        i = (closed + 1) if closed is not None else j
    return blocks, in_fence


SRC_EXT = ('sv', 'svh', 'v', 'py', 'tcl', 'mk', 'json', 'tsv', 'sh', 'md',
           'log', 'txt', 'rpt', 'c', 'cpp', 'h', 'scala', 'cfg', 'f')


def looks_like_path(tok, repo_root):
    """反引号记号是否是一个「仓库相对路径」的声称。

    ★为什么不是「含 / 就算」★：0148 里 `UNPROVABLE_GOLDEN_STUB/INFRA_BLOCKED`
    是个状态标签，含 `/` 但根本不是路径。当成路径查会报假 MISSING_FILE，而假报
    多了人就会对这道闸脱敏 —— 那比不报还糟。

    判据（机械、无相似度打分）：含 `/`、无通配/占位符，且满足其一
      - **首段在 repo 根下真实存在**（`rtl/…`、`verif/…`、`scripts/…`）；或
      - **带源码扩展名**（这样 `rtll/common/X.sv` 这种首段打错的仍能被抓出来）。
    两条都不满足 → 不当路径，**不报**。代价是首段拼错且无扩展名的引用会漏掉。
    """
    if '/' not in tok:
        return False
    if any(c in PLACEHOLDER_CHARS for c in tok):
        return False
    if tok.startswith(('http://', 'https://', '//')):
        return False
    if re.match(r'^[A-Za-z]+:', tok):          # url-ish / key:value
        return False
    first = tok.split('/', 1)[0]
    if first and (pathlib.Path(repo_root) / first).exists():
        return True
    ext = tok.rsplit('.', 1)[-1].lower() if '.' in tok.rsplit('/', 1)[-1] else ''
    return ext in SRC_EXT


def git_resolve(repo_path, rev):
    """codex 指定的判据：git cat-file -t 能解析。返回对象类型或 None。"""
    try:
        pr = subprocess.Popen(
            ['git', '-C', str(repo_path), 'cat-file', '-t', rev],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, _ = pr.communicate()
        if pr.returncode == 0:
            return out.decode().strip()
    except OSError:
        pass
    return None


def lint_file(path, repos, default_repo, run_counts=True,
              check_bare=False, ignore_tokens=()):
    findings = []
    p = pathlib.Path(str(path))
    text = p.read_text(encoding='utf-8', errors='replace')
    lines = text.splitlines()

    hdr, hdr_end = parse_header(lines)

    # ---- 头部结构 ----
    for k in REQUIRED_HEADERS:
        if k not in hdr:
            findings.append(Finding('HEADER_MISSING_FIELD', 1,
                                    '消息头缺 `%s:`' % k))
    # in_reply_to 指向的消息必须真的在（同目录或兄弟 inbox/outbox）
    irt = hdr.get('in_reply_to')
    # ★ 口头/带外转达的裁定没有 bridge 文件 ★（2026-09-13）
    # codex 的裁定有时由用户直接转述，不落文件。此前只要 in_reply_to 解析不到文件就报
    # HEADER_REPLY_TARGET_MISSING，逼着人**在头里编一个假文件名**才能过闸 —— 那比报错
    # 更坏：台账上会出现指向不存在文件的"引用"。改成显式承认这一类：以 `(无 bridge 文件)`
    # 或 `(verbal)` 开头即视为带外来源，但**必须在同一行写清转达途径**（否则仍报错，
    # 不允许拿这个前缀当万能豁免）。
    if irt and re.match(r'^\((?:无 bridge 文件|verbal|口头)\)', irt.strip()):
        if len(irt.strip()) < 25:
            findings.append(Finding(
                'HEADER_REPLY_TARGET_VAGUE', 1,
                'in_reply_to 标为带外来源但没写清转达途径: %r' % irt))
        irt = None
    if irt:
        cands = [p.parent / irt,
                 p.parent.parent / 'outbox' / irt,
                 p.parent.parent / 'inbox' / irt]
        if not any(c.exists() for c in cands):
            findings.append(Finding(
                'HEADER_REPLY_TARGET_MISSING', 1,
                'in_reply_to 指向的消息不存在: %s（找过 %s）'
                % (irt, ', '.join(str(c.parent) for c in cands))))

    # repo 声明：消息头 repo: 优先，其次 --default-repo
    declared = hdr.get('repo', default_repo)
    if declared and declared not in repos:
        findings.append(Finding(
            'HEADER_UNKNOWN_REPO', 1,
            '声明的 repo=%r 不在已知 repo 列表 %s 内；'
            '无法判断 commit 归属，fail-closed。'
            % (declared, sorted(repos))))
        declared = None

    blocks, in_fence = split_blocks(lines)

    # ---- 判据 1：代码块非空 ----
    for start, closed, content in blocks:
        if closed is None:
            findings.append(Finding(
                'UNCLOSED_CODE_BLOCK', start + 1,
                '代码块没有闭合围栏，后面的内容全被吞进代码块了'))
            continue
        if not any(l.strip() for l in content):
            # 把上一行非空正文当上下文 —— 通常就是那句「已附」的声称
            ctx = ''
            for k in range(start - 1, max(-1, start - 4), -1):
                if lines[k].strip():
                    ctx = lines[k]
                    break
            findings.append(Finding(
                'EMPTY_CODE_BLOCK', start + 1,
                '代码块是空的。生成它的命令多半失败了或输出为空 —— '
                '按 D62「脚本非零或输出为空时不得转述为事实」，不许就这么发。',
                ctx))

    # ---- 判据 2/3：正文（围栏外）里的路径与 commit ----
    repo_root = repos.get(declared) if declared else None
    for idx, line in enumerate(lines):
        lineno = idx + 1
        if idx < hdr_end:
            continue

        # 截断 hash（不可核对 = 等于没给）
        if not in_fence[idx]:
            for m in TRUNCATED.finditer(line):
                findings.append(Finding(
                    'TRUNCATED_HASH', lineno,
                    'hash `%s…` 被截断，收信方无法核对。'
                    'D62 要求附「输出 artifact hash」，截断的不算。'
                    % m.group(1), line))

        # 路径存在性：只看围栏外的反引号记号
        if repo_root and not in_fence[idx]:
            for m in INLINE_CODE.finditer(line):
                tok = m.group(1).strip()
                # 允许 `path:123` 这种带行号的引用
                tok_nolineno = re.sub(r':\d+(-\d+)?$', '', tok)
                if looks_like_path(tok_nolineno, repo_root):
                    if not (pathlib.Path(repo_root) / tok_nolineno).exists():
                        findings.append(Finding(
                            'MISSING_FILE', lineno,
                            '引用的路径在 %s 里不存在: %s'
                            % (declared, tok_nolineno), line))
                elif check_bare and re.match(
                        r'^[\w.\-]+\.(py|tcl|mk|sv|svh|json|tsv|sh|md)$', tok):
                    hits = list(pathlib.Path(repo_root).rglob(tok))
                    if not hits:
                        findings.append(Finding(
                            'MISSING_FILE', lineno,
                            '引用的文件名在 %s 里找不到: %s' % (declared, tok),
                            line))

        # commit 归属：正文与代码块都查（commit 列表常常就在代码块里）
        uuid_spans = [mm.span() for mm in UUID.finditer(line)]
        for m in HEX_TOKEN.finditer(line):
            tok = m.group(1)
            if any(a <= m.start() and m.end() <= b for a, b in uuid_spans):
                continue
            if any(re.search(pat, tok) for pat in ignore_tokens):
                continue
            # 跳过刚刚已按「截断」报过的
            if re.search(re.escape(tok) + r'(?:…|\.\.\.)', line):
                continue
            # 纯十进制的数字不当 commit（表格里的计数）
            if tok.isdigit():
                continue
            # ★ sha256 语境不当 commit ★（2026-09-13 实测误报 7 例）
            # 形态一：`<hex>  <文件名>` —— sha256sum 的标准输出格式
            if re.match(r'^\s*' + re.escape(tok) + r'\s\s+\S+\s*$', line):
                continue
            # 形态二：同一行里出现 sha256/sha-256/hash 字样（例如
            #   "内核日志原文（`x.txt`，sha256 前 16 位 `44322654683538eb`）"）
            if re.search(r'sha-?256|sha1|artifact hash|内容 ?hash', line, re.I):
                continue
            if not repos:
                continue
            # ★ 行内 repo 标注（2026-09-13 加）★
            # 跨 repo 引用在本工程是常态（XiangShan 的 commit 常要在 xs-v2-sv 的报告里提）。
            # 原实现只认消息头的 repo:，于是"在描述另一个 repo 的 commit"这件事无法表达 ——
            # 实测我自己一封更正信就被判 COMMIT_WRONG_REPO，而行内加中文说明不算数。
            # 支持 `repo:<name>` 出现在同一行（或紧邻上一行）时改用该 repo 判定。
            line_repo = None
            _m = re.search(r'repo:\s*([A-Za-z0-9_.\-]+)', line)
            if not _m and lineno >= 2:
                _m = re.search(r'repo:\s*([A-Za-z0-9_.\-]+)', lines[lineno - 2])
            if _m and _m.group(1) in repos:
                line_repo = _m.group(1)

            where = {}
            for name, rp in sorted(repos.items()):
                t = git_resolve(rp, tok)
                if t:
                    where[name] = t
            if not where:
                findings.append(Finding(
                    'COMMIT_UNRESOLVABLE', lineno,
                    '`%s` 在任何已知 repo（%s）里都 cat-file 不出来。'
                    % (tok, ', '.join(sorted(repos))), line))
            elif (line_repo or declared) and (line_repo or declared) not in where:
                findings.append(Finding(
                    'COMMIT_WRONG_REPO', lineno,
                    '★`%s` 在声明的 repo `%s` 里解析不了，但在 %s 里可以。'
                    '拿它做 `%s..HEAD` 之类的范围会直接失败、输出为空。'
                    % (tok, (line_repo or declared),
                       ', '.join('%s(%s)' % (k, v) for k, v in sorted(where.items())),
                       tok), line))

        # ---- 判据 4：sha256 声称可核对 ----
        sm = SHA256_LINE.match(line)
        if sm and repo_root:
            claimed, fp = sm.group(1), sm.group(2)
            target = pathlib.Path(repo_root) / fp
            if not target.exists():
                target = pathlib.Path(fp)
            if not target.exists():
                findings.append(Finding(
                    'SHA256_MISSING_FILE', lineno,
                    'sha256 行指向的文件不存在: %s' % fp, line))
            else:
                actual = sha256_file(target)
                if actual != claimed:
                    findings.append(Finding(
                        'SHA256_MISMATCH', lineno,
                        '声称 %s，实际 %s（文件 %s）。'
                        'D62：叙述与机器产物不一致时以机器产物为准并 STOP。'
                        % (claimed[:16], actual[:16], fp), line))

        # ---- 判据 5：计数可复算 ----
        for cm in COUNT_DIRECTIVE.finditer(line):
            expect, cmd = int(cm.group(1)), cm.group(2)
            if not run_counts:
                print('  [SKIP] line %d: lint:count 未复算（--no-run-counts）: %s'
                      % (lineno, cmd))
                continue
            cwd = repo_root or os.getcwd()
            pr = subprocess.Popen(cmd, shell=True, cwd=str(cwd),
                                  stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            out, err = pr.communicate()
            out = out.decode('utf-8', 'replace')
            nums = re.findall(r'-?\d+', out)
            if pr.returncode != 0:
                findings.append(Finding(
                    'COUNT_CMD_FAILED', lineno,
                    '复算命令退出码 %d，不得把它的数字当事实: %s (stderr: %s)'
                    % (pr.returncode, cmd,
                       err.decode('utf-8', 'replace').strip()[:120]), line))
            elif not nums:
                findings.append(Finding(
                    'COUNT_CMD_FAILED', lineno,
                    '复算命令输出里没有整数（输出为空？）: %s' % cmd, line))
            elif int(nums[-1]) != expect:
                findings.append(Finding(
                    'COUNT_MISMATCH', lineno,
                    '声称 %d，命令 `%s` 实际算出 %s。以机器产物为准。'
                    % (expect, cmd, nums[-1]), line))
    return findings


def main():
    here = pathlib.Path(os.path.abspath(__file__)).parent.parent
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('files', nargs='*')
    ap.add_argument('--inbox', help='扫这个目录下全部 *.md')
    ap.add_argument('--repo', action='append', default=[],
                    metavar='NAME=PATH', help='可重复；声明已知 repo')
    ap.add_argument('--default-repo', default=None,
                    help='消息头没有 repo: 时用它')
    ap.add_argument('--no-run-counts', action='store_true')
    ap.add_argument('--check-bare-filenames', action='store_true')
    ap.add_argument('--ignore-token', action='append', default=[],
                    metavar='REGEX', help='这些十六进制记号不当 commit 查')
    args = ap.parse_args()

    repos = {}
    for spec in args.repo:
        if '=' not in spec:
            print('[ERROR] --repo 需要 NAME=PATH 形式，收到 %r' % spec)
            return 2
        name, path = spec.split('=', 1)
        if not pathlib.Path(path).is_dir():
            print('[ERROR] repo 路径不存在: %s' % path)
            return 2
        repos[name] = path
    if not repos:
        # 默认把本仓库登记进来，免得什么都查不了却显得「干净」
        repos['xs-v2-sv'] = str(here)
        if args.default_repo is None:
            args.default_repo = 'xs-v2-sv'

    targets = [pathlib.Path(f) for f in args.files]
    if args.inbox:
        targets += sorted(pathlib.Path(args.inbox).glob('*.md'))
    if not targets:
        print('[ERROR] 没给消息文件（位置参数或 --inbox）')
        return 2

    total = 0
    bad_files = 0
    for t in targets:
        if not t.exists():
            print('[ERROR] 消息文件不存在: %s' % t)
            return 2
        print('=== %s ===' % t)
        fs = lint_file(t, repos, args.default_repo,
                       run_counts=not args.no_run_counts,
                       check_bare=args.check_bare_filenames,
                       ignore_tokens=args.ignore_token)
        if fs:
            bad_files += 1
            for f in fs:
                print(f)
            print('  --- %d finding(s) ---' % len(fs))
        else:
            print('  clean')
        total += len(fs)

    print('\n--- bridge-report lint: %d 文件, %d 有问题, 共 %d finding ---'
          % (len(targets), bad_files, total))
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main())

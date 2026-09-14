#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""equality_dup_lint.py —— 防「已知重复静默分叉」闸（codex 0151 D61）。

## 这道闸要解决的问题不是「有重复」，而是「重复的两份悄悄变得不一样」

仓库里的已知重复登记在 `docs/deferred_refactor.tsv`，分两类：

1. **逐字节重复的 common 文件**。历史上 `rtl/common/DataModule.sv` 与
   `rtl/common/xs_DataModule.sv` 逐字节相同、且**定义同一个模块名**
   `xs_DataModule`（`SyncDataModule` 同理），两份分别被 `FtqPcMemWrapper`
   和 `SyncDataModule` 两个 UT 各用一份——改一份忘另一份，两个 UT 从此验的是
   不同的 RTL，而**没有任何现有闸会响**。这正是本闸判据 B 要盯的形态。
   ★ 2026-09-14 cleanup：这两组已真正合并（删掉无前缀那份），登记表里相应的
   `dm_common_dup` / `sdm_common_dup` 两条随之删除，**现在 rtl/ 下逐字节相同的
   组数为 0**。判据 A/B 依然在岗，等的是下一组。

2. **功能重复的核**。`rtl/frontend/ITTageTable{,_1..4}.sv` 内嵌的
   `xs_MbistPipeIttage_core`，与 `rtl/dft/xs_mbist_pipe_core.sv` 功能重复
   （前者是后者在 1/2-child 情况下的子集，array id 逐个对得上）。两份今天
   都各自验证正确，只是重复。

★ 关键认识：**单靠「扫逐字节相同的文件」当防腐闸是自欺的。** 一旦发生分叉，
这两份就不再逐字节相同，于是从扫描结果里**消失**，闸反而哑了 —— 正是要防的
那件事发生时闸不响。所以真正的机制是**登记表钉 hash**：扫描只负责*发现新增*
的重复，登记表负责*盯住已知*的重复不许漂。

## 三道判据

- **A. 发现**：`rtl/` 下逐字节相同的文件组；同一模块名在多个文件里定义。
  任一组**未登记** → `UNDECLARED_*`，FAIL。
- **B. 同步**（本闸核心）：登记表里 `byte_identical` 条目的成员之间**必须仍然
  逐字节相同**。任一份动了另一份没跟上 → `DIVERGED`，FAIL。
- **C. 留痕**：成员相对登记表里钉的 sha256 变了（哪怕是同步地一起变）→
  `HASH_STALE` / `MEMBER_CHANGED`，FAIL。这不是找茬：登记表钉的 hash 是
  「下个 cycle 要重跑哪些目标」的唯一依据，同步改动也必须显式重钉
  （`--update-hashes`），否则受影响目标会被漏掉重跑。

## 为什么不需要「排除合法变体薄文件」的例外名单

任务书要求「排除合法的变体薄文件」。实测下来**这条例外是空的，而且必须是空的**：

逐字节相同 ⟹ `module` 声明行也相同 ⟹ **模块名相同** ⟹ 两份永远不能进同一个
编译单元。所以逐字节相同的一对**在定义上就不可能是「同族不同变体」**——
同族变体（`SRAMTemplate_128` vs `_145`、`MbistPipeIttage_2` vs `_3`）至少在
模块名上就不同，通常参数也不同。

实测佐证（合并前，2026-09-13）：`rtl/` 289 个 .sv、393 处 module 定义 /
391 个不同名字，逐字节相同的组恰好 2 组，且这 2 组正好就是那 2 处同名定义
——**完全重合**。（合并后两组都没了：两类 finding 数同时归 0，佐证的是同一条
「逐字节相同 ⟺ 模块重名」的等价关系。）

因此本闸对精确相等不设任何排除名单，**误伤风险为零**：若将来某个新生成的族成员
真的与兄弟逐字节相同，那本身就是 bug（两个模块重名），报出来是对的。

**诚实说明本闸看不见什么**（见文件头 ★）：它检测不了「近似重复」。第 2 类
（ITTageTable 内嵌核 vs dft 核）**不是**逐字节相同，扫描判据 A 永远扫不到它；
它只能靠登记表的 `functional_duplicate` 条目钉住——任一份变了就要求人重新确认
另一份是否要跟着改。这是登记，不是证明。

## 退出码

  0 = 干净
  1 = 有 finding（未登记重复 / 分叉 / hash 过期）
  2 = 用法或登记表解析失败（fail-closed：登记表读不懂绝不当成「没条目」放行）

用法:
  python3 scripts/equality_dup_lint.py
  python3 scripts/equality_dup_lint.py --json out.json
  python3 scripts/equality_dup_lint.py --update-hashes   # 审阅后显式重钉
"""
import argparse
import hashlib
import json
import os
import pathlib
import re
import sys

REGISTRY_COLS = ['id', 'type', 'members', 'pinned_sha256',
                 'why_deferred', 'next_cycle_recipe', 'affected_targets']
VALID_TYPES = ('byte_identical', 'functional_duplicate')

# 去注释用：先抹块注释再抹行注释，避免把注释里的 "module foo" 当定义。
_BLOCK_COMMENT = re.compile(r'/\*.*?\*/', re.S)
_LINE_COMMENT = re.compile(r'//[^\n]*')
_MODULE_DECL = re.compile(r'^[ \t]*module[ \t]+([A-Za-z_][A-Za-z0-9_$]*)', re.M)


def sha256_file(path):
    h = hashlib.sha256()
    with open(str(path), 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


def sv_files(root):
    """rtl/ 下全部 .sv，按相对路径排序（稳定输出，便于 diff 与复算）。"""
    root = pathlib.Path(root)
    return sorted(p for p in root.rglob('*.sv') if p.is_file())


def module_defs(path):
    """一个文件里定义的模块名列表（已去注释）。"""
    try:
        text = pathlib.Path(str(path)).read_text(encoding='utf-8', errors='replace')
    except OSError as e:
        raise RuntimeError('读不了 %s: %s' % (path, e))
    text = _BLOCK_COMMENT.sub(' ', text)
    text = _LINE_COMMENT.sub(' ', text)
    return _MODULE_DECL.findall(text)


def scan(rtl_root, repo_root):
    """返回 (identical_groups, modname_collisions, path->sha256)。

    identical_groups: [(sha256, [relpath, ...])]  组内 >=2 个成员
    modname_collisions: [(modname, [relpath, ...])]
    """
    repo_root = pathlib.Path(repo_root)
    by_hash = {}
    by_mod = {}
    hashes = {}
    for p in sv_files(rtl_root):
        rel = str(p.relative_to(repo_root))
        h = sha256_file(p)
        hashes[rel] = h
        by_hash.setdefault(h, []).append(rel)
        for m in module_defs(p):
            by_mod.setdefault(m, []).append(rel)

    groups = sorted((h, sorted(v)) for h, v in by_hash.items() if len(v) > 1)
    colls = sorted((m, sorted(set(v))) for m, v in by_mod.items()
                   if len(set(v)) > 1)
    return groups, colls, hashes


def load_registry(path):
    """读登记表。fail-closed：任何一行读不懂都抛异常，绝不跳过。"""
    p = pathlib.Path(str(path))
    if not p.exists():
        return []
    rows = []
    lines = p.read_text(encoding='utf-8').splitlines()
    header = None
    for lineno, raw in enumerate(lines, 1):
        if not raw.strip() or raw.lstrip().startswith('#'):
            continue
        fields = raw.split('\t')
        if header is None:
            header = [f.strip() for f in fields]
            if header != REGISTRY_COLS:
                raise RuntimeError(
                    '%s:%d 表头必须恰好是 %s，实际 %s'
                    % (path, lineno, REGISTRY_COLS, header))
            continue
        if len(fields) != len(REGISTRY_COLS):
            raise RuntimeError(
                '%s:%d 列数 %d != %d（TSV 字段内不得含 tab）'
                % (path, lineno, len(fields), len(REGISTRY_COLS)))
        row = dict(zip(REGISTRY_COLS, [f.strip() for f in fields]))
        row['_lineno'] = lineno
        if row['type'] not in VALID_TYPES:
            raise RuntimeError('%s:%d type=%r 不在 %s 内'
                               % (path, lineno, row['type'], list(VALID_TYPES)))
        row['members'] = [m.strip() for m in row['members'].split(',') if m.strip()]
        row['pinned_sha256'] = [h.strip() for h in row['pinned_sha256'].split(',')
                                if h.strip()]
        if len(row['members']) < 2:
            raise RuntimeError('%s:%d members 少于 2 个，不构成重复条目'
                               % (path, lineno))
        if len(row['pinned_sha256']) != len(row['members']):
            raise RuntimeError(
                '%s:%d pinned_sha256 个数 %d != members 个数 %d（须逐位对齐）'
                % (path, lineno, len(row['pinned_sha256']), len(row['members'])))
        for h in row['pinned_sha256']:
            if not re.fullmatch(r'[0-9a-f]{64}', h):
                raise RuntimeError('%s:%d pinned_sha256 含非法值 %r'
                                   % (path, lineno, h))
        for f in ('why_deferred', 'next_cycle_recipe'):
            if not row[f]:
                raise RuntimeError('%s:%d %s 不得为空（登记表的全部价值就在这两列）'
                                   % (path, lineno, f))
        rows.append(row)
    return rows


class Finding(object):
    def __init__(self, code, where, msg):
        self.code = code
        self.where = where
        self.msg = msg

    def __str__(self):
        return '[FAIL] %-26s %s\n         %s' % (self.code, self.where, self.msg)

    def as_dict(self):
        return {'code': self.code, 'where': self.where, 'msg': self.msg}


def check(rtl_root, repo_root, registry_path, update_hashes=False):
    """返回 (findings, repin_rows, scan_summary)。"""
    findings = []
    groups, colls, hashes = scan(rtl_root, repo_root)
    rows = load_registry(registry_path)
    try:
        registry_path = pathlib.Path(str(registry_path)).relative_to(repo_root)
    except ValueError:
        pass
    repo_root = pathlib.Path(repo_root)

    # 登记表覆盖到的成员集合（用 frozenset 比对「这一组是否已登记」）
    declared_sets = []
    for r in rows:
        declared_sets.append((frozenset(r['members']), r))

    def covered(paths):
        s = frozenset(paths)
        for ds, r in declared_sets:
            if s <= ds:
                return r
        return None

    # ---- 判据 A：发现未登记的重复 ----
    for h, members in groups:
        r = covered(members)
        if r is None:
            findings.append(Finding(
                'UNDECLARED_DUPLICATE', ', '.join(members),
                '这 %d 个文件逐字节相同（sha256 %s）但未登记。'
                '要么合并，要么登记进 %s 说明为何推迟。'
                % (len(members), h[:16], registry_path)))

    for mod, members in colls:
        r = covered(members)
        if r is None:
            findings.append(Finding(
                'UNDECLARED_MODULE_COLLISION', ', '.join(members),
                '模块 %s 在 %d 个文件里各定义了一次且未登记。'
                '两份不可能进同一编译单元，必然有一份是影子。'
                % (mod, len(members))))

    # ---- 判据 B/C：登记条目的同步与留痕 ----
    repin = {}
    for r in rows:
        loc = '%s:%d (%s)' % (registry_path, r['_lineno'], r['id'])
        live = []
        missing = []
        for m in r['members']:
            fp = repo_root / m
            if not fp.exists():
                missing.append(m)
                live.append(None)
            else:
                live.append(hashes.get(m) or sha256_file(fp))
        if missing:
            findings.append(Finding(
                'MISSING_MEMBER', loc,
                '登记的成员不存在：%s。若重构已完成请删掉该条目，'
                '不要留着假装还在盯。' % ', '.join(missing)))
            continue

        if r['type'] == 'byte_identical':
            # B：成员之间必须仍逐字节相同 —— 这是整道闸的核心
            if len(set(live)) != 1:
                detail = '; '.join('%s=%s' % (m, h[:16])
                                   for m, h in zip(r['members'], live))
                findings.append(Finding(
                    'DIVERGED', loc,
                    '★静默分叉★ 登记为逐字节重复，但现在已不相同：%s。'
                    '改了一份就必须同改另一份（或者现在就合并）。' % detail))
                continue
            # C：同步了，但相对钉的 hash 变了 → 必须显式重钉
            if live[0] != r['pinned_sha256'][0]:
                if update_hashes:
                    repin[r['id']] = [live[0]] * len(r['members'])
                else:
                    findings.append(Finding(
                        'HASH_STALE', loc,
                        '两份仍同步，但相对登记表钉的 sha256 已变 '
                        '(%s → %s)。请确认受影响目标 [%s] 已重跑，再用 '
                        '--update-hashes 重钉。'
                        % (r['pinned_sha256'][0][:16], live[0][:16],
                           r['affected_targets'] or '未填')))
        else:  # functional_duplicate
            # 两份本来就不相同，只能钉各自的 hash：任一份动了就要求人重新确认另一份
            drift = [(m, pin, cur) for m, pin, cur
                     in zip(r['members'], r['pinned_sha256'], live)
                     if pin != cur]
            if drift:
                if update_hashes:
                    repin[r['id']] = live
                else:
                    detail = '; '.join('%s (%s → %s)' % (m, p[:16], c[:16])
                                       for m, p, c in drift)
                    findings.append(Finding(
                        'MEMBER_CHANGED', loc,
                        '功能重复条目的成员变了：%s。本闸无法自动判断另一份是否'
                        '需要同改（两份本就不逐字节相同），请人工确认孪生实现仍然'
                        '等价、受影响目标 [%s] 已重跑，再用 --update-hashes 重钉。'
                        % (detail, r['affected_targets'] or '未填')))

    summary = {
        'scanned_files': len(hashes),
        'identical_groups': [{'sha256': h, 'members': m} for h, m in groups],
        'modname_collisions': [{'module': m, 'members': v} for m, v in colls],
        'registry_entries': len(rows),
    }
    return findings, repin, summary


def rewrite_registry(path, repin):
    """把重钉后的 hash 写回 TSV，其余列原样保留。"""
    p = pathlib.Path(str(path))
    out = []
    header = None
    for raw in p.read_text(encoding='utf-8').splitlines():
        if not raw.strip() or raw.lstrip().startswith('#'):
            out.append(raw)
            continue
        fields = raw.split('\t')
        if header is None:
            header = fields
            out.append(raw)
            continue
        row = dict(zip(REGISTRY_COLS, fields))
        if row['id'] in repin:
            fields[REGISTRY_COLS.index('pinned_sha256')] = ','.join(repin[row['id']])
            out.append('\t'.join(fields))
        else:
            out.append(raw)
    p.write_text('\n'.join(out) + '\n', encoding='utf-8')


def main():
    here = pathlib.Path(os.path.abspath(__file__)).parent.parent
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--repo-root', default=str(here))
    ap.add_argument('--rtl-root', default=None,
                    help='默认 <repo-root>/rtl')
    ap.add_argument('--registry', default=None,
                    help='默认 <repo-root>/docs/deferred_refactor.tsv')
    ap.add_argument('--json', default=None, help='另存机器可读结果')
    ap.add_argument('--update-hashes', action='store_true',
                    help='把 HASH_STALE/MEMBER_CHANGED 的条目重钉到当前值（需人工审阅后使用）')
    args = ap.parse_args()

    repo_root = pathlib.Path(args.repo_root)
    rtl_root = pathlib.Path(args.rtl_root) if args.rtl_root else repo_root / 'rtl'
    registry = (pathlib.Path(args.registry) if args.registry
                else repo_root / 'docs' / 'deferred_refactor.tsv')

    if not rtl_root.is_dir():
        print('[ERROR] rtl 根目录不存在: %s' % rtl_root)
        return 2
    try:
        findings, repin, summary = check(rtl_root, repo_root, registry,
                                         args.update_hashes)
    except RuntimeError as e:
        print('[ERROR] 登记表解析失败（fail-closed，不放行）: %s' % e)
        return 2

    print('--- equality/duplicate lint ---')
    print('扫描 %d 个 .sv；逐字节相同组 %d；同名模块多处定义 %d；登记条目 %d'
          % (summary['scanned_files'], len(summary['identical_groups']),
             len(summary['modname_collisions']), summary['registry_entries']))
    for g in summary['identical_groups']:
        print('  identical  %s  [%s]' % (g['sha256'][:16], ', '.join(g['members'])))
    for c in summary['modname_collisions']:
        print('  modname    %-24s [%s]' % (c['module'], ', '.join(c['members'])))

    if args.update_hashes and repin:
        rewrite_registry(registry, repin)
        for k, v in sorted(repin.items()):
            print('[REPIN] %s → %s' % (k, ','.join(h[:16] for h in v)))

    for f in findings:
        print(f)

    if args.json:
        pathlib.Path(args.json).write_text(json.dumps(
            {'summary': summary,
             'findings': [f.as_dict() for f in findings]},
            indent=1, ensure_ascii=False, sort_keys=True) + '\n', encoding='utf-8')

    if findings:
        print('--- %d finding(s) ---' % len(findings))
        return 1
    print('--- clean ---')
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_universe_freeze.py —— 冻结前的机器门禁（codex 0150 D54 第 2 步）。

codex 要求冻结前机器验证四件事，**全部 fail-closed**：

  C1 OWNER_UNIQUE   target/G1 owner 唯一
  C2 CONSERVATION   全集守恒（四个集合的差集必须能被明确归类，不许有残余）
  C3 NO_DUPLICATE   零重复
  C4 NO_DANGLING    零悬挂
  C5 SLOT_CONSISTENT 台账映射与「槽位判据」重算结果一致（可 --no-slots 关掉）

## 为什么 C5 必须在（不是锦上添花）

C1..C4 只看「台账自洽」。台账可以自洽地全错：把 G0 的 96 端口模块认领成 G1 的
17 端口同名模块，四条全绿。真正的身份判据是**槽位**：

    模块身份 = 它占据的 (父模块, 实例名) 集合。

firtool 的实例名来自 Chisel 变量名，跨 422 个 commit 比「例化顺序编号」稳定得多；
槽位→模块 在每个基线内是双射，所以**两个基线都存在的槽位就是映射本身**。
C5 重算这张图并要求台账与之一致，不一致而又没有登记依据的一律 FAIL。

判据强度（只用能给出是/否的精确判据，不用相似度打分——相似度总能给出"最像的"，
把「判不准」伪装成「判出来了」）：

  site            两侧槽位集合完全相等。
  site_common     集合不等但有两版共有的槽位；共有槽位在对侧放的是谁就是答案。
  site_via_parent 父模块自己也被重编号了（SplittedSRAMTemplate_24→_25 这类），
                  先把父映射过去再查槽位。迭代到不动点。
  wrapper_insert  槽位答案 X 是**新插入的薄壳**：X 恰好只有一个子例化，且该子模块
                  与源同名。此时真身仍是同名模块，X 是新增层。
                  （全基线只有 IMSIC→IMSIC_WRAP 一例。）
  UNRESOLVED      以上都不给答案 → **如实留白**，不猜。必须在证据表里登记原因，
                  否则 FAIL（沉默不等于通过）。

## 输入

  docs/g1_universe.tsv            主台账 old_target → g1_name（本次冻结对象）
  docs/g1_old_to_new_map.tsv      守恒映射（须与主台账逐行一致）
  docs/g1_configured_universe.tsv G1 configured universe + source 列
  docs/ledger_normalized.tsv      每 target 唯一终态 + MAIN/AUX 分栏
  docs/g1_slot_map_evidence.tsv   ★槽位判据的可复算证据表★（C5 用）
  rtl/**.sv                       本仓实现
  G0/G1 golden-rtl                两个基线（C5 用；--no-slots 时只需 G1）

## 退出码

  0  五条全绿
  1  至少一条不满足（逐条打印是哪一条、哪几行）
  2  解析失败 / 输入缺失（fail-closed，绝不静默跳过）

用法:
  python3 scripts/check_universe_freeze.py                 # 全部五条
  python3 scripts/check_universe_freeze.py --no-slots      # 只跑 C1..C4（快）
  python3 scripts/check_universe_freeze.py --only C2       # 只跑某条
"""
from __future__ import print_function

import argparse
import collections
import os
import pathlib
import re
import sys

G0_DEFAULT = '/home/eda/xs-env/G0-canonical/golden-rtl'
G1_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'

# rtl/ 下允许存在、且**不对应任何 golden 模块**的内部件命名约定。
# 不符合这些约定又不在 golden 里的模块 = 无法归类的残余 → C2 FAIL。
INTERNAL_CORE_RE = re.compile(r'^xs_|_pkg$|_wrapper$')

_MOD = re.compile(r'^[ \t]*module[ \t]+([A-Za-z_]\w*)')
_END = re.compile(r'^[ \t]*endmodule\b')
# firtool 例化：缩进 >= 2 空格 + `<Type> <inst> (` 单独成行
_INST = re.compile(r'^[ \t]{2,}([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)[ \t]*\([ \t]*$')
_PORT = re.compile(r'^[ \t]*(input|output|inout)[ \t]')
_HDR_END = re.compile(r'^[ \t]*\)[ \t]*;[ \t]*$')

GONE_TOKENS = ('gone_in_g1', 'removed_in_g1', 'no_g0_file')
PASSISH = ('WORKING_PASS', 'WORKING_PASS_DEAD_REF', 'WORKING_MERGED_PASS',
           'REVALIDATED_PASS', 'REVALIDATED_PASS_DEAD_REF')


class InputError(Exception):
    """fail-closed：读不到 / 解析不了的东西一律抛出，不猜、不跳过。"""


# ------------------------------------------------------------------ 基线解析

class Baseline(object):
    """流式扫一遍 golden：模块名 / 端口数 / 例化槽位。不留模块体，内存 O(MB)。"""

    def __init__(self, root, tag):
        p = pathlib.Path(root)
        if not p.is_dir():
            raise InputError('%s golden 目录不存在: %s' % (tag, root))
        files = sorted(p.glob('*.sv'))
        if not files:
            raise InputError('%s: %s 下一个 .sv 都没有' % (tag, root))
        self.tag = tag
        self.ports = {}                       # name -> nports
        self.sites = collections.defaultdict(set)   # type -> {(parent, inst)}
        self.slot = {}                        # (parent, inst) -> type
        self.kids = collections.defaultdict(list)   # parent -> [(type, inst)]
        dups = []
        for f in files:
            cur, np_, inhdr = None, 0, False
            with f.open(errors='replace') as fh:
                for lineno, ln in enumerate(fh, 1):
                    if cur is None:
                        m = _MOD.match(ln)
                        if m:
                            cur, np_, inhdr = m.group(1), 0, True
                        continue
                    if _END.match(ln):
                        if cur in self.ports:
                            dups.append(cur)
                        self.ports[cur] = np_
                        cur, inhdr = None, False
                        continue
                    if inhdr:
                        if _HDR_END.match(ln):
                            inhdr = False
                        elif _PORT.match(ln):
                            np_ += 1
                        continue
                    im = _INST.match(ln.rstrip('\n'))
                    if im:
                        typ, inst = im.group(1), im.group(2)
                        self.sites[typ].add((cur, inst))
                        self.slot[(cur, inst)] = typ
                        self.kids[cur].append((typ, inst))
            if cur is not None:
                raise InputError('%s: %s 里 module %s 没有 endmodule（解析器 fail-closed）'
                                 % (tag, f.name, cur))
        if not self.ports:
            raise InputError('%s: 一个模块都没解析出来（解析器坏了？）' % tag)
        if dups:
            raise InputError('%s: 同名模块出现多次: %s' % (tag, ' '.join(sorted(set(dups))[:8])))

    def site_key(self, name):
        s = self.sites.get(name)
        return tuple(sorted(s)) if s else None


def build_slot_map(g0, g1):
    """G0 模块 -> G1 模块。返回 (map, why)。判不准的**不进 map**。"""
    by_site = collections.defaultdict(list)
    for t, s in g1.sites.items():
        by_site[tuple(sorted(s))].append(t)

    mp, why = {}, {}
    for n in g0.ports:
        sk = g0.site_key(n)
        if not sk:
            continue
        hit = sorted(set(by_site.get(sk, [])))
        if len(hit) == 1:
            mp[n], why[n] = hit[0], 'site'
            continue
        common = [x for x in sk if x in g1.slot]
        if common:
            hit = sorted(set(g1.slot[x] for x in common))
            if len(hit) == 1:
                mp[n], why[n] = hit[0], 'site_common'

    # 父模块自己也重编号了：把槽位的父先映射过去，再查。迭代到不动点。
    for _ in range(8):
        added = 0
        for n in g0.ports:
            if n in mp:
                continue
            sk = g0.site_key(n)
            if not sk:
                continue
            tgt, ok = set(), True
            for (par, inst) in sk:
                par2 = mp.get(par)
                if par2 is None:
                    ok = False
                    break
                t = g1.slot.get((par2, inst))
                if t is None:
                    ok = False
                    break
                tgt.add(t)
            if ok and len(tgt) == 1:
                mp[n], why[n] = tgt.pop(), 'site_via_parent'
                added += 1
        if not added:
            break

    # 新插入的薄壳：槽位答案 X 只有一个子例化且该子模块与源同名 → 真身仍是同名模块。
    for n in list(mp):
        m = mp[n]
        if m == n:
            continue
        k = g1.kids.get(m, [])
        if len(k) == 1 and k[0][0] == n:
            mp[n], why[n] = n, 'wrapper_insert'
    return mp, why


# ------------------------------------------------------------------ 台账解析

def read_tsv(path, ncol, name):
    """返回 [(行号, [字段…])]。列数不足 → fail-closed。"""
    if not path.exists():
        raise InputError('%s 不存在: %s' % (name, path))
    out = []
    for i, ln in enumerate(path.read_text().splitlines(), 1):
        if ln.startswith('#') or not ln.strip():
            continue
        f = ln.split('\t')
        if len(f) < ncol:
            raise InputError('%s:%d 列数 %d < %d，看不懂: %r'
                             % (name, i, len(f), ncol, ln))
        out.append((i, f))
    if not out:
        raise InputError('%s: 一行数据都没有（空台账不算通过）' % name)
    return out


def rtl_modules(repo):
    d = repo / 'rtl'
    if not d.is_dir():
        raise InputError('rtl/ 不存在: %s' % d)
    out = set()
    for f in sorted(d.rglob('*.sv')):
        for ln in f.read_text(errors='replace').splitlines():
            m = _MOD.match(ln)
            if m:
                out.add(m.group(1))
    if not out:
        raise InputError('rtl/ 下没解析出任何 module')
    return out


# ------------------------------------------------------------------ 五条检查

class Report(object):
    def __init__(self):
        self.fail = collections.OrderedDict()
        self.info = []

    def bad(self, check, msg):
        self.fail.setdefault(check, []).append(msg)

    def note(self, msg):
        self.info.append(msg)

    def ok(self, check):
        return check not in self.fail


def c1_owner_unique(uni, o2n, rep):
    """C1: 一个 old_target 只能有一行；两个 old_target 不得认领同一个 G1 模块。"""
    for label, rows, gi in (('g1_universe.tsv', uni, 1), ('g1_old_to_new_map.tsv', o2n, 1)):
        seen = {}
        for i, f in rows:
            if f[0] in seen:
                rep.bad('C1', '%s: old_target %s 出现在两行 (第 %d 行 与 第 %d 行)'
                             % (label, f[0], seen[f[0]], i))
            seen[f[0]] = i
        owner = collections.defaultdict(list)
        for i, f in rows:
            if f[gi] and f[gi] != '-':
                owner[f[gi]].append((i, f[0]))
        for g1n, who in sorted(owner.items()):
            if len(who) > 1:
                rep.bad('C1', '%s: G1 模块 %s 被 %d 个 old_target 同时认领: %s'
                             % (label, g1n, len(who),
                                ', '.join('第%d行 %s' % w for w in who)))


def c3_no_duplicate(uni, o2n, norm, cfg, rep):
    """C3: 逐字重复行 / 重复键 / 两份台账互相矛盾。"""
    for label, rows in (('g1_universe.tsv', uni), ('g1_old_to_new_map.tsv', o2n),
                        ('ledger_normalized.tsv', norm),
                        ('g1_configured_universe.tsv', cfg)):
        seen = {}
        for i, f in rows:
            k = '\t'.join(f)
            if k in seen:
                rep.bad('C3', '%s: 第 %d 行与第 %d 行逐字重复: %s'
                             % (label, i, seen[k], f[0]))
            seen[k] = i
        keys = {}
        for i, f in rows:
            if f[0] in keys:
                rep.bad('C3', '%s: 键 %s 重复出现（第 %d、%d 行）'
                             % (label, f[0], keys[f[0]], i))
            keys[f[0]] = i

    a = dict((f[0], f[1]) for _, f in uni)
    b = dict((f[0], f[1]) for _, f in o2n)
    if set(a) != set(b):
        only_a, only_b = sorted(set(a) - set(b)), sorted(set(b) - set(a))
        rep.bad('C3', 'g1_universe.tsv 与 g1_old_to_new_map.tsv 的 old_target 集合不同: '
                      '仅前者 %s; 仅后者 %s' % (only_a[:5], only_b[:5]))
    for k in sorted(set(a) & set(b)):
        if a[k] != b[k]:
            rep.bad('C3', '两份台账对 %s 的 g1_name 不一致: g1_universe=%s vs '
                          'g1_old_to_new_map=%s' % (k, a[k], b[k]))


def c4_no_dangling(uni, o2n, g1mods, rep):
    """C4: 映射到的 G1 模块必须真实存在；标 gone 的必须真的不存在。"""
    for label, rows in (('g1_universe.tsv', uni), ('g1_old_to_new_map.tsv', o2n)):
        for i, f in rows:
            old, g1n, disp = f[0], f[1], f[2]
            gone = disp in GONE_TOKENS
            if g1n == '-':
                if not gone:
                    rep.bad('C4', '%s:%d %s 的 g1_name 是 "-" 却没标 gone/removed（disposition=%s）'
                                 % (label, i, old, disp))
                elif old in g1mods:
                    rep.bad('C4', '%s:%d %s 标了 %s，但 G1 golden 里确实存在同名模块 '
                                  '→ 悬挂的 gone 声明' % (label, i, old, disp))
            else:
                if gone:
                    rep.bad('C4', '%s:%d %s 既标 %s 又给了 g1_name=%s，自相矛盾'
                                 % (label, i, old, disp, g1n))
                if g1n not in g1mods:
                    rep.bad('C4', '%s:%d %s → %s，但 G1 golden 里没有这个模块 → 悬挂'
                                 % (label, i, old, g1n))


def c2_conservation(uni, cfg, norm, g1mods, impl, rep):
    """C2: 四个集合的差集必须能被明确归类；不能有无法归类的残余。"""
    A = set(f[0] for _, f in cfg if f[1] == 'yes')          # in_universe
    X = set(f[0] for _, f in cfg if f[1] == 'no')           # 排除类
    src = dict((f[0], f[2]) for _, f in cfg)
    B = set(f[1] for _, f in uni if f[1] != '-')            # 台账映射目标

    for i, f in cfg:
        if f[1] not in ('yes', 'no'):
            rep.bad('C2', 'g1_configured_universe.tsv:%d %s 的 in_universe=%r 既不是 yes 也不是 no'
                         % (i, f[0], f[1]))

    if A & X:
        rep.bad('C2', 'in_universe 同时为 yes 和 no: %s' % sorted(A & X)[:5])

    # (a) universe ∪ 排除类 必须精确等于 G1 golden 模块全集
    resid_cfg = (A | X) - g1mods
    resid_g1 = g1mods - (A | X)
    if resid_cfg:
        rep.bad('C2', 'configured_universe 里有 %d 个模块不在 G1 golden（幽灵条目）: %s'
                     % (len(resid_cfg), sorted(resid_cfg)[:8]))
    if resid_g1:
        rep.bad('C2', 'G1 golden 里有 %d 个模块在 configured_universe 中完全没出现，'
                      '既没计入 universe 也没归入排除类（★无法归类的残余★）: %s'
                     % (len(resid_g1), sorted(resid_g1)[:8]))

    # (b) 台账映射目标必须落在 universe 或排除类里
    resid_b = B - (A | X)
    if resid_b:
        rep.bad('C2', '台账映射到了 %d 个既不在 universe 也不在排除类的模块: %s'
                     % (len(resid_b), sorted(resid_b)[:8]))

    # (c) source 列必须与「是否被 old306 映射覆盖」逐行一致
    covered = A & B
    for n in sorted(A):
        want = 'from_old_306' if n in covered else 'new_target'
        if src.get(n) != want:
            rep.bad('C2', 'g1_configured_universe.tsv: %s 的 source=%s，但按台账映射应为 %s'
                         % (n, src.get(n), want))

    # (d) rtl/ 实现集合：要么对应 universe 里的目标，要么是符合命名约定的内部件
    resid_impl = set()
    for m in sorted(impl):
        if m in g1mods:
            if m not in A:
                rep.bad('C2', 'rtl/ 实现了 %s，它在 G1 golden 里但不在 universe（属排除类），'
                              '无法归类' % m)
        elif not INTERNAL_CORE_RE.search(m):
            resid_impl.add(m)
    if resid_impl:
        rep.bad('C2', 'rtl/ 里有 %d 个模块既不对应任何 G1 golden 模块，也不符合内部件命名'
                      '约定 (^xs_ / _pkg / _wrapper)（★无法归类的残余★）: %s'
                     % (len(resid_impl), sorted(resid_impl)[:8]))

    # (e) ledger_normalized 的 MAIN/AUX 分栏必须与映射一致，且 target 须在 universe 内
    for i, f in norm:
        t, bucket = f[0], f[1]
        if bucket not in ('MAIN', 'AUX'):
            rep.bad('C2', 'ledger_normalized.tsv:%d %s 的 bucket=%r 不是 MAIN/AUX' % (i, t, bucket))
            continue
        if t not in A:
            rep.bad('C2', 'ledger_normalized.tsv:%d target %s 不在 G1 universe 里，无法归类'
                         % (i, t))
            continue
        want = 'MAIN' if t in covered else 'AUX'
        if bucket != want:
            rep.bad('C2', 'ledger_normalized.tsv:%d %s 记 %s，但它%s被 old306 映射覆盖，应为 %s'
                         % (i, t, bucket, '' if t in covered else '不', want))

    rep.note('C2 集合规模: G1 golden=%d = universe %d + 排除 %d; '
             '台账映射目标 %d (其中落在 universe 内 %d); rtl 实现 %d '
             '(对应 golden %d + 内部件 %d)'
             % (len(g1mods), len(A), len(X), len(B), len(covered), len(impl),
                len(impl & g1mods), len(impl - g1mods)))


def c5_slot_consistent(uni, ev, slotmap, slotwhy, g0, g1, rep):
    """C5: 台账映射必须与重算的槽位判据一致；判不准的必须在证据表里登记。"""
    evrow = {}
    for i, f in ev:
        if f[0] in evrow:
            rep.bad('C5', 'g1_slot_map_evidence.tsv:%d old_target %s 重复' % (i, f[0]))
        evrow[f[0]] = (i, f)

    # 证据表本身必须与重算结果一致（防止证据表跟着台账一起漂）
    for old, (i, f) in sorted(evrow.items()):
        rec_g1, rec_by = f[1], f[2]
        got = slotmap.get(old)
        got_by = slotwhy.get(old, 'UNRESOLVED')
        if got is None:
            if rec_by != 'UNRESOLVED':
                rep.bad('C5', '证据表:%d %s 记判据=%s → %s，但重算结果是判不准；证据表已失效'
                             % (i, old, rec_by, rec_g1))
        else:
            if rec_by == 'UNRESOLVED':
                rep.bad('C5', '证据表:%d %s 记为 UNRESOLVED，但重算给出了 %s (%s)；'
                              '留白已经不成立，必须补映射' % (i, old, got, got_by))
            elif rec_g1 != got or rec_by != got_by:
                rep.bad('C5', '证据表:%d %s 记 %s(%s)，重算是 %s(%s)'
                             % (i, old, rec_g1, rec_by, got, got_by))
        # 端口数也必须对得上（多一道能看见的闸）
        if len(f) >= 5:
            for want, base, nm in ((f[3], g0, old), (f[4], g1, rec_g1)):
                if want in ('-', ''):
                    continue
                have = base.ports.get(nm)
                if have is None or str(have) != want:
                    rep.bad('C5', '证据表:%d %s 记 %s 端口=%s，实测=%s'
                                 % (i, old, nm, want, have))

    for i, f in uni:
        old, g1n = f[0], f[1]
        claim = '' if g1n == '-' else g1n
        got = slotmap.get(old)
        if got is None:
            # 槽位沉默：只有登记在证据表里的留白才允许放行
            if old not in evrow or evrow[old][1][2] != 'UNRESOLVED':
                rep.bad('C5', 'g1_universe.tsv:%d %s 的槽位判据判不准，且证据表里没有登记'
                              '留白理由 → fail-closed（沉默不等于通过）' % (i, old))
            continue
        if claim != got:
            rep.bad('C5', 'g1_universe.tsv:%d %s → 台账写 %s，槽位判据(%s)说是 %s'
                         % (i, old, claim or '(gone)', slotwhy[old], got))
        if got != old and old not in evrow:
            rep.bad('C5', 'g1_universe.tsv:%d %s → %s 是非同名映射，但证据表里没有对应依据行'
                         % (i, old, got))


# ------------------------------------------------------------------ main

EV_HDR = ('# 槽位判据重算证据（check_universe_freeze.py --emit-evidence 生成；note 列人工补）\n'
          '# 只收录「槽位答案 != 同名」与「判不准」两类行；其余 274 行同名同槽位，无话可说。\n'
          '# old_target\tg1_name\tcriterion\tg0_ports\tg1_ports\tg0_slots\tg1_slots\tnote')


def fmt_sites(base, name):
    s = base.sites.get(name)
    return ';'.join('%s.%s' % t for t in sorted(s)) if s else '(无例化点)'


CHECKS = ('C1', 'C2', 'C3', 'C4', 'C5')
TITLES = {'C1': 'OWNER_UNIQUE   target/G1 owner 唯一',
          'C2': 'CONSERVATION   全集守恒（无法归类的残余 = FAIL）',
          'C3': 'NO_DUPLICATE   零重复',
          'C4': 'NO_DANGLING    零悬挂',
          'C5': 'SLOT_CONSISTENT 槽位判据重算一致'}


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    here = pathlib.Path(__file__).resolve().parent
    ap.add_argument('--repo', default=str(os.environ.get('XSSV_HOME') or here.parent))
    ap.add_argument('--g0', default=G0_DEFAULT)
    ap.add_argument('--g1', default=G1_DEFAULT)
    ap.add_argument('--no-slots', action='store_true',
                    help='跳过 C5（不读 G0/G1 golden，只查台账自洽）')
    ap.add_argument('--only', action='append', choices=CHECKS,
                    help='只跑指定的检查（可重复）')
    ap.add_argument('--emit-evidence', metavar='FILE',
                    help='把槽位判据的重算结果写成证据表（只写非同名映射与判不准的行），'
                         '然后退出。人工补 note 列后即为 docs/g1_slot_map_evidence.tsv。')
    args = ap.parse_args(argv)

    want = set(args.only) if args.only else set(CHECKS)
    if args.no_slots:
        want.discard('C5')
    repo = pathlib.Path(args.repo)
    d = repo / 'docs'
    rep = Report()

    if args.emit_evidence:
        try:
            uni0 = read_tsv(d / 'g1_universe.tsv', 5, 'g1_universe.tsv')
            g0b, g1b = Baseline(args.g0, 'G0'), Baseline(args.g1, 'G1')
        except InputError as e:
            sys.stderr.write('INPUT/PARSE ERROR (fail-closed): %s\n' % e)
            return 2
        mp, wy = build_slot_map(g0b, g1b)
        lines = [EV_HDR]
        for _, f in uni0:
            old = f[0]
            got = mp.get(old)
            if got == old and wy.get(old) != 'wrapper_insert':
                continue            # 同名且无插壳：无话可说，不进证据表
            if got is None:
                lines.append('\t'.join([old, '-', 'UNRESOLVED',
                                        str(g0b.ports.get(old, '-')), '-',
                                        fmt_sites(g0b, old), '-', 'TODO 填留白理由']))
            else:
                lines.append('\t'.join([old, got, wy[old],
                                        str(g0b.ports.get(old, '-')),
                                        str(g1b.ports.get(got, '-')),
                                        fmt_sites(g0b, old), fmt_sites(g1b, got), '']))
        pathlib.Path(args.emit_evidence).write_text('\n'.join(lines) + '\n')
        sys.stderr.write('# 写出 %d 行证据 -> %s\n' % (len(lines) - 2, args.emit_evidence))
        return 0

    try:
        uni = read_tsv(d / 'g1_universe.tsv', 5, 'g1_universe.tsv')
        o2n = read_tsv(d / 'g1_old_to_new_map.tsv', 4, 'g1_old_to_new_map.tsv')
        cfg = read_tsv(d / 'g1_configured_universe.tsv', 3, 'g1_configured_universe.tsv')
        norm = read_tsv(d / 'ledger_normalized.tsv', 3, 'ledger_normalized.tsv')
        impl = rtl_modules(repo)
        g1 = Baseline(args.g1, 'G1')
        g1mods = set(g1.ports)
        g0 = slotmap = slotwhy = ev = None
        if 'C5' in want:
            g0 = Baseline(args.g0, 'G0')
            slotmap, slotwhy = build_slot_map(g0, g1)
            ev = read_tsv(d / 'g1_slot_map_evidence.tsv', 3, 'g1_slot_map_evidence.tsv')
    except InputError as e:
        sys.stderr.write('INPUT/PARSE ERROR (fail-closed): %s\n' % e)
        return 2

    if 'C1' in want:
        c1_owner_unique(uni, o2n, rep)
    if 'C3' in want:
        c3_no_duplicate(uni, o2n, norm, cfg, rep)
    if 'C4' in want:
        c4_no_dangling(uni, o2n, g1mods, rep)
    if 'C2' in want:
        c2_conservation(uni, cfg, norm, g1mods, impl, rep)
    if 'C5' in want:
        c5_slot_consistent(uni, ev, slotmap, slotwhy, g0, g1, rep)

    print('# check_universe_freeze  repo=%s' % repo)
    print('# g1_universe.tsv %d 行, old_to_new %d 行, configured_universe %d 行, '
          'ledger_normalized %d 行, rtl 模块 %d'
          % (len(uni), len(o2n), len(cfg), len(norm), len(impl)))
    for m in rep.info:
        print('# %s' % m)
    print()
    nfail = 0
    for c in CHECKS:
        if c not in want:
            print('%s %-46s SKIPPED' % (c, TITLES[c]))
            continue
        msgs = rep.fail.get(c)
        if not msgs:
            print('%s %-46s PASS' % (c, TITLES[c]))
            continue
        nfail += 1
        print('%s %-46s ★FAIL★ (%d)' % (c, TITLES[c], len(msgs)))
        for m in msgs:
            print('    - %s' % m)
    print()
    if nfail:
        print('FREEZE BLOCKED: %d/%d 项不满足' % (nfail, len(want)))
        return 1
    print('FREEZE OK: %d 项全部满足' % len(want))
    return 0


if __name__ == '__main__':
    sys.exit(main())

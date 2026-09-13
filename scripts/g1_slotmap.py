#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""g1_slotmap.py —— G0/G1 身份解析的**单一实现**（codex 0151 D58）。

## 为什么要有这个文件

在此之前，"G0 目标在 G1 里叫什么"这个问题有三份互不相同的实现：

  scripts/g1_universe.py             同名优先 → 再 manual → 再 body 字节全等
  scripts/g1_configured_universe.py  同名优先 → 再 manual → 再全局 body 哈希
  scripts/check_universe_freeze.py   槽位判据（C5）

前两份都把**同名当身份**，于是 firtool 的整串重编号一发生就串位；第三份是对的，
但它只是个事后检查器 —— 检查器说不一致，生成器下一次重跑又把它改回去。
三份实现互相矛盾的直接后果（实测，见报告）：

  SyncDataModuleTemplate__64entry 家族在 G1 里整体后移一位
      G0 _1(30端口) _2(121) _3(106) _4(10)
      G1 _1(46)     _2(30)  _3(121) _4(106) _5(10)
  同名优先的生成器把 5 行全写成 `same_name`，并把 `_4` 的 receipt 记到了
  G1 `_5` 头上 —— 而 G1 `_5` 没有实现、没有 UT、没有 receipt。
  ★这 4 行在正确映射下两侧端口数逐位相同（30/121/106/10），
    任何"比端口总数"的闸都看不见它。★

本模块把身份解析收敛成一份：**槽位判据为准，同名只是兜底**。
两个生成器与冻结门禁都 import 它，实现上不可能再漂。

## 判据（全部能给出是/否，不用相似度打分）

模块身份 = 它占据的 `(父模块, 实例名)` 槽位集合。firtool 的实例名来自 Chisel
变量名，跨 422 个 commit 比"例化顺序编号"稳定得多；槽位→模块 在每个基线内是
双射，所以**两个基线都存在的槽位就是映射本身**。

  site             两侧槽位集合完全相等。
  site_common      集合不等但有两版共有的槽位；共有槽位在对侧放的是谁就是答案。
  site_via_parent  父模块自己也被重编号了；先把父映射过去再查槽位，迭代到不动点。
  wrapper_insert   槽位答案 X 是**新插入的薄壳**（恰好 1 个子例化、无 always、
                   除纯直通外无赋值），真身仍是同名模块，X 是新增 target。
  （判不准 → 不进 map。**如实留白，不猜**。）

## 指纹（C6）

`fingerprint()` 返回端口方向/宽度/名字的有序签名、参数签名、子例化类型多重集、
层次角色。**端口总数不是指纹**：同一个 Chisel 类的两次例化端口表天生相同，
端口数相等只能给候选集，不能定身份。
"""
from __future__ import print_function

import collections
import hashlib
import json
import pathlib
import re

G0_DEFAULT = '/home/eda/xs-env/G0-canonical/golden-rtl'
G1_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'

_MOD = re.compile(r'^[ \t]*module[ \t]+([A-Za-z_]\w*)')
_END = re.compile(r'^[ \t]*endmodule\b')
# firtool 例化：缩进 >= 2 空格 + `<Type> <inst> (` 单独成行
_INST = re.compile(r'^[ \t]{2,}([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)[ \t]*\([ \t]*$')
_PORT = re.compile(r'^[ \t]*(input|output|inout)[ \t]')
# 完整端口声明（方向 / 位宽 / 名字）。容忍 wire/reg/logic、signed、`[ 7:0]`。
_PORT_FULL = re.compile(
    r'^[ \t]*(input|output|inout)[ \t]+'
    r'(?:(?:wire|reg|logic)[ \t]+)?'
    r'(?:signed[ \t]+)?'
    r'(?:\[[ \t]*(\d+)[ \t]*:[ \t]*(\d+)[ \t]*\][ \t]*)?'
    r'([A-Za-z_]\w*)[ \t]*'
    r'(?:,[ \t]*)?$')
_HDR_END = re.compile(r'^[ \t]*\)[ \t]*;[ \t]*$')
_PARAM = re.compile(r'^[ \t]*parameter[ \t]+(?:\[[^\]]*\][ \t]*)?([A-Za-z_]\w*)')
_TRAIL_NUM = re.compile(r'_\d+$')
_SCALA_LN = re.compile(rb'\.scala:\d+')


class InputError(Exception):
    """fail-closed：读不到 / 解析不了的东西一律抛出，不猜、不跳过。"""


class Baseline(object):
    """流式扫一遍 golden：模块名 / 端口签名 / 参数 / 例化槽位。不留模块体。

    `include_v`（codex 0151 D59）：主 universe 要扫 `.sv` **与** `.v`。
    G1 里 `PrintCommitIDModule.v` 是真实设计定义，只扫 `.sv` 会让它凭空消失。
    """

    def __init__(self, root, tag, include_v=True):
        p = pathlib.Path(root)
        if not p.is_dir():
            raise InputError('%s golden 目录不存在: %s' % (tag, root))
        files = sorted(p.glob('*.sv'))
        if include_v:
            files += sorted(p.glob('*.v'))
        if not files:
            raise InputError('%s: %s 下一个 .sv 都没有' % (tag, root))
        self.tag = tag
        self.root = p
        self.ports = {}                              # name -> 端口数（C5 沿用）
        self.portsig = {}                            # name -> ((dir,msb,lsb,name), …)
        self.params = {}                             # name -> (参数名, …)
        self.deffile = {}                            # name -> 定义文件名
        self.sites = collections.defaultdict(set)    # type -> {(parent, inst)}
        self.slot = {}                               # (parent, inst) -> type
        self.kids = collections.defaultdict(list)    # parent -> [(type, inst)]
        dups = []
        for f in files:
            self._scan(f, dups)
        if not self.ports:
            raise InputError('%s: 一个模块都没解析出来（解析器坏了？）' % tag)
        if dups:
            raise InputError('%s: 同名模块出现多次: %s'
                             % (tag, ' '.join(sorted(set(dups))[:8])))

    def _scan(self, f, dups):
        cur, np_, inhdr, inparam = None, 0, False, False
        sig, prm = [], []
        with f.open(errors='replace') as fh:
            for ln in fh:
                if cur is None:
                    m = _MOD.match(ln)
                    if m:
                        cur, np_, sig, prm = m.group(1), 0, [], []
                        # `module Foo #(` —— 先过参数段，再进端口段
                        inparam = '#' in ln[m.end():]
                        inhdr = not inparam
                    continue
                if _END.match(ln):
                    if cur in self.ports:
                        dups.append(cur)
                    self.ports[cur] = np_
                    self.portsig[cur] = tuple(sig)
                    self.params[cur] = tuple(prm)
                    self.deffile[cur] = f.name
                    cur, inhdr, inparam = None, False, False
                    continue
                if inparam:
                    pm = _PARAM.match(ln)
                    if pm:
                        prm.append(pm.group(1))
                    # 参数段以 `)(`（紧接端口段）或 `);`（无端口）收尾
                    s = ln.strip()
                    if s.startswith(')'):
                        inparam = False
                        inhdr = not _HDR_END.match(ln)
                    continue
                if inhdr:
                    if _HDR_END.match(ln):
                        inhdr = False
                    elif _PORT.match(ln):
                        np_ += 1
                        fm = _PORT_FULL.match(ln.rstrip('\n'))
                        if fm:
                            d, msb, lsb, nm = fm.groups()
                            sig.append((d,
                                        int(msb) if msb is not None else -1,
                                        int(lsb) if lsb is not None else -1,
                                        nm))
                        else:
                            # 看不懂的端口行：记成不可比指纹元素，绝不静默当成"没有"
                            sig.append(('?', -1, -1, ln.strip()))
                    continue
                im = _INST.match(ln.rstrip('\n'))
                if im:
                    typ, inst = im.group(1), im.group(2)
                    self.sites[typ].add((cur, inst))
                    self.slot[(cur, inst)] = typ
                    self.kids[cur].append((typ, inst))
        if cur is not None:
            raise InputError('%s: %s 里 module %s 没有 endmodule（解析器 fail-closed）'
                             % (self.tag, f.name, cur))

    # ---- 槽位 ----------------------------------------------------------
    def site_key(self, name):
        s = self.sites.get(name)
        return tuple(sorted(s)) if s else None

    # ---- 指纹（C6）------------------------------------------------------
    def fingerprint(self, name):
        """(端口签名, 参数签名, 子例化类型多重集, 层次角色) —— **不含端口总数**。

        端口总数刻意不作为指纹分量：同一个 Chisel 类的两次例化端口表天生相同，
        `端口数相等` 既不充分也不必要，拿它当证据正是 D58 要禁的东西。
        """
        if name not in self.ports:
            return None
        childs = collections.Counter(_TRAIL_NUM.sub('', t)
                                     for t, _ in self.kids.get(name, ()))
        if not self.kids.get(name):
            role = 'leaf'
        else:
            role = 'internal'
        if not self.sites.get(name):
            role += '+unsited'
        return {
            'ports': list(self.portsig.get(name, ())),
            'params': list(self.params.get(name, ())),
            'children': sorted(childs.items()),
            'role': role,
        }

    def fp_hash(self, name):
        fp = self.fingerprint(name)
        if fp is None:
            return ''
        return hashlib.sha1(json.dumps(fp, sort_keys=True).encode()).hexdigest()[:16]

    def fp_parts(self, name):
        """指纹分量的独立短哈希，便于报告"哪一维不一样"。"""
        fp = self.fingerprint(name)
        if fp is None:
            return None
        h = lambda o: hashlib.sha1(json.dumps(o, sort_keys=True).encode()).hexdigest()[:8]
        return {'ports': h(fp['ports']), 'params': h(fp['params']),
                'children': h(fp['children']), 'role': fp['role']}


# ---------------------------------------------------------------- 薄壳

def is_thin_shell(base, name):
    """`name` 是不是「只包一层」的薄壳：恰好 1 个子例化、无 always、
    除纯 io->io 直通外无别的赋值 —— 返回那个唯一子例化的类型名，否则 None。

    为什么需要：槽位判据认的是槽位。G1 若在某个槽位上插了一层薄壳，槽位的
    占用者就变成薄壳，判据于是把薄壳报成后继，而真正带逻辑的模块被挤进了薄壳里。
    实测唯一一例是 IMSIC：
        G0 槽位 (CSR, imsic) 放 IMSIC
        G1 槽位 (CSR, imsic) 放 IMSIC_WRAP，IMSIC 挪到 (IMSIC_WRAP, imsic)
    把 IMSIC_WRAP 当成"IMSIC 的后继"会让人以为 IMSIC 被重构掉了，其实真身没动窝。

    ★只在槽位解析发现名字移动时才调用★（见 build_slot_map）。G1 里有 83 个薄壳，
    无差别触发会过度改判。
    """
    k = base.kids.get(name, [])
    if len(k) != 1:
        return None
    f = base.root / base.deffile.get(name, '')
    if not f.exists():
        return None
    txt = f.read_text(errors='replace')
    body = _module_body(txt, name)
    if body is None or 'always' in body:
        return None
    keep = []
    for ln in body.splitlines():
        t = ln.strip()
        if (not t or t.startswith('.') or t.startswith('//')
                or t in (');', ')', ';', '(')
                or _INST.match(ln.rstrip('\n'))
                or re.match(r'^(wire|reg|logic)\b[^=]*;$', t)
                or re.match(r'^assign\s+(\w+)\s*=\s*(\w+)\s*;$', t)):
            continue
        keep.append(t)
    if keep:
        return None
    return k[0][0]


def _module_body(txt, name):
    """取 `module <name>` 的端口段之后到 endmodule 之间的原文。"""
    lines = txt.splitlines(True)
    i, n = 0, len(lines)
    while i < n:
        m = _MOD.match(lines[i])
        if m and m.group(1) == name:
            break
        i += 1
    else:
        return None
    if i >= n:
        return None
    # 跳过端口头
    j = i + 1
    while j < n and not _HDR_END.match(lines[j]):
        if _END.match(lines[j]):
            return ''
        j += 1
    k = j + 1
    while k < n and not _END.match(lines[k]):
        k += 1
    return ''.join(lines[j + 1:k])


def unwrap_shell(base, name, origin, limit=3):
    """槽位答案若是薄壳就往里剥，直到剥到带逻辑的那个。
    返回 (真身名, 被剥掉的薄壳列表)。"""
    peeled, cur = [], name
    for _ in range(limit):
        child = is_thin_shell(base, cur)
        if child is None or child == cur or child not in base.ports:
            break
        peeled.append(cur)
        cur = child
        if cur == origin:
            break
    return cur, peeled


# ---------------------------------------------------------------- 槽位映射

def build_slot_map(g0, g1):
    """G0 模块 -> G1 模块。返回 (map, why)。**判不准的不进 map**。"""
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

    # 新插入的薄壳：只在槽位解析发现名字移动时才触发。
    for n in list(mp):
        m = mp[n]
        if m == n:
            continue
        real, peeled = unwrap_shell(g1, m, n)
        if peeled and real == n:
            mp[n], why[n] = n, 'wrapper_insert'
    return mp, why


# ---------------------------------------------------------------- 老路判据

def load_manual_map(repo):
    """docs/g1_manual_map.tsv：人工核对过的重编号。"""
    out = {}
    p = pathlib.Path(repo) / 'docs' / 'g1_manual_map.tsv'
    if p.exists():
        for ln in p.read_text().splitlines():
            if ln.startswith('#') or not ln.strip():
                continue
            f = ln.split('\t')
            if len(f) >= 2:
                out[f[0]] = f[1]
    return out


def _norm_file(path, self_name):
    return _SCALA_LN.sub(b'.scala:0',
                         path.read_bytes()).replace(self_name.encode(), b'@S@')


def body_renumber(g0dir, g1dir, name):
    """纯重编号的铁证：自名归一 + `.scala:<行号>` 归零后，文件字节全等。
    返回唯一命中的 G1 名，多义/无命中返回 None。"""
    g0dir, g1dir = pathlib.Path(g0dir), pathlib.Path(g1dir)
    src = g0dir / ('%s.sv' % name)
    if not src.exists():
        return None
    want = _norm_file(src, name)
    fam = re.match(r'^(.*?)(_\d+)?$', name).group(1)
    hits = [c.stem for c in sorted(g1dir.glob(fam + '*.sv'))
            if _norm_file(c, c.stem) == want]
    # ★必须唯一★：命中多个说明这个家族里有若干个模块体逐字相同的变体，
    # "字节全等"于是只能给候选集、不能定身份。原实现取 sorted 后的第一个，
    # 那是拿字母序当证据。判不准就返回 None，让槽位判据说话。
    return hits[0] if len(hits) == 1 else None


# ---------------------------------------------------------------- 决策

#: 解析方式 → 是否属于「槽位判据背书」
SLOT_CRITERIA = ('site', 'site_common', 'site_via_parent', 'wrapper_insert')


class Resolver(object):
    """把「G0 老目标 → G1 名字」的决策收敛到一处。

    ★优先级（codex 0151 D58：槽位/manual 优先于 same-name）★
        1. 槽位判据          —— 唯一能看穿整串重编号的判据
        2. 人工映射表        —— 槽位沉默时的登记过的人工结论
        3. 同名              —— 兜底，**最低优先级**
        4. body 字节全等重编号
        5. gone

    `resolve()` 返回 (g1_name, label, criterion)：
        label      写进台账的 resolve/disposition 列
        criterion  真正做决定的判据（槽位判据名 / manual / same_name / body / -）
    """

    def __init__(self, g0, g1, g0dir, g1dir, manual=None):
        self.g0, self.g1 = g0, g1
        self.g0dir, self.g1dir = pathlib.Path(g0dir), pathlib.Path(g1dir)
        self.manual = manual or {}
        self.slot, self.slot_why = build_slot_map(g0, g1)

    def resolve(self, old):
        slot = self.slot.get(old)
        man = self.manual.get(old)
        man = man if (man and man in self.g1.ports) else None
        same = old if old in self.g1.ports else None

        if slot is not None:
            crit = self.slot_why[old]
            # 标签只反映"还有谁独立佐证了这个答案"，决定权始终在槽位判据。
            if slot == old:
                label = 'same_name'
            elif man == slot:
                label = 'manual_map'
            elif self._body(old) == slot:
                label = 'renumbered'
            else:
                label = 'slot_map'
            return slot, label, crit
        if man is not None:
            return man, 'manual_map', 'manual'
        if same is not None:
            return same, 'same_name', 'same_name'
        b = self._body(old)
        if b is not None:
            return b, 'renumbered', 'body_exact'
        return '', 'gone_in_g1', '-'

    def _body(self, old):
        if not hasattr(self, '_bodycache'):
            self._bodycache = {}
        if old not in self._bodycache:
            self._bodycache[old] = body_renumber(self.g0dir, self.g1dir, old)
        return self._bodycache[old]

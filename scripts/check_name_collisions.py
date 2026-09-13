#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_name_collisions.py —— 机械查出 G0/G1 两个 golden 基线之间的「同名不同物」。

## 为什么需要这个脚本

firtool 给同一个 Chisel 类的多次例化编号（`FastArbiter`, `FastArbiter_1`, …）。
编号是**按 elaborate 顺序发的**，不是模块身份的一部分。G0(v2r2) → G1(kunminghu-v2)
之间隔了 422 个 commit，插入/删除了模块，整串编号于是平移：

    G0 NewPipelineConnectPipe_31 (17 端口)  ==>  G1 NewPipelineConnectPipe_33
    G0 NewPipelineConnectPipe_33 (96 端口)  ==>  G1 NewPipelineConnectPipe_35 (356 端口)

而工程里几乎所有判据（台账配对、继承脚本、FM 白名单、UT Makefile）都默认
**同名即同模块**。这个假设一旦破，症状是「拿 G0 的 96 端口模块去顶 G1 的 17 端口
目标」——端口对不上，FM unmatched；运气差一点还会一路带进装配层。

## 判据：全是精确比对，没有相似度打分

相似度（Jaccard 之类）在这里是有害的：它总能给出一个"最像的"，于是把
「判不准」伪装成「判出来了」。本脚本只用能给出**是/否**的机械判据：

1. `site` / `site_common` —— **例化点身份**（最强）。一个模块的身份 = 它在设计里
   被谁在哪个实例名上例化的集合 `{(父模块, 实例名)}`；把 `(父模块, 实例名)` 叫一个
   「坑位」。firtool 的实例名来自 Chisel 变量名，跨版本远比编号稳定。
   - `site`：两侧坑位集合完全相同。
   - `site_common`：坑位集合不完全相同（新增/删掉了几处例化），但存在两版共有的
     坑位；共有坑位在对侧放的是谁就是答案。共有坑位指向不止一个模块（例化被拆开）
     时就算判不准。
   这条能定位「内容也一起变了」的重编号，body 比对做不到。
2. `body_exact` —— 模块体（自名换成 `@SELF@`、`.scala:<行号>` 归零）逐字相等。
   「纯重编号」的铁证。
3. `body_childnorm` —— 在 2 之上再把被例化子模块类型名尾部的 `_<数字>` 抹掉，
   用于「自己没变、只是子模块跟着重编号」。仍是精确相等。

端口表相等**不作为身份判据**：同一个 Chisel 类的两次例化端口表天生相同，
它只能给候选集，不能定身份。

## 结论词

- `RENUMBER_COLLISION` ★危险★：该名字在 G0/G1 下是不同的设计元素，且端口表也不同。
  G0 的那个在 G1 里另有其名（本行给出）。按名字配对的台账/脚本在这一行上是错的。
  好消息是端口表能看见它——继承进来后 FM 会 unmatched。
- `SILENT_COLLISION` ★★最危险★★：同名不同物，**但两侧端口表逐位相同**。
  同一个 Chisel 类的两次例化端口表本来就一样，所以"比端口"这道闸完全看不见它；
  继承过去甚至可能 FM SUCCEEDED——把错的东西证明成对的。只有例化点判据能抓。
- `EVOLVED`：同名同例化点，只是 G1 里内容/端口变了。名字配对**是对的**，
  但不能继承上轮实现，须对着 G1 golden 重做。
- `UNRESOLVED`：上述判据都没给出对侧唯一对应。**如实留白**，不猜。
  常见成因（脚本会把例化点原样打出来，让人自己看）：父模块整个改了名、
  一处例化被拆成多处、SRAM 宏几何变了。

## 输出与退出码

TSV 到 stdout（`--tsv <file>` 另存）。
  0 = 扫描完成（有冲突也算完成，冲突是数据不是错误）
  2 = 解析失败（fail-closed：任何一行端口声明看不懂就整体退出，绝不静默跳过）
  3 = `--fail-on-collision` 且存在 RENUMBER_/SILENT_COLLISION

用法:
  python3 scripts/check_name_collisions.py --tsv docs/name_collisions.tsv
  python3 scripts/check_name_collisions.py --name FastArbiter    # 只看该前缀
  python3 scripts/check_name_collisions.py --family FastArbiter  # 家族双射表
  python3 scripts/check_name_collisions.py --where NewPipelineConnectPipe_33
                                                 # 某个名字的两侧例化点
"""
import argparse
import hashlib
import pathlib
import re
import sys
from collections import defaultdict

G0_DEFAULT = '/home/eda/xs-env/G0-canonical/golden-rtl'
G1_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'


class ParseError(Exception):
    """fail-closed: 解析器看不懂的东西一律抛出，不猜、不跳过。"""


# ---------------------------------------------------------------- 词法

# `module Foo(` / `module Foo ();` / `module Foo #(`（DPI helper）
_MOD_OPEN = re.compile(r'^\s*module\s+([A-Za-z_]\w*)\s*(#\s*\()?\s*(\(.*)?$')
_ENDMODULE = re.compile(r'^\s*endmodule\b')
# firtool 端口行：`input  [49:0]  io_in_bits_vaddr,`
# 另容忍 ClockGate.sv 的 `input  wire TE,`、DPI helper 的 `output reg [63:0] r_data`、
# 以及括号内带空格的 `[ 7:0]`。
_PORT = re.compile(
    r'^\s*(input|output|inout)\s+'
    r'(?:(?:wire|reg|logic)\s+)?'
    r'(?:signed\s+)?'
    r'(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?'
    r'([A-Za-z_]\w*)\s*'
    r'(?:,\s*)?$'
)
_CLOSE = re.compile(r'^\s*\)\s*;\s*$')
# firtool 例化：缩进 + `<Type> <inst> (`，单独成行
_INST = re.compile(r'^\s{2,}([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*\(\s*$')
_SCALA_LN = re.compile(rb'\.scala:\d+')
_TYPE_NUM = re.compile(rb'^(\s{2,})([A-Za-z_]\w*?)(?:_\d+)?(\s+[A-Za-z_]\w*\s*\(\s*)$',
                       re.MULTILINE)
_TRAIL_NUM = re.compile(r'_\d+$')


class Port(object):
    __slots__ = ('dirn', 'msb', 'lsb', 'name')

    def __init__(self, dirn, msb, lsb, name):
        self.dirn, self.msb, self.lsb, self.name = dirn, msb, lsb, name

    def key(self):
        return (self.dirn, self.msb, self.lsb, self.name)

    def __str__(self):
        rng = '' if self.msb is None else '[%d:%d] ' % (self.msb, self.lsb)
        return '%s %s%s' % (self.dirn, rng, self.name)


class Module(object):
    __slots__ = ('name', 'file', 'ports', 'body', 'child_insts', '_norm', '_h')

    def __init__(self, name, file, ports, body, child_insts):
        self.name = name
        self.file = file
        self.ports = ports
        self.body = body                 # module 头到 endmodule 的原文 bytes
        self.child_insts = child_insts   # [(子模块类型, 实例名)]
        self._norm = None
        self._h = {}

    # ---- 端口表 --------------------------------------------------------
    def port_key(self):
        return tuple(p.key() for p in self.ports)

    def port_hash(self):
        if 'p' not in self._h:
            h = hashlib.sha1()
            for p in self.ports:
                h.update(('%s|%s|%s|%s\n' % (p.dirn, p.msb, p.lsb, p.name)).encode())
            self._h['p'] = h.hexdigest()
        return self._h['p']

    def n_in(self):
        return sum(1 for p in self.ports if p.dirn == 'input')

    def n_out(self):
        return len(self.ports) - self.n_in()

    # ---- 模块体 --------------------------------------------------------
    def _norm_self(self):
        if self._norm is None:
            b = re.sub(rb'\b' + re.escape(self.name.encode()) + rb'\b',
                       b'@SELF@', self.body)
            self._norm = _SCALA_LN.sub(b'.scala:0', b)
        return self._norm

    def body_exact_hash(self):
        if 'b' not in self._h:
            self._h['b'] = hashlib.sha1(self._norm_self()).hexdigest()
        return self._h['b']

    def body_childnorm_hash(self):
        if 'c' not in self._h:
            self._h['c'] = hashlib.sha1(
                _TYPE_NUM.sub(rb'\1\2\3', self._norm_self())).hexdigest()
        return self._h['c']

    def drop_body(self):
        """哈希算完就把原文丢掉，2000 个模块的全文常驻内存没必要。"""
        self.body = None
        self._norm = None


# ---------------------------------------------------------------- 解析

def parse_file(path):
    """返回该文件里所有 module。看不懂的端口行 -> ParseError（fail-closed）。"""
    lines = path.read_text(errors='replace').splitlines(True)
    out = []
    i, n = 0, len(lines)
    while i < n:
        raw = lines[i]
        if not raw.lstrip().startswith('module '):
            i += 1
            continue
        m = _MOD_OPEN.match(raw)
        if not m:
            raise ParseError('%s:%d: 看不懂的 module 头: %r' % (path.name, i + 1, raw))
        name = m.group(1)
        start = i
        if m.group(2):
            # 参数化 `module Foo #( ... ) (` —— 跳过参数段
            j, depth, opened = i, 0, False
            while j < n:
                depth += lines[j].count('(') - lines[j].count(')')
                if '(' in lines[j]:
                    opened = True
                if opened and depth <= 0:
                    break
                j += 1
            if j >= n:
                raise ParseError('%s: module %s 参数段没闭合' % (path.name, name))
            i = j + 1
            ports, i = _scan_ports(path, lines, i)
        elif m.group(3) and m.group(3).strip() != '(':
            inner = m.group(3).strip()
            if inner in ('();', '()', '() ;'):
                ports = []
                i += 1
            else:
                raise ParseError('%s:%d: 单行端口列表暂不支持: %r'
                                 % (path.name, i + 1, raw))
        else:
            i += 1
            ports, i = _scan_ports(path, lines, i)

        j = i
        while j < n and not _ENDMODULE.match(lines[j]):
            j += 1
        if j >= n:
            raise ParseError('%s: module %s 没有 endmodule' % (path.name, name))

        insts = []
        for k in range(i, j):
            im = _INST.match(lines[k].rstrip('\n'))
            if im:
                insts.append((im.group(1), im.group(2)))

        out.append(Module(name, path.name, ports,
                          ''.join(lines[start:j + 1]).encode(), insts))
        i = j + 1
    return out


def _scan_ports(path, lines, i):
    ports = []
    n = len(lines)
    while i < n:
        line = lines[i].rstrip('\n')
        if _CLOSE.match(line):
            return ports, i + 1
        s = line.strip()
        if not s or s.startswith('//'):
            i += 1
            continue
        pm = _PORT.match(line)
        if not pm:
            raise ParseError('%s:%d: 看不懂的端口声明: %r' % (path.name, i + 1, line))
        d, msb, lsb, pname = pm.groups()
        ports.append(Port(d,
                          int(msb) if msb is not None else None,
                          int(lsb) if lsb is not None else None,
                          pname))
        i += 1
    raise ParseError('%s: 端口列表没有闭合的 ");"' % path.name)


class Baseline(object):
    """一个 golden 基线：模块表 + 各种精确指纹的倒排索引。"""

    def __init__(self, root, include_v=False):
        p = pathlib.Path(root)
        if not p.is_dir():
            raise ParseError('golden 目录不存在: %s' % root)
        files = sorted(p.glob('*.sv'))
        if include_v:
            files += sorted(p.glob('*.v'))
        if not files:
            raise ParseError('%s: 一个 RTL 文件都没有' % root)
        self.root = root
        self.mods = {}
        self.dups = []
        for f in files:
            for m in parse_file(f):
                if m.name in self.mods:
                    self.dups.append((m.name, self.mods[m.name].file, m.file))
                self.mods[m.name] = m
        if not self.mods:
            raise ParseError('%s: 一个模块都没解析出来（解析器坏了？）' % root)

        # 例化点：子模块类型 -> {(父模块, 实例名)}，以及反向的 坑位 -> 类型
        self.sites = defaultdict(set)
        self.site_type = {}
        for parent, m in self.mods.items():
            for typ, inst in m.child_insts:
                self.sites[typ].add((parent, inst))
                self.site_type[(parent, inst)] = typ

        self.by_port = defaultdict(list)
        self.by_body = defaultdict(list)
        self.by_bodycn = defaultdict(list)
        self.by_site = defaultdict(list)
        self.by_sitecn = defaultdict(list)
        for name, m in self.mods.items():
            self.by_port[m.port_hash()].append(name)
            self.by_body[m.body_exact_hash()].append(name)
            self.by_bodycn[m.body_childnorm_hash()].append(name)
            m.drop_body()
            sk = self.site_key(name)
            if sk:
                self.by_site[sk].append(name)
                self.by_sitecn[self.site_key(name, True)].append(name)

    def site_key(self, name, parent_norm=False):
        s = self.sites.get(name)
        if not s:
            return None
        if parent_norm:
            s = set((_TRAIL_NUM.sub('', p), i) for p, i in s)
        return tuple(sorted(s))


# ---------------------------------------------------------------- 比对

# 判据强度。「多义」（同一指纹命中多个名字）与空判据一律 -1：不可用作证据。
_RANK = {'site': 4, 'site_common': 3, 'site_parentnorm': 2,
         'body_exact': 1, 'body_childnorm': 0}


def _uniq(lst, exclude=None):
    out = sorted(set(x for x in lst if x != exclude))
    return out


def first_port_diff(a, b):
    pa, pb = a.ports, b.ports
    if len(pa) != len(pb):
        na = set(p.name for p in pa)
        nb = set(p.name for p in pb)
        bits = ['端口数 %d vs %d' % (len(pa), len(pb))]
        only_a, only_b = sorted(na - nb)[:3], sorted(nb - na)[:3]
        if only_a:
            bits.append('仅G0有:' + ','.join(only_a))
        if only_b:
            bits.append('仅G1有:' + ','.join(only_b))
        return '; '.join(bits)
    for i, (x, y) in enumerate(zip(pa, pb)):
        if x.key() != y.key():
            return '第%d号端口 "%s" vs "%s"' % (i, x, y)
    return ''


def resolve(src, dst, name):
    """在 dst 基线里找 src 基线中 `name` 这个设计元素的对应物。

    返回 (对应名列表, 判据)。判据强度
      site > site_common > site_parentnorm > body_exact > body_childnorm。
    找不到唯一对应就返回 ([], '')——**如实留白，不猜**。
    """
    m = src.mods[name]
    sk = src.site_key(name)
    if sk:
        hit = _uniq(dst.by_site.get(sk, []))
        if len(hit) == 1:
            return hit, 'site'
        # 例化点集合没有完全相等（新增/删除了几处例化），但只要有**两版共有的
        # 例化点**，那个坑位在 G1 里放的是谁就是答案：坑位是 (父模块, 实例名)，
        # 两版都存在同一个坑位时，坑位→模块 的映射本身就是身份映射。
        # 只有当共有坑位在对侧指向不止一个模块（例化被拆开）时才算判不准。
        common = [s for s in sk if s in dst.site_type]
        if common:
            hit = _uniq(dst.site_type[s] for s in common)
            if len(hit) == 1:
                return hit, 'site_common'
        hit = _uniq(dst.by_sitecn.get(src.site_key(name, True), []))
        if len(hit) == 1:
            return hit, 'site_parentnorm'
    hit = _uniq(dst.by_body.get(m.body_exact_hash(), []))
    if len(hit) == 1:
        return hit, 'body_exact'
    if hit:
        return hit, 'body_exact(多义)'
    hit = _uniq(dst.by_bodycn.get(m.body_childnorm_hash(), []))
    if len(hit) == 1:
        return hit, 'body_childnorm'
    if hit:
        return hit, 'body_childnorm(多义)'
    return [], ''


def analyse(g0, g1, name_filter=None):
    """遍历**所有**同名模块，不只端口表不一致的那些。

    只看端口表会漏掉最毒的一类：同一个名字在两版下是不同的设计元素，
    而两者端口表恰好逐位相同（同一个 Chisel 类的两次例化本来就长一样）。
    这类叫 SILENT_COLLISION——现有任何"比端口"的闸都看不见它，
    继承进来后 FM 甚至可能 SUCCEEDED，错的东西被证明成对的。
    """
    rows = []
    for nm in sorted(set(g0.mods) & set(g1.mods)):
        if name_filter and not nm.startswith(name_filter):
            continue
        a, b = g0.mods[nm], g1.mods[nm]
        ports_equal = a.port_key() == b.port_key()
        same_site = (g0.site_key(nm) is not None
                     and g0.site_key(nm) == g1.site_key(nm))
        if ports_equal and same_site:
            continue                      # 名字、端口、例化点全一致：无话可说
        if ports_equal and a.body_exact_hash() == b.body_exact_hash():
            continue                      # 端口 + 模块体逐字一致：无话可说
        fwd, fwd_by = resolve(g0, g1, nm)
        rev, rev_by = resolve(g1, g0, nm)
        # 两个方向可能给出不同强度的证据（例如正向"共有坑位"说是自己、反向
        # "模块体逐字相等"说是别人——参数化家族里两个变体体一样是常事）。
        # 只让**最强的那一档**证据说话，弱证据不足以推翻强证据。
        best = max(_RANK.get(fwd_by, -1), _RANK.get(rev_by, -1))
        collide = ((fwd and nm not in fwd and _RANK.get(fwd_by, -1) == best)
                   or (rev and nm not in rev and _RANK.get(rev_by, -1) == best))
        if collide and not same_site:
            v = 'SILENT_COLLISION' if ports_equal else 'RENUMBER_COLLISION'
        elif fwd == [nm] and rev == [nm]:
            v = 'EVOLVED'
        elif same_site:
            v = 'EVOLVED'
        elif fwd or rev:
            v = 'EVOLVED'
        elif ports_equal:
            continue                      # 端口一致又找不到任何反证：不报
        else:
            v = 'UNRESOLVED'
        rows.append({
            'name': nm, 'verdict': v,
            'g0': '%d(%di/%do)' % (len(a.ports), a.n_in(), a.n_out()),
            'g1': '%d(%di/%do)' % (len(b.ports), b.n_in(), b.n_out()),
            'diff': first_port_diff(a, b),
            'fwd': ','.join(fwd) or '-', 'fwd_by': fwd_by or '-',
            'rev': ','.join(rev) or '-', 'rev_by': rev_by or '-',
            'g0_sites': len(g0.sites.get(nm, ())),
            'g1_sites': len(g1.sites.get(nm, ())),
        })
    return rows


# ---------------------------------------------------------------- 报表

HDR = ['name', 'verdict', 'g0_ports', 'g1_ports',
       'G0.<name>在G1叫', '判据', 'G1.<name>在G0叫', '判据',
       'g0_例化点数', 'g1_例化点数', '第一处端口差异']


def row_line(r):
    return '\t'.join([r['name'], r['verdict'], r['g0'], r['g1'],
                      r['fwd'], r['fwd_by'], r['rev'], r['rev_by'],
                      str(r['g0_sites']), str(r['g1_sites']), r['diff']])


def family_table(g0, g1, prefix, out=sys.stdout):
    fam = re.compile(r'^' + re.escape(prefix) + r'(_\d+)?$')
    n0 = sorted((n for n in g0.mods if fam.match(n)),
                key=lambda n: int(n[len(prefix) + 1:]) if n != prefix else -1)
    n1 = sorted((n for n in g1.mods if fam.match(n)),
                key=lambda n: int(n[len(prefix) + 1:]) if n != prefix else -1)
    out.write('# 家族 %s: G0 %d 个, G1 %d 个\n' % (prefix, len(n0), len(n1)))
    out.write('# G0名\tG1对应\t判据\t端口(G0->G1)\t同名端口表是否一致\t例化点(G0)\n')
    claimed = set()
    for n in n0:
        hit, by = resolve(g0, g1, n)
        claimed.update(hit)
        same = '(G1无同名)'
        if n in g1.mods:
            same = 'YES' if g1.mods[n].port_key() == g0.mods[n].port_key() else 'NO<<<'
        tgt = ','.join(hit) or '判不准'
        pw = '%d->%s' % (len(g0.mods[n].ports),
                         len(g1.mods[hit[0]].ports) if len(hit) == 1 else '?')
        sites = ';'.join('%s.%s' % t for t in sorted(g0.sites.get(n, ()))) or '(顶层/未被例化)'
        out.write('%s\t%s\t%s\t%s\t%s\t%s\n' % (n, tgt, by or '-', pw, same, sites))
    out.write('# G1 里没有被上表认领的:\n')
    for n in n1:
        if n not in claimed:
            hit, by = resolve(g1, g0, n)
            sites = ';'.join('%s.%s' % t for t in sorted(g1.sites.get(n, ()))) or '(顶层/未被例化)'
            out.write('(G1新)%s\t反查G0=%s\t%s\t端口%d\t%s\n'
                      % (n, ','.join(hit) or '判不准', by or '-',
                         len(g1.mods[n].ports), sites))


def where(g0, g1, name, out=sys.stdout):
    for tag, bl in (('G0', g0), ('G1', g1)):
        if name not in bl.mods:
            out.write('%s: 无模块 %s\n' % (tag, name))
            continue
        m = bl.mods[name]
        out.write('%s %s: %d 端口 (%di/%do), body=%s\n'
                  % (tag, name, len(m.ports), m.n_in(), m.n_out(),
                     m.body_exact_hash()[:12]))
        s = bl.sites.get(name)
        if not s:
            out.write('    例化点: (无——顶层或死模块)\n')
        for p, i in sorted(s or ()):
            out.write('    例化点: %s . %s\n' % (p, i))
    if name in g0.mods:
        hit, by = resolve(g0, g1, name)
        out.write('=> G0.%s 在 G1 里是: %s  (判据 %s)\n'
                  % (name, ','.join(hit) or '判不准', by or '-'))
    if name in g1.mods:
        hit, by = resolve(g1, g0, name)
        out.write('=> G1.%s 在 G0 里是: %s  (判据 %s)\n'
                  % (name, ','.join(hit) or '判不准', by or '-'))


# ---------------------------------------------------------------- main

def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--g0', default=G0_DEFAULT)
    ap.add_argument('--g1', default=G1_DEFAULT)
    ap.add_argument('--tsv', help='冲突表另存为 TSV')
    ap.add_argument('--name', help='只看名字以此为前缀的模块')
    ap.add_argument('--family', help='打印该家族的 G0<->G1 对应表后退出')
    ap.add_argument('--where', help='打印该模块在两侧的例化点与对应关系后退出')
    ap.add_argument('--only', choices=['RENUMBER_COLLISION', 'SILENT_COLLISION',
                                       'EVOLVED', 'UNRESOLVED'],
                    help='只输出该结论的行')
    ap.add_argument('--include-v', action='store_true',
                    help='连 .v（DPI helper / SRAM 宏）一起扫，默认只扫 .sv')
    ap.add_argument('--fail-on-collision', action='store_true',
                    help='存在 RENUMBER_/SILENT_COLLISION 就退出码 3（给 CI 用）')
    args = ap.parse_args(argv)

    try:
        g0 = Baseline(args.g0, args.include_v)
        g1 = Baseline(args.g1, args.include_v)
    except ParseError as e:
        sys.stderr.write('PARSE ERROR (fail-closed): %s\n' % e)
        return 2

    for tag, bl in (('G0', g0), ('G1', g1)):
        for nm, f1, f2 in bl.dups:
            sys.stderr.write('WARN %s: 模块 %s 出现在多个文件: %s, %s\n' % (tag, nm, f1, f2))

    if args.where:
        where(g0, g1, args.where)
        return 0
    if args.family:
        family_table(g0, g1, args.family)
        return 0

    rows = analyse(g0, g1, args.name)
    counts = defaultdict(int)
    for r in rows:
        counts[r['verdict']] += 1

    both = set(g0.mods) & set(g1.mods)
    print('# G0 模块 %d, G1 模块 %d, 同名 %d' % (len(g0.mods), len(g1.mods), len(both)))
    print('# 仅 G0 有 %d, 仅 G1 有 %d' % (len(set(g0.mods) - both), len(set(g1.mods) - both)))
    print('# 同名但两侧不是同一回事: %d —— ' % len(rows)
          + ', '.join('%s=%d' % kv for kv in sorted(counts.items())))
    print('# RENUMBER_COLLISION = 同名不同物且端口表也不同（比端口能看见）。')
    print('# SILENT_COLLISION   = 同名不同物但端口表逐位相同 ★比端口的闸看不见★。')
    print('# 以上两类里，按名字配对的台账/脚本都是错的。')
    print()

    shown = [r for r in rows if not args.only or r['verdict'] == args.only]
    text = '\n'.join(['\t'.join(HDR)] + [row_line(r) for r in shown])
    print(text)
    if args.tsv:
        pathlib.Path(args.tsv).write_text(
            '\n'.join(['\t'.join(HDR)] + [row_line(r) for r in rows]) + '\n')
        sys.stderr.write('# 全量 TSV -> %s\n' % args.tsv)

    if args.fail_on_collision and (counts['RENUMBER_COLLISION']
                                   or counts['SILENT_COLLISION']):
        return 3
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""parent_wrapper_lib.py —— 父级 wrapper 生成器的公共部分（被 scripts/gen_tl2chi.py、scripts/gen_l2top.py import；
本身没有 main，不是生成器）。

做法（fail-closed）：父级 = golden 同名端口表 + 一个手写胶合核 + 若干已签核 child。
  * child 按 golden 的实例名 / 模块名 / 顺序例化；每个 child 输出接一根线 <实例名>_<端口名>
    （golden 直接接到顶层输出口的，照接顶层口）；
  * 每个 child 输入的来源从 golden 连线表现读，必须恰好落在下面一类：
      - golden 连的是顶层输入口 / 另一个 child 的输出（可带位选） → 照接（child 输出换成本文件的线名）；
      - golden 连的是字面常量 → 照抄常量；
      - 其余（golden 在那里写了表达式 / 本层寄存器 / 本层具名线）→ 必须在 spec.drives 里有一条，接到核的某个输出（元素）；
    两类都不命中、或一个端口命中两类 → 生成失败；
  * 每个顶层输出必须恰好有一个驱动者（child 输出 / golden assign 的简单来源 / spec.top_drives 里的核输出），否则失败；
  * 核的端口表从手写核现读，每个核输入必须在 spec.gather 里有来源（逐元素），每个核输出至少被用一次，否则失败；
  * spec.drives / spec.top_drives 里每一条都必须被用到（防陈旧规则）。
spec.gather 的来源记号：`<实例名>.<端口名>[位选]` = 该 child 输出的线；顶层输入口名；字面常量。
"""
import os
import re
import sys

G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')


class Spec(object):
    def __init__(self, top, core, out, tag, params, gather, drives, top_drives, name):
        self.top, self.core, self.out, self.tag = top, core, out, tag
        self.params, self.gather, self.drives, self.top_drives = params, gather, drives, top_drives
        self.name = name


def die(msg):
    raise SystemExit('parent_wrapper_lib: ' + msg)


def golden_text(mod):
    return open(os.path.join(G, mod + '.sv')).read()


def ports(mod):
    t = golden_text(mod)
    i = t.index('\nmodule %s(' % mod) + 1
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?$', line)
        if not m:
            die('%s: 端口行解析失败: %r' % (mod, line))
        out.append((m.group(1), 1 if m.group(2) is None else int(m.group(2)) + 1, m.group(3)))
    return out


def split_conns(s):
    """.port (expr) 列表，expr 按括号配平取（golden 表达式里有嵌套括号）。"""
    res = []
    i = 0
    while True:
        m = re.compile(r'\.(\w+)\s*\(').search(s, i)
        if not m:
            break
        j = m.end()
        depth = 1
        while depth:
            if s[j] == '(':
                depth += 1
            elif s[j] == ')':
                depth -= 1
            j += 1
        res.append((m.group(1), ' '.join(s[m.end():j - 1].split())))
        i = j
    return res


def golden_instances(TOP):
    t = golden_text(TOP)
    body = t[t.index('\nmodule %s(' % TOP):]
    res = []
    for m in re.finditer(r'^  (\w+) (\w+) \(\n(.*?)^  \);', body, re.S | re.M):
        cm = split_conns(m.group(3))
        if len({p for p, _ in cm}) != len(cm):
            die('%s 有重复端口连线' % m.group(2))
        res.append((m.group(1), m.group(2), dict(cm)))
    return res


def golden_assigns(TOP):
    t = golden_text(TOP)
    body = t[t.index('\nmodule %s(' % TOP):]
    return {m.group(1): ' '.join(m.group(2).split())
            for m in re.finditer(r'^  assign (\w+) =\s*(.*?);\n', body, re.S | re.M)}


def golden_wires_init(TOP):
    """golden 里带初值的具名线：wire X = <表达式>; —— 只用来顺着"纯改名"链找到真正的来源"""
    t = golden_text(TOP)
    body = t[t.index('\nmodule %s(' % TOP):]
    return {m.group(1): ' '.join(m.group(2).split())
            for m in re.finditer(r'^  wire\s+(?:\[\d+:0\]\s+)?(\w+)\s*=\s*(.*?);\n', body, re.S | re.M)}


def core_ports(OUT, CORE, PARAMS):
    """从手写核现读端口表：[(方向, packed 声明（参数已代入）, 名字, unpacked 维)]"""
    t = open(OUT).read()
    i = t.index('module %s' % CORE)
    i = t.index(') (\n', i) + 4
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines():
        line = line.split('//')[0].strip().rstrip(',')
        if not line:
            continue
        m = re.match(r'(input|output)\s+logic\s+(\[[^\]]+\]\s+)?(\w+)((?:\s*\[[^\]]+\])*)$', line)
        if not m:
            die('核端口行解析失败: %r' % line)
        packed = (m.group(2) or '').strip()
        unpacked = re.sub(r'\s+', '', m.group(4) or '')
        for k, v in PARAMS.items():
            packed = packed.replace(k, str(v))
            unpacked = unpacked.replace(k, str(v))
        out.append((m.group(1), packed, m.group(3), unpacked))
    return out


SIMPLE = re.compile(r"(\w+)(\[\d+(?::\d+)?\])?$")
CONST = re.compile(r"\d+'h[0-9A-F]+$")


def emit(S):
    TOP, CORE, OUT, PARAMS = S.top, S.core, S.out, S.params
    CORE_GATHER, CORE_DRIVES, CORE_TOP_DRIVES = S.gather, S.drives, S.top_drives
    P = ports(TOP)
    pdir = {n: d for d, w, n in P}
    pw = {n: w for d, w, n in P}
    I = golden_instances(TOP)
    A_ = golden_assigns(TOP)
    W_ = golden_wires_init(TOP)
    cports = core_ports(OUT, CORE, PARAMS)
    cdir = {n: d for d, _, n, _ in cports}

    # child 输出：golden 线名 -> (inst, port)；以及本文件里的线名
    gnet_driver = {}
    out_target = {}      # (inst, port) -> 顶层输出口名（golden 直连顶层的）
    for mod, inst, cm in I:
        pd = {n: (d, w) for d, w, n in ports(mod)}
        if set(cm) != set(pd):
            die('%s 端口集合与 golden %s 不同' % (inst, mod))
        for p, e in cm.items():
            if pd[p][0] != 'output' or e in ('', '/* unused */'):
                continue
            if e in pdir:
                if pdir[e] != 'output':
                    die('%s.%s 接到顶层输入 %s' % (inst, p, e))
                out_target[(inst, p)] = e
            if e in gnet_driver:
                die('golden 线 %s 有两个驱动' % e)
            gnet_driver[e] = (inst, p)
    child_ports = {inst: {n: (d, w) for d, w, n in ports(mod)} for mod, inst, _ in I}

    used_nets = {}       # 本文件线名 -> 位宽

    def net(inst, port):
        if inst not in child_ports or port not in child_ports[inst]:
            die('没有 child 端口 %s.%s' % (inst, port))
        d, w = child_ports[inst][port]
        if d != 'output':
            die('%s.%s 不是输出' % (inst, port))
        if (inst, port) in out_target:
            return out_target[(inst, port)]
        name = '%s_%s' % (inst, port)
        used_nets[name] = w
        return name

    def resolve_ref(text):
        """CORE_GATHER 里的来源记号 -> wrapper 表达式"""
        m = re.match(r"(\w+)\.(\w+)(\[\d+(?::\d+)?\])?$", text)
        if m:
            return net(m.group(1), m.group(2)) + (m.group(3) or '')
        m = SIMPLE.match(text)
        if m and m.group(1) in pdir:
            if pdir[m.group(1)] != 'input':
                die('核输入来源 %s 是顶层输出' % text)
            return text
        if CONST.match(text) or re.fullmatch(r"\d+'b[01]+", text):
            return text
        die('认不出的来源记号 %s' % text)

    def resolve_golden(e):
        """golden 的 child 输入表达式：简单（顶层输入 / child 输出 / 常量）→ wrapper 表达式；否则 None"""
        if CONST.match(e):
            return e
        m = SIMPLE.match(e)
        if not m:
            return None
        base, sl = m.group(1), m.group(2) or ''
        if base in pdir and pdir[base] == 'input':
            return e
        if base in gnet_driver:
            return net(*gnet_driver[base]) + sl
        if base in W_ and not sl:
            # golden 的"纯改名"具名线（wire inner_x = io_x;）：顺着链找来源；链上一旦出现表达式就不算简单
            return resolve_golden(W_[base])
        return None

    L = []
    A = L.append
    A('module %s (' % TOP)
    A(',\n'.join('  %-6s %-9s%s' % (d, '' if w == 1 else '[%d:0]' % (w - 1), n) for d, w, n in P))
    A(');')
    A('')

    # ---- 核 ----
    core_used_out = set()
    gather_lines = []
    for d, packed, n, unpacked in cports:
        if d == 'input':
            src = CORE_GATHER.get(n)
            if src is None:
                die('核输入 %s 没有来源（CORE_GATHER）' % n)
            if isinstance(src, str):
                if n in ('clock', 'reset'):
                    continue
                gather_lines.append('  assign %s = %s;' % (n, resolve_ref(src)))
            else:
                for idx, s in src:
                    gather_lines.append('  assign %s%s = %s;' % (n, idx, resolve_ref(s)))
    extra = set(CORE_GATHER) - {n for d, _, n, _ in cports if d == 'input'}
    if extra:
        die('CORE_GATHER 有核里不存在的输入：%s' % sorted(extra))

    # ---- child 实例 ----
    used_drives = set()
    used_top = set()
    driven = {}

    def drive(port, who):
        if port in driven:
            die('顶层输出 %s 被驱动两次（%s / %s）' % (port, driven[port], who))
        driven[port] = who

    def core_ref(text):
        m = re.match(r'(\w+)(\[\d+\])?$', text)
        if not m or m.group(1) not in cdir or cdir[m.group(1)] != 'output':
            die('%s 不是核输出' % text)
        core_used_out.add(m.group(1))
        return text

    inst_lines = []
    for mod, inst, cm in I:
        cl = []
        for d, w, p in ports(mod):
            e = cm[p]
            if d == 'output':
                if e in ('', '/* unused */'):
                    tgt = ''
                elif (inst, p) in out_target:
                    tgt = out_target[(inst, p)]
                    drive(tgt, '%s.%s' % (inst, p))
                else:
                    tgt = '%s_%s' % (inst, p)
                    used_nets[tgt] = w
            else:
                r = resolve_golden(e)
                rule = CORE_DRIVES.get((inst, p))
                if r is not None and rule is not None:
                    die('%s.%s 既是简单连线（%s）又有核规则' % (inst, p, e))
                if r is None and rule is None:
                    die('%s.%s 的 golden 来源 "%s" 不是简单连线，也没有核规则' % (inst, p, e[:80]))
                if rule is not None:
                    used_drives.add((inst, p))
                    tgt = core_ref(rule)
                else:
                    tgt = r
            cl.append('    .%-40s (%s)' % (p, tgt))
        inst_lines.append('  %s %s (' % (mod, inst))
        inst_lines.append(',\n'.join(cl))
        inst_lines.append('  );')
    stale = set(CORE_DRIVES) - used_drives
    if stale:
        die('CORE_DRIVES 有没用到的规则：%s' % sorted(stale)[:5])

    # ---- 顶层输出 ----
    top_lines = []
    for d, w, n in P:
        if d != 'output' or n in driven:
            continue
        rule = CORE_TOP_DRIVES.get(n)
        e = A_.get(n)
        r = resolve_golden(e) if e is not None else None
        if rule is not None and r is not None:
            die('顶层输出 %s 既是简单连线又有核规则' % n)
        if rule is not None:
            used_top.add(n)
            top_lines.append('  assign %s = %s;' % (n, core_ref(rule)))
        elif r is not None:
            top_lines.append('  assign %s = %s;' % (n, r))
        else:
            die('顶层输出 %s 无驱动（golden: %s）' % (n, e))
        drive(n, 'assign')
    stale = set(CORE_TOP_DRIVES) - used_top
    if stale:
        die('CORE_TOP_DRIVES 有没用到的规则：%s' % sorted(stale)[:5])
    outs = {n for d, w, n in P if d == 'output'}
    if set(driven) != outs:
        die('顶层输出未全覆盖：缺 %s' % sorted(outs - set(driven))[:5])
    unused_core = {n for d, _, n, _ in cports if d == 'output'} - core_used_out
    if unused_core:
        die('核输出没被用到：%s' % sorted(unused_core))

    # ---- 拼装 ----
    A('  // ---- child 输出线（<实例名>_<端口名>）----')
    for n in sorted(used_nets, key=lambda s: [int(x) if x.isdigit() else x for x in re.split(r'(\d+)', s)]):
        w = used_nets[n]
        A('  logic %s%s;' % ('' if w == 1 else '[%d:0] ' % (w - 1), n))
    A('')
    A('  // ---- 胶合核的端口 ----')
    for d, packed, n, unpacked in cports:
        if n in ('clock', 'reset'):
            continue
        A('  logic %s%s%s;' % (packed + ' ' if packed else '', n, (' ' + unpacked) if unpacked else ''))
    A('')
    A('  // ---- 核的输入：从 child 输出 / 顶层输入收集 ----')
    L.extend(gather_lines)
    A('')
    A('  %s u_core (' % CORE)
    A(',\n'.join('    .%-20s (%s)' % (n, n) for _, _, n, _ in cports))
    A('  );')
    A('')
    A('  // ---- %d 个 child（实例名 / 顺序同 golden）----' % len(I))
    L.extend(inst_lines)
    A('')
    A('  // ---- 顶层输出 ----')
    L.extend(top_lines)
    A('')
    A('endmodule')
    return '\n'.join(L)


def replace_region(text, body, tag):
    begin = '// BEGIN GENERATED(%s)' % tag
    end = '// END GENERATED'
    if begin not in text:
        return text.rstrip('\n') + '\n\n' + begin + '\n' + body + '\n' + end + '\n'
    i = text.index(begin)
    j = text.index(end, i)
    return text[:i] + begin + '\n' + body + '\n' + end + text[j + len(end):]


def main(S, argv):
    cur = open(S.out).read()
    new = replace_region(cur, emit(S), S.tag)
    if '--check' in argv:
        ok = new == cur
        print(('OK: ' if ok else 'DRIFT: ') + S.out)
        return 0 if ok else 1
    if new != cur:
        open(S.out, 'w').write(new)
    print('wrote ' + S.out)
    return 0

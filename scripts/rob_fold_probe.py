#!/usr/bin/env python3
"""rob_fold_probe.py -- 证明 golden Rob 的展平寄存器真能按条目下标折叠回数组。

这是"用 for 循环写核"这条路的**前置证据**，不生成 RTL。

做法
  1. 把 golden 的 always 块解析成语句树（if / else if / else + 非阻塞赋值）。
  2. 对每个条目下标 i，取出树里**只**触及 `<prefix>_<i>_<field>` 的投影
     （条件路径一并带上）。
  3. 把投影里 i 的所有下标出现换成 `#`，逐条目比对规范化文本。
     全等 => 这一族可以写成一个 for 循环；不全等 => 报出差异，必须分别写。

★为什么不抽样★：上一轮 Entries 家族"从 VfdivVidiv 外推"得出过两处错结论。
这里对全部条目比对。
"""
import argparse, collections, difflib, re, sys

sys.setrecursionlimit(100000)
ASSIGN = re.compile(r'^([\w\[\]:\.]+)\s*<=\s*(.*);$')


def tokenize(lines, start, end):
    """合并续行，产出 [(indent, text)]，text 是一条完整语句/关键字行。

    ★这里有一个真踩过的坑★：firtool 会把长的 `if (...)` 条件折行，
    而且条件下一行就是它的单条语句体（没有 begin）。若按“累到分号为止”
    合并，条件头和语句体会被粘成一个 token，之后整棵树都错位——
    症状是把并列的 160 个 `if (isFirstEnq_i)` 解成一条 160 层的 else 链。
    所以 if 头以**括号配平**为终止，剩下的文本另起一个 token。
    """
    toks = []
    buf, ind = None, 0

    def flush():
        nonlocal buf
        if buf is not None and buf.strip():
            toks.append((ind, buf.strip()))
        buf = None

    def balanced(t):
        return t.count('(') > 0 and t.count('(') == t.count(')')

    for ln in lines[start:end]:
        s = ln.rstrip()
        if not s.strip():
            continue
        t = s.strip()
        if buf is None:
            ind = len(s) - len(s.lstrip())
            buf = t
        else:
            buf += ' ' + t
        while True:
            b = buf
            if re.match(r'^(if|else if)\s*\(', b) and balanced(b):
                i = b.index('(')
                d, j = 0, i
                while j < len(b):
                    if b[j] == '(':
                        d += 1
                    elif b[j] == ')':
                        d -= 1
                        if d == 0:
                            break
                    j += 1
                head, rest = b[:j + 1], b[j + 1:].strip()
                if rest == 'begin':
                    toks.append((ind, head + ' begin'))
                    buf = None
                    break
                toks.append((ind, head))
                buf = rest if rest else None
                if buf is None:
                    break
                continue
            if b in ('end', 'else', 'else begin') or b.startswith('end'):
                flush()
                break
            if b.endswith(';') or b.endswith('begin'):
                flush()
                break
            break
    flush()
    return toks


def _cond(text):
    """取 `if (...)` 里的条件，按括号配平，不用贪婪/非贪婪猜。"""
    i = text.index('(')
    d, j = 0, i
    while j < len(text):
        if text[j] == '(':
            d += 1
        elif text[j] == ')':
            d -= 1
            if d == 0:
                return text[i + 1:j], text[j + 1:].strip()
        j += 1
    raise ValueError('unbalanced: %r' % text[:80])


class P(object):
    def __init__(self, toks):
        self.t, self.p = toks, 0

    def peek(self):
        return self.t[self.p][1] if self.p < len(self.t) else None

    def seq(self):
        out = []
        while self.p < len(self.t):
            x = self.peek()
            if x.startswith('end') or x.startswith('else'):
                return out
            if x.startswith('if ('):
                out.append(self.ifnode())
                continue
            m = ASSIGN.match(x)
            if m:
                out.append(('asg', m.group(1), m.group(2).strip()))
            self.p += 1 if not m else 1
            if m:
                continue
        return out

    def body(self, has_begin):
        if has_begin:
            b = self.seq()
            if self.peek() is not None and self.peek().startswith('end'):
                self.p += 1
            return b
        x = self.peek()
        if x is None:
            return []
        if x.startswith('if ('):
            return [self.ifnode()]
        m = ASSIGN.match(x)
        self.p += 1
        return [('asg', m.group(1), m.group(2).strip())] if m else []

    def ifnode(self):
        x = self.t[self.p][1]
        cond, tail = _cond(x)
        self.p += 1
        then = self.body(tail == 'begin')
        els = []
        y = self.peek()
        if y is not None and y.startswith('else'):
            if y.startswith('else if'):
                self.t[self.p] = (self.t[self.p][0], y[5:].strip())
                els = [self.ifnode()]
            else:
                hb = y.endswith('begin')
                self.p += 1
                els = self.body(hb)
        return ('if', cond, then, els)


def project(nodes, want):
    out = []
    for n in nodes:
        if n[0] == 'asg':
            if n[1] in want:
                out.append(n)
        else:
            t, e = project(n[2], want), project(n[3], want)
            if t or e:
                out.append(('if', n[1], t, e))
    return out


def render(nodes, ind=0):
    L = []
    for n in nodes:
        if n[0] == 'asg':
            L.append('%s%s <= %s' % (' ' * ind, n[1], n[2]))
        else:
            L.append('%sIF %s' % (' ' * ind, n[1]))
            L += render(n[2], ind + 2)
            if n[3]:
                L.append('%sELSE' % (' ' * ind))
                L += render(n[3], ind + 2)
    return L


def normalize(text, i):
    t = re.sub(r'(?<=_)%d(?=_)' % i, '#', text)
    t = re.sub(r'(?<=_)%d\b' % i, '#', t)
    return re.sub(r'\[%d\]' % i, '[#]', t)


def load_tree(golden, block):
    lines = open(golden).read().split('\n')
    starts = [k for k, l in enumerate(lines)
              if l.startswith('  always @(posedge clock')]
    ends = [k for k, l in enumerate(lines) if l.startswith('  end // always')]
    s = next(k for k in starts
             if ('reset' in lines[k]) == (block == 'reset'))
    e = next(k for k in ends if k > s)
    regs = set()
    for l in lines:
        m = re.match(r'\s*reg\s*(?:\[[^\]]*\])?\s*(\w+)\s*;', l)
        if m:
            regs.add(m.group(1))
    return P(tokenize(lines, s + 1, e)).seq(), regs, (s + 1, e)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden',
                    default='/home/eda/xs-env/G1-canonical/golden-rtl/Rob.sv')
    ap.add_argument('--prefix', required=True)
    ap.add_argument('--depth', type=int, required=True)
    ap.add_argument('--block', choices=['noreset', 'reset'], default='noreset')
    ap.add_argument('--dump', type=int, default=-1)
    a = ap.parse_args()

    tree, regs, span = load_tree(a.golden, a.block)
    print('# block lines %d..%d, %d top-level statements'
          % (span[0], span[1], len(tree)), file=sys.stderr)

    sigs = {}
    for i in range(a.depth):
        want = {r for r in regs
                if re.match(r'^%s_%d_' % (re.escape(a.prefix), i), r)
                or r == '%s_%d' % (a.prefix, i)}
        if not want:
            sigs[i] = None
            continue
        txt = '\n'.join(render(project(tree, want)))
        if a.dump == i:
            print(txt)
            return 0
        sigs[i] = normalize(txt, i)

    groups = collections.defaultdict(list)
    for i, v in sigs.items():
        groups[v].append(i)
    ordered = sorted(groups.items(), key=lambda x: -len(x[1]))
    print('prefix=%s depth=%d block=%s -> %d distinct normalized shapes'
          % (a.prefix, a.depth, a.block, len(groups)))
    for k, (v, idxs) in enumerate(ordered):
        head = (v or '<empty>').split('\n')[0][:88]
        print('  shape%-2d n=%-4d lines=%-5d entries %s%s | %s'
              % (k, len(idxs), 0 if v is None else v.count('\n') + 1,
                 idxs[:6], '...' if len(idxs) > 6 else '', head))
    if len(ordered) > 1:
        d = list(difflib.unified_diff((ordered[0][0] or '').split('\n'),
                                      (ordered[1][0] or '').split('\n'),
                                      'shape0', 'shape1', n=1))
        print('--- shape0 vs shape1 ---')
        for l in d[:60]:
            print(l)
    return 0 if len(groups) == 1 else 2


if __name__ == '__main__':
    sys.exit(main())

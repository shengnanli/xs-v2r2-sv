#!/usr/bin/env python3
"""svparse.py —— 装配壳解析的共享底座（端口表 / 子模块输出网 / 例化连接）。

为什么要单独一个：第一版把"一条连接就是一行、最多折两行"当成事实，Composer 侧
碰巧成立，一上 Predictor 就炸——golden 里有跨十几行、内部带嵌套括号和 `?:` 的连接
表达式。行启发式在这种输入上**会静默配错**，比报错更危险。所以这里改成
**括号配平 + 顶层逗号切分**，任何配不平的输入直接抛错（fail-closed）。
"""
import re


class ParseError(Exception):
    pass


def strip_comments(text):
    """去 // 与 /* */，保留字符串字面量与行数。"""
    def rep(m):
        s = m.group(0)
        if s[0] == '"':
            return s
        if s[1] == '/':
            return ''
        return '\n' * s.count('\n')
    out = re.sub(r'"(?:\\.|[^"\\\n])*"|//[^\n]*|/\*.*?\*/', rep, text, flags=re.S)
    if '/*' in out:
        raise ParseError('未闭合的 /* 注释 -> fail-closed')
    return out


def match_close(text, i):
    pairs = {'(': ')', '[': ']', '{': '}'}
    op = text[i]
    if op not in pairs:
        raise ParseError(f'位置 {i} 不是开括号')
    cl, depth, j = pairs[op], 0, i
    while j < len(text):
        if text[j] == op:
            depth += 1
        elif text[j] == cl:
            depth -= 1
            if depth == 0:
                return j
        j += 1
    raise ParseError(f'括号 {op!r} 未闭合')


def split_top(text, sep=','):
    """按顶层分隔符切分（忽略 () [] {} 内部的分隔符）。"""
    out, depth, cur = [], 0, []
    for ch in text:
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
            if depth < 0:
                raise ParseError('右括号多于左括号')
        if ch == sep and depth == 0:
            out.append(''.join(cur))
            cur = []
        else:
            cur.append(ch)
    if depth != 0:
        raise ParseError('括号未配平')
    out.append(''.join(cur))
    return out


PORT_RE = re.compile(r'^(input|output|inout)\s+(?:wire\s+|reg\s+|logic\s+)?'
                     r'(\[[^\]]*\]\s*)?([A-Za-z_]\w*)$')


def module(text, mod):
    """返回 (端口表原文, 模块体原文)。"""
    t = strip_comments(text)
    m = re.search(r'^module\s+' + re.escape(mod) + r'\b', t, re.M)
    if not m:
        raise ParseError(f'找不到 module {mod}')
    i = t.index('(', m.end())
    j = match_close(t, i)
    k = re.search(r'^endmodule', t[j:], re.M)
    if not k:
        raise ParseError(f'module {mod} 没有 endmodule')
    return t[i + 1:j], t[j + 1:j + k.start()]


def ports(portlist):
    out = []
    for chunk in split_top(portlist):
        d = ' '.join(chunk.split())
        if not d:
            continue
        m = PORT_RE.match(d)
        if not m:
            raise ParseError(f'端口解析失败: {d!r}')
        rng = (m.group(2) or '').strip()
        w = 1
        if rng:
            hi, lo = rng[1:-1].split(':')
            w = int(hi) - int(lo) + 1
        out.append((m.group(3), m.group(1), rng, w))
    if not out:
        raise ParseError('端口表为空')
    return out


WIRE_RE = re.compile(r'^\s*wire\s+(\[[^\]]*\]\s*)?(_\w+_io_\w+)\s*;\s*$', re.M)
INST_RE = re.compile(r'^  ([A-Z][A-Za-z0-9_]*)\s+(\w+)\s*\($', re.M)


def child_nets(body):
    """子模块输出网 = `wire [..] _<inst>_io_<port>;`（无内联赋值的那种）。"""
    out = []
    for line in body.split('\n'):
        m = WIRE_RE.match(line)
        if m:
            out.append(((m.group(1) or '').strip(), m.group(2)))
    return out


def instances(body):
    """返回 [(类型, 实例名, [(子端口, 连接表达式), ...]), ...]，顺序即出现顺序。"""
    out = []
    for m in INST_RE.finditer(body):
        i = body.index('(', m.end() - 1)
        j = match_close(body, i)
        conns = []
        for chunk in split_top(body[i + 1:j]):
            s = ' '.join(chunk.split())
            if not s:
                continue
            if not s.startswith('.'):
                raise ParseError(f'{m.group(2)}: 非具名连接 {s!r} -> fail-closed')
            k = s.index('(')
            port = s[1:k].strip()
            if match_close(s, k) != len(s) - 1:
                raise ParseError(f'{m.group(2)}.{port}: 连接括号不闭合 {s!r}')
            conns.append((port, s[k + 1:-1].strip()))
        if not conns:
            raise ParseError(f'{m.group(2)}: 连接为空')
        out.append((m.group(1), m.group(2), conns))
    if not out:
        raise ParseError('没解析到任何例化')
    return out


def assigns(body):
    out = {}
    for m in re.finditer(r'^  assign\s+(\w+)\s*=\s*(.*?);\s*$', body, re.S | re.M):
        out[m.group(1)] = ' '.join(m.group(2).split())
    return out

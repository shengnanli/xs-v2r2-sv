#!/usr/bin/env python3
"""gen_file_nav.py —— 给大文件生成/刷新「本文件导航」。

背景：用户裁定大文件**不拆**（保持"一个 golden 模块一个文件"）。代价是读者要在
两千行里找路，所以大文件必须带一份导航。

坑（第一次写就踩了）：导航里的行号是插入前算的，导航块一插进去，下面全体下移，
导航**在写下的那一刻就失效了**。所以这里迭代到不动点：插入 → 重算 → 再插入，
直到行号不再变化。之后 readability_audit 的 E 类会持续校验导航没有腐烂。

用法: gen_file_nav.py [--min-lines 1500] [文件...]   （不给文件则扫全 rtl/）
"""
import argparse
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
DIV = re.compile(r'^\s*//\s*[-=]{10,}\s*$')
NAV_START = '// 本文件导航'


def sections(lines):
    """真实分节 = 分隔线的下一行注释，或 //【…】行。纯分隔线/空注释不算。"""
    out = []
    for i, l in enumerate(lines):
        t = None
        if DIV.match(l) and i + 1 < len(lines):
            nxt = lines[i + 1].strip()
            if nxt.startswith('//') and not DIV.match(lines[i + 1]):
                t = nxt.lstrip('/ ').strip()
                out_line = i + 2      # 指向标题行本身，而不是它上面的分隔线
        elif re.match(r'^\s*//\s*【', l):
            t = l.strip().lstrip('/ ').strip()
            out_line = i + 1
        if t and len(t) > 4 and not t.startswith('=') and NAV_START not in t:
            out.append((out_line, t))
    ded = []
    for ln, t in out:
        if not ded or ded[-1][1] != t:
            ded.append((ln, t))
    return ded


def strip_nav(lines):
    out, skip = [], False
    for l in lines:
        if l.startswith(NAV_START):
            skip = True
            continue
        if skip:
            if re.match(r'^//\s+L\d+\s', l) or l.strip() == '//':
                continue
            skip = False
        out.append(l)
    return out


def header_end(lines):
    k = 0
    while k < len(lines) and lines[k].startswith('//'):
        k += 1
    return k


def build(lines, shift):
    """lines = 去掉导航后的文本；shift = 导航块将占用的行数（插入后下方行号统一右移）。"""
    secs = [(ln, t) for ln, t in sections(lines)
            if not t.startswith(('对应 ', '角色：')) and ln > 3]
    nav = [f'{NAV_START}（共 {len(lines) + shift} 行；按"一个 golden 模块一个文件"的规范'
           f'不拆分，用下面的分节定位）：']
    for ln, t in secs:
        title = re.sub(r'^【|】$', '', t).split('。')[0].split('（')[0].strip()
        nav.append(f'//   L{ln + shift:<5d} {title[:64]}')
    nav.append('//')
    return nav


def apply(path):
    """位移是确定的：导航插在文件头之后，所有分节都在其下方，故行号统一加导航块长度。
    （第一版写成迭代求不动点，既绕又写错——插进去的导航当场就指错行。）"""
    lines = strip_nav(path.read_text().splitlines())
    k = header_end(lines)
    secs = [(ln, t) for ln, t in sections(lines)
            if not t.startswith(('对应 ', '角色：')) and ln > 3]
    shift = len(secs) + 2                      # 标题行 + 每条一行 + 收尾的 '//'
    nav = build(lines, shift)
    assert len(nav) == shift, f'导航长度 {len(nav)} 与预估位移 {shift} 不符'
    path.write_text('\n'.join(lines[:k] + nav + lines[k:]) + '\n')
    return len(secs)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('files', nargs='*')
    ap.add_argument('--min-lines', type=int, default=1500)
    a = ap.parse_args()
    # ★相对路径也要能用★：原来直接 pathlib.Path(f)，命令行给相对路径时
    # 下面的 p.relative_to(REPO) 会抛 ValueError —— 导航**已经写进文件了**才崩，
    # 看上去像"工具失败"，实际是成功后在打印那一步挂掉（2026-09-20 实测踩到）。
    targets = [pathlib.Path(f).resolve() for f in a.files] if a.files else [
        p for p in sorted((REPO / 'rtl').rglob('*.sv'))
        if p.read_text().count('\n') + 1 > a.min_lines]
    for p in targets:
        n = apply(p)
        try:
            shown = p.relative_to(REPO)
        except ValueError:      # 目标在仓库外（别的 worktree / 临时树）时照样打印
            shown = p
        print(f'{shown}: 导航 {n} 条')
    return 0


if __name__ == '__main__':
    sys.exit(main())

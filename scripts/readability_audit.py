#!/usr/bin/env python3
"""readability_audit.py —— 可读性验收（与 FM 同等地位的硬指标，须常态化跑）。

本工程有两个硬指标：正确性与可读性。正确性有 UT+FM+receipt 一整套闸；可读性此前
只在最早期人工 grep 过一次，之后上百个文件经机械继承/生成进来**从未复查**——
本脚本把可读性也变成可机器复跑的闸。

检查项（每项都能指出具体文件与行）：
  A. 禁用命名：代码区出现 golden 展平中间名 `_GEN_*` / `_T_<n>`。
     注释里作为"对应 golden 哪根线"的交叉引用是允许的，故按**去注释后的代码区**判。
  B. 文件头：首行须是注释，且头部注释块 ≥3 行（说清这个模块是什么、在哪一层、核心机制）。
  C. 头注释与内容自洽：
     - 头里若列了"已覆盖变体/覆盖 X 个"之类清单，清单中的模块必须真在本文件里；
     - 头里不得引用已不存在的文件（单文件规范下 `<X>_wrapper.sv` 已并入，再提就是误导）。
  D. 单文件结构：模块声明顺序须是 package → xs_*_core → golden 同名 wrapper。
  E. 体量提示：单文件 > 2000 行给出提示（不判失败，仅提示人工评估是否该拆核）。

退出码非零 = 有 A/B/C/D 类问题。
"""
import argparse
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = REPO / 'rtl'

FORBIDDEN = re.compile(r'\b_(GEN|T)(_\d+)?\b')
MOD_RE = re.compile(r'^(package|module)\s+(\w+)', re.MULTILINE)
COVER_LIST = re.compile(r'^//\s{2,}(\w+)\s*[:：]', re.MULTILINE)
WRAPPER_REF = re.compile(r'\b(\w+)_wrapper(\.sv)?\b')


def strip_comments(text):
    """去掉 // 行注释与 /* */ 块注释，只留代码区。"""
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)


def header_block(text):
    out = []
    for ln in text.splitlines():
        if ln.startswith('//'):
            out.append(ln)
        elif not ln.strip():
            if out:
                break
        else:
            break
    return out


def audit_file(p):
    text = p.read_text(errors='replace')
    rel = str(p.relative_to(REPO))
    problems = []

    code = strip_comments(text)
    for m in FORBIDDEN.finditer(code):
        line = code[:m.start()].count('\n') + 1
        problems.append(('A', f'{rel}: 代码区出现 golden 展平名 {m.group(0)}（约第 {line} 行）'))
        break

    hdr = header_block(text)
    if not hdr:
        problems.append(('B', f'{rel}: 文件头没有注释'))
    elif len(hdr) < 3:
        problems.append(('B', f'{rel}: 文件头注释仅 {len(hdr)} 行（要求 ≥3，说清定位与机制）'))

    decls = {m.group(2) for m in MOD_RE.finditer(text)}
    hdr_text = '\n'.join(hdr)
    if re.search(r'已覆盖变体|覆盖变体|变体包装层', hdr_text):
        listed = {m.group(1) for m in COVER_LIST.finditer(hdr_text)}
        stray = sorted(n for n in listed if n not in decls and n.startswith(p.stem.split('_')[0]))
        if stray:
            problems.append(('C', f'{rel}: 头注释列了本文件没有的模块 {stray[:3]}'
                                  f'（单文件规范下这是家族头被整段复制的残留）'))
    for m in WRAPPER_REF.finditer(hdr_text):
        problems.append(('C', f'{rel}: 头注释引用了已不存在的 {m.group(0)}'
                              f'（单文件规范下 wrapper 已并入本文件）'))
        break

    order = [m.group(2) for m in MOD_RE.finditer(text)]
    core_i = next((i for i, n in enumerate(order) if n.startswith('xs_') and n.endswith('_core')), None)
    wrap_i = next((i for i, n in enumerate(order) if n == p.stem), None)
    if core_i is not None and wrap_i is not None and core_i > wrap_i:
        problems.append(('D', f'{rel}: 模块顺序应为 核 → golden 同名 wrapper，当前相反'))

    n = text.count('\n') + 1
    hint = [f'{rel}: {n} 行，建议人工评估是否该把核拆细'] if n > 2000 else []
    return problems, hint


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args()

    all_problems, hints, nfiles = [], [], 0
    for p in sorted(RTL.rglob('*.sv')):
        nfiles += 1
        pr, hi = audit_file(p)
        all_problems += pr
        hints += hi

    from collections import Counter
    cnt = Counter(k for k, _ in all_problems)
    print(f'可读性验收：扫描 {nfiles} 个文件')
    labels = {'A': 'A 代码区禁用命名', 'B': 'B 文件头缺失/过短',
              'C': 'C 头注释与内容不符', 'D': 'D 单文件结构顺序'}
    for k in 'ABCD':
        print(f'  {labels[k]}: {cnt.get(k, 0)}')
    if hints:
        print(f'  E 体量提示（不判失败）: {len(hints)}')
        for h in hints[:5]:
            print(f'      {h}')
    if not a.quiet:
        for k in 'ABCD':
            items = [m for kk, m in all_problems if kk == k]
            for m in items[:8]:
                print(f'    [{k}] {m}')
            if len(items) > 8:
                print(f'    [{k}] …另有 {len(items) - 8} 条')
    return 1 if all_problems else 0


if __name__ == '__main__':
    sys.exit(main())

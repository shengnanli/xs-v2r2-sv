#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_mshr.py —— 从 golden MSHR.sv 的端口表机械生成 rtl/uncore/MSHR.sv 里的两个 GENERATED 区。

  BEGIN GENERATED(core_ports)  —— xs_MSHR_core 的端口表（与 golden 逐位同名同宽同序）
  BEGIN GENERATED(wrapper)     —— golden 同名 wrapper `MSHR`：端口表 + 按名直连 u_core

核体（两个 GENERATED 区之间的全部内容）是手写的，本脚本一个字节都不碰。
端口表逐行取自 golden（fail-closed：解析不了的行直接报错），所以端口契约闸
（port_contract_lint，PORTLINT_ORDER=fail）按构造成立。

用法:
  python3 scripts/gen_mshr.py          # 幂等写入
  python3 scripts/gen_mshr.py --check  # 只比对不写，有漂移 rc=1（gate 用）
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                    '/home/eda/xs-env/G1-canonical/golden-rtl'))
TARGET = REPO / 'rtl' / 'uncore' / 'MSHR.sv'
TOP = 'MSHR'


def golden_ports(top):
    src = (GOLDEN / (top + '.sv')).read_text()
    m = re.search(r'^module %s\(\n(.*?)\n\);\n' % top, src, re.S | re.M)
    if not m:
        raise SystemExit('golden %s.sv 里找不到 module 端口表' % top)
    ports = []
    for ln in m.group(1).split('\n'):
        mm = re.match(r'\s*(input|output)\s+(\[\d+:0\]\s+)?(\w+),?\s*$', ln)
        if not mm:
            raise SystemExit('%s: 解析不了端口行 %r' % (top, ln))
        ports.append((mm.group(1), (mm.group(2) or '').strip(), mm.group(3)))
    return ports


def port_lines(ports, indent):
    wdir = max(len(d) for d, _, _ in ports)
    wwid = max(len(w) for _, w, _ in ports)
    out = []
    for k, (d, w, n) in enumerate(ports):
        sep = ',' if k < len(ports) - 1 else ''
        out.append('%s%-*s %-*s %s%s' % (' ' * indent, wdir, d, wwid, w, n, sep))
    return out


def region_core_ports(ports):
    return port_lines(ports, 2)


def region_wrapper(ports):
    L = ['// ---------------------------------------------------------------------------',
         '// golden 同名 wrapper：端口与 G1 golden MSHR.sv 逐位同名同宽同序，按名直连可读核。',
         '// ---------------------------------------------------------------------------',
         'module %s(' % TOP]
    L += port_lines(ports, 2)
    L.append(');')
    L.append('  xs_MSHR_core u_core (')
    w = max(len(n) for _, _, n in ports)
    for k, (_, _, n) in enumerate(ports):
        sep = ',' if k < len(ports) - 1 else ''
        L.append('    .%-*s (%s)%s' % (w, n, n, sep))
    L.append('  );')
    L.append('endmodule')
    return L


def replace_region(text, tag, lines):
    pat = re.compile(r'(^[ \t]*// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(^[ \t]*// END GENERATED\(%s\)[^\n]*$)'
                     % (re.escape(tag), re.escape(tag)), re.S | re.M)
    m = pat.search(text)
    if not m:
        raise SystemExit('%s 里找不到 GENERATED(%s) 区' % (TARGET, tag))
    return text[:m.start(2)] + '\n'.join(lines) + '\n' + text[m.end(2):]


NAV_RE = re.compile(r'^(  // §\d.*|// BEGIN GENERATED\(wrapper\).*)$')


def region_nav(text):
    """本文件导航（readability_audit E 类：>1500 行必须有，且行号落在分节注释上）。"""
    lines = text.split('\n')
    out = ['// 本文件导航：']
    for i, ln in enumerate(lines):
        if NAV_RE.match(ln):
            label = ln.strip().lstrip('/').strip()
            label = re.sub(r'\s*——.*$', '', label)
            out.append('//   L%d %s' % (i + 1, label[:70]))
    return out


def render():
    ports = golden_ports(TOP)
    text = TARGET.read_text()
    text = replace_region(text, 'core_ports', region_core_ports(ports))
    text = replace_region(text, 'wrapper', region_wrapper(ports))
    # 导航区条目数固定，先占位再按占位后的行号回填（两遍即收敛）
    for _ in range(2):
        text = replace_region(text, 'nav', region_nav(text))
    return text


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('--check', action='store_true', help='只比对不写，有漂移 rc=1')
    args = ap.parse_args()
    new = render()
    cur = TARGET.read_text()
    if args.check:
        if new != cur:
            print('gen_mshr: DRIFT %s' % TARGET.relative_to(REPO))
            return 1
        print('gen_mshr: OK')
        return 0
    if new != cur:
        TARGET.write_text(new)
        print('gen_mshr: 更新 %s' % TARGET.relative_to(REPO))
    else:
        print('gen_mshr: 已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())

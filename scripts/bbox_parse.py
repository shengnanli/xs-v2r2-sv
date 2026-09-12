#!/usr/bin/env python3
"""bbox_parse.py —— 解析 Formality `report_black_boxes` 报告为精确对象集。

返回条目 (side, attrs, design, inst_path)：
  side      'r' / 'i'（ref / impl 容器）
  attrs     黑盒属性串（u=unresolved / e=empty / i=interface_only / s=set_black_box …）
  design    黑盒模块名
  inst_path 实例全路径

只收 **Instances ≥ 1** 的条目：`Instances : 0` 的是读进容器但在本 top 下未被例化的
兄弟变体（e * 标记），不属于本次证明的抽象边界。

fail-closed：报告缺少 FM-184/FM-249 标记、或某 design 块声明的实例数与实际列出的
路径条数不符，一律抛异常——宁可判不出来，也不让残缺报告变成"没有黑盒"。
"""
import re

FM184 = 'Reporting black boxes for current reference and implementation designs. (FM-184)'
FM249 = "No 'black boxes' matched current 'reference and implementation designs'."
SEC_RE = re.compile(r'^####\s+(TECH LIBRARY|DESIGN LIBRARY)\s+-\s+([ri]):(\S+)')
ENTRY_RE = re.compile(r'^([a-zA-Z* ]{1,6}?)\s{2,}(\w+)\s*$')
INST_RE = re.compile(r'^\s+Instances\s*:\s*(\d+)')
PATH_RE = re.compile(r'^\s+([ri]):/\S+')


class BBoxParseError(Exception):
    pass


def parse(text):
    if FM249 in text:
        return []
    if FM184 not in text:
        raise BBoxParseError('报告缺少 FM-184/FM-249 标记，拒绝据此判定')

    out = []
    side = None
    cur = None          # (attrs, design)
    want = 0
    got = []
    for ln in text.splitlines():
        m = SEC_RE.match(ln)
        if m:
            if cur and want and len(got) != want:
                raise BBoxParseError(f'{cur[1]}: 声明 {want} 实例但列出 {len(got)} 条路径')
            side, cur, want, got = m.group(2), None, 0, []
            continue
        if side is None:
            continue
        m = INST_RE.match(ln)
        if m:
            if cur is None:
                raise BBoxParseError('Instances 行出现在 design 名之前')
            want, got = int(m.group(1)), []
            continue
        m = PATH_RE.match(ln)
        if m and cur is not None and want:
            p = ln.strip()
            got.append(p)
            out.append((side, cur[0].strip(), cur[1], p))
            continue
        m = ENTRY_RE.match(ln)
        if m and not ln.startswith(' '):
            if cur and want and len(got) != want:
                raise BBoxParseError(f'{cur[1]}: 声明 {want} 实例但列出 {len(got)} 条路径')
            cur, want, got = (m.group(1), m.group(2)), 0, []
    if cur and want and len(got) != want:
        raise BBoxParseError(f'{cur[1]}: 声明 {want} 实例但列出 {len(got)} 条路径')
    return out


def normalize(entries):
    """归一为可比对的对象集: {(side, design, inst_path)} + 每项属性。"""
    objs, attrs = set(), {}
    for side, a, design, path in entries:
        key = (side, design, path)
        objs.add(key)
        attrs[key] = a
    return objs, attrs


if __name__ == '__main__':
    import sys
    ents = parse(open(sys.argv[1]).read())
    for e in ents:
        print('\t'.join(e))
    print(f'# {len(ents)} 条实例化黑盒', file=sys.stderr)

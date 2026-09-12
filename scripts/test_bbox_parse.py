#!/usr/bin/env python3
"""test_bbox_parse.py —— 黑盒解析负测（codex 0140 P0-1 要求的最低集合 + G1 真实样本）。

跑法: python3 scripts/test_bbox_parse.py
任何一例不符预期即非零退出。
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import bbox_parse as B

BANNER = """**************************************************
Report         : black_boxes

Reference      : r:/WORK/T
Implementation : i:/WORK/T
Version        : V-2023.12-SP3
Date           : Fri Sep 11 22:49:32 2026
**************************************************
"""
LEGEND = """
 ___________________________________________________
|                                                   |
|  Legend:                                          |
|              u = Unresolved design module         |
|___________________________________________________|

"""
BLK_TECH = """##################################################################
####    TECH LIBRARY - i:/FM_BBOX
##################################################################
Type  Design Name
----  ----------
u      array_ext

       Instances : 1 of 1
       ------------------------
       i:/WORK/T/array/array_ext
"""
BLK_TECH_R = BLK_TECH.replace('i:/FM_BBOX', 'r:/FM_BBOX').replace('i:/WORK', 'r:/WORK')
TAIL = '\n1\n'


def ok(name, text, expect_n):
    try:
        got = len(B.parse(text))
    except B.BBoxParseError as e:
        print(f'  BAD  {name}: 预期接受 {expect_n} 条，却抛 {e}')
        return False
    if got != expect_n:
        print(f'  BAD  {name}: 预期 {expect_n} 条，实得 {got}')
        return False
    print(f'  ok   {name}: 接受 {got} 条')
    return True


def rej(name, text):
    try:
        r = B.parse(text)
    except B.BBoxParseError as e:
        print(f'  ok   {name}: 已拒（{str(e)[:58]}）')
        return True
    print(f'  BAD  {name}: 应拒却接受了 {r}')
    return False


def main():
    good_empty = BANNER + B.FM184 + '\n' + LEGEND + B.FM249 + TAIL
    good_full = BANNER + B.FM184 + '\n' + LEGEND + BLK_TECH_R + BLK_TECH + TAIL
    res = []

    # 正样本
    res.append(ok('空集(184+249)', good_empty, 0))
    res.append(ok('非空(ref+impl 各1)', good_full, 2))

    # codex 0140 点名的三类 fail-open
    res.append(rej('P0-1a: 184+249+非空块',
                   BANNER + B.FM184 + '\n' + LEGEND + B.FM249 + '\n' + BLK_TECH + TAIL))
    res.append(rej('P0-1b: 只有249无184', BANNER + B.FM249 + '\n' + BLK_TECH + TAIL))
    res.append(rej('P0-1c: 重复184',
                   BANNER + B.FM184 + '\n' + B.FM184 + '\n' + LEGEND + BLK_TECH + TAIL))

    # 其余 fail-closed 面
    res.append(rej('缺184', BANNER + LEGEND + BLK_TECH + TAIL))
    res.append(rej('184文本被篡改',
                   BANNER + B.FM184.replace('black boxes', 'blackboxes') + '\n' + LEGEND
                   + BLK_TECH + TAIL))
    res.append(rej('249重复', BANNER + B.FM184 + '\n' + LEGEND + B.FM249 + '\n' + B.FM249 + TAIL))
    res.append(rej('249之后又有section',
                   BANNER + B.FM184 + '\n' + LEGEND + B.FM249 + '\n' + BLK_TECH_R + TAIL))
    res.append(rej('实例数多于路径',
                   BANNER + B.FM184 + '\n' + LEGEND
                   + BLK_TECH.replace('Instances : 1 of 1', 'Instances : 2 of 2') + TAIL))
    res.append(rej('路径多于实例数',
                   BANNER + B.FM184 + '\n' + LEGEND
                   + BLK_TECH + '       i:/WORK/T/array/array_ext2\n' + TAIL))
    res.append(rej('重复实例路径',
                   BANNER + B.FM184 + '\n' + LEGEND
                   + BLK_TECH.replace('Instances : 1 of 1', 'Instances : 2 of 2')
                   + '       i:/WORK/T/array/array_ext\n' + TAIL))
    res.append(rej('路径side与section不符',
                   BANNER + B.FM184 + '\n' + LEGEND
                   + BLK_TECH.replace('i:/WORK/T/array', 'r:/WORK/T/array') + TAIL))
    res.append(rej('TECH LIBRARY 未配 FM_BBOX',
                   BANNER + B.FM184 + '\n' + LEGEND
                   + BLK_TECH.replace('i:/FM_BBOX', 'i:/WORK') + TAIL))
    res.append(rej('section内0个design块',
                   BANNER + B.FM184 + '\n' + LEGEND
                   + '##################################################################\n'
                     '####    TECH LIBRARY - i:/FM_BBOX\n'
                     '##################################################################\n' + TAIL))
    res.append(rej('Instances行在design名之前',
                   BANNER + B.FM184 + '\n' + LEGEND
                   + '##################################################################\n'
                     '####    TECH LIBRARY - i:/FM_BBOX\n'
                     '##################################################################\n'
                     '       Instances : 1 of 1\n       i:/WORK/T/a/b\n' + TAIL))

    # 全 0 实例形态（有 section/design 块但都未被例化）→ 合法空集
    zero_blk = ("""##################################################################
####    DESIGN LIBRARY - i:/WORK
##################################################################
Type  Design Name
----  ----------
e *    Sibling_1

       Instances : 0

e *    Sibling_2

       Instances : 0
""")
    res.append(ok('全0实例(未例化兄弟变体)',
                  BANNER + B.FM184 + '\n' + LEGEND + zero_blk + TAIL, 0))
    res.append(rej('无249且无任何design块(报告残缺)',
                   BANNER + B.FM184 + '\n' + LEGEND + TAIL))

    # G1 真实样本（含 Instances : 0 的未例化兄弟变体）
    real = pathlib.Path('/home/eda/xs-env/xs-v2-sv/verif/ut/SRAMTemplate/fm_work/'
                        'SRAMTemplate/black_boxes.rpt')
    if real.exists():
        res.append(ok('G1真实样本 SRAMTemplate(含 Instances:0 兄弟变体)', real.read_text(), 2))
    tage = pathlib.Path('/home/eda/xs-env/xs-v2-sv/verif/ut/TageTable/fm_work/'
                        'TageTable/black_boxes.rpt')
    if tage.exists():
        res.append(ok('G1真实样本 TageTable(多 design 多实例)', tage.read_text(), 26))

    print(f'\n{sum(res)}/{len(res)} 通过')
    return 0 if all(res) else 1


if __name__ == '__main__':
    sys.exit(main())

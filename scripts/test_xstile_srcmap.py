#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""xstile_srcmap.py 的正反测：闸不能恒绿也不能恒红。

  正例：现场 rtl/ + golden + 登记表 → 过，且 golden 逻辑 0。
  反例（每条都必须 FATAL，exit 2）：
    R1 删掉闭包里一个 rtl 定义（Rob）→ 选源退回 golden Rob.sv，它不是存储模型
    R2 从登记表里拿掉一个闭包内的存储模型 → 未登记的 golden 源
    R3 把一个存储模型的登记 sha 改一位 → sha 不等
    R4 登记的文件名与实际选到的文件不同
"""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import xstile_srcmap as x  # noqa: E402

G = pathlib.Path(x.GOLDEN_DEFAULT)
IDX = x.index_sources(G)
REG = x.registered_memories()
fails = 0


def expect(name, ok_expected, idx, reg):
    global fails
    try:
        rows, _ = x.build(G, idx=idx, reg=reg)
        got_ok = True
    except SystemExit as e:
        got_ok = False
        if e.code != 2:
            print(f'FAIL {name}: exit {e.code}，应为 2')
            fails += 1
            return None
    if got_ok != ok_expected:
        print(f'FAIL {name}: 期望{"通过" if ok_expected else "判死"}，实际{"通过" if got_ok else "判死"}')
        fails += 1
        return None
    print(f'ok   {name}')
    return rows if got_ok else None


rows = expect('P0 现场', True, IDX, REG)
if rows is not None:
    mem = [r[0] for r in rows if r[1] == 'MEMORY_MODEL']
    if not mem or any(r[1] not in ('RTL', 'MEMORY_MODEL') for r in rows):
        print('FAIL P0: 分类异常'); fails += 1
    m0 = sorted(mem)[0]

    rtl, gold = IDX
    assert 'Rob' in rtl, 'Rob 应有 rtl 定义'
    expect('R1 删 rtl Rob', False, ({k: v for k, v in rtl.items() if k != 'Rob'}, gold), REG)
    expect('R2 去掉登记 ' + m0, False, IDX, {k: v for k, v in REG.items() if k != m0})
    leaf, sha = REG[m0]
    bad = ('0' if sha[0] != '0' else '1') + sha[1:]
    expect('R3 改登记 sha ' + m0, False, IDX, {**REG, m0: (leaf, bad)})
    expect('R4 改登记文件名 ' + m0, False, IDX, {**REG, m0: ('not_' + leaf, sha)})

print('PASS' if not fails else f'{fails} 条失败')
sys.exit(1 if fails else 0)

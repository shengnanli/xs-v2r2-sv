#!/usr/bin/env python3
"""test_ledger_append_only.py —— 守住 fastlane_ledger 的「最后一行为准」不变式。

**为什么要有这条闸**（2026-09-13 实测）：
`docs/fastlane_ledger.tsv` 是追加式尝试日志，同一 target 可有多行。66 个 target 有重复行，
消费方一律「后者覆盖前者」。对账结果：归一化与「取最后一行」181/181 全等，与「取第一行」
只 123/181 相符 —— **58 个 target 的状态取决于行序**。

也就是说把这个文件排一次序（一个再自然不过的动作），58 个目标的状态会静默改变，而当时
没有任何闸会响：C1-C6 里的 C3 NO_DUPLICATE 查的是 universe 映射表，不是本表。

本测试把这条隐式契约变成可机器复跑的断言。
"""
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
LEDGER = REPO / 'docs' / 'fastlane_ledger.tsv'
NORM = REPO / 'docs' / 'ledger_normalized.tsv'

PASS, FAIL = [], []


def ck(name, ok, detail=''):
    (PASS if ok else FAIL).append(name)
    print(f'  {"ok  " if ok else "FAIL"}  {name}{"  " + detail if detail else ""}')


def rows(path):
    return [l.split('\t') for l in path.read_text().splitlines()
            if l.strip() and not l.startswith('#')]


r = rows(LEDGER)
last, first = {}, {}
for c in r:
    if len(c) > 1:
        last[c[0]] = c[1]
        first.setdefault(c[0], c[1])

norm = {c[0]: c[2] for c in rows(NORM) if len(c) > 2}
inter = set(norm) & set(last)

ck('L1 归一化与「最后一行」逐个相符',
   all(norm[k] == last[k] for k in inter),
   f'{sum(norm[k] == last[k] for k in inter)}/{len(inter)}')

# ★对照★：若「第一行」也全等，那 L1 就是空转的（分不出两种语义）。
n_first = sum(norm[k] == first[k] for k in inter)
ck('L2 对照：「第一行」不全等（否则 L1 空转）',
   n_first < len(inter),
   f'第一行只 {n_first}/{len(inter)} 相符，差 {len(inter) - n_first} 个 target 靠行序区分')

# 重复行存在本身也是前提：没有重复行，这条不变式无从谈起。
dup = [k for k in last if sum(1 for c in r if c and c[0] == k) > 1]
ck('L3 确有重复行（不变式的前提成立）', len(dup) > 0, f'{len(dup)} 个 target 有多行')

# 排序会破坏语义 —— 直接算给看，不靠断言语气。
srt = {}
for c in sorted((c for c in r if len(c) > 1), key=lambda c: (c[0], c[1])):
    srt[c[0]] = c[1]
changed = [k for k in inter if srt.get(k) != last[k]]
ck('L4 排序会静默改变状态（证明约束是实的）', len(changed) > 0,
   f'一旦排序，{len(changed)} 个 target 的状态会变')

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)

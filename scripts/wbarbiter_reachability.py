#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""wbarbiter_reachability.py —— WBArbiter 反饥饿状态机的穷举可达性分析。

## 为什么需要它

`verif/ut/WBArbiterVariants/tb.sv` 的覆盖判据是分档的：N=1 要求那 5 位寄存器**恒 0**，
N=2 要求 `isFull_0` **恒 0**、`cancelCounter_0 <= 1`，N>=3 要求逐路 `isFull` 都到过 1
并且出现过计数饱和分支。这些"该到"与"不该到"如果只是跑出来的经验，就会有两种烂法：

  · 随机激励没跑到 ⇒ 被当成"不可达"，于是把真正的覆盖缺口写进判据里当成合理；
  · 反过来，把本来不可达的挂进判据 ⇒ 这个 UT 永远判 FAILED。

本脚本把判据的来源换成**穷举**：按 golden 的次态方程逐字实现状态机
（cancelCounter[N]×3 位 + isFull[N] + hasFull），从复位态出发遍历全部输入组合，
枚举可达状态集合。N<=4（本家族最大宽度）时状态空间只有几千个，秒级跑完。

## 判据

`--check`：重算并与下表（tb 判据的依据）逐项比对，不一致即非零退出。

用法: python3 scripts/wbarbiter_reachability.py [--check]
"""
import sys
from itertools import product

# 期望表：(可达状态数, 逐路 isFull 是否可达, 逐路 cancelCounter 上界, 饱和分支是否可达)
EXPECTED = {
    1: (1,    [False],                        [0],           False),
    2: (9,    [False, True],                  [1, 7],        False),
    3: (133,  [True, True, True],             [7, 7, 7],     True),
    4: (1479, [True, True, True, True],       [7, 7, 7, 7],  True),
}


def ready_and_next(n, cnt, isf, hf, vld):
    """golden 的一拍：先算 finalValid / in_ready，再算次态。"""
    starving = hf and any(vld[i] and isf[i] for i in range(n))
    fv = [vld[i] and ((not starving) or isf[i]) for i in range(n)]
    rdy, none_higher = [], True
    for i in range(n):
        rdy.append((none_higher and fv[i]) or (not vld[i]))
        none_higher = none_higher and not fv[i]
    ncnt, nisf = list(cnt), []
    for i in range(n):
        stalled = vld[i] and not rdy[i]
        fired = vld[i] and rdy[i]
        if stalled:
            ncnt[i] = 7 if cnt[i] == 7 else cnt[i] + 1
            nisf.append(1 if (cnt[i] >> 1) == 3 else 0)   # golden: &cancelCounter[2:1]
        else:
            if fired:
                ncnt[i] = 0
            nisf.append(0 if fired else isf[i])
    return rdy, (tuple(ncnt), tuple(nisf), 1 if any(nisf) else 0)


def analyse(n):
    start = ((0,) * n, (0,) * n, 0)
    seen, stack, sat = {start}, [start], False
    while stack:
        cnt, isf, hf = stack.pop()
        for vld in product((0, 1), repeat=n):
            rdy, nxt = ready_and_next(n, cnt, isf, hf, vld)
            for i in range(n):
                if cnt[i] == 7 and vld[i] and not rdy[i]:
                    sat = True
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return (len(seen),
            [any(st[1][i] for st in seen) for i in range(n)],
            [max(st[0][i] for st in seen) for i in range(n)],
            sat)


def main():
    check = '--check' in sys.argv[1:]
    bad = []
    for n in sorted(EXPECTED):
        got = analyse(n)
        exp = EXPECTED[n]
        ok = got == exp
        print('N=%d: 可达状态 %-5d isFull_i 可达=%s cnt_i 上界=%s 饱和分支=%s  %s'
              % (n, got[0], got[1], got[2], got[3], 'OK' if ok else '★与登记表不符★'))
        if not ok:
            bad.append((n, exp, got))
    if check and bad:
        for n, exp, got in bad:
            print('  N=%d 期望 %s 实得 %s' % (n, exp, got))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

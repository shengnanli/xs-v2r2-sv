#!/usr/bin/env python3
"""calibrate_cov.py —— 从实跑日志机械算出 `enqentry_gen.COV_MIN_200K` 这张表。

## 为什么这张表不能手填

覆盖闸的下限如果是 1（= 只判非零），它抓不到「激励塌了一个数量级」这种形态 ——
而那正是 UT 报 errors=0 却什么也没测到的主要路子。所以 `enqentry_gen.py` 在
`COV_CALIBRATED=False` 时**拒绝生成**，必须先标定。

标定跑法（CONVENTIONS + enqentry_gen.py 文件头定的）：
    9 变体 x 3 seed x 2 initreg x 200k 拍，取**各桶族内最小值 / 4**。
除以 4 是留余量：下限要抓"塌一个数量级"，不是卡在实测值上让正常波动变红。

## 数据是在哪跑的

仓库现状（共享核那一行还没修，UT 因此在 `perfWakeupByWB` 上红）。
★这不影响标定★：覆盖桶数的是激励打到的事件，而那个 perf 输出不回灌任何状态。
已实测对照：同一 seed 下「仓库现状」与「打了核补丁的一次性副本」两份日志的
cov 行**逐字节相同**（见 CORE_BLOCKER.md）。

用法:
    python3 calibrate_cov.py <raw.txt>            # 打表 + 打每桶的 min/来源
    python3 calibrate_cov.py <raw.txt> --emit     # 只输出可粘进生成器的 dict 字面量
其中 raw.txt 每行形如
    <变体> <seed> <initreg> cov <桶名> = <值>  (min N)
"""
import collections, re, sys

LINE = re.compile(r'^(\S+)\s+(\S+)\s+(\S+)\s+cov\s+(\w+)\s*=\s*(\d+)')


def load(path):
    per = collections.defaultdict(list)          # 桶名 -> [(值, 变体, seed, initreg)]
    runs = set()
    for ln in open(path):
        m = LINE.match(ln)
        if m:
            mod, seed, ir, nm, val = m.groups()
            per[nm].append((int(val), mod, seed, ir))
            runs.add((mod, seed, ir))
    return per, runs


def main(argv):
    per, runs = load(argv[0])
    mods = sorted({r[0] for r in runs})
    print('# 跑了 %d 次（%d 变体 x seed x initreg），%d 个桶'
          % (len(runs), len(mods), len(per)))
    table = {}
    rows = []
    for nm in sorted(per):
        lo, mod, seed, ir = min(per[nm])
        table[nm] = max(1, lo // 4)
        rows.append((nm, lo, table[nm], len(per[nm]), mod, seed, ir))
    if '--emit' in argv:
        print('COV_MIN_200K = {')
        for nm, lo, v, n, mod, seed, ir in rows:
            print("    '%s': %d,%s# 实测最小 %d @ %s seed=%s initreg=%s（%d 次跑）"
                  % (nm, v, ' ' * max(1, 22 - len(nm) - len(str(v))), lo,
                     mod, seed, ir, n))
        print('}')
        return 0
    print('%-18s%10s%10s%8s   最小值出处' % ('桶', '实测最小', '下限=/4', '跑到次数'))
    for nm, lo, v, n, mod, seed, ir in rows:
        print('%-18s%10d%10d%8d   %s seed=%s initreg=%s' % (nm, lo, v, n, mod, seed, ir))
    thin = [r for r in rows if r[1] < 40]
    if thin:
        print('\n★下面这些桶实测最小值 < 40，/4 之后下限 < 10，分辨力有限，逐个记下来：')
        for nm, lo, v, n, mod, seed, ir in thin:
            print('   %-18s 最小 %d -> 下限 %d   (%s seed=%s initreg=%s)'
                  % (nm, lo, v, mod, seed, ir))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_ut_initreg.py —— 哪些 UT 从来没跑过 +vcs+initreg（棘轮闸）。

## 由来

CONVENTIONS 要求每个 UT 两轮都绿：编译期 `+vcs+initreg+random` 打开机制，
运行期 plusarg 选 `+0` 或 `+random`。两轮都绿也**不等于**复位域正确，但一轮都不跑
等于这条判据完全没执行。

2026-09-17 SbufferData lane 在改 MulUnit 时顺手发现：

    grep initreg verif/ut/MulUnit/Makefile   -> 一处都没有
    git log -S initreg -- verif/ut/MulUnit/  -> 空（不是被删，是**从来没加过**）
    实测命令行: ./simv +ntb_random_seed=1 +ncycles=200000     ← 没有 initreg

顺着查全仓：**147 个 UT 里 68 个的 Makefile 完全没提 initreg**，
而 `scripts/ut_common.mk` 也不全局下发（只从 SIM_ARGS 里**推导** INITREG_TAG）。
也就是说这 68 个目标的 UT 验收，是在「寄存器初值由 VCS 默认决定」的条件下过的。

## 为什么是棘轮而不是硬闸

68 个是存量，一次性补齐要重跑 68 个 UT，而且大概率会**真的跑红**一批
（本轮已有多条 lane 因为打开 initreg 才发现 tb 缺暖机）——那是好事，但不该
在别的工作进行中一次性引爆。所以这里只做两件：
  1. **可见**：把不合规清单和计数打出来；
  2. **不许再涨**：超过基线就非零退出。新写的 UT 必须合规，存量按自己的节奏还。

## 判据

Makefile 里出现 `initreg` 即视为已配置（编译期或运行期任一处）。
这是**静态**判据，不保证真跑了两轮 —— 真正的两轮证据是磁盘上
`sim_<seed>_initreg0.log` 与 `sim_<seed>_initregrandom.log` 并存
（ut_common.mk 的 INITREG_TAG 负责产生），但日志是 gitignore 的、不进版本库，
所以这里只能守住"有没有配"这一层。★这是本闸的已知上限，不要把它读成"两轮都绿"★。

用法:
  python3 scripts/check_ut_initreg.py          # 报告 + 棘轮
  python3 scripts/check_ut_initreg.py --list   # 打印完整不合规清单
  python3 scripts/check_ut_initreg.py --bless  # 把当前计数写成新基线（只许降）
"""
import argparse
import pathlib
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
BASELINE = REPO / 'docs' / 'ut_initreg_baseline.txt'


def scan():
    ok, missing = [], []
    for mk in sorted((REPO / 'verif' / 'ut').glob('*/Makefile')):
        name = mk.parent.name
        txt = mk.read_text(encoding='utf-8', errors='replace')
        (ok if 'initreg' in txt else missing).append(name)
    return ok, missing


def read_baseline():
    if not BASELINE.exists():
        return None
    for line in BASELINE.read_text(encoding='utf-8').splitlines():
        line = line.strip()
        if line and not line.startswith('#'):
            return int(line)
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--list', action='store_true')
    ap.add_argument('--bless', action='store_true')
    a = ap.parse_args()

    ok, missing = scan()
    total = len(ok) + len(missing)
    n = len(missing)

    if a.list:
        for m in missing:
            print(m)

    if a.bless:
        base = read_baseline()
        if base is not None and n > base:
            print('check_ut_initreg: 拒绝 bless —— 当前 %d 比基线 %d 还多，棘轮只许降'
                  % (n, base), file=sys.stderr)
            return 1
        BASELINE.write_text(
            '# 未配置 +vcs+initreg 的 UT 数量基线（棘轮：只许降，不许升）\n'
            '# 复算: python3 scripts/check_ut_initreg.py\n'
            '%d\n' % n, encoding='utf-8')
        print('check_ut_initreg: 基线写为 %d' % n)
        return 0

    base = read_baseline()
    print('check_ut_initreg: %d/%d 个 UT 未配置 initreg（基线 %s）'
          % (n, total, base if base is not None else '未设'))
    if base is None:
        print('  提示: 先跑一次 --bless 记下基线', file=sys.stderr)
        return 0
    if n > base:
        print('check_ut_initreg: ★不过★ 未配置数从 %d 涨到 %d —— '
              '新写的 UT 必须配 initreg（存量可以慢慢还，但不许再欠）' % (base, n),
              file=sys.stderr)
        newly = [m for m in missing]
        print('  当前不合规清单（--list 可单独打印）: %s%s'
              % (' '.join(newly[:10]), ' …' if len(newly) > 10 else ''), file=sys.stderr)
        return 1
    if n < base:
        print('  比基线少 %d 个 —— 记得跑 --bless 把棘轮收紧' % (base - n))
    return 0


if __name__ == '__main__':
    sys.exit(main())

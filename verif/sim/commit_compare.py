#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""commit_compare.py —— golden vs impl 逐拍提交 trace 对拍（判据预登记在 docs/lanes/fullchip-bench.md）。

两件事**分开报**，互不替代：
  A. difftest 架构正确性（每侧独立）：sim.log 里 `Difftest enabled` 出现、HIT GOOD TRAP、
     无 `different at pc|Mismatch|DIFFTEST FAILED|ABORT|HIT BAD TRAP`、无 EXCEEDED MAX CYCLE。
  B. 重写 vs golden 逐拍一致：两侧 commit.trace（run_fcb.sh 的 FCB_COMMIT_TRACE）去掉 `#` 头后
     **逐行逐字节**相等；每行即一个观测事件：
       C <cycle> <slot> pc inst rvc rfwen fpwen vecwen v0wen wdest wdata skip fused special rob lq sq ld st
       E <cycle> irq exc epc einst nmi        （DUT 报的中断/异常事件）
       T <cycle> instrCnt code pc            （trap 事件）
     外加 sim.log 里 trap pc / instrCnt / cycleCnt 两侧相等。
     不做任何字段剔除、不做容差；第一处不等即判 MISMATCH 并打印两侧该行与前 5 行上下文。

用法: commit_compare.py <golden_rundir> <impl_rundir>
退出码: 0 = A 两侧 PASS 且 B MATCH；1 = 否则。
"""
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import bench_verdict as bv  # noqa: E402


def trace(p):
    with open(p, errors='replace') as f:
        for n, l in enumerate(f, 1):
            if not l.startswith('#'):
                yield n, l.rstrip('\n')


def difftest_verdict(side, rundir):
    lines = bv.norm(rundir / 'sim.log')
    f = bv.facts(lines)
    ok = bool(f['difftest_on'] and f['mismatches'] == 0 and f['trap']
              and f['trap'].startswith('HIT GOOD') and not f['maxcycle'])
    print(f'[A] difftest {side:6s}: {"PASS" if ok else "FAIL"}  trap={f["trap"]!r} '
          f'counts={f["counts"]!r} done={f["done"]!r} maxcycle={f["maxcycle"]!r} '
          f'difftest_on={f["difftest_on"]} mismatch_lines={f["mismatches"]}')
    return ok, f


def main():
    g, i = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    okg, fg = difftest_verdict('golden', g)
    oki, fi = difftest_verdict('impl', i)
    end_same = all(fg[k] == fi[k] for k in ('trap', 'counts', 'done', 'maxcycle'))
    print(f'[B] 终点 trap/instrCnt/cycleCnt/done 两侧相等: {end_same}')
    gt, it = g / 'commit.trace', i / 'commit.trace'
    if not (gt.exists() and it.exists()):
        print(f'[B] 逐拍对拍: NO_TRACE (golden {gt.exists()} impl {it.exists()})')
        return 1
    hist = []
    n = nc = 0
    gi, ii = trace(gt), trace(it)
    while True:
        a, b = next(gi, None), next(ii, None)
        if a is None and b is None:
            break
        if a is None or b is None or a[1] != b[1]:
            print(f'[B] 逐拍对拍: MISMATCH at event #{n + 1}')
            for h in hist[-5:]:
                print(f'      ctx  {h}')
            print(f'      golden L{a[0] if a else "-"}: {a[1] if a else "<EOF>"}')
            print(f'      impl   L{b[0] if b else "-"}: {b[1] if b else "<EOF>"}')
            if a and b:
                fa, fb = a[1].split(), b[1].split()
                diff = [f'{x}|{y}' for x, y in zip(fa, fb) if x != y]
                print(f'      differing fields (golden|impl): {diff}')
            return 1
        n += 1
        nc += a[1].startswith('C ')
        hist.append(a[1])
        if len(hist) > 5:
            hist.pop(0)
    last = hist[-1] if hist else ''
    print(f'[B] 逐拍对拍: MATCH  events={n} commits={nc} last={last!r}')
    ok = okg and oki and end_same
    print(f'VERDICT: A(golden)={"PASS" if okg else "FAIL"} A(impl)={"PASS" if oki else "FAIL"} '
          f'B={"MATCH" if end_same else "END_MISMATCH"}')
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())

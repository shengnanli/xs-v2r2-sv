#!/usr/bin/env python3
"""覆盖闸的双向负测 —— 证明「闸看得见激励塌陷」。

## 为什么必须有

CONVENTIONS「判据也必须先自证『它看得见改变』」（2026-09-20，TlbStorageWrapper 实测）：
变异体要先证明自己改了电路，**判据也要先证明自己看得见改变**，两边各塌一次就能
凑出一个完全错误的结论。覆盖桶尤其容易塌成摆设：

* 只判 `!= 0`：激励退化成「几乎打不到」时计数掉到个位数，仍然非零，闸照样绿。
* 设了下限却没验过：下限要是设得比任何退化都松，它等于没设。

所以本文件做**两个方向**：

| 方向 | 怎么做 | 期望 |
|---|---|---|
| 正向 | 正常跑 | `TEST PASSED`，每个桶 ≥ MINCOV |
| ★反向★ | `+nopool`（psrc/pdest 小池换成整个 psrc 空间，唤醒几乎打不中） | 必须 `COVERAGE HOLE` + `TEST FAILED` |

反向那一轮**电路一个字都没改**，改的只是激励 —— 它证明的正是
「闸对激励塌陷有分辨力」，与变异体证明「自己改了电路」互为对偶。

用法:
    python3 check_cov_gate.py <变体名> [--cycles N]
退出码 0 = 两个方向都如期。
"""
import argparse, pathlib, re, subprocess, sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]


def run_sim(utdir, args):
    subprocess.run(['make', 'simv'], cwd=str(utdir), stdout=subprocess.PIPE,
                   stderr=subprocess.STDOUT, check=True)
    r = subprocess.run(['./simv'] + args, cwd=str(utdir), stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT, universal_newlines=True)
    return r.stdout


def buckets(out):
    return {m[0]: int(m[1]) for m in
            re.findall(r'cov (\S+)\s+= (\d+)', out)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('variant')
    ap.add_argument('--cycles', type=int, default=200000)
    a = ap.parse_args()
    ut = REPO / 'verif' / 'ut' / a.variant
    common = [f'+ncycles={a.cycles}', '+ntb_random_seed=1', '+vcs+initreg+random']

    print(f'[{a.variant}] 正向：正常激励')
    pos = run_sim(ut, common)
    ok_pos = 'TEST PASSED' in pos and 'COVERAGE HOLE' not in pos
    bp = buckets(pos)
    print(f'  TEST PASSED={"TEST PASSED" in pos}  桶 {len(bp)} 个，最小 '
          f'{min(bp.values()) if bp else "-"}')

    print(f'[{a.variant}] ★反向★：+nopool（激励退化，电路没改）')
    neg = run_sim(ut, common + ['+nopool'])
    holes = re.findall(r'COVERAGE HOLE: (\S+)', neg)
    ok_neg = bool(holes) and 'TEST FAILED' in neg
    bn = buckets(neg)
    print(f'  COVERAGE HOLE {len(holes)} 个: {holes[:6]}')
    print(f'  TEST FAILED={"TEST FAILED" in neg}')
    for k in sorted(set(bp) & set(bn)):
        if bn[k] < bp[k]:
            print(f'    {k:<20} {bp[k]:>8} -> {bn[k]:>8}')

    rc = 0 if (ok_pos and ok_neg) else 1
    print('结论:', '★覆盖闸双向都成立：正常跑绿，激励塌陷时红★' if rc == 0
          else f'★负测没达成（正向 ok={ok_pos} 反向 ok={ok_neg}）—— 闸可能是摆设★')
    return rc


if __name__ == '__main__':
    sys.exit(main())

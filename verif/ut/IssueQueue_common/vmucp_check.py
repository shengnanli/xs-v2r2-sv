#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""vmucp_check.py —— IssueQueue<V> 申请 vmucp 前的配对核查（standing rule 第 1/2 条的机械部分）

读一次**未开 vmucp** 的 FM 跑出来的 unread_points.txt，逐条核：
  * 未配对的未读点（ref / impl 行）必须为 0；
  * 每一对 matched_nc 都必须**恰好**是 fm_pins_pre.tcl 里的一条钉点（按两侧完整路径比），
    即配对全部来自机械生成的钉点、FM 自行猜配 0 对；
  * 钉点不重复（一一对应）。
全过才打印 OK 与未读点数 N（即开 vmucp 后 passing 应当恰好 +N）。

用法: python3 vmucp_check.py <V> <unread_points.txt>
"""
import pathlib
import re
import sys

UT = pathlib.Path(__file__).resolve().parent.parent


def pins(v):
    t = (UT / v / 'fm_pins_pre.tcl').read_text()
    blocks = re.findall(r'foreach _pair \{\n(.*?)\n  \} \{\n    lassign \$_pair _r _i\n    if \{\[set_user_match "(.*?)" "(.*?)"\]\}',
                        t, re.S)
    out = set()
    for body, rt, it in blocks:
        for r, i in re.findall(r'\{(\S+) (\S+)\}', body):
            rp = rt.replace('$top', v).replace('$_r', r)
            ip = it.replace('$top', v).replace('$_i', i)
            if (rp, ip) in out:
                raise SystemExit(f'重复钉点 {rp} {ip}')
            out.add((rp, ip))
    return out, None


def main():
    v, uf = sys.argv[1], sys.argv[2]
    P, _ = pins(v)
    n = bad = unm = 0
    for l in pathlib.Path(uf).read_text().splitlines():
        kind, rest = l.split('\t', 1)
        if kind != 'matched_nc':
            unm += 1
            print('未配对未读点:', l)
            continue
        toks = re.findall(r'\{([^{}]*)\}|(\S+)', rest)
        if len(toks) != 2:
            raise SystemExit(f'行格式异常: {l!r}')
        r, i = [a or b for a, b in toks]
        n += 1
        if (r, i) not in P:
            bad += 1
            if bad <= 10:
                print('不在钉点表里的配对:', r, i)
    print(f'{v}: matched_nc={n} 不在钉点表={bad} 未配对={unm} 钉点总数={len(P)}')
    if bad or unm:
        print('FAIL')
        return 1
    print(f'OK: 开 vmucp 后 passing 应当恰好 +{n}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

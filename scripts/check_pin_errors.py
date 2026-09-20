#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_pin_errors.py —— 从 fm.log 里判「钉点到底有没有失败」，且**不把投机性试名误判成失败**。

## 为什么光靠计数不够

`set_user_match` **从不抛异常**（2026-09-20 真 fm_shell 实测：名字存在返回 1，
不存在返回 0 并往日志写 `Error: Unknown name: ... (FM-036)`）。钉点文件里用返回值
计数 + `error` 中止已经能 fail-closed，但那只管**本文件自己**。日志里还可能有
别处来的 `Error:`，而"计数对了"并不等于"没报错"。

## 为什么不能一刀切「fm.log 里 Error: 行数必须为 0」

全仓 evidence 扫过：多数 `FM-036` 出自 `match_packed_payload` 这类**投机性辅助** ——
它试一批**可能**的名字，试不中是常态。134 个带 FM-036 的目录里，判了 SUCCEEDED
又有 unread/unmatched 残留的是 **0 个**。把这些也判红，等于把一批真绿目标打成红。

## 判据：按**区间**归因，不按全局计数

钉点文件在开头/结尾各打一个标记：

    OE_PIN_BEGIN <top> expect=<N>
    ... 这中间的 set_user_match 都是本文件发出的 ...
    OE_PIN_END <top> n=<n> miss=<miss> expect=<N>

于是：
* **区间内**的 `Error:` 行 = 本文件钉点失败 → **红**
* **区间外**的 `Error:` 行 = 别处来的（投机性试名等）→ 只报数，不判红
* 声明了要钉点却**找不到标记对** → 无法归因 → **红**（fail-closed，不是"没找到就算过"）
* `OE_PIN_END` 里 `miss != 0` 或 `n != expect` → **红**（与钉点文件自己的 error 互为双保险）

标记名可换（`--marker`），别的钉点文件照这个形状加标记就能共用这道判据。

## 用法

    python3 scripts/check_pin_errors.py <fm.log> [--require-pins]
    python3 scripts/check_pin_errors.py --selftest
"""
import argparse, pathlib, re, sys

ERR_RE = re.compile(r'^\s*Error:', re.M)


def analyze(log, marker='OE_PIN'):
    """返回 dict：区间内错误、区间外错误、标记对、计数是否自洽。"""
    lines = log.split('\n')
    beg = re.compile(rf'^{marker}_BEGIN\s+(\S+)\s+expect=(\d+)')
    end = re.compile(rf'^{marker}_END\s+(\S+)\s+n=(\d+)\s+miss=(\d+)\s+expect=(\d+)')
    windows, cur = [], None
    inside, outside = [], []
    pairs = []
    for i, l in enumerate(lines):
        mb = beg.match(l)
        me = end.match(l)
        if mb:
            cur = dict(top=mb.group(1), expect=int(mb.group(2)), start=i, errs=[])
        elif me and cur is not None:
            cur.update(end=i, n=int(me.group(2)), miss=int(me.group(3)),
                       expect_end=int(me.group(4)))
            windows.append(cur)
            pairs.append(cur['top'])
            cur = None
        elif ERR_RE.match(l):
            (cur['errs'] if cur is not None else outside).append(l.strip())
    if cur is not None:                 # 开了没关 —— 中途 error 中止了
        cur.update(end=None, n=None, miss=None, expect_end=None)
        windows.append(cur)
    for w in windows:
        inside.extend(w['errs'])
    return dict(windows=windows, inside=inside, outside=outside, pairs=pairs)


def judge(res, require_pins):
    probs = []
    if require_pins and not res['windows']:
        probs.append('声明了要钉点，但日志里找不到 PIN_BEGIN/END 标记 —— 无法归因')
    for w in res['windows']:
        if w.get('end') is None:
            probs.append(f'{w["top"]}: 有 BEGIN 没有 END —— 钉点中途中止了')
            continue
        if w['errs']:
            probs.append(f'{w["top"]}: 区间内有 {len(w["errs"])} 条 Error —— 真钉点失败')
        if w['miss'] != 0:
            probs.append(f'{w["top"]}: miss={w["miss"]} != 0')
        if w['n'] != w['expect_end']:
            probs.append(f'{w["top"]}: n={w["n"]} != expect={w["expect_end"]}')
    return probs


SPEC_LOG = """Loading...
Error: Unknown name: 'r:/WORK/Foo/payload_guess_0' (FM-036)
Error: Unknown name: 'r:/WORK/Foo/payload_guess_1' (FM-036)
match_packed_payload: 0 / 2 matched
OE_PIN_BEGIN Foo expect=3
OE_PIN_END Foo n=3 miss=0 expect=3
Verification SUCCEEDED
"""

REAL_FAIL_LOG = """Loading...
OE_PIN_BEGIN Foo expect=3
Error: Unknown name: 'r:/WORK/Foo/typo_reg' (FM-036)
OE_PIN_FAIL: typo_reg <-> r_typo
OE_PIN_END Foo n=2 miss=1 expect=3
"""

NO_MARKER_LOG = """Loading...
Error: Unknown name: 'r:/WORK/Foo/whatever' (FM-036)
Verification SUCCEEDED
"""

ABORT_LOG = """Loading...
OE_PIN_BEGIN Foo expect=3
Error: Unknown name: 'r:/WORK/Foo/typo_reg' (FM-036)
"""


def selftest():
    cases = [
        ('★反例方向 1：投机性试名（区间外 FM-036）+ 钉点全中 -> 必须绿★',
         SPEC_LOG, True, 0),
        ('★正例方向：真钉点失败（区间内 Error + miss!=0）-> 必须红★',
         REAL_FAIL_LOG, True, 1),
        ('声明要钉点但日志没标记 -> 红（无法归因，不许当过）',
         NO_MARKER_LOG, True, 1),
        ('没声明要钉点、日志只有投机性 FM-036 -> 绿',
         NO_MARKER_LOG, False, 0),
        ('BEGIN 有、END 没有（中途 error 中止）-> 红',
         ABORT_LOG, True, 1),
    ]
    rc = 0
    print('check_pin_errors --selftest:')
    for name, log, req, want in cases:
        res = analyze(log)
        probs = judge(res, req)
        got = 1 if probs else 0
        ok = got == want
        extra = ''
        if name.startswith('★反例方向 1'):
            extra = f'（区间外 Error {len(res["outside"])} 条，只报数不判红）'
        print(f'  [{"OK" if ok else "FAIL"}] {name} -> {"红" if got else "绿"}{extra}')
        if probs and not ok:
            for p in probs:
                print(f'        {p}')
        rc |= 0 if ok else 1
    print('负测', 'PASS' if rc == 0 else 'FAIL')
    return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('log', nargs='?')
    ap.add_argument('--marker', default='OE_PIN')
    ap.add_argument('--require-pins', action='store_true')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    res = analyze(pathlib.Path(a.log).read_text(errors='replace'), a.marker)
    probs = judge(res, a.require_pins)
    print(f'钉点区间 {len(res["windows"])} 个：'
          + ', '.join(f'{w["top"]}(n={w.get("n")},miss={w.get("miss")})'
                      for w in res['windows']))
    print(f'区间内 Error {len(res["inside"])} 条（= 真钉点失败）')
    print(f'区间外 Error {len(res["outside"])} 条（投机性试名等，不判红）')
    for p in probs:
        print('  FAIL ' + p)
    print('结论:', '钉点无失败' if not probs else '★钉点有失败★')
    return 1 if probs else 0


if __name__ == '__main__':
    sys.exit(main())

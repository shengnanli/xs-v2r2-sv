#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_pin_errors.py -- fm.log 里 FM-036 的**按区间归因**，钉点的第二条独立判据。

为什么需要第二条判据
--------------------
第一条判据（钉点文件自己的 `pinned N of M` + fail-closed 中止）用的是
`set_user_match` 的**返回值**。它是对的，但它的输入是钉点文件自己算出来的 ——
钉点文件写错、少钉、或者自己的计数守卫是空的，第一条判据就一起错。
本脚本改用**工具的输出**：`set_user_match` 钉不上一个名字时**不抛异常**，
而是往 fm.log 写一行

    Error: Unknown name: 'r:/WORK/<top>/<path>' (FM-036)

这是一条完全独立于钉点文件的证据链（docs/rob_pin_failclosed.tsv 的 F 行实测：
3 个坏 pin / 4 个坏名字 -> 正好 4 行行首 `Error:`）。

★为什么不能 `grep -c FM-036` 了事★
--------------------------------
实测反例（evidence/25cdce831a66/SyncDataModuleTemplate__64entry_3/fm.log）：
该 log 有 **2304** 行 FM-036，钉点文件却如实报 `pinned=5760 miss=0` —— 两者都没错。
因为那个钉点文件是**投机性试名**：一个比较点准备了多个候选名字，逐个试，
第一个成功就 break，失败的候选各留一行 FM-036。那 2304 行是**设计如此**。
而 Rob 的钉点文件是 1 个比较点 1 次 set_user_match，没有候选、没有 break ——
它区间里的**任何一行 FM-036 都是真钉点失败**。

所以判据必须先归因再计数。归因靠 fm.log 里 **fm_shell 对 fm_eq.tcl 源码行的回显**：
Tcl 先回显整条命令再执行它，所以

    ...
    <回显> if {$SIDECAR_ON} { sidecar_pin_source $env(FM_PIN_TCL) } else { ... }
    <执行产生的 FM-036 行……>            <- 这些就是钉点文件的
    <回显> report_unmatched_points > fm_work/$top/unmatched.rpt

两条回显之间就是钉点文件的区间。钉点文件本身走 sidecar 的 safe interp
（`interp eval`，**不回显**），所以区间内不会混进它自己的源码行。

★fail-closed★
-------------
找不到区间锚点 = 「结果不存在」，**不是 0 个错误**。本脚本此时判红（rc=2），
绝不返回绿。同理：钉点文件的自报行缺失、或自报 pinned != want，一律判红。

用法
  python3 scripts/check_pin_errors.py --log verif/ut/Rob/fm_work/Rob/fm.log \
          --pins verif/ut/Rob/fm_pins.tcl --top Rob
  python3 scripts/check_pin_errors.py --selftest     # 正负测，不需要 fm.log

退出码：0 = 区间干净；1 = 区间里有真钉点失败 / 自报不一致；2 = 判据无法成立（fail-closed）
"""
from __future__ import print_function

import argparse
import os
import re
import sys

# ★行首锚定，且只认 set_user_match 真正的失败消息形状★
# 坑（集成者 0920 转来的实测）：fm_shell 会把入口 Tcl **逐行回显，注释也回显**，
# 而 scripts/fm_eq.tcl:437-441 那段注释本身就在讲这个坑、里面就写着 `FM-036`。
# 所以 `grep -c "FM-036" fm.log` 恒 >= 1，「FM-036 行数必须为 0」那条判据
# 不是"没抓住"，是**必然响**。本正则行首锚定（容前导空白）+ 认全消息形状，
# 回显进来的注释行一律不计。自测 M11 就是这条。
FM036 = re.compile(r"^\s*Error: Unknown name:\s*'([^']*)'\s*\(FM-036\)")

# fm_eq.tcl 回显出来的区间锚点。★只认代码行，不认注释行★：
# 注释里也写着 FM_PIN_TCL，但不含 `sidecar_pin_source $env(...)` 这段字面量。
A_PRE_PIN = "sidecar_pin_source $env(FM_PIN_PRE_TCL)"
A_PACKED = "match_packed_payload $top"
A_POST_PIN = "sidecar_pin_source $env(FM_PIN_TCL)"
A_END = "report_unmatched_points > fm_work/$top/unmatched.rpt"

# 钉点文件自报行：`<前缀> pinned <n> of <m>`（Rob 用 `ROB_PINS pinned N of M`）
SELF_REPORT = re.compile(r"\bpinned[ =](\d+)\s+(?:of|miss=)\s*(\d+)")
SELF_REPORT2 = re.compile(r"\bpinned=(\d+)\s+miss=(\d+)")


def _find(lines, needle, start=0):
    for i in range(start, len(lines)):
        if needle in lines[i]:
            return i
    return -1


def regions(lines):
    """把 fm.log 切成命名区间。返回 (dict name->(lo,hi), problems)。

    lo/hi 是**行下标**，半开区间 [lo, hi)。找不到的锚点不进 dict。
    """
    out = {}
    probs = []
    i_pre = _find(lines, A_PRE_PIN)
    i_packed = _find(lines, A_PACKED, max(i_pre, 0))
    # `match_packed_payload $top` 在 proc 定义体里**不会**出现（定义体是
    # `proc match_packed_payload { top } {`），所以这里找到的就是调用点的回显。
    i_post = _find(lines, A_POST_PIN)
    i_end = _find(lines, A_END, max(i_post, 0))

    if i_pre >= 0 and i_packed > i_pre:
        out['pre_pin'] = (i_pre + 1, i_packed)
    if i_packed >= 0 and i_post > i_packed:
        out['packed_and_automatch'] = (i_packed + 1, i_post)
    if i_post >= 0 and i_end > i_post:
        out['post_pin'] = (i_post + 1, i_end)

    if i_post < 0:
        probs.append("找不到区间起点锚点 %r —— fm_eq.tcl 没走到钉点那一步，"
                     "或 FM_PIN_TCL 根本没被设上。判据不成立。" % A_POST_PIN)
    elif i_end < 0:
        probs.append("找到了钉点起点，却找不到终点锚点 %r —— 跑挂在钉点区间里了"
                     "（钉点文件 error/exit 就是这个形状）。判据不成立。" % A_END)
    return out, probs


def count_errors(lines, span):
    lo, hi = span
    hits = []
    for i in range(lo, hi):
        m = FM036.match(lines[i])
        if m:
            hits.append((i + 1, m.group(1)))
    return hits


def classify_pins_file(path):
    """静态判定钉点文件是不是**投机性试名**。

    投机的形状：一个计数点配多个候选 set_user_match（典型是 foreach 候选 + break）。
    非投机的形状：set_user_match 的出现次数 == 计数自增的出现次数。

    返回 (speculative: bool, detail: str)。读不到文件 -> 抛 IOError（由调用者判红）。
    """
    with open(path) as f:
        src = f.read()
    code = '\n'.join(l for l in src.split('\n')
                     if not l.lstrip().startswith('#'))
    n_sum = len(re.findall(r'\bset_user_match\b', code))
    n_want = len(re.findall(r'\bincr\s+_?want\b', code))
    # 「候选循环」的形状：一次 set_user_match 成功就 break 出候选列表。
    # ★break 可能与 set_user_match 同行★（`if {[set_user_match ...]} {incr n; break}`），
    # 早先只查「下一行有 break」的写法漏掉了这个最常见的形态 —— 自测 M10 抓到的。
    clines = code.split('\n')
    has_break = False
    for k, l in enumerate(clines):
        if 'set_user_match' not in l:
            continue
        for l2 in clines[k:k + 4]:
            if re.search(r'\bbreak\b', l2):
                has_break = True
                break
        if has_break:
            break
    if n_sum == 0:
        return None, "文件里没有 set_user_match —— 这不是一个钉点文件"
    if has_break or (n_want and n_sum > n_want):
        return True, ("投机性试名：set_user_match 出现 %d 次 / 计数自增 %d 次%s"
                      % (n_sum, n_want, "，且有 break" if has_break else ""))
    return False, ("非投机：set_user_match 出现 %d 次 == 计数自增 %d 次，无候选 break"
                   % (n_sum, n_want))


def self_report(lines, span):
    """在钉点区间里找钉点文件的自报行。返回 (pinned, want) 或 None。"""
    lo, hi = span
    for i in range(hi - 1, lo - 1, -1):
        m = SELF_REPORT2.search(lines[i])
        if m:
            return int(m.group(1)), int(m.group(1)) + int(m.group(2))
        m = SELF_REPORT.search(lines[i])
        if m:
            return int(m.group(1)), int(m.group(2))
    return None


def run(log_path, pins_path, top, expect=None, out=sys.stdout, region='post_pin'):
    if not os.path.exists(log_path):
        print("PIN_ERRORS: fm.log 不存在: %s —— 判据不成立" % log_path, file=out)
        return 2
    with open(log_path, errors='replace') as f:
        lines = f.read().split('\n')

    try:
        spec, detail = classify_pins_file(pins_path)
    except IOError as e:
        print("PIN_ERRORS: 读不到钉点文件 %s (%s) —— 判据不成立" % (pins_path, e),
              file=out)
        return 2
    if spec is None:
        print("PIN_ERRORS: %s" % detail, file=out)
        return 2
    print("钉点文件形态: %s" % detail, file=out)

    regs, probs = regions(lines)
    total = len([1 for l in lines if FM036.match(l)])
    print("fm.log 行数 %d，行首 FM-036 总数 %d（★总数不是判据★）"
          % (len(lines), total), file=out)
    for p in probs:
        print("PIN_ERRORS_FAILCLOSED: %s" % p, file=out)
    if probs:
        return 2

    rc = 0
    for name in ('pre_pin', 'packed_and_automatch', 'post_pin'):
        if name not in regs:
            continue
        hits = count_errors(lines, regs[name])
        lo, hi = regs[name]
        kind = "投机性试名区（fm_eq.tcl 自带候选循环，期望内）" \
            if name == 'packed_and_automatch' else "钉点文件区"
        if name == region:
            kind += "  <- --pins 指的就是它"
        print("  区间 %-22s 行 %6d..%-6d  FM-036 %6d   %s"
              % (name, lo + 1, hi, len(hits), kind), file=out)
        if name == region and not spec and hits:
            rc = 1
            print("  ★真钉点失败★ 本钉点文件非投机 ⇒ 区间内每一行都是钉不上的名字："
                  , file=out)
            for ln, path in hits[:20]:
                print("      fm.log:%d  %s" % (ln, path), file=out)
            if len(hits) > 20:
                print("      ...（共 %d 行）" % len(hits), file=out)

    if region not in regs:
        print("PIN_ERRORS_FAILCLOSED: 钉点区间 %s 为空 —— 判据不成立" % region,
              file=out)
        return 2

    sr = self_report(lines, regs[region])
    if sr is None:
        print("PIN_ERRORS_FAILCLOSED: 钉点区间里没有自报行"
              "（`pinned N of M`）—— 钉点文件没跑完或没自报，判据不成立", file=out)
        return 2
    pinned, want = sr
    print("  钉点文件自报: pinned %d of %d" % (pinned, want), file=out)
    if pinned != want:
        print("PIN_ERRORS_FAIL: 自报 pinned != want（%d != %d）" % (pinned, want),
              file=out)
        rc = 1
    if expect is not None and want != expect:
        print("PIN_ERRORS_FAIL: 自报 want=%d，与 --expect %d 不符" % (want, expect),
              file=out)
        rc = 1
    print("PIN_ERRORS_RC=%d" % rc, file=out)
    return rc


# ---------------------------------------------------------------------------
# 自测：★本仓规矩 —— 「我加了一道更严的判据」本身也要先证明它会响★
# 每条负测都先证明干净样本是绿的，再种一处病，要求变红（且是**预期的那种红**）。
# ---------------------------------------------------------------------------
_CLEAN_PINS = """\
set _pinned 0
set _want 0
for {set i 0} {$i < 3} {incr i} {
  incr _want
  if {[set_user_match r:/WORK/T/a_${i}_reg i:/WORK/T/u_core/a_reg\\[$i\\]]} {incr _pinned}
}
puts "T_PINS pinned $_pinned of $_want"
if {$_pinned != $_want} { exit 3 }
if {$_want != 3} { exit 3 }
"""

_SPEC_PINS = """\
set _pinned 0
set _want 0
foreach r {a b} {
  incr _want
  foreach cand [list r:/WORK/T/${r}_0_reg r:/WORK/T/${r}_reg] {
    if {[set_user_match $cand i:/WORK/T/u_core/${r}_reg]} {incr _pinned; break}
  }
}
puts "T_PINS pinned $_pinned of $_want"
if {$_pinned != $_want} { exit 3 }
"""


def _log(pre_errs=0, packed_errs=0, post_errs=0, report="T_PINS pinned 3 of 3",
         with_post_anchor=True, with_end_anchor=True):
    L = ["Status:   Elaborating design T   ...  ",
         "    if {$SIDECAR_ON} { sidecar_pin_source $env(FM_PIN_PRE_TCL) } else"
         " { source $env(FM_PIN_PRE_TCL) }"]
    L += ["Error: Unknown name: 'r:/WORK/T/pre_%d' (FM-036)" % i
          for i in range(pre_errs)]
    L.append("match_packed_payload $top")
    L += ["Error: Unknown name: 'r:/WORK/T/pk_%d' (FM-036)" % i
          for i in range(packed_errs)]
    L.append("            puts \"AUTO_MATCH: $rpath <-> $ipath\"")
    if with_post_anchor:
        L.append("    if {$SIDECAR_ON} { sidecar_pin_source $env(FM_PIN_TCL) }"
                 " else { source $env(FM_PIN_TCL) }")
    L += ["Error: Unknown name: 'r:/WORK/T/post_%d' (FM-036)" % i
          for i in range(post_errs)]
    if report:
        L.append(report)
    if with_end_anchor:
        L.append("report_unmatched_points > fm_work/$top/unmatched.rpt")
    L.append("Verification SUCCEEDED")
    return '\n'.join(L) + '\n'


def selftest():
    import io
    import tempfile
    d = tempfile.mkdtemp(prefix='chkpin_')
    clean = os.path.join(d, 'clean.tcl')
    spec = os.path.join(d, 'spec.tcl')
    open(clean, 'w').write(_CLEAN_PINS)
    open(spec, 'w').write(_SPEC_PINS)

    cases = [
        # (名字, 日志, 钉点文件, 期望 rc, 期望输出里出现的字样)
        ('M0  干净样本必须绿', _log(), clean, 0, 'PIN_ERRORS_RC=0'),
        ('M0b 投机区间有错也必须绿（那是期望内的）',
         _log(packed_errs=99), clean, 0, 'PIN_ERRORS_RC=0'),
        ('M1  ★钉点区间里有 FM-036 必须红★',
         _log(post_errs=4), clean, 1, '真钉点失败'),
        ('M2  锚点缺失必须 fail-closed（不是 0 个错误）',
         _log(with_post_anchor=False), clean, 2, 'PIN_ERRORS_FAILCLOSED'),
        ('M3  终点锚点缺失（跑挂在区间里）必须 fail-closed',
         _log(with_end_anchor=False), clean, 2, 'PIN_ERRORS_FAILCLOSED'),
        ('M4  自报行缺失必须 fail-closed',
         _log(report=''), clean, 2, 'PIN_ERRORS_FAILCLOSED'),
        ('M5  自报 pinned<want 必须红',
         _log(report='T_PINS pinned 2 of 3'), clean, 1, 'PIN_ERRORS_FAIL'),
        ('M6  ★投机文件：区间里有错但自报全钉上 -> 绿（不许误报）★',
         _log(post_errs=7, report='T_PINS pinned 2 of 2'), spec, 0,
         'PIN_ERRORS_RC=0'),
        ('M7  投机文件自报有 miss 仍必须红',
         _log(post_errs=7, report='T_PINS pinned 1 of 2'), spec, 1,
         'PIN_ERRORS_FAIL'),
        ('M8  钉点文件不存在必须 fail-closed',
         _log(), os.path.join(d, 'nope.tcl'), 2, '判据不成立'),
        ('M9  fm.log 不存在必须 fail-closed',
         None, clean, 2, '判据不成立'),
        # ★M11：fm_shell 回显的**注释行**里写着 FM-036，不许被算成错误★
        ('M11 回显的 Tcl 注释里提到 FM-036，不许计数',
         _log().replace('Verification SUCCEEDED',
                        '    #   `grep -c "FM-036" fm.log` 就永远 >= 1\n'
                        '    #   Error: Unknown name (FM-036) <- 这也是注释\n'
                        'Verification SUCCEEDED'),
         clean, 0, 'PIN_ERRORS_RC=0'),
    ]
    ok = True
    for name, logtext, pins, want_rc, want_txt in cases:
        if logtext is None:
            lp = os.path.join(d, 'absent.log')
        else:
            lp = os.path.join(d, 'x.log')
            open(lp, 'w').write(logtext)
        buf = io.StringIO()
        rc = run(lp, pins, 'T', out=buf)
        txt = buf.getvalue()
        good = (rc == want_rc) and (want_txt in txt)
        ok &= good
        print('  %-4s %-58s rc=%d (期望 %d)' %
              ('ok' if good else 'FAIL', name, rc, want_rc))
        if not good:
            print('    ---- 实际输出 ----')
            for l in txt.split('\n'):
                print('    ' + l)

    # M10: 形态分类器本身的正负测（它是上面所有判据的输入，必须自己也被证）
    s1, _ = classify_pins_file(clean)
    s2, _ = classify_pins_file(spec)
    g = (s1 is False and s2 is True)
    ok &= g
    print('  %-4s %-58s' % ('ok' if g else 'FAIL',
                            'M10 形态分类器：干净=非投机 / 候选+break=投机'))
    print('SELFTEST %s' % ('OK' if ok else 'FAILED'))
    return 0 if ok else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--log')
    ap.add_argument('--pins')
    ap.add_argument('--top')
    ap.add_argument('--expect', type=int,
                    help='期望的钉点总数（自报 want 必须等于它）')
    ap.add_argument('--region', default='post_pin',
                    choices=['post_pin', 'pre_pin'],
                    help='--pins 那个文件被 fm_eq.tcl 从哪个入口 source 进来：'
                         'FM_PIN_TCL(post_pin，默认) 还是 FM_PIN_PRE_TCL(pre_pin)')
    ap.add_argument('--selftest', action='store_true')
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if not (a.log and a.pins):
        ap.error('--log 与 --pins 必填（或用 --selftest）')
    return run(a.log, a.pins, a.top or '?', a.expect, region=a.region)


if __name__ == '__main__':
    sys.exit(main())

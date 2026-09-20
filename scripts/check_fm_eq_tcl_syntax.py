#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_fm_eq_tcl_syntax.py —— 用真 tclsh 解析 fm_eq.tcl 里的 switch 块。

## 为什么要有这道闸（2026-09-20，Entries lane 踩到）

`ee3aa24` 往 `fm_eq.tcl` 里加了一段 merge_dup 的经验注记，**加在了
`switch -- $_mergedup {` 的花括号里面**。Tcl 的 switch 体是一张
**pattern/body 列表**，不是脚本体 —— `#` 在那里不是注释，整块要按列表语法解析。
那段注记里有 ASCII 双引号 `"Merging duplicated registers"` 紧跟中文逗号，于是：

    list element in quotes followed by "，★从未到达" instead of space   (CMD-013)

★后果不是"注记没生效"，是 **本仓每一次 FM 都在 setup 阶段死掉**★ ——
这个 switch 无条件执行，与目标、与 FM_MERGE_DUP 给没给都无关。
实测 EntriesFaluFmac：44 秒、0 个比较点、`FM_MODE_ERROR` 之外的 rc=2。

**没有任何现成的闸会响**：Python lint 不看 tcl；`fm_shell` 只有真跑一次才知道；
而 Formality license 贵、一次几十分钟。所以这道闸做成**不需要 Formality** 的：
把 fm_eq.tcl 里的 switch 块抠出来，stub 掉 FM 命令，交给 `tclsh` 解析。

## 判据自己的负测（本仓规矩：闸必须双向，且要能证明自己有分辨力）

    --selftest 三例：
      ok       现在的 fm_eq.tcl 能解析           -> rc 0
      bug      把注记搬回 switch 体里            -> ★必须 rc != 0★，且报的是 CMD-013 那句
      meta     把提取器改成"永远交出空脚本"      -> ★正例必须转红★（防止闸变成 `return True`）

用法:
    python3 scripts/check_fm_eq_tcl_syntax.py             # 查仓里的 fm_eq.tcl
    python3 scripts/check_fm_eq_tcl_syntax.py --selftest  # 判据自检（含元负例）
"""
import pathlib
import re
import subprocess
import sys
import tempfile

REPO = pathlib.Path(__file__).resolve().parents[1]
FM_EQ = REPO / 'scripts' / 'fm_eq.tcl'

# 只查**解析**，不查语义：把会改变退出码的命令 stub 成 no-op，这样
# `FM_MODE_ERROR: 未知 FM_MODE=...` 这类"取值不合法"的正常分支不会被误判成语法错。
# Tcl 的 switch 体是在执行 switch 命令时才按列表解析的，所以仍然必须执行到它 ——
# 真有列表语法错就是一个未捕获的 Tcl error，tclsh rc=1，照样红。
STUB = '''proc set_app_var {args} {}
proc set_top {args} {}
proc exit {args} {}
'''


def extract_switches(text, blanket=False):
    """抠出所有 `switch -- $var {` 块（含体），返回可独立解析的 tcl 片段。

    blanket=True 是**元负例**：交出空脚本，用来验证正例那一行不是恒绿的。
    """
    if blanket:
        return ''
    lines = text.split('\n')
    chunks, seen_vars = [], []
    for i, l in enumerate(lines):
        m = re.match(r'^switch\s+--\s+\$(\w+)\s*\{', l)
        if not m:
            continue
        seen_vars.append(m.group(1))
        depth, j = 0, i
        while True:
            depth += lines[j].count('{') - lines[j].count('}')
            chunks.append(lines[j])
            j += 1
            if depth == 0:
                break
        chunks.append('')
    if not chunks:
        return ''
    head = ''.join(f'set {v} "false"\n' for v in dict.fromkeys(seen_vars))
    return STUB + head + 'set top X\n' + '\n'.join(chunks)


def run_tcl(script):
    """返回 (rc, stderr)。没有 tclsh 就报告不可用（不静默放行）。"""
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as f:
        f.write(script + '\nputs SWITCH_PARSE_OK\n')
        path = f.name
    try:
        p = subprocess.run(['tclsh', path], stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, universal_newlines=True)
        return p.returncode, (p.stderr + p.stdout)
    finally:
        try:
            pathlib.Path(path).unlink()
        except OSError:
            pass


def check(text, blanket=False):
    script = extract_switches(text, blanket=blanket)
    if not script.strip():
        return 1, 'fm_eq.tcl 里一个 switch 块都没抠到 —— 提取器失效，不算通过'
    rc, out = run_tcl(script)
    return rc, out


def selftest():
    text = FM_EQ.read_text()
    rc = 0

    r, out = check(text)
    ok = (r == 0)
    print(f'  ok        rc={r} {"PASS" if ok else "FAIL: " + out.strip()[:200]}')
    rc |= 0 if ok else 1

    # bug：把注记搬回 switch 体里（用真实那一行）
    bug = text.replace(
        'switch -- $_mergedup {',
        'switch -- $_mergedup {\n'
        '#       true   烧掉 5674 s CPU 卡在 "Merging duplicated registers"，★从未到达 match★')
    r, out = check(bug)
    ok = (r != 0 and 'list element in quotes' in out)
    print(f'  bug       rc={r} {"PASS（且理由正确）" if ok else "FAIL: " + out.strip()[:200]}')
    rc |= 0 if ok else 1

    # meta_blanket：提取器永远交出空脚本 -> 正例必须转红
    r, out = check(text, blanket=True)
    ok = (r != 0)
    print(f'  meta_blanket rc={r} {"PASS（正例转红）" if ok else "★FAIL：闸恒绿，上面两行什么也不证明★"}')
    rc |= 0 if ok else 1
    return rc


def main(argv):
    if '--selftest' in argv:
        print('check_fm_eq_tcl_syntax --selftest:')
        return selftest()
    r, out = check(FM_EQ.read_text())
    if r == 0:
        print('check_fm_eq_tcl_syntax: OK —— fm_eq.tcl 的 switch 块 tclsh 可解析')
        return 0
    print('check_fm_eq_tcl_syntax: ★FAIL★ —— fm_eq.tcl 的 switch 块 tclsh 解析失败，'
          '每一次 FM 都会在 setup 阶段死掉：')
    print(out.strip()[:1500])
    return 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""test_fm_eq_wellformed.py —— fm_eq.tcl 的结构不变式。

**为什么要有这道闸**（2026-09-14，我自己犯了两次才加）：

`scripts/fm_eq.tcl` 是多个 worker 并行修改的共享文件，冲突集中在同一行——
vmucp 白名单 `if {$top ni {...}}`。合并冲突时我两次处理错：

  第一次：沿用解**追加式台账**的做法"两侧都保留"。对台账对，对**代码**错——
          留下两条串联的 if，后一条会把只在前一条列表里的目标拒成
          `FM_MODE_ERROR: matched-unread strengthening 仅允许精确白名单`。
          实测 RNXbar/SNXbar（agent/arb 加）与 ITTageTable×5（agent/ittage 加）
          会互相拒掉对方。
  第二次：合并 agent/tage 时用 `git add -A` 把**仍带 `<<<<<<<` 标记**的文件
          提交了。那会让 Tcl 直接语法错、每个目标的证明都跑不起来。

两次都是我修好了却**没有加闸**，于是下一次合并原样复发。这道闸把"修好"变成
"修住"。

正确的合并方式：**取两侧白名单的并集，合成一条 if，两组依据注释都保留**。
"""
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile


def tcl_unparsable(text):
    """这段文本能不能被 Tcl 解析？不能就返回一句人话，能就返回 ''。

    ★这里原本是 `text.count('{') != text.count('}')`，是个误报源，换掉了★
    （2026-09-20，agent/fubusy-wbarb；同一天另一条 lane 也被它咬过一次）：
    main 上的 fm_eq.tcl 裸花括号是 139 vs 138，这道闸于是天天报"不配平"，
    而 `info complete` 说它**完全可以解析** —— 多出来的那个 `{` 在注释里
    （Tcl 的注释不是词法层剥掉的，但 `info complete` 数的是**命令结构**上的
    配平，注释里的孤立括号不影响一条完整命令的边界）。
    字符级计数看不见语法结构：它既会像这样误报，也会漏报
    （`}{` 数量相等但结构全错）。判"能不能解析"就该用解析器。

    真正咬人的那次（main 的 4c5615b 修的）是反过来的：一段注记被写进了
    `switch` 的花括号里，而 switch 的 body 是 **pattern/body 列表**不是脚本体，
    于是每个目标的 FM 都在 setup 阶段死掉（~44 秒、0 比较点、run_proof rc=2、
    native_facts.json 不生成）。那种错括号是**配平的**，计数一样抓不到；
    抓到它的是 scripts/check_fm_eq_tcl_syntax.py 的 tclsh 解析。
    """
    tclsh = shutil.which('tclsh')
    if not tclsh:
        # ★fail-closed：没有 tclsh 就说清楚判不了，不许悄悄退回字符计数★
        return 'tclsh 不在 PATH 上，无法判定 Tcl 可解析性（这道闸拒绝用字符计数替代）'
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False,
                                     encoding='utf-8') as fh:
        fh.write(text)
        src = fh.name
    try:
        probe = ('set f [open {%s} r]\n'
                 'fconfigure $f -encoding utf-8\n'
                 'set d [read $f]\n'
                 'close $f\n'
                 'puts [info complete $d]\n') % src
        r = subprocess.run([tclsh], input=probe, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, universal_newlines=True)
        out = (r.stdout or '').strip().splitlines()
        if r.returncode != 0 or not out:
            return 'tclsh 探针没跑出结果：%s' % (r.stdout or '')[-200:]
        if out[-1].strip() != '1':
            return 'Tcl 解析不完整（info complete = 0）—— 有命令没有闭合'
        return ''
    finally:
        pathlib.Path(src).unlink()

HERE = pathlib.Path(__file__).resolve().parent
TCL = HERE / 'fm_eq.tcl'
PASS, FAIL = [], []


def ck(name, ok, detail=''):
    (PASS if ok else FAIL).append(name)
    print(f'  {"ok  " if ok else "FAIL"}  {name}{"  " + detail if detail else ""}')


def check(text):
    """返回问题列表；空 = 结构良好。"""
    probs = []
    for mk in ('<<<<<<<', '=======', '>>>>>>>'):
        n = sum(1 for l in text.splitlines()
                if l.startswith(mk) or (mk == '=======' and l.rstrip() == mk))
        if n:
            probs.append(f'残留合并冲突标记 {mk} × {n}')
    n_if = len(re.findall(r'top ni \{', text))
    if n_if != 1:
        probs.append(f'vmucp 白名单 if 有 {n_if} 条（必须恰 1 —— 多条会串联互拒）')
    bad = tcl_unparsable(text)
    if bad:
        probs.append(bad)
    return probs


print('=== scripts/fm_eq.tcl 结构不变式 ===')
txt = TCL.read_text(errors='replace')
probs = check(txt)
ck('W1 无冲突标记 / 恰一条白名单 if / Tcl 可解析（info complete，不是数括号）', not probs)
for p in probs:
    print(f'          {p}')

if not probs:
    names = set(re.search(r'ni \{([^}]*)\}', txt).group(1).split())
    ck('W2 白名单非空且都是合法模块名', bool(names) and all(
        re.match(r'^[A-Za-z_]\w*$', n) for n in names), f'{len(names)} 个目标')

# ★对照★：种入每种坏形态都必须被抓，否则 W1 可能是空转。
cases = [
    ('两条 if',
     txt.replace('if {$top ni {', 'if {$top ni {A B} } ;# dup\n    if {$top ni {', 1)),
    ('残留冲突标记', '<<<<<<< HEAD\n' + txt + '\n>>>>>>> other\n'),
    # 负控：未闭合的 if —— info complete 必须说 0（数括号也抓得到，
    # 但这里考的是解析器判据还在不在）
    ('命令没闭合', txt + '\nif {1} {\n'),
]
for i, (label, bad) in enumerate(cases, start=3):
    got = check(bad)
    ck(f'W{i} 对照：种入「{label}」必须被抓', bool(got),
       f'报出 {len(got)} 项' if got else '★没抓到★')

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)

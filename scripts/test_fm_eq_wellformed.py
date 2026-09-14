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
import sys

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
    if text.count('{') != text.count('}'):
        probs.append(f'花括号不配平：{{ {text.count("{")} vs }} {text.count("}")}')
    return probs


print('=== scripts/fm_eq.tcl 结构不变式 ===')
txt = TCL.read_text(errors='replace')
probs = check(txt)
ck('W1 无冲突标记 / 恰一条白名单 if / 括号配平', not probs)
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
    ('括号不配平', txt + '\nif {1} {\n'),
]
for i, (label, bad) in enumerate(cases, start=3):
    got = check(bad)
    ck(f'W{i} 对照：种入「{label}」必须被抓', bool(got),
       f'报出 {len(got)} 项' if got else '★没抓到★')

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)

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
import subprocess
import sys
import tempfile

HERE = pathlib.Path(__file__).resolve().parent
TCL = HERE / 'fm_eq.tcl'
PASS, FAIL = [], []


def _strip_full_line_comments(text):
    """去掉整行注释。Tcl 里 `#` 只在命令起始位置才是注释起始。

    这里只去**整行**注释（首个非空字符是 `#`），不碰行尾的 `;#` ——
    实测 fm_eq.tcl 里 `;#` 出现 0 次，而少去一类注释只会让判据更严、不会漏。
    """
    return '\n'.join(l for l in text.split('\n')
                     if not l.lstrip().startswith('#'))


def _info_complete(text):
    """交给真 tclsh 问 `info complete`：这段文本是不是一个完整可解析的脚本。

    ★这是替换掉"裸数花括号"的那半★。数出来的 { 与 } 不相等**不等于**语法有问题：
    注释里、字符串里的花括号都会被数进去。2026-09-20 实测 fm_eq.tcl 裸计数
    139 vs 138，差的那个 `{` 在第 495 行的注释里（引用 `switch -- $_mergedup {`），
    而 `info complete` 返回 1 —— 文件完全可解析。
    判 Tcl 能不能解析，用 `info complete`，别用计数。

    返回 True/False/None（None = 没有 tclsh，判据不可用，调用方须 fail-closed）。
    """
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False) as f:
        f.write('set _t [read [open [lindex $argv 0] r]]\n'
                'puts [info complete $_t]\n')
        drv = f.name
    with tempfile.NamedTemporaryFile('w', suffix='.tclin', delete=False) as f:
        f.write(text)
        src = f.name
    try:
        r = subprocess.run(['tclsh', drv, src], stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, universal_newlines=True)
    except OSError:
        return None
    finally:
        for q in (drv, src):
            try:
                pathlib.Path(q).unlink()
            except OSError:
                pass
    if r.returncode != 0:
        return None
    return r.stdout.strip() == '1'


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
    # ★括号配平：两道判据，谁都不是裸计数★
    #  (a) info complete —— 抓「少了一个 }」（未闭合）。这是权威解析，注释/字符串
    #      里的花括号不会算数。
    #  (b) 去掉整行注释后的计数 —— 抓「多了一个 }」，info complete 对它返回 1
    #      （实测：`set a 1\n}\n` -> 1），所以不能只靠 (a)。
    comp = _info_complete(text)
    if comp is None:
        probs.append('无法调用 tclsh 判 info complete —— 判据不可用，按 fail-closed 判红')
    elif not comp:
        probs.append('tclsh info complete = 0：脚本未闭合（花括号/引号少了收口）')
    code = _strip_full_line_comments(text)
    if code.count('{') != code.count('}'):
        probs.append('去掉整行注释后花括号仍不配平：'
                     f'{{ {code.count("{")} vs }} {code.count("}")}')
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
    ('少一个收口括号', txt + '\nif {1} {\n'),
    ('多一个收口括号', txt + '\n}\n'),
    # ★注意这里要用 `\nswitch` 定位★：不带换行的那个串在文件里的**第一次**出现
    # 是在第 495 行的注释里（它正是引用了这条 switch）。种到注释里就等于没种，
    # 而 W8 要求注释里的不配平不被抓 —— 这个用例就会永远"没抓到"。
    ('括号不配平藏在代码里（不是注释里）',
     txt.replace('\nswitch -- $_mergedup {', '\nswitch -- $_mergedup { {', 1)),
]
# ★反向判据★：把不配平放进**注释**里，必须**不**被抓 —— 否则这道闸就是
# 2026-09-20 那个误报本身（它把第 495 行注释里的 `{` 当成了代码）。
_benign = txt + '\n# 这一行注释里有一个不配平的 { 字面量，它不影响解析\n'
for i, (label, bad) in enumerate(cases, start=3):
    got = check(bad)
    ck(f'W{i} 对照：种入「{label}」必须被抓', bool(got),
       f'报出 {len(got)} 项' if got else '★没抓到★')

ck('W%d 反向：注释里的不配平花括号**不许**被抓' % (3 + len(cases)),
   not check(_benign),
   '注释不参与配平计数' if not check(_benign) else '★误报：又把注释当代码了★')

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)

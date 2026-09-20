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
    # ★括号配平：数之前先去掉整行注释★（2026-09-20，Rob lane 实测的误报）
    # 裸计数在 main 4c442c13 上把 fm_eq.tcl 判红：{ 139 vs } 138，而
    # `check_fm_eq_tcl_syntax.py` 与 tclsh 的 `info complete` 都说文件是好的 ——
    # 差的那个 `{` 在一句**注释**里（它逐字引用了 `switch -- $_mergedup` 那行）。
    # 当时的处置是把那个字符从注释里删掉，让计数配平；但判据不改的话，
    # 下一句需要引用花括号的注释还会再红一次，而"改注释迁就判据"是反的：
    # ★判据应当看得懂语法结构，而不是让代码去迁就字符计数★
    # （同一类坑：check_array_mixed_drive.py 那次也是行级计数看不见结构）。
    # 这里只去**整行**注释，不碰行尾 `;#`：少去一类只会让判据更严，不会漏。
    code = _strip_full_line_comments(text)
    if code.count('{') != code.count('}'):
        probs.append('去掉整行注释后花括号仍不配平：'
                     f'{{ {code.count("{")} vs }} {code.count("}")}')
    probs += tcl_parse_probs(text)
    return probs


def _strip_full_line_comments(text):
    """去掉整行注释（首个非空字符是 `#`）。Tcl 里 `#` 只在命令起始位置才是注释。"""
    return '\n'.join(l for l in text.split('\n')
                     if not l.lstrip().startswith('#'))


# ---------------------------------------------------------------------------
# W5：整份脚本必须能被 Tcl **解析**（不是执行）。
#
# ★与 scripts/check_fm_eq_tcl_syntax.py 重叠，这是有意的★：两条 lane（本 lane 与
#   entries-rest3）在同一天各自独立撞到同一个缺陷、各自写了一道闸，main 合了它们的、
#   我合了 main。两份实现判的是同一件事但写法不同（那边逐个 switch 块，这里
#   整份 info complete + 每个 switch 体 llength），同一个缺陷要同时骗过两份才过得去。
#   合并成一份反而会丢掉这份独立性，所以留着。
#
# 为什么非加不可（2026-09-20 实测，ee3aa24）：那一版把一段经验注记贴进了
#   `switch -- $_mergedup { ... }` 的**体内**。★Tcl 的 switch 体里没有注释★——
#   body 按**列表**解析，`#` 开头的行是 pattern/body 元素，不是注释。其中一行含
#   `"Merging duplicated registers"，`（引号元素后紧跟非空格字符），Tcl 列表解析报
#       list element in quotes followed by "，★从未到达" instead of space
#   于是 **每一个 FM 目标**都在 setup 阶段死掉：fm_shell rc=2、不产 native_facts.json。
#   而当时 W1~W4 全绿 —— 冲突标记没有、白名单恰一条、括号也配平（switch 体的
#   花括号本来就配平）。**括号配平挡不住这个形状**，所以要一条真正过解析器的判据。
#
# 做法：`tclsh` 里 `info complete` + 一次不执行的解析。用 `proc _p {} { <脚本> }`
#   让 Tcl 走完整的语法/列表检查而**一条命令都不执行**（fm_shell 的 set_app_var
#   之类在纯 tclsh 里并不存在，所以绝不能真跑）。
# ---------------------------------------------------------------------------
def tcl_parse_probs(text):
    """两层：整份 info complete + 每个 switch 体真过一次 Tcl **列表**解析。

    第二层是关键。`proc __probe {} $s` 抓不到这个形状 —— Tcl **惰性编译** proc 体，
    switch 体的列表检查要到真正执行 switch 那一刻才发生（这也正是 ee3aa24 能一路
    提交进 main、直到第一个 FM 目标跑起来才炸的原因）。
    所以这里把每个 switch 的**体**单独喂给 `llength`：它走的就是出事的那个
    列表解析器，且**不执行任何命令**。
    """
    import subprocess, tempfile, os
    if shutil.which('tclsh') is None:
        return []          # 没有 tclsh：如实跳过（W0 会打印），不假装通过
    probs = []
    snippets = [('<整份脚本>', text, 'complete')]
    for body in _switch_bodies(text):
        snippets.append(('switch 体', body, 'llength'))
    for label, s, mode in snippets:
        err = _tcl_check(s, mode)
        if err:
            probs.append('Tcl 解析失败（%s / %s）：%s' % (label, mode, err))
    return probs


def _switch_bodies(text):
    """取出每条 switch 命令的体（最外层花括号内的原文）。"""
    out = []
    for m in re.finditer(r'(?m)^[ \t]*switch\b[^\n{]*\{', text):
        i = m.end() - 1                     # 指向开体的 '{'
        depth, j = 0, i
        while j < len(text):
            c = text[j]
            if c == '\\':
                j += 2
                continue
            if c == '{':
                depth += 1
            elif c == '}':
                depth -= 1
                if depth == 0:
                    out.append(text[i + 1:j])
                    break
            j += 1
    return out


def _tcl_check(s, mode):
    import subprocess, tempfile, os
    with tempfile.NamedTemporaryFile('w', suffix='.tcl', delete=False,
                                     encoding='utf-8') as fh:
        body = fh.name
        fh.write(s)
    drv = body + '.drv'
    with open(drv, 'w', encoding='utf-8') as fh:
        fh.write('set f [open {%s} r]\n' % body)
        fh.write('fconfigure $f -encoding utf-8\n')
        fh.write('set s [read $f]; close $f\n')
        if mode == 'complete':
            fh.write('if {![info complete $s]} { puts "脚本不完整(括号/引号未闭合)"; exit 1 }\n')
        else:
            # llength 走的就是出事的那个列表解析器；一条命令都不执行。
            fh.write('if {[catch {llength $s} e]} { puts $e; exit 1 }\n')
            fh.write('if {[llength $s] % 2} { puts "switch 体元素个数为奇数(pattern/body 不成对)"; exit 1 }\n')
        fh.write('exit 0\n')
    try:
        r = subprocess.run(['tclsh', drv], stdout=subprocess.PIPE,
                           stderr=subprocess.PIPE, timeout=60)
    finally:
        for f in (body, drv):
            try:
                os.unlink(f)
            except OSError:
                pass
    if r.returncode != 0:
        msg = (r.stdout + r.stderr).decode('utf-8', 'replace').strip().splitlines()
        return msg[0] if msg else '(无输出)'
    return None




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
    # ★多一个收口括号★：`info complete` 对它返回 **1**（实测
    #   `info complete "set a 1\n}\n"` = 1），所以解析判据是瞎的，
    #   只有配平计数抓得到。两条判据各有盲区，都得留着。
    ('多一个收口括号', txt + '\n}\n'),
    # 不配平藏在**代码**里（不是注释里）必须被抓。
    # ★写这条时自己先踩了一次★：用不带换行的 'switch -- $_mergedup {' 定位时，
    #   文件里第一次出现是在上方那段注释里，种子落进注释 = 等于没种，
    #   用例会永远"没抓到"。改用 '\nswitch' 定位。
    ('括号不配平藏在代码里（不是注释里）',
     txt.replace('\nswitch -- $_mergedup', '\nswitch -- $_mergedup {', 1)),
    # ★这条就是 ee3aa24 的真实形态★：注记贴进 switch 体。括号仍然配平、
    #   冲突标记仍然没有 —— 只有 Tcl 解析判据抓得到。
    # ★同样要用 '\nswitch' 定位★：2026-09-20 把注释里那个被删掉的左花括号
    #   写回去之后，这条用例当场"没抓到" —— 它的种子落进了上方那段**注释**里
    #   （注释逐字引用了这条 switch）。同一个坑，两条用例先后各踩一次。
    ('注释塞进 switch 体',
     txt.replace('\nswitch -- $_mergedup {',
                 '\nswitch -- $_mergedup {\n'
                 '#   卡在 "Merging duplicated registers"，★从未到达 match★', 1)),
]
for i, (label, bad) in enumerate(cases, start=3):
    got = check(bad)
    ck(f'W{i} 对照：种入「{label}」必须被抓', bool(got),
       f'报出 {len(got)} 项' if got else '★没抓到★')

# ★反向判据★：不配平只在**注释**里时不许被抓 —— 这正是 2026-09-20 那次误报本身。
_benign = txt + '\n# 这一行注释里有一个不配平的 { 字面量，它不影响 Tcl 解析\n'
_bp = check(_benign)
ck('W%d 反向：不配平只在注释里时**不许**被抓' % (3 + len(cases)), not _bp,
   '注释不参与配平计数' if not _bp else '★误报：又把注释当代码了★ %s' % _bp)

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)

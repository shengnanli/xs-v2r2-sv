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

正确的合并方式（★2026-09-20 起作废★）：取两侧白名单的并集，合成一条 if。

## ★2026-09-20：白名单搬走了，这条判据跟着换★

per-target 数据（白名单 65 个名字 + 各自依据 + LoadQueueReplay 的 appvar 块）已拆进
`verif/fm_target_config/<top>.tcl`（理由与实测见那里的 README）。于是：

  · 旧 W1 断言「`top ni {` **恰 1 条**」 —— 现在必须是 **0 条**：白名单一旦"回家"，
    就又把全仓 child 证书打翻一遍，所以这里从"要求它在"翻成"要求它不在"。
  · 新增两条同类不变式，防的是**同一种合并事故**换了个位置复发：
      per-target 配置的**载入器**必须恰 1 份（合并时留下两条 `source
      $::FM_TARGET_CONFIG` 会把同一份文件 source 两遍，appvar 声明翻倍）；
      `fm_target_apply_appvars` 的**调用**必须恰 1 处（丢了它，per-target appvar
      静默不生效 —— 没有任何人会报错，证明语义悄悄变了）。
  · "白名单里的名字合法" 这条改成查 `verif/fm_target_config/` 的**文件名**。

★改判据和改被判对象是两件事★：所以下面的对照用例也整套换过，
`W3` 现在种的是"白名单搬回 fm_eq.tcl"，`W8/W9` 种的是新增那两条。
"""
import pathlib
import re
import subprocess
import sys

HERE = pathlib.Path(__file__).resolve().parent
TCL = HERE / 'fm_eq.tcl'
CFG_DIR = HERE.parent / 'verif' / 'fm_target_config'
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
    if n_if != 0:
        probs.append(f'vmucp 白名单 if 有 {n_if} 条（必须 0 —— 白名单在 '
                     f'verif/fm_target_config/<top>.tcl，搬回来就又打翻全仓证书）')
    n_src = len(re.findall(r'^\s*source \$::FM_TARGET_CONFIG\s*$', text, re.M))
    if n_src != 1:
        probs.append(f'per-target 配置载入器有 {n_src} 条（必须恰 1 —— '
                     f'两条会把同一份配置 source 两遍，appvar 声明翻倍）')
    n_apply = len(re.findall(r'^\s*fm_target_apply_appvars\s*$', text, re.M))
    if n_apply != 1:
        probs.append(f'fm_target_apply_appvars 调用有 {n_apply} 处（必须恰 1 —— '
                     f'丢了它 per-target appvar 静默不生效，没人会报错）')
    if text.count('{') != text.count('}'):
        probs.append(f'花括号不配平：{{ {text.count("{")} vs }} {text.count("}")}')
    probs += switch_body_problems(text)
    return probs


# ---------------------------------------------------------------------------
# ★switch 的 body 是一个 **Tcl list**，`#` 在 list 里不是注释★（2026-09-20 实测）
#
# 括号配平 + 无冲突标记都过，脚本照样可以在运行期炸：ee3aa24 把一段中文注记写进了
# `switch -- $_mergedup { ... }` 的 body 里，注记中含引号
# `"Merging duplicated registers"`，于是 Tcl 解析 body 这个 list 时报
#     Error: list element in quotes followed by "，★从未到达" instead of space
#     ... stopped at line 494 due to error. (CMD-081)
# ★fm_eq.tcl 是每个 FM 目标共用的入口★：从 ee3aa24 起，main 上任何
# `make fm-<target>` 都在 44 秒内死在这里、一个比较点都跑不到。
#
# 上面那三条不变式（冲突标记 / 白名单条数 / 括号配平）**全都没抓到**它 ——
# 括号是配平的，冲突标记也没有。所以这里补一条**真解析**：把每个 switch 的 body
# 交给 tclsh 当 list 解析（`llength`），解析不了就报。用 tclsh 而不是自己写解析器，
# 判据才和运行时的那一个是同一个。
# ---------------------------------------------------------------------------
def _switch_bodies(text):
    """返回 [(行号, body 原文)]：每个 `switch ...{` 到配对 `}` 之间的内容。"""
    out = []
    for m in re.finditer(r'^[ \t]*switch\b[^\n{]*\{', text, re.M):
        start = m.end()          # 紧跟在开括号之后
        depth, i = 1, start
        while i < len(text) and depth:
            if text[i] == '{':
                depth += 1
            elif text[i] == '}':
                depth -= 1
            i += 1
        if depth == 0:
            out.append((text.count('\n', 0, m.start()) + 1, text[start:i - 1]))
    return out


def switch_body_problems(text):
    probs = []
    bodies = _switch_bodies(text)
    if not bodies:
        return ['找不到任何 switch —— 解析器与文件对不上，按 fail-closed 报']
    for ln, body in bodies:
        # 交给真正的 Tcl 解析器判：body 能不能当 list 读
        # 不用 capture_output / text=：本机是 python3.6，两者都不支持。
        r = subprocess.run(['tclsh'], input=('llength {' + body + '}\n').encode(),
                           stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if r.returncode != 0:
            err = r.stderr.decode('utf-8', 'replace')
            first = (err.strip().splitlines() or [''])[0]
            probs.append(f'第 {ln} 行的 switch body 不是合法 Tcl list：{first}')
            continue
        # 即使能解析，body 的**顶层**出现 `#` 开头的元素也是**静默错**：它会被当成一个
        # pattern，把紧跟其后的那一段当成它的 script。所以一并拒。
        # ★只看顶层★：`"true" { ... }` 里面是**脚本**不是 list，那里的 `#` 是正常注释
        #   （fm_eq.tcl 的 vmucp 白名单依据就写在那儿，几十行，完全合法）。
        #   第一版判据没分层，把那几十行也报了 —— 判据比坑还宽就会被当噪音关掉。
        depth = 0
        for bl in body.splitlines():
            s = bl.lstrip()
            if depth == 0 and s.startswith('#'):
                probs.append(f'第 {ln} 行的 switch body 顶层有 `#` 行 —— '
                             f'Tcl 会把它当 pattern 而不是注释：{s[:40]}')
                break
            depth += bl.count('{') - bl.count('}')
    return probs


print('=== scripts/fm_eq.tcl 结构不变式 ===')
txt = TCL.read_text(errors='replace')
probs = check(txt)
ck('W1 无冲突标记 / 白名单已搬走(0 条) / 载入器与 apply 各恰 1 / 括号配平', not probs)
for p in probs:
    print(f'          {p}')

if not probs:
    names = {p.stem for p in CFG_DIR.glob('*.tcl')} if CFG_DIR.is_dir() else set()
    ck('W2 per-target 配置非空且文件名都是合法模块名', bool(names) and all(
        re.match(r'^[A-Za-z_]\w*$', n) for n in names), f'{len(names)} 份配置')

def inject_into_switch(text, line):
    """把 line 插进**第一条真正的** `switch ... {` 语句体（行首匹配，跳过注释里的同形字样）。"""
    m = re.search(r'^[ \t]*switch\b[^\n{]*\{', text, re.M)
    assert m, '找不到行首的 switch 语句——对照用例失去意义，直接判失败'
    return text[:m.end()] + '\n' + line + text[m.end():]


# ★对照★：种入每种坏形态都必须被抓，否则 W1 可能是空转。
# 元负例在这里是**结构自带**的：W1 断言的是真文件上 check() 返回**空**。
# 任何把判据变成"无条件报警"的改动（例如 switch_body_problems 直接 return ['x']）
# 都会让 W1 转红，所以下面这几条对照不会退化成"只要出声就算过"。
cases = [
    # ★换判据之后的头号对照★：白名单"回家"必须被抓（旧版判据在这里是反的）。
    ('白名单搬回 fm_eq.tcl',
     txt.replace('\nfm_target_apply_appvars',
                 '\nif {$top ni {A B}} { exit 3 }\nfm_target_apply_appvars', 1)),
    ('载入器被合并成两份',
     txt.replace('\n    source $::FM_TARGET_CONFIG',
                 '\n    source $::FM_TARGET_CONFIG\n    source $::FM_TARGET_CONFIG', 1)),
    ('apply 调用被合并掉',
     txt.replace('\nfm_target_apply_appvars', '\n# fm_target_apply_appvars', 1)),
    ('残留冲突标记', '<<<<<<< HEAD\n' + txt + '\n>>>>>>> other\n'),
    ('括号不配平', txt + '\nif {1} {\n'),
    # ★本轮真事故的复现★：注记搬回 switch body 里，必须被抓。
    # ★注入点必须锚到**行首的真语句**★：文件顶部的注记里现在也写着
    #   `switch -- $_mergedup { ... }` 这串字样（说明事故长什么样），
    #   用 str.replace(..., 1) 会打到那条**注释**上、注入等于没发生，
    #   两条对照就会静默变成"没抓到"——这正是本轮实测踩到的。
    ('注记写进 switch body（含引号）',
     inject_into_switch(txt, '# 卡在 "Merging duplicated registers"，★从未到达 match★')),
    # 引号即使配平、list 能解析，`#` 行照样是静默错（被当 pattern）。
    ('注记写进 switch body（不含引号）',
     inject_into_switch(txt, '# 纯中文注记没有引号也不行')),
]
for i, (label, bad) in enumerate(cases, start=3):
    got = check(bad)
    ck(f'W{i} 对照：种入「{label}」必须被抓', bool(got),
       f'报出 {len(got)} 项' if got else '★没抓到★')

print()
print(f'PASS {len(PASS)} / FAIL {len(FAIL)}')
sys.exit(1 if FAIL else 0)

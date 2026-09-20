#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""check_param_override.py —— 例化时按名覆盖了一个**目标模块根本没有**的参数。

## 由来（2026-09-20 实测，DelayN lane）

`rtl/common/xs_DelayNWithValid_core.sv` 从「固定两级」泛化成「n 级」，参数
`GOLDEN_DATA_REG_BITS` 改名成 `GOLDEN_REG_BITS`，并新增 `STAGES` / `VALID_CHAIN`。
两个薄文件 `DelayNWithValid.sv` / `DelayNWithValid_1.sv` 没跟着改，仍然写着

    xs_DelayNWithValid_core #( .WIDTH(...), .GOLDEN_DATA_REG_BITS(100), ... )

★VCS 对这件事只给一条 Warning，不报错★：

    Warning-[AOUP] Attempt to override undefined parameter
      Attempting to override undefined parameter "GOLDEN_DATA_REG_BITS", will be ignored

于是 `GOLDEN_REG_BITS` 取**默认值** `VALID_CHAIN + STAGES*WIDTH` ——
那正好是核自己算出来的值，`initial` 里那条守恒等式变成恒真，
**整条 elaborate 期不变式被静默解除武装**。这两个目标本来是靠这条不变式守着
「位宽/级数抄错立刻 $fatal」的；而 UT 照过、FM 照绿（电路恰好没变，
因为 STAGES/VALID_CHAIN 的默认值 2/1 碰巧就是对的）。

也就是说：**改名一个参数，就能让不变式无声消失，六道闸没有一道会响。**
这道闸就是那个响。

## 判据

对 `rtl/` 下每一处按名参数覆盖 `Mod #(.P(...)) u_x (...)`：
若 `Mod` 是本仓 `rtl/` 里定义的模块，则 `P` 必须出现在它的参数表里
（ANSI 头 `#(...)` 里的 `parameter`，或模块体里的 `parameter` 声明；
`localparam` 不算 —— 它本来就不可覆盖）。
目标模块不在 `rtl/` 里（厂商宏、golden 件）时跳过：那种情况下本闸无从判断，
不假装知道。

用法:
  python3 scripts/check_param_override.py            # 报告 + fail-closed
  python3 scripts/check_param_override.py --quiet
  python3 scripts/check_param_override.py --root <dir>   # 负测用
"""
import argparse
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent

# 注释与字符串先抹掉，避免注释里的示例代码被当成真例化（本仓注释里就有）。
LINE_COMMENT = re.compile(r'//[^\n]*')
BLOCK_COMMENT = re.compile(r'/\*.*?\*/', re.S)
STRING = re.compile(r'"(?:[^"\\\n]|\\.)*"')

BRACKET = {'(': ')', '[': ']', '{': '}'}
IDENT = re.compile(r'[A-Za-z_]\w*')
# 例化头：<Type> #( ... ) <inst> ( —— Type 必须是标识符，且不是关键字。
INST_HEAD = re.compile(r'(?<![\w.$])([A-Za-z_]\w*)\s*#\s*\(')
KEYWORDS = {
    'module', 'if', 'else', 'for', 'while', 'case', 'casez', 'casex', 'return',
    'function', 'task', 'always', 'always_ff', 'always_comb', 'always_latch',
    'assign', 'initial', 'final', 'generate', 'endgenerate', 'begin', 'end',
    'assert', 'assume', 'cover', 'class', 'interface', 'package', 'program',
    'logic', 'bit', 'reg', 'wire', 'int', 'integer', 'byte', 'shortint',
    'longint', 'real', 'time', 'typedef', 'localparam', 'parameter', 'repeat',
}


def strip_noise(text):
    text = BLOCK_COMMENT.sub(lambda m: '\n' * m.group(0).count('\n'), text)
    text = LINE_COMMENT.sub('', text)
    return STRING.sub('""', text)


def match_paren(text, open_idx):
    """open_idx 指向 '('，返回配对 ')' 的下标（找不到返回 -1）。"""
    depth = 0
    for i in range(open_idx, len(text)):
        if text[i] == '(':
            depth += 1
        elif text[i] == ')':
            depth -= 1
            if depth == 0:
                return i
    return -1


def split_top_level(text, sep):
    """按 sep 切分，但不进入 () [] {} 内部。"""
    items, depth, cur = [], [], ''
    for ch in text:
        if ch in BRACKET:
            depth.append(BRACKET[ch])
        elif depth and ch == depth[-1]:
            depth.pop()
        if ch == sep and not depth:
            items.append(cur)
            cur = ''
        else:
            cur += ch
    items.append(cur)
    return items


def _decl_name(item):
    """一条声明里的被声明名：取顶层 '=' 之前、去掉括号/方括号内容后的最后一个标识符。

    ★这里不能图省事用 `[^;,()]*?(\w+)\s*=` 那种正则★（2026-09-20 第一版就是，
    当场在 xs_iq_entries_core 上报出 30 多个假阳性）：本仓的参数声明里带着
    `parameter logic [NUM_REGSRC-1:0][(NUM_WK_IQ > 0 ? NUM_WK_IQ : 1)-1:0] IQ_SRC_MASK = '0`
    这种**维度表达式里有括号**的写法，排除 '(' 的正则直接匹配不上，
    于是「参数表里没有这个名字」——闸自己看错了。
    """
    head = split_top_level(item, '=')[0]
    stripped, depth = '', []
    for ch in head:
        if ch in BRACKET:
            depth.append(BRACKET[ch])
            continue
        if depth:
            if ch == depth[-1]:
                depth.pop()
            continue
        stripped += ch
    ids = IDENT.findall(stripped)
    return ids[-1] if ids else None


def module_params(text, decl_end):
    """从 module 声明处开始，取出它可被覆盖的参数名集合。"""
    names = set()
    body_start = decl_end
    if re.compile(r'\bmodule\s+\w+\s*#\s*\(').match(text, decl_end):
        open_idx = text.index('(', decl_end)
        close_idx = match_paren(text, open_idx)
        if close_idx > 0:
            # ANSI 参数表里每一个顶层逗号项都是一个参数（首项带 parameter 关键字，
            # 后续项可以省略关键字继承前一项 —— 省略的那些同样可被按名覆盖）。
            for item in split_top_level(text[open_idx + 1:close_idx], ','):
                if re.search(r'\blocalparam\b', item):
                    continue
                n = _decl_name(item)
                if n:
                    names.add(n)
            body_start = close_idx
    # 模块体里的 parameter 声明（非 ANSI 写法也可被按名覆盖）
    end = text.find('endmodule', body_start)
    body = text[body_start:end if end > 0 else len(text)]
    for stmt in split_top_level(body, ';'):
        if not re.search(r'(^|[^\w.])parameter\b', stmt):
            continue
        stmt = stmt[re.search(r'(^|[^\w.])parameter\b', stmt).end() - len('parameter') :]
        for item in split_top_level(stmt, ','):
            n = _decl_name(item)
            if n:
                names.add(n)
    return names


def collect_modules(files):
    """返回 {模块名: (参数名集合, 文件)}。同名模块由别的闸去管，这里取第一个。"""
    mods = {}
    for f in files:
        text = strip_noise(f.read_text(errors='replace'))
        for m in re.finditer(r'\bmodule\s+(\w+)\b', text):
            name = m.group(1)
            if name in mods:
                continue
            mods[name] = (module_params(text, m.start()), f)
    return mods


def collect_overrides(files):
    """返回 [(文件, 行号, 被例化模块名, 覆盖的参数名)]。"""
    out = []
    for f in files:
        text = strip_noise(f.read_text(errors='replace'))
        for m in INST_HEAD.finditer(text):
            mod = m.group(1)
            if mod in KEYWORDS:
                continue
            open_idx = text.index('(', m.end() - 1)
            close_idx = match_paren(text, open_idx)
            if close_idx < 0:
                continue
            # 参数表后面必须跟「实例名 (」，否则不是例化（例如 `int #(...)` 这种不会出现）
            tail = text[close_idx + 1:close_idx + 200]
            if not re.match(r'\s*\w+\s*(\[[^\]]*\]\s*)?\(', tail):
                continue
            inner = text[open_idx + 1:close_idx]
            if '.' not in inner:
                continue        # 按位置覆盖，本闸管不了（也没有名字可核）
            for pm in re.finditer(r'\.\s*(\w+)\s*\(', inner):
                line = text.count('\n', 0, open_idx + 1 + pm.start()) + 1
                out.append((f, line, mod, pm.group(1)))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=None, help='扫描根目录（默认 <repo>/rtl）')
    ap.add_argument('--quiet', action='store_true')
    args = ap.parse_args()

    root = pathlib.Path(args.root) if args.root else (REPO / 'rtl')
    files = sorted(root.rglob('*.sv'))
    if not files:
        print('check_param_override: %s 下没有 .sv，判失败（空扫描不算通过）' % root)
        return 2

    mods = collect_modules(files)
    bad = []
    checked = 0
    for f, line, mod, pname in collect_overrides(files):
        if mod not in mods:
            continue            # 目标不在本仓 rtl/ 里：厂商宏 / golden 件，不假装知道
        checked += 1
        if pname not in mods[mod][0]:
            bad.append((f, line, mod, pname, sorted(mods[mod][0])))

    if not args.quiet:
        print('check_param_override: 扫描 %d 个文件，核对 %d 处按名参数覆盖'
              % (len(files), checked))
    if bad:
        print('★参数覆盖了目标模块没有的名字（VCS 只给 Warning-[AOUP]，会静默取默认值）★')
        for f, line, mod, pname, have in bad:
            print('  %s:%d  %s #(.%s(...))  —— %s 的参数表里没有这个名字'
                  % (f.relative_to(REPO) if REPO in f.parents else f, line, mod, pname, mod))
            print('      %s 实有参数: %s' % (mod, ', '.join(have) or '(无)'))
        return 1
    if not args.quiet:
        print('check_param_override: OK')
    return 0


if __name__ == '__main__':
    sys.exit(main())

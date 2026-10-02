#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""hier_reach.py —— 整芯片（重写件优先）例化图 + 从 XSTop 出发的可达性。

## 这个脚本回答的问题

单目标 UT/FM 只证明「这个重写模块与它的 golden 对照等价」。它**不回答**
「这个模块在整芯片层次里还在不在」。本轮整芯片 elaborate 暴露的现象是：
一批重写父模块把 golden 的子模块**吸收**进了自己的可读核（例如 golden
`TLPLIC` 例化 65 个 `LevelGateway`，重写 `TLPLIC` 直接例化 65 个
`xs_LevelGateway_core`），于是那个独立签核过的 `LevelGateway` 模块**在
XSTop 可达闭包里一个实例都没有**。

本脚本把这件事变成可复算的数字：impl 侧模块定义集合、XSTop 可达集合、
不可达集合，以及每个模块的例化点（含 generate 块路径）。

## 解析口径（两条路径，因为两侧源码形态不同）

  * **golden**（firtool 产物，1.8 GB）：一文件一模块、例化恒为
    `  <Type> <inst> (` 单独成行。用逐行正则流式扫，20 秒扫完。
  * **impl**（rtl/**.sv，4.9 MB，手写）：有参数化例化 `xs_X_core #(...) u (`、
    有 generate-for + `begin : label`。用逐行状态机，额外跟踪 begin/end 栈，
    于是能给出 `g_gateways[d].u_gw` 这种**真实层次路径**，而不是只给实例名。

两条路径都做注释剥离（impl 侧逐字符，golden 侧走「整行无 `/` 无 `"` 就跳过」
的快路径——不加这条快路径，1.8 GB 要跑 10 分钟以上，实测）。

fail-closed：同一个模块名被两个文件定义 → 退出码 2（整芯片只能进一份）。

用法:
  python3 scripts/hier_reach.py --filelist build_full_elab/impl-XSTop/files.f \\
                                --out build_hier
  python3 scripts/hier_reach.py --gen-filelist --out build_hier
"""
from __future__ import print_function

import argparse
import collections
import json
import os
import pathlib
import re
import subprocess
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent

_MOD = re.compile(r'^[ \t]*module[ \t]+([A-Za-z_]\w*)')
_END = re.compile(r'^[ \t]*endmodule\b')
# firtool 例化：缩进 >= 2 空格 + `<Type> <inst> (` 单独成行
_INST_FT = re.compile(r'^[ \t]{2,}([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)[ \t]*\([ \t]*$')
# 手写例化（非参数化）：`<Type> <inst> (` 行尾可带注释（注释已剥离）
_INST_PLAIN = re.compile(r'^[ \t]*([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)[ \t]*\([ \t]*$')
_INST_ONELINE = re.compile(r'^[ \t]*([A-Za-z_]\w*)[ \t]+([A-Za-z_]\w*)[ \t]*\([^;]*\)[ \t]*;')
_PARAM_HEAD = re.compile(r'^[ \t]*([A-Za-z_]\w*)[ \t]*#[ \t]*\(')
_IDENT_HEAD = re.compile(r'^[ \t]*([A-Za-z_]\w*)')
_BEGIN_LBL = re.compile(r'\bbegin\b[ \t]*:[ \t]*([A-Za-z_]\w*)')
_GENFOR = re.compile(r'\bfor[ \t]*\([ \t]*(?:genvar[ \t]+)?([A-Za-z_]\w*)[ \t]*=')

#: 不可能是模块类型名的 SV 关键字（例化识别的否定名单，宁可漏也不能误认）
KW = set('''module endmodule input output inout wire reg logic assign always always_comb always_ff
always_latch initial final generate endgenerate genvar for if else case casex casez endcase begin end
function endfunction task endtask return parameter localparam typedef struct union enum packed signed
unsigned bit byte int integer shortint longint real time string import export package endpackage
interface endinterface modport class endclass automatic static const ref var void new
posedge negedge or and not xor nand nor xnor buf supply0 supply1 tri wand wor uwire
default disable fork join join_any join_none wait while do repeat forever break continue
defparam unique unique0 priority assert assume cover restrict property endproperty sequence
endsequence bind virtual extends pure chandle event let nettype timeunit timeprecision
initial assign'''.split())


class ParseError(Exception):
    pass


def strip_comments_line(line, in_block):
    """逐字符剥离行注释/块注释/字符串。只在行里真的有 `/` 或 `"` 时才调用。"""
    out = []
    i, n = 0, len(line)
    while i < n:
        if in_block:
            j = line.find('*/', i)
            if j < 0:
                return ''.join(out), True
            i, in_block = j + 2, False
            continue
        c = line[i]
        if c == '/' and i + 1 < n and line[i + 1] == '/':
            break
        if c == '/' and i + 1 < n and line[i + 1] == '*':
            in_block = True
            i += 2
            continue
        if c == '"':
            j = i + 1
            while j < n:
                if line[j] == '\\':
                    j += 2
                    continue
                if line[j] == '"':
                    break
                j += 1
            out.append('""')
            i = j + 1
            continue
        out.append(c)
        i += 1
    return ''.join(out), in_block


def clean_lines(path):
    """流式产出剥了注释的行。无 `/` 无 `"` 的行走快路径直接 yield。"""
    in_block = False
    with open(path, errors='replace') as fh:
        for raw in fh:
            if not in_block and '/' not in raw and '"' not in raw:
                yield raw
                continue
            line, in_block = strip_comments_line(raw, in_block)
            yield line


def scan_golden(path):
    """firtool 产物：一文件一模块、例化单独成行。返回 [(module, [(type,inst,path)])]"""
    cur, kids, res = None, [], []
    for line in clean_lines(path):
        m = _MOD.match(line)
        if m:
            if cur is not None:
                res.append((cur, kids))
            cur, kids = m.group(1), []
            continue
        if _END.match(line):
            if cur is not None:
                res.append((cur, kids))
            cur, kids = None, []
            continue
        if cur is None:
            continue
        mi = _INST_FT.match(line)
        if mi and mi.group(1) not in KW and mi.group(2) not in KW:
            kids.append((mi.group(1), mi.group(2), mi.group(2)))
    if cur is not None:
        res.append((cur, kids))
    return res


def scan_impl(path):
    """手写 SV：参数化例化 + generate 块路径。返回 [(module, [(type,inst,hierpath)])]"""
    cur, kids, res = None, [], []
    blocks = []            # [(label|None, is_genfor, genvar|None)]
    pend_type, pend_depth = None, 0

    def hierpath(inst):
        segs = []
        for lbl, isfor, gv in blocks:
            if lbl is None:
                continue
            segs.append('%s[%s]' % (lbl, gv) if isfor and gv else lbl)
        segs.append(inst)
        return '.'.join(segs)

    for line in clean_lines(path):
        s = line.strip()
        if not s:
            continue
        # --- 参数化例化的续行：吃完 #( ... ) 再读实例名 ---
        if pend_type is not None:
            for k, ch in enumerate(line):
                if ch == '(':
                    pend_depth += 1
                elif ch == ')':
                    pend_depth -= 1
                    if pend_depth == 0:
                        tail = line[k + 1:]
                        mt = _IDENT_HEAD.match(tail)
                        inst = mt.group(1) if mt and mt.group(1) not in KW else '?'
                        kids.append((pend_type, inst, hierpath(inst)))
                        pend_type = None
                        break
            continue
        m = _MOD.match(line)
        if m:
            if cur is not None:
                res.append((cur, kids))
            cur, kids, blocks = m.group(1), [], []
            continue
        if _END.match(line):
            if cur is not None:
                res.append((cur, kids))
            cur, kids, blocks = None, [], []
            continue
        if cur is None:
            continue
        # --- begin/end 栈（generate 块路径的来源） ---
        # ★按 token 出现顺序处理 begin/end★：`end else begin : g_b` 必须先弹出
        # 前一个分支（g_a）再压入 g_b。旧写法先压后弹，把 g_b 弹掉、留下 g_a，
        # 于是 else 分支里的实例被记到 if 分支的标签下（例：VSMergeBufferImp 的
        # FreeList_1 被记成 g_freelist_vl.freeCount_freeList，实际在 g_freelist_vs，
        # 重绑 SimTop 的 XMR 在 VCS 里解析失败）。
        mf = _GENFOR.search(line)
        for mt in re.finditer(r'\b(begin|end)\b(?![a-z_])', line):
            if mt.group(1) == 'end':
                if blocks:
                    blocks.pop()
                continue
            mb = _BEGIN_LBL.match(line, mt.start())
            blocks.append((mb.group(1) if mb else None, bool(mf),
                           mf.group(1) if mf else None))
        # --- 例化识别 ---
        mp = _PARAM_HEAD.match(line)
        if mp and mp.group(1) not in KW:
            pend_type, pend_depth = mp.group(1), 0
            for k, ch in enumerate(line):
                if ch == '(':
                    pend_depth += 1
                elif ch == ')':
                    pend_depth -= 1
                    if pend_depth == 0:
                        tail = line[k + 1:]
                        mt = _IDENT_HEAD.match(tail)
                        inst = mt.group(1) if mt and mt.group(1) not in KW else '?'
                        kids.append((pend_type, inst, hierpath(inst)))
                        pend_type = None
                        break
            continue
        for rx in (_INST_PLAIN, _INST_ONELINE):
            mi = rx.match(line)
            if mi and mi.group(1) not in KW and mi.group(2) not in KW:
                kids.append((mi.group(1), mi.group(2), hierpath(mi.group(2))))
                break
    if cur is not None:
        res.append((cur, kids))
    return res


def build(files, repo=REPO):
    defs, kids = {}, {}
    dups = collections.defaultdict(list)
    rtl = str((repo / 'rtl').resolve())
    for f in files:
        p = pathlib.Path(f)
        if not p.exists():
            raise ParseError('源清单里的文件不存在: %s' % f)
        impl = str(p.resolve()).startswith(rtl)
        for name, ks in (scan_impl(p) if impl else scan_golden(p)):
            if name in defs:
                dups[name].append(str(p))
                continue
            defs[name] = str(p)
            kids[name] = ks
    if dups:
        raise ParseError('同一个模块名被多个文件定义（整芯片只能进一份）:\n  ' +
                         '\n  '.join('%s: %s + %s' % (k, defs[k], v)
                                     for k, v in sorted(dups.items())))
    return defs, kids


def reachable(kids, defs, top):
    if top not in defs:
        raise ParseError('顶层 %s 不在模块定义集合里' % top)
    seen, st = set(), [top]
    while st:
        m = st.pop()
        if m in seen:
            continue
        seen.add(m)
        for ty, _i, _p in kids.get(m, ()):
            if ty in defs and ty not in seen:
                st.append(ty)
    return seen


def gen_filelist(out, repo=REPO):
    out.parent.mkdir(parents=True, exist_ok=True)
    subprocess.check_call([sys.executable, str(repo / 'scripts' / 'full_elab_filelist.py'),
                           '--out', str(out)], stdout=subprocess.DEVNULL)
    return out


def load_filelist(fl):
    return [l.strip() for l in pathlib.Path(fl).read_text().splitlines()
            if l.strip() and not l.strip().startswith(('-', '+', '#'))]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--filelist')
    ap.add_argument('--gen-filelist', action='store_true')
    ap.add_argument('--top', default='XSTop')
    ap.add_argument('--out', default=str(REPO / 'build_hier'))
    a = ap.parse_args()

    out = pathlib.Path(a.out)
    out.mkdir(parents=True, exist_ok=True)
    fl = pathlib.Path(a.filelist) if a.filelist else gen_filelist(out / 'files.f')
    if a.gen_filelist:
        fl = gen_filelist(out / 'files.f')
    files = load_filelist(fl)
    try:
        defs, kids = build(files)
        reach = reachable(kids, defs, a.top)
    except ParseError as e:
        print('hier_reach: FATAL: %s' % e, file=sys.stderr)
        return 2
    unreach = sorted(set(defs) - reach)
    print('源清单文件数   : %d' % len(files))
    print('模块定义       : %d' % len(defs))
    print('从 %-9s可达: %d' % (a.top, len(reach)))
    print('不可达         : %d' % len(unreach))

    (out / 'defs.tsv').write_text(''.join('%s\t%s\n' % (k, v) for k, v in sorted(defs.items())))
    (out / 'reachable.txt').write_text('\n'.join(sorted(reach)) + '\n')
    (out / 'unreachable.txt').write_text('\n'.join(unreach) + '\n')
    with (out / 'insts.tsv').open('w') as f:
        f.write('# parent\ttype\tinst\thier_path\n')
        for p in sorted(kids):
            for ty, inst, hp in kids[p]:
                f.write('%s\t%s\t%s\t%s\n' % (p, ty, inst, hp))
    print('产物: %s/{defs.tsv,reachable.txt,unreachable.txt,insts.tsv}' % out)
    return 0


if __name__ == '__main__':
    sys.exit(main())

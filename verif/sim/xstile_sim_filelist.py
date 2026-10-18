#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""xstile_sim_filelist.py —— 整芯片 SimTop 仿真的 impl 清单：**只换 XSTile**，核外保持 golden。

## 与 scripts/full_elab_filelist.py 的区别（为什么不能直接用它）

full_elab_filelist.py 的规则是「rtl/ 里凡与 golden 同名的模块一律顶掉 golden」。
rtl/ 里除了核还有核外件的重写（OpenLLC 家族、TLPLIC、IMSIC、CHI 交叉开关 …），
用它出清单 = 同时替换了 XSTop 的核外部分。codex 0238 要求的是：
**SimTop 里只把 XSTile 换成重写版，核外件保持在已知 golden 基线**。所以本脚本：

  1. impl 侧：从 rtl/xstile/XSTile.sv 出发，沿**重写件的例化关系**做可达闭包 R_in。
     闭包里的名字若 rtl/ 有定义就用 rtl/，否则只允许是**登记过的存储模型**
     （ram_* / sram_array_* / array_* / *_ext / data_mem_* / 三个具名阵列），
     其余任何 golden 逻辑件出现在 R_in 里都直接 fail-closed。
  2. 核外：从 golden SimTop 出发沿 **golden 例化关系**做闭包，遇到 XSTile 不下钻，得 G_out。
     G_out 全部取 golden 文件。
  3. R_in ∩ G_out（核内外共用的同名模块）——同一名字只能有一份定义，
     出现即 fail-closed（除非是存储模型：两侧同一份 golden 文件，无歧义）。
  4. 纳入清单的每个 rtl 文件里声明的**所有**模块名都不得与 golden 取用件重名。

产物里**不含 SimTop.sv**（difftest Makefile 显式传 $(RTL_DIR)/SimTop.sv）。
配合 run_fullchip.sh 的 IMPL_ONLY_LIST=1：impl 侧 build/rtl 只放打补丁的 SimTop.sv，
`-y $(RTL_DIR)` 库兜底**为空**——清单漏了任何件 VCS 当场报错，**不可能静默回落到 golden**。

用法:
  python3 verif/sim/xstile_sim_filelist.py --out <files.f> --tsv <srcmap.tsv>
"""
import argparse
import collections
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent.parent
GOLDEN_DEFAULT = '/home/eda/xs-env/G1-canonical/golden-rtl'

MODULE_RE = re.compile(r'^\s*module\s+(\w+)', re.M)
PKG_DEF_RE = re.compile(r'^\s*package\s+(\w+)\s*;', re.M)
PKG_USE_RE = re.compile(r'\b(\w+)\s*::')
TOK_RE = re.compile(r'[A-Za-z_]\w*|\S')

# 登记的存储模型（memory note ram-models-not-rewritten：存储层不重写，两侧读同一份 golden 文件）
MEM_RE = re.compile(r'^(ram_\w+|sram_array_\w+|array|array_\w+|data_mem_\w+|'
                    r'dt_pcTransType_160x2|stateBankTags_320x3|diff_rat_state_bank_320x776)$')


def die(msg):
    print('xstile_sim_filelist: FATAL: ' + msg, file=sys.stderr)
    sys.exit(2)


def strip(t):
    t = re.sub(r'/\*.*?\*/', ' ', t, flags=re.S)
    return re.sub(r'//[^\n]*', '', t)


def insts(text, known):
    """返回 text 里被例化的已知模块名集合：<Name> [#( ... )] <inst> [ [..] ] ("""
    toks = TOK_RE.findall(strip(text))
    out, n = set(), len(toks)
    for i, t in enumerate(toks):
        if t not in known or (i and toks[i - 1] in ('module', 'endmodule')):
            continue
        # 宏例化：`MACRO(<模块名>, ...)（rtl/backend/Rename.sv 的 `STD_FL(StdFreeList, ...)，实测漏过一次）
        if i >= 3 and toks[i - 1] == '(' and toks[i - 3] == '`':
            out.add(t)
            continue
        j = i + 1
        if j < n and toks[j] == '#':
            j += 1
            if j >= n or toks[j] != '(':
                continue
            d = 0
            while j < n:
                d += toks[j] == '('
                d -= toks[j] == ')'
                j += 1
                if d == 0:
                    break
        if j < n and re.match(r'[A-Za-z_]', toks[j]):
            j += 1
            while j < n and toks[j] == '[':
                while j < n and toks[j] != ']':
                    j += 1
                j += 1
            if j < n and toks[j] == '(':
                out.add(t)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN_DEFAULT)
    ap.add_argument('--rtl', default=str(REPO / 'rtl'))
    ap.add_argument('--out', required=True)
    ap.add_argument('--tsv', required=True)
    ap.add_argument('--rename-dir', required=True, help='核外共用模块改名拷贝的落点（工作区）')
    a = ap.parse_args()
    G, R = pathlib.Path(a.golden), pathlib.Path(a.rtl)

    gfile = {}
    for p in sorted(G.iterdir()):
        if p.suffix not in ('.sv', '.v'):
            continue
        for m in MODULE_RE.findall(p.read_text(errors='replace')):
            if m in gfile:
                die(f'golden 模块 {m} 在两个文件里: {gfile[m]} {p}')
            gfile[m] = p
    rfile, rdecl, pkg_only = {}, {}, []
    for p in sorted(R.rglob('*.sv')):
        ms = MODULE_RE.findall(p.read_text(errors='replace'))
        rdecl[p] = ms
        if not ms:
            pkg_only.append(p)
        for m in ms:
            if m in rfile:
                die(f'rtl 模块 {m} 在两个文件里: {rfile[m]} {p}')
            rfile[m] = p
    known = set(gfile) | set(rfile)
    cache = {}

    def children(p):
        if p not in cache:
            cache[p] = insts(p.read_text(errors='replace'), known)
        return cache[p]

    if 'XSTile' not in rfile:
        die('rtl/ 里没有 XSTile')
    # 1) R_in：重写 XSTile 闭包（有 rtl 定义的走 rtl）
    r_in, src, stack = set(), {}, ['XSTile']
    while stack:
        m = stack.pop()
        if m in r_in:
            continue
        r_in.add(m)
        if m in rfile:
            src[m] = ('RTL_XSTILE', rfile[m])
        elif m in gfile:
            src[m] = ('GOLDEN_MEM' if MEM_RE.match(m) else 'GOLDEN_LOGIC_IN_XSTILE', gfile[m])
        else:
            die(f'XSTile 闭包里的 {m} 无定义')
        stack += sorted(children(src[m][1]) - r_in)
    bad = sorted(m for m in r_in if src[m][0] == 'GOLDEN_LOGIC_IN_XSTILE')
    if bad:
        die('XSTile 闭包里有非存储的 golden 逻辑件: ' + ' '.join(bad))
    # 2) G_out：golden SimTop 闭包，不下钻 XSTile
    g_out, stack = set(), ['SimTop']
    while stack:
        m = stack.pop()
        if m in g_out:
            continue
        g_out.add(m)
        if m == 'XSTile':
            continue
        if m not in gfile:
            die(f'golden 核外闭包里的 {m} 无定义')
        stack += sorted(children(gfile[m]) - g_out)
    g_out.discard('XSTile')
    shared = sorted((g_out & r_in) - {m for m in r_in if src[m][0] == 'GOLDEN_MEM'})
    # 3) 核内外共用的同名逻辑模块：XSTile 内必须用 rtl，核外必须保持 golden。
    #    同一编译单元里一个名字只能有一份定义，所以对**核外**一侧做机械改名：
    #    golden 文件拷贝到 --rename-dir，`module X` -> `module X__golden_outcore`，
    #    核外 golden 父模块里 `X <inst> (` 的类型名同样改掉。只改类型标识符，逐字其余不变。
    ren_dir = pathlib.Path(a.rename_dir)
    ren_dir.mkdir(parents=True, exist_ok=True)
    renamed = {}
    if shared:
        if 'SimTop' in {m for m in g_out if children(gfile[m]) & set(shared)}:
            die('SimTop 直接例化共用模块，改名方案不适用')
        need = sorted(m for m in g_out if m in shared or (children(gfile[m]) & set(shared)))
        pat_inst = re.compile(r'^(\s*)(' + '|'.join(map(re.escape, shared)) + r')(\s+\w+\s*\()', re.M)
        pat_mod = re.compile(r'^(\s*module\s+)(' + '|'.join(map(re.escape, shared)) + r')\b', re.M)
        for m in need:
            t = gfile[m].read_text(errors='replace')
            t2, n1 = pat_mod.subn(r'\1\2__golden_outcore', t)
            t2, n2 = pat_inst.subn(r'\1\2__golden_outcore\3', t2)
            q = ren_dir / gfile[m].name
            q.write_text('// RENAMED-FOR-SIM(xstile_sim_filelist.py): 核外 golden 拷贝, 共用模块类型名加 __golden_outcore\n' + t2)
            renamed[m] = (q, n1, n2)
        for m in shared:
            src[m + '__golden_outcore'] = ('GOLDEN_OUTCORE_RENAMED', renamed[m][0])
    for m in g_out:
        if m in shared:
            continue
        if m in renamed:
            src[m] = ('GOLDEN_OUTCORE_PATCHED_INST', renamed[m][0])
        else:
            src.setdefault(m, ('GOLDEN_MEM_OUTCORE' if MEM_RE.match(m) else 'GOLDEN_OUTCORE', gfile[m]))
    golden_names = {m for m, (c, _) in src.items() if c != 'RTL_XSTILE'} - set(shared)
    rtl_files = sorted({src[m][1] for m in r_in if src[m][0] == 'RTL_XSTILE'})
    for p in rtl_files:
        clash = set(rdecl[p]) & golden_names
        if clash:
            die(f'{p} 声明了与 golden 取用件重名的模块 {sorted(clash)}')

    # 包顺序：复用 full_elab_filelist.pkg_order（只读引用，不改那个脚本）
    sys.path.insert(0, str(REPO / 'scripts'))
    import full_elab_filelist as fef
    # ★golden 的 firtool 宏头 extern_modules.sv 放最前★（0 个模块，只有 `ifndef/`define）：
    # rtl/backend/{TrapEntryVSEventModule,VSstatusModule}.sv 用了 `ASSERT_VERBOSE_COND_ 等
    # firtool 宏却不自己定义。golden 流里这些宏由先编的 golden 文件头带进来；本清单 rtl 在前，
    # 不先给宏头就 Error-[UM] Undefined macro（实测踩过）。宏头逐字来自同一份 G1，无设计逻辑。
    lines = [str(G / 'extern_modules.sv')]
    lines += [str(p) for p in pkg_only] + [str(p) for p in fef.pkg_order(rtl_files)]
    gold_files = sorted({str(p) for m, (c, p) in src.items()
                         if c != 'RTL_XSTILE' and m != 'SimTop'})
    lines += gold_files
    pathlib.Path(a.out).write_text('\n'.join(lines) + '\n')

    cnt = collections.Counter(c for c, _ in src.values())
    with open(a.tsv, 'w') as f:
        f.write('# xstile_sim_filelist.py 生成；module\tclass\tsource\n')
        for m in sorted(src):
            f.write(f'{m}\t{src[m][0]}\t{src[m][1]}\n')
    print(f'R_in(XSTile 闭包) 模块: {len(r_in)}  其中 rtl: {cnt["RTL_XSTILE"]}  '
          f'golden 存储模型: {cnt["GOLDEN_MEM"]}')
    print(f'G_out(核外, golden) 模块: {len(g_out)}  其中存储模型: {cnt["GOLDEN_MEM_OUTCORE"]}  '
          f'逻辑: {cnt["GOLDEN_OUTCORE"]}（含 SimTop，SimTop 由 Makefile 另传）')
    print(f'核内外共用、核外侧改名的模块: {len(shared)} {shared}')
    print(f'因此打了改名补丁的核外 golden 文件: {len(renamed)} -> {ren_dir}')
    print(f'清单: package-only rtl {len(pkg_only)} + rtl 模块文件 {len(rtl_files)} + golden 文件 {len(gold_files)}'
          f' = {len(lines)} 项 -> {a.out}')
    unused = sorted(m for m in rfile if m not in r_in)
    print(f'rtl/ 中不在 XSTile 闭包、本清单不用的模块: {len(unused)}'
          f'（其中与 golden 同名=核外重写件: {sum(1 for m in unused if m in gfile)}）')
    return 0


if __name__ == '__main__':
    sys.exit(main())

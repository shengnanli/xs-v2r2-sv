#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""xstile_srcmap.py —— XSTile「重写逻辑 + 已批准存储模型」源表（codex 0238 主线 1）。

## 回答的问题

XSTile 闭包已逐层 FM 签核，但签核是**组合证明**：每一层的 impl 侧可以读 golden 子模块、
靠 child 证书承接。它不直接回答「只拿 rtl/ 能不能把整个 XSTile 拼出来」。本脚本回答这个：

  从 XSTile 出发，按例化关系求闭包；每个模块按「rtl/ 有定义 → 用 rtl/，否则 → golden」
  选源（与 scripts/full_elab_filelist.py 的整芯片取舍规则一致），然后要求：
    * 选到 golden 的模块**全部**是登记过的存储模型（verif/vendor_boundary.tsv 或
      verif/mc_memory_registry.tsv 里有同名行），且文件 sha256 与登记值逐字相等；
    * 一个 golden 逻辑模块都不许有——有就 FATAL，不静默放过。

## 输出

  docs/xstile_srcmap.tsv   闭包内每个模块一行：module / kind / source / sha256(仅 golden 存储)
                           kind ∈ {RTL, MEMORY_MODEL}；本表进 gate 幂等闸。
  --filelist <f>           可直接喂给 VCS 的源清单（package 拓扑序在前，存储模型在后）；
                           不入库，由 scripts/xstile_rtl_elab.sh 生成并 elaborate。

存储模型保留**完整仿真行为**（golden 行为级 RAM 原文），不是 FM 的黑盒壳。

## 例化识别（保守）

去注释后，用「已知模块名 [#(...)] 实例名 [数组] (」匹配例化。名字只取已知模块集合，
所以只会**多认**（例如某个函数恰好与模块同名），不会漏认合法例化；多认的后果是闭包偏大、
更严。闭包是否恰好等于 VCS 实际 elaborate 的集合，由 xstile_rtl_elab.sh 用
「不给 -top 时 VCS 列出的 Top Level Modules 只能是 XSTile」交叉核对。

用法:
  python3 scripts/xstile_srcmap.py                 # 写 docs/xstile_srcmap.tsv
  python3 scripts/xstile_srcmap.py --check         # 只比对，不写（gate 用）
  python3 scripts/xstile_srcmap.py --filelist build_xstile_rtl/files.f
"""
import argparse
import hashlib
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / 'scripts'))
from full_elab_filelist import GOLDEN_DEFAULT, pkg_order  # noqa: E402

TOP = 'XSTile'
OUT = REPO / 'docs' / 'xstile_srcmap.tsv'
MODULE_RE = re.compile(r'^\s*module\s+(\w+)', re.M)
MACRO_CALL_RE = re.compile(r'`\w+\s*\(')
WORD_RE = re.compile(r'\b[A-Za-z_]\w*\b')
COMMENT_RE = re.compile(r'//[^\n]*|/\*.*?\*/', re.S)
# 例化只出现在语句开头（行首 / `;` / `begin` / `else` / generate 标签 `:` 之后），后接
# 参数表 `#` 或实例名。锚在语句开头是为了线性时间：不锚的「任意词 [#(...)] 词 (」写法
# 在 Python 3.6 上对 XSCore/Rob 这类大文件要 140 秒。锚定可能漏认的例化由
# xstile_rtl_elab.sh 兜底——清单少一个模块，VCS 当场 Error-[CFCILFBI]。
INST_RE = re.compile(r'(?:^|;|\bbegin\b|\belse\b|:)[ \t]*(\w+)\s*(?:#|\w+\s*[\[(])', re.M)


def die(msg):
    print('xstile_srcmap: FATAL: ' + msg, file=sys.stderr)
    sys.exit(2)


def sha256(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def registered_memories():
    """design -> (leaf_file, sha256)，两张冻结登记表的并集；同名两表都有时必须一致。"""
    reg = {}
    for path, fcol, scol in ((REPO / 'verif' / 'vendor_boundary.tsv', 3, 4),
                             (REPO / 'verif' / 'mc_memory_registry.tsv', 2, 3)):
        for line in path.read_text().splitlines():
            if not line.strip() or line.startswith('#'):
                continue
            c = line.split('\t')
            ent = (c[fcol], c[scol])
            if c[0] in reg and reg[c[0]] != ent:
                die(f'{c[0]} 在两张存储登记表里的文件/sha 不一致：{reg[c[0]]} vs {ent}')
            reg[c[0]] = ent
    return reg


def index_sources(G):
    rtl = {}
    for p in sorted((REPO / 'rtl').rglob('*.sv')):
        for n in MODULE_RE.findall(p.read_text(errors='replace')):
            if n in rtl:
                die(f'模块 {n} 被两个 rtl 文件声明：{rtl[n]} 与 {p}')
            rtl[n] = p
    gold = {}
    for p in sorted(G.iterdir()):
        if p.suffix not in ('.sv', '.v'):
            continue
        for n in MODULE_RE.findall(p.read_text(errors='replace')):
            gold.setdefault(n, p)
    return rtl, gold


def closure(rtl, gold):
    known = set(rtl) | set(gold)
    src_of, kids_of = {}, {}
    todo = [TOP]
    while todo:
        m = todo.pop()
        if m in src_of:
            continue
        if m in rtl:
            src_of[m] = ('RTL', rtl[m])
        elif m in gold:
            src_of[m] = ('GOLDEN', gold[m])
        else:
            die(f'模块 {m} 在 rtl/ 与 golden 里都找不到定义')
        text = COMMENT_RE.sub(' ', src_of[m][1].read_text(errors='replace'))
        body = _module_body(text, m)
        kids = {k for k in INST_RE.findall(body) if k in known and k != m}
        # 宏例化：rtl/backend/Rename.sv 用 `STD_FL(StdFreeList_2, v0FreeList, ...) 例化四个
        # free list，上面的例化式看不见（实测被 xstile_rtl_elab.sh 的 Error-[URMI] 兜住）。
        # 宏调用实参里出现的已知模块名一律算子模块——多认只会让闭包更严。
        for mc in MACRO_CALL_RE.finditer(body):
            kids |= {k for k in WORD_RE.findall(_balanced(body, mc.end() - 1))
                     if k in known and k != m}
        kids_of[m] = kids
        todo.extend(kids)
    return src_of, kids_of


def _balanced(text, i):
    """text[i] == '('：返回到配对 ')' 为止的实参串。"""
    depth = 0
    for j in range(i, len(text)):
        if text[j] == '(':
            depth += 1
        elif text[j] == ')':
            depth -= 1
            if depth == 0:
                return text[i + 1:j]
    return text[i + 1:]


def _module_body(text, m):
    """只取模块 m 的 module..endmodule 段（一个 rtl 文件里可能有多个模块）。"""
    mm = re.search(r'^\s*module\s+' + re.escape(m) + r'\b', text, re.M)
    if not mm:
        die(f'{m} 的源文件里找不到 module 声明')
    end = re.search(r'\bendmodule\b', text[mm.end():])
    return text[mm.end(): mm.end() + (end.start() if end else len(text))]


def build(G, idx=None, reg=None):
    """idx=(rtl, gold)、reg 可由调用方给（负测用：改一处登记/删一个 rtl 定义，看是否判死）。"""
    rtl, gold = idx if idx is not None else index_sources(G)
    reg = reg if reg is not None else registered_memories()
    src_of, _ = closure(rtl, gold)
    rows, bad = [], []
    for m in sorted(src_of):
        kind, p = src_of[m]
        if kind == 'RTL':
            rows.append((m, 'RTL', str(p.relative_to(REPO)), '-'))
            continue
        if m not in reg:
            bad.append(f'{m}: golden 逻辑模块（{p.name}）出现在 XSTile 闭包里，且不在存储登记表')
            continue
        leaf, want = reg[m]
        got = sha256(p)
        if p.name != leaf:
            bad.append(f'{m}: 登记文件 {leaf}，实际选到 {p.name}')
        elif got != want:
            bad.append(f'{m}: {p.name} sha256 {got} ≠ 登记值 {want}')
        rows.append((m, 'MEMORY_MODEL', '$G1/' + p.name, got))
    if bad:
        die('XSTile 闭包里有不该出现的 golden 源：\n  ' + '\n  '.join(bad))
    return rows, src_of


def render(rows):
    n_rtl = sum(1 for r in rows if r[1] == 'RTL')
    head = [
        '# XSTile 源表（scripts/xstile_srcmap.py 生成；禁止手工编辑）。codex 0238 主线 1。',
        '# 「重写逻辑 + 已批准存储模型」：闭包内 RTL 一律取 rtl/；golden 只允许登记过的存储模型，',
        '# sha256 与 verif/vendor_boundary.tsv / verif/mc_memory_registry.tsv 登记值逐字相等。',
        '# $G1 = G1-canonical/golden-rtl。存储模型是 golden 行为级 RAM 原文（完整仿真行为），非 FM 黑盒壳。',
        f'# 闭包模块 {len(rows)}：RTL {n_rtl} / MEMORY_MODEL {len(rows) - n_rtl} / golden 逻辑 0',
        'module\tkind\tsource\tsha256',
    ]
    return '\n'.join(head + ['\t'.join(r) for r in rows]) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--golden', default=GOLDEN_DEFAULT)
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--filelist')
    a = ap.parse_args()
    G = pathlib.Path(a.golden)
    rows, src_of = build(G)
    text = render(rows)

    if a.filelist:
        rtl_files = sorted({p for k, p in src_of.values() if k == 'RTL'})
        mem_files = sorted({p for k, p in src_of.values() if k == 'GOLDEN'})
        # 只含 package、被闭包内文件用到的 rtl 文件也得进：package 不是模块，闭包看不见它
        pkgs = sorted(p for p in (REPO / 'rtl').rglob('*.sv')
                      if not MODULE_RE.search(p.read_text(errors='replace')))
        files = pkg_order(pkgs + rtl_files)
        out = pathlib.Path(a.filelist)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text('\n'.join(str(p) for p in files + mem_files) + '\n')
        print(f'写出 {out}：rtl {len(rtl_files)} + 纯 package {len(pkgs)} + 存储模型 {len(mem_files)}')

    if a.check:
        cur = OUT.read_text() if OUT.exists() else ''
        if cur != text:
            print(f'FAIL: {OUT.relative_to(REPO)} 与重算结果不一致（DRIFT）')
            return 1
        print(f'OK: {OUT.relative_to(REPO)} 与重算一致')
        return 0
    if not a.filelist:
        OUT.write_text(text)
        print(f'写出 {OUT.relative_to(REPO)}')
    print(text.splitlines()[4])
    return 0


if __name__ == '__main__':
    sys.exit(main())

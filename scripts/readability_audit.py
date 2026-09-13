#!/usr/bin/env python3
"""readability_audit.py —— 可读性验收（与 FM 同等地位的硬指标，须常态化跑）。

本工程有两个硬指标：正确性与可读性。正确性有 UT+FM+receipt 一整套闸；可读性此前
只在最早期人工 grep 过一次，之后上百个文件经机械继承/生成进来**从未复查**——
本脚本把可读性也变成可机器复跑的闸。

检查项（每项都能指出具体文件与行）：
  A. 禁用命名：代码区出现 golden 展平中间名 `_GEN_*` / `_T_<n>`。
     注释里作为"对应 golden 哪根线"的交叉引用是允许的，故按**去注释后的代码区**判。
  B. 文件头：首行须是注释，且头部注释块 ≥3 行（说清这个模块是什么、在哪一层、核心机制）。
  C. 头注释与内容自洽：
     - 头里若列了"已覆盖变体/覆盖 X 个"之类清单，清单中的模块必须真在本文件里；
     - 头里不得引用已不存在的文件（单文件规范下 `<X>_wrapper.sv` 已并入，再提就是误导）。
  D. 单文件结构：模块声明顺序须是 package → xs_*_core → golden 同名 wrapper。
  E. 大文件导航：>1500 行的文件不拆（保持一模块一文件），但必须有"本文件导航"，
     且导航行号须真落在分节注释上——导航一旦腐烂就成了误导。

退出码非零 = 有 A/B/C/D 类问题。
"""
import argparse
import pathlib
import os
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = pathlib.Path(os.environ['XSSV_RTL']) if os.environ.get('XSSV_RTL') else REPO / 'rtl'

FORBIDDEN = re.compile(r'\b_(GEN|T)(_\d+)?\b')
MOD_RE = re.compile(r'^(package|module)\s+(\w+)', re.MULTILINE)
COVER_LIST = re.compile(r'^//\s{2,}(\w+)\s*[:：]', re.MULTILINE)
WRAPPER_REF = re.compile(r'\b(\w+)_wrapper(\.sv)?\b')


def strip_comments(text):
    """去掉 // 行注释与 /* */ 块注释，只留代码区。"""
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)


def header_block(text):
    out = []
    for ln in text.splitlines():
        if ln.startswith('//'):
            out.append(ln)
        elif not ln.strip():
            if out:
                break
        else:
            break
    return out



# --- F 类：头注释的断言与文件事实是否相符 ------------------------------------
# 为什么需要这一类：B 类（头 ≥3 行）只管"有没有写"，不管"写的对不对"。
# 本轮补审时我用脚本批量补头，结果补出了假话——某个 74 行、含 16 条 always/assign
# 的自足模块，头上写着"只做参数化与端口展平""核体见 X.sv"。注释里的假话比没有注释更害人。
CLAIM_THIN = re.compile(r'只做参数化与端口展平|只做端口适配|不含逻辑')
CLAIM_CORE = re.compile(r'核体见\s+(\S+?\.sv)')
# 端口展平 = 给端口赋一个不含运算符的表达式（切片/拼接/常量都算）
FLATTEN_RHS = re.compile(r'^[\w\[\]:{},\s\']+$')
# 例化：覆盖 `Name inst (`、`Name #( ... ) inst (`、`Name #(` 三种写法
# 例化写法三种都要认：`Name inst (`、`Name #(...) inst (`、以及参数表换行的 `Name #(`
INST_ANY = re.compile(
    r'^\s+([A-Za-z_]\w*)\s*(?:#\s*\((?:[^()]|\([^()]*\))*\)\s*\w*\s*\('
    r'|#\s*\($'
    r'|\s+\w+\s*\()', re.MULTILINE)


def _module_index(root):
    idx = {}
    for f in root.rglob('*.sv'):
        for m in re.finditer(r'^module\s+(\w+)', f.read_text(errors='replace'), re.M):
            idx[m.group(1)] = f
    return idx


def _resolve(tgt, f, repo):
    import pathlib as _pl
    for c in (repo / tgt, f.parent / _pl.Path(tgt).name, repo / 'rtl' / 'common' / _pl.Path(tgt).name):
        if c.exists():
            return c
    return None


def claim_problems(p, text, hdr, modidx, repo):
    try:
        rel = str(p.relative_to(repo))
    except ValueError:
        rel = str(p)
    h = '\n'.join(hdr)
    out = []
    n_always = len(re.findall(r'\balways(_ff|_comb|_latch)?\b', text))
    n_logic = 0
    for a in re.findall(r'^\s*assign\b.*?;', text, re.M | re.S):
        rhs = a.split('=', 1)[1].rstrip(';').strip() if '=' in a else ''
        if rhs and not FLATTEN_RHS.match(rhs):
            n_logic += 1
    insts = [m.group(1) for m in INST_ANY.finditer(text) if m.group(1) in modidx]
    if CLAIM_THIN.search(h) and (n_always > 0 or n_logic > 0):
        out.append(f'{rel}: 头称"只做端口展平/不含逻辑"，实有 {n_always} 个 always '
                   f'+ {n_logic} 条含运算的 assign —— 注释在说假话')
    m = CLAIM_CORE.search(h)
    if m:
        tgt = m.group(1)
        if _resolve(tgt, p, repo) is None:
            out.append(f'{rel}: 头称"核体见 {tgt}"，该文件不存在')
        elif not insts:
            out.append(f'{rel}: 头称"核体见 {tgt}"，但本文件没有例化任何模块')
    # 头部重复行（补头脚本容易叠出来的噪音；空 // 分隔行不算）
    # 分隔线（// 后面只有重复标点）成对出现是正常排版，不算重复噪音
    DIVIDER = re.compile(r'^//[\s=\-*_~#]*$')
    seen, dup = set(), None
    for l in hdr:
        s = l.strip()
        if DIVIDER.match(s):
            continue
        if s in seen:
            dup = s
            break
        seen.add(s)
    if dup:
        out.append(f'{rel}: 头注释有重复行 "{dup[:40]}"')
    return out



# ---- G 类：代码区与 golden 逐字重合率 ----
# 为什么需要它：A 类只查 golden 的展平中间名（_GEN_/_T_），但如果照抄的那段 golden
# 恰好不含这类名字（纯端口表、纯实例连线、纯 assign），A 类就抓不到。
# 实证（上一轮 xs-v2r2-sv）：
#   Predictor_wrapper.sv  44604 行，98.5% 逐字来自 G0 golden，代码区 7940 处 _GEN_/_T_  → A 类能抓
#   Composer_wrapper.sv    4157 行，71.0% 逐字来自 G0 golden，代码区 **0** 处          → A 类抓不到
# 后者正是"照抄但躲过审计"的形态。
#
# 判据只看**代码区**（去注释、去空行），且排除 wrapper 的端口表——端口必须与 golden
# 逐位同名是规范要求，那部分重合是应该的。
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                      '/home/eda/xs-env/G1-canonical/golden-rtl'))
OVERLAP_LIMIT = float(os.environ.get('XSSV_OVERLAP_LIMIT', '0.45'))
_PORTLINE = re.compile(r'^\s*(input|output|inout)\b')
# 实例连线 `.io_x (y),`、例化头 `Foo bar (`、收尾 `);`、纯声明、括号关键字 ——
# 这些与 golden 逐字相同是**规范要求或结构必然**（端口名由 golden 定），不构成"照抄逻辑"。
# 实证：ICacheDataArray 是 MBIST 分发壳，1351 行重合里 99.85% 属这几类
# （实例连线 975 / 声明 320 / 例化头 36 / 括号 18），真逻辑行只重合 2 条。
# 只看剩下的真逻辑行才有判别力。
_STRUCTURAL = re.compile(
    r'^(\.\w+'
    r'|\)\s*\w*\s*;?$'
    r'|(wire|logic|reg|localparam|parameter|genvar|typedef|import|package|endpackage)\b'
    r'|[A-Za-z_]\w*(\s*#\s*\(.*)?\s+\w+\s*\($'
    r'|(begin|end|endmodule|endcase|endgenerate|endfunction|else)\b'
    r'|module\s+\w+'
    r'|\{|\}|,$)')

def _codelines(text, drop_ports=True):
    out = []
    for ln in strip_comments(text).splitlines():
        s = ln.rstrip()
        if not s.strip():
            continue
        if drop_ports and (_PORTLINE.match(s) or _STRUCTURAL.match(s.strip())):
            continue
        out.append(s.strip())
    return out

def golden_overlap(p, text):
    """返回 (重合行数, 代码区行数, 比率)；golden 不存在时返回 None。"""
    g = GOLDEN / p.name
    if not g.exists():
        return None
    impl = _codelines(text)
    if len(impl) < 60:          # 小文件重合率噪声大，不判
        return None
    gold = set(_codelines(g.read_text(errors='replace')))
    same = sum(1 for l in impl if l in gold)
    return same, len(impl), same / len(impl)

def audit_file(p, modidx=None):
    text = p.read_text(errors='replace')
    try:
        rel = str(p.relative_to(REPO))
    except ValueError:          # RTL 根被 XSSV_RTL 覆盖（反测夹具）时不在 REPO 下
        rel = str(p)
    problems = []

    code = strip_comments(text)
    for m in FORBIDDEN.finditer(code):
        line = code[:m.start()].count('\n') + 1
        problems.append(('A', f'{rel}: 代码区出现 golden 展平名 {m.group(0)}（约第 {line} 行）'))
        break

    hdr = header_block(text)
    if not hdr:
        problems.append(('B', f'{rel}: 文件头没有注释'))
    elif len(hdr) < 3:
        problems.append(('B', f'{rel}: 文件头注释仅 {len(hdr)} 行（要求 ≥3，说清定位与机制）'))

    ov = golden_overlap(p, text)
    if ov and ov[2] > OVERLAP_LIMIT:
        problems.append(('G', f'{rel}: 代码区 {ov[0]}/{ov[1]} 行（{100*ov[2]:.1f}%）'
                              f'逐字来自 golden（已排除端口表/实例连线/声明），超过 {100*OVERLAP_LIMIT:.0f}% —— '
                              f'疑似照抄而非重写（端口表已排除在外）'))

    decls = {m.group(2) for m in MOD_RE.finditer(text)}
    hdr_text = '\n'.join(hdr)
    if re.search(r'已覆盖变体|覆盖变体|变体包装层', hdr_text):
        listed = {m.group(1) for m in COVER_LIST.finditer(hdr_text)}
        stray = sorted(n for n in listed if n not in decls and n.startswith(p.stem.split('_')[0]))
        if stray:
            problems.append(('C', f'{rel}: 头注释列了本文件没有的模块 {stray[:3]}'
                                  f'（单文件规范下这是家族头被整段复制的残留）'))
    for m in WRAPPER_REF.finditer(hdr_text):
        problems.append(('C', f'{rel}: 头注释引用了已不存在的 {m.group(0)}'
                              f'（单文件规范下 wrapper 已并入本文件）'))
        break

    order = [m.group(2) for m in MOD_RE.finditer(text)]
    core_i = next((i for i, n in enumerate(order) if n.startswith('xs_') and n.endswith('_core')), None)
    wrap_i = next((i for i, n in enumerate(order) if n == p.stem), None)
    if core_i is not None and wrap_i is not None and core_i > wrap_i:
        problems.append(('D', f'{rel}: 模块顺序应为 核 → golden 同名 wrapper，当前相反'))

    if modidx is not None:
        for msg in claim_problems(p, text, hdr, modidx, REPO):
            problems.append(('F', msg))

    # E 类（大文件）：用户裁定**不拆文件**，保持"一个 golden 模块一个文件"。
    # 代价是读者要在两千行里找路，所以改判为：>1500 行必须有"本文件导航"，
    # 且导航里的行号必须真落在一条分节注释上（否则导航会随改动腐烂成误导）。
    n = text.count('\n') + 1
    hint = []
    if n > 1500:
        lines = text.splitlines()
        if '本文件导航' not in text:
            problems.append(('E', f'{rel}: {n} 行且无"本文件导航"——不拆文件就必须给导航'))
        else:
            stale = []
            for m in re.finditer(r'^//\s+L(\d+)\s+(\S.*)$', text, re.M):
                ln = int(m.group(1))
                near = [lines[i].strip() for i in range(max(0, ln - 2), min(len(lines), ln + 1))]
                if not any(x.startswith('//') and len(x) > 6 for x in near):
                    stale.append(ln)
            if stale:
                problems.append(('E', f'{rel}: 导航行号 {stale[:4]} 没落在分节注释上（导航已腐烂）'))
        hint = [f'{rel}: {n} 行（按裁定不拆，已配导航）']
    return problems, hint


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args()

    modidx = _module_index(RTL)
    all_problems, hints, nfiles = [], [], 0
    for p in sorted(RTL.rglob('*.sv')):
        nfiles += 1
        pr, hi = audit_file(p, modidx)
        all_problems += pr
        hints += hi

    from collections import Counter
    cnt = Counter(k for k, _ in all_problems)
    print(f'可读性验收：扫描 {nfiles} 个文件')
    labels = {'A': 'A 代码区禁用命名', 'B': 'B 文件头缺失/过短',
              'C': 'C 头注释与内容不符', 'D': 'D 单文件结构顺序',
              'E': 'E 大文件导航缺失/腐烂', 'F': 'F 头注释断言与事实矛盾',
              'G': 'G 代码区与 golden 逐字重合过高'}
    for k in 'ABCDEFG':
        print(f'  {labels[k]}: {cnt.get(k, 0)}')
    if hints:
        print(f'  （大文件，按裁定不拆）: {len(hints)}')
        for h in hints[:5]:
            print(f'      {h}')
    if not a.quiet:
        for k in 'ABCDEFG':
            items = [m for kk, m in all_problems if kk == k]
            for m in items[:8]:
                print(f'    [{k}] {m}')
            if len(items) > 8:
                print(f'    [{k}] …另有 {len(items) - 8} 条')
    return 1 if all_problems else 0


if __name__ == '__main__':
    sys.exit(main())

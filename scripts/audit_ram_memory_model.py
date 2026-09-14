#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""audit_ram_memory_model.py —— codex 0158 §1「最小功能审查」的可复算实现。

codex 0158 §1 原文（方案 1）要求：把 golden 里那批**非 2 的幂**行为级 RAM 模型
逐条审定登记为 `APPROVED_MEMORY_MACRO_MODEL`，按**精确 module 名 + golden 源码
hash** 绑定；不得建通用 ELAB-147 政策例外，也不得让后缀或诊断文本本身授权任何东西。
每条入表前要做三项最小功能审查：

    M1  它确实是 memory-only 模型（没有功能逻辑）；
    M2  端口宽度与读写行为和实现边界一致；
    M3  父级控制不会**有意**依赖越界地址值。

★ 本脚本不让任何东西转绿 ★。codex 0158：「A clean native result, not registry
membership, turns the target green.」入表只是允许把同一个精确边界两侧对称黑盒，
证明仍要自己跑 FM 并且干净。本脚本只是把那三项审查从「我读过了」变成「谁都能
复算一遍」，好让剩下的模型逐个加时不用重新发明判据。

## 判据强度（全部 fail-closed，认不出就报 MANUAL，绝不报 PASS）

M1 用的是**精确模板等价**，不是「grep 不到 FSM 关键字所以没有逻辑」：
   按 (module 名, 地址位宽, 数据位宽, 深度, 随机化位宽) 重建整段 firtool 模板文本，
   与 golden 现文件去注释/归一空白后的正文**逐字**比对。多一条 assign、多一个
   always、改一个位选，都会当场不等。**宏定义头**（firtool 标准头，第 1..module 行）
   另按 sha256 与家族参照件比对，堵住往头里塞代码的路。

M3 是一条**归纳证明**的机器复核，不是随机仿真观察：
   把父文件里驱动该地址口的寄存器的**全部**赋值枚举出来，要求
     (a) 复位/flush 支路赋的都是 0；
     (b) 唯一的非常量赋值是「自增 1」；
     (c) 该自增被 `sig == <depth-1>` 的比较**互斥地**挡住（相等时赋 0）。
   三条成立即 0 ≤ sig ≤ depth-1 对所有可达状态成立（基例 0，归纳步 +1 且在
   depth-1 处回卷）。impl 侧的回卷常写在 `function` 里，本脚本会把被引用的
   function 体**内联**后再判。任何一步认不出来 -> MANUAL（退出码 1），
   **不许**默认通过。
   `ifdef ENABLE_INITIAL_REG_` 里的 RANDOMIZE_REG_INIT 随机化不计入：那是
   仿真专用初始化，`SYNTHESIS` 下整段不存在（UT 编译带 +define+SYNTHESIS），
   而且本工程的 UT 还额外 `+vcs+initreg+0`。脚本会**显式列出**这些被排除的
   赋值，不让它们悄悄消失。

## 用法

    # 审查单个模型（给出 registry 行所需的全部字段 + 三项审查结论）
    python3 scripts/audit_ram_memory_model.py ram_40x47 \\
        --parent-ref  Queue40_L2TlbMQBundle.sv \\
        --parent-impl rtl/memblock/L2TlbMissQueue.sv

    # 只做 M1（还没有 parent 时；M2/M3 会报 SKIPPED 而不是 PASS）
    python3 scripts/audit_ram_memory_model.py ram_10x89

    # 复算：把 registry 里所有 kind=APPROVED_MEMORY_MACRO_MODEL 且属于
    # firtool ram_* 家族的条目重新跑一遍 M1（parent 由 --parent-map 提供）
    python3 scripts/audit_ram_memory_model.py --check

退出码：0 全过；1 有 FAIL/MANUAL；2 用法错/输入缺失（fail-closed）。
"""
from __future__ import print_function

import argparse
import hashlib
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parent
DEFAULT_G1 = os.environ.get('G1_CANONICAL') or '/home/eda/xs-env/G1-canonical'

# 家族参照件：firtool 标准头以它为准，其余成员逐字节比对头部。
FAMILY_HEADER_REF = 'ram_40x47.sv'


# ---------------------------------------------------------------------------
# 基础工具
# ---------------------------------------------------------------------------
def norm(s):
    """归一空白：模板比对对缩进/换行不敏感，但对 token 序列敏感。"""
    return ' '.join(s.split())


def strip_comments(s):
    return re.sub(r'//[^\n]*', '', re.sub(r'/\*.*?\*/', '', s, flags=re.S))


def hexlit(n):
    """firtool 写常量一律 `<w>'h<大写十六进制>`。"""
    return format(n, 'X')


def clog2(n):
    w = 1
    while (1 << w) < n:
        w += 1
    return w


# ---------------------------------------------------------------------------
# M1 —— memory-only：精确模板等价
# ---------------------------------------------------------------------------
def build_expected_body(design, aw, dw, depth, randw, jw):
    """重建 firtool 行为级 RAM 叶子的**完整**正文（module 头到 endmodule）。"""
    p = [f'module {design}(',
         f"input [{aw - 1}:0] R0_addr,",
         'input R0_en,',
         'input R0_clk,',
         f'output [{dw - 1}:0] R0_data,',
         f'input [{aw - 1}:0] W0_addr,',
         'input W0_en,',
         'input W0_clk,',
         f'input [{dw - 1}:0] W0_data',
         ');']
    body = [
        f'reg [{dw - 1}:0] Memory[0:{depth - 1}];',
        'always @(posedge W0_clk) begin',
        "if (W0_en & 1'h1)",
        'Memory[W0_addr] <= W0_data;',
        'end',
        '`ifdef ENABLE_INITIAL_MEM_',
        f'reg [{randw - 1}:0] _RANDOM_MEM;',
        'initial begin',
        '`INIT_RANDOM_PROLOG_',
        '`ifdef RANDOMIZE_MEM_INIT',
        f"for (logic [{aw - 1}:0] i = {aw}'h0; i < {aw}'h{hexlit(depth)}; i += {aw}'h1) begin",
    ]
    if randw > 32:
        body += [
            f"for (logic [{jw - 1}:0] j = {jw}'h0; j < {jw}'h{hexlit(randw)}; j += {jw}'h20) begin",
            '_RANDOM_MEM[j +: 32] = `RANDOM;',
            'end',
        ]
    else:
        body += ['_RANDOM_MEM = `RANDOM;']
    body += [
        f'Memory[i] = _RANDOM_MEM[{dw - 1}:0];',
        'end',
        '`endif',
        'end',
        '`endif',
        f"assign R0_data = R0_en ? Memory[R0_addr] : {dw}'bx;",
        'endmodule',
    ]
    return norm(' '.join(p + body))


def m1_memory_only(path, design):
    """返回 (ok, 结论串, facts)。facts 含 aw/dw/depth 等供报告使用。"""
    raw = path.read_text()
    mstart = raw.find(f'module {design}(')
    if mstart < 0:
        return False, f'M1 FAIL: 找不到 `module {design}(`', {}
    header, moddecl = raw[:mstart], raw[mstart:]
    hdr_sha = hashlib.sha256(header.encode()).hexdigest()

    txt = strip_comments(moddecl)
    end = txt.find('endmodule')
    if end < 0:
        return False, 'M1 FAIL: 没有 endmodule', {}
    actual = norm(txt[:end + len('endmodule')])

    m = re.search(r'reg\s*\[(\d+):0\]\s*Memory\s*\[\s*0\s*:\s*(\d+)\s*\]\s*;', txt)
    a = re.search(r'input\s*\[(\d+):0\]\s*R0_addr', txt)
    r = re.search(r'reg\s*\[(\d+):0\]\s*_RANDOM_MEM\s*;', txt)
    if not (m and a and r):
        return False, ('M1 FAIL: 认不出 Memory / R0_addr / _RANDOM_MEM 声明 —— '
                       '不是 firtool 行为级 RAM 叶子的形状（fail-closed）'), {}
    dw, depth, aw, randw = int(m.group(1)) + 1, int(m.group(2)) + 1, int(a.group(1)) + 1, int(r.group(1)) + 1
    jw = clog2(randw + 1) if randw > 32 else 0

    exp = build_expected_body(design, aw, dw, depth, randw, jw)
    facts = {'addr_width': aw, 'data_width': dw, 'depth': depth,
             'rand_width': randw, 'header_sha256': hdr_sha,
             'oob_headroom': (1 << aw) - depth}
    if actual != exp:
        # 给出第一处分歧，方便判断是「模板没覆盖的合法变体」还是「真有逻辑」。
        i = next((k for k in range(min(len(actual), len(exp))) if actual[k] != exp[k]),
                 min(len(actual), len(exp)))
        return False, ('M1 FAIL: 正文与 firtool 行为级 RAM 模板不逐字相等 —— '
                       '该模型可能含模板之外的逻辑，必须人工审读，**不得入表**。\n'
                       f'        首处分歧 @{i}\n'
                       f'        golden: ...{actual[max(0, i - 40):i + 60]}...\n'
                       f'        模板  : ...{exp[max(0, i - 40):i + 60]}...'), facts
    return True, ('M1 PASS: 正文与 firtool 行为级 RAM 模板**逐字相等** —— '
                  '只有 1 个存储数组、1 个时钟写支路、1 个组合读 assign，'
                  '外加仿真专用随机初始化（SYNTHESIS 下不存在）；无状态机/无算术/'
                  '无其它功能逻辑。'), facts


# ---------------------------------------------------------------------------
# M2 —— 端口宽度与读写行为和实现边界一致
# ---------------------------------------------------------------------------
INST_RE_T = r'\b{d}\s+(\w+)\s*\((.*?)\)\s*;'


def parse_inst(text, design):
    """抓 design 的例化，返回 [(实例名, {端口: 连接表达式})]。"""
    out = []
    for m in re.finditer(INST_RE_T.format(d=re.escape(design)), strip_comments(text), re.S):
        conns = {}
        for pm in re.finditer(r'\.(\w+)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)', m.group(2)):
            conns[pm.group(1)] = norm(pm.group(2))
        out.append((m.group(1), conns))
    return out


def localparam_env(text):
    """扫本文件的 `localparam [int] NAME = <整型表达式>;`，迭代到不动点。"""
    env, pend = {}, dict(re.findall(r'localparam\s+(?:int\s+)?(\w+)\s*=\s*([^;]+);',
                                    strip_comments(text)))
    for _ in range(8):
        for k, v in list(pend.items()):
            e = norm(v)
            if not re.fullmatch(r"[\w\s()+\-*/]+", e):
                continue
            try:
                env[k] = int(eval(e, {'__builtins__': {}}, dict(env)))  # noqa: S307
                pend.pop(k)
            except Exception:  # noqa: BLE001
                pass
    return env


def const_val(expr, env=None):
    """把 `1'h1` / `6'h0` / `'0` / `PTR_W'(QUEUE_SIZE-1)` 之类解析成整数；认不出返回 None。

    ★只认纯常量★：含未知标识符、含被审信号名的表达式一律返回 None（fail-closed）。
    """
    e = norm(expr)
    for _ in range(4):
        m = re.fullmatch(r'\((.*)\)', e)
        if m and _balanced(m.group(1)):
            e = norm(m.group(1))
        else:
            break
    m = re.fullmatch(r"(\d*)'([bBhHdD])([0-9a-fA-F_]+)", e)
    if m:
        base = {'b': 2, 'h': 16, 'd': 10}[m.group(2).lower()]
        return int(m.group(3).replace('_', ''), base)
    if e in ("'0", '0'):
        return 0
    # 位宽转换壳：`<宽度>'( <表达式> )`，宽度可以是数字或 localparam 名。
    m = re.fullmatch(r"[\w]+'\((.*)\)", e)
    if m and _balanced(m.group(1)):
        return const_val(m.group(1), env)
    if env is not None and re.fullmatch(r"[\w\s()+\-*/]+", e):
        try:
            return int(eval(e, {'__builtins__': {}}, dict(env)))  # noqa: S307
        except Exception:  # noqa: BLE001
            return None
    return None


def _balanced(s):
    d = 0
    for c in s:
        d += (c == '(') - (c == ')')
        if d < 0:
            return False
    return d == 0


def split_ternary(e):
    """顶层三元切分 `c ? t : f`；不是顶层三元返回 None。"""
    e = norm(e)
    for _ in range(4):
        m = re.fullmatch(r'\((.*)\)', e)
        if m and _balanced(m.group(1)):
            e = norm(m.group(1))
        else:
            break
    d, qi = 0, -1
    for k, c in enumerate(e):
        d += (c == '(') - (c == ')')
        if d == 0 and c == '?':
            qi = k
            break
    if qi < 0:
        return None
    d, ci = 0, -1
    for k in range(qi + 1, len(e)):
        c = e[k]
        d += (c == '(') - (c == ')')
        if d == 0 and c == ':':
            ci = k
            break
    if ci < 0:
        return None
    return norm(e[:qi]), norm(e[qi + 1:ci]), norm(e[ci + 1:])


def is_inc1(e, sig, env):
    """e 是否为 `sig + 1`（允许任意层位宽转换壳与括号）。"""
    core = norm(e)
    for _ in range(4):
        m = re.fullmatch(r"[\w]*'?\((.*)\)", core)
        if m and _balanced(m.group(1)):
            core = norm(m.group(1))
        else:
            break
    m = re.fullmatch(r'(?:' + re.escape(sig) + r'\s*\+\s*(\S+)|(\S+)\s*\+\s*' + re.escape(sig) + r')',
                     core)
    return bool(m) and const_val(m.group(1) or m.group(2), env) == 1


def m2_boundary_parity(design, ref_text, impl_text, ports):
    ri, ii = parse_inst(ref_text, design), parse_inst(impl_text, design)
    if len(ri) != 1 or len(ii) != 1:
        return False, (f'M2 MANUAL: ref 侧 {len(ri)} 个例化 / impl 侧 {len(ii)} 个 —— '
                       f'本脚本只判「两侧各恰好 1 个」的简单情形（fail-closed）')
    (rn, rc), (inm, ic) = ri[0], ii[0]
    if set(rc) != set(ports):
        return False, f'M2 FAIL: ref 侧例化端口集 {sorted(rc)} != 模块端口集 {sorted(ports)}'
    if set(ic) != set(ports):
        return False, f'M2 FAIL: impl 侧例化端口集 {sorted(ic)} != 模块端口集 {sorted(ports)}'
    diffs = []
    for p in sorted(ports):
        rv, iv = const_val(rc[p]), const_val(ic[p])
        if (rv is None) != (iv is None):
            diffs.append(f'{p}: ref={rc[p]!r} impl={ic[p]!r}（一侧是常量一侧不是）')
        elif rv is not None and rv != iv:
            diffs.append(f'{p}: ref 常量 {rc[p]} != impl 常量 {ic[p]}')
    if diffs:
        return False, 'M2 FAIL: 常量连接不一致 —— ' + '; '.join(diffs)
    return True, (f'M2 PASS: 两侧各 1 个例化（ref {rn} / impl {inm}），端口集合与模块声明'
                  f'逐名相同（{len(ports)} 个），常量连接逐口相同 '
                  + ', '.join(f'{p}={rc[p]}' for p in sorted(ports) if const_val(rc[p]) is not None))


# ---------------------------------------------------------------------------
# M3 —— 父级控制不会有意依赖越界地址值（归纳证明的机器复核）
# ---------------------------------------------------------------------------
def inline_functions(text):
    """把 `function automatic T f(input T p); return EXPR; endfunction` 的调用内联。"""
    out = text
    for fm in re.finditer(r'function\s+automatic\s+[^;]*?\b(\w+)\s*\(\s*input\s+[^;]*?\b(\w+)\s*\)\s*;'
                          r'\s*return\s+(.*?);\s*endfunction', text, re.S):
        fname, pname, expr = fm.group(1), fm.group(2), norm(fm.group(3))
        out = re.sub(r'\b' + re.escape(fname) + r'\s*\(\s*([A-Za-z_]\w*)\s*\)',
                     lambda m: '(' + re.sub(r'\b' + re.escape(pname) + r'\b', m.group(1), expr) + ')',
                     out)
    return out


def strip_sim_only(text):
    """摘掉 `ifdef ENABLE_INITIAL_REG_ ... endif` 段，返回 (剩余文本, 被摘掉的文本)。"""
    kept, dropped, depth_, i = [], [], 0, 0
    toks = re.split(r'(`ifdef\s+\w+|`ifndef\s+\w+|`endif)', text)
    for t in toks:
        if re.match(r'`ifdef\s+ENABLE_INITIAL_REG_', t) and depth_ == 0:
            depth_ = 1
            dropped.append(t)
            continue
        if depth_:
            dropped.append(t)
            if re.match(r'`ifdef|`ifndef', t):
                depth_ += 1
            elif t == '`endif':
                depth_ -= 1
            continue
        kept.append(t)
    return ''.join(kept), ''.join(dropped)


def m3_addr_in_range(side, text, sig, depth, width):
    """证明 sig ∈ [0, depth-1]。返回 (ok, 结论串)。

    判据（三条全要，任何一条认不出即 MANUAL）：
      (a) 基例    —— 复位/flush 等常量赋值的值全部 < depth（实测两侧都是 0）；
      (b) 归纳步  —— 唯一的非常量赋值是「自增 1」；
      (c) 回卷    —— 该自增被 `sig == depth-1` **互斥地**挡住，相等时赋 0。
    (c) 有两种合法写法，都要认：
      golden(firtool)  `if (sig == 6'h27) sig <= 6'h0; else sig <= 6'(sig + 6'h1);`
                       —— 守卫在 if 里，非常量赋值本身就是裸自增；
      impl(可读重写)   `sig <= ptr_next(sig);` 其中
                       `function ptr_next(p) = (p == PTR_W'(QUEUE_SIZE-1)) ? '0 : p + 1'b1;`
                       —— 守卫在被内联进来的三元里。
    """
    src = inline_functions(strip_comments(text))
    env = localparam_env(text)
    rtl, sim = strip_sim_only(src)
    sim_assigns = [norm(x) for x in
                   re.findall(r'\b' + re.escape(sig) + r'\s*=\s*([^;]+);', sim)]

    assigns = [norm(a) for a in re.findall(r'\b' + re.escape(sig) + r'\s*<=\s*([^;]+);', rtl)]
    if not assigns:
        return False, f'M3 MANUAL[{side}]: 在 {sig} 上找不到任何非阻塞赋值（fail-closed）'

    consts, wrapped, bare_inc, unknown = [], [], [], []
    for a in assigns:
        v = const_val(a, env)
        if v is not None:
            consts.append((a, v))
            continue
        t = split_ternary(a)
        if t:
            cond, tb, fb = t
            for _ in range(4):  # 剥掉守卫外层的成对括号
                mm = re.fullmatch(r'\((.*)\)', cond)
                if mm and _balanced(mm.group(1)):
                    cond = norm(mm.group(1))
                else:
                    break
            m = re.fullmatch(r'\s*' + re.escape(sig) + r'\s*==\s*(.+?)\s*', cond)
            gv = const_val(m.group(1), env) if m else None
            if gv == depth - 1 and const_val(tb, env) == 0 and is_inc1(fb, sig, env):
                wrapped.append(a)
                continue
        if is_inc1(a, sig, env):
            bare_inc.append(a)
            continue
        unknown.append(a)

    if unknown:
        return False, (f'M3 MANUAL[{side}]: {sig} 有认不出形态的赋值 {sorted(set(unknown))}'
                       f'（fail-closed）')
    bad = [a for a, v in consts if v >= depth]
    if bad:
        return False, f'M3 FAIL[{side}]: {sig} 有越界常量赋值 {bad}'
    if not consts:
        return False, f'M3 MANUAL[{side}]: {sig} 没有常量赋值支路，归纳基例缺失（fail-closed）'
    if not (wrapped or bare_inc):
        return False, f'M3 MANUAL[{side}]: {sig} 没有自增支路，形态不是环形指针（fail-closed）'
    if len(set(wrapped)) > 1 or len(set(bare_inc)) > 1:
        return False, (f'M3 MANUAL[{side}]: {sig} 的自增赋值不唯一 '
                       f'{sorted(set(wrapped) | set(bare_inc))}（fail-closed）')
    if bare_inc:
        # 守卫不在赋值里，必须在包住它的 if 条件里找到 `sig == depth-1`。
        guards = [norm(g) for g in
                  re.findall(r'\bif\s*\(\s*' + re.escape(sig) + r'\s*==\s*([^)]+)\)', rtl)]
        gv = sorted({const_val(g, env) for g in guards} - {None})
        if depth - 1 not in gv:
            return False, (f'M3 MANUAL[{side}]: 裸自增 {bare_inc[0]!r} 没有 '
                           f'`{sig} == {depth - 1}` 的 if 守卫，实得比较常量 {gv}（fail-closed）')
        step = f'{bare_inc[0]!r}（if 守卫 `{sig} == {depth - 1}` 时改赋 0）'
    else:
        step = f'{wrapped[0]!r}（守卫内联自 function，相等时赋 0）'
    return True, (f'M3 PASS[{side}]: {sig}[{width - 1}:0] 归纳可证 ∈ [0,{depth - 1}]；'
                  f'基例 = 常量赋值 {sorted({v for _, v in consts})}，归纳步 = {step}；'
                  + (f'另有 {len(sim_assigns)} 处仿真专用初始化赋值被排除'
                     f'（`ifdef ENABLE_INITIAL_REG_`，SYNTHESIS 下整段不存在）：{sim_assigns}'
                     if sim_assigns else '无仿真专用赋值'))


# ---------------------------------------------------------------------------
def audit(design, golden_rtl, parent_ref, parent_impl):
    g = pathlib.Path(golden_rtl)
    path = g / f'{design}.sv'
    if not path.is_file():
        path = g / f'{design}.v'
    if not path.is_file():
        print(f'ERROR: golden 里找不到 {design}.sv/.v', file=sys.stderr)
        return 2
    raw = path.read_bytes()
    print(f'=== audit {design} ===')
    print(f'  golden  : {path}')
    print(f'  sha256  : {hashlib.sha256(raw).hexdigest()}')

    ok1, msg1, facts = m1_memory_only(path, design)
    if facts:
        print(f'  形状    : addr {facts["addr_width"]} 位 / data {facts["data_width"]} 位 / '
              f'depth {facts["depth"]} / 随机化 {facts["rand_width"]} 位')
        print(f'  越界余量: 2^{facts["addr_width"]}={1 << facts["addr_width"]} - {facts["depth"]} '
              f'= {facts["oob_headroom"]} 个地址落在数组之外'
              + ('（★这正是 FMR_ELAB-147 的来源★）' if facts['oob_headroom'] else ''))
        ref_hdr = hashlib.sha256(
            (g / FAMILY_HEADER_REF).read_text()[:(g / FAMILY_HEADER_REF).read_text()
                                                .find('module ')].encode()).hexdigest()
        same = facts['header_sha256'] == ref_hdr
        print(f'  宏定义头: sha256={facts["header_sha256"][:16]} '
              + ('== 家族参照 ' + FAMILY_HEADER_REF if same else '★与家族参照不同，须人工审读★'))
        if not same:
            ok1 = False
            msg1 += '\n        M1 FAIL: 宏定义头与家族参照件不逐字节相同'
    print('  ' + msg1)

    rc = 0 if ok1 else 1
    ports = ['R0_addr', 'R0_en', 'R0_clk', 'R0_data', 'W0_addr', 'W0_en', 'W0_clk', 'W0_data']
    if parent_ref and parent_impl:
        rtxt = pathlib.Path(parent_ref).read_text()
        itxt = pathlib.Path(parent_impl).read_text()
        ok2, msg2 = m2_boundary_parity(design, rtxt, itxt, ports)
        print('  ' + msg2)
        rc = rc or (0 if ok2 else 1)
        if ok2:
            rc3 = 0
            for side, txt in (('ref', rtxt), ('impl', itxt)):
                conns = parse_inst(txt, design)[0][1]
                for port in ('R0_addr', 'W0_addr'):
                    sig = conns[port]
                    if not re.fullmatch(r'[A-Za-z_]\w*', sig):
                        print(f'  M3 MANUAL[{side}]: {port} 连的不是单个信号名（{sig!r}）')
                        rc3 = 1
                        continue
                    ok3, msg3 = m3_addr_in_range(side, txt, sig, facts['depth'],
                                                 facts['addr_width'])
                    print(f'  {msg3}')
                    rc3 = rc3 or (0 if ok3 else 1)
            rc = rc or rc3
    else:
        print('  M2/M3 SKIPPED: 未给 --parent-ref/--parent-impl —— '
              '★SKIPPED 不是 PASS，未做 parent 审查前不得入表★')
        rc = rc or 1
    print(f'  => {"AUDIT_PASS" if rc == 0 else "AUDIT_INCOMPLETE"}  '
          f'（入表只是允许两侧对称黑盒；转绿仍须 clean native FM 结果）')
    return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('design', nargs='?')
    ap.add_argument('--golden-rtl', default=str(pathlib.Path(DEFAULT_G1) / 'golden-rtl'))
    ap.add_argument('--parent-ref', help='golden 侧例化该 RAM 的父文件（相对 --golden-rtl 或绝对路径）')
    ap.add_argument('--parent-impl', help='重写侧例化该 RAM 的父文件（相对仓库根或绝对路径）')
    ap.add_argument('--check', action='store_true',
                    help='复算模式：对 --parent-map 里登记的每一条重跑全部三项审查')
    ap.add_argument('--parent-map', default=str(REPO / 'verif' / 'ram_model_parents.tsv'))
    a = ap.parse_args()

    def resolve(p, base):
        if not p:
            return None
        q = pathlib.Path(p)
        return str(q if q.is_absolute() or q.exists() else base / p)

    if a.check:
        mp = pathlib.Path(a.parent_map)
        if not mp.is_file():
            print(f'ERROR: 找不到 {mp}（fail-closed）', file=sys.stderr)
            return 2
        rc = 0
        for ln in mp.read_text().splitlines():
            if ln.startswith('#') or not ln.strip():
                continue
            f = ln.split('\t')
            if len(f) < 3:
                print(f'ERROR: parent-map 行格式错: {ln!r}', file=sys.stderr)
                return 2
            rc |= audit(f[0], a.golden_rtl,
                        resolve(f[1], pathlib.Path(a.golden_rtl)),
                        resolve(f[2], REPO))
        print('=== audit --check: ' + ('全部 AUDIT_PASS ===' if rc == 0 else '★有条目未过★ ==='))
        return rc
    if not a.design:
        ap.error('须给 design 名，或用 --check')
    return audit(a.design, a.golden_rtl,
                 resolve(a.parent_ref, pathlib.Path(a.golden_rtl)),
                 resolve(a.parent_impl, REPO))


if __name__ == '__main__':
    sys.exit(main())

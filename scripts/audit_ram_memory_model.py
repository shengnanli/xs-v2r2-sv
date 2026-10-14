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

## 2026-09-27 扩展（DiffRatStateBuffer 的两个叶子逼出来的，判据强度不降）

M1 模板支持 **N 个写口**（firtool 对多写口 RAM 的形状：同一个 `always @(posedge W0_clk)`
   里 W0..W{N-1} 顺序非阻塞写，后口赢；每口 addr/en/clk/data 四个端口）。写口数从模块
   端口现读，模板仍是逐字重建 + 逐字比对，不是放宽。
M2 支持 **每侧多于 1 个例化**：按「设计名的**展开后**实例数」比（impl 用 generate-for
   数组时，把 `for (genvar k = A; k < B; k++)` 的次数乘进去，嵌套相乘，B-A 必须能由
   localparam 静态求值，否则 MANUAL），并要求两侧「每个实例的常量连接签名」多重集相等。
M3 新增形态 B「输入偏移地址」（形态 A 环形指针归纳证明原样保留，先试 A 再试 B）：
   地址口经纯组合线/纯函数内联后**逐字**匹配 `{1'b0, V} + (F ? K : 0)`，V/F 必须是被审
   模块的 **input 端口**（或 input struct 端口的字段，宽度从 typedef 现读），表达式里
   除 V/F/常量外不得含任何别的标识符（即没有任何内部状态参与地址）。这种形态里
   「不越界」在模块内部**不可证**（V 是外部给的），只能是接口契约：所以形态 B 要求
   parent 对照表第 4 列显式写 `value<Vmax`，脚本核 `Vmax + K <= depth` 且 `2^w <= depth`
   （w = V 的位宽，保证 F=0 时任何 V 都不越界），并把每个 V/F 的名字打印出来供人核对
   那个契约到底指的是什么。结论标 **PASS_INPUT_CONTRACT**，不冒充无条件 PASS；
   没写契约 -> MANUAL。这满足 codex 0158 M3 的原话「父级控制不会**有意**依赖越界地址值」
   ——地址是输入的纯函数，没有任何逻辑去利用越界值。

## 2026-10-14 扩展（codex 0230 问题 1，dt_pcTransType_160x2 逼出来的，判据强度不降）

M1 模板支持 **N 个读口**：端口表里 R0..R{N-1} 依次排在全部写口之前（每口 addr/en/clk/data），
   正文末尾按 R0..R{N-1} 顺序各一条 `assign Rk_data = Rk_en ? Memory[Rk_addr] : <dw>'bx;`。
   读口数从模块端口现读，编号必须 0..N-1 连续；模板仍是**逐字**重建 + 逐字比对（读口错接地址、
   assign 乱序/缺条、读口夹在写口之间、写序颠倒都当场不等）。N=1 时生成的模板与原 1R 模板
   逐字相同，既有条目的 `--check` 输出逐字节不变。M2 的端口集合随之含 R0..R{N-1}。
   ★M3 形态未扩★：0230 只授权扩 M1 模板；地址驱动形态认不出照旧 MANUAL。
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
def build_expected_body(design, aw, dw, depth, randw, jw, nw=1, nr=1):
    """重建 firtool 行为级 RAM 叶子的**完整**正文（module 头到 endmodule）。

    nw = 写口数。firtool 对多写口的形状：全部写口共用 W0_clk 的一个 always 块，
    W0..W{nw-1} 顺序非阻塞赋值（同址后口赢）。
    nr = 读口数（codex 0230 问题 1）。firtool 对多读口的形状：端口表里 R0..R{nr-1} 依次
    排在全部写口之前，每口 addr/en/clk/data 四个端口；正文末尾按 R0..R{nr-1} 顺序各一条
    `assign Rk_data = Rk_en ? Memory[Rk_addr] : <dw>'bx;`。nr=1 时与原 1R 模板逐字相同。"""
    p = [f'module {design}(']
    for k in range(nr):
        p += [f"input [{aw - 1}:0] R{k}_addr,",
              f'input R{k}_en,',
              f'input R{k}_clk,',
              f'output [{dw - 1}:0] R{k}_data,']
    for i in range(nw):
        p += [f'input [{aw - 1}:0] W{i}_addr,',
              f'input W{i}_en,',
              f'input W{i}_clk,',
              f'input [{dw - 1}:0] W{i}_data' + (',' if i < nw - 1 else '')]
    p += [');']
    body = [
        f'reg [{dw - 1}:0] Memory[0:{depth - 1}];',
        'always @(posedge W0_clk) begin']
    for i in range(nw):
        body += [f"if (W{i}_en & 1'h1)", f'Memory[W{i}_addr] <= W{i}_data;']
    body += ['end',
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
    ]
    body += [f"assign R{k}_data = R{k}_en ? Memory[R{k}_addr] : {dw}'bx;" for k in range(nr)]
    body += ['endmodule']
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
    # 写口数从端口现读：W<i>_addr 必须恰好是 0..nw-1 连续编号，否则认不出（fail-closed）。
    widx = sorted({int(x) for x in re.findall(r'input\s*\[\d+:0\]\s*W(\d+)_addr', txt)})
    if not widx or widx != list(range(len(widx))):
        return False, f'M1 FAIL: 写口编号 {widx} 不是 0..N-1 连续（fail-closed）', {}
    nw = len(widx)
    # 读口数同样从端口现读：R<k>_addr 必须恰好是 0..nr-1 连续编号（fail-closed）。
    ridx = sorted({int(x) for x in re.findall(r'input\s*\[\d+:0\]\s*R(\d+)_addr', txt)})
    if not ridx or ridx != list(range(len(ridx))):
        return False, f'M1 FAIL: 读口编号 {ridx} 不是 0..N-1 连续（fail-closed）', {}
    nr = len(ridx)

    exp = build_expected_body(design, aw, dw, depth, randw, jw, nw, nr)
    facts = {'addr_width': aw, 'data_width': dw, 'depth': depth, 'n_write': nw, 'n_read': nr,
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
                  f'只有 1 个存储数组、1 个时钟写 always（{nw} 个写口顺序非阻塞赋值'
                  + ('，同址后口赢' if nw > 1 else '') + '）、'
                  + (f'{nr} 个组合读 assign（R0..R{nr - 1}），' if nr > 1 else '1 个组合读 assign，')
                  + '外加仿真专用随机初始化（SYNTHESIS 下不存在）；无状态机/无算术/'
                  '无其它功能逻辑。'), facts


# ---------------------------------------------------------------------------
# M2 —— 端口宽度与读写行为和实现边界一致
# ---------------------------------------------------------------------------
INST_RE_T = r'\b{d}\s+(\w+)\s*\((.*?)\)\s*;'


def parse_inst(text, design):
    """抓 design 的例化，返回 [(实例名, {端口: 连接表达式})]（文本序；不含 generate 倍数）。"""
    return [(n, c) for n, c, _ in parse_inst_pos(text, design)]


def parse_inst_pos(text, design):
    """同 parse_inst，但多返回例化在**去注释文本**里的起始位置（供 generate 倍数与所属模块定位）。"""
    out = []
    for m in re.finditer(INST_RE_T.format(d=re.escape(design)), strip_comments(text), re.S):
        conns = {}
        for pm in re.finditer(r'\.(\w+)\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)', m.group(2)):
            conns[pm.group(1)] = norm(pm.group(2))
        out.append((m.group(1), conns, m.start()))
    return out


def _block_end(text, begin_pos):
    """text[begin_pos:] 以 `begin` 开头；返回与之配对的 `end` 之后的位置；配不上返回 None。"""
    depth_ = 0
    for m in re.finditer(r'\b(begin|end)\b', text[begin_pos:]):
        depth_ += 1 if m.group(1) == 'begin' else -1
        if depth_ == 0:
            return begin_pos + m.end()
    return None


def generate_multiplicity(text, pos, env):
    """pos 处的例化被几层 `for (genvar i = A; i < B; i++) begin ... end` 包住，返回各层次数之积。

    B-A 必须能由 localparam 静态求值；认不出返回 None（fail-closed）。
    只认 `<` 与 `i++`/`i = i + 1` 的最简形态。"""
    src = strip_comments(text)
    mult = 1
    for m in re.finditer(r'for\s*\(\s*genvar\s+(\w+)\s*=\s*([^;]+);\s*\1\s*<\s*([^;]+);'
                         r'\s*(?:\1\s*\+\+|\1\s*=\s*\1\s*\+\s*1)\s*\)\s*begin', src):
        e = _block_end(src, m.end() - len('begin'))
        if e is None:
            return None
        if m.start() < pos < e:
            lo, hi = const_val(m.group(2), env), const_val(m.group(3), env)
            if lo is None or hi is None or hi <= lo:
                return None
            mult *= hi - lo
    return mult


def module_region(text, pos):
    """返回包住 pos 的 `module NAME ... endmodule` 区段 (name, 区段文本)；找不到返回 (None, 全文)。"""
    src = strip_comments(text)
    for m in re.finditer(r'\bmodule\s+(\w+)', src):
        e = src.find('endmodule', m.end())
        if e < 0:
            break
        if m.start() <= pos < e:
            return m.group(1), src[m.start():e]
    return None, src


def localparam_env(text):
    """扫本文件的 `localparam [int] NAME = <整型表达式>;`，迭代到不动点。"""
    env, pend = {}, dict(re.findall(r'localparam\s+(?:int\s+(?:unsigned\s+)?|integer\s+)?(\w+)\s*=\s*([^;]+);',
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


def _inst_signature(conns, ports, env=None):
    """一个实例的「常量连接签名」：((端口, 常量值或 None), …)。"""
    return tuple((p, const_val(conns[p], env)) for p in sorted(ports))


def m2_boundary_parity(design, ref_text, impl_text, ports):
    """两侧按设计名的**展开后**实例数相等，每个实例端口集 == 模块端口集，
    且两侧「每实例常量连接签名」的多重集相等。返回 (ok, 结论串, ref_insts, impl_insts)，
    insts = [(实例名, conns, 倍数)]。"""
    sides = {}
    for side, text in (('ref', ref_text), ('impl', impl_text)):
        env = localparam_env(text)
        insts = []
        for name, conns, pos in parse_inst_pos(text, design):
            mult = generate_multiplicity(text, pos, env)
            if mult is None:
                return False, (f'M2 MANUAL: {side} 侧例化 {name} 所在 generate-for 的次数无法静态求值'
                               f'（fail-closed）'), [], []
            if set(conns) != set(ports):
                return False, (f'M2 FAIL: {side} 侧例化 {name} 端口集 {sorted(conns)} '
                               f'!= 模块端口集 {sorted(ports)}'), [], []
            insts.append((name, conns, mult))
        if not insts:
            return False, f'M2 MANUAL: {side} 侧找不到 {design} 的例化（fail-closed）', [], []
        sides[side] = (env, insts)
    (renv, ri), (ienv, ii) = sides['ref'], sides['impl']
    nr, ni = sum(m for _, _, m in ri), sum(m for _, _, m in ii)
    if nr != ni:
        return False, (f'M2 FAIL: 展开后实例数不等 —— ref {nr} 个 / impl {ni} 个'
                       f'（ref {[(n, m) for n, _, m in ri]}，impl {[(n, m) for n, _, m in ii]}）'), ri, ii
    from collections import Counter
    rsig = Counter()
    for _, c, m in ri:
        rsig[_inst_signature(c, ports, renv)] += m
    isig = Counter()
    for _, c, m in ii:
        isig[_inst_signature(c, ports, ienv)] += m
    if rsig != isig:
        only_r = [k for k in rsig if rsig[k] != isig.get(k, 0)]
        only_i = [k for k in isig if isig[k] != rsig.get(k, 0)]
        show = lambda sig: '{' + ', '.join(f'{p}={v}' for p, v in sig if v is not None) + '}'  # noqa: E731
        return False, ('M2 FAIL: 两侧「每实例常量连接签名」多重集不等 —— '
                       f'ref 独有 {[show(k) + "x" + str(rsig[k]) for k in only_r]}；'
                       f'impl 独有 {[show(k) + "x" + str(isig[k]) for k in only_i]}'), ri, ii
    consts = sorted({f'{p}={v}' for sig in rsig for p, v in sig if v is not None})
    return True, (f'M2 PASS: 两侧展开后各 {nr} 个例化'
                  f'（ref {[(n, m) for n, _, m in ri]} / impl {[(n, m) for n, _, m in ii]}），'
                  f'每个实例端口集合与模块声明逐名相同（{len(ports)} 个），'
                  f'两侧每实例常量连接签名多重集相等；出现的常量连接 {consts}'), ri, ii


# ---------------------------------------------------------------------------
# M3 —— 父级控制不会有意依赖越界地址值（归纳证明的机器复核）
# ---------------------------------------------------------------------------
def _split_top(s, sep=','):
    out, d, cur = [], 0, []
    for c in s:
        if c in '([{':
            d += 1
        elif c in ')]}':
            d -= 1
        if c == sep and d == 0:
            out.append(''.join(cur))
            cur = []
        else:
            cur.append(c)
    out.append(''.join(cur))
    return [norm(x) for x in out]


def inline_functions(text, defs=None):
    """把 `function automatic T f(input T1 p1, input T2 p2, …); return EXPR; endfunction` 的调用内联。

    只认「单条 return 表达式」的纯函数；实参可以是任意不含顶层逗号的表达式。
    defs：函数定义所在文本（默认就是 text；可读核常把函数放在 package 里，
    与例化它的 module 区段不在一处，这时传整文件）。"""
    out = text
    for fm in re.finditer(r'function\s+automatic\s+[^;(]*?\b(\w+)\s*\(([^()]*)\)\s*;'
                          r'\s*return\s+(.*?);\s*endfunction', defs if defs is not None else text, re.S):
        fname, expr = fm.group(1), norm(fm.group(3))
        pnames = []
        for prm in _split_top(fm.group(2)):
            mm = re.search(r'(\w+)\s*$', prm)
            if not mm:
                pnames = None
                break
            pnames.append(mm.group(1))
        if not pnames:
            continue

        def _repl(m, pnames=pnames, expr=expr):
            args = _split_top(m.group(1))
            if len(args) != len(pnames):
                return m.group(0)
            e = expr
            for pn, av in zip(pnames, args):
                e = re.sub(r'\b' + re.escape(pn) + r'\b', lambda _m, av=av: av, e)
            return '(' + e + ')'
        out = re.sub(r'\b' + re.escape(fname) + r'\s*\(([^()]*(?:\([^()]*\)[^()]*)*)\)', _repl, out)
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
# M3 形态 B —— 输入偏移地址：addr = {1'b0, V} + (F ? K : 0)，V/F 为 input 端口
# ---------------------------------------------------------------------------
def _strip_shell(e):
    """剥掉最外层成对括号与 `<w>'( … )` 位宽转换壳（可多层）。"""
    e = norm(e)
    for _ in range(6):
        m = re.fullmatch(r"(?:[\w]+')?\((.*)\)", e)
        if m and _balanced(m.group(1)):
            e = norm(m.group(1))
        else:
            break
    return e


def resolve_comb_driver(region, expr, depth_=0):
    """把 expr（信号名 / 信号名[idx]）沿**纯组合**驱动链解析成最终表达式。

    认三种驱动：`wire [..] NAME = EXPR;`、`assign NAME = EXPR;`、always_comb 里的
    `NAME = EXPR;` / `NAME[i] = EXPR;`（阻塞赋值）。只要发现该名字有非阻塞赋值 `<=`，
    说明它是寄存器，立刻返回 (None, 原因)。驱动必须唯一（多条即 MANUAL）。
    不是纯名字（已经是表达式）就原样返回。"""
    e = _strip_shell(expr)
    m = re.fullmatch(r'([A-Za-z_]\w*)(?:\s*\[\s*(\w+)\s*\])?', e)
    if not m or depth_ > 6:
        return e, None
    name = m.group(1)
    if re.search(r'\b' + re.escape(name) + r'\b(?:\s*\[[^\]]*\])?\s*<=', region):
        return None, f'{name} 有非阻塞赋值（是寄存器，不是输入的纯函数）'
    drv = re.findall(r'(?:\bwire\b[^;=]*?|\bassign\b\s*)\b' + re.escape(name) + r'\s*=\s*([^;]+);', region)
    drv += re.findall(r'(?<![\w.])' + re.escape(name) + r'(?:\s*\[\s*\w+\s*\])?\s*=\s*([^;=][^;]*);',
                      # always_comb 阻塞赋值；排除 `==` 与声明行（声明行已被上一条抓走）
                      re.sub(r'\b(?:wire|logic|reg)\b[^;]*;', '', region))
    drv = sorted({norm(d) for d in drv})
    if not drv:
        return e, None          # 没有驱动 —— 大概率是端口，交给上层判
    if len(drv) > 1:
        return None, f'{name} 的组合驱动不唯一 {drv}'
    return resolve_comb_driver(region, drv[0], depth_ + 1)


def input_width(region, whole_text, name, env):
    """name 是本模块 input 端口（或 input struct 端口的字段 `X.f` / `X[i].f`）时返回位宽，否则 None。"""
    m = re.fullmatch(r'([A-Za-z_]\w*)(?:\s*\[\s*\w+\s*\])?(?:\.(\w+))?', name)
    if not m:
        return None
    base, field = m.group(1), m.group(2)
    pm = re.search(r'\binput\b\s*(?:logic\s+|wire\s+)?(?:(\w+)\s+)?(?:\[\s*([^\]]+?)\s*:\s*0\s*\]\s*)?'
                   + re.escape(base) + r'\s*[,)]', region)
    if not pm:
        return None
    if field is None:
        if pm.group(1) and pm.group(1) not in ('logic', 'wire'):
            return None          # 类型化端口却没取字段
        return const_val(pm.group(2), env) + 1 if pm.group(2) else 1
    tname = pm.group(1)
    if not tname:
        return None
    tm = re.search(r'typedef\s+struct\s+packed\s*\{(.*?)\}\s*' + re.escape(tname) + r'\s*;',
                   strip_comments(whole_text), re.S)
    if not tm:
        return None
    fm = re.search(r'\blogic\s*(?:\[\s*([^\]]+?)\s*:\s*0\s*\]\s*)?\b' + re.escape(field) + r'\b',
                   tm.group(1))
    if not fm:
        return None
    return const_val(fm.group(1), env) + 1 if fm.group(1) else 1


def m3_input_offset(side, text, region, expr, depth, contract):
    """形态 B。返回 (ok, 结论串, facts)。facts = {'V':…, 'F':…, 'K':…, 'w':…}。"""
    env = localparam_env(text)
    reg_i = inline_functions(region, strip_comments(text))
    final, why = resolve_comb_driver(reg_i, expr)
    if final is None:
        return False, f'M3 MANUAL[{side}]: 地址 {expr!r} —— {why}（fail-closed）', {}
    core = _strip_shell(final)
    m = re.fullmatch(r"\{\s*1'[bh]0\s*,\s*([^{}]+?)\s*\}\s*\+\s*\(\s*(.+?)\s*\?\s*(.+?)\s*:\s*(.+?)\s*\)", core)
    if not m:
        return False, (f'M3 MANUAL[{side}]: 地址 {expr!r} 解析到 {core!r}，既不是环形指针也不是 '
                       "`{1'b0, V} + (F ? K : 0)` 形态（fail-closed）"), {}
    V, F, k1, k0 = norm(m.group(1)), _strip_shell(m.group(2)), m.group(3), m.group(4)
    K, K0 = const_val(k1, env), const_val(k0, env)
    if K is None or K0 != 0:
        return False, f'M3 MANUAL[{side}]: 偏移常量认不出（K={k1!r}, K0={k0!r}）（fail-closed）', {}
    w = input_width(region, text, V, env)
    fw = input_width(region, text, F, env)
    if w is None or fw != 1:
        return False, (f'M3 MANUAL[{side}]: V={V!r}（宽 {w}）/ F={F!r}（宽 {fw}）不是本模块 input 端口'
                       f'或 input struct 端口字段（fail-closed）'), {}
    facts = {'V': V, 'F': F, 'K': K, 'w': w}
    if not contract:
        return False, (f'M3 MANUAL[{side}]: 地址 = {{1\'b0,{V}}} + ({F} ? {K} : 0)，V 是外部输入，'
                       f'不越界在模块内不可证；须在 parent 对照表第 4 列写明接口契约 `value<Vmax`'
                       f'（fail-closed）'), facts
    cm = re.match(r'value<(\d+)', contract)
    if not cm:
        return False, f'M3 MANUAL[{side}]: 契约 {contract!r} 不是 `value<Vmax…` 形态（fail-closed）', facts
    vmax = int(cm.group(1))
    if (1 << w) > depth:
        return False, (f'M3 FAIL[{side}]: F=0 时 V[{w - 1}:0] 可达 {(1 << w) - 1} >= depth {depth}，'
                       f'契约管不住 F=0 支路'), facts
    if vmax + K > depth:
        return False, (f'M3 FAIL[{side}]: 契约 value<{vmax} 下 F=1 时地址可达 {vmax - 1 + K} '
                       f'>= depth {depth}，契约不充分'), facts
    return True, (f'M3 PASS_INPUT_CONTRACT[{side}]: 地址 = {{1\'b0,{V}}} + ({F} ? {K} : 0)，'
                  f'V/F 均为本模块 input（V 宽 {w}），表达式不含任何内部状态；'
                  f'F=0 时最大 {(1 << w) - 1} < {depth}；F=1 时在契约 `{contract}` 下最大 '
                  f'{vmax - 1 + K} < {depth}。★这是接口契约下的结论，不是模块内的无条件证明★'), facts


def m3_any(side, text, region, expr, depth, width, contract):
    """先试形态 A（环形指针归纳），认不出再试形态 B（输入偏移 + 契约）。"""
    if re.fullmatch(r'[A-Za-z_]\w*', expr):
        okA, msgA = m3_addr_in_range(side, text, expr, depth, width)
        if okA:
            return True, msgA
    else:
        msgA = f'M3 MANUAL[{side}]: {expr!r} 不是单个信号名，形态 A 不适用'
    okB, msgB, _ = m3_input_offset(side, text, region, expr, depth, contract)
    if okB:
        return True, msgB
    return False, msgA + '\n  ' + msgB


# ---------------------------------------------------------------------------
# M3 MANUAL_REVIEWED —— 一次性人工复核的精确绑定（codex 0203 裁定 X）
#
# 只为 impl 侧的 M3 MANUAL（地址指针在共享核里、薄文件上认不出）提供一个**窄**出口：
#   · design 必须在下面的硬编码名单里（不读 tsv、不做模式匹配——不推广到其它 ram_*）；
#   · parent-map 第 5 列写 `<reviewer 消息号>;<path>=<sha256>;<path>=<sha256>…`，
#     消息号须形如 codex_NNNN 且 bridge outbox 里真有这条消息；
#   · 绑定文件必须**包含** parent_impl 本身，且每个文件当前字节的 sha256 精确相等——
#     任何一个字节变了就退回 MANUAL（fail-closed），须重新复核；
#   · 只放行 MANUAL，不放行 FAIL；ref 侧永远要机器 PASS。
MANUAL_REVIEW_DESIGNS = {
    'ram_10x89': 'codex_0202',   # GrantBuffer/Queue10_GrantBuffer_Anon；xs_ChiselQueue_core 指针归纳 ∈[0,9]
    'ram_78x15': 'codex_0210',   # Queue78_PCrdGranted；xs_ChiselQueue_core #(.DEPTH(78)) 指针归纳 ∈[0,77]
}
BRIDGE_OUTBOX = pathlib.Path('/home/eda/xs-env/.agent-bridge/outbox')


# ---------------------------------------------------------------------------
# 父级授权范围（codex 0206 D3）
#
# MANUAL_REVIEW_DESIGNS 只说「这个 design 的 M3 可以按人工复核放行」，**不说它能在哪些
# 父级里被两侧对称黑盒**。0202 的授权限于 GrantBuffer / Queue10_GrantBuffer_Anon 当前闭包；
# 0206 D3 把它显式扩到 Slice/Slice_1/Slice_2/Slice_3 四个父级，但只限这些父级里
# **已签 GrantBuffer 子树** grantBuf.pftRespQueue 下的同一个 ram_ext。
#
# 表项：design -> {父级 target: (授权消息号, 经由的已签 child, 父级内相对路径)}
#   via_child=None：父级就是 0202 原授权里的目标本身；
#   via_child='GrantBuffer'：须在父 commit 上验 GrantBuffer 的 tracked 证书仍然有效
#   （fm_verdict 做，因为那要 commit 上下文）。
# 父级内相对路径：ref 侧 r:/WORK/<T>/<rel>，impl 侧 i:/WORK/<T>/u_core/<rel>（wrapper 例化可读核
# 多一层 u_core）或 i:/WORK/<T>/<rel>，两侧**各恰好一个**、且归一后路径相同。
# 表外的父级、表外的 ram_*、同一父级里别的路径，一律拒绝。
#
# ram_40x47（codex 0158 §1 原授权 L2TlbMissQueue；codex 0209 显式扩到 L2TLB / L2TLBWrapper，
# 仅限其 L2TlbMissQueue 子树 missQueue.io_out_q 下的同一个 ram_ext）。与 ram_10x89 的两处不同：
#   · 父级内相对路径两侧不同名（重写核把 missQueue 例化成 u_missQueue；L2TlbMissQueue 自己的
#     重写核把 Queue40 内联，ram_ext 直接挂在 u_core 下），所以 rel 写成 (ref_rel, impl_rel) 二元组；
#   · 经由的 child 没有 tracked 证书（verif/proof_certificates/L2TlbMissQueue.json 不存在，0209 明令
#     不得虚构「证书有效」），via 写成 'receipt:<tracked receipt 路径>'：在本 commit 的字节上机器复算
#     该 receipt 的 impl 闭包（repo 文件）与 golden 闭包（G1 文件）逐个 sha256 不 stale、verdict 合格、
#     非 dirty / provisional——见 check_child_receipt_current()。
# 0209 其余绑定：design + golden sha256 + 8 端口签名（MANUAL_REVIEW_GOLDEN，并与 vendor_boundary.tsv
# 同行逐字核对）；每个父级两侧各恰好 1 个实例、在授权路径上（本函数）；指针复位 0 / ==39 回卷
# 的归纳由 `audit_ram_memory_model.py --check` 的 M3 机器 PASS 管（parent-map 的 Queue40 行）；
# 父级自己 official FM 全零、无 dont_verify/elab147/放宽 appvar 与「allow 只列实测对象集」由
# fm_verdict 的 assembly 判据管（观测黑盒集合与声明精确相等）。
L2TLB_MQ_RECEIPT = 'receipt:evidence/dd55953a7513/L2TlbMissQueue/receipt.json'
MANUAL_REVIEW_PARENTS = {
    'ram_40x47': {
        'L2TlbMissQueue': ('codex_0158', None, ('io_out_q/ram_ext', 'ram_ext')),
        'L2TLB':          ('codex_0209', L2TLB_MQ_RECEIPT,
                           ('missQueue/io_out_q/ram_ext', 'u_missQueue/io_out_q/ram_ext')),
        'L2TLBWrapper':   ('codex_0209', L2TLB_MQ_RECEIPT,
                           ('ptw/missQueue/io_out_q/ram_ext', 'ptw/u_core/u_missQueue/io_out_q/ram_ext')),
        # codex 0210 R2：Queue40 自己作为目标，同一个 ram_ext（impl 侧挂在复用的 xs_L2TlbMissQueue_core 即 u_core 下）
        'Queue40_L2TlbMQBundle': ('codex_0210', None, 'ram_ext'),
    },
    # codex 0210 R1：仅 Queue78_PCrdGranted（TL2CHICoupledL2.pCrdQueue_s2）当前闭包内两侧对称的 ram_ext
    # codex 0215 Q1：显式扩到 TL2CHICoupledL2 / L2Top 两个父级，逐对象完整路径写死（见 TL2_RAM_PATHS），
    # 经由 Queue78 的 tracked receipt（Q78_RECEIPT，本 commit 字节上复算不 stale）
    'ram_78x15': {
        'Queue78_PCrdGranted': ('codex_0210', None, 'ram_ext'),
        'TL2CHICoupledL2':     ('codex_0215', None, None),   # 占位，下面用 TL2_RAM_PATHS 填
        'L2Top':               ('codex_0215', None, None),
    },
    'ram_10x89': {
        'GrantBuffer':              ('codex_0202', None, 'pftRespQueue/ram_ext'),
        'Queue10_GrantBuffer_Anon': ('codex_0202', None, 'ram_ext'),
        'Slice':                    ('codex_0206', 'GrantBuffer', 'grantBuf/pftRespQueue/ram_ext'),
        'Slice_1':                  ('codex_0206', 'GrantBuffer', 'grantBuf/pftRespQueue/ram_ext'),
        'Slice_2':                  ('codex_0206', 'GrantBuffer', 'grantBuf/pftRespQueue/ram_ext'),
        'Slice_3':                  ('codex_0206', 'GrantBuffer', 'grantBuf/pftRespQueue/ram_ext'),
        'TL2CHICoupledL2':          ('codex_0215', None, None),   # 占位，下面用 TL2_RAM_PATHS 填
        'L2Top':                    ('codex_0215', None, None),
    },
}

# codex 0215 Q1：TL2CHICoupledL2 / L2Top 两个父级里的授权对象，**逐 top、逐对象完整路径**（不通配）。
# 多对象父级的 rel 写成 [(ref_rel, impl_rel), ...]：两侧观测集合必须与之**精确相等**（不多、不少、不错位），
# impl 路径按表写死（保留 slices_<k>/u_core/...），不再做 u_core 可选归一。
#   ram_10x89：slices_0..3 的 grantBuf.pftRespQueue.ram_ext，经由已签 GrantBuffer 的 tracked 证书（fm_verdict 验）；
#   ram_78x15：pCrdQueue_s2.ram_ext，经由 Queue78_PCrdGranted 的 tracked receipt（本 commit 字节上复算）。
Q78_RECEIPT = 'receipt:evidence/3afabfed181d/Queue78_PCrdGranted/receipt.json'
TL2_RAM_PATHS = {
    'ram_10x89': ('GrantBuffer',
                  [('slices_%d/grantBuf/pftRespQueue/ram_ext' % k,
                    'slices_%d/u_core/grantBuf/pftRespQueue/ram_ext' % k) for k in range(4)]),
    'ram_78x15': (Q78_RECEIPT, [('pCrdQueue_s2/ram_ext', 'pCrdQueue_s2/ram_ext')]),
}
for _d, (_via, _pairs) in TL2_RAM_PATHS.items():
    MANUAL_REVIEW_PARENTS[_d]['TL2CHICoupledL2'] = ('codex_0215', _via, list(_pairs))
    MANUAL_REVIEW_PARENTS[_d]['L2Top'] = ('codex_0215', _via,
                                          [('inner_l2cache/' + r, 'inner_l2cache/' + i) for r, i in _pairs])
# 0202 的精确绑定（golden 文件 sha256 + 端口签名），与 verif/vendor_boundary.tsv 第 5/7 列相同。
MANUAL_REVIEW_GOLDEN = {
    'ram_40x47': ('68dbc6df0bcb0aafe5bdf199e6241e5a744207d34db15af3dd7aa191413f9766',
                  'input [5:0] R0_addr;input R0_en;input R0_clk;output [46:0] R0_data;'
                  'input [5:0] W0_addr;input W0_en;input W0_clk;input [46:0] W0_data'),
    'ram_10x89': ('7cdc3e1c7dd131d409d1ed2b639b7cdb1f5ef12bad423815e50fed20fa6c2f0f',
                  'input [3:0] R0_addr;input R0_en;input R0_clk;output [88:0] R0_data;'
                  'input [3:0] W0_addr;input W0_en;input W0_clk;input [88:0] W0_data'),
    'ram_78x15': ('6563db65bfaa610b27eff79224e23e94200f62261a6bce5c8fd2daf2e28452fa',
                  'input [6:0] R0_addr;input R0_en;input R0_clk;output [14:0] R0_data;'
                  'input [6:0] W0_addr;input W0_en;input W0_clk;input [14:0] W0_data'),
}


def check_parent_scope(design, target, objects, golden_rtl=None):
    """返回 (ok, msg, via_child)。objects = 该父级 allow 里 design==design 的条目
    （每条含 side/path/attrs/class）。只做与 commit 无关的静态判据；via_child 的证书由调用方验。"""
    table = MANUAL_REVIEW_PARENTS.get(design)
    if table is None:
        return False, f'{design} 不在父级授权表里（表硬编码，不推广到其它 ram_*）', None
    if target not in table:
        return False, f'{design} 未授权在父级 {target} 里黑盒（授权父级：{",".join(sorted(table))}）', None
    msg_id, via, rel = table[target]
    if not list(BRIDGE_OUTBOX.glob(f'*_{msg_id}_*.md')):
        return False, f'bridge outbox 里找不到授权消息 {msg_id}', None
    want_sha, want_ports = MANUAL_REVIEW_GOLDEN[design]
    g = pathlib.Path(golden_rtl or (pathlib.Path(DEFAULT_G1) / 'golden-rtl'))
    gf = g / f'{design}.sv'
    if not gf.is_file():
        return False, f'golden 里找不到 {gf}', None
    cur = hashlib.sha256(gf.read_bytes()).hexdigest()
    if cur != want_sha:
        return False, f'golden {design}.sv sha256 {cur[:16]} != 授权绑定 {want_sha[:16]}', None
    vb = REPO / 'verif' / 'vendor_boundary.tsv'
    row = [ln.split('\t') for ln in vb.read_text().splitlines()
           if ln.split('\t')[0] == design] if vb.is_file() else []
    if len(row) != 1 or len(row[0]) < 7 or row[0][4] != want_sha or row[0][6] != want_ports:
        return False, f'verif/vendor_boundary.tsv 的 {design} 行与授权绑定（sha256/端口签名）不符', None
    got = [(o.get('side'), o.get('path')) for o in objects]
    for o in objects:
        if o.get('class') != 'APPROVED_MEMORY_MACRO_MODEL':
            return False, f'{o.get("path")} 的 class={o.get("class")!r} 不是 APPROVED_MEMORY_MACRO_MODEL', None
    if isinstance(rel, list):
        # codex 0215：多对象父级，逐对象完整路径写死，观测集合与表精确相等（各侧不多不少、无重复）
        want_r = sorted(f'r:/WORK/{target}/{r}' for r, _ in rel)
        want_i = sorted(f'i:/WORK/{target}/{i}' for _, i in rel)
        got_r = sorted(p for sd, p in got if sd == 'r')
        got_i = sorted(p for sd, p in got if sd == 'i')
        if any(sd not in ('r', 'i') for sd, _ in got):
            return False, f'{target} 里 {design} 有认不出的 side', None
        if got_r != want_r or got_i != want_i:
            miss = sorted(set(want_r + want_i) - set(got_r + got_i))
            extra = sorted(set(got_r + got_i) - set(want_r + want_i))
            dup = len(got_r) != len(set(got_r)) or len(got_i) != len(set(got_i))
            return False, (f'{target} 里 {design} 的对象集合与 codex 0215 授权表不精确相等'
                           f'（缺 {miss[:2]} 多 {extra[:2]}{" 有重复" if dup else ""}；'
                           f'ref={len(got_r)}/{len(want_r)} impl={len(got_i)}/{len(want_i)}）'), None
        ref_rel = '%d 对' % len(rel)
    else:
        ref_rel, impl_rel = rel if isinstance(rel, tuple) else (rel, rel)
        want = {('r', f'r:/WORK/{target}/{ref_rel}'),
                ('i', f'i:/WORK/{target}/{impl_rel}'), ('i', f'i:/WORK/{target}/u_core/{impl_rel}')}
        bad = [x for x in got if x not in want]
        if bad:
            return False, f'{design} 出现在授权路径之外：{bad[0][1]}（只许 {rel}）', None
        n_r = sum(1 for sd, _ in got if sd == 'r')
        n_i = sum(1 for sd, _ in got if sd == 'i')
        if n_r != 1 or n_i != 1:
            return False, f'{target} 里 {design} 两侧实例不对称/不唯一（ref={n_r}, impl={n_i}，须各恰好 1）', None
    if via and via.startswith('receipt:'):
        ok, why = check_child_receipt_current(via[len('receipt:'):], golden_rtl=golden_rtl)
        if not ok:
            return False, f'{design}@{target} 经由的 child receipt 不成立：{why}', None
        return True, f'{design}@{target}:{ref_rel} 在 {msg_id} 授权内（child receipt 未 stale：{why}）', None
    return True, (f'{design}@{target}:{ref_rel} 在 {msg_id} 授权内'
                  + (f'（经由已签 {via}，证书须另验）' if via else '')), via


def check_child_receipt_current(rel_path, golden_rtl=None, repo=None):
    """codex 0209：经由 child 的 tracked receipt（不是证书）判它此刻仍成立。返回 (ok, msg)。
    在 repo（默认本脚本所在仓库 = 被证明的那个 commit 的 worktree）的字节上逐个复算。"""
    import json as _json
    repo = pathlib.Path(repo or REPO)
    f = repo / rel_path
    if not f.is_file():
        return False, f'receipt {rel_path} 不存在'
    try:
        d = _json.loads(f.read_text())
    except Exception as e:                                   # noqa: BLE001
        return False, f'receipt {rel_path} 读不了：{e}'
    if d.get('verdict') not in ('SUCCEEDED', 'PASS_DEAD_REF'):
        return False, f'receipt verdict={d.get("verdict")!r} 不合格'
    if d.get('impl_worktree_dirty') is not False or d.get('provisional') is not False:
        return False, 'receipt 是 dirty 或 provisional'
    g = pathlib.Path(golden_rtl or (pathlib.Path(DEFAULT_G1) / 'golden-rtl'))
    impl = d.get('impl_closure') or []
    if not impl:
        return False, 'receipt 没有 impl 闭包'
    for e in impl + list(d.get('golden_closure') or []):
        if e.get('kind') == 'repo':
            p = repo / e['path']
        elif e.get('kind') == 'golden':
            p = g / e['path'].split('golden-rtl/', 1)[-1]
        else:
            return False, f'receipt 闭包条目 kind={e.get("kind")!r} 认不出'
        if not p.is_file():
            return False, f'闭包文件 {e["path"]} 不存在'
        if hashlib.sha256(p.read_bytes()).hexdigest() != e.get('sha256'):
            return False, f'闭包文件 {e["path"]} 已 stale'
    return True, f'{rel_path} {d.get("verdict")}，{len(impl)} 个 impl + {len(d.get("golden_closure") or [])} 个 golden 文件字节未变'


def check_manual_review(design, review, parent_impl):
    """返回 (ok, msg)。review 为 parent-map 第 5 列原文（可为 None）。"""
    if design not in MANUAL_REVIEW_DESIGNS:
        return False, f'{design} 不在人工复核名单里（名单硬编码，不推广）'
    if not review:
        return False, 'parent-map 第 5 列没有人工复核绑定'
    parts = [x.strip() for x in review.split(';') if x.strip()]
    msg_id = parts[0] if parts else ''
    if msg_id != MANUAL_REVIEW_DESIGNS[design]:
        return False, f'复核消息号 {msg_id!r} 与名单要求的 {MANUAL_REVIEW_DESIGNS[design]!r} 不符'
    if not list(BRIDGE_OUTBOX.glob(f'*_{msg_id}_*.md')):
        return False, f'bridge outbox 里找不到复核消息 {msg_id}'
    binds = {}
    for b in parts[1:]:
        if '=' not in b:
            return False, f'绑定项 {b!r} 不是 path=sha256 形态'
        path, sha = b.split('=', 1)
        binds[path.strip()] = sha.strip()
    if not binds:
        return False, '没有绑定任何文件 sha256'
    impl_rel = str(pathlib.Path(parent_impl).resolve().relative_to(REPO)) if parent_impl else None
    if impl_rel not in binds:
        return False, f'绑定文件里没有 parent_impl 本身（{impl_rel}）'
    for path, sha in sorted(binds.items()):
        f = REPO / path
        if not f.is_file():
            return False, f'绑定文件 {path} 不存在'
        cur = hashlib.sha256(f.read_bytes()).hexdigest()
        if cur != sha:
            return False, f'绑定文件 {path} 字节已变（{cur[:16]} != {sha[:16]}），须重新复核'
    return True, (f'按 {msg_id} 人工复核，绑定 {len(binds)} 个文件字节未变：'
                  + ', '.join(sorted(binds)))


def audit(design, golden_rtl, parent_ref, parent_impl, contract=None, review=None):
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
              f'depth {facts["depth"]} / '
              + (f'读口 {facts["n_read"]} / ' if facts['n_read'] > 1 else '')
              + f'写口 {facts["n_write"]} / 随机化 {facts["rand_width"]} 位')
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
    if not facts:
        print('  => AUDIT_INCOMPLETE（M1 认不出形状，M2/M3 无从做）')
        return 1
    ports = []
    for k in range(facts['n_read']):
        ports += [f'R{k}_addr', f'R{k}_en', f'R{k}_clk', f'R{k}_data']
    for i in range(facts['n_write']):
        ports += [f'W{i}_addr', f'W{i}_en', f'W{i}_clk', f'W{i}_data']
    if parent_ref and parent_impl:
        rtxt = pathlib.Path(parent_ref).read_text()
        itxt = pathlib.Path(parent_impl).read_text()
        ok2, msg2, ri, ii = m2_boundary_parity(design, rtxt, itxt, ports)
        print('  ' + msg2)
        rc = rc or (0 if ok2 else 1)
        if ok2:
            rc3 = 0
            addr_ports = [p for p in ports if p.endswith('_addr')]
            for side, txt, insts in (('ref', rtxt, ri), ('impl', itxt, ii)):
                seen = {}
                for name, conns, pos in parse_inst_pos(txt, design):
                    modname, region = module_region(txt, pos)
                    for port in addr_ports:
                        sig = conns[port]
                        key = (modname, sig)
                        if key in seen:
                            continue      # 同一表达式已判过（多个实例共用读地址等）
                        ok3, msg3 = m3_any(side, txt, region, sig, facts['depth'],
                                           facts['addr_width'], contract)
                        if (not ok3 and side == 'impl' and 'M3 FAIL' not in msg3
                                and review is not None):
                            okr, msgr = check_manual_review(design, review, parent_impl)
                            if okr:
                                ok3, msg3 = True, f'M3 MANUAL_REVIEWED[impl]: {msgr}（机器结论原为 MANUAL）'
                            else:
                                msg3 += f'\n  M3 人工复核未生效: {msgr}'
                        seen[key] = ok3
                        print(f'  [{modname}.{name}.{port} <- {sig}] {msg3}')
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
    ap.add_argument('--contract', help='M3 形态 B 的接口契约，形如 `value<160@…`；形态 A 不需要')
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
            contract = f[3].strip() if len(f) > 3 and f[3].strip() not in ('', '-', 'none') else None
            review = f[4].strip() if len(f) > 4 and f[4].strip() not in ('', '-', 'none') else None
            rc |= audit(f[0], a.golden_rtl,
                        resolve(f[1], pathlib.Path(a.golden_rtl)),
                        resolve(f[2], REPO), contract, review)
        print('=== audit --check: ' + ('全部 AUDIT_PASS ===' if rc == 0 else '★有条目未过★ ==='))
        return rc
    if not a.design:
        ap.error('须给 design 名，或用 --check')
    return audit(a.design, a.golden_rtl,
                 resolve(a.parent_ref, pathlib.Path(a.golden_rtl)),
                 resolve(a.parent_impl, REPO), a.contract)


if __name__ == '__main__':
    sys.exit(main())

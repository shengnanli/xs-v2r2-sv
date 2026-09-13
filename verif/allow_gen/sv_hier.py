#!/usr/bin/env python3
"""sv_hier.py —— 从**设计源文件**独立解析 module/instance 层次图。

codex 0150 强制两阶段的第 1 阶段用：expected set 的来源必须是设计源 +
elaboration 元数据，**不得**来自 black_boxes.rpt。本模块只读 .sv/.v 源文件，
不读任何 FM 产物。

解析法：先剥注释与字符串字面量，按 module/endmodule 切出模块体，再在模块体
的**括号深度 0** 上做例化识别：
    TYPE [#(...)] INST [[range]] ( ... );
关键字/系统函数/`@(`/单标识符函数调用一律排除（见 KEYWORDS）。
generate-for 里的例化会被识别，但**实例名带循环下标**，本模块把它标成
gen_scope 让调用方显形处理，绝不静默当成单实例。
"""
import re

KEYWORDS = {
    'module', 'endmodule', 'input', 'output', 'inout', 'wire', 'reg', 'logic',
    'bit', 'byte', 'shortint', 'int', 'longint', 'integer', 'time', 'real',
    'shortreal', 'realtime', 'string', 'event', 'chandle', 'void',
    'assign', 'always', 'always_ff', 'always_comb', 'always_latch', 'initial',
    'final', 'generate', 'endgenerate', 'if', 'else', 'for', 'while', 'repeat',
    'forever', 'do', 'case', 'casez', 'casex', 'endcase', 'begin', 'end',
    'function', 'endfunction', 'task', 'endtask', 'return', 'break', 'continue',
    'parameter', 'localparam', 'defparam', 'genvar', 'typedef', 'struct',
    'union', 'enum', 'packed', 'signed', 'unsigned', 'automatic', 'static',
    'const', 'var', 'ref', 'package', 'endpackage', 'import', 'export',
    'interface', 'endinterface', 'modport', 'program', 'endprogram',
    'property', 'endproperty', 'sequence', 'endsequence', 'assert', 'assume',
    'cover', 'expect', 'disable', 'fork', 'join', 'join_any', 'join_none',
    'wait', 'posedge', 'negedge', 'edge', 'or', 'and', 'nand', 'nor', 'xor',
    'xnor', 'not', 'buf', 'bufif0', 'bufif1', 'notif0', 'notif1', 'pullup',
    'pulldown', 'nmos', 'pmos', 'cmos', 'rnmos', 'rpmos', 'rcmos', 'tran',
    'tranif0', 'tranif1', 'rtran', 'rtranif0', 'rtranif1', 'supply0',
    'supply1', 'tri', 'triand', 'trior', 'tri0', 'tri1', 'trireg', 'wand',
    'wor', 'uwire', 'default', 'unique', 'unique0', 'priority', 'inside',
    'with', 'this', 'super', 'new', 'null', 'specify', 'endspecify',
    'specparam', 'table', 'endtable', 'primitive', 'endprimitive',
    'macromodule', 'config', 'endconfig', 'cell', 'design', 'liblist',
    'instance', 'use', 'timeunit', 'timeprecision', 'bind', 'alias',
    'randcase', 'randsequence', 'let', 'nettype', 'checker', 'endchecker',
    'clocking', 'endclocking', 'covergroup', 'endgroup', 'class', 'endclass',
    'extern', 'virtual', 'pure', 'context', 'localparam',
}

_BLOCK_C = re.compile(r'/\*.*?\*/', re.S)
_LINE_C = re.compile(r'//[^\n]*')
_STR = re.compile(r'"(?:\\.|[^"\\\n])*"')
_ID = re.compile(r'[A-Za-z_][A-Za-z0-9_$]*')


def _scrub(text):
    """去字符串字面量与注释；保留换行数以便报行号。"""
    def keepnl(m):
        return '\n' * m.group(0).count('\n')
    text = _STR.sub('""', text)
    text = _BLOCK_C.sub(keepnl, text)
    text = _LINE_C.sub('', text)
    return text


def _match_paren(s, i):
    """s[i]=='('，返回匹配 ')' 的下标。"""
    d = 0
    while i < len(s):
        if s[i] == '(':
            d += 1
        elif s[i] == ')':
            d -= 1
            if d == 0:
                return i
        i += 1
    return -1


def _prev_ident(s, i):
    """从 i-1 往前跳空白，取一个标识符，返回 (ident, 起始下标) 或 (None, i)。"""
    j = i - 1
    while j >= 0 and s[j].isspace():
        j -= 1
    if j < 0 or not (s[j].isalnum() or s[j] in '_$'):
        return None, j + 1
    k = j
    while k >= 0 and (s[k].isalnum() or s[k] in '_$'):
        k -= 1
    return s[k + 1:j + 1], k + 1


def _skip_ranges_back(s, i):
    """从 i-1 往前跳过空白与 [..] 段（实例数组维度），返回新的下标。"""
    j = i
    while True:
        k = j - 1
        while k >= 0 and s[k].isspace():
            k -= 1
        if k >= 0 and s[k] == ']':
            d = 0
            while k >= 0:
                if s[k] == ']':
                    d += 1
                elif s[k] == '[':
                    d -= 1
                    if d == 0:
                        break
                k -= 1
            j = k
            continue
        return j


def parse_file(path):
    """返回 {module_name: {'insts': [(inst, type, in_generate)], 'file': path}}"""
    raw = open(path, errors='replace').read()
    s = _scrub(raw)
    mods = {}
    for m in re.finditer(r'(?:^|\n)\s*(?:macro)?module\s+([A-Za-z_]\w*)', s):
        name = m.group(1)
        # 找模块头端口表结束的 ';'
        i = m.end()
        # 可能有 #( 参数表
        while i < len(s) and s[i] not in '(;':
            i += 1
        while i < len(s) and s[i] == '(':
            j = _match_paren(s, i)
            i = j + 1
            while i < len(s) and s[i].isspace():
                i += 1
            if i < len(s) and s[i] == '#':
                i += 1
                while i < len(s) and s[i].isspace():
                    i += 1
                continue
            break
        while i < len(s) and s[i] != ';':
            i += 1
        body_start = i + 1
        em = re.compile(r'(?:^|\n)\s*endmodule\b').search(s, body_start)
        body_end = em.start() if em else len(s)
        mods[name] = {'insts': _insts(s[body_start:body_end]), 'file': path}
    return mods


def _insts(body):
    out = []
    # generate 区间（粗粒度：genvar for 的 begin 块）标记
    gen_spans = []
    for gm in re.finditer(r'\bfor\s*\(\s*(?:genvar\s+)?\w+\s*=', body):
        # 找到该 for 对应的 begin...end 粗略跨度：从 for 到同层 'end'
        gen_spans.append(gm.start())
    i = 0
    n = len(body)
    depth = 0
    pending_type = None
    while i < n:
        c = body[i]
        if c == '[':
            d = 0
            while i < n:
                if body[i] == '[':
                    d += 1
                elif body[i] == ']':
                    d -= 1
                    if d == 0:
                        break
                i += 1
            i += 1
            continue
        if c == ')':
            depth = max(0, depth - 1)
            i += 1
            continue
        if c != '(':
            i += 1
            continue
        # c == '('
        if depth > 0:
            depth += 1
            i += 1
            continue
        # depth-0 open paren
        j = i - 1
        while j >= 0 and body[j].isspace():
            j -= 1
        if j >= 0 and body[j] == '#':
            # 参数表: TYPE #( ... )
            t, _ = _prev_ident(body, j)
            close = _match_paren(body, i)
            if t and t not in KEYWORDS:
                pending_type = t
            i = close + 1 if close > 0 else i + 1
            continue
        if j >= 0 and body[j] == '@':
            close = _match_paren(body, i)
            i = close + 1 if close > 0 else i + 1
            continue
        p = _skip_ranges_back(body, i)
        inst, s0 = _prev_ident(body, p)
        if inst is None or inst in KEYWORDS or inst.startswith('$'):
            close = _match_paren(body, i)
            i = close + 1 if close > 0 else i + 1
            pending_type = None
            continue
        if pending_type is not None:
            typ = pending_type
            pending_type = None
        else:
            typ, _ = _prev_ident(body, s0)
            if typ is None or typ in KEYWORDS or typ.startswith('$'):
                close = _match_paren(body, i)
                i = close + 1 if close > 0 else i + 1
                continue
        close = _match_paren(body, i)
        seg_start = max(0, s0 - 400)
        in_gen = any(seg_start <= g < s0 for g in gen_spans)
        out.append((inst, typ, in_gen))
        i = close + 1 if close > 0 else i + 1
    return out


def load_universe(files):
    u = {}
    dup = []
    for f in files:
        for k, v in parse_file(f).items():
            if k in u and u[k]['file'] != f:
                dup.append((k, u[k]['file'], f))
            u[k] = v
    return u, dup


def enumerate_blackboxes(top, universe, side, prefix=None):
    """DFS 层次遍历，返回 [(side, design, path)]，design=未定义模块类型。
    path 形如 '<side>:/WORK/<top>/inst/inst/leafinst'（FM report 格式：
    末段是**实例名**）。同时返回 gen_scope 警告。"""
    res, warn = [], []
    root = prefix if prefix is not None else f'{side}:/WORK/{top}'
    if top not in universe:
        warn.append(f'TOP_NOT_FOUND:{top}')
        return res, warn

    seen_stack = []

    def rec(mod, path):
        if mod in seen_stack:
            warn.append('RECURSION:' + '/'.join(seen_stack + [mod]))
            return
        seen_stack.append(mod)
        for inst, typ, in_gen in universe[mod]['insts']:
            p = f'{path}/{inst}'
            if in_gen:
                warn.append(f'GEN_SCOPE:{mod}.{inst}({typ}) 在 generate-for 内，实例名需人工确认')
            if typ in universe:
                rec(typ, p)
            else:
                res.append((side, typ, p))
        seen_stack.pop()

    rec(top, root)
    return res, warn


if __name__ == '__main__':
    import sys
    u, dup = load_universe(sys.argv[2:])
    for d in dup:
        print('DUP', d)
    r, w = enumerate_blackboxes(sys.argv[1], u, 'r')
    for x in r:
        print(*x)
    for x in w:
        print('WARN', x)

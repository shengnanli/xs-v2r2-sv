#!/usr/bin/env python3
"""port_contract_lint.py —— G1 端口契约闸（codex 0145 决策三）

对给定 target，逐项精确核对 **G1 golden 的模块端口表** 与 **仓库可读实现里同名
wrapper 的端口表**：

  * 端口集合（缺失 / 多余，按名字）
  * 方向（input / output / inout / ref）
  * packed 维度（含多维 `[a:b][c:d]`，逐维比 msb:lsb 原值，不只比宽度）
  * unpacked 维度（同上）
  * 每端口总位宽（base × packed × unpacked 元素数）
  * signed / unsigned
  * 端口顺序（默认 WARN，可 --order fail 升级；理由见 ORDER 说明）

**为什么需要这道闸**：迁移模式 A / D_DEPRENUM 的判据都会把端口表整段剥掉再比模块
体，于是"逻辑逐字未变、只有位宽变了"的目标会被判成机械迁移，产出位宽写回旧值的核。
UT 通常测不出（tb 按旧位宽驱动），一路漏到 FM 才炸。本闸在 UT **之前**拦。

**fail-closed 是硬要求**：解析不了 / 找不到模块 / 找到多个同名定义 / 端口表为空 /
位宽求不出常数值 —— 一律判失败并说明原因，绝不因为"没解析到差异"就放行。

ORDER 为什么默认 warn：golden 是 firtool 位置化生成的，但本工程所有例化（golden
父模块、UT tb、FM）都用**具名端口连接**，端口顺序不影响连接正确性；顺序不一致只是
可读性/审阅信号。若某天出现位置化例化，用 `--order fail` 升级为硬闸。

用法：
    # 单个 / 批量 target（impl 侧在 rtl/ 下自动找同名模块）
    port_contract_lint.py TARGET [TARGET ...]

    # 限定 impl 侧只在这些文件里找（UT 流程用这个：impl 源就是 RTL_SRCS）
    port_contract_lint.py --impl-src a.sv --impl-src b.sv TARGET ...

    # 从某个 UT 目录的 Makefile 推 target 与 impl 源（用 make 自己展开变量）
    port_contract_lint.py --ut-dir verif/ut/TLBuffer_6

    # 扫全部 UT（= `make portlint` 的全量版本）
    port_contract_lint.py --all-uts

    # 扫 rtl/ 下所有与 golden 同名的模块——比 --all-uts 宽，能覆盖到"重写件已入库
    # 但还没有 UT 目录"的目标（UT 闸看不见它们）
    port_contract_lint.py --all-impl

    # 模式 A 附加闸：G0 golden vs G1 golden 必须 width_chg==0 && dir_chg==0
    port_contract_lint.py --mode-a TARGET ...

退出码：0 = 全部通过；1 = 有 target 失败；2 = 用法/环境错误（同样算失败）。
"""



import argparse
import glob
import os
import re
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
G1_DEFAULT = os.environ.get(
    'GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
G0_DEFAULT = os.environ.get(
    'G0_GOLDEN_RTL', '/home/eda/xs-env/G0-canonical/golden-rtl')


class ParseError(Exception):
    """解析/求值失败。调用方必须把它翻成 FAIL，绝不许吞掉。"""


# ---------------------------------------------------------------------------
# 词法预处理
# ---------------------------------------------------------------------------
_COMMENT_RE = re.compile(r'"(?:\\.|[^"\\\n])*"|//[^\n]*|/\*.*?\*/', re.S)


def strip_comments(text: str) -> str:
    """去 // 与 /* */ 注释；字符串字面量原样保留；行数不变（行号仍可用）。
    残留未闭合的 /* -> ParseError（fail-closed，不当没看见）。"""
    def rep(m):
        s = m.group(0)
        if s[0] == '"':
            return s
        if s[1] == '/':
            return ''
        return '\n' * s.count('\n')
    out = _COMMENT_RE.sub(rep, text)
    if '/*' in out:
        raise ParseError('未闭合的 /* 注释（或字符串里出现 /*），无法可靠去注释'
                         ' -> fail-closed')
    return out


_TXT_CACHE = {}


def read_stripped(path: str) -> str:
    """带缓存的"读文件 + 去注释"。解析失败照抛，不吞。"""
    key = os.path.abspath(path)
    if key not in _TXT_CACHE:
        _TXT_CACHE[key] = strip_comments(
            open(path, errors='replace').read())
    return _TXT_CACHE[key]


def match_close(text: str, i: int) -> int:
    """text[i] 是 ( [ {，返回配对闭合符下标。"""
    pairs = {'(': ')', '[': ']', '{': '}'}
    if i >= len(text) or text[i] not in pairs:
        raise ParseError(f'match_close: 位置 {i} 不是开括号')
    op, cl = text[i], pairs[text[i]]
    depth, j = 0, i
    while j < len(text):
        if text[j] == op:
            depth += 1
        elif text[j] == cl:
            depth -= 1
            if depth == 0:
                return j
        j += 1
    raise ParseError(f'括号 {op!r} 未闭合（起于下标 {i}）')


def split_top(text: str, sep: str = ',') -> list:
    """按 top-level（不在 () [] {} 内）分隔符切分。括号不平衡 -> ParseError。"""
    parts, buf, depth = [], [], 0
    for ch in text:
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
            if depth < 0:
                raise ParseError('split_top: 括号不平衡')
        if ch == sep and depth == 0:
            parts.append(''.join(buf))
            buf = []
        else:
            buf.append(ch)
    if depth != 0:
        raise ParseError('split_top: 括号不平衡')
    parts.append(''.join(buf))
    return parts


# ---------------------------------------------------------------------------
# 常数表达式求值（fail-closed）
# ---------------------------------------------------------------------------
_SV_NUM = re.compile(
    r"""(?:\d+\s*)?'\s*[sS]?\s*([bodhBODH])\s*([0-9a-fA-FxXzZ_?]+)""")


def _sv_literals_to_int(expr: str) -> str:
    def rep(m):
        base = m.group(1).lower()
        digits = m.group(2).replace('_', '')
        if re.search(r'[xXzZ?]', digits):
            raise ParseError(f"位宽表达式含 x/z 字面量: {m.group(0)!r}")
        return str(int(digits, {'b': 2, 'o': 8, 'd': 10, 'h': 16}[base]))
    expr = _SV_NUM.sub(rep, expr)
    return re.sub(r'\b(\d[\d_]*)\b',
                  lambda m: m.group(1).replace('_', ''), expr)


def _clog2(x):
    x = int(x)
    return 0 if x <= 1 else (x - 1).bit_length()


def eval_const(expr: str, env: dict, what: str) -> int:
    """求 SV 常数表达式。求不出就抛 ParseError —— 绝不猜、绝不给默认值。"""
    e = expr.strip()
    if not e:
        raise ParseError(f'{what}: 空表达式')
    e = _sv_literals_to_int(e)
    e = re.sub(r'\$clog2\b', '__clog2', e)
    if '$' in e:
        raise ParseError(f'{what}: 位宽表达式含不支持的系统函数: {expr!r}')
    e = re.sub(r'\b([A-Za-z_]\w*)\s*::\s*([A-Za-z_]\w*)\b', r'\1__\2', e)
    local = {'__clog2': _clog2}
    for nm in set(re.findall(r'\b([A-Za-z_]\w*)\b', e)):
        if nm == '__clog2':
            continue
        if nm in env:
            local[nm] = env[nm]
        elif nm.split('__')[-1] in env:
            local[nm] = env[nm.split('__')[-1]]
        else:
            raise ParseError(
                f'{what}: 位宽表达式 {expr!r} 里的 {nm!r} 无法静态求值'
                f'（parameter/localparam/package 里都没找到）-> fail-closed')
    if re.search(r'[^\w\s+\-*/%()\[\]<>|&^~!=?:,.]', e):
        raise ParseError(f'{what}: 位宽表达式含不支持的字符: {expr!r}')
    py = e.replace('&&', ' and ').replace('||', ' or ')
    try:
        val = eval(py, {'__builtins__': {}}, local)  # noqa: S307 受限环境
    except ParseError:
        raise
    except Exception as exc:  # noqa: BLE001
        raise ParseError(f'{what}: 位宽表达式 {expr!r} 求值失败: {exc}') from exc
    if isinstance(val, bool):
        val = int(val)
    if not isinstance(val, int):
        raise ParseError(f'{what}: 位宽表达式 {expr!r} 不是整数常量（得 {val!r}）')
    return val


# ---------------------------------------------------------------------------
# 端口模型
# ---------------------------------------------------------------------------
BUILTIN_WIDTH = {
    'logic': 1, 'bit': 1, 'reg': 1, 'wire': 1, 'tri': 1, 'uwire': 1,
    'wand': 1, 'wor': 1, 'triand': 1, 'trior': 1, 'tri0': 1, 'tri1': 1,
    'trireg': 1, 'supply0': 1, 'supply1': 1,
    'byte': 8, 'shortint': 16, 'int': 32, 'integer': 32,
    'longint': 64, 'time': 64,
}
INT_ATOM = {'byte', 'shortint', 'int', 'integer', 'longint', 'time'}
UNSIZED_TYPES = {'real', 'shortreal', 'realtime', 'string', 'event',
                 'chandle', 'genvar'}
NET_KW = {'wire', 'tri', 'uwire', 'wand', 'wor', 'triand', 'trior',
          'tri0', 'tri1', 'trireg', 'supply0', 'supply1'}
DIRECTIONS = ('input', 'output', 'inout', 'ref')


def dims_str(dims):
    return ''.join('[%d:%d]' % d for d in dims) or '(标量)'


class Port:
    __slots__ = ('name', 'direction', 'packed', 'unpacked', 'signed',
                 'base_width', 'width', 'index', 'raw', 'basetype')

    def __init__(self, name, direction, packed, unpacked, signed,
                 base_width, index, raw, basetype):
        self.name = name
        self.direction = direction
        self.packed = packed        # [(msb,lsb), ...] 已求值
        self.unpacked = unpacked    # [(msb,lsb), ...]（[N] 归一为 (N-1,0)）
        self.signed = signed
        self.base_width = base_width
        self.index = index
        self.raw = raw
        self.basetype = basetype
        w = base_width
        for (m, l) in packed:
            w *= abs(m - l) + 1
        for (m, l) in unpacked:
            w *= abs(m - l) + 1
        self.width = w

    def desc(self):
        s = self.direction + ' '
        if self.signed:
            s += 'signed '
        s += self.basetype or 'logic'
        if self.packed:
            s += ' ' + dims_str(self.packed)
        s += ' ' + self.name
        if self.unpacked:
            s += ' ' + dims_str(self.unpacked)
        return s + '  (总位宽 %d)' % self.width


class ModuleIface:
    def __init__(self, name, path, ports, params):
        self.name = name
        self.path = path
        self.ports = ports
        self.params = params

    @property
    def by_name(self):
        return dict((p.name, p) for p in self.ports)


# ---------------------------------------------------------------------------
# parameter / package / typedef 收集
# ---------------------------------------------------------------------------
_PARAM_DECL = re.compile(r'(?<![\w$])(?:localparam|parameter)\b([^;]*);', re.S)


def collect_params(scope_text: str, env: dict) -> dict:
    """收 localparam/parameter 的整型常量。求不出的**跳过**（不猜值）——
    真正用到它的端口会在 eval_const 里 fail-closed。"""
    out = dict(env)
    for m in _PARAM_DECL.finditer(scope_text):
        try:
            items = split_top(m.group(1), ',')
        except ParseError:
            continue
        for it in items:
            mm = re.search(r'([A-Za-z_]\w*)\s*=\s*(.+)$', it, re.S)
            if not mm:
                continue
            try:
                out[mm.group(1)] = eval_const(mm.group(2), out,
                                              'localparam ' + mm.group(1))
            except ParseError:
                continue
    return out


def collect_packages(paths) -> dict:
    """{pkg_name: {'params': {...}, 'body': '...'}}"""
    pkgs = {}
    for p in paths:
        try:
            txt = read_stripped(p)
        except (OSError, ParseError):
            continue
        for m in re.finditer(r'(?<![\w$])package\s+([A-Za-z_]\w*)\s*;', txt):
            nm = m.group(1)
            end = txt.find('endpackage', m.end())
            body = txt[m.end():end if end > 0 else len(txt)]
            e = pkgs.setdefault(nm, {'params': {}, 'body': ''})
            e['params'].update(collect_params(body, {}))
            e['body'] += '\n' + body
    return pkgs


def typedef_width(tname: str, scopes, env: dict, depth: int = 0) -> int:
    """尽力解析 typedef 位宽；解析不出就抛（不给默认 1）。"""
    if depth > 8:
        raise ParseError('typedef %s 解析层数过深' % tname)
    for body in scopes:
        for m in re.finditer(r'(?<![\w$])typedef\s+(?:struct|union)\s+packed\b',
                             body):
            b = body.find('{', m.end())
            if b < 0:
                continue
            e = match_close(body, b)
            mm = re.match(r'\s*([A-Za-z_]\w*)\s*;', body[e + 1:e + 200])
            if not mm or mm.group(1) != tname:
                continue
            total = 0
            for fld in body[b + 1:e].split(';'):
                if fld.strip():
                    total += _decl_width(fld, scopes, env, depth + 1)
            return total
        for m in re.finditer(r'(?<![\w$])typedef\s+enum\b([^{;]*)\{', body):
            b = body.index('{', m.start())
            e = match_close(body, b)
            mm = re.match(r'\s*([A-Za-z_]\w*)\s*;', body[e + 1:e + 200])
            if not mm or mm.group(1) != tname:
                continue
            base = m.group(1).strip()
            if not base:
                return 32
            return _decl_width(base + ' __dummy', scopes, env, depth + 1)
        for m in re.finditer(
                r'(?<![\w$])typedef\s+(?!struct|union|enum)([^;]+?)\s+'
                r'([A-Za-z_]\w*)\s*;', body):
            if m.group(2) != tname:
                continue
            return _decl_width(m.group(1) + ' __dummy', scopes, env, depth + 1)
    raise ParseError('类型 %r 无法解析位宽（未找到 typedef 定义）-> fail-closed'
                     % tname)


def _decl_width(decl: str, scopes, env: dict, depth: int) -> int:
    """`<type> [dims] name [unpacked]`（可含逗号分隔的多个名字）的总位宽之和。"""
    parts = split_top(decl, ',')
    base = _classify_decl_tokens(_tokenize_decl(parts[0]), env, scopes, depth)

    def wof(info):
        w = info['base_width']
        for (m, l) in info['packed']:
            w *= abs(m - l) + 1
        for (m, l) in info['unpacked']:
            w *= abs(m - l) + 1
        return w

    total = wof(base)
    for extra in parts[1:]:
        toks = _tokenize_decl(extra)
        if not toks:
            continue
        info = dict(base)
        info['unpacked'] = [_split_dim(t, env, 'field ' + toks[0])
                            for t in toks[1:] if t.startswith('[')]
        total += wof(info)
    return total


# ---------------------------------------------------------------------------
# 声明 token 化与分类
# ---------------------------------------------------------------------------
def _tokenize_decl(s: str):
    """切成 token：标识符（含 pkg::name）/ [..] 整块 / 其它单字符。
    遇到 `=` 就停（端口默认值不属于契约）。"""
    toks, i, n = [], 0, len(s)
    while i < n:
        c = s[i]
        if c.isspace():
            i += 1
            continue
        if c == '[':
            j = match_close(s, i)
            toks.append(re.sub(r'\s+', '', s[i:j + 1]))
            i = j + 1
            continue
        if c == '=':
            break
        m = re.match(r'[A-Za-z_$][\w$]*(?:\s*::\s*[A-Za-z_]\w*)?', s[i:])
        if m:
            toks.append(re.sub(r'\s+', '', m.group(0)))
            i += m.end()
            continue
        toks.append(c)
        i += 1
    return toks


def _split_dim(d: str, env, what):
    inner = d[1:-1]
    if ':' in inner:
        a, b = split_top(inner, ':')
        return (eval_const(a, env, what), eval_const(b, env, what))
    n = eval_const(inner, env, what)
    if n <= 0:
        raise ParseError('%s: 维度 [%s] 求值为 %d' % (what, inner, n))
    return (n - 1, 0)


def _classify_decl_tokens(toks, env, scopes, depth=0):
    # SV 声明的语法是  <dir> <var/net> <type> <packed dims> NAME <unpacked dims>。
    # 关键是不能靠"下一个 token 是不是 [ 或标识符"来猜哪个标识符是类型名——
    # `input [63:0] data [0:3]` 与 `input my_t data [0:3]` 在那种猜法下同形，
    # 会把端口名当成类型名（这类猜错就是静默漏检的温床）。
    # 稳妥做法：**最后一个标识符就是端口名**，它之后只能是 unpacked 维，
    # 它之前是方向/类型/packed 维。任何不符合这个形状的都 fail-closed。
    direction = None
    signed = None
    basetype = None
    rest = []
    i = 0
    while i < len(toks):
        t = toks[i]
        if (t in DIRECTIONS and direction is None and not rest):
            direction = t
            i += 1
            continue
        if t == 'var' and not rest:
            i += 1
            continue
        if t in (',', ';'):
            i += 1
            continue
        rest.append(t)
        i += 1

    ident_idx = [k for k, t in enumerate(rest)
                 if re.match(r'^[A-Za-z_$]', t) and t not in ('signed',
                                                              'unsigned')]
    if not ident_idx:
        raise ParseError('声明里找不到端口名: %r' % (toks,))
    name_idx = ident_idx[-1]
    name = rest[name_idx]

    unpacked = []
    for t in rest[name_idx + 1:]:
        if not t.startswith('['):
            raise ParseError('端口名 %s 之后出现无法识别的 token %r: %r'
                             % (name, t, toks))
        unpacked.append(t)

    packed = []
    for t in rest[:name_idx]:
        if t in ('signed', 'unsigned'):
            signed = (t == 'signed')
            continue
        if t.startswith('['):
            packed.append(t)
            continue
        if re.match(r'^[A-Za-z_$]', t):
            if basetype is not None:
                raise ParseError('声明里出现多个类型标识符（%s / %s），'
                                 '无法判定端口类型: %r'
                                 % (basetype, t, toks))
            basetype = t
            continue
        raise ParseError('声明里出现无法识别的 token %r: %r' % (t, toks))

    what = '端口 ' + name
    pk = [_split_dim(d, env, what) for d in packed]
    up = [_split_dim(d, env, what) for d in unpacked]

    if basetype is None or basetype in NET_KW:
        base_width = 1
    elif basetype in INT_ATOM:
        if pk:
            raise ParseError('%s: 整型原子类型 %s 上又带 packed 维，拒绝猜测语义'
                             % (what, basetype))
        base_width = BUILTIN_WIDTH[basetype]
    elif basetype in BUILTIN_WIDTH:
        base_width = BUILTIN_WIDTH[basetype]
    elif basetype in UNSIZED_TYPES:
        raise ParseError('%s: 类型 %s 没有确定位宽，无法核对契约 -> fail-closed'
                         % (what, basetype))
    else:
        base_width = typedef_width(basetype.split('::')[-1], scopes, env,
                                   depth + 1)
    return {'direction': direction, 'signed': bool(signed),
            'basetype': basetype, 'base_width': base_width,
            'packed': pk, 'unpacked': up, 'name': name}


# ---------------------------------------------------------------------------
# 模块头解析
# ---------------------------------------------------------------------------
def find_module(text: str, name: str):
    """找 `module <name>`（跳过 extern / 宏定义里的）。返回 match 或 None。"""
    pat = re.compile(r'(?<![\w$])module\s+(?:automatic\s+|static\s+)?'
                     + re.escape(name) + r'(?![\w$])')
    for m in pat.finditer(text):
        head = text[max(0, m.start() - 24):m.start()]
        if re.search(r'(?<![\w$])extern\s*$', head):
            continue
        return m
    return None


def parse_module_iface(path, name, extra_scopes, pkgs):
    text = read_stripped(path)
    m = find_module(text, name)
    if m is None:
        raise ParseError('%s: 找不到 module %s' % (path, name))
    i = m.end()

    imports = []
    while True:
        mm = re.match(r'\s*import\s+([^;]+);', text[i:])
        if not mm:
            break
        for it in mm.group(1).split(','):
            if '::' in it:
                imports.append(it.split('::')[0].strip())
        i += mm.end()

    env = {}
    scopes = []
    for pk in imports:
        if pk in pkgs:
            env.update(pkgs[pk]['params'])
            scopes.append(pkgs[pk]['body'])
    file_head = text[:m.start()]
    env = collect_params(file_head, env)
    scopes.append(file_head)
    scopes.extend(extra_scopes)

    mm = re.match(r'\s*#\s*\(', text[i:])
    if mm:
        op = i + mm.end() - 1
        cl = match_close(text, op)
        inner = text[op + 1:cl]
        env = collect_params('parameter ' + inner + ';', env)
        for it in split_top(inner, ','):
            m2 = re.search(r'([A-Za-z_]\w*)\s*=\s*(.+)$', it, re.S)
            if m2 and m2.group(1) not in env:
                try:
                    env[m2.group(1)] = eval_const(
                        m2.group(2), env, 'parameter ' + m2.group(1))
                except ParseError:
                    pass
        i = cl + 1

    if re.match(r'\s*;', text[i:]):
        raise ParseError('%s: module %s 没有端口表（端口表为空）-> fail-closed'
                         % (path, name))
    mm = re.match(r'\s*\(', text[i:])
    if not mm:
        raise ParseError('%s: module %s 头部无法解析（既无 ( 也无 ;）: %r'
                         % (path, name, text[i:i + 80]))
    op = i + mm.end() - 1
    cl = match_close(text, op)
    plist = text[op + 1:cl]
    if '`' in plist:
        raise ParseError('%s: module %s 端口表里有预处理指令(`)，无法静态核对'
                         ' -> fail-closed' % (path, name))

    endm = text.find('\nendmodule', cl)
    body = text[cl + 1:endm if endm > 0 else len(text)]
    body_env = collect_params(body, env)
    scopes_body = scopes + [body]

    items = [s.strip() for s in split_top(plist, ',')]
    items = [s for s in items if s]
    if not items:
        raise ParseError('%s: module %s 端口表为空 -> fail-closed' % (path, name))

    ports = []
    first_toks = _tokenize_decl(items[0])
    ansi = bool(first_toks) and (first_toks[0] in DIRECTIONS
                                 or len(first_toks) > 1)

    if ansi:
        last_dir = None
        for idx, it in enumerate(items):
            toks = _tokenize_decl(it)
            if not toks:
                raise ParseError('%s: module %s 第 %d 个端口项为空'
                                 % (path, name, idx))
            info = _classify_decl_tokens(toks, env, scopes_body)
            if info['direction'] is None:
                if last_dir is None:
                    raise ParseError(
                        '%s: module %s 端口 %s 没有方向关键字，且前面无可继承方向'
                        ' -> fail-closed（SV 默认 inout 不猜）'
                        % (path, name, info['name']))
                info['direction'] = last_dir
            last_dir = info['direction']
            ports.append(Port(info['name'], info['direction'], info['packed'],
                              info['unpacked'], info['signed'],
                              info['base_width'], idx, it, info['basetype']))
    else:
        names = []
        for it in items:
            t = _tokenize_decl(it)
            if len(t) != 1 or not re.match(r'^[A-Za-z_]', t[0]):
                raise ParseError('%s: module %s 非 ANSI 端口表里有无法识别的项 %r'
                                 ' -> fail-closed' % (path, name, it))
            names.append(t[0])
        decls = {}
        for m2 in re.finditer(r'(?<![\w$])(input|output|inout)\b([^;]*);', body):
            try:
                subs = split_top(m2.group(2), ',')
            except ParseError:
                raise ParseError('%s: 非 ANSI 声明解析失败: %r'
                                 % (path, m2.group(0)[:80]))
            base = _classify_decl_tokens(
                _tokenize_decl(m2.group(1) + ' ' + subs[0]), body_env,
                scopes_body)
            decls[base['name']] = base
            for extra in subs[1:]:
                t2 = _tokenize_decl(extra)
                if not t2:
                    continue
                if len(t2) == 1:
                    d = dict(base)
                    d['name'] = t2[0]
                else:
                    d = _classify_decl_tokens([m2.group(1)] + t2, body_env,
                                              scopes_body)
                decls[d['name']] = d
        for idx, nm in enumerate(names):
            if nm not in decls:
                raise ParseError('%s: module %s 非 ANSI 端口 %s 在模块体里找不到'
                                 '方向声明 -> fail-closed' % (path, name, nm))
            d = decls[nm]
            ports.append(Port(d['name'], d['direction'], d['packed'],
                              d['unpacked'], d['signed'], d['base_width'],
                              idx, nm, d['basetype']))

    if not ports:
        raise ParseError('%s: module %s 解析出 0 个端口 -> fail-closed'
                         % (path, name))
    dup = [p.name for p in ports if [q.name for q in ports].count(p.name) > 1]
    if dup:
        raise ParseError('%s: module %s 端口名重复: %s -> fail-closed'
                         % (path, name, sorted(set(dup))))
    return ModuleIface(name, path, ports, env)


# ---------------------------------------------------------------------------
# 比较
# ---------------------------------------------------------------------------
def compare(gold, impl, order_mode):
    fails, warns = [], []
    gmap, imap = gold.by_name, impl.by_name

    missing = [p.name for p in gold.ports if p.name not in imap]
    extra = [p.name for p in impl.ports if p.name not in gmap]
    for nm in missing:
        fails.append('MISSING   端口 %s: golden 有、实现没有   <golden: %s>'
                     % (nm, gmap[nm].desc()))
    for nm in extra:
        fails.append('EXTRA     端口 %s: 实现有、golden 没有   <impl: %s>'
                     % (nm, imap[nm].desc()))

    for p in gold.ports:
        q = imap.get(p.name)
        if q is None:
            continue
        if p.direction != q.direction:
            fails.append('DIR       端口 %s: golden=%s impl=%s'
                         % (p.name, p.direction, q.direction))
        if p.packed != q.packed:
            fails.append('PACKED    端口 %s: golden packed %s != impl packed %s'
                         % (p.name, dims_str(p.packed), dims_str(q.packed)))
        if p.unpacked != q.unpacked:
            fails.append('UNPACKED  端口 %s: golden unpacked %s != impl unpacked %s'
                         % (p.name, dims_str(p.unpacked), dims_str(q.unpacked)))
        if p.width != q.width:
            fails.append('WIDTH     端口 %s: golden 总位宽 %d != impl 总位宽 %d'
                         % (p.name, p.width, q.width))
        if p.signed != q.signed:
            fails.append('SIGNED    端口 %s: golden signed=%s impl signed=%s'
                         % (p.name, p.signed, q.signed))

    if not missing and not extra:
        go = [p.name for p in gold.ports]
        io = [p.name for p in impl.ports]
        if go != io:
            k = next((x for x in range(len(go)) if go[x] != io[x]), 0)
            msg = ('ORDER     端口顺序与 golden 不一致（第 %d 项: golden=%s '
                   'impl=%s）' % (k, go[k], io[k]))
            (fails if order_mode == 'fail' else warns).append(msg)
    return fails, warns


# ---------------------------------------------------------------------------
# 定位 golden / impl
# ---------------------------------------------------------------------------
_GIDX = {}


def golden_index(gdir):
    if gdir not in _GIDX:
        idx = {}
        for f in sorted(glob.glob(os.path.join(gdir, '*.sv'))
                        + glob.glob(os.path.join(gdir, '*.v'))):
            b = os.path.basename(f)
            idx.setdefault(b[:b.rindex('.')], f)
        _GIDX[gdir] = idx
    return _GIDX[gdir]


def find_golden(gdir, name):
    p = os.path.join(gdir, name + '.sv')
    if os.path.exists(p):
        return p
    idx = golden_index(gdir)
    if name in idx:
        return idx[name]
    for f in sorted(glob.glob(os.path.join(gdir, '*.sv'))):
        try:
            if find_module(read_stripped(f),
                           name):
                return f
        except ParseError:
            continue
    raise ParseError('golden 目录 %s 里找不到 module %s -> fail-closed'
                     % (gdir, name))


def repo_sv_files(rtl_root):
    out = []
    for ext in ('*.sv', '*.svh', '*.v'):
        out.extend(glob.glob(os.path.join(rtl_root, '**', ext), recursive=True))
    return sorted(set(out))


_INC = re.compile(r'^\s*`include\s+"([^"]+)"', re.M)


def expand_includes(srcs, rtl_root, depth=0):
    """把 `include 的文件也纳入搜索范围（.svh 套壳的核可能在 include 里）。"""
    out = list(srcs)
    if depth > 3:
        return out
    for f in list(srcs):
        if not os.path.exists(f):
            continue
        try:
            txt = read_stripped(f)
        except ParseError:
            continue
        for m in _INC.finditer(txt):
            cand = [os.path.join(os.path.dirname(f), m.group(1)),
                    os.path.join(rtl_root, m.group(1))]
            cand += glob.glob(os.path.join(rtl_root, '**',
                                           os.path.basename(m.group(1))),
                              recursive=True)
            for c in cand:
                if os.path.exists(c) and c not in out:
                    out.extend(expand_includes([c], rtl_root, depth + 1))
                    break
    return out


_MODULE_DECL = re.compile(
    r'(?<![\w$])(?<!extern )module\s+(?:automatic\s+|static\s+)?([A-Za-z_]\w*)')
_REPO_MODIDX = {}


def repo_module_index(rtl_root):
    """{模块名: [文件, ...]}，整棵 rtl/ 只扫一遍（供未给 --impl-src 时用）。"""
    if rtl_root not in _REPO_MODIDX:
        idx = {}
        for f in repo_sv_files(rtl_root):
            try:
                txt = read_stripped(f)
            except (OSError, ParseError):
                continue
            for m in _MODULE_DECL.finditer(txt):
                idx.setdefault(m.group(1), []).append(f)
        _REPO_MODIDX[rtl_root] = idx
    return _REPO_MODIDX[rtl_root]


def find_impl(name, impl_srcs, rtl_root):
    if not impl_srcs:
        pool = repo_module_index(rtl_root).get(name, [])
    else:
        pool = expand_includes(impl_srcs, rtl_root)
    hits = []
    for f in pool:
        if not os.path.exists(f):
            continue
        try:
            if find_module(read_stripped(f), name):
                hits.append(f)
        except ParseError:
            continue
    if not hits:
        where = '给定的 impl 源' if impl_srcs else rtl_root
        msg = ('在 %s 里找不到 module %s 的可读实现 -> fail-closed' % (where, name))
        if impl_srcs:
            msg += '\n            （查过: %s）' % ', '.join(pool)
        raise ParseError(msg)
    if len(set(hits)) > 1:
        raise ParseError('module %s 在多个文件里都有定义，无法判定核对哪个'
                         ' -> fail-closed: %s' % (name, sorted(set(hits))))
    return hits[0]


# ---------------------------------------------------------------------------
# 模式 A 附加闸：G0 golden vs G1 golden
# ---------------------------------------------------------------------------
def mode_a_check(name, g0dir, g1dir, pkgs):
    g0 = parse_module_iface(find_golden(g0dir, name), name, [], pkgs)
    g1 = parse_module_iface(find_golden(g1dir, name), name, [], pkgs)
    a, b = g0.by_name, g1.by_name
    common = sorted(set(a) & set(b))
    fails = []
    for n in common:
        if (a[n].width != b[n].width or a[n].packed != b[n].packed
                or a[n].unpacked != b[n].unpacked):
            fails.append('MODE_A_WIDTH  端口 %s: G0 %s(w=%d) -> G1 %s(w=%d)'
                         ' —— 位宽变了，不是纯接口增量，不能按模式 A 施工'
                         % (n, dims_str(a[n].packed), a[n].width,
                            dims_str(b[n].packed), b[n].width))
    for n in common:
        if a[n].direction != b[n].direction:
            fails.append('MODE_A_DIR    端口 %s: G0 %s -> G1 %s'
                         % (n, a[n].direction, b[n].direction))
    return fails


# ---------------------------------------------------------------------------
# UT 目录 -> (targets, impl_srcs)
# ---------------------------------------------------------------------------
_PROBE = ('__portlint_probe:\n'
          '\t@echo "FM_VARIANTS=$(FM_VARIANTS)"\n'
          '\t@echo "RTL_SRCS=$(abspath $(RTL_SRCS))"\n'
          '\t@echo "PORTLINT_EXTRA_SRCS=$(abspath $(PORTLINT_EXTRA_SRCS))"\n')


def ut_vars(utdir):
    """用 make 自己展开变量（不手工解析 Makefile 语法）。"""
    if not os.path.exists(os.path.join(utdir, 'Makefile')):
        raise ParseError('%s: 没有 Makefile' % utdir)
    r = subprocess.run(
        ['make', '-C', utdir, '-f', 'Makefile', '-f', '-',
         '__portlint_probe', '--no-print-directory'],
        input=_PROBE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        universal_newlines=True)
    if r.returncode != 0:
        raise ParseError('%s: make 取变量失败:\n%s' % (utdir, r.stderr.strip()))
    vals = {}
    for line in r.stdout.splitlines():
        if '=' in line:
            k, v = line.split('=', 1)
            vals[k.strip()] = v.strip()
    if 'FM_VARIANTS' not in vals:
        raise ParseError('%s: make 没有回报 FM_VARIANTS -> fail-closed' % utdir)
    return (vals['FM_VARIANTS'].split(),
            vals.get('RTL_SRCS', '').split()
            + vals.get('PORTLINT_EXTRA_SRCS', '').split())


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------
def lint_one(name, impl_srcs, args, pkgs):
    try:
        gold = parse_module_iface(find_golden(args.golden_dir, name), name,
                                  [], pkgs)
    except ParseError as e:
        return 'FAIL', ['  [golden 侧] %s' % e]
    except Exception as e:  # noqa: BLE001
        return 'FAIL', ['  [golden 侧] 解析异常 %s: %s' % (type(e).__name__, e)]

    try:
        ipath = find_impl(name, impl_srcs, args.rtl_root)
        extra = []
        for f in impl_srcs:
            if os.path.exists(f) and f != ipath:
                try:
                    extra.append(read_stripped(f))
                except ParseError:
                    pass
        impl = parse_module_iface(ipath, name, extra, pkgs)
    except ParseError as e:
        return 'FAIL', ['  [impl 侧] %s' % e]
    except Exception as e:  # noqa: BLE001
        return 'FAIL', ['  [impl 侧] 解析异常 %s: %s' % (type(e).__name__, e)]

    fails, warns = compare(gold, impl, args.order)
    if args.mode_a:
        try:
            fails += mode_a_check(name, args.g0_dir, args.golden_dir, pkgs)
        except ParseError as e:
            fails.append('MODE_A    无法完成 G0/G1 对比 -> fail-closed: %s' % e)

    def rel(p):
        return os.path.relpath(p, REPO) if p.startswith(REPO) else p

    lines = ['  golden: %s (%d 端口)   impl: %s (%d 端口)'
             % (os.path.basename(gold.path), len(gold.ports),
                rel(impl.path), len(impl.ports))]
    lines += ['  WARN  ' + w for w in warns]
    if fails:
        tally = {}
        for f in fails:
            tally[f.split()[0]] = tally.get(f.split()[0], 0) + 1
        lines.append('  差异统计: ' + ', '.join(
            '%s=%d' % kv for kv in sorted(tally.items())))
        shown = fails if args.max_diff <= 0 else fails[:args.max_diff]
        lines += ['  ' + f for f in shown]
        if len(fails) > len(shown):
            lines.append('  ...（还有 %d 条差异未打印，用 --max-diff 0 看全部）'
                         % (len(fails) - len(shown)))
    return ('FAIL' if fails else 'PASS'), lines


def main(argv=None):
    ap = argparse.ArgumentParser(description='G1 端口契约 lint（fail-closed）')
    ap.add_argument('targets', nargs='*', help='golden 模块名')
    ap.add_argument('--impl-src', action='append', default=[],
                    help='限定 impl 侧只在这些文件里找同名模块（可重复）')
    ap.add_argument('--golden-dir', default=G1_DEFAULT)
    ap.add_argument('--g0-dir', default=G0_DEFAULT)
    ap.add_argument('--rtl-root', default=os.path.join(REPO, 'rtl'))
    ap.add_argument('--ut-dir', action='append', default=[])
    ap.add_argument('--all-uts', action='store_true')
    ap.add_argument('--all-impl', action='store_true',
                    help='扫 rtl/ 下**所有**与 golden 同名的模块（比 --all-uts 宽：'
                         '包含没有 UT 目录的重写件）')
    ap.add_argument('--order', choices=['warn', 'fail'], default='warn')
    ap.add_argument('--mode-a', action='store_true',
                    help='附加模式 A 闸：G0 vs G1 必须 width_chg==0 && dir_chg==0')
    ap.add_argument('--quiet-pass', action='store_true')
    ap.add_argument('--max-diff', type=int, default=25,
                    help='每个 target 最多打印几条差异（0 = 全打）；'
                         '差异统计行始终完整')
    args = ap.parse_args(argv)

    if not os.path.isdir(args.golden_dir):
        print('PORTLINT ERROR: golden 目录不存在: %s' % args.golden_dir,
              file=sys.stderr)
        return 2
    if args.mode_a and not os.path.isdir(args.g0_dir):
        print('PORTLINT ERROR: --mode-a 需要 G0 目录，但不存在: %s' % args.g0_dir,
              file=sys.stderr)
        return 2

    jobs, hard_errors, skipped = [], [], []
    utdirs = list(args.ut_dir)
    if args.all_uts:
        base = os.path.join(REPO, 'verif', 'ut')
        utdirs += sorted(os.path.join(base, d) for d in os.listdir(base)
                         if os.path.isdir(os.path.join(base, d)))
    for d in utdirs:
        try:
            tg, srcs = ut_vars(d)
        except ParseError as e:
            hard_errors.append('%s: %s' % (os.path.basename(d), e))
            continue
        if not tg:
            # 无 FM_VARIANTS = 本 UT 没有 golden 对位目标（纯学习 tb / 家族聚合
            # tb）。本闸不适用；注意 ut_common.mk 的 `fm` 目标本身就拒绝空
            # FM_VARIANTS，所以这不是给谁开的后门。
            skipped.append(os.path.basename(d))
            continue
        for t in tg:
            jobs.append((os.path.basename(d), t, srcs))
    if args.all_impl:
        gidx = golden_index(args.golden_dir)
        midx = repo_module_index(args.rtl_root)
        for t in sorted(n for n in midx if n in gidx):
            jobs.append(('rtl', t, []))

    for t in args.targets:
        jobs.append((None, t, args.impl_src))

    if not jobs and not hard_errors and not skipped:
        print('PORTLINT ERROR: 没有任何 target（既没给 target 也没给 '
              '--ut-dir/--all-uts/--all-impl）-> fail-closed', file=sys.stderr)
        return 2

    pkg_paths = repo_sv_files(args.rtl_root)
    for _, _, srcs in jobs:
        pkg_paths.extend(srcs)
    pkgs = collect_packages(sorted(set(pkg_paths)))

    npass = 0
    failed = []
    for label, t, srcs in jobs:
        tag = ('%s::%s' % (label, t)) if label else t
        status, lines = lint_one(t, srcs, args, pkgs)
        if status == 'PASS':
            npass += 1
            print('[PASS] ' + tag)
            if not args.quiet_pass:
                for l in lines:
                    if l.strip().startswith('WARN'):
                        print(l)
        else:
            failed.append(tag)
            print('[FAIL] ' + tag)
            for l in lines:
                print(l)
    for e in hard_errors:
        print('[FAIL] ' + e)
        failed.append(e.split(':')[0])
    for s in skipped:
        print('[SKIP] %s: 无 FM_VARIANTS（本 UT 无 golden 对位目标）' % s)

    print('--- portlint: %d pass, %d fail, %d skip ---'
          % (npass, len(failed), len(skipped)))
    if failed:
        print('FAILED: ' + ', '.join(failed))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())

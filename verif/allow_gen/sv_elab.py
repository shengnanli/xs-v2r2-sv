#!/usr/bin/env python3
"""sv_elab.py —— 只读**设计源**的轻量 elaborator：模块/参数/generate 作用域/例化。

用途（codex 0150 阶段 1）：独立产生 assembly expected 黑盒集合。
**不读**任何 FM 产物（black_boxes.rpt / native_facts.json / fm.log）。

能力与边界（fail-loud，宁可抛异常也不猜）：
  * module/endmodule 切块；parameter/localparam 求值（含 $clog2、位宽字面量、
    三目、位运算、比较）；例化 #(.P(v)) 覆盖按父作用域求值。
  * generate 作用域：`for (genvar v=A; v<B; v++) begin : L`（含先声明 `genvar v;`
    的写法）→ 路径段 `L[i]`；`if (cond) begin : L` / `else begin : L` → 路径段 `L`。
  * 过程 for（`for (int ...)`）不产生作用域（过程块里不可能有例化）。
  * 任何无法求值的边界/条件、任何宏体里疑似例化 → 抛 ElabError。
"""
import re

from sv_hier import KEYWORDS, _scrub, _match_paren, _prev_ident, _skip_ranges_back


class ElabError(Exception):
    pass


_DIRECTIVE = re.compile(r'^[ \t]*`.*?(?<!\\)$', re.M)
_INST_LOOKING = re.compile(r'\b[A-Za-z_]\w*\s+[A-Za-z_]\w*\s*\(')


def _strip_directives(s):
    """删预处理指令行（含反斜杠续行）。删掉的 `define 体若疑似含例化 → 抛。"""
    out = []
    lines = s.split('\n')
    i = 0
    while i < len(lines):
        ln = lines[i]
        if ln.lstrip().startswith('`'):
            chunk = [ln]
            while chunk[-1].rstrip().endswith('\\') and i + 1 < len(lines):
                i += 1
                chunk.append(lines[i])
            body = '\n'.join(chunk)
            if body.lstrip().startswith('`define'):
                inner = body.split('\n', 1)[1] if '\n' in body else ''
                for m in _INST_LOOKING.finditer(inner):
                    head = m.group(0).split()[0]
                    if head not in KEYWORDS:
                        raise ElabError(f'宏体疑似含例化，须人工确认: {m.group(0)!r}')
            out.append('\n' * (len(chunk) - 1))
            i += 1
            continue
        out.append(ln)
        i += 1
    return '\n'.join(out)


# ---------------- 表达式求值 ----------------
_SIZED = re.compile(r"(\d+)?'\s*[sS]?([bodhBODH])\s*([0-9a-fA-FxXzZ_]+)")
_CAST = re.compile(r"\b[A-Za-z_]\w*\s*'\s*\(")


def _lit(m):
    base = {'b': 2, 'o': 8, 'd': 10, 'h': 16}[m.group(2).lower()]
    d = m.group(3).replace('_', '')
    if re.search(r'[xXzZ]', d):
        raise ElabError(f'含 x/z 的字面量不可求值: {m.group(0)}')
    return str(int(d, base))


def _drop_casts(e):
    while True:
        m = _CAST.search(e)
        if not m:
            return e
        close = _match_paren(e, m.end() - 1)
        if close < 0:
            raise ElabError(f'类型转换括号不匹配: {e}')
        e = e[:m.start()] + '(' + e[m.end():close] + ')' + e[close + 1:]


def evaluate(expr, env):
    e = expr.strip().rstrip(';,')
    if not e:
        raise ElabError('空表达式')
    e = _SIZED.sub(_lit, e)
    # 数组参数的赋值模式 '{a, b, ...}（如 xs_mbist_pipe_core 的 ID_LO/ID_CNT）：逐项求值成元组。
    # 它们只作参数值传递，不参与本工具关心的例化层次；遇到就按元组返回，不再当成语法错误。
    m_ap = re.fullmatch(r"'\{(.*)\}", e.strip())
    if m_ap:
        return tuple(evaluate(x, env) for x in m_ap.group(1).split(',') if x.strip())
    e = _drop_casts(e)
    e = re.sub(r'\$clog2\s*\(', '_clog2(', e)
    e = re.sub(r'\$bits\s*\(', '_unsupported(', e)
    e = e.replace('&&', ' and ').replace('||', ' or ')
    e = re.sub(r'(?<![<>=!])!(?!=)', ' not ', e)
    e = re.sub(r'\b(\d+)\s*\?', r'\1 ?', e)
    # 三目 a ? b : c  → (b) if (a) else (c)
    for _ in range(8):
        m = re.search(r'\?', e)
        if not m:
            break
        e = _ternary(e)
    e = re.sub(r'/(?!/)', '//', e)          # Verilog 整数除
    e = re.sub(r'\bnot\b\s*//', 'not /', e)
    names = set(re.findall(r'\b(?![0-9])[A-Za-z_]\w*\b', e))

    def _clog2(x):
        x = int(x)
        return 0 if x <= 1 else (x - 1).bit_length()

    g = {'_clog2': _clog2, '_unsupported': None}
    for n in names:
        if n in ('and', 'or', 'not', 'if', 'else', '_clog2'):
            continue
        if n not in env:
            raise ElabError(f'未知标识符 {n} in {expr!r}')
        if isinstance(env[n], _Deferred):
            raise ElabError(f'用到了未求值的参数 {n}: {env[n].msg}')
        g[n] = env[n]
    try:
        return int(eval(e, {'__builtins__': {}}, g))
    except ElabError:
        raise
    except Exception as ex:
        raise ElabError(f'求值失败 {expr!r} -> {e!r}: {ex}')


def _ternary(e):
    q = e.index('?')
    d = 0
    i = q + 1
    while i < len(e):
        if e[i] == '(':
            d += 1
        elif e[i] == ')':
            d -= 1
            if d < 0:
                break
        elif e[i] == '?' and d == 0:
            raise ElabError('嵌套三目未支持: ' + e)
        elif e[i] == ':' and d == 0:
            break
        i += 1
    if i >= len(e) or e[i] != ':':
        raise ElabError('三目缺 ":" : ' + e)
    # 条件左界
    j = q - 1
    d = 0
    while j >= 0:
        if e[j] == ')':
            d += 1
        elif e[j] == '(':
            d -= 1
            if d < 0:
                break
        j -= 1
    cond = e[j + 1:q]
    a = e[q + 1:i]
    # 假分支右界
    k = i + 1
    d = 0
    while k < len(e):
        if e[k] == '(':
            d += 1
        elif e[k] == ')':
            d -= 1
            if d < 0:
                break
        k += 1
    b = e[i + 1:k]
    return e[:j + 1] + f'(({a}) if ({cond}) else ({b}))' + e[k:]


# ---------------- 模块解析 ----------------
_PARAM = re.compile(
    r'\b(parameter|localparam)\b((?:\s+(?:type|int|integer|logic|bit|reg|byte|'
    r'shortint|longint|unsigned|signed))*)\s*(\[[^\]]*\]\s*)?')


class Module:
    def __init__(self, name, header, body, path, filescope=None):
        self.name = name
        self.header = header
        self.body = body
        self.file = path
        self.filescope = filescope or {}
        self.hdr_params = _params_of(header)
        # 只取模块体**顶层**（不在任何 begin...end 里）的 localparam：
        # generate 作用域里的 localparam 依赖 genvar，属局部量，不进模块 env。
        spans = _begin_spans(body)
        self.body_params = [(n, e) for n, e, pos in _params_of(body, True)
                            if not any(a <= pos < b for a, b in spans)]
        self.scopes = _scopes_of(body)
        self.insts = _insts_of(body)


def _begin_spans(body):
    spans, stack = [], []
    for m in re.finditer(r'\b(begin|end)\b', body):
        if m.group(1) == 'begin':
            stack.append(m.start())
        elif stack:
            spans.append((stack.pop(), m.end()))
    return spans


def _params_of(txt, withpos=False):
    out = []
    for m in _PARAM.finditer(txt):
        rest = txt[m.end():]
        # 可能一条声明里多个 name = expr,
        pos = 0
        while True:
            nm = re.match(r'\s*([A-Za-z_]\w*)\s*(\[[^\]]*\]\s*)?=', rest[pos:])
            if not nm:
                break
            start = pos + nm.end()
            d = 0
            i = start
            while i < len(rest):
                c = rest[i]
                if c in '([{':
                    d += 1
                elif c in ')]}':
                    if d == 0:
                        break
                    d -= 1
                elif c in ',;' and d == 0:
                    break
                i += 1
            if withpos:
                out.append((nm.group(1), rest[start:i].strip(), m.end() + pos))
            else:
                out.append((nm.group(1), rest[start:i].strip()))
            if i < len(rest) and rest[i] == ',':
                pos = i + 1
                continue
            break
    return out


def _find_end(body, i):
    """body[i:] 以 begin 开头，返回匹配 end 的结束下标。"""
    d = 0
    for m in re.finditer(r'\b(begin|end)\b', body[i:]):
        if m.group(1) == 'begin':
            d += 1
        else:
            d -= 1
            if d == 0:
                return i + m.end()
    raise ElabError('begin/end 不匹配')


def _scopes_of(body):
    """返回 [dict(kind,label,var,init,bound,cond,start,end)]，start/end 覆盖块体。"""
    scopes = []
    genvars = set(re.findall(r'^\s*genvar\s+([\w\s,]+);', body, re.M))
    gv = set()
    for g in genvars:
        gv |= {x.strip() for x in g.split(',') if x.strip()}
    for m in re.finditer(r'\bbegin\b\s*:\s*([A-Za-z_]\w*)', body):
        label = m.group(1)
        end = _find_end(body, m.start())
        pre = body[:m.start()]
        # 往回找引导构造
        mm = None
        for cand in re.finditer(r'\b(for|if|else)\b', pre):
            mm = cand
        if mm is None:
            continue
        kind = mm.group(1)
        if kind == 'for':
            hdr_open = pre.index('(', mm.end())
            hdr_close = _match_paren(pre, hdr_open)
            hdr = pre[hdr_open + 1:hdr_close]
            parts = [p.strip() for p in hdr.split(';')]
            if len(parts) != 3:
                raise ElabError(f'for 头非三段: {hdr}')
            im = re.match(r'(?:genvar\s+)?(?:int\s+unsigned|int|integer)?\s*'
                          r'([A-Za-z_]\w*)\s*=\s*(.+)$', parts[0])
            if not im:
                raise ElabError(f'for 初始化无法解析: {parts[0]}')
            var = im.group(1)
            is_gen = parts[0].strip().startswith('genvar') or var in gv
            if not is_gen:
                continue                       # 过程 for：不产生 generate 作用域
            cm = re.match(r'([A-Za-z_]\w*)\s*(<=|<)\s*(.+)$', parts[1])
            if not cm or cm.group(1) != var:
                raise ElabError(f'for 条件无法解析: {parts[1]}')
            scopes.append({'kind': 'for', 'label': label, 'var': var,
                           'init': im.group(2), 'op': cm.group(2),
                           'bound': cm.group(3),
                           'start': m.start(), 'end': end})
        else:
            if kind == 'if':
                cond_open = pre.index('(', mm.end())
                cond = pre[cond_open + 1:_match_paren(pre, cond_open)]
                scopes.append({'kind': 'if', 'label': label, 'cond': cond,
                               'start': m.start(), 'end': end})
            else:
                # else / else if
                tail = pre[mm.end():]
                em = re.match(r'\s*if\s*\(', tail)
                if em:
                    cond_open = mm.end() + tail.index('(')
                    cond = pre[cond_open + 1:_match_paren(pre, cond_open)]
                    scopes.append({'kind': 'elif', 'label': label, 'cond': cond,
                                   'prev_end': mm.start(),
                                   'start': m.start(), 'end': end})
                else:
                    scopes.append({'kind': 'else', 'label': label,
                                   'prev_end': mm.start(),
                                   'start': m.start(), 'end': end})
    return scopes


def _insts_of(body):
    """[(pos, type, inst, override_text)]，pos 为实例名起点。"""
    out = []
    i, n, depth = 0, len(body), 0
    pending = None
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
        if depth > 0:
            depth += 1
            i += 1
            continue
        j = i - 1
        while j >= 0 and body[j].isspace():
            j -= 1
        close = _match_paren(body, i)
        if j >= 0 and body[j] == '#':
            t, _ = _prev_ident(body, j)
            if t and t not in KEYWORDS:
                pending = (t, body[i + 1:close])
            i = close + 1 if close > 0 else i + 1
            continue
        if j >= 0 and body[j] == '@':
            i = close + 1 if close > 0 else i + 1
            continue
        p = _skip_ranges_back(body, i)
        inst, s0 = _prev_ident(body, p)
        if inst is None or inst in KEYWORDS or inst.startswith('$'):
            i = close + 1 if close > 0 else i + 1
            pending = None
            continue
        if pending is not None:
            typ, ov = pending
            pending = None
        else:
            typ, _ = _prev_ident(body, s0)
            ov = ''
            if typ is None or typ in KEYWORDS or typ.startswith('$'):
                i = close + 1 if close > 0 else i + 1
                continue
        out.append((s0, typ, inst, ov))
        i = close + 1 if close > 0 else i + 1
    return out


def parse_file(path):
    s = _strip_directives(_scrub(open(path, errors='replace').read()))
    # 文件级 / package 级 localparam（$unit 作用域）：模块内查不到时的兜底
    spans = []
    for m in re.finditer(r'(?:^|\n)\s*(?:macro)?module\s+[A-Za-z_]\w*', s):
        em = re.compile(r'(?:^|\n)\s*endmodule\b').search(s, m.end())
        spans.append((m.start(), em.end() if em else len(s)))
    outside = list(s)
    for a, b in spans:
        for k in range(a, b):
            if outside[k] != '\n':
                outside[k] = ' '
    fscope = {}
    for nm, ex in _params_of(''.join(outside)):
        fscope[nm] = ex
    mods = {}
    for m in re.finditer(r'(?:^|\n)\s*(?:macro)?module\s+([A-Za-z_]\w*)', s):
        name = m.group(1)
        i = m.end()
        hdr_start = i
        # 模块头里的包导入 `module M import p::*; #(...) (...);`（CONVENTIONS：import 必须写在模块头里）
        # —— 跳过这些 import 子句，否则会把它的分号当成模块头结束。
        while True:
            mi = re.match(r'\s*import\s+[^;]*;', s[i:])
            if not mi:
                break
            i += mi.end()
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
        header = s[hdr_start:i]
        body_start = i + 1
        em = re.compile(r'(?:^|\n)\s*endmodule\b').search(s, body_start)
        body_end = em.start() if em else len(s)
        mods[name] = Module(name, header, s[body_start:body_end], path, fscope)
    return mods


def load_universe(files):
    u, dup = {}, []
    for f in files:
        for k, v in parse_file(f).items():
            if k in u and u[k].file != f:
                dup.append((k, u[k].file, f))
            u[k] = v
    return u, dup


class LazyEnv(dict):
    """模块参数环境：header 参数立即求值；body/文件级 localparam 按需求值。
    generate 里依赖 genvar 的 localparam 因此不会在无关路径上炸掉。"""

    def __init__(self, base, thunks):
        super().__init__(base)
        self._thunks = thunks

    def __contains__(self, k):
        return dict.__contains__(self, k) or k in self._thunks

    def __getitem__(self, k):
        if dict.__contains__(self, k):
            return dict.__getitem__(self, k)
        if k in self._thunks:
            v = evaluate(self._thunks[k], self)
            self[k] = v
            return v
        raise KeyError(k)


def _mod_env(mod, overrides):
    env = {}
    ov = dict(overrides)
    for nm, ex in mod.hdr_params:
        env[nm] = ov.pop(nm) if nm in ov else evaluate(ex, env)
    if ov:
        raise ElabError(f'{mod.name}: 覆盖了不存在的参数 {sorted(ov)}')
    thunks = dict(mod.filescope)
    thunks.update(dict(mod.body_params))
    return LazyEnv(env, thunks)


class _Deferred(object):
    """覆盖值里含 $bits(端口...) 这类本工具不建模的表达式（变体薄文件给共享核传的自检参数）：
    不当场报错，记下来；只有真被用到（参与层次/generate 判定）时才报 —— 用不到就说明它与例化层次无关。"""

    def __init__(self, msg):
        self.msg = msg


def _parse_overrides(text, env):
    out = {}
    if not text.strip():
        return out
    d, cur, parts = 0, '', []
    for ch in text:
        if ch in '([{':
            d += 1
        elif ch in ')]}':
            d -= 1
        if ch == ',' and d == 0:
            parts.append(cur)
            cur = ''
            continue
        cur += ch
    parts.append(cur)
    for p in parts:
        p = p.strip()
        if not p:
            continue
        m = re.match(r'\.\s*([A-Za-z_]\w*)\s*\((.*)\)\s*$', p, re.S)
        if not m:
            raise ElabError(f'仅支持具名参数覆盖: {p!r}')
        try:
            out[m.group(1)] = evaluate(m.group(2), env)
        except ElabError as ex:
            if '$bits' not in m.group(2):
                raise
            out[m.group(1)] = _Deferred(str(ex))
    return out


def _chain(mod, pos):
    """包含 pos 的作用域链（外→内）。"""
    c = [s for s in mod.scopes if s['start'] <= pos < s['end']]
    c.sort(key=lambda s: s['start'])
    return c


def _cond_true(mod, sc, env):
    if sc['kind'] == 'if':
        return evaluate(sc['cond'], env) != 0
    if sc['kind'] == 'elif':
        return (not _prev_taken(mod, sc, env)) and evaluate(sc['cond'], env) != 0
    return not _prev_taken(mod, sc, env)


def _prev_taken(mod, sc, env):
    """else/elif 之前那条 if/elif 链是否已成立。"""
    prev = [s for s in mod.scopes
            if s['end'] <= sc['start'] and s['kind'] in ('if', 'elif')]
    if not prev:
        raise ElabError(f"{mod.name}: else 分支 {sc['label']} 找不到配对 if")
    p = max(prev, key=lambda s: s['end'])
    if p['kind'] == 'if':
        return evaluate(p['cond'], env) != 0
    return _cond_true(mod, p, env)


def enumerate_blackboxes(top, universe, side):
    """返回 (objects, notes)；objects = [(side, design, path)]。"""
    res, notes = [], []
    if top not in universe:
        raise ElabError(f'top 未在读入文件集中定义: {top}')

    def walk(mod, path, env, stack):
        if mod.name in stack:
            raise ElabError('层次递归: ' + '/'.join(stack + [mod.name]))
        for pos, typ, inst, ovtxt in mod.insts:
            chain = _chain(mod, pos)
            for prefix, lenv in _expand(mod, chain, env):
                p = f'{path}/{prefix}{inst}' if prefix else f'{path}/{inst}'
                child = universe.get(typ)
                if child is None:
                    res.append((side, typ, p))
                    continue
                ov = _parse_overrides(ovtxt, lenv)
                walk(child, p, _mod_env(child, ov), stack + [mod.name])

    def _expand(mod, chain, env):
        if not chain:
            yield '', env
            return
        sc, rest = chain[0], chain[1:]
        if sc['kind'] == 'for':
            lo = evaluate(sc['init'], env)
            hi = evaluate(sc['bound'], env)
            rng = range(lo, hi + 1) if sc['op'] == '<=' else range(lo, hi)
            for k in rng:
                e2 = LazyEnv(env, getattr(env, '_thunks', {}))
                e2[sc['var']] = k
                for pfx, e3 in _expand(mod, rest, e2):
                    yield f"{sc['label']}[{k}].{pfx}", e3
        else:
            if not _cond_true(mod, sc, env):
                return
            for pfx, e3 in _expand(mod, rest, env):
                yield f"{sc['label']}.{pfx}", e3

    walk(universe[top], f'{side}:/WORK/{top}', _mod_env(universe[top], {}), [])
    return res, notes

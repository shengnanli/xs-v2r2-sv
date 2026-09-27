#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— DecodeUnit 的机械派生区（rtl/backend/DecodeUnit.sv 的 GENERATED 段）与 UT tb。

DecodeUnit 的主体是一张 **译码表**：Chisel 里 12 个 DecodeConstants 对象（XDecode /
FpDecode / BitmanipDecode / ScalarCryptoDecode / XSDebugDecode / CBODecode / SvinvalDecode /
HypervisorDecode / VecDecoder / ZicondDecode / ZimopDecode / ZfaDecode）拼成一个
`Array[(BitPat, List[BitPat])]`，由 `ListLookup` 按 **表序优先** 查（第一条命中的行胜出）。
firtool 把它展平成 golden 里 5,000 多行的三目链，人没法对着读。

本脚本把表**从 Scala 源码现场读出来**，机械地翻成一个 `casez (instr)`（casez 的
"第一条命中胜出"与 ListLookup 语义相同），写进 rtl/backend/DecodeUnit.sv 的 GENERATED 段：

  1. GENERATED(insn_patterns) —— 每条指令一个 localparam（`?` 位写成 z，casez 当通配），
     名字即 Scala/rocket-chip 里的助记符（LW / VADD_VV / FLI_H …）。
  2. GENERATED(decode_table)  —— `casez` 表本体，每行一条指令，列顺序与 Scala 的
     XSDecode(src1, src2, src3, fu, fuOp, selImm, uopSplitType, 标志…) 一致；
     Scala 源码里的分节注释（`// RV32I` / `// Zba` …）原样带过来。
  3. GENERATED(structs)       —— static_inst_t / csr_to_decode_t / decoded_inst_t：
     成员名与位宽逐字取自 golden 端口表（端口缺哪些字段以 golden 为准）。
  4. GENERATED(ports)/(wrapper) —— golden 同名 wrapper 的端口表（逐字取自 golden）与
     struct 打包/拆包。
  5. verif/ut/DecodeUnit/tb.sv —— 双例化 tb（golden DecodeUnit vs DecodeUnit_xs）。

★常量不抄手，全部从源码求值★：SrcType / SelImm / UopSplitType / FuType（addType 顺序）/
各 *OpType（xiangshan/package.scala）/ yunsuan 的向量 OpType（含 LiteralCat 拼接与
VialuOpcode/VimacOpcode）。

★与 golden 的机械对账（fail-closed）★：golden 里每条指令的匹配项
`_decodedInst_decoder_T_N = <slice> == <const>` 按定义顺序恰好是表序（firtool 对重复
匹配做了 CSE，只保留首次出现）。本脚本把表里每条 BitPat 算成 (mask, value)，按首次出现
去重后，必须与 golden 的匹配项序列 **逐条相等**——助记符解析错一位、表序错一行都会红。

用法：
    python3 gen.py            # 生成（幂等）
    python3 gen.py --check    # 与库里的产物不一致则非零退出
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
REPO = HERE.parents[2]
RTL = REPO / 'rtl' / 'backend' / 'DecodeUnit.sv'
TB = HERE / 'tb.sv'
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/DecodeUnit.sv')
XS = pathlib.Path('/home/eda/xs-env/XiangShan')
SCALA = XS / 'src/main/scala/xiangshan'
ROCKET = XS / 'rocket-chip/src/main/scala/rocket'
YUNSUAN = XS / 'yunsuan/src/main/scala/yunsuan'

TAG = 'verif/ut/DecodeUnit/gen.py'

# ---------------------------------------------------------------------------
# 0. 小工具
# ---------------------------------------------------------------------------
def strip_comments(text):
    """去掉 Scala 的 // 行尾注释与 /* */ 块注释（字符串里没有这些，本文件不需要更细）。"""
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    return re.sub(r'//[^\n]*', '', text)

def brace_block(text, start_pat):
    """返回 start_pat（正则）之后第一个 { … } 的内部文本。"""
    m = re.search(start_pat, text)
    assert m, f'找不到 {start_pat!r}'
    i = text.index('{', m.end())
    depth = 0
    for j in range(i, len(text)):
        if text[j] == '{':
            depth += 1
        elif text[j] == '}':
            depth -= 1
            if depth == 0:
                return text[i + 1:j]
    raise AssertionError('括号不配对')

def blank_comments(text):
    """把注释内容换成等长空白（保住下标），括号配对时忽略注释里的括号。"""
    def blank(m):
        return ' ' * len(m.group(0))
    text = re.sub(r'/\*.*?\*/', blank, text, flags=re.S)
    return re.sub(r'//[^\n]*', blank, text)

def paren_block(text, start_pat):
    """返回 start_pat 之后第一个 ( … ) 的内部文本（保留注释；配对时忽略注释里的括号）。"""
    m = re.search(start_pat, text)
    assert m, f'找不到 {start_pat!r}'
    i = text.index('(', m.end())
    scan = blank_comments(text)
    depth = 0
    for j in range(i, len(text)):
        if scan[j] == '(':
            depth += 1
        elif scan[j] == ')':
            depth -= 1
            if depth == 0:
                return text[i + 1:j]
    raise AssertionError('括号不配对')

def split_top(text, sep=','):
    """按最外层的 sep 切分（忽略括号内）。"""
    out, depth, cur = [], 0, []
    for ch in text:
        if ch in '([':
            depth += 1
        elif ch in ')]':
            depth -= 1
        if ch == sep and depth == 0:
            out.append(''.join(cur))
            cur = []
        else:
            cur.append(ch)
    out.append(''.join(cur))
    return [s.strip() for s in out if s.strip()]

# ---------------------------------------------------------------------------
# 1. BitPat（指令模式）：rocket-chip Instructions / CustomInstructions + XiangShan 自有
# ---------------------------------------------------------------------------
BITPAT_RE = re.compile(r'def\s+(\w+)\s*=\s*BitPat\("b([01?_]+)"\)')

def parse_bitpats(text):
    pats = {}
    for name, bits in BITPAT_RE.findall(text):
        bits = bits.replace('_', '')
        if len(bits) != 32:
            continue          # 1 位的 X/N/Y 之类不是指令模式
        mask = int(''.join('0' if c == '?' else '1' for c in bits), 2)
        val = int(''.join('0' if c == '?' else c for c in bits), 2)
        pats[name] = (mask, val, bits)
    return pats

def load_insn_patterns():
    pats = {}
    pats.update(parse_bitpats((ROCKET / 'Instructions.scala').read_text()))
    pats.update(parse_bitpats((ROCKET / 'CustomInstructions.scala').read_text()))
    pats.update(parse_bitpats((SCALA / 'backend/decode/Instructions.scala').read_text()))   # Zvbb / Zimop
    pats.update(parse_bitpats((SCALA / 'backend/decode/DecodeUnit.scala').read_text()))     # TRAP / SIM_TRIG
    return pats

# ---------------------------------------------------------------------------
# 2. 常量求值：一个够用的 Scala 字面量小解释器
#    值 = (int, width)
# ---------------------------------------------------------------------------
class Env:
    def __init__(self):
        self.objs = {}        # 'SrcType' -> {'xp': (1,4), ...}
        self.consts = {'OpTypeWidth': (9, 32)}

    def lookup(self, ref, scope=None):
        ref = ref.strip()
        if ref.startswith('this.'):
            ref = ref[5:]
        if '.' in ref:
            obj, mem = ref.rsplit('.', 1)
            obj = obj.split('.')[-1]           # xiangshan.backend.x.Y.z -> Y
            d = self.objs.get(obj)
            if d is None:
                raise KeyError(ref)
            return d[mem]
        if scope is not None and ref in scope:
            return scope[ref]
        if ref in self.consts:
            return self.consts[ref]
        raise KeyError(ref)

def eval_expr(env, expr, scope):
    e = expr.strip()
    # "b0101".U(w.W) / "b0101".U
    m = re.fullmatch(r'"b([01_]+)"\.U(?:\((\w+)\.W\))?', e)
    if m:
        bits = m.group(1).replace('_', '')
        w = width_of(env, m.group(2), scope) if m.group(2) else len(bits)
        return (int(bits, 2), w)
    m = re.fullmatch(r'(\d+)\.U\s*(?:\((\w+)\.W\))?', e)
    if m:
        w = width_of(env, m.group(2), scope) if m.group(2) else max(1, int(m.group(1)).bit_length())
        return (int(m.group(1)), w)
    m = re.fullmatch(r'(\d+)', e)
    if m:
        return (int(m.group(1)), 32)
    m = re.fullmatch(r'BitPat\("b([01?_]+)"\)', e)
    if m:
        bits = m.group(1).replace('_', '')
        return (int(''.join('0' if c == '?' else c for c in bits), 2), len(bits))   # bitPatToUInt: ? -> 0
    m = re.fullmatch(r'BitPat\.([YN])\((\w+)\)', e)
    if m:
        w = width_of(env, m.group(2), scope)
        return ((1 << w) - 1 if m.group(1) == 'Y' else 0, w)
    m = re.fullmatch(r'LiteralCat\((.*)\)', e, flags=re.S)
    if m:
        v, w = 0, 0
        for a in split_top(m.group(1)):
            av, aw = eval_expr(env, a, scope)
            v = (v << aw) | av
            w += aw
        return (v, w)
    if re.fullmatch(r'[\w.]+', e):
        return env.lookup(e, scope)
    raise ValueError(f'无法求值: {expr!r}')

def width_of(env, name, scope):
    if name.isdigit():
        return int(name)
    v = env.lookup(name, scope)
    return v[0]

def load_object(env, text, objname, extra=None):
    """解析 `object objname { def a = …; object Nested {…} }`，把成员写进 env.objs[objname]。"""
    body = brace_block(text, r'\bobject\s+' + re.escape(objname) + r'\b')
    body = strip_comments(body)
    scope = dict(extra or {})
    # 嵌套 object（FMT / INT）：先递归装载，成员以 Nested.x 的形式可见
    for nm in re.findall(r'\bobject\s+(\w+)\s*\{', body):
        sub = brace_block(body, r'\bobject\s+' + re.escape(nm) + r'\b')
        load_object(env, body, nm)
        body = body.replace(sub, '', 1)
    members = {}
    lines = re.findall(r'(?:private\s+)?(?:def|val)\s+(\w+)\s*(?::\s*[\w.]+)?\s*=\s*([^\n]+)', body)
    pending = list(lines)
    for _ in range(3):   # 允许少量前向引用
        rest = []
        for name, rhs in pending:
            rhs = rhs.strip().rstrip(';')
            try:
                val = eval_expr(env, rhs, {**scope, **members})
            except (KeyError, ValueError):
                rest.append((name, rhs))
                continue
            members[name] = val
            scope[name] = val
        pending = rest
        if not pending:
            break
    env.objs[objname] = members
    return members, pending

def load_constants():
    env = Env()
    pkg = (SCALA / 'package.scala').read_text()
    for obj in ['SrcType', 'FuOpType', 'VlduType', 'VstuType', 'IF2VectorType', 'CSROpType',
                'JumpOpType', 'FenceOpType', 'ALUOpType', 'VSETOpType', 'BRUOpType', 'MDUOpType',
                'LSUOpType', 'BKUOpType', 'SelImm', 'UopSplitType']:
        load_object(env, pkg, obj)
    # FuType：按 addType 出现顺序编号，35 位 one-hot
    ft = (SCALA / 'backend/fu/FuType.scala').read_text()
    names = re.findall(r'val\s+(\w+)\s*=\s*addType\(', ft)
    assert len(names) == 35, len(names)
    env.objs['FuType'] = {n: (1 << i, 35) for i, n in enumerate(names)}
    env.objs['FuType']['X'] = (0, 35)
    env.fu_names = names
    # yunsuan
    ys = (YUNSUAN / 'package.scala').read_text()
    load_object(env, (YUNSUAN / 'encoding/Opcode/VialuOpcode.scala').read_text(), 'VialuOpcode')
    load_object(env, (YUNSUAN / 'encoding/Opcode/VimacOpcode.scala').read_text(), 'VimacOpcode')
    for obj in ['VfaddOpCode', 'VfmaOpCode', 'VfdivOpCode', 'VipuType', 'VidivType', 'VfpuType',
                'VpermType', 'VfcvtType', 'VialuFixType', 'VimacType', 'VfaluType', 'VfmaType', 'VfdivType']:
        load_object(env, ys, obj)
    # 求值结果的几处哨兵。★yunsuan 里 LiteralCat 行尾的 "b.." 注释有不少是陈旧的
    # （vadd_vv 注释写 b00_0_000000，按 SINT=1 算出来是 b00_1_000000），所以哨兵只取
    # 能与 golden 对上的值：真正的裁判是 UT/FM。
    assert env.objs['VialuFixType']['vadd_vv'] == (0x040, 9)
    assert env.objs['VialuFixType']['vmv_s_x'] == (int('00_1_101110'.replace('_', ''), 2), 9)
    assert env.objs['VimacType']['vmul'] == (int('00_110_0_000'.replace('_', ''), 2), 9)
    assert env.objs['VfaluType']['fminm'][0] == int('11110', 2)
    assert env.objs['SelImm']['INVALID_INSTR'] == (6, 4)
    assert env.objs['UopSplitType']['VEC_VRED'] == (0x24, 6)
    assert env.objs['LSUOpType']['amocas_q'] == (0x2C, 6)
    assert env.objs['VSETOpType']['csrrvl'] == (0x16, 8)
    return env

# ---------------------------------------------------------------------------
# 3. 译码表：Scala 的 case class 语义（位置参数 + 命名参数 + 默认值）
# ---------------------------------------------------------------------------
FLAG_NAMES = ['xWen', 'fWen', 'vWen', 'xsTrap', 'noSpec', 'blockBack', 'flushPipe', 'canRobCompress']

class Row:
    """一行译码结果 = XSDecode.generate() 的 15 列，其中 vecWen = vWen || mWen。"""
    def __init__(self, src1, src2, src3, fu, fuOp, selImm, split, xWen, fWen, vWen, mWen,
                 xsTrap, noSpec, blockBack, flushPipe, canRobCompress):
        self.src = (src1, src2, src3)
        self.fu, self.fuOp, self.selImm, self.split = fu, fuOp, selImm, split
        self.flags = dict(xWen=xWen, fWen=fWen, vWen=(vWen or mWen), xsTrap=xsTrap, noSpec=noSpec,
                          blockBack=blockBack, flushPipe=flushPipe, canRobCompress=canRobCompress)

def bind(sig, args, kwargs):
    """sig: [(name, default_or_None)]；返回按名字绑定的 dict。default None = 必填。"""
    names = [n for n, _ in sig]
    out = {n: d for n, d in sig if d is not None}
    if len(args) > len(sig):
        raise ValueError('位置参数过多')
    # Scala 允许命名参数之后再接位置参数（位置按签名顺序继续），这里按同样规则处理
    pos = 0
    for a in args:
        while pos < len(names) and names[pos] in kwargs:
            pos += 1
        out[names[pos]] = a
        pos += 1
    out.update(kwargs)
    missing = [n for n in names if n not in out]
    assert not missing, f'缺参数 {missing}'
    return out

class Ctors:
    def __init__(self, env):
        self.env = env
        E = env.objs
        self.SRC = E['SrcType']
        self.SEL = E['SelImm']
        self.SPL = E['UopSplitType']
        self.FU = E['FuType']

    def value(self, tok):
        t = tok.strip()
        if t == 'T':
            return True
        if t == 'F':
            return False
        return self.env.lookup(t)

    def XSDecode(self, args, kw):
        sig = [('src1', None), ('src2', None), ('src3', None), ('fu', None), ('fuOp', None), ('selImm', None),
               ('uopSplitType', self.SPL['X']), ('xWen', False), ('fWen', False), ('vWen', False), ('mWen', False),
               ('xsTrap', False), ('noSpec', False), ('blockBack', False), ('flushPipe', False),
               ('canRobCompress', False)]
        b = bind(sig, args, kw)
        return Row(b['src1'], b['src2'], b['src3'], b['fu'], b['fuOp'], b['selImm'], b['uopSplitType'],
                   b['xWen'], b['fWen'], b['vWen'], b['mWen'], b['xsTrap'], b['noSpec'], b['blockBack'],
                   b['flushPipe'], b['canRobCompress'])

    def FDecode(self, args, kw):
        sig = [('src1', None), ('src2', None), ('src3', None), ('fu', None), ('fuOp', None), ('selImm', self.SEL['X']),
               ('uopSplitType', self.SPL['X']), ('xWen', False), ('fWen', False), ('vWen', False), ('mWen', False),
               ('xsTrap', False), ('noSpec', False), ('blockBack', False), ('flushPipe', False),
               ('canRobCompress', False)]
        b = bind(sig, args, kw)
        return self.XSDecode([], b)

    def OPIVV(self, args, kw):
        sig = [('fu', None), ('fuOp', None), ('vWen', None), ('mWen', None), ('vxsatWen', None),
               ('uopSplitType', self.SPL['VEC_VVV']), ('src1', self.SRC['vp']), ('src2', self.SRC['vp']), ('src3', self.SRC['vp'])]
        b = bind(sig, args, kw)
        return Row(b['src1'], b['src2'], b['src3'], b['fu'], b['fuOp'], self.SEL['X'], b['uopSplitType'],
                   False, False, b['vWen'], b['mWen'], False, False, False, False, False)

    def OPIVX(self, args, kw):
        sig = [('fu', None), ('fuOp', None), ('vWen', None), ('mWen', None), ('vxsatWen', None),
               ('uopSplitType', self.SPL['VEC_VXV']), ('src1', self.SRC['xp']), ('src2', self.SRC['vp']), ('src3', self.SRC['vp'])]
        b = bind(sig, args, kw)
        return Row(b['src1'], b['src2'], b['src3'], b['fu'], b['fuOp'], self.SEL['X'], b['uopSplitType'],
                   False, False, b['vWen'], b['mWen'], False, False, False, False, False)

    def OPIVI(self, args, kw):
        sig = [('fu', None), ('fuOp', None), ('vWen', None), ('mWen', None), ('vxsatWen', None),
               ('selImm', self.SEL['IMM_OPIVIS']), ('uopSplitType', self.SPL['VEC_VXV']),
               ('src1', self.SRC['imm']), ('src2', self.SRC['vp']), ('src3', self.SRC['vp'])]
        b = bind(sig, args, kw)
        return Row(b['src1'], b['src2'], b['src3'], b['fu'], b['fuOp'], b['selImm'], b['uopSplitType'],
                   False, False, b['vWen'], b['mWen'], False, False, False, False, False)

    def OPMVV(self, args, kw):
        sig = [('vdRen', None), ('fu', None), ('fuOp', None), ('xWen', None), ('vWen', None), ('mWen', None),
               ('uopSplitType', self.SPL['dummy']), ('src1', self.SRC['vp']), ('src2', self.SRC['vp'])]
        b = bind(sig, args, kw)
        src3 = self.SRC['vp'] if b['vdRen'] else self.SRC['X']
        return Row(b['src1'], b['src2'], src3, b['fu'], b['fuOp'], self.SEL['X'], b['uopSplitType'],
                   b['xWen'], False, b['vWen'], b['mWen'], False, False, False, False, False)

    def OPMVX(self, args, kw):
        sig = [('vdRen', None), ('fu', None), ('fuOp', None), ('xWen', None), ('vWen', None), ('mWen', None),
               ('uopSplitType', self.SPL['dummy']), ('src1', self.SRC['xp']), ('src2', self.SRC['vp'])]
        b = bind(sig, args, kw)
        src3 = self.SRC['vp'] if b['vdRen'] else self.SRC['X']
        return Row(b['src1'], b['src2'], src3, b['fu'], b['fuOp'], self.SEL['X'], b['uopSplitType'],
                   b['xWen'], False, b['vWen'], b['mWen'], False, False, False, False, False)

    def OPFVV(self, args, kw):
        sig = [('src1', None), ('src3', None), ('fu', None), ('fuOp', None), ('fWen', None), ('vWen', None), ('mWen', None),
               ('uopSplitType', self.SPL['dummy']), ('src2', self.SRC['vp'])]
        b = bind(sig, args, kw)
        return Row(b['src1'], b['src2'], b['src3'], b['fu'], b['fuOp'], self.SEL['X'], b['uopSplitType'],
                   False, b['fWen'], b['vWen'], b['mWen'], False, False, False, False, False)

    def OPFVF(self, args, kw):
        return self.OPFVV(args, kw)

    def OPFFF(self, args, kw):
        sig = [('src1', None), ('src2', None), ('src3', None), ('fu', None), ('fuOp', None), ('xWen', None),
               ('fWen', None), ('vWen', None), ('uopSplitType', self.SPL['dummy'])]
        b = bind(sig, args, kw)
        return Row(b['src1'], b['src2'], b['src3'], b['fu'], b['fuOp'], self.SEL['X'], b['uopSplitType'],
                   b['xWen'], b['fWen'], b['vWen'], False, False, False, False, False, True)

    def VSET(self, args, kw):
        sig = [('vli', None), ('vtypei', None), ('fuOp', None), ('flushPipe', None), ('blockBack', None),
               ('selImm', None), ('uopSplitType', self.SPL['VSET'])]
        b = bind(sig, args, kw)
        src1 = self.SRC['imm'] if b['vli'] else self.SRC['xp']
        src2 = self.SRC['imm'] if b['vtypei'] else self.SRC['xp']
        return Row(src1, src2, self.SRC['X'], self.FU['vsetiwf'], b['fuOp'], b['selImm'], b['uopSplitType'],
                   False, False, False, False, False, False, b['blockBack'], b['flushPipe'], False)

    def VLD(self, args, kw):
        sig = [('src2', None), ('fuOp', None), ('strided', False), ('indexed', False), ('ff', False), ('mask', False),
               ('whole', False), ('ordered', False), ('uopSplitType', self.SPL['VEC_US_LDST'])]
        b = bind(sig, args, kw)
        return Row(self.SRC['xp'], b['src2'], self.SRC['vp'], self.FU['vldu'], b['fuOp'], self.SEL['X'], b['uopSplitType'],
                   False, False, True, False, False, False, False, False, False)

    def VST(self, args, kw):
        sig = [('src2', None), ('fuOp', None), ('strided', False), ('indexed', False), ('mask', False),
               ('whole', False), ('ordered', False), ('uopSplitType', self.SPL['VEC_US_LDST'])]
        b = bind(sig, args, kw)
        return Row(self.SRC['xp'], b['src2'], self.SRC['vp'], self.FU['vstu'], b['fuOp'], self.SEL['X'], b['uopSplitType'],
                   False, False, False, False, False, False, False, False, False)

ENTRY_RE = re.compile(r'^\s*(\w+)\s*->\s*(\w+)\((.*)\)\s*,?\s*$')

def split_code_comment(line):
    """把一行拆成 (代码, 行尾注释)；注释里可能含括号，先拆再解析。"""
    if '//' in line:
        i = line.index('//')
        return line[:i], line[i + 2:].strip()
    return line, ''

def parse_array(body, ctors):
    """body = Array( … ) 的内部文本（保留注释）。返回 [(mnemonic, ctor, Row, comments_before, trailing_comment)]。"""
    entries, pending = [], []
    for line in body.split('\n'):
        s = line.strip()
        if not s:
            pending.append('')
            continue
        if s.startswith('//'):
            pending.append(s[2:].strip())
            continue
        if s.startswith('/*') or s.startswith('*'):
            continue
        code, trail = split_code_comment(line)
        m = ENTRY_RE.match(code)
        assert m, f'无法解析表项: {line!r}'
        mnem, ctor, argtxt = m.groups()
        args, kw = [], {}
        for a in split_top(argtxt):
            if re.match(r'^\w+\s*=[^=]', a):
                k, v = a.split('=', 1)
                kw[k.strip()] = ctors.value(v)
            else:
                args.append(ctors.value(a))
        row = getattr(ctors, ctor)(args, kw)
        # 去掉首尾空行，保留中间的空行作为分组分隔
        while pending and pending[0] == '':
            pending.pop(0)
        entries.append((mnem, ctor, row, pending, trail))
        pending = []
    return entries

def load_table(env):
    ctors = Ctors(env)
    du = (SCALA / 'backend/decode/DecodeUnit.scala').read_text()
    vd = (SCALA / 'backend/decode/VecDecoder.scala').read_text()

    def obj_array(text, obj):
        body = brace_block(text, r'\bobject\s+' + re.escape(obj) + r'\b')
        arr = paren_block(body, r'decodeArray[^=]*=\s*Array')
        return parse_array(arr, ctors)

    def val_array(text, val):
        arr = paren_block(text, r'\bval\s+' + re.escape(val) + r'\s*:[^=]*=\s*Array')
        return parse_array(arr, ctors)

    # 表序 = DecodeUnit.scala 里 decode_table 的 ++ 顺序（FDivSqrtDecode 被注释掉，不在表里）
    order_du = re.search(r'val decode_table[^=]*=\s*(.*?)\n\s*\n', du, flags=re.S).group(1)
    # 被 // 注释掉的行（FDivSqrtDecode）不在表里
    order = [t for t in re.findall(r'^\s*(\w+)\.table', order_du, flags=re.M)]
    assert order == ['XDecode', 'FpDecode', 'BitmanipDecode', 'ScalarCryptoDecode', 'XSDebugDecode', 'CBODecode',
                     'SvinvalDecode', 'HypervisorDecode', 'VecDecoder', 'ZicondDecode', 'ZimopDecode', 'ZfaDecode'], order
    vec_order = re.search(r'override val decodeArray[^=]*=\s*(.*?)\n\}', vd, flags=re.S).group(1)
    vec_vals = re.findall(r'(\w+)', vec_order)
    vec_vals = [v for v in vec_vals if v in ('vset', 'opivv', 'opivx', 'opivi', 'opmvv', 'opmvx', 'opfvv', 'opfvf', 'opfff', 'vls')]
    assert vec_vals == ['vset', 'opivv', 'opivx', 'opivi', 'opmvv', 'opmvx', 'opfvv', 'opfvf', 'opfff', 'vls'], vec_vals

    sections = []
    for obj in order:
        if obj == 'VecDecoder':
            for v in vec_vals:
                sections.append((f'VecDecoder.{v}', val_array(vd, v)))
        else:
            sections.append((obj, obj_array(du, obj)))
    return sections

# ---------------------------------------------------------------------------
# 4. golden 对账：匹配项序列
# ---------------------------------------------------------------------------
INSTR = 'io_enq_ctrlFlow_instr'

SLICE_RE = re.compile(INSTR + r'\[(\d+)(?::(\d+))?\]')

def instr_slices(text):
    """{instr[a:b], instr[c], …} -> [(a,b),(c,c),…]；要求花括号里只有 instr 切片。"""
    parts = SLICE_RE.findall(text)
    assert len(parts) == text.count(INSTR), text
    return [(int(a), int(b) if b else int(a)) for a, b in parts]

def golden_match_terms(gtext):
    """按定义顺序返回 golden 里所有译码匹配项的 (mask, value)。"""
    body = gtext[gtext.index('module DecodeUnit('):]
    # _GEN_k = {instr[a:b], …}
    gens = {}
    for m in re.finditer(r'wire\s+\[\d+:0\]\s+(_GEN(?:_\d+)?)\s*=\s*(\{[^;]*\});', body):
        if m.group(2).count(INSTR) != len(SLICE_RE.findall(m.group(2))) or INSTR not in m.group(2):
            continue
        gens[m.group(1)] = instr_slices(m.group(2))
    terms = []
    for m in re.finditer(r'wire\s+_decodedInst_decoder_T_\d+\s*=\s*([^;]+);', body):
        rhs = ' '.join(m.group(1).split())
        mm = re.fullmatch(r'(.+?)\s*==\s*\d+\'h([0-9A-Fa-f]+)', rhs)
        if not mm:
            continue     # 同名前缀下也有字段表达式（firtool 复用了 _T_ 编号），只取 `== 常量` 的匹配项
        lhs, val = mm.group(1).strip(), int(mm.group(2), 16)
        if lhs.startswith('_GEN'):
            slices = gens[lhs]
        elif lhs.startswith('{'):
            slices = instr_slices(lhs)
        elif lhs == INSTR:
            slices = [(31, 0)]
        else:
            slices = instr_slices(lhs)
            assert len(slices) == 1, rhs
        mask = value = 0
        # 拼接顺序：第一个切片在最高位
        total = sum(a - b + 1 for a, b in slices)
        pos = total
        for a, b in slices:
            w = a - b + 1
            pos -= w
            chunk = (val >> pos) & ((1 << w) - 1)
            mask |= ((1 << w) - 1) << b
            value |= chunk << b
        terms.append((mask, value))
    return terms

# ---------------------------------------------------------------------------
# 5. 端口表 / struct
# ---------------------------------------------------------------------------
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')

def parse_ports(gtext):
    start = gtext.index('module DecodeUnit(')
    end = gtext.index(');', start)
    ports = []
    for line in gtext[start:end].split('\n')[1:]:
        m = PORT_RE.match(line)
        if m:
            d, hi, name = m.groups()
            ports.append((d, (int(hi) + 1) if hi else 1, name))
    assert len(ports) == 172, len(ports)
    return ports

def wdecl(w):
    return f'logic [{w-1}:0]' if w > 1 else 'logic      '

def emit_structs(ports):
    """static_inst_t（io_enq_ctrlFlow_*）/ csr_to_decode_t（io_fromCSR_*）/ decoded_inst_t（io_deq_decodedInst_*）。"""
    L = []
    def struct(name, prefix, arrays, note):
        fields = [(w, n[len(prefix):]) for d, w, n in ports if n.startswith(prefix)]
        L.append(f'  // {note}')
        L.append(f'  // 成员名与位宽由 {TAG} 从 golden 的 {prefix}* 端口机械生成，与 golden 逐字同名。')
        L.append('  typedef struct packed {')
        done = set()
        for w, n in fields:
            hit = None
            for pfx, (mem, cnt) in arrays.items():
                if n.startswith(pfx) and n[len(pfx):].isdigit():
                    hit = (mem, cnt)
            if hit:
                if hit[0] in done:
                    continue
                done.add(hit[0])
                L.append(f'    logic [{hit[1]-1}:0][{w-1}:0] {hit[0]};' if w > 1 else f'    logic [{hit[1]-1}:0] {hit[0]};')
            else:
                L.append(f'    {wdecl(w)} {n};')
        L.append(f'  }} {name};')
        L.append('')
        return fields
    in_fields = struct('static_inst_t', 'io_enq_ctrlFlow_', {'exceptionVec_': ('exceptionVec', 24)},
                       'IBuffer 送来的一条静态指令（StaticInst）。golden 输入端口没有 exceptionVec_3/_22'
                       '（本模块整段改写它们，firtool 删了入口），wrapper 给这两位喂 0。')
    struct('csr_to_decode_t', 'io_fromCSR_', {},
           'CSR 给译码的"当前特权态下哪些指令非法/虚拟非法"标志（CSRToDecode）。')
    out_fields = struct('decoded_inst_t', 'io_deq_decodedInst_',
                        {'exceptionVec_': ('exceptionVec', 24), 'srcType_': ('srcType', 5), 'lsrc_': ('lsrc', 3)},
                        '译码结果（DecodedInst，送 DecodeStage 再往 Rename）。')
    in_names = {n for _, n in in_fields}
    out_names = {n for _, n in out_fields}
    # 断言期望差集：golden 输入缺 exceptionVec_3/_22，输出多出的字段固定
    assert {f'exceptionVec_{i}' for i in range(24)} - in_names == {'exceptionVec_3', 'exceptionVec_22'}, in_names
    only_out = out_names - in_names
    expect_only_out = {'exceptionVec_3', 'exceptionVec_22', 'srcType_0', 'srcType_1', 'srcType_2', 'srcType_3', 'srcType_4',
                       'lsrc_0', 'lsrc_1', 'lsrc_2', 'ldest', 'fuType', 'fuOpType', 'rfWen', 'fpWen', 'vecWen', 'isXSTrap',
                       'waitForward', 'blockBackward', 'flushPipe', 'canRobCompress', 'selImm', 'imm',
                       'fpu_typeTagOut', 'fpu_wflags', 'fpu_typ', 'fpu_fmt', 'fpu_rm',
                       'vpu_vill', 'vpu_vma', 'vpu_vta', 'vpu_vsew', 'vpu_vlmul', 'vpu_specVill', 'vpu_specVma', 'vpu_specVta',
                       'vpu_specVsew', 'vpu_specVlmul', 'vpu_vm', 'vpu_vstart', 'vpu_nf', 'vpu_veew', 'vpu_isReverse', 'vpu_isExt',
                       'vpu_isNarrow', 'vpu_isDstMask', 'vpu_isOpMask', 'vpu_isDependOldVd', 'vpu_isWritePartVd', 'vpu_isVleff',
                       'vlsInstr', 'wfflags', 'isMove', 'uopSplitType', 'isVset', 'commitType', 'debug_fuType'}
    assert only_out == expect_only_out, (only_out ^ expect_only_out)
    assert in_names - out_names == {'isLastInFtqEntry'}, in_names - out_names
    return L, in_fields, out_fields

def emit_ports(ports):
    L = [f'  // 端口表由 {TAG} 逐字取自 golden DecodeUnit.sv（顺序/位宽/名字一致，port_contract_lint --order fail）。']
    for i, (d, w, n) in enumerate(ports):
        comma = ',' if i < len(ports) - 1 else ''
        ww = f'[{w-1}:0] ' if w > 1 else ''
        L.append(f'  {d:6s} {ww:8s}{n}{comma}')
    return L

def emit_wrapper(ports, in_fields, out_fields):
    L = [f'  // 接线由 {TAG} 机械生成：输入打包成 struct 喂给可读核，核的输出摊回 golden 端口。']
    L.append('  static_inst_t   enq;')
    L.append('  vtype_t         enq_vtype;')
    L.append('  csr_to_decode_t from_csr;')
    L.append('  decoded_inst_t  deq;')
    L.append('  uop_info_t      deq_uop_info;')
    L.append('')
    for w, n in in_fields:
        m = re.fullmatch(r'exceptionVec_(\d+)', n)
        lhs = f'enq.exceptionVec[{m.group(1)}]' if m else f'enq.{n}'
        L.append(f'  assign {lhs} = io_enq_ctrlFlow_{n};')
    L.append('  // golden 输入端口没有的两位（本模块整段改写它们）')
    L.append("  assign enq.exceptionVec[3]  = 1'b0;")
    L.append("  assign enq.exceptionVec[22] = 1'b0;")
    for f in ['illegal', 'vma', 'vta', 'vsew', 'vlmul']:
        L.append(f'  assign enq_vtype.{f} = io_enq_vtype_{f};')
    for d, w, n in ports:
        if n.startswith('io_fromCSR_'):
            L.append(f'  assign from_csr.{n[len("io_fromCSR_"):]} = {n};')
    L.append('')
    L.append('  xs_DecodeUnit_core u_core (')
    L.append('    .enq            (enq),')
    L.append('    .enq_vtype      (enq_vtype),')
    L.append('    .enq_vstart     (io_enq_vstart),')
    L.append('    .csr_singlestep (io_csrCtrl_singlestep),')
    L.append('    .from_csr       (from_csr),')
    L.append('    .deq            (deq),')
    L.append('    .deq_is_complex (io_deq_isComplex),')
    L.append('    .deq_uop_info   (deq_uop_info)')
    L.append('  );')
    L.append('')
    for w, n in out_fields:
        m = re.fullmatch(r'(exceptionVec|srcType|lsrc)_(\d+)', n)
        rhs = f'deq.{m.group(1)}[{m.group(2)}]' if m else f'deq.{n}'
        L.append(f'  assign io_deq_decodedInst_{n} = {rhs};')
    for f in ['numOfUop', 'numOfWB', 'lmul']:
        L.append(f'  assign io_deq_uopInfo_{f} = deq_uop_info.{f};')
    return L

# ---------------------------------------------------------------------------
# 6. 译码表 SV 文本
# ---------------------------------------------------------------------------
def sv_bits(bits):
    return "32'b" + bits.replace('?', 'z')

SRC_NAME = {}   # (val) -> 首选名（imm/pc/no/DC/X 全是 0，按 Scala 写法保留原名）

def src_sv(tokname):
    return 'SRC_' + tokname.split('.')[1].upper()

def fu_name(env, v):
    for n, (val, _) in env.objs['FuType'].items():
        if val == v and n != 'X':
            return 'FU_' + n.upper()
    assert v == 0
    return 'FU_X'

OP_FAMILIES = ['FuOpType', 'ALUOpType', 'BKUOpType', 'MDUOpType', 'JumpOpType', 'BRUOpType', 'CSROpType', 'FenceOpType',
               'LSUOpType', 'VlduType', 'VstuType', 'VSETOpType', 'IF2VectorType',
               'VialuFixType', 'VimacType', 'VipuType', 'VidivType', 'VpermType', 'VfaluType', 'VfmaType',
               'VfdivType', 'VfcvtType', 'VfpuType']
FAMILY_PREFIX = {'FuOpType': 'FUOP', 'ALUOpType': 'ALU', 'BKUOpType': 'BKU', 'MDUOpType': 'MDU', 'JumpOpType': 'JMP', 'BRUOpType': 'BRU',
                 'CSROpType': 'CSR', 'FenceOpType': 'FENCE', 'LSUOpType': 'LSU', 'VlduType': 'VLDU', 'VstuType': 'VSTU',
                 'VSETOpType': 'VSET', 'IF2VectorType': 'I2V', 'VialuFixType': 'VIALU', 'VimacType': 'VIMAC',
                 'VipuType': 'VIPU', 'VidivType': 'VIDIV', 'VpermType': 'VPERM', 'VfaluType': 'VFALU', 'VfmaType': 'VFMA',
                 'VfdivType': 'VFDIV', 'VfcvtType': 'VFCVT', 'VfpuType': 'VFPU'}

def build_table_text(env, sections, insn, extra_pats=()):
    """返回 (patterns_lines, table_lines, entries_flat, opname_used)。"""
    # 记住每个表项在 Scala 里引用的 fuOp 名字：重新扫一遍源码文本拿 token（求值时已丢失名字）
    ctors_tokens = collect_tokens(sections)
    pat_lines, tbl_lines = [], []
    used_ops = {}       # 'ALU_add' -> (val, family)
    used_pats = {}
    flat = []
    for secname, entries in sections:
        tbl_lines.append('')
        tbl_lines.append(f'      // ======== {secname} ========')
        for mnem, ctor, row, comments, trail in entries:
            for c in comments:
                tbl_lines.append('' if c == '' else f'      // {c}')
            toks = ctors_tokens[(secname, mnem)]
            s1, s2, s3 = (src_sv(t) for t in toks['src'])
            fu = fu_name(env, row.fu[0])
            opn = toks['fuOp']
            if opn == 'FuOpType.X':
                op_sv = 'OP_X'
            else:
                fam, nm = opn.split('.')
                op_sv = f'{FAMILY_PREFIX[fam]}_{nm}'
                used_ops[op_sv] = (row.fuOp[0], fam, nm)
            sel = 'SELIMM_X' if toks['selImm'] == 'SelImm.X' else toks['selImm'].split('.')[1]
            assert env.objs['SelImm'][toks['selImm'].split('.')[1]] == row.selImm
            spl = toks['split'].split('.')[1]
            spl_sv = 'SPLIT_X' if spl == 'X' else 'SPLIT_' + spl.upper()
            assert env.objs['UopSplitType'][spl] == row.split
            flags = [FLAG_SV[k] for k in FLAG_NAMES if row.flags[k]]
            flag_sv = ' | '.join(flags) if flags else 'NOFLAG'
            mask, val, bits = insn[mnem]
            used_pats[mnem] = bits
            line = f'      {mnem:15s}: d = R({s1:7s}, {s2:7s}, {s3:7s}, {fu:12s}, {op_sv:20s}, {sel:12s}, {spl_sv:20s}, {flag_sv});'
            if trail:
                line += f'  // {trail}'
            tbl_lines.append(line)
            flat.append((mnem, mask, val))
    extra = sorted(n for n in extra_pats if n not in used_pats)
    for mnem, bits in used_pats.items():
        pat_lines.append(f'  localparam logic [31:0] {mnem:16s} = {sv_bits(bits)};')
    if extra:
        pat_lines.append('  // 下面这些只出现在指令集合判据里（不在译码表中）')
        for mnem in extra:
            pat_lines.append(f'  localparam logic [31:0] {mnem:16s} = {sv_bits(insn[mnem][2])};')
    return pat_lines, tbl_lines, flat, used_ops

FLAG_SV = {'xWen': 'XWEN', 'fWen': 'FWEN', 'vWen': 'VWEN', 'xsTrap': 'XSTRAP', 'noSpec': 'NOSPEC',
           'blockBack': 'BLOCKBACK', 'flushPipe': 'FLUSHPIPE', 'canRobCompress': 'ROBCOMP'}

def collect_tokens(sections):
    """第二遍扫源码，取每个表项的 src/fuOp/selImm/split **名字**（给 SV 用助记名而不是数）。"""
    du = (SCALA / 'backend/decode/DecodeUnit.scala').read_text()
    vd = (SCALA / 'backend/decode/VecDecoder.scala').read_text()
    out = {}
    for secname, entries in sections:
        if secname.startswith('VecDecoder.'):
            text = paren_block(vd, r'\bval\s+' + secname.split('.')[1] + r'\s*:[^=]*=\s*Array')
        else:
            text = paren_block(brace_block(du, r'\bobject\s+' + secname + r'\b'), r'decodeArray[^=]*=\s*Array')
        for line in text.split('\n'):
            m = ENTRY_RE.match(split_code_comment(line)[0])
            if not m:
                continue
            mnem, ctor, argtxt = m.groups()
            args, kw = [], {}
            for a in split_top(argtxt):
                if re.match(r'^\w+\s*=[^=]', a):
                    k, v = a.split('=', 1)
                    kw[k.strip()] = v.strip()
                else:
                    args.append(a.strip())
            out[(secname, mnem)] = ctor_tokens(ctor, args, kw)
    return out

def ctor_tokens(ctor, args, kw):
    """与 Ctors 同一套签名，但只做名字绑定。"""
    def bnd(sig):
        return bind(sig, args, kw)
    if ctor in ('XSDecode', 'FDecode'):
        b = bnd([('src1', None), ('src2', None), ('src3', None), ('fu', None), ('fuOp', None),
                 ('selImm', 'SelImm.X'), ('uopSplitType', 'UopSplitType.X')] + [(f, 'F') for f in ['xWen', 'fWen', 'vWen', 'mWen', 'xsTrap', 'noSpec', 'blockBack', 'flushPipe', 'canRobCompress']])
        return dict(src=[b['src1'], b['src2'], b['src3']], fuOp=b['fuOp'], selImm=b['selImm'], split=b['uopSplitType'])
    if ctor == 'OPIVV':
        b = bnd([('fu', None), ('fuOp', None), ('vWen', None), ('mWen', None), ('vxsatWen', None),
                 ('uopSplitType', 'UopSplitType.VEC_VVV'), ('src1', 'SrcType.vp'), ('src2', 'SrcType.vp'), ('src3', 'SrcType.vp')])
        return dict(src=[b['src1'], b['src2'], b['src3']], fuOp=b['fuOp'], selImm='SelImm.X', split=b['uopSplitType'])
    if ctor == 'OPIVX':
        b = bnd([('fu', None), ('fuOp', None), ('vWen', None), ('mWen', None), ('vxsatWen', None),
                 ('uopSplitType', 'UopSplitType.VEC_VXV'), ('src1', 'SrcType.xp'), ('src2', 'SrcType.vp'), ('src3', 'SrcType.vp')])
        return dict(src=[b['src1'], b['src2'], b['src3']], fuOp=b['fuOp'], selImm='SelImm.X', split=b['uopSplitType'])
    if ctor == 'OPIVI':
        b = bnd([('fu', None), ('fuOp', None), ('vWen', None), ('mWen', None), ('vxsatWen', None),
                 ('selImm', 'SelImm.IMM_OPIVIS'), ('uopSplitType', 'UopSplitType.VEC_VXV'),
                 ('src1', 'SrcType.imm'), ('src2', 'SrcType.vp'), ('src3', 'SrcType.vp')])
        return dict(src=[b['src1'], b['src2'], b['src3']], fuOp=b['fuOp'], selImm=b['selImm'], split=b['uopSplitType'])
    if ctor in ('OPMVV', 'OPMVX'):
        b = bnd([('vdRen', None), ('fu', None), ('fuOp', None), ('xWen', None), ('vWen', None), ('mWen', None),
                 ('uopSplitType', 'UopSplitType.dummy'), ('src1', 'SrcType.vp' if ctor == 'OPMVV' else 'SrcType.xp'), ('src2', 'SrcType.vp')])
        src3 = 'SrcType.vp' if b['vdRen'] == 'T' else 'SrcType.X'
        return dict(src=[b['src1'], b['src2'], src3], fuOp=b['fuOp'], selImm='SelImm.X', split=b['uopSplitType'])
    if ctor in ('OPFVV', 'OPFVF'):
        b = bnd([('src1', None), ('src3', None), ('fu', None), ('fuOp', None), ('fWen', None), ('vWen', None), ('mWen', None),
                 ('uopSplitType', 'UopSplitType.dummy'), ('src2', 'SrcType.vp')])
        return dict(src=[b['src1'], b['src2'], b['src3']], fuOp=b['fuOp'], selImm='SelImm.X', split=b['uopSplitType'])
    if ctor == 'OPFFF':
        b = bnd([('src1', None), ('src2', None), ('src3', None), ('fu', None), ('fuOp', None), ('xWen', None),
                 ('fWen', None), ('vWen', None), ('uopSplitType', 'UopSplitType.dummy')])
        return dict(src=[b['src1'], b['src2'], b['src3']], fuOp=b['fuOp'], selImm='SelImm.X', split=b['uopSplitType'])
    if ctor == 'VSET':
        b = bnd([('vli', None), ('vtypei', None), ('fuOp', None), ('flushPipe', None), ('blockBack', None),
                 ('selImm', None), ('uopSplitType', 'UopSplitType.VSET')])
        src1 = 'SrcType.imm' if b['vli'] == 'T' else 'SrcType.xp'
        src2 = 'SrcType.imm' if b['vtypei'] == 'T' else 'SrcType.xp'
        return dict(src=[src1, src2, 'SrcType.X'], fuOp=b['fuOp'], selImm=b['selImm'], split=b['uopSplitType'])
    if ctor in ('VLD', 'VST'):
        b = bnd([('src2', None), ('fuOp', None), ('strided', 'F'), ('indexed', 'F')] + ([('ff', 'F')] if ctor == 'VLD' else []) +
                [('mask', 'F'), ('whole', 'F'), ('ordered', 'F'), ('uopSplitType', 'UopSplitType.VEC_US_LDST')])
        return dict(src=['SrcType.xp', b['src2'], 'SrcType.vp'], fuOp=b['fuOp'], selImm='SelImm.X', split=b['uopSplitType'])
    raise ValueError(ctor)

def emit_constants(env, used_ops):
    """fuOpType 助记常量：只列表里用到的，按家族分组，值来自源码求值。"""
    L = []
    by_fam = {}
    for sv, (val, fam, nm) in used_ops.items():
        by_fam.setdefault(fam, []).append((sv, val, nm))
    for fam in OP_FAMILIES:
        if fam not in by_fam:
            continue
        L.append(f'  // ---- {fam}（xiangshan/package.scala 或 yunsuan/package.scala）----')
        for sv, val, nm in sorted(by_fam[fam], key=lambda t: (t[1], t[0])):
            L.append(f"  localparam logic [8:0] {sv:22s} = 9'h{val:03X};")
    return L

# ---------------------------------------------------------------------------
# 6b. 指令集合判据：DecodeUnit.scala 里 `private val xxxInsts = Seq(A, B, …)`，
#     Chisel 写成 `insts.map(_ === inst.ALL).reduce(_ || _)`；这里翻成一个 casez 函数。
# ---------------------------------------------------------------------------
INSN_SETS = [   # (Scala val 名, SV 函数名, 说明)
    ('needReverseInsts',   'is_reverse_insn',        'vpu.isReverse：源操作数要换位的指令（vrsub / vfrdiv / vfrsub / vfmv.f.s）'),
    ('vextInsts',          'is_vext_insn',           'vpu.isExt：整数扩展 vzext/vsext'),
    ('narrowInsts',        'is_narrow_insn',         'vpu.isNarrow：窄化指令 vnsra/vnsrl/vnclip(u)'),
    ('maskDstInsts',       'is_mask_dst_insn',       'vpu.isDstMask：结果写掩码寄存器的指令'),
    ('maskOpInsts',        'is_mask_op_insn',        'vpu.isOpMask：掩码逻辑指令 vm{and,nand,andn,xor,or,nor,orn,xnor}.mm'),
    ('vmaInsts',           'is_vma_insn',            '乘加类（依赖旧 vd）：vmacc/vnmsac/vmadd/vnmsub/vwmacc*'),
    ('wfflagsInsts',       'is_wfflags_insn',        'decodedInst.wfflags：会写 fflags 的标量/向量浮点指令'),
    ('scalaNeedFrmInsts',  'is_scalar_need_frm_insn', 'needFrm.scalaNeedFrm：标量浮点里要读 frm 的指令'),
    ('vectorNeedFrmInsts', 'is_vector_need_frm_insn', 'needFrm.vectorNeedFrm：vfslide1up/down.vf'),
]

def load_insn_sets(insn):
    du = (SCALA / 'backend/decode/DecodeUnit.scala').read_text()
    out = []
    for sc, sv, note in INSN_SETS:
        body = paren_block(du, r'private val ' + sc + r'\s*=\s*Seq')
        names = re.findall(r'\b([A-Z][A-Z0-9_]+)\b', strip_comments(body))
        assert names, sc
        for n in names:
            assert n in insn, (sc, n)
        out.append((sc, sv, note, names))
    return out

def emit_insn_sets(sets):
    L = [f'  // 由 {TAG} 从 DecodeUnit.scala 的 `private val xxxInsts = Seq(…)` 机械生成；',
         '  // Chisel 写法 `insts.map(_ === inst.ALL).reduce(_ || _)` 翻成 casez（z 位=通配）。']
    for sc, sv, note, names in sets:
        L.append('')
        L.append(f'  // {note}（Scala: {sc}，{len(names)} 条）')
        L.append(f'  function automatic logic {sv}(input logic [31:0] i);')
        L.append('    casez (i)')
        for k in range(0, len(names), 6):
            chunk = ', '.join(names[k:k + 6])
            tail = ':' if k + 6 >= len(names) else ','
            L.append(f'      {chunk}{tail}')
        L.append("        return 1'b1;")
        L.append("      default: return 1'b0;")
        L.append('    endcase')
        L.append('  endfunction')
    return L

# ---------------------------------------------------------------------------
# 7. tb.sv
# ---------------------------------------------------------------------------
def emit_tb(ports, flat, shadowed):
    ins = [(w, n) for d, w, n in ports if d == 'input']
    outs = [(w, n) for d, w, n in ports if d == 'output']
    L = []
    A = L.append
    A('// =============================================================================')
    A('// DecodeUnit UT —— golden DecodeUnit 对重写 DecodeUnit_xs 双例化，同激励逐拍比对全部')
    A(f'// {len(outs)} 根输出线。本文件由 {TAG} 生成（幂等），不要手改。')
    A('//')
    A('// ★ 被测件是纯组合译码器：判别力全在「指令编码空间」上 ★')
    A('//   · 均匀随机 32 位字几乎只会落进"非法"一行（表里 700 多条指令的编码密度极低），')
    A('//     所以主激励是：随机挑一条表项，把它的 `?` 位随机填满 —— 每条表项都被命中过才算数；')
    A('//   · 再定向打那些"表之外"的判据：csrr vl / csrr vlenb（转 vsetvl/addi）、prefetch.{i,r,w}、')
    A('//     fli、zimop、cbo、TRAP、amocas.q 奇数寄存器、aes64ks1i 保留 rnum、NF!=0 的向量访存等；')
    A('//   · 剩余份额给全随机字（非法指令路径）。')
    A('//   · fromCSR 的 24 个标志、vtype、vstart、singlestep、isLastInFtqEntry 每拍全随机，')
    A('//     让异常判据里每个 && 的两边都有 0/1。')
    A('// 覆盖判据：表里每条**可达**的指令（前面没有更宽的模式把它整个遮住）命中次数 ≥ 1，')
    A('// 否则这一轮 errors=0 不作数。')
    A('// =============================================================================')
    A('`timescale 1ns/1ps')
    A('')
    A('module tb;')
    A('')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit  clk = 0;')
    A('  int  errors = 0;')
    A('  longint checks = 0;')
    A('  always #5 clk = ~clk;')
    A('')
    A('  // ---- 输入（两个 DUT 共用）----')
    for w, n in ins:
        A(f'  {wdecl(w)} {n};')
    A('')
    A('  // ---- 输出（各一份）----')
    for w, n in outs:
        A(f'  {wdecl(w)} g_{n}, x_{n};')
    A('')
    def inst(mod, pfx):
        A(f'  {mod} u_{pfx} (')
        conns = [f'    .{n}({n})' for w, n in ins] + [f'    .{n}({pfx}_{n})' for w, n in outs]
        A(',\n'.join(conns))
        A('  );')
        A('')
    inst('DecodeUnit', 'g')
    inst('DecodeUnit_xs', 'x')
    # 表项模式
    N = len(flat)
    A(f'  // ---- 译码表模式（{N} 条，表序）：value / mask，与 rtl 的 localparam 同源 ----')
    A(f'  localparam int NPAT = {N};')
    A('  logic [31:0] pat_val [NPAT];')
    A('  logic [31:0] pat_mask[NPAT];')
    A('  bit          pat_reach[NPAT];   // 0 = 被前面更宽的模式整个遮住（表序优先下不可达）')
    A('  int          pat_hit [NPAT];')
    A('  initial begin')
    for i, (mnem, mask, val) in enumerate(flat):
        A(f"    pat_val[{i:3d}] = 32'h{val:08X}; pat_mask[{i:3d}] = 32'h{mask:08X}; pat_reach[{i:3d}] = {0 if i in shadowed else 1};  // {mnem}")
    A('  end')
    A('')
    A('  function automatic logic [31:0] fill(input int i);')
    A('    return (pat_val[i] & pat_mask[i]) | (32\'($urandom) & ~pat_mask[i]);')
    A('  endfunction')
    A('')
    A('  // 定向激励：表之外的判据')
    A('  function automatic logic [31:0] mk_special();')
    A('    logic [4:0] rd = 5\'($urandom), rs1 = 5\'($urandom), rs2 = 5\'($urandom);')
    A('    case ($urandom_range(0, 15))')
    A("      0:  return {12'hC20, 5'h0, 3'b010, rd, 7'h73};                       // csrr rd, vl  (csrrs rd, vl, x0)")
    A("      1:  return {12'hC22, 5'h0, 3'b010, rd, 7'h73};                       // csrr rd, vlenb")
    A("      2:  return {12'hC20 | 12'($urandom_range(0,3)), 5'h0, (1'($urandom) ? 3'b110 : 3'b010), rd, 7'h73}; // csrrs/csrrsi 附近")
    A("      3:  return {7'($urandom), 5'($urandom_range(0,3)), rs1, 3'b110, 5'h0, 7'h13};  // prefetch.{i,r,w} 及邻近 ori x0")
    A("      4:  return {5'b11110, 2'($urandom), 5'h1, rs1, 3'b000, rd, 7'h53};     // fli.{h,s,d}")
    A("      5:  return {1'b1, 1'($urandom), 2'b00, 2'($urandom), 1'b0, 3'b111, 2'($urandom), rs1, 3'b100, rd, 7'h73}; // mop.r")
    A("      6:  return {1'b1, 1'($urandom), 2'b00, 2'($urandom), 1'b1, 5'($urandom), rs1, 3'b100, rd, 7'h73}; // mop.rr")
    A("      7:  return {12'h000, rs1, 3'b000, rd, 7'h13};                          // addi rd, rs1, 0 (isMove)")
    A("      8:  return {12'($urandom_range(0,4)), rs1, 3'b010, 5'h0, 7'h0F};       // cbo.*")
    A("      9:  return {12'h000, rs1, 3'b000, 5'h0, 7'h6B};                        // TRAP")
    A("      10: return {5'b00101, 1'($urandom), 1'($urandom), rs2, rs1, 3'b100, rd, 7'h2F}; // amocas.q（rd/rs2 奇偶随机）")
    A("      11: return {8'b00110001, 4'($urandom), rs1, 3'b001, rd, 7'h13};         // aes64ks1i（rnum 含保留值）")
    A("      12: return {3'($urandom), 1'b0, 2'($urandom), 1'($urandom), rs2, rs1, (1'($urandom) ? 3'b000 : 3'b110), rd, 7'h07}; // 向量 load，NF 随机")
    A("      13: return {3'($urandom), 1'b0, 2'($urandom), 1'($urandom), rs2, rs1, (1'($urandom) ? 3'b101 : 3'b111), rd, 7'h27}; // 向量 store，NF 随机")
    A("      14: return {7'($urandom), rs2, rs1, 3'b111, rd, 7'h57};                // vset* 及非法 funct3=111")
    A("      default: return {7'($urandom), rs2, rs1, 3'($urandom), rd, 7'h53};    // 随机 OP-FP（含 rm=5/6/7）")
    A('    endcase')
    A('  endfunction')
    A('')
    A('  function automatic logic [31:0] mk_instr();')
    A('    int pick = $urandom_range(0, 99);')
    A('    if (pick < 60)      return fill($urandom_range(0, NPAT - 1));')
    A('    else if (pick < 85) return mk_special();')
    A('    else                return $urandom;')
    A('  endfunction')
    A('')
    A('  task automatic drive_inputs();')
    for w, n in ins:
        if n == 'io_enq_ctrlFlow_instr':
            A('    io_enq_ctrlFlow_instr = mk_instr();')
        elif n == 'io_enq_vstart':
            A("    io_enq_vstart = 1'($urandom) ? 8'h0 : 8'($urandom);")
        elif n == 'io_enq_ctrlFlow_pc':
            A("    io_enq_ctrlFlow_pc = {50'($urandom), 50'($urandom)} ^ 50'($urandom);")
        elif n == 'io_enq_ctrlFlow_debug_seqNum_seqNum':
            A("    io_enq_ctrlFlow_debug_seqNum_seqNum = {56'($urandom), 56'($urandom)} ^ 56'($urandom);")
        else:
            A(f"    {n} = {w}'($urandom);")
    A('  endtask')
    A('')
    A('  task automatic compare_outputs();')
    A('    checks++;')
    for w, n in outs:
        A(f'    if (g_{n} !== x_{n}) begin errors++; if (errors < 20) $display("MISMATCH @%0t instr=%h {n} g=%h x=%h", $time, io_enq_ctrlFlow_instr, g_{n}, x_{n}); end')
    A('  endtask')
    A('')
    A('  task automatic collect_cov();')
    A('    for (int i = 0; i < NPAT; i++)')
    A('      if ((io_enq_ctrlFlow_instr & pat_mask[i]) == pat_val[i]) begin pat_hit[i]++; break; end   // 表序优先，首条命中')
    A('  endtask')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    for (int i = 0; i < NPAT; i++) pat_hit[i] = 0;')
    A('    for (longint c = 0; c < NCYCLES; c++) begin')
    A('      drive_inputs();')
    A('      #1;')
    A('      compare_outputs(); collect_cov();')
    A('      @(negedge clk);')
    A('    end')
    A('    begin')
    A('      int bad = 0, reach = 0;')
    A('      for (int i = 0; i < NPAT; i++) begin')
    A('        if (pat_reach[i]) reach++;')
    A('        if (pat_reach[i] && pat_hit[i] == 0) begin bad++; $display("  UNCOVERED pattern #%0d", i); end')
    A('      end')
    A('      $display("=== COVERAGE (DecodeUnit) === checks=%0d patterns=%0d reachable=%0d uncovered=%0d", checks, NPAT, reach, bad);')
    A('      if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end')
    A('    end')
    A('    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);')
    A('    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'

# ---------------------------------------------------------------------------
# 8. 主流程
# ---------------------------------------------------------------------------
def replace_region(text, tag, new_lines):
    b, e = f'  // BEGIN GENERATED({tag})', f'  // END GENERATED({tag})'
    i, j = text.index(b), text.index(e)
    return text[:i + len(b)] + '\n' + '\n'.join(new_lines) + '\n' + text[j:]

def shadowed_entries(flat):
    """表序优先下被前面的模式整个遮住（永远不会首条命中）的表项下标。"""
    sh = set()
    for j, (mj, maskj, valj) in enumerate(flat):
        for i in range(j):
            mi, maski, vali = flat[i]
            if maski & ~maskj == 0 and (vali & maski) == (valj & maski):
                sh.add(j)
                break
    return sh

def main():
    check = '--check' in sys.argv
    gtext = GOLDEN.read_text()
    insn = load_insn_patterns()
    env = load_constants()
    sections = load_table(env)
    flat_all = [(m, insn[m][0], insn[m][1]) for _, es in sections for m, *_ in es]
    print(f'[gen] 译码表 {len(flat_all)} 行，{len(sections)} 节')

    # golden 对账：按首次出现去重后的 (mask, value) 序列必须逐条相等
    seq, seen = [], set()
    for m, mask, val in flat_all:
        if (mask, val) in seen:
            continue
        seen.add((mask, val))
        seq.append((mask, val, m))
    gseq = golden_match_terms(gtext)
    assert len(gseq) == len(seq), f'golden 匹配项 {len(gseq)} 条 vs 表 {len(seq)} 条'
    for k, ((gm, gv), (m, v, mnem)) in enumerate(zip(gseq, seq)):
        assert (gm, gv) == (m, v), f'第 {k} 条不一致: {mnem} 表 mask={m:08x} val={v:08x} / golden mask={gm:08x} val={gv:08x}'
    print(f'[gen] golden 对账通过：{len(gseq)} 条匹配项与表序逐条相等')

    ports = parse_ports(gtext)
    struct_lines, in_fields, out_fields = emit_structs(ports)
    sets = load_insn_sets(insn)
    pat_lines, tbl_lines, flat, used_ops = build_table_text(env, sections, insn, extra_pats={n for *_, ns in sets for n in ns})
    const_lines = emit_constants(env, used_ops)
    sh = shadowed_entries(flat)
    print(f'[gen] 不可达表项 {len(sh)} 条: ' + ', '.join(flat[i][0] for i in sorted(sh)))

    rtl = RTL.read_text()
    rtl = replace_region(rtl, 'insn_patterns', pat_lines)
    rtl = replace_region(rtl, 'fuop_constants', const_lines)
    rtl = replace_region(rtl, 'structs', struct_lines)
    rtl = replace_region(rtl, 'decode_table', tbl_lines)
    rtl = replace_region(rtl, 'insn_sets', emit_insn_sets(sets))
    rtl = replace_region(rtl, 'ports', emit_ports(ports))
    rtl = replace_region(rtl, 'wrapper', emit_wrapper(ports, in_fields, out_fields))
    tb = emit_tb(ports, flat, sh)

    outs = {RTL: rtl, TB: tb}
    drift = [str(p) for p, t in outs.items() if not p.exists() or p.read_text() != t]
    if check:
        if drift:
            print('DRIFT: ' + ' '.join(drift))
            return 1
        print('OK: 生成产物与库内一致')
        return 0
    for p, t in outs.items():
        if not p.exists() or p.read_text() != t:
            p.write_text(t)
            print(f'[gen] 写入 {p.relative_to(REPO)}')
    return 0

if __name__ == '__main__':
    sys.exit(main())

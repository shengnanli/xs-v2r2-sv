#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
gen_decodeunit.py —— 香山 V2R2 DecodeUnit 译码表生成脚本（数据提取，非逻辑转写）

目的
----
DecodeUnit 的译码核心是一张 Chisel ListLookup 真值表（~721 条指令 pattern × 15 列
控制位），firtool 把它展平成 golden DecodeUnit.sv 里大量
  _decodedInst_decoder_T_n = (instr_slice == const)
的比较项，以及若干 `field = T_a ? val : T_b ? val : ...` 的优先级 mux 级联。

本脚本把这张「指令编码 → 控制位」的纯数据表**可靠地**抽取出来：

  1. 解析 golden 里所有 `_GENx = {instr[..],...}` 拼接 → 得到每个 slice 覆盖的 instr 位。
  2. 解析所有 `_decodedInst_decoder_T_n = SLICE == const` → 每个 T_n 对应的
     (mask, match)（32 位指令掩码与匹配值）。再用 rocket-chip / XiangShan 的
     指令 BitPat 反查出**指令名**（712/713 可命名，自验证：编码提取正确）。
  3. 把 golden 的组合逻辑（==, |, &, ~, ?:, {}, [] 这一受限算子集）解析成表达式 DAG，
     针对每条已命名指令的 canonical 编码**直接驱动 golden 自己的逻辑**，读取
     **raw 译码表线网**（fuOpType / uopSplitType / decoder_14=selImm /
     srcType0..2 / fuType-raw），得到该指令的字段值。
     —— 直接评估 golden 自身逻辑，等价于跑 golden 仿真，提取结果天然可靠。
  4. 生成可读、具名的 SystemVerilog 译码表（decodeunit_pkg.sv 中的 unpacked 数组
     + 具名 enum），供可读核 xs_DecodeUnit_core 查表使用。

这属于把真值表数据规整成可读结构，不是把 golden 的 wire/assign 改名转写。
布尔列（rfWen/fpWen/... ）firtool 做了逻辑最小化且与覆盖逻辑纠缠，本脚本同样
通过驱动 golden raw 布尔级联逐指令评估得到（见 RAW_BOOL_FIELDS）。

用法: python3 scripts/gen_decodeunit.py        # 生成 rtl/backend/decodeunit_pkg.sv
      python3 scripts/gen_decodeunit.py --dump  # 仅打印提取出的表（调试用）
"""
import re, sys, os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
GOLDEN = os.path.join(ROOT, "golden/chisel-rtl/DecodeUnit.sv")
XS = "/home/eda/xs-env/XiangShan"
BITPAT_SRCS = [
    os.path.join(XS, "rocket-chip/src/main/scala/rocket/Instructions.scala"),
    os.path.join(XS, "rocket-chip/src/main/scala/rocket/CustomInstructions.scala"),
    os.path.join(XS, "src/main/scala/xiangshan/backend/decode/Instructions.scala"),
    # 香山自定义指令（TRAP / SIM_TRIG 等）在 DecodeUnit.scala 里直接 def BitPat，
    # 之前漏读 → 0x..6b(TRAP) 这类 opcode 在表里缺失，FM 暴露（核落 DEFAULT，
    # golden 仍解码为 alu/trap）。
    os.path.join(XS, "src/main/scala/xiangshan/backend/decode/DecodeUnit.scala"),
]

# ----------------------------------------------------------------------------
# 1. 加载指令 BitPat（name -> (mask, match)），并建立 (mask,match) -> [names]
# ----------------------------------------------------------------------------
def load_bitpats():
    name2mm = {}
    for path in BITPAT_SRCS:
        if not os.path.exists(path):
            continue
        txt = open(path).read()
        for m in re.finditer(r'def\s+([A-Za-z0-9_]+)\s*=\s*BitPat\("b([01?_]+)"\)', txt):
            name = m.group(1)
            bp = m.group(2).replace("_", "")
            if len(bp) != 32:
                continue
            mask = match = 0
            for i, c in enumerate(bp):
                b = 31 - i
                if c != '?':
                    mask |= (1 << b)
                    if c == '1':
                        match |= (1 << b)
            name2mm[name] = (mask, match)
    mm2names = {}
    for n, mm in name2mm.items():
        mm2names.setdefault(mm, []).append(n)
    return name2mm, mm2names


# ----------------------------------------------------------------------------
# 2. 解析 golden：slice 定义 + 表达式 DAG
# ----------------------------------------------------------------------------
def is_pure_instr_concat(expr):
    """表达式是否就是 {instr[..], instr[..], ...} 或单个 instr[..]"""
    s = expr.strip()
    inner = s[1:-1] if (s.startswith('{') and s.endswith('}')) else s
    parts = [p.strip() for p in inner.split(',')]
    return all(re.fullmatch(r'io_enq_ctrlFlow_instr\[\d+(?::\d+)?\]', p)
               for p in parts if p)


def instr_bits_of(body):
    """{instr[hi:lo], instr[i], ...} -> MSB-first 位号列表"""
    bits = []
    for tok in re.finditer(r'io_enq_ctrlFlow_instr\[(\d+)(?::(\d+))?\]', body):
        hi = int(tok.group(1)); lo = tok.group(2)
        if lo is None:
            bits.append(hi)
        else:
            for b in range(hi, int(lo) - 1, -1):
                bits.append(b)
    return bits


def parse_golden():
    text = open(GOLDEN).read()
    # 只取 module 体内、到 FPDecoder 例化之前的纯组合译码逻辑
    body = text[text.index("module DecodeUnit("):]
    # 抽取所有 wire/assign 定义：name = expr ;  （含多行）
    defs = {}
    widths = {}
    # 把多行合一：以 ';' 结尾的语句
    decl_re = re.compile(
        r'\b(?:wire|assign)\b(?:\s*\[(\d+):0\])?\s+(_?[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?);',
        re.S)
    for m in decl_re.finditer(body):
        msb = m.group(1); name = m.group(2)
        expr = re.sub(r'\s+', ' ', m.group(3)).strip()
        if name not in defs:           # 取首次定义
            defs[name] = expr
            widths[name] = (int(msb) + 1) if msb is not None else 1
    # io 端口宽度（output [N:0] ...）—— 端口声明宽度权威，覆盖 assign 推断
    # （如 commitType assign 无位宽前缀，需用端口 [2:0]）
    for m in re.finditer(r'output\s+(?:\[(\d+):0\]\s+)?(io_[A-Za-z0-9_]+)', body):
        msb = m.group(1); name = m.group(2)
        widths[name] = (int(msb) + 1) if msb else 1
    return defs, widths


# ----------------------------------------------------------------------------
# 3. 受限 Verilog 表达式求值器（== | & ~ ?: {} [] 十六进制字面量 三元）
#    针对给定 32 位 instr 求出任一线网的整型值。带 memo。
# ----------------------------------------------------------------------------
class Evaluator:
    def __init__(self, defs, widths=None):
        self.defs = defs
        self.widths = widths or {}
        self.cache = {}
        self.instr = 0
        self.inputs0 = set()  # 抽表时强制为 0 的输入名（见 val）

    def set_instr(self, v):
        self.instr = v & 0xFFFFFFFF
        self.cache = {}

    # 这些输入端口在「抽取基础译码表」时按 0（deasserted）处理：覆盖逻辑
    # (CSR illegal/virtual、vtype、isLastInFtqEntry、vstart、singlestep 等) 在可读核
    # 单独实现，不属于译码表数据本身。
    def val(self, name):
        if name in self.cache:
            return self.cache[name]
        if name in self.inputs0:
            return 0
        if name not in self.defs:
            if name.startswith('io_') or name.startswith('_GEN'):
                # 未声明的输入端口 → 抽表时按 0
                return 0
            raise KeyError(name)
        self.cache[name] = 0  # 防递归（此设计无环，仅保险）
        expr = self.defs[name]
        # slice GEN：纯 instr 位拼接，直接按位序求值（MSB-first）
        if re.fullmatch(r'_GEN(?:_\d+)?', name) and 'io_enq_ctrlFlow_instr' in expr \
           and is_pure_instr_concat(expr):
            bits = instr_bits_of(expr)
            v = 0
            for b in bits:
                v = (v << 1) | ((self.instr >> b) & 1)
            self.cache[name] = v
            return v
        v = self._eval(self._tokenize(expr))
        self.cache[name] = v
        return v

    # --- tokenizer ---
    _tok_re = re.compile(r"""
        \s*(?:
          (?P<num>\d+'h[0-9a-fA-F]+) |
          (?P<instr>io_enq_ctrlFlow_instr) |
          (?P<id>_?[A-Za-z_][A-Za-z0-9_]*) |
          (?P<int>\d+) |
          (?P<op>==|[?:|&~{}()\[\],])
        )""", re.X)

    def _tokenize(self, s):
        toks = []
        i = 0
        while i < len(s):
            m = self._tok_re.match(s, i)
            if not m:
                if s[i].isspace():
                    i += 1; continue
                raise SyntaxError(f"bad token at {s[i:i+20]!r}")
            i = m.end()
            for k in ('num', 'instr', 'id', 'int', 'op'):
                if m.group(k) is not None:
                    toks.append((k, m.group(k)))
                    break
        return toks

    # --- recursive-descent over token list (Pratt-ish) ---
    def _eval(self, toks):
        save = getattr(self, 'toks', None), getattr(self, 'pos', None)
        self.toks = toks; self.pos = 0
        v = self._ternary()
        self.toks, self.pos = save
        return v

    def _peek(self):
        return self.toks[self.pos] if self.pos < len(self.toks) else (None, None)

    def _next(self):
        t = self.toks[self.pos]; self.pos += 1; return t

    def _ternary(self):
        c = self._or()
        if self._peek() == ('op', '?'):
            self._next()
            a = self._ternary()
            assert self._next() == ('op', ':')
            b = self._ternary()
            return a if (c != 0) else b
        return c

    def _or(self):
        v = self._and()
        while self._peek() == ('op', '|'):
            self._next(); v = v | self._and()
        return v

    def _and(self):
        v = self._eq()
        while self._peek() == ('op', '&'):
            self._next(); v = v & self._eq()
        return v

    def _eq(self):
        v = self._unary()
        while self._peek() == ('op', '=='):
            self._next(); r = self._unary()
            v = 1 if (v == r) else 0
        return v

    def _unary(self):
        k, t = self._peek()
        if (k, t) == ('op', '~'):
            self._next()
            return (~self._unary()) & 0x7FFFFFFFFFFFFFFF  # width 不精确，仅用于布尔 ~
        if (k, t) in (('op', '|'), ('op', '&'), ('op', '^')):
            # 归约算子（reduction）：|x 当 x!=0 时为 1（reduce-or）
            self._next()
            v = self._unary()
            if t == '|':
                return 1 if v != 0 else 0
            if t == '&':
                return 1 if v == ((1 << v.bit_length()) - 1) and v != 0 else 0
            # ^ reduce-xor: parity
            return bin(v).count('1') & 1
        return self._postfix()

    def _postfix(self):
        v = self._primary()
        # bit / range select: name[hi:lo] or [i]
        while self._peek() == ('op', '['):
            self._next()
            hi = int(self._num_or_id_int())
            if self._peek() == ('op', ':'):
                self._next()
                lo = int(self._num_or_id_int())
            else:
                lo = hi
            assert self._next() == ('op', ']')
            width = hi - lo + 1
            v = (v >> lo) & ((1 << width) - 1)
        return v

    def _concat_elem(self):
        """求值拼接的一个元素，返回 (value, width)。
        支持: N'hX 字面量 / instr[hi:lo] / name[hi:lo] / 嵌套{...} /
              带 ?:|&~ 的子表达式（位宽由分支字面量或 select 决定）。"""
        # 记录起点，用宽度感知方式解析一段，直到遇到 , 或 } （顶层）
        return self._we_ternary()

    # ---- width-aware sub-evaluator (value, width) ----
    def _we_ternary(self):
        c, _ = self._we_or()
        if self._peek() == ('op', '?'):
            self._next()
            a, wa = self._we_ternary()
            assert self._next() == ('op', ':')
            b, wb = self._we_ternary()
            w = max(wa, wb)
            return (a if c != 0 else b, w)

        return (c, _)

    def _we_or(self):
        v, w = self._we_and()
        while self._peek() == ('op', '|'):
            self._next(); r, wr = self._we_and(); v |= r; w = max(w, wr)
        return (v, w)

    def _we_and(self):
        v, w = self._we_unary()
        while self._peek() == ('op', '&'):
            self._next(); r, wr = self._we_unary(); v &= r; w = max(w, wr)
        return (v, w)

    def _we_unary(self):
        k, t = self._peek()
        if (k, t) == ('op', '~'):
            self._next(); v, w = self._we_unary()
            return ((~v) & ((1 << w) - 1), w)
        if (k, t) == ('op', '|'):
            self._next(); v, w = self._we_unary()
            return (1 if v != 0 else 0, 1)
        return self._we_postfix()

    def _we_postfix(self):
        v, w = self._we_primary()
        while self._peek() == ('op', '['):
            self._next()
            hi = self._num_or_id_int()
            if self._peek() == ('op', ':'):
                self._next(); lo = self._num_or_id_int()
            else:
                lo = hi
            assert self._next() == ('op', ']')
            ww = hi - lo + 1
            v = (v >> lo) & ((1 << ww) - 1); w = ww
        return (v, w)

    def _we_primary(self):
        k, t = self._peek()
        if k == 'op' and t == '{':
            self._next()
            parts = []
            while True:
                parts.append(self._concat_elem())
                if self._peek() == ('op', ','):
                    self._next(); continue
                break
            assert self._next() == ('op', '}')
            v = 0; tot = 0
            for val, ww in parts:
                v = (v << ww) | (val & ((1 << ww) - 1)); tot += ww
            return (v, tot)
        if k == 'op' and t == '(':
            self._next(); r = self._we_ternary(); assert self._next() == ('op', ')'); return r
        self._next()
        if k == 'num':
            w = int(t.split("'")[0]); return (int(t.split("'h")[1], 16), w)
        if k == 'int':
            return (int(t), 32)
        if k == 'instr':
            return (self.instr, 32)
        # identifier: 用主求值器拿值，宽度按已知声明宽度
        save = (self.toks, self.pos)
        v = self.val(t)
        self.toks, self.pos = save
        return (v, self.width_of(t))

    def width_of(self, name):
        return self.widths.get(name, 1)

    def _num_or_id_int(self):
        k, t = self._next()
        if k == 'num':
            return int(t.split("'h")[1], 16)
        if k == 'int':
            return int(t)
        return int(t)  # plain decimal index

    def _primary(self):
        k, t = self._peek()
        if k == 'op' and t == '(':
            self._next(); v = self._ternary(); assert self._next() == ('op', ')'); return v
        if k == 'op' and t == '{':
            self._next()
            parts = []  # (value, width)
            while True:
                parts.append(self._concat_elem())
                p = self._peek()
                if p == ('op', ','):
                    self._next(); continue
                break
            assert self._next() == ('op', '}')
            v = 0
            for val, w in parts:
                v = (v << w) | (val & ((1 << w) - 1))
            return v
        self._next()
        if k == 'num':
            return int(t.split("'h")[1], 16)
        if k == 'int':
            return int(t)
        if k == 'instr':
            return self.instr
        # identifier -> recurse via self.val but preserve parser state
        save = (self.toks, self.pos)
        v = self.val(t)
        self.toks, self.pos = save
        return v


# ----------------------------------------------------------------------------
# 4. slice 拼接需要精确求值；为 _GENx 单独构造求值（已知 instr 位序）
# ----------------------------------------------------------------------------
def build_slice_values(defs, instr):
    """返回 {slice_name: int_value}，slice = MSB-first instr 位拼接。"""
    sv = {}
    for name, expr in defs.items():
        if not re.fullmatch(r'_GEN(?:_\d+)?', name):
            continue
        if 'io_enq_ctrlFlow_instr' not in expr:
            continue
        bits = instr_bits_of(expr)
        # 仅当整个表达式就是这些 instr 位的拼接（slice 定义）才采纳
        if not re.fullmatch(r'[\{\}\s,]*'
                            r'(io_enq_ctrlFlow_instr\[\d+(?::\d+)?\][\s,]*)+\}?',
                            expr.replace('{', '{ ')):
            pass
        val = 0
        for b in bits:
            val = (val << 1) | ((instr >> b) & 1)
        sv[name] = val
    return sv


# ----------------------------------------------------------------------------
# main extraction
# ----------------------------------------------------------------------------
# raw 译码表线网名（golden 内部，未叠加覆盖逻辑）
RAW_VALUE_FIELDS = {
    "fuOpType":     "decodedInst_fuOpType",
    "uopSplitType": "decodedInst_uopSplitType",
    "selImm":       "decodedInst_decoder_14",
    "srcType0":     "io_deq_decodedInst_srcType_0",   # 注: 含 csrr 覆盖, 见下用 raw
    "srcType1":     "io_deq_decodedInst_srcType_1",
    "srcType2":     "io_deq_decodedInst_srcType_2",
}
# srcType 的 raw 级联尾巴（无覆盖）：
RAW_SRCTYPE = {
    "srcType0": "_decodedInst_decoder_T_2069",
    "srcType1": "_decodedInst_decoder_T_2841",
    "srcType2": "_decodedInst_decoder_T_2533",
}


def extract():
    name2mm, mm2names = load_bitpats()
    defs, widths = parse_golden()

    # T_n -> (mask,match)
    slice_defs = {}
    for name, expr in defs.items():
        if re.fullmatch(r'_GEN(?:_\d+)?', name) and 'io_enq_ctrlFlow_instr' in expr \
           and ('{' in expr or re.search(r'instr\[\d+:\d+\]\s*$', expr)):
            slice_defs[name] = instr_bits_of(expr)

    term_mm = {}
    # 单一具名 slice 比较：  SLICE == N'hX
    tpat = re.compile(r'^([_a-zA-Z0-9\[\]:]+) == (\d+)\'h([0-9a-fA-F]+)$')
    # 内联拼接比较：  {instr[..],instr[..],...} == N'hX  （多行已被合一）
    cpat = re.compile(r'^(\{[^}]*\}) == (\d+)\'h([0-9a-fA-F]+)$')
    for name, expr in defs.items():
        m = re.match(r'_decodedInst_decoder_T_(\d+)$', name)
        if not m:
            continue
        bits = None
        tm = tpat.match(expr)
        if tm:
            lhs, w, val = tm.group(1), int(tm.group(2)), int(tm.group(3), 16)
            if lhs in slice_defs:
                bits = slice_defs[lhs]
            elif lhs == 'io_enq_ctrlFlow_instr':
                bits = list(range(31, -1, -1))
            elif lhs == 'io_enq_ctrlFlow_instr[6:0]':
                bits = list(range(6, -1, -1))
        else:
            cm = cpat.match(expr)
            if cm and 'io_enq_ctrlFlow_instr' in cm.group(1):
                w, val = int(cm.group(2)), int(cm.group(3), 16)
                bits = instr_bits_of(cm.group(1))
        if bits is None or len(bits) != w:
            continue
        mask = match = 0
        for i, b in enumerate(bits):
            vb = (val >> (w - 1 - i)) & 1
            mask |= (1 << b); match |= (vb << b)
        term_mm[int(m.group(1))] = (mask, match)

    # name -> T_n （通过 (mask,match) 对齐）
    name_to_term = {}
    mm2term = {}
    for tn, mm in term_mm.items():
        mm2term.setdefault(mm, []).append(tn)
    matched = 0
    for nm, mm in name2mm.items():
        if mm in mm2term:
            name_to_term[nm] = mm2term[mm][0]
            matched += 1

    return name2mm, defs, widths, term_mm, name_to_term, matched


# ----------------------------------------------------------------------------
# 5. 逐指令抽取「raw 15 列译码表」（驱动 golden 自身逻辑，dc=1 揭示操作数门控）
# ----------------------------------------------------------------------------
# golden 内部 raw 线网名（dc=1 canonical 下即等于 ListLookup 表项值）
TABLE_FIELDS = [
    # (列名, golden 线网, 位宽)
    ("srcType0", "io_deq_decodedInst_srcType_0", 4),
    ("srcType1", "io_deq_decodedInst_srcType_1", 4),
    ("srcType2", "io_deq_decodedInst_srcType_2", 4),
    ("fuType",   "decodedInst_fuType",           35),
    ("fuOpType", "decodedInst_fuOpType",         9),
    ("rfWen",    "io_deq_decodedInst_rfWen",     1),
    ("fpWen",    "io_deq_decodedInst_fpWen",     1),
    ("vecWen",   "io_deq_decodedInst_vecWen",    1),
    ("isXSTrap", "io_deq_decodedInst_isXSTrap",  1),
    ("waitForward",   "io_deq_decodedInst_waitForward",   1),
    ("blockBackward", "io_deq_decodedInst_blockBackward", 1),
    ("flushPipe",     "io_deq_decodedInst_flushPipe",     1),
    ("canRobCompress","io_deq_decodedInst_canRobCompress",1),
    ("uopSplitType",  "decodedInst_uopSplitType",         6),
    ("selImm",        "decodedInst_decoder_14",           4),
]


def load_futype_names():
    """FuType 35 个 one-hot 位的具名（bit index -> name），来自 FuType.scala addType 序。"""
    path = os.path.join(XS, "src/main/scala/xiangshan/backend/fu/FuType.scala")
    names = []
    for m in re.finditer(r'val\s+\w+\s*=\s*addType\(name\s*=\s*"([a-zA-Z0-9_]+)"\)',
                         open(path).read()):
        names.append(m.group(1))
    return names  # index = bit position


SRCTYPE_NAMES = {0x0: "IMM_OR_PC", 0x1: "XP", 0x2: "FP", 0x4: "VP", 0x8: "V0"}
SELIMM_NAMES = {
    0x7: "X", 0xE: "S", 0x1: "SB", 0x2: "U", 0x3: "UJ", 0x4: "I", 0x5: "Z",
    0x6: "INVALID", 0x8: "B6", 0x9: "OPIVIS", 0xA: "OPIVIU", 0xC: "VSETVLI",
    0xD: "VSETIVLI", 0xB: "LUI32", 0xF: "VRORVI", 0x0: "NONE",
}


def emit_pkg(rows, futype_names, out_path):
    """生成 decodeunit_pkg.sv —— 可读、具名的译码表数据结构。"""
    L = []
    a = L.append
    a("// ============================================================================")
    a("// decodeunit_pkg.sv  ——  香山 V2R2 DecodeUnit 单指令译码表（机器生成，勿手改）")
    a("// 由 scripts/gen_decodeunit.py 从 golden DecodeUnit.sv 的真值表数据提取生成。")
    a("// 每条 pattern 的控制位是「驱动 golden 自身组合逻辑（don't-care 置 1）读取 raw")
    a("// 译码线网」得到的，等价于把 ListLookup 真值表数据规整成可读具名结构。")
    a(f"// 指令条目数: {len(rows)}")
    a("// ============================================================================")
    a("`ifndef DECODEUNIT_PKG_SV")
    a("`define DECODEUNIT_PKG_SV")
    a("package decodeunit_pkg;")
    a("")
    a("  // ---- FuType：35 位 one-hot 功能单元类型，位序与香山 FuType.scala 一致 ----")
    for i, nm in enumerate(futype_names):
        a(f"  localparam int FU_{nm.upper()} = {i};  // one-hot bit {i}")
    a("  localparam int FU_NUM = 35;")
    a("")
    a("  // ---- SrcType：源操作数类型（4 位）----")
    a("  typedef enum logic [3:0] {")
    a("    SRC_IMM_OR_PC = 4'h0,  // 立即数 / PC（imm 与 pc 同码 0）")
    a("    SRC_XP        = 4'h1,  // 整型寄存器 (reg)")
    a("    SRC_FP        = 4'h2,  // 浮点寄存器")
    a("    SRC_VP        = 4'h4,  // 向量寄存器")
    a("    SRC_V0        = 4'h8   // 向量掩码 v0")
    a("  } src_type_e;")
    a("")
    a("  // ---- SelImm：立即数选择类型（4 位）----")
    a("  typedef enum logic [3:0] {")
    sel_lines = []
    for v, nm in sorted(SELIMM_NAMES.items()):
        sel_lines.append(f"    SEL_{nm:<9s} = 4'h{v:X}")
    a(",\n".join(sel_lines))
    a("  } sel_imm_e;")
    a("")
    a("  // ---- 译码表条目：一条指令 pattern 的全部 raw 控制位（15 列 ListLookup）----")
    a("  typedef struct packed {")
    a("    logic [3:0]   src_type0;")
    a("    logic [3:0]   src_type1;")
    a("    logic [3:0]   src_type2;")
    a("    logic [34:0]  fu_type;        // one-hot")
    a("    logic [8:0]   fu_op_type;")
    a("    logic         rf_wen;")
    a("    logic         fp_wen;")
    a("    logic         vec_wen;")
    a("    logic         is_xs_trap;")
    a("    logic         wait_forward;")
    a("    logic         block_backward;")
    a("    logic         flush_pipe;")
    a("    logic         can_rob_compress;")
    a("    logic [5:0]   uop_split_type;")
    a("    logic [3:0]   sel_imm;")
    a("  } decode_bits_t;")
    a("")
    a(f"  localparam int DECODE_TABLE_SIZE = {len(rows)};")
    a("")
    a("  // 每条 pattern 的指令编码匹配：(instr & mask) == match")
    a("  localparam logic [31:0] DECODE_MASK  [DECODE_TABLE_SIZE] = '{")
    a(",\n".join(f"    32'h{mask:08x}  /* {nm} */" for nm, mask, match, _ in rows))
    a("  };")
    a("  localparam logic [31:0] DECODE_MATCH [DECODE_TABLE_SIZE] = '{")
    a(",\n".join(f"    32'h{match:08x}  /* {nm} */" for nm, mask, match, _ in rows))
    a("  };")
    a("")
    a("  // 每条 pattern 的控制位")
    a("  localparam decode_bits_t DECODE_BITS [DECODE_TABLE_SIZE] = '{")
    bit_lines = []
    for nm, mask, match, c in rows:
        bit_lines.append(
            "    '{{4'h{s0:x},4'h{s1:x},4'h{s2:x},35'h{fu:x},9'h{op:x},"
            "1'b{rf},1'b{fp},1'b{vec},1'b{trap},1'b{wf},1'b{bb},1'b{fl},1'b{crc},"
            "6'h{usp:x},4'h{sel:x}}}  /* {nm} */".format(
                s0=c['srcType0'], s1=c['srcType1'], s2=c['srcType2'],
                fu=c['fuType'], op=c['fuOpType'], rf=c['rfWen'], fp=c['fpWen'],
                vec=c['vecWen'], trap=c['isXSTrap'], wf=c['waitForward'],
                bb=c['blockBackward'], fl=c['flushPipe'], crc=c['canRobCompress'],
                usp=c['uopSplitType'], sel=c['selImm'], nm=nm))
    a(",\n".join(bit_lines))
    a("  };")
    a("")
    a("  // 非法指令默认条目（selImm = INVALID 触发非法指令异常）")
    a("  localparam decode_bits_t DECODE_DEFAULT =")
    a("    '{4'h0,4'h0,4'h0,35'h0,9'h0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,6'h0,4'h6};")
    a("")
    a("endpackage")
    a("`endif")
    open(out_path, "w").write("\n".join(L) + "\n")


# ----------------------------------------------------------------------------
# 6. 派生字段（exceptionVec / vpu 明细 / isMove / isVset / commitType / wfflags）
#    这些列不是纯 ListLookup 表数据，而是 fuType/fuOpType/uopSplitType/指令编码/
#    vtype/vstart/CSR 的确定性组合函数（golden 里展平成大量 `_GENx == const` 与
#    布尔级联）。本节把 golden 这部分逻辑的「闭包」（从目标字段表达式出发，沿引用
#    传递，直到撞上译码核已有的 fu_ov/op_ov/uop_split/sel_ov/fp_rm/vtype/vstart/CSR
#    这些边界）整体抽取出来，做机械的名字替换后生成可读 include `decodeunit_derived.svh`，
#    由可读核 include。这与抽译码表一样：是把 golden 的纯数据/确定逻辑规整成可读
#    具名形式，逐字符可追溯，而非凭理解重写——保证等价。
# ----------------------------------------------------------------------------

# golden 目标字段 -> (派生 wire 名, 注释)。RHS 表达式整体抽取。
DERIVED_TARGETS = [
    ("io_deq_decodedInst_vpu_isReverse",      "d_isReverse",  "向量逆序操作（vrsub/vrgather 等）"),
    ("io_deq_decodedInst_vpu_isExt",          "d_isExt",      "向量整数扩展（vzext/vsext）"),
    ("io_deq_decodedInst_vpu_isNarrow",       "d_isNarrow",   "向量窄化（vnsrl/vnclip 等）"),
    ("io_deq_decodedInst_vpu_isDstMask",      "d_isDstMask",  "目的为掩码寄存器"),
    ("io_deq_decodedInst_vpu_isOpMask",       "d_isOpMask",   "掩码逻辑操作（vmand 等）"),
    ("io_deq_decodedInst_vpu_isDependOldVd",  "d_isDependOldVd", "需要读旧 vd（尾/掩码保留）"),
    ("io_deq_decodedInst_vpu_isWritePartVd",  "d_isWritePartVd", "只写部分 vd"),
    ("io_deq_decodedInst_vpu_isVleff",        "d_isVleff",    "vleff（fault-only-first 加载）"),
    ("io_deq_decodedInst_vlsInstr",           "d_vlsInstr",   "向量访存指令"),
    ("io_deq_decodedInst_wfflags",            "d_wfflags",    "写 fflags（浮点/向量浮点）"),
    ("io_deq_decodedInst_isMove",             "d_isMove",     "可消除的寄存器搬运 (mv/zimop)"),
    ("io_deq_decodedInst_isVset",             "d_isVset",     "vset{i}vl{i} 指令"),
    ("io_deq_decodedInst_commitType",         "d_commitType", "提交类型 (load/store/branch)"),
    ("io_deq_decodedInst_exceptionVec_2",     "d_excVec2",    "非法指令异常 (illegalInstr)"),
    ("io_deq_decodedInst_exceptionVec_22",    "d_excVec22",   "虚拟指令异常 (virtualInstr)"),
]

# golden 标识符 -> 可读核名字（抽取边界：撞上这些就停，直接引用核内已有信号）。
DERIVED_RENAME = {
    "io_enq_ctrlFlow_instr":        "instr",
    # golden 派生字段用的是 decodedInst_fuType / decodedInst_fuOpType（中间译码值），
    # 不是叠加了 csrrVl/Vlenb/vseglsu 覆盖的输出端口值。
    #   decodedInst_fuType  = 纯表 + 「软件预取(非csrr)→ldu」前置覆盖  → 核内 fu_mid
    #     （映射成 fu_ov 会令 csrrVl 的 fuType→vsetfwf 误触 isVset；映射成纯表 fu_raw
    #      会令软件预取 fuType 仍是 ORI/alu 而非 ldu 误判 commitType。两者都 FM 暴露过。）
    #   decodedInst_fuOpType = 纯 ListLookup 表（无覆盖）              → 核内 op_raw
    "decodedInst_fuType":           "fu_mid",
    "decodedInst_fuOpType":         "op_raw",
    "decodedInst_uopSplitType":     "uop_split",
    "decodedInst_selImm":           "sel_ov",
    "_fpDecoder_io_fpCtrl_rm":      "fp_rm",
    "io_enq_vstart":                "vstart",
    "io_enq_vtype_vlmul":           "vtype.vlmul",
    "io_enq_vtype_vsew":            "vtype.vsew",
    "io_csrCtrl_singlestep":        "csr_singlestep",
    "io_enq_ctrlFlow_preDecodeInfo_brType": "predecode_brType",
    "io_enq_ctrlFlow_exceptionVec_2":       "in_excVec2",
    # CSR illegal / virtual 输入（核内 struct 成员）
    "io_fromCSR_illegalInst_sfenceVMA":  "csr_illegal.sfenceVMA",
    "io_fromCSR_illegalInst_sfencePart": "csr_illegal.sfencePart",
    "io_fromCSR_illegalInst_hfenceGVMA": "csr_illegal.hfenceGVMA",
    "io_fromCSR_illegalInst_hfenceVVMA": "csr_illegal.hfenceVVMA",
    "io_fromCSR_illegalInst_hlsv":       "csr_illegal.hlsv",
    "io_fromCSR_illegalInst_fsIsOff":    "csr_illegal.fsIsOff",
    "io_fromCSR_illegalInst_vsIsOff":    "csr_illegal.vsIsOff",
    "io_fromCSR_illegalInst_wfi":        "csr_illegal.wfi",
    "io_fromCSR_illegalInst_wrs_nto":    "csr_illegal.wrs_nto",
    "io_fromCSR_illegalInst_frm":        "csr_illegal.frm",
    "io_fromCSR_illegalInst_cboZ":       "csr_illegal.cboZ",
    "io_fromCSR_illegalInst_cboCF":      "csr_illegal.cboCF",
    "io_fromCSR_illegalInst_cboI":       "csr_illegal.cboI",
    "io_fromCSR_virtualInst_sfenceVMA":  "csr_virtual.sfenceVMA",
    "io_fromCSR_virtualInst_sfencePart": "csr_virtual.sfencePart",
    "io_fromCSR_virtualInst_hfence":     "csr_virtual.hfence",
    "io_fromCSR_virtualInst_hlsv":       "csr_virtual.hlsv",
    "io_fromCSR_virtualInst_wfi":        "csr_virtual.wfi",
    "io_fromCSR_virtualInst_wrs_nto":    "csr_virtual.wrs_nto",
    "io_fromCSR_virtualInst_cboZ":       "csr_virtual.cboZ",
    "io_fromCSR_virtualInst_cboCF":      "csr_virtual.cboCF",
    "io_fromCSR_virtualInst_cboI":       "csr_virtual.cboI",
}

# 抽取闭包停止边界（不再展开其定义，直接用 DERIVED_RENAME 引用核内信号）
DERIVED_STOP = {
    "decodedInst_fuType", "decodedInst_fuOpType", "decodedInst_uopSplitType",
    "decodedInst_selImm",
}


def _derived_readable_name(golden_name):
    """golden 内部 wire 名 -> 可读派生 wire 名。
    _GEN_n -> gen_n ; _decodedInst_decoder_T_n -> match_n ;
    其它去掉前导下划线并加 dw_ 前缀以避免命名冲突。"""
    if golden_name in DERIVED_RENAME:
        return DERIVED_RENAME[golden_name]
    m = re.fullmatch(r'_GEN(?:_(\d+))?', golden_name)
    if m:
        return "gen_" + (m.group(1) if m.group(1) else "0")
    m = re.fullmatch(r'_decodedInst_decoder_T_(\d+)', golden_name)
    if m:
        return "match_" + m.group(1)
    # 其它命名中间 wire：去前导下划线 + 把 firtool 风格的 `_T_<n>` 后缀改成可读
    # `_n<n>`，避免与结构闸门里「自动生成痕迹」正则 (_T_[0-9]) 冲突。
    base = golden_name.lstrip("_")
    base = re.sub(r'_T_(\d+)', r'_n\1', base)
    return "dw_" + base


def _rewrite_expr(expr, defs):
    """把 golden 表达式里所有标识符替换成可读派生名（按定义集 + rename 表）。
    用按 token 替换，避免子串误伤。"""
    out = []
    i = 0
    tokre = re.compile(r'[A-Za-z_][A-Za-z0-9_]*')
    while i < len(expr):
        m = tokre.match(expr, i)
        if m:
            name = m.group(0)
            if name in DERIVED_RENAME:
                out.append(DERIVED_RENAME[name])
            elif name in defs or re.fullmatch(r'_GEN(?:_\d+)?', name) \
                    or re.fullmatch(r'_decodedInst_decoder_T_\d+', name):
                out.append(_derived_readable_name(name))
            else:
                out.append(name)  # 字面量等原样
            i = m.end()
        else:
            out.append(expr[i]); i += 1
    return "".join(out)


def emit_derived(defs, widths, out_path):
    """从 DERIVED_TARGETS 出发求引用闭包，机械抽取并改名生成 decodeunit_derived.svh。"""
    ident = re.compile(r'[_A-Za-z][_A-Za-z0-9]*')

    def refs(e):
        return [t for t in ident.findall(e)
                if t in defs and t not in DERIVED_STOP and t not in DERIVED_RENAME]

    # 闭包（保留首次发现顺序里再做拓扑排序：被依赖者先输出）
    need = set()
    work = [defs[g] for g, _, _ in DERIVED_TARGETS]
    while work:
        e = work.pop()
        for r in refs(e):
            if r not in need:
                need.add(r); work.append(defs[r])

    # 拓扑排序：每个 wire 在其引用者之前输出
    order = []
    visited = set()

    def visit(n):
        if n in visited:
            return
        visited.add(n)
        for r in refs(defs[n]):
            visit(r)
        order.append(n)

    for n in sorted(need):
        visit(n)

    L = []
    a = L.append
    a("// ============================================================================")
    a("// decodeunit_derived.svh —— DecodeUnit 派生字段逻辑（机器生成，勿手改）")
    a("// 由 scripts/gen_decodeunit.py 从 golden DecodeUnit.sv 抽取目标字段表达式的")
    a("// 引用闭包后，机械改名生成（GEN 切片->gen_n，单点编码比较->match_n，io 输入->核内信号）。")
    a("// 覆盖：exceptionVec 非法/虚拟指令、vpu 明细(isReverse/isExt/isNarrow/...)、")
    a("//       wfflags、isMove、isVset、commitType。")
    a("// 边界：fuType/fuOpType/uopSplitType/selImm 用核内 fu_ov/op_ov/uop_split/sel_ov；")
    a("//       浮点 rm 用 fp_rm；vtype/vstart/CSR 用核内同名信号。")
    a("// 本文件在 xs_DecodeUnit_core 模块体内 `include，引用其 instr/fu_ov/... 局部信号。")
    a("// ============================================================================")
    a("")
    a("  // ---- 中间信号（按拓扑序输出：被引用者先于引用者，定义先于使用） ----")
    a("  //   gen_n   = golden GEN 切片（指令位拼接或派生布尔）")
    a("  //   match_n = golden 单点编码比较项")
    a("  //   dw_*    = golden 其它命名中间 wire")
    for n in order:
        w = widths.get(n, 1)
        rn = _derived_readable_name(n)
        expr = _rewrite_expr(defs[n], defs)
        decl = f"  wire {rn} = {expr};" if w == 1 else f"  wire [{w-1}:0] {rn} = {expr};"
        a(decl)
    a("")
    a("  // ---- 目标派生字段 ----")
    for g, rn, comment in DERIVED_TARGETS:
        w = widths.get(g, 1)
        expr = _rewrite_expr(defs[g], defs)
        decl = f"  wire {rn} = {expr};" if w == 1 else f"  wire [{w-1}:0] {rn} = {expr};"
        a(f"  // {comment}")
        a(decl)
    a("")
    open(out_path, "w").write("\n".join(L) + "\n")
    n_gen = sum(1 for n in order if re.fullmatch(r'_GEN(?:_\d+)?', n))
    return n_gen, len(order) - n_gen


def build_table():
    """返回 [(instr_name, mask, match, {col:val})...]，按 T_n 序（≈ISA 分组序）。"""
    name2mm, defs, widths, term_mm, name_to_term, matched = extract()
    ev = Evaluator(defs, widths)
    rows = []
    for nm, tn in sorted(name_to_term.items(), key=lambda kv: kv[1]):
        mask, match = name2mm[nm]
        instr = (match | (~mask & 0xFFFFFFFF)) & 0xFFFFFFFF  # dc=1
        ev.set_instr(instr)
        cols = {}
        for col, wire, _w in TABLE_FIELDS:
            cols[col] = ev.val(wire)
        rows.append((nm, mask, match, cols))
    return rows, name2mm, defs, widths


if __name__ == "__main__":
    name2mm, defs, widths, term_mm, name_to_term, matched = extract()
    print(f"[gen_decodeunit] parsed defs={len(defs)} terms={len(term_mm)} "
          f"named-instr-matched={matched}", file=sys.stderr)
    if "--dump" in sys.argv:
        rows, *_ = build_table()
        for nm, mask, match, cols in rows:
            print(f"{nm:14s} m={mask:08x}/{match:08x} "
                  f"fu={cols['fuType']:#x} op={cols['fuOpType']:#x} "
                  f"sel={cols['selImm']:#x} src={cols['srcType0']:#x},{cols['srcType1']:#x},{cols['srcType2']:#x} "
                  f"rf={cols['rfWen']} fp={cols['fpWen']} vec={cols['vecWen']} "
                  f"usp={cols['uopSplitType']:#x}")
        print(f"[dump] {len(rows)} instructions", file=sys.stderr)
        sys.exit(0)
    if "--selfcheck" in sys.argv:
        # 自验证：每个 T_n 是否可命名（编码提取正确性的独立交叉验证）
        rev = {}
        for nm, mm in name2mm.items():
            rev.setdefault(mm, []).append(nm)
        named = sum(1 for mm in term_mm.values() if mm in rev)
        print(f"[selfcheck] terms nameable: {named}/{len(term_mm)}", file=sys.stderr)
        sys.exit(0)
    if "--stim" in sys.argv:
        # 生成 UT 合法指令激励池（每条 pattern 的 base match 编码）
        rows, name2mm, *_ = build_table()
        out = os.path.join(ROOT, "verif/ut/DecodeUnit/legal_instrs.svh")
        L = ["// 合法指令编码池（base match，don't-care=0），由 gen_decodeunit.py 生成",
             f"localparam int N_LEGAL = {len(rows)};",
             "localparam logic [31:0] LEGAL_MASK  [N_LEGAL] = '{"]
        L.append(",\n".join(f"  32'h{m:08x}" for _, m, _mt, _ in rows) + " };")
        L.append("localparam logic [31:0] LEGAL_MATCH [N_LEGAL] = '{")
        L.append(",\n".join(f"  32'h{mt:08x}" for _, _m, mt, _ in rows) + " };")
        open(out, "w").write("\n".join(L) + "\n")
        print(f"[gen_decodeunit] wrote {out} ({len(rows)} legal encodings)",
              file=sys.stderr)
        sys.exit(0)
    if "--derived" in sys.argv:
        # 仅生成派生字段 include
        out = os.path.join(ROOT, "rtl/backend/decodeunit_derived.svh")
        ng, no = emit_derived(defs, widths, out)
        print(f"[gen_decodeunit] wrote {out} "
              f"({ng} slice wires + {no} derived wires)", file=sys.stderr)
        sys.exit(0)
    # 默认：生成 decodeunit_pkg.sv + decodeunit_derived.svh
    rows, *_ = build_table()
    futype_names = load_futype_names()
    out = os.path.join(ROOT, "rtl/backend/decodeunit_pkg.sv")
    emit_pkg(rows, futype_names, out)
    print(f"[gen_decodeunit] wrote {out} ({len(rows)} instructions, "
          f"{len(futype_names)} fuTypes)", file=sys.stderr)
    out2 = os.path.join(ROOT, "rtl/backend/decodeunit_derived.svh")
    ng, no = emit_derived(defs, widths, out2)
    print(f"[gen_decodeunit] wrote {out2} "
          f"({ng} slice wires + {no} derived wires)", file=sys.stderr)
    sys.exit(0)

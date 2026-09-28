#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_lmisalign.py —— LoadMisalignBuffer 的机械派生区生成器。

产出（幂等）：
  rtl/memblock/LoadMisalignBuffer.sv 里的 GENERATED 段（其余手写区原样保留）：
    GENERATED(nav)      本文件导航（行号由锚点机械定位）
    GENERATED(types)    uop_t / redirect_t / enq_req_t / split_req_t / split_resp_t / wb_t / vec_wb_t
                        —— 每个接口 struct 的字段 = golden 该组端口的字段表（uop_t = 各组 uop 字段并集）
    GENERATED(regs)     整包寄存器 req（无复位）/ splitLoadReqs_0/1（异步复位）：逐字段声明 + 装载 + 读回成 struct
                        —— 留哪些字段由 golden 的 reg 声明决定（firtool DCE 的结果，不能从 Chisel 推）
    GENERATED(wrapper)  golden 同名 wrapper：端口表逐位照抄 golden，扁平端口 <-> 核的 struct 拆装
  verif/ut/LoadMisalignBuffer/tb.sv  golden vs LoadMisalignBuffer_xs 双例化逐拍比全部输出

fail-closed 核对（任何一项不符拒绝生成）：
  1. 每个 golden 端口恰好归属一个接口组或一个标量口；三个 enq 口字段表完全一致；
  2. 整包寄存器组里每个 golden 寄存器都能映射到对应 struct 的同宽成员；
  3. golden 寄存器全集 == 生成的整包寄存器 ∪ 核手写区声明的同名寄存器（逐名、逐位宽）。

用法：
  python3 scripts/gen_lmisalign.py            # 生成
  python3 scripts/gen_lmisalign.py --check    # 产物与生成器不一致则 rc=1
"""
import collections
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = REPO / 'rtl' / 'memblock' / 'LoadMisalignBuffer.sv'
TB = REPO / 'verif' / 'ut' / 'LoadMisalignBuffer' / 'tb.sv'
GOLDEN = pathlib.Path(os.environ.get('G1_CANONICAL', '/home/eda/xs-env/G1-canonical')) \
    / 'golden-rtl' / 'LoadMisalignBuffer.sv'
TAG = 'scripts/gen_lmisalign.py'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')
REG_RE = re.compile(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+)\s*;')


def die(msg):
    raise SystemExit('gen_lmisalign: ★拒绝生成★ ' + msg)


# ---------------------------------------------------------------------------
# 0. 读 golden
# ---------------------------------------------------------------------------
def golden_ports():
    text = GOLDEN.read_text()
    m = re.search(r'^module LoadMisalignBuffer\((.*?)\n\);', text, re.S | re.M)
    if not m:
        die('golden 里找不到 module LoadMisalignBuffer')
    res = []
    for line in m.group(1).splitlines():
        if not line.strip():
            continue
        pm = PORT_RE.match(line)
        if not pm:
            die('不认识的端口行: %r' % line)
        w = int(pm.group(2)) + 1 if pm.group(2) else 1
        res.append((pm.group(1), w, pm.group(3)))
    return res


def golden_regs():
    res = collections.OrderedDict()
    for line in GOLDEN.read_text().splitlines():
        m = REG_RE.match(line)
        if m:
            if m.group(2) in res:
                die('golden 寄存器重名 %s' % m.group(2))
            res[m.group(2)] = int(m.group(1)) + 1 if m.group(1) else 1
    return res


PORTS = golden_ports()
REGS = golden_regs()

# ---------------------------------------------------------------------------
# 1. 字段模型
# ---------------------------------------------------------------------------
# golden 展平成 <name>_<i> 的向量字段，struct 里收成一个打包向量 <name>[N-1:0]
ARRAYS = {'exceptionVec': 24, 'rep_info_cause': 11}


def split_field(f):
    m = re.fullmatch(r'(\w+?)_(\d+)', f)
    if m and m.group(1) in ARRAYS:
        return m.group(1), int(m.group(2))
    return f, None


class Struct:
    def __init__(self, name, doc):
        self.name, self.doc = name, doc
        self.members = collections.OrderedDict()   # name -> (width, arr_len or None, nested type or None)

    def add(self, field, width):
        name, idx = split_field(field)
        if idx is not None:
            if width != 1:
                die('%s.%s 向量字段元素不是 1 位' % (self.name, field))
            self.members[name] = (1, ARRAYS[name], None)
            return
        old = self.members.get(name)
        if old and old != (width, None, None):
            die('%s.%s 位宽不一致 %r vs %d' % (self.name, name, old, width))
        self.members[name] = (width, None, None)

    def add_nested(self, name, typ):
        self.members[name] = (0, None, typ)

    def member(self, field):
        """golden 扁平字段 -> (struct 成员表达式后缀, 位宽)。"""
        name, idx = split_field(field)
        m = self.members.get(name)
        if not m or m[2]:
            return None
        if idx is not None:
            return '%s[%d]' % (name, idx), 1
        return name, m[0]

    def emit(self):
        out = ['  // %s' % self.doc, '  typedef struct packed {']
        for n, (w, arr, typ) in self.members.items():
            if typ:
                out.append('    %-16s %s;' % (typ, n))
            elif arr:
                out.append('    logic %-10s %s;' % ('[%d:0]' % (arr - 1), n))
            elif w == 1:
                out.append('    logic %-10s %s;' % ('', n))
            else:
                out.append('    logic %-10s %s;' % ('[%d:0]' % (w - 1), n))
        out.append('  } %s;' % self.name)
        return out


# 接口组：(golden 端口前缀, struct 类型, 核端信号名模板, 方向, 说明)
GROUPS = [
    ('io_redirect_bits_', 'redirect_t', 'redirect', 'input',
     'Redirect（后端重定向）：本模块只用 robIdx 与 level'),
    ('io_enq_%d_req_bits_', 'enq_req_t', 'enq_bits[%d]', 'input',
     'MisalignBufferEnqIO.req：LoadUnit s3 送进来的非对齐 load（LqWriteBundle 的子集），也是条目本体 req 的类型'),
    ('io_splitLoadReq_bits_', 'split_req_t', 'split_req', 'output',
     'LsPipelineBundle：发回 LoadUnit s0 的对齐子访问（两个子访问寄存器 splitLoadReqs 也是这个类型）'),
    ('io_splitLoadResp_bits_', 'split_resp_t', 'split_resp', 'input',
     'LqWriteBundle：子访问从 LoadUnit s3 回来的结果'),
    ('io_writeBack_bits_', 'wb_t', 'wb', 'output',
     'MemExuOutput：标量写回（写 ROB / 唤醒）'),
    ('io_vecWriteBack_bits_', 'vec_wb_t', 'vec_wb', 'output',
     'VecPipelineFeedbackIO：向量元素写回（送向量合并缓冲）'),
]
# 标量口：golden 名 -> 核端口名
SCALARS = collections.OrderedDict([
    ('clock', 'clock'), ('reset', 'reset'),
    ('io_redirect_valid', 'redirect_valid'),
    ('io_enq_0_req_valid', 'enq_valid[0]'), ('io_enq_1_req_valid', 'enq_valid[1]'),
    ('io_enq_2_req_valid', 'enq_valid[2]'),
    ('io_enq_0_req_ready', 'enq_ready[0]'), ('io_enq_1_req_ready', 'enq_ready[1]'),
    ('io_enq_2_req_ready', 'enq_ready[2]'),
    ('io_splitLoadReq_ready', 'split_req_ready'), ('io_splitLoadReq_valid', 'split_req_valid'),
    ('io_splitLoadResp_valid', 'split_resp_valid'),
    ('io_writeBack_ready', 'wb_ready'), ('io_writeBack_valid', 'wb_valid'),
    ('io_vecWriteBack_valid', 'vec_wb_valid'),
    ('io_loadOutValid', 'load_out_valid'), ('io_loadVecOutValid', 'load_vec_out_valid'),
])
NUM_ENQ = 3


def classify():
    """每个 golden 端口 -> ('scalar', core) 或 ('group', gi, enq_idx, field)。恰好一类。"""
    res = collections.OrderedDict()
    for d, w, n in PORTS:
        hits = []
        if n in SCALARS:
            hits.append(('scalar', SCALARS[n]))
        for gi, (pre, _, _, gdir, _) in enumerate(GROUPS):
            if '%d' in pre:
                for i in range(NUM_ENQ):
                    p = pre % i
                    if n.startswith(p):
                        hits.append(('group', gi, i, n[len(p):]))
            elif n.startswith(pre):
                hits.append(('group', gi, None, n[len(pre):]))
        if len(hits) != 1:
            die('端口 %s 命中 %d 个分类（必须恰好 1）: %r' % (n, len(hits), hits))
        if hits[0][0] == 'group' and GROUPS[hits[0][1]][3] != d:
            die('端口 %s 方向 %s 与组方向不符' % (n, d))
        res[n] = hits[0]
    used = {h[1] for h in res.values() if h[0] == 'scalar'}
    if set(SCALARS.values()) - used:
        die('标量规则没命中任何端口: %r' % (set(SCALARS.values()) - used))
    return res


CLS = classify()
PW = {n: w for _, w, n in PORTS}


def build_structs():
    uop = Struct('uop_t', 'DynInst（后端微操作）在本模块出现过的全部字段；各接口只用其中一部分，其余在 wrapper 里补 0 / 丢弃')
    # uop 字段顺序：以 splitLoadReq 组（字段最全）为主，其余组补充
    order = [2, 1, 3, 4, 5, 0]
    for gi in order:
        for n, h in CLS.items():
            if h[0] == 'group' and h[1] == gi and (h[2] in (None, 0)) and h[3].startswith('uop_'):
                uop.add(h[3][4:], PW[n])
    structs = [uop]
    per_group = {}
    for gi, (pre, typ, core, _, doc) in enumerate(GROUPS):
        s = Struct(typ, doc)
        fields = collections.OrderedDict()
        for n, h in CLS.items():
            if h[0] == 'group' and h[1] == gi:
                fields.setdefault(h[2], []).append((h[3], PW[n]))
        if '%d' in pre:
            ref = fields[0]
            for i in range(1, NUM_ENQ):
                if fields.get(i) != ref:
                    die('enq_%d 字段表与 enq_0 不一致' % i)
            flist = ref
        else:
            flist = fields[None]
        has_uop = False
        for f, w in flist:
            if f.startswith('uop_'):
                if not has_uop:
                    s.add_nested('uop', 'uop_t')
                    has_uop = True
            else:
                s.add(f, w)
        structs.append(s)
        per_group[gi] = s
    return structs, per_group, uop


STRUCTS, GSTRUCT, UOP = build_structs()


def field_expr(gi, var, field):
    """golden 组内字段 -> 核端 struct 成员表达式；位宽核对。"""
    s = GSTRUCT[gi]
    if field.startswith('uop_'):
        m = UOP.member(field[4:])
        if not m:
            die('uop 字段 %s 不在 uop_t' % field)
        return '%s.uop.%s' % (var, m[0]), m[1]
    m = s.member(field)
    if not m:
        die('%s 里没有字段 %s' % (s.name, field))
    return '%s.%s' % (var, m[0]), m[1]


def gen_types():
    out = []
    for s in STRUCTS:
        out += s.emit()
        out.append('')
    return out[:-1]


# ---------------------------------------------------------------------------
# 2. 整包寄存器
# ---------------------------------------------------------------------------
# (golden 前缀, struct 组下标, 读回变量, 次态表达式, 复位, 使能, 说明)
PACK_REGS = [
    ('req_', 1, 'req', 'req_nxt', False, None,
     'req：入队时整包锁存，子访问异常时改写地址字段（无复位；次态 req_nxt 见 §5）'),
    ('splitLoadReqs_0_', 2, 'split_reqs[0]', 'split_new[0]', True, 'split_now',
     'splitLoadReqs(0)：低地址那一半子访问（异步复位为 0；s_split 且跨 16B 时写入，见 §3）'),
    ('splitLoadReqs_1_', 2, 'split_reqs[1]', 'split_new[1]', True, 'split_now',
     'splitLoadReqs(1)：高地址那一半子访问（同上）'),
]


# 前缀撞上但不属于整包的寄存器（核里手写）
PACK_EXCLUDE = {'req_valid'}


def pack_reg_members():
    res = collections.OrderedDict()   # prefix -> [(reg, width, suffix_expr)]
    for pre, gi, _, _, _, _, _ in PACK_REGS:
        lst = []
        for r, w in REGS.items():
            if not r.startswith(pre) or r in PACK_EXCLUDE:
                continue
            f = r[len(pre):]
            e, ew = field_expr(gi, '', f)
            if ew != w:
                die('寄存器 %s 位宽 %d 与 struct 成员 %s 位宽 %d 不符' % (r, w, e, ew))
            lst.append((r, w, e))
        if not lst:
            die('前缀 %s 一个寄存器都没匹配到' % pre)
        res[pre] = lst
    return res


PACK = pack_reg_members()
PACK_NAMES = {r for lst in PACK.values() for r, _, _ in lst}


def decl(w, name):
    return '  logic %-9s %s;' % ('' if w == 1 else '[%d:0]' % (w - 1), name)


def gen_regs():
    out = []
    for pre, gi, rd, nxt, rst, en, doc in PACK_REGS:
        lst = PACK[pre]
        out.append('  // ---- %s：golden 留下的 %d 个字段 ----' % (doc, len(lst)))
        for r, w, _ in lst:
            out.append(decl(w, r))
        if rst:
            out.append('  always_ff @(posedge clock or posedge reset) begin')
            out.append('    if (reset) begin')
            for r, w, _ in lst:
                out.append('      %s <= %s;' % (r, "1'b0" if w == 1 else "'0"))
            out.append('    end else if (%s) begin' % en)
            for r, _, e in lst:
                out.append('      %s <= %s%s;' % (r, nxt, e))
            out.append('    end')
            out.append('  end')
        else:
            out.append('  always_ff @(posedge clock) begin')
            for r, _, e in lst:
                out.append('    %s <= %s%s;' % (r, nxt, e))
            out.append('  end')
        out.append('  always_comb begin')
        out.append('    %s = \'0;   // golden 没留的字段恒 0' % rd)
        for r, _, e in lst:
            out.append('    %s%s = %s;' % (rd, e, r))
        out.append('  end')
        out.append('')
    return out[:-1]


# ---------------------------------------------------------------------------
# 3. wrapper
# ---------------------------------------------------------------------------
def gen_wrapper():
    out = ['module LoadMisalignBuffer', '  import loadmisalignbuffer_pkg::*;', '(']
    for k, (d, w, n) in enumerate(PORTS):
        rng = '' if w == 1 else '[%d:0]' % (w - 1)
        out.append('  %-6s %-8s %s%s' % (d, rng, n, ',' if k + 1 < len(PORTS) else ''))
    out.append(');')
    out.append('')
    out.append('  // 核端的 struct / 向量信号')
    for gi, (pre, typ, core, d, _) in enumerate(GROUPS):
        if '%d' in pre:
            out.append('  %-12s [NUM_ENQ-1:0] %s;' % (typ, core.split('[')[0]))
        else:
            out.append('  %-12s %s;' % (typ, core))
    out.append('  logic [NUM_ENQ-1:0] enq_valid, enq_ready;')
    out.append('')
    # 输入组：默认 0 再逐字段填
    for gi, (pre, typ, core, d, _) in enumerate(GROUPS):
        if d != 'input':
            continue
        idxs = range(NUM_ENQ) if '%d' in pre else [None]
        for i in idxs:
            var = core % i if i is not None else core
            p = pre % i if i is not None else pre
            out.append('  always_comb begin')
            out.append('    %s = \'0;   // golden 没有端口的字段（上层恒 0 / 被 DCE）补 0' % var)
            for dd, w, n in PORTS:
                h = CLS[n]
                if h[0] == 'group' and h[1] == gi and h[2] == i:
                    e, ew = field_expr(gi, var, h[3])
                    if ew != w:
                        die('端口 %s 位宽 %d vs 成员 %s %d' % (n, w, e, ew))
                    out.append('    %s = %s;' % (e, n))
            out.append('  end')
    out.append('')
    for n, h in CLS.items():
        if h[0] == 'scalar' and h[1] in ('enq_valid[0]', 'enq_valid[1]', 'enq_valid[2]'):
            out.append('  assign %s = %s;' % (h[1], n))
    for n, h in CLS.items():
        if h[0] == 'scalar' and h[1].startswith('enq_ready'):
            out.append('  assign %s = %s;' % (n, h[1]))
    out.append('')
    # 输出组：逐端口取成员
    for d, w, n in PORTS:
        h = CLS[n]
        if h[0] == 'group' and GROUPS[h[1]][3] == 'output':
            e, ew = field_expr(h[1], GROUPS[h[1]][2], h[3])
            if ew != w:
                die('端口 %s 位宽 %d vs 成员 %s %d' % (n, w, e, ew))
            out.append('  assign %s = %s;' % (n, e))
    out.append('')
    out.append('  xs_LoadMisalignBuffer_core u_core (')
    conns = []
    for n, core in SCALARS.items():
        if core.startswith('enq_'):
            continue
        conns.append('    .%s (%s)' % (core, n))
    conns.append('    .enq_valid (enq_valid)')
    conns.append('    .enq_ready (enq_ready)')
    for gi, (pre, typ, core, d, _) in enumerate(GROUPS):
        c = core.split('[')[0]
        conns.append('    .%s (%s)' % (c, c))
    out.append(',\n'.join(conns))
    out.append('  );')
    out.append('')
    out.append('endmodule')
    return out


# ---------------------------------------------------------------------------
# 4. 替换 / 导航 / 寄存器全集核对
# ---------------------------------------------------------------------------
def replace_region(text, tag, lines):
    b = '// BEGIN GENERATED(%s) —— %s 生成，勿手改' % (tag, TAG)
    e = '// END GENERATED(%s)' % tag
    pat = re.compile(r'([ \t]*)' + re.escape(b) + r'\n.*?' + re.escape(e), re.S)
    m = pat.search(text)
    if not m:
        die('找不到 GENERATED(%s) 标记' % tag)
    ind = m.group(1)
    body = '\n'.join(lines)
    return text[:m.start()] + ind + b + '\n' + (body + '\n' if lines else '') + ind + e + text[m.end():]


NAV = [
    ('loadmisalignbuffer_pkg：常量、状态编码、接口 struct、拆分方案表与小工具函数', r'^  // ---------------- 常量 ----------------'),
    ('xs_LoadMisalignBuffer_core —— 可读核：全部状态', r'^// xs_LoadMisalignBuffer_core —— 可读核'),
    ('§1 入队', r'^  // §1 入队'),
    ('§2 状态机', r'^  // §2 状态机'),
    ('§3 拆分成两个对齐子访问', r'^  // §3 拆分'),
    ('§4 发请求', r'^  // §4 发请求'),
    ('§5 收响应：异常 / uncache / replay', r'^  // §5 收响应'),
    ('§6 结果拼接', r'^  // §6 结果拼接'),
    ('§7 写回', r'^  // §7 写回'),
    ('§8 整包寄存器（生成）', r'^  // §8 整包寄存器'),
    ('golden 同名 wrapper（生成）', r'^// golden 同名 wrapper —— 端口逐位照抄'),
]


def gen_nav(text):
    lines = text.split('\n')
    out = []
    for label, pat in NAV:
        idx = [i for i, ln in enumerate(lines) if re.match(pat, ln)]
        if len(idx) != 1:
            die('导航锚点 %r 命中 %d 处（要求恰好 1 处）' % (pat, len(idx)))
        out.append('//   L%-5d %s' % (idx[0] + 1, label))
    return out


def check_reg_universe(text):
    code = re.sub(r'// BEGIN GENERATED\(regs\).*?// END GENERATED\(regs\)', '', text, flags=re.S)
    code = re.sub(r'//[^\n]*', '', code)
    core = re.search(r'module xs_LoadMisalignBuffer_core(.*?)\nendmodule', code, re.S)
    if not core:
        return ['找不到 xs_LoadMisalignBuffer_core']
    hand = {}
    for m in re.finditer(r'^\s*(logic|state_e)\s*(?:\[(\d+):0\]\s*)?([\w,\s]+?);', core.group(1), re.M):
        w = 3 if m.group(1) == 'state_e' else (int(m.group(2)) + 1 if m.group(2) else 1)
        for nm in m.group(3).split(','):
            hand[nm.strip()] = w
    errs = []
    for rn, w in REGS.items():
        if rn in PACK_NAMES:
            continue
        if rn not in hand:
            errs.append('golden 寄存器 %s 在核里没有同名声明' % rn)
        elif hand[rn] != w:
            errs.append('golden 寄存器 %s 位宽 %d，核里 %d' % (rn, w, hand[rn]))
    return errs


def main(argv):
    check = '--check' in argv
    text = RTL.read_text()
    new = replace_region(text, 'types', gen_types())
    new = replace_region(new, 'regs', gen_regs())
    new = replace_region(new, 'wrapper', gen_wrapper())
    new = replace_region(new, 'nav', gen_nav(new))
    new = replace_region(new, 'nav', gen_nav(new))
    errs = check_reg_universe(new)
    if errs:
        for e in errs[:40]:
            print('  ' + e)
        die('%d 处寄存器全集不符' % len(errs))
    sys.path.insert(0, str(TB.parent))
    from tb_template import gen_tb  # noqa: E402  (UT 目录：激励与覆盖计数的手写部分)
    tb = gen_tb(PORTS, CLS)
    outputs = [(RTL, new), (TB, tb)]
    if check:
        bad = [p for p, t in outputs if not p.exists() or p.read_text() != t]
        if bad:
            print('gen_lmisalign --check: 以下产物与生成器不一致：')
            for p in bad:
                print('  ' + str(p.relative_to(REPO)))
            return 1
        print('gen_lmisalign --check: %d 个产物与生成器一致' % len(outputs))
        return 0
    for p, t in outputs:
        if not p.exists() or p.read_text() != t:
            p.write_text(t)
            print('写入 ' + str(p.relative_to(REPO)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

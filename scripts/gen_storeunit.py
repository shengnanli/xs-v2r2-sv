#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_storeunit.py —— StoreUnit 的机械派生区生成器（rtl/memblock/StoreUnit.sv 的 GENERATED 段 + UT tb）。

★为什么要机械生成★ golden StoreUnit 有 447 个扁平端口、233 个扁平寄存器，绝大部分是
"同一份 uop / 访问包在 6 个接口和 4 级流水寄存器之间传来传去"：
  * 端口：wrapper 只是"扁平端口 ↔ 核的 struct"的拆装，手抄几百行 assign 漏一根线 UT 未必抓得住；
  * 寄存器：s1_in / s2_in / s3_in / sx_in_1 四级整包打拍。golden 每级留下哪些字段是 firtool 的
    DCE 决定的（CONVENTIONS：字段集合必须从 golden 现数，不能从 Chisel 推），所以"留哪些字段"
    这张表只能从 golden 的 reg 声明机械读出来；每个字段的**次态值**（s0_out / s1_out / s2_out /
    sx_in_0 怎么算）全部在核里手写。寄存器保持 golden 的展平名，FM 按名配对，不需要钉点。

产出（幂等）：
  rtl/memblock/StoreUnit.sv 的 GENERATED 段（手写区原样保留）：
    types       storeunit_pkg 里的 uop_t / flow_t / 各接口 struct（字段 = golden 端口表与寄存器表的并集）
    core_ports  xs_StoreUnit_core 的端口表（每个 bits 接口一个 struct 口，其余标量口）
    trigger     MemTrigger_3 例化
    pipe_regs   整包打拍寄存器组：声明 + 装载 + 读回成 struct（golden 没留的字段读回 0）
    wrapper     golden 同名 wrapper：端口表逐行照抄 golden，拆装成 struct 接核
    nav         文件头导航行号
  verif/ut/StoreUnit/tb.sv   golden StoreUnit vs StoreUnit_xs 双例化逐拍比全部输出
                             （激励 / 覆盖的手写部分在本文件 TB_HAND）

生成时的机械核对（fail-closed，任一不符拒绝生成）：
  1. 每个 golden 端口恰好归属一个接口组或一个标量口；同名字段在各处位宽一致；
  2. 每个寄存器组的每个 golden 字段都能落到对应 struct 的成员上；
  3. golden 寄存器全集 == 生成的寄存器 ∪ 核手写区里被 `<=` 赋值的名字（逐名，多一个少一个都红）；
  4. 产物代码区无 firtool 展平中间名。

用法：
    python3 scripts/gen_storeunit.py            # 生成
    python3 scripts/gen_storeunit.py --check    # 产物与生成器不一致则非零退出
"""
import collections
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = REPO / 'rtl' / 'memblock' / 'StoreUnit.sv'
TB = REPO / 'verif' / 'ut' / 'StoreUnit' / 'tb.sv'
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/StoreUnit.sv')
GOLDEN_TRIG = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/MemTrigger_3.sv')
TAG = 'scripts/gen_storeunit.py'

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')
REG_RE = re.compile(r'^\s*reg\s+(?:\[(\d+):0\]\s+)?(\w+)\s*;')


def die(msg):
    raise SystemExit('gen_storeunit: ★拒绝生成★ ' + msg)


# ---------------------------------------------------------------------------
# 0. 读 golden
# ---------------------------------------------------------------------------
def module_ports(path, mod):
    text = path.read_text()
    m = re.search(r'^module %s\((.*?)\n\);' % mod, text, re.S | re.M)
    if not m:
        die('golden 里找不到 module %s' % mod)
    res = []
    for line in m.group(1).splitlines():
        if not line.strip():
            continue
        pm = PORT_RE.match(line)
        if not pm:
            die('不认识的端口行: %r' % line)
        res.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return res, m.group(1)


def golden_regs():
    res = collections.OrderedDict()
    for line in GOLDEN.read_text().splitlines():
        m = REG_RE.match(line)
        if m:
            res[m.group(2)] = int(m.group(1)) + 1 if m.group(1) else 1
    return res


PORTS, PORT_TEXT = module_ports(GOLDEN, 'StoreUnit')
TRIG_PORTS, _ = module_ports(GOLDEN_TRIG, 'MemTrigger_3')
REGS = golden_regs()

# ---------------------------------------------------------------------------
# 1. 接口组 / 寄存器组 → struct 类型
# ---------------------------------------------------------------------------
# (golden 端口前缀, struct 类型, 核端口名)。最长前缀优先；没落进任何组的端口是标量口。
PORT_GROUPS = [
    ('io_redirect_bits_',         'redirect_t',     'redirect'),
    ('io_stin_bits_',             'stin_t',         'stin'),
    ('io_issue_bits_',            'stin_t',         'issue'),
    ('io_misalign_stin_bits_',    'flow_t',         'misalign_stin'),
    ('io_misalign_stout_bits_',   'flow_t',         'misalign_stout'),
    ('io_tlb_req_bits_',          'tlb_req_t',      'tlb_req'),
    ('io_tlb_resp_bits_',         'tlb_resp_t',     'tlb_resp'),
    ('io_pmp_',                   'pmp_t',          'pmp'),
    ('io_lsq_bits_',              'flow_t',         'lsq'),
    ('io_lsq_replenish_',         'flow_t',         'lsq_replenish'),
    ('io_feedback_slow_bits_',    'feedback_t',     'feedback_slow'),
    ('io_stld_nuke_query_bits_',  'nuke_query_t',   'stld_nuke_query'),
    ('io_stout_bits_',            'mem_out_t',      'stout'),
    ('io_vecstout_bits_',         'vec_feedback_t', 'vecstout'),
    ('io_st_mask_out_bits_',      'st_mask_t',      'st_mask_out'),
    ('io_vecstin_bits_',          'vec_in_t',       'vecstin'),
    ('io_misalign_enq_req_bits_', 'flow_t',         'misalign_enq_req'),
]
# (golden 寄存器前缀, struct 类型, 读回成的 struct 信号, 装载使能, 装载源)
REG_GROUPS = [
    ('s1_in_',                    'flow_t',     's1_in',           's0_fire',                  's0_out'),
    ('s2_in_',                    'flow_t',     's2_in',           's1_fire',                  's1_out'),
    ('s3_in_',                    'flow_t',     's3_in',           's2_fire',                  's2_out'),
    ('sx_in_1_r_',                'sx_t',       'sx_in_1',         'sx_prev_fire',             'sx_in_0'),
    ('io_feedback_slow_bits_r_',  'feedback_t', 'feedback_slow_r', 'feedback_slow_valid_next', 's1_feedback'),
]
REG_GROUP_DOC = {
    's1_in_': 's1_in <= s0_out（s0_fire 时整包打拍，无复位）',
    's2_in_': 's2_in <= s1_out（s1_fire 时整包打拍，无复位）',
    's3_in_': 's3_in <= s2_out（s2_fire 时整包打拍，无复位）',
    'sx_in_1_r_': 'sx_in_1 <= sx_in_0（写回延迟级，s3 发出时打拍，无复位）',
    'io_feedback_slow_bits_r_': 'feedback_slow_r <= s1_feedback（s1 反馈有效时打拍，无复位）',
}
TYPE_DOC = collections.OrderedDict([
    ('uop_t',          '微操作信息（DynInst 在本模块各接口 / 各级留下的字段并集）'),
    ('redirect_t',     'redirect（冲刷）'),
    ('stin_t',         '发射队列来的标量 store（MemExuInput）'),
    ('vec_in_t',       '向量拆分流水来的元素访问（VecPipeBundle）'),
    ('flow_t',         '流水各级传递的访问包（LsPipelineBundle 并集；SQ / 非对齐缓冲接口也用它）'),
    ('tlb_req_t',      'DTLB 请求'),
    ('tlb_resp_t',     'DTLB 应答'),
    ('pmp_t',          'PMP / PMA 检查结果'),
    ('feedback_t',     '给发射队列的反馈（RSFeedback）'),
    ('nuke_query_t',   'st-ld 违例查询（StoreNukeQueryBundle）'),
    ('mem_out_t',      '标量写回（MemExuOutput）'),
    ('sx_t',           '写回延迟级的包（VecMemExuOutput：标量写回 + 向量元素信息）'),
    ('vec_feedback_t', '向量 store 写回（VecPipelineFeedbackIO）'),
    ('st_mask_t',      '提前告诉 SQ 的字节掩码（StoreMaskBundle）'),
])
HAS_UOP = {'stin_t', 'vec_in_t', 'flow_t', 'mem_out_t'}
EXC_W = 24


class Struct:
    def __init__(self, name):
        self.name = name
        self.members = collections.OrderedDict()   # name -> width(int) 或 类型名(str)

    def add(self, name, width):
        old = self.members.get(name)
        if old is not None and old != width:
            die('%s.%s 位宽不一致 %r vs %r' % (self.name, name, old, width))
        self.members[name] = width


TYPES = collections.OrderedDict((n, Struct(n)) for n in TYPE_DOC)
TYPES['stin_t'].add('uop', 'uop_t')
TYPES['vec_in_t'].add('uop', 'uop_t')
TYPES['flow_t'].add('uop', 'uop_t')
TYPES['mem_out_t'].add('uop', 'uop_t')
TYPES['sx_t'].add('out', 'mem_out_t')


def resolve(typ, field, width, declare):
    """golden 扁平字段名 → struct 成员访问路径（如 '.uop.exceptionVec[3]'）。declare=True 时登记成员。"""
    if typ == 'sx_t' and field.startswith('output_'):
        return '.out' + resolve('mem_out_t', field[len('output_'):], width, declare)
    if typ in HAS_UOP and field.startswith('uop_'):
        return '.uop' + resolve('uop_t', field[len('uop_'):], width, declare)
    st = TYPES[typ]
    m = re.fullmatch(r'exceptionVec_(\d+)', field)
    if m:
        if width != 1 or int(m.group(1)) >= EXC_W:
            die('%s.%s 不是合法的 exceptionVec 位' % (typ, field))
        if declare:
            st.add('exceptionVec', EXC_W)
        elif 'exceptionVec' not in st.members:
            die('%s 没有 exceptionVec' % typ)
        return '.exceptionVec[%s]' % m.group(1)
    if declare:
        st.add(field, width)
    elif st.members.get(field) != width:
        die('%s.%s 不存在或位宽不符（要 %d，有 %r）' % (typ, field, width, st.members.get(field)))
    return '.' + field


def classify_ports():
    """返回 [(dir, width, name, group_or_None, field)]，并登记 struct 成员。"""
    groups = sorted(PORT_GROUPS, key=lambda g: -len(g[0]))
    res = []
    for d, w, n in PORTS:
        for g in groups:
            if n.startswith(g[0]):
                resolve(g[1], n[len(g[0]):], w, True)
                res.append((d, w, n, g, n[len(g[0]):]))
                break
        else:
            res.append((d, w, n, None, None))
    return res


def classify_regs():
    """返回 {prefix: [(regname, width, field)]}，并登记 struct 成员。"""
    res = collections.OrderedDict((g[0], []) for g in REG_GROUPS)
    groups = sorted(REG_GROUPS, key=lambda g: -len(g[0]))
    for n, w in REGS.items():
        for g in groups:
            if n.startswith(g[0]):
                resolve(g[1], n[len(g[0]):], w, True)
                res[g[0]].append((n, w, n[len(g[0]):]))
                break
    return res


CPORTS = classify_ports()
CREGS = classify_regs()
PIPE_REGS = {n for lst in CREGS.values() for n, _, _ in lst}

# 每个组方向必须一致
GROUP_DIR = {}
for d, w, n, g, f in CPORTS:
    if g:
        if GROUP_DIR.setdefault(g[2], d) != d:
            die('接口组 %s 方向不一致' % g[2])


def wdecl(w):
    return 'logic' if w == 1 else 'logic [%d:0]' % (w - 1)


def core_name(port):
    return port[3:] if port.startswith('io_') else port


# ---------------------------------------------------------------------------
# 2. 各 GENERATED 段
# ---------------------------------------------------------------------------
def gen_types():
    out = []
    for name, doc in TYPE_DOC.items():
        st = TYPES[name]
        if not st.members:
            die('类型 %s 没有成员' % name)
        out.append('  // %s' % doc)
        out.append('  typedef struct packed {')
        for mn, w in st.members.items():
            out.append('    %-14s %s;' % (w if isinstance(w, str) else wdecl(w), mn))
        out.append('  } %s;' % name)
        out.append('')
    return out[:-1]


def gen_core_ports():
    lines = []
    seen = set()
    for d, w, n, g, f in CPORTS:
        if g:
            if g[2] in seen:
                continue
            seen.add(g[2])
            lines.append('  %-6s %-14s %s' % (d, g[1], g[2]))
        else:
            lines.append('  %-6s %-14s %s' % (d, wdecl(w), core_name(n)))
    return [ln + ',' for ln in lines[:-1]] + [lines[-1]]


TRIG_HAND = {
    'tdataVec_io_fromLoadStore_vaddr':              's1_fullva[VADDR_W-1:0]',
    'tdataVec_io_fromLoadStore_isVectorUnitStride': 's1_in.isvec & s1_in.is128bit',
    'tdataVec_io_fromLoadStore_mask':               's1_in.mask',
    'tdataVec_io_toLoadStore_triggerAction':        's1_trigger_action',
    'tdataVec_io_toLoadStore_triggerVaddr':         's1_trigger_vaddr',
    'tdataVec_io_isCbo':                            's1_isCbo',
}


def gen_trigger():
    scalars = {core_name(n): w for d, w, n, g, f in CPORTS if not g}
    out = ['  MemTrigger_3 storeTrigger (']
    conns = []
    for d, w, n in TRIG_PORTS:
        if n in TRIG_HAND:
            conns.append((n, TRIG_HAND[n]))
        else:
            src = n[len('tdataVec_io_'):]
            if scalars.get(src) != w:
                die('MemTrigger_3 端口 %s 在核里没有同宽的 %s' % (n, src))
            conns.append((n, src))
    for i, (p, s) in enumerate(conns):
        out.append('    .%-52s (%s)%s' % (p, s, ',' if i < len(conns) - 1 else ''))
    out.append('  );')
    return out


def gen_pipe_regs():
    out = []
    for prefix, typ, sig, en, src in REG_GROUPS:
        regs = CREGS[prefix]
        out.append('  // ---- %s：golden 留下的 %d 个字段 ----' % (REG_GROUP_DOC[prefix], len(regs)))
        for n, w, f in regs:
            out.append('  %-14s %s;' % (wdecl(w), n))
        out.append('  always_ff @(posedge clock) begin')
        out.append('    if (%s) begin' % en)
        for n, w, f in regs:
            out.append('      %s <= %s%s;' % (n, src, resolve(typ, f, w, False)))
        out.append('    end')
        out.append('  end')
        out.append('  always_comb begin')
        out.append("    %s = '0;" % sig)
        for n, w, f in regs:
            out.append('    %s%s = %s;' % (sig, resolve(typ, f, w, False), n))
        out.append('  end')
        out.append('')
    return out[:-1]


def gen_wrapper():
    out = ['module StoreUnit', '  import storeunit_pkg::*;', '(']
    out += PORT_TEXT.strip('\n').split('\n')
    out.append(');')
    out.append('')
    by_group = collections.OrderedDict()
    for d, w, n, g, f in CPORTS:
        if g:
            by_group.setdefault(g[2], []).append((d, w, n, g, f))
    for gname, lst in by_group.items():
        typ = lst[0][3][1]
        out.append('  %-14s %s;' % (typ, gname))
        if GROUP_DIR[gname] == 'input':
            out.append('  always_comb begin')
            out.append("    %s = '0;" % gname)
            for d, w, n, g, f in lst:
                out.append('    %s%s = %s;' % (gname, resolve(typ, f, w, False), n))
            out.append('  end')
        else:
            for d, w, n, g, f in lst:
                out.append('  assign %s = %s%s;' % (n, gname, resolve(typ, f, w, False)))
        out.append('')
    out.append('  xs_StoreUnit_core u_core (')
    conns = []
    seen = set()
    for d, w, n, g, f in CPORTS:
        if g:
            if g[2] not in seen:
                seen.add(g[2])
                conns.append((g[2], g[2]))
        else:
            conns.append((core_name(n), n))
    for i, (p, s) in enumerate(conns):
        out.append('    .%-44s (%s)%s' % (p, s, ',' if i < len(conns) - 1 else ''))
    out.append('  );')
    out.append('')
    out.append('endmodule')
    return out


NAV = [
    ('storeunit_pkg：常量、译码与掩码小函数、接口 struct（生成）', r'^  // -{16} 位宽 -{16}'),
    ('xs_StoreUnit_core —— 可读核',                               r'^// xs_StoreUnit_core —— 可读核'),
    ('s0：三路来源选一路，算虚地址 / 掩码 / 对齐，发 DTLB 请求',  r'^  // s0：'),
    ('s1：TLB 应答、调试触发器、写 SQ、违例查询、非对齐入缓冲',   r'^  // s1：'),
    ('s2：PMP 应答、异常与 MMIO 判定、补写 SQ、反馈',             r'^  // s2：'),
    ('s3 + sx：写回',                                             r'^  // s3 \+ sx：'),
    ('整包打拍寄存器（生成）',                                    r'^  // 整包打拍寄存器（生成）'),
    ('golden 同名 wrapper（生成）',                               r'^// golden 同名 wrapper（生成）'),
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


def replace_region(text, tag, body):
    pat = re.compile(r'(^[ \t]*// BEGIN GENERATED\(%s\)[^\n]*\n)(.*?)(^[ \t]*// END GENERATED\(%s\))' % (tag, tag),
                     re.S | re.M)
    if len(pat.findall(text)) != 1:
        die('GENERATED(%s) 标记不是恰好一对' % tag)
    return pat.sub(lambda m: m.group(1) + ''.join(ln + '\n' for ln in body) + m.group(3), text)


def check_reg_universe(text):
    """golden 寄存器全集 == 生成的寄存器 ∪ 核手写区里被 `<=` 赋值的名字（逐名）。"""
    code = re.sub(r'// BEGIN GENERATED\(pipe_regs\).*?// END GENERATED\(pipe_regs\)', '', text, flags=re.S)
    code = re.sub(r'//[^\n]*', '', code)
    core = re.search(r'module xs_StoreUnit_core(.*?)\nendmodule', code, re.S)
    if not core:
        return ['找不到 xs_StoreUnit_core']
    hand = set(re.findall(r'^\s*(?:if\s*\([^\n]*\)\s*|else\s+)?(\w+)\s*<=', core.group(1), re.M))
    want = set(REGS) - PIPE_REGS
    errs = ['golden 寄存器 %s 在核手写区没有同名寄存器' % n for n in sorted(want - hand)]
    errs += ['核手写区的寄存器 %s 不在 golden 寄存器表里' % n for n in sorted(hand - want)]
    return errs


# ---------------------------------------------------------------------------
# 3. tb
# ---------------------------------------------------------------------------
TB_HEAD = r'''// =============================================================================
// StoreUnit UT —— golden StoreUnit 对重写 StoreUnit_xs 双例化，同激励逐拍比全部 %(nout)d 根输出。
// 本文件由 scripts/gen_storeunit.py 生成（端口连接 / 随机驱动 / 逐根比较是机械部分，
// 激励整形与覆盖判据是生成器里 TB_HAND 的手写部分）。勿手改。
//
// 激励要点：
//   · 每拍所有输入先整体随机，再整形：三路来源 valid 以 1/2、1/4、1/8 的概率出现（保证三种
//     流都被选中，也有相互挤占）；redirect 1/16；
//   · 标量 fuOpType 在 sb/sh/sw/sd、cbo.zero、cbo.clean/flush/inval、hsv、全随机之间分桶；
//     地址低位随机 ⇒ 对齐 / 16B 内非对齐 / 跨 16B 三种情形都常见；
//   · sqCommitPtr 以 1/2 概率对准当前标量 store（跨 16B 时"能进缓冲 / 要重发"两边都打）；
//   · TLB：miss 1/4，Svpbmt 偏向 PMA，各页异常位 1/16；memidx 以 1/2 概率对准 s1 的 sqIdx；
//   · PMP：st/ld 1/16，mmio 1/8；
//   · 触发器：一半时间全关；其余时间 tdata2 取 s1 虚地址附近（相等 / 略大略小 / 同 16B / 同缓存行）。
// 不复位寄存器：+vcs+initreg+random / +<seed> 两个实例各摇各的，先跑 +warmup 拍（各级流水寄存器
//   都被写过）再开始比。
// 覆盖判据（读重写核内部信号，逐项有下限，不达标本轮不作数）：见 cov_names。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 0;
  int      errors = 0;
  longint  checks = 0;
  bit      comparing = 0;

  logic clock = 0;
  logic reset;
  always #5 clock = ~clock;
'''

TB_HAND = r'''
  // ---------------------------------------------------------------------------
  // 手写：激励整形
  // ---------------------------------------------------------------------------
  function automatic logic [63:0] near(logic [63:0] va);
    logic [63:0] t;
    case ($urandom_range(0, 7))
      0: t = {14'h0, va[49:0]};
      1: t = {14'h0, va[49:0]} + $urandom_range(1, 40);
      2: t = {14'h0, va[49:0]} - $urandom_range(1, 40);
      3: t = {14'h0, va[49:4], 4'($urandom)};
      4: t = {14'($urandom), va[49:4], 4'($urandom)};
      5: t = {14'h0, va[49:6], 6'($urandom)};
      6: t = {14'h0, va[49:6] + 44'($urandom_range(0, 2)) - 44'd1, 6'($urandom)};
      default: t = {$urandom, $urandom};
    endcase
    return t;
  endfunction

`define TRIG_CFG(I) \
    io_fromCsrTrigger_tdataVec_``I``_matchType = 2'($urandom); \
    io_fromCsrTrigger_tdataVec_``I``_select    = ($urandom_range(0, 9) == 0); \
    io_fromCsrTrigger_tdataVec_``I``_timing    = ($urandom_range(0, 3) == 0); \
    io_fromCsrTrigger_tdataVec_``I``_chain     = ($urandom_range(0, 3) == 0); \
    io_fromCsrTrigger_tdataVec_``I``_store     = ($urandom_range(0, 9) != 0); \
    io_fromCsrTrigger_tdataVec_``I``_action    = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1)); \
    io_fromCsrTrigger_tdataVec_``I``_tdata2    = $urandom_range(0, 1) ? near(target) : {$urandom, $urandom}; \
    io_fromCsrTrigger_tEnableVec_``I``         = trig_on & ($urandom_range(0, 9) != 0);

  task automatic drive();
    logic [63:0] target;
    logic        trig_on;
    drive_random();
    io_redirect_valid      = ($urandom_range(0, 15) == 0);
    io_stin_valid          = ($urandom_range(0, 1) == 0);
    io_vecstin_valid       = ($urandom_range(0, 3) == 0);
    io_misalign_stin_valid = ($urandom_range(0, 7) == 0);
    case ($urandom_range(0, 15))
      0:       io_stin_bits_uop_fuOpType = 9'h007;                              // cbo.zero
      1:       io_stin_bits_uop_fuOpType = 9'h00C + 9'($urandom_range(0, 2));   // cbo.clean/flush/inval
      2:       io_stin_bits_uop_fuOpType = 9'h010 + 9'($urandom_range(0, 3));   // hsv.b/h/w/d
      3:       io_stin_bits_uop_fuOpType = 9'($urandom);
      default: io_stin_bits_uop_fuOpType = 9'($urandom_range(0, 3));            // sb/sh/sw/sd
    endcase
    if ($urandom_range(0, 3) != 0) io_misalign_stin_bits_uop_fuOpType = 9'($urandom_range(0, 3));
    if ($urandom_range(0, 1)) begin
      io_sqCommitPtr_flag  = io_stin_bits_uop_sqIdx_flag;
      io_sqCommitPtr_value = io_stin_bits_uop_sqIdx_value;
    end
    // TLB
    io_tlb_resp_valid     = ($urandom_range(0, 7) != 0);
    io_tlb_resp_bits_miss = ($urandom_range(0, 3) == 0);
    io_tlb_resp_bits_pbmt_0 = ($urandom_range(0, 7) < 5) ? 2'd0 : 2'($urandom);
    io_tlb_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_gpf_st = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_pf_ld  = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_pf_st  = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_af_ld  = ($urandom_range(0, 15) == 0);
    io_tlb_resp_bits_excp_0_af_st  = ($urandom_range(0, 15) == 0);
    if ($urandom_range(0, 1)) io_tlb_resp_bits_memidx_idx = {1'b0, u_golden.s1_in_uop_sqIdx_value};
    // PMP / CSR / 非对齐缓冲
    io_pmp_st   = ($urandom_range(0, 15) == 0);
    io_pmp_ld   = ($urandom_range(0, 15) == 0);
    io_pmp_mmio = ($urandom_range(0, 7) == 0);
    io_csrCtrl_hd_misalign_st_enable = ($urandom_range(0, 15) != 0);
    io_misalign_enq_req_ready        = ($urandom_range(0, 3) != 0);
    // 触发器
    target  = u_golden.s1_in_isFrmMisAlignBuf ? {14'h0, u_golden.s1_in_vaddr} : io_tlb_resp_bits_fullva;
    trig_on = ($urandom_range(0, 1) == 0);
    `TRIG_CFG(0)
    `TRIG_CFG(1)
    `TRIG_CFG(2)
    `TRIG_CFG(3)
    io_fromCsrTrigger_debugMode            = ($urandom_range(0, 15) == 0);
    io_fromCsrTrigger_triggerCanRaiseBpExp = ($urandom_range(0, 5) != 0);
  endtask

  // ---------------------------------------------------------------------------
  // 手写：覆盖计数（读重写核内部信号）
  // ---------------------------------------------------------------------------
  localparam int NCOV = 28;
  longint cov [NCOV];
  string  cov_names [NCOV] = '{
    "s0_fire_rs", "s0_fire_vec", "s0_fire_ma", "s0_kill", "s0_cbo", "s0_cross16", "s0_misalign_in16",
    "s0_need_replay", "s1_tlbmiss_kill", "s1_redirect_flush", "s1_trig_breakpoint", "s1_trig_debugmode",
    "s1_enq_misalign", "s1_enq_nack", "s1_resptime_stamp", "s2_mmio_kill", "s2_exception",
    "s2_access_fault", "s2_addr_misaligned", "s2_revoke", "s2_mab_stout", "s2_no_writeback",
    "s3_kill", "sx_kill", "stout", "vecstout", "feedback_hit", "feedback_miss"};
  int cov_min [NCOV] = '{
    1000, 1000, 1000, 100, 100, 100, 100,
    100, 100, 100, 20, 20,
    100, 20, 100, 20, 100,
    100, 5, 100, 100, 20,
    20, 20, 1000, 100, 100, 100};

`define C u_impl.u_core
  task automatic collect_cov();
    if (`C.s0_fire & `C.s0_use_flow_rs)  cov[0]++;
    if (`C.s0_fire & `C.s0_use_flow_vec) cov[1]++;
    if (`C.s0_fire & `C.s0_use_flow_ma)  cov[2]++;
    if (`C.s0_valid & `C.s0_kill)        cov[3]++;
    if (`C.s0_fire & `C.s0_isCbo)        cov[4]++;
    if (`C.s0_fire & `C.s0_rs_cross16Bytes & ~`C.s0_addr_aligned) cov[5]++;
    if (`C.s0_fire & `C.s0_misalignWith16Byte)                    cov[6]++;
    if (`C.s0_fire & `C.s0_misalignNeedReplay)                    cov[7]++;
    if (`C.s1_valid & `C.s1_tlb_miss & ~`C.s1_isvec & ~`C.s1_frm_mabuf) cov[8]++;
    if (`C.s1_valid & `C.s1_redirect_flush)                       cov[9]++;
    if (`C.s1_fire & `C.s1_trigger_breakpoint)                    cov[10]++;
    if (`C.s1_fire & `C.s1_trigger_debug_mode)                    cov[11]++;
    if (`C.misalign_enq_req_valid & io_misalign_enq_req_ready)    cov[12]++;
    if (`C.s1_fire & `C.s1_toMisalignBufferValid & (~io_misalign_enq_req_ready | `C.s1_misalignNeedReplay)) cov[13]++;
    if (`C.s1_fire & (`C.s1_out.uop.debugInfo_tlbRespTime == `C.s1_out_uop_debugInfo_tlbRespTime_c)) cov[14]++;
    if (`C.s2_valid & `C.s2_mmio & ~`C.s2_exception & ~`C.s2_in.isvec & ~`C.s2_frm_mabuf) cov[15]++;
    if (`C.s2_fire & `C.s2_exception)                             cov[16]++;
    if (`C.s2_fire & `C.s2_access_fault)                          cov[17]++;
    if (`C.s2_fire & `C.s2_addr_misaligned)                       cov[18]++;
    if (`C.s2_valid & `C.misalign_enq_revoke)                     cov[19]++;
    if (`C.misalign_stout_valid)                                  cov[20]++;
    if (`C.s2_fire & ~`C.s2_misalign_cango)                       cov[21]++;
    if (`C.s3_valid & `C.s3_kill)                                 cov[22]++;
    if (`C.sx_valid_1_r & `C.sx_cur_kill)                         cov[23]++;
    if (`C.stout_valid)                                           cov[24]++;
    if (`C.vecstout_valid)                                        cov[25]++;
    if (`C.feedback_slow_valid & `C.feedback_slow.hit)            cov[26]++;
    if (`C.feedback_slow_valid & ~`C.feedback_slow.hit)           cov[27]++;
  endtask

  initial begin
    int bad = 0;
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    if (!$value$plusargs("warmup=%d", WARMUP))   WARMUP  = 0;
    for (int i = 0; i < NCOV; i++) cov[i] = 0;
    reset = 1'b1;
    drive();
    io_stin_valid = 0; io_vecstin_valid = 0; io_misalign_stin_valid = 0;
    repeat (5) @(negedge clock);
    reset = 1'b0;
    for (int c = 0; c < NCYCLES + WARMUP; c++) begin
      drive();
      #4;
      comparing = (c >= WARMUP);
      if (comparing) begin
        compare();
        collect_cov();
      end
      @(negedge clock);
    end
    for (int i = 0; i < NCOV; i++) begin
      $display("  cov %-22s = %0d (min %0d)%s", cov_names[i], cov[i], cov_min[i],
               (cov[i] < cov_min[i]) ? "  <-- LOW" : "");
      if (cov[i] < cov_min[i]) bad++;
    end
    $display("=== COVERAGE (StoreUnit) === checks=%0d uncovered=%0d", checks, bad);
    if (bad != 0) begin $display("COVERAGE INSUFFICIENT"); errors++; end
    $display("StoreUnit UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) $display("TEST PASSED (checks=%0d)", checks);
    else             $display("TEST FAILED errors=%0d (checks=%0d)", errors, checks);
    $finish;
  end
endmodule
'''


def rnd_expr(w, name):
    if 'exceptionVec' in name:
        return '($urandom_range(0, 7) == 0)'
    if w <= 32:
        return "%d'($urandom)" % w
    parts = ['$urandom'] * ((w + 31) // 32)
    return "%d'({%s})" % (w, ', '.join(parts))


def gen_tb():
    ins = [(w, n) for d, w, n in PORTS if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in PORTS if d == 'output']
    o = [TB_HEAD % {'nout': len(outs)}]
    o.append('  // ---- 输入（两侧共用）----')
    for w, n in ins:
        o.append('  %-14s %s;' % (wdecl(w), n))
    o.append('  // ---- 输出：g_ = golden，x_ = 重写 ----')
    for w, n in outs:
        o.append('  wire %-13s g_%s, x_%s;' % ('' if w == 1 else '[%d:0]' % (w - 1), n, n))
    for inst, mod, pfx in (('u_golden', 'StoreUnit', 'g_'), ('u_impl', 'StoreUnit_xs', 'x_')):
        o.append('')
        o.append('  %s %s (' % (mod, inst))
        conns = []
        for d, w, n in PORTS:
            conns.append('    .%s (%s)' % (n, n if d == 'input' else pfx + n))
        o.append(',\n'.join(conns))
        o.append('  );')
    o.append('')
    o.append('  // ---- 所有输入整体随机（整形在 drive 里）----')
    o.append('  task automatic drive_random();')
    for w, n in ins:
        o.append('    %s = %s;' % (n, rnd_expr(w, n)))
    o.append('  endtask')
    o.append('')
    o.append('  // ---- 逐根比较 ----')
    o.append('`define CMP(SIG) \\')
    o.append('    if (g_``SIG !== x_``SIG) begin \\')
    o.append('      errors++; \\')
    o.append('      if (errors < 30) $display("MISMATCH @%0d %s g=%h x=%h", checks, `"SIG`", g_``SIG, x_``SIG); \\')
    o.append('    end')
    o.append('  task automatic compare();')
    o.append('    checks++;')
    for w, n in outs:
        o.append('    `CMP(%s)' % n)
    o.append('  endtask')
    o.append(TB_HAND)
    return '\n'.join(o)


# ---------------------------------------------------------------------------
def build(text):
    new = replace_region(text, 'types', gen_types())
    new = replace_region(new, 'core_ports', gen_core_ports())
    new = replace_region(new, 'trigger', gen_trigger())
    new = replace_region(new, 'pipe_regs', gen_pipe_regs())
    new = replace_region(new, 'wrapper', gen_wrapper())
    # 导航行数固定：先填一遍让行数到位，再按到位后的行号填第二遍
    new = replace_region(new, 'nav', gen_nav(new))
    new = replace_region(new, 'nav', gen_nav(new))
    return new


def main(argv):
    check = '--check' in argv
    text = RTL.read_text()
    new = build(text)
    errs = check_reg_universe(new)
    code = re.sub(r'//[^\n]*', '', new)
    if re.search(r'_GEN_|_T_\d|\b_T\b', code):
        errs.append('产物代码区出现 firtool 展平中间名')
    if errs:
        die('\n  '.join(['机械核对未通过：'] + errs))
    tb = gen_tb()
    if check:
        bad = []
        if new != text:
            bad.append(str(RTL.relative_to(REPO)))
        if not TB.exists() or TB.read_text() != tb:
            bad.append(str(TB.relative_to(REPO)))
        if bad:
            print('gen_storeunit --check: DRIFT ' + ', '.join(bad))
            return 1
        print('gen_storeunit --check: OK（%d 端口 / %d 寄存器 = 生成 %d + 手写 %d）'
              % (len(PORTS), len(REGS), len(PIPE_REGS), len(REGS) - len(PIPE_REGS)))
        return 0
    if new != text:
        RTL.write_text(new)
    TB.parent.mkdir(parents=True, exist_ok=True)
    if not TB.exists() or TB.read_text() != tb:
        TB.write_text(tb)
    print('gen_storeunit: 已生成（%d 端口 / %d 寄存器 = 生成 %d + 手写 %d）'
          % (len(PORTS), len(REGS), len(PIPE_REGS), len(REGS) - len(PIPE_REGS)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

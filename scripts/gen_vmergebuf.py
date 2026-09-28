#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_vmergebuf.py —— VMergeBuffer 家族（VLMergeBufferImp / VSMergeBufferImp）的机械派生区。

产物（全部从 G1 golden 端口表现场读出，不抄手）：
  rtl/memblock/VLMergeBufferImp.sv
    · GENERATED(structs)         package 里的端口 struct：成员 = 两个变体端口的并集
    · GENERATED(deq_pipe)        核里 NewPipelineConnectPipe_29 的端口连线
    · GENERATED(uop_store)       核里"入队照抄、出队原样送出"的 uop 字段：每字段一个数组
    · GENERATED(wrapper_VLMergeBufferImp)   golden 同名 wrapper（端口逐行照 golden）
  rtl/memblock/VSMergeBufferImp.sv
    · GENERATED(wrapper_VSMergeBufferImp)
  verif/ut/VMergeBuffer/tb.sv    双例化 UT（两个变体各一对 golden vs *_xs）

★与 golden 的机械对账（fail-closed）★
  1. uop_store 里的每个字段，两个变体的 golden 里都必须有 `entries_0_uop_<字段>` 寄存器；
  2. golden 里每个 `entries_0_*` 寄存器都必须落在"本脚本生成的字段 ∪ 核里手写的字段表"里，
     手写字段表 HAND_FIELDS 按变体给出 —— golden 多一个、少一个都报错（寄存器字段集合必须
     逐字对齐，见 CONVENTIONS「golden 的寄存器字段集合必须逐字照搬」）。
  3. wrapper 的输入常量（端口被 firtool 常量传播删掉的字段）只许来自 TIES 表，且 TIES 里的
     每个成员在该变体里都必须**确实没有**对应端口。

用法：
  python3 scripts/gen_vmergebuf.py          # 生成（幂等）
  python3 scripts/gen_vmergebuf.py --check  # 与库里的产物不一致则非零退出
"""
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
RTL_VL = REPO / 'rtl' / 'memblock' / 'VLMergeBufferImp.sv'
RTL_VS = REPO / 'rtl' / 'memblock' / 'VSMergeBufferImp.sv'
TB = REPO / 'verif' / 'ut' / 'VMergeBuffer' / 'tb.sv'
TAG = 'scripts/gen_vmergebuf.py'

VARIANTS = {
    'VLMergeBufferImp': dict(short='vl', is_vs=0, enq=2, pipe=3, deq=2, thr=6, exc='VLDU_EXC_SEL',
                             rtl=RTL_VL),
    'VSMergeBufferImp': dict(short='vs', is_vs=1, enq=1, pipe=1, deq=1, thr=3, exc='VSTU_EXC_SEL',
                             rtl=RTL_VS),
}

# 端口被 firtool 跨模块常量传播删掉的输入字段：上游恒送的常量（量自 golden 的常量折叠结果）。
#   VL：mergePortMatrixMiss_* 全是 1'h0（hit 恒 1）、sourceTypeNext = entries.sourceType（|0）、
#       flushState 写入值恒 0；VS：sourceTypeNext = entries.sourceType | 3'h1、flushState 恒 0。
TIES = {
    'VLMergeBufferImp': {('pipe', 'hit'): "1'b1", ('pipe', 'sourceType'): "3'h0",
                         ('pipe', 'flushState'): "1'b0"},
    'VSMergeBufferImp': {('pipe', 'sourceType'): "3'h1", ('pipe', 'flushState'): "1'b0"},
}
# 不对应任何 golden 端口、只由 TIES 驱动的 pipe 成员
PIPE_EXTRA = [('sourceType', 3), ('flushState', 1)]

# 核里手写存储的条目字段（除 uop_store 生成的之外），按变体。键是 golden 的 entries_0_<名>。
HAND_COMMON = {'mask', 'flowNum', 'exceptionVec', 'uop_trigger', 'sourceType', 'elemIdx', 'vstart',
               'vlmax', 'vaddr', 'gpaddr', 'vaNeedExt', 'isForVSnonLeafPTE', 'replayFlowNum',
               'replayFlowMask'}
HAND_FIELDS = {
    'VLMergeBufferImp': HAND_COMMON | {'data', 'vdIdx', 'fof', 'vl', 'originVl', 'flushState'},
    'VSMergeBufferImp': HAND_COMMON | {'isPartReplay', 'uop_vpu_vmask', 'uop_vpu_vl'},
}
# uop 里由核手写处理、不进 uop_store 的成员
UOP_HAND = {'exceptionVec', 'trigger', 'vpu_vstart', 'vpu_vmask', 'vpu_vl'}

PORT_RE = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+)\s*,?\s*$')


def read_ports(mod):
    text = (GOLDEN / f'{mod}.sv').read_text()
    m = re.search(r'^module\s+' + mod + r'\s*\((.*?)^\);', text, re.S | re.M)
    assert m, mod
    ports = []
    for ln in m.group(1).splitlines():
        pm = PORT_RE.match(ln)
        if pm:
            ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    assert ports, mod
    return ports


EXC_NOS = {'VLMergeBufferImp': {3, 4, 5, 13, 19, 21}, 'VSMergeBufferImp': {3, 6, 7, 15, 19, 23}}


def golden_entry_fields(mod):
    """golden 条目 0 的寄存器字段名；exceptionVec_<n> 收成 exceptionVec，且异常号集合必须
    等于本变体的 exceptionOut（核里按 EXC_SEL 压缩存储，两者要逐位对上）"""
    text = (GOLDEN / f'{mod}.sv').read_text()
    names = set(re.findall(r'^\s*reg\s+(?:\[\d+:0\]\s+)?entries_0_(\w+);', text, re.M))
    excs = {int(m.group(1)) for n in names for m in [re.fullmatch(r'exceptionVec_(\d+)', n)] if m}
    assert excs == EXC_NOS[mod], f'{mod}: golden 条目异常位 {sorted(excs)} != exceptionOut'
    sel = int(re.search(VARIANTS[mod]['exc'] + r" = 24'h([0-9A-Fa-f_]+);",
                        RTL_VL.read_text()).group(1).replace('_', ''), 16)
    assert sel == sum(1 << b for b in excs), f'{mod}: 包里的 {VARIANTS[mod]["exc"]} 与 golden 不一致'
    return {n for n in names if not n.startswith('exceptionVec_')} | {'exceptionVec'}


def classify(name):
    """golden 端口名 -> (组, 口号, 成员路径)。成员路径里 exceptionVec_<n> 写成 exceptionVec[n]。"""
    pats = [
        (r'io_redirect_(valid)$', 'redirect'),
        (r'io_redirect_bits_(\w+)$', 'redirect'),
        (r'io_fromPipeline_(\d+)_(valid)$', 'pipe'),
        (r'io_fromPipeline_(\d+)_bits_(\w+)$', 'pipe'),
        (r'io_fromSplit_(\d+)_req_(ready)$', 'enq_ready'),
        (r'io_fromSplit_(\d+)_req_(valid)$', 'enq'),
        (r'io_fromSplit_(\d+)_req_bits_(\w+)$', 'enq'),
        (r'io_fromSplit_(\d+)_resp_(valid)$', 'enq_resp_valid'),
        (r'io_fromSplit_(\d+)_resp_bits_(mBIndex)$', 'enq_resp_mBIndex'),
        (r'io_uopWriteback_(\d+)_(ready)$', 'wb_ready'),
        (r'io_uopWriteback_(\d+)_(valid)$', 'wb'),
        (r'io_uopWriteback_(\d+)_bits_(\w+)$', 'wb'),
        (r'io_toSplit_(threshold)$', 'threshold'),
        (r'io_toLsq_(\d+)_(valid)$', 'lsq'),
        (r'io_toLsq_(\d+)_bits_(\w+)$', 'lsq'),
        (r'io_feedback_(\d+)_(valid)$', 'fb'),
        (r'io_feedback_(\d+)_bits_(\w+)$', 'fb'),
    ]
    for pat, grp in pats:
        m = re.match(pat, name)
        if m:
            if len(m.groups()) == 1:
                return grp, None, m.group(1)
            return grp, int(m.group(1)), m.group(2)
    raise AssertionError(f'未分类端口 {name}')


def member_path(mem):
    """golden 成员后缀 -> struct 访问路径"""
    mem = re.sub(r'^uop_', 'uop.', mem)
    mem = re.sub(r'exceptionVec_(\d+)$', r'exceptionVec[\1]', mem)
    mem = re.sub(r'^feedback_(\d+)$', r'feedback[\1]', mem)
    return mem


def base_member(mem):
    """成员后缀 -> (struct 成员名, 宽度覆盖)；exceptionVec/feedback 收成向量"""
    if re.fullmatch(r'exceptionVec_\d+', mem):
        return 'exceptionVec', 24
    if re.fullmatch(r'feedback_\d+', mem):
        return 'feedback', 2
    return mem, None


class Union:
    """保持首次出现顺序的成员并集"""
    def __init__(self):
        self.items = []
        self.width = {}

    def add(self, name, w):
        if name not in self.width:
            self.items.append(name)
            self.width[name] = w
        else:
            assert self.width[name] == w, (name, self.width[name], w)


def build_structs():
    pipe29 = read_ports('NewPipelineConnectPipe_29')
    uop = Union()
    for _, w, n in pipe29:
        m = re.match(r'io_in_bits_uop_(\w+)$', n)
        if m:
            b, ow = base_member(m.group(1))
            uop.add(b, ow or w)
    groups = {g: Union() for g in ('redirect', 'enq', 'pipe', 'wb', 'lsq', 'fb')}
    for mod in VARIANTS:
        for d, w, n in read_ports(mod):
            if n in ('clock', 'reset'):
                continue
            g, _, mem = classify(n)
            if g not in groups:
                continue
            if g in ('enq', 'wb') and mem.startswith('uop_'):
                b, ow = base_member(mem[4:])
                uop.add(b, ow or w)
                continue
            b, ow = base_member(mem)
            groups[g].add(b, ow or w)
    for n, w in PIPE_EXTRA:
        groups['pipe'].add(n, w)
    for g in ('enq', 'wb'):
        groups[g].add('uop', None)
    return uop, groups, pipe29


def decl(name, w, typ=None):
    if typ:
        return f'    {typ:<20} {name};'
    t = 'logic' if w == 1 else f'logic [{w - 1}:0]'
    return f'    {t:<20} {name};'


def gen_structs(uop, groups):
    out = []
    def emit(tname, u, comment):
        out.append(f'  // {comment}')
        out.append('  typedef struct packed {')
        for n in u.items:
            out.append(decl(n, u.width[n], 'mb_uop_t' if n == 'uop' else None))
        out.append(f'  }} {tname};')
        out.append('')
    emit('mb_uop_t', uop, 'DynInst 在本单元进出的字段（入队请求 uop 与写回 uop 的并集）')
    emit('mb_redirect_t', groups['redirect'], 'redirect：重定向点 robIdx 与 level')
    emit('mb_enq_req_t', groups['enq'], 'fromSplit.req：VSplit 发来的一条 uop（MergeBufferReq）')
    emit('mb_pipe_t', groups['pipe'], 'fromPipeline：一个 flow 的写回（VecPipelineFeedbackIO）；'
         'sourceType/flushState 无端口，恒由 wrapper 补常量')
    emit('mb_wb_t', groups['wb'], 'uopWriteback：写回后端的 MemExuOutput')
    emit('mb_lsq_t', groups['lsq'], 'toLsq：FeedbackToLsqIO')
    emit('mb_fb_t', groups['fb'], 'feedback：给发射队列的 RSFeedback')
    return out[:-1]


def gen_deq_pipe(uop, groups, pipe29):
    out = ['      NewPipelineConnectPipe_29 VMergebufferPipelineConnect (']
    conns = []
    driven_uop, driven_exc, driven_top = set(), set(), set()
    for d, w, n in pipe29:
        if n in ('clock', 'reset'):
            conns.append((n, n))
        elif n == 'io_in_ready':
            conns.append((n, 'pipe_in_ready[d]'))
        elif n == 'io_in_valid':
            conns.append((n, 'pipe_in_valid[d]'))
        elif n == 'io_out_ready':
            conns.append((n, 'io_uopWriteback_ready[d]'))
        elif n == 'io_out_valid':
            conns.append((n, 'pipe_out_valid[d]'))
        elif n == 'io_rightOutFire':
            conns.append((n, 'io_uopWriteback_ready[d] && pipe_out_valid[d]'))
        elif n == 'io_isFlush':
            conns.append((n, 'isFlush'))
        else:
            m = re.match(r'io_(in|out)_bits_(\w+)$', n)
            assert m, n
            side, mem = m.groups()
            tgt = 'deq_bits[d]' if side == 'in' else 'io_uopWriteback[d]'
            conns.append((n, f'{tgt}.{member_path(mem)}'))
            if side == 'out':
                em = re.match(r'uop_exceptionVec_(\d+)$', mem)
                if em:
                    driven_exc.add(int(em.group(1)))
                elif mem.startswith('uop_'):
                    driven_uop.add(mem[4:])
                else:
                    driven_top.add(mem)
    wid = max(len(c[0]) for c in conns)
    for k, (p, s) in enumerate(conns):
        out.append(f'        .{p:<{wid}} ({s}){"," if k < len(conns) - 1 else ""}')
    out.append('      );')
    out.append('      // 流水缓冲不携带的写回字段：接常量（wrapper 也不读它们）')
    for b in range(24):
        if b not in driven_exc:
            out.append(f"      assign io_uopWriteback[d].uop.exceptionVec[{b}] = 1'b0;")
    for n in uop.items:
        if n != 'exceptionVec' and n not in driven_uop:
            out.append(f"      assign io_uopWriteback[d].uop.{n} = '0;")
    for n in groups['wb'].items:
        if n not in ('valid', 'uop') and n not in driven_top:
            out.append(f"      assign io_uopWriteback[d].{n} = '0;")
    return out


def uop_store_fields(uop):
    fields = [n for n in uop.items if n not in UOP_HAND]
    for mod in VARIANTS:
        have = golden_entry_fields(mod)
        miss = [f for f in fields if f'uop_{f}' not in have]
        assert not miss, f'{mod}: golden 没有 entries_0_uop_{miss}，不能按透传字段存'
        mine = {f'uop_{f}' for f in fields} | HAND_FIELDS[mod]
        extra_g = sorted(have - mine)
        extra_m = sorted(mine - have)
        assert not extra_g and not extra_m, (
            f'{mod}: 条目字段集合与 golden 不一致：golden 多 {extra_g}，本核多 {extra_m}')
    return fields


def gen_uop_store(uop):
    fields = uop_store_fields(uop)
    out = []
    for f in fields:
        w = uop.width[f]
        t = 'logic' if w == 1 else f'logic [{w - 1}:0]'
        out.append(f'  {t:<14} entries_uop_{f:<34} [MB_SIZE];')
    out.append('')
    out.append('  always_ff @(posedge clock) begin')
    out.append('    for (int e = 0; e < MB_SIZE; e++) begin')
    out.append('      for (int p = 0; p < ENQ_W; p++) begin')
    out.append('        if (enq_fire[p] && enq_idx[p] == MB_IDX_W\'(e)) begin')
    for f in fields:
        out.append(f'          entries_uop_{f + "[e]":<38} <= io_fromSplit_req[p].uop.{f};')
    out.append('        end')
    out.append('      end')
    out.append('    end')
    out.append('  end')
    out.append('')
    out.append('  always_comb begin')
    out.append('    for (int e = 0; e < MB_SIZE; e++) begin')
    out.append("      entries_uop[e] = '0;")
    for f in fields:
        out.append(f'      entries_uop[e].{f:<34} = entries_uop_{f}[e];')
    out.append('    end')
    out.append('  end')
    return out


def gen_wrapper(mod, uop, groups):
    v = VARIANTS[mod]
    ports = read_ports(mod)
    ties = TIES[mod]
    out = [f'module {mod}', '  import vmergebuffer_pkg::*;', '(']
    for k, (d, w, n) in enumerate(ports):
        t = f'{d:<6} logic' + ('' if w == 1 else f' [{w - 1}:0]')
        out.append(f'  {t:<26} {n}{"," if k < len(ports) - 1 else ""}')
    out.append(');')
    out.append('')
    E, P, D = v['enq'], v['pipe'], v['deq']
    out += [
        '  mb_redirect_t        redirect;',
        f'  mb_enq_req_t         enq_req          [{E}];',
        f'  logic                enq_ready        [{E}];',
        f'  logic                enq_resp_valid   [{E}];',
        f'  logic [3:0]          enq_resp_mBIndex [{E}];',
        f'  mb_pipe_t            pipe             [{P}];',
        f'  logic                wb_ready         [{D}];',
        f'  mb_wb_t              wb               [{D}];',
        '  logic                threshold;',
        f'  mb_lsq_t             lsq              [{D}];',
        f'  mb_fb_t              fb               [{D}];',
        '',
    ]
    ins, outs = [], []
    present = set()
    for d, w, n in ports:
        if n in ('clock', 'reset'):
            continue
        g, i, mem = classify(n)
        path = member_path(mem)
        idx = '' if i is None else f'[{i}]'
        if g in ('redirect', 'enq', 'pipe', 'wb_ready'):
            var = {'redirect': 'redirect', 'enq': 'enq_req', 'pipe': 'pipe'}.get(g)
            lhs = f'{var}{idx}.{path}' if var else f'wb_ready{idx}'
            if g in ('enq', 'pipe') and not mem.startswith('uop_'):
                present.add((g, base_member(mem)[0]))
            ins.append((lhs, n))
        else:
            if g in ('enq_ready', 'enq_resp_valid', 'enq_resp_mBIndex', 'threshold'):
                rhs = f'{g}{idx}'
            else:
                rhs = f'{g}{idx}.{path}'
            outs.append((n, rhs))
    for (g, mem) in ties:
        assert (g, mem) not in present, f'{mod}: TIES 里的 {g}.{mem} 在 golden 有端口，不许补常量'
    out.append('  // 输入：先整体清零（端口被 firtool 删掉、上游恒送 0 的字段就停在 0），再逐个接端口')
    out.append('  always_comb begin')
    out.append("    redirect = '0;")
    for i in range(E):
        out.append(f"    enq_req[{i}] = '0;")
    for i in range(P):
        out.append(f"    pipe[{i}] = '0;")
    wid = max(len(a) for a, _ in ins)
    for lhs, n in ins:
        out.append(f'    {lhs:<{wid}} = {n};')
    for (g, mem), val in ties.items():
        n = {'pipe': P, 'enq': E}[g]
        for i in range(n):
            out.append(f'    {g}[{i}].{mem} = {val};  // 无端口：上游恒送 {val}')
    out.append('  end')
    out.append('')
    out.append('  xs_VMergeBuffer_core #(')
    out.append(f"    .IS_VSTORE (1'b{v['is_vs']}),")
    out.append(f"    .ENQ_W     ({E}),")
    out.append(f"    .PIPE_W    ({P}),")
    out.append(f"    .DEQ_W     ({D}),")
    out.append(f"    .THRESHOLD ({v['thr']}),")
    out.append(f"    .EXC_SEL   ({v['exc']})")
    out.append('  ) u_core (')
    conns = [('clock', 'clock'), ('reset', 'reset'), ('io_redirect', 'redirect'),
             ('io_fromSplit_req', 'enq_req'), ('io_fromSplit_req_ready', 'enq_ready'),
             ('io_fromSplit_resp_valid', 'enq_resp_valid'), ('io_fromSplit_resp_mBIndex', 'enq_resp_mBIndex'),
             ('io_fromPipeline', 'pipe'), ('io_uopWriteback_ready', 'wb_ready'),
             ('io_uopWriteback', 'wb'), ('io_toSplit_threshold', 'threshold'), ('io_toLsq', 'lsq'),
             ('io_feedback', 'fb')]
    for k, (p, s) in enumerate(conns):
        out.append(f'    .{p:<25} ({s}){"," if k < len(conns) - 1 else ""}')
    out.append('  );')
    out.append('')
    out.append('  // 输出')
    wid = max(len(n) for n, _ in outs)
    for n, rhs in outs:
        out.append(f'  assign {n:<{wid}} = {rhs};')
    out.append('')
    out.append('endmodule')
    return out


# ---------------------------------------------------------------------------
# tb
# ---------------------------------------------------------------------------
def rnd_expr(w):
    if w <= 32:
        return f"{w}'($urandom)"
    n = (w + 31) // 32
    return f"{w}'({{" + ', '.join(['$urandom'] * n) + '})'


def tb_stim(mod, ports):
    """每个输入端口的随机激励（phase 3 = 随机阶段）"""
    v = VARIANTS[mod]
    s = v['short']
    lines = []
    for d, w, n in ports:
        if d != 'input' or n in ('clock', 'reset'):
            continue
        g, i, mem = classify(n)
        sig = f'{s}_{n}'
        e = rnd_expr(w)
        if n == 'io_redirect_valid':
            e = "($urandom % 100) < 4"
        elif n == 'io_redirect_bits_robIdx_value':
            e = "8'(96 + $urandom % 16)"
        elif n == 'io_redirect_bits_robIdx_flag':
            e = "1'b0"
        elif g == 'enq' and mem == 'valid':
            e = "($urandom % 100) < 50"
        elif g == 'enq' and mem == 'uop_robIdx_value':
            e = "8'(96 + $urandom % 16)"
        elif g == 'enq' and mem == 'uop_robIdx_flag':
            e = "($urandom % 100) < 5"
        elif g == 'enq' and mem == 'flowNum':
            e = "(($urandom % 100) < 10) ? 5'($urandom) : 5'(1 + $urandom % 4)"
        elif g == 'enq' and mem == 'vlmax':
            e = "8'(1 << ($urandom % 8))"
        elif g == 'enq' and mem == 'fof':
            e = "($urandom % 100) < 25"
        elif g == 'enq' and mem == 'uop_fuOpType':
            e = "(($urandom % 100) < 40) ? {2'b01, 2'b00, 5'($urandom)} : 9'($urandom)"
        elif g == 'pipe' and mem == 'valid':
            e = "($urandom % 100) < 60"
        elif g == 'pipe' and mem == 'mBIndex':
            if i == 0:
                e = f"pick_idx({s}_alloc)"
            else:
                e = f"(($urandom % 100) < 35) ? {s}_io_fromPipeline_0_bits_mBIndex : pick_idx({s}_alloc)"
        elif g == 'pipe' and mem == 'hasException':
            e = "($urandom % 100) < 15"
        elif g == 'pipe' and mem.startswith('exceptionVec_'):
            e = "($urandom % 100) < 8"
        elif g == 'pipe' and mem == 'trigger':
            e = "pick_trigger()"
        elif g == 'pipe' and mem == 'hit':
            e = "($urandom % 100) < 80"
        elif g == 'pipe' and mem == 'elemIdx':
            e = "(($urandom % 100) < 80) ? 8'($urandom % 32) : 8'($urandom)"
        elif g == 'pipe' and mem == 'elemIdxInsideVd':
            e = "(($urandom % 100) < 30) ? 8'd0 : 8'($urandom % 16)"
        elif g == 'pipe' and mem == 'mask':
            e = "(($urandom % 100) < 20) ? 16'hFFFF : 16'($urandom) & 16'($urandom)"
        elif g == 'wb_ready':
            e = "($urandom % 100) < 70"
        lines.append(f'      {sig} = {e};')
    return lines


def tb_warm(mod, ports, phase):
    """phase 0：只入队（固定 robIdx=100、fof=0、flowNum=31，把 16 个条目占满）；
    phase 1：只有流水口 0 写回，逐条目带异常（把只在异常时才写的 gpaddr 等字段写一遍）；
    phase 2：redirect robIdx=50，把全部条目冲掉。"""
    v = VARIANTS[mod]
    s = v['short']
    lines = []
    for d, w, n in ports:
        if d != 'input' or n in ('clock', 'reset'):
            continue
        g, i, mem = classify(n)
        sig = f'{s}_{n}'
        e = rnd_expr(w)
        if g == 'redirect':
            e = {'valid': "1'b1" if phase == 2 else "1'b0", 'robIdx_flag': "1'b0",
                 'robIdx_value': "8'd50", 'level': "1'b0"}[mem]
        elif g == 'enq' and mem == 'valid':
            e = "1'b1" if phase == 0 else "1'b0"
        elif g == 'enq' and mem == 'uop_robIdx_value':
            e = "8'd100"
        elif g == 'enq' and mem == 'uop_robIdx_flag':
            e = "1'b0"
        elif g == 'enq' and mem == 'fof':
            e = "1'b0"
        elif g == 'enq' and mem == 'flowNum':
            e = "5'd31"
        elif g == 'pipe' and mem == 'valid':
            e = "1'b1" if (phase == 1 and i == 0) else "1'b0"
        elif g == 'pipe' and mem == 'mBIndex':
            e = "4'(cycle)"
        elif g == 'pipe' and mem == 'hasException':
            e = "1'b1"
        elif g == 'pipe' and mem == 'trigger':
            e = "4'd15"
        elif g == 'pipe' and mem == 'elemIdx':
            e = "8'd0"
        elif g == 'wb_ready':
            e = "1'b1"
        lines.append(f'      {sig} = {e};')
    return lines


def tb_compare(mod, ports):
    s = VARIANTS[mod]['short']
    lines = []
    for d, w, n in ports:
        if d != 'output':
            continue
        g, i, mem = classify(n)
        gate = '1\'b1'
        if g in ('wb', 'lsq', 'fb') and mem != 'valid':
            base = {'wb': 'io_uopWriteback', 'lsq': 'io_toLsq', 'fb': 'io_feedback'}[g]
            gate = f'{s}_g_{base}_{i}_valid'
        lines.append(f'    if ({gate}) chk("{mod}.{n}", {s}_g_{n} !== {s}_i_{n});')
    # 覆盖计数（只读 golden 侧）：确认激励真的走到了出队 / 通知 LSQ / 反馈 / 部分重放 / 异常冲刷
    for d_ in range(VARIANTS[mod]['deq']):
        lines.append(f'    cov_{s}[0] += {s}_g_io_uopWriteback_{d_}_valid;')
        lines.append(f'    cov_{s}[1] += {s}_g_io_toLsq_{d_}_valid;')
        lines.append(f'    cov_{s}[2] += {s}_g_io_feedback_{d_}_valid;')
        lines.append(f'    cov_{s}[3] += {s}_g_io_feedback_{d_}_valid & {s}_g_io_feedback_{d_}_bits_isVecPartReplay;')
        lines.append(f'    cov_{s}[4] += {s}_g_io_toLsq_{d_}_valid & {s}_g_io_toLsq_{d_}_bits_feedback_0;')
    return lines


def gen_tb():
    out = [
        f'// tb.sv —— VMergeBuffer 家族双例化 UT（由 {TAG} 生成，勿手改）',
        '//',
        '// 两个变体各一对：golden VLMergeBufferImp / VSMergeBufferImp 与重写件 *_xs（rtl/memblock，',
        '// derive_ut_impl.py 改名）。同激励并跑，每拍（下降沿）逐位比较全部输出端口；',
        '// uopWriteback / toLsq / feedback 的 bits 只在对应 valid（取 golden 侧）为 1 时比较',
        '// —— 它们在 valid=0 时取自没写过的条目/不复位的寄存器，内容没有定义。',
        '//',
        '// 时间线：复位 5 拍 -> 暖机（入队占满 16 条目 / 逐条目带异常写回 / redirect 全冲）-> 随机。',
        '// 暖机的目的：条目里 gpaddr / vaNeedExt / isForVSnonLeafPTE 只在异常写回时才写，',
        '// +vcs+initreg+random 下两侧初值不同，先全部写一遍才能在出队时逐位比较。',
        '// 随机阶段的激励偏置：写回口的 mBIndex 多数取 golden 当前已分配的条目，多口常撞同一条目；',
        '// flowNum 多为 1..4（条目能在几拍内完成出队）；redirect 的 robIdx 与请求落在同一小窗口',
        '// （约一半请求/条目会被冲）；fuOpType 约四成是 unit-stride（走字节合并路径）。',
        '`timescale 1ns/1ps',
        'module tb;',
        '  logic clock = 1\'b0;',
        '  logic reset = 1\'b1;',
        '  always #5 clock = ~clock;',
        '',
        '  int ncycles = 200000;',
        '  int cycle   = 0;',
        '  longint checks = 0;',
        '  int errors = 0;',
        '',
        '  function automatic void chk(input string name, input logic bad);',
        '    checks++;',
        '    if (bad) begin',
        '      errors++;',
        '      if (errors <= 20) $display("[%0d] MISMATCH %s", cycle, name);',
        '    end',
        '  endfunction',
        '',
        '  function automatic logic [3:0] pick_idx(input logic [15:0] alloc);',
        '    logic [3:0] c;',
        '    if (($urandom % 100) < 80 && alloc != 16\'h0) begin',
        '      do c = 4\'($urandom); while (!alloc[c]);',
        '      return c;',
        '    end',
        '    return 4\'($urandom);',
        '  endfunction',
        '',
        '  function automatic logic [3:0] pick_trigger();',
        '    int r;',
        '    r = $urandom % 100;',
        '    if (r < 70) return 4\'d15;',
        '    if (r < 80) return 4\'d0;',
        '    if (r < 90) return 4\'d1;',
        '    return 4\'($urandom);',
        '  endfunction',
        '',
    ]
    for mod, v in VARIANTS.items():
        s = v['short']
        ports = read_ports(mod)
        out.append(f'  // ---------------- {mod} ----------------')
        for d, w, n in ports:
            if n in ('clock', 'reset'):
                continue
            t = 'logic' + ('' if w == 1 else f' [{w - 1}:0]')
            if d == 'input':
                out.append(f'  {t:<16} {s}_{n};')
            else:
                out.append(f'  {t:<16} {s}_g_{n};')
                out.append(f'  {t:<16} {s}_i_{n};')
        out.append(f'  longint          cov_{s} [5];  // 写回 / toLsq / 反馈 / 部分重放 / 带异常出队')
        out.append(f'  logic [15:0]     {s}_alloc;')
        out.append(f'  assign {s}_alloc = {{' + ', '.join(
            f'u_{s}_g.allocated_{e}' for e in range(15, -1, -1)) + '};')
        for side, modname in (('g', mod), ('i', f'{mod}_xs')):
            out.append(f'  {modname} u_{s}_{side} (')
            conns = [('clock', 'clock'), ('reset', 'reset')]
            for d, w, n in ports:
                if n in ('clock', 'reset'):
                    continue
                conns.append((n, f'{s}_{n}' if d == 'input' else f'{s}_{side}_{n}'))
            wid = max(len(c[0]) for c in conns)
            for k, (p, sg) in enumerate(conns):
                out.append(f'    .{p:<{wid}} ({sg}){"," if k < len(conns) - 1 else ""}')
            out.append('  );')
        out.append('')
        out.append(f'  task automatic drive_{s}(input int phase);')
        out.append('    if (phase == 3) begin')
        out += tb_stim(mod, ports)
        for ph in (0, 1, 2):
            out.append(f'    end else if (phase == {ph}) begin')
            out += tb_warm(mod, ports, ph)
        out.append('    end')
        out.append('  endtask')
        out.append('')
        out.append(f'  task automatic compare_{s}();')
        out += tb_compare(mod, ports)
        out.append('  endtask')
        out.append('')
    out += [
        '  initial begin',
        '    int phase;',
        '    if ($value$plusargs("ncycles=%d", ncycles)) ;',
        '    phase = 0;',
        '    drive_vl(0);',
        '    drive_vs(0);',
        '    repeat (5) @(posedge clock);',
        '    #1 reset = 1\'b0;',
        '    for (cycle = 0; cycle < ncycles; cycle++) begin',
        '      phase = (cycle < 40) ? 0 : (cycle < 80) ? 1 : (cycle < 82) ? 2 : 3;',
        '      drive_vl(phase);',
        '      drive_vs(phase);',
        '      @(negedge clock);',
        '      if (cycle >= 2) begin',
        '        compare_vl();',
        '        compare_vs();',
        '      end',
        '      @(posedge clock);',
        '      #1;',
        '    end',
        '    $display("coverage vl: wb=%0d toLsq=%0d feedback=%0d partReplay=%0d excFlush=%0d",',
        '             cov_vl[0], cov_vl[1], cov_vl[2], cov_vl[3], cov_vl[4]);',
        '    $display("coverage vs: wb=%0d toLsq=%0d feedback=%0d partReplay=%0d excFlush=%0d",',
        '             cov_vs[0], cov_vs[1], cov_vs[2], cov_vs[3], cov_vs[4]);',
        '    $display("checks=%0d errors=%0d", checks, errors);',
        '    if (errors == 0) $display("TEST PASSED");',
        '    else $display("TEST FAILED");',
        '    $finish;',
        '  end',
        'endmodule',
    ]
    return out


# ---------------------------------------------------------------------------
# FM 匹配前钉点：写回口流水缓冲（NewPipelineConnectPipe_29）的 payload 逐位双射
# ---------------------------------------------------------------------------
PIPE29_MAP = REPO / 'verif' / 'ut' / 'NewPipelineConnectPipe_29_34_35' / 'fm_map' / 'NewPipelineConnectPipe_29.txt'
PINS_PRE = REPO / 'verif' / 'ut' / 'VMergeBuffer' / 'fm_pins_pre.tcl'


def gen_pins_pre():
    rows = []
    for ln in PIPE29_MAP.read_text().splitlines():
        m = re.match(r'^(\S+)\s+(\d+)\s+(\d+)$', ln)
        if m:
            rows.append((m.group(1), int(m.group(2)), int(m.group(3))))
    total = sum(w for _, _, w in rows)
    # 与 golden 对账：字段名 = golden 的 data_<suf> 寄存器，位宽逐个相等，总宽 = 1023
    gold = dict((n, int(w) + 1 if w else 1) for w, n in re.findall(
        r'^\s*reg\s+(?:\[(\d+):0\]\s+)?data_(\w+);',
        (GOLDEN / 'NewPipelineConnectPipe_29.sv').read_text(), re.M))
    assert gold == {s: w for s, _, w in rows}, 'fm_map 与 golden NewPipelineConnectPipe_29 的 data_* 寄存器不一致'
    ndeq = {m: v['deq'] for m, v in VARIANTS.items()}
    out = [
        f'# VMergeBuffer FM「匹配前」钉点 —— 由 {TAG} 生成，勿手改。',
        '# 只消命名鸿沟：不约束 ref、不放宽 appvar、不扩黑盒、不 dont_verify。',
        '# ---------------------------------------------------------------------------',
        '# 对象：每个出队口的写回流水缓冲 NewPipelineConnectPipe_29 的 payload 寄存器。',
        '# golden 每字段一个寄存器 data_<字段>_reg[b]，重写件（rtl/uncore/NewPipelineConnectPipe_29.sv）',
        '# 把整个 payload 存在一个扁平的 u_core/data_reg。★实测（2026-09-28 VSMergeBufferImp 首次试跑）★：',
        '# 不钉的话 FM 按"末段名"把 data_data_reg[0] 配到 data_reg[6] 这类错位的对子（Name(Last)），',
        '# 整片 payload 错位 —— 与该模块单独签核时遇到的是同一个坑，这里沿用它的字段映射',
        '# verif/ut/NewPipelineConnectPipe_29_34_35/fm_map/NewPipelineConnectPipe_29.txt',
        '# （<字段> <起始位> <宽度>，生成时已与 golden 的 data_* 寄存器逐个对过名字与位宽）。',
        '# 路径：ref  r:/WORK/<top>/VMergebufferPipelineConnect<d>/data_<字段>_reg[b]（1 位字段无 [b]）',
        '#       impl i:/WORK/<top>/u_core/g_deq_pipe[<d>].VMergebufferPipelineConnect/u_core/data_reg[起始+b]',
        f'# fail-closed：每次 set_user_match 必须返回 1；配对数必须等于 {total} × 出队口数',
        '# （VLMergeBufferImp 2 口 = %d，VSMergeBufferImp 1 口 = %d）。' % (2 * total, total),
        '# 跑在 sidecar 的 safe child interp 里：只用 set_user_match / puts / error。',
        '# ---------------------------------------------------------------------------',
        'set _mb_pipe29_fields {',
    ]
    for s, lo, w in rows:
        out.append(f'    {{{s} {lo} {w}}}')
    out += [
        '}',
        '',
        'proc _mb_prepin {top fields} {',
        '    switch -exact -- $top {',
        f'        VLMergeBufferImp {{ set ndeq {ndeq["VLMergeBufferImp"]} }}',
        f'        VSMergeBufferImp {{ set ndeq {ndeq["VSMergeBufferImp"]} }}',
        '        default { error "MB_PREPIN_BAD_TOP=$top" }',
        '    }',
        f'    set expect [expr {{{total} * $ndeq}}]',
        '    puts "MB_PREPIN_BEGIN top=$top expect=$expect"',
        '    set n 0',
        '    for {set d 0} {$d < $ndeq} {incr d} {',
        '        foreach f $fields {',
        '            lassign $f suf lo w',
        '            for {set b 0} {$b < $w} {incr b} {',
        '                if {$w == 1} {',
        '                    set rpath "r:/WORK/$top/VMergebufferPipelineConnect$d/data_${suf}_reg"',
        '                } else {',
        '                    set rpath "r:/WORK/$top/VMergebufferPipelineConnect$d/data_${suf}_reg\[$b\]"',
        '                }',
        '                set ipath "i:/WORK/$top/u_core/g_deq_pipe\[$d\].VMergebufferPipelineConnect/u_core/data_reg\[[expr {$lo + $b}]\]"',
        '                if {![set_user_match $rpath $ipath]} {',
        '                    puts "MB_PREPIN_FAIL: set_user_match returned 0 for $rpath <-> $ipath"',
        '                    error "MB_PREPIN_MISS=$rpath"',
        '                }',
        '                incr n',
        '            }',
        '        }',
        '    }',
        '    puts "MB_PREPIN_END top=$top n=$n expect=$expect"',
        '    if {$n != $expect} { error "MB_PREPIN_COUNT=$n" }',
        '}',
        '',
        '_mb_prepin $top $_mb_pipe29_fields',
    ]
    return out


# ---------------------------------------------------------------------------
def replace_region(text, tag, lines, path):
    pat = re.compile(r'(^[ \t]*// BEGIN GENERATED\(' + re.escape(tag) + r'\)[^\n]*\n)(.*?)(^[ \t]*// END GENERATED)',
                     re.S | re.M)
    m = pat.search(text)
    assert m, f'{path}: 找不到 GENERATED({tag}) 区'
    body = '\n'.join(lines) + '\n' if lines else ''
    return text[:m.start(2)] + body + text[m.start(3):]


def main():
    check = '--check' in sys.argv[1:]
    uop, groups, pipe29 = build_structs()
    outputs = {}
    t = RTL_VL.read_text()
    t = replace_region(t, 'structs', gen_structs(uop, groups), RTL_VL)
    t = replace_region(t, 'deq_pipe', gen_deq_pipe(uop, groups, pipe29), RTL_VL)
    t = replace_region(t, 'uop_store', gen_uop_store(uop), RTL_VL)
    t = replace_region(t, 'wrapper_VLMergeBufferImp', gen_wrapper('VLMergeBufferImp', uop, groups), RTL_VL)
    outputs[RTL_VL] = t
    t = RTL_VS.read_text()
    t = replace_region(t, 'wrapper_VSMergeBufferImp', gen_wrapper('VSMergeBufferImp', uop, groups), RTL_VS)
    outputs[RTL_VS] = t
    outputs[TB] = '\n'.join(gen_tb()) + '\n'
    outputs[PINS_PRE] = '\n'.join(gen_pins_pre()) + '\n'
    bad = 0
    for p, txt in outputs.items():
        old = p.read_text() if p.exists() else None
        if old == txt:
            continue
        if check:
            print(f'[gen_vmergebuf] 过期: {p.relative_to(REPO)}')
            bad += 1
        else:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(txt)
            print(f'[gen_vmergebuf] 写入 {p.relative_to(REPO)}')
    if check:
        print('[gen_vmergebuf] --check ' + ('FAIL' if bad else 'OK'))
        return 1 if bad else 0
    return 0


if __name__ == '__main__':
    sys.exit(main())

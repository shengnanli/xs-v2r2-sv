#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_vsplit.py —— 向量访存拆分单元（VSplit 家族，7 个 golden 模块）的机械派生区生成器。

覆盖的目标与产物（都是 `// BEGIN GENERATED(<tag>)` 标记的原地替换，手写区不碰）：
  rtl/memblock/vlsu_pkg.sv            types：uop_t / vls_t / ... 接口 struct（四个模块端口表与寄存器表的并集）
  rtl/memblock/VLSplitPipelineImp.sv    core_ports（xs_VSplitPipeline_core 端口表）+ wrapper_VLSplitPipelineImp
  rtl/memblock/VSSplitPipelineImp.sv    wrapper_VSSplitPipelineImp
  rtl/memblock/VLSplitBufferImp.sv      core_ports（xs_VSplitBuffer_core 端口表）+ wrapper_VLSplitBufferImp
  rtl/memblock/VSSplitBufferImp.sv      wrapper_VSSplitBufferImp
  rtl/memblock/skidBufferConnect.sv     wrapper：逐字段的 "暂存寄存器 + 二选一"（控制在手写的 xs_SkidBuffer_core）
  rtl/memblock/VLSplitImp.sv            wrapper_VLSplitImp：三个子模块例化与连线（连接关系照 golden 的例化块）
  rtl/memblock/VSSplitImp.sv            wrapper_VSSplitImp
  verif/ut/<7 个目标>/tb.sv              双例化 tb（激励整形与覆盖判据是本文件 TB_* 里的手写部分）

★为什么要机械生成★ 这一族每个模块两三百个扁平端口，绝大部分是同一份 uop / VLSBundle 在
流水 → skid → 缓冲之间传递。golden 每个模块、每个变体留下哪些字段由 firtool 的 DCE 决定
（CONVENTIONS：字段集合必须从 golden 现数），手抄几百行拆装线，漏一根 UT 未必抓得住。
核（译码 / 掩码 / 握手 / 计数 / 状态机）全部手写；这里只产出"扁平名 ↔ struct 成员"的拆装、
整包寄存器（golden 展平名，FM 按名配对）、装配壳的例化连线。

生成时的机械核对（fail-closed）：
  1. 每个端口恰归一个接口组或标量口；同名成员在所有模块 / 变体里位宽一致；
  2. 每个 golden 寄存器 = 某个生成的寄存器组成员，或核手写区里同名的 `<=` 目标（逐名，多 / 少都红）；
  3. skid 缓冲：dataBuffer_<f> 与 io_out_bits_<f> 一一对应，io_in_bits_<f> ⊆ 它们；
  4. 装配壳：golden 例化块的每个 pin 只能接 clock/reset、本层同名端口、别的实例的输出线
     （唯一例外是 skid 的 io_flush，接手写胶水核的输出）；本层输出都有驱动；
  5. 产物代码区无 firtool 展平中间名。

用法：
    python3 scripts/gen_vsplit.py            # 生成
    python3 scripts/gen_vsplit.py --check    # 产物与生成器不一致则非零退出
"""
import collections
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import xs_structgen as X  # noqa: E402

REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = REPO / 'rtl' / 'memblock'
UT = REPO / 'verif' / 'ut'
TAG = 'scripts/gen_vsplit.py'

VARIANTS = (('VL', 0), ('VS', 1))
G = {m: X.Golden(m) for m in (
    'VLSplitPipelineImp', 'VSSplitPipelineImp', 'VLSplitBufferImp', 'VSSplitBufferImp',
    'skidBufferConnect', 'VLSplitImp', 'VSSplitImp')}

# ---------------------------------------------------------------------------
# 1. 类型空间（vlsu_pkg）
# ---------------------------------------------------------------------------
TS = X.TypeSpace(
    collections.OrderedDict([
        ('uop_t',       '微操作信息（DynInst 在拆分流水 / 拆分缓冲各接口与寄存器里留下的字段并集）'),
        ('split_in_t',  '发射队列来的向量访存 uop（src_0=基址 rs1，src_1=stride / index 向量，src_2=store 数据，'
                        'src_3=v0 mask，src_4=vl）'),
        ('vls_t',       '一条"读懂了的"向量访存 uop（VLSBundle）：拆分流水 s1 → skid → 拆分缓冲'),
        ('merge_req_t', '向合并缓冲申请条目（FromSplitIO.req）'),
        ('vec_pipe_t',  '发给标量访存流水的一个访问（VecPipeBundle）'),
        ('vstd_t',      '送 store queue 的元素数据（只有 store）'),
    ]),
    {t: [('uop_', 'uop', 'uop_t')] for t in ('split_in_t', 'vls_t', 'merge_req_t', 'vec_pipe_t', 'vstd_t')})

PIPE_PORT_GROUPS = [
    ('io_in_bits_',                'split_in_t',  'in'),
    ('io_toMergeBuffer_req_bits_', 'merge_req_t', 'toMergeBuffer_req'),
    ('io_out_bits_',               'vls_t',       'out'),
]
PIPE_REG_GROUPS = [('s1_in_r_', 'vls_t', 's1_in', 's0_fire', 's0_out')]
PIPE_BRIDGE = [('output', 'vls_t', 's0_out'), ('output', 'logic', 's0_fire'), ('input', 'vls_t', 's1_in')]

BUF_PORT_GROUPS = [
    ('io_in_bits_',   'vls_t',      'in'),
    ('io_out_bits_',  'vec_pipe_t', 'out'),
    ('io_vstd_bits_', 'vstd_t',     'vstd'),
]
BUF_REG_GROUPS = [('uopq_', 'vls_t', 'uopq', 'doEnqueue', 'in')]
BUF_BRIDGE = [('output', 'logic', 'doEnqueue'), ('input', 'vls_t', 'uopq')]
# golden 把 uopq.usLowBitsAddr 这个寄存器起名叫 regOffset（Chisel 里 `val regOffset = ...` 的名字被 firtool 采用）
BUF_REG_ALIAS = {'regOffset': 'usLowBitsAddr'}

FAM = {}
for tag, _ in VARIANTS:
    pm, bm = tag + 'SplitPipelineImp', tag + 'SplitBufferImp'
    FAM[pm] = dict(cports=X.classify_ports(G[pm], PIPE_PORT_GROUPS, TS),
                   cregs=X.classify_regs(G[pm], PIPE_REG_GROUPS, TS))
    FAM[bm] = dict(cports=X.classify_ports(G[bm], BUF_PORT_GROUPS, TS),
                   cregs=X.classify_regs(G[bm], BUF_REG_GROUPS, TS))
    for rn, field in BUF_REG_ALIAS.items():
        if rn not in G[bm].regs:
            X.die('%s: 找不到别名寄存器 %s' % (bm, rn))
        TS.resolve('vls_t', field, G[bm].regs[rn], True)
        FAM[bm]['cregs']['uopq_'].append((rn, G[bm].regs[rn], field))

PIPE_PLIST = X.core_port_list([FAM['VLSplitPipelineImp']['cports'], FAM['VSSplitPipelineImp']['cports']], PIPE_BRIDGE)
BUF_PLIST = X.core_port_list([FAM['VLSplitBufferImp']['cports'], FAM['VSSplitBufferImp']['cports']], BUF_BRIDGE)


def family_wrapper(mod, core, is_vstore, reg_groups, plist, bridge, doc):
    g = G[mod]
    f = FAM[mod]
    out = ['module %s' % mod, '  import vlsu_pkg::*;', '(']
    out += g.port_text.split('\n')
    out += [');', '']
    out += X.emit_group_glue(TS, f['cports'])
    decl = collections.OrderedDict()
    for d, t, name in bridge:
        decl.setdefault(t, []).append(name)
    out.append('  // ---- 核与寄存器之间的桥 ----')
    for t, names in decl.items():
        out.append('  %-14s %s;' % (t, ', '.join(names)))
    out.append('')
    for prefix, typ, sig, en, src in reg_groups:
        out += X.emit_reg_group(TS, f['cregs'][prefix], typ, sig, en, src, doc)
        out.append('')
    out += X.emit_core_inst(core, '.IS_VSTORE(1\'b%d)' % is_vstore, plist, f['cports'],
                            [name for _, _, name in bridge])
    out += ['', 'endmodule']
    return out


def check_family_regs(mod, core_text, core_name):
    """golden 寄存器全集 == wrapper 里生成的寄存器组 ∪ 核手写区的 `<=` 目标（按变体过滤 generate 分支不可行，
    所以核一侧取"两个变体的并集"，逐变体要求：golden - 生成 ⊆ 核，且 核 - 两变体 golden 并集 = ∅）。"""
    g = G[mod]
    gen = {n for lst in FAM[mod]['cregs'].values() for n, _, _ in lst}
    code = X.strip_comments(core_text)
    core = re.search(r'module %s\b(.*?)\nendmodule' % core_name, code, re.S)
    if not core:
        return ['找不到 %s' % core_name], set(), set()
    hand = X.nb_assigned(core.group(1))
    want = set(g.regs) - gen
    return ['%s: golden 寄存器 %s 在核手写区没有同名寄存器' % (mod, n) for n in sorted(want - hand)], hand, want


# ---------------------------------------------------------------------------
# 2. skid 缓冲
# ---------------------------------------------------------------------------
def skid_wrapper():
    g = G['skidBufferConnect']
    ins = collections.OrderedDict((n[len('io_in_bits_'):], w) for d, w, n in g.ports if n.startswith('io_in_bits_'))
    outs = collections.OrderedDict((n[len('io_out_bits_'):], w) for d, w, n in g.ports if n.startswith('io_out_bits_'))
    regs = collections.OrderedDict((n[len('dataBuffer_'):], w) for n, w in g.regs.items() if n.startswith('dataBuffer_'))
    if set(g.regs) - {'dataBuffer_' + f for f in regs} != {'state'}:
        X.die('skidBufferConnect: 寄存器表里有预期之外的名字')
    if list(regs.items()) != list(outs.items()):
        X.die('skidBufferConnect: dataBuffer_* 与 io_out_bits_* 不是逐个同名同宽同序')
    for f, w in ins.items():
        if regs.get(f) != w:
            X.die('skidBufferConnect: 输入字段 %s 没有同宽的暂存寄存器' % f)
    scalars = {n for d, w, n in g.ports} - {'io_in_bits_' + f for f in ins} - {'io_out_bits_' + f for f in outs}
    if scalars != {'clock', 'reset', 'io_in_ready', 'io_in_valid', 'io_flush', 'io_out_ready', 'io_out_valid'}:
        X.die('skidBufferConnect: 握手端口与预期不符 %r' % sorted(scalars))
    out = ['module skidBufferConnect', '(']
    out += g.port_text.split('\n')
    out += [');', '',
            '  logic capture;      // 这一拍把输入暂存进 dataBuffer',
            '  logic use_buffer;   // 输出取 dataBuffer（否则直通输入）',
            '',
            '  xs_SkidBuffer_core u_core (',
            '    .clock      (clock),',
            '    .reset      (reset),',
            '    .in_valid   (io_in_valid),',
            '    .in_ready   (io_in_ready),',
            '    .flush      (io_flush),',
            '    .out_ready  (io_out_ready),',
            '    .out_valid  (io_out_valid),',
            '    .capture    (capture),',
            '    .use_buffer (use_buffer)',
            '  );',
            '',
            '  // ---- 暂存寄存器：%d 个字段（golden 的字段集合）；其中 %d 个上游有驱动，'
            '其余 %d 个上游恒 0（端口被消掉），暂存的也是 0 ----' % (len(regs), len(ins), len(regs) - len(ins))]
    for f, w in regs.items():
        out.append('  %-14s dataBuffer_%s;' % (X.wdecl(w), f))
    out.append('  always_ff @(posedge clock) begin')
    out.append('    if (capture) begin')
    for f, w in regs.items():
        out.append('      dataBuffer_%s <= %s;' % (f, ('io_in_bits_' + f) if f in ins else "'0"))
    out.append('    end')
    out.append('  end')
    out.append('')
    out.append('  // ---- 输出：skid 状态取暂存值，否则直通（上游恒 0 的字段直通值就是 0）----')
    for f, w in outs.items():
        out.append('  assign io_out_bits_%s = use_buffer ? dataBuffer_%s : %s;'
                   % (f, f, ('io_in_bits_' + f) if f in ins else "'0"))
    out += ['', 'endmodule']
    return out


# ---------------------------------------------------------------------------
# 3. 装配壳
# ---------------------------------------------------------------------------
SHELL_CORE_PINS = [   # 胶水核端口 → 壳里的信号
    ('redirect_valid',             'io_redirect_valid'),
    ('redirect_bits_robIdx_flag',  'io_redirect_bits_robIdx_flag'),
    ('redirect_bits_robIdx_value', 'io_redirect_bits_robIdx_value'),
    ('redirect_bits_level',        'io_redirect_bits_level'),
    ('pipeline_out_valid',         'splitPipeline_io_out_valid'),
    ('pipeline_out_robIdx_flag',   'splitPipeline_io_out_bits_uop_robIdx_flag'),
    ('pipeline_out_robIdx_value',  'splitPipeline_io_out_bits_uop_robIdx_value'),
    ('skid_in_ready',              'VSSplitSkidBuffer_io_in_ready'),
    ('skid_out_robIdx_flag',       'VSSplitSkidBuffer_io_out_bits_uop_robIdx_flag'),
    ('skid_out_robIdx_value',      'VSSplitSkidBuffer_io_out_bits_uop_robIdx_value'),
    ('skid_flush',                 'skid_flush'),
]


def shell_wrapper(mod):
    g = G[mod]
    insts = X.golden_instances(mod)
    if [i[1] for i in insts] != ['splitPipeline', 'splitBuffer', 'VSSplitSkidBuffer']:
        X.die('%s: 例化与预期不符' % mod)
    child = {inst: X.Golden(cm) for cm, inst, _ in insts}
    wires = collections.OrderedDict()   # 线名 → 位宽（子模块输出）
    driven = set()
    body = []
    for cm, inst, pins in insts:
        cg = child[inst]
        if [p for p, _ in pins] != [n for _, _, n in cg.ports]:
            X.die('%s.%s: pin 表与 %s 的端口表不一致' % (mod, inst, cm))
        conns = []
        for pin, expr in pins:
            pdir, pw = cg.pd[pin], cg.pw[pin]
            own = '%s_%s' % (inst, pin)
            if expr == '/* unused */':
                if pdir != 'output':
                    X.die('%s.%s.%s: 输入 pin 悬空' % (mod, inst, pin))
                conns.append((pin, ''))
            elif inst == 'VSSplitSkidBuffer' and pin == 'io_flush':
                conns.append((pin, 'skid_flush'))
            elif expr in ('clock', 'reset'):
                conns.append((pin, expr))
            elif expr.startswith('io_'):
                if g.pw.get(expr) != pw:
                    X.die('%s.%s.%s: 接的 %s 不是本层同宽端口' % (mod, inst, pin, expr))
                if pdir == 'output':
                    driven.add(expr)
                conns.append((pin, expr))
            elif re.fullmatch(r'_\w+', expr):
                net = expr[1:]
                if pdir == 'output':
                    if net != own:
                        X.die('%s.%s.%s: 输出线名 %s 不是 %s' % (mod, inst, pin, net, own))
                    wires[net] = pw
                conns.append((pin, net))
            else:
                X.die('%s.%s.%s: 不认识的连接 %r' % (mod, inst, pin, expr))
        body.append((cm, inst, conns))
    # 输入 pin 引用的线必须是某个实例的输出线且同宽
    for cm, inst, conns in body:
        cg = child[inst]
        for pin, net in conns:
            if cg.pd[pin] == 'input' and net not in ('clock', 'reset', 'skid_flush') and not net.startswith('io_'):
                if wires.get(net) != cg.pw[pin]:
                    X.die('%s.%s.%s: 接的线 %s 没有同宽驱动' % (mod, inst, pin, net))
    assigns = []
    for lhs, rhs in X.golden_assigns(mod):
        if lhs.startswith('io_'):
            net = rhs[1:]
            if not rhs.startswith('_') or wires.get(net) != g.pw[lhs]:
                X.die('%s: assign %s = %s 不是同宽的子模块输出线' % (mod, lhs, rhs))
            assigns.append((lhs, net))
            driven.add(lhs)
    for sig in [s for _, s in SHELL_CORE_PINS if s not in ('skid_flush',) and not s.startswith('io_')]:
        if sig not in wires:
            X.die('%s: 胶水核要的线 %s 不存在' % (mod, sig))
    missing = {n for d, w, n in g.ports if d == 'output'} - driven
    if missing:
        X.die('%s: 输出端口没有驱动 %r' % (mod, sorted(missing)))

    out = ['module %s' % mod, '(']
    out += g.port_text.split('\n')
    out += [');', '', '  // ---- 子模块输出线（<实例名>_<端口名>）----']
    for net, w in wires.items():
        out.append('  %-14s %s;' % (X.wdecl(w), net))
    out += ['  logic          skid_flush;', '',
            '  // ---- 胶水：skid 缓冲的冲刷条件 ----',
            '  xs_VSplitImp_core u_core (']
    for i, (p, s) in enumerate(SHELL_CORE_PINS):
        out.append('    .%-28s (%s)%s' % (p, s, ',' if i < len(SHELL_CORE_PINS) - 1 else ''))
    out += ['  );', '']
    for cm, inst, conns in body:
        out.append('  // ---- 子模块 %s（%s）----' % (inst, cm))
        out.append('  %s %s (' % (cm, inst))
        for i, (pin, net) in enumerate(conns):
            out.append('    .%-52s (%s)%s' % (pin, net, ',' if i < len(conns) - 1 else ''))
        out += ['  );', '']
    for lhs, net in assigns:
        out.append('  assign %s = %s;' % (lhs, net))
    out += ['', 'endmodule']
    return out


# ---------------------------------------------------------------------------
# 4. tb 的手写部分
# ---------------------------------------------------------------------------
TB_HEAD = '''// =============================================================================
// %(mod)s UT —— golden %(mod)s 对重写 %(mod)s_xs 双例化，同激励逐拍比全部 %(nout)d 根输出。
// 本文件由 scripts/gen_vsplit.py 生成（端口连接 / 随机驱动 / 逐根比较是机械部分，
// 激励整形与覆盖判据是生成器里 TB_* 的手写部分）。勿手改。
//
%(notes)s
// 不复位寄存器：非常量 initreg 档两个实例各摇各的，先跑 +warmup 拍再开始比。
// 覆盖判据（读重写件内部信号，逐项有下限，不达标本轮不作数）：见 cov_names。
// =============================================================================
'''

# ---- 拆分流水 / 装配壳共用的"一条向量访存 uop"激励 ----
TB_DRIVE_UOP = r'''
  // 一条向量访存 uop 的整形：操作码按 mop 与三种特殊 unit-stride 分桶；倍数 / 宽度 / nf / uopIdx 取
  // 合法范围为主、偶尔全随机（非法编码两侧也必须一致）；vl / vstart 取小值让掩码区间落在可见范围。
  task automatic shape_uop();
    logic [1:0] mop;
    logic [4:0] low5;
    mop = 2'($urandom);
    case ($urandom_range(0, 9))
      0, 1:    low5 = 5'h08;                 // whole-register
      2:       low5 = 5'h0B;                 // mask 型
      3:       low5 = 5'h10;                 // fault-only-first（load）
      4:       low5 = 5'($urandom);
      default: low5 = 5'h00;
    endcase
    io_in_bits_uop_fuOpType  = {(@IS_VSTORE@ ? 2'b10 : 2'b01), mop, low5};
    if ($urandom_range(0, 15) == 0) io_in_bits_uop_fuOpType = 9'($urandom);
    if ($urandom_range(0, 7) != 0) io_in_bits_uop_vpu_vlmul = 3'($urandom_range(5, 11));   // 5,6,7,0,1,2,3
    case ($urandom_range(0, 7))
      0, 1, 2, 3: io_in_bits_uop_vpu_nf = 3'd0;
      4:          io_in_bits_uop_vpu_nf = 3'd1;
      5:          io_in_bits_uop_vpu_nf = 3'd3;
      6:          io_in_bits_uop_vpu_nf = 3'd7;
      default:    io_in_bits_uop_vpu_nf = 3'($urandom);
    endcase
    if ($urandom_range(0, 3) != 0) io_in_bits_uop_vpu_vuopIdx = 7'($urandom_range(0, 7));
    io_in_bits_src_4 = 128'($urandom_range(0, 3) == 0 ? $urandom_range(0, 255) : $urandom_range(0, 40));
    io_in_bits_uop_vpu_vstart = ($urandom_range(0, 3) == 0) ? 8'($urandom_range(0, 20)) : 8'h0;
    io_in_bits_isVecPartReplay = ($urandom_range(0, 7) == 0);
    io_in_bits_flowNum = ($urandom_range(0, 7) == 0) ? 5'($urandom) : 5'($urandom_range(1, 8));
    io_in_valid        = ($urandom_range(0, 3) != 0);
    io_redirect_valid  = ($urandom_range(0, 15) == 0);
    io_threshold_valid = ($urandom_range(0, 3) == 0);
    if ($urandom_range(0, 1)) begin
      io_threshold_bits_robIdx_flag  = io_in_bits_uop_robIdx_flag;
      io_threshold_bits_robIdx_value = io_in_bits_uop_robIdx_value;
      if ($urandom_range(0, 3) != 0) io_threshold_bits_uopIdx = io_in_bits_uop_vpu_vuopIdx;
    end
    io_toMergeBuffer_req_ready  = ($urandom_range(0, 3) != 0);
    io_toMergeBuffer_resp_valid = ($urandom_range(0, 3) != 0);
  endtask
'''

TB_PIPE_NOTES = '''// 激励要点：见 shape_uop（操作码 / 倍数 / nf / uopIdx / vl 分桶）；out_ready 3/4；
//   合并缓冲 ready / resp 各 3/4；threshold 1/4，且一半时间点名当前 uop。'''
TB_PIPE_HAND = TB_DRIVE_UOP + r'''
  task automatic drive();
    drive_random();
    shape_uop();
    io_out_ready = ($urandom_range(0, 3) != 0);
  endtask
  task automatic quiesce();
    io_in_valid = 0;
  endtask

`define C u_impl.u_core
'''
PIPE_COV = [
    ('s0_fire_unit_stride',   1000, '`C.s0_fire & (`C.s0_mop == 2\'b00)'),
    ('s0_fire_strided',       1000, '`C.s0_fire & (`C.s0_mop == 2\'b10)'),
    ('s0_fire_indexed',       1000, '`C.s0_fire & `C.s0_mop[0]'),
    ('s0_whole_reg',          200,  '`C.s0_fire & `C.s0_isUsWholeReg'),
    ('s0_mask_reg',           100,  '`C.s0_fire & `C.s0_isMaskReg'),
    ('s0_segment',            500,  '`C.s0_fire & `C.s0_isSegment'),
    ('s0_special_indexed',    200,  '`C.s0_fire & `C.s0_isSpecialIndexed'),
    ('s0_indexed_lmul_gt',    200,  '`C.s0_fire & `C.s0_mop[0] & `C.s0_lmulGtEmul'),
    ('s0_flowmask_nonzero',   1000, '`C.s0_fire & (|`C.s0_flowMask)'),
    ('s0_nack',               200,  'io_in_valid & `C.s0_mergeBufferNack'),
    ('s0_kill',               100,  'io_in_valid & `C.s0_kill'),
    ('s1_fire',               1000, '`C.s1_fire'),
    ('s1_kill',               100,  '`C.s1_valid & `C.s1_kill'),
    ('s1_us_two_flows',       100,  '`C.s1_fire & ~`C.s1_in.preIsSplit & (`C.s1_usActiveNum == 5\'d2)'),
    ('s1_us_one_flow',        100,  '`C.s1_fire & ~`C.s1_in.preIsSplit & (`C.s1_usActiveNum == 5\'d1)'),
    ('s1_strided_offset',     200,  '`C.s1_fire & `C.s1_isStrided & (|`C.s1_uopOffset)'),
    ('s1_part_replay_out',    100,  '`C.out_valid & `C.s1_in.isVecPartReplay'),
    ('s1_wait_mergebuffer',   100,  '`C.s1_valid & io_out_ready & ~io_toMergeBuffer_resp_valid'),
    ('s1_blocked_by_out',     100,  '`C.out_valid & ~io_out_ready'),
]

TB_BUF_NOTES = '''// 激励要点：入队 valid 1/2；flowNum 逐元素拆时 1..16、unit-stride 时 2；usMask 一半时间高半为 0
//   （一次访问就够）；indexVlMaxInVd 取 2^k-1；部分重放 1/8；out_ready 3/4；redirect 1/32。
//   store：非对齐缓冲空闲 / 标量发射 / SQ 队头向量各随机；
//   load ：三个 load 流水写回 valid 各 1/4，mBIndex 一半时间对准缓冲里这条 uop。'''
TB_BUF_HAND = r'''
  task automatic drive();
    drive_random();
    io_redirect_valid = ($urandom_range(0, 31) == 0);
    io_in_valid       = ($urandom_range(0, 1) == 0);
    io_out_ready      = ($urandom_range(0, 3) != 0);
    io_in_bits_preIsSplit = ($urandom_range(0, 2) != 0);
    io_in_bits_flowNum    = io_in_bits_preIsSplit ? 5'($urandom_range(1, 16)) : 5'd2;
    if ($urandom_range(0, 15) == 0) io_in_bits_flowNum = 5'($urandom);
    if ($urandom_range(0, 1)) io_in_bits_usMask[31:16] = 16'h0;
    if ($urandom_range(0, 3) == 0) io_in_bits_flowMask = 16'hFFFF;
    case ($urandom_range(0, 5))
      0: io_in_bits_indexVlMaxInVd = 8'h00;
      1: io_in_bits_indexVlMaxInVd = 8'h01;
      2: io_in_bits_indexVlMaxInVd = 8'h03;
      3: io_in_bits_indexVlMaxInVd = 8'h07;
      4: io_in_bits_indexVlMaxInVd = 8'h0F;
      default: ;
    endcase
    if ($urandom_range(0, 3) != 0) io_in_bits_alignedType = io_in_bits_preIsSplit ? 3'($urandom_range(0, 3)) : 3'd4;
    if ($urandom_range(0, 3) != 0) io_in_bits_sew = 3'($urandom_range(0, 3));
    io_in_bits_isVecPartReplay = ($urandom_range(0, 7) == 0);
@VARIANT_DRIVE@
  endtask
  task automatic quiesce();
    io_in_valid = 0;
  endtask

`define C u_impl.u_core
'''
BUF_DRIVE = {
    0: r'''    if ($urandom_range(0, 3) == 0) io_in_bits_instType = 3'b011;     // 有序 indexed
    io_fromPipeline_0_valid = ($urandom_range(0, 3) == 0);
    io_fromPipeline_1_valid = ($urandom_range(0, 3) == 0);
    io_fromPipeline_2_valid = ($urandom_range(0, 3) == 0);
    if ($urandom_range(0, 1)) io_fromPipeline_0_bits_mBIndex = u_golden.uopq_mBIndex;
    if ($urandom_range(0, 1)) io_fromPipeline_1_bits_mBIndex = u_golden.uopq_mBIndex;
    if ($urandom_range(0, 1)) io_fromPipeline_2_bits_mBIndex = u_golden.uopq_mBIndex;''',
    1: r'''    io_vstdMisalign_storeMisalignBufferEmpty = ($urandom_range(0, 3) != 0);
    io_vstdMisalign_scalaIssueValid          = ($urandom_range(0, 1) == 0);
    io_vstdMisalign_sqDeqIsVec               = ($urandom_range(0, 3) == 0);''',
}
BUF_COV_COMMON = [
    ('enqueue',               1000, '`C.doEnqueue'),
    ('enqueue_while_busy',    100,  '`C.doEnqueue & `C.allocated'),
    ('enqueue_cancelled',     20,   'io_in_valid & `C.canAccept & `C.cancelEnq'),
    ('active_issue',          1000, '`C.activeIssue'),
    ('inactive_skip',         1000, '`C.inActiveIssue'),
    ('split_finish',          1000, '`C.splitFinish & `C.issuedThisCycle'),
    ('need_cancel',           100,  '`C.needCancel'),
    ('us_no_split',           100,  '`C.activeIssue & `C.usNoSplit'),
    ('us_second_flow',        100,  '`C.activeIssue & ~`C.uopq.preIsSplit & (`C.splitIdx == 5\'d1)'),
    ('issue_indexed',         500,  '`C.activeIssue & `C.uopq.preIsSplit & `C.isIndexed'),
    ('issue_strided',         500,  '`C.activeIssue & `C.uopq.preIsSplit & ~`C.isIndexed'),
    ('stride_accumulated',    500,  '`C.activeIssue & `C.uopq.preIsSplit & ~`C.isIndexed & (|`C.strideOffsetReg)'),
    ('part_replay_issue',     100,  '`C.activeIssue & `C.uopq.isVecPartReplay'),
    ('first_active',          500,  '`C.out_fire & `C.isFirstActive'),
    ('blocked_by_out',        200,  '`C.out_valid & ~io_out_ready'),
    ('queue_ptr_wrap',        100,  '`C.activeIssue & `C.ptrWrap'),
]
BUF_COV = {
    0: BUF_COV_COMMON + [
        ('sw_enter_stop',         100,  '(`C.g_vload.allowIssue_splitCanGo_stopWaitState != 2\'d2) & `C.out_fire'
                                        ' & (`C.uopq.instType == 3\'b011) & ~`C.splitFinish & ~`C.needCancel'),
        ('sw_stop_blocks',        100,  '`C.issueValid & `C.vecActive & ~`C.splitCanGo'),
        ('sw_stop_to_send',       50,   '(`C.g_vload.allowIssue_splitCanGo_stopWaitState == 2\'d2) & `C.g_vload.pipelineWbValid'
                                        ' & ~`C.splitFinish & ~`C.needCancel'),
        ('sw_send_issue',         50,   '(`C.g_vload.allowIssue_splitCanGo_stopWaitState == 2\'d1) & `C.out_fire'),
    ],
    1: BUF_COV_COMMON + [
        ('vstd_valid',            1000, '`C.vstd_valid'),
        ('vstd_already_issued',   100,  '`C.issueValid & `C.vecActive & `C.g_vstore.dataIssued'),
        ('misalign_blocked',      100,  '`C.issueValid & `C.vecActive & ~`C.addrAligned & ~`C.misalignedCanGo'),
        ('misalign_go',           100,  '`C.activeIssue & ~`C.addrAligned'),
    ],
}

TB_SKID_NOTES = '''// 激励要点：所有输入全随机；in_valid 3/4、out_ready 1/2、flush 1/8。'''
TB_SKID_HAND = r'''
  task automatic drive();
    drive_random();
    io_in_valid  = ($urandom_range(0, 3) != 0);
    io_out_ready = ($urandom_range(0, 1) == 0);
    io_flush     = ($urandom_range(0, 7) == 0);
  endtask
  task automatic quiesce();
    io_in_valid = 0;
  endtask

`define C u_impl.u_core
'''
SKID_COV = [
    ('capture',               1000, '`C.capture'),
    ('capture_but_flushed',   100,  '`C.capture & io_flush'),
    ('skid_state',            1000, '`C.state'),
    ('skid_drained',          1000, '`C.state & io_out_ready'),
    ('skid_flushed',          100,  '`C.state & io_flush & ~io_out_ready'),
    ('skid_hold',             100,  '`C.state & ~io_flush & ~io_out_ready'),
    ('passthrough',           1000, '~`C.state & io_in_valid & io_out_ready'),
]

TB_SHELL_NOTES = '''// 激励要点：入口 uop 的整形同拆分流水（见 shape_uop）；out_ready 3/4；
//   store：非对齐缓冲空闲 / 标量发射 / SQ 队头向量各随机；load：三个 load 流水写回各 1/4。
// 本 tb 两侧都是整棵子树（golden 壳 + golden 子模块 对 重写壳 + 重写子模块）。'''
TB_SHELL_HAND = TB_DRIVE_UOP + r'''
  task automatic drive();
    drive_random();
    shape_uop();
    io_out_ready = ($urandom_range(0, 3) != 0);
    io_redirect_valid = ($urandom_range(0, 31) == 0);
@VARIANT_DRIVE@
  endtask
  task automatic quiesce();
    io_in_valid = 0;
  endtask

`define P u_impl.splitPipeline.u_core
`define B u_impl.splitBuffer.u_core
`define K u_impl.VSSplitSkidBuffer.u_core
'''
SHELL_DRIVE = {
    0: r'''    io_fromPipeline_0_valid = ($urandom_range(0, 3) == 0);
    io_fromPipeline_1_valid = ($urandom_range(0, 3) == 0);
    io_fromPipeline_2_valid = ($urandom_range(0, 3) == 0);
    if ($urandom_range(0, 1)) io_fromPipeline_0_bits_mBIndex = u_golden.splitBuffer.uopq_mBIndex;''',
    1: r'''    io_vstdMisalign_storeMisalignBufferEmpty = ($urandom_range(0, 3) != 0);
    io_vstdMisalign_scalaIssueValid          = ($urandom_range(0, 1) == 0);
    io_vstdMisalign_sqDeqIsVec               = ($urandom_range(0, 3) == 0);''',
}
SHELL_COV_COMMON = [
    ('pipeline_s0_fire',      1000, '`P.s0_fire'),
    ('pipeline_out_fire',     1000, '`P.out_valid & `P.out_ready'),
    ('skid_capture',          200,  '`K.capture'),
    ('skid_state',            200,  '`K.state'),
    ('skid_flush_passthru',   10,   '`K.flush & ~`K.state & `K.in_valid'),
    ('skid_flush_buffered',   5,    '`K.flush & `K.state'),
    ('buffer_enqueue',        1000, '`B.doEnqueue'),
    ('buffer_active_issue',   1000, '`B.activeIssue'),
    ('buffer_inactive_skip',  200,  '`B.inActiveIssue'),
    ('buffer_split_finish',   500,  '`B.splitFinish & `B.issuedThisCycle'),
    ('buffer_need_cancel',    50,   '`B.needCancel'),
    ('out_blocked',           200,  '`B.out_valid & ~io_out_ready'),
]
SHELL_COV = {
    0: SHELL_COV_COMMON + [('load_stop_wait', 20, '`B.issueValid & `B.vecActive & ~`B.splitCanGo')],
    1: SHELL_COV_COMMON + [('store_vstd', 500, '`B.vstd_valid')],
}


NAV = {
    'VLSplitBufferImp.sv': [
        ('xs_VSplitBuffer_core —— 拆分缓冲的可读核',            r'^// xs_VSplitBuffer_core —— 拆分缓冲的可读核'),
        ('§1 状态与入队',                                        r'^  // §1 状态与入队'),
        ('§2 当前访问的元素号、地址、掩码',                      r'^  // §2 当前访问'),
        ('§3 发射握手与计数',                                    r'^  // §3 发射握手与计数'),
        ('§4 变体专属：store 非对齐门控与数据 / load stop-and-wait', r'^  // §4 变体专属'),
        ('§5 发给标量访存流水的访问包',                          r'^  // §5 发给标量访存流水的访问包'),
        ('VLSplitBufferImp wrapper（生成）：端口拆装 + uopq_* 寄存器', r'^// VLSplitBufferImp —— golden 同名 wrapper'),
    ],
    'VLSplitImp.sv': [
        ('xs_VSplitImp_core —— skid 冲刷条件（手写胶水）',       r'^// xs_VSplitImp_core —— 胶水核'),
        ('VLSplitImp wrapper（生成）',                           r'^// VLSplitImp —— golden 同名 wrapper'),
        ('子模块输出线声明',                                     r'^  // ---- 子模块输出线'),
        ('胶水核例化',                                           r'^  // ---- 胶水：skid 缓冲的冲刷条件'),
        ('splitPipeline 例化',                                   r'^  // ---- 子模块 splitPipeline'),
        ('splitBuffer 例化',                                     r'^  // ---- 子模块 splitBuffer'),
        ('VSSplitSkidBuffer 例化',                               r'^  // ---- 子模块 VSSplitSkidBuffer'),
    ],
    'VSSplitImp.sv': [
        ('VSSplitImp wrapper（生成）',                           r'^// VSSplitImp —— golden 同名 wrapper'),
        ('子模块输出线声明',                                     r'^  // ---- 子模块输出线'),
        ('胶水核例化',                                           r'^  // ---- 胶水：skid 缓冲的冲刷条件'),
        ('splitPipeline 例化',                                   r'^  // ---- 子模块 splitPipeline'),
        ('splitBuffer 例化',                                     r'^  // ---- 子模块 splitBuffer'),
        ('VSSplitSkidBuffer 例化',                               r'^  // ---- 子模块 VSSplitSkidBuffer'),
    ],
}


def make_tb(mod, notes, hand, cov, is_vstore=0, variant_drive=''):
    hand = hand.replace('@IS_VSTORE@', str(is_vstore)).replace('@VARIANT_DRIVE@', variant_drive)
    hand = hand + '\n' + X.tb_cov_block(cov) + X.TB_MAIN.replace('@MOD@', mod)
    nout = sum(1 for d, w, n in G[mod].ports if d == 'output')
    text, _ = X.emit_tb(G[mod], TB_HEAD % {'mod': mod, 'nout': nout, 'notes': notes}, hand)
    return text


# ---------------------------------------------------------------------------
# 5. 组装
# ---------------------------------------------------------------------------
def build():
    """返回 {path: 新内容}（rtl 文件做 region 替换，tb 整文件生成）。"""
    res = {}
    errs = []

    def load(name):
        p = RTL / name
        if p not in res:
            res[p] = p.read_text()
        return p

    p = load('vlsu_pkg.sv')
    res[p] = X.replace_region(res[p], 'types', TS.emit())

    # 拆分流水
    p = load('VLSplitPipelineImp.sv')
    res[p] = X.replace_region(res[p], 'core_ports', X.emit_core_ports(PIPE_PLIST))
    pipe_core_text = res[p]
    for tag, isv in VARIANTS:
        mod = tag + 'SplitPipelineImp'
        p = load(mod + '.sv')
        res[p] = X.replace_region(res[p], 'wrapper_' + mod, family_wrapper(
            mod, 'xs_VSplitPipeline_core', isv, PIPE_REG_GROUPS, PIPE_PLIST, PIPE_BRIDGE,
            's1_in <= s0_out（s0_fire 时整包打拍，无复位）'))
    # 拆分缓冲
    p = load('VLSplitBufferImp.sv')
    res[p] = X.replace_region(res[p], 'core_ports', X.emit_core_ports(BUF_PLIST))
    buf_core_text = res[p]
    for tag, isv in VARIANTS:
        mod = tag + 'SplitBufferImp'
        p = load(mod + '.sv')
        res[p] = X.replace_region(res[p], 'wrapper_' + mod, family_wrapper(
            mod, 'xs_VSplitBuffer_core', isv, BUF_REG_GROUPS, BUF_PLIST, BUF_BRIDGE,
            'uopq <= in（doEnqueue 时整包装入，无复位）'))
    # 寄存器全集核对：逐变体"golden - 生成 ⊆ 核"，且核里的寄存器必须属于某个变体的 golden
    for core_text, core, mods in ((pipe_core_text, 'xs_VSplitPipeline_core', ('VLSplitPipelineImp', 'VSSplitPipelineImp')),
                                  (buf_core_text, 'xs_VSplitBuffer_core', ('VLSplitBufferImp', 'VSSplitBufferImp'))):
        hand_all, want_all = set(), set()
        for mod in mods:
            e, hand, want = check_family_regs(mod, core_text, core)
            errs += e
            hand_all |= hand
            want_all |= want
        errs += ['%s: 手写区寄存器 %s 不在任何变体的 golden 寄存器表里' % (core, n) for n in sorted(hand_all - want_all)]

    # skid
    p = load('skidBufferConnect.sv')
    res[p] = X.replace_region(res[p], 'wrapper', skid_wrapper())
    code = X.strip_comments(res[p])
    core = re.search(r'module xs_SkidBuffer_core\b(.*?)\nendmodule', code, re.S)
    if not core or X.nb_assigned(core.group(1)) != {'state'}:
        errs.append('skidBufferConnect: 核手写区的寄存器应当恰好是 state')

    # 装配壳
    for tag, isv in VARIANTS:
        mod = tag + 'SplitImp'
        p = load(mod + '.sv')
        res[p] = X.replace_region(res[p], 'wrapper_' + mod, shell_wrapper(mod))

    # 大文件导航（>1500 行必须有；行号两遍定稿）
    for name, anchors in NAV.items():
        p = RTL / name
        for _ in range(2):
            res[p] = X.replace_region(res[p], 'nav', X.gen_nav(res[p], anchors))

    for p, t in res.items():
        if X.has_firtool_names(t):
            errs.append('%s: 代码区出现 firtool 展平中间名' % p.name)
    if errs:
        X.die('\n  '.join(['机械核对未通过：'] + errs))

    # tb
    for tag, isv in VARIANTS:
        res[UT / (tag + 'SplitPipelineImp') / 'tb.sv'] = make_tb(
            tag + 'SplitPipelineImp', TB_PIPE_NOTES, TB_PIPE_HAND, PIPE_COV, isv)
        res[UT / (tag + 'SplitBufferImp') / 'tb.sv'] = make_tb(
            tag + 'SplitBufferImp', TB_BUF_NOTES, TB_BUF_HAND, BUF_COV[isv], isv, BUF_DRIVE[isv])
        res[UT / (tag + 'SplitImp') / 'tb.sv'] = make_tb(
            tag + 'SplitImp', TB_SHELL_NOTES, TB_SHELL_HAND, SHELL_COV[isv], isv, SHELL_DRIVE[isv])
    res[UT / 'skidBufferConnect' / 'tb.sv'] = make_tb('skidBufferConnect', TB_SKID_NOTES, TB_SKID_HAND, SKID_COV)
    return res


def main(argv):
    check = '--check' in argv
    res = build()
    bad = []
    for p, new in res.items():
        old = p.read_text() if p.exists() else None
        if old != new:
            bad.append(str(p.relative_to(REPO)))
            if not check:
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(new)
    if check:
        if bad:
            print('gen_vsplit --check: DRIFT ' + ', '.join(bad))
            return 1
        print('gen_vsplit --check: OK（%d 个文件）' % len(res))
        return 0
    print('gen_vsplit: 已生成（%d 个文件，其中改写 %d 个）' % (len(res), len(bad)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

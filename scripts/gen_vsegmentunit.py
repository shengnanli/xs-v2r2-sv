#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_vsegmentunit.py —— VSegmentUnit（向量 segment 访存单元）的机械派生区生成器。

产物（`// BEGIN GENERATED(<tag>)` 原地替换；手写区不碰）：
  rtl/memblock/vsegment_pkg.sv      types：seg_uop_t / seg_in_t / seg_wb_t / ... 接口 struct
                                    （成员 = golden 端口表与寄存器表的并集）
  rtl/memblock/VSegmentUnit.sv      core_ports（核端口表）、trigger（VSegmentTrigger 例化）、
                                    pipe（NewPipelineConnectPipe_33 例化）、wrapper（扁平端口 ↔ struct 拆装 +
                                    大块 payload 寄存器：uopq×8 / data×8 / stride×8 / instMicroOp.uop /
                                    fofBuffer / 写回与反馈打拍寄存器，字段集合照 golden 现数）、nav
  verif/ut/VSegmentUnit/tb.sv       双例化 tb（激励整形与覆盖判据是本文件 TB_* 的手写部分）

★为什么要机械生成★ golden 240 个端口、436 个寄存器，其中 8 项 uop 队列 ×26 字段、instMicroOp 的
45 个 uop 字段、fofBuffer 53 个字段、写回打拍 67 个字段都是"同一份 uop 原样存一遍"；留哪些字段由
firtool 的 DCE 决定（CONVENTIONS：字段集合从 golden 现数）。核只写状态机 / 地址 / 数据拼接 /
异常规则；payload 寄存器保持 golden 展平名，FM 按名配对。

机械核对（fail-closed）：
  1. 每个端口恰归一组或标量口；同名成员位宽一致；
  2. golden 寄存器全集 == 生成的寄存器组 ∪ 核手写区 `<=` 目标（逐名，多 / 少都红）；
  3. 子模块 pin 表与 golden 子模块端口表逐个一致；
  4. 产物代码区无 firtool 展平中间名。

用法：
    python3 scripts/gen_vsegmentunit.py            # 生成
    python3 scripts/gen_vsegmentunit.py --check    # 产物与生成器不一致则非零退出
"""
import collections
import pathlib
import re
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import xs_structgen as X  # noqa: E402

REPO = pathlib.Path(__file__).resolve().parent.parent
RTL = REPO / 'rtl' / 'memblock' / 'VSegmentUnit.sv'
PKG = REPO / 'rtl' / 'memblock' / 'vsegment_pkg.sv'
TB = REPO / 'verif' / 'ut' / 'VSegmentUnit' / 'tb.sv'
MOD = 'VSegmentUnit'
Q = 8

G = X.Golden(MOD)
GT = X.Golden('VSegmentTrigger')
GP = X.Golden('NewPipelineConnectPipe_33')

TS = X.TypeSpace(
    collections.OrderedDict([
        ('seg_uop_t',         '微操作信息（DynInst 在本单元各接口与寄存器里留下的字段并集）'),
        ('seg_in_t',          '后端发来的 segment 访存 uop（src_0=基址 rs1，src_1=stride / index 向量，src_2=store 数据 vs3，'
                              'src_3=v0 mask，src_4=vl）'),
        ('seg_wb_t',          '写回后端（MemExuOutput，带 vdIdx）'),
        ('seg_difftest_t',    'difftest 用的出队 uop 信息'),
        ('seg_dcache_req_t',  'DCache 读请求'),
        ('seg_dcache_resp_t', 'DCache 读应答（数据与错误晚一拍到）'),
        ('seg_sbuf_t',        '写 sbuffer 的一笔（DCacheWordReqWithVaddrAndPfFlag）'),
        ('seg_tlb_req_t',     'DTLB 请求'),
        ('seg_tlb_resp_t',    'DTLB 应答'),
        ('seg_feedback_t',    '给发射队列的反馈'),
        ('seg_excinfo_t',     '异常地址信息'),
    ]),
    {t: [('uop_', 'uop', 'seg_uop_t')] for t in ('seg_in_t', 'seg_wb_t', 'seg_difftest_t')})

PORT_GROUPS = [
    ('io_in_bits_',              'seg_in_t',          'in'),
    ('io_uopwriteback_bits_',    'seg_wb_t',          'uopwriteback'),
    ('io_vecDifftestInfo_bits_', 'seg_difftest_t',    'vecDifftestInfo'),
    ('io_rdcache_req_bits_',     'seg_dcache_req_t',  'rdcache_req'),
    ('io_rdcache_resp_bits_',    'seg_dcache_resp_t', 'rdcache_resp'),
    ('io_sbuffer_bits_',         'seg_sbuf_t',        'sbuffer'),
    ('io_dtlb_req_bits_',        'seg_tlb_req_t',     'dtlb_req'),
    ('io_dtlb_resp_bits_',       'seg_tlb_resp_t',    'dtlb_resp'),
    ('io_feedback_bits_',        'seg_feedback_t',    'feedback'),
    ('io_exceptionInfo_bits_',   'seg_excinfo_t',     'exceptionInfo'),
]
# (前缀, 类型, 读回信号, 使能, 装载源, 复位, 核里手写的字段)
REG_GROUPS = [
    ('instMicroOp_uop_',        'seg_uop_t',      'instMicroOp_uop_q', 'instMicroOp_load', 'in.uop',       False,
     {'trigger'} | {'exceptionVec_%d' % i for i in range(24)}),
    ('fofBuffer_',              'seg_uop_t',      'fofBuffer',         'fofBuffer_we',     'fofBuffer_wdata', True, set()),
    ('io_uopwriteback_bits_r_', 'seg_wb_t',       'uopwriteback_r',    'writebackValid',   'writebackOut', False,
     {'vdIdx', 'vdIdxInField'}),
    ('io_feedback_bits_r_',     'seg_feedback_t', 'feedback_r',        'feedbackValid',    'feedbackOut',  False, set()),
] + [('uopq_%d_uop_' % i, 'seg_uop_t', 'uopq_uop[%d]' % i, 'uopq_we[%d]' % i, 'in.uop', False, set()) for i in range(Q)]
REG_GROUP_DOC = {
    'instMicroOp_uop_': 'instMicroOp.uop <= in.uop（第一条 uop 到达时锁存；exceptionVec / trigger 在核里改写）',
    'fofBuffer_': 'fofBuffer（fof 的最后一条 uop；RegInit 0，用完清零）',
    'io_uopwriteback_bits_r_': '写回打拍 RegEnable(writebackOut, writebackValid)（vdIdx / vdIdxInField 在核里：fof 那条不改它们）',
    'io_feedback_bits_r_': '反馈打拍 RegEnable(feedbackOut, feedbackValid)',
}
BRIDGE = [
    ('output', 'logic [%d:0]' % (Q - 1), 'uopq_we'),
    ('input',  'seg_uop_t [%d:0]' % (Q - 1), 'uopq_uop'),
    ('output', 'logic [%d:0]' % (Q - 1), 'data_we'),
    ('output', 'logic [%d:0][127:0]' % (Q - 1), 'data_wdata'),
    ('input',  'logic [%d:0][127:0]' % (Q - 1), 'data'),
    ('input',  'logic [%d:0][127:0]' % (Q - 1), 'stride'),
    ('output', 'logic', 'instMicroOp_load'),
    ('input',  'seg_uop_t', 'instMicroOp_uop_q'),
    ('output', 'logic', 'fofBuffer_we'),
    ('output', 'seg_uop_t', 'fofBuffer_wdata'),
    ('input',  'seg_uop_t', 'fofBuffer'),
    ('output', 'logic', 'writebackValid'),
    ('output', 'seg_wb_t', 'writebackOut'),
    ('input',  'seg_wb_t', 'uopwriteback_r'),
    ('output', 'logic', 'feedbackValid'),
    ('output', 'seg_feedback_t', 'feedbackOut'),
    ('input',  'seg_feedback_t', 'feedback_r'),
]

CPORTS = X.classify_ports(G, PORT_GROUPS, TS)
CREGS = X.classify_regs(G, [(g[0], g[1]) for g in REG_GROUPS], TS)
# 核里手写的字段从组里拿掉（它们在核里是同名寄存器）
for prefix, typ, sig, en, src, rst, hand in REG_GROUPS:
    CREGS[prefix] = [(n, w, f) for n, w, f in CREGS[prefix] if f not in hand]
# data_<i> / stride_<i>：标量数组
ARR = {}
for base in ('data', 'stride'):
    ARR[base] = []
    for i in range(Q):
        n = '%s_%d' % (base, i)
        if G.regs.get(n) != 128:
            X.die('golden 没有 128 位的 %s' % n)
        ARR[base].append(n)
GEN_REGS = {n for lst in CREGS.values() for n, _, _ in lst} | {n for lst in ARR.values() for n in lst}
PLIST = X.core_port_list([CPORTS], BRIDGE)


def gen_trigger():
    scalars = {X.core_name(n): w for d, w, n, grp, f in CPORTS if not grp}
    hand = {'tdataVec_io_fromLoadStore_vaddr': 'dcacheReqVaddr',
            'tdataVec_io_toLoadStore_triggerAction': 'triggerAction',
            'tdataVec_io_memType': 'instMicroOp_isVSegLoad'}
    out = ['  VSegmentTrigger segmentTrigger (']
    conns = []
    for d, w, n in GT.ports:
        if n in hand:
            conns.append((n, hand[n]))
        else:
            src = n[len('tdataVec_io_'):]
            if scalars.get(src) != w:
                X.die('VSegmentTrigger 端口 %s 在核里没有同宽的 %s' % (n, src))
            conns.append((n, src))
    for i, (p, s) in enumerate(conns):
        out.append('    .%-48s (%s)%s' % (p, s, ',' if i < len(conns) - 1 else ''))
    out.append('  );')
    return out


def gen_pipe():
    hand = {'clock': 'clock', 'reset': 'reset', 'io_in_ready': 'pipe_in_ready', 'io_in_valid': 'sbufferOut_valid',
            'io_out_ready': 'sbuffer_ready', 'io_out_valid': 'pipe_out_valid', 'io_rightOutFire': 'sbufferFire'}
    out = ['  NewPipelineConnectPipe_33 VSegmentUnitPipelineConnect (']
    conns = []
    for d, w, n in GP.ports:
        if n in hand:
            conns.append((n, hand[n]))
        elif n.startswith('io_in_bits_'):
            TS.resolve('seg_sbuf_t', n[len('io_in_bits_'):], w, False)
            conns.append((n, 'sbufferOut.' + n[len('io_in_bits_'):]))
        elif n.startswith('io_out_bits_'):
            TS.resolve('seg_sbuf_t', n[len('io_out_bits_'):], w, False)
            conns.append((n, 'sbuffer.' + n[len('io_out_bits_'):]))
        else:
            X.die('NewPipelineConnectPipe_33 端口 %s 不认识' % n)
    for i, (p, s) in enumerate(conns):
        out.append('    .%-22s (%s)%s' % (p, s, ',' if i < len(conns) - 1 else ''))
    out.append('  );')
    return out


def gen_wrapper():
    out = ['module %s' % MOD, '  import vlsu_pkg::*;', '  import vsegment_pkg::*;', '(']
    out += G.port_text.split('\n')
    out += [');', '']
    out += X.emit_group_glue(TS, CPORTS)
    out.append('  // ---- 核与寄存器之间的桥 ----')
    decl = collections.OrderedDict()
    for d, t, name in BRIDGE:
        decl.setdefault(t, []).append(name)
    for t, names in decl.items():
        out.append('  %-26s %s;' % (t, ', '.join(names)))
    out.append('')
    for prefix, typ, sig, en, src, rst, hand in REG_GROUPS:
        doc = REG_GROUP_DOC.get(prefix, 'uop 队列第 %s 项 <= in.uop（入队时装入，无复位）' % prefix.split('_')[1])
        out += X.emit_reg_group(TS, CREGS[prefix], typ, sig, en, src, doc, reset=rst)
        out.append('')
    out.append('  // ---- data[i]：目的寄存器的数据（load 拼接 / store 的 vs3）；stride[i]：stride 或 index 向量 ----')
    for base, en_fmt, src_fmt in (('data', 'data_we[%d]', 'data_wdata[%d]'), ('stride', 'uopq_we[%d]', 'in.src_1')):
        for i, n in enumerate(ARR[base]):
            out.append('  logic [127:0]  %s;' % n)
        out.append('  always_ff @(posedge clock) begin')
        for i, n in enumerate(ARR[base]):
            out.append('    if (%s) %s <= %s;' % (en_fmt % i, n, src_fmt % i if '%d' in src_fmt else src_fmt))
        out.append('  end')
        out.append('  assign %s = {%s};' % (base, ', '.join(reversed(ARR[base]))))
        out.append('')
    out += X.emit_core_inst('xs_VSegmentUnit_core', '', PLIST, CPORTS, [name for _, _, name in BRIDGE])
    out += ['', 'endmodule']
    return out


NAV = [
    ('xs_VSegmentUnit_core —— 可读核',                       r'^// xs_VSegmentUnit_core —— segment 访存状态机的可读核'),
    ('§1 指令级状态（instMicroOp）与队列指针',               r'^  // §1 指令级状态'),
    ('§2 状态机',                                            r'^  // §2 状态机'),
    ('§3 地址：虚地址、非对齐拆分、TLB 请求',                r'^  // §3 地址'),
    ('§4 异常与对齐检查（s_pm 态）',                         r'^  // §4 异常与对齐检查'),
    ('§5 load：读 DCache，拼进目的寄存器',                   r'^  // §5 load'),
    ('§6 store：取出元素数据，经流水缓冲写 sbuffer',         r'^  // §6 store'),
    ('§7 指针与计数的推进',                                  r'^  // §7 指针与计数的推进'),
    ('§8 fof 的最后一条 uop（fofBuffer）',                   r'^  // §8 fof'),
    ('§9 写回 / 反馈 / 异常上报',                            r'^  // §9 写回'),
    ('VSegmentUnit wrapper（生成）：端口拆装 + payload 寄存器', r'^// VSegmentUnit —— golden 同名 wrapper'),
]

PKG_HEAD = '''// =====================================================================
// vsegment_pkg.sv —— 向量 segment 访存单元（VSegmentUnit）的接口 struct（全部由 scripts/gen_vsegmentunit.py 生成）
// ---------------------------------------------------------------------
// 使用者：xs_VSegmentUnit_core 与 VSegmentUnit wrapper（VSegmentUnit.sv）。常量与小函数在 vlsu_pkg.sv。
// 成员 = golden VSegmentUnit 端口表与寄存器表的并集：seg_uop_t 是 DynInst 在本单元各接口 / 各寄存器组
//   留下的字段并集；golden 某个接口 / 寄存器组没有的成员由 wrapper 补 0 或不接。
// 单独成文件的原因：包被核与 wrapper 共用；按 scripts/check_pkg_scope.py 判据 B，包名与文件名相同的
//   独立文件是合法落点。
// =====================================================================

package vsegment_pkg;

  // BEGIN GENERATED(types) —— scripts/gen_vsegmentunit.py 生成，勿手改
  // END GENERATED(types)

endpackage
'''

# ---------------------------------------------------------------------------
# tb
# ---------------------------------------------------------------------------
TB_HEAD = '''// =============================================================================
// VSegmentUnit UT —— golden VSegmentUnit 对重写 VSegmentUnit_xs 双例化（各带自己的 VSegmentTrigger /
// NewPipelineConnectPipe_33 子树），同激励逐拍比全部 %(nout)d 根输出。
// 本文件由 scripts/gen_vsegmentunit.py 生成（端口连接 / 随机驱动 / 逐根比较是机械部分，
// 激励整形与覆盖判据是生成器里 TB_* 的手写部分）。勿手改。
//
// 激励要点：
//   · 入口：golden 空闲时以 1/4 概率起一条指令（1..6 条 uop 成串，串内指令级字段不变：fuType 一半
//     segment load（bit33）一半 segment store（bit34），mop 随机，nf 偏 0..2，vl 偏 1..8，vstart 偶尔非 0，
//     fof（0x90）1/8；最后一条 uop 带 lastUop）；每条 uop 的 vuopIdx 递增、源操作数随机；
//   · DTLB：应答 7/8，miss 1/8，Svpbmt 偏 0，各页异常位 1/256；PMP ld/st/mmio 各 1/256；
//   · DCache：req_ready 3/4，resp 7/8，miss 1/8，bank_conflict 1/16，tl_denied/corrupt 各 1/256；
//     data_delayed 随机；sbuffer_ready 3/4；flush_sbuffer_empty 3/4；cache_error_enable 7/8；
//   · 触发器：15/16 时间全关；其余 tdata2 取 golden 当前元素地址附近。
// 不复位寄存器：非常量 initreg 档两个实例各摇各的，先跑 +warmup 拍再开始比。
// 覆盖判据（读重写核内部信号，逐项有下限，不达标本轮不作数）：见 cov_names。
// =============================================================================
'''

TB_HAND = r'''
  function automatic logic [63:0] near(logic [63:0] va);
    logic [63:0] t;
    case ($urandom_range(0, 5))
      0: t = {14'h0, va[49:0]};
      1: t = {14'h0, va[49:0]} + $urandom_range(1, 40);
      2: t = {14'h0, va[49:0]} - $urandom_range(1, 40);
      3: t = {14'h0, va[49:4], 4'($urandom)};
      4: t = {14'h0, va[49:6], 6'($urandom)};
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
    io_fromCsrTrigger_tdataVec_``I``_load      = ($urandom_range(0, 9) != 0); \
    io_fromCsrTrigger_tdataVec_``I``_action    = ($urandom_range(0, 7) == 0) ? 4'($urandom) : 4'($urandom_range(0, 1)); \
    io_fromCsrTrigger_tdataVec_``I``_tdata2    = $urandom_range(0, 1) ? near(target) : {$urandom, $urandom}; \
    io_fromCsrTrigger_tEnableVec_``I``         = trig_on & ($urandom_range(0, 9) != 0);

  // 一条指令 = 一串 uop：指令级字段（robIdx / fuType / fuOpType / vtype / nf / vl / vstart / mask）在
  // 串内保持不变（后端不会在上一条指令写回前发下一条）；每条 uop 只变 vuopIdx / lastUop / 源操作数。
  logic        inst_robIdx_flag;
  logic [7:0]  inst_robIdx_value;
  logic [34:0] inst_fuType;
  logic [8:0]  inst_fuOpType;
  logic [2:0]  inst_nf, inst_vlmul;
  logic [1:0]  inst_vsew, inst_veew;
  logic        inst_vm;
  logic [7:0]  inst_vl, inst_vstart;
  logic [127:0] inst_mask;
  int          burst_left = 0, burst_idx = 0;

  task automatic new_inst();
    inst_robIdx_flag  = $urandom;
    inst_robIdx_value = $urandom;
    inst_fuType = '0;
    if ($urandom_range(0, 1)) inst_fuType[33] = 1'b1; else inst_fuType[34] = 1'b1;
    if ($urandom_range(0, 31) == 0) inst_fuType = 35'($urandom);
    inst_fuOpType = ($urandom_range(0, 7) == 0) ? 9'h090 : {2'($urandom), 2'($urandom), 5'($urandom_range(0, 1))};
    inst_nf     = ($urandom_range(0, 3) != 0) ? 3'($urandom_range(0, 2)) : 3'($urandom);
    inst_vlmul  = ($urandom_range(0, 7) != 0) ? 3'($urandom_range(5, 11)) : 3'($urandom);
    inst_vsew   = 2'($urandom);
    inst_veew   = 2'($urandom);
    inst_vm     = ($urandom_range(0, 2) == 0);
    inst_vl     = ($urandom_range(0, 15) == 0) ? 8'($urandom_range(0, 255)) : 8'($urandom_range(1, 8));
    inst_vstart = ($urandom_range(0, 7) == 0) ? 8'($urandom_range(0, 6)) : 8'h0;
    inst_mask   = ($urandom_range(0, 3) == 0) ? '1 : {$urandom, $urandom, $urandom, $urandom};
  endtask

  task automatic drive();
    logic [63:0] target;
    logic        trig_on;
    drive_random();
    // ---- 入口 uop ----
    if (burst_left == 0 && u_golden.state == 4'd0 && $urandom_range(0, 3) == 0) begin
      burst_left = $urandom_range(1, 6);
      burst_idx  = 0;
      new_inst();
    end
    io_in_valid = 1'b0;
    if (burst_left > 0 && $urandom_range(0, 3) != 0) begin
      io_in_valid = 1'b1;
      burst_left--;
    end
    io_in_bits_uop_robIdx_flag  = inst_robIdx_flag;
    io_in_bits_uop_robIdx_value = inst_robIdx_value;
    io_in_bits_uop_fuType       = inst_fuType;
    io_in_bits_uop_fuOpType     = inst_fuOpType;
    io_in_bits_uop_vpu_nf       = inst_nf;
    io_in_bits_uop_vpu_vlmul    = inst_vlmul;
    io_in_bits_uop_vpu_vsew     = inst_vsew;
    io_in_bits_uop_vpu_veew     = inst_veew;
    io_in_bits_uop_vpu_vm       = inst_vm;
    io_in_bits_uop_vpu_vstart   = inst_vstart;
    io_in_bits_uop_vpu_vuopIdx  = 7'(burst_idx);
    io_in_bits_uop_vpu_lastUop  = (burst_left == 0);
    io_in_bits_src_4            = 128'(inst_vl);
    io_in_bits_src_3            = inst_mask;
    if (io_in_valid) burst_idx++;
    if ($urandom_range(0, 1)) io_in_bits_src_0[63:4] = '0;                     // 基址偏小，让非对齐 / 跨 16B 常见
    if ($urandom_range(0, 1)) io_in_bits_src_1[127:4] = '0;
    // ---- TLB / PMP ----
    io_dtlb_resp_valid     = ($urandom_range(0, 7) != 0);
    io_dtlb_resp_bits_miss = ($urandom_range(0, 7) == 0);
    io_dtlb_resp_bits_pbmt_0 = ($urandom_range(0, 7) < 6) ? 2'd0 : 2'($urandom);
    io_dtlb_resp_bits_excp_0_gpf_ld = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_gpf_st = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_pf_ld  = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_pf_st  = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_af_ld  = ($urandom_range(0, 255) == 0);
    io_dtlb_resp_bits_excp_0_af_st  = ($urandom_range(0, 255) == 0);
    io_pmpResp_ld   = ($urandom_range(0, 255) == 0);
    io_pmpResp_st   = ($urandom_range(0, 255) == 0);
    io_pmpResp_mmio = ($urandom_range(0, 255) == 0);
    // ---- DCache / sbuffer ----
    io_rdcache_req_ready   = ($urandom_range(0, 3) != 0);
    io_rdcache_resp_valid  = ($urandom_range(0, 7) != 0);
    io_rdcache_resp_bits_miss = ($urandom_range(0, 7) == 0);
    io_rdcache_s2_bank_conflict = ($urandom_range(0, 15) == 0);
    io_rdcache_resp_bits_tl_error_delayed_tl_denied  = ($urandom_range(0, 255) == 0);
    io_rdcache_resp_bits_tl_error_delayed_tl_corrupt = ($urandom_range(0, 255) == 0);
    io_sbuffer_ready       = ($urandom_range(0, 3) != 0);
    io_flush_sbuffer_empty = ($urandom_range(0, 3) != 0);
    io_csrCtrl_cache_error_enable = ($urandom_range(0, 7) != 0);
    // ---- 触发器 ----
    target  = {14'h0, u_golden.dcacheReqVaddr};
    trig_on = ($urandom_range(0, 15) == 0);
    `TRIG_CFG(0)
    `TRIG_CFG(1)
    `TRIG_CFG(2)
    `TRIG_CFG(3)
    io_fromCsrTrigger_debugMode            = ($urandom_range(0, 63) == 0);
    io_fromCsrTrigger_triggerCanRaiseBpExp = ($urandom_range(0, 5) != 0);
  endtask
  task automatic quiesce();
    io_in_valid = 0;
  endtask

`define C u_impl.u_core
'''
COV = [
    ('enq_uop',             1000, '`C.uopEnqueue'),
    ('inst_latch',          200,  '`C.instMicroOp_load'),
    ('fof_fixvl_enq',       50,   '`C.fofBuffer_load'),
    ('st_flush_sbuffer',    200,  '`C.state == 4\'d1'),
    ('st_wait_flush',       50,  '`C.state == 4\'d2'),
    ('st_tlb_req',          1000, '`C.state == 4\'d3'),
    ('st_tlb_miss_retry',   100,  '(`C.state == 4\'d4) & io_dtlb_resp_valid & io_dtlb_resp_bits_miss'),
    ('st_pm',               1000, '`C.state == 4\'d5'),
    ('st_cache_req',        500,  '`C.state == 4\'d6'),
    ('st_cache_retry',      50,  '(`C.state == 4\'d7) & io_rdcache_resp_valid & (io_rdcache_resp_bits_miss | io_rdcache_s2_bank_conflict)'),
    ('st_misalign_merge',   30,   '`C.state == 4\'d8'),
    ('st_latch_merge',      500,  '`C.state == 4\'d9'),
    ('st_send_data',        500,  '`C.state == 4\'d10'),
    ('st_wait_to_sbuffer',  20,   '`C.state == 4\'d11'),
    ('st_finish',           500,  '`C.state == 4\'d12'),
    ('st_fof_fix_vl',       20,   '`C.state == 4\'d13'),
    ('seg_inactive',        200,  '(`C.state == 4\'d3) & ~`C.segmentActive'),
    ('misalign_detected',   100,  '(`C.state == 4\'d5) & `C.isMisalignWire & ~`C.anyException'),
    ('misalign_cross16',    50,   '(`C.state == 4\'d5) & `C.isMisalignWire & ~`C.notCross16ByteWire & ~`C.anyException'),
    ('load_second_half',    10,   '(`C.state == 4\'d8) & `C.curPtr'),
    ('store_second_half',   10,   '(`C.state == 4\'d10) & `C.isMisalignReg & ~`C.notCross16ByteReg & `C.curPtr & `C.sbufferOut_fire'),
    ('exception_va',        50,   '`C.exception_va'),
    ('exception_gpa',       5,   '`C.exception_gpa'),
    ('exception_pa',        10,   '`C.exception_pa'),
    ('cache_error',         3,   '`C.cacheRespError'),
    ('fof_suppressed_exc',  2,   '(`C.state == 4\'d5) & `C.anyException & ~`C.canTriggerException'),
    ('trigger_breakpoint',  5,   '(`C.state == 4\'d5) & `C.triggerBreakpoint'),
    ('trigger_debugmode',   5,   '(`C.state == 4\'d5) & `C.triggerDebugMode'),
    ('indexed_inst',        300,  '(`C.state == 4\'d3) & `C.issueIsIndexed'),
    ('strided_inst',        300,  '(`C.state == 4\'d3) & (`C.instMicroOp_uop_q.fuOpType[6:5] == 2\'b10)'),
    ('multi_field',         300,  '(`C.state == 4\'d3) & (`C.fieldIdx != 4\'d0)'),
    ('writeback',           500,  '`C.writebackValid'),
    ('writeback_fof',       20,   '`C.fofFixVlValid'),
    ('feedback',            500,  '`C.feedbackValid'),
    ('exception_info',      50,   '`C.exceptionInfo_valid'),
    ('split_ptr_next_seg',  200,  '(`C.state == 4\'d9) & (`C.fieldDone | ~`C.segmentActive)'),
    ('queue_wrap',          100,  '`C.uopEnqueue & (`C.enqPtr_value == 3\'d7)'),
]


def build():
    res = {}
    pkg = PKG.read_text() if PKG.exists() else PKG_HEAD
    rtl = RTL.read_text()
    rtl = X.replace_region(rtl, 'core_ports', X.emit_core_ports(PLIST))
    rtl = X.replace_region(rtl, 'trigger', gen_trigger())
    rtl = X.replace_region(rtl, 'pipe', gen_pipe())
    rtl = X.replace_region(rtl, 'wrapper', gen_wrapper())
    for _ in range(2):
        rtl = X.replace_region(rtl, 'nav', X.gen_nav(rtl, NAV))
    pkg = X.replace_region(pkg, 'types', TS.emit())
    errs = []
    code = X.strip_comments(rtl)
    core = re.search(r'module xs_VSegmentUnit_core\b(.*?)\nendmodule', code, re.S)
    hand = X.nb_assigned(core.group(1)) if core else set()
    want = set(G.regs) - GEN_REGS
    errs += ['golden 寄存器 %s 在核手写区没有同名寄存器' % n for n in sorted(want - hand)]
    errs += ['核手写区的寄存器 %s 不在 golden 寄存器表里' % n for n in sorted(hand - want)]
    for name, t in (('VSegmentUnit.sv', rtl), ('vsegment_pkg.sv', pkg)):
        if X.has_firtool_names(t):
            errs.append('%s: 代码区出现 firtool 展平中间名' % name)
    if errs:
        X.die('\n  '.join(['机械核对未通过：'] + errs))
    hand_tb = TB_HAND + '\n' + X.tb_cov_block(COV) + X.TB_MAIN.replace('@MOD@', MOD)
    nout = sum(1 for d, w, n in G.ports if d == 'output')
    tb, _ = X.emit_tb(G, TB_HEAD % {'nout': nout}, hand_tb)
    res[RTL] = rtl
    res[PKG] = pkg
    res[TB] = tb
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
            print('gen_vsegmentunit --check: DRIFT ' + ', '.join(bad))
            return 1
        print('gen_vsegmentunit --check: OK（%d 端口 / %d 寄存器 = 生成 %d + 手写 %d）'
              % (len(G.ports), len(G.regs), len(GEN_REGS), len(G.regs) - len(GEN_REGS)))
        return 0
    print('gen_vsegmentunit: 已生成（%d 端口 / %d 寄存器 = 生成 %d + 手写 %d）'
          % (len(G.ports), len(G.regs), len(GEN_REGS), len(G.regs) - len(GEN_REGS)))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_tb.py —— 生成 Slice 家族 UT 的 tb.sv：四对（golden Slice/_1/_2/_3 vs 重写 Slice*_xs）同激励逐拍比对。

端口表从 golden 解析；激励偏置写在 drive_expr 里。

★未复位寄存器的初值同步表是从各 child 自己的 UT tb 机械收割的★（不重写规则）：
child 单独签核时，tb 在首个时钟沿前把 golden 侧未复位寄存器 / 存储阵列的初值 force（或直接赋给
存储阵列）到重写侧。放进 Slice 后对象不变，只多一层路径：golden 侧 u_g<k>.<inst>.，重写侧
u_i<k>.u_core.<inst>.（目录 / 数据阵列 / MBIST 分发在 wrapper 里：u_i<k>.<inst>.）。
收割源与实例的对应见 CHILD_TBS；TXREQ / TXRSP 的 UT 只跑过 initreg 0 档、没有同步表，
这里补上它们队列存储（两侧都是 golden 的 ram_16x137 / ram_16x62）的拷贝（MANUAL_SYNC）。

用法: python3 gen_tb.py [--check]
"""
import os
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
UT = HERE.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN', '/home/eda/xs-env/G1-canonical/golden-rtl'))
VARIANTS = ['Slice', 'Slice_1', 'Slice_2', 'Slice_3']
SFX = {'Slice': '', 'Slice_1': '_1', 'Slice_2': '_2', 'Slice_3': '_3'}
WRAP_INSTS = ('directory', 'dataStorage', 'mbistPl')

# (child UT 目录, tb 里的实例后缀（u_g<后缀> / u_i<后缀>）, 本层实例名)；后缀里的 {s} = 变体后缀
CHILD_TBS = [
    ('MSHRCtl', '', 'mshrCtl'),
    ('MainPipe_1', '_MainPipe_1', 'mainPipe'),
    ('GrantBuffer', '_GrantBuffer', 'grantBuf'),
    ('RXSNP', '_RXSNP', 'rxsnp'),
    ('RequestBuffer', '_RequestBuffer', 'reqBuf'),
    ('SinkC', '_SinkC', 'sinkC'),
    ('RequestArb', '_RequestArb', 'reqArb'),
    ('MSHRBuffer', '_MSHRBuffer', 'refillBuf'),
    ('MSHRBuffer', '_MSHRBuffer_1', 'releaseBuf'),
    ('TXDAT', '_TXDAT', 'txdat'),
    ('Directory', '_Directory{s}', 'directory'),
    ('DataStorage', '_DataStorage{s}', 'dataStorage'),
    ('L2Slice', '_L2Slice{s}', 'mbistPl'),
]
# (golden 相对路径, 重写相对路径, 是否 force)；重写路径相对 u_i<k>
MANUAL_SYNC = [
    ('txreq.queue.ram_ext.Memory', 'u_core.txreq.u_core.queue.ram_ext.Memory', False),
    ('txrsp.queue.ram_ext.Memory', 'u_core.txrsp.u_core.queue.ram_ext.Memory', False),
] + [(r, 'u_core.' + r, True) for r in
     ['io_error_bits_REG_valid', 'io_error_bits_REG_address'] +
     ['io_perf_%d_value_REG%s' % (k, s) for k in [0, 1] + list(range(3, 17)) for s in ('', '_1')]]

# 覆盖探针（golden Slice 层的线 / 端口；golden 已冻结，探针不会腐烂）：任何一项为 0 即判 FAILED
COVER = [
    ('A 收下', 'io_in_a_valid & io_in_a_ready'),
    ('C 收下', 'io_in_c_valid & io_in_c_ready'),
    ('D 发出', 'io_in_d_valid & io_in_d_ready'),
    ('B(Probe) 发出', 'io_in_b_valid & io_in_b_ready'),
    ('E 收下', 'io_in_e_valid'),
    ('TXREQ 发出', 'io_out_tx_req_valid & io_out_tx_req_ready'),
    ('TXRSP 发出', 'io_out_tx_rsp_valid & io_out_tx_rsp_ready'),
    ('TXDAT 发出', 'io_out_tx_dat_valid & io_out_tx_dat_ready'),
    ('RXSNP 收下', 'io_out_rx_snp_valid & io_out_rx_snp_ready'),
    ('MSHR 分配', '_mainPipe_io_toMSHRCtl_mshr_alloc_s3_valid'),
    ('目录命中', '_directory_io_resp_valid & _directory_io_resp_bits_hit'),
    ('目录缺失', '_directory_io_resp_valid & ~_directory_io_resp_bits_hit'),
    ('MSHR 全占', 'io_msStatus_15_valid & io_msStatus_0_valid'),
    ('releaseBuf 写(MainPipe)', '_mainPipe_io_releaseBufWrite_valid'),
    ('refillBuf 写(RXDAT)', '_rxdat_io_refillBufWrite_valid'),
    ('数据阵列写', '_mainPipe_io_toDS_en_s3 & _mainPipe_io_toDS_req_s3_bits_wen'),
    ('L1 hint', 'io_l1Hint_valid'),
    ('预取 train', 'io_prefetch_train_valid'),
    ('预取 resp', 'io_prefetch_resp_valid'),
    ('预取 sent', 'io_pfSent_valid'),
    ('L2 miss', 'io_l2Miss'),
    ('dirResult', 'io_dirResult_valid'),
    ('MBIST ack', 'boreChildrenBd_bore_ack'),
]


def ports(top):
    src = (GOLDEN / (top + '.sv')).read_text()
    m = re.search(r'^module %s\(\n(.*?)\n\);\n' % top, src, re.S | re.M)
    out = []
    for ln in m.group(1).split('\n'):
        mm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\]\s+)?(\w+),?\s*$', ln)
        out.append((mm.group(1), int(mm.group(2)) + 1 if mm.group(2) else 1, mm.group(3)))
    return out


SYNC_RE = re.compile(r'^\s*(force\s+)?u_i(\w*)\.(\S+)\s*=\s*u_g(\w*)\.(\S+?)\s*;\s*$')


def harvest(var):
    """返回 [(golden 相对路径, 重写相对路径, force?)]，相对 u_g<k> / u_i<k>。"""
    out = []
    for ut, sfx, inst in CHILD_TBS:
        sfx = sfx.format(s=SFX[var])
        text = (UT / ut / 'tb.sv').read_text()
        n = 0
        for ln in text.split('\n'):
            m = SYNC_RE.match(ln)
            if not m or m.group(2) != sfx or m.group(4) != sfx:
                continue
            ipath = inst if inst in WRAP_INSTS else 'u_core.' + inst
            out.append(('%s.%s' % (inst, m.group(5)), '%s.%s' % (ipath, m.group(3)), bool(m.group(1))))
            n += 1
        if n == 0:
            # 每个收割源至少要收到一条（否则多半是 tb 改了实例名，收割悄悄变空）
            raise SystemExit('从 %s/tb.sv 按后缀 %r 没收割到任何同步行' % (ut, sfx))
    out += MANUAL_SYNC
    if len({i for _, i, _ in out}) != len(out):
        raise SystemExit('%s: 同步表重写侧有重复' % var)
    return out


def drive_expr(name, w):
    """每个输入每拍的取值（偏置规则）。"""
    if name == 'io_in_a_valid':
        return '($urandom_range(0, 3) == 0)'
    if name == 'io_in_a_bits_opcode':
        return 'pick_a_opcode()'
    if name in ('io_in_a_bits_address', 'io_in_c_bits_address'):
        return 'pick_addr()'
    if name == 'io_in_a_bits_size' or name == 'io_in_c_bits_size':
        return "($urandom_range(0, 7) == 0) ? 3'($urandom) : 3'h6"
    if name in ('io_in_a_bits_source', 'io_in_c_bits_source', 'io_prefetch_req_bits_source'):
        return "7'($urandom_range(0, 7))"
    if name == 'io_in_c_valid':
        return '($urandom_range(0, 9) == 0)'
    if name == 'io_in_c_bits_opcode':
        return "($urandom_range(0, 9) == 0) ? 3'($urandom) : 3'($urandom_range(4, 7))"
    if name == 'io_in_e_valid':
        return '($urandom_range(0, 4) == 0)'
    if name == 'io_in_e_bits_sink':
        return "8'($urandom_range(0, 16))"
    if name == 'io_prefetch_req_valid':
        return '($urandom_range(0, 15) == 0)'
    if name == 'io_prefetch_req_bits_tag':
        return "33'($urandom_range(0, 15))"
    if name == 'io_prefetch_req_bits_set':
        return "9'($urandom_range(0, 3))"
    if name == 'io_out_rx_rsp_valid' or name == 'io_out_rx_dat_valid':
        return '(slow_phase() ? ($urandom_range(0, 31) == 0) : ($urandom_range(0, 3) == 0))'
    if name == 'io_out_rx_snp_valid':
        return '($urandom_range(0, 9) == 0)'
    if name in ('io_out_rx_rsp_bits_txnID', 'io_out_rx_dat_bits_txnID'):
        return "12'($urandom_range(0, 15))"   # 实际 txnID 由 pick_target 改写
    if name == 'io_out_rx_rsp_bits_opcode':
        return "pick_rsp_opcode()"
    if name == 'io_out_rx_dat_bits_opcode':
        return "($urandom_range(0, 7) == 0) ? 4'($urandom) : (($urandom_range(0, 3) == 0) ? 4'hB : 4'h4)"
    if name == 'io_out_rx_dat_bits_dataID':
        return "2'($urandom_range(0, 1)) << 1"
    if name in ('io_out_rx_rsp_bits_respErr', 'io_out_rx_dat_bits_respErr'):
        return "($urandom_range(0, 15) == 0) ? 2'($urandom) : 2'h0"
    if name == 'io_out_rx_dat_bits_poison':
        return "($urandom_range(0, 15) == 0) ? 4'($urandom) : 4'h0"
    if name == 'io_out_rx_snp_bits_opcode':
        return "($urandom_range(0, 3) == 0) ? 5'($urandom) : 5'($urandom_range(1, 10))"
    if name == 'io_out_rx_snp_bits_addr':
        return 'pick_addr() >> 3'
    if name in ('io_out_rx_rsp_bits_srcID', 'io_out_rx_dat_bits_homeNID', 'io_out_rx_snp_bits_srcID'):
        # 节点号压到 0..1：RetryAck 记下的 srcID 才会被后续 PCrdGrant 匹配上（否则 MSHR 卡在 reissue）
        return "($urandom_range(0, 15) == 0) ? 11'($urandom) : 11'($urandom_range(0, 1))"
    if name.startswith('io_pCrd_') and name.endswith('_grant'):
        # 只在 MSHR 真的在查询 P-Credit 时给（上层 PCrd 队列的行为）；乱给会让 MSHR 在没收到
        # RetryAck 时就清掉 s_reissue，永远卡住。查询状态取第 0 对 golden 的输出（四对激励相同）。
        k = name[len('io_pCrd_'):-len('_grant')]
        return "g0_io_pCrd_%s_query_valid && ($urandom_range(0, 3) == 0)" % k
    if name in ('io_in_a_bits_corrupt', 'io_in_c_bits_corrupt'):
        return '($urandom_range(0, 31) == 0)'
    if name.startswith('sigFromSrams_'):
        return '($urandom_range(0, 63) == 0)'
    if name == 'boreChildrenBd_bore_req':
        return "mbist_phase() ? 1'b1 : ($urandom_range(0, 255) == 0)"
    if name in ('boreChildrenBd_bore_all', 'boreChildrenBd_bore_writeen', 'boreChildrenBd_bore_readen'):
        return "mbist_phase() ? 1'($urandom) : ($urandom_range(0, 255) == 0)"
    if name == 'boreChildrenBd_bore_array':
        return "6'($urandom)"   # tb 侧按最宽变体（6 位）声明，各对截到自己的位宽
    if name.endswith('_ready'):
        return '($urandom_range(0, 9) < 8)'
    if w <= 32:
        return "%d'($urandom)" % w
    return "%d'({%s})" % (w, ', '.join(['$urandom'] * ((w + 31) // 32)))


def tb():
    base = ports('Slice')
    ins = [(w, n) for d, w, n in base if d == 'input' and n not in ('clock', 'reset')]
    outs = [(w, n) for d, w, n in base if d == 'output']
    syncs = {v: harvest(v) for v in VARIANTS}
    bdw = {v: {n: w for _, w, n in ports(v)}['boreChildrenBd_bore_array'] for v in VARIANTS}
    L = []
    A = L.append
    A('// =============================================================================')
    A('// tb —— Slice 家族 UT：golden Slice/_1/_2/_3 与重写 Slice*_xs 四对双例化，同激励逐拍比对')
    A('//       每对全部 %d 个输出（4 态 !==）。' % len(outs))
    A('//')
    A('// 激励（每拍全部输入重摇，偏置见 gen_tb.py 的 drive_expr）：')
    A('//   · 地址压到 tag 0..15 × set 0..3（A/C/snoop/预取同一地址域），让命中、替换、同 set 冲突、')
    A('//     snoop 撞在途 MSHR 真正发生；A opcode 偏向 Get/Hint/AcquireBlock/AcquirePerm，C 偏向')
    A('//     ProbeAck/ProbeAckData/Release/ReleaseData；RXDAT/RXRSP 的 txnID 偏向 0..15（= mshrId）、')
    A('//     opcode 偏向 CompData/DataSepResp 与 RetryAck..ReadReceipt；snoop opcode 偏向 1..10；')
    A('//   · CHI 节点号（srcID/homeNID）压到 0..1；P-Credit grant 只在对应 MSHR 查询时给（1/4 概率）；')
    A('//     RXDAT/RXRSP 只发给处在对应等待状态的 MSHR（pick_target）；E 通道 sink 取 0..16；')
    A('//   · 每 4000 拍一轮三个阶段：常速 2000 拍 / 下游慢 1000 拍（RXDAT/RXRSP 1/32，逼 MSHR 全占）/')
    A('//     MBIST 窗口 1000 拍（bore req 持续拉高）；SRAM hold/bypass 低频翻；约 1/20000 拍一次异步复位。')
    A('// 厂商 SRAM 叶子（array_*_ext）的存储体：编译带 +define+RANDOMIZE_MEM_INIT，由叶子自带的 initial')
    A('//   块填随机值（模拟上电垃圾；不填则 tag/数据读出全 X、流水在 X 上停摆、比对 X===X 空过），')
    A('//   再随同步表拷到重写侧。')
    A('// 未复位寄存器 / 存储阵列：+vcs+initreg+random 下两侧初值不同，tb 在首个时钟沿前把 golden 侧')
    A('//   初值同步到重写侧（表从各 child 的 UT tb 机械收割，见 gen_tb.py 文件头）；有复位的不同步。')
    A('// 覆盖：一组 golden 内部事件各自为真的拍数（只计 Slice 那一对），任何一项为 0 即判 TEST FAILED。')
    A('//')
    A('// 本文件由 verif/ut/Slice/gen_tb.py 生成，勿手改。')
    A('// =============================================================================')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clock = 0; always #5 clock = ~clock;')
    A('  logic reset;')
    A('  longint errors = 0, checks = 0;')
    A('  longint cyc = 0;')
    A('  // 阶段：每 4000 拍一轮 —— [0,2000) 常速；[2000,3000) 下游慢（RXDAT/RXRSP 1/32），逼 MSHR 全占；')
    A('  //        [3000,4000) MBIST 窗口（bore req 持续拉高、array/读写随机），让 MBIST 分发真正握手。')
    A('  function automatic bit slow_phase();  return (cyc % 4000) >= 2000 && (cyc % 4000) < 3000; endfunction')
    A('  function automatic bit mbist_phase(); return (cyc % 4000) >= 3000; endfunction')
    A('')
    for w, n in ins:
        if n == 'boreChildrenBd_bore_array':
            w = max(bdw.values())
        A('  logic %s%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', n))
    for k, v in enumerate(VARIANTS):
        for w, n in outs:
            A('  logic %sg%d_%s, i%d_%s;' % ('[%d:0] ' % (w - 1) if w > 1 else '', k, n, k, n))
    A('')
    for k, v in enumerate(VARIANTS):
        for side, mod in (('g', v), ('i', v + '_xs')):
            A('  %s u_%s%d (' % (mod, side, k))
            conns = ['    .clock(clock)', '    .reset(reset)']
            for d, w, n in base:
                if n in ('clock', 'reset'):
                    continue
                if d == 'input':
                    e = n
                    if n == 'boreChildrenBd_bore_array':
                        e = "%d'(%s)" % (bdw[v], n)
                else:
                    e = '%s%d_%s' % (side, k, n)
                    if n == 'boreChildrenBd_bore_array':
                        raise SystemExit('bore_array 不该是输出')
                conns.append('    .%s(%s)' % (n, e))
            A(',\n'.join(conns))
            A('  );')
    A('')
    A('  function automatic logic [3:0] pick_a_opcode();')
    A('    case ($urandom_range(0, 9))')
    A("      0, 1: return 4'h4;  2: return 4'h5;  3, 4, 5: return 4'h6;  6, 7: return 4'h7;")
    A("      default: return 4'($urandom);")
    A('    endcase')
    A('  endfunction')
    A('  // 地址 = {tag 31 位, set 9 位, bank 2 位, offset 6 位}；tag 压到 0..15（> 8 路，逼出替换）、set 0..3')
    A('  function automatic logic [47:0] pick_addr();')
    A("    return {31'($urandom_range(0, 15)), 9'($urandom_range(0, 3)), 2'($urandom),")
    A("            ($urandom_range(0, 7) == 0) ? 6'($urandom) : 6'h0};")
    A('  endfunction')
    A('')
    A('  // RXRSP opcode：RetryAck 3 / Comp 4 / CompDBIDResp 5 / DBIDResp 6 / PCrdGrant 7 / ReadReceipt 8 /')
    A('  //               RespSepData B，另 1/8 全随机')
    A('  function automatic logic [4:0] pick_rsp_opcode();')
    A("    case ($urandom_range(0, 7))")
    A("      0: return 5'h3;  1: return 5'h4;  2: return 5'h5;  3: return 5'h6;")
    A("      4: return 5'h8;  5: return 5'hB;  6: return 5'h7;  default: return 5'($urandom);")
    A('    endcase')
    A('  endfunction')
    A('  // CHI 响应只发给"合法"的 MSHR（看 golden 第 0 对的 MSHR 状态；四对激励相同）：')
    A('  //   kind 0 = RXDAT（CompData/DataSepResp）：数据没收齐（!w_grantlast）且没被 retry；')
    A('  //   kind 1 = RetryAck：请求已发出、还没收到任何响应（读：!w_grantfirst && !w_grant；写：!w_releaseack）；')
    A('  //   kind 2 = 其余 RXRSP：还在等响应（!w_grant 或 !w_releaseack）且没被 retry。')
    A('  // 乱发会把 MSHR 推进不可能的状态（例如拿到数据后又被 retry、retry 后又来数据）而永不释放，')
    A('  // 整个 slice 随之停摆 —— 真实 CHI 下这些序列不会出现。没有合法对象时本拍不发（valid=0）。')
    A('  function automatic int pick_target(input int kind);')
    A('    int c[$];')
    for k in range(16):
        m = 'u_g0.mshrCtl.mshrs_%d.' % k
        A('    if (%sreq_valid && !%sgotRetryAck && (' % (m, m))
        A('          kind == 0 ? !%sstate_w_grantlast :' % m)
        A('          kind == 1 ? (%sstate_s_acquire && !%sstate_w_grantfirst && !%sstate_w_grant ||' % (m, m, m))
        A('                       %sstate_s_release && !%sstate_w_releaseack) :' % (m, m))
        A('                      (!%sstate_w_grant || !%sstate_w_releaseack))) c.push_back(%d);' % (m, m, k))
    A('    if (c.size() == 0) return -1;')
    A('    return c[$urandom_range(0, c.size() - 1)];')
    A('  endfunction')
    A('')
    A('  task automatic drive();')
    for w, n in ins:
        A('    %s = %s;' % (n, drive_expr(n, w)))
    A('    if (io_out_rx_dat_valid) begin')
    A('      automatic int t = pick_target(0);')
    A("      if (t < 0) io_out_rx_dat_valid = 1'b0; else io_out_rx_dat_bits_txnID = 12'(t);")
    A('    end')
    A("    if (io_out_rx_rsp_valid && io_out_rx_rsp_bits_opcode != 5'h7) begin   // PCrdGrant 不带 txnID 语义")
    A("      automatic int t = pick_target(io_out_rx_rsp_bits_opcode == 5'h3 ? 1 : 2);")
    A("      if (t < 0) io_out_rx_rsp_valid = 1'b0; else io_out_rx_rsp_bits_txnID = 12'(t);")
    A('    end')
    A("    reset = ($urandom_range(0, 19999) == 0);")
    A('  endtask')
    A('')
    A('  `define CK(k, nm) begin checks++; if (g``k``_``nm !== i``k``_``nm) begin errors++; \\')
    A('    if (errors <= 40) $display("[cycle %0d] MISMATCH pair%0d %s golden=%h impl=%h", cyc, k, `"nm`", \\')
    A('                               g``k``_``nm, i``k``_``nm); \\')
    A('    end end')
    A('  task automatic check();')
    for k in range(len(VARIANTS)):
        for w, n in outs:
            A('    `CK(%d, %s)' % (k, n))
    A('  endtask')
    A('')
    A('  longint cov [%d];' % len(COVER))
    A("  localparam string COV_NAME [%d] = '{%s};" % (len(COVER), ', '.join('"%s"' % c for c, _ in COVER)))
    A('  task automatic sample();')
    for k, (_, expr) in enumerate(COVER):
        e = re.sub(r'(~?)(\b[A-Za-z_]\w*)', lambda m: '%su_g0.%s' % (m.group(1), m.group(2)), expr)
        A('    if (%s) cov[%d]++;' % (e, k))
    A('  endtask')
    A('')
    A('  task automatic sync_init();')
    for k, v in enumerate(VARIANTS):
        for g, i, frc in syncs[v]:
            if frc:
                A('    force u_i%d.%s = u_g%d.%s;' % (k, i, k, g))
            else:
                A('    u_i%d.%s = u_g%d.%s;' % (k, i, k, g))
    A('    #1;')
    for k, v in enumerate(VARIANTS):
        for g, i, frc in syncs[v]:
            if frc:
                A('    release u_i%d.%s;' % (k, i))
    A('  endtask')
    A('')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;')
    A('    foreach (cov[k]) cov[k] = 0;')
    A("    drive(); reset = 1'b1;")
    A('    #1;')
    A('    sync_init();          // 未复位寄存器两侧同初值（见文件头）')
    A('    repeat (8) @(posedge clock);')
    A("    #1; drive(); reset = 1'b0;")
    A('    repeat (NCYCLES) begin')
    A('      @(posedge clock); #1; cyc++;')
    A('      check(); sample(); drive();')
    A('    end')
    A('    begin')
    A('      int zero = 0;')
    A('      foreach (cov[k]) begin')
    A('        $display("COVER %-24s %0d", COV_NAME[k], cov[k]);')
    A('        if (cov[k] == 0) zero++;')
    A('      end')
    A('      $display("checks=%0d errors=%0d cover_zero=%0d", checks, errors, zero);')
    A('      if (errors == 0 && zero == 0) $display("TEST PASSED");')
    A('      else $display("TEST FAILED");')
    A('    end')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'


def main():
    new = tb()
    p = HERE / 'tb.sv'
    cur = p.read_text() if p.exists() else None
    if '--check' in sys.argv[1:]:
        if cur != new:
            print('gen_tb(Slice): DRIFT tb.sv')
            return 1
        print('gen_tb(Slice): OK')
        return 0
    if cur != new:
        p.write_text(new)
        print('gen_tb(Slice): 更新 tb.sv')
    else:
        print('gen_tb(Slice): 已是最新')
    return 0


if __name__ == '__main__':
    sys.exit(main())

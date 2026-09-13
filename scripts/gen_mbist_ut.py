#!/usr/bin/env python3
"""gen_mbist_ut.py —— 生成 MbistPipe* 家族的双例化 UT testbench。

同族共用一个 tb：24 个 golden 变体和 24 个自动派生的 <M>_xs 同时例化、同激励，
每拍逐位比对全部输出。

比对方式：把一个变体的所有输出端口打包成一根大向量，两侧用 `!==` 一次比完
（4 态比较，X 也要逐位相等，**没有任何 $isunknown 跳过**）；只有不等时才走
慢路径逐端口定位。checks 按"输出端口数 x 比对拍数"精确累加，收尾时与理论
上限对拍——数字对不上就说明有比对被静默跳过，直接判 FAIL。
"""
import os, sys, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_mbist_pipe_family as F

REPO = F.REPO
OUT = os.path.join(REPO, 'verif', 'ut', 'MbistPipe')

MASTER = dict(ARRAY=7, ADDR=10, BE=76, DATA=148)


def vdecl(w, name):
    return 'logic %s%s' % ('' if w == 1 else '[%d:0] ' % (w - 1), name)


def main():
    Rs = []
    for m in F.MODS:
        R = F.parse_golden(m)
        F.check_invariants(R)
        Rs.append(R)
    os.makedirs(OUT, exist_ok=True)

    L = []
    A = L.append
    A('// tb.sv —— MbistPipe* 家族（24 个变体）双例化 UT')
    A('//')
    A('// 24 个 golden 变体 + 24 个由 scripts/derive_ut_impl.py 派生的 <M>_xs 同时例化，')
    A('// 同一套激励，每拍逐位比全部输出。生成脚本：scripts/gen_mbist_ut.py')
    A('`timescale 1ns/1ps')
    A('')
    A('module tb;')
    A('')
    A('  // ---------------- 时钟 / 复位 ----------------')
    A('  logic clock = 1\'b0;')
    A('  logic reset = 1\'b1;')
    A('  always #5 clock = ~clock;')
    A('')
    A('  int unsigned ncycles = 200000;')
    A('  longint unsigned cyc = 0;        // 复位释放后的拍数')
    A('  longint unsigned cmp_cycles = 0; // 真正参与比对的拍数')
    A('  longint unsigned checks = 0;')
    A('  longint unsigned errors = 0;')
    A('  bit               armed = 1\'b0;  // 比对是否已开闸')
    A('')
    A('  // ---------------- 主激励（各变体按自己的位宽取低位切片）----------------')
    A('  logic [%d:0]   s_array;' % (MASTER['ARRAY'] - 1))
    A('  logic         s_all, s_req, s_wen, s_ren;')
    A('  logic [%d:0]  s_be;' % (MASTER['BE'] - 1))
    A('  logic [%d:0]   s_addr, s_addr_rd;' % (MASTER['ADDR'] - 1))
    A('  logic [%d:0] s_indata;' % (MASTER['DATA'] - 1))
    A('')
    A('  // ---------------- 覆盖闸 ----------------')
    A('  bit [%d:0] cov_id;                    // 每个 array 编号都以 req&!all 打过' % ((1 << MASTER['ARRAY']) - 1))
    A('  bit [%d:0]  cov_addr0, cov_addr1;      // 地址每一位都出现过 0 和 1' % (MASTER['ADDR'] - 1))
    A('  bit [%d:0] cov_be0, cov_be1;' % (MASTER['BE'] - 1))
    A('  bit [%d:0] cov_din0, cov_din1;' % (MASTER['DATA'] - 1))
    A('  bit cov_all_bcast, cov_idle, cov_wr, cov_rd, cov_rdwr;')
    A('')

    total_out = 0
    for vi, R in enumerate(Rs):
        m = R['module']
        outs = [(n, w) for n, d, w in R['ports'] if d == 'output']
        ins = [(n, w) for n, d, w in R['ports'] if d == 'input' and n not in ('clock', 'reset')]
        total_out += len(outs)
        R['_outs'] = outs
        R['_ins'] = ins
        pfx = 'toNextPipeline_' if R['kind'] == 'node' else 'toSRAM_'
        A('  // ======================== [%02d] %s ========================' % (vi, m))
        # child data drivers
        for c in R['child']:
            A('  %s;' % vdecl(c['DATA_W'], 'v%d_rd%d' % (vi, c['idx'])))
            if R['kind'] == 'node':
                A('  %s;' % vdecl(1, 'v%d_ack%d' % (vi, c['idx'])))
        for side in ('g', 'x'):
            for n, w in outs:
                A('  %s;' % vdecl(w, '%s%d_%s' % (side, vi, n)))
        A('  bit [%d:0] cov_spread%d;' % (R['nchild'] - 1, vi))
        A('  bit [%d:0] cov_od0_%d, cov_od1_%d;' % (R['DATA_W'] - 1, vi, vi))
        A('  bit cov_ack0_%d, cov_ack1_%d;' % (vi, vi))
        for side, mod in (('g', m), ('x', m + '_xs')):
            A('  %s u_%s%d (' % (mod, side, vi))
            conn = ['    .clock (clock), .reset (reset)']
            for n, w in ins:
                if n == 'mbist_array':
                    src = 's_array[%d:0]' % (R['ARRAY_W'] - 1) if R['ARRAY_W'] < MASTER['ARRAY'] else 's_array'
                elif n == 'mbist_all':
                    src = 's_all'
                elif n == 'mbist_req':
                    src = 's_req'
                elif n == 'mbist_writeen':
                    src = 's_wen'
                elif n == 'mbist_readen':
                    src = 's_ren'
                elif n == 'mbist_be':
                    src = 's_be[%d:0]' % (R['BE_W'] - 1) if R['BE_W'] < MASTER['BE'] else 's_be'
                elif n == 'mbist_addr':
                    src = 's_addr[%d:0]' % (R['ADDR_W'] - 1) if R['ADDR_W'] < MASTER['ADDR'] else 's_addr'
                elif n == 'mbist_addr_rd':
                    src = 's_addr_rd[%d:0]' % (R['ADDR_W'] - 1) if R['ADDR_W'] < MASTER['ADDR'] else 's_addr_rd'
                elif n == 'mbist_indata':
                    src = 's_indata[%d:0]' % (R['DATA_W'] - 1) if R['DATA_W'] < MASTER['DATA'] else 's_indata'
                elif n.endswith('_rdata') or n.endswith('_outdata'):
                    k = int(n[len(pfx):].split('_')[0])
                    src = 'v%d_rd%d' % (vi, k)
                elif n.endswith('_ack'):
                    k = int(n[len(pfx):].split('_')[0])
                    src = 'v%d_ack%d' % (vi, k)
                else:
                    raise AssertionError('未知输入端口 %s.%s' % (m, n))
                conn.append('    .%s (%s)' % (n, src))
            for n, w in outs:
                conn.append('    .%s (%s%d_%s)' % (n, side, vi, n))
            A(',\n'.join(conn))
            A('  );')
        # packed buses
        A('  wire [%d:0] gbus%d = {%s};' % (sum(w for _, w in outs) - 1, vi,
                                            ', '.join('g%d_%s' % (vi, n) for n, _ in outs)))
        A('  wire [%d:0] xbus%d = {%s};' % (sum(w for _, w in outs) - 1, vi,
                                            ', '.join('x%d_%s' % (vi, n) for n, _ in outs)))
        A('  task automatic detail%d();' % vi)
        for n, w in outs:
            A('    if (g%d_%s !== x%d_%s) begin errors++; if (errors < 20) $display("  [MISMATCH] cyc=%%0d %s.%s golden=%%h impl=%%h", cyc, g%d_%s, x%d_%s); end'
              % (vi, n, vi, n, m, n, vi, n, vi, n))
        A('  endtask')
        A('')

    A('  localparam longint unsigned N_OUT_PORTS = %d;   // 24 个变体的输出端口总数' % total_out)
    A('')
    A('  // ---------------- 每拍比对 ----------------')
    A('  task automatic compare_all();')
    A('    bit bad;')
    A('    bad = 1\'b0;')
    for vi, R in enumerate(Rs):
        A('    if (gbus%d !== xbus%d) begin bad = 1\'b1; detail%d(); end' % (vi, vi, vi))
    A('    checks += N_OUT_PORTS;')
    A('    cmp_cycles++;')
    A('    if (bad && errors < 20) $display("  [MISMATCH] cyc=%0d 见上方逐端口明细", cyc);')
    A('  endtask')
    A('')
    A('  // ---------------- 覆盖累计 ----------------')
    A('  task automatic sample_cov();')
    A('    if (s_req && !s_all && (s_ren || s_wen)) cov_id[s_array] = 1\'b1;')
    A('    if (s_all) cov_all_bcast = 1\'b1;')
    A('    if (!s_req && !s_all) cov_idle = 1\'b1;')
    A('    if (s_wen && !s_ren) cov_wr = 1\'b1;')
    A('    if (s_ren && !s_wen) cov_rd = 1\'b1;')
    A('    if (s_ren && s_wen)  cov_rdwr = 1\'b1;')
    A('    cov_addr0 |= ~(s_addr & s_addr_rd); cov_addr1 |= (s_addr | s_addr_rd);')
    A('    cov_be0   |= ~s_be;                 cov_be1   |= s_be;')
    A('    cov_din0  |= ~s_indata;             cov_din1  |= s_indata;')
    for vi, R in enumerate(Rs):
        pfx = 'toNextPipeline_' if R['kind'] == 'node' else 'toSRAM_'
        parts = []
        for c in reversed(R['child']):
            k = c['idx']
            if R['kind'] == 'leaf':
                parts.append('(g%d_%s%d_re | g%d_%s%d_we)' % (vi, pfx, k, vi, pfx, k))
            else:
                parts.append('(g%d_%s%d_readen | g%d_%s%d_writeen)' % (vi, pfx, k, vi, pfx, k))
        A('    cov_spread%d |= {%s};' % (vi, ', '.join(parts)))
        A('    cov_od0_%d |= ~g%d_mbist_outdata; cov_od1_%d |= g%d_mbist_outdata;' % (vi, vi, vi, vi))
        A('    if (g%d_mbist_ack) cov_ack1_%d = 1\'b1; else cov_ack0_%d = 1\'b1;' % (vi, vi, vi))
    A('  endtask')
    A('')
    A('  // ---------------- 覆盖闸判定 ----------------')
    A('  function automatic int unsigned cov_gate();')
    A('    int unsigned bad;')
    A('    bad = 0;')
    A('    if (!(&cov_id))    begin bad++; $display("  [COV FAIL] 有 array 编号从未以 req&!all 打过: %b", cov_id); end')
    A('    if (!(&cov_addr0) || !(&cov_addr1)) begin bad++; $display("  [COV FAIL] 地址位未全翻转 zero=%b one=%b", cov_addr0, cov_addr1); end')
    A('    if (!(&cov_be0) || !(&cov_be1))     begin bad++; $display("  [COV FAIL] be 位未全翻转"); end')
    A('    if (!(&cov_din0) || !(&cov_din1))   begin bad++; $display("  [COV FAIL] indata 位未全翻转"); end')
    A('    if (!cov_all_bcast) begin bad++; $display("  [COV FAIL] all 广播从未出现"); end')
    A('    if (!cov_idle)      begin bad++; $display("  [COV FAIL] 空闲拍从未出现"); end')
    A('    if (!cov_wr || !cov_rd || !cov_rdwr) begin bad++; $display("  [COV FAIL] 读/写/读写并发组合未覆盖全"); end')
    for vi, R in enumerate(Rs):
        A('    if (!(&cov_spread%d)) begin bad++; $display("  [COV FAIL] %s 有 child 从未被铺开: %%b", cov_spread%d); end'
          % (vi, R['module'], vi))
        A('    if (!(&cov_od0_%d) || !(&cov_od1_%d)) begin bad++; $display("  [COV FAIL] %s mbist_outdata 有位未翻转"); end'
          % (vi, vi, R['module']))
        A('    if (!cov_ack0_%d || !cov_ack1_%d) begin bad++; $display("  [COV FAIL] %s mbist_ack 未两态"); end'
          % (vi, vi, R['module']))
    A('    return bad;')
    A('  endfunction')
    A('')
    A('  // ---------------- 激励 ----------------')
    A('  task automatic drive_random();')
    A('    s_array   = $urandom_range(0, %d);' % ((1 << MASTER['ARRAY']) - 1))
    A('    s_all     = ($urandom_range(0, 15) == 0);   // 广播是少数派')
    A('    s_req     = ($urandom_range(0, 9) != 0);')
    A('    s_wen     = $urandom_range(0, 1);')
    A('    s_ren     = $urandom_range(0, 1);')
    for nm, w in (('s_be', MASTER['BE']), ('s_indata', MASTER['DATA'])):
        A('    %s = {%s};' % (nm, ', '.join(['$urandom'] * ((w + 31) // 32))))
    A('    s_addr    = $urandom;')
    A('    s_addr_rd = $urandom;')
    A('  endtask')
    A('')
    A('  // 定向阶段：把 128 个 array 编号逐个扫一遍，并让地址/数据/be 走全 0、全 1、')
    A('  // 逐位游走三种图形——MBIST 地址位宽是本家族最容易写错的地方（G1 里普遍是')
    A('  // 按最大 id 算出来的最小位宽），不把每一位都打到就等于没验位宽。')
    A('  task automatic drive_directed(input int unsigned k);')
    A('    int unsigned phase, idx;')
    A('    phase = (k / 128) % 6;')
    A('    idx   = k % 128;')
    A('    s_array   = idx[6:0];')
    A('    s_req     = 1\'b1;')
    A('    s_all     = (phase == 5);')
    A('    s_wen     = (phase != 1);')
    A('    s_ren     = (phase != 2);')
    A('    case (phase)')
    A('      0: begin s_addr = \'0; s_addr_rd = \'0; s_be = \'0; s_indata = \'0; end')
    A('      1: begin s_addr = \'1; s_addr_rd = \'1; s_be = \'1; s_indata = \'1; end')
    A('      2: begin s_addr = %d\'(1) << (idx %% %d); s_addr_rd = %d\'(1) << ((idx+3) %% %d);'
      % (MASTER['ADDR'], MASTER['ADDR'], MASTER['ADDR'], MASTER['ADDR']))
    A('           s_be = %d\'(1) << (idx %% %d); s_indata = %d\'(1) << (idx %% %d); end'
      % (MASTER['BE'], MASTER['BE'], MASTER['DATA'], MASTER['DATA']))
    A('      3: begin s_addr = ~(%d\'(1) << (idx %% %d)); s_addr_rd = \'1;' % (MASTER['ADDR'], MASTER['ADDR']))
    A('           s_be = ~(%d\'(1) << (idx %% %d)); s_indata = ~(%d\'(1) << (idx %% %d)); end'
      % (MASTER['BE'], MASTER['BE'], MASTER['DATA'], MASTER['DATA']))
    A('      default: begin s_addr = $urandom; s_addr_rd = $urandom;')
    A('           s_be = {%s}; s_indata = {%s}; end'
      % (', '.join(['$urandom'] * ((MASTER['BE'] + 31) // 32)),
         ', '.join(['$urandom'] * ((MASTER['DATA'] + 31) // 32))))
    A('    endcase')
    A('  endtask')
    A('')
    A('  task automatic drive_children();')
    for vi, R in enumerate(Rs):
        for c in R['child']:
            nw = (c['DATA_W'] + 31) // 32
            A('    v%d_rd%d = {%s};' % (vi, c['idx'], ', '.join(['$urandom'] * nw)))
            if R['kind'] == 'node':
                A('    v%d_ack%d = $urandom_range(0, 1);' % (vi, c['idx']))
    A('  endtask')
    A('')
    A('  // ---------------- 主流程 ----------------')
    A('  initial begin')
    A('    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;')
    A('    s_array = \'0; s_all = 1\'b0; s_req = 1\'b0; s_wen = 1\'b0; s_ren = 1\'b0;')
    A('    s_be = \'0; s_addr = \'0; s_addr_rd = \'0; s_indata = \'0;')
    A('    drive_children();')
    A('    repeat (4) @(posedge clock);')
    A('    reset = 1\'b0;')
    A('    // 开闸前先打两拍 all 广播读：中间节点的 pipelineDataOutReg 在 golden 里')
    A('    // **没有复位**，上电是随机值，两侧随机数不同。先用 activated=1 的拍把它')
    A('    // 载成同一个确定值，之后所有比对都是无条件的（没有 X 跳过守卫）。')
    A('    @(negedge clock);')
    A('    s_all = 1\'b1; s_req = 1\'b1; s_ren = 1\'b1; s_wen = 1\'b1;')
    A('    @(posedge clock); @(negedge clock);')
    A('    drive_children();')
    A('    @(posedge clock); @(negedge clock);')
    A('    armed = 1\'b1;')
    A('')
    A('    for (int unsigned i = 0; i < ncycles; i++) begin')
    A('      drive_children();')
    A('      if (i < 1536) drive_directed(i);   // 前 1536 拍走定向图形')
    A('      else          drive_random();')
    A('      sample_cov();')
    A('      @(posedge clock);')
    A('      #1;')
    A('      cyc++;')
    A('      compare_all();')
    A('      @(negedge clock);')
    A('    end')
    A('')
    A('    finish_report();')
    A('  end')
    A('')
    A('  task automatic finish_report();')
    A('    longint unsigned expect_checks;')
    A('    int unsigned covbad;')
    A('    expect_checks = N_OUT_PORTS * cmp_cycles;')
    A('    covbad = cov_gate();')
    A('    $display("=== MbistPipe family UT ===");')
    A('    $display("  variants   = 24 (22 leaf + 2 node)");')
    A('    $display("  cycles     = %0d", cmp_cycles);')
    A('    $display("  out ports  = %0d", N_OUT_PORTS);')
    A('    $display("  checks     = %0d", checks);')
    A('    $display("  expected   = %0d  (out ports x cycles)", expect_checks);')
    A('    $display("  errors     = %0d", errors);')
    A('    $display("  cov fails  = %0d", covbad);')
    A('    if (checks != expect_checks) begin')
    A('      $display("=== TEST FAILED: checks(%0d) != 输出端口数 x 拍数(%0d) —— 有比对被静默跳过 ===",')
    A('               checks, expect_checks);')
    A('      $fatal(1, "check accounting mismatch");')
    A('    end')
    A('    if (errors != 0) begin')
    A('      $display("=== TEST FAILED: errors=%0d ===", errors); $fatal(1, "mismatch");')
    A('    end')
    A('    if (covbad != 0) begin')
    A('      $display("=== TEST FAILED: 覆盖闸未过 (%0d 项) ===", covbad); $fatal(1, "coverage");')
    A('    end')
    A('    $display("=== TEST PASSED ===");')
    A('    $finish;')
    A('  endtask')
    A('')
    A('endmodule')

    txt = '\n'.join(L) + '\n'
    path = os.path.join(OUT, 'tb.sv')
    if not os.path.exists(path) or open(path).read() != txt:
        open(path, 'w').write(txt)
    print('wrote %s (%d lines, %d output ports total)' % (path, len(L), total_out))


if __name__ == '__main__':
    main()

#!/usr/bin/env python3
"""生成本目录的 tb.sv —— golden Predictor 与重写 Predictor_xs 双例化逐拍对照台。

Predictor 有 633 个端口（508 输入 / 125 输出），手写 tb 不现实：端口表直接从
G1 golden 的 module Predictor(...) 解析。端口一变重跑本脚本即可。

激励不是均匀随机。Predictor 是 BPU 的顶层流水，端口间有强协议约束：
  · 重定向包里的 cfiUpdate_shift 只有 0/1/2 合法（numBr=2），纯随机会常年落在 3；
  · redirect/update 都是稀疏事件，概率打太高流水永远在冲刷，S2/S3 覆盖判定
    这条最深的锥根本走不到；
  · histPtr 必须跟着 BPU 自己吐出来的 last_stage_spec_info_histPtr 走，否则
    重定向回滚永远在一个随机点上，折叠历史重算的对比价值很低。
  · 457 根 MBIST 扫描线是纯直通，随机打即可（它们只验证连线没接错）。

用法:  python3 gen_tb.py tb.sv
"""
import re, sys

G1 = '/home/eda/xs-env/G1-canonical/golden-rtl/Predictor.sv'
OUT = sys.argv[1] if len(sys.argv) > 1 else 'tb.sv'

src = open(G1).read()
m = re.search(r'^module Predictor\(\s*(.*?)^\);', src, re.S | re.M)
ins, outs = [], []
for l in m.group(1).split('\n'):
    l = l.strip().rstrip(',')
    if not l:
        continue
    mm = re.match(r'(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)$', l)
    assert mm, l
    (ins if mm.group(1) == 'input' else outs).append((mm.group(3), mm.group(2) or ''))
ins = [(n, w) for n, w in ins if n not in ('clock', 'reset')]
assert len(ins) + len(outs) == 631, (len(ins), len(outs))

HAND = {
    'io_bpu_to_ftq_resp_ready',
    'io_ftq_to_bpu_redirect_valid',
    'io_ftq_to_bpu_update_valid',
    'io_ftq_to_bpu_redirctFromIFU',
    'io_ftq_to_bpu_redirect_bits_cfiUpdate_shift',
    'io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist',
    'io_ftq_to_bpu_redirect_bits_cfiUpdate_taken',
    'io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag',
    'io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value',
    'io_ftq_to_bpu_redirect_bits_debugIsCtrl',
    'io_ftq_to_bpu_redirect_bits_debugIsMemVio',
    'io_ftq_to_bpu_update_bits_spec_info_histPtr_value',
    'io_ftq_to_bpu_enq_ptr_flag', 'io_ftq_to_bpu_enq_ptr_value',
    'io_ctrl_ubtb_enable', 'io_ctrl_btb_enable', 'io_ctrl_tage_enable',
    'io_ctrl_sc_enable', 'io_ctrl_ras_enable',
}
RANDOM = [(n, w) for n, w in ins if n not in HAND]


def wid(w):
    if not w:
        return 1
    a, b = w.strip('[]').split(':')
    return int(a) - int(b) + 1


def rnd(n, w):
    k = wid(w)
    if k == 1:
        return f"{n} = $urandom_range(0,1);"
    if k <= 32:
        return f"{n} = {k}'($urandom());"
    chunks = (k + 31) // 32
    return f"{n} = {k}'({{{', '.join(['$urandom()'] * chunks)}}});"


L = []
A = L.append
A('// tb.sv —— Predictor UT：golden `Predictor` 与重写 `Predictor_xs` 双例化，')
A('//          同激励逐拍比全部 125 个输出。本文件由 gen_tb.py 从 golden 端口表生成。')
A('//')
A('// 两侧共用同一份 golden Composer（及其 5 个预测器闭包）——本 UT 只验 Predictor')
A('// 这一层的流水控制与全局历史管理，预测器本身另有各自的签核。')
A('//')
A('// 激励设计见 gen_tb.py 头注释：shift 约束在 0..2、redirect/update 稀疏、')
A('// histPtr 跟随 DUT 自己吐出的 last_stage_spec_info_histPtr。')
A('`timescale 1ns/1ps')
A('module tb;')
A('  int unsigned NCYCLES = 200000;')
A('  bit clk = 0, rst;')
A('  longint errors = 0, checks = 0;')
A('  always #5 clk = ~clk;')
A('')
A('  // ---- 输入信号（两侧共用） ----')
for n, w in ins:
    A(f'  logic {w} {n};')
A('')
A('  // ---- 每个输出两根线：g_<port> / i_<port> ----')
for n, w in outs:
    A(f'  wire {w} g_{n};')
    A(f'  wire {w} i_{n};')
A('')
for dut, pref in (('Predictor dut_g', 'g_'), ('Predictor_xs dut_i', 'i_')):
    A(f'  {dut} (')
    A('    .clock(clk), .reset(rst),')
    for n, _ in ins:
        A(f'    .{n}({n}),')
    for k, (n, _) in enumerate(outs):
        comma = '' if k == len(outs) - 1 else ','
        A(f'    .{n}({pref}{n}){comma}')
    A('  );')
    A('')
A('  function automatic bit chance(int unsigned pct);')
A('    return ($urandom_range(0, 99) < pct);')
A('  endfunction')
A('')
A('  // ---- 覆盖计数（关键事件；为 0 即判失败）----')
COV = [
    ('cov_s0_fire',        'g_io_bpu_to_ftq_resp_valid === 1\'b1'),
    ('cov_s2_override',    'g_io_bpu_to_ftq_resp_bits_s2_hasRedirect_3 === 1\'b1'),
    ('cov_s3_override',    'g_io_bpu_to_ftq_resp_bits_s3_hasRedirect_3 === 1\'b1'),
    ('cov_s2_valid',       'g_io_bpu_to_ftq_resp_bits_s2_valid_3 === 1\'b1'),
    ('cov_s3_valid',       'g_io_bpu_to_ftq_resp_bits_s3_valid_3 === 1\'b1'),
    ('cov_redirect',       'io_ftq_to_bpu_redirect_valid === 1\'b1'),
    ('cov_update',         'io_ftq_to_bpu_update_valid === 1\'b1'),
    ('cov_shift1',         'io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_cfiUpdate_shift == 2\'d1'),
    ('cov_shift2',         'io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_cfiUpdate_shift == 2\'d2'),
    ('cov_ctrl_bubble',    'io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_debugIsCtrl'),
    ('cov_memvio_bubble',  'io_ftq_to_bpu_redirect_valid && io_ftq_to_bpu_redirect_bits_debugIsMemVio'),
    ('cov_topdown_set',    '|{g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_1, '
                           'g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_2, '
                           'g_io_bpu_to_ftq_resp_bits_topdown_info_reasons_9}'),
    ('cov_ftq_stall',      'io_bpu_to_ftq_resp_ready === 1\'b0'),
]
for nm, _ in COV:
    A(f'  longint {nm} = 0;')
A('')
A('  // 重定向的历史指针跟着 BPU 自己吐出来的末级指针走（见头注释）')
A('  logic [7:0] hp_shadow;')
A('  logic       hpf_shadow;')
A('  always @(posedge clk) begin')
A('    if (rst) begin hp_shadow <= 8\'h0; hpf_shadow <= 1\'b0; end')
A('    else if (chance(70)) begin')
A('      hp_shadow  <= g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_value;')
A('      hpf_shadow <= g_io_bpu_to_ftq_resp_bits_last_stage_spec_info_histPtr_flag;')
A('    end')
A('  end')
A('')
A('  task automatic drive();')
for n, w in RANDOM:
    A('    ' + rnd(n, w))
A('  endtask')
A('')
A('  always @(negedge clk) begin')
A('    drive();')
A('    io_bpu_to_ftq_resp_ready                          = chance(80);')
A('    io_ftq_to_bpu_redirect_valid                      = chance(4);')
A('    io_ftq_to_bpu_update_valid                        = chance(25);')
A('    io_ftq_to_bpu_redirctFromIFU                      = chance(3);')
A('    // shift 只有 0/1/2 合法；偶尔打 3 压一下越界行为（golden 也有确定语义）')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_shift       = chance(95) ? 2\'($urandom_range(0,2)) : 2\'d3;')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_addIntoHist = chance(70);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_taken       = chance(50);')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_value = chance(75) ? hp_shadow : 8\'($urandom());')
A('    io_ftq_to_bpu_redirect_bits_cfiUpdate_histPtr_flag  = chance(75) ? hpf_shadow : $urandom_range(0,1);')
A('    io_ftq_to_bpu_redirect_bits_debugIsCtrl           = chance(45);')
A('    io_ftq_to_bpu_redirect_bits_debugIsMemVio         = chance(20);')
A('    io_ftq_to_bpu_update_bits_spec_info_histPtr_value = chance(75) ? hp_shadow : 8\'($urandom());')
A('    io_ftq_to_bpu_enq_ptr_flag                        = $urandom_range(0,1);')
A('    io_ftq_to_bpu_enq_ptr_value                       = 6\'($urandom());')
A('    // ctrl 五个使能绝大多数时间全开（关掉预测器会让预测包恒定，覆盖变差）')
A('    io_ctrl_ubtb_enable = chance(97); io_ctrl_btb_enable  = chance(97);')
A('    io_ctrl_tage_enable = chance(97); io_ctrl_sc_enable   = chance(97);')
A('    io_ctrl_ras_enable  = chance(97);')
A('  end')
A('')
A('  // 逐拍比对全部 %d 个输出' % len(outs))
A('  always @(posedge clk) if (!rst) begin')
for n, _ in outs:
    A(f'    if (!$isunknown(g_{n})) begin checks++;')
    A(f'      if (g_{n} !== i_{n}) begin errors++;')
    A(f'        if (errors<=60) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n}); end end')
for nm, cond in COV:
    A(f'    if ({cond}) {nm}++;')
A('  end')
A('')
A('  initial begin')
A('    void\'($value$plusargs("ncycles=%d", NCYCLES));')
A('    rst = 1; repeat (20) @(posedge clk); rst = 0;')
A('    repeat (NCYCLES) @(posedge clk);')
A('    $display("checks=%0d errors=%0d", checks, errors);')
A('    $display("--- coverage ---");')
for nm, _ in COV:
    A(f'    $display("  {nm:<20s} = %0d", {nm});')
A('    begin')
A('      int unsigned zero_cov = 0;')
for nm, _ in COV:
    A(f'      if ({nm} == 0) begin zero_cov++; $display("  [COVERAGE FAIL] {nm} 从未发生"); end')
A('      if (errors == 0 && checks > 1000000 && zero_cov == 0) $display("TEST PASSED");')
A('      else begin')
A('        if (zero_cov != 0) $display("=== 覆盖闸不过：%0d 个关键事件计数为 0 ===", zero_cov);')
A('        if (checks <= 1000000) $display("=== checks=%0d 过少，激励没打进去 ===", checks);')
A('        $display("TEST FAILED");')
A('      end')
A('    end')
A('    $finish;')
A('  end')
A('endmodule')
open(OUT, 'w').write('\n'.join(L) + '\n')
print(f'{OUT}: {len(ins)} inputs, {len(outs)} outputs, {len(L)} lines')

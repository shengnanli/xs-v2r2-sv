#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 生成 L1CohMetaArray / L1FlagMetaArray / L1FlagMetaArray_1 的 golden 同名 wrapper、
# xs 变体包装、tb、Makefile。可读核 (rtl/memblock/L1CohMetaArray.sv /
# L1FlagMetaArray.sv / l1metaarray_pkg.sv) 手写；本脚本只产出机械的扁平端口适配层
# （golden 扁平端口 <-> 核 struct/数组端口）与验证 harness。
#
# 三个 golden 变体：
#   L1CohMetaArray    : READ=4 WRITE=1  resp=2bit(coh_state)
#   L1FlagMetaArray   : READ=4 WRITE=1  resp=1bit
#   L1FlagMetaArray_1 : READ=5 WRITE=4  resp=1bit
#
# 用法： python3 scripts/gen_l1metaarray.py
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
RTL  = os.path.join(ROOT, 'rtl', 'memblock')
UT   = os.path.join(ROOT, 'verif', 'ut')

N_WAYS   = 4
IDX_BITS = 8

# kind: 'coh' -> resp 是 2-bit coh_state；'flag' -> resp 1-bit
VARIANTS = {
    'L1CohMetaArray':    dict(READ=4, WRITE=1, kind='coh',  core='xs_L1CohMetaArray_core'),
    'L1FlagMetaArray':   dict(READ=4, WRITE=1, kind='flag', core='xs_L1FlagMetaArray_core'),
    'L1FlagMetaArray_1': dict(READ=5, WRITE=4, kind='flag', core='xs_L1FlagMetaArray_core'),
}

# ---------------------------------------------------------------------------
# golden 扁平端口列表（按 golden 模块声明顺序），用于 wrapper 端口与 tb 连接
# ---------------------------------------------------------------------------
def golden_ports(R, W, kind):
    """返回 [(dir, width, name), ...]，顺序与 golden 一致。"""
    p = [('input', 1, 'clock'), ('input', 1, 'reset')]
    for i in range(R):
        p += [('input', 1, f'io_read_{i}_valid'),
              ('input', IDX_BITS, f'io_read_{i}_bits_idx')]
    rw = 2 if kind == 'coh' else 1
    suf = '_coh_state' if kind == 'coh' else ''
    for i in range(R):
        for w in range(N_WAYS):
            p.append(('output', rw, f'io_resp_{i}_{w}{suf}'))
    for j in range(W):
        p += [('input', 1, f'io_write_{j}_valid'),
              ('input', IDX_BITS, f'io_write_{j}_bits_idx'),
              ('input', N_WAYS, f'io_write_{j}_bits_way_en')]
        # 仅最后一个写口带 meta/flag 数据（golden 对未用数据做了死代码消除：
        # 所有写口共享同一 meta 端口，firtool 只保留一份在最后一个写口名下）
        if j == W - 1:
            if kind == 'coh':
                p.append(('input', rw, f'io_write_{j}_bits_meta_coh_state'))
            else:
                p.append(('input', 1, f'io_write_{j}_bits_flag'))
    return p

def decl(d, w, n):
    ww = '' if w == 1 else f'[{w-1}:0] '
    return f'  {d} {ww}{n}'

# ---------------------------------------------------------------------------
# wrapper：golden 扁平端口 <-> 核 struct/数组端口
# ---------------------------------------------------------------------------
def gen_wrapper(modname, golden_name, R, W, kind, core):
    gp = golden_ports(R, W, kind)
    s = []
    s.append('// 自动生成：scripts/gen_l1metaarray.py —— 勿手改')
    s.append('// L1 元数据阵列 golden 同名 / xs 变体扁平包装：扁平端口 <-> 可读核数组端口。')
    s.append(f'module {modname} import xs_l1metaarray_pkg::*; (')
    s.append(',\n'.join(decl(d, w, n) for (d, w, n) in gp))
    s.append(');')
    # 核侧数组信号
    s.append(f'  logic                rvalid [{R}];')
    s.append(f'  logic [{IDX_BITS-1}:0] ridx   [{R}];')
    s.append(f'  logic                wvalid [{W}];')
    s.append(f'  logic [{IDX_BITS-1}:0] widx   [{W}];')
    s.append(f'  logic [{N_WAYS-1}:0]   wen    [{W}];')
    if kind == 'coh':
        s.append(f'  meta_coh_t           resp   [{R}][{N_WAYS}];')
        s.append(f'  meta_coh_t           wdata  [{W}];')
    else:
        s.append(f'  logic                resp   [{R}][{N_WAYS}];')
        s.append(f'  logic                wdata  [{W}];')
    s.append('  always_comb begin')
    for i in range(R):
        s.append(f'    rvalid[{i}] = io_read_{i}_valid;')
        s.append(f'    ridx[{i}]   = io_read_{i}_bits_idx;')
    last = W - 1
    for j in range(W):
        s.append(f'    wvalid[{j}] = io_write_{j}_valid;')
        s.append(f'    widx[{j}]   = io_write_{j}_bits_idx;')
        s.append(f'    wen[{j}]    = io_write_{j}_bits_way_en;')
        # 写数据：golden 只暴露最后一个写口的数据端口。这是父模块例化时的常量传播：
        #   - 单写口变体(Coh/Flag)：唯一写口带真实数据。
        #   - L1FlagMetaArray_1：写口 0/1/2 在父模块恒写 flag=1（firtool 把它们的写数据
        #     常量传播成 1，只保留写口 3 的可变 flag 端口）。这里如实复刻该 tie-off，
        #     使 wrapper 与 golden 等价；可读核本身仍按“每写口独立数据”的设计语义建模。
        if kind == 'coh':
            s.append(f'    wdata[{j}].coh_state = io_write_{last}_bits_meta_coh_state;')
        else:
            if W > 1 and j != last:
                s.append(f'    wdata[{j}] = 1\'b1;  // 父模块 tie-off：写口{j} 恒写 flag=1')
            else:
                s.append(f'    wdata[{j}] = io_write_{last}_bits_flag;')
    s.append('  end')
    s.append(f'  {core} #(.READ_PORTS({R}), .WRITE_PORTS({W})) u_core (')
    s.append('    .clock(clock), .reset(reset),')
    s.append('    .io_read_valid(rvalid), .io_read_idx(ridx), .io_resp(resp),')
    s.append('    .io_write_valid(wvalid), .io_write_idx(widx),')
    if kind == 'coh':
        s.append('    .io_write_way_en(wen), .io_write_meta(wdata)')
    else:
        s.append('    .io_write_way_en(wen), .io_write_flag(wdata)')
    s.append('  );')
    suf = '_coh_state' if kind == 'coh' else ''
    fld = '.coh_state' if kind == 'coh' else ''
    for i in range(R):
        for w in range(N_WAYS):
            s.append(f'  assign io_resp_{i}_{w}{suf} = resp[{i}][{w}]{fld};')
    s.append('endmodule')
    return '\n'.join(s) + '\n'

# ---------------------------------------------------------------------------
# Testbench：golden vs xs 双例化，随机激励，逐拍比对全部 resp 输出
# ---------------------------------------------------------------------------
def gen_tb(golden_name, R, W, kind):
    gp = golden_ports(R, W, kind)
    ins  = [(w, n) for (d, w, n) in gp if d == 'input'  and n not in ('clock', 'reset')]
    outs = [(w, n) for (d, w, n) in gp if d == 'output']
    s = []
    s.append('// 自动生成：scripts/gen_l1metaarray.py —— 勿手改')
    s.append('`timescale 1ns/1ps')
    s.append('module tb;')
    s.append('  int unsigned NVEC = 250000;')
    s.append('  int errors = 0, checks = 0;')
    s.append('  logic clock = 0, reset;')
    s.append('  always #5 clock = ~clock;')
    for (w, n) in ins:
        ww = '' if w == 1 else f'[{w-1}:0] '
        s.append(f'  logic {ww}{n};')
    for (w, n) in outs:
        ww = '' if w == 1 else f'[{w-1}:0] '
        s.append(f'  wire {ww}g_{n};  wire {ww}i_{n};')
    def inst(mod, pfx):
        conns = ['.clock(clock)', '.reset(reset)']
        for (w, n) in ins:  conns.append(f'.{n}({n})')
        for (w, n) in outs: conns.append(f'.{n}({pfx}{n})')
        return f'  {mod} u_{pfx} (' + ', '.join(conns) + ');'
    s.append(inst(golden_name, 'g_'))
    s.append(inst(golden_name + '_xs', 'i_'))
    s.append('  task automatic do_check(int t);')
    s.append('    checks++;')
    for (w, n) in outs:
        # 仅在 golden 非 X 时比对（复位后未写过的条目读出 X 为 don\'t-care）
        s.append(f'    if (!$isunknown(g_{n}) && (g_{n} !== i_{n})) begin errors++;')
        s.append(f'      if(errors<=60) $display("vec %0d {n} g=%h i=%h",t,g_{n},i_{n}); end')
    s.append('  endtask')
    s.append('  task automatic drive_random();')
    for i in range(R):
        s.append(f'    io_read_{i}_valid = $urandom_range(0,1);')
        # idx 收窄到小范围，提升 bypass/读写同址命中概率
        s.append(f'    io_read_{i}_bits_idx = {IDX_BITS}\'($urandom_range(0,15));')
    for j in range(W):
        s.append(f'    io_write_{j}_valid = ($urandom_range(0,2) == 0);')
        s.append(f'    io_write_{j}_bits_idx = {IDX_BITS}\'($urandom_range(0,15));')
        s.append(f'    io_write_{j}_bits_way_en = {N_WAYS}\'($urandom);')
    last = W - 1
    if kind == 'coh':
        s.append(f'    io_write_{last}_bits_meta_coh_state = 2\'($urandom);')
    else:
        s.append(f'    io_write_{last}_bits_flag = $urandom_range(0,1);')
    s.append('  endtask')
    s.append('  initial begin')
    s.append('    reset = 1;')
    for i in range(R):
        s.append(f'    io_read_{i}_valid = 0;  io_read_{i}_bits_idx = 0;')
    for j in range(W):
        s.append(f'    io_write_{j}_valid = 0;  io_write_{j}_bits_idx = 0;  io_write_{j}_bits_way_en = 0;')
    if kind == 'coh':
        s.append(f'    io_write_{last}_bits_meta_coh_state = 0;')
    else:
        s.append(f'    io_write_{last}_bits_flag = 0;')
    s.append('    repeat (3) @(posedge clock); #1; reset = 0;')
    s.append('    @(posedge clock);')
    s.append('    for (int t = 0; t < NVEC; t++) begin')
    s.append('      drive_random();')
    s.append('      @(posedge clock); #1;')
    s.append('      do_check(t);')
    s.append('    end')
    s.append('    $display("checks=%0d errors=%0d", checks, errors);')
    s.append('    if (errors == 0 && checks > 1000) $display("TEST PASSED");')
    s.append('    else $display("TEST FAILED");')
    s.append('    $finish;')
    s.append('  end')
    s.append('endmodule')
    return '\n'.join(s) + '\n'

def w(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w') as f:
        f.write(content)
    print('wrote', path)

def main():
    # wrapper（golden 同名）
    for name, prm in VARIANTS.items():
        w(os.path.join(RTL, f'{name}_wrapper.sv'),
          gen_wrapper(name, name, prm['READ'], prm['WRITE'], prm['kind'], prm['core']))

    # 按 UT 目录分组：Coh 一个目录，两个 Flag 变体一个目录
    # ---- L1CohMetaArray ----
    pc = VARIANTS['L1CohMetaArray']
    coh_var = gen_wrapper('L1CohMetaArray_xs', 'L1CohMetaArray', pc['READ'], pc['WRITE'], pc['kind'], pc['core'])
    w(os.path.join(UT, 'L1CohMetaArray', 'variants_xs.sv'), coh_var)
    w(os.path.join(UT, 'L1CohMetaArray', 'tb.sv'), gen_tb('L1CohMetaArray', pc['READ'], pc['WRITE'], pc['kind']))
    mk = []
    mk.append('MODULE = L1CohMetaArray')
    mk.append('RTL_DIR = ../../../rtl')
    mk.append('GOLDEN_RTL = ../../../golden/chisel-rtl')
    mk.append('RTL_SRCS = $(RTL_DIR)/memblock/l1metaarray_pkg.sv $(RTL_DIR)/memblock/L1CohMetaArray.sv')
    mk.append('WRAPPER_SRCS = $(RTL_DIR)/memblock/L1CohMetaArray_wrapper.sv')
    mk.append('GOLDEN_SRCS = $(GOLDEN_RTL)/L1CohMetaArray.sv')
    mk.append('TB_SRCS = variants_xs.sv tb.sv')
    mk.append('FM_VARIANTS = L1CohMetaArray')
    mk.append('FM_MERGE_DUP = false')
    mk.append('include ../../../scripts/ut_common.mk')
    mk.append('')
    w(os.path.join(UT, 'L1CohMetaArray', 'Makefile'), '\n'.join(mk) + '\n')

    # ---- L1FlagMetaArray (+_1) ----
    pf  = VARIANTS['L1FlagMetaArray']
    pf1 = VARIANTS['L1FlagMetaArray_1']
    flag_var = '\n'.join([
        gen_wrapper('L1FlagMetaArray_xs',   'L1FlagMetaArray',   pf['READ'],  pf['WRITE'],  pf['kind'],  pf['core']),
        gen_wrapper('L1FlagMetaArray_1_xs', 'L1FlagMetaArray_1', pf1['READ'], pf1['WRITE'], pf1['kind'], pf1['core']),
    ])
    w(os.path.join(UT, 'L1FlagMetaArray', 'variants_xs.sv'), flag_var)
    w(os.path.join(UT, 'L1FlagMetaArray', 'tb.sv'),   gen_tb('L1FlagMetaArray',   pf['READ'],  pf['WRITE'],  pf['kind']))
    w(os.path.join(UT, 'L1FlagMetaArray', 'tb_1.sv'), gen_tb('L1FlagMetaArray_1', pf1['READ'], pf1['WRITE'], pf1['kind']))
    mk = []
    mk.append('MODULE = L1FlagMetaArray')
    mk.append('RTL_DIR = ../../../rtl')
    mk.append('GOLDEN_RTL = ../../../golden/chisel-rtl')
    mk.append('RTL_SRCS = $(RTL_DIR)/memblock/l1metaarray_pkg.sv $(RTL_DIR)/memblock/L1FlagMetaArray.sv')
    mk.append('WRAPPER_SRCS = $(RTL_DIR)/memblock/L1FlagMetaArray_wrapper.sv $(RTL_DIR)/memblock/L1FlagMetaArray_1_wrapper.sv')
    mk.append('GOLDEN_SRCS = $(GOLDEN_RTL)/L1FlagMetaArray.sv')
    mk.append('TB_SRCS = variants_xs.sv tb.sv')
    mk.append('FM_VARIANTS = L1FlagMetaArray L1FlagMetaArray_1')
    mk.append('FM_MERGE_DUP = false')
    mk.append('include ../../../scripts/ut_common.mk')
    mk.append('')
    mk.append('# 变体 L1FlagMetaArray_1 的独立 UT（默认 compile/run 跑 L1FlagMetaArray）')
    mk.append('SEED ?= 1')
    mk.append('compile1: simv1')
    mk.append('simv1: $(RTL_SRCS) $(WRAPPER_SRCS) variants_xs.sv tb_1.sv $(GOLDEN_RTL)/L1FlagMetaArray_1.sv')
    mk.append('\t$(VCS) $(RTL_SRCS) $(RTL_DIR)/memblock/L1FlagMetaArray_1_wrapper.sv $(GOLDEN_RTL)/L1FlagMetaArray_1.sv variants_xs.sv tb_1.sv -top tb -o simv1')
    mk.append('run1: simv1')
    mk.append('\t./simv1 +ntb_random_seed=$(SEED) -l sim1.log')
    mk.append('\t@grep -q "TEST PASSED" sim1.log && echo "=== UT PASSED (L1FlagMetaArray_1) ===" \\')
    mk.append('\t\t|| { echo "=== UT FAILED (L1FlagMetaArray_1) ==="; exit 1; }')
    mk.append('.PHONY: compile1 run1')
    mk.append('')
    w(os.path.join(UT, 'L1FlagMetaArray', 'Makefile'), '\n'.join(mk) + '\n')

if __name__ == '__main__':
    main()

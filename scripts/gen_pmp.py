#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 生成 PMP / PMPChecker 的 golden 同名 wrapper、xs 变体包装、tb、Makefile。
# 可读核心 (rtl/memblock/PMP.sv, PMPChecker.sv, pmp_pkg.sv) 手写，本脚本只产出
# 机械的扁平端口适配层与验证 harness。各变体端口顺序对齐 golden RTL。
#
# 用法： python3 scripts/gen_pmp.py
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
RTL  = os.path.join(ROOT, 'rtl', 'memblock')
UT   = os.path.join(ROOT, 'verif', 'ut')

NUM_PMP = 16
NUM_PMA = 16
ADDR_REG_W = 46
MASK_W = 48
PADDR_W = 48

# pmp_entry_t / pma_entry_t 的扁平字段（与 golden 端口后缀一致）。
# PMP 条目 cfg 输出不含 c/atomic（golden PMP 的 io_pmp_* 无这两位）；PMA 条目含。
def entry_fields(is_pma):
    f = []
    if is_pma:
        f.append(('cfg_c', 1)); f.append(('cfg_atomic', 1))
    else:
        f.append(('cfg_l', 1))
    f.append(('cfg_a', 2)); f.append(('cfg_x', 1)); f.append(('cfg_w', 1)); f.append(('cfg_r', 1))
    f.append(('addr', ADDR_REG_W)); f.append(('mask', MASK_W))
    return f

# checker 的输入条目含全部字段（pmp 带 l，pma 带 c/atomic）
def chk_entry_fields(is_pma):
    if is_pma:
        return [('cfg_c',1),('cfg_atomic',1),('cfg_a',2),('cfg_x',1),('cfg_w',1),('cfg_r',1),
                ('addr',ADDR_REG_W),('mask',MASK_W)]
    else:
        return [('cfg_l',1),('cfg_a',2),('cfg_x',1),('cfg_w',1),('cfg_r',1),
                ('addr',ADDR_REG_W),('mask',MASK_W)]

def decl(width, name, dir_):
    w = '' if width == 1 else f'[{width-1}:0] '
    return f'  {dir_} {w}{name}'

# 把扁平字段连到 struct entry：返回 always_comb 赋值串（wrapper 内部）
def pack_entry(prefix, idx, fields, busname):
    # busname[idx].field = prefix_idx_field
    lines = []
    for (fn, w) in fields:
        member = fn.replace('cfg_', 'cfg.') if fn.startswith('cfg_') else fn
        lines.append(f'    {busname}[{idx}].{member} = {prefix}_{idx}_{fn};')
    return lines

# ---------------------------------------------------------------------------
# PMP wrapper / variant
# ---------------------------------------------------------------------------
def pmp_ports():
    p = []
    p.append(decl(1, 'clock', 'input'))
    p.append(decl(1, 'reset', 'input'))
    p.append(decl(1, 'io_distribute_csr_w_valid', 'input'))
    p.append(decl(12, 'io_distribute_csr_w_bits_addr', 'input'))
    p.append(decl(64, 'io_distribute_csr_w_bits_data', 'input'))
    for i in range(NUM_PMP):
        for (fn, w) in entry_fields(False):
            p.append(decl(w, f'io_pmp_{i}_{fn}', 'output'))
    for i in range(NUM_PMA):
        for (fn, w) in entry_fields(True):
            p.append(decl(w, f'io_pma_{i}_{fn}', 'output'))
    return p

def gen_pmp_module(modname):
    ports = pmp_ports()
    s = []
    s.append('// 自动生成：scripts/gen_pmp.py —— 勿手改')
    s.append('// PMP golden 同名/xs 变体扁平包装：扁平 CSR 端口 <-> 可读核 xs_PMP_core 的条目结构。')
    s.append(f'module {modname} import xs_pmp_pkg::*; (')
    s.append(',\n'.join(ports))
    s.append(');')
    s.append('  pmp_entry_t [NUM_PMP-1:0] pmp;')
    s.append('  pmp_entry_t [NUM_PMA-1:0] pma;')
    s.append('  xs_PMP_core u_core (')
    s.append('    .clock(clock), .reset(reset),')
    s.append('    .io_distribute_csr_w_valid(io_distribute_csr_w_valid),')
    s.append('    .io_distribute_csr_w_bits_addr(io_distribute_csr_w_bits_addr),')
    s.append('    .io_distribute_csr_w_bits_data(io_distribute_csr_w_bits_data),')
    s.append('    .io_pmp(pmp), .io_pma(pma)')
    s.append('  );')
    # 拆 struct -> 扁平输出
    for i in range(NUM_PMP):
        for (fn, w) in entry_fields(False):
            member = fn.replace('cfg_', 'cfg.') if fn.startswith('cfg_') else fn
            s.append(f'  assign io_pmp_{i}_{fn} = pmp[{i}].{member};')
    for i in range(NUM_PMA):
        for (fn, w) in entry_fields(True):
            member = fn.replace('cfg_', 'cfg.') if fn.startswith('cfg_') else fn
            s.append(f'  assign io_pma_{i}_{fn} = pma[{i}].{member};')
    s.append('endmodule')
    return '\n'.join(s) + '\n'

# ---------------------------------------------------------------------------
# PMPChecker wrapper / variant
# ---------------------------------------------------------------------------
def chk_ports(registered):
    p = []
    if registered:
        p.append(decl(1, 'clock', 'input'))
        p.append(decl(1, 'reset', 'input'))
    # check_env: mode, pmp[16], pma[16]
    p.append(decl(2, 'io_check_env_mode', 'input'))
    for i in range(NUM_PMP):
        for (fn, w) in chk_entry_fields(False):
            p.append(decl(w, f'io_check_env_pmp_{i}_{fn}', 'input'))
    for i in range(NUM_PMA):
        for (fn, w) in chk_entry_fields(True):
            p.append(decl(w, f'io_check_env_pma_{i}_{fn}', 'input'))
    if registered:
        p.append(decl(1, 'io_req_valid', 'input'))
    p.append(decl(PADDR_W, 'io_req_bits_addr', 'input'))
    p.append(decl(3, 'io_req_bits_cmd', 'input'))
    for o in ('ld', 'st', 'instr', 'mmio', 'atomic'):
        p.append(decl(1, f'io_resp_{o}', 'output'))
    return p

def gen_chk_module(modname, registered):
    ports = chk_ports(registered)
    s = []
    s.append('// 自动生成：scripts/gen_pmp.py —— 勿手改')
    s.append('// PMPChecker 扁平包装：扁平 check_env/req 端口 <-> 可读核 xs_PMPChecker_core。')
    s.append(f'module {modname} import xs_pmp_pkg::*; (')
    s.append(',\n'.join(ports))
    s.append(');')
    s.append('  pmp_entry_t [NUM_PMP-1:0] pmp;')
    s.append('  pmp_entry_t [NUM_PMA-1:0] pma;')
    s.append('  always_comb begin')
    for i in range(NUM_PMP):
        s += pack_entry('io_check_env_pmp', i, chk_entry_fields(False), 'pmp')
    for i in range(NUM_PMA):
        s += pack_entry('io_check_env_pma', i, chk_entry_fields(True), 'pma')
    # PMP 条目 c/atomic 不参与检查，置 0
    for i in range(NUM_PMP):
        s.append(f'    pmp[{i}].cfg.c = 1\'b0; pmp[{i}].cfg.atomic = 1\'b0;')
    # PMA 条目 l 不参与检查，置 0
    for i in range(NUM_PMA):
        s.append(f'    pma[{i}].cfg.l = 1\'b0;')
    s.append('  end')
    reg = '1' if registered else '0'
    clk = 'clock' if registered else "1'b0"
    rst = 'reset' if registered else "1'b0"
    rvalid = 'io_req_valid' if registered else "1'b0"
    s.append(f'  xs_PMPChecker_core #(.REGISTERED(1\'b{reg})) u_core (')
    s.append(f'    .clock({clk}), .reset({rst}), .io_req_valid({rvalid}),')
    s.append('    .io_req_bits_addr(io_req_bits_addr), .io_req_bits_cmd(io_req_bits_cmd),')
    s.append('    .io_check_env_mode(io_check_env_mode), .io_check_env_pmp(pmp), .io_check_env_pma(pma),')
    s.append('    .io_resp_ld(io_resp_ld), .io_resp_st(io_resp_st), .io_resp_instr(io_resp_instr),')
    s.append('    .io_resp_mmio(io_resp_mmio), .io_resp_atomic(io_resp_atomic)')
    s.append('  );')
    s.append('endmodule')
    return '\n'.join(s) + '\n'

# ---------------------------------------------------------------------------
# Testbench 生成（golden vs xs 双例化，逐拍比对输出）
# ---------------------------------------------------------------------------
def conn(ports, prefix=''):
    # 端口连接串：.name(prefix+name) ；clock/reset 特殊处理由调用方加
    out = []
    for p in ports:
        nm = p.strip().split()[-1]
        out.append(f'.{nm}({prefix}{nm})')
    return ', '.join(out)

def gen_pmp_tb():
    # PMP 时序：随机 CSR 写，逐拍比对所有 pmp/pma 输出
    in_ports = [
        ('io_distribute_csr_w_valid', 1),
        ('io_distribute_csr_w_bits_addr', 12),
        ('io_distribute_csr_w_bits_data', 64),
    ]
    out_ports = []
    for i in range(NUM_PMP):
        for (fn, w) in entry_fields(False):
            out_ports.append((f'io_pmp_{i}_{fn}', w))
    for i in range(NUM_PMA):
        for (fn, w) in entry_fields(True):
            out_ports.append((f'io_pma_{i}_{fn}', w))

    s = []
    s.append('// 自动生成：scripts/gen_pmp.py —— 勿手改')
    s.append('`timescale 1ns/1ps')
    s.append('module tb;')
    s.append('  int unsigned NVEC = 20000;')
    s.append('  int errors = 0, checks = 0;')
    s.append('  logic clock = 0, reset;')
    s.append('  always #5 clock = ~clock;')
    for (n, w) in in_ports:
        ww = '' if w == 1 else f'[{w-1}:0] '
        s.append(f'  logic {ww}{n};')
    for (n, w) in out_ports:
        ww = '' if w == 1 else f'[{w-1}:0] '
        s.append(f'  wire {ww}g_{n};  wire {ww}i_{n};')
    # CSR 写地址池：合法的 pmp/pma cfg/addr 地址 + 偶发非法地址
    s.append('  logic [11:0] addr_pool [];')
    s.append('  initial begin')
    s.append('    addr_pool = new[36];')
    s.append("    addr_pool[0]=12'h3A0; addr_pool[1]=12'h3A2;")
    s.append('    for (int i=0;i<16;i++) addr_pool[2+i]=12\'h3B0+i[11:0];')
    s.append("    addr_pool[18]=12'h7C0; addr_pool[19]=12'h7C2;")
    s.append('    for (int i=0;i<16;i++) addr_pool[20+i]=12\'h7C8+i[11:0];')
    s.append('  end')
    # 例化 golden 与 xs
    def inst(mod, pfx):
        conns = ['.clock(clock)', '.reset(reset)']
        for (n, w) in in_ports:
            conns.append(f'.{n}({n})')
        for (n, w) in out_ports:
            conns.append(f'.{n}({pfx}{n})')
        return f'  {mod} {pfx if pfx else "u"}u (' + ', '.join(conns) + ');'
    s.append(inst('PMP', 'g_'))
    s.append(inst('PMP_xs', 'i_'))
    s.append('  task automatic do_check(int t);')
    s.append('    checks++;')
    for (n, w) in out_ports:
        s.append(f'    if (g_{n} !== i_{n}) begin errors++;')
        s.append(f'      if (errors<=40) $display("vec %0d {n}: g=%h i=%h", t, g_{n}, i_{n}); end')
    s.append('  endtask')
    s.append('  initial begin')
    s.append('    reset = 1; io_distribute_csr_w_valid = 0;')
    s.append("    io_distribute_csr_w_bits_addr = 0; io_distribute_csr_w_bits_data = 0;")
    s.append('    repeat (3) @(posedge clock); #1; reset = 0;')
    s.append('    @(posedge clock);')
    s.append('    for (int t = 0; t < NVEC; t++) begin')
    s.append('      // 多数拍发合法 CSR 写；偶发无写 / 随机非法地址')
    s.append('      automatic int kind = $urandom_range(0, 9);')
    s.append('      io_distribute_csr_w_valid = (kind != 0);')
    s.append('      if (kind <= 7)')
    s.append('        io_distribute_csr_w_bits_addr = addr_pool[$urandom_range(0, 35)];')
    s.append("      else")
    s.append("        io_distribute_csr_w_bits_addr = 12'($urandom);")
    s.append('      io_distribute_csr_w_bits_data = {$urandom, $urandom};')
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

def gen_chk_tb(golden_mod, registered):
    in_ports = [('io_check_env_mode', 2)]
    for i in range(NUM_PMP):
        for (fn, w) in chk_entry_fields(False):
            in_ports.append((f'io_check_env_pmp_{i}_{fn}', w))
    for i in range(NUM_PMA):
        for (fn, w) in chk_entry_fields(True):
            in_ports.append((f'io_check_env_pma_{i}_{fn}', w))
    if registered:
        in_ports.append(('io_req_valid', 1))
    in_ports.append(('io_req_bits_addr', PADDR_W))
    in_ports.append(('io_req_bits_cmd', 3))
    out_ports = [(f'io_resp_{o}', 1) for o in ('ld', 'st', 'instr', 'mmio', 'atomic')]

    s = []
    s.append('// 自动生成：scripts/gen_pmp.py —— 勿手改')
    s.append('`timescale 1ns/1ps')
    s.append('module tb;')
    s.append('  int unsigned NVEC = 200000;')
    s.append('  int errors = 0, checks = 0;')
    if registered:
        s.append('  logic clock = 0, reset;')
        s.append('  always #5 clock = ~clock;')
    for (n, w) in in_ports:
        ww = '' if w == 1 else f'[{w-1}:0] '
        s.append(f'  logic {ww}{n};')
    for (n, w) in out_ports:
        s.append(f'  wire g_{n};  wire i_{n};')
    # 例化
    def inst(mod, pfx):
        conns = []
        if registered:
            conns.append('.clock(clock)')
            conns.append('.reset(reset)')
        for (n, w) in in_ports:
            conns.append(f'.{n}({n})')
        for (n, w) in out_ports:
            conns.append(f'.{n}({pfx}{n})')
        return f'  {mod} u_{pfx} (' + ', '.join(conns) + ');'
    s.append(inst(golden_mod, 'g'))
    s.append(inst(golden_mod + '_xs', 'i'))
    # 激励：随机条目 + 随机地址/命令/mode。条目 a 偏向有效模式以增覆盖。
    s.append('  task automatic randomize_env();')
    s.append("    io_check_env_mode = 2'($urandom);")
    for i in range(NUM_PMP):
        s.append(f'    io_check_env_pmp_{i}_cfg_l = 1\'($urandom);')
        s.append(f'    io_check_env_pmp_{i}_cfg_a = 2\'($urandom);')
        s.append(f'    io_check_env_pmp_{i}_cfg_x = 1\'($urandom);')
        s.append(f'    io_check_env_pmp_{i}_cfg_w = 1\'($urandom);')
        s.append(f'    io_check_env_pmp_{i}_cfg_r = 1\'($urandom);')
        s.append(f'    io_check_env_pmp_{i}_addr = {{$urandom, $urandom}};')
        s.append(f'    io_check_env_pmp_{i}_mask = {{$urandom, $urandom}};')
    for i in range(NUM_PMA):
        s.append(f'    io_check_env_pma_{i}_cfg_c = 1\'($urandom);')
        s.append(f'    io_check_env_pma_{i}_cfg_atomic = 1\'($urandom);')
        s.append(f'    io_check_env_pma_{i}_cfg_a = 2\'($urandom);')
        s.append(f'    io_check_env_pma_{i}_cfg_x = 1\'($urandom);')
        s.append(f'    io_check_env_pma_{i}_cfg_w = 1\'($urandom);')
        s.append(f'    io_check_env_pma_{i}_cfg_r = 1\'($urandom);')
        s.append(f'    io_check_env_pma_{i}_addr = {{$urandom, $urandom}};')
        s.append(f'    io_check_env_pma_{i}_mask = {{$urandom, $urandom}};')
    s.append('  endtask')
    s.append('  task automatic randomize_req();')
    s.append('    io_req_bits_addr = {$urandom, $urandom};')
    s.append("    io_req_bits_cmd = 3'($urandom);")
    s.append('  endtask')
    s.append('  task automatic do_check(int t);')
    s.append('    checks++;')
    for (n, w) in out_ports:
        s.append(f'    if (g_{n} !== i_{n}) begin errors++;')
        s.append(f'      if (errors<=40) $display("vec %0d {n}: g=%h i=%h", t, g_{n}, i_{n}); end')
    s.append('  endtask')
    s.append('  initial begin')
    if registered:
        s.append('    reset = 1; io_req_valid = 0; randomize_env(); randomize_req();')
        s.append('    repeat (3) @(posedge clock); #1; reset = 0;')
        s.append('    @(posedge clock);')
        s.append('    for (int t = 0; t < NVEC; t++) begin')
        s.append('      randomize_env(); randomize_req();')
        s.append("      io_req_valid = 1'($urandom) | 1'b1;  // 多发 valid 以推进打拍")
        s.append('      @(posedge clock); #1;')
        s.append('      do_check(t);')
        s.append('    end')
    else:
        s.append('    for (int t = 0; t < NVEC; t++) begin')
        s.append('      randomize_env(); randomize_req();')
        s.append('      #1; do_check(t);')
        s.append('    end')
    s.append('    $display("checks=%0d errors=%0d", checks, errors);')
    s.append('    if (errors == 0 && checks > 1000) $display("TEST PASSED");')
    s.append('    else $display("TEST FAILED");')
    s.append('    $finish;')
    s.append('  end')
    s.append('endmodule')
    return '\n'.join(s) + '\n'

# ---------------------------------------------------------------------------
def w(path, content):
    with open(path, 'w') as f:
        f.write(content)
    print('wrote', path)

def main():
    # PMP wrapper（golden 名）+ xs 变体
    w(os.path.join(RTL, 'PMP_wrapper.sv'),  gen_pmp_module('PMP'))
    w(os.path.join(UT, 'PMP', 'variants_xs.sv'), gen_pmp_module('PMP_xs'))
    w(os.path.join(UT, 'PMP', 'tb.sv'), gen_pmp_tb())
    w(os.path.join(UT, 'PMP', 'Makefile'),
      'MODULE = PMP\n'
      'RTL_DIR = ../../../rtl\n'
      'GOLDEN_RTL = ../../../golden/chisel-rtl\n'
      'RTL_SRCS = $(RTL_DIR)/memblock/pmp_pkg.sv $(RTL_DIR)/memblock/PMP.sv\n'
      'WRAPPER_SRCS = $(RTL_DIR)/memblock/PMP_wrapper.sv\n'
      'GOLDEN_SRCS = $(GOLDEN_RTL)/PMP.sv\n'
      'TB_SRCS = variants_xs.sv tb.sv\n'
      'FM_VARIANTS = PMP\n'
      '# PMA 的 16 个 mask 寄存器低 12 位恒为 0xFFF（NAPOT 粒度），merge-dup pass 会把这些\n'
      '# 常量位跨条目误并、并在 wrapper/u_core 层次边界两侧做不对称常量传播，导致两个输出\n'
      '# 端口 io_pma_0/10_mask 误判 fail（寄存器本身全部等价）。关掉合并即干净比对。\n'
      'FM_MERGE_DUP = false\n'
      'include ../../../scripts/ut_common.mk\n')

    # PMPChecker: 组合变体(PMPChecker) + 寄存变体(PMPChecker_10)
    w(os.path.join(RTL, 'PMPChecker_wrapper.sv'),
      gen_chk_module('PMPChecker', False) + '\n' + gen_chk_module('PMPChecker_10', True))
    w(os.path.join(UT, 'PMPChecker', 'variants_xs.sv'),
      gen_chk_module('PMPChecker_xs', False) + '\n' + gen_chk_module('PMPChecker_10_xs', True))
    w(os.path.join(UT, 'PMPChecker', 'tb.sv'), gen_chk_tb('PMPChecker', False))
    w(os.path.join(UT, 'PMPChecker', 'tb_10.sv'), gen_chk_tb('PMPChecker_10', True))
    w(os.path.join(UT, 'PMPChecker', 'Makefile'),
      'MODULE = PMPChecker\n'
      'RTL_DIR = ../../../rtl\n'
      'GOLDEN_RTL = ../../../golden/chisel-rtl\n'
      'RTL_SRCS = $(RTL_DIR)/memblock/pmp_pkg.sv $(RTL_DIR)/memblock/PMPChecker.sv\n'
      'WRAPPER_SRCS = $(RTL_DIR)/memblock/PMPChecker_wrapper.sv\n'
      'GOLDEN_SRCS = $(GOLDEN_RTL)/PMPChecker.sv\n'
      'TB_SRCS = variants_xs.sv tb.sv\n'
      'FM_VARIANTS = PMPChecker PMPChecker_10\n'
      'include ../../../scripts/ut_common.mk\n'
      '\n'
      '# 寄存变体 PMPChecker_10 的独立 UT（组合变体走默认 compile/run）\n'
      'SEED ?= 1\n'
      'compile10: simv10\n'
      'simv10: $(RTL_SRCS) $(WRAPPER_SRCS) variants_xs.sv tb_10.sv $(GOLDEN_RTL)/PMPChecker_10.sv\n'
      '\t$(VCS) $(RTL_SRCS) $(WRAPPER_SRCS) $(GOLDEN_RTL)/PMPChecker_10.sv variants_xs.sv tb_10.sv -top tb -o simv10\n'
      'run10: simv10\n'
      '\t./simv10 +ntb_random_seed=$(SEED) -l sim10.log\n'
      '\t@grep -q "TEST PASSED" sim10.log && echo "=== UT PASSED (PMPChecker_10) ===" \\\n'
      '\t\t|| { echo "=== UT FAILED (PMPChecker_10) ==="; exit 1; }\n'
      '.PHONY: compile10 run10\n')

if __name__ == '__main__':
    main()

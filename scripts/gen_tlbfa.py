#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 生成 TLBFA / TLBFA_1 的 golden 同名 wrapper、xs 变体包装、tb、Makefile。
# 可读核心 (rtl/memblock/TLBFA.sv, tlbfa_pkg.sv) 手写，本脚本只产出机械的扁平
# 端口适配层（golden 扁平端口 <-> 可读核 xs_TLBFA_core 的 struct/数组端口）与
# 验证 harness。
#
# 关键点：firtool 对 golden 各变体/各 dup 的 perm/g_perm/ppn/pbmt/s2xlate 输出做了
#   非均匀死代码裁剪（只暴露下游真正用到的位）。因此 wrapper 的“输出端口集合”不能
#   写死，而是直接从 golden RTL 解析（单一真相源），逐变体精确对齐。
#   输入端口在两变体里都齐全，按已知布局生成即可。
#
# 两个变体：
#   TLBFA   : PORTS=3 NDUPS=1 NWAYS=48
#   TLBFA_1 : PORTS=4 NDUPS=2 NWAYS=48
#
# 用法： python3 scripts/gen_tlbfa.py
import os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
RTL  = os.path.join(ROOT, 'rtl', 'memblock')
UT   = os.path.join(ROOT, 'verif', 'ut')
GOLD = os.path.join(ROOT, 'golden', 'chisel-rtl')

NWAYS  = 48
WAY_W  = 6
CONTIG = 8

VARIANTS = {
    'TLBFA':   dict(PORTS=3, NDUPS=1),
    'TLBFA_1': dict(PORTS=4, NDUPS=2),
}

def decl(width, name, dir_):
    w = '' if width == 1 else f'[{width-1}:0] '
    return f'  {dir_} {w}{name}'

# ---------------------------------------------------------------------------
# 解析 golden 模块端口（保持原始顺序），返回 [(dir, width, name), ...]
# ---------------------------------------------------------------------------
def parse_golden_ports(modname):
    path = os.path.join(GOLD, modname + '.sv')
    txt = open(path).read()
    m = re.search(r'^module %s\(\s*(.*?)^\);' % re.escape(modname), txt, re.S | re.M)
    body = m.group(1)
    out = []
    for line in body.splitlines():
        line = line.strip().rstrip(',')
        if not line:
            continue
        mm = re.match(r'(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)', line)
        if not mm:
            continue
        d = mm.group(1)
        w = (int(mm.group(2)) + 1) if mm.group(2) else 1
        out.append((d, w, mm.group(4)))
    return out

# ---------------------------------------------------------------------------
# 把一个 io_r_resp_<p>_bits_<grp>[_<dup>][_<field>] 输出名映射到核内信号表达式
# ---------------------------------------------------------------------------
def out_to_core_expr(name):
    # access
    m = re.match(r'io_access_(\d+)_touch_ways_(valid|bits)$', name)
    if m:
        i, fld = int(m.group(1)), m.group(2)
        return f'acc_{fld}[{i}]'
    m = re.match(r'io_r_resp_(\d+)_bits_hit$', name)
    if m:
        return f'resp_hit[{int(m.group(1))}]'
    m = re.match(r'io_r_resp_(\d+)_bits_(ppn|pbmt|g_pbmt|s2xlate)_(\d+)$', name)
    if m:
        p, grp, d = int(m.group(1)), m.group(2), int(m.group(3))
        return f'resp_{grp}[{p}][{d}]'
    m = re.match(r'io_r_resp_(\d+)_bits_(perm|g_perm)_(\d+)_(\w+)$', name)
    if m:
        p, grp, d, fld = int(m.group(1)), m.group(2), int(m.group(3)), m.group(4)
        return f'resp_{grp}[{p}][{d}].{fld}'
    raise ValueError('unmapped output ' + name)

# ---------------------------------------------------------------------------
# 输入端口（两变体齐全），按 golden 布局生成
# ---------------------------------------------------------------------------
def input_ports(P):
    p = []
    p += [decl(1,'clock','input'), decl(1,'reset','input')]
    p += [decl(1,'io_sfence_valid','input'), decl(1,'io_sfence_bits_rs1','input'),
          decl(1,'io_sfence_bits_rs2','input'), decl(50,'io_sfence_bits_addr','input'),
          decl(16,'io_sfence_bits_id','input'), decl(1,'io_sfence_bits_hv','input'),
          decl(1,'io_sfence_bits_hg','input')]
    p += [decl(16,'io_csr_satp_asid','input'), decl(16,'io_csr_vsatp_asid','input'),
          decl(16,'io_csr_hgatp_vmid','input'), decl(1,'io_csr_priv_virt','input')]
    for i in range(P):
        p += [decl(1,f'io_r_req_{i}_valid','input'), decl(38,f'io_r_req_{i}_bits_vpn','input'),
              decl(2,f'io_r_req_{i}_bits_s2xlate','input')]
    p += [decl(1,'io_w_valid','input'), decl(WAY_W,'io_w_bits_wayIdx','input'),
          decl(2,'io_w_bits_data_s2xlate','input'),
          decl(35,'io_w_bits_data_s1_entry_tag','input'),
          decl(16,'io_w_bits_data_s1_entry_asid','input'),
          decl(14,'io_w_bits_data_s1_entry_vmid','input'),
          decl(1,'io_w_bits_data_s1_entry_n','input'),
          decl(2,'io_w_bits_data_s1_entry_pbmt','input')]
    for f in ['d','a','g','u','x','w','r']:
        p.append(decl(1,f'io_w_bits_data_s1_entry_perm_{f}','input'))
    p += [decl(2,'io_w_bits_data_s1_entry_level','input'),
          decl(1,'io_w_bits_data_s1_entry_v','input'),
          decl(41,'io_w_bits_data_s1_entry_ppn','input')]
    for k in range(CONTIG): p.append(decl(3,f'io_w_bits_data_s1_ppn_low_{k}','input'))
    for k in range(CONTIG): p.append(decl(1,f'io_w_bits_data_s1_valididx_{k}','input'))
    for k in range(CONTIG): p.append(decl(1,f'io_w_bits_data_s1_pteidx_{k}','input'))
    p += [decl(1,'io_w_bits_data_s1_pf','input'), decl(1,'io_w_bits_data_s1_af','input'),
          decl(38,'io_w_bits_data_s2_entry_tag','input'),
          decl(14,'io_w_bits_data_s2_entry_vmid','input'),
          decl(1,'io_w_bits_data_s2_entry_n','input'),
          decl(2,'io_w_bits_data_s2_entry_pbmt','input'),
          decl(38,'io_w_bits_data_s2_entry_ppn','input')]
    for f in ['d','a','g','u','x','w','r']:
        p.append(decl(1,f'io_w_bits_data_s2_entry_perm_{f}','input'))
    p += [decl(2,'io_w_bits_data_s2_entry_level','input'),
          decl(1,'io_w_bits_data_s2_gpf','input'), decl(1,'io_w_bits_data_s2_gaf','input')]
    return p

# 完整端口列表（顺序对齐 golden）：输入按布局 + 输出从 golden 解析
def ports(modname, P):
    gp = parse_golden_ports(modname)
    out_decls = [decl(w, n, 'output') for (d, w, n) in gp if d == 'output']
    return input_ports(P) + out_decls

# 输入/输出端口名+宽度（tb 用）
def port_names_io(modname, P):
    ins, outs = [], []
    for pl in input_ports(P):
        toks = pl.split(); name = toks[-1]
        if name in ('clock','reset'): continue
        w = 1
        for t in toks:
            if t.startswith('['): w = int(t[1:t.index(':')]) + 1
        ins.append((name, w))
    for (d, w, n) in parse_golden_ports(modname):
        if d == 'output': outs.append((n, w))
    return ins, outs

# ---------------------------------------------------------------------------
# wrapper：扁平端口 <-> 核 struct/数组端口
# ---------------------------------------------------------------------------
def gen_wrapper(modname, golden_name, P, D, core='xs_TLBFA_core'):
    outs = [(w, n) for (d, w, n) in parse_golden_ports(golden_name) if d == 'output']
    s = []
    s.append('// 自动生成：scripts/gen_tlbfa.py —— 勿手改')
    s.append('// TLBFA golden 同名 / xs 变体扁平包装：扁平端口 <-> 可读核 struct/数组端口。')
    s.append('// 输出端口集合按 golden 实测裁剪结果生成（firtool 死代码消除非均匀）。')
    s.append(f'module {modname} import xs_tlbfa_pkg::*; (')
    s.append(',\n'.join(ports(golden_name, P)))
    s.append(');')
    s.append(f'  tlb_req_t      req       [{P}];')
    s.append(f'  logic          req_valid [{P}];')
    s.append(f'  logic          resp_valid[{P}];')
    s.append(f'  logic          resp_hit  [{P}];')
    s.append(f'  logic [35:0]   resp_ppn    [{P}][{D}];')
    s.append(f'  logic [1:0]    resp_pbmt   [{P}][{D}];')
    s.append(f'  logic [1:0]    resp_g_pbmt [{P}][{D}];')
    s.append(f'  tlb_perm_t     resp_perm   [{P}][{D}];')
    s.append(f'  tlb_gperm_t    resp_g_perm [{P}][{D}];')
    s.append(f'  logic [1:0]    resp_s2xlate[{P}][{D}];')
    s.append('  tlb_refill_t   wdata;')
    s.append(f'  logic          acc_valid [{P}];')
    s.append(f'  logic [{WAY_W-1}:0] acc_bits  [{P}];')
    s.append('  always_comb begin')
    for i in range(P):
        s.append(f'    req[{i}].vpn = io_r_req_{i}_bits_vpn;')
        s.append(f'    req[{i}].s2xlate = io_r_req_{i}_bits_s2xlate;')
        s.append(f'    req_valid[{i}] = io_r_req_{i}_valid;')
    s.append('    wdata.s1_entry_tag  = io_w_bits_data_s1_entry_tag;')
    s.append('    wdata.s1_entry_asid = io_w_bits_data_s1_entry_asid;')
    s.append('    wdata.s1_entry_vmid = io_w_bits_data_s1_entry_vmid;')
    s.append('    wdata.s1_entry_n    = io_w_bits_data_s1_entry_n;')
    s.append('    wdata.s1_entry_pbmt = io_w_bits_data_s1_entry_pbmt;')
    s.append("    wdata.s1_entry_perm = '0;")
    for f in ['d','a','g','u','x','w','r']:
        s.append(f'    wdata.s1_entry_perm.{f} = io_w_bits_data_s1_entry_perm_{f};')
    s.append('    wdata.s1_entry_level = io_w_bits_data_s1_entry_level;')
    s.append('    wdata.s1_entry_v     = io_w_bits_data_s1_entry_v;')
    s.append('    wdata.s1_entry_ppn   = io_w_bits_data_s1_entry_ppn;')
    for k in range(CONTIG):
        s.append(f'    wdata.s1_ppn_low[{k}] = io_w_bits_data_s1_ppn_low_{k};')
        s.append(f'    wdata.s1_valididx[{k}] = io_w_bits_data_s1_valididx_{k};')
        s.append(f'    wdata.s1_pteidx[{k}]   = io_w_bits_data_s1_pteidx_{k};')
    s.append('    wdata.s1_pf = io_w_bits_data_s1_pf;')
    s.append('    wdata.s1_af = io_w_bits_data_s1_af;')
    s.append('    wdata.s2_entry_tag  = io_w_bits_data_s2_entry_tag;')
    s.append('    wdata.s2_entry_vmid = io_w_bits_data_s2_entry_vmid;')
    s.append('    wdata.s2_entry_n    = io_w_bits_data_s2_entry_n;')
    s.append('    wdata.s2_entry_pbmt = io_w_bits_data_s2_entry_pbmt;')
    s.append('    wdata.s2_entry_ppn  = io_w_bits_data_s2_entry_ppn;')
    s.append("    wdata.s2_entry_perm = '0;")
    for f in ['d','a','g','u','x','w','r']:
        s.append(f'    wdata.s2_entry_perm.{f} = io_w_bits_data_s2_entry_perm_{f};')
    s.append('    wdata.s2_entry_level = io_w_bits_data_s2_entry_level;')
    s.append('    wdata.s2_gpf = io_w_bits_data_s2_gpf;')
    s.append('    wdata.s2_gaf = io_w_bits_data_s2_gaf;')
    s.append('    wdata.s2xlate = io_w_bits_data_s2xlate;')
    s.append('  end')
    s.append(f'  {core} #(.PORTS({P}), .NDUPS({D}), .NWAYS({NWAYS}), .WAY_W({WAY_W})) u_core (')
    s.append('    .clock(clock), .reset(reset),')
    s.append('    .io_sfence_valid(io_sfence_valid), .io_sfence_bits_rs1(io_sfence_bits_rs1),')
    s.append('    .io_sfence_bits_rs2(io_sfence_bits_rs2), .io_sfence_bits_addr(io_sfence_bits_addr),')
    s.append('    .io_sfence_bits_id(io_sfence_bits_id), .io_sfence_bits_hv(io_sfence_bits_hv),')
    s.append('    .io_sfence_bits_hg(io_sfence_bits_hg),')
    s.append('    .io_csr_satp_asid(io_csr_satp_asid), .io_csr_vsatp_asid(io_csr_vsatp_asid),')
    s.append('    .io_csr_hgatp_vmid(io_csr_hgatp_vmid), .io_csr_priv_virt(io_csr_priv_virt),')
    s.append('    .io_r_req(req), .io_r_req_valid(req_valid),')
    s.append('    .io_r_resp_valid(resp_valid), .io_r_resp_hit(resp_hit),')
    s.append('    .io_r_resp_ppn(resp_ppn), .io_r_resp_pbmt(resp_pbmt), .io_r_resp_g_pbmt(resp_g_pbmt),')
    s.append('    .io_r_resp_perm(resp_perm), .io_r_resp_g_perm(resp_g_perm), .io_r_resp_s2xlate(resp_s2xlate),')
    s.append('    .io_w_valid(io_w_valid), .io_w_bits_wayIdx(io_w_bits_wayIdx), .io_w_bits_data(wdata),')
    s.append('    .io_access_touch_ways_valid(acc_valid), .io_access_touch_ways_bits(acc_bits)')
    s.append('  );')
    # 输出：按 golden 实际暴露的端口逐一接核内表达式
    for (w, n) in outs:
        s.append(f'  assign {n} = {out_to_core_expr(n)};')
    s.append('endmodule')
    return '\n'.join(s) + '\n'

# ---------------------------------------------------------------------------
# Testbench：golden vs xs 双例化，随机激励，逐拍比对所有输出
# ---------------------------------------------------------------------------
def gen_tb(golden_mod, P, D):
    ins, outs = port_names_io(golden_mod, P)
    out_names = set(n for (n, w) in outs)
    s = []
    s.append('// 自动生成：scripts/gen_tlbfa.py —— 勿手改')
    s.append('`timescale 1ns/1ps')
    s.append('module tb;')
    s.append('  int unsigned NVEC = 60000;')
    s.append('  int errors = 0, checks = 0;')
    s.append('  logic clock = 0, reset;')
    s.append('  always #5 clock = ~clock;')
    for (n, w) in ins:
        ww = '' if w == 1 else f'[{w-1}:0] '
        s.append(f'  logic {ww}{n};')
    for (n, w) in outs:
        ww = '' if w == 1 else f'[{w-1}:0] '
        s.append(f'  wire {ww}g_{n};  wire {ww}i_{n};')
    def inst(mod, pfx):
        conns = ['.clock(clock)', '.reset(reset)']
        for (n, w) in ins: conns.append(f'.{n}({n})')
        for (n, w) in outs: conns.append(f'.{n}({pfx}{n})')
        return f'  {mod} u_{pfx} (' + ', '.join(conns) + ');'
    s.append(inst(golden_mod, 'g_'))
    s.append(inst(golden_mod + '_xs', 'i_'))
    s.append('  task automatic do_check(int t);')
    s.append('    checks++;')
    for i in range(P):
        hitn = f'io_r_resp_{i}_bits_hit'
        s.append(f'    if (g_{hitn} !== i_{hitn}) begin errors++;')
        s.append(f'      if(errors<=60) $display("vec %0d {hitn} g=%b i=%b",t,g_{hitn},i_{hitn}); end')
        # resp.* 仅在两侧 hit 时比（命中才有意义；未命中 ppn/perm 是 don't care）
        for (n, w) in outs:
            if n.startswith(f'io_r_resp_{i}_bits_') and n != hitn:
                s.append(f'    if (g_{hitn} && (g_{n} !== i_{n})) begin errors++;')
                s.append(f'      if(errors<=60) $display("vec %0d {n} g=%h i=%h",t,g_{n},i_{n}); end')
        av = f'io_access_{i}_touch_ways_valid'; ab = f'io_access_{i}_touch_ways_bits'
        s.append(f'    if (g_{av} !== i_{av}) begin errors++;')
        s.append(f'      if(errors<=60) $display("vec %0d {av} g=%b i=%b",t,g_{av},i_{av}); end')
        s.append(f'    if (g_{av} && (g_{ab} !== i_{ab})) begin errors++;')
        s.append(f'      if(errors<=60) $display("vec %0d {ab} g=%h i=%h",t,g_{ab},i_{ab}); end')
    s.append('  endtask')
    s.append('  task automatic drive_random();')
    s.append('    automatic int act = $urandom_range(0,9);')
    for i in range(P):
        s.append(f'    io_r_req_{i}_valid = $urandom_range(0,1);')
        s.append(f'    io_r_req_{i}_bits_vpn = {{$urandom, $urandom}};')
        s.append(f'    io_r_req_{i}_bits_s2xlate = ($urandom_range(0,1)) ? 2\'($urandom_range(0,3)) : 2\'b0;')
    s.append('    io_w_valid = ($urandom_range(0,3) == 0);')
    s.append(f"    io_w_bits_wayIdx = {WAY_W}'($urandom_range(0,{NWAYS-1}));")
    s.append('    io_w_bits_data_s2xlate = 2\'($urandom_range(0,3));')
    s.append('    io_w_bits_data_s1_entry_tag = {$urandom};')
    s.append('    io_w_bits_data_s1_entry_asid = 16\'($urandom);')
    s.append('    io_w_bits_data_s1_entry_vmid = 14\'($urandom);')
    s.append('    io_w_bits_data_s1_entry_n = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s1_entry_pbmt = 2\'($urandom);')
    for f in ['d','a','g','u','x','w','r']:
        s.append(f'    io_w_bits_data_s1_entry_perm_{f} = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s1_entry_level = 2\'($urandom_range(0,2));')
    s.append('    io_w_bits_data_s1_entry_v = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s1_entry_ppn = {$urandom, $urandom};')
    for k in range(CONTIG):
        s.append(f'    io_w_bits_data_s1_ppn_low_{k} = 3\'($urandom);')
        s.append(f'    io_w_bits_data_s1_valididx_{k} = $urandom_range(0,1);')
        s.append(f'    io_w_bits_data_s1_pteidx_{k} = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s1_pf = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s1_af = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s2_entry_tag = {$urandom};')
    s.append('    io_w_bits_data_s2_entry_vmid = 14\'($urandom);')
    s.append('    io_w_bits_data_s2_entry_n = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s2_entry_pbmt = 2\'($urandom);')
    s.append('    io_w_bits_data_s2_entry_ppn = {$urandom};')
    for f in ['d','a','g','u','x','w','r']:
        s.append(f'    io_w_bits_data_s2_entry_perm_{f} = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s2_entry_level = 2\'($urandom_range(0,2));')
    s.append('    io_w_bits_data_s2_gpf = $urandom_range(0,1);')
    s.append('    io_w_bits_data_s2_gaf = $urandom_range(0,1);')
    s.append('    io_sfence_valid = (act == 0);')
    s.append('    io_sfence_bits_rs1 = $urandom_range(0,1);')
    s.append('    io_sfence_bits_rs2 = $urandom_range(0,1);')
    s.append('    io_sfence_bits_addr = {$urandom, $urandom};')
    s.append('    io_sfence_bits_id = 16\'($urandom);')
    s.append('    io_sfence_bits_hv = $urandom_range(0,1);')
    s.append('    io_sfence_bits_hg = $urandom_range(0,1);')
    s.append('    io_csr_satp_asid = 16\'($urandom);')
    s.append('    io_csr_vsatp_asid = 16\'($urandom);')
    s.append('    io_csr_hgatp_vmid = 16\'($urandom);')
    s.append('    io_csr_priv_virt = $urandom_range(0,1);')
    s.append('  endtask')
    s.append('  initial begin')
    s.append('    reset = 1; io_w_valid = 0; io_sfence_valid = 0;')
    for i in range(P):
        s.append(f'    io_r_req_{i}_valid = 0;')
    s.append('    io_csr_satp_asid=0; io_csr_vsatp_asid=0; io_csr_hgatp_vmid=0; io_csr_priv_virt=0;')
    s.append('    io_sfence_bits_rs1=0; io_sfence_bits_rs2=0; io_sfence_bits_addr=0;')
    s.append('    io_sfence_bits_id=0; io_sfence_bits_hv=0; io_sfence_bits_hg=0;')
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
    var_all = []
    for name, prm in VARIANTS.items():
        P, D = prm['PORTS'], prm['NDUPS']
        w(os.path.join(RTL, f'{name}_wrapper.sv'), gen_wrapper(name, name, P, D))
        var_all.append(gen_wrapper(name + '_xs', name, P, D))
    w(os.path.join(UT, 'TLBFA', 'variants_xs.sv'), '\n'.join(var_all))
    w(os.path.join(UT, 'TLBFA', 'tb.sv'), gen_tb('TLBFA', 3, 1))
    w(os.path.join(UT, 'TLBFA', 'tb_1.sv'), gen_tb('TLBFA_1', 4, 2))

    mk = []
    mk.append('MODULE = TLBFA')
    mk.append('RTL_DIR = ../../../rtl')
    mk.append('GOLDEN_RTL = ../../../golden/chisel-rtl')
    mk.append('RTL_SRCS = $(RTL_DIR)/memblock/tlbfa_pkg.sv $(RTL_DIR)/memblock/TLBFA.sv')
    mk.append('WRAPPER_SRCS = $(RTL_DIR)/memblock/TLBFA_wrapper.sv $(RTL_DIR)/memblock/TLBFA_1_wrapper.sv')
    mk.append('GOLDEN_SRCS = $(GOLDEN_RTL)/TLBFA.sv')
    mk.append('TB_SRCS = variants_xs.sv tb.sv')
    mk.append('FM_VARIANTS = TLBFA TLBFA_1')
    mk.append('# 纯叶子逻辑，关合并以免跨条目常量误并影响签名比对')
    mk.append('FM_MERGE_DUP = false')
    mk.append('include ../../../scripts/ut_common.mk')
    mk.append('')
    mk.append('# 变体 TLBFA_1 的独立 UT（默认 compile/run 跑 TLBFA）')
    mk.append('SEED ?= 1')
    mk.append('compile1: simv1')
    mk.append('simv1: $(RTL_SRCS) $(WRAPPER_SRCS) variants_xs.sv tb_1.sv $(GOLDEN_RTL)/TLBFA_1.sv')
    mk.append('\t$(VCS) $(RTL_SRCS) $(RTL_DIR)/memblock/TLBFA_1_wrapper.sv $(GOLDEN_RTL)/TLBFA_1.sv variants_xs.sv tb_1.sv -top tb -o simv1')
    mk.append('run1: simv1')
    mk.append('\t./simv1 +ntb_random_seed=$(SEED) -l sim1.log')
    mk.append('\t@grep -q "TEST PASSED" sim1.log && echo "=== UT PASSED (TLBFA_1) ===" \\')
    mk.append('\t\t|| { echo "=== UT FAILED (TLBFA_1) ==="; exit 1; }')
    mk.append('.PHONY: compile1 run1')
    mk.append('')
    w(os.path.join(UT, 'TLBFA', 'Makefile'), '\n'.join(mk) + '\n')

if __name__ == '__main__':
    main()

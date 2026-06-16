#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 生成 TlbStorageWrapper / TlbStorageWrapper_1 的 golden 同名 wrapper、xs 变体包装、
# tb、Makefile。
#
# 可读核心手写：
#   rtl/memblock/tlbstoragewrapper_pkg.sv  —— Tree-PLRU 类型 + 纯函数
#   rtl/memblock/TlbStorageWrapper.sv      —— xs_TlbStorageWrapper_core（仅 PLRU 替换器）
#
# 本脚本只产出机械的“端口适配 + 黑盒例化”层：
#   - golden 同名 wrapper(TlbStorageWrapper / _1)：例化 **golden 黑盒 TLBFA / TLBFA_1**
#     做存储与匹配（按要求 UT/FM 内层用 golden TLBFA 黑盒），把 TLBFA 的 io_access
#     反馈接到可读核 xs_TlbStorageWrapper_core 求替换 wayIdx，再回灌 TLBFA 的
#     io_w_bits_wayIdx。其余 r/sfence/csr/wdata 端口对 TLBFA 全透传。
#   - xs 变体包装(_xs)：同结构，供 UT 与 golden TlbStorageWrapper 逐拍比对。
#
# golden TlbStorageWrapper 内部例化的是 golden TLBFA；wrapper 的端口集合（含 firtool
#   对各端口 resp 的非均匀死代码裁剪）直接从 golden RTL 解析，保证逐变体精确对齐。
#
# 两个变体：
#   TlbStorageWrapper   : PORTS=3
#   TlbStorageWrapper_1 : PORTS=4
#
# 用法： python3 scripts/gen_tlbstoragewrapper.py
import os, re

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
RTL  = os.path.join(ROOT, 'rtl', 'memblock')
UT   = os.path.join(ROOT, 'verif', 'ut')
GOLD = os.path.join(ROOT, 'golden', 'chisel-rtl')

NWAYS = 48
WAY_W = 6

VARIANTS = {
    'TlbStorageWrapper':   dict(PORTS=3, TLBFA='TLBFA'),
    'TlbStorageWrapper_1': dict(PORTS=4, TLBFA='TLBFA_1'),
}

# ---------------------------------------------------------------------------
# 解析 golden 模块端口（保持原始顺序），返回 [(dir, width, name), ...]
# ---------------------------------------------------------------------------
def parse_golden_ports(modname):
    txt = open(os.path.join(GOLD, modname + '.sv')).read()
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

def decl(d, w, n):
    ww = '' if w == 1 else f'[{w-1}:0] '
    return f'  {d} {ww}{n}'

# ---------------------------------------------------------------------------
# wrapper：golden 同名（或 _xs）。例化 golden 黑盒 TLBFA + 可读 PLRU 核。
#   wrapper 端口 = golden TlbStorageWrapper 端口（透传，无 wayIdx）。
#   TLBFA 例化的所有端口（除 io_w_bits_wayIdx 与 io_access_*）都与 wrapper 同名直连；
#   io_access_* 由本地 wire 承接喂给 PLRU 核；io_w_bits_wayIdx 由 PLRU 核回灌。
# ---------------------------------------------------------------------------
# 从 golden 顶层解析内层 TLBFA 的例化实例名（如 page_itlb_storage_fa），
#   impl 侧沿用同名 → 内层 TLBFA 寄存器层次路径与 ref 一致，FM 自动按名配对。
def golden_storage_inst(golden_name, tlbfa):
    txt = open(os.path.join(GOLD, golden_name + '.sv')).read()
    m = re.search(r'%s\s+(\w+)\s*\(' % re.escape(tlbfa), txt)
    return m.group(1)

def gen_wrapper(modname, golden_name, P, tlbfa):
    gp = parse_golden_ports(golden_name)               # wrapper 透传端口
    tp = parse_golden_ports(tlbfa)                      # 内层 TLBFA 端口
    wrapper_names = set(n for (_, _, n) in gp)
    storage_inst = golden_storage_inst(golden_name, tlbfa)
    s = []
    s.append('// 自动生成：scripts/gen_tlbstoragewrapper.py —— 勿手改')
    s.append('// TlbStorageWrapper golden 同名 / xs 变体包装：')
    s.append('//   例化 golden 黑盒 TLBFA 做存储匹配 + 可读 PLRU 核 xs_TlbStorageWrapper_core 做替换。')
    s.append('//   wayIdx 内部产生（PLRU），其余端口对 TLBFA 全透传。')
    s.append(f'module {modname} import xs_tlbsw_pkg::*; (')
    s.append(',\n'.join(decl(d, w, n) for (d, w, n) in gp))
    s.append(');')
    s.append('')
    # 承接 TLBFA 的 access 反馈（扁平 valid/bits）→ 打包成 tlb_access_t 数组喂给替换核；
    #   PLRU 算出 victim wayIdx 回灌 TLBFA。
    s.append(f'  logic        acc_valid [{P}];')
    s.append(f'  logic [{WAY_W-1}:0] acc_bits  [{P}];')
    s.append(f'  tlb_access_t access    [{P}];')
    s.append(f'  logic [{WAY_W-1}:0] refill_wayIdx;')
    s.append('  always_comb begin')
    s.append(f'    for (int i = 0; i < {P}; i++) begin')
    s.append('      access[i].valid = acc_valid[i];')
    s.append('      access[i].way   = acc_bits[i];')
    s.append('    end')
    s.append('  end')
    s.append('')
    # ---- 内层 golden 黑盒 TLBFA 例化（实例名沿用 golden，便于 FM 层次配对）----
    s.append(f'  {tlbfa} {storage_inst} (')
    conns = []
    for (d, w, n) in tp:
        if n == 'io_w_bits_wayIdx':
            conns.append(f'    .{n}(refill_wayIdx)')
        elif n.startswith('io_access_') and n.endswith('_touch_ways_valid'):
            i = int(re.match(r'io_access_(\d+)_', n).group(1))
            conns.append(f'    .{n}(acc_valid[{i}])')
        elif n.startswith('io_access_') and n.endswith('_touch_ways_bits'):
            i = int(re.match(r'io_access_(\d+)_', n).group(1))
            conns.append(f'    .{n}(acc_bits[{i}])')
        else:
            # 其余端口与 wrapper 同名直连（clock/reset/r/sfence/csr/wdata/resp）
            assert n in wrapper_names, f'TLBFA port {n} not on wrapper'
            conns.append(f'    .{n}({n})')
    s.append(',\n'.join(conns))
    s.append('  );')
    s.append('')
    # ---- 可读 PLRU 替换核（实例名 u_core：FM 自动配对会剥离该层次）----
    s.append(f'  xs_TlbStorageWrapper_core #(.PORTS({P}), .WAYS({NWAYS}), .WW({WAY_W})) u_core (')
    s.append('    .clock(clock), .reset(reset),')
    s.append('    .io_access(access),')
    s.append('    .io_w_bits_wayIdx(refill_wayIdx)')
    s.append('  );')
    s.append('endmodule')
    return '\n'.join(s) + '\n'

# ---------------------------------------------------------------------------
# Testbench：golden TlbStorageWrapper vs xs 双例化，随机激励，逐拍比对所有输出。
#   两侧内层都是 golden 黑盒 TLBFA（同一份），因此差异只可能来自 PLRU/wayIdx；
#   但 wayIdx 是内部信号，外部体现为 refill 写到哪一路 → 经后续查询/access 暴露。
#   比对所有 wrapper 输出端口（resp.* 仅 hit 时比，access.* valid 时比 bits）。
# ---------------------------------------------------------------------------
def gen_tb(golden_mod, P):
    gp = parse_golden_ports(golden_mod)
    ins  = [(n, w) for (d, w, n) in gp if d == 'input'  and n not in ('clock', 'reset')]
    outs = [(n, w) for (d, w, n) in gp if d == 'output']
    s = []
    s.append('// 自动生成：scripts/gen_tlbstoragewrapper.py —— 勿手改')
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
        c = ['.clock(clock)', '.reset(reset)']
        for (n, w) in ins:  c.append(f'.{n}({n})')
        for (n, w) in outs: c.append(f'.{n}({pfx}{n})')
        return f'  {mod} u_{pfx} (' + ', '.join(c) + ');'
    s.append(inst(golden_mod, 'g_'))
    s.append(inst(golden_mod + '_xs', 'i_'))
    # 比对
    s.append('  task automatic do_check(int t);')
    s.append('    checks++;')
    for i in range(P):
        hitn = f'io_r_resp_{i}_bits_hit'
        s.append(f'    if (g_{hitn} !== i_{hitn}) begin errors++;')
        s.append(f'      if(errors<=80) $display("vec %0d {hitn} g=%b i=%b",t,g_{hitn},i_{hitn}); end')
        for (n, w) in outs:
            if n.startswith(f'io_r_resp_{i}_bits_') and n != hitn:
                s.append(f'    if (g_{hitn} && (g_{n} !== i_{n})) begin errors++;')
                s.append(f'      if(errors<=80) $display("vec %0d {n} g=%h i=%h",t,g_{n},i_{n}); end')
    s.append('  endtask')
    # 随机激励：与 TLBFA tb 同源，外加 wrapper 不暴露 wayIdx（内部 PLRU 决定）。
    s.append('  task automatic drive_random();')
    s.append('    automatic int act = $urandom_range(0,9);')
    for i in range(P):
        s.append(f'    io_r_req_{i}_valid = $urandom_range(0,1);')
        s.append(f'    io_r_req_{i}_bits_vpn = {{$urandom, $urandom}};')
        s.append(f'    io_r_req_{i}_bits_s2xlate = ($urandom_range(0,1)) ? 2\'($urandom_range(0,3)) : 2\'b0;')
    s.append('    io_w_valid = ($urandom_range(0,3) == 0);')
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
    for k in range(8):
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
        P, tlbfa = prm['PORTS'], prm['TLBFA']
        w(os.path.join(RTL, f'{name}_wrapper.sv'), gen_wrapper(name, name, P, tlbfa))
        var_all.append(gen_wrapper(name + '_xs', name, P, tlbfa))
    w(os.path.join(UT, 'TlbStorageWrapper', 'variants_xs.sv'), '\n'.join(var_all))
    w(os.path.join(UT, 'TlbStorageWrapper', 'tb.sv'),   gen_tb('TlbStorageWrapper', 3))
    w(os.path.join(UT, 'TlbStorageWrapper', 'tb_1.sv'), gen_tb('TlbStorageWrapper_1', 4))

    # 公共源（可读核 + golden 黑盒 TLBFA）
    PKG  = '$(RTL_DIR)/memblock/tlbstoragewrapper_pkg.sv'
    CORE = '$(RTL_DIR)/memblock/TlbStorageWrapper.sv'
    # golden 黑盒 TLBFA（内层存储）：UT/FM 都用 golden
    GTLBFA  = '$(GOLDEN_RTL)/TLBFA.sv'
    GTLBFA1 = '$(GOLDEN_RTL)/TLBFA_1.sv'

    mk = []
    mk.append('MODULE = TlbStorageWrapper')
    mk.append('RTL_DIR = ../../../rtl')
    mk.append('GOLDEN_RTL = ../../../golden/chisel-rtl')
    mk.append(f'RTL_SRCS = {PKG} {CORE}')
    # WRAPPER_SRCS 仅 FM 用（不进 UT 编译）。impl 侧 wrapper 例化 golden 黑盒 TLBFA，
    #   故把两份 golden TLBFA 一并给 impl，使 ref/impl 两侧 TLBFA 都解析为同一实现，
    #   FM 只需证明外围 PLRU/wayIdx 路由等价。
    mk.append('WRAPPER_SRCS = $(RTL_DIR)/memblock/TlbStorageWrapper_wrapper.sv \\')
    mk.append('               $(RTL_DIR)/memblock/TlbStorageWrapper_1_wrapper.sv \\')
    mk.append(f'               {GTLBFA} {GTLBFA1}')
    # 内层 golden 黑盒 TLBFA + golden 顶层做对照
    # variants_xs.sv 同时含两变体 _xs（分别例化 golden TLBFA / TLBFA_1），故默认编译
    #   需把两份 golden 黑盒 TLBFA 都带上。
    mk.append(f'GOLDEN_SRCS = $(GOLDEN_RTL)/TlbStorageWrapper.sv {GTLBFA} {GTLBFA1}')
    mk.append('TB_SRCS = variants_xs.sv tb.sv')
    mk.append('FM_VARIANTS = TlbStorageWrapper TlbStorageWrapper_1')
    # FM：ref = golden 顶层 + 其依赖 golden TLBFA；impl = 可读核 + wrapper + 同一 golden TLBFA
    mk.append('FM_REF_DEPS_TlbStorageWrapper = TLBFA.sv')
    mk.append('FM_REF_DEPS_TlbStorageWrapper_1 = TLBFA_1.sv')
    # 内层 golden TLBFA 含 48 条目对称寄存器，关合并以免两侧不对称合并导致误配/漏配
    #   （与 TLBFA UT 同理）。
    mk.append('FM_MERGE_DUP = false')
    mk.append('include ../../../scripts/ut_common.mk')
    mk.append('')
    mk.append('# 变体 _1 的独立 UT（默认 compile/run 跑变体 0）')
    mk.append('SEED ?= 1')
    mk.append('compile1: simv1')
    mk.append(f'simv1: $(RTL_SRCS) $(WRAPPER_SRCS) variants_xs.sv tb_1.sv $(GOLDEN_RTL)/TlbStorageWrapper_1.sv {GTLBFA} {GTLBFA1}')
    mk.append(f'\t$(VCS) $(RTL_SRCS) $(RTL_DIR)/memblock/TlbStorageWrapper_1_wrapper.sv $(GOLDEN_RTL)/TlbStorageWrapper_1.sv {GTLBFA} {GTLBFA1} variants_xs.sv tb_1.sv -top tb -o simv1')
    mk.append('run1: simv1')
    mk.append('\t./simv1 +ntb_random_seed=$(SEED) -l sim1.log')
    mk.append('\t@grep -q "TEST PASSED" sim1.log && echo "=== UT PASSED (TlbStorageWrapper_1) ===" \\')
    mk.append('\t\t|| { echo "=== UT FAILED (TlbStorageWrapper_1) ==="; exit 1; }')
    mk.append('.PHONY: compile1 run1')
    mk.append('')
    w(os.path.join(UT, 'TlbStorageWrapper', 'Makefile'), '\n'.join(mk) + '\n')

if __name__ == '__main__':
    main()

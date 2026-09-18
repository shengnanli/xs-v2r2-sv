#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 TLBFA 家族 UT 的 tb.sv（四个变体各一对 golden / 重写 DUT，同激励逐拍全比）。

为什么生成而不是手写：四个变体合计 588 个端口，例化连线 + 逐端口比对 + 失配定位
共约 1500 行纯机械代码。手抄一处漏连，UT 会**照样 errors=0**（漏比的那根线没人看），
正是本工程反复踩到的"看起来在验、实际没在验"。端口表与例化全部从 G1 golden 的
模块头机械展开，漏连在结构上不可能发生。

激励与判据（手写部分）在 STIM 模板里，见 tb.sv 顶部注释。
用法: python3 verif/ut/TLBFA/gen.py
"""
import os
import re
import sys

G = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
HERE = os.path.dirname(os.path.abspath(__file__))
VARIANTS = [('TLBFA', 3), ('TLBFA_1', 4), ('TLBFA_2', 2), ('TLBFA_3', 2)]
PORT = re.compile(r'^\s*(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)\s*,?\s*$')

SIMPLE = {
    'clock': 'clk', 'reset': 'rst',
    'io_sfence_valid': 'sf_valid', 'io_sfence_bits_rs1': 'sf_rs1',
    'io_sfence_bits_rs2': 'sf_rs2', 'io_sfence_bits_addr': 'sf_addr',
    'io_sfence_bits_id': 'sf_id', 'io_sfence_bits_hv': 'sf_hv',
    'io_sfence_bits_hg': 'sf_hg',
    'io_csr_satp_asid': 'csr_satp_asid', 'io_csr_vsatp_asid': 'csr_vsatp_asid',
    'io_csr_hgatp_vmid': 'csr_hgatp_vmid', 'io_csr_mbmc_BME': 'csr_bme',
    'io_csr_mbmc_CMODE': 'csr_cmode', 'io_csr_priv_virt': 'csr_virt',
    'io_w_valid': 'w_valid', 'io_w_bits_wayIdx': 'w_way',
    'io_w_bits_data_s2xlate': 'w_s2xlate',
    'io_w_bits_data_s1_pf': 'w_s1_pf', 'io_w_bits_data_s1_af': 'w_s1_af',
    'io_w_bits_data_s2_gpf': 'w_s2_gpf', 'io_w_bits_data_s2_gaf': 'w_s2_gaf',
}


def golden_ports(name):
    text = open(os.path.join(G, f'{name}.sv')).read()
    m = re.search(rf'^module {name}\(\n(.*?)^\);', text, re.S | re.M)
    if not m:
        sys.exit(f'{name}: 找不到模块头')
    out = []
    for ln in m.group(1).splitlines():
        pm = PORT.match(ln)
        if not pm:
            sys.exit(f'{name}: 端口行解析失败 {ln!r}')
        d, msb, lsb, pname = pm.groups()
        out.append((d, int(msb) + 1 if msb else 1, pname))
    return out


def stim_of(p):
    """输入端口 -> tb 激励信号表达式。"""
    if p in SIMPLE:
        return SIMPLE[p]
    m = re.fullmatch(r'io_r_req_(\d+)_valid', p)
    if m:
        return f'rq_valid[{m.group(1)}]'
    m = re.fullmatch(r'io_r_req_(\d+)_bits_vpn', p)
    if m:
        return f'rq_vpn[{m.group(1)}]'
    m = re.fullmatch(r'io_r_req_(\d+)_bits_s2xlate', p)
    if m:
        return f'rq_s2x[{m.group(1)}]'
    m = re.fullmatch(r'io_w_bits_data_s(\d)_entry_(\w+)', p)
    if m:
        return f'w_s{m.group(1)}_entry_{m.group(2)}'
    m = re.fullmatch(r'io_w_bits_data_s1_(ppn_low|valididx|pteidx)_(\d+)', p)
    if m:
        return f'w_s1_{m.group(1)}[{m.group(2)}]'
    sys.exit(f'未知输入端口 {p}')


def main():
    L = []
    A = L.append
    A(HEADER)
    # ---- 每个变体：输出线声明 + 两个 DUT 例化 + 全输出打包 ----
    for name, nports in VARIANTS:
        ports = golden_ports(name)
        outs = [(w, p) for d, w, p in ports if d == 'output']
        A(f'  // ------------------------------------------------------------------')
        A(f'  //  {name}: PORTS={nports}，{len(ports)} 端口（{len(outs)} 个输出逐拍全比）')
        A(f'  // ------------------------------------------------------------------')
        for w, p in outs:
            wid = f'[{w-1}:0] ' if w > 1 else ''
            A(f'  wire {wid}g_{name}_{p}, x_{name}_{p};')
        A('')
        for pref, mod in (('g', name), ('x', name + '_xs')):
            A(f'  {mod} u_{pref}_{name} (')
            conn = []
            for d, w, p in ports:
                rhs = stim_of(p) if d == 'input' else f'{pref}_{name}_{p}'
                conn.append(f'    .{p}({rhs})')
            A(',\n'.join(conn))
            A('  );')
            A('')
        total = sum(w for w, _ in outs)
        A(f'  wire [{total-1}:0] gall_{name} = {{' +
          ', '.join(f'g_{name}_{p}' for _, p in outs) + '};')
        A(f'  wire [{total-1}:0] xall_{name} = {{' +
          ', '.join(f'x_{name}_{p}' for _, p in outs) + '};')
        A('')
        # 失配定位：只在失配那拍逐端口打印
        A(f'  task automatic diff_{name}();')
        for w, p in outs:
            A(f'    if (g_{name}_{p} !== x_{name}_{p}) '
              f'$display("    {name}.{p}: g=%h x=%h", g_{name}_{p}, x_{name}_{p});')
        A('  endtask')
        A('')
    # ---- 比对与覆盖 ----
    A('  // ==================================================================')
    A('  //  逐拍比对（时钟低电平中段采样，组合输出已稳定）')
    A('  // ==================================================================')
    A('  always @(negedge clk) if (!rst && warm) begin')
    A('    #4;')
    A('    checks++;')
    for name, _ in VARIANTS:
        A(f'    if (gall_{name} !== xall_{name}) begin')
        A(f'      errors++;')
        A(f'      if (errors <= 20) begin')
        A(f'        $display("[%0t] {name} MISMATCH", $time);')
        A(f'        diff_{name}();')
        A('      end')
        A('    end')
    A('  end')
    A('')
    # ---- 覆盖：命中/按 s2xlate 分桶/golden 内部 v 位（XMR，只读 golden 侧）----
    A('  // ==================================================================')
    A('  //  覆盖计数（★全部取自 golden 侧★：impl 自己说自己覆盖到了不算数）')
    A('  //  golden 的 48 个 valid 位用层次引用读出来，用来证明 sfence 真的刷掉过项、')
    A('  //  以及阵列真的被填满过——否则"两边都不命中"也能凑出 errors=0。')
    A('  // ==================================================================')
    for name, np in VARIANTS:
        A(f'  wire [47:0] vbits_{name} = {{' +
          ', '.join(f'u_g_{name}.v_{47-i}' for i in range(48)) + '};')
    A('  // 多命中（sector TLB 允许一个请求同时命中多条 entry；golden 用 Mux1H = 按位或，')
    A('  // 不是优先选择）。这条覆盖专门回答"本 UT 到底有没有制造出多命中"。')
    A('  wire [47:0] hitvec0_TLBFA = {' +
      ', '.join(f'u_g_TLBFA.hitVecReg_{47-i}' for i in range(48)) + '};')
    A('')
    A('  int cov_multihit = 0;')
    A('  // fence 形态四桶：[0]=sfence.vma [1]=hfence.vvma [2]=hfence.gvma [3]=hv&hg 同置')
    A('  int cov_fence [4] = ' + "'" + '{default: 0};')
    A('  int cov_hvhg = 0, cov_sf_w = 0;   // 两个纯激励侧的角落：hv&hg 同拍、sfence 与 refill 同拍')
    for name, np in VARIANTS:
        A(f'  int cov_hit_{name} = 0, cov_touch_{name} = 0, cov_flush_{name} = 0;')
        A(f'  int cov_occ_{name} = 0, cov_ppnnz_{name} = 0;')
        A('  int cov_s2x_' + name + ' [4] = ' + "'" + '{default: 0};')
        A(f'  int prev_occ_{name} = 0;')
    A('')
    A('  always @(posedge clk) if (!rst) begin : cov_blk')
    A('    int occ;')
    for name, np in VARIANTS:
        A(f'    occ = $countones(vbits_{name});')
        A(f'    if (occ > cov_occ_{name}) cov_occ_{name} = occ;')
        A(f'    if (occ < prev_occ_{name}) cov_flush_{name}++;')
        A(f'    prev_occ_{name} = occ;')
        for p in range(np):
            A(f'    if (g_{name}_io_r_resp_{p}_bits_hit) begin')
            A(f'      cov_hit_{name}++;')
            A(f'      if (g_{name}_io_r_resp_{p}_bits_ppn_0 != 0) cov_ppnnz_{name}++;')
            if any(pp == f'io_r_resp_{p}_bits_s2xlate_0' for _, _, pp in golden_ports(name)):
                A(f'      cov_s2x_{name}[g_{name}_io_r_resp_{p}_bits_s2xlate_0]++;')
            A('    end')
            A(f'    if (g_{name}_io_access_{p}_touch_ways_valid) cov_touch_{name}++;')
    A('    if ($countones(hitvec0_TLBFA) > 1) cov_multihit++;')
    A('    if (sf_valid) cov_fence[{sf_hg, sf_hv}]++;')
    A('    if (sf_valid && sf_hv && sf_hg) cov_hvhg++;')
    A('    if (sf_valid && w_valid) cov_sf_w++;')
    A('  end')
    A('')
    # ---- 覆盖门槛：数字标在这里，改不动就是改不动（收尾判据引用它们）----
    A('  // 覆盖门槛（按 200k 拍标定；实测值见 sim_*.log 的 [cov] 行）。')
    A('  // TH_OCC=30 而不是 48：sfence/hfence 约占 3%，阵列被反复刷掉，48 条同时有效')
    A('  // 在这套激励下不会出现（实测峰值 37）。门槛要卡在"确实填起来过"，不是卡在理想值。')
    A('  localparam int TH_HIT = 20000, TH_TOUCH = 20000, TH_FLUSH = 500;')
    A('  localparam int TH_OCC = 30, TH_PPNNZ = 20000, TH_S2X = 1000, TH_CORNER = 200;')
    A('')
    A('  function automatic void print_cov();')
    A('    $display("[cov] fence    sfence=%0d hfence.vvma=%0d hfence.gvma=%0d hv&hg=%0d",')
    A('             cov_fence[0], cov_fence[1], cov_fence[2], cov_fence[3]);')
    A('    $display("[cov] corner   hv&hg=%0d sfence+refill 同拍=%0d 多命中(TLBFA port0)=%0d",')
    A('             cov_hvhg, cov_sf_w, cov_multihit);')
    for name, np in VARIANTS:
        has_s2x = any(pp.endswith('_bits_s2xlate_0') for _, _, pp in golden_ports(name))
        s2x = (" s2x=[%0d %0d %0d %0d]" if has_s2x else "")
        args = (f', cov_s2x_{name}[0], cov_s2x_{name}[1], cov_s2x_{name}[2], cov_s2x_{name}[3]'
                if has_s2x else '')
        A(f'    $display("[cov] {name:<8} hit=%0d touch=%0d flush=%0d occ_max=%0d ppn!=0=%0d{s2x}",')
        A(f'             cov_hit_{name}, cov_touch_{name}, cov_flush_{name}, '
          f'cov_occ_{name}, cov_ppnnz_{name}{args});')
    A('  endfunction')
    A('')
    A('  function automatic bit cov_ok();')
    A('    bit ok = 1;')
    A('    for (int k = 0; k < 4; k++) if (cov_fence[k] < TH_CORNER) begin ok = 0; '
      '$display("[cov] FAIL fence 形态 %0d 只出现 %0d 次 < %0d", k, cov_fence[k], TH_CORNER); end')
    A('    if (cov_multihit < TH_CORNER) begin ok = 0; '
      '$display("[cov] FAIL 多命中=%0d < %0d", cov_multihit, TH_CORNER); end')
    A('    if (cov_hvhg < TH_CORNER) begin ok = 0; '
      '$display("[cov] FAIL hv&hg=%0d < %0d", cov_hvhg, TH_CORNER); end')
    A('    if (cov_sf_w < TH_CORNER) begin ok = 0; '
      '$display("[cov] FAIL sfence+refill=%0d < %0d", cov_sf_w, TH_CORNER); end')
    for name, np in VARIANTS:
        A(f'    if (cov_hit_{name}   < TH_HIT)   begin ok = 0; '
          f'$display("[cov] FAIL {name} hit=%0d < %0d", cov_hit_{name}, TH_HIT); end')
        A(f'    if (cov_touch_{name} < TH_TOUCH) begin ok = 0; '
          f'$display("[cov] FAIL {name} touch=%0d < %0d", cov_touch_{name}, TH_TOUCH); end')
        A(f'    if (cov_flush_{name} < TH_FLUSH) begin ok = 0; '
          f'$display("[cov] FAIL {name} flush=%0d < %0d", cov_flush_{name}, TH_FLUSH); end')
        A(f'    if (cov_occ_{name}   < TH_OCC)   begin ok = 0; '
          f'$display("[cov] FAIL {name} occ_max=%0d < %0d", cov_occ_{name}, TH_OCC); end')
        A(f'    if (cov_ppnnz_{name} < TH_PPNNZ) begin ok = 0; '
          f'$display("[cov] FAIL {name} ppn!=0=%0d < %0d", cov_ppnnz_{name}, TH_PPNNZ); end')
        if any(pp.endswith('_bits_s2xlate_0') for _, _, pp in golden_ports(name)):
            A(f'    for (int k = 0; k < 4; k++) if (cov_s2x_{name}[k] < TH_S2X) begin ok = 0; '
              f'$display("[cov] FAIL {name} s2x[%0d]=%0d < %0d", k, cov_s2x_{name}[k], TH_S2X); end')
    A('    return ok;')
    A('  endfunction')
    A('')
    A(STIM)
    open(os.path.join(HERE, 'tb.sv'), 'w').write('\n'.join(L))
    print('wrote verif/ut/TLBFA/tb.sv')


HEADER = r'''// =============================================================================
// TLBFA 家族 UT —— 四个变体各一对 DUT（golden 与重写件 <名>_xs）同激励逐拍全比。
//
// ★本文件由 verif/ut/TLBFA/gen.py 生成，勿手改★（手改会被下一次跑生成器静默删掉）
//
// 比对口径：每个变体把**全部输出端口**拼成一根大向量逐拍比（不是挑几根比），
//   失配那拍再逐端口打印差异。采样点在时钟低电平中段（#4），组合输出已稳定。
//
// 激励要点（要让 TLB 真的命中，随机不能是纯随机）：
//   · 地址取自一个 24 项的 vpn 池，池内高位大量重合 —— 这样 refill 与查询会撞上，
//     且超页（level>0 只比高位）也能命中；低 3 位单独随机以搅动 sector 内的
//     valididx / pteidx / ppn_low 选择。
//   · s2xlate 四种取值均匀出现；命中要求 entry.s2xlate 与请求**完全相等**，
//     所以读写用同一分布才有命中率。
//   · asid/vmid/priv.virt 在 0..3 的小值域里变，保证 asid_hit / vmid_hit 两条路
//     既有命中也有不命中。
//   · sfence / hfence.vvma / hfence.gvma 各约 1%，rs1/rs2 组合均匀。
//   · refill 约 25%，与 sfence 会同拍撞上（golden 的优先级：sfence 赢，entry 照写
//     但 v 不置位）——这个角落靠随机自然覆盖，覆盖计数里有它。
//
// 收尾判据：errors==0 **并且**覆盖门槛全部达标（见 TEST PASSED 那段）。
//   只有 errors==0 是不够的：本工程踩过"两边都不动、比的是一串 0"的假绿。
// =============================================================================
`timescale 1ns/1ps

module tb;

  int unsigned NCYCLES = 200000;
  bit clk = 0, rst = 1;
  bit warm = 0;            // 复位后的热身窗口：两侧无复位寄存器的随机初值不同，
                           // 要等第一次 req/refill 把它们冲成确定值后才开始比
  int errors = 0, checks = 0;

  always #5 clk = ~clk;

  // ---- 共享激励信号 ----
  logic        sf_valid, sf_rs1, sf_rs2, sf_hv, sf_hg;
  logic [49:0] sf_addr;
  logic [15:0] sf_id;
  logic [15:0] csr_satp_asid, csr_vsatp_asid, csr_hgatp_vmid;
  logic        csr_bme, csr_cmode, csr_virt;

  logic [3:0]        rq_valid;
  logic [3:0][37:0]  rq_vpn;
  logic [3:0][1:0]   rq_s2x;

  logic        w_valid;
  logic [5:0]  w_way;
  logic [1:0]  w_s2xlate;
  logic [34:0] w_s1_entry_tag;
  logic [15:0] w_s1_entry_asid;
  logic [13:0] w_s1_entry_vmid;
  logic        w_s1_entry_n;
  logic [1:0]  w_s1_entry_pbmt;
  logic        w_s1_entry_perm_d, w_s1_entry_perm_a, w_s1_entry_perm_g;
  logic        w_s1_entry_perm_u, w_s1_entry_perm_x, w_s1_entry_perm_w, w_s1_entry_perm_r;
  logic [1:0]  w_s1_entry_level;
  logic        w_s1_entry_v;
  logic [40:0] w_s1_entry_ppn;
  logic [7:0][2:0] w_s1_ppn_low;
  logic [7:0]  w_s1_valididx, w_s1_pteidx;
  logic        w_s1_pf, w_s1_af;
  logic [37:0] w_s2_entry_tag;
  logic [13:0] w_s2_entry_vmid;
  logic        w_s2_entry_n;
  logic [1:0]  w_s2_entry_pbmt;
  logic [37:0] w_s2_entry_ppn;
  logic        w_s2_entry_perm_d, w_s2_entry_perm_a, w_s2_entry_perm_g;
  logic        w_s2_entry_perm_u, w_s2_entry_perm_x, w_s2_entry_perm_w, w_s2_entry_perm_r;
  logic [1:0]  w_s2_entry_level;
  logic        w_s2_gpf, w_s2_gaf;
'''

STIM = r'''  // ==================================================================
  //  激励生成
  // ==================================================================
  localparam int POOLN = 24;
  logic [37:0] pool [POOLN];

  initial begin
    // vpn 池：高 11 位只有 3 种、次高 9 位只有 4 种 —— 高位大量重合，
    // 这样 1GB/512GB 超页（只比高位）也能被命中，而不是只测 4KB 精确匹配。
    for (int i = 0; i < POOLN; i++)
      pool[i] = {11'(i % 3), 9'((i / 3) % 4), 9'(i % 5), 9'((i * 37) % 512)};
  end

  function automatic logic [37:0] pick_vpn();
    logic [37:0] a;
    a = pool[$urandom_range(0, POOLN - 1)];
    if ($urandom_range(0, 9) == 0) a = 38'($urandom);   // 10% 纯随机，制造未命中
    a[2:0] = 3'($urandom);                              // sector 内位置单独随机
    return a;
  endfunction

  function automatic logic [1:0] pick_level();
    int r = $urandom_range(0, 9);
    if (r < 6) return 2'd0;                             // 4KB 占多数
    else if (r < 8) return 2'd1;
    else if (r < 9) return 2'd2;
    else return 2'd3;
  endfunction

  function automatic logic [7:0] pick_idxvec(input bit onehot_bias);
    int r = $urandom_range(0, 9);
    if (onehot_bias && r < 6) return 8'(1 << $urandom_range(0, 7));
    if (r < 8) return 8'hFF;
    return 8'($urandom);
  endfunction

  always @(negedge clk) begin
    logic [37:0] a;
    int          kind;
    if (rst) begin
      rq_valid <= 4'hF;      // 复位期间也发请求：把两侧的 hitVecReg 冲成确定的 0
      rq_vpn   <= '0;
      rq_s2x   <= '0;
      w_valid  <= 1'b0;
      sf_valid <= 1'b0;
      sf_hv    <= 1'b0;
      sf_hg    <= 1'b0;
      csr_satp_asid  <= 16'd1;
      csr_vsatp_asid <= 16'd2;
      csr_hgatp_vmid <= 16'd1;
      csr_bme   <= 1'b0;
      csr_cmode <= 1'b0;
      csr_virt  <= 1'b0;
    end else begin
      // --- CSR 现场：偶尔换一次 ---
      if ($urandom_range(0, 999) < 8) begin
        csr_satp_asid  <= 16'($urandom_range(0, 3));
        csr_vsatp_asid <= 16'($urandom_range(0, 3));
        csr_hgatp_vmid <= 16'($urandom_range(0, 3));
        csr_virt       <= 1'($urandom_range(0, 1));
        csr_bme        <= ($urandom_range(0, 9) < 3);
        csr_cmode      <= 1'($urandom_range(0, 1));
      end

      // --- 查询：4 路各自独立 ---
      for (int p = 0; p < 4; p++) begin
        rq_valid[p] <= ($urandom_range(0, 9) < 8);
        rq_vpn[p]   <= pick_vpn();
        rq_s2x[p]   <= 2'($urandom_range(0, 3));
      end

      // --- refill ---
      w_valid   <= ($urandom_range(0, 99) < 25);
      w_way     <= 6'($urandom_range(0, 47));
      w_s2xlate <= 2'($urandom_range(0, 3));
      a = pool[$urandom_range(0, POOLN - 1)];
      w_s1_entry_tag  <= a[37:3];
      w_s2_entry_tag  <= {a[37:3], 3'($urandom)};
      w_s1_entry_asid <= 16'($urandom_range(0, 3));
      w_s1_entry_vmid <= 14'($urandom_range(0, 3));
      w_s2_entry_vmid <= 14'($urandom_range(0, 3));
      w_s1_entry_n    <= ($urandom_range(0, 9) < 2);
      w_s2_entry_n    <= ($urandom_range(0, 9) < 2);
      w_s1_entry_level <= pick_level();
      w_s2_entry_level <= pick_level();
      w_s1_entry_pbmt <= 2'($urandom);
      w_s2_entry_pbmt <= 2'($urandom);
      w_s1_entry_ppn  <= 41'($urandom);
      w_s2_entry_ppn  <= 38'($urandom);
      w_s1_entry_v    <= ($urandom_range(0, 9) < 7);
      w_s1_pf         <= ($urandom_range(0, 9) < 2);
      w_s1_af         <= ($urandom_range(0, 9) < 2);
      w_s2_gpf        <= ($urandom_range(0, 9) < 2);
      w_s2_gaf        <= ($urandom_range(0, 9) < 2);
      {w_s1_entry_perm_d, w_s1_entry_perm_a, w_s1_entry_perm_g, w_s1_entry_perm_u,
       w_s1_entry_perm_x, w_s1_entry_perm_w, w_s1_entry_perm_r} <= 7'($urandom);
      {w_s2_entry_perm_d, w_s2_entry_perm_a, w_s2_entry_perm_g, w_s2_entry_perm_u,
       w_s2_entry_perm_x, w_s2_entry_perm_w, w_s2_entry_perm_r} <= 7'($urandom);
      for (int k = 0; k < 8; k++) w_s1_ppn_low[k] <= 3'($urandom);
      w_s1_valididx <= pick_idxvec(1'b0);
      w_s1_pteidx   <= pick_idxvec(1'b1);

      // --- sfence / hfence：约 3%，三种指令各约 1% ---
      if ($urandom_range(0, 99) < 3) begin
        // kind==3 = hv 与 hg **同时**置位。父级 TLB 不会这么发，但 golden 对这种
        // 输入有确定行为（else-if 链里 hg 排在最前 => hg 赢），所以模块级比对必须覆盖它：
        // 不覆盖的话，把两支优先级写反的重写件照样 errors=0（实测：这正是 M2 变异体）。
        //
        // ★ kind 的声明与赋值必须分开 ★：always 块里变量默认是 **static** 生命期，
        // `int kind = $urandom_range(0,3);` 的初值只在 0 时刻算**一次**，此后永远不变。
        // 实测（本 UT 第一版）：seed=1 整轮 6000 次 sfence **全是** kind=3，
        // seed=7 整轮一次 kind=3 都没有（[cov] hv&hg=0）——三条 fence 指令里
        // 每轮只测了一种，而 errors=0 照样打印。这正是"看起来在验、实际没在验"。
        kind = $urandom_range(0, 3);
        sf_valid <= 1'b1;
        sf_hv    <= (kind == 1) || (kind == 3);
        sf_hg    <= (kind == 2) || (kind == 3);
        sf_rs1   <= 1'($urandom_range(0, 1));
        sf_rs2   <= 1'($urandom_range(0, 1));
        sf_addr  <= {pool[$urandom_range(0, POOLN - 1)], 12'($urandom)};
        sf_id    <= 16'($urandom_range(0, 3));
      end else begin
        sf_valid <= 1'b0;
      end
    end
  end

  // ==================================================================
  //  主控
  // ==================================================================
  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    if ($test$plusargs("fsdb")) begin
      $fsdbDumpfile("novas.fsdb");
      $fsdbDumpvars(0, tb);
    end

    rst = 1;
    warm = 0;
    repeat (8) @(posedge clk);
    rst = 0;
    repeat (8) @(posedge clk);   // 热身：让无复位寄存器被写成确定值
    warm = 1;

    repeat (NCYCLES / 2) @(posedge clk);

    // 中途复位（正常宽度）：验复位后 entry 还在、但 v=0 所以读不出来
    @(negedge clk);
    rst = 1;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst = 0;

    repeat (NCYCLES / 4) @(posedge clk);

    // ★单拍复位毛刺★：rst 在两个上升沿**之间**起落，期间没有任何时钟沿。
    // golden 的 v 是 `always @(posedge clock or posedge reset)`（异步），会当场清零；
    // 写成同步复位的实现则完全看不见这次复位 —— 只有这种激励能把两者区分开。
    // （本 UT 的 M6 变异体就是把异步改成同步，不加这一段它抓不出来。）
    repeat (2) begin
      @(posedge clk);
      #1 rst = 1;
      #3 rst = 0;
      repeat (20) @(posedge clk);
    end

    repeat (NCYCLES / 4) @(posedge clk);

    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    print_cov();
    if (errors == 0 && checks > 10000 && cov_ok())
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end

endmodule
'''


if __name__ == '__main__':
    main()

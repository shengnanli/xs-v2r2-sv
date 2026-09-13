#!/usr/bin/env python3
"""gen_ut.py —— 从 G1 golden 端口表生成 Composer / Predictor 的双例化 UT tb。

装配壳有 828 / 633 根端口，tb 手写必错，所以端口声明、两侧例化、逐拍比对这三段
从 golden 端口表现取现生成；激励策略与覆盖闸是手写的（见下面的 DRIVE/COVER 段）。

**为什么这个 tb 必须带覆盖闸**：Composer 有两类东西"光比输出比不出来"——
  1. MBIST 的 boreChildrenBd_bore_{2..5}_addr 这一轮由 9 位收窄到 8 位。若激励只驱动
     低位，写宽了写窄了都照过。所以要数最高位被打到多少次，并数 outdata 真的被比过
     多少次（比不到就如实报"UT 观测不到"，不许假装验过）。
  2. s1/s2/s3 影子 PC 流水（SegmentedAddrNext）是 **cone-dead** 的：它的值不出现在
     任何输出端口上。只比输出等于完全没验它。所以 tb 额外做**层次探针比对**，把两侧
     29 个内部寄存器逐拍比。
"""
import os
import re
import sys

GOLDEN = os.environ.get('GOLDEN_RTL', '/home/eda/xs-env/G1-canonical/golden-rtl')
REPO = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def parse_ports(mod):
    src = re.sub(r'//[^\n]*', '', open(os.path.join(GOLDEN, mod + '.sv'),
                                       errors='replace').read())
    m = re.search(r'^module\s+' + mod + r'\s*\((.*?)^\);', src, re.S | re.M)
    if not m:
        sys.exit(f'FATAL: 找不到 module {mod}')
    out = []
    for c in m.group(1).split(','):
        d = ' '.join(c.split())
        if not d:
            continue
        mm = re.match(r'(input|output|inout)\s*(?:wire|reg|logic)?\s*'
                      r'(\[[^\]]*\]\s*)?([A-Za-z_]\w*)$', d)
        if not mm:
            sys.exit(f'FATAL: 端口解析失败 {d!r}')
        rng = (mm.group(2) or '').strip()
        w = 1
        if rng:
            hi, lo = rng[1:-1].split(':')
            w = int(hi) - int(lo) + 1
        out.append((mm.group(3), mm.group(1), rng, w))
    return out


def decl(rng, w):
    return f'{rng:<10s}' if rng else ' ' * 10


HEADER = '''// Composer UT —— golden Composer 与重写 Composer_xs 双例化逐拍比对。
//
// 【为什么不能只比输出】
//   Composer 是装配壳：293 个输出里 282 个是子模块直连（两侧接的是同一份 golden
//   子模块，天然一致），真正由本层算出来的只有 11 个。如果只比输出，等于只验了
//   那 11 根，而且下面两块**一根输出都不经过**：
//     · MBIST boreChildrenBd_bore_{{2..5}}_addr 这轮由 9 位收窄到 8 位 —— 激励不打
//       最高位就等于没验位宽（本轮已发生过 3 次"位宽错但 UT 照过"）；
//     · s1/s2/s3 影子 PC 流水（utility.SegmentedAddrNext）是 cone-dead 的，值不出现
//       在任何输出上。
//   所以本 tb 除逐拍比 293 个输出外，另加：
//     (a) 层次探针：两侧 29 个内部寄存器（modified_reset / s1_pc×4 / s2、s3 各 12 段）
//         逐拍比 —— 把 cone-dead 那条链直接钉住；
//     (b) 覆盖闸：关键事件计数为 0 即判 FAIL（见文件尾的判定段）。
//
// 【激励设计要点】
//   · s0_pc 大部分拍只在低 12 位小步走（让 SegmentedAddrNext 的高段"没变"分支生效），
//     少数拍整段跳（让"变了"分支生效）—— 两条分支都要打到。
//   · reset 在运行中反复拉起放下，让 modified_reset 那一拍脉冲被反复观测
//     （G1 相对 G0 正是把这个脉冲提前了一拍，只复位一次就只有一次机会看到）。
//   · MBIST addr / addr_rd 全宽随机，最高位必须被打到。
//
// 自动生成：tools/predictor_composer/gen_ut.py —— 勿手改
`timescale 1ns/1ps
`define CHECK(SIG) begin \\
  if (!$isunknown(g_``SIG)) begin \\
    checks++; \\
    if (g_``SIG !== i_``SIG) begin \\
      errors++; \\
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \\
    end \\
  end \\
end
`define CHECKH(NAME, G, I) begin \\
  if (!$isunknown(G)) begin \\
    hchecks++; \\
    if ((G) !== (I)) begin \\
      herrors++; \\
      if (herrors <= 30) $display("[%0t] HIER MISMATCH %s g=%0h i=%0h", $time, NAME, G, I); \\
    end \\
  end \\
end
'''


def main():
    mod = sys.argv[1] if len(sys.argv) > 1 else 'Composer'
    ports = parse_ports(mod)
    ins = [p for p in ports if p[1] == 'input' and p[0] not in ('clock', 'reset')]
    outs = [p for p in ports if p[1] == 'output']

    L = [HEADER.format()]
    L.append('module tb;')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  bit clock = 0;')
    L.append('  logic reset;')
    L.append('  int errors = 0, checks = 0;')
    L.append('  int herrors = 0, hchecks = 0;')
    L.append('  always #5 clock = ~clock;')
    L.append('')
    L.append('  // ---- 覆盖计数（0 即判 FAIL，见文件尾）----')
    L.append('  logic [3:0] fire_s0, fire_s1, fire_s2;   // 采样用临时向量')
    L.append('  int reset_pulses = 0;            // 复位放开次数（每次给 modified_reset 一次脉冲）')
    L.append('  int mres_hi = 0;                 // 观测到 modified_reset==1 的拍数')
    L.append('  int s0f[4], s1f[4], s2f[4];      // 各 dup 的 fire 拍数')
    L.append('  int seg_hi_same = 0, seg_hi_diff = 0;   // s2 高段"没变/变了"两条分支')
    L.append('  int seg_mid_same = 0, seg_mid_diff = 0;')
    L.append('  int s3_hi_same = 0, s3_hi_diff = 0;')
    L.append('  int mbist_addr_msb[4], mbist_addrrd_msb[4];  // bore2..5 的 addr[7]/addr_rd[7] 命中数')
    L.append('  logic [7:0] mbist_addr_or[4], mbist_addrrd_or[4];  // 逐位或（每位都要翻过）')
    L.append('  int mbist_outdata_checks = 0;    // bore2..5 outdata 真被比到的拍数（X 不算）')
    L.append('  int s1_ready_hi = 0, s1_ready_lo = 0;')
    L.append('  int s1r_lo[3];                   // tage / ftb / ittage 各自为 0 的拍数')
    L.append('  int s1r_only_lo[3];              // 只有这一路为 0（其余两路为 1）的拍数：')
    L.append('                                   // 只有这种拍才能分辨"与门里少了这一路"')
    L.append('  int seg_hi_trap = 0;             // 定向激励命中数（见 drive_random_inputs）')
    L.append('  int btm_hi = 0;                  // uFTB s1 br_taken_mask 出过 1 的拍数（G1 新增旁路给 TAGE）')
    L.append('  int meta_nz = 0;                 // last_stage_meta 非零的拍数')
    L.append('  int perf_nz = 0;                 // 任一 perf 输出非零的拍数')
    L.append('')
    L.append('  // ---- 输入 ----')
    for n, _, rng, w in ins:
        L.append(f'  logic {decl(rng, w)} {n};')
    L.append('')
    L.append('  // ---- 输出（g_ = golden, i_ = 重写）----')
    for n, _, rng, w in outs:
        L.append(f'  wire  {decl(rng, w)} g_{n};')
        L.append(f'  wire  {decl(rng, w)} i_{n};')
    L.append('')

    for pre, inst in (('g_', f'{mod} g_dut'), ('i_', f'{mod}_xs i_dut')):
        L.append(f'  {inst} (')
        conns = []
        for n, d, _, _ in ports:
            if n in ('clock', 'reset'):
                conns.append(f'    .{n} ({n})')
            elif d == 'input':
                conns.append(f'    .{n} ({n})')
            else:
                conns.append(f'    .{n} ({pre}{n})')
        L.append(',\n'.join(conns))
        L.append('  );')
        L.append('')

    # ---- 随机填充 ----
    L.append('  // 宽端口随机填充：$urandom 一次 32 位，按位宽拼够。')
    L.append('  function automatic logic [1023:0] rnd(input int w);')
    L.append('    logic [1023:0] v;')
    L.append('    v = 1024\'b0;')
    L.append('    for (int k = 0; k < (w + 31) / 32; k++) v[k*32 +: 32] = $urandom();')
    L.append('    return v;')
    L.append('  endfunction')
    L.append('')

    # 分类
    pcports = [n for n, _, _, _ in ins if re.match(r'^io_in_bits_s0_pc_\d$', n)]
    ctrl = [n for n, _, _, _ in ins if n.startswith('io_ctrl_')]
    special = set(pcports) | set(ctrl)
    L.append('  // s0_pc 的"基址 + 小步"驱动：大多数拍只动低 12 位（高两段不变 ->')
    L.append('  // SegmentedAddrNext 走"没变"分支），偶尔整段跳（走"变了"分支）。')
    L.append('  logic [49:0] pc_base = 50\'h0;')
    L.append('')
    L.append('  logic [1023:0] rtmp;')
    L.append('  task automatic drive_random_inputs();')
    L.append('    rtmp = rnd(50);')
    L.append('    if ($urandom_range(0, 63) == 0) begin')
    L.append('      pc_base = rtmp[49:0];')
    L.append('    end')
    L.append('    else if ($urandom_range(0, 15) == 0 &&')
    L.append('             !$isunknown(g_dut.s2_pc_dup_s2_pc_seg_0_value)) begin')
    L.append('      // 定向：让 pc[48:23] 恰好等于当前 s2 高段存值。这样"高段比较"若误取')
    L.append('      // [48:23] 就会判成"没变"而漏掉一次更新 —— 随机激励撞不到这种巧合，')
    L.append('      // 只能这样构造（阴性对照里 M4 就是靠它才被抓住的）。')
    L.append('      pc_base = {~g_dut.s2_pc_dup_s2_pc_seg_0_value[25],')
    L.append('                 g_dut.s2_pc_dup_s2_pc_seg_0_value, rtmp[22:0]};')
    L.append('      seg_hi_trap++;')
    L.append('    end')
    L.append('    else                            pc_base = {pc_base[49:12], rtmp[11:0]};')
    for n in pcports:
        L.append('    rtmp = rnd(2);')
        L.append(f'    {n} = pc_base ^ {{48\'h0, rtmp[1:0]}};')
    L.append('    // ctrl 开关大多数时候打开，让各预测器真的在跑')
    for n in ctrl:
        L.append(f'    {n} = ($urandom_range(0, 9) != 0);')
    for n, _, rng, w in ins:
        if n in special:
            continue
        L.append(f'    {n} = rnd({w});')
    L.append('  endtask')
    L.append('')

    L.append('  task automatic check_outputs();')
    for n, _, _, _ in outs:
        L.append(f'    `CHECK({n})')
    L.append('  endtask')
    L.append('')

    # 层次探针（只有 Composer 有这批内部寄存器）
    if mod == 'Composer':
        L.append('  // 层次探针：cone-dead 的影子 PC 流水 + modified_reset，输出端口看不到，')
        L.append('  // 只能这样钉。golden 侧名字直接来自 G1 golden Composer.sv。')
        L.append('  task automatic check_hier();')
        L.append('    `CHECKH("modified_reset", g_dut.modified_reset, i_dut.u_core.modified_reset)')
        for d in range(4):
            sfx = '' if d == 0 else f'_{d}'
            L.append(f'    `CHECKH("s1_pc[{d}]", g_dut.s1_pc_dup_{d}, i_dut.u_core.s1_pc[{d}])')
            for seg, nm in ((0, 'hi'), (1, 'mid'), (2, 'lo')):
                L.append(f'    `CHECKH("s2_pc_{nm}[{d}]", '
                         f'g_dut.s2_pc_dup_s2_pc_seg_{seg}_value{sfx}, '
                         f'i_dut.u_core.s2_pc_{nm}[{d}])')
            for seg, nm in ((0, 'hi'), (1, 'mid'), (2, 'lo')):
                L.append(f'    `CHECKH("s3_pc_{nm}[{d}]", '
                         f'g_dut.s3_pc_dup_s3_pc_seg_{seg}_value{sfx}, '
                         f'i_dut.u_core.s3_pc_{nm}[{d}])')
        L.append('  endtask')
        L.append('')
        L.append('  task automatic sample_coverage();')
        L.append('    if (g_dut.modified_reset === 1\'b1) mres_hi++;')
        L.append('    fire_s0 = {io_s0_fire_3, io_s0_fire_2, io_s0_fire_1, io_s0_fire_0};')
        L.append('    fire_s1 = {io_s1_fire_3, io_s1_fire_2, io_s1_fire_1, io_s1_fire_0};')
        L.append('    fire_s2 = {io_s2_fire_3, io_s2_fire_2, io_s2_fire_1, io_s2_fire_0};')
        L.append('    for (int d = 0; d < 4; d++) begin')
        L.append('      if (fire_s0[d]) s0f[d]++;')
        L.append('      if (fire_s1[d]) s1f[d]++;')
        L.append('      if (fire_s2[d]) s2f[d]++;')
        L.append('    end')
        L.append('    // SegmentedAddrNext 两条分支各自被打到多少次（用 dup0 采样）')
        L.append('    if (!$isunknown(g_dut.s1_pc_dup_0) && !$isunknown(g_dut.s2_pc_dup_s2_pc_seg_0_value)) begin')
        L.append('      if (g_dut.s2_pc_dup_s2_pc_seg_0_value == g_dut.s1_pc_dup_0[49:24]) seg_hi_same++;')
        L.append('      else                                                              seg_hi_diff++;')
        L.append('      if (g_dut.s2_pc_dup_s2_pc_seg_1_value == g_dut.s1_pc_dup_0[23:12]) seg_mid_same++;')
        L.append('      else                                                              seg_mid_diff++;')
        L.append('      if (g_dut.s3_pc_dup_s3_pc_seg_0_value == g_dut.s2_pc_dup_s2_pc_seg_0_value) s3_hi_same++;')
        L.append('      else                                                                       s3_hi_diff++;')
        L.append('    end')
        L.append('    // MBIST：G1 收窄到 8 位的那 4 个 bore 的 addr / addr_rd')
        for k, b in enumerate((2, 3, 4, 5)):
            L.append(f'    if (boreChildrenBd_bore_{b}_addr[7])    mbist_addr_msb[{k}]++;')
            L.append(f'    if (boreChildrenBd_bore_{b}_addr_rd[7]) mbist_addrrd_msb[{k}]++;')
            L.append(f'    mbist_addr_or[{k}]   |= boreChildrenBd_bore_{b}_addr;')
            L.append(f'    mbist_addrrd_or[{k}] |= boreChildrenBd_bore_{b}_addr_rd;')
            L.append(f'    if (!$isunknown(g_boreChildrenBd_bore_{b}_outdata)) mbist_outdata_checks++;')
        L.append('    if (g_io_s1_ready === 1\'b1) s1_ready_hi++; else if (g_io_s1_ready === 1\'b0) s1_ready_lo++;')
        L.append('    if (g_dut._tage_io_s1_ready   === 1\'b0) s1r_lo[0]++;')
        L.append('    if (g_dut._ftb_io_s1_ready    === 1\'b0) s1r_lo[1]++;')
        L.append('    if (g_dut._ittage_io_s1_ready === 1\'b0) s1r_lo[2]++;')
        L.append('    if (!g_dut._tage_io_s1_ready &&  g_dut._ftb_io_s1_ready &&  g_dut._ittage_io_s1_ready) s1r_only_lo[0]++;')
        L.append('    if ( g_dut._tage_io_s1_ready && !g_dut._ftb_io_s1_ready &&  g_dut._ittage_io_s1_ready) s1r_only_lo[1]++;')
        L.append('    if ( g_dut._tage_io_s1_ready &&  g_dut._ftb_io_s1_ready && !g_dut._ittage_io_s1_ready) s1r_only_lo[2]++;')
        L.append('    if (g_io_out_s1_full_pred_0_br_taken_mask_0 === 1\'b1 ||')
        L.append('        g_io_out_s1_full_pred_0_br_taken_mask_1 === 1\'b1) btm_hi++;')
        L.append('    if (!$isunknown(g_io_out_last_stage_meta) && g_io_out_last_stage_meta != 0) meta_nz++;')
        L.append('    if (!$isunknown(g_io_perf_0_value) && (g_io_perf_0_value | g_io_perf_1_value |')
        L.append('        g_io_perf_2_value | g_io_perf_3_value | g_io_perf_4_value |')
        L.append('        g_io_perf_5_value | g_io_perf_6_value) != 0) perf_nz++;')
        L.append('  endtask')
        L.append('')

    L.append('  int unsigned c;')
    L.append('  initial begin')
    L.append('    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end')
    L.append('    for (int d = 0; d < 4; d++) begin s0f[d]=0; s1f[d]=0; s2f[d]=0; end')
    L.append('    for (int k = 0; k < 3; k++) begin s1r_lo[k]=0; s1r_only_lo[k]=0; end')
    L.append('    for (int k = 0; k < 4; k++) begin')
    L.append('      mbist_addr_msb[k]=0; mbist_addrrd_msb[k]=0;')
    L.append('      mbist_addr_or[k]=8\'h0; mbist_addrrd_or[k]=8\'h0;')
    L.append('    end')
    L.append('    reset = 1\'b1;')
    L.append('    drive_random_inputs();')
    for n, _, _, w in ins:
        pass
    L.append('    repeat (8) @(posedge clock);')
    L.append('    reset = 1\'b0; reset_pulses++;')
    L.append('    for (c = 0; c < NCYCLES; c++) begin')
    L.append('      @(negedge clock);')
    L.append('      // 每 ~4000 拍再复位一次：modified_reset 的一拍脉冲要被反复观测')
    L.append('      if (c != 0 && c % 4000 == 0) reset = 1\'b1;')
    L.append('      else if (reset) begin reset = 1\'b0; reset_pulses++; end')
    L.append('      drive_random_inputs();')
    L.append('      @(posedge clock);')
    L.append('      #1;')
    L.append('      check_outputs();')
    if mod == 'Composer':
        L.append('      check_hier();')
        L.append('      sample_coverage();')
    L.append('    end')
    L.append('')
    L.append(f'    $display("{mod} checks=%0d errors=%0d  hier_checks=%0d hier_errors=%0d",')
    L.append('             checks, errors, hchecks, herrors);')
    if mod == 'Composer':
        L.append('    $display("COV reset_pulses=%0d modified_reset_cycles=%0d", reset_pulses, mres_hi);')
        L.append('    $display("COV fire s0=%p s1=%p s2=%p", s0f, s1f, s2f);')
        L.append('    $display("COV seg_hi same=%0d diff=%0d | seg_mid same=%0d diff=%0d | s3_hi same=%0d diff=%0d",')
        L.append('             seg_hi_same, seg_hi_diff, seg_mid_same, seg_mid_diff, s3_hi_same, s3_hi_diff);')
        L.append('    $display("COV mbist addr_msb=%p addr_rd_msb=%p addr_or=%p addr_rd_or=%p outdata_checks=%0d",')
        L.append('             mbist_addr_msb, mbist_addrrd_msb, mbist_addr_or, mbist_addrrd_or, mbist_outdata_checks);')
        L.append('    $display("COV s1_ready hi=%0d lo=%0d src_lo(tage,ftb,ittage)=%p only_lo=%p | br_taken_mask hi=%0d | meta_nz=%0d | perf_nz=%0d | seg_hi_trap=%0d",')
        L.append('             s1_ready_hi, s1_ready_lo, s1r_lo, s1r_only_lo, btm_hi, meta_nz, perf_nz, seg_hi_trap);')
        L.append('')
        L.append('    // ---- 覆盖闸：任一为 0 即判 FAIL（装配层极易假绿）----')
        L.append('    if (reset_pulses < 2 || mres_hi == 0) begin')
        L.append('      $display("COVERAGE HOLE: modified_reset 脉冲没被反复观测");')
        L.append('      $display("TEST FAILED"); $fatal(1);')
        L.append('    end')
        L.append('    for (int d = 0; d < 4; d++)')
        L.append('      if (s0f[d] == 0 || s1f[d] == 0 || s2f[d] == 0) begin')
        L.append('        $display("COVERAGE HOLE: dup %0d 的某一级 fire 从未发生", d);')
        L.append('        $display("TEST FAILED"); $fatal(1);')
        L.append('      end')
        L.append('    if (seg_hi_same == 0 || seg_hi_diff == 0 || seg_mid_same == 0 ||')
        L.append('        seg_mid_diff == 0 || s3_hi_same == 0 || s3_hi_diff == 0) begin')
        L.append('      $display("COVERAGE HOLE: SegmentedAddrNext 的\\"变了/没变\\"两条分支没都打到");')
        L.append('      $display("TEST FAILED"); $fatal(1);')
        L.append('    end')
        L.append('    for (int k = 0; k < 4; k++)')
        L.append('      if (mbist_addr_msb[k] == 0 || mbist_addrrd_msb[k] == 0 ||')
        L.append('          mbist_addr_or[k] != 8\'hff || mbist_addrrd_or[k] != 8\'hff) begin')
        L.append('        $display("COVERAGE HOLE: bore%0d 的 8 位 MBIST 地址没被打满（G1 正是把它从 9 位收窄到 8 位）", k+2);')
        L.append('        $display("TEST FAILED"); $fatal(1);')
        L.append('      end')
        L.append('    if (s1_ready_hi == 0 || s1_ready_lo == 0) begin')
        L.append('      $display("COVERAGE HOLE: io_s1_ready 只出现过一种值");')
        L.append('      $display("TEST FAILED"); $fatal(1);')
        L.append('    end')
        L.append('    // 与门的每一路都要被单独压低过：某一路恒 1 时，把它从与门里删掉')
        L.append('    // 也测不出来（阴性对照 M6 就是这么逃掉的）。')
        L.append('    // 每一路都必须被观测为 0 过（否则连它接没接对都不知道）。')
        L.append('    for (int k = 0; k < 3; k++)')
        L.append('      if (s1r_lo[k] == 0) begin')
        L.append('        $display("COVERAGE HOLE: s1_ready 第 %0d 路(0=tage 1=ftb 2=ittage) 全程为 1", k);')
        L.append('        $display("TEST FAILED"); $fatal(1);')
        L.append('      end')
        L.append('    // 更强的一条：只有"只有这一路为 0"的拍才能分辨与门里少了它。')
        L.append('    // tage / ftb 两路做硬闸；ittage 这一路**结构上做不到**——它的')
        L.append('    // io_s1_ready = 5 个 ITTageTable 的 ~powerOnResetState，低电平窗口')
        L.append('    // 完全落在 tage 的窗口里，任何激励都分不开。所以这一项如实打印、')
        L.append('    // 不假装验过：`& ittage` 这一项的正确性由 FM 负责（FM 不做可达性')
        L.append('    // 分析，a&b&c 与 a&b 作为函数就不等价，一定会被抓）。')
        L.append('    for (int k = 0; k < 2; k++)')
        L.append('      if (s1r_only_lo[k] == 0) begin')
        L.append('        $display("COVERAGE HOLE: s1_ready 第 %0d 路没有过\\"只有它为 0\\"的拍", k);')
        L.append('        $display("TEST FAILED"); $fatal(1);')
        L.append('      end')
        L.append('    if (s1r_only_lo[2] == 0)')
        L.append('      $display("NOTE: ittage 一路无法单独压低（结构性，见上），该项由 FM 覆盖");')
        L.append('    if (seg_hi_trap == 0) begin')
        L.append('      $display("COVERAGE HOLE: 高段比较的定向激励一次都没打出去");')
        L.append('      $display("TEST FAILED"); $fatal(1);')
        L.append('    end')
        L.append('    if (meta_nz == 0 || perf_nz == 0) begin')
        L.append('      $display("COVERAGE HOLE: meta 或 perf 全程为 0 —— 拼接/打拍路径没被激励");')
        L.append('      $display("TEST FAILED"); $fatal(1);')
        L.append('    end')
        L.append('    if (herrors != 0 || hchecks == 0) begin')
        L.append('      $display("TEST FAILED"); $fatal(1);')
        L.append('    end')
    L.append('    if (errors == 0 && checks > 1000) begin')
    L.append('      $display("TEST PASSED");')
    L.append('      $finish;')
    L.append('    end')
    L.append('    $display("TEST FAILED");')
    L.append('    $fatal(1);')
    L.append('  end')
    L.append('endmodule')

    d = os.path.join(REPO, 'verif', 'ut', mod)
    os.makedirs(d, exist_ok=True)
    p = os.path.join(d, 'tb.sv')
    open(p, 'w').write('\n'.join(L) + '\n')
    print(f'generated {p}: {len(ports)} ports ({len(ins)} in / {len(outs)} out), '
          f'{len(L)} lines')


if __name__ == '__main__':
    main()

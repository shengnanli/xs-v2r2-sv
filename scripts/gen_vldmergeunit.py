#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_vldmergeunit.py —— VldMergeUnit 的 golden 同名 wrapper 与向量合并链 UT tb 生成器。

核是手写的：rtl/backend/VldMergeUnit.sv 里的 vldmergeunit_pkg（写回字段结构体）与
xs_VldMergeUnit_core。本脚本只产出：
  * VldMergeUnit.sv 里 `// BEGIN GENERATED(vldmergeunit-wrapper)` 区：端口表照抄 golden，
    每个 io_writeback_bits_<f> / io_writebackAfterMerge_bits_<f> 按固定规则映射到结构体成员
    （fail-closed：每个 golden 端口恰好命中一条规则，映射是单射；结构体里有而 golden 没有的
    成员由 VCS 编译报错兜底）；
  * verif/ut/VldMergeUnit/tb.sv：UIntToContLow1s / UIntToContLow0s / ByteMaskTailGen /
    VldMgu / VldMergeUnit 五对双例化逐拍比对。

用法: python3 scripts/gen_vldmergeunit.py [--check]
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))
CORE = 'rtl/backend/VldMergeUnit.sv'
TB = 'verif/ut/VldMergeUnit/tb.sv'
BEGIN = '// BEGIN GENERATED(vldmergeunit-wrapper)\n'
END = '// END GENERATED\n'

# golden 字段名前缀 -> 结构体成员路径（长前缀在前）
PREFIX = [('vls_vpu_fpu_', 'vls.vpu.fpu.'), ('vls_vpu_', 'vls.vpu.'), ('vls_', 'vls.'),
          ('debug_seqNum_', 'debug.seqNum.'), ('debugInfo_', 'debugInfo.'),
          ('debug_', 'debug.'), ('robIdx_', 'robIdx.')]


def die(msg):
    sys.exit('gen_vldmergeunit: ERROR: ' + msg)


def field_path(f):
    m = re.fullmatch(r'exceptionVec_(\d+)', f)
    if m:
        return 'exceptionVec[%s]' % m[1]
    for p, s in PREFIX:
        if f.startswith(p):
            return s + f[len(p):]
    if '_' in f and f != 'data_0':
        die('字段 %s 没有映射规则' % f)
    return f


def ports(name):
    t = (GOLDEN / (name + '.sv')).read_text()
    body = t[t.index('\nmodule ' + name + '('):]
    hdr = body[:body.index(');\n')]
    lines = [l.rstrip().rstrip(',') for l in hdr.splitlines() if re.match(r'\s*(input|output)\b', l)]
    out = []
    for l in lines:
        m = re.match(r'\s*(input|output)\s*(?:\[(\d+):0\])?\s*(\w+)$', l)
        if not m:
            die('%s 端口行解析失败: %r' % (name, l))
        out.append((l, m[1], int(m[2]) + 1 if m[2] else 1, m[3]))
    return out


def wrapper():
    P = ports('VldMergeUnit')
    L = ['module VldMergeUnit ('] + [',\n'.join(l for l, *_ in P)] + [');']
    L.append('  import vldmergeunit_pkg::*;')
    L.append('')
    L.append('  rob_ptr_t flush_robIdx;')
    L.append('  vld_wb_t  in_bits, out_bits;')
    L.append('  assign flush_robIdx = \'{io_flush_bits_robIdx_flag, io_flush_bits_robIdx_value};')
    seen = {}
    ins, outs = [], []
    for l, d, w, n in P:
        m = re.fullmatch(r'io_writeback_bits_(\w+)', n)
        if m:
            p = field_path(m[1])
            if ('in', p) in seen:
                die('映射不单射: %s 与 %s' % (n, seen[('in', p)]))
            seen[('in', p)] = n
            ins.append('  assign in_bits.%s = %s;' % (p, n))
            continue
        m = re.fullmatch(r'io_writebackAfterMerge_bits_(\w+)', n)
        if m:
            p = field_path(m[1])
            if ('out', p) in seen:
                die('映射不单射: %s' % n)
            seen[('out', p)] = n
            outs.append('  assign %s = out_bits.%s;' % (n, p))
            continue
        if n not in ('clock', 'io_flush_valid', 'io_flush_bits_robIdx_flag',
                     'io_flush_bits_robIdx_value', 'io_flush_bits_level',
                     'io_writeback_valid', 'io_writebackAfterMerge_valid'):
            die('未知端口 %s' % n)
    in_set = {p for k, p in seen if k == 'in'}
    out_set = {p for k, p in seen if k == 'out'}
    if in_set != out_set:
        die('输入/输出字段集合不一致: %s' % sorted(in_set ^ out_set))
    L += ins
    L.append('')
    L.append('  xs_VldMergeUnit_core u_core (')
    L.append('    .clock        (clock),')
    L.append('    .flush_valid  (io_flush_valid),')
    L.append('    .flush_robIdx (flush_robIdx),')
    L.append('    .flush_level  (io_flush_bits_level),')
    L.append('    .in_valid     (io_writeback_valid),')
    L.append('    .in_bits      (in_bits),')
    L.append('    .out_valid    (io_writebackAfterMerge_valid),')
    L.append('    .out_bits     (out_bits)')
    L.append('  );')
    L.append('')
    L += outs
    L.append('endmodule')
    return '\n'.join(L) + '\n'


# ---------------------------------------------------------------------------
# tb
# ---------------------------------------------------------------------------
def inst(mod, suffix, P, drive, prefix):
    conns = []
    for l, d, w, n in P:
        if d == 'output':
            conns.append('    .%s (%s_%s)' % (n, prefix, n))
        else:
            conns.append('    .%s (%s)' % (n, drive(n, w)))
    return ['  %s u_%s (' % (mod + suffix, prefix)] + [',\n'.join(conns)] + ['  );']


def decl_outs(P, tag):
    L = []
    for l, d, w, n in P:
        if d == 'output':
            L.append('  logic [%d:0] g%s_%s, i%s_%s;' % (w - 1, tag, n, tag, n))
    return L


def cmp_outs(P, tag, mod, gate=''):
    L = []
    for l, d, w, n in P:
        if d == 'output':
            L.append('    %s`CK(g%s_%s, i%s_%s, "%s.%s")' % (gate, tag, n, tag, n, mod, n))
    return L


def tb():
    P1 = ports('UIntToContLow1s')
    P0 = ports('UIntToContLow0s')
    PB = ports('ByteMaskTailGen')
    PG = ports('VldMgu')
    PM = ports('VldMergeUnit')
    L = []
    L.append('// ' + '=' * 76)
    L.append('// tb —— 向量 load 合并链 UT：UIntToContLow1s / UIntToContLow0s / ByteMaskTailGen /')
    L.append('//        VldMgu / VldMergeUnit 五对 golden vs 重写件，同激励逐拍比全部输出。')
    L.append('//')
    L.append('// 激励有偏：vstart 0..40、vl 0..140（字节号经 <<vsew 后能跨 128 字节整组边界，')
    L.append('// 也能落进 vstart>=vl 的空区间）；vm / vlWen / isIndexed / isMasked 各约 1/4 置位；')
    L.append('// 冲刷口 robIdx 与写回 robIdx 同 flag 且 value 相差 0..3 的概率约 1/2（覆盖「之后 /')
    L.append('// 相等 / 之前」三种比较与翻转位）。VldMergeUnit 无复位：两侧先灌 4 拍 valid 再比。')
    L.append('//')
    L.append('// 本文件由 scripts/gen_vldmergeunit.py 生成，勿手改。')
    L.append('// ' + '=' * 76)
    L.append('`timescale 1ns/1ps')
    L.append('module tb;')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  bit clock = 0; always #5 clock = ~clock;')
    L.append('  longint errors = 0, checks = 0;')
    L.append('  `define CK(g, i, nm) \\')
    L.append('    begin checks++; if ((g) !== (i)) begin errors++; \\')
    L.append('      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \\')
    L.append('    end end')
    L.append('')
    L.append('  // ---- 共用随机源 ----')
    L.append('  logic [7:0]   u8a, u8b;')
    L.append('  logic [127:0] r128a, r128b, r128c;')
    L.append('  logic [1:0]   r2a, r2b;')
    L.append('  logic [2:0]   r3;')
    L.append('  logic [15:0]  r16;')
    L.append('  logic [7:0]   vstart, vl;')
    L.append('  logic         vma, vta, vm, vlwen, idx, msk;')
    L.append('  logic         wb_valid, fl_valid, fl_level, fl_flag, wb_flag;')
    L.append('  logic [7:0]   fl_value, wb_value;')
    L.append('  logic [1023:0] noise;   // 其余字段的随机位')
    L.append('')
    for tag, P in (('1', P1), ('0', P0), ('B', PB), ('G', PG), ('M', PM)):
        L += decl_outs(P, tag)
    L.append('')

    def d_u1(n, w):
        return 'u8a'

    def d_u0(n, w):
        return 'u8b'

    def d_b(n, w):
        return {'io_in_begin': 'vstart', 'io_in_end': 'vl', 'io_in_vma': 'vma', 'io_in_vta': 'vta',
                'io_in_vsew': 'r2a', 'io_in_maskUsed': 'r16', 'io_in_vdIdx': 'r3'}[n]

    def d_g(n, w):
        return {'io_in_vd': 'r128a', 'io_in_oldVd': 'r128b', 'io_in_mask': 'r128c',
                'io_in_info_ta': 'vta', 'io_in_info_ma': 'vma', 'io_in_info_vl': 'vl',
                'io_in_info_vstart': 'vstart', 'io_in_info_eew': 'r2a', 'io_in_info_vsew': 'r2b',
                'io_in_info_vdIdx': 'r3', 'io_in_isIndexedVls': 'idx'}[n]

    off = [0]
    memo = {}   # 同一端口两侧必须拿同一段随机位

    def d_m(n, w):
        fixed = {'clock': 'clock', 'io_flush_valid': 'fl_valid', 'io_flush_bits_robIdx_flag': 'fl_flag',
                 'io_flush_bits_robIdx_value': 'fl_value', 'io_flush_bits_level': 'fl_level',
                 'io_writeback_valid': 'wb_valid', 'io_writeback_bits_data_0': 'r128a',
                 'io_writeback_bits_robIdx_flag': 'wb_flag', 'io_writeback_bits_robIdx_value': 'wb_value',
                 'io_writeback_bits_vlWen': 'vlwen', 'io_writeback_bits_vls_vpu_vm': 'vm',
                 'io_writeback_bits_vls_vpu_vmask': 'r128c', 'io_writeback_bits_vls_vpu_vma': 'vma',
                 'io_writeback_bits_vls_vpu_vta': 'vta', 'io_writeback_bits_vls_vpu_vl': 'vl',
                 'io_writeback_bits_vls_vpu_vstart': 'vstart', 'io_writeback_bits_vls_vpu_veew': 'r2a',
                 'io_writeback_bits_vls_vpu_vsew': 'r2b', 'io_writeback_bits_vls_vdIdxInField': 'r3',
                 'io_writeback_bits_vls_isIndexed': 'idx', 'io_writeback_bits_vls_isMasked': 'msk'}
        if n in fixed:
            return fixed[n]
        if w > 64:
            return 'r128b[%d:0]' % (w - 1)
        if n not in memo:
            memo[n] = 'noise[%d +: %d]' % (off[0] % 960, w)
            off[0] += w
        return memo[n]

    for mod, tag, P, drv in (('UIntToContLow1s', '1', P1, d_u1), ('UIntToContLow0s', '0', P0, d_u0),
                             ('ByteMaskTailGen', 'B', PB, d_b), ('VldMgu', 'G', PG, d_g),
                             ('VldMergeUnit', 'M', PM, d_m)):
        L += inst(mod, '', P, drv, 'g' + tag)
        L += inst(mod, '_xs', P, drv, 'i' + tag)
    L.append('')
    L.append('  // 上一拍送进去的 valid（用于数「被冲刷吃掉」的次数）')
    L.append('  logic wb_valid_q;')
    L.append('  always @(posedge clock) wb_valid_q <= wb_valid;')
    L.append('  // 覆盖计数')
    L.append('  longint c_empty = 0, c_active = 0, c_agn = 0, c_flush_kill = 0, c_vlwen = 0, c_merge_diff = 0;')
    L.append('')
    L.append('  task automatic drive();')
    L.append('    u8a = 8\'($urandom); u8b = 8\'($urandom);')
    L.append('    r128a = {$urandom, $urandom, $urandom, $urandom};')
    L.append('    r128b = {$urandom, $urandom, $urandom, $urandom};')
    L.append('    r128c = {$urandom, $urandom, $urandom, $urandom};')
    L.append('    r2a = 2\'($urandom); r2b = 2\'($urandom); r3 = 3\'($urandom); r16 = 16\'($urandom);')
    L.append('    vstart = 8\'($urandom_range(0, 40)); vl = 8\'($urandom_range(0, 140));')
    L.append('    if ($urandom_range(0, 15) == 0) begin vstart = 8\'($urandom); vl = 8\'($urandom); end')
    L.append('    vma = $urandom; vta = $urandom;')
    L.append('    vm = ($urandom_range(0, 3) == 0); vlwen = ($urandom_range(0, 3) == 0);')
    L.append('    idx = ($urandom_range(0, 3) == 0); msk = ($urandom_range(0, 3) == 0);')
    L.append('    wb_valid = ($urandom_range(0, 3) != 0);')
    L.append('    wb_flag = $urandom; wb_value = 8\'($urandom);')
    L.append('    fl_valid = ($urandom_range(0, 2) == 0); fl_level = $urandom;')
    L.append('    if ($urandom_range(0, 1)) begin')
    L.append('      fl_flag = wb_flag ^ ($urandom_range(0, 7) == 0);')
    L.append('      fl_value = wb_value + 8\'($urandom_range(0, 6)) - 8\'d3;')
    L.append('    end else begin fl_flag = $urandom; fl_value = 8\'($urandom); end')
    L.append('    for (int k = 0; k < 32; k++) noise[k*32 +: 32] = $urandom;')
    L.append('  endtask')
    L.append('')
    L.append('  task automatic compare(bit seq_ok);')
    L += cmp_outs(P1, '1', 'UIntToContLow1s')
    L += cmp_outs(P0, '0', 'UIntToContLow0s')
    L += cmp_outs(PB, 'B', 'ByteMaskTailGen')
    L += cmp_outs(PG, 'G', 'VldMgu')
    L.append('    if (seq_ok) begin')
    L += cmp_outs(PM, 'M', 'VldMergeUnit', '  ')
    L.append('    end')
    L.append('  endtask')
    L.append('')
    L.append('  initial begin')
    L.append('    void\'($value$plusargs("ncycles=%d", NCYCLES));')
    L.append('    for (int unsigned cyc = 0; cyc < NCYCLES; cyc++) begin')
    L.append('      drive();')
    L.append('      if (cyc < 4) wb_valid = 1;          // 无复位：先把寄存器灌成确定值')
    L.append('      #1;')
    L.append('      compare(cyc >= 5);')
    L.append('      if (vstart >= vl) c_empty++;')
    L.append('      if (gB_io_out_activeEn != 0) c_active++;')
    L.append('      if (gB_io_out_agnosticEn != 0) c_agn++;')
    L.append('      if (gM_io_writebackAfterMerge_bits_vlWen) c_vlwen++;')
    L.append('      if (gM_io_writebackAfterMerge_valid && gM_io_writebackAfterMerge_bits_data_0 != u_gM.wbReg_bits_data_0) c_merge_diff++;')
    L.append('      @(posedge clock); #1;')
    L.append('      if (!gM_io_writebackAfterMerge_valid && wb_valid_q) c_flush_kill++;')
    L.append('    end')
    L.append('    $display("COVER empty=%0d active=%0d agnostic=%0d vlwen_out=%0d merge_changed=%0d flush_killed=%0d",')
    L.append('             c_empty, c_active, c_agn, c_vlwen, c_merge_diff, c_flush_kill);')
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && c_active > 0 && c_agn > 0 && c_merge_diff > 0 && c_flush_kill > 0)')
    L.append('      $display("TEST PASSED");')
    L.append('    else $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def build():
    files = {}
    core = (REPO / CORE).read_text()
    if core.count(BEGIN) != 1 or core.count(END) != 1:
        die('%s: GENERATED 标记不唯一' % CORE)
    head, rest = core.split(BEGIN)
    _, tail = rest.split(END)
    files[CORE] = head + BEGIN + wrapper() + END + tail
    files[TB] = tb()
    return files


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    a = ap.parse_args()
    files = build()
    drift = []
    for rel, text in sorted(files.items()):
        p = REPO / rel
        old = p.read_text() if p.exists() else None
        if old == text:
            continue
        if a.check:
            drift.append(rel)
        else:
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(text)
    if a.check:
        if drift:
            print('DRIFT: %d 个产物与生成器不一致：' % len(drift))
            for d in drift:
                print('  ' + d)
            return 1
        print('gen_vldmergeunit: %d 个产物与生成器一致' % len(files))
        return 0
    print('gen_vldmergeunit: 写出/校验 %d 个文件' % len(files))
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_renametablewrapper.py —— RenameTableWrapper / DiffRatStateBuffer 的机械派生区生成器（G1 golden 端口表驱动）。

产出（原地替换 BEGIN/END GENERATED 标记之间的内容，手写区不碰）：
  rtl/backend/RenameTableWrapper.sv
      rtw_instances : 五张 RenameTable（golden 同名变体）+ DiffRatStateBuffer 的例化，接可读核的数组信号
      rtw_wrapper   : golden 同名 wrapper（455 端口逐字来自 golden，数组打包/拆包）
  rtl/backend/DiffRatStateBuffer.sv
      diffrat_wrapper : golden 同名 wrapper
  verif/ut/RenameTableWrapper/tb.sv   双例化随机比对 testbench（整文件）

连线规则（与 golden RenameTableWrapper.sv 的例化逐项核对）：
  RenameTable 读口 N = 通道 i × 每通道读口数 + p；int 地址取低 5 位、fp/vec 取低 6 位、v0/vl 无地址口；
  arch/spec 写口按通道 N 直连可读核算出的 {c}_arch[N] / {c}_spec[N]；
  need_free 只有 int 有消费者，debug_rdata 只有 int 有消费者；fp 变体没有这两组口。

用法: python3 scripts/gen_renametablewrapper.py [--check]
"""
import pathlib, re, sys

XSSV = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
RTW = XSSV / 'rtl/backend/RenameTableWrapper.sv'
DRB = XSSV / 'rtl/backend/DiffRatStateBuffer.sv'
UT = XSSV / 'verif/ut/RenameTableWrapper'
W = 6   # RenameWidth

# 类别表：(名, golden 变体, 实例名, 读口数/通道, 地址位宽(0=无地址口), 有 need_free 口, 有 debug_rdata 口, diffRatBase 项数)
CLASSES = [
    ('int', 'RenameTable',   'intRat', 2, 5, True,  True,  32),
    ('fp',  'RenameTable_1', 'fpRat',  3, 6, False, False, 32),
    ('vec', 'RenameTable_2', 'vecRat', 3, 6, True,  True,  31),
    ('v0',  'RenameTable_3', 'v0Rat',  1, 0, True,  True,  1),
    ('vl',  'RenameTable_3', 'vlRat',  1, 0, True,  True,  1),
]
UPD_FIELDS = ['robIdx_flag', 'robIdx_value', 'lastUop', 'ldest', 'pdest', 'rfWen', 'fpWen', 'vecWen', 'v0Wen', 'vlWen']
INFO_FIELDS = ['ldest', 'pdest', 'rfWen', 'fpWen', 'vecWen', 'v0Wen', 'vlWen']


def parse_ports(svfile, modname):
    text = svfile.read_text()
    m = re.search(rf'^module {re.escape(modname)}\((.*?)\n\);', text, re.S | re.M)
    assert m, modname
    ports = []
    for line in m.group(1).splitlines():
        pm = re.match(r'\s*(input|output)\s+(?:\[(\d+):0\])?\s*(\w+),?\s*$', line)
        if pm:
            ports.append((pm.group(1), int(pm.group(2)) + 1 if pm.group(2) else 1, pm.group(3)))
    return ports


def w(width):
    return f'[{width-1}:0] ' if width > 1 else ''


# ---------------------------------------------------------------------------
# RTW: 例化区
# ---------------------------------------------------------------------------
def rat_instance(cls, variant, inst, P, AW, has_nf, has_dbg):
    ports = parse_ports(GOLDEN / f'{variant}.sv', variant)
    names = [n for _, _, n in ports]
    conn = []
    for n in names:
        m = re.match(r'io_readPorts_(\d+)_(hold|addr|data)$', n)
        if m:
            N, f = int(m.group(1)), m.group(2); i, p = divmod(N, P)
            sub_ = f'[{i}][{p}]' if AW > 0 else f'[{i}]'      # v0/vl 每通道只有 1 个读口：一维
            if f == 'addr':   conn.append((n, f'{cls}_rd_addr[{i}][{p}][{AW-1}:0]'))
            elif f == 'hold': conn.append((n, f'{cls}_rd_hold{sub_}'))
            else:             conn.append((n, f'{cls}_rd_data{sub_}'))
            continue
        m = re.match(r'io_(arch|spec)WritePorts_(\d+)_(wen|addr|data)$', n)
        if m:
            kind, N, f = m.group(1), int(m.group(2)), m.group(3)
            sel = f'{cls}_{kind}[{N}].{f}' + (f'[{AW-1}:0]' if f == 'addr' else '')
            conn.append((n, sel)); continue
        m = re.match(r'io_old_pdest_(\d+)$', n)
        if m: conn.append((n, f'{cls}_old_pdest[{m.group(1)}]')); continue
        m = re.match(r'io_need_free_(\d+)$', n)
        if m: conn.append((n, f'int_need_free[{m.group(1)}]' if cls == 'int' else '')); continue
        m = re.match(r'io_diffRatBase_(\d+)$', n)
        if m:
            idx = int(m.group(1))
            conn.append((n, f'{cls}_diffRatBase' if cls in ('v0', 'vl') else f'{cls}_diffRatBase[{idx}]')); continue
        m = re.match(r'io_debug_rdata_(\d+)$', n)
        if m: conn.append((n, f'debug_int_rat[{m.group(1)}]' if cls == 'int' else '')); continue
        if n == 'io_debug_v0': conn.append((n, '')); continue
        if n == 'io_redirect': conn.append((n, 'redirect')); continue
        m = re.match(r'io_snpt_flushVec_(\d+)$', n)
        if m: conn.append((n, f'snpt_flushVec[{m.group(1)}]')); continue
        m = re.match(r'io_snpt_(\w+)$', n)
        if m: conn.append((n, f'snpt_{m.group(1)}')); continue
        if n in ('clock', 'reset'): conn.append((n, n)); continue
        raise SystemExit(f'{variant}: 未识别端口 {n}')
    L = [f'  {variant} {inst} (']
    L.append(',\n'.join(f'    .{n:26s}({s})' for n, s in conn))
    L.append('  );')
    return '\n'.join(L)


def drb_instance():
    ports = parse_ports(GOLDEN / 'DiffRatStateBuffer.sv', 'DiffRatStateBuffer')
    conn = []
    for _, _, n in ports:
        m = re.match(r'io_diffRatBase_(int|fp|vec|v0|vl)Rat_(\d+)$', n)
        if m:
            c, i = m.group(1), int(m.group(2))
            conn.append((n, f'{c}_diffRatBase' if c in ('v0', 'vl') else f'{c}_diffRatBase[{i}]')); continue
        m = re.match(r'io_diffRat_(int|fp|vec|v0|vl)Rat_(\d+)$', n)
        if m:
            c, i = m.group(1), int(m.group(2))
            conn.append((n, {'v0': 'diffRat_v0', 'vl': 'diff_vl_rat'}.get(c, f'diffRat_{c}[{i}]'))); continue
        m = re.match(r'io_renameUpdates_(\d+)_valid$', n)
        if m: conn.append((n, f'renameUpdates_valid[{m.group(1)}]')); continue
        m = re.match(r'io_renameUpdates_(\d+)_bits_(\w+)$', n)
        if m: conn.append((n, f'renameUpdates_{m.group(2)}[{m.group(1)}]')); continue
        m = re.match(r'io_commitRobIdx_(valid|bits_flag|bits_value)$', n)
        if m: conn.append((n, 'diffRatCommitRobIdx_' + m.group(1).replace('bits_', ''))); continue
        if n in ('clock', 'reset'): conn.append((n, n)); continue
        raise SystemExit(f'DiffRatStateBuffer: 未识别端口 {n}')
    L = ['  DiffRatStateBuffer diffRatBuffer (']
    L.append(',\n'.join(f'    .{n:34s}({s})' for n, s in conn))
    L.append('  );')
    return '\n'.join(L)


def rtw_instances():
    parts = ['  // 五张重命名表（已签核可读件，golden 同名变体）与 difftest 快照缓冲']
    for cls, variant, inst, P, AW, nf, dbg, _ in CLASSES:
        parts.append(rat_instance(cls, variant, inst, P, AW, nf, dbg))
    parts.append(drb_instance())
    return '\n'.join(parts)


# ---------------------------------------------------------------------------
# RTW: wrapper
# ---------------------------------------------------------------------------
def rtw_map(n):
    """golden 端口名 -> 可读核信号选择（输入与输出同一张表）。"""
    if n == 'io_hartId': return 'hartId'
    if n == 'io_redirect': return 'redirect'
    if n in ('io_rabCommits_isCommit', 'io_rabCommits_isWalk'): return 'rab_' + n.split('_')[-1]
    m = re.match(r'io_rabCommits_(commitValid|walkValid)_(\d+)$', n)
    if m: return f'rab_{m.group(1)}[{m.group(2)}]'
    m = re.match(r'io_rabCommits_info_(\d+)_(\w+)$', n)
    if m: return f'rab_info[{m.group(1)}].{m.group(2)}'
    m = re.match(r'io_renameUpdates_(\d+)_valid$', n)
    if m: return f'renameUpdates_valid[{m.group(1)}]'
    m = re.match(r'io_renameUpdates_(\d+)_bits_(\w+)$', n)
    if m: return f'renameUpdates_{m.group(2)}[{m.group(1)}]'
    m = re.match(r'io_diffRatCommitRobIdx_(valid|bits_flag|bits_value)$', n)
    if m: return 'diffRatCommitRobIdx_' + m.group(1).replace('bits_', '')
    m = re.match(r'io_snpt_flushVec_(\d+)$', n)
    if m: return f'snpt_flushVec[{m.group(1)}]'
    m = re.match(r'io_snpt_(\w+)$', n)
    if m: return f'snpt_{m.group(1)}'
    m = re.match(r'io_(int|fp|vec)ReadPorts_(\d+)_(\d+)_(addr|hold|data)$', n)
    if m: return f'{m.group(1)}_rd_{m.group(4)}[{m.group(2)}][{m.group(3)}]'
    m = re.match(r'io_(v0|vl)ReadPorts_(\d+)_(hold|data)$', n)
    if m: return f'{m.group(1)}_rd_{m.group(3)}[{m.group(2)}]'
    m = re.match(r'io_(int|fp|vec|v0|vl)RenamePorts_(\d+)_(wen|addr|data)$', n)
    if m: return f'{m.group(1)}_rn_{m.group(3)}[{m.group(2)}]'
    m = re.match(r'io_(int|fp|vec|v0|vl)_old_pdest_(\d+)$', n)
    if m: return f'{m.group(1)}_old_pdest[{m.group(2)}]'
    m = re.match(r'io_int_need_free_(\d+)$', n)
    if m: return f'int_need_free[{m.group(1)}]'
    m = re.match(r'io_debug_int_rat_(\d+)$', n)
    if m: return f'debug_int_rat[{m.group(1)}]'
    if n == 'io_diff_vl_rat_0': return 'diff_vl_rat'
    if n == 'gatewayIn_packed_23_bore': return 'difftest_rat_xrf'
    if n == 'gatewayIn_packed_24_bore': return 'difftest_rat_frf'
    if n == 'gatewayIn_packed_25_bore': return 'difftest_rat_vrf'
    raise SystemExit(f'RenameTableWrapper: 未识别端口 {n}')


def rtw_wrapper(ports):
    L = ['module RenameTableWrapper(']
    L.append(',\n'.join(f'  {d:6s} {w(wd)}{n}' for d, wd, n in ports) + '\n);')
    L.append('  import renametablewrapper_pkg::*;')
    decls = '''  logic [7:0] hartId; logic redirect, rab_isCommit, rab_isWalk;
  logic [RENAME_W-1:0] rab_commitValid, rab_walkValid;
  rab_info_t [RENAME_W-1:0] rab_info;
  logic [RENAME_W-1:0] renameUpdates_valid, renameUpdates_robIdx_flag, renameUpdates_lastUop,
        renameUpdates_rfWen, renameUpdates_fpWen, renameUpdates_vecWen, renameUpdates_v0Wen, renameUpdates_vlWen;
  logic [RENAME_W-1:0][PREG_W-1:0]  renameUpdates_robIdx_value, renameUpdates_pdest;
  logic [RENAME_W-1:0][LDEST_W-1:0] renameUpdates_ldest;
  logic diffRatCommitRobIdx_valid, diffRatCommitRobIdx_flag; logic [PREG_W-1:0] diffRatCommitRobIdx_value;
  logic snpt_snptEnq, snpt_snptDeq, snpt_useSnpt; logic [1:0] snpt_snptSelect; logic [SNPT_N-1:0] snpt_flushVec;
  logic [RENAME_W-1:0][INT_RD_N-1:0][INT_RD_W-1:0] int_rd_addr; logic [RENAME_W-1:0][INT_RD_N-1:0] int_rd_hold;
  logic [RENAME_W-1:0][INT_RD_N-1:0][PREG_W-1:0]   int_rd_data;
  logic [RENAME_W-1:0][FP_RD_N-1:0][FP_RD_W-1:0]   fp_rd_addr;  logic [RENAME_W-1:0][FP_RD_N-1:0]  fp_rd_hold;
  logic [RENAME_W-1:0][FP_RD_N-1:0][PREG_W-1:0]    fp_rd_data;
  logic [RENAME_W-1:0][VEC_RD_N-1:0][VEC_RD_W-1:0] vec_rd_addr; logic [RENAME_W-1:0][VEC_RD_N-1:0] vec_rd_hold;
  logic [RENAME_W-1:0][VEC_RD_N-1:0][PREG_W-1:0]   vec_rd_data;
  logic [RENAME_W-1:0] v0_rd_hold, vl_rd_hold; logic [RENAME_W-1:0][PREG_W-1:0] v0_rd_data, vl_rd_data;
  logic [RENAME_W-1:0] int_rn_wen, fp_rn_wen, vec_rn_wen, v0_rn_wen, vl_rn_wen;
  logic [RENAME_W-1:0][INT_RD_W-1:0] int_rn_addr; logic [RENAME_W-1:0][FP_RD_W-1:0] fp_rn_addr; logic [RENAME_W-1:0][VEC_RD_W-1:0] vec_rn_addr;
  logic [RENAME_W-1:0][PREG_W-1:0] int_rn_data, fp_rn_data, vec_rn_data, v0_rn_data, vl_rn_data;
  logic [RENAME_W-1:0][PREG_W-1:0] int_old_pdest, fp_old_pdest, vec_old_pdest, v0_old_pdest, vl_old_pdest;
  logic [RENAME_W-1:0] int_need_free; logic [INT_N-1:0][PREG_W-1:0] debug_int_rat; logic [PREG_W-1:0] diff_vl_rat;
  logic [INT_N*PREG_W+8-1:0] difftest_rat_xrf; logic [FP_N*PREG_W+8-1:0] difftest_rat_frf; logic [2*(1+VEC_N)*9+8-1:0] difftest_rat_vrf;'''
    L.append(decls)
    ins = [(n, rtw_map(n)) for d, _, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(n, rtw_map(n)) for d, _, n in ports if d == 'output']
    L.append('  always_comb begin')
    for n, s in ins: L.append(f'    {s} = {n};')
    L.append('  end')
    for n, s in outs: L.append(f'  assign {n} = {s};')
    core_ports = ['clock', 'reset', 'hartId', 'redirect', 'rab_isCommit', 'rab_isWalk', 'rab_commitValid', 'rab_walkValid', 'rab_info',
                  'renameUpdates_valid', 'renameUpdates_robIdx_flag', 'renameUpdates_robIdx_value', 'renameUpdates_lastUop',
                  'renameUpdates_ldest', 'renameUpdates_pdest', 'renameUpdates_rfWen', 'renameUpdates_fpWen', 'renameUpdates_vecWen',
                  'renameUpdates_v0Wen', 'renameUpdates_vlWen', 'diffRatCommitRobIdx_valid', 'diffRatCommitRobIdx_flag',
                  'diffRatCommitRobIdx_value', 'snpt_snptEnq', 'snpt_snptDeq', 'snpt_useSnpt', 'snpt_snptSelect', 'snpt_flushVec',
                  'int_rd_addr', 'int_rd_hold', 'int_rd_data', 'fp_rd_addr', 'fp_rd_hold', 'fp_rd_data', 'vec_rd_addr', 'vec_rd_hold',
                  'vec_rd_data', 'v0_rd_hold', 'v0_rd_data', 'vl_rd_hold', 'vl_rd_data',
                  'int_rn_wen', 'int_rn_addr', 'int_rn_data', 'fp_rn_wen', 'fp_rn_addr', 'fp_rn_data', 'vec_rn_wen', 'vec_rn_addr',
                  'vec_rn_data', 'v0_rn_wen', 'v0_rn_data', 'vl_rn_wen', 'vl_rn_data',
                  'int_old_pdest', 'fp_old_pdest', 'vec_old_pdest', 'v0_old_pdest', 'vl_old_pdest', 'int_need_free',
                  'debug_int_rat', 'diff_vl_rat', 'difftest_rat_xrf', 'difftest_rat_frf', 'difftest_rat_vrf']
    L.append('  xs_RenameTableWrapper_core u_core (')
    L.append(',\n'.join(f'    .{p}({p})' for p in core_ports))
    L.append('  );\nendmodule')
    return '\n'.join(L)


# ---------------------------------------------------------------------------
# DiffRatStateBuffer: wrapper
# ---------------------------------------------------------------------------
def drb_wrapper(ports):
    L = ['module DiffRatStateBuffer(']
    L.append(',\n'.join(f'  {d:6s} {w(wd)}{n}' for d, wd, n in ports) + '\n);')
    L.append('  import diffrat_pkg::*;')
    L.append('  diff_rat_state_t diffRatBase, diffRat;\n  diff_rat_update_t [RENAME_W-1:0] renameUpdates;\n  logic [RENAME_W-1:0] renameUpdates_valid;')
    L.append('  always_comb begin')
    for d, _, n in ports:
        if d != 'input' or n in ('clock', 'reset', 'io_commitRobIdx_valid', 'io_commitRobIdx_bits_flag', 'io_commitRobIdx_bits_value'):
            continue
        m = re.match(r'io_diffRatBase_(\w+)Rat_(\d+)$', n)
        if m: L.append(f'    diffRatBase.{m.group(1)}Rat[{m.group(2)}] = {n};'); continue
        m = re.match(r'io_renameUpdates_(\d+)_valid$', n)
        if m: L.append(f'    renameUpdates_valid[{m.group(1)}] = {n};'); continue
        m = re.match(r'io_renameUpdates_(\d+)_bits_(\w+)$', n)
        if m: L.append(f'    renameUpdates[{m.group(1)}].{m.group(2)} = {n};'); continue
        raise SystemExit(f'DiffRatStateBuffer wrapper: 未识别输入 {n}')
    L.append('  end')
    for d, _, n in ports:
        if d != 'output': continue
        m = re.match(r'io_diffRat_(\w+)Rat_(\d+)$', n)
        assert m, n
        L.append(f'  assign {n} = diffRat.{m.group(1)}Rat[{m.group(2)}];')
    L.append('''  xs_DiffRatStateBuffer_core u_core (
    .clock               (clock),
    .reset               (reset),
    .diffRatBase         (diffRatBase),
    .renameUpdates_valid (renameUpdates_valid),
    .renameUpdates       (renameUpdates),
    .commitRobIdx_valid  (io_commitRobIdx_valid),
    .commitRobIdx_flag   (io_commitRobIdx_bits_flag),
    .commitRobIdx_value  (io_commitRobIdx_bits_value),
    .diffRat             (diffRat)
  );
endmodule''')
    return '\n'.join(L)


# ---------------------------------------------------------------------------
# tb
# ---------------------------------------------------------------------------
def gen_tb(ports):
    ins = [(wd, n) for d, wd, n in ports if d == 'input' and n not in ('clock', 'reset')]
    outs = [(wd, n) for d, wd, n in ports if d == 'output']
    L = ['''// 自动生成：scripts/gen_renametablewrapper.py —— 勿手改（make gencheck 校验）
// RenameTableWrapper UT：golden（含 golden DiffRatStateBuffer 与两个存储叶子）vs RenameTableWrapper_xs
// （含 DiffRatStateBuffer_xs 与叶子 _xs），五张 RenameTable 两侧都例化本仓已签核的可读件。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cyc = 0;
  int cov_commit = 0, cov_walk = 0, cov_rn = 0, cov_diffrd = 0, cov_snpt = 0;
  always #5 clk = ~clk;
  always @(negedge clk) if (!rst) cyc <= cyc + 1;
  // ★暖机窗口★：RenameTable 的 4 个快照槽 payload 无复位（见 verif/ut/StdFreeList/tb.sv 的同一条定式），
  // 复位一撤先 snptEnq 连续 8 拍把槽写满、useSnpt 恒 0，之后才允许随机读快照。
  localparam int WARM = 8;''']
    for wd, n in ins: L.append(f'  logic {w(wd)}{n};')
    for wd, n in outs: L.append(f'  logic {w(wd)}g_{n}, i_{n};')
    conn = ', '.join(f'.{n}({n})' for _, n in ins)
    L.append(f'  RenameTableWrapper g_u (.clock(clk), .reset(rst), {conn}, ' + ', '.join(f'.{n}(g_{n})' for _, n in outs) + ');')
    L.append(f'  RenameTableWrapper_xs i_u (.clock(clk), .reset(rst), {conn}, ' + ', '.join(f'.{n}(i_{n})' for _, n in outs) + ');')
    L.append('''
  // robIdx 取小池子（0..15）：写快照与提交读命中同一批槽，且落在合法范围内（< RobSize=160）
  function automatic logic [7:0] rnd_rob(); return 8'($urandom_range(0, 15)); endfunction
  task automatic drive_random();''')
    for wd, n in ins:
        if re.search(r'robIdx_value$', n):
            L.append(f'    {n} = rnd_rob();')
        elif n.endswith('_bits_flag') or n.endswith('robIdx_flag'):
            L.append(f'    {n} = ($urandom_range(0, 99) < 10);')
        elif n == 'io_rabCommits_isCommit':
            L.append(f'    {n} = ($urandom_range(0, 99) < 45);')
        elif n == 'io_rabCommits_isWalk':
            L.append(f'    {n} = ($urandom_range(0, 99) < 25);')
        elif n == 'io_redirect':
            L.append(f'    {n} = (cyc < WARM) ? 1\'b0 : ($urandom_range(0, 99) < 3);')
        elif n == 'io_snpt_snptEnq':
            L.append(f'    {n} = (cyc < WARM) ? 1\'b1 : ($urandom_range(0, 99) < 15);')
        elif n == 'io_snpt_snptDeq':
            L.append(f'    {n} = (cyc < WARM) ? 1\'b0 : ($urandom_range(0, 99) < 15);')
        elif n == 'io_snpt_useSnpt':
            L.append(f'    {n} = (cyc < WARM) ? 1\'b0 : ($urandom_range(0, 99) < 20);')
        elif n == 'io_diffRatCommitRobIdx_valid':
            L.append(f'    {n} = ($urandom_range(0, 99) < 30);')
        elif re.search(r'_wen$|_valid$|Wen$|_hold$|lastUop$|Valid_\d+$|flushVec_\d+$', n):
            L.append(f'    {n} = ($urandom_range(0, 99) < 40);')
        elif wd <= 32:
            L.append(f'    {n} = {wd}\'($urandom);')
        else:
            L.append(f'    {n} = {wd}\'({{$urandom(), $urandom()}});')
    L.append('  endtask\n')
    L.append('  always @(negedge clk) if (!rst && cyc > WARM + 4) begin\n    #4; checks++;')
    for wd, n in outs:
        L.append(f'    if (g_{n} !== i_{n}) begin errors++; if (errors <= 40) $display("[%0t] {n} g=%h i=%h", $time, g_{n}, i_{n}); end')
    L.append('''    if (io_rabCommits_isCommit && io_rabCommits_commitValid_0 && io_rabCommits_info_0_rfWen) cov_commit++;
    if (io_rabCommits_isWalk && io_rabCommits_walkValid_0 && !io_intRenamePorts_0_wen) cov_walk++;
    if (io_intRenamePorts_0_wen) cov_rn++;
    if (g_u.diffRatBuffer.readValid) cov_diffrd++;
    if (io_snpt_useSnpt) cov_snpt++;
  end

  initial begin
    void'($value$plusargs("ncycles=%d", NCYCLES));
    drive_random();
    rst = 1; repeat (4) @(posedge clk); @(negedge clk) rst = 0;
    for (int unsigned n = 0; n < NCYCLES; n++) begin drive_random(); @(negedge clk); end
    $display("--- COVERAGE (每项必须 > 0) ---");
    $display("  int 架构表提交写      : %0d", cov_commit);
    $display("  walk 回滚写(无 rename): %0d", cov_walk);
    $display("  rename 写口           : %0d", cov_rn);
    $display("  difftest 快照读回     : %0d", cov_diffrd);
    $display("  useSnpt               : %0d", cov_snpt);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000 && cov_commit > 0 && cov_walk > 0 && cov_rn > 0 && cov_diffrd > 0 && cov_snpt > 0)
      $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule
''')
    return '\n'.join(L)


def sub(text, tag, body):
    pat = re.compile(r'(// BEGIN GENERATED\(' + re.escape(tag) + r'\)[^\n]*\n)(.*?)([ \t]*// END GENERATED)', re.S)
    m = pat.search(text); assert m, tag
    return text[:m.start()] + m.group(1) + body + '\n' + m.group(3) + text[m.end():]


def main():
    check = '--check' in sys.argv
    rtw_ports = parse_ports(GOLDEN / 'RenameTableWrapper.sv', 'RenameTableWrapper')
    drb_ports = parse_ports(GOLDEN / 'DiffRatStateBuffer.sv', 'DiffRatStateBuffer')
    rtw = sub(sub(RTW.read_text(), 'rtw_instances', rtw_instances()), 'rtw_wrapper', rtw_wrapper(rtw_ports))
    drb = sub(DRB.read_text(), 'diffrat_wrapper', drb_wrapper(drb_ports))
    outs = {RTW: rtw, DRB: drb, UT / 'tb.sv': gen_tb(rtw_ports)}
    stale = [p for p, t in outs.items() if not p.exists() or p.read_text() != t]
    if check:
        for p in stale: print('STALE', p.relative_to(XSSV))
        return 1 if stale else 0
    UT.mkdir(parents=True, exist_ok=True)
    for p, t in outs.items(): p.write_text(t)
    print(f'generated: RTW {len(rtw_ports)} ports, DRB {len(drb_ports)} ports')
    return 0


if __name__ == '__main__':
    sys.exit(main())

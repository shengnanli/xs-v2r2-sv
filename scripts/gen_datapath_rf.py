#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_datapath_rf.py —— DataPath 的 11 个寄存器堆变体（Fp/Vf/V0 各 Part、VlRegFile）的薄 wrapper 与 UT tb。

核是手写的：rtl/backend/xs_Regfile_core.sv（xs_Regfile_core）。本脚本只产出
「每变体一个薄文件」（golden 同名模块：端口逐行照抄 golden，展平/改名后例化 u_core）
与 verif/ut/RegfileVariants/tb.sv。

★所有参数都从 golden **实测**并断言★：项数 = mem_<i> 寄存器个数（必须 0..N-1 连续）；
读/写口数、数据/地址位宽、debug 读口数、有无 debug_all_rdata 由端口表解析；
0 号项是否异步复位由 `always @(posedge clock or posedge reset)` 块里是否复位 mem_0 判定；
读视图越界填 mem_0 这件事也在 golden 的 _GEN 查找表里逐项核对（对不上当场退出）。

用法: python3 scripts/gen_datapath_rf.py [--check]
      --check 只比对、不写盘，有漂移即非零退出（gate_all.sh 的幂等闸）。
"""
import argparse
import os
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parent.parent
GOLDEN = pathlib.Path(os.environ.get('G1_GOLDEN',
                                     '/home/eda/xs-env/G1-canonical/golden-rtl'))

VARIANTS = ['VlRegFile', 'V0RegFilePart0', 'V0RegFilePart1'] + \
           [f'VfRegFilePart{i}' for i in range(4)] + [f'FpRegFilePart{i}' for i in range(4)]
OUT_DIR = REPO / 'rtl' / 'backend'
TB_PATH = REPO / 'verif' / 'ut' / 'RegfileVariants' / 'tb.sv'
CORE = 'rtl/backend/xs_Regfile_core.sv'


def die(msg):
    sys.exit(f'gen_datapath_rf: {msg}')


def parse(top):
    txt = (GOLDEN / f'{top}.sv').read_text()
    m = re.search(r'^module ' + top + r'\(\n(.*?)\n\);\n(.*?)^endmodule', txt, re.S | re.M)
    if not m:
        die(f'{top}: 找不到 module 体')
    ports = []
    for ln in m.group(1).split('\n'):
        pm = re.match(r'^\s+(input|output)\s+(\[(\d+):0\]\s+)?(\w+),?$', ln)
        if not pm:
            die(f'{top}: 端口行不认识 {ln!r}')
        w = int(pm.group(3)) + 1 if pm.group(3) else 1
        ports.append((pm.group(1), w, pm.group(4)))
    body = m.group(2)
    pd = {n: (d, w) for d, w, n in ports}

    def idx(pat):
        return sorted(int(x) for x in {re.match(pat, n).group(1) for n in pd if re.match(pat, n)})

    rd = idx(r'io_readPorts_(\d+)_addr$')
    wr = idx(r'io_writePorts_(\d+)_wen$')
    dr = idx(r'io_debug_rports_(\d+)_addr$')
    da = idx(r'io_debug_all_rdata_(\d+)$')
    for lst, nm in ((rd, 'read'), (wr, 'write'), (dr, 'debug_read'), (da, 'debug_all')):
        if lst != list(range(len(lst))):
            die(f'{top}: {nm} 口编号不连续 {lst}')
    aw = pd['io_readPorts_0_addr'][1]
    dw = pd['io_readPorts_0_data'][1]
    for n, (d, w) in pd.items():
        if n.endswith('_addr') and w != aw:
            die(f'{top}: {n} 位宽 {w} != {aw}')
        if (n.endswith('_data') or n.startswith('io_debug_all_rdata')) and w != dw:
            die(f'{top}: {n} 位宽 {w} != {dw}')
    mems = sorted(int(x) for x in re.findall(r'^\s+reg\s+\[\d+:0\]\s+mem_(\d+);', body, re.M))
    if mems != list(range(len(mems))):
        die(f'{top}: mem_<i> 不连续')
    npregs = len(mems)
    if da and len(da) != npregs:
        die(f'{top}: debug_all_rdata 路数 {len(da)} != 项数 {npregs}')
    # 读视图：_GEN 查找表必须是 2^aw 行，[i<n]=mem_i，越界=mem_0（firtool 列表从高行到低行）
    gm = re.search(r'wire \[(\d+):0\]\[\d+:0\] _GEN =\s*\{(.*?)\};', body, re.S)
    if not gm or int(gm.group(1)) + 1 != (1 << aw):
        die(f'{top}: 读视图 _GEN 行数不是 2^{aw}')
    rows = list(reversed(re.findall(r'\{mem_(\d+)\}', gm.group(2))))
    exp = [str(i) if i < npregs else '0' for i in range(1 << aw)]
    if rows != exp:
        die(f'{top}: 读视图与"越界填 mem_0"模型不符')
    # 0 号项是否异步复位
    mem0_reset = bool(re.search(r'always @\(posedge clock or posedge reset\) begin\n\s+if \(reset\)\n\s+mem_0 <= \d+\'h0;', body))
    # 其余寄存器一律不复位：异步复位块只允许出现 mem_0
    for blk in re.findall(r'always @\(posedge clock or posedge reset\) begin(.*?)end // always', body, re.S):
        regs = set(re.findall(r'(\w+) <=', blk))
        if regs != {'mem_0'}:
            die(f'{top}: 异步复位块里出现了 mem_0 之外的寄存器 {regs}')
    return dict(ports=ports, nread=len(rd), nwrite=len(wr), ndbg=len(dr), dball=bool(da),
                npregs=npregs, aw=aw, dw=dw, mem0_reset=mem0_reset)


def gen_wrapper(top, p):
    L = []
    fam = re.sub(r'Part\d+$', '', top)
    L.append(f'// {top}.sv —— {fam} 物理寄存器堆的一片：xs_Regfile_core 的薄 wrapper（参数 + 端口展平）')
    L.append('// =============================================================================')
    L.append(f'// 参数（golden 实测，由 scripts/gen_datapath_rf.py 解析并断言）：{p["npregs"]} 项 × {p["dw"]} 位，')
    L.append(f'//   {p["nread"]} 个同步读口、{p["nwrite"]} 个写口、地址 {p["aw"]} 位（读视图 {1 << p["aw"]} 行，越界读 0 号项）；')
    L.append(f'//   debug 组合读口 {p["ndbg"]} 个；debug 全量读出 {"有" if p["dball"] else "无"}；'
             f'0 号项{"异步复位为 0" if p["mem0_reset"] else "不复位"}。')
    if 'Part' in top:
        L.append(f'//   {fam}Part0..N 在 golden 里逐字相同（仅模块名不同），片号只决定上层接哪几位数据。')
    L.append(f'// 机制（Mux1H 按位或写、地址打一拍的同步读、越界填 0 号项）见核体 {CORE}。')
    L.append(f'// golden 对照：G1-canonical/golden-rtl/{top}.sv。本文件由 scripts/gen_datapath_rf.py 生成，勿手改。')
    L.append('// =============================================================================')
    L.append(f'module {top}(')
    ports = p['ports']
    for i, (d, w, n) in enumerate(ports):
        rng = f'[{w - 1}:0]' if w > 1 else ''
        sep = ',' if i < len(ports) - 1 else ''
        L.append(f'  {d:<6} {rng:<7} {n}{sep}')
    L.append(');')
    nr, nw, nd = p['nread'], p['nwrite'], max(p['ndbg'], 1)
    aw, dw, npg = p['aw'], p['dw'], p['npregs']
    L.append(f'  localparam int unsigned NUM_PREGS = {npg};')
    L.append(f'  localparam int unsigned NUM_READ  = {nr};')
    L.append(f'  localparam int unsigned NUM_WRITE = {nw};')
    L.append(f'  localparam int unsigned DATA_W    = {dw};')
    L.append(f'  localparam int unsigned ADDR_W    = {aw};')
    L.append('')
    L.append('  logic [NUM_READ-1:0][ADDR_W-1:0]  read_addr;')
    L.append('  logic [NUM_READ-1:0][DATA_W-1:0]  read_data;')
    L.append('  logic [NUM_WRITE-1:0]             write_wen;')
    L.append('  logic [NUM_WRITE-1:0][ADDR_W-1:0] write_addr;')
    L.append('  logic [NUM_WRITE-1:0][DATA_W-1:0] write_data;')
    L.append(f'  logic [{nd - 1}:0][ADDR_W-1:0]         debug_read_addr;')
    L.append(f'  logic [{nd - 1}:0][DATA_W-1:0]         debug_read_data;')
    L.append('  logic [NUM_PREGS-1:0][DATA_W-1:0] debug_all_rdata;')
    L.append('')
    L.append('  xs_Regfile_core #(')
    L.append('    .NUM_PREGS      (NUM_PREGS),')
    L.append('    .NUM_READ       (NUM_READ),')
    L.append('    .NUM_WRITE      (NUM_WRITE),')
    L.append('    .DATA_W         (DATA_W),')
    L.append('    .ADDR_W         (ADDR_W),')
    L.append(f'    .NUM_DEBUG_READ ({p["ndbg"]}),')
    L.append(f"    .MEM0_RESET     (1'b{1 if p['mem0_reset'] else 0})")
    L.append('  ) u_core (')
    L.append('    .clock           (clock),')
    L.append('    .reset           (reset),')
    L.append('    .read_addr       (read_addr),')
    L.append('    .read_data       (read_data),')
    L.append('    .write_wen       (write_wen),')
    L.append('    .write_addr      (write_addr),')
    L.append('    .write_data      (write_data),')
    L.append('    .debug_read_addr (debug_read_addr),')
    L.append('    .debug_read_data (debug_read_data),')
    L.append('    .debug_all_rdata (debug_all_rdata)')
    L.append('  );')
    L.append('')
    L.append('  // 读口')
    for r in range(nr):
        L.append(f'  assign read_addr[{r}] = io_readPorts_{r}_addr;')
        L.append(f'  assign io_readPorts_{r}_data = read_data[{r}];')
    L.append('  // 写口')
    for w in range(nw):
        L.append(f'  assign write_wen[{w}]  = io_writePorts_{w}_wen;')
        L.append(f'  assign write_addr[{w}] = io_writePorts_{w}_addr;')
        L.append(f'  assign write_data[{w}] = io_writePorts_{w}_data;')
    L.append('  // debug')
    if p['ndbg']:
        for d in range(p['ndbg']):
            L.append(f'  assign debug_read_addr[{d}] = io_debug_rports_{d}_addr;')
            L.append(f'  assign io_debug_rports_{d}_data = debug_read_data[{d}];')
    else:
        L.append("  assign debug_read_addr = '0;  // 本变体没有 debug 组合读口")
    if p['dball']:
        for i in range(npg):
            L.append(f'  assign io_debug_all_rdata_{i} = debug_all_rdata[{i}];')
    else:
        L.append('  // 本变体没有 debug_all_rdata 端口（debug_all_rdata 悬空）')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def gen_tb(params):
    L = []
    L.append('// RegfileVariants UT —— 11 个寄存器堆变体 golden vs 重写件（_xs）双例化，逐拍比全部输出')
    L.append('// ★本文件由 scripts/gen_datapath_rf.py 生成（勿手改，--check 进闸）★')
    L.append('//')
    L.append('// 定向打的点：')
    L.append('//  (1) 同拍多写口写同一地址（Mux1H 按位或，golden 仅有非综合断言）：约 1/8 拍把写口 1 的地址抄成写口 0 的；')
    L.append('//  (2) 越界地址（地址 >= 项数，Fp/V0 有）：写被丢弃、读到 0 号项；')
    L.append('//  (3) 同拍读写同一地址：约 1/4 拍把读口 0 的地址抄成写口 0 的，下一拍应读到新值；')
    L.append('//  (4) Vl 的 0 号项异步复位：约每 2k 拍插一次 2 拍复位脉冲（变异 R3「去掉 0 号项复位」在每 20k 拍一次的频度下 20k 拍漏检，据此加密）。')
    L.append('// ★暖机★：除 Vl 的 0 号项外全部寄存器不复位，+vcs+initreg+random / +<n> 档两侧初值不同；')
    L.append('//   先用 WARMUP 拍按顺序把每一项写一遍（各写口并行）、读地址寄存器也写过之后再开始比对。')
    L.append('`timescale 1ns/1ps')
    L.append('module tb;')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  localparam int WARMUP = 64;')
    L.append('  bit clk = 0, rst = 1;')
    L.append('  int errors = 0, checks = 0, cyc = 0;')
    L.append('  always #5 clk = ~clk;')
    L.append('')
    oks = []
    for top in VARIANTS:
        p = params[top]
        t = top
        nr, nw, aw, dw, npg = p['nread'], p['nwrite'], p['aw'], p['dw'], p['npregs']
        L.append(f'  // ---------------- {t}：{npg} 项 × {dw} 位，{nr} 读 {nw} 写 ----------------')
        ins = [(w, n) for d, w, n in p['ports'] if d == 'input' and n not in ('clock', 'reset')]
        outs = [(w, n) for d, w, n in p['ports'] if d == 'output']
        for w, n in ins:
            L.append(f'  logic [{w - 1}:0] {t}__{n};')
        for w, n in outs:
            L.append(f'  wire [{w - 1}:0] {t}__{n}__g, {t}__{n}__x;')
        for suf, mod in (('g', t), ('x', t + '_xs')):
            L.append(f'  {mod} u_{t}_{suf} (')
            conns = ['    .clock(clk)', '    .reset(rst)']
            conns += [f'    .{n}({t}__{n})' for _, n in ins]
            conns += [f'    .{n}({t}__{n}__{suf})' for _, n in outs]
            L.append(',\n'.join(conns))
            L.append('  );')
        L.append(f'  int cov_{t}_samewrite = 0, cov_{t}_oob = 0, cov_{t}_rawsame = 0;')
        # 驱动
        L.append('  always @(posedge clk) begin')
        L.append(f'    automatic logic [{aw - 1}:0] a;')
        L.append('    if (cyc < WARMUP) begin')
        for w in range(nw):
            L.append(f"      {t}__io_writePorts_{w}_wen  <= 1'b1;")
            L.append(f"      {t}__io_writePorts_{w}_addr <= {aw}'((cyc * {nw} + {w}) % {npg});")
            L.append(f'      {t}__io_writePorts_{w}_data <= {dw}\'({{$urandom, $urandom}});')
        for r in range(nr):
            L.append(f'      {t}__io_readPorts_{r}_addr <= {aw}\'($urandom);')
        for d in range(p['ndbg']):
            L.append(f'      {t}__io_debug_rports_{d}_addr <= {aw}\'($urandom);')
        L.append('    end else begin')
        for w in range(nw):
            L.append(f'      {t}__io_writePorts_{w}_wen  <= ($urandom_range(0, 99) < 60);')
            L.append(f'      {t}__io_writePorts_{w}_addr <= {aw}\'($urandom);')
            L.append(f'      {t}__io_writePorts_{w}_data <= {dw}\'({{$urandom, $urandom}});')
        L.append(f'      a = {aw}\'($urandom);')
        L.append(f'      {t}__io_writePorts_0_addr <= a;')
        L.append(f'      if ($urandom_range(0, 7) == 0) {t}__io_writePorts_1_addr <= a;')
        for r in range(nr):
            L.append(f'      {t}__io_readPorts_{r}_addr <= {aw}\'($urandom);')
        L.append(f'      if ($urandom_range(0, 3) == 0) {t}__io_readPorts_0_addr <= a;')
        for d in range(p['ndbg']):
            L.append(f'      {t}__io_debug_rports_{d}_addr <= {aw}\'($urandom);')
        L.append('    end')
        L.append('  end')
        # 比对 + 覆盖
        L.append('  always @(negedge clk) if (cyc > WARMUP + 2) begin')
        for w, n in outs:
            L.append(f'    if ({t}__{n}__g !== {t}__{n}__x) begin errors++;'
                     f' if (errors <= 40) $display("[cyc %0d] {t}.{n} g=%h x=%h", cyc, {t}__{n}__g, {t}__{n}__x); end')
        same = ' || '.join(f'({t}__io_writePorts_{i}_wen && {t}__io_writePorts_{j}_wen && '
                           f'{t}__io_writePorts_{i}_addr == {t}__io_writePorts_{j}_addr)'
                           for i in range(nw) for j in range(i + 1, nw))
        L.append(f'    if ({same}) cov_{t}_samewrite++;')
        if (1 << aw) > npg:
            L.append(f'    if ({t}__io_readPorts_0_addr >= {npg} || ({t}__io_writePorts_0_wen && {t}__io_writePorts_0_addr >= {npg})) cov_{t}_oob++;')
            oks.append(f'cov_{t}_oob > 1000')
        L.append(f'    if ({t}__io_writePorts_0_wen && {t}__io_readPorts_0_addr == {t}__io_writePorts_0_addr) cov_{t}_rawsame++;')
        L.append('  end')
        L.append('')
        oks += [f'cov_{t}_samewrite > 1000', f'cov_{t}_rawsame > 1000']
    L.append('  always @(negedge clk) if (cyc > WARMUP + 2) checks++;')
    L.append('  initial begin')
    L.append('    if ($value$plusargs("ncycles=%d", NCYCLES)) ;')
    L.append('    rst = 1; repeat (4) @(posedge clk); #2 rst = 0;')
    L.append('    repeat (NCYCLES) begin')
    L.append('      @(posedge clk); cyc++;')
    L.append('      if (cyc > WARMUP && $urandom_range(0, 1999) == 0) begin')
    L.append('        #2 rst = 1; @(posedge clk); cyc++; @(posedge clk); cyc++; #2 rst = 0;')
    L.append('      end')
    L.append('    end')
    for top in VARIANTS:
        L.append(f'    $display("COV {top} samewrite=%0d oob=%0d rawsame=%0d", cov_{top}_samewrite, cov_{top}_oob, cov_{top}_rawsame);')
    L.append('    $display("checks=%0d errors=%0d", checks, errors);')
    L.append('    if (errors == 0 && checks > 1000 &&')
    L.append('        ' + ' &&\n        '.join(oks) + ')')
    L.append('      $display("TEST PASSED");')
    L.append('    else')
    L.append('      $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    args = ap.parse_args()
    params = {t: parse(t) for t in VARIANTS}
    outs = {OUT_DIR / f'{t}.sv': gen_wrapper(t, params[t]) for t in VARIANTS}
    outs[TB_PATH] = gen_tb(params)
    drift = 0
    for path, txt in outs.items():
        if not path.exists() or path.read_text() != txt:
            drift += 1
            if args.check:
                print(f'DRIFT {path.relative_to(REPO)}')
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(txt)
                print(f'wrote {path.relative_to(REPO)}')
    for t in VARIANTS:
        p = params[t]
        print(f'  {t}: {p["npregs"]}x{p["dw"]} R{p["nread"]} W{p["nwrite"]} AW{p["aw"]} '
              f'dbgR{p["ndbg"]} dball={p["dball"]} mem0_reset={p["mem0_reset"]}')
    return 1 if (args.check and drift) else 0


if __name__ == '__main__':
    sys.exit(main())

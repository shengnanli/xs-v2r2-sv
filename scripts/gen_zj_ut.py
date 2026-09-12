#!/usr/bin/env python3
"""gen_zj_ut.py —— 为"零判断批"目标生成 UT 双例化 testbench。

生成的 tb 直接从 **G1 golden 的端口表** 推出激励与比对表：
  - 所有输入（clock/reset 除外）逐拍随机驱动；`*_ready` 偏置成 75% 高以制造反压，
    `*_valid` / `*_flitv` / `*_lcrdv` 按 50% 拉高；
  - 所有输出逐拍比对 golden `<T>` 与派生 `<T>_xs`；
  - **覆盖闸**：光看 errors=0 会被"DUT 根本没动"骗过去（握手永远握不上、状态机卡死
    都会给出一个漂亮的 0）。所以 tb 另外统计三个数并在收尾时判：
      checks   比对次数（为 0 直接 FAIL）
      toggled  至少变化过一次的输出个数（低于门限 FAIL）
      fires    valid&ready 同时为 1 的拍数（该模块有握手对时，低于门限 FAIL）
    门限由生成时传入（--min-toggled / --min-fires），是"跑出来的真实数字打个折"，
    所以它既能挡住后续改动把激励打死，也不会自我实现。

用法:
  gen_zj_ut.py <Target> --out <dir>/tb.sv [--ncycles N]
               [--min-toggled K] [--min-fires K]
"""
import argparse
import pathlib
import re
import sys

G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
PORT_LINE = re.compile(r'(input|output|inout)\s+(?:(\[[^\]]*\])\s+)?(\w+)')


def ports_of(name):
    t = (G1 / f'{name}.sv').read_text(errors='replace')
    i = t.index(f'module {name}(')
    j = t.index('\n);', i) + len('\n);')
    out = []
    for line in t[i:j].splitlines():
        m = PORT_LINE.match(line.strip().rstrip(','))
        if m:
            w = m.group(2) or ''
            width = 1
            if w:
                hi, lo = w.strip('[]').split(':')
                width = int(hi) - int(lo) + 1
            out.append((m.group(1), w, m.group(3), width))
    return out


VALIDISH = re.compile(r'_(valid|flitv|lcrdv|flitpend|wen|ren|req|fire|en)$')
READYISH = re.compile(r'_(ready|lcrdv|linkactiveack)$')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('target')
    ap.add_argument('--out', required=True)
    ap.add_argument('--ncycles', type=int, default=200000)
    ap.add_argument('--min-toggled', type=int, default=1)
    ap.add_argument('--min-fires', type=int, default=0)
    ap.add_argument('--note', default='')
    ap.add_argument('--narrow', nargs='*', default=[],
                    help='端口域收窄，形如 "<正则>=<最大值>"。全随机会让"要靠相等才'
                         '走通"的路径(tag 比对、地址命中)概率归零 —— 那正是"跑了 '
                         '20 万拍 errors=0 其实什么都没测到"的来源。')
    a = ap.parse_args()
    T = a.target
    ps = ports_of(T)

    ins = [p for p in ps if p[0] == 'input' and p[2] not in ('clock', 'reset')]
    outs = [p for p in ps if p[0] == 'output']
    has_clock = any(p[2] == 'clock' for p in ps)
    has_reset = any(p[2] == 'reset' for p in ps)

    # handshake pairs: input X_valid  <-> output X_ready  (and the mirror)
    onames = {p[2] for p in outs}
    inames = {p[2] for p in ins}
    pairs = []
    for _, _, n, _w in ins:
        if n.endswith('_valid') and n[:-6] + '_ready' in onames:
            pairs.append((n, n[:-6] + '_ready'))
    for _, _, n, _w in outs:
        if n.endswith('_valid') and n[:-6] + '_ready' in inames:
            pairs.append((n[:-6] + '_ready', n))   # (input ready, golden valid)

    # "<regex>=<max>"  -> $urandom_range(0, max)
    # "<regex>=@<expr>" -> the expression verbatim (for mixed distributions)
    narrow = []
    for spec in a.narrow:
        pat, rhs = spec.split('=', 1)
        narrow.append((re.compile(pat), rhs))

    def narrow_rhs(n):
        for pat, rhs in narrow:
            if pat.search(n):
                return rhs[1:] if rhs.startswith('@') else f'$urandom_range(0, {rhs})'
        return None

    L = []
    ap_ = L.append
    ap_(f'// 自动生成：scripts/gen_zj_ut.py {T} —— 勿手改')
    ap_(f'// {T} 双例化逐拍比对：golden {T} vs 重写 {T}_xs（derive_ut_impl.py 派生）。')
    ap_('// 激励 = G1 golden 端口表全随机（ready 偏置 75% 高以制造反压）；')
    ap_('// 收尾判 errors / checks / toggled / fires 四项，后三项是覆盖闸（防假绿）。')
    if a.note:
        ap_(f'// {a.note}')
    ap_('`timescale 1ns/1ps')
    ap_('module tb;')
    ap_(f'  localparam int unsigned NCYCLES     = {a.ncycles};')
    ap_(f'  localparam int unsigned MIN_TOGGLED = {a.min_toggled};')
    ap_(f'  localparam int unsigned MIN_FIRES   = {a.min_fires};')
    ap_(f'  localparam int unsigned N_OUT       = {len(outs)};')
    ap_('')
    # tb 自己永远有时钟/复位（组合模块也要按拍推进激励），只是不一定连到 DUT
    ap_('  bit clock = 0;')
    ap_('  always #5 clock = ~clock;')
    ap_('  bit reset;')
    ap_('  longint checks = 0, errors = 0, fires = 0;')
    ap_('  int      toggled = 0;')
    ap_('')
    ap_('  // 宽随机：$urandom 一次 32 位，拼够位宽。')
    ap_('  function automatic logic [2047:0] rnd(input int w);')
    ap_('    logic [2047:0] v;')
    ap_("    v = '0;")
    ap_('    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;')
    ap_('    return v;')
    ap_('  endfunction')
    ap_('')
    for d, w, n, _w in ins:
        ap_(f'  logic {w + " " if w else ""}{n};')
    ap_('')
    for d, w, n, _w in outs:
        ap_(f'  wire {w + " " if w else ""}g_{n};')
        ap_(f'  wire {w + " " if w else ""}i_{n};')
    ap_('')
    for d, w, n, _w in outs:
        ap_(f'  logic {w + " " if w else ""}p_{n};   // 上一拍值（toggle 统计）')
        ap_(f'  bit tog_{n};')
    ap_('')

    def inst(mod, inst_name, pre):
        ap_(f'  {mod} {inst_name} (')
        conns = []
        for d, w, n, _w in ps:
            if n in ('clock', 'reset'):
                conns.append(f'    .{n}({n})')
            elif d == 'output':
                conns.append(f'    .{n}({pre}{n})')
            else:
                conns.append(f'    .{n}({n})')
        ap_(',\n'.join(conns))
        ap_('  );')

    inst(T, 'u_g', 'g_')
    inst(f'{T}_xs', 'u_i', 'i_')
    ap_('')
    ap_('  task automatic drive_random();')
    for d, w, n, wid in ins:
        rhs = narrow_rhs(n)
        if rhs is not None:
            ap_(f'    {n} = {rhs};'
                f'   // 域收窄：让"必须相等/必须全 1"的路径有非零概率')
            continue
        if READYISH.search(n):
            ap_(f'    {n} = (($urandom % 4) != 0);            // 75% 高：制造反压')
        elif VALIDISH.search(n):
            ap_(f'    {n} = $urandom % 2;')
        elif wid == 1:
            ap_(f'    {n} = $urandom % 2;')
        else:
            ap_(f'    {n} = rnd({wid});')
    ap_('  endtask')
    ap_('')
    ap_('  task automatic check_outputs();')
    for d, w, n, _w in outs:
        ap_(f'    if (!$isunknown(g_{n})) begin')
        ap_('      checks++;')
        ap_(f'      if (g_{n} !== i_{n}) begin')
        ap_('        errors++;')
        ap_(f'        if (errors <= 30) $display("[%0t] MISMATCH {n} g=%0h i=%0h",'
            f' $time, g_{n}, i_{n});')
        ap_('      end')
        ap_('    end')
    ap_('  endtask')
    ap_('')
    ap_('  task automatic sample_coverage();')
    for d, w, n, _w in outs:
        ap_(f'    if (g_{n} !== p_{n}) tog_{n} = 1\'b1;')
        ap_(f'    p_{n} = g_{n};')
    if pairs:
        cond = ' ||\n        '.join(f'({v} && {r})' if v in inames else f'(g_{v} && {r})'
                                    for r, v in [(r, v) for r, v in pairs])
        ap_(f'    if ({cond}) fires++;')
    ap_('  endtask')
    ap_('')
    ap_('  initial begin')
    for d, w, n, _w in ins:
        ap_(f"    {n} = '0;")
    for d, w, n, _w in outs:
        ap_(f"    p_{n} = '0; tog_{n} = 1'b0;")
    ap_('    reset = 1\'b1;')
    ap_('    repeat (5) @(posedge clock);')
    ap_('    reset = 1\'b0;')
    ap_('    for (int unsigned c = 0; c < NCYCLES; c++) begin')
    if has_reset:
        ap_('      // 中途再来一次复位脉冲，覆盖复位路径（两侧同拍同源）。')
        ap_('      if (c == NCYCLES/2) begin')
        ap_('        @(negedge clock); reset = 1\'b1;')
        ap_('        repeat (3) @(posedge clock);')
        ap_('        @(negedge clock); reset = 1\'b0;')
        ap_('      end')
    ap_('      @(negedge clock);')
    ap_('      drive_random();')
    ap_('      #1 check_outputs();')
    ap_('      sample_coverage();')
    ap_('      @(posedge clock);')
    ap_('    end')
    ap_('')
    for d, w, n, _w in outs:
        ap_(f'    if (tog_{n}) toggled++; else $display("COV: output {n} never toggled");')
    ap_(f'    $display("{T} checks=%0d errors=%0d toggled=%0d/%0d fires=%0d",'
        ' checks, errors, toggled, N_OUT, fires);')
    ap_('    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end')
    ap_('    if (checks == 0) begin'
        ' $display("TEST FAILED (coverage: no comparison happened)"); $fatal(1); end')
    ap_('    if (toggled < MIN_TOGGLED) begin'
        ' $display("TEST FAILED (coverage: only %0d outputs toggled, need >= %0d)",'
        ' toggled, MIN_TOGGLED); $fatal(1); end')
    if pairs:
        ap_('    if (fires < MIN_FIRES) begin'
            ' $display("TEST FAILED (coverage: only %0d handshake fires, need >= %0d)",'
            ' fires, MIN_FIRES); $fatal(1); end')
    ap_('    $display("TEST PASSED");')
    ap_('    $finish;')
    ap_('  end')
    ap_('endmodule')

    p = pathlib.Path(a.out)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text('\n'.join(L) + '\n')
    print(f'{T}: wrote {p}  ({len(ins)} driven inputs, {len(outs)} checked outputs, '
          f'{len(pairs)} handshake pairs)')


if __name__ == '__main__':
    sys.exit(main())

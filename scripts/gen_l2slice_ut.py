#!/usr/bin/env python3
"""gen_l2slice_ut.py —— agent/l2slice lane 的多目标双例化 UT testbench 生成器。

每个目标 T：golden `T` 与派生 `T_xs`（scripts/derive_ut_impl.py）同激励并跑，逐拍用
4 态 `!==` 比较**全部**输出（不做 $isunknown 跳过）。激励由 G1 golden 端口表机械推出，
可按端口正则收窄/改写（--narrow），否则：*_ready 75% 高、*_valid 50%、其余均匀随机。

复位：前 5 拍复位，此后约 1/RSTPERIOD 拍一次 2 拍复位脉冲（两侧同源）。
未复位寄存器：+vcs+initreg+random 下两个实例各摇各的初值。--sync 给出
"golden 相对路径=impl 相对路径" 对，tb 在第一个时钟沿之前把 golden 初值抄给 impl
（只同步初态，之后两侧各自演化；有复位的寄存器不在此列）。

覆盖闸：checks>0；每个目标 toggled 输出数 >= --min-toggled；--cover 给出的 golden
内部表达式（`名字=表达式`，可用 u_g_<T>. 前缀引用内部信号）每项为真的拍数 > 0。

用法:
  gen_l2slice_ut.py --out verif/ut/<D>/tb.sv --target T [--target T2 ...]
        [--narrow 'T:<regex>=<expr>'] [--sync 'T:<gpath>=<ipath>']
        [--cover 'T:<name>=<expr>'] [--min-toggled 'T:<n>'] [--rst-period N]
确切的命令行记在各 UT 目录的 gen.py 里（幂等：内容不变不写；漂移比对由 gen.py
的比对模式做，并由 scripts/test_gen_idempotent.py 逐目录重跑把守）。
"""
import argparse
import pathlib
import re
import sys

G1 = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
PORT_LINE = re.compile(r'(input|output)\s+(?:\[(\d+):(\d+)\]\s+)?(\w+)$')
READYISH = re.compile(r'_ready$')
VALIDISH = re.compile(r'_(valid|flitv|lcrdv|flitpend)$')


def ports_of(name):
    t = (G1 / f'{name}.sv').read_text(errors='replace')
    i = t.index(f'module {name}(')
    j = t.index('\n);', i)
    out = []
    for line in t[i:j].splitlines()[1:]:
        m = PORT_LINE.match(line.strip().rstrip(','))
        if m:
            w = 1 if m.group(2) is None else int(m.group(2)) - int(m.group(3)) + 1
            out.append((m.group(1), w, m.group(4)))
    return out


def per_target(specs, tgt):
    out = []
    for s in specs:
        t, rest = s.split(':', 1)
        if t == tgt:
            out.append(rest)
    return out


def gen(a):
    L = []
    A = L.append
    A('// 自动生成：scripts/gen_l2slice_ut.py —— 勿手改（命令行见同目录 Makefile 的 gentb）')
    A('// 目标：' + ' '.join(a.target))
    A('// golden <T> 与派生 <T>_xs 双例化，同激励逐拍 4 态比全部输出；覆盖闸见文件尾。')
    A('`timescale 1ns/1ps')
    A('module tb;')
    A('  int unsigned NCYCLES = 200000;')
    A('  bit clock = 0;')
    A('  always #5 clock = ~clock;')
    A('  logic reset;')
    A('  longint checks = 0, errors = 0;')
    A('  longint cyc = 0;   // 复位释放后的拍号（--narrow 表达式可用它做分相激励）')
    A('  function automatic logic [4095:0] rnd(input int w);')
    A('    logic [4095:0] v;')
    A("    v = '0;")
    A('    for (int i = 0; i < w; i += 32) v[i+:32] = $urandom;')
    A('    return v;')
    A('  endfunction')
    A('')
    finals = []
    for T in a.target:
        ps = ports_of(T)
        ins = [p for p in ps if p[0] == 'input' and p[2] not in ('clock', 'reset')]
        outs = [p for p in ps if p[0] == 'output']
        narrow = []
        for spec in per_target(a.narrow, T):
            pat, rhs = spec.split('=', 1)
            narrow.append((re.compile(pat), rhs))
        pre = f'{T}__'
        A(f'  // ======================= {T} =======================')
        for _, w, n in ins:
            A(f'  logic {"[%d:0] " % (w - 1) if w > 1 else ""}{pre}{n};')
        for _, w, n in outs:
            d = "[%d:0] " % (w - 1) if w > 1 else ""
            A(f'  wire  {d}g_{pre}{n};')
            A(f'  wire  {d}i_{pre}{n};')
            A(f'  logic {d}p_{pre}{n};')
            A(f'  bit   t_{pre}{n};')
        has_clk = any(p[2] == 'clock' for p in ps)
        has_rst = any(p[2] == 'reset' for p in ps)
        for mod, inst, op in ((T, f'u_g_{T}', 'g_'), (f'{T}_xs', f'u_i_{T}', 'i_')):
            A(f'  {mod} {inst} (')
            conns = []
            if has_clk:
                conns.append('    .clock (clock)')
            if has_rst:
                conns.append('    .reset (reset)')
            for d, w, n in ps:
                if n in ('clock', 'reset'):
                    continue
                conns.append(f'    .{n} ({op + pre if d == "output" else pre}{n})')
            A(',\n'.join(conns))
            A('  );')
        A(f'  task automatic drive_{T}();')
        for _, w, n in ins:
            rhs = None
            for pat, r in narrow:
                if pat.search(n):
                    rhs = r
                    break
            if rhs is not None:
                A(f'    {pre}{n} = {rhs};')
            elif READYISH.search(n):
                A(f'    {pre}{n} = (($urandom % 4) != 0);')
            elif VALIDISH.search(n) or w == 1:
                A(f'    {pre}{n} = $urandom % 2;')
            else:
                A(f'    {pre}{n} = rnd({w});')
        A('  endtask')
        A(f'  task automatic check_{T}();')
        for _, w, n in outs:
            A(f'    checks++;')
            A(f'    if (g_{pre}{n} !== i_{pre}{n}) begin')
            A('      errors++;')
            A(f'      if (errors <= 40) $display("[cyc %0d] MISMATCH {T}.{n} g=%h i=%h", cyc, g_{pre}{n}, i_{pre}{n});')
            A('    end')
            A(f'    if (g_{pre}{n} !== p_{pre}{n}) t_{pre}{n} = 1\'b1;')
            A(f'    p_{pre}{n} = g_{pre}{n};')
        A('  endtask')
        covs = []
        for spec in per_target(a.cover, T):
            nm, ex = spec.split('=', 1)
            covs.append((nm, ex))
            A(f'  longint cov_{T}_{nm} = 0;')
        A(f'  task automatic cover_{T}();')
        for nm, ex in covs:
            A(f'    if ({ex}) cov_{T}_{nm}++;')
        A('  endtask')
        A(f'  task automatic sync_{T}();')
        for spec in per_target(a.sync, T):
            if '=>' in spec:
                # 'gpath=>ipath'：目标变量由普通 always（非 always_ff）驱动，可直接过程赋值
                # （firtool 行为级 ram 的 Memory 数组就是这种；整数组 force 不被支持）
                gp, ip = spec.split('=>', 1)
                A(f'    u_i_{T}.{ip} = u_g_{T}.{gp};')
                continue
            gp, ip = spec.split('=', 1)
            # always_ff 变量不许有第二个过程驱动 -> 用 force/release：release 之后变量保持
            # 被 force 的值，直到下一次自身时钟沿赋值。只在 t=1（首沿之前）做一次。
            A(f'    force u_i_{T}.{ip} = u_g_{T}.{gp};')
            A(f'    #0 release u_i_{T}.{ip};')
        A('  endtask')
        mt = per_target(a.min_toggled, T)
        mtv = int(mt[0]) if mt else len(outs)
        fin = []
        fin.append(f'    begin int tg; tg = 0;')
        for _, w, n in outs:
            fin.append(f'      if (t_{pre}{n}) tg++; else $display("COV: {T}.{n} never toggled");')
        fin.append(f'      $display("{T}: toggled=%0d/{len(outs)} (need >= {mtv})", tg);')
        fin.append(f'      if (tg < {mtv}) covfail = 1;')
        for nm, _ in covs:
            fin.append(f'      $display("{T}: cover {nm} = %0d", cov_{T}_{nm});')
            fin.append(f'      if (cov_{T}_{nm} == 0) covfail = 1;')
        fin.append('    end')
        finals.append((T, fin))
        A('')
    A('  bit covfail = 0;')
    A('  initial begin')
    A('    void\'($value$plusargs("ncycles=%d", NCYCLES));')
    A('    reset = 1\'b1;')
    for T in a.target:
        A(f'    drive_{T}();')
    A('    #1;')
    for T in a.target:
        A(f'    sync_{T}();')
    A('    repeat (5) @(posedge clock);')
    A('    @(negedge clock) reset = 1\'b0;')
    A('    for (cyc = 0; cyc < NCYCLES; cyc++) begin')
    A('      @(negedge clock);')
    A(f'      if (reset) reset = 1\'b0; else if (($urandom % {a.rst_period}) == 0) reset = 1\'b1;')
    for T in a.target:
        A(f'      drive_{T}();')
    A('      #1;')
    for T in a.target:
        A(f'      check_{T}();')
        A(f'      cover_{T}();')
    A('    end')
    for T, fin in finals:
        L.extend(fin)
    A('    $display("checks=%0d errors=%0d", checks, errors);')
    A('    if (errors != 0) begin $display("TEST FAILED (mismatch)"); $fatal(1); end')
    A('    if (checks == 0 || covfail) begin $display("TEST FAILED (coverage)"); $fatal(1); end')
    A('    $display("TEST PASSED");')
    A('    $finish;')
    A('  end')
    A('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', required=True)
    ap.add_argument('--target', action='append', required=True)
    ap.add_argument('--narrow', action='append', default=[])
    ap.add_argument('--sync', action='append', default=[])
    ap.add_argument('--cover', action='append', default=[])
    ap.add_argument('--min-toggled', action='append', default=[])
    ap.add_argument('--rst-period', type=int, default=5000)
    a = ap.parse_args()
    txt = gen(a)
    p = pathlib.Path(a.out)
    p.parent.mkdir(parents=True, exist_ok=True)
    if not p.exists() or p.read_text() != txt:
        p.write_text(txt)
    print(f'wrote {p}')
    return 0


if __name__ == '__main__':
    sys.exit(main())

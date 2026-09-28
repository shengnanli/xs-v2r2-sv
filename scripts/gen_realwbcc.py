#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen_realwbcc.py —— RealWBCollideChecker 家族（5 变体）的 wrapper 与 UT tb 生成器。

核是手写的：rtl/backend/RealWBCollideChecker.sv 里的 xs_RealWBCollideChecker_core。
本脚本只产出：
  * RealWBCollideChecker.sv 里 `// BEGIN GENERATED(realwbcc-wrapper)` 区（本变体 wrapper）；
  * RealWBCollideChecker_1.._4.sv 四个薄文件（整文件生成）；
  * verif/ut/RealWBCollideChecker/tb.sv（五变体双例化逐拍比对）。

★所有维度都从 golden 实测★：端口表逐行照抄 golden（portlint 要求同名同序）；分组表
GROUP[j][k] 取自 golden 里 `arbiters_j` 实例的 `.io_in_k_valid (io_in_X_valid)` 连线；
域写使能名、pdest/data 位宽取自 golden 出口端口。断言（fail-closed）：
  - 每个输入恰好出现在一个组里；
  - 每个组的第 k 名，其 ready/wen/pdest/data 引脚接的都是同一个输入 X 的对应端口
    （或 golden 接常数 0 的「别的域 wen」）；
  - golden 有 io_in_X_ready 端口 ⇔ X 所在组宽 >= 2。

用法: python3 scripts/gen_realwbcc.py [--check]
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
VARIANTS = ['RealWBCollideChecker'] + ['RealWBCollideChecker_%d' % i for i in range(1, 5)]
DOMAIN = {'rfWen': 'int', 'fpWen': 'fp', 'vecWen': 'vec', 'v0Wen': 'v0', 'vlWen': 'vl'}
CORE = 'rtl/backend/RealWBCollideChecker.sv'
BEGIN = '// BEGIN GENERATED(realwbcc-wrapper)\n'
END = '// END GENERATED\n'


def die(msg):
    sys.exit('gen_realwbcc: ERROR: ' + msg)


def gbody(name):
    t = (GOLDEN / (name + '.sv')).read_text()
    return t[t.index('\nmodule ' + name + '('):]


def parse(name):
    body = gbody(name)
    hdr = body[:body.index(');\n')]
    port_lines = [l.rstrip().rstrip(',') for l in hdr.splitlines()
                  if re.match(r'\s*(input|output)\b', l)]
    ports = {}
    for l in port_lines:
        m = re.match(r'\s*(input|output)\s*(?:\[(\d+):0\])?\s*(\w+)$', l)
        if not m:
            die('%s: 端口行解析失败: %r' % (name, l))
        ports[m[3]] = (m[1], int(m[2]) + 1 if m[2] else 1)
    # 出口：域 wen / pdest / data 宽度
    outs = sorted({int(m[1]) for p in ports for m in [re.match(r'io_out_(\d+)_valid$', p)] if m})
    num_out = len(outs)
    if outs != list(range(num_out)):
        die('%s: io_out 编号不连续' % name)
    wens = {m[1] for p in ports for m in [re.match(r'io_out_0_bits_(\w+Wen)$', p)] if m}
    if len(wens) != 1:
        die('%s: 出口 wen 字段不唯一: %s' % (name, wens))
    wen = wens.pop()
    pd_w = ports['io_out_0_bits_pdest'][1]
    d_w = ports['io_out_0_bits_data'][1]
    for j in range(num_out):
        for f, w in (('valid', 1), ('bits_' + wen, 1), ('bits_pdest', pd_w), ('bits_data', d_w)):
            if ports.get('io_out_%d_%s' % (j, f)) != ('output', w):
                die('%s: io_out_%d_%s 形状不对' % (name, j, f))
    ins = sorted({int(m[1]) for p in ports for m in [re.match(r'io_in_(\d+)_valid$', p)] if m})
    num_in = len(ins)
    if ins != list(range(num_in)):
        die('%s: io_in 编号不连续' % name)
    # 实例连线 -> 分组表
    groups = {}
    for m in re.finditer(r'\n  (RealWBArbiter\w*) arbiters_(\d+) \((.*?)\n  \);', body, re.S):
        j = int(m[2])
        conns = dict(re.findall(r'\.(\w+)\s*\(([^)]*)\)', m[3]))
        k = 0
        members = []
        while ('io_in_%d_valid' % k) in conns:
            src = conns['io_in_%d_valid' % k].strip()
            mm = re.fullmatch(r'io_in_(\d+)_valid', src)
            if not mm:
                die('%s arbiters_%d: io_in_%d_valid 接的不是输入 valid: %r' % (name, j, k, src))
            x = int(mm[1])
            for f, w in (('bits_' + wen, 1), ('bits_pdest', pd_w), ('bits_data', d_w)):
                got = conns.get('io_in_%d_%s' % (k, f), '').strip()
                if got != 'io_in_%d_%s' % (x, f):
                    die('%s arbiters_%d 第 %d 名 %s 接 %r，不是 io_in_%d_%s' % (name, j, k, f, got, x, f))
            rdy = conns.get('io_in_%d_ready' % k)
            if rdy is not None and rdy.strip() != 'io_in_%d_ready' % x:
                die('%s arbiters_%d 第 %d 名 ready 接 %r' % (name, j, k, rdy))
            members.append(x)
            k += 1
        for f, w in (('valid', 1), ('bits_' + wen, 1), ('bits_pdest', 1), ('bits_data', 1)):
            got = conns.get('io_out_%s' % f, '').strip()
            if got != 'io_out_%d_%s' % (j, f):
                die('%s arbiters_%d io_out_%s 接 %r' % (name, j, f, got))
        groups[j] = members
    if sorted(groups) != list(range(num_out)):
        die('%s: 实例组号 %s 与写口数 %d 不符' % (name, sorted(groups), num_out))
    grp = [groups[j] for j in range(num_out)]
    flat = sorted(x for g in grp for x in g)
    if flat != list(range(num_in)):
        die('%s: 输入没有恰好各属一组: %s' % (name, flat))
    size_of = {x: len(g) for g in grp for x in g}
    for x in range(num_in):
        has_rdy = ('io_in_%d_ready' % x) in ports
        if has_rdy != (size_of[x] >= 2):
            die('%s: io_in_%d_ready 端口存在=%s 但组宽=%d' % (name, x, has_rdy, size_of[x]))
    unused = [p for p, (d, w) in ports.items() if d == 'input'
              and re.fullmatch(r'io_in_\d+_bits_\w+Wen', p) and not p.endswith('_bits_' + wen)]
    return dict(name=name, port_lines=port_lines, ports=ports, wen=wen, pd_w=pd_w, d_w=d_w,
                num_in=num_in, num_out=num_out, grp=grp, max_g=max(len(g) for g in grp),
                unused=unused)


def sv_list(xs):
    return "'{" + ', '.join(str(x) for x in xs) + '}'


def wrapper(info):
    n = info['name']
    wen = info['wen']
    L = []
    L.append('module %s (' % n)
    L.append(',\n'.join(info['port_lines']))
    L.append(');')
    L.append('  // 域 = %s（本域写使能 %s），pdest %d 位、data %d 位。'
             % (DOMAIN[wen], wen, info['pd_w'], info['d_w']))
    L.append('  localparam int NUM_IN  = %d;' % info['num_in'])
    L.append('  localparam int NUM_OUT = %d;' % info['num_out'])
    L.append('  localparam int MAX_G   = %d;' % info['max_g'])
    L.append('  // 分组表（取自 golden 实例连线）：写口 j 的候选输入，按优先级从高到低')
    for j, g in enumerate(info['grp']):
        L.append('  //   out[%d] <- in %s' % (j, ', '.join(str(x) for x in g)))
    L.append('  localparam int GROUP_N [NUM_OUT] = %s;' % sv_list(len(g) for g in info['grp']))
    rows = [sv_list(g + [0] * (info['max_g'] - len(g))) for g in info['grp']]
    L.append('  localparam int GROUP [NUM_OUT][MAX_G] = %s;' % ("'{" + ', '.join(rows) + '}'))
    L.append('')
    L.append('  typedef struct packed {')
    L.append('    logic        wen;     // %s' % wen)
    L.append('    logic [%d:0] pdest;' % (info['pd_w'] - 1))
    L.append('    logic [%d:0] data;' % (info['d_w'] - 1))
    L.append('  } wb_t;')
    L.append('')
    L.append('  logic [NUM_IN-1:0]  in_valid;')
    L.append('  wb_t  [NUM_IN-1:0]  in_bits;')
    L.append('  logic [NUM_IN-1:0]  in_ready;')
    L.append('  logic [NUM_OUT-1:0] out_valid;')
    L.append('  wb_t  [NUM_OUT-1:0] out_bits;')
    L.append('')
    for x in range(info['num_in']):
        L.append('  assign in_valid[%d] = io_in_%d_valid;' % (x, x))
        L.append("  assign in_bits[%d]  = '{io_in_%d_bits_%s, io_in_%d_bits_pdest, io_in_%d_bits_data};"
                 % (x, x, wen, x, x))
    if info['unused']:
        L.append('  // 以下输入是别的域的写使能：golden 里它们进了子仲裁器，出口那一位悬空，')
        L.append('  // 没有读者，故不接：' + ', '.join(sorted(info['unused'],
                 key=lambda p: int(re.match(r'io_in_(\d+)', p)[1]))))
    L.append('')
    L.append('  xs_RealWBCollideChecker_core #(')
    L.append('    .NUM_IN  (NUM_IN),')
    L.append('    .NUM_OUT (NUM_OUT),')
    L.append('    .MAX_G   (MAX_G),')
    L.append('    .PW      ($bits(wb_t)),')
    L.append('    .GROUP_N (GROUP_N),')
    L.append('    .GROUP   (GROUP)')
    L.append('  ) u_core (')
    L.append('    .in_valid  (in_valid),')
    L.append('    .in_bits   (in_bits),')
    L.append('    .in_ready  (in_ready),')
    L.append('    .out_valid (out_valid),')
    L.append('    .out_bits  (out_bits)')
    L.append('  );')
    L.append('')
    L.append('  // 只有组宽 >= 2 的输入在 golden 里有 ready 端口（组内第 0 名恒 1 也照样导出）')
    for x in range(info['num_in']):
        if ('io_in_%d_ready' % x) in info['ports']:
            L.append('  assign io_in_%d_ready = in_ready[%d];' % (x, x))
    for j in range(info['num_out']):
        L.append('  assign io_out_%d_valid       = out_valid[%d];' % (j, j))
        L.append('  assign io_out_%d_bits_%s = out_bits[%d].wen;' % (j, wen, j))
        L.append('  assign io_out_%d_bits_pdest  = out_bits[%d].pdest;' % (j, j))
        L.append('  assign io_out_%d_bits_data   = out_bits[%d].data;' % (j, j))
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def thin_file(info):
    n = info['name']
    hdr = ['// ' + '=' * 76,
           '// %s.sv —— RealWBCollideChecker 家族薄 wrapper：%s 域写回口分组仲裁'
           % (n, DOMAIN[info['wen']]),
           '//',
           '// 本文件只做参数设定（分组表、payload 形状）与端口对位；核体见',
           '// %s（xs_RealWBCollideChecker_core），全家族共一份。' % CORE,
           '// 由 scripts/gen_realwbcc.py 从 golden 端口表与实例连线生成，勿手改。',
           '// golden 对照：G1-canonical/golden-rtl/%s.sv' % n,
           '// ' + '=' * 76]
    return '\n'.join(hdr) + '\n' + wrapper(info)


# ---------------------------------------------------------------------------
# tb：五变体各一对（golden vs <名>_xs），同激励逐拍比全部输出
# ---------------------------------------------------------------------------
def tb(infos):
    L = []
    L.append('// ' + '=' * 76)
    L.append('// tb —— RealWBCollideChecker 家族 UT：5 个 golden 变体与重写件逐拍双例化比对。')
    L.append('//')
    L.append('// 本族纯组合。判别力靠覆盖：每一路输入都要真的在自己组里赢过（比它优先级高的')
    L.append('// 都不请求而它请求），且每个 ready 端口取遍 0/1（组内第 0 名只要求取到 1）。')
    L.append('// 激励：valid 六种形态轮换（全 0 / 全 1 / 单点 / 稀疏 / 稠密 / 随机），')
    L.append('// payload 每路每拍独立随机（含别的域 wen 这些「应被忽略」的输入）。')
    L.append('//')
    L.append('// 本文件由 scripts/gen_realwbcc.py 生成，勿手改。')
    L.append('// ' + '=' * 76)
    L.append('`timescale 1ns/1ps')
    L.append('module tb;')
    L.append('  int unsigned NCYCLES = 200000;')
    L.append('  bit clk = 0; always #5 clk = ~clk;')
    L.append('  longint errors = 0, checks = 0;')
    L.append('  `define CK(g, i, nm) \\')
    L.append('    begin checks++; if ((g) !== (i)) begin errors++; \\')
    L.append('      if (errors < 20) $display("MISMATCH %0t %s golden=%h impl=%h", $time, nm, (g), (i)); \\')
    L.append('    end end')
    L.append('  localparam int MAXIN = 16;')
    L.append('  logic [MAXIN-1:0] vld [%d];' % len(infos))
    L.append('  logic [MAXIN-1:0] w1, w2;          // 本域 wen / 别的域 wen')
    L.append('  logic [7:0]   pd  [MAXIN];')
    L.append('  logic [127:0] dat [MAXIN];')
    L.append('  longint win_cnt [%d][MAXIN];' % len(infos))
    L.append('  longint rdy0 [%d][MAXIN], rdy1 [%d][MAXIN];' % (len(infos), len(infos)))
    for vi, info in enumerate(infos):
        n = info['name']
        L.append('')
        L.append('  // ---- %s ----' % n)
        sigs = []
        for p, (d, w) in info['ports'].items():
            if d == 'output':
                L.append('  logic [%d:0] g_%s_%s, i_%s_%s;' % (w - 1, vi, p, vi, p))
                sigs.append((p, w))
        for side, mod in (('g', n), ('i', n + '_xs')):
            L.append('  %s u_%s%d (' % (mod, side, vi))
            conns = []
            for p, (d, w) in info['ports'].items():
                if d == 'output':
                    conns.append('    .%s (%s_%d_%s)' % (p, side, vi, p))
                    continue
                m = re.fullmatch(r'io_in_(\d+)_(\w+)', p)
                x, f = int(m[1]), m[2]
                if f == 'valid':
                    e = 'vld[%d][%d]' % (vi, x)
                elif f == 'bits_' + info['wen']:
                    e = 'w1[%d]' % x
                elif f.endswith('Wen'):
                    e = 'w2[%d]' % x
                elif f == 'bits_pdest':
                    e = 'pd[%d][%d:0]' % (x, w - 1)
                elif f == 'bits_data':
                    e = 'dat[%d][%d:0]' % (x, w - 1)
                else:
                    die('tb: 未知输入 %s' % p)
                conns.append('    .%s (%s)' % (p, e))
            L.append(',\n'.join(conns))
            L.append('  );')
        info['_outs'] = sigs
    L.append('')
    L.append('  task automatic drive(int unsigned cyc);')
    L.append('    for (int v = 0; v < %d; v++) begin' % len(infos))
    L.append('      case ((cyc / 7 + v) % 6)')
    L.append("        0: vld[v] = '0;")
    L.append("        1: vld[v] = '1;")
    L.append("        2: vld[v] = MAXIN'(1) << $urandom_range(MAXIN-1);")
    L.append('        3: vld[v] = MAXIN\'($urandom) & MAXIN\'($urandom) & MAXIN\'($urandom);')
    L.append('        4: vld[v] = MAXIN\'($urandom) | MAXIN\'($urandom);')
    L.append("        default: vld[v] = MAXIN'($urandom);")
    L.append('      endcase')
    L.append('    end')
    L.append("    w1 = MAXIN'($urandom); w2 = MAXIN'($urandom);")
    L.append('    for (int i = 0; i < MAXIN; i++) begin')
    L.append('      pd[i] = 8\'($urandom);')
    L.append('      dat[i] = {$urandom, $urandom, $urandom, $urandom};')
    L.append('    end')
    L.append('  endtask')
    L.append('')
    L.append('  task automatic compare();')
    for vi, info in enumerate(infos):
        for p, w in info['_outs']:
            L.append('    `CK(g_%d_%s, i_%d_%s, "%s.%s")' % (vi, p, vi, p, info['name'], p))
    L.append('  endtask')
    L.append('')
    L.append('  // 覆盖：谁赢了（按 golden 分组表，赢 = 本组排在它前面的都不请求而它请求）')
    L.append('  task automatic sample_cov();')
    for vi, info in enumerate(infos):
        for g in info['grp']:
            for k, x in enumerate(g):
                higher = ' & '.join('~vld[%d][%d]' % (vi, y) for y in g[:k])
                cond = 'vld[%d][%d]' % (vi, x) + ((' & ' + higher) if higher else '')
                L.append('    if (%s) win_cnt[%d][%d]++;' % (cond, vi, x))
        for x in range(info['num_in']):
            p = 'io_in_%d_ready' % x
            if p in info['ports']:
                L.append('    if (g_%d_%s) rdy1[%d][%d]++; else rdy0[%d][%d]++;' % (vi, p, vi, x, vi, x))
    L.append('  endtask')
    L.append('')
    L.append('  initial begin')
    L.append('    int unsigned cyc;')
    L.append('    bit cov_ok;')
    L.append('    void\'($value$plusargs("ncycles=%d", NCYCLES));')
    L.append('    for (cyc = 0; cyc < NCYCLES; cyc++) begin')
    L.append('      drive(cyc);')
    L.append('      #1;')
    L.append('      compare();')
    L.append('      sample_cov();')
    L.append('      @(posedge clk);')
    L.append('    end')
    L.append('    cov_ok = 1;')
    for vi, info in enumerate(infos):
        size_of = {x: len(g) for g in info['grp'] for x in g}
        first = {g[0] for g in info['grp']}
        for x in range(info['num_in']):
            L.append('    if (win_cnt[%d][%d] == 0) begin cov_ok = 0; $display("COVER-MISS %s in%d never won"); end'
                     % (vi, x, info['name'], x))
            if ('io_in_%d_ready' % x) in info['ports']:
                L.append('    if (rdy1[%d][%d] == 0) begin cov_ok = 0; $display("COVER-MISS %s in%d ready never 1"); end'
                         % (vi, x, info['name'], x))
                if x not in first:
                    L.append('    if (rdy0[%d][%d] == 0) begin cov_ok = 0; $display("COVER-MISS %s in%d ready never 0"); end'
                             % (vi, x, info['name'], x))
    for vi, info in enumerate(infos):
        L.append('    $display("COVER %s wins:%s", %s);' % (
            info['name'], ''.join(' %0d' for _ in range(info['num_in'])),
            ', '.join('win_cnt[%d][%d]' % (vi, x) for x in range(info['num_in']))))
    L.append('    $display("checks=%0d errors=%0d cover=%0d", checks, errors, cov_ok);')
    L.append('    if (errors == 0 && cov_ok) $display("TEST PASSED");')
    L.append('    else $display("TEST FAILED");')
    L.append('    $finish;')
    L.append('  end')
    L.append('endmodule')
    return '\n'.join(L) + '\n'


def build():
    infos = [parse(v) for v in VARIANTS]
    files = {}
    core_p = REPO / CORE
    core = core_p.read_text()
    if core.count(BEGIN) != 1 or core.count(END) != 1:
        die('%s: GENERATED 标记不唯一' % CORE)
    head, rest = core.split(BEGIN)
    _, tail = rest.split(END)
    files[CORE] = head + BEGIN + wrapper(infos[0]) + END + tail
    for info in infos[1:]:
        files['rtl/backend/%s.sv' % info['name']] = thin_file(info)
    files['verif/ut/RealWBCollideChecker/tb.sv'] = tb(infos)
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
        print('gen_realwbcc: %d 个产物与生成器一致' % len(files))
        return 0
    print('gen_realwbcc: 写出/校验 %d 个文件' % len(files))
    return 0


if __name__ == '__main__':
    sys.exit(main())

#!/usr/bin/env python3
"""gen_storequeue_ut.py —— 生成 verif/ut/StoreQueue/tb.sv（golden vs 重写 双例化差分）

用法：
    gen_storequeue_ut.py --emit [-o FILE]   # 生成
    gen_storequeue_ut.py --check            # 幂等校验（与仓库内文件比对）

为什么要逐根输出统计而不是只报一个 errors：
  StoreQueue 有 399 根输出，一轮重写不可能一次全驱动。只报 errors 的话，
  「驱动了 0 根」和「驱动了 300 根但错 1 根」都是红的，看不出进度，也容易
  被拿来当作「按构造不会红」的话术。这里每根输出各自计一个失配计数，
  最后打印 MATCH_OUTPUTS=<n>/<总数>，n 是**整轮零失配**的输出根数。
  ★注意 n 只是差分指标，不等于『这根已证明正确』★：没被激励覆盖到的
  输出也会零失配。所以同时打印 TOGGLED（golden 侧真的变过值的根数），
  零 toggle 的那些单独列出，不许算进已验证。
"""
import argparse, pathlib, re, sys

HERE = pathlib.Path(__file__).resolve().parent
GOLDEN = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl/StoreQueue.sv')
TARGET = HERE.parent / 'verif' / 'ut' / 'StoreQueue' / 'tb.sv'

PORT_RE = re.compile(r'^\s*(input|output)\s+(\[[^\]]*\]\s*)?([A-Za-z_][A-Za-z0-9_]*)\s*,?\s*$')


def parse_ports(path=GOLDEN):
    ports, inside = [], False
    for line in path.read_text().splitlines():
        if not inside:
            if re.match(r'^module\s+StoreQueue\s*\(', line):
                inside = True
            continue
        if line.strip().startswith(');'):
            break
        m = PORT_RE.match(line)
        if m:
            d, w, n = m.group(1), (m.group(2) or '').strip(), m.group(3)
            ports.append((d, w, n))
    return ports


def width_of(w):
    if not w:
        return 1
    m = re.match(r'\[(\d+):(\d+)\]', w)
    return int(m.group(1)) - int(m.group(2)) + 1


def emit():
    ports = parse_ports()
    ins = [p for p in ports if p[0] == 'input' and p[2] not in ('clock', 'reset')]
    outs = [p for p in ports if p[0] == 'output']
    L = []
    a = L.append
    a('// ===========================================================================')
    a('//  verif/ut/StoreQueue/tb.sv —— ★本文件由 scripts/gen_storequeue_ut.py 生成★')
    a('//  不要手改；改生成器后跑 `python3 scripts/gen_storequeue_ut.py --emit -o tb.sv`')
    a('//')
    a('//  golden StoreQueue 与重写 StoreQueue_xs 同激励双例化，逐根输出差分。')
    a('//  报告口径见生成器 docstring：MATCH_OUTPUTS 只是差分指标，')
    a('//  ★没被激励 toggle 到的输出不算已验证★，单独打印 NEVER_TOGGLED。')
    a('// ===========================================================================')
    a('`timescale 1ns/1ps')
    a('')
    a('module tb;')
    a('  localparam int NOUT = %d;' % len(outs))
    a('')
    a('  reg clock = 1\'b0;')
    a('  reg reset = 1\'b1;')
    a('  always #5 clock = ~clock;')
    a('')
    a('  integer ncycles;')
    a('  integer seed;')
    a('  integer seed0;   // $random(seed) 会就地更新 seed，报告要打初值')
    a('  integer i;')
    a('  integer cyc;')
    a('  integer checks;')
    a('  integer mism [0:NOUT-1];')
    a('  integer togg [0:NOUT-1];')
    a('  reg [127:0] prev [0:NOUT-1];')
    a('  reg        seen [0:NOUT-1];')
    a('  integer gx  [0:NOUT-1];   // golden 侧该根出现 X/Z 的拍数')
    a('  integer xx  [0:NOUT-1];   // 两侧**都**是 X/Z 的拍数（!== 会判成"相等"）')
    a('')
    # input regs
    a('  // ---- 激励（604 根输入，clock/reset 除外 -> %d 根） ----' % len(ins))
    for d, w, n in ins:
        a('  reg %-12s %s;' % (w if w else '', n))
    a('')
    # output wires
    a('  // ---- golden 侧 / 重写侧 输出 ----')
    for d, w, n in outs:
        a('  wire %-12s g_%s;' % (w if w else '', n))
    for d, w, n in outs:
        a('  wire %-12s x_%s;' % (w if w else '', n))
    a('')
    # instances
    for inst, pfx in (('StoreQueue', 'g_'), ('StoreQueue_xs', 'x_')):
        a('  %s u_%s (' % (inst, pfx.rstrip('_')))
        a('    .clock(clock), .reset(reset),')
        conn = []
        for d, w, n in ports:
            if n in ('clock', 'reset'):
                continue
            conn.append('    .%s(%s%s)' % (n, pfx if d == 'output' else '', n))
        a(',\n'.join(conn))
        a('  );')
        a('')
    # stimulus
    a('  // ---- 随机激励：1 位信号按密度给，多位全随机 ----')
    a('  task drive_random;')
    a('    begin')
    for d, w, n in ins:
        wd = width_of(w)
        if wd == 1:
            a('      %s <= ($random(seed) %% 100) < 30;' % n)
        elif wd <= 32:
            a('      %s <= $random(seed);' % n)
        else:
            nch = (wd + 31) // 32
            parts = ', '.join(['$random(seed)'] * nch)
            a('      %s <= {%s};' % (n, parts))
    a('    end')
    a('  endtask')
    a('')
    a('  // ---- 逐根输出差分 ----')
    a('  task check_outputs;')
    a('    begin')
    for idx, (d, w, n) in enumerate(outs):
        a('      if (g_%s !== x_%s) mism[%d] = mism[%d] + 1;' % (n, n, idx, idx))
        a('      if (^g_%s === 1\'bx) begin' % n)
        a('        gx[%d] = gx[%d] + 1;' % (idx, idx))
        a('        if (^x_%s === 1\'bx) xx[%d] = xx[%d] + 1;' % (n, idx, idx))
        a('      end')
        a('      if (seen[%d] && prev[%d] !== g_%s) togg[%d] = togg[%d] + 1;'
          % (idx, idx, n, idx, idx))
        a('      prev[%d] = g_%s; seen[%d] = 1\'b1;' % (idx, n, idx))
    a('      checks = checks + 1;')
    a('    end')
    a('  endtask')
    a('')
    a('  integer nmatch; integer ntogg; integer nnever; integer nverified;')
    a('  integer nxonly;   // 整轮 golden 恒 X 的根数')
    a('  integer nxmatch;  // "零失配"里靠 X===X 混进来的根数')
    a('  initial begin')
    a('    seed = 1; ncycles = 200000;')
    a('    // ★ut_common.mk 下发的是 +ntb_random_seed=，不是 +seed=★')
    a('    // 用错名字的话 3 个 seed 跑的是同一条激励，等于只跑了一轮。')
    a('    if (!$value$plusargs("ntb_random_seed=%d", seed)) seed = 1;')
    a('    seed0 = seed;')
    a('    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;')
    a('    for (i = 0; i < NOUT; i = i + 1) begin')
    a('      mism[i] = 0; togg[i] = 0; prev[i] = 128\'d0; seen[i] = 1\'b0;')
    a('      gx[i] = 0; xx[i] = 0;')
    a('    end')
    a('    checks = 0;')
    a('    drive_random();')
    a('    repeat (10) @(posedge clock);')
    a('    reset <= 1\'b0;')
    a('    @(posedge clock);')
    a('    for (cyc = 0; cyc < ncycles; cyc = cyc + 1) begin')
    a('      @(negedge clock);')
    a('      check_outputs();')
    a('      drive_random();')
    a('      @(posedge clock);')
    a('    end')
    a('    nmatch = 0; ntogg = 0; nnever = 0; nverified = 0; nxonly = 0; nxmatch = 0;')
    a('    for (i = 0; i < NOUT; i = i + 1) begin')
    a('      if (mism[i] == 0) nmatch = nmatch + 1;')
    a('      if (togg[i] >  0) ntogg  = ntogg  + 1;')
    a('      else              nnever = nnever + 1;')
    a('      if (mism[i] == 0 && togg[i] > 0) nverified = nverified + 1;')
    a('      if (gx[i] == checks) nxonly = nxonly + 1;')
    a('      if (mism[i] == 0 && xx[i] > 0) nxmatch = nxmatch + 1;')
    a('    end')
    a('    $display("");')
    a('    $display("==== StoreQueue UT (seed=%0d ncycles=%0d) ====", seed0, ncycles);')
    a('    $display("checks          = %0d", checks);')
    a('    $display("MATCH_OUTPUTS   = %0d/%0d   (整轮零失配的输出根数)", nmatch, NOUT);')
    a('    $display("TOGGLED         = %0d/%0d   (golden 侧真的变过值)", ntogg, NOUT);')
    a('    $display("NEVER_TOGGLED   = %0d      (★未被激励覆盖，不算已验证★)", nnever);')
    a('    $display("GOLDEN_ALWAYS_X = %0d      (golden 侧整轮恒 X，多为无复位寄存器)", nxonly);')
    a('    $display("XEQX_FAKE_MATCH = %0d      (★零失配里靠 X===X 混进来的，不是真匹配★)", nxmatch);')
    a('    $display("VERIFIED        = %0d/%0d   (零失配 AND 被 toggle 到)", nverified, NOUT);')
    a('    $display("errors          = %0d", NOUT - nmatch);')
    a('    // ★判绿口径★ ut_common.mk 的 run: 靠 grep "TEST PASSED" 判定。')
    a('    // checks==0 时**不许**打 TEST PASSED —— 那是"什么都没比",不是通过。')
    a('    if (checks == 0) begin')
    a('      $display("★checks=0：什么都没比，既不是通过也不是失败★");')
    a('      $display("TEST FAILED (checks=0)");')
    a('    end else if (nmatch == NOUT) begin')
    a('      $display("TEST PASSED");')
    a('    end else begin')
    a('      $display("TEST FAILED (%0d/%0d 根输出失配)", NOUT - nmatch, NOUT);')
    a('    end')
    a('    $finish;')
    a('  end')
    a('')
    a('endmodule')
    return '\n'.join(L) + '\n'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--emit', action='store_true')
    ap.add_argument('--check', action='store_true')
    ap.add_argument('-o', '--out')
    a = ap.parse_args()
    if a.check:
        want = emit()
        if not TARGET.exists():
            print('FAIL gen_storequeue_ut --check: %s 不存在' % TARGET)
            return 1
        if TARGET.read_text() != want:
            print('FAIL gen_storequeue_ut --check: %s 与生成器输出不一致' % TARGET)
            return 1
        print('PASS gen_storequeue_ut --check: %s 一致 (%d 行)' % (TARGET, want.count('\n')))
        return 0
    if a.emit:
        t = emit()
        if a.out:
            pathlib.Path(a.out).write_text(t)
            print('wrote %s (%d lines)' % (a.out, t.count('\n')))
        else:
            sys.stdout.write(t)
        return 0
    ap.print_help()
    return 0


if __name__ == '__main__':
    sys.exit(main() or 0)

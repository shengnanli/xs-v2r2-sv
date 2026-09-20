#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""gen.py —— 生成 SnapshotGenerator **家族** UT 的 tb.sv（11 个变体一次跑完）。

端口声明 / 双例化 / 逐拍比对这三段是机械文本，照样从 **G1 golden 的端口表**生成 ——
手抄漏一根线，UT 自己发现不了（漏掉的那根在两侧都悬空成 x，`===` 比对反而"通过"）。
所以除了生成，还在 tb 里钉了两道机械守卫（见 tb 文件头的 §GUARD）。

手写的只有激励与覆盖统计。

★为什么 11 个变体合在一个 tb★ 实测（gen_variants.py 的三道闸 + 逐字节 diff）：
11 份 golden 的控制逻辑完全相同，只有 payload 位宽不同（_14 另加 ptr/valids 输出）。
控制激励因此可以共用一份 —— 11 个实例走同一条队列轨迹，任何一个变体的 payload
通路接错都会当拍暴露。这与 verif/ut/WrBypass 的家族 tb 是同一个形状。

用法: python3 gen.py   （Makefile 不自动调用；改了本文件要手动重跑并提交 tb.sv）
"""
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
GOLDEN_DIR = pathlib.Path('/home/eda/xs-env/G1-canonical/golden-rtl')
PORT_RE = re.compile(r'^\s*(input|output)\s+(?:(\[[^\]]*\])\s+)?(\w+)\s*,?\s*$')

# 家族 11 个变体。base 放第一个：覆盖统计读的是它的内部状态（控制核 11 份相同，
# 所以读任何一个都一样；固定读 base 免得换个文件就得改覆盖段）。
VARIANTS = ['SnapshotGenerator'] + ['SnapshotGenerator_%d' % n
                                    for n in (1, 2, 3, 4, 5, 6, 7, 11, 12, 14)]
# 期望端口数（实测自 G1 golden；对不上就拒绝生成，防 golden 换版后静默少测）
EXPECT_PORTS = {'SnapshotGenerator': 19, 'SnapshotGenerator_1': 19,
                'SnapshotGenerator_2': 34, 'SnapshotGenerator_3': 19,
                'SnapshotGenerator_4': 169, 'SnapshotGenerator_5': 179,
                'SnapshotGenerator_6': 244, 'SnapshotGenerator_7': 14,
                'SnapshotGenerator_11': 19, 'SnapshotGenerator_12': 19,
                'SnapshotGenerator_14': 107}

# 11 个变体共用的控制端口（激励只有这一份）
SHARED = {'clock', 'reset', 'io_enq', 'io_deq', 'io_redirect',
          'io_flushVec_0', 'io_flushVec_1', 'io_flushVec_2', 'io_flushVec_3'}


def width(rng):
    if not rng:
        return 1
    m = re.fullmatch(r'\[(\d+):0\]', rng)
    if not m:
        raise SystemExit('不认识的位宽写法: %r' % rng)
    return int(m.group(1)) + 1


def parse_ports(top):
    txt = (GOLDEN_DIR / (top + '.sv')).read_text().split('\n')
    start = next(i for i, l in enumerate(txt) if l.startswith('module %s(' % top))
    ports, i = [], start + 1
    while txt[i].rstrip() != ');':
        m = PORT_RE.match(txt[i])
        if not m:
            raise SystemExit('%s 端口行解析失败: %r' % (top, txt[i]))
        ports.append((m.group(1), m.group(2) or '', m.group(3)))
        i += 1
    if len(ports) != EXPECT_PORTS[top]:
        raise SystemExit('%s 只解析到 %d 个端口，与实测的 %d 不符，拒绝生成'
                         % (top, len(ports), EXPECT_PORTS[top]))
    return ports


def tag(top):
    """变体的短标识，用作 tb 里的信号名前缀。"""
    return 'v0' if top == 'SnapshotGenerator' else 'v' + top.split('_')[-1]


def payload(ports):
    """io_enqData* 输入端口 -> [(名, 位宽, hi, lo)]，按声明顺序先声明的放高位。"""
    fs = [(n, width(r)) for d, r, n in ports
          if d == 'input' and n.startswith('io_enqData')]
    dw = sum(w for _, w in fs)
    out, lo = [], dw
    for n, w in fs:
        hi = lo - 1
        lo -= w
        out.append((n, w, hi, lo))
    assert lo == 0
    return out, dw


HEADER = r'''// =============================================================================
// SnapshotGenerator 家族 UT —— 11 个 golden 变体（SnapshotGenerator 与
// _1/_2/_3/_4/_5/_6/_7/_11/_12/_14）与各自的重写 <名>_xs 双例化同激励，
// 逐拍比对全部输出端口（合计 596 根）。
// ★本文件由 gen.py 生成，改激励请改 gen.py 再重跑★
//
// ★ 为什么一个 tb 装 11 个 ★ 实测 11 份 golden 的控制逻辑逐字节相同，
// 差别只在 payload 位宽（6/7/8/8/8/9/9/60/256/272/376 位）与 _14 多出的
// ptr/valids 输出。所以控制激励共用一份，11 个实例走同一条队列轨迹；
// 每个变体自带一路独立随机 payload，谁的 payload 通路接错都当拍暴露。
//
// ★ 暖机 ★ 4 个快照槽**不带复位**，上电随机时两个实例各拿各的随机值，
// 必须先各写一次才能比对：暖机段连开 4 拍 enq（队列从空到满，正好写遍 4 个槽），
// 再放掉。暖机 24 拍，之后才开比对。
// ★暖机之后周期性打 reset 脉冲★（见 §RESET，每 829 拍拉高 3 拍，
// 200k 拍里约 240 个复位拍）：那时 4 个槽两侧已一致，复位臂落在比对窗口里，
// 「给 snapshots 加复位」这类变异才可观测（mutants.py M1）。
//
// ★ §GUARD 两道机械守卫 ★ 生成器漏接一根线，两侧都会悬空成 x，
// 而 `===` 认为 x 等于 x —— 比对反而"通过"。所以：
//   G1 x 守卫：暖机之后 golden 侧任何一根输出出现 x/z 即记 error；
//   G2 激励守卫：每个变体的 payload 总线必须每一位都被观测到 0 和 1
//                （见 COVERAGE 的 "payload bits 全翻转"），
//                否则说明有端口根本没进激励。
//
// ★ 激励为什么要定向 ★ 这是个 4 项环形队列 + 按位作废(flushVec)。
// 判别力全在边界上：队满时 enq 被静默丢弃、队空时 deq（golden 有断言但不改行为）、
// enq/deq 同拍、redirect 把 enq/deq 一起关掉而 flush 照常生效、
// 以及 flush 打中有效槽后从 deqPtr 往后扫重算 enqPtr 的那四个候选。
// 纯均匀随机能碰到前几条，但「四个候选各被选中过」要靠定向：
// 所以激励在若干相位间切换（FILL / DRAIN / CHURN / FLUSH / RAND），
// FLUSH 相位会**直接枚举 16 种 flushVec 组合**，保证每种都打过。
// 覆盖由文件末尾的 COVERAGE 段判定，任何一项不足即 TEST FAILED。
// =============================================================================
`timescale 1ns/1ps

module tb;

  logic clock = 1'b0;
  logic reset = 1'b1;
  always #5 clock = ~clock;

  int unsigned ncycles = 200000;
  int unsigned cyc     = 0;
  int unsigned errors  = 0;
  int unsigned checked = 0;

  localparam int WARM_CYCLES = 24;

  // --- 共用控制激励（11 个实例同一份） ---
  logic io_enq;
  logic io_deq;
  logic io_redirect;
  logic io_flushVec_0;
  logic io_flushVec_1;
  logic io_flushVec_2;
  logic io_flushVec_3;
'''


def gen_variant_block(top, ports):
    tg, (pay, dw) = tag(top), payload(ports)
    outs = [(n, width(r)) for d, r, n in ports if d == 'output']
    ow = sum(w for _, w in outs)
    L = ['', '  // ==== %s（payload %d 位 / 输出 %d 根 %d 位）====' % (top, dw, len(outs), ow)]
    L.append('  logic [%d:0] pay_%s;   // 本变体独立的随机 payload' % (dw - 1, tg))
    for n, w, hi, lo in pay:
        sl = '[%d]' % hi if w == 1 else '[%d:%d]' % (hi, lo)
        L.append('  wire %-8s %s_%s = pay_%s%s;' %
                 ('[%d:0]' % (w - 1) if w > 1 else '', tg, n, tg, sl))
    for n, w in outs:
        r = '[%d:0]' % (w - 1) if w > 1 else ''
        L.append('  logic %-8s g_%s_%s, x_%s_%s;' % (r, tg, n, tg, n))

    for side, mod in (('g', top), ('x', top + '_xs')):
        inst = 'dut_g' if (side == 'g' and top == 'SnapshotGenerator') else \
               'dut_x' if (side == 'x' and top == 'SnapshotGenerator') else \
               '%s_%s' % (side, tg)
        L.append('  %s %s (' % (mod, inst))
        conns = []
        for d, r, n in ports:
            if n in SHARED:
                conns.append('    .%-30s (%s)' % (n, n))
            elif d == 'input':
                conns.append('    .%-30s (%s_%s)' % (n, tg, n))
            else:
                conns.append('    .%-30s (%s_%s_%s)' % (n, side, tg, n))
        L.append(',\n'.join(conns))
        L.append('  );')

    # 打包成一根总线做快速比对（逐拍 596 次 task 调用太慢；出错再逐根定位）
    for side in ('g', 'x'):
        L.append('  wire [%d:0] %s_bus_%s = {' % (ow - 1, side, tg))
        L.append(',\n'.join('    %s_%s_%s' % (side, tg, n) for n, _ in outs))
        L.append('  };')
    return '\n'.join(L)


def gen_detail(top, ports):
    tg = tag(top)
    L = ['  task automatic detail_%s();' % tg]
    for d, r, n in ports:
        if d == 'output':
            L.append('    chk("%s.%s", g_%s_%s, x_%s_%s);' % (top, n, tg, n, tg, n))
    L.append('  endtask')
    return '\n'.join(L)


def gen_check_all(tops):
    L = ['  // --- 逐拍比对：先比总线（快），不一致再逐根定位（本段由 gen.py 生成） ---',
         '  task automatic check_outputs();']
    for t in tops:
        tg = tag(t)
        L.append('    checked++;')
        L.append('    if (g_bus_%s !== x_bus_%s) begin' % (tg, tg))
        L.append('      if (errors <= 40) $display("[%%0t] cyc=%%0d BUS MISMATCH %s", $time, cyc);' % t)
        L.append('      detail_%s();' % tg)
        L.append('    end')
        # §GUARD G1：golden 侧出现 x/z ⇒ 有端口没被驱动（多半是 tb 漏接）
        L.append('    if (^g_bus_%s === 1\'bx) begin' % tg)
        L.append('      errors++;')
        L.append('      if (errors <= 40) $display("[%%0t] cyc=%%0d ★X ON GOLDEN BUS★ %s", $time, cyc);' % t)
        L.append('    end')
    L.append('  endtask')
    return '\n'.join(L)


def gen_fresh(tops):
    L = ['  // 每拍换一组可区分的 payload，这样「写错槽」一定看得出来（gen.py 生成）。',
         '  task automatic fresh_data();']
    for t in tops:
        tg, (_, dw) = tag(t), payload(parse_ports(t))
        for k in range((dw + 31) // 32):
            hi = min(dw - 1, 32 * k + 31)
            lo = 32 * k
            sl = '[%d]' % hi if hi == lo else '[%d:%d]' % (hi, lo)
            L.append('    pay_%s%s = $urandom();' % (tg, sl))
    L.append('  endtask')
    return '\n'.join(L)


def gen_payload_cov(tops):
    """G2 激励守卫：每个变体的 payload 每一位都要见过 0 和 1。"""
    decl, smp, chk = [], [], []
    for t in tops:
        tg, (_, dw) = tag(t), payload(parse_ports(t))
        decl.append('  logic [%d:0] pones_%s = \'0, pzeros_%s = \'0;' % (dw - 1, tg, tg))
        smp.append('    pones_%s  |= pay_%s;' % (tg, tg))
        smp.append('    pzeros_%s |= ~pay_%s;' % (tg, tg))
        chk.append('    need("%s payload bits 全翻转", ((&pones_%s) && (&pzeros_%s)) ? 1 : 0, 1);'
                   % (t, tg, tg))
    return '\n'.join(decl), '\n'.join(smp), '\n'.join(chk)


def gen_slot_cov(tops):
    """每个变体的 4 个槽在 golden 侧两两不同的拍数（保证激励能区分槽）。"""
    decl, smp, chk = [], [], []
    for t in tops:
        ports = parse_ports(t)
        tg = tag(t)
        # 每个槽的输出端口按声明顺序拼成一根
        slot = []
        for i in range(4):
            pre = 'io_snapshots_%d' % i
            sig = [n for d, _, n in ports if d == 'output' and n.startswith(pre)]
            slot.append('{%s}' % ', '.join('g_%s_%s' % (tg, n) for n in sig))
        decl.append('  int unsigned cov_distinct_%s = 0;' % tg)
        cond = ' && '.join('%s !== %s' % (slot[a], slot[b])
                           for a in range(4) for b in range(a + 1, 4))
        smp.append('    if (%s) cov_distinct_%s++;' % (cond, tg))
        chk.append('    need("%s 4 槽两两不同", cov_distinct_%s, 500);' % (t, tg))
    return '\n'.join(decl), '\n'.join(smp), '\n'.join(chk)


BODY_HEAD = r'''
  task automatic chk(string name, logic [31:0] gv, logic [31:0] xv);
    if (gv !== xv) begin
      errors++;
      if (errors <= 40)
        $display("[%0t] cyc=%0d MISMATCH %s: golden=%0h xs=%0h", $time, cyc, name, gv, xv);
    end
  endtask

  // ---------------------------------------------------------------------------
  // §STIM
  // ---------------------------------------------------------------------------
  typedef enum int { PH_FILL, PH_DRAIN, PH_CHURN, PH_FLUSH, PH_RAND } phase_e;
  phase_e phase      = PH_FILL;
  int     phase_left = 0;
  int     flush_enum = 0;     // FLUSH 相位里逐个枚举 16 种 flushVec 组合

  function automatic logic chance(int pct);
    return ($urandom_range(0, 99) < pct);
  endfunction

  task automatic set_flush(logic [3:0] f);
    io_flushVec_0 = f[0];
    io_flushVec_1 = f[1];
    io_flushVec_2 = f[2];
    io_flushVec_3 = f[3];
  endtask

  task automatic idle_inputs();
    io_enq      = 1'b0;
    io_deq      = 1'b0;
    io_redirect = 1'b0;
    set_flush(4'h0);
  endtask

  task automatic warm_drive(int c);
    idle_inputs();
    fresh_data();
    if (c < 6)       io_enq = 1'b1;    // 4 拍写满 4 个槽（第 5、6 拍队满被丢）
    else if (c < 12) io_deq = 1'b1;    // 放干净
  endtask

  task automatic drive();
    idle_inputs();
    fresh_data();

    if (phase_left <= 0) begin
      case ($urandom_range(0, 9))
        0, 1:    phase = PH_FILL;
        2, 3:    phase = PH_DRAIN;
        4, 5, 6: phase = PH_CHURN;
        7, 8:    phase = PH_FLUSH;
        default: phase = PH_RAND;
      endcase
      phase_left = $urandom_range(8, 120);
    end
    phase_left--;

    case (phase)
      PH_FILL:  begin io_enq = chance(85); io_deq = chance(5);  end
      PH_DRAIN: begin io_enq = chance(5);  io_deq = chance(85); end
      PH_CHURN: begin io_enq = chance(55); io_deq = chance(55);
                      io_redirect = chance(8); end
      PH_FLUSH: begin
        io_enq = chance(45); io_deq = chance(30);
        // ★枚举★ 16 种组合轮着来，保证每种都打过（纯随机下 4'hF 很稀疏）
        set_flush(flush_enum[3:0]);
        flush_enum = flush_enum + 1;
        io_redirect = chance(10);
      end
      default: begin
        io_enq      = chance(50);
        io_deq      = chance(50);
        io_redirect = chance(10);
        set_flush($urandom_range(0, 15));
      end
    endcase
  endtask

  // ---------------------------------------------------------------------------
  // §RESET 暖机后的复位脉冲（复位窗口必须落在比对窗口里）
  // ---------------------------------------------------------------------------
  // ★周期性★ 每 RST_PERIOD 拍拉高 3 拍（暖机后 200 拍起）。
  // 一开始只打了 3 次固定点，结果「给 4 个快照槽加复位」这个变异只报出
  // **26 个** error —— 余量太薄，换个 seed 就可能漏。改成周期性之后
  // 200k 拍里约 240 次复位事件，复位臂被反复观测（见 mutants.py 的 M1）。
  localparam int RST_PERIOD = 829;
  function automatic logic want_reset(int unsigned c);
    return (c > WARM_CYCLES + 200) && ((c % RST_PERIOD) < 3);
  endfunction

  // ---------------------------------------------------------------------------
  // §COV 覆盖事件 —— 控制部分读 base golden 实例（dut_g）。
  // 控制核 11 份逐字节相同（见 rtl 文件头的家族表），读哪个都一样。
  // ---------------------------------------------------------------------------
  int unsigned cov_valids [16];     // snptValids 的 16 种取值
  int unsigned cov_flush  [16];     // flushVec 的 16 种取值
  int unsigned cov_full, cov_empty;
  int unsigned cov_enq_drop;        // 队满时 enq 被丢
  int unsigned cov_deq_empty;       // 队空时 deq（golden 的断言场景）
  int unsigned cov_enqdeq_same;     // 同拍 enq+deq
  int unsigned cov_redir_gate;      // redirect 把 enq/deq 关掉的那一拍
  int unsigned cov_repair;          // flush 打中有效槽 ⇒ 重算 enqPtr
  int unsigned cov_cand [4];        // 重算时选中第几个候选
  int unsigned cov_ptrflag [2];     // snptEnqPtr.flag 两种取值
  int unsigned cov_rst_pulse;
'''

BODY_TAIL = r'''
  task automatic sample_cov();
    logic [3:0] v, f;
    logic full, empty, repair;
    v = {dut_g.snptValids_3, dut_g.snptValids_2, dut_g.snptValids_1, dut_g.snptValids_0};
    f = {io_flushVec_3, io_flushVec_2, io_flushVec_1, io_flushVec_0};
    full  = (dut_g.snptEnqPtr_flag != dut_g.snptDeqPtr_flag)
          && (dut_g.snptEnqPtr_value == dut_g.snptDeqPtr_value);
    empty = (dut_g.snptEnqPtr_flag == dut_g.snptDeqPtr_flag)
          && (dut_g.snptEnqPtr_value == dut_g.snptDeqPtr_value);
    repair = |(f & v);

    cov_valids[v]++;
    cov_flush[f]++;
    if (full)  cov_full++;
    if (empty) cov_empty++;
    if (io_enq && !io_redirect && full)   cov_enq_drop++;
    if (io_deq && !io_redirect && empty)  cov_deq_empty++;
    if (io_enq && io_deq && !io_redirect) cov_enqdeq_same++;
    if (io_redirect && (io_enq || io_deq)) cov_redir_gate++;
    if (repair) begin
      cov_repair++;
      if      (dut_g.newEnqPtrQualified_0) cov_cand[0]++;
      else if (dut_g.newEnqPtrQualified_1) cov_cand[1]++;
      else if (dut_g.newEnqPtrQualified_2) cov_cand[2]++;
      else                                 cov_cand[3]++;
    end
    cov_ptrflag[dut_g.snptEnqPtr_flag]++;
    if (reset && cyc > WARM_CYCLES) cov_rst_pulse++;
__PAYCOV_SMP__
__SLOTCOV_SMP__
  endtask

  int unsigned cov_fail = 0;
  task automatic need(string name, int unsigned v, int unsigned lo);
    $display("  %-40s %10d %s", name, v, (v >= lo) ? "" : "  <<< 覆盖不足");
    if (v < lo) cov_fail++;
  endtask

  task automatic report_cov();
    $display("--- COVERAGE (golden 侧内部状态统计) ---");
    for (int i = 0; i < 16; i++)
      need($sformatf("snptValids=%0h", i), cov_valids[i], 20);
    for (int i = 0; i < 16; i++)
      need($sformatf("flushVec=%0h", i), cov_flush[i], 20);
    need("queue full",        cov_full, 100);
    need("queue empty",       cov_empty, 100);
    need("enq dropped (full)",cov_enq_drop, 50);
    need("deq when empty",    cov_deq_empty, 50);
    need("enq+deq same cycle",cov_enqdeq_same, 100);
    need("redirect gates e/d",cov_redir_gate, 50);
    need("flush repairs ptr", cov_repair, 100);
    need("newEnqPtr cand 0",  cov_cand[0], 10);
    need("newEnqPtr cand 1",  cov_cand[1], 10);
    need("newEnqPtr cand 2",  cov_cand[2], 10);
    need("newEnqPtr cand 3",  cov_cand[3], 10);
    need("snptEnqPtr.flag=0", cov_ptrflag[0], 100);
    need("snptEnqPtr.flag=1", cov_ptrflag[1], 100);
    need("RST_PULSE 暖机后复位拍数", cov_rst_pulse, 60);
    $display("--- 每变体 payload 通路（§GUARD G2 + 槽可区分性）---");
__PAYCOV_CHK__
__SLOTCOV_CHK__
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    idle_inputs();
    fresh_data();
    reset = 1'b1;
    repeat (5) @(posedge clock);
    reset = 1'b0;

    for (cyc = 0; cyc < ncycles; cyc++) begin
      // 比对与覆盖采样都放在**上升沿之前**（输入已稳定的那一刻）
      @(negedge clock);
      reset = want_reset(cyc);
      if (cyc < WARM_CYCLES) warm_drive(cyc);
      else                   drive();
      #2;
      if (cyc >= WARM_CYCLES) begin
        check_outputs();
        sample_cov();
      end
      @(posedge clock);
      if (errors > 200) begin
        $display("错误过多，提前结束");
        break;
      end
    end

    report_cov();
    $display("cycles=%0d  compared=%0d  errors=%0d  cov_fail=%0d",
             cyc, checked, errors, cov_fail);
    if (errors == 0 && cov_fail == 0) $display("TEST PASSED");
    else                              $display("TEST FAILED");
    $finish;
  end

endmodule
'''


def main():
    allports = {t: parse_ports(t) for t in VARIANTS}
    parts = [HEADER]
    for t in VARIANTS:
        parts.append(gen_variant_block(t, allports[t]))
    pdecl, psmp, pchk = gen_payload_cov(VARIANTS)
    sdecl, ssmp, schk = gen_slot_cov(VARIANTS)
    parts.append('\n  // --- §GUARD G2 / 槽可区分性 的计数器（gen.py 生成） ---')
    parts.append(pdecl)
    parts.append(sdecl)
    parts.append(BODY_HEAD)
    parts.append(gen_fresh(VARIANTS))
    parts.append('')
    for t in VARIANTS:
        parts.append(gen_detail(t, allports[t]))
    parts.append('')
    parts.append(gen_check_all(VARIANTS))
    tail = (BODY_TAIL.replace('__PAYCOV_SMP__', psmp)
                     .replace('__SLOTCOV_SMP__', ssmp)
                     .replace('__PAYCOV_CHK__', pchk)
                     .replace('__SLOTCOV_CHK__', schk))
    parts.append(tail)
    (HERE / 'tb.sv').write_text('\n'.join(parts))
    n = sum(len(v) for v in allports.values())
    print('gen.py: 写出 tb.sv（%d 个变体 / 合计 %d 端口）' % (len(VARIANTS), n))
    return 0


if __name__ == '__main__':
    sys.exit(main())

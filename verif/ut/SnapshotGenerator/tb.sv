// =============================================================================
// SnapshotGenerator UT —— golden SnapshotGenerator 与重写 SnapshotGenerator_xs
// 双例化同激励，逐拍比对全部 8 根输出端口。
// ★本文件由 gen.py 生成，改激励请改 gen.py 再重跑★
//
// ★ 暖机 ★ 4 个快照槽（snapshots_0..3 的 flag+value）**不带复位**，
// 上电随机时两个实例各拿各的随机值，必须先各写一次才能比对：
// 暖机段连开 4 拍 enq（队列从空到满，正好写遍 4 个槽），再放掉。
// 暖机 24 拍，之后才开比对。
// ★暖机之后周期性打 reset 脉冲★（见 §RESET，每 829 拍拉高 3 拍，
// 200k 拍里约 240 个复位拍）：那时 4 个槽两侧已一致，复位臂落在比对窗口里，
// 「给 snapshots 加复位」这类变异才可观测（mutants.py M1）。
// ★一开始只打了 3 次固定点，M1 只报出 26 个 error —— 余量太薄，换个 seed 就可能漏。
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


  // --- 输入寄存器（两个 DUT 共用同一份激励） ---
  logic          io_enq;
  logic          io_enqData_flag;
  logic [7:0]    io_enqData_value;
  logic          io_deq;
  logic          io_redirect;
  logic          io_flushVec_0;
  logic          io_flushVec_1;
  logic          io_flushVec_2;
  logic          io_flushVec_3;

  // --- 输出线：g_ = golden，x_ = 重写 ---
  logic          g_io_snapshots_0_flag, x_io_snapshots_0_flag;
  logic [7:0]    g_io_snapshots_0_value, x_io_snapshots_0_value;
  logic          g_io_snapshots_1_flag, x_io_snapshots_1_flag;
  logic [7:0]    g_io_snapshots_1_value, x_io_snapshots_1_value;
  logic          g_io_snapshots_2_flag, x_io_snapshots_2_flag;
  logic [7:0]    g_io_snapshots_2_value, x_io_snapshots_2_value;
  logic          g_io_snapshots_3_flag, x_io_snapshots_3_flag;
  logic [7:0]    g_io_snapshots_3_value, x_io_snapshots_3_value;

  // --- 双例化（本段由 gen.py 生成） ---
  SnapshotGenerator dut_g (
    .clock                    (clock),
    .reset                    (reset),
    .io_enq                   (io_enq),
    .io_enqData_flag          (io_enqData_flag),
    .io_enqData_value         (io_enqData_value),
    .io_deq                   (io_deq),
    .io_redirect              (io_redirect),
    .io_flushVec_0            (io_flushVec_0),
    .io_flushVec_1            (io_flushVec_1),
    .io_flushVec_2            (io_flushVec_2),
    .io_flushVec_3            (io_flushVec_3),
    .io_snapshots_0_flag      (g_io_snapshots_0_flag),
    .io_snapshots_0_value     (g_io_snapshots_0_value),
    .io_snapshots_1_flag      (g_io_snapshots_1_flag),
    .io_snapshots_1_value     (g_io_snapshots_1_value),
    .io_snapshots_2_flag      (g_io_snapshots_2_flag),
    .io_snapshots_2_value     (g_io_snapshots_2_value),
    .io_snapshots_3_flag      (g_io_snapshots_3_flag),
    .io_snapshots_3_value     (g_io_snapshots_3_value)
  );

  SnapshotGenerator_xs dut_x (
    .clock                    (clock),
    .reset                    (reset),
    .io_enq                   (io_enq),
    .io_enqData_flag          (io_enqData_flag),
    .io_enqData_value         (io_enqData_value),
    .io_deq                   (io_deq),
    .io_redirect              (io_redirect),
    .io_flushVec_0            (io_flushVec_0),
    .io_flushVec_1            (io_flushVec_1),
    .io_flushVec_2            (io_flushVec_2),
    .io_flushVec_3            (io_flushVec_3),
    .io_snapshots_0_flag      (x_io_snapshots_0_flag),
    .io_snapshots_0_value     (x_io_snapshots_0_value),
    .io_snapshots_1_flag      (x_io_snapshots_1_flag),
    .io_snapshots_1_value     (x_io_snapshots_1_value),
    .io_snapshots_2_flag      (x_io_snapshots_2_flag),
    .io_snapshots_2_value     (x_io_snapshots_2_value),
    .io_snapshots_3_flag      (x_io_snapshots_3_flag),
    .io_snapshots_3_value     (x_io_snapshots_3_value)
  );

  // --- 逐拍比对全部 8 根输出（本段由 gen.py 生成） ---
  task automatic check_outputs();
    chk("io_snapshots_0_flag", g_io_snapshots_0_flag, x_io_snapshots_0_flag);
    chk("io_snapshots_0_value", g_io_snapshots_0_value, x_io_snapshots_0_value);
    chk("io_snapshots_1_flag", g_io_snapshots_1_flag, x_io_snapshots_1_flag);
    chk("io_snapshots_1_value", g_io_snapshots_1_value, x_io_snapshots_1_value);
    chk("io_snapshots_2_flag", g_io_snapshots_2_flag, x_io_snapshots_2_flag);
    chk("io_snapshots_2_value", g_io_snapshots_2_value, x_io_snapshots_2_value);
    chk("io_snapshots_3_flag", g_io_snapshots_3_flag, x_io_snapshots_3_flag);
    chk("io_snapshots_3_value", g_io_snapshots_3_value, x_io_snapshots_3_value);
  endtask

  task automatic chk(string name, logic [31:0] gv, logic [31:0] xv);
    checked++;
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
    io_enq           = 1'b0;
    io_deq           = 1'b0;
    io_redirect      = 1'b0;
    io_enqData_flag  = 1'b0;
    io_enqData_value = '0;
    set_flush(4'h0);
  endtask

  // 每拍换一个可区分的 enqData，这样「写错槽」一定看得出来。
  task automatic fresh_data();
    io_enqData_flag  = $urandom_range(0, 1);
    io_enqData_value = $urandom_range(0, 255);
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
  // §COV 覆盖事件 —— 全部读 golden 侧（dut_g）
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
  endtask

  int unsigned cov_fail = 0;
  task automatic need(string name, int unsigned v, int unsigned lo);
    $display("  %-28s %10d %s", name, v, (v >= lo) ? "" : "  <<< 覆盖不足");
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
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", ncycles)) ncycles = 200000;
    idle_inputs();
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

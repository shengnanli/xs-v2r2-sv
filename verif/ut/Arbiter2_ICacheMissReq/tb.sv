// 自动生成：verif/ut/Arbiter2_ICacheMissReq/gen.py（读 G1 golden）—— 勿手改
// ICache 固定优先级仲裁器家族双例化逐拍比对：
//   golden Arbiter2_ICacheMissReq / Arbiter5_MSHRAcquire vs 各自的 _xs
//   （同一个 xs_FixedPriorityArbiter_core 设不同 WIDTH/NUM_IN）。
// 被测语义：纯组合、lowest-index-wins、无锁定；一路都没请求时 out_bits 取最后一路
//   （golden 三元链的兜底分支，输出无意义但必须逐位一致，所以照样比）。
// 激励：valid 位图按"全 0 / 单热 / 稀疏 / 全随机"混合，各路载荷逐位随机，
//   out_ready 一半概率为 0（覆盖 in_ready 全 0 的情形）。
// 覆盖闸：每个变体都要 (1) 有效比对 >= COV_MIN；(2) **每一路**单独胜出 >= COV_MIN；
//   (3) 无人请求（out_valid=0）>= COV_MIN；(4) out_ready=0 >= COV_MIN；
//   (5) 每个输出位都被观察到过 1 和 0。任何一项不足即 TEST FAILED。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;

  // ---- Arbiter2_ICacheMissReq: 2 入口 / 载荷 50 位 ----
  logic [1:0] a2_valid;
  logic a2_out_ready;
  logic [99:0] a2_bits;   // 高位段 = 第 0 路
  wire  [1:0] g_a2_ready, i_a2_ready;
  wire  g_a2_out_valid, i_a2_out_valid;
  wire  [49:0] g_a2_out_bits, i_a2_out_bits;
  logic [49:0] a2_ones, a2_zeros;
  int   a2_checks, a2_none, a2_stall;
  int   a2_win [2];
  Arbiter2_ICacheMissReq u_g_a2 (
    .io_in_0_ready(g_a2_ready[1]),
    .io_in_0_valid(a2_valid[1]),
    .io_in_0_bits_blkPaddr(a2_bits[99:58]),
    .io_in_0_bits_vSetIdx(a2_bits[57:50]),
    .io_in_1_ready(g_a2_ready[0]),
    .io_in_1_valid(a2_valid[0]),
    .io_in_1_bits_blkPaddr(a2_bits[49:8]),
    .io_in_1_bits_vSetIdx(a2_bits[7:0]),
    .io_out_ready(a2_out_ready),
    .io_out_valid(g_a2_out_valid),
    .io_out_bits_blkPaddr(g_a2_out_bits[49:8]),
    .io_out_bits_vSetIdx(g_a2_out_bits[7:0])
  );
  Arbiter2_ICacheMissReq_xs u_i_a2 (
    .io_in_0_ready(i_a2_ready[1]),
    .io_in_0_valid(a2_valid[1]),
    .io_in_0_bits_blkPaddr(a2_bits[99:58]),
    .io_in_0_bits_vSetIdx(a2_bits[57:50]),
    .io_in_1_ready(i_a2_ready[0]),
    .io_in_1_valid(a2_valid[0]),
    .io_in_1_bits_blkPaddr(a2_bits[49:8]),
    .io_in_1_bits_vSetIdx(a2_bits[7:0]),
    .io_out_ready(a2_out_ready),
    .io_out_valid(i_a2_out_valid),
    .io_out_bits_blkPaddr(i_a2_out_bits[49:8]),
    .io_out_bits_vSetIdx(i_a2_out_bits[7:0])
  );

  // ---- Arbiter5_MSHRAcquire: 5 入口 / 载荷 60 位 ----
  logic [4:0] a5_valid;
  logic a5_out_ready;
  logic [299:0] a5_bits;   // 高位段 = 第 0 路
  wire  [4:0] g_a5_ready, i_a5_ready;
  wire  g_a5_out_valid, i_a5_out_valid;
  wire  [59:0] g_a5_out_bits, i_a5_out_bits;
  logic [59:0] a5_ones, a5_zeros;
  int   a5_checks, a5_none, a5_stall;
  int   a5_win [5];
  Arbiter5_MSHRAcquire u_g_a5 (
    .io_in_0_ready(g_a5_ready[4]),
    .io_in_0_valid(a5_valid[4]),
    .io_in_0_bits_acquire_address(a5_bits[295:248]),
    .io_in_0_bits_vSetIdx(a5_bits[247:240]),
    .io_in_1_ready(g_a5_ready[3]),
    .io_in_1_valid(a5_valid[3]),
    .io_in_1_bits_acquire_address(a5_bits[235:188]),
    .io_in_1_bits_vSetIdx(a5_bits[187:180]),
    .io_in_2_ready(g_a5_ready[2]),
    .io_in_2_valid(a5_valid[2]),
    .io_in_2_bits_acquire_address(a5_bits[175:128]),
    .io_in_2_bits_vSetIdx(a5_bits[127:120]),
    .io_in_3_ready(g_a5_ready[1]),
    .io_in_3_valid(a5_valid[1]),
    .io_in_3_bits_acquire_address(a5_bits[115:68]),
    .io_in_3_bits_vSetIdx(a5_bits[67:60]),
    .io_in_4_ready(g_a5_ready[0]),
    .io_in_4_valid(a5_valid[0]),
    .io_in_4_bits_acquire_source(a5_bits[59:56]),
    .io_in_4_bits_acquire_address(a5_bits[55:8]),
    .io_in_4_bits_vSetIdx(a5_bits[7:0]),
    .io_out_ready(a5_out_ready),
    .io_out_valid(g_a5_out_valid),
    .io_out_bits_acquire_source(g_a5_out_bits[59:56]),
    .io_out_bits_acquire_address(g_a5_out_bits[55:8]),
    .io_out_bits_vSetIdx(g_a5_out_bits[7:0])
  );
  Arbiter5_MSHRAcquire_xs u_i_a5 (
    .io_in_0_ready(i_a5_ready[4]),
    .io_in_0_valid(a5_valid[4]),
    .io_in_0_bits_acquire_address(a5_bits[295:248]),
    .io_in_0_bits_vSetIdx(a5_bits[247:240]),
    .io_in_1_ready(i_a5_ready[3]),
    .io_in_1_valid(a5_valid[3]),
    .io_in_1_bits_acquire_address(a5_bits[235:188]),
    .io_in_1_bits_vSetIdx(a5_bits[187:180]),
    .io_in_2_ready(i_a5_ready[2]),
    .io_in_2_valid(a5_valid[2]),
    .io_in_2_bits_acquire_address(a5_bits[175:128]),
    .io_in_2_bits_vSetIdx(a5_bits[127:120]),
    .io_in_3_ready(i_a5_ready[1]),
    .io_in_3_valid(a5_valid[1]),
    .io_in_3_bits_acquire_address(a5_bits[115:68]),
    .io_in_3_bits_vSetIdx(a5_bits[67:60]),
    .io_in_4_ready(i_a5_ready[0]),
    .io_in_4_valid(a5_valid[0]),
    .io_in_4_bits_acquire_source(a5_bits[59:56]),
    .io_in_4_bits_acquire_address(a5_bits[55:8]),
    .io_in_4_bits_vSetIdx(a5_bits[7:0]),
    .io_out_ready(a5_out_ready),
    .io_out_valid(i_a5_out_valid),
    .io_out_bits_acquire_source(i_a5_out_bits[59:56]),
    .io_out_bits_acquire_address(i_a5_out_bits[55:8]),
    .io_out_bits_vSetIdx(i_a5_out_bits[7:0])
  );


  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  // valid 位图：全 0 / 单热 / 稀疏 / 全随机 四种混合
  function automatic int unsigned pick_bits(int unsigned n);
    int unsigned v;
    case ($urandom_range(0, 3))
      0: v = 0;
      1: v = 1 << $urandom_range(0, n - 1);
      2: v = $urandom & $urandom;
      default: v = $urandom;
    endcase
    return v & ((1 << n) - 1);
  endfunction

  task automatic drive_random_inputs();
    a2_valid = 2'(pick_bits(2));
    a2_out_ready = ($urandom_range(0, 1) == 1);
    for (int b = 0; b < 100; b++) a2_bits[b] = 1'($urandom);
    a5_valid = 5'(pick_bits(5));
    a5_out_ready = ($urandom_range(0, 1) == 1);
    for (int b = 0; b < 300; b++) a5_bits[b] = 1'($urandom);
  endtask

  task automatic check_outputs();
    if (!$isunknown({g_a2_ready, g_a2_out_valid, g_a2_out_bits})) begin
      checks++; a2_checks++;
      a2_ones  |= g_a2_out_bits;
      a2_zeros |= ~g_a2_out_bits;
      if (!a2_out_ready) a2_stall++;
      if (a2_valid == '0) a2_none++;
      else for (int k = 2 - 1; k >= 0; k--)
        if (a2_valid[k]) begin a2_win[k]++; break; end
      if ({g_a2_ready, g_a2_out_valid, g_a2_out_bits} !==
          {i_a2_ready, i_a2_out_valid, i_a2_out_bits}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH Arbiter2_ICacheMissReq valid=%0b rdy=%0b/%0b bits=%0h/%0h", $time,
                   a2_valid, g_a2_ready, i_a2_ready, g_a2_out_bits, i_a2_out_bits);
      end
    end
    if (!$isunknown({g_a5_ready, g_a5_out_valid, g_a5_out_bits})) begin
      checks++; a5_checks++;
      a5_ones  |= g_a5_out_bits;
      a5_zeros |= ~g_a5_out_bits;
      if (!a5_out_ready) a5_stall++;
      if (a5_valid == '0) a5_none++;
      else for (int k = 5 - 1; k >= 0; k--)
        if (a5_valid[k]) begin a5_win[k]++; break; end
      if ({g_a5_ready, g_a5_out_valid, g_a5_out_bits} !==
          {i_a5_ready, i_a5_out_valid, i_a5_out_bits}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH Arbiter5_MSHRAcquire valid=%0b rdy=%0b/%0b bits=%0h/%0h", $time,
                   a5_valid, g_a5_ready, i_a5_ready, g_a5_out_bits, i_a5_out_bits);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    a2_valid = '0; a2_bits = '0; a2_out_ready = 0; a2_ones = '0; a2_zeros = '0;
    a2_checks = 0; a2_none = 0; a2_stall = 0;
    for (int k = 0; k < 2; k++) a2_win[k] = 0;
    a5_valid = '0; a5_bits = '0; a5_out_ready = 0; a5_ones = '0; a5_zeros = '0;
    a5_checks = 0; a5_none = 0; a5_stall = 0;
    for (int k = 0; k < 5; k++) a5_win[k] = 0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("Arbiter family checks=%0d errors=%0d", checks, errors);
    $write("  Arbiter2_ICacheMissReq: checks=%0d none=%0d stall=%0d win=",
           a2_checks, a2_none, a2_stall);
    for (int k = 2 - 1; k >= 0; k--) $write("%0d ", a2_win[k]);
    $display("ones=%0d/50 zeros=%0d/50", $countones(a2_ones), $countones(a2_zeros));
    cov_fail += cov_short("Arbiter2_ICacheMissReq checks", a2_checks)
              + cov_short("Arbiter2_ICacheMissReq none",   a2_none)
              + cov_short("Arbiter2_ICacheMissReq stall",  a2_stall);
    for (int k = 0; k < 2; k++)
      cov_fail += cov_short($sformatf("Arbiter2_ICacheMissReq 第 %0d 路胜出", 2-1-k), a2_win[k]);
    if (!(&a2_ones) || !(&a2_zeros)) begin
      $display("COVERAGE FAIL: Arbiter2_ICacheMissReq 有输出位从未观察到 1 或 0"); cov_fail++;
    end
    $write("  Arbiter5_MSHRAcquire: checks=%0d none=%0d stall=%0d win=",
           a5_checks, a5_none, a5_stall);
    for (int k = 5 - 1; k >= 0; k--) $write("%0d ", a5_win[k]);
    $display("ones=%0d/60 zeros=%0d/60", $countones(a5_ones), $countones(a5_zeros));
    cov_fail += cov_short("Arbiter5_MSHRAcquire checks", a5_checks)
              + cov_short("Arbiter5_MSHRAcquire none",   a5_none)
              + cov_short("Arbiter5_MSHRAcquire stall",  a5_stall);
    for (int k = 0; k < 5; k++)
      cov_fail += cov_short($sformatf("Arbiter5_MSHRAcquire 第 %0d 路胜出", 5-1-k), a5_win[k]);
    if (!(&a5_ones) || !(&a5_zeros)) begin
      $display("COVERAGE FAIL: Arbiter5_MSHRAcquire 有输出位从未观察到 1 或 0"); cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule

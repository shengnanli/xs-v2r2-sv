// 自动生成：verif/ut/DeMultiplexer/gen.py（读 G1 golden）—— 勿手改
// DeMultiplexer 家族双例化逐拍比对：golden DeMultiplexer / DeMultiplexer_1 vs 各自的 _xs
//   （同一个 xs_DeMultiplexer_core 设不同 NUM_OUT / 有无 chosen）。
// 被测语义：纯组合；载荷广播给所有出口，valid 按 ready 的 lowest-index-wins 优先级
//   链逐级屏蔽；chosen（只有 _1 有）= 第一个 ready 的出口下标，全不 ready 给末位。
// 激励：out_ready 位图按"全 0 / 单热 / 稀疏 / 全随机"混合，载荷逐位随机，
//   in_valid 一半概率为 0。
// 覆盖闸：每个变体都要 (1) 有效比对 >= COV_MIN；(2) **每个出口**被选中（= 它是第一个
//   ready 的）>= COV_MIN；(3) 一个出口都不 ready >= COV_MIN；(4) in_valid=0 >= COV_MIN；
//   (5) 每个广播载荷位都被观察到过 1 和 0。任何一项不足即 TEST FAILED。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;

  // ---- DeMultiplexer: 4 出口 / 载荷 50 位 / chosen=无 ----
  logic dm0_in_valid;
  logic [49:0] dm0_in_bits;
  logic [3:0] dm0_ready;   // 位 3 = 出口 0
  wire  g_dm0_in_ready, i_dm0_in_ready;
  wire  [3:0] g_dm0_valid, i_dm0_valid;
  wire  [199:0] g_dm0_bits, i_dm0_bits;
  logic [199:0] dm0_ones, dm0_zeros;
  int   dm0_checks, dm0_noready, dm0_idle;
  int   dm0_pick [4];
  DeMultiplexer u_g_dm0 (
    .io_in_valid(dm0_in_valid),
    .io_in_ready(g_dm0_in_ready),
    .io_in_bits_blkPaddr(dm0_in_bits[49:8]),
    .io_in_bits_vSetIdx(dm0_in_bits[7:0]),
    .io_out_0_ready(dm0_ready[3]),
    .io_out_0_valid(g_dm0_valid[3]),
    .io_out_0_bits_blkPaddr(g_dm0_bits[199:158]),
    .io_out_0_bits_vSetIdx(g_dm0_bits[157:150]),
    .io_out_1_ready(dm0_ready[2]),
    .io_out_1_valid(g_dm0_valid[2]),
    .io_out_1_bits_blkPaddr(g_dm0_bits[149:108]),
    .io_out_1_bits_vSetIdx(g_dm0_bits[107:100]),
    .io_out_2_ready(dm0_ready[1]),
    .io_out_2_valid(g_dm0_valid[1]),
    .io_out_2_bits_blkPaddr(g_dm0_bits[99:58]),
    .io_out_2_bits_vSetIdx(g_dm0_bits[57:50]),
    .io_out_3_ready(dm0_ready[0]),
    .io_out_3_valid(g_dm0_valid[0]),
    .io_out_3_bits_blkPaddr(g_dm0_bits[49:8]),
    .io_out_3_bits_vSetIdx(g_dm0_bits[7:0])
  );
  DeMultiplexer_xs u_i_dm0 (
    .io_in_valid(dm0_in_valid),
    .io_in_ready(i_dm0_in_ready),
    .io_in_bits_blkPaddr(dm0_in_bits[49:8]),
    .io_in_bits_vSetIdx(dm0_in_bits[7:0]),
    .io_out_0_ready(dm0_ready[3]),
    .io_out_0_valid(i_dm0_valid[3]),
    .io_out_0_bits_blkPaddr(i_dm0_bits[199:158]),
    .io_out_0_bits_vSetIdx(i_dm0_bits[157:150]),
    .io_out_1_ready(dm0_ready[2]),
    .io_out_1_valid(i_dm0_valid[2]),
    .io_out_1_bits_blkPaddr(i_dm0_bits[149:108]),
    .io_out_1_bits_vSetIdx(i_dm0_bits[107:100]),
    .io_out_2_ready(dm0_ready[1]),
    .io_out_2_valid(i_dm0_valid[1]),
    .io_out_2_bits_blkPaddr(i_dm0_bits[99:58]),
    .io_out_2_bits_vSetIdx(i_dm0_bits[57:50]),
    .io_out_3_ready(dm0_ready[0]),
    .io_out_3_valid(i_dm0_valid[0]),
    .io_out_3_bits_blkPaddr(i_dm0_bits[49:8]),
    .io_out_3_bits_vSetIdx(i_dm0_bits[7:0])
  );

  // ---- DeMultiplexer_1: 10 出口 / 载荷 50 位 / chosen=有 ----
  logic dm1_in_valid;
  logic [49:0] dm1_in_bits;
  logic [9:0] dm1_ready;   // 位 9 = 出口 0
  wire  g_dm1_in_ready, i_dm1_in_ready;
  wire  [9:0] g_dm1_valid, i_dm1_valid;
  wire  [499:0] g_dm1_bits, i_dm1_bits;
  wire  [3:0] g_dm1_chosen, i_dm1_chosen;
  logic [499:0] dm1_ones, dm1_zeros;
  int   dm1_checks, dm1_noready, dm1_idle;
  int   dm1_pick [10];
  DeMultiplexer_1 u_g_dm1 (
    .io_in_valid(dm1_in_valid),
    .io_in_ready(g_dm1_in_ready),
    .io_in_bits_blkPaddr(dm1_in_bits[49:8]),
    .io_in_bits_vSetIdx(dm1_in_bits[7:0]),
    .io_out_0_ready(dm1_ready[9]),
    .io_out_0_valid(g_dm1_valid[9]),
    .io_out_0_bits_blkPaddr(g_dm1_bits[499:458]),
    .io_out_0_bits_vSetIdx(g_dm1_bits[457:450]),
    .io_out_1_ready(dm1_ready[8]),
    .io_out_1_valid(g_dm1_valid[8]),
    .io_out_1_bits_blkPaddr(g_dm1_bits[449:408]),
    .io_out_1_bits_vSetIdx(g_dm1_bits[407:400]),
    .io_out_2_ready(dm1_ready[7]),
    .io_out_2_valid(g_dm1_valid[7]),
    .io_out_2_bits_blkPaddr(g_dm1_bits[399:358]),
    .io_out_2_bits_vSetIdx(g_dm1_bits[357:350]),
    .io_out_3_ready(dm1_ready[6]),
    .io_out_3_valid(g_dm1_valid[6]),
    .io_out_3_bits_blkPaddr(g_dm1_bits[349:308]),
    .io_out_3_bits_vSetIdx(g_dm1_bits[307:300]),
    .io_out_4_ready(dm1_ready[5]),
    .io_out_4_valid(g_dm1_valid[5]),
    .io_out_4_bits_blkPaddr(g_dm1_bits[299:258]),
    .io_out_4_bits_vSetIdx(g_dm1_bits[257:250]),
    .io_out_5_ready(dm1_ready[4]),
    .io_out_5_valid(g_dm1_valid[4]),
    .io_out_5_bits_blkPaddr(g_dm1_bits[249:208]),
    .io_out_5_bits_vSetIdx(g_dm1_bits[207:200]),
    .io_out_6_ready(dm1_ready[3]),
    .io_out_6_valid(g_dm1_valid[3]),
    .io_out_6_bits_blkPaddr(g_dm1_bits[199:158]),
    .io_out_6_bits_vSetIdx(g_dm1_bits[157:150]),
    .io_out_7_ready(dm1_ready[2]),
    .io_out_7_valid(g_dm1_valid[2]),
    .io_out_7_bits_blkPaddr(g_dm1_bits[149:108]),
    .io_out_7_bits_vSetIdx(g_dm1_bits[107:100]),
    .io_out_8_ready(dm1_ready[1]),
    .io_out_8_valid(g_dm1_valid[1]),
    .io_out_8_bits_blkPaddr(g_dm1_bits[99:58]),
    .io_out_8_bits_vSetIdx(g_dm1_bits[57:50]),
    .io_out_9_ready(dm1_ready[0]),
    .io_out_9_valid(g_dm1_valid[0]),
    .io_out_9_bits_blkPaddr(g_dm1_bits[49:8]),
    .io_out_9_bits_vSetIdx(g_dm1_bits[7:0]),
    .io_chosen(g_dm1_chosen)
  );
  DeMultiplexer_1_xs u_i_dm1 (
    .io_in_valid(dm1_in_valid),
    .io_in_ready(i_dm1_in_ready),
    .io_in_bits_blkPaddr(dm1_in_bits[49:8]),
    .io_in_bits_vSetIdx(dm1_in_bits[7:0]),
    .io_out_0_ready(dm1_ready[9]),
    .io_out_0_valid(i_dm1_valid[9]),
    .io_out_0_bits_blkPaddr(i_dm1_bits[499:458]),
    .io_out_0_bits_vSetIdx(i_dm1_bits[457:450]),
    .io_out_1_ready(dm1_ready[8]),
    .io_out_1_valid(i_dm1_valid[8]),
    .io_out_1_bits_blkPaddr(i_dm1_bits[449:408]),
    .io_out_1_bits_vSetIdx(i_dm1_bits[407:400]),
    .io_out_2_ready(dm1_ready[7]),
    .io_out_2_valid(i_dm1_valid[7]),
    .io_out_2_bits_blkPaddr(i_dm1_bits[399:358]),
    .io_out_2_bits_vSetIdx(i_dm1_bits[357:350]),
    .io_out_3_ready(dm1_ready[6]),
    .io_out_3_valid(i_dm1_valid[6]),
    .io_out_3_bits_blkPaddr(i_dm1_bits[349:308]),
    .io_out_3_bits_vSetIdx(i_dm1_bits[307:300]),
    .io_out_4_ready(dm1_ready[5]),
    .io_out_4_valid(i_dm1_valid[5]),
    .io_out_4_bits_blkPaddr(i_dm1_bits[299:258]),
    .io_out_4_bits_vSetIdx(i_dm1_bits[257:250]),
    .io_out_5_ready(dm1_ready[4]),
    .io_out_5_valid(i_dm1_valid[4]),
    .io_out_5_bits_blkPaddr(i_dm1_bits[249:208]),
    .io_out_5_bits_vSetIdx(i_dm1_bits[207:200]),
    .io_out_6_ready(dm1_ready[3]),
    .io_out_6_valid(i_dm1_valid[3]),
    .io_out_6_bits_blkPaddr(i_dm1_bits[199:158]),
    .io_out_6_bits_vSetIdx(i_dm1_bits[157:150]),
    .io_out_7_ready(dm1_ready[2]),
    .io_out_7_valid(i_dm1_valid[2]),
    .io_out_7_bits_blkPaddr(i_dm1_bits[149:108]),
    .io_out_7_bits_vSetIdx(i_dm1_bits[107:100]),
    .io_out_8_ready(dm1_ready[1]),
    .io_out_8_valid(i_dm1_valid[1]),
    .io_out_8_bits_blkPaddr(i_dm1_bits[99:58]),
    .io_out_8_bits_vSetIdx(i_dm1_bits[57:50]),
    .io_out_9_ready(dm1_ready[0]),
    .io_out_9_valid(i_dm1_valid[0]),
    .io_out_9_bits_blkPaddr(i_dm1_bits[49:8]),
    .io_out_9_bits_vSetIdx(i_dm1_bits[7:0]),
    .io_chosen(i_dm1_chosen)
  );


  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  // ready 位图：全 0 / 单热 / 稀疏 / 全随机 四种混合
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
    dm0_in_valid = ($urandom_range(0, 1) == 1);
    dm0_ready = 4'(pick_bits(4));
    for (int b = 0; b < 50; b++) dm0_in_bits[b] = 1'($urandom);
    dm1_in_valid = ($urandom_range(0, 1) == 1);
    dm1_ready = 10'(pick_bits(10));
    for (int b = 0; b < 50; b++) dm1_in_bits[b] = 1'($urandom);
  endtask

  task automatic check_outputs();
    if (!$isunknown({g_dm0_in_ready, g_dm0_valid, g_dm0_bits})) begin
      checks++; dm0_checks++;
      dm0_ones  |= g_dm0_bits;
      dm0_zeros |= ~g_dm0_bits;
      if (!dm0_in_valid) dm0_idle++;
      if (dm0_ready == '0) dm0_noready++;
      else for (int k = 4 - 1; k >= 0; k--)
        if (dm0_ready[k]) begin dm0_pick[k]++; break; end
      if ({g_dm0_in_ready, g_dm0_valid, g_dm0_bits} !== {i_dm0_in_ready, i_dm0_valid, i_dm0_bits}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DeMultiplexer rdy=%0b g=%0h i=%0h", $time,
                   dm0_ready, g_dm0_valid, i_dm0_valid);
      end
    end
    if (!$isunknown({g_dm1_in_ready, g_dm1_valid, g_dm1_bits, g_dm1_chosen})) begin
      checks++; dm1_checks++;
      dm1_ones  |= g_dm1_bits;
      dm1_zeros |= ~g_dm1_bits;
      if (!dm1_in_valid) dm1_idle++;
      if (dm1_ready == '0) dm1_noready++;
      else for (int k = 10 - 1; k >= 0; k--)
        if (dm1_ready[k]) begin dm1_pick[k]++; break; end
      if ({g_dm1_in_ready, g_dm1_valid, g_dm1_bits, g_dm1_chosen} !== {i_dm1_in_ready, i_dm1_valid, i_dm1_bits, i_dm1_chosen}) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DeMultiplexer_1 rdy=%0b g=%0h i=%0h", $time,
                   dm1_ready, g_dm1_valid, i_dm1_valid);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    dm0_in_valid = 0; dm0_in_bits = '0; dm0_ready = '0; dm0_ones = '0; dm0_zeros = '0;
    dm0_checks = 0; dm0_noready = 0; dm0_idle = 0;
    for (int k = 0; k < 4; k++) dm0_pick[k] = 0;
    dm1_in_valid = 0; dm1_in_bits = '0; dm1_ready = '0; dm1_ones = '0; dm1_zeros = '0;
    dm1_checks = 0; dm1_noready = 0; dm1_idle = 0;
    for (int k = 0; k < 10; k++) dm1_pick[k] = 0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
      @(posedge clock);
    end
    $display("DeMultiplexer family checks=%0d errors=%0d", checks, errors);
    $write("  DeMultiplexer: checks=%0d noready=%0d idle=%0d pick=",
           dm0_checks, dm0_noready, dm0_idle);
    for (int k = 4 - 1; k >= 0; k--) $write("%0d ", dm0_pick[k]);
    $display("ones=%0d/200 zeros=%0d/200",
             $countones(dm0_ones), $countones(dm0_zeros));
    cov_fail += cov_short("DeMultiplexer checks",  dm0_checks)
              + cov_short("DeMultiplexer noready", dm0_noready)
              + cov_short("DeMultiplexer idle",    dm0_idle);
    for (int k = 0; k < 4; k++)
      cov_fail += cov_short($sformatf("DeMultiplexer 出口 %0d 被选中", 4-1-k), dm0_pick[k]);
    if (!(&dm0_ones) || !(&dm0_zeros)) begin
      $display("COVERAGE FAIL: DeMultiplexer 有广播载荷位从未观察到 1 或 0"); cov_fail++;
    end
    $write("  DeMultiplexer_1: checks=%0d noready=%0d idle=%0d pick=",
           dm1_checks, dm1_noready, dm1_idle);
    for (int k = 10 - 1; k >= 0; k--) $write("%0d ", dm1_pick[k]);
    $display("ones=%0d/500 zeros=%0d/500",
             $countones(dm1_ones), $countones(dm1_zeros));
    cov_fail += cov_short("DeMultiplexer_1 checks",  dm1_checks)
              + cov_short("DeMultiplexer_1 noready", dm1_noready)
              + cov_short("DeMultiplexer_1 idle",    dm1_idle);
    for (int k = 0; k < 10; k++)
      cov_fail += cov_short($sformatf("DeMultiplexer_1 出口 %0d 被选中", 10-1-k), dm1_pick[k]);
    if (!(&dm1_ones) || !(&dm1_zeros)) begin
      $display("COVERAGE FAIL: DeMultiplexer_1 有广播载荷位从未观察到 1 或 0"); cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule

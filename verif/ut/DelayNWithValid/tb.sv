// 自动生成：verif/ut/DelayNWithValid/gen.py（读 G1 golden）—— 勿手改
// DelayNWithValid 家族 2 变体双例化逐拍比对：golden <V> vs 可读重写 <V>_xs
//   （同一个 xs_DelayNWithValid_core 设不同 WIDTH）。
// 被测语义：valid 打一拍 + 两级"只在使能时更新"的数据寄存器；输入无效时输出保持。
//   只有 valid 寄存器带异步复位，两级数据寄存器无复位（上电 X），故用
//   $isunknown(golden 输出) 跳过尚未灌满的拍。
// 激励：io_in_valid 按 50% 随机（既有连续有效也有长时间无效，才测得到"保持"），
//   载荷逐位随机并混入全 0 / 全 1；reset 偶尔异步脉冲一拍。
// 覆盖闸：每个变体都要 (1) 有效比对 >= COV_MIN；(2) in_valid=1 与 in_valid=0
//   各 >= COV_MIN；(3) 输出**保持不变**（相邻拍相等）与**发生变化**各 >= COV_MIN
//   —— 只测流动不测保持的 tb 会在这里被判 FAIL；(4) 每个载荷位都见过 1 和 0。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  localparam int COV_MIN = 1000;
  bit clock = 0;
  logic reset;
  int errors = 0, checks = 0, cov_fail = 0;
  always #5 clock = ~clock;

  // ---- DelayNWithValid: 载荷 50 位 / 1 字段 ----
  logic dv0_in_valid;
  logic [49:0] dv0_in;
  wire  [49:0] g_dv0_out, i_dv0_out;
  logic [49:0] dv0_ones, dv0_zeros, dv0_prev;
  int   dv0_checks, dv0_vld, dv0_idle, dv0_hold, dv0_move;
  DelayNWithValid u_g_dv0 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv0_in_valid),
    .io_in_bits(dv0_in[49:0]),
    .io_out_bits(g_dv0_out[49:0])
  );
  DelayNWithValid_xs u_i_dv0 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv0_in_valid),
    .io_in_bits(dv0_in[49:0]),
    .io_out_bits(i_dv0_out[49:0])
  );

  // ---- DelayNWithValid_1: 载荷 60 位 / 19 字段 ----
  logic dv1_in_valid;
  logic [59:0] dv1_in;
  wire  [59:0] g_dv1_out, i_dv1_out;
  logic [59:0] dv1_ones, dv1_zeros, dv1_prev;
  int   dv1_checks, dv1_vld, dv1_idle, dv1_hold, dv1_move;
  DelayNWithValid_1 u_g_dv1 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv1_in_valid),
    .io_in_bits_isCall(dv1_in[59]),
    .io_in_bits_isRet(dv1_in[58]),
    .io_in_bits_isJalr(dv1_in[57]),
    .io_in_bits_valid(dv1_in[56]),
    .io_in_bits_brSlots_0_offset(dv1_in[55:52]),
    .io_in_bits_brSlots_0_sharing(dv1_in[51]),
    .io_in_bits_brSlots_0_valid(dv1_in[50]),
    .io_in_bits_brSlots_0_lower(dv1_in[49:38]),
    .io_in_bits_brSlots_0_tarStat(dv1_in[37:36]),
    .io_in_bits_tailSlot_offset(dv1_in[35:32]),
    .io_in_bits_tailSlot_sharing(dv1_in[31]),
    .io_in_bits_tailSlot_valid(dv1_in[30]),
    .io_in_bits_tailSlot_lower(dv1_in[29:10]),
    .io_in_bits_tailSlot_tarStat(dv1_in[9:8]),
    .io_in_bits_pftAddr(dv1_in[7:4]),
    .io_in_bits_carry(dv1_in[3]),
    .io_in_bits_last_may_be_rvi_call(dv1_in[2]),
    .io_in_bits_strong_bias_0(dv1_in[1]),
    .io_in_bits_strong_bias_1(dv1_in[0]),
    .io_out_bits_isCall(g_dv1_out[59]),
    .io_out_bits_isRet(g_dv1_out[58]),
    .io_out_bits_isJalr(g_dv1_out[57]),
    .io_out_bits_valid(g_dv1_out[56]),
    .io_out_bits_brSlots_0_offset(g_dv1_out[55:52]),
    .io_out_bits_brSlots_0_sharing(g_dv1_out[51]),
    .io_out_bits_brSlots_0_valid(g_dv1_out[50]),
    .io_out_bits_brSlots_0_lower(g_dv1_out[49:38]),
    .io_out_bits_brSlots_0_tarStat(g_dv1_out[37:36]),
    .io_out_bits_tailSlot_offset(g_dv1_out[35:32]),
    .io_out_bits_tailSlot_sharing(g_dv1_out[31]),
    .io_out_bits_tailSlot_valid(g_dv1_out[30]),
    .io_out_bits_tailSlot_lower(g_dv1_out[29:10]),
    .io_out_bits_tailSlot_tarStat(g_dv1_out[9:8]),
    .io_out_bits_pftAddr(g_dv1_out[7:4]),
    .io_out_bits_carry(g_dv1_out[3]),
    .io_out_bits_last_may_be_rvi_call(g_dv1_out[2]),
    .io_out_bits_strong_bias_0(g_dv1_out[1]),
    .io_out_bits_strong_bias_1(g_dv1_out[0])
  );
  DelayNWithValid_1_xs u_i_dv1 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(dv1_in_valid),
    .io_in_bits_isCall(dv1_in[59]),
    .io_in_bits_isRet(dv1_in[58]),
    .io_in_bits_isJalr(dv1_in[57]),
    .io_in_bits_valid(dv1_in[56]),
    .io_in_bits_brSlots_0_offset(dv1_in[55:52]),
    .io_in_bits_brSlots_0_sharing(dv1_in[51]),
    .io_in_bits_brSlots_0_valid(dv1_in[50]),
    .io_in_bits_brSlots_0_lower(dv1_in[49:38]),
    .io_in_bits_brSlots_0_tarStat(dv1_in[37:36]),
    .io_in_bits_tailSlot_offset(dv1_in[35:32]),
    .io_in_bits_tailSlot_sharing(dv1_in[31]),
    .io_in_bits_tailSlot_valid(dv1_in[30]),
    .io_in_bits_tailSlot_lower(dv1_in[29:10]),
    .io_in_bits_tailSlot_tarStat(dv1_in[9:8]),
    .io_in_bits_pftAddr(dv1_in[7:4]),
    .io_in_bits_carry(dv1_in[3]),
    .io_in_bits_last_may_be_rvi_call(dv1_in[2]),
    .io_in_bits_strong_bias_0(dv1_in[1]),
    .io_in_bits_strong_bias_1(dv1_in[0]),
    .io_out_bits_isCall(i_dv1_out[59]),
    .io_out_bits_isRet(i_dv1_out[58]),
    .io_out_bits_isJalr(i_dv1_out[57]),
    .io_out_bits_valid(i_dv1_out[56]),
    .io_out_bits_brSlots_0_offset(i_dv1_out[55:52]),
    .io_out_bits_brSlots_0_sharing(i_dv1_out[51]),
    .io_out_bits_brSlots_0_valid(i_dv1_out[50]),
    .io_out_bits_brSlots_0_lower(i_dv1_out[49:38]),
    .io_out_bits_brSlots_0_tarStat(i_dv1_out[37:36]),
    .io_out_bits_tailSlot_offset(i_dv1_out[35:32]),
    .io_out_bits_tailSlot_sharing(i_dv1_out[31]),
    .io_out_bits_tailSlot_valid(i_dv1_out[30]),
    .io_out_bits_tailSlot_lower(i_dv1_out[29:10]),
    .io_out_bits_tailSlot_tarStat(i_dv1_out[9:8]),
    .io_out_bits_pftAddr(i_dv1_out[7:4]),
    .io_out_bits_carry(i_dv1_out[3]),
    .io_out_bits_last_may_be_rvi_call(i_dv1_out[2]),
    .io_out_bits_strong_bias_0(i_dv1_out[1]),
    .io_out_bits_strong_bias_1(i_dv1_out[0])
  );


  function automatic int cov_short(string what, int n);
    if (n < COV_MIN) begin
      $display("COVERAGE FAIL: %s 只发生 %0d 次 (需 >= %0d)", what, n, COV_MIN);
      return 1;
    end
    return 0;
  endfunction

  task automatic drive_random_inputs();
    dv0_in_valid = ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv0_in = '0;
      1:       dv0_in = '1;
      default: for (int b = 0; b < 50; b++) dv0_in[b] = 1'($urandom);
    endcase
    dv1_in_valid = ($urandom_range(0, 1) == 1);
    case ($urandom_range(0, 7))
      0:       dv1_in = '0;
      1:       dv1_in = '1;
      default: for (int b = 0; b < 60; b++) dv1_in[b] = 1'($urandom);
    endcase
  endtask

  task automatic check_outputs();
    if (!$isunknown(g_dv0_out)) begin
      checks++; dv0_checks++;
      dv0_ones  |= g_dv0_out;
      dv0_zeros |= ~g_dv0_out;
      if (dv0_in_valid) dv0_vld++; else dv0_idle++;
      if (!$isunknown(dv0_prev)) begin
        if (dv0_prev === g_dv0_out) dv0_hold++; else dv0_move++;
      end
      dv0_prev = g_dv0_out;
      if (g_dv0_out !== i_dv0_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid g=%0h i=%0h", $time, g_dv0_out, i_dv0_out);
      end
    end
    if (!$isunknown(g_dv1_out)) begin
      checks++; dv1_checks++;
      dv1_ones  |= g_dv1_out;
      dv1_zeros |= ~g_dv1_out;
      if (dv1_in_valid) dv1_vld++; else dv1_idle++;
      if (!$isunknown(dv1_prev)) begin
        if (dv1_prev === g_dv1_out) dv1_hold++; else dv1_move++;
      end
      dv1_prev = g_dv1_out;
      if (g_dv1_out !== i_dv1_out) begin
        errors++;
        if (errors <= 20)
          $display("[%0t] MISMATCH DelayNWithValid_1 g=%0h i=%0h", $time, g_dv1_out, i_dv1_out);
      end
    end
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end
    reset = 1'b1;
    dv0_in_valid = 0; dv0_in = '0; dv0_ones = '0; dv0_zeros = '0; dv0_prev = 'x;
    dv0_checks = 0; dv0_vld = 0; dv0_idle = 0; dv0_hold = 0; dv0_move = 0;
    dv1_in_valid = 0; dv1_in = '0; dv1_ones = '0; dv1_zeros = '0; dv1_prev = 'x;
    dv1_checks = 0; dv1_vld = 0; dv1_idle = 0; dv1_hold = 0; dv1_move = 0;
    repeat (4) @(negedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      check_outputs();        // 输出在 posedge 变，negedge 稳定
      drive_random_inputs();
      @(posedge clock);
      if ($urandom_range(0, 4999) == 0) begin   // 异步复位脉冲
        reset = 1'b1;
        #1 reset = 1'b0;
      end
    end
    $display("DelayNWithValid family checks=%0d errors=%0d", checks, errors);
    $display("  DelayNWithValid: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/50 zeros=%0d/50",
             dv0_checks, dv0_vld, dv0_idle, dv0_hold, dv0_move,
             $countones(dv0_ones), $countones(dv0_zeros));
    cov_fail += cov_short("DelayNWithValid checks", dv0_checks)
              + cov_short("DelayNWithValid valid",  dv0_vld)
              + cov_short("DelayNWithValid idle",   dv0_idle)
              + cov_short("DelayNWithValid hold",   dv0_hold)
              + cov_short("DelayNWithValid move",   dv0_move);
    if (!(&dv0_ones) || !(&dv0_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    $display("  DelayNWithValid_1: checks=%0d valid=%0d idle=%0d hold=%0d move=%0d ones=%0d/60 zeros=%0d/60",
             dv1_checks, dv1_vld, dv1_idle, dv1_hold, dv1_move,
             $countones(dv1_ones), $countones(dv1_zeros));
    cov_fail += cov_short("DelayNWithValid_1 checks", dv1_checks)
              + cov_short("DelayNWithValid_1 valid",  dv1_vld)
              + cov_short("DelayNWithValid_1 idle",   dv1_idle)
              + cov_short("DelayNWithValid_1 hold",   dv1_hold)
              + cov_short("DelayNWithValid_1 move",   dv1_move);
    if (!(&dv1_ones) || !(&dv1_zeros)) begin
      $display("COVERAGE FAIL: DelayNWithValid_1 有载荷位从未在输出上观察到 1 或 0"); cov_fail++;
    end
    if (errors == 0 && cov_fail == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED (errors=%0d cov_fail=%0d)", errors, cov_fail);
    $fatal(1);
  end
endmodule

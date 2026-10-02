`timescale 1ns/1ps
// Differential UT for the two FP-normalize priority-shifter leaves.
// Every vector is checked twice: golden vs rewritten (dual instantiation),
// and rewritten vs an independent in-tb oracle that recomputes the leading-
// zero count by scanning from the MSB down and stopping at the first set
// bit (a different formulation from the RTL's upward override scan).
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  logic [9:0] f32_src, f32_sel;
  wire [9:0] f32_lshift_g, f32_lshift_i;
  wire [7:0] f32_exp_g, f32_exp_i;
  ShiftLeftPriorityWithF32EXPResult g_f32 (
    .io_src(f32_src), .io_priority_shiftValue(f32_sel),
    .io_lshift_result(f32_lshift_g), .io_exp_result(f32_exp_g)
  );
  ShiftLeftPriorityWithF32EXPResult_xs i_f32 (
    .io_src(f32_src), .io_priority_shiftValue(f32_sel),
    .io_lshift_result(f32_lshift_i), .io_exp_result(f32_exp_i)
  );

  logic [52:0] lzd_src, lzd_sel;
  wire [52:0] lzd_lshift_g, lzd_lshift_i;
  wire [5:0] lzd_cnt_g, lzd_cnt_i;
  ShiftLeftPriorityWithLZDResult g_lzd (
    .io_src(lzd_src), .io_priority_shiftValue(lzd_sel),
    .io_lshift_result(lzd_lshift_g), .io_lzd_result(lzd_cnt_g)
  );
  ShiftLeftPriorityWithLZDResult_xs i_lzd (
    .io_src(lzd_src), .io_priority_shiftValue(lzd_sel),
    .io_lshift_result(lzd_lshift_i), .io_lzd_result(lzd_cnt_i)
  );

  function automatic logic [31:0] random32;
    random32 = $urandom;
  endfunction

  // Independent oracle: leading-zero count of the low `width` bits of v,
  // scanning from the top down and keeping the FIRST set bit found.
  // Returns `width` when no bit is set (the golden unconditional fallback).
  function automatic int unsigned oracle_lzd(input logic [52:0] v,
                                             input int unsigned width);
    oracle_lzd = width;
    for (int i = int'(width) - 1; i >= 0; i--) begin
      if (v[i] && (oracle_lzd == width))
        oracle_lzd = width - 1 - int'(i);
    end
  endfunction

  task automatic compare_now;
    int unsigned lzd10, lzd53;
    logic [9:0] exp_lshift10;
    logic [7:0] exp_exp10;
    logic [52:0] exp_lshift53;
    logic [5:0] exp_cnt53;
    begin
      #1;
      vectors++;

      lzd10 = oracle_lzd({43'h0, f32_sel}, 10);
      lzd53 = oracle_lzd(lzd_sel, 53);
      exp_lshift10 = f32_src << lzd10;
      exp_exp10    = 8'(112 - lzd10);
      exp_lshift53 = lzd_src << lzd53;
      exp_cnt53    = 6'(lzd53);

      if ({f32_lshift_g, f32_exp_g, lzd_lshift_g, lzd_cnt_g} !==
          {f32_lshift_i, f32_exp_i, lzd_lshift_i, lzd_cnt_i}) begin
        errors++;
        if (errors < 8)
          $display("golden mismatch at vector %0d: sel10=%b sel53=%b", vectors, f32_sel, lzd_sel);
      end

      if ((f32_lshift_i !== exp_lshift10) || (f32_exp_i !== exp_exp10) ||
          (lzd_lshift_i !== exp_lshift53) || (lzd_cnt_i !== exp_cnt53)) begin
        errors++;
        if (errors < 8)
          $display("oracle mismatch at vector %0d: sel10=%b sel53=%b", vectors, f32_sel, lzd_sel);
      end
    end
  endtask

  task automatic randomize_inputs;
    automatic logic [3:0] mode;
    mode = random32();
    f32_src = random32();
    lzd_src = {random32(), random32()};
    case (mode[1:0])
      2'b00: begin  // one-hot / sparse selects hit individual priority arms
        f32_sel = 10'(10'b1 << (random32() % 10));
        lzd_sel = 53'(53'b1 << (random32() % 53));
      end
      2'b01: begin  // dense multi-hot: priority resolution is exercised
        f32_sel = random32();
        lzd_sel = {random32(), random32()};
      end
      2'b10: begin  // low bits only: near-fallback behavior
        f32_sel = random32() & 10'h00f;
        lzd_sel = {random32(), random32()} & 53'h1f;
      end
      default: begin  // high bits only: small shift amounts
        f32_sel = random32() & 10'h3f0;
        lzd_sel = {random32(), random32()} & 53'hffffffffffffe0;
      end
    endcase
  endtask

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end

    // Corner: all-zero select vectors (golden unconditional fallback arm).
    f32_src = '0; f32_sel = '0; lzd_src = '0; lzd_sel = '0;
    compare_now();
    f32_src = '1; lzd_src = '1;
    compare_now();

    // Corner: all-ones selects (highest priority bit must win).
    f32_sel = '1; lzd_sel = '1;
    compare_now();
    f32_src = '0; lzd_src = '0;
    compare_now();

    // Directed: single set bit at every priority position, both src corners.
    for (int pos = 0; pos < 53; pos++) begin
      f32_src = '1; lzd_src = '1;
      f32_sel = '0; lzd_sel = '0;
      lzd_sel[pos] = 1'b1;
      if (pos < 10) f32_sel[pos] = 1'b1;
      compare_now();
      f32_src = '0; lzd_src = '0;
      compare_now();
      // walking one-hot data under the same select
      f32_src = 10'(10'b1 << (pos % 10));
      lzd_src = 53'(53'b1 << pos);
      compare_now();
    end

    // Directed: multi-hot combinations (adjacent pairs, alternating bits,
    // both end bits) — the highest set bit must override the rest.
    f32_src = '1; lzd_src = '1;
    for (int pos = 0; pos < 52; pos++) begin
      f32_sel = '0; lzd_sel = '0;
      lzd_sel[pos] = 1'b1; lzd_sel[pos + 1] = 1'b1;
      if (pos + 1 < 10) begin f32_sel[pos] = 1'b1; f32_sel[pos + 1] = 1'b1; end
      compare_now();
    end
    f32_sel = 10'b1010101010; lzd_sel = {21'b0, 32'hAAAAAAAA};
    compare_now();
    f32_sel = 10'b0101010101; lzd_sel = {21'b0, 32'h55555555};
    compare_now();
    f32_sel = 10'b1000000001; lzd_sel = {1'b1, 51'b0, 1'b1};
    compare_now();

    repeat (NCYCLES) begin
      randomize_inputs();
      compare_now();
    end

    $display("ShiftPriorityLeaves2 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 2, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule

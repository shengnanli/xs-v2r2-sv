`timescale 1ns/1ps
// Differential UT for the three FP-normalize priority-shifter leaves
// (ShiftLeftPriorityWithLZDResult_6 / _8, ShiftLeftPriorityWithF64EXPResult).
// Every vector is checked twice: golden vs rewritten (dual instantiation),
// and rewritten vs an independent in-tb oracle that finds the leading set
// bit by scanning from the MSB down and stopping at the first hit (a
// different formulation from the RTL's upward override scan).
// Coverage: per-leaf histogram of the oracle shift amount 0..WIDTH (the
// fallback arm included); the run fails if any bucket stays empty.
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  // ---- leaf A: LZD_6, 24 bit ----
  logic [23:0] a_src, a_sel;
  wire  [23:0] a_sh_g, a_sh_i;
  wire  [4:0]  a_cnt_g, a_cnt_i;
  ShiftLeftPriorityWithLZDResult_6 g_a (
    .io_src(a_src), .io_priority_shiftValue(a_sel),
    .io_lshift_result(a_sh_g), .io_lzd_result(a_cnt_g)
  );
  ShiftLeftPriorityWithLZDResult_6_xs i_a (
    .io_src(a_src), .io_priority_shiftValue(a_sel),
    .io_lshift_result(a_sh_i), .io_lzd_result(a_cnt_i)
  );

  // ---- leaf B: LZD_8, 11 bit ----
  logic [10:0] b_src, b_sel;
  wire  [10:0] b_sh_g, b_sh_i;
  wire  [3:0]  b_cnt_g, b_cnt_i;
  ShiftLeftPriorityWithLZDResult_8 g_b (
    .io_src(b_src), .io_priority_shiftValue(b_sel),
    .io_lshift_result(b_sh_g), .io_lzd_result(b_cnt_g)
  );
  ShiftLeftPriorityWithLZDResult_8_xs i_b (
    .io_src(b_src), .io_priority_shiftValue(b_sel),
    .io_lshift_result(b_sh_i), .io_lzd_result(b_cnt_i)
  );

  // ---- leaf C: F64EXP, 23 bit, exp = 0x380 - shift ----
  logic [22:0] c_src, c_sel;
  wire  [22:0] c_sh_g, c_sh_i;
  wire  [10:0] c_exp_g, c_exp_i;
  ShiftLeftPriorityWithF64EXPResult g_c (
    .io_src(c_src), .io_priority_shiftValue(c_sel),
    .io_lshift_result(c_sh_g), .io_exp_result(c_exp_g)
  );
  ShiftLeftPriorityWithF64EXPResult_xs i_c (
    .io_src(c_src), .io_priority_shiftValue(c_sel),
    .io_lshift_result(c_sh_i), .io_exp_result(c_exp_i)
  );

  int unsigned hist_a[0:24];
  int unsigned hist_b[0:11];
  int unsigned hist_c[0:23];

  // Independent oracle: leading-zero count of the low `width` bits of v,
  // scanning from the top down and keeping the FIRST set bit found.
  function automatic int unsigned oracle_lzd(input logic [23:0] v,
                                             input int unsigned width);
    oracle_lzd = width;
    for (int i = int'(width) - 1; i >= 0; i--)
      if (v[i] && (oracle_lzd == width))
        oracle_lzd = width - 1 - int'(i);
  endfunction

  task automatic compare_now;
    int unsigned na, nb, nc;
    begin
      #1;
      vectors++;
      na = oracle_lzd(a_sel, 24);
      nb = oracle_lzd({13'h0, b_sel}, 11);
      nc = oracle_lzd({1'b0, c_sel}, 23);
      hist_a[na]++;
      hist_b[nb]++;
      hist_c[nc]++;

      if ({a_sh_g, a_cnt_g, b_sh_g, b_cnt_g, c_sh_g, c_exp_g} !==
          {a_sh_i, a_cnt_i, b_sh_i, b_cnt_i, c_sh_i, c_exp_i}) begin
        errors++;
        if (errors < 8)
          $display("golden mismatch @%0d: selA=%h selB=%h selC=%h", vectors, a_sel, b_sel, c_sel);
      end
      if ((a_sh_i !== 24'(a_src << na)) || (a_cnt_i !== 5'(na)) ||
          (b_sh_i !== 11'(b_src << nb)) || (b_cnt_i !== 4'(nb)) ||
          (c_sh_i !== 23'(c_src << nc)) || (c_exp_i !== 11'('h380 - nc))) begin
        errors++;
        if (errors < 8)
          $display("oracle mismatch @%0d: selA=%h selB=%h selC=%h", vectors, a_sel, b_sel, c_sel);
      end
    end
  endtask

  task automatic randomize_inputs;
    logic [1:0] mode;
    mode  = 2'($urandom);
    a_src = 24'($urandom);
    b_src = 11'($urandom);
    c_src = 23'($urandom);
    case (mode)
      2'd0: begin  // one-hot: each priority arm individually
        a_sel = 24'(24'b1 << ($urandom % 24));
        b_sel = 11'(11'b1 << ($urandom % 11));
        c_sel = 23'(23'b1 << ($urandom % 23));
      end
      2'd1: begin  // dense multi-hot: priority resolution
        a_sel = 24'($urandom);
        b_sel = 11'($urandom);
        c_sel = 23'($urandom);
      end
      2'd2: begin  // random-length low mask: deep shifts and the fallback arm
        a_sel = 24'($urandom) & ((24'b1 << ($urandom % 25)) - 24'b1);
        b_sel = 11'($urandom) & ((11'b1 << ($urandom % 12)) - 11'b1);
        c_sel = 23'($urandom) & ((23'b1 << ($urandom % 24)) - 23'b1);
      end
      default: begin  // all-zero select (fallback) mixed with all-ones
        a_sel = $urandom_range(1) ? '0 : '1;
        b_sel = $urandom_range(1) ? '0 : '1;
        c_sel = $urandom_range(1) ? '0 : '1;
      end
    endcase
  endtask

  initial begin
    int unsigned min_a, min_b, min_c;
    if ($value$plusargs("ncycles=%d", NCYCLES)) begin end

    // Directed: every single-bit select at every position, src all-ones / zero.
    for (int pos = 0; pos < 24; pos++) begin
      a_sel = 24'(24'b1 << pos);
      b_sel = 11'(11'b1 << (pos % 11));
      c_sel = 23'(23'b1 << (pos % 23));
      a_src = '1; b_src = '1; c_src = '1;
      compare_now();
      a_src = '0; b_src = '0; c_src = '0;
      compare_now();
    end

    repeat (NCYCLES) begin
      randomize_inputs();
      compare_now();
    end

    min_a = hist_a[0]; foreach (hist_a[k]) if (hist_a[k] < min_a) min_a = hist_a[k];
    min_b = hist_b[0]; foreach (hist_b[k]) if (hist_b[k] < min_b) min_b = hist_b[k];
    min_c = hist_c[0]; foreach (hist_c[k]) if (hist_c[k] < min_c) min_c = hist_c[k];
    $display("COVERAGE shift-amount buckets: LZD_6 25 buckets min=%0d fallback=%0d | LZD_8 12 buckets min=%0d fallback=%0d | F64EXP 24 buckets min=%0d fallback=%0d",
             min_a, hist_a[24], min_b, hist_b[11], min_c, hist_c[23]);
    if (min_a == 0 || min_b == 0 || min_c == 0) begin
      errors++;
      $display("coverage hole: some shift-amount bucket never hit");
    end
    $display("ShiftPriorityLeaves3 UT: vectors=%0d module_checks=%0d errors=%0d",
             vectors, vectors * 3, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0;
  int vectors = 0;

  logic max_mode;
  logic signed_mode;

  logic [31:0] a2_32, b2_32;
  logic [7:0]  a2_8, b2_8;
  logic [63:0] a3_64, b3_64, c3_64;
  logic [31:0] a3_32, b3_32, c3_32;
  logic [15:0] a3_16, b3_16, c3_16;
  logic [7:0]  a3_8, b3_8, c3_8;

  wire [31:0] y2_32_g, y2_32_i;
  wire [7:0]  y2_8_g, y2_8_i;
  wire [63:0] y3_64_g, y3_64_i;
  wire [31:0] y3_32_g, y3_32_i;
  wire [15:0] y3_16_g, y3_16_i;
  wire [7:0]  y3_8_g, y3_8_i;

  compare_2to1 g2_32 (
    .io_a(a2_32), .io_b(b2_32), .io_max(max_mode),
    .io_signed(signed_mode), .io_c(y2_32_g)
  );
  compare_2to1_xs i2_32 (
    .io_a(a2_32), .io_b(b2_32), .io_max(max_mode),
    .io_signed(signed_mode), .io_c(y2_32_i)
  );
  compare_2to1_2 g2_8 (
    .io_a(a2_8), .io_b(b2_8), .io_max(max_mode),
    .io_signed(signed_mode), .io_c(y2_8_g)
  );
  compare_2to1_2_xs i2_8 (
    .io_a(a2_8), .io_b(b2_8), .io_max(max_mode),
    .io_signed(signed_mode), .io_c(y2_8_i)
  );

  compare_3to1 g3_64 (
    .io_a(a3_64), .io_b(b3_64), .io_c(c3_64),
    .io_max(max_mode), .io_signed(signed_mode), .io_d(y3_64_g)
  );
  compare_3to1_xs i3_64 (
    .io_a(a3_64), .io_b(b3_64), .io_c(c3_64),
    .io_max(max_mode), .io_signed(signed_mode), .io_d(y3_64_i)
  );
  compare_3to1_1 g3_32 (
    .io_a(a3_32), .io_b(b3_32), .io_c(c3_32),
    .io_max(max_mode), .io_signed(signed_mode), .io_d(y3_32_g)
  );
  compare_3to1_1_xs i3_32 (
    .io_a(a3_32), .io_b(b3_32), .io_c(c3_32),
    .io_max(max_mode), .io_signed(signed_mode), .io_d(y3_32_i)
  );
  compare_3to1_2 g3_16 (
    .io_a(a3_16), .io_b(b3_16), .io_c(c3_16),
    .io_max(max_mode), .io_signed(signed_mode), .io_d(y3_16_g)
  );
  compare_3to1_2_xs i3_16 (
    .io_a(a3_16), .io_b(b3_16), .io_c(c3_16),
    .io_max(max_mode), .io_signed(signed_mode), .io_d(y3_16_i)
  );
  compare_3to1_6 g3_8 (
    .io_a(a3_8), .io_b(b3_8), .io_c(c3_8),
    .io_max(max_mode), .io_signed(signed_mode), .io_d(y3_8_g)
  );
  compare_3to1_6_xs i3_8 (
    .io_a(a3_8), .io_b(b3_8), .io_c(c3_8),
    .io_max(max_mode), .io_signed(signed_mode), .io_d(y3_8_i)
  );

  function automatic [31:0] oracle2_32(
    input logic [31:0] a, b,
    input logic choose_max,
    input logic use_signed
  );
    logic a_lt_b;
    begin
      a_lt_b = use_signed ? ($signed(a) < $signed(b)) : (a < b);
      oracle2_32 = choose_max ? (a_lt_b ? b : a) : (a_lt_b ? a : b);
    end
  endfunction

  function automatic [7:0] oracle2_8(
    input logic [7:0] a, b,
    input logic choose_max,
    input logic use_signed
  );
    logic a_lt_b;
    begin
      a_lt_b = use_signed ? ($signed(a) < $signed(b)) : (a < b);
      oracle2_8 = choose_max ? (a_lt_b ? b : a) : (a_lt_b ? a : b);
    end
  endfunction

  function automatic [63:0] oracle3_64(
    input logic [63:0] a, b, c,
    input logic choose_max,
    input logic use_signed
  );
    logic a_lt_b, a_lt_c, b_lt_c;
    begin
      a_lt_b = use_signed ? ($signed(a) < $signed(b)) : (a < b);
      a_lt_c = use_signed ? ($signed(a) < $signed(c)) : (a < c);
      b_lt_c = use_signed ? ($signed(b) < $signed(c)) : (b < c);
      if (choose_max)
        oracle3_64 = (!a_lt_b && !a_lt_c) ? a : (!b_lt_c ? b : c);
      else
        oracle3_64 = (a_lt_b && a_lt_c) ? a : (b_lt_c ? b : c);
    end
  endfunction

  function automatic [31:0] oracle3_32(
    input logic [31:0] a, b, c,
    input logic choose_max,
    input logic use_signed
  );
    logic a_lt_b, a_lt_c, b_lt_c;
    begin
      a_lt_b = use_signed ? ($signed(a) < $signed(b)) : (a < b);
      a_lt_c = use_signed ? ($signed(a) < $signed(c)) : (a < c);
      b_lt_c = use_signed ? ($signed(b) < $signed(c)) : (b < c);
      if (choose_max)
        oracle3_32 = (!a_lt_b && !a_lt_c) ? a : (!b_lt_c ? b : c);
      else
        oracle3_32 = (a_lt_b && a_lt_c) ? a : (b_lt_c ? b : c);
    end
  endfunction

  function automatic [15:0] oracle3_16(
    input logic [15:0] a, b, c,
    input logic choose_max,
    input logic use_signed
  );
    logic a_lt_b, a_lt_c, b_lt_c;
    begin
      a_lt_b = use_signed ? ($signed(a) < $signed(b)) : (a < b);
      a_lt_c = use_signed ? ($signed(a) < $signed(c)) : (a < c);
      b_lt_c = use_signed ? ($signed(b) < $signed(c)) : (b < c);
      if (choose_max)
        oracle3_16 = (!a_lt_b && !a_lt_c) ? a : (!b_lt_c ? b : c);
      else
        oracle3_16 = (a_lt_b && a_lt_c) ? a : (b_lt_c ? b : c);
    end
  endfunction

  function automatic [7:0] oracle3_8(
    input logic [7:0] a, b, c,
    input logic choose_max,
    input logic use_signed
  );
    logic a_lt_b, a_lt_c, b_lt_c;
    begin
      a_lt_b = use_signed ? ($signed(a) < $signed(b)) : (a < b);
      a_lt_c = use_signed ? ($signed(a) < $signed(c)) : (a < c);
      b_lt_c = use_signed ? ($signed(b) < $signed(c)) : (b < c);
      if (choose_max)
        oracle3_8 = (!a_lt_b && !a_lt_c) ? a : (!b_lt_c ? b : c);
      else
        oracle3_8 = (a_lt_b && a_lt_c) ? a : (b_lt_c ? b : c);
    end
  endfunction

  task automatic check_one(
    input logic pass,
    input string tag
  );
    if (!pass) begin
      errors++;
      if (errors < 12)
        $display("mismatch vector=%0d tag=%s signed=%0b max=%0b", vectors, tag,
                 signed_mode, max_mode);
    end
  endtask

  task automatic compare_now;
    logic [31:0] e2_32;
    logic [7:0]  e2_8;
    logic [63:0] e3_64;
    logic [31:0] e3_32;
    logic [15:0] e3_16;
    logic [7:0]  e3_8;
    begin
      #1;
      vectors++;
      e2_32 = oracle2_32(a2_32, b2_32, max_mode, signed_mode);
      e2_8 = oracle2_8(a2_8, b2_8, max_mode, signed_mode);
      e3_64 = oracle3_64(a3_64, b3_64, c3_64, max_mode, signed_mode);
      e3_32 = oracle3_32(a3_32, b3_32, c3_32, max_mode, signed_mode);
      e3_16 = oracle3_16(a3_16, b3_16, c3_16, max_mode, signed_mode);
      e3_8 = oracle3_8(a3_8, b3_8, c3_8, max_mode, signed_mode);
      check_one(y2_32_g === e2_32, "golden compare_2to1 vs oracle");
      check_one(y2_32_i === e2_32, "impl compare_2to1 vs oracle");
      check_one(y2_8_g === e2_8, "golden compare_2to1_2 vs oracle");
      check_one(y2_8_i === e2_8, "impl compare_2to1_2 vs oracle");
      check_one(y3_64_g === e3_64, "golden compare_3to1 vs oracle");
      check_one(y3_64_i === e3_64, "impl compare_3to1 vs oracle");
      check_one(y3_32_g === e3_32, "golden compare_3to1_1 vs oracle");
      check_one(y3_32_i === e3_32, "impl compare_3to1_1 vs oracle");
      check_one(y3_16_g === e3_16, "golden compare_3to1_2 vs oracle");
      check_one(y3_16_i === e3_16, "impl compare_3to1_2 vs oracle");
      check_one(y3_8_g === e3_8, "golden compare_3to1_6 vs oracle");
      check_one(y3_8_i === e3_8, "impl compare_3to1_6 vs oracle");
    end
  endtask

  task automatic set_values(
    input logic [63:0] a,
    input logic [63:0] b,
    input logic [63:0] c
  );
    begin
      a2_32 = a[31:0]; b2_32 = b[31:0];
      a2_8 = a[7:0]; b2_8 = b[7:0];
      a3_64 = a; b3_64 = b; c3_64 = c;
      a3_32 = a[31:0]; b3_32 = b[31:0]; c3_32 = c[31:0];
      a3_16 = a[15:0]; b3_16 = b[15:0]; c3_16 = c[15:0];
      a3_8 = a[7:0]; b3_8 = b[7:0]; c3_8 = c[7:0];
    end
  endtask

  task automatic randomize_inputs;
    begin
      a2_32 = $urandom; b2_32 = $urandom;
      a2_8 = $urandom; b2_8 = $urandom;
      a3_64 = {$urandom, $urandom};
      b3_64 = {$urandom, $urandom};
      c3_64 = {$urandom, $urandom};
      a3_32 = $urandom; b3_32 = $urandom; c3_32 = $urandom;
      a3_16 = $urandom; b3_16 = $urandom; c3_16 = $urandom;
      a3_8 = $urandom; b3_8 = $urandom; c3_8 = $urandom;
      max_mode = $urandom;
      signed_mode = $urandom;
    end
  endtask

  initial begin
    // Equal operands pin the intentionally different max/min tie priorities.
    signed_mode = 0; max_mode = 0; set_values(64'h0, 64'h0, 64'h0); compare_now();
    signed_mode = 0; max_mode = 1; set_values(64'hFFFF_FFFF_FFFF_FFFF,
      64'hFFFF_FFFF_FFFF_FFFF, 64'hFFFF_FFFF_FFFF_FFFF); compare_now();
    // Unsigned extrema and each two-way tie among the three operands.
    signed_mode = 0; max_mode = 0; set_values(64'h0, 64'h0, 64'h1); compare_now();
    signed_mode = 0; max_mode = 1; set_values(64'hFFFF_FFFF_FFFF_FFFF,
      64'hFFFF_FFFF_FFFF_FFFF, 64'h0); compare_now();
    signed_mode = 0; max_mode = 0; set_values(64'h2, 64'h1, 64'h1); compare_now();
    signed_mode = 0; max_mode = 1; set_values(64'h0, 64'h1, 64'h1); compare_now();
    // Signed minimum, minus one, zero, and maximum cross the sign boundary.
    signed_mode = 1; max_mode = 0; set_values(64'h8000_0000_0000_0000,
      64'hFFFF_FFFF_FFFF_FFFF, 64'h7FFF_FFFF_FFFF_FFFF); compare_now();
    signed_mode = 1; max_mode = 1; set_values(64'h8000_0000_0000_0000,
      64'h0, 64'h7FFF_FFFF_FFFF_FFFF); compare_now();

    repeat (NCYCLES) begin
      randomize_inputs();
      compare_now();
    end

    $display("CompareLeaves6 UT: vectors=%0d oracle_checks=%0d errors=%0d",
             vectors, vectors * 12, errors);
    if (errors == 0)
      $display("TEST PASSED");
    else
      $display("TEST FAILED");
    $finish;
  end
endmodule

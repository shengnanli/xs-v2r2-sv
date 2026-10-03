// AMOALU 双例化逐拍比对：golden AMOALU vs 可读 AMOALU_xs。
// 随机覆盖全部 32 个 cmd（包括非法编码的默认语义）、全部 byte mask，
// 并穿插 32/64 位有符号边界、无符号边界和加法进位截断的定向向量。
`timescale 1ns/1ps

module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  int errors = 0;
  int checks = 0;

  logic [7:0]  io_mask;
  logic [4:0]  io_cmd;
  logic [63:0] io_lhs;
  logic [63:0] io_rhs;
  wire  [63:0] golden_out;
  wire  [63:0] impl_out;

  always #5 clock = ~clock;

  AMOALU u_golden (
    .io_mask (io_mask),
    .io_cmd  (io_cmd),
    .io_lhs  (io_lhs),
    .io_rhs  (io_rhs),
    .io_out  (golden_out)
  );

  AMOALU_xs u_impl (
    .io_mask (io_mask),
    .io_cmd  (io_cmd),
    .io_lhs  (io_lhs),
    .io_rhs  (io_rhs),
    .io_out  (impl_out)
  );

  task automatic check_now(input string label);
    #1;
    checks++;
    if (golden_out !== impl_out) begin
      errors++;
      if (errors <= 20)
        $display("[%0t] %s mismatch mask=%02h cmd=%02h lhs=%016h rhs=%016h golden=%016h impl=%016h",
                 $time, label, io_mask, io_cmd, io_lhs, io_rhs, golden_out, impl_out);
    end
  endtask

  task automatic directed(
      input logic [7:0] mask,
      input logic [4:0] cmd,
      input logic [63:0] lhs,
      input logic [63:0] rhs,
      input string label);
    @(negedge clock);
    io_mask = mask;
    io_cmd  = cmd;
    io_lhs  = lhs;
    io_rhs  = rhs;
    check_now(label);
  endtask

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 200000;
    io_mask = '0;
    io_cmd  = '0;
    io_lhs  = '0;
    io_rhs  = '0;

    // 加法：32 位进位不得污染高半字；64 位进位必须保留。
    directed(8'h0f, 5'h08, 64'h1234_5678_ffff_ffff, 64'hffff_ffff_0000_0001, "add32");
    directed(8'hff, 5'h08, 64'h0000_0000_ffff_ffff, 64'h0000_0000_0000_0001, "add64");

    // MIN/MAX：符号不同、低 32 位符号不同、相等值和无符号边界。
    directed(8'hff, 5'h0c, 64'h8000_0000_0000_0000, 64'h7fff_ffff_ffff_ffff, "min64_signed");
    directed(8'h0f, 5'h0d, 64'h0000_0000_8000_0000, 64'hffff_ffff_7fff_ffff, "max32_signed");
    directed(8'hff, 5'h0e, 64'hffff_ffff_ffff_ffff, 64'h0000_0000_0000_0001, "min64_unsigned");
    directed(8'h0f, 5'h0f, 64'haaaa_aaaa_0000_0001, 64'h5555_5555_ffff_ffff, "max32_unsigned");
    directed(8'h55, 5'h0c, 64'h0123_4567_89ab_cdef, 64'h0123_4567_89ab_cdef, "equal_partial_mask");

    // 逻辑与 byte write mask。
    directed(8'haa, 5'h09, 64'h0123_4567_89ab_cdef, 64'hffff_0000_ffff_0000, "xor_masked");
    directed(8'h33, 5'h0a, 64'h0123_4567_89ab_cdef, 64'hffff_0000_ffff_0000, "or_masked");
    directed(8'hcc, 5'h0b, 64'h0123_4567_89ab_cdef, 64'hffff_0000_ffff_0000, "and_masked");

    repeat (NCYCLES) begin
      @(negedge clock);
      io_mask = $urandom;
      io_cmd  = $urandom;
      io_lhs  = {$urandom, $urandom};
      io_rhs  = {$urandom, $urandom};
      check_now("random");
    end

    $display("AMOALU UT: checks=%0d errors=%0d", checks, errors);
    if (errors == 0) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule

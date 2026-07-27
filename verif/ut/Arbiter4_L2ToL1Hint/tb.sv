// Arbiter4_L2ToL1Hint 双例化逐拍比对: golden Arbiter4_L2ToL1Hint vs 可读 Arbiter4_L2ToL1Hint_xs (随机激励).
`timescale 1ns/1ps
`define CHECK(SIG) begin \
  if (!$isunknown(g_``SIG)) begin \
    checks++; \
    if (g_``SIG !== i_``SIG) begin \
      errors++; \
      if (errors <= 30) $display("[%0t] MISMATCH %s g=%0h i=%0h", $time, `"SIG`", g_``SIG, i_``SIG); \
    end \
  end \
end
module tb;
  int unsigned NCYCLES = 200000;
  bit clock = 0;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;
  logic io_in_0_valid;
  logic [31:0] io_in_0_bits_sourceId;
  logic io_in_0_bits_isKeyword;
  logic io_in_1_valid;
  logic [31:0] io_in_1_bits_sourceId;
  logic io_in_1_bits_isKeyword;
  logic io_in_2_valid;
  logic [31:0] io_in_2_bits_sourceId;
  logic io_in_2_bits_isKeyword;
  logic io_in_3_valid;
  logic [31:0] io_in_3_bits_sourceId;
  logic io_in_3_bits_isKeyword;
  logic io_out_ready;
  wire g_io_in_0_ready;
  wire i_io_in_0_ready;
  wire g_io_in_1_ready;
  wire i_io_in_1_ready;
  wire g_io_in_2_ready;
  wire i_io_in_2_ready;
  wire g_io_in_3_ready;
  wire i_io_in_3_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [31:0] g_io_out_bits_sourceId;
  wire [31:0] i_io_out_bits_sourceId;
  wire g_io_out_bits_isKeyword;
  wire i_io_out_bits_isKeyword;
  wire [1:0] g_io_chosen;
  wire [1:0] i_io_chosen;
  Arbiter4_L2ToL1Hint u_g (
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_sourceId(io_in_0_bits_sourceId),
    .io_in_0_bits_isKeyword(io_in_0_bits_isKeyword),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_sourceId(io_in_1_bits_sourceId),
    .io_in_1_bits_isKeyword(io_in_1_bits_isKeyword),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_sourceId(io_in_2_bits_sourceId),
    .io_in_2_bits_isKeyword(io_in_2_bits_isKeyword),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_sourceId(io_in_3_bits_sourceId),
    .io_in_3_bits_isKeyword(io_in_3_bits_isKeyword),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_sourceId(g_io_out_bits_sourceId),
    .io_out_bits_isKeyword(g_io_out_bits_isKeyword),
    .io_chosen(g_io_chosen)
  );
  Arbiter4_L2ToL1Hint_xs u_i (
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_sourceId(io_in_0_bits_sourceId),
    .io_in_0_bits_isKeyword(io_in_0_bits_isKeyword),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_sourceId(io_in_1_bits_sourceId),
    .io_in_1_bits_isKeyword(io_in_1_bits_isKeyword),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_sourceId(io_in_2_bits_sourceId),
    .io_in_2_bits_isKeyword(io_in_2_bits_isKeyword),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_sourceId(io_in_3_bits_sourceId),
    .io_in_3_bits_isKeyword(io_in_3_bits_isKeyword),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_sourceId(i_io_out_bits_sourceId),
    .io_out_bits_isKeyword(i_io_out_bits_isKeyword),
    .io_chosen(i_io_chosen)
  );
  task automatic drive_random_inputs();
    io_in_0_valid = $urandom_range(0, 1);
    io_in_0_bits_sourceId = 32'($urandom);
    io_in_0_bits_isKeyword = $urandom_range(0, 1);
    io_in_1_valid = $urandom_range(0, 1);
    io_in_1_bits_sourceId = 32'($urandom);
    io_in_1_bits_isKeyword = $urandom_range(0, 1);
    io_in_2_valid = $urandom_range(0, 1);
    io_in_2_bits_sourceId = 32'($urandom);
    io_in_2_bits_isKeyword = $urandom_range(0, 1);
    io_in_3_valid = $urandom_range(0, 1);
    io_in_3_bits_sourceId = 32'($urandom);
    io_in_3_bits_isKeyword = $urandom_range(0, 1);
    io_out_ready = $urandom_range(0, 1);
  endtask
  task automatic check_outputs();
    `CHECK(io_in_0_ready)
    `CHECK(io_in_1_ready)
    `CHECK(io_in_2_ready)
    `CHECK(io_in_3_ready)
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_sourceId)
    `CHECK(io_out_bits_isKeyword)
    `CHECK(io_chosen)
  endtask
  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    io_in_0_valid = '0;
    io_in_0_bits_sourceId = '0;
    io_in_0_bits_isKeyword = '0;
    io_in_1_valid = '0;
    io_in_1_bits_sourceId = '0;
    io_in_1_bits_isKeyword = '0;
    io_in_2_valid = '0;
    io_in_2_bits_sourceId = '0;
    io_in_2_bits_isKeyword = '0;
    io_in_3_valid = '0;
    io_in_3_bits_sourceId = '0;
    io_in_3_bits_isKeyword = '0;
    io_out_ready = '0;
    repeat (2) @(posedge clock);
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
    end
    $display("Arbiter4_L2ToL1Hint checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED"); $finish;
    end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHECK

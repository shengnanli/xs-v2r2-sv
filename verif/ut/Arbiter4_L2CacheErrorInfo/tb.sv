// Arbiter4_L2CacheErrorInfo 双例化逐拍比对: golden Arbiter4_L2CacheErrorInfo vs 可读 Arbiter4_L2CacheErrorInfo_xs (随机激励).
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
  logic io_in_0_bits_valid;
  logic [45:0] io_in_0_bits_address;
  logic io_in_1_valid;
  logic io_in_1_bits_valid;
  logic [45:0] io_in_1_bits_address;
  logic io_in_2_valid;
  logic io_in_2_bits_valid;
  logic [45:0] io_in_2_bits_address;
  logic io_in_3_valid;
  logic io_in_3_bits_valid;
  logic [45:0] io_in_3_bits_address;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire g_io_out_bits_valid;
  wire i_io_out_bits_valid;
  wire [45:0] g_io_out_bits_address;
  wire [45:0] i_io_out_bits_address;
  Arbiter4_L2CacheErrorInfo u_g (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_valid(io_in_0_bits_valid),
    .io_in_0_bits_address(io_in_0_bits_address),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_valid(io_in_1_bits_valid),
    .io_in_1_bits_address(io_in_1_bits_address),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_valid(io_in_2_bits_valid),
    .io_in_2_bits_address(io_in_2_bits_address),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_valid(io_in_3_bits_valid),
    .io_in_3_bits_address(io_in_3_bits_address),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_valid(g_io_out_bits_valid),
    .io_out_bits_address(g_io_out_bits_address)
  );
  Arbiter4_L2CacheErrorInfo_xs u_i (
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_valid(io_in_0_bits_valid),
    .io_in_0_bits_address(io_in_0_bits_address),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_valid(io_in_1_bits_valid),
    .io_in_1_bits_address(io_in_1_bits_address),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_valid(io_in_2_bits_valid),
    .io_in_2_bits_address(io_in_2_bits_address),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_valid(io_in_3_bits_valid),
    .io_in_3_bits_address(io_in_3_bits_address),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_valid(i_io_out_bits_valid),
    .io_out_bits_address(i_io_out_bits_address)
  );
  task automatic drive_random_inputs();
    io_in_0_valid = $urandom_range(0, 1);
    io_in_0_bits_valid = $urandom_range(0, 1);
    io_in_0_bits_address = 46'($urandom);
    io_in_1_valid = $urandom_range(0, 1);
    io_in_1_bits_valid = $urandom_range(0, 1);
    io_in_1_bits_address = 46'($urandom);
    io_in_2_valid = $urandom_range(0, 1);
    io_in_2_bits_valid = $urandom_range(0, 1);
    io_in_2_bits_address = 46'($urandom);
    io_in_3_valid = $urandom_range(0, 1);
    io_in_3_bits_valid = $urandom_range(0, 1);
    io_in_3_bits_address = 46'($urandom);
  endtask
  task automatic check_outputs();
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_valid)
    `CHECK(io_out_bits_address)
  endtask
  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    io_in_0_valid = '0;
    io_in_0_bits_valid = '0;
    io_in_0_bits_address = '0;
    io_in_1_valid = '0;
    io_in_1_bits_valid = '0;
    io_in_1_bits_address = '0;
    io_in_2_valid = '0;
    io_in_2_bits_valid = '0;
    io_in_2_bits_address = '0;
    io_in_3_valid = '0;
    io_in_3_bits_valid = '0;
    io_in_3_bits_address = '0;
    repeat (2) @(posedge clock);
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      #1 check_outputs();
    end
    $display("Arbiter4_L2CacheErrorInfo checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED"); $finish;
    end
    $display("TEST FAILED"); $fatal(1);
  end
endmodule
`undef CHECK

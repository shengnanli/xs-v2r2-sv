// 自动生成：scripts/gen_fastarbiter.py —— 勿手改
// FastArbiter_2 双例化逐拍比对: golden FastArbiter_2 vs 可读 FastArbiter_2_xs。
// 激励: 全随机 (随机 valids + 随机 io_out_ready 自然遍历 round-robin 轮转相位)。
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
  bit reset;
  int errors = 0;
  int checks = 0;
  always #5 clock = ~clock;

  logic io_in_0_valid;
  logic [4:0] io_in_0_bits_pfSource;
  logic io_in_1_valid;
  logic [4:0] io_in_1_bits_pfSource;
  logic io_in_2_valid;
  logic [4:0] io_in_2_bits_pfSource;
  logic io_in_3_valid;
  logic [4:0] io_in_3_bits_pfSource;
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
  wire [4:0] g_io_out_bits_pfSource;
  wire [4:0] i_io_out_bits_pfSource;

  FastArbiter_2 u_g (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(g_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_pfSource(io_in_0_bits_pfSource),
    .io_in_1_ready(g_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_pfSource(io_in_1_bits_pfSource),
    .io_in_2_ready(g_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_pfSource(io_in_2_bits_pfSource),
    .io_in_3_ready(g_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_pfSource(io_in_3_bits_pfSource),
    .io_out_ready(io_out_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_pfSource(g_io_out_bits_pfSource)
  );

  FastArbiter_2_xs u_i (
    .clock(clock),
    .reset(reset),
    .io_in_0_ready(i_io_in_0_ready),
    .io_in_0_valid(io_in_0_valid),
    .io_in_0_bits_pfSource(io_in_0_bits_pfSource),
    .io_in_1_ready(i_io_in_1_ready),
    .io_in_1_valid(io_in_1_valid),
    .io_in_1_bits_pfSource(io_in_1_bits_pfSource),
    .io_in_2_ready(i_io_in_2_ready),
    .io_in_2_valid(io_in_2_valid),
    .io_in_2_bits_pfSource(io_in_2_bits_pfSource),
    .io_in_3_ready(i_io_in_3_ready),
    .io_in_3_valid(io_in_3_valid),
    .io_in_3_bits_pfSource(io_in_3_bits_pfSource),
    .io_out_ready(io_out_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_pfSource(i_io_out_bits_pfSource)
  );

  task automatic drive_random_inputs();
    io_in_0_valid <= $urandom_range(0, 1);
    io_in_0_bits_pfSource <= 5'({$urandom});
    io_in_1_valid <= $urandom_range(0, 1);
    io_in_1_bits_pfSource <= 5'({$urandom});
    io_in_2_valid <= $urandom_range(0, 1);
    io_in_2_bits_pfSource <= 5'({$urandom});
    io_in_3_valid <= $urandom_range(0, 1);
    io_in_3_bits_pfSource <= 5'({$urandom});
    io_out_ready <= $urandom_range(0, 1);
  endtask

  task automatic check_outputs();
    `CHECK(io_in_0_ready)
    `CHECK(io_in_1_ready)
    `CHECK(io_in_2_ready)
    `CHECK(io_in_3_ready)
    `CHECK(io_out_valid)
    `CHECK(io_out_bits_pfSource)
  endtask

  initial begin
    if ($value$plusargs("NCYCLES=%d", NCYCLES)) begin end
    reset = 1'b1;
    io_in_0_valid = '0;
    io_in_0_bits_pfSource = '0;
    io_in_1_valid = '0;
    io_in_1_bits_pfSource = '0;
    io_in_2_valid = '0;
    io_in_2_bits_pfSource = '0;
    io_in_3_valid = '0;
    io_in_3_bits_pfSource = '0;
    io_out_ready = '0;
    repeat (6) @(posedge clock);
    reset = 1'b0;
    repeat (NCYCLES) begin
      @(negedge clock);
      drive_random_inputs();
      @(posedge clock);
      #1 check_outputs();
    end
    $display("FastArbiter_2 checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) begin
      $display("TEST PASSED");
      $finish;
    end
    $display("TEST FAILED");
    $fatal(1);
  end
endmodule
`undef CHECK

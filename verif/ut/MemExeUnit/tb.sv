// 自动生成: gen_tb.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [34:0] io_in_bits_uop_fuType;
  logic [8:0] io_in_bits_uop_fuOpType;
  logic [7:0] io_in_bits_uop_robIdx_value;
  logic io_in_bits_uop_sqIdx_flag;
  logic [5:0] io_in_bits_uop_sqIdx_value;
  logic [63:0] io_in_bits_src_0;
  logic io_out_ready;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [34:0] g_io_out_bits_uop_fuType;
  wire [34:0] i_io_out_bits_uop_fuType;
  wire [8:0] g_io_out_bits_uop_fuOpType;
  wire [8:0] i_io_out_bits_uop_fuOpType;
  wire [7:0] g_io_out_bits_uop_robIdx_value;
  wire [7:0] i_io_out_bits_uop_robIdx_value;
  wire g_io_out_bits_uop_sqIdx_flag;
  wire i_io_out_bits_uop_sqIdx_flag;
  wire [5:0] g_io_out_bits_uop_sqIdx_value;
  wire [5:0] i_io_out_bits_uop_sqIdx_value;
  wire [63:0] g_io_out_bits_data;
  wire [63:0] i_io_out_bits_data;

  MemExeUnit dut_g (
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_fuType(io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_out_ready(io_out_ready),
    .io_in_ready(g_io_in_ready),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_uop_fuType(g_io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType(g_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_robIdx_value(g_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_sqIdx_flag(g_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(g_io_out_bits_uop_sqIdx_value),
    .io_out_bits_data(g_io_out_bits_data)
  );

  MemExeUnit_xs dut_i (
    .io_in_valid(io_in_valid),
    .io_in_bits_uop_fuType(io_in_bits_uop_fuType),
    .io_in_bits_uop_fuOpType(io_in_bits_uop_fuOpType),
    .io_in_bits_uop_robIdx_value(io_in_bits_uop_robIdx_value),
    .io_in_bits_uop_sqIdx_flag(io_in_bits_uop_sqIdx_flag),
    .io_in_bits_uop_sqIdx_value(io_in_bits_uop_sqIdx_value),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_out_ready(io_out_ready),
    .io_in_ready(i_io_in_ready),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_uop_fuType(i_io_out_bits_uop_fuType),
    .io_out_bits_uop_fuOpType(i_io_out_bits_uop_fuOpType),
    .io_out_bits_uop_robIdx_value(i_io_out_bits_uop_robIdx_value),
    .io_out_bits_uop_sqIdx_flag(i_io_out_bits_uop_sqIdx_flag),
    .io_out_bits_uop_sqIdx_value(i_io_out_bits_uop_sqIdx_value),
    .io_out_bits_data(i_io_out_bits_data)
  );

  task automatic drive_random();
    io_in_valid = $random;
    io_in_bits_uop_fuType = {$random,$random};
    io_in_bits_uop_fuOpType = $random;
    io_in_bits_uop_robIdx_value = $random;
    io_in_bits_uop_sqIdx_flag = $random;
    io_in_bits_uop_sqIdx_value = $random;
    io_in_bits_src_0 = {$random,$random};
    io_out_ready = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_in_ready !== i_io_in_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_in_ready: g=%h i=%h", cyc, g_io_in_ready, i_io_in_ready); end
    if (g_io_out_valid !== i_io_out_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_valid: g=%h i=%h", cyc, g_io_out_valid, i_io_out_valid); end
    if (g_io_out_bits_uop_fuType !== i_io_out_bits_uop_fuType) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_fuType: g=%h i=%h", cyc, g_io_out_bits_uop_fuType, i_io_out_bits_uop_fuType); end
    if (g_io_out_bits_uop_fuOpType !== i_io_out_bits_uop_fuOpType) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_fuOpType: g=%h i=%h", cyc, g_io_out_bits_uop_fuOpType, i_io_out_bits_uop_fuOpType); end
    if (g_io_out_bits_uop_robIdx_value !== i_io_out_bits_uop_robIdx_value) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_robIdx_value: g=%h i=%h", cyc, g_io_out_bits_uop_robIdx_value, i_io_out_bits_uop_robIdx_value); end
    if (g_io_out_bits_uop_sqIdx_flag !== i_io_out_bits_uop_sqIdx_flag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_sqIdx_flag: g=%h i=%h", cyc, g_io_out_bits_uop_sqIdx_flag, i_io_out_bits_uop_sqIdx_flag); end
    if (g_io_out_bits_uop_sqIdx_value !== i_io_out_bits_uop_sqIdx_value) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_uop_sqIdx_value: g=%h i=%h", cyc, g_io_out_bits_uop_sqIdx_value, i_io_out_bits_uop_sqIdx_value); end
    if (g_io_out_bits_data !== i_io_out_bits_data) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_out_bits_data: g=%h i=%h", cyc, g_io_out_bits_data, i_io_out_bits_data); end
  endtask

  initial begin
    io_in_valid = '0;
    io_in_bits_uop_fuType = '0;
    io_in_bits_uop_fuOpType = '0;
    io_in_bits_uop_robIdx_value = '0;
    io_in_bits_uop_sqIdx_flag = '0;
    io_in_bits_uop_sqIdx_value = '0;
    io_in_bits_src_0 = '0;
    io_out_ready = '0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      #1;
      check_outputs();
    end
    if (errors == 0)
      $display("TEST PASSED: checks=%0d errors=0", checks);
    else
      $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule

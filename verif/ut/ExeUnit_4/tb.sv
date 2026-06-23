// 自动生成:scripts/gen_exeunit.py（ExeUnit_4）—— 勿手改(逻辑为从设计意图的可读重写)

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [34:0] io_in_bits_fuType;
  logic [8:0] io_in_bits_fuOpType;
  logic [63:0] io_in_bits_src_0;
  logic [63:0] io_in_bits_src_1;
  logic io_in_bits_robIdx_flag;
  logic [7:0] io_in_bits_robIdx_value;
  logic [7:0] io_in_bits_pdest;
  logic io_in_bits_rfWen;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [63:0] g_io_out_bits_data_0;
  wire [63:0] i_io_out_bits_data_0;
  wire [63:0] g_io_out_bits_data_1;
  wire [63:0] i_io_out_bits_data_1;
  wire [7:0] g_io_out_bits_pdest;
  wire [7:0] i_io_out_bits_pdest;
  wire g_io_out_bits_robIdx_flag;
  wire i_io_out_bits_robIdx_flag;
  wire [7:0] g_io_out_bits_robIdx_value;
  wire [7:0] i_io_out_bits_robIdx_value;
  wire g_io_out_bits_intWen;
  wire i_io_out_bits_intWen;
  wire [63:0] g_io_out_bits_debugInfo_enqRsTime;
  wire [63:0] i_io_out_bits_debugInfo_enqRsTime;
  wire [63:0] g_io_out_bits_debugInfo_selectTime;
  wire [63:0] i_io_out_bits_debugInfo_selectTime;
  wire [63:0] g_io_out_bits_debugInfo_issueTime;
  wire [63:0] i_io_out_bits_debugInfo_issueTime;

  ExeUnit_4 u_g (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_data_0(g_io_out_bits_data_0),
    .io_out_bits_data_1(g_io_out_bits_data_1),
    .io_out_bits_pdest(g_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(g_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_io_out_bits_robIdx_value),
    .io_out_bits_intWen(g_io_out_bits_intWen),
    .io_out_bits_debugInfo_enqRsTime(g_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(g_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(g_io_out_bits_debugInfo_issueTime)
  );
  ExeUnit_4_xs u_i (
    .clock(clk),
    .reset(rst),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_data_0(i_io_out_bits_data_0),
    .io_out_bits_data_1(i_io_out_bits_data_1),
    .io_out_bits_pdest(i_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(i_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_io_out_bits_robIdx_value),
    .io_out_bits_intWen(i_io_out_bits_intWen),
    .io_out_bits_debugInfo_enqRsTime(i_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(i_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(i_io_out_bits_debugInfo_issueTime)
  );

  always @(posedge clk) if (!rst) begin
    io_in_valid <= $urandom_range(0,1);
    io_in_bits_fuType <= 35'({$urandom(), $urandom()});
    io_in_bits_fuOpType <= 9'($urandom);
    io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
    io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
    io_in_bits_robIdx_flag <= $urandom_range(0,1);
    io_in_bits_robIdx_value <= 8'($urandom);
    io_in_bits_pdest <= 8'($urandom);
    io_in_bits_rfWen <= $urandom_range(0,1);
    io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_out_valid) && g_io_out_valid !== i_io_out_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_out_valid g=%h i=%h", $time, g_io_out_valid, i_io_out_valid); end
    if (!$isunknown(g_io_out_bits_data_0) && g_io_out_bits_data_0 !== i_io_out_bits_data_0) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_data_0 g=%h i=%h", $time, g_io_out_bits_data_0, i_io_out_bits_data_0); end
    if (!$isunknown(g_io_out_bits_data_1) && g_io_out_bits_data_1 !== i_io_out_bits_data_1) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_data_1 g=%h i=%h", $time, g_io_out_bits_data_1, i_io_out_bits_data_1); end
    if (!$isunknown(g_io_out_bits_pdest) && g_io_out_bits_pdest !== i_io_out_bits_pdest) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_pdest g=%h i=%h", $time, g_io_out_bits_pdest, i_io_out_bits_pdest); end
    if (!$isunknown(g_io_out_bits_robIdx_flag) && g_io_out_bits_robIdx_flag !== i_io_out_bits_robIdx_flag) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_robIdx_flag g=%h i=%h", $time, g_io_out_bits_robIdx_flag, i_io_out_bits_robIdx_flag); end
    if (!$isunknown(g_io_out_bits_robIdx_value) && g_io_out_bits_robIdx_value !== i_io_out_bits_robIdx_value) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_robIdx_value g=%h i=%h", $time, g_io_out_bits_robIdx_value, i_io_out_bits_robIdx_value); end
    if (!$isunknown(g_io_out_bits_intWen) && g_io_out_bits_intWen !== i_io_out_bits_intWen) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_intWen g=%h i=%h", $time, g_io_out_bits_intWen, i_io_out_bits_intWen); end
    if (!$isunknown(g_io_out_bits_debugInfo_enqRsTime) && g_io_out_bits_debugInfo_enqRsTime !== i_io_out_bits_debugInfo_enqRsTime) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_debugInfo_enqRsTime g=%h i=%h", $time, g_io_out_bits_debugInfo_enqRsTime, i_io_out_bits_debugInfo_enqRsTime); end
    if (!$isunknown(g_io_out_bits_debugInfo_selectTime) && g_io_out_bits_debugInfo_selectTime !== i_io_out_bits_debugInfo_selectTime) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_debugInfo_selectTime g=%h i=%h", $time, g_io_out_bits_debugInfo_selectTime, i_io_out_bits_debugInfo_selectTime); end
    if (!$isunknown(g_io_out_bits_debugInfo_issueTime) && g_io_out_bits_debugInfo_issueTime !== i_io_out_bits_debugInfo_issueTime) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_debugInfo_issueTime g=%h i=%h", $time, g_io_out_bits_debugInfo_issueTime, i_io_out_bits_debugInfo_issueTime); end
  end

  initial begin
    rst = 1; repeat (16) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule

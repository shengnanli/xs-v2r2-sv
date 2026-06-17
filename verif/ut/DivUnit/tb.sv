// 自动生成：scripts/gen_divunit.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_flush_valid;
  logic io_flush_bits_robIdx_flag;
  logic [7:0] io_flush_bits_robIdx_value;
  logic io_flush_bits_level;
  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic io_in_bits_ctrl_robIdx_flag;
  logic [7:0] io_in_bits_ctrl_robIdx_value;
  logic [7:0] io_in_bits_ctrl_pdest;
  logic io_in_bits_ctrl_rfWen;
  logic [63:0] io_in_bits_data_src_1;
  logic [63:0] io_in_bits_data_src_0;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic io_out_ready;
  wire g_io_in_ready;
  wire i_io_in_ready;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire g_io_out_bits_ctrl_robIdx_flag;
  wire i_io_out_bits_ctrl_robIdx_flag;
  wire [7:0] g_io_out_bits_ctrl_robIdx_value;
  wire [7:0] i_io_out_bits_ctrl_robIdx_value;
  wire [7:0] g_io_out_bits_ctrl_pdest;
  wire [7:0] i_io_out_bits_ctrl_pdest;
  wire g_io_out_bits_ctrl_rfWen;
  wire i_io_out_bits_ctrl_rfWen;
  wire [63:0] g_io_out_bits_res_data;
  wire [63:0] i_io_out_bits_res_data;
  wire [63:0] g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] i_io_out_bits_perfDebugInfo_issueTime;
  DivUnit    u_g (.clock(clk), .reset(rst), .io_flush_valid(io_flush_valid), .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag), .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value), .io_flush_bits_level(io_flush_bits_level), .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag), .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value), .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest), .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen), .io_in_bits_data_src_1(io_in_bits_data_src_1), .io_in_bits_data_src_0(io_in_bits_data_src_0), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_out_ready(io_out_ready), .io_in_ready(g_io_in_ready), .io_out_valid(g_io_out_valid), .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(g_io_out_bits_ctrl_rfWen), .io_out_bits_res_data(g_io_out_bits_res_data), .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime));
  DivUnit_xs u_i (.clock(clk), .reset(rst), .io_flush_valid(io_flush_valid), .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag), .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value), .io_flush_bits_level(io_flush_bits_level), .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_robIdx_flag(io_in_bits_ctrl_robIdx_flag), .io_in_bits_ctrl_robIdx_value(io_in_bits_ctrl_robIdx_value), .io_in_bits_ctrl_pdest(io_in_bits_ctrl_pdest), .io_in_bits_ctrl_rfWen(io_in_bits_ctrl_rfWen), .io_in_bits_data_src_1(io_in_bits_data_src_1), .io_in_bits_data_src_0(io_in_bits_data_src_0), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_out_ready(io_out_ready), .io_in_ready(i_io_in_ready), .io_out_valid(i_io_out_valid), .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(i_io_out_bits_ctrl_rfWen), .io_out_bits_res_data(i_io_out_bits_res_data), .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime));
  // 合法除法 fuOpType（10xxx）：div=10000 rem=10001 divu=10010 remu=10011
  //   divw=10100 remw=10101 divuw=10110 remuw=10111
  logic [8:0] divops [0:7] = '{9'h10, 9'h11, 9'h12, 9'h13, 9'h14, 9'h15, 9'h16, 9'h17};
  always @(negedge clk) begin
    if (rst) begin
      io_in_valid <= 1'b0;
      io_flush_valid <= 1'b0;
      io_out_ready <= 1'b0;
    end else begin
      io_flush_valid <= ($urandom_range(0,7)==0);
      io_flush_bits_robIdx_flag <= $urandom_range(0,1);
      io_flush_bits_robIdx_value <= 8'($urandom_range(0,15));
      io_flush_bits_level <= $urandom_range(0,1);
      io_in_valid <= ($urandom_range(0,3)!=0);
      io_in_bits_ctrl_fuOpType <= divops[$urandom_range(0,7)];
      io_in_bits_ctrl_robIdx_flag <= $urandom_range(0,1);
      io_in_bits_ctrl_robIdx_value <= 8'($urandom_range(0,15));
      io_in_bits_ctrl_pdest <= 8'($urandom);
      io_in_bits_ctrl_rfWen <= $urandom_range(0,1);
      io_in_bits_data_src_1 <= 64'({$urandom(), $urandom()});
      io_in_bits_data_src_0 <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      io_out_ready <= $urandom_range(0,1);
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_in_ready) && g_io_in_ready !== i_io_in_ready) begin errors++;
      if(errors<=60) $display("[%0t] io_in_ready g=%h i=%h", $time, g_io_in_ready, i_io_in_ready); end
    if (!$isunknown(g_io_out_valid) && g_io_out_valid !== i_io_out_valid) begin errors++;
      if(errors<=60) $display("[%0t] io_out_valid g=%h i=%h", $time, g_io_out_valid, i_io_out_valid); end
    if (!$isunknown(g_io_out_bits_ctrl_robIdx_flag) && g_io_out_bits_ctrl_robIdx_flag !== i_io_out_bits_ctrl_robIdx_flag) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_ctrl_robIdx_flag g=%h i=%h", $time, g_io_out_bits_ctrl_robIdx_flag, i_io_out_bits_ctrl_robIdx_flag); end
    if (!$isunknown(g_io_out_bits_ctrl_robIdx_value) && g_io_out_bits_ctrl_robIdx_value !== i_io_out_bits_ctrl_robIdx_value) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_ctrl_robIdx_value g=%h i=%h", $time, g_io_out_bits_ctrl_robIdx_value, i_io_out_bits_ctrl_robIdx_value); end
    if (!$isunknown(g_io_out_bits_ctrl_pdest) && g_io_out_bits_ctrl_pdest !== i_io_out_bits_ctrl_pdest) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_ctrl_pdest g=%h i=%h", $time, g_io_out_bits_ctrl_pdest, i_io_out_bits_ctrl_pdest); end
    if (!$isunknown(g_io_out_bits_ctrl_rfWen) && g_io_out_bits_ctrl_rfWen !== i_io_out_bits_ctrl_rfWen) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_ctrl_rfWen g=%h i=%h", $time, g_io_out_bits_ctrl_rfWen, i_io_out_bits_ctrl_rfWen); end
    if (!$isunknown(g_io_out_bits_res_data) && g_io_out_bits_res_data !== i_io_out_bits_res_data) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_res_data g=%h i=%h", $time, g_io_out_bits_res_data, i_io_out_bits_res_data); end
    if (!$isunknown(g_io_out_bits_perfDebugInfo_enqRsTime) && g_io_out_bits_perfDebugInfo_enqRsTime !== i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_perfDebugInfo_enqRsTime g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_enqRsTime, i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (!$isunknown(g_io_out_bits_perfDebugInfo_selectTime) && g_io_out_bits_perfDebugInfo_selectTime !== i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_perfDebugInfo_selectTime g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_selectTime, i_io_out_bits_perfDebugInfo_selectTime); end
    if (!$isunknown(g_io_out_bits_perfDebugInfo_issueTime) && g_io_out_bits_perfDebugInfo_issueTime !== i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_perfDebugInfo_issueTime g=%h i=%h", $time, g_io_out_bits_perfDebugInfo_issueTime, i_io_out_bits_perfDebugInfo_issueTime); end
  end
  initial begin
    rst = 1; repeat (8) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED"); else $display("TEST FAILED");
    $finish;
  end
endmodule

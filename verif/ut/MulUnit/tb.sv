// 自动生成：scripts/gen_mulunit.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic io_in_bits_ctrlPipe_2_robIdx_flag;
  logic [7:0] io_in_bits_ctrlPipe_2_robIdx_value;
  logic [7:0] io_in_bits_ctrlPipe_2_pdest;
  logic io_in_bits_ctrlPipe_2_rfWen;
  logic io_in_bits_validPipe_0;
  logic io_in_bits_validPipe_1;
  logic io_in_bits_validPipe_2;
  logic [63:0] io_in_bits_data_src_1;
  logic [63:0] io_in_bits_data_src_0;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
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
  MulUnit    u_g (.clock(clk), .reset(rst), .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag), .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value), .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest), .io_in_bits_ctrlPipe_2_rfWen(io_in_bits_ctrlPipe_2_rfWen), .io_in_bits_validPipe_0(io_in_bits_validPipe_0), .io_in_bits_validPipe_1(io_in_bits_validPipe_1), .io_in_bits_validPipe_2(io_in_bits_validPipe_2), .io_in_bits_data_src_1(io_in_bits_data_src_1), .io_in_bits_data_src_0(io_in_bits_data_src_0), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_out_valid(g_io_out_valid), .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(g_io_out_bits_ctrl_rfWen), .io_out_bits_res_data(g_io_out_bits_res_data), .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime));
  MulUnit_xs u_i (.clock(clk), .reset(rst), .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrlPipe_2_robIdx_flag(io_in_bits_ctrlPipe_2_robIdx_flag), .io_in_bits_ctrlPipe_2_robIdx_value(io_in_bits_ctrlPipe_2_robIdx_value), .io_in_bits_ctrlPipe_2_pdest(io_in_bits_ctrlPipe_2_pdest), .io_in_bits_ctrlPipe_2_rfWen(io_in_bits_ctrlPipe_2_rfWen), .io_in_bits_validPipe_0(io_in_bits_validPipe_0), .io_in_bits_validPipe_1(io_in_bits_validPipe_1), .io_in_bits_validPipe_2(io_in_bits_validPipe_2), .io_in_bits_data_src_1(io_in_bits_data_src_1), .io_in_bits_data_src_0(io_in_bits_data_src_0), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_out_valid(i_io_out_valid), .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(i_io_out_bits_ctrl_rfWen), .io_out_bits_res_data(i_io_out_bits_res_data), .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime));
  // 合法乘法 fuOpType：mul=00000 mulh=00001 mulhsu=00010 mulhu=00011 mulw=00100 mulw7=01100
  logic [8:0] mulops [0:5] = '{9'h00, 9'h01, 9'h02, 9'h03, 9'h04, 9'h0C};
  always @(negedge clk) begin
    if (rst) begin
      io_in_valid <= 1'b0;
      io_in_bits_validPipe_0 <= 1'b0;
      io_in_bits_validPipe_1 <= 1'b0;
      io_in_bits_validPipe_2 <= 1'b0;
    end else begin
      io_in_valid <= $urandom_range(0,1);
      io_in_bits_ctrl_fuOpType <= mulops[$urandom_range(0,5)];
      io_in_bits_ctrlPipe_2_robIdx_flag <= $urandom_range(0,1);
      io_in_bits_ctrlPipe_2_robIdx_value <= 8'($urandom);
      io_in_bits_ctrlPipe_2_pdest <= 8'($urandom);
      io_in_bits_ctrlPipe_2_rfWen <= $urandom_range(0,1);
      io_in_bits_validPipe_0 <= $urandom_range(0,1);
      io_in_bits_validPipe_1 <= $urandom_range(0,1);
      io_in_bits_validPipe_2 <= $urandom_range(0,1);
      io_in_bits_data_src_1 <= 64'({$urandom(), $urandom()});
      io_in_bits_data_src_0 <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
    end
  end
  always @(negedge clk) if (!rst) begin
    #4; checks++;
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

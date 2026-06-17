// 自动生成：scripts/gen_falu.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  always #5 clk = ~clk;

  logic io_in_valid;
  logic [8:0] io_in_bits_ctrl_fuOpType;
  logic [1:0] io_in_bits_ctrl_fpu_fmt;
  logic [2:0] io_in_bits_ctrl_fpu_rm;
  logic io_in_bits_ctrlPipe_1_robIdx_flag;
  logic [7:0] io_in_bits_ctrlPipe_1_robIdx_value;
  logic [7:0] io_in_bits_ctrlPipe_1_pdest;
  logic io_in_bits_ctrlPipe_1_rfWen;
  logic io_in_bits_ctrlPipe_1_fpWen;
  logic io_in_bits_ctrlPipe_1_fpu_wflags;
  logic io_in_bits_validPipe_1;
  logic [63:0] io_in_bits_data_src_1;
  logic [63:0] io_in_bits_data_src_0;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic [2:0] io_frm;
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
  wire g_io_out_bits_ctrl_fpWen;
  wire i_io_out_bits_ctrl_fpWen;
  wire g_io_out_bits_ctrl_fpu_wflags;
  wire i_io_out_bits_ctrl_fpu_wflags;
  wire [63:0] g_io_out_bits_res_data;
  wire [63:0] i_io_out_bits_res_data;
  wire [4:0] g_io_out_bits_res_fflags;
  wire [4:0] i_io_out_bits_res_fflags;
  wire [63:0] g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] i_io_out_bits_perfDebugInfo_issueTime;
  FAlu    u_g (.clock(clk), .reset(rst), .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_fpu_fmt(io_in_bits_ctrl_fpu_fmt), .io_in_bits_ctrl_fpu_rm(io_in_bits_ctrl_fpu_rm), .io_in_bits_ctrlPipe_1_robIdx_flag(io_in_bits_ctrlPipe_1_robIdx_flag), .io_in_bits_ctrlPipe_1_robIdx_value(io_in_bits_ctrlPipe_1_robIdx_value), .io_in_bits_ctrlPipe_1_pdest(io_in_bits_ctrlPipe_1_pdest), .io_in_bits_ctrlPipe_1_rfWen(io_in_bits_ctrlPipe_1_rfWen), .io_in_bits_ctrlPipe_1_fpWen(io_in_bits_ctrlPipe_1_fpWen), .io_in_bits_ctrlPipe_1_fpu_wflags(io_in_bits_ctrlPipe_1_fpu_wflags), .io_in_bits_validPipe_1(io_in_bits_validPipe_1), .io_in_bits_data_src_1(io_in_bits_data_src_1), .io_in_bits_data_src_0(io_in_bits_data_src_0), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_frm(io_frm), .io_out_valid(g_io_out_valid), .io_out_bits_ctrl_robIdx_flag(g_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(g_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(g_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(g_io_out_bits_ctrl_rfWen), .io_out_bits_ctrl_fpWen(g_io_out_bits_ctrl_fpWen), .io_out_bits_ctrl_fpu_wflags(g_io_out_bits_ctrl_fpu_wflags), .io_out_bits_res_data(g_io_out_bits_res_data), .io_out_bits_res_fflags(g_io_out_bits_res_fflags), .io_out_bits_perfDebugInfo_enqRsTime(g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(g_io_out_bits_perfDebugInfo_issueTime));
  FAlu_xs u_i (.clock(clk), .reset(rst), .io_in_valid(io_in_valid), .io_in_bits_ctrl_fuOpType(io_in_bits_ctrl_fuOpType), .io_in_bits_ctrl_fpu_fmt(io_in_bits_ctrl_fpu_fmt), .io_in_bits_ctrl_fpu_rm(io_in_bits_ctrl_fpu_rm), .io_in_bits_ctrlPipe_1_robIdx_flag(io_in_bits_ctrlPipe_1_robIdx_flag), .io_in_bits_ctrlPipe_1_robIdx_value(io_in_bits_ctrlPipe_1_robIdx_value), .io_in_bits_ctrlPipe_1_pdest(io_in_bits_ctrlPipe_1_pdest), .io_in_bits_ctrlPipe_1_rfWen(io_in_bits_ctrlPipe_1_rfWen), .io_in_bits_ctrlPipe_1_fpWen(io_in_bits_ctrlPipe_1_fpWen), .io_in_bits_ctrlPipe_1_fpu_wflags(io_in_bits_ctrlPipe_1_fpu_wflags), .io_in_bits_validPipe_1(io_in_bits_validPipe_1), .io_in_bits_data_src_1(io_in_bits_data_src_1), .io_in_bits_data_src_0(io_in_bits_data_src_0), .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime), .io_frm(io_frm), .io_out_valid(i_io_out_valid), .io_out_bits_ctrl_robIdx_flag(i_io_out_bits_ctrl_robIdx_flag), .io_out_bits_ctrl_robIdx_value(i_io_out_bits_ctrl_robIdx_value), .io_out_bits_ctrl_pdest(i_io_out_bits_ctrl_pdest), .io_out_bits_ctrl_rfWen(i_io_out_bits_ctrl_rfWen), .io_out_bits_ctrl_fpWen(i_io_out_bits_ctrl_fpWen), .io_out_bits_ctrl_fpu_wflags(i_io_out_bits_ctrl_fpu_wflags), .io_out_bits_res_data(i_io_out_bits_res_data), .io_out_bits_res_fflags(i_io_out_bits_res_fflags), .io_out_bits_perfDebugInfo_enqRsTime(i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(i_io_out_bits_perfDebugInfo_issueTime));
  // 合法 fuOpType 集合（覆盖各 opType）
  logic [8:0] fops [0:9] = '{9'h00, 9'h01, 9'h02, 9'h03, 9'h04, 9'h08, 9'h0C, 9'h0E, 9'h10, 9'h12};
  always @(negedge clk) begin
    if (rst) begin
      io_in_valid <= 1'b0;
      io_in_bits_validPipe_1 <= 1'b0;
    end else begin
      io_in_valid <= $urandom_range(0,1);
      io_in_bits_ctrl_fuOpType <= fops[$urandom_range(0,9)];
      io_in_bits_ctrl_fpu_fmt <= 2'($urandom);
      io_in_bits_ctrl_fpu_rm <= 3'($urandom);
      io_in_bits_ctrlPipe_1_robIdx_flag <= $urandom_range(0,1);
      io_in_bits_ctrlPipe_1_robIdx_value <= 8'($urandom);
      io_in_bits_ctrlPipe_1_pdest <= 8'($urandom);
      io_in_bits_ctrlPipe_1_rfWen <= $urandom_range(0,1);
      io_in_bits_ctrlPipe_1_fpWen <= $urandom_range(0,1);
      io_in_bits_ctrlPipe_1_fpu_wflags <= $urandom_range(0,1);
      io_in_bits_validPipe_1 <= $urandom_range(0,1);
      io_in_bits_data_src_1 <= 64'({$urandom(), $urandom()});
      io_in_bits_data_src_0 <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      io_frm <= 3'($urandom);
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
    if (!$isunknown(g_io_out_bits_ctrl_fpWen) && g_io_out_bits_ctrl_fpWen !== i_io_out_bits_ctrl_fpWen) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_ctrl_fpWen g=%h i=%h", $time, g_io_out_bits_ctrl_fpWen, i_io_out_bits_ctrl_fpWen); end
    if (!$isunknown(g_io_out_bits_ctrl_fpu_wflags) && g_io_out_bits_ctrl_fpu_wflags !== i_io_out_bits_ctrl_fpu_wflags) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_ctrl_fpu_wflags g=%h i=%h", $time, g_io_out_bits_ctrl_fpu_wflags, i_io_out_bits_ctrl_fpu_wflags); end
    if (!$isunknown(g_io_out_bits_res_data) && g_io_out_bits_res_data !== i_io_out_bits_res_data) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_res_data g=%h i=%h", $time, g_io_out_bits_res_data, i_io_out_bits_res_data); end
    if (!$isunknown(g_io_out_bits_res_fflags) && g_io_out_bits_res_fflags !== i_io_out_bits_res_fflags) begin errors++;
      if(errors<=60) $display("[%0t] io_out_bits_res_fflags g=%h i=%h", $time, g_io_out_bits_res_fflags, i_io_out_bits_res_fflags); end
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

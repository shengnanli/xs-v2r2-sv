// 自动生成:scripts/gen_exeunit.py（ExeUnit_8）—— 勿手改(逻辑为从设计意图的可读重写)

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
  logic [34:0] io_in_bits_fuType;
  logic [8:0] io_in_bits_fuOpType;
  logic [63:0] io_in_bits_src_0;
  logic [63:0] io_in_bits_src_1;
  logic [63:0] io_in_bits_src_2;
  logic io_in_bits_robIdx_flag;
  logic [7:0] io_in_bits_robIdx_value;
  logic [7:0] io_in_bits_pdest;
  logic io_in_bits_rfWen;
  logic io_in_bits_fpWen;
  logic io_in_bits_vecWen;
  logic io_in_bits_v0Wen;
  logic io_in_bits_fpu_wflags;
  logic [1:0] io_in_bits_fpu_fmt;
  logic [2:0] io_in_bits_fpu_rm;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic [2:0] io_frm;
  logic cg_bore_cgen;
  logic cg_bore_1_cgen;
  logic cg_bore_2_cgen;
  wire g_io_out_valid;
  wire i_io_out_valid;
  wire [127:0] g_io_out_bits_data_0;
  wire [127:0] i_io_out_bits_data_0;
  wire [127:0] g_io_out_bits_data_1;
  wire [127:0] i_io_out_bits_data_1;
  wire [127:0] g_io_out_bits_data_2;
  wire [127:0] i_io_out_bits_data_2;
  wire [127:0] g_io_out_bits_data_3;
  wire [127:0] i_io_out_bits_data_3;
  wire [127:0] g_io_out_bits_data_4;
  wire [127:0] i_io_out_bits_data_4;
  wire [7:0] g_io_out_bits_pdest;
  wire [7:0] i_io_out_bits_pdest;
  wire g_io_out_bits_robIdx_flag;
  wire i_io_out_bits_robIdx_flag;
  wire [7:0] g_io_out_bits_robIdx_value;
  wire [7:0] i_io_out_bits_robIdx_value;
  wire g_io_out_bits_intWen;
  wire i_io_out_bits_intWen;
  wire g_io_out_bits_fpWen;
  wire i_io_out_bits_fpWen;
  wire g_io_out_bits_vecWen;
  wire i_io_out_bits_vecWen;
  wire g_io_out_bits_v0Wen;
  wire i_io_out_bits_v0Wen;
  wire [4:0] g_io_out_bits_fflags;
  wire [4:0] i_io_out_bits_fflags;
  wire g_io_out_bits_wflags;
  wire i_io_out_bits_wflags;
  wire [63:0] g_io_out_bits_debugInfo_enqRsTime;
  wire [63:0] i_io_out_bits_debugInfo_enqRsTime;
  wire [63:0] g_io_out_bits_debugInfo_selectTime;
  wire [63:0] i_io_out_bits_debugInfo_selectTime;
  wire [63:0] g_io_out_bits_debugInfo_issueTime;
  wire [63:0] i_io_out_bits_debugInfo_issueTime;

  ExeUnit_8 u_g (
    .clock(clk),
    .reset(rst),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_src_2(io_in_bits_src_2),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_fpWen(io_in_bits_fpWen),
    .io_in_bits_vecWen(io_in_bits_vecWen),
    .io_in_bits_v0Wen(io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags(io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(g_io_out_valid),
    .io_out_bits_data_0(g_io_out_bits_data_0),
    .io_out_bits_data_1(g_io_out_bits_data_1),
    .io_out_bits_data_2(g_io_out_bits_data_2),
    .io_out_bits_data_3(g_io_out_bits_data_3),
    .io_out_bits_data_4(g_io_out_bits_data_4),
    .io_out_bits_pdest(g_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(g_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_io_out_bits_robIdx_value),
    .io_out_bits_intWen(g_io_out_bits_intWen),
    .io_out_bits_fpWen(g_io_out_bits_fpWen),
    .io_out_bits_vecWen(g_io_out_bits_vecWen),
    .io_out_bits_v0Wen(g_io_out_bits_v0Wen),
    .io_out_bits_fflags(g_io_out_bits_fflags),
    .io_out_bits_wflags(g_io_out_bits_wflags),
    .io_out_bits_debugInfo_enqRsTime(g_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(g_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(g_io_out_bits_debugInfo_issueTime),
    .io_frm(io_frm),
    .cg_bore_cgen(cg_bore_cgen),
    .cg_bore_1_cgen(cg_bore_1_cgen),
    .cg_bore_2_cgen(cg_bore_2_cgen)
  );
  ExeUnit_8_xs u_i (
    .clock(clk),
    .reset(rst),
    .io_flush_valid(io_flush_valid),
    .io_flush_bits_robIdx_flag(io_flush_bits_robIdx_flag),
    .io_flush_bits_robIdx_value(io_flush_bits_robIdx_value),
    .io_flush_bits_level(io_flush_bits_level),
    .io_in_valid(io_in_valid),
    .io_in_bits_fuType(io_in_bits_fuType),
    .io_in_bits_fuOpType(io_in_bits_fuOpType),
    .io_in_bits_src_0(io_in_bits_src_0),
    .io_in_bits_src_1(io_in_bits_src_1),
    .io_in_bits_src_2(io_in_bits_src_2),
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_fpWen(io_in_bits_fpWen),
    .io_in_bits_vecWen(io_in_bits_vecWen),
    .io_in_bits_v0Wen(io_in_bits_v0Wen),
    .io_in_bits_fpu_wflags(io_in_bits_fpu_wflags),
    .io_in_bits_fpu_fmt(io_in_bits_fpu_fmt),
    .io_in_bits_fpu_rm(io_in_bits_fpu_rm),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_valid(i_io_out_valid),
    .io_out_bits_data_0(i_io_out_bits_data_0),
    .io_out_bits_data_1(i_io_out_bits_data_1),
    .io_out_bits_data_2(i_io_out_bits_data_2),
    .io_out_bits_data_3(i_io_out_bits_data_3),
    .io_out_bits_data_4(i_io_out_bits_data_4),
    .io_out_bits_pdest(i_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(i_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(i_io_out_bits_robIdx_value),
    .io_out_bits_intWen(i_io_out_bits_intWen),
    .io_out_bits_fpWen(i_io_out_bits_fpWen),
    .io_out_bits_vecWen(i_io_out_bits_vecWen),
    .io_out_bits_v0Wen(i_io_out_bits_v0Wen),
    .io_out_bits_fflags(i_io_out_bits_fflags),
    .io_out_bits_wflags(i_io_out_bits_wflags),
    .io_out_bits_debugInfo_enqRsTime(i_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(i_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(i_io_out_bits_debugInfo_issueTime),
    .io_frm(io_frm),
    .cg_bore_cgen(cg_bore_cgen),
    .cg_bore_1_cgen(cg_bore_1_cgen),
    .cg_bore_2_cgen(cg_bore_2_cgen)
  );

  always @(posedge clk) if (!rst) begin
    io_flush_valid <= $urandom_range(0,1);
    io_flush_bits_robIdx_flag <= $urandom_range(0,1);
    io_flush_bits_robIdx_value <= 8'($urandom);
    io_flush_bits_level <= $urandom_range(0,1);
    io_in_valid <= $urandom_range(0,1);
    io_in_bits_fuType <= 35'({$urandom(), $urandom()});
    io_in_bits_fuOpType <= 9'($urandom);
    io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
    io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
    io_in_bits_src_2 <= 64'({$urandom(), $urandom()});
    io_in_bits_robIdx_flag <= $urandom_range(0,1);
    io_in_bits_robIdx_value <= 8'($urandom);
    io_in_bits_pdest <= 8'($urandom);
    io_in_bits_rfWen <= $urandom_range(0,1);
    io_in_bits_fpWen <= $urandom_range(0,1);
    io_in_bits_vecWen <= $urandom_range(0,1);
    io_in_bits_v0Wen <= $urandom_range(0,1);
    io_in_bits_fpu_wflags <= $urandom_range(0,1);
    io_in_bits_fpu_fmt <= 2'($urandom);
    io_in_bits_fpu_rm <= 3'($urandom);
    io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
    io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
    io_frm <= 3'($urandom);
    cg_bore_cgen <= $urandom_range(0,1);
    cg_bore_1_cgen <= $urandom_range(0,1);
    cg_bore_2_cgen <= $urandom_range(0,1);
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (!$isunknown(g_io_out_valid) && g_io_out_valid !== i_io_out_valid) begin errors++;
      if(errors<=80) $display("[%0t] io_out_valid g=%h i=%h", $time, g_io_out_valid, i_io_out_valid); end
    if (!$isunknown(g_io_out_bits_data_0) && g_io_out_bits_data_0 !== i_io_out_bits_data_0) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_data_0 g=%h i=%h", $time, g_io_out_bits_data_0, i_io_out_bits_data_0); end
    if (!$isunknown(g_io_out_bits_data_1) && g_io_out_bits_data_1 !== i_io_out_bits_data_1) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_data_1 g=%h i=%h", $time, g_io_out_bits_data_1, i_io_out_bits_data_1); end
    if (!$isunknown(g_io_out_bits_data_2) && g_io_out_bits_data_2 !== i_io_out_bits_data_2) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_data_2 g=%h i=%h", $time, g_io_out_bits_data_2, i_io_out_bits_data_2); end
    if (!$isunknown(g_io_out_bits_data_3) && g_io_out_bits_data_3 !== i_io_out_bits_data_3) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_data_3 g=%h i=%h", $time, g_io_out_bits_data_3, i_io_out_bits_data_3); end
    if (!$isunknown(g_io_out_bits_data_4) && g_io_out_bits_data_4 !== i_io_out_bits_data_4) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_data_4 g=%h i=%h", $time, g_io_out_bits_data_4, i_io_out_bits_data_4); end
    if (!$isunknown(g_io_out_bits_pdest) && g_io_out_bits_pdest !== i_io_out_bits_pdest) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_pdest g=%h i=%h", $time, g_io_out_bits_pdest, i_io_out_bits_pdest); end
    if (!$isunknown(g_io_out_bits_robIdx_flag) && g_io_out_bits_robIdx_flag !== i_io_out_bits_robIdx_flag) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_robIdx_flag g=%h i=%h", $time, g_io_out_bits_robIdx_flag, i_io_out_bits_robIdx_flag); end
    if (!$isunknown(g_io_out_bits_robIdx_value) && g_io_out_bits_robIdx_value !== i_io_out_bits_robIdx_value) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_robIdx_value g=%h i=%h", $time, g_io_out_bits_robIdx_value, i_io_out_bits_robIdx_value); end
    if (!$isunknown(g_io_out_bits_intWen) && g_io_out_bits_intWen !== i_io_out_bits_intWen) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_intWen g=%h i=%h", $time, g_io_out_bits_intWen, i_io_out_bits_intWen); end
    if (!$isunknown(g_io_out_bits_fpWen) && g_io_out_bits_fpWen !== i_io_out_bits_fpWen) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_fpWen g=%h i=%h", $time, g_io_out_bits_fpWen, i_io_out_bits_fpWen); end
    if (!$isunknown(g_io_out_bits_vecWen) && g_io_out_bits_vecWen !== i_io_out_bits_vecWen) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_vecWen g=%h i=%h", $time, g_io_out_bits_vecWen, i_io_out_bits_vecWen); end
    if (!$isunknown(g_io_out_bits_v0Wen) && g_io_out_bits_v0Wen !== i_io_out_bits_v0Wen) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_v0Wen g=%h i=%h", $time, g_io_out_bits_v0Wen, i_io_out_bits_v0Wen); end
    if (!$isunknown(g_io_out_bits_fflags) && g_io_out_bits_fflags !== i_io_out_bits_fflags) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_fflags g=%h i=%h", $time, g_io_out_bits_fflags, i_io_out_bits_fflags); end
    if (!$isunknown(g_io_out_bits_wflags) && g_io_out_bits_wflags !== i_io_out_bits_wflags) begin errors++;
      if(errors<=80) $display("[%0t] io_out_bits_wflags g=%h i=%h", $time, g_io_out_bits_wflags, i_io_out_bits_wflags); end
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

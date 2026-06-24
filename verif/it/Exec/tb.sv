// 后端 Exec 簇 IT tb —— 由 gen_it.py 生成（= ExeUnit UT tb，u_i 换 ExeUnit_it，
// 并加强 fuType 激励以真正激活 Alu/Mul/Bku 重写 FU 数据通路，见下方说明）。
// 自动生成:scripts/gen_exeunit.py（ExeUnit）—— 勿手改(逻辑为从设计意图的可读重写)

`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int act_valid = 0, act_data_nz = 0;  // [IT] FU 数据通路活化计数
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
  logic io_in_bits_robIdx_flag;
  logic [7:0] io_in_bits_robIdx_value;
  logic [7:0] io_in_bits_pdest;
  logic io_in_bits_rfWen;
  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] io_in_bits_perfDebugInfo_issueTime;
  logic cg_bore_cgen;
  logic cg_bore_1_cgen;
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

  ExeUnit u_g (
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
    .io_in_bits_robIdx_flag(io_in_bits_robIdx_flag),
    .io_in_bits_robIdx_value(io_in_bits_robIdx_value),
    .io_in_bits_pdest(io_in_bits_pdest),
    .io_in_bits_rfWen(io_in_bits_rfWen),
    .io_in_bits_perfDebugInfo_enqRsTime(io_in_bits_perfDebugInfo_enqRsTime),
    .io_in_bits_perfDebugInfo_selectTime(io_in_bits_perfDebugInfo_selectTime),
    .io_in_bits_perfDebugInfo_issueTime(io_in_bits_perfDebugInfo_issueTime),
    .io_out_ready(1'b1),  // [IT 修正] golden 恒就绪，匹配重写无背压设计（见说明）
    .io_out_valid(g_io_out_valid),
    .io_out_bits_data_0(g_io_out_bits_data_0),
    .io_out_bits_data_1(g_io_out_bits_data_1),
    .io_out_bits_pdest(g_io_out_bits_pdest),
    .io_out_bits_robIdx_flag(g_io_out_bits_robIdx_flag),
    .io_out_bits_robIdx_value(g_io_out_bits_robIdx_value),
    .io_out_bits_intWen(g_io_out_bits_intWen),
    .io_out_bits_debugInfo_enqRsTime(g_io_out_bits_debugInfo_enqRsTime),
    .io_out_bits_debugInfo_selectTime(g_io_out_bits_debugInfo_selectTime),
    .io_out_bits_debugInfo_issueTime(g_io_out_bits_debugInfo_issueTime),
    .cg_bore_cgen(cg_bore_cgen),
    .cg_bore_1_cgen(cg_bore_1_cgen)
  );
  ExeUnit_it u_i (
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
    .io_out_bits_debugInfo_issueTime(i_io_out_bits_debugInfo_issueTime),
    .cg_bore_cgen(cg_bore_cgen),
    .cg_bore_1_cgen(cg_bore_1_cgen)
  );

  always @(posedge clk) if (!rst) begin
    io_flush_valid <= $urandom_range(0,1);
    io_flush_bits_robIdx_flag <= $urandom_range(0,1);
    io_flush_bits_robIdx_value <= 8'($urandom);
    io_flush_bits_level <= $urandom_range(0,1);
    io_in_valid <= $urandom_range(0,1);
    // [IT 加强] fuType 加权：~90% 命中 3 个合法 FU 类型，激活 Alu/Mul/Bku 数据通路；
    //          ~10% 随机（覆盖非命中/Dispatcher reject 路径）。详见本文件顶部说明。
    begin
      int unsigned _ftsel; _ftsel = $urandom_range(0,9);
      case (_ftsel)
        0,1,2:  io_in_bits_fuType <= 35'h40;   // Alu (lat0)
        3,4,5:  io_in_bits_fuType <= 35'h80;   // Mul (lat2)
        6,7,8:  io_in_bits_fuType <= 35'h400;  // Bku (lat2)
        default: io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      endcase
    end
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
    cg_bore_cgen <= $urandom_range(0,1);
    cg_bore_1_cgen <= $urandom_range(0,1);
  end

  always @(negedge clk) if (!rst) begin
    #4; checks++;
    if (g_io_out_valid === 1'b1) act_valid++;
    if (g_io_out_valid === 1'b1 && !$isunknown(g_io_out_bits_data_0)
        && g_io_out_bits_data_0 !== 64'h0) act_data_nz++;
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
    $display("checks=%0d errors=%0d act_valid=%0d act_data_nz=%0d",
             checks, errors, act_valid, act_data_nz);
    if (errors == 0 && checks > 1000 && act_valid > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule

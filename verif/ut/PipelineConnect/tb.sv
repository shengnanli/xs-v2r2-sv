// 自动生成：scripts/gen_pc_wrappers.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 50000;
  int unsigned WARMUP  = 2000;
  bit clk = 0, rst;
  int errors = 0, checks = 0;
  int unsigned cycle = 0;
  always #5 clk = ~clk;
  always @(posedge clk) cycle++;

  logic vNewPipelineConnectPipe_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_io_in_bits_src_1;
  logic vNewPipelineConnectPipe_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_io_in_bits_rfWen;
  logic [63:0] vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_io_rightOutFire;
  logic vNewPipelineConnectPipe_io_isFlush;
  wire vNewPipelineConnectPipe_g_io_out_valid;
  wire vNewPipelineConnectPipe_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_g_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_i_io_out_bits_src_1;
  wire vNewPipelineConnectPipe_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_i_io_out_bits_rfWen;
  wire [63:0] vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe u_g_NewPipelineConnectPipe (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_io_in_bits_src_1), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_io_in_bits_rfWen), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_g_io_out_bits_src_1), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_g_io_out_bits_rfWen), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_xs u_i_NewPipelineConnectPipe (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_io_in_bits_src_1), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_io_in_bits_rfWen), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_i_io_out_bits_src_1), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_i_io_out_bits_rfWen), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_g_io_out_valid !== vNewPipelineConnectPipe_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_valid, vNewPipelineConnectPipe_i_io_out_valid); end
    if (vNewPipelineConnectPipe_g_io_out_bits_fuType !== vNewPipelineConnectPipe_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_fuType, vNewPipelineConnectPipe_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_src_0, vNewPipelineConnectPipe_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_src_1, vNewPipelineConnectPipe_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_g_io_out_bits_pdest !== vNewPipelineConnectPipe_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_pdest, vNewPipelineConnectPipe_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_rfWen, vNewPipelineConnectPipe_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_1_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_1_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_1_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_1_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_1_io_in_bits_src_1;
  logic [63:0] vNewPipelineConnectPipe_1_io_in_bits_imm;
  logic [4:0] vNewPipelineConnectPipe_1_io_in_bits_nextPcOffset;
  logic vNewPipelineConnectPipe_1_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_1_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_1_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_1_io_in_bits_rfWen;
  logic [49:0] vNewPipelineConnectPipe_1_io_in_bits_pc;
  logic vNewPipelineConnectPipe_1_io_in_bits_ftqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_1_io_in_bits_ftqIdx_value;
  logic [3:0] vNewPipelineConnectPipe_1_io_in_bits_ftqOffset;
  logic [49:0] vNewPipelineConnectPipe_1_io_in_bits_predictInfo_target;
  logic vNewPipelineConnectPipe_1_io_in_bits_predictInfo_taken;
  logic [63:0] vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_1_io_rightOutFire;
  logic vNewPipelineConnectPipe_1_io_isFlush;
  wire vNewPipelineConnectPipe_1_g_io_out_valid;
  wire vNewPipelineConnectPipe_1_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_1_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_1_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_1_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_1_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_1_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_1_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_1_g_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_1_i_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_1_g_io_out_bits_imm;
  wire [63:0] vNewPipelineConnectPipe_1_i_io_out_bits_imm;
  wire [4:0] vNewPipelineConnectPipe_1_g_io_out_bits_nextPcOffset;
  wire [4:0] vNewPipelineConnectPipe_1_i_io_out_bits_nextPcOffset;
  wire vNewPipelineConnectPipe_1_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_1_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_1_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_1_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_1_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_1_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_1_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_1_i_io_out_bits_rfWen;
  wire [49:0] vNewPipelineConnectPipe_1_g_io_out_bits_pc;
  wire [49:0] vNewPipelineConnectPipe_1_i_io_out_bits_pc;
  wire vNewPipelineConnectPipe_1_g_io_out_bits_ftqIdx_flag;
  wire vNewPipelineConnectPipe_1_i_io_out_bits_ftqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_1_g_io_out_bits_ftqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_1_i_io_out_bits_ftqIdx_value;
  wire [3:0] vNewPipelineConnectPipe_1_g_io_out_bits_ftqOffset;
  wire [3:0] vNewPipelineConnectPipe_1_i_io_out_bits_ftqOffset;
  wire [49:0] vNewPipelineConnectPipe_1_g_io_out_bits_predictInfo_target;
  wire [49:0] vNewPipelineConnectPipe_1_i_io_out_bits_predictInfo_target;
  wire vNewPipelineConnectPipe_1_g_io_out_bits_predictInfo_taken;
  wire vNewPipelineConnectPipe_1_i_io_out_bits_predictInfo_taken;
  wire [63:0] vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_1 u_g_NewPipelineConnectPipe_1 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_1_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_1_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_1_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_1_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_1_io_in_bits_src_1), .io_in_bits_imm(vNewPipelineConnectPipe_1_io_in_bits_imm), .io_in_bits_nextPcOffset(vNewPipelineConnectPipe_1_io_in_bits_nextPcOffset), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_1_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_1_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_1_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_1_io_in_bits_rfWen), .io_in_bits_pc(vNewPipelineConnectPipe_1_io_in_bits_pc), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_1_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_1_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_1_io_in_bits_ftqOffset), .io_in_bits_predictInfo_target(vNewPipelineConnectPipe_1_io_in_bits_predictInfo_target), .io_in_bits_predictInfo_taken(vNewPipelineConnectPipe_1_io_in_bits_predictInfo_taken), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_1_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_1_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_1_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_1_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_1_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_1_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_1_g_io_out_bits_src_1), .io_out_bits_imm(vNewPipelineConnectPipe_1_g_io_out_bits_imm), .io_out_bits_nextPcOffset(vNewPipelineConnectPipe_1_g_io_out_bits_nextPcOffset), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_1_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_1_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_1_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_1_g_io_out_bits_rfWen), .io_out_bits_pc(vNewPipelineConnectPipe_1_g_io_out_bits_pc), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_1_g_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_1_g_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_1_g_io_out_bits_ftqOffset), .io_out_bits_predictInfo_target(vNewPipelineConnectPipe_1_g_io_out_bits_predictInfo_target), .io_out_bits_predictInfo_taken(vNewPipelineConnectPipe_1_g_io_out_bits_predictInfo_taken), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_1_xs u_i_NewPipelineConnectPipe_1 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_1_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_1_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_1_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_1_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_1_io_in_bits_src_1), .io_in_bits_imm(vNewPipelineConnectPipe_1_io_in_bits_imm), .io_in_bits_nextPcOffset(vNewPipelineConnectPipe_1_io_in_bits_nextPcOffset), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_1_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_1_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_1_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_1_io_in_bits_rfWen), .io_in_bits_pc(vNewPipelineConnectPipe_1_io_in_bits_pc), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_1_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_1_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_1_io_in_bits_ftqOffset), .io_in_bits_predictInfo_target(vNewPipelineConnectPipe_1_io_in_bits_predictInfo_target), .io_in_bits_predictInfo_taken(vNewPipelineConnectPipe_1_io_in_bits_predictInfo_taken), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_1_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_1_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_1_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_1_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_1_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_1_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_1_i_io_out_bits_src_1), .io_out_bits_imm(vNewPipelineConnectPipe_1_i_io_out_bits_imm), .io_out_bits_nextPcOffset(vNewPipelineConnectPipe_1_i_io_out_bits_nextPcOffset), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_1_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_1_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_1_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_1_i_io_out_bits_rfWen), .io_out_bits_pc(vNewPipelineConnectPipe_1_i_io_out_bits_pc), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_1_i_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_1_i_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_1_i_io_out_bits_ftqOffset), .io_out_bits_predictInfo_target(vNewPipelineConnectPipe_1_i_io_out_bits_predictInfo_target), .io_out_bits_predictInfo_taken(vNewPipelineConnectPipe_1_i_io_out_bits_predictInfo_taken), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_1_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_1_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_1_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_1_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_1_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_in_bits_imm <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_in_bits_nextPcOffset <= 5'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_pc <= 50'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_in_bits_ftqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_ftqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_ftqOffset <= 4'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_predictInfo_target <= 50'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_in_bits_predictInfo_taken <= 1'($urandom);
      vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_1_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_1_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_1_g_io_out_valid !== vNewPipelineConnectPipe_1_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_valid, vNewPipelineConnectPipe_1_i_io_out_valid); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_fuType !== vNewPipelineConnectPipe_1_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_fuType, vNewPipelineConnectPipe_1_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_1_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_1_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_1_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_src_0, vNewPipelineConnectPipe_1_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_1_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_src_1, vNewPipelineConnectPipe_1_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_imm !== vNewPipelineConnectPipe_1_i_io_out_bits_imm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_imm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_imm, vNewPipelineConnectPipe_1_i_io_out_bits_imm); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_nextPcOffset !== vNewPipelineConnectPipe_1_i_io_out_bits_nextPcOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_nextPcOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_nextPcOffset, vNewPipelineConnectPipe_1_i_io_out_bits_nextPcOffset); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_1_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_1_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_1_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_1_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_pdest !== vNewPipelineConnectPipe_1_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_pdest, vNewPipelineConnectPipe_1_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_1_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_rfWen, vNewPipelineConnectPipe_1_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_pc !== vNewPipelineConnectPipe_1_i_io_out_bits_pc) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_pc mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_pc, vNewPipelineConnectPipe_1_i_io_out_bits_pc); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_ftqIdx_flag !== vNewPipelineConnectPipe_1_i_io_out_bits_ftqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_ftqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_ftqIdx_flag, vNewPipelineConnectPipe_1_i_io_out_bits_ftqIdx_flag); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_ftqIdx_value !== vNewPipelineConnectPipe_1_i_io_out_bits_ftqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_ftqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_ftqIdx_value, vNewPipelineConnectPipe_1_i_io_out_bits_ftqIdx_value); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_ftqOffset !== vNewPipelineConnectPipe_1_i_io_out_bits_ftqOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_ftqOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_ftqOffset, vNewPipelineConnectPipe_1_i_io_out_bits_ftqOffset); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_predictInfo_target !== vNewPipelineConnectPipe_1_i_io_out_bits_predictInfo_target) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_predictInfo_target mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_predictInfo_target, vNewPipelineConnectPipe_1_i_io_out_bits_predictInfo_target); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_predictInfo_taken !== vNewPipelineConnectPipe_1_i_io_out_bits_predictInfo_taken) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_predictInfo_taken mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_predictInfo_taken, vNewPipelineConnectPipe_1_i_io_out_bits_predictInfo_taken); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_1.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_1_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_1_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_5_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_5_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_5_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_5_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_5_io_in_bits_src_1;
  logic [63:0] vNewPipelineConnectPipe_5_io_in_bits_imm;
  logic [4:0] vNewPipelineConnectPipe_5_io_in_bits_nextPcOffset;
  logic vNewPipelineConnectPipe_5_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_5_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_5_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_5_io_in_bits_rfWen;
  logic vNewPipelineConnectPipe_5_io_in_bits_fpWen;
  logic vNewPipelineConnectPipe_5_io_in_bits_vecWen;
  logic vNewPipelineConnectPipe_5_io_in_bits_v0Wen;
  logic vNewPipelineConnectPipe_5_io_in_bits_vlWen;
  logic [1:0] vNewPipelineConnectPipe_5_io_in_bits_fpu_typeTagOut;
  logic vNewPipelineConnectPipe_5_io_in_bits_fpu_wflags;
  logic [1:0] vNewPipelineConnectPipe_5_io_in_bits_fpu_typ;
  logic [2:0] vNewPipelineConnectPipe_5_io_in_bits_fpu_rm;
  logic [49:0] vNewPipelineConnectPipe_5_io_in_bits_pc;
  logic vNewPipelineConnectPipe_5_io_in_bits_ftqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_5_io_in_bits_ftqIdx_value;
  logic [3:0] vNewPipelineConnectPipe_5_io_in_bits_ftqOffset;
  logic [49:0] vNewPipelineConnectPipe_5_io_in_bits_predictInfo_target;
  logic vNewPipelineConnectPipe_5_io_in_bits_predictInfo_taken;
  logic [63:0] vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_5_io_rightOutFire;
  logic vNewPipelineConnectPipe_5_io_isFlush;
  wire vNewPipelineConnectPipe_5_g_io_out_valid;
  wire vNewPipelineConnectPipe_5_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_5_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_5_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_5_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_5_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_5_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_5_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_5_g_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_5_i_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_5_g_io_out_bits_imm;
  wire [63:0] vNewPipelineConnectPipe_5_i_io_out_bits_imm;
  wire [4:0] vNewPipelineConnectPipe_5_g_io_out_bits_nextPcOffset;
  wire [4:0] vNewPipelineConnectPipe_5_i_io_out_bits_nextPcOffset;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_5_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_5_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_5_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_5_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_vlWen;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_vlWen;
  wire [1:0] vNewPipelineConnectPipe_5_g_io_out_bits_fpu_typeTagOut;
  wire [1:0] vNewPipelineConnectPipe_5_i_io_out_bits_fpu_typeTagOut;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_fpu_wflags;
  wire [1:0] vNewPipelineConnectPipe_5_g_io_out_bits_fpu_typ;
  wire [1:0] vNewPipelineConnectPipe_5_i_io_out_bits_fpu_typ;
  wire [2:0] vNewPipelineConnectPipe_5_g_io_out_bits_fpu_rm;
  wire [2:0] vNewPipelineConnectPipe_5_i_io_out_bits_fpu_rm;
  wire [49:0] vNewPipelineConnectPipe_5_g_io_out_bits_pc;
  wire [49:0] vNewPipelineConnectPipe_5_i_io_out_bits_pc;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_ftqIdx_flag;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_ftqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_5_g_io_out_bits_ftqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_5_i_io_out_bits_ftqIdx_value;
  wire [3:0] vNewPipelineConnectPipe_5_g_io_out_bits_ftqOffset;
  wire [3:0] vNewPipelineConnectPipe_5_i_io_out_bits_ftqOffset;
  wire [49:0] vNewPipelineConnectPipe_5_g_io_out_bits_predictInfo_target;
  wire [49:0] vNewPipelineConnectPipe_5_i_io_out_bits_predictInfo_target;
  wire vNewPipelineConnectPipe_5_g_io_out_bits_predictInfo_taken;
  wire vNewPipelineConnectPipe_5_i_io_out_bits_predictInfo_taken;
  wire [63:0] vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_5 u_g_NewPipelineConnectPipe_5 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_5_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_5_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_5_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_5_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_5_io_in_bits_src_1), .io_in_bits_imm(vNewPipelineConnectPipe_5_io_in_bits_imm), .io_in_bits_nextPcOffset(vNewPipelineConnectPipe_5_io_in_bits_nextPcOffset), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_5_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_5_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_5_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_5_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_5_io_in_bits_fpWen), .io_in_bits_vecWen(vNewPipelineConnectPipe_5_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_5_io_in_bits_v0Wen), .io_in_bits_vlWen(vNewPipelineConnectPipe_5_io_in_bits_vlWen), .io_in_bits_fpu_typeTagOut(vNewPipelineConnectPipe_5_io_in_bits_fpu_typeTagOut), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_5_io_in_bits_fpu_wflags), .io_in_bits_fpu_typ(vNewPipelineConnectPipe_5_io_in_bits_fpu_typ), .io_in_bits_fpu_rm(vNewPipelineConnectPipe_5_io_in_bits_fpu_rm), .io_in_bits_pc(vNewPipelineConnectPipe_5_io_in_bits_pc), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_5_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_5_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_5_io_in_bits_ftqOffset), .io_in_bits_predictInfo_target(vNewPipelineConnectPipe_5_io_in_bits_predictInfo_target), .io_in_bits_predictInfo_taken(vNewPipelineConnectPipe_5_io_in_bits_predictInfo_taken), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_5_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_5_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_5_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_5_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_5_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_5_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_5_g_io_out_bits_src_1), .io_out_bits_imm(vNewPipelineConnectPipe_5_g_io_out_bits_imm), .io_out_bits_nextPcOffset(vNewPipelineConnectPipe_5_g_io_out_bits_nextPcOffset), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_5_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_5_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_5_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_5_g_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_5_g_io_out_bits_fpWen), .io_out_bits_vecWen(vNewPipelineConnectPipe_5_g_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_5_g_io_out_bits_v0Wen), .io_out_bits_vlWen(vNewPipelineConnectPipe_5_g_io_out_bits_vlWen), .io_out_bits_fpu_typeTagOut(vNewPipelineConnectPipe_5_g_io_out_bits_fpu_typeTagOut), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_5_g_io_out_bits_fpu_wflags), .io_out_bits_fpu_typ(vNewPipelineConnectPipe_5_g_io_out_bits_fpu_typ), .io_out_bits_fpu_rm(vNewPipelineConnectPipe_5_g_io_out_bits_fpu_rm), .io_out_bits_pc(vNewPipelineConnectPipe_5_g_io_out_bits_pc), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_5_g_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_5_g_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_5_g_io_out_bits_ftqOffset), .io_out_bits_predictInfo_target(vNewPipelineConnectPipe_5_g_io_out_bits_predictInfo_target), .io_out_bits_predictInfo_taken(vNewPipelineConnectPipe_5_g_io_out_bits_predictInfo_taken), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_5_xs u_i_NewPipelineConnectPipe_5 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_5_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_5_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_5_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_5_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_5_io_in_bits_src_1), .io_in_bits_imm(vNewPipelineConnectPipe_5_io_in_bits_imm), .io_in_bits_nextPcOffset(vNewPipelineConnectPipe_5_io_in_bits_nextPcOffset), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_5_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_5_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_5_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_5_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_5_io_in_bits_fpWen), .io_in_bits_vecWen(vNewPipelineConnectPipe_5_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_5_io_in_bits_v0Wen), .io_in_bits_vlWen(vNewPipelineConnectPipe_5_io_in_bits_vlWen), .io_in_bits_fpu_typeTagOut(vNewPipelineConnectPipe_5_io_in_bits_fpu_typeTagOut), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_5_io_in_bits_fpu_wflags), .io_in_bits_fpu_typ(vNewPipelineConnectPipe_5_io_in_bits_fpu_typ), .io_in_bits_fpu_rm(vNewPipelineConnectPipe_5_io_in_bits_fpu_rm), .io_in_bits_pc(vNewPipelineConnectPipe_5_io_in_bits_pc), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_5_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_5_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_5_io_in_bits_ftqOffset), .io_in_bits_predictInfo_target(vNewPipelineConnectPipe_5_io_in_bits_predictInfo_target), .io_in_bits_predictInfo_taken(vNewPipelineConnectPipe_5_io_in_bits_predictInfo_taken), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_5_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_5_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_5_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_5_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_5_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_5_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_5_i_io_out_bits_src_1), .io_out_bits_imm(vNewPipelineConnectPipe_5_i_io_out_bits_imm), .io_out_bits_nextPcOffset(vNewPipelineConnectPipe_5_i_io_out_bits_nextPcOffset), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_5_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_5_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_5_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_5_i_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_5_i_io_out_bits_fpWen), .io_out_bits_vecWen(vNewPipelineConnectPipe_5_i_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_5_i_io_out_bits_v0Wen), .io_out_bits_vlWen(vNewPipelineConnectPipe_5_i_io_out_bits_vlWen), .io_out_bits_fpu_typeTagOut(vNewPipelineConnectPipe_5_i_io_out_bits_fpu_typeTagOut), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_5_i_io_out_bits_fpu_wflags), .io_out_bits_fpu_typ(vNewPipelineConnectPipe_5_i_io_out_bits_fpu_typ), .io_out_bits_fpu_rm(vNewPipelineConnectPipe_5_i_io_out_bits_fpu_rm), .io_out_bits_pc(vNewPipelineConnectPipe_5_i_io_out_bits_pc), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_5_i_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_5_i_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_5_i_io_out_bits_ftqOffset), .io_out_bits_predictInfo_target(vNewPipelineConnectPipe_5_i_io_out_bits_predictInfo_target), .io_out_bits_predictInfo_taken(vNewPipelineConnectPipe_5_i_io_out_bits_predictInfo_taken), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_5_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_5_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_5_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_5_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_5_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_in_bits_imm <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_in_bits_nextPcOffset <= 5'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_fpWen <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_vecWen <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_v0Wen <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_vlWen <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_fpu_typeTagOut <= 2'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_fpu_wflags <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_fpu_typ <= 2'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_fpu_rm <= 3'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_pc <= 50'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_in_bits_ftqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_ftqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_ftqOffset <= 4'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_predictInfo_target <= 50'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_in_bits_predictInfo_taken <= 1'($urandom);
      vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_5_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_5_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_5_g_io_out_valid !== vNewPipelineConnectPipe_5_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_valid, vNewPipelineConnectPipe_5_i_io_out_valid); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_fuType !== vNewPipelineConnectPipe_5_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_fuType, vNewPipelineConnectPipe_5_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_5_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_5_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_5_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_src_0, vNewPipelineConnectPipe_5_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_5_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_src_1, vNewPipelineConnectPipe_5_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_imm !== vNewPipelineConnectPipe_5_i_io_out_bits_imm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_imm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_imm, vNewPipelineConnectPipe_5_i_io_out_bits_imm); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_nextPcOffset !== vNewPipelineConnectPipe_5_i_io_out_bits_nextPcOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_nextPcOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_nextPcOffset, vNewPipelineConnectPipe_5_i_io_out_bits_nextPcOffset); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_5_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_5_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_5_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_5_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_pdest !== vNewPipelineConnectPipe_5_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_pdest, vNewPipelineConnectPipe_5_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_5_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_rfWen, vNewPipelineConnectPipe_5_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_fpWen !== vNewPipelineConnectPipe_5_i_io_out_bits_fpWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_fpWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_fpWen, vNewPipelineConnectPipe_5_i_io_out_bits_fpWen); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_vecWen !== vNewPipelineConnectPipe_5_i_io_out_bits_vecWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_vecWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_vecWen, vNewPipelineConnectPipe_5_i_io_out_bits_vecWen); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_v0Wen !== vNewPipelineConnectPipe_5_i_io_out_bits_v0Wen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_v0Wen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_v0Wen, vNewPipelineConnectPipe_5_i_io_out_bits_v0Wen); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_vlWen !== vNewPipelineConnectPipe_5_i_io_out_bits_vlWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_vlWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_vlWen, vNewPipelineConnectPipe_5_i_io_out_bits_vlWen); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_fpu_typeTagOut !== vNewPipelineConnectPipe_5_i_io_out_bits_fpu_typeTagOut) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_fpu_typeTagOut mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_fpu_typeTagOut, vNewPipelineConnectPipe_5_i_io_out_bits_fpu_typeTagOut); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_fpu_wflags !== vNewPipelineConnectPipe_5_i_io_out_bits_fpu_wflags) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_fpu_wflags mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_fpu_wflags, vNewPipelineConnectPipe_5_i_io_out_bits_fpu_wflags); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_fpu_typ !== vNewPipelineConnectPipe_5_i_io_out_bits_fpu_typ) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_fpu_typ mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_fpu_typ, vNewPipelineConnectPipe_5_i_io_out_bits_fpu_typ); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_fpu_rm !== vNewPipelineConnectPipe_5_i_io_out_bits_fpu_rm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_fpu_rm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_fpu_rm, vNewPipelineConnectPipe_5_i_io_out_bits_fpu_rm); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_pc !== vNewPipelineConnectPipe_5_i_io_out_bits_pc) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_pc mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_pc, vNewPipelineConnectPipe_5_i_io_out_bits_pc); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_ftqIdx_flag !== vNewPipelineConnectPipe_5_i_io_out_bits_ftqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_ftqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_ftqIdx_flag, vNewPipelineConnectPipe_5_i_io_out_bits_ftqIdx_flag); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_ftqIdx_value !== vNewPipelineConnectPipe_5_i_io_out_bits_ftqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_ftqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_ftqIdx_value, vNewPipelineConnectPipe_5_i_io_out_bits_ftqIdx_value); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_ftqOffset !== vNewPipelineConnectPipe_5_i_io_out_bits_ftqOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_ftqOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_ftqOffset, vNewPipelineConnectPipe_5_i_io_out_bits_ftqOffset); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_predictInfo_target !== vNewPipelineConnectPipe_5_i_io_out_bits_predictInfo_target) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_predictInfo_target mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_predictInfo_target, vNewPipelineConnectPipe_5_i_io_out_bits_predictInfo_target); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_predictInfo_taken !== vNewPipelineConnectPipe_5_i_io_out_bits_predictInfo_taken) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_predictInfo_taken mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_predictInfo_taken, vNewPipelineConnectPipe_5_i_io_out_bits_predictInfo_taken); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_5.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_5_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_5_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_7_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_7_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_7_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_7_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_7_io_in_bits_src_1;
  logic [63:0] vNewPipelineConnectPipe_7_io_in_bits_imm;
  logic vNewPipelineConnectPipe_7_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_7_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_7_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_7_io_in_bits_rfWen;
  logic vNewPipelineConnectPipe_7_io_in_bits_flushPipe;
  logic vNewPipelineConnectPipe_7_io_in_bits_ftqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_7_io_in_bits_ftqIdx_value;
  logic [3:0] vNewPipelineConnectPipe_7_io_in_bits_ftqOffset;
  logic [63:0] vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_7_io_out_ready;
  logic vNewPipelineConnectPipe_7_io_rightOutFire;
  logic vNewPipelineConnectPipe_7_io_isFlush;
  wire vNewPipelineConnectPipe_7_g_io_in_ready;
  wire vNewPipelineConnectPipe_7_i_io_in_ready;
  wire vNewPipelineConnectPipe_7_g_io_out_valid;
  wire vNewPipelineConnectPipe_7_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_7_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_7_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_7_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_7_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_7_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_7_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_7_g_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_7_i_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_7_g_io_out_bits_imm;
  wire [63:0] vNewPipelineConnectPipe_7_i_io_out_bits_imm;
  wire vNewPipelineConnectPipe_7_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_7_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_7_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_7_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_7_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_7_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_7_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_7_i_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_7_g_io_out_bits_flushPipe;
  wire vNewPipelineConnectPipe_7_i_io_out_bits_flushPipe;
  wire vNewPipelineConnectPipe_7_g_io_out_bits_ftqIdx_flag;
  wire vNewPipelineConnectPipe_7_i_io_out_bits_ftqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_7_g_io_out_bits_ftqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_7_i_io_out_bits_ftqIdx_value;
  wire [3:0] vNewPipelineConnectPipe_7_g_io_out_bits_ftqOffset;
  wire [3:0] vNewPipelineConnectPipe_7_i_io_out_bits_ftqOffset;
  wire [63:0] vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_7 u_g_NewPipelineConnectPipe_7 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_7_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_7_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_7_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_7_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_7_io_in_bits_src_1), .io_in_bits_imm(vNewPipelineConnectPipe_7_io_in_bits_imm), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_7_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_7_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_7_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_7_io_in_bits_rfWen), .io_in_bits_flushPipe(vNewPipelineConnectPipe_7_io_in_bits_flushPipe), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_7_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_7_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_7_io_in_bits_ftqOffset), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_7_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_7_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_7_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_7_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_7_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_7_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_7_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_7_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_7_g_io_out_bits_src_1), .io_out_bits_imm(vNewPipelineConnectPipe_7_g_io_out_bits_imm), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_7_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_7_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_7_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_7_g_io_out_bits_rfWen), .io_out_bits_flushPipe(vNewPipelineConnectPipe_7_g_io_out_bits_flushPipe), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_7_g_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_7_g_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_7_g_io_out_bits_ftqOffset), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_7_xs u_i_NewPipelineConnectPipe_7 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_7_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_7_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_7_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_7_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_7_io_in_bits_src_1), .io_in_bits_imm(vNewPipelineConnectPipe_7_io_in_bits_imm), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_7_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_7_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_7_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_7_io_in_bits_rfWen), .io_in_bits_flushPipe(vNewPipelineConnectPipe_7_io_in_bits_flushPipe), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_7_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_7_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_7_io_in_bits_ftqOffset), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_7_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_7_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_7_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_7_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_7_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_7_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_7_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_7_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_7_i_io_out_bits_src_1), .io_out_bits_imm(vNewPipelineConnectPipe_7_i_io_out_bits_imm), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_7_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_7_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_7_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_7_i_io_out_bits_rfWen), .io_out_bits_flushPipe(vNewPipelineConnectPipe_7_i_io_out_bits_flushPipe), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_7_i_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_7_i_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_7_i_io_out_bits_ftqOffset), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_7_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_7_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_7_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_7_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_7_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_7_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_7_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_7_io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_7_io_in_bits_imm <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_7_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_flushPipe <= 1'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_ftqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_ftqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_ftqOffset <= 4'($urandom);
      vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_7_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_7_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_7_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_7_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_7_g_io_in_ready !== vNewPipelineConnectPipe_7_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_in_ready, vNewPipelineConnectPipe_7_i_io_in_ready); end
    if (vNewPipelineConnectPipe_7_g_io_out_valid !== vNewPipelineConnectPipe_7_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_valid, vNewPipelineConnectPipe_7_i_io_out_valid); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_fuType !== vNewPipelineConnectPipe_7_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_fuType, vNewPipelineConnectPipe_7_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_7_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_7_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_7_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_src_0, vNewPipelineConnectPipe_7_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_7_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_src_1, vNewPipelineConnectPipe_7_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_imm !== vNewPipelineConnectPipe_7_i_io_out_bits_imm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_imm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_imm, vNewPipelineConnectPipe_7_i_io_out_bits_imm); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_7_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_7_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_7_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_7_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_pdest !== vNewPipelineConnectPipe_7_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_pdest, vNewPipelineConnectPipe_7_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_7_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_rfWen, vNewPipelineConnectPipe_7_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_flushPipe !== vNewPipelineConnectPipe_7_i_io_out_bits_flushPipe) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_flushPipe mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_flushPipe, vNewPipelineConnectPipe_7_i_io_out_bits_flushPipe); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_ftqIdx_flag !== vNewPipelineConnectPipe_7_i_io_out_bits_ftqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_ftqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_ftqIdx_flag, vNewPipelineConnectPipe_7_i_io_out_bits_ftqIdx_flag); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_ftqIdx_value !== vNewPipelineConnectPipe_7_i_io_out_bits_ftqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_ftqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_ftqIdx_value, vNewPipelineConnectPipe_7_i_io_out_bits_ftqIdx_value); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_ftqOffset !== vNewPipelineConnectPipe_7_i_io_out_bits_ftqOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_ftqOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_ftqOffset, vNewPipelineConnectPipe_7_i_io_out_bits_ftqOffset); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_7.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_7_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_7_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_8_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_8_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_8_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_8_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_8_io_in_bits_src_1;
  logic [63:0] vNewPipelineConnectPipe_8_io_in_bits_src_2;
  logic vNewPipelineConnectPipe_8_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_8_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_8_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_8_io_in_bits_rfWen;
  logic vNewPipelineConnectPipe_8_io_in_bits_fpWen;
  logic vNewPipelineConnectPipe_8_io_in_bits_vecWen;
  logic vNewPipelineConnectPipe_8_io_in_bits_v0Wen;
  logic vNewPipelineConnectPipe_8_io_in_bits_fpu_wflags;
  logic [1:0] vNewPipelineConnectPipe_8_io_in_bits_fpu_fmt;
  logic [2:0] vNewPipelineConnectPipe_8_io_in_bits_fpu_rm;
  logic [63:0] vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_8_io_rightOutFire;
  logic vNewPipelineConnectPipe_8_io_isFlush;
  wire vNewPipelineConnectPipe_8_g_io_out_valid;
  wire vNewPipelineConnectPipe_8_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_8_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_8_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_8_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_8_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_8_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_8_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_8_g_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_8_i_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_8_g_io_out_bits_src_2;
  wire [63:0] vNewPipelineConnectPipe_8_i_io_out_bits_src_2;
  wire vNewPipelineConnectPipe_8_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_8_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_8_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_8_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_8_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_8_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_8_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_8_i_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_8_g_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_8_i_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_8_g_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_8_i_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_8_g_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_8_i_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_8_g_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_8_i_io_out_bits_fpu_wflags;
  wire [1:0] vNewPipelineConnectPipe_8_g_io_out_bits_fpu_fmt;
  wire [1:0] vNewPipelineConnectPipe_8_i_io_out_bits_fpu_fmt;
  wire [2:0] vNewPipelineConnectPipe_8_g_io_out_bits_fpu_rm;
  wire [2:0] vNewPipelineConnectPipe_8_i_io_out_bits_fpu_rm;
  wire [63:0] vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_8 u_g_NewPipelineConnectPipe_8 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_8_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_8_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_8_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_8_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_8_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_8_io_in_bits_src_2), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_8_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_8_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_8_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_8_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_8_io_in_bits_fpWen), .io_in_bits_vecWen(vNewPipelineConnectPipe_8_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_8_io_in_bits_v0Wen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_8_io_in_bits_fpu_wflags), .io_in_bits_fpu_fmt(vNewPipelineConnectPipe_8_io_in_bits_fpu_fmt), .io_in_bits_fpu_rm(vNewPipelineConnectPipe_8_io_in_bits_fpu_rm), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_8_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_8_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_8_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_8_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_8_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_8_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_8_g_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_8_g_io_out_bits_src_2), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_8_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_8_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_8_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_8_g_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_8_g_io_out_bits_fpWen), .io_out_bits_vecWen(vNewPipelineConnectPipe_8_g_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_8_g_io_out_bits_v0Wen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_8_g_io_out_bits_fpu_wflags), .io_out_bits_fpu_fmt(vNewPipelineConnectPipe_8_g_io_out_bits_fpu_fmt), .io_out_bits_fpu_rm(vNewPipelineConnectPipe_8_g_io_out_bits_fpu_rm), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_8_xs u_i_NewPipelineConnectPipe_8 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_8_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_8_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_8_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_8_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_8_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_8_io_in_bits_src_2), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_8_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_8_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_8_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_8_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_8_io_in_bits_fpWen), .io_in_bits_vecWen(vNewPipelineConnectPipe_8_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_8_io_in_bits_v0Wen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_8_io_in_bits_fpu_wflags), .io_in_bits_fpu_fmt(vNewPipelineConnectPipe_8_io_in_bits_fpu_fmt), .io_in_bits_fpu_rm(vNewPipelineConnectPipe_8_io_in_bits_fpu_rm), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_8_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_8_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_8_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_8_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_8_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_8_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_8_i_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_8_i_io_out_bits_src_2), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_8_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_8_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_8_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_8_i_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_8_i_io_out_bits_fpWen), .io_out_bits_vecWen(vNewPipelineConnectPipe_8_i_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_8_i_io_out_bits_v0Wen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_8_i_io_out_bits_fpu_wflags), .io_out_bits_fpu_fmt(vNewPipelineConnectPipe_8_i_io_out_bits_fpu_fmt), .io_out_bits_fpu_rm(vNewPipelineConnectPipe_8_i_io_out_bits_fpu_rm), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_8_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_8_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_8_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_8_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_8_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_8_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_8_io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_8_io_in_bits_src_2 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_8_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_fpWen <= 1'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_vecWen <= 1'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_v0Wen <= 1'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_fpu_wflags <= 1'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_fpu_fmt <= 2'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_fpu_rm <= 3'($urandom);
      vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_8_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_8_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_8_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_8_g_io_out_valid !== vNewPipelineConnectPipe_8_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_valid, vNewPipelineConnectPipe_8_i_io_out_valid); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_fuType !== vNewPipelineConnectPipe_8_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_fuType, vNewPipelineConnectPipe_8_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_8_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_8_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_8_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_src_0, vNewPipelineConnectPipe_8_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_8_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_src_1, vNewPipelineConnectPipe_8_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_src_2 !== vNewPipelineConnectPipe_8_i_io_out_bits_src_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_src_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_src_2, vNewPipelineConnectPipe_8_i_io_out_bits_src_2); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_8_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_8_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_8_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_8_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_pdest !== vNewPipelineConnectPipe_8_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_pdest, vNewPipelineConnectPipe_8_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_8_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_rfWen, vNewPipelineConnectPipe_8_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_fpWen !== vNewPipelineConnectPipe_8_i_io_out_bits_fpWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_fpWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_fpWen, vNewPipelineConnectPipe_8_i_io_out_bits_fpWen); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_vecWen !== vNewPipelineConnectPipe_8_i_io_out_bits_vecWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_vecWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_vecWen, vNewPipelineConnectPipe_8_i_io_out_bits_vecWen); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_v0Wen !== vNewPipelineConnectPipe_8_i_io_out_bits_v0Wen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_v0Wen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_v0Wen, vNewPipelineConnectPipe_8_i_io_out_bits_v0Wen); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_fpu_wflags !== vNewPipelineConnectPipe_8_i_io_out_bits_fpu_wflags) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_fpu_wflags mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_fpu_wflags, vNewPipelineConnectPipe_8_i_io_out_bits_fpu_wflags); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_fpu_fmt !== vNewPipelineConnectPipe_8_i_io_out_bits_fpu_fmt) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_fpu_fmt mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_fpu_fmt, vNewPipelineConnectPipe_8_i_io_out_bits_fpu_fmt); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_fpu_rm !== vNewPipelineConnectPipe_8_i_io_out_bits_fpu_rm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_fpu_rm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_fpu_rm, vNewPipelineConnectPipe_8_i_io_out_bits_fpu_rm); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_8.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_8_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_8_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_9_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_9_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_9_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_9_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_9_io_in_bits_src_1;
  logic vNewPipelineConnectPipe_9_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_9_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_9_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_9_io_in_bits_fpWen;
  logic vNewPipelineConnectPipe_9_io_in_bits_fpu_wflags;
  logic [1:0] vNewPipelineConnectPipe_9_io_in_bits_fpu_fmt;
  logic [2:0] vNewPipelineConnectPipe_9_io_in_bits_fpu_rm;
  logic [63:0] vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_9_io_out_ready;
  logic vNewPipelineConnectPipe_9_io_rightOutFire;
  logic vNewPipelineConnectPipe_9_io_isFlush;
  wire vNewPipelineConnectPipe_9_g_io_in_ready;
  wire vNewPipelineConnectPipe_9_i_io_in_ready;
  wire vNewPipelineConnectPipe_9_g_io_out_valid;
  wire vNewPipelineConnectPipe_9_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_9_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_9_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_9_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_9_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_9_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_9_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_9_g_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_9_i_io_out_bits_src_1;
  wire vNewPipelineConnectPipe_9_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_9_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_9_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_9_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_9_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_9_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_9_g_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_9_i_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_9_g_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_9_i_io_out_bits_fpu_wflags;
  wire [1:0] vNewPipelineConnectPipe_9_g_io_out_bits_fpu_fmt;
  wire [1:0] vNewPipelineConnectPipe_9_i_io_out_bits_fpu_fmt;
  wire [2:0] vNewPipelineConnectPipe_9_g_io_out_bits_fpu_rm;
  wire [2:0] vNewPipelineConnectPipe_9_i_io_out_bits_fpu_rm;
  wire [63:0] vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_9 u_g_NewPipelineConnectPipe_9 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_9_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_9_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_9_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_9_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_9_io_in_bits_src_1), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_9_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_9_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_9_io_in_bits_pdest), .io_in_bits_fpWen(vNewPipelineConnectPipe_9_io_in_bits_fpWen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_9_io_in_bits_fpu_wflags), .io_in_bits_fpu_fmt(vNewPipelineConnectPipe_9_io_in_bits_fpu_fmt), .io_in_bits_fpu_rm(vNewPipelineConnectPipe_9_io_in_bits_fpu_rm), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_9_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_9_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_9_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_9_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_9_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_9_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_9_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_9_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_9_g_io_out_bits_src_1), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_9_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_9_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_9_g_io_out_bits_pdest), .io_out_bits_fpWen(vNewPipelineConnectPipe_9_g_io_out_bits_fpWen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_9_g_io_out_bits_fpu_wflags), .io_out_bits_fpu_fmt(vNewPipelineConnectPipe_9_g_io_out_bits_fpu_fmt), .io_out_bits_fpu_rm(vNewPipelineConnectPipe_9_g_io_out_bits_fpu_rm), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_9_xs u_i_NewPipelineConnectPipe_9 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_9_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_9_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_9_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_9_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_9_io_in_bits_src_1), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_9_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_9_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_9_io_in_bits_pdest), .io_in_bits_fpWen(vNewPipelineConnectPipe_9_io_in_bits_fpWen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_9_io_in_bits_fpu_wflags), .io_in_bits_fpu_fmt(vNewPipelineConnectPipe_9_io_in_bits_fpu_fmt), .io_in_bits_fpu_rm(vNewPipelineConnectPipe_9_io_in_bits_fpu_rm), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_9_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_9_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_9_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_9_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_9_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_9_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_9_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_9_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_9_i_io_out_bits_src_1), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_9_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_9_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_9_i_io_out_bits_pdest), .io_out_bits_fpWen(vNewPipelineConnectPipe_9_i_io_out_bits_fpWen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_9_i_io_out_bits_fpu_wflags), .io_out_bits_fpu_fmt(vNewPipelineConnectPipe_9_i_io_out_bits_fpu_fmt), .io_out_bits_fpu_rm(vNewPipelineConnectPipe_9_i_io_out_bits_fpu_rm), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_9_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_9_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_9_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_9_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_9_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_9_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_9_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_9_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_9_io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_9_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_9_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_9_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_9_io_in_bits_fpWen <= 1'($urandom);
      vNewPipelineConnectPipe_9_io_in_bits_fpu_wflags <= 1'($urandom);
      vNewPipelineConnectPipe_9_io_in_bits_fpu_fmt <= 2'($urandom);
      vNewPipelineConnectPipe_9_io_in_bits_fpu_rm <= 3'($urandom);
      vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_9_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_9_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_9_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_9_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_9_g_io_in_ready !== vNewPipelineConnectPipe_9_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_in_ready, vNewPipelineConnectPipe_9_i_io_in_ready); end
    if (vNewPipelineConnectPipe_9_g_io_out_valid !== vNewPipelineConnectPipe_9_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_valid, vNewPipelineConnectPipe_9_i_io_out_valid); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_fuType !== vNewPipelineConnectPipe_9_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_fuType, vNewPipelineConnectPipe_9_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_9_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_9_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_9_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_src_0, vNewPipelineConnectPipe_9_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_9_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_src_1, vNewPipelineConnectPipe_9_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_9_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_9_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_9_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_9_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_pdest !== vNewPipelineConnectPipe_9_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_pdest, vNewPipelineConnectPipe_9_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_fpWen !== vNewPipelineConnectPipe_9_i_io_out_bits_fpWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_fpWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_fpWen, vNewPipelineConnectPipe_9_i_io_out_bits_fpWen); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_fpu_wflags !== vNewPipelineConnectPipe_9_i_io_out_bits_fpu_wflags) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_fpu_wflags mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_fpu_wflags, vNewPipelineConnectPipe_9_i_io_out_bits_fpu_wflags); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_fpu_fmt !== vNewPipelineConnectPipe_9_i_io_out_bits_fpu_fmt) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_fpu_fmt mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_fpu_fmt, vNewPipelineConnectPipe_9_i_io_out_bits_fpu_fmt); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_fpu_rm !== vNewPipelineConnectPipe_9_i_io_out_bits_fpu_rm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_fpu_rm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_fpu_rm, vNewPipelineConnectPipe_9_i_io_out_bits_fpu_rm); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_9.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_9_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_9_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_10_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_10_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_10_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_10_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_10_io_in_bits_src_1;
  logic [63:0] vNewPipelineConnectPipe_10_io_in_bits_src_2;
  logic vNewPipelineConnectPipe_10_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_10_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_10_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_10_io_in_bits_rfWen;
  logic vNewPipelineConnectPipe_10_io_in_bits_fpWen;
  logic vNewPipelineConnectPipe_10_io_in_bits_fpu_wflags;
  logic [1:0] vNewPipelineConnectPipe_10_io_in_bits_fpu_fmt;
  logic [2:0] vNewPipelineConnectPipe_10_io_in_bits_fpu_rm;
  logic [63:0] vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_10_io_rightOutFire;
  logic vNewPipelineConnectPipe_10_io_isFlush;
  wire vNewPipelineConnectPipe_10_g_io_out_valid;
  wire vNewPipelineConnectPipe_10_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_10_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_10_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_10_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_10_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_10_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_10_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_10_g_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_10_i_io_out_bits_src_1;
  wire [63:0] vNewPipelineConnectPipe_10_g_io_out_bits_src_2;
  wire [63:0] vNewPipelineConnectPipe_10_i_io_out_bits_src_2;
  wire vNewPipelineConnectPipe_10_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_10_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_10_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_10_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_10_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_10_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_10_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_10_i_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_10_g_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_10_i_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_10_g_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_10_i_io_out_bits_fpu_wflags;
  wire [1:0] vNewPipelineConnectPipe_10_g_io_out_bits_fpu_fmt;
  wire [1:0] vNewPipelineConnectPipe_10_i_io_out_bits_fpu_fmt;
  wire [2:0] vNewPipelineConnectPipe_10_g_io_out_bits_fpu_rm;
  wire [2:0] vNewPipelineConnectPipe_10_i_io_out_bits_fpu_rm;
  wire [63:0] vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_10 u_g_NewPipelineConnectPipe_10 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_10_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_10_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_10_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_10_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_10_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_10_io_in_bits_src_2), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_10_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_10_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_10_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_10_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_10_io_in_bits_fpWen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_10_io_in_bits_fpu_wflags), .io_in_bits_fpu_fmt(vNewPipelineConnectPipe_10_io_in_bits_fpu_fmt), .io_in_bits_fpu_rm(vNewPipelineConnectPipe_10_io_in_bits_fpu_rm), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_10_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_10_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_10_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_10_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_10_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_10_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_10_g_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_10_g_io_out_bits_src_2), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_10_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_10_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_10_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_10_g_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_10_g_io_out_bits_fpWen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_10_g_io_out_bits_fpu_wflags), .io_out_bits_fpu_fmt(vNewPipelineConnectPipe_10_g_io_out_bits_fpu_fmt), .io_out_bits_fpu_rm(vNewPipelineConnectPipe_10_g_io_out_bits_fpu_rm), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_10_xs u_i_NewPipelineConnectPipe_10 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_10_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_10_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_10_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_10_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_10_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_10_io_in_bits_src_2), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_10_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_10_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_10_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_10_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_10_io_in_bits_fpWen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_10_io_in_bits_fpu_wflags), .io_in_bits_fpu_fmt(vNewPipelineConnectPipe_10_io_in_bits_fpu_fmt), .io_in_bits_fpu_rm(vNewPipelineConnectPipe_10_io_in_bits_fpu_rm), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_10_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_10_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_10_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_10_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_10_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_10_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_10_i_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_10_i_io_out_bits_src_2), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_10_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_10_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_10_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_10_i_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_10_i_io_out_bits_fpWen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_10_i_io_out_bits_fpu_wflags), .io_out_bits_fpu_fmt(vNewPipelineConnectPipe_10_i_io_out_bits_fpu_fmt), .io_out_bits_fpu_rm(vNewPipelineConnectPipe_10_i_io_out_bits_fpu_rm), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_10_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_10_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_10_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_10_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_10_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_10_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_10_io_in_bits_src_1 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_10_io_in_bits_src_2 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_10_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_fpWen <= 1'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_fpu_wflags <= 1'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_fpu_fmt <= 2'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_fpu_rm <= 3'($urandom);
      vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_10_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_10_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_10_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_10_g_io_out_valid !== vNewPipelineConnectPipe_10_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_valid, vNewPipelineConnectPipe_10_i_io_out_valid); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_fuType !== vNewPipelineConnectPipe_10_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_fuType, vNewPipelineConnectPipe_10_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_10_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_10_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_10_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_src_0, vNewPipelineConnectPipe_10_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_10_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_src_1, vNewPipelineConnectPipe_10_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_src_2 !== vNewPipelineConnectPipe_10_i_io_out_bits_src_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_src_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_src_2, vNewPipelineConnectPipe_10_i_io_out_bits_src_2); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_10_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_10_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_10_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_10_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_pdest !== vNewPipelineConnectPipe_10_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_pdest, vNewPipelineConnectPipe_10_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_10_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_rfWen, vNewPipelineConnectPipe_10_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_fpWen !== vNewPipelineConnectPipe_10_i_io_out_bits_fpWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_fpWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_fpWen, vNewPipelineConnectPipe_10_i_io_out_bits_fpWen); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_fpu_wflags !== vNewPipelineConnectPipe_10_i_io_out_bits_fpu_wflags) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_fpu_wflags mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_fpu_wflags, vNewPipelineConnectPipe_10_i_io_out_bits_fpu_wflags); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_fpu_fmt !== vNewPipelineConnectPipe_10_i_io_out_bits_fpu_fmt) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_fpu_fmt mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_fpu_fmt, vNewPipelineConnectPipe_10_i_io_out_bits_fpu_fmt); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_fpu_rm !== vNewPipelineConnectPipe_10_i_io_out_bits_fpu_rm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_fpu_rm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_fpu_rm, vNewPipelineConnectPipe_10_i_io_out_bits_fpu_rm); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_10.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_10_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_10_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_13_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_13_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_13_io_in_bits_fuOpType;
  logic [127:0] vNewPipelineConnectPipe_13_io_in_bits_src_0;
  logic [127:0] vNewPipelineConnectPipe_13_io_in_bits_src_1;
  logic [127:0] vNewPipelineConnectPipe_13_io_in_bits_src_2;
  logic [127:0] vNewPipelineConnectPipe_13_io_in_bits_src_3;
  logic [127:0] vNewPipelineConnectPipe_13_io_in_bits_src_4;
  logic vNewPipelineConnectPipe_13_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_13_io_in_bits_robIdx_value;
  logic [6:0] vNewPipelineConnectPipe_13_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_13_io_in_bits_vecWen;
  logic vNewPipelineConnectPipe_13_io_in_bits_v0Wen;
  logic vNewPipelineConnectPipe_13_io_in_bits_fpu_wflags;
  logic vNewPipelineConnectPipe_13_io_in_bits_vpu_vma;
  logic vNewPipelineConnectPipe_13_io_in_bits_vpu_vta;
  logic [1:0] vNewPipelineConnectPipe_13_io_in_bits_vpu_vsew;
  logic [2:0] vNewPipelineConnectPipe_13_io_in_bits_vpu_vlmul;
  logic vNewPipelineConnectPipe_13_io_in_bits_vpu_vm;
  logic [7:0] vNewPipelineConnectPipe_13_io_in_bits_vpu_vstart;
  logic [6:0] vNewPipelineConnectPipe_13_io_in_bits_vpu_vuopIdx;
  logic vNewPipelineConnectPipe_13_io_in_bits_vpu_isExt;
  logic vNewPipelineConnectPipe_13_io_in_bits_vpu_isNarrow;
  logic vNewPipelineConnectPipe_13_io_in_bits_vpu_isDstMask;
  logic vNewPipelineConnectPipe_13_io_in_bits_vpu_isOpMask;
  logic [63:0] vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_13_io_out_ready;
  logic vNewPipelineConnectPipe_13_io_rightOutFire;
  logic vNewPipelineConnectPipe_13_io_isFlush;
  wire vNewPipelineConnectPipe_13_g_io_in_ready;
  wire vNewPipelineConnectPipe_13_i_io_in_ready;
  wire vNewPipelineConnectPipe_13_g_io_out_valid;
  wire vNewPipelineConnectPipe_13_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_13_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_13_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_13_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_13_i_io_out_bits_fuOpType;
  wire [127:0] vNewPipelineConnectPipe_13_g_io_out_bits_src_0;
  wire [127:0] vNewPipelineConnectPipe_13_i_io_out_bits_src_0;
  wire [127:0] vNewPipelineConnectPipe_13_g_io_out_bits_src_1;
  wire [127:0] vNewPipelineConnectPipe_13_i_io_out_bits_src_1;
  wire [127:0] vNewPipelineConnectPipe_13_g_io_out_bits_src_2;
  wire [127:0] vNewPipelineConnectPipe_13_i_io_out_bits_src_2;
  wire [127:0] vNewPipelineConnectPipe_13_g_io_out_bits_src_3;
  wire [127:0] vNewPipelineConnectPipe_13_i_io_out_bits_src_3;
  wire [127:0] vNewPipelineConnectPipe_13_g_io_out_bits_src_4;
  wire [127:0] vNewPipelineConnectPipe_13_i_io_out_bits_src_4;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_13_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_13_i_io_out_bits_robIdx_value;
  wire [6:0] vNewPipelineConnectPipe_13_g_io_out_bits_pdest;
  wire [6:0] vNewPipelineConnectPipe_13_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vma;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vma;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vta;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vta;
  wire [1:0] vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vsew;
  wire [1:0] vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vsew;
  wire [2:0] vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vlmul;
  wire [2:0] vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vlmul;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vm;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vm;
  wire [7:0] vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vstart;
  wire [7:0] vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vstart;
  wire [6:0] vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vuopIdx;
  wire [6:0] vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vuopIdx;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isExt;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isExt;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isNarrow;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isNarrow;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isDstMask;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isDstMask;
  wire vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isOpMask;
  wire vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isOpMask;
  wire [63:0] vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_13 u_g_NewPipelineConnectPipe_13 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_13_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_13_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_13_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_13_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_13_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_13_io_in_bits_src_2), .io_in_bits_src_3(vNewPipelineConnectPipe_13_io_in_bits_src_3), .io_in_bits_src_4(vNewPipelineConnectPipe_13_io_in_bits_src_4), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_13_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_13_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_13_io_in_bits_pdest), .io_in_bits_vecWen(vNewPipelineConnectPipe_13_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_13_io_in_bits_v0Wen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_13_io_in_bits_fpu_wflags), .io_in_bits_vpu_vma(vNewPipelineConnectPipe_13_io_in_bits_vpu_vma), .io_in_bits_vpu_vta(vNewPipelineConnectPipe_13_io_in_bits_vpu_vta), .io_in_bits_vpu_vsew(vNewPipelineConnectPipe_13_io_in_bits_vpu_vsew), .io_in_bits_vpu_vlmul(vNewPipelineConnectPipe_13_io_in_bits_vpu_vlmul), .io_in_bits_vpu_vm(vNewPipelineConnectPipe_13_io_in_bits_vpu_vm), .io_in_bits_vpu_vstart(vNewPipelineConnectPipe_13_io_in_bits_vpu_vstart), .io_in_bits_vpu_vuopIdx(vNewPipelineConnectPipe_13_io_in_bits_vpu_vuopIdx), .io_in_bits_vpu_isExt(vNewPipelineConnectPipe_13_io_in_bits_vpu_isExt), .io_in_bits_vpu_isNarrow(vNewPipelineConnectPipe_13_io_in_bits_vpu_isNarrow), .io_in_bits_vpu_isDstMask(vNewPipelineConnectPipe_13_io_in_bits_vpu_isDstMask), .io_in_bits_vpu_isOpMask(vNewPipelineConnectPipe_13_io_in_bits_vpu_isOpMask), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_13_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_13_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_13_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_13_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_13_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_13_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_13_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_13_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_13_g_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_13_g_io_out_bits_src_2), .io_out_bits_src_3(vNewPipelineConnectPipe_13_g_io_out_bits_src_3), .io_out_bits_src_4(vNewPipelineConnectPipe_13_g_io_out_bits_src_4), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_13_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_13_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_13_g_io_out_bits_pdest), .io_out_bits_vecWen(vNewPipelineConnectPipe_13_g_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_13_g_io_out_bits_v0Wen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_13_g_io_out_bits_fpu_wflags), .io_out_bits_vpu_vma(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vma), .io_out_bits_vpu_vta(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vta), .io_out_bits_vpu_vsew(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vsew), .io_out_bits_vpu_vlmul(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vlmul), .io_out_bits_vpu_vm(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vm), .io_out_bits_vpu_vstart(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vstart), .io_out_bits_vpu_vuopIdx(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vuopIdx), .io_out_bits_vpu_isExt(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isExt), .io_out_bits_vpu_isNarrow(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isNarrow), .io_out_bits_vpu_isDstMask(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isDstMask), .io_out_bits_vpu_isOpMask(vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isOpMask), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_13_xs u_i_NewPipelineConnectPipe_13 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_13_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_13_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_13_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_13_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_13_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_13_io_in_bits_src_2), .io_in_bits_src_3(vNewPipelineConnectPipe_13_io_in_bits_src_3), .io_in_bits_src_4(vNewPipelineConnectPipe_13_io_in_bits_src_4), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_13_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_13_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_13_io_in_bits_pdest), .io_in_bits_vecWen(vNewPipelineConnectPipe_13_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_13_io_in_bits_v0Wen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_13_io_in_bits_fpu_wflags), .io_in_bits_vpu_vma(vNewPipelineConnectPipe_13_io_in_bits_vpu_vma), .io_in_bits_vpu_vta(vNewPipelineConnectPipe_13_io_in_bits_vpu_vta), .io_in_bits_vpu_vsew(vNewPipelineConnectPipe_13_io_in_bits_vpu_vsew), .io_in_bits_vpu_vlmul(vNewPipelineConnectPipe_13_io_in_bits_vpu_vlmul), .io_in_bits_vpu_vm(vNewPipelineConnectPipe_13_io_in_bits_vpu_vm), .io_in_bits_vpu_vstart(vNewPipelineConnectPipe_13_io_in_bits_vpu_vstart), .io_in_bits_vpu_vuopIdx(vNewPipelineConnectPipe_13_io_in_bits_vpu_vuopIdx), .io_in_bits_vpu_isExt(vNewPipelineConnectPipe_13_io_in_bits_vpu_isExt), .io_in_bits_vpu_isNarrow(vNewPipelineConnectPipe_13_io_in_bits_vpu_isNarrow), .io_in_bits_vpu_isDstMask(vNewPipelineConnectPipe_13_io_in_bits_vpu_isDstMask), .io_in_bits_vpu_isOpMask(vNewPipelineConnectPipe_13_io_in_bits_vpu_isOpMask), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_13_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_13_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_13_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_13_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_13_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_13_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_13_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_13_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_13_i_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_13_i_io_out_bits_src_2), .io_out_bits_src_3(vNewPipelineConnectPipe_13_i_io_out_bits_src_3), .io_out_bits_src_4(vNewPipelineConnectPipe_13_i_io_out_bits_src_4), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_13_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_13_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_13_i_io_out_bits_pdest), .io_out_bits_vecWen(vNewPipelineConnectPipe_13_i_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_13_i_io_out_bits_v0Wen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_13_i_io_out_bits_fpu_wflags), .io_out_bits_vpu_vma(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vma), .io_out_bits_vpu_vta(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vta), .io_out_bits_vpu_vsew(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vsew), .io_out_bits_vpu_vlmul(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vlmul), .io_out_bits_vpu_vm(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vm), .io_out_bits_vpu_vstart(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vstart), .io_out_bits_vpu_vuopIdx(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vuopIdx), .io_out_bits_vpu_isExt(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isExt), .io_out_bits_vpu_isNarrow(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isNarrow), .io_out_bits_vpu_isDstMask(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isDstMask), .io_out_bits_vpu_isOpMask(vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isOpMask), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_13_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_13_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_13_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_13_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_13_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_13_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_src_0 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_in_bits_src_1 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_in_bits_src_2 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_in_bits_src_3 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_in_bits_src_4 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_pdest <= 7'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vecWen <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_v0Wen <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_fpu_wflags <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_vma <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_vta <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_vsew <= 2'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_vlmul <= 3'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_vm <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_vstart <= 8'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_vuopIdx <= 7'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_isExt <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_isNarrow <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_isDstMask <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_vpu_isOpMask <= 1'($urandom);
      vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_13_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_13_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_13_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_13_g_io_in_ready !== vNewPipelineConnectPipe_13_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_in_ready, vNewPipelineConnectPipe_13_i_io_in_ready); end
    if (vNewPipelineConnectPipe_13_g_io_out_valid !== vNewPipelineConnectPipe_13_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_valid, vNewPipelineConnectPipe_13_i_io_out_valid); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_fuType !== vNewPipelineConnectPipe_13_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_fuType, vNewPipelineConnectPipe_13_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_13_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_13_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_13_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_src_0, vNewPipelineConnectPipe_13_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_13_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_src_1, vNewPipelineConnectPipe_13_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_src_2 !== vNewPipelineConnectPipe_13_i_io_out_bits_src_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_src_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_src_2, vNewPipelineConnectPipe_13_i_io_out_bits_src_2); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_src_3 !== vNewPipelineConnectPipe_13_i_io_out_bits_src_3) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_src_3 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_src_3, vNewPipelineConnectPipe_13_i_io_out_bits_src_3); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_src_4 !== vNewPipelineConnectPipe_13_i_io_out_bits_src_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_src_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_src_4, vNewPipelineConnectPipe_13_i_io_out_bits_src_4); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_13_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_13_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_13_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_13_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_pdest !== vNewPipelineConnectPipe_13_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_pdest, vNewPipelineConnectPipe_13_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vecWen !== vNewPipelineConnectPipe_13_i_io_out_bits_vecWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vecWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vecWen, vNewPipelineConnectPipe_13_i_io_out_bits_vecWen); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_v0Wen !== vNewPipelineConnectPipe_13_i_io_out_bits_v0Wen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_v0Wen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_v0Wen, vNewPipelineConnectPipe_13_i_io_out_bits_v0Wen); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_fpu_wflags !== vNewPipelineConnectPipe_13_i_io_out_bits_fpu_wflags) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_fpu_wflags mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_fpu_wflags, vNewPipelineConnectPipe_13_i_io_out_bits_fpu_wflags); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vma !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vma) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_vma mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vma, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vma); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vta !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vta) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_vta mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vta, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vta); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vsew !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vsew) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_vsew mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vsew, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vsew); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vlmul !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vlmul) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_vlmul mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vlmul, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vlmul); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vm !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_vm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vm, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vm); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vstart !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vstart) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_vstart mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vstart, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vstart); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vuopIdx !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vuopIdx) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_vuopIdx mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_vuopIdx, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_vuopIdx); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isExt !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isExt) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_isExt mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isExt, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isExt); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isNarrow !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isNarrow) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_isNarrow mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isNarrow, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isNarrow); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isDstMask !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isDstMask) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_isDstMask mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isDstMask, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isDstMask); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isOpMask !== vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isOpMask) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_vpu_isOpMask mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_vpu_isOpMask, vNewPipelineConnectPipe_13_i_io_out_bits_vpu_isOpMask); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_13.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_13_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_13_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_14_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_14_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_14_io_in_bits_fuOpType;
  logic [127:0] vNewPipelineConnectPipe_14_io_in_bits_src_0;
  logic [127:0] vNewPipelineConnectPipe_14_io_in_bits_src_1;
  logic [127:0] vNewPipelineConnectPipe_14_io_in_bits_src_2;
  logic [127:0] vNewPipelineConnectPipe_14_io_in_bits_src_3;
  logic [127:0] vNewPipelineConnectPipe_14_io_in_bits_src_4;
  logic vNewPipelineConnectPipe_14_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_14_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_14_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_14_io_in_bits_rfWen;
  logic vNewPipelineConnectPipe_14_io_in_bits_fpWen;
  logic vNewPipelineConnectPipe_14_io_in_bits_vecWen;
  logic vNewPipelineConnectPipe_14_io_in_bits_v0Wen;
  logic vNewPipelineConnectPipe_14_io_in_bits_vlWen;
  logic vNewPipelineConnectPipe_14_io_in_bits_fpu_wflags;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_vma;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_vta;
  logic [1:0] vNewPipelineConnectPipe_14_io_in_bits_vpu_vsew;
  logic [2:0] vNewPipelineConnectPipe_14_io_in_bits_vpu_vlmul;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_vm;
  logic [7:0] vNewPipelineConnectPipe_14_io_in_bits_vpu_vstart;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_2;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_4;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_8;
  logic [6:0] vNewPipelineConnectPipe_14_io_in_bits_vpu_vuopIdx;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_lastUop;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_isNarrow;
  logic vNewPipelineConnectPipe_14_io_in_bits_vpu_isDstMask;
  logic [63:0] vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_14_io_rightOutFire;
  logic vNewPipelineConnectPipe_14_io_isFlush;
  wire vNewPipelineConnectPipe_14_g_io_out_valid;
  wire vNewPipelineConnectPipe_14_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_14_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_14_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_14_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_14_i_io_out_bits_fuOpType;
  wire [127:0] vNewPipelineConnectPipe_14_g_io_out_bits_src_0;
  wire [127:0] vNewPipelineConnectPipe_14_i_io_out_bits_src_0;
  wire [127:0] vNewPipelineConnectPipe_14_g_io_out_bits_src_1;
  wire [127:0] vNewPipelineConnectPipe_14_i_io_out_bits_src_1;
  wire [127:0] vNewPipelineConnectPipe_14_g_io_out_bits_src_2;
  wire [127:0] vNewPipelineConnectPipe_14_i_io_out_bits_src_2;
  wire [127:0] vNewPipelineConnectPipe_14_g_io_out_bits_src_3;
  wire [127:0] vNewPipelineConnectPipe_14_i_io_out_bits_src_3;
  wire [127:0] vNewPipelineConnectPipe_14_g_io_out_bits_src_4;
  wire [127:0] vNewPipelineConnectPipe_14_i_io_out_bits_src_4;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_14_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_14_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_14_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_14_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vlWen;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vlWen;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vma;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vma;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vta;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vta;
  wire [1:0] vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vsew;
  wire [1:0] vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vsew;
  wire [2:0] vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vlmul;
  wire [2:0] vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vlmul;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vm;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vm;
  wire [7:0] vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vstart;
  wire [7:0] vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vstart;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire [6:0] vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vuopIdx;
  wire [6:0] vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vuopIdx;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_lastUop;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_lastUop;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_isNarrow;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_isNarrow;
  wire vNewPipelineConnectPipe_14_g_io_out_bits_vpu_isDstMask;
  wire vNewPipelineConnectPipe_14_i_io_out_bits_vpu_isDstMask;
  wire [63:0] vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_14 u_g_NewPipelineConnectPipe_14 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_14_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_14_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_14_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_14_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_14_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_14_io_in_bits_src_2), .io_in_bits_src_3(vNewPipelineConnectPipe_14_io_in_bits_src_3), .io_in_bits_src_4(vNewPipelineConnectPipe_14_io_in_bits_src_4), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_14_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_14_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_14_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_14_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_14_io_in_bits_fpWen), .io_in_bits_vecWen(vNewPipelineConnectPipe_14_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_14_io_in_bits_v0Wen), .io_in_bits_vlWen(vNewPipelineConnectPipe_14_io_in_bits_vlWen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_14_io_in_bits_fpu_wflags), .io_in_bits_vpu_vma(vNewPipelineConnectPipe_14_io_in_bits_vpu_vma), .io_in_bits_vpu_vta(vNewPipelineConnectPipe_14_io_in_bits_vpu_vta), .io_in_bits_vpu_vsew(vNewPipelineConnectPipe_14_io_in_bits_vpu_vsew), .io_in_bits_vpu_vlmul(vNewPipelineConnectPipe_14_io_in_bits_vpu_vlmul), .io_in_bits_vpu_vm(vNewPipelineConnectPipe_14_io_in_bits_vpu_vm), .io_in_bits_vpu_vstart(vNewPipelineConnectPipe_14_io_in_bits_vpu_vstart), .io_in_bits_vpu_fpu_isFoldTo1_2(vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_2), .io_in_bits_vpu_fpu_isFoldTo1_4(vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_4), .io_in_bits_vpu_fpu_isFoldTo1_8(vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_8), .io_in_bits_vpu_vuopIdx(vNewPipelineConnectPipe_14_io_in_bits_vpu_vuopIdx), .io_in_bits_vpu_lastUop(vNewPipelineConnectPipe_14_io_in_bits_vpu_lastUop), .io_in_bits_vpu_isNarrow(vNewPipelineConnectPipe_14_io_in_bits_vpu_isNarrow), .io_in_bits_vpu_isDstMask(vNewPipelineConnectPipe_14_io_in_bits_vpu_isDstMask), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_14_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_14_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_14_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_14_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_14_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_14_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_14_g_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_14_g_io_out_bits_src_2), .io_out_bits_src_3(vNewPipelineConnectPipe_14_g_io_out_bits_src_3), .io_out_bits_src_4(vNewPipelineConnectPipe_14_g_io_out_bits_src_4), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_14_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_14_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_14_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_14_g_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_14_g_io_out_bits_fpWen), .io_out_bits_vecWen(vNewPipelineConnectPipe_14_g_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_14_g_io_out_bits_v0Wen), .io_out_bits_vlWen(vNewPipelineConnectPipe_14_g_io_out_bits_vlWen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_14_g_io_out_bits_fpu_wflags), .io_out_bits_vpu_vma(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vma), .io_out_bits_vpu_vta(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vta), .io_out_bits_vpu_vsew(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vsew), .io_out_bits_vpu_vlmul(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vlmul), .io_out_bits_vpu_vm(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vm), .io_out_bits_vpu_vstart(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vstart), .io_out_bits_vpu_fpu_isFoldTo1_2(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_2), .io_out_bits_vpu_fpu_isFoldTo1_4(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_4), .io_out_bits_vpu_fpu_isFoldTo1_8(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_8), .io_out_bits_vpu_vuopIdx(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vuopIdx), .io_out_bits_vpu_lastUop(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_lastUop), .io_out_bits_vpu_isNarrow(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_isNarrow), .io_out_bits_vpu_isDstMask(vNewPipelineConnectPipe_14_g_io_out_bits_vpu_isDstMask), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_14_xs u_i_NewPipelineConnectPipe_14 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_14_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_14_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_14_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_14_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_14_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_14_io_in_bits_src_2), .io_in_bits_src_3(vNewPipelineConnectPipe_14_io_in_bits_src_3), .io_in_bits_src_4(vNewPipelineConnectPipe_14_io_in_bits_src_4), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_14_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_14_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_14_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_14_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_14_io_in_bits_fpWen), .io_in_bits_vecWen(vNewPipelineConnectPipe_14_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_14_io_in_bits_v0Wen), .io_in_bits_vlWen(vNewPipelineConnectPipe_14_io_in_bits_vlWen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_14_io_in_bits_fpu_wflags), .io_in_bits_vpu_vma(vNewPipelineConnectPipe_14_io_in_bits_vpu_vma), .io_in_bits_vpu_vta(vNewPipelineConnectPipe_14_io_in_bits_vpu_vta), .io_in_bits_vpu_vsew(vNewPipelineConnectPipe_14_io_in_bits_vpu_vsew), .io_in_bits_vpu_vlmul(vNewPipelineConnectPipe_14_io_in_bits_vpu_vlmul), .io_in_bits_vpu_vm(vNewPipelineConnectPipe_14_io_in_bits_vpu_vm), .io_in_bits_vpu_vstart(vNewPipelineConnectPipe_14_io_in_bits_vpu_vstart), .io_in_bits_vpu_fpu_isFoldTo1_2(vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_2), .io_in_bits_vpu_fpu_isFoldTo1_4(vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_4), .io_in_bits_vpu_fpu_isFoldTo1_8(vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_8), .io_in_bits_vpu_vuopIdx(vNewPipelineConnectPipe_14_io_in_bits_vpu_vuopIdx), .io_in_bits_vpu_lastUop(vNewPipelineConnectPipe_14_io_in_bits_vpu_lastUop), .io_in_bits_vpu_isNarrow(vNewPipelineConnectPipe_14_io_in_bits_vpu_isNarrow), .io_in_bits_vpu_isDstMask(vNewPipelineConnectPipe_14_io_in_bits_vpu_isDstMask), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_14_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_14_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_14_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_14_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_14_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_14_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_14_i_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_14_i_io_out_bits_src_2), .io_out_bits_src_3(vNewPipelineConnectPipe_14_i_io_out_bits_src_3), .io_out_bits_src_4(vNewPipelineConnectPipe_14_i_io_out_bits_src_4), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_14_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_14_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_14_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_14_i_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_14_i_io_out_bits_fpWen), .io_out_bits_vecWen(vNewPipelineConnectPipe_14_i_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_14_i_io_out_bits_v0Wen), .io_out_bits_vlWen(vNewPipelineConnectPipe_14_i_io_out_bits_vlWen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_14_i_io_out_bits_fpu_wflags), .io_out_bits_vpu_vma(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vma), .io_out_bits_vpu_vta(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vta), .io_out_bits_vpu_vsew(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vsew), .io_out_bits_vpu_vlmul(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vlmul), .io_out_bits_vpu_vm(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vm), .io_out_bits_vpu_vstart(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vstart), .io_out_bits_vpu_fpu_isFoldTo1_2(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_2), .io_out_bits_vpu_fpu_isFoldTo1_4(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_4), .io_out_bits_vpu_fpu_isFoldTo1_8(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_8), .io_out_bits_vpu_vuopIdx(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vuopIdx), .io_out_bits_vpu_lastUop(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_lastUop), .io_out_bits_vpu_isNarrow(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_isNarrow), .io_out_bits_vpu_isDstMask(vNewPipelineConnectPipe_14_i_io_out_bits_vpu_isDstMask), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_14_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_14_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_14_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_14_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_14_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_src_0 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_in_bits_src_1 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_in_bits_src_2 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_in_bits_src_3 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_in_bits_src_4 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_fpWen <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vecWen <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_v0Wen <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vlWen <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_fpu_wflags <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_vma <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_vta <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_vsew <= 2'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_vlmul <= 3'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_vm <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_vstart <= 8'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_2 <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_4 <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_fpu_isFoldTo1_8 <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_vuopIdx <= 7'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_lastUop <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_isNarrow <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_vpu_isDstMask <= 1'($urandom);
      vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_14_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_14_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_14_g_io_out_valid !== vNewPipelineConnectPipe_14_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_valid, vNewPipelineConnectPipe_14_i_io_out_valid); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_fuType !== vNewPipelineConnectPipe_14_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_fuType, vNewPipelineConnectPipe_14_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_14_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_14_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_14_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_src_0, vNewPipelineConnectPipe_14_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_14_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_src_1, vNewPipelineConnectPipe_14_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_src_2 !== vNewPipelineConnectPipe_14_i_io_out_bits_src_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_src_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_src_2, vNewPipelineConnectPipe_14_i_io_out_bits_src_2); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_src_3 !== vNewPipelineConnectPipe_14_i_io_out_bits_src_3) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_src_3 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_src_3, vNewPipelineConnectPipe_14_i_io_out_bits_src_3); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_src_4 !== vNewPipelineConnectPipe_14_i_io_out_bits_src_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_src_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_src_4, vNewPipelineConnectPipe_14_i_io_out_bits_src_4); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_14_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_14_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_14_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_14_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_pdest !== vNewPipelineConnectPipe_14_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_pdest, vNewPipelineConnectPipe_14_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_14_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_rfWen, vNewPipelineConnectPipe_14_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_fpWen !== vNewPipelineConnectPipe_14_i_io_out_bits_fpWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_fpWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_fpWen, vNewPipelineConnectPipe_14_i_io_out_bits_fpWen); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vecWen !== vNewPipelineConnectPipe_14_i_io_out_bits_vecWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vecWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vecWen, vNewPipelineConnectPipe_14_i_io_out_bits_vecWen); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_v0Wen !== vNewPipelineConnectPipe_14_i_io_out_bits_v0Wen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_v0Wen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_v0Wen, vNewPipelineConnectPipe_14_i_io_out_bits_v0Wen); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vlWen !== vNewPipelineConnectPipe_14_i_io_out_bits_vlWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vlWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vlWen, vNewPipelineConnectPipe_14_i_io_out_bits_vlWen); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_fpu_wflags !== vNewPipelineConnectPipe_14_i_io_out_bits_fpu_wflags) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_fpu_wflags mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_fpu_wflags, vNewPipelineConnectPipe_14_i_io_out_bits_fpu_wflags); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vma !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vma) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_vma mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vma, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vma); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vta !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vta) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_vta mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vta, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vta); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vsew !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vsew) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_vsew mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vsew, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vsew); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vlmul !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vlmul) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_vlmul mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vlmul, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vlmul); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vm !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_vm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vm, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vm); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vstart !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vstart) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_vstart mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vstart, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vstart); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_2 !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_fpu_isFoldTo1_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_2, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_2); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_4 !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_fpu_isFoldTo1_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_4, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_4); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_8 !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_8) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_fpu_isFoldTo1_8 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_fpu_isFoldTo1_8, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_fpu_isFoldTo1_8); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vuopIdx !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vuopIdx) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_vuopIdx mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_vuopIdx, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_vuopIdx); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_lastUop !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_lastUop) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_lastUop mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_lastUop, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_lastUop); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_isNarrow !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_isNarrow) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_isNarrow mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_isNarrow, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_isNarrow); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_vpu_isDstMask !== vNewPipelineConnectPipe_14_i_io_out_bits_vpu_isDstMask) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_vpu_isDstMask mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_vpu_isDstMask, vNewPipelineConnectPipe_14_i_io_out_bits_vpu_isDstMask); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_14.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_14_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_14_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_16_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_16_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_16_io_in_bits_fuOpType;
  logic [127:0] vNewPipelineConnectPipe_16_io_in_bits_src_0;
  logic [127:0] vNewPipelineConnectPipe_16_io_in_bits_src_1;
  logic [127:0] vNewPipelineConnectPipe_16_io_in_bits_src_2;
  logic [127:0] vNewPipelineConnectPipe_16_io_in_bits_src_3;
  logic [127:0] vNewPipelineConnectPipe_16_io_in_bits_src_4;
  logic vNewPipelineConnectPipe_16_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_16_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_16_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_16_io_in_bits_fpWen;
  logic vNewPipelineConnectPipe_16_io_in_bits_vecWen;
  logic vNewPipelineConnectPipe_16_io_in_bits_v0Wen;
  logic vNewPipelineConnectPipe_16_io_in_bits_fpu_wflags;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_vma;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_vta;
  logic [1:0] vNewPipelineConnectPipe_16_io_in_bits_vpu_vsew;
  logic [2:0] vNewPipelineConnectPipe_16_io_in_bits_vpu_vlmul;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_vm;
  logic [7:0] vNewPipelineConnectPipe_16_io_in_bits_vpu_vstart;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_2;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_4;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_8;
  logic [6:0] vNewPipelineConnectPipe_16_io_in_bits_vpu_vuopIdx;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_lastUop;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_isNarrow;
  logic vNewPipelineConnectPipe_16_io_in_bits_vpu_isDstMask;
  logic [63:0] vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_16_io_rightOutFire;
  logic vNewPipelineConnectPipe_16_io_isFlush;
  wire vNewPipelineConnectPipe_16_g_io_out_valid;
  wire vNewPipelineConnectPipe_16_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_16_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_16_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_16_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_16_i_io_out_bits_fuOpType;
  wire [127:0] vNewPipelineConnectPipe_16_g_io_out_bits_src_0;
  wire [127:0] vNewPipelineConnectPipe_16_i_io_out_bits_src_0;
  wire [127:0] vNewPipelineConnectPipe_16_g_io_out_bits_src_1;
  wire [127:0] vNewPipelineConnectPipe_16_i_io_out_bits_src_1;
  wire [127:0] vNewPipelineConnectPipe_16_g_io_out_bits_src_2;
  wire [127:0] vNewPipelineConnectPipe_16_i_io_out_bits_src_2;
  wire [127:0] vNewPipelineConnectPipe_16_g_io_out_bits_src_3;
  wire [127:0] vNewPipelineConnectPipe_16_i_io_out_bits_src_3;
  wire [127:0] vNewPipelineConnectPipe_16_g_io_out_bits_src_4;
  wire [127:0] vNewPipelineConnectPipe_16_i_io_out_bits_src_4;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_16_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_16_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_16_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_16_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_fpu_wflags;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vma;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vma;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vta;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vta;
  wire [1:0] vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vsew;
  wire [1:0] vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vsew;
  wire [2:0] vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vlmul;
  wire [2:0] vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vlmul;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vm;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vm;
  wire [7:0] vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vstart;
  wire [7:0] vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vstart;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_2;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_4;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_8;
  wire [6:0] vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vuopIdx;
  wire [6:0] vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vuopIdx;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_lastUop;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_lastUop;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_isNarrow;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_isNarrow;
  wire vNewPipelineConnectPipe_16_g_io_out_bits_vpu_isDstMask;
  wire vNewPipelineConnectPipe_16_i_io_out_bits_vpu_isDstMask;
  wire [63:0] vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_16 u_g_NewPipelineConnectPipe_16 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_16_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_16_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_16_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_16_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_16_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_16_io_in_bits_src_2), .io_in_bits_src_3(vNewPipelineConnectPipe_16_io_in_bits_src_3), .io_in_bits_src_4(vNewPipelineConnectPipe_16_io_in_bits_src_4), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_16_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_16_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_16_io_in_bits_pdest), .io_in_bits_fpWen(vNewPipelineConnectPipe_16_io_in_bits_fpWen), .io_in_bits_vecWen(vNewPipelineConnectPipe_16_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_16_io_in_bits_v0Wen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_16_io_in_bits_fpu_wflags), .io_in_bits_vpu_vma(vNewPipelineConnectPipe_16_io_in_bits_vpu_vma), .io_in_bits_vpu_vta(vNewPipelineConnectPipe_16_io_in_bits_vpu_vta), .io_in_bits_vpu_vsew(vNewPipelineConnectPipe_16_io_in_bits_vpu_vsew), .io_in_bits_vpu_vlmul(vNewPipelineConnectPipe_16_io_in_bits_vpu_vlmul), .io_in_bits_vpu_vm(vNewPipelineConnectPipe_16_io_in_bits_vpu_vm), .io_in_bits_vpu_vstart(vNewPipelineConnectPipe_16_io_in_bits_vpu_vstart), .io_in_bits_vpu_fpu_isFoldTo1_2(vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_2), .io_in_bits_vpu_fpu_isFoldTo1_4(vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_4), .io_in_bits_vpu_fpu_isFoldTo1_8(vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_8), .io_in_bits_vpu_vuopIdx(vNewPipelineConnectPipe_16_io_in_bits_vpu_vuopIdx), .io_in_bits_vpu_lastUop(vNewPipelineConnectPipe_16_io_in_bits_vpu_lastUop), .io_in_bits_vpu_isNarrow(vNewPipelineConnectPipe_16_io_in_bits_vpu_isNarrow), .io_in_bits_vpu_isDstMask(vNewPipelineConnectPipe_16_io_in_bits_vpu_isDstMask), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_16_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_16_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_16_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_16_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_16_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_16_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_16_g_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_16_g_io_out_bits_src_2), .io_out_bits_src_3(vNewPipelineConnectPipe_16_g_io_out_bits_src_3), .io_out_bits_src_4(vNewPipelineConnectPipe_16_g_io_out_bits_src_4), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_16_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_16_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_16_g_io_out_bits_pdest), .io_out_bits_fpWen(vNewPipelineConnectPipe_16_g_io_out_bits_fpWen), .io_out_bits_vecWen(vNewPipelineConnectPipe_16_g_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_16_g_io_out_bits_v0Wen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_16_g_io_out_bits_fpu_wflags), .io_out_bits_vpu_vma(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vma), .io_out_bits_vpu_vta(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vta), .io_out_bits_vpu_vsew(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vsew), .io_out_bits_vpu_vlmul(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vlmul), .io_out_bits_vpu_vm(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vm), .io_out_bits_vpu_vstart(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vstart), .io_out_bits_vpu_fpu_isFoldTo1_2(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_2), .io_out_bits_vpu_fpu_isFoldTo1_4(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_4), .io_out_bits_vpu_fpu_isFoldTo1_8(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_8), .io_out_bits_vpu_vuopIdx(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vuopIdx), .io_out_bits_vpu_lastUop(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_lastUop), .io_out_bits_vpu_isNarrow(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_isNarrow), .io_out_bits_vpu_isDstMask(vNewPipelineConnectPipe_16_g_io_out_bits_vpu_isDstMask), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_16_xs u_i_NewPipelineConnectPipe_16 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_16_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_16_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_16_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_16_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_16_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_16_io_in_bits_src_2), .io_in_bits_src_3(vNewPipelineConnectPipe_16_io_in_bits_src_3), .io_in_bits_src_4(vNewPipelineConnectPipe_16_io_in_bits_src_4), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_16_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_16_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_16_io_in_bits_pdest), .io_in_bits_fpWen(vNewPipelineConnectPipe_16_io_in_bits_fpWen), .io_in_bits_vecWen(vNewPipelineConnectPipe_16_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_16_io_in_bits_v0Wen), .io_in_bits_fpu_wflags(vNewPipelineConnectPipe_16_io_in_bits_fpu_wflags), .io_in_bits_vpu_vma(vNewPipelineConnectPipe_16_io_in_bits_vpu_vma), .io_in_bits_vpu_vta(vNewPipelineConnectPipe_16_io_in_bits_vpu_vta), .io_in_bits_vpu_vsew(vNewPipelineConnectPipe_16_io_in_bits_vpu_vsew), .io_in_bits_vpu_vlmul(vNewPipelineConnectPipe_16_io_in_bits_vpu_vlmul), .io_in_bits_vpu_vm(vNewPipelineConnectPipe_16_io_in_bits_vpu_vm), .io_in_bits_vpu_vstart(vNewPipelineConnectPipe_16_io_in_bits_vpu_vstart), .io_in_bits_vpu_fpu_isFoldTo1_2(vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_2), .io_in_bits_vpu_fpu_isFoldTo1_4(vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_4), .io_in_bits_vpu_fpu_isFoldTo1_8(vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_8), .io_in_bits_vpu_vuopIdx(vNewPipelineConnectPipe_16_io_in_bits_vpu_vuopIdx), .io_in_bits_vpu_lastUop(vNewPipelineConnectPipe_16_io_in_bits_vpu_lastUop), .io_in_bits_vpu_isNarrow(vNewPipelineConnectPipe_16_io_in_bits_vpu_isNarrow), .io_in_bits_vpu_isDstMask(vNewPipelineConnectPipe_16_io_in_bits_vpu_isDstMask), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_issueTime), .io_rightOutFire(vNewPipelineConnectPipe_16_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_16_io_isFlush), .io_out_valid(vNewPipelineConnectPipe_16_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_16_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_16_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_16_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_16_i_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_16_i_io_out_bits_src_2), .io_out_bits_src_3(vNewPipelineConnectPipe_16_i_io_out_bits_src_3), .io_out_bits_src_4(vNewPipelineConnectPipe_16_i_io_out_bits_src_4), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_16_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_16_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_16_i_io_out_bits_pdest), .io_out_bits_fpWen(vNewPipelineConnectPipe_16_i_io_out_bits_fpWen), .io_out_bits_vecWen(vNewPipelineConnectPipe_16_i_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_16_i_io_out_bits_v0Wen), .io_out_bits_fpu_wflags(vNewPipelineConnectPipe_16_i_io_out_bits_fpu_wflags), .io_out_bits_vpu_vma(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vma), .io_out_bits_vpu_vta(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vta), .io_out_bits_vpu_vsew(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vsew), .io_out_bits_vpu_vlmul(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vlmul), .io_out_bits_vpu_vm(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vm), .io_out_bits_vpu_vstart(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vstart), .io_out_bits_vpu_fpu_isFoldTo1_2(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_2), .io_out_bits_vpu_fpu_isFoldTo1_4(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_4), .io_out_bits_vpu_fpu_isFoldTo1_8(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_8), .io_out_bits_vpu_vuopIdx(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vuopIdx), .io_out_bits_vpu_lastUop(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_lastUop), .io_out_bits_vpu_isNarrow(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_isNarrow), .io_out_bits_vpu_isDstMask(vNewPipelineConnectPipe_16_i_io_out_bits_vpu_isDstMask), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_16_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_16_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_16_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_16_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_16_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_src_0 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_in_bits_src_1 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_in_bits_src_2 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_in_bits_src_3 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_in_bits_src_4 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_fpWen <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vecWen <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_v0Wen <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_fpu_wflags <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_vma <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_vta <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_vsew <= 2'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_vlmul <= 3'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_vm <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_vstart <= 8'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_2 <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_4 <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_fpu_isFoldTo1_8 <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_vuopIdx <= 7'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_lastUop <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_isNarrow <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_vpu_isDstMask <= 1'($urandom);
      vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_16_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_16_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_16_g_io_out_valid !== vNewPipelineConnectPipe_16_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_valid, vNewPipelineConnectPipe_16_i_io_out_valid); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_fuType !== vNewPipelineConnectPipe_16_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_fuType, vNewPipelineConnectPipe_16_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_16_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_16_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_16_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_src_0, vNewPipelineConnectPipe_16_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_16_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_src_1, vNewPipelineConnectPipe_16_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_src_2 !== vNewPipelineConnectPipe_16_i_io_out_bits_src_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_src_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_src_2, vNewPipelineConnectPipe_16_i_io_out_bits_src_2); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_src_3 !== vNewPipelineConnectPipe_16_i_io_out_bits_src_3) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_src_3 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_src_3, vNewPipelineConnectPipe_16_i_io_out_bits_src_3); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_src_4 !== vNewPipelineConnectPipe_16_i_io_out_bits_src_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_src_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_src_4, vNewPipelineConnectPipe_16_i_io_out_bits_src_4); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_16_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_16_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_16_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_16_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_pdest !== vNewPipelineConnectPipe_16_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_pdest, vNewPipelineConnectPipe_16_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_fpWen !== vNewPipelineConnectPipe_16_i_io_out_bits_fpWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_fpWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_fpWen, vNewPipelineConnectPipe_16_i_io_out_bits_fpWen); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vecWen !== vNewPipelineConnectPipe_16_i_io_out_bits_vecWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vecWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vecWen, vNewPipelineConnectPipe_16_i_io_out_bits_vecWen); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_v0Wen !== vNewPipelineConnectPipe_16_i_io_out_bits_v0Wen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_v0Wen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_v0Wen, vNewPipelineConnectPipe_16_i_io_out_bits_v0Wen); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_fpu_wflags !== vNewPipelineConnectPipe_16_i_io_out_bits_fpu_wflags) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_fpu_wflags mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_fpu_wflags, vNewPipelineConnectPipe_16_i_io_out_bits_fpu_wflags); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vma !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vma) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_vma mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vma, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vma); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vta !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vta) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_vta mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vta, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vta); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vsew !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vsew) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_vsew mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vsew, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vsew); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vlmul !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vlmul) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_vlmul mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vlmul, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vlmul); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vm !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_vm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vm, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vm); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vstart !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vstart) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_vstart mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vstart, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vstart); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_2 !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_fpu_isFoldTo1_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_2, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_2); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_4 !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_fpu_isFoldTo1_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_4, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_4); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_8 !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_8) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_fpu_isFoldTo1_8 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_fpu_isFoldTo1_8, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_fpu_isFoldTo1_8); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vuopIdx !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vuopIdx) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_vuopIdx mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_vuopIdx, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_vuopIdx); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_lastUop !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_lastUop) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_lastUop mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_lastUop, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_lastUop); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_isNarrow !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_isNarrow) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_isNarrow mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_isNarrow, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_isNarrow); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_vpu_isDstMask !== vNewPipelineConnectPipe_16_i_io_out_bits_vpu_isDstMask) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_vpu_isDstMask mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_vpu_isDstMask, vNewPipelineConnectPipe_16_i_io_out_bits_vpu_isDstMask); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_16.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_16_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_16_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_18_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_18_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_18_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_18_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_18_io_in_bits_imm;
  logic vNewPipelineConnectPipe_18_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_18_io_in_bits_robIdx_value;
  logic vNewPipelineConnectPipe_18_io_in_bits_isFirstIssue;
  logic [7:0] vNewPipelineConnectPipe_18_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_18_io_in_bits_rfWen;
  logic [5:0] vNewPipelineConnectPipe_18_io_in_bits_ftqIdx_value;
  logic [3:0] vNewPipelineConnectPipe_18_io_in_bits_ftqOffset;
  logic vNewPipelineConnectPipe_18_io_in_bits_sqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_18_io_in_bits_sqIdx_value;
  logic [63:0] vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_18_io_out_ready;
  logic vNewPipelineConnectPipe_18_io_rightOutFire;
  logic vNewPipelineConnectPipe_18_io_isFlush;
  wire vNewPipelineConnectPipe_18_g_io_in_ready;
  wire vNewPipelineConnectPipe_18_i_io_in_ready;
  wire vNewPipelineConnectPipe_18_g_io_out_valid;
  wire vNewPipelineConnectPipe_18_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_18_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_18_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_18_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_18_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_18_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_18_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_18_g_io_out_bits_imm;
  wire [63:0] vNewPipelineConnectPipe_18_i_io_out_bits_imm;
  wire vNewPipelineConnectPipe_18_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_18_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_18_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_18_i_io_out_bits_robIdx_value;
  wire vNewPipelineConnectPipe_18_g_io_out_bits_isFirstIssue;
  wire vNewPipelineConnectPipe_18_i_io_out_bits_isFirstIssue;
  wire [7:0] vNewPipelineConnectPipe_18_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_18_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_18_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_18_i_io_out_bits_rfWen;
  wire [5:0] vNewPipelineConnectPipe_18_g_io_out_bits_ftqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_18_i_io_out_bits_ftqIdx_value;
  wire [3:0] vNewPipelineConnectPipe_18_g_io_out_bits_ftqOffset;
  wire [3:0] vNewPipelineConnectPipe_18_i_io_out_bits_ftqOffset;
  wire vNewPipelineConnectPipe_18_g_io_out_bits_sqIdx_flag;
  wire vNewPipelineConnectPipe_18_i_io_out_bits_sqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_18_g_io_out_bits_sqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_18_i_io_out_bits_sqIdx_value;
  wire [63:0] vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_18 u_g_NewPipelineConnectPipe_18 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_18_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_18_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_18_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_18_io_in_bits_src_0), .io_in_bits_imm(vNewPipelineConnectPipe_18_io_in_bits_imm), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_18_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_18_io_in_bits_robIdx_value), .io_in_bits_isFirstIssue(vNewPipelineConnectPipe_18_io_in_bits_isFirstIssue), .io_in_bits_pdest(vNewPipelineConnectPipe_18_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_18_io_in_bits_rfWen), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_18_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_18_io_in_bits_ftqOffset), .io_in_bits_sqIdx_flag(vNewPipelineConnectPipe_18_io_in_bits_sqIdx_flag), .io_in_bits_sqIdx_value(vNewPipelineConnectPipe_18_io_in_bits_sqIdx_value), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_18_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_18_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_18_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_18_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_18_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_18_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_18_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_18_g_io_out_bits_src_0), .io_out_bits_imm(vNewPipelineConnectPipe_18_g_io_out_bits_imm), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_18_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_18_g_io_out_bits_robIdx_value), .io_out_bits_isFirstIssue(vNewPipelineConnectPipe_18_g_io_out_bits_isFirstIssue), .io_out_bits_pdest(vNewPipelineConnectPipe_18_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_18_g_io_out_bits_rfWen), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_18_g_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_18_g_io_out_bits_ftqOffset), .io_out_bits_sqIdx_flag(vNewPipelineConnectPipe_18_g_io_out_bits_sqIdx_flag), .io_out_bits_sqIdx_value(vNewPipelineConnectPipe_18_g_io_out_bits_sqIdx_value), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_18_xs u_i_NewPipelineConnectPipe_18 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_18_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_18_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_18_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_18_io_in_bits_src_0), .io_in_bits_imm(vNewPipelineConnectPipe_18_io_in_bits_imm), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_18_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_18_io_in_bits_robIdx_value), .io_in_bits_isFirstIssue(vNewPipelineConnectPipe_18_io_in_bits_isFirstIssue), .io_in_bits_pdest(vNewPipelineConnectPipe_18_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_18_io_in_bits_rfWen), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_18_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_18_io_in_bits_ftqOffset), .io_in_bits_sqIdx_flag(vNewPipelineConnectPipe_18_io_in_bits_sqIdx_flag), .io_in_bits_sqIdx_value(vNewPipelineConnectPipe_18_io_in_bits_sqIdx_value), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_18_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_18_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_18_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_18_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_18_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_18_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_18_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_18_i_io_out_bits_src_0), .io_out_bits_imm(vNewPipelineConnectPipe_18_i_io_out_bits_imm), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_18_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_18_i_io_out_bits_robIdx_value), .io_out_bits_isFirstIssue(vNewPipelineConnectPipe_18_i_io_out_bits_isFirstIssue), .io_out_bits_pdest(vNewPipelineConnectPipe_18_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_18_i_io_out_bits_rfWen), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_18_i_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_18_i_io_out_bits_ftqOffset), .io_out_bits_sqIdx_flag(vNewPipelineConnectPipe_18_i_io_out_bits_sqIdx_flag), .io_out_bits_sqIdx_value(vNewPipelineConnectPipe_18_i_io_out_bits_sqIdx_value), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_18_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_18_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_18_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_18_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_18_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_18_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_18_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_18_io_in_bits_imm <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_18_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_isFirstIssue <= 1'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_ftqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_ftqOffset <= 4'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_sqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_sqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_18_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_18_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_18_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_18_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_18_g_io_in_ready !== vNewPipelineConnectPipe_18_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_in_ready, vNewPipelineConnectPipe_18_i_io_in_ready); end
    if (vNewPipelineConnectPipe_18_g_io_out_valid !== vNewPipelineConnectPipe_18_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_valid, vNewPipelineConnectPipe_18_i_io_out_valid); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_fuType !== vNewPipelineConnectPipe_18_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_fuType, vNewPipelineConnectPipe_18_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_18_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_18_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_18_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_src_0, vNewPipelineConnectPipe_18_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_imm !== vNewPipelineConnectPipe_18_i_io_out_bits_imm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_imm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_imm, vNewPipelineConnectPipe_18_i_io_out_bits_imm); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_18_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_18_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_18_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_18_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_isFirstIssue !== vNewPipelineConnectPipe_18_i_io_out_bits_isFirstIssue) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_isFirstIssue mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_isFirstIssue, vNewPipelineConnectPipe_18_i_io_out_bits_isFirstIssue); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_pdest !== vNewPipelineConnectPipe_18_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_pdest, vNewPipelineConnectPipe_18_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_18_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_rfWen, vNewPipelineConnectPipe_18_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_ftqIdx_value !== vNewPipelineConnectPipe_18_i_io_out_bits_ftqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_ftqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_ftqIdx_value, vNewPipelineConnectPipe_18_i_io_out_bits_ftqIdx_value); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_ftqOffset !== vNewPipelineConnectPipe_18_i_io_out_bits_ftqOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_ftqOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_ftqOffset, vNewPipelineConnectPipe_18_i_io_out_bits_ftqOffset); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_sqIdx_flag !== vNewPipelineConnectPipe_18_i_io_out_bits_sqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_sqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_sqIdx_flag, vNewPipelineConnectPipe_18_i_io_out_bits_sqIdx_flag); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_sqIdx_value !== vNewPipelineConnectPipe_18_i_io_out_bits_sqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_sqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_sqIdx_value, vNewPipelineConnectPipe_18_i_io_out_bits_sqIdx_value); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_18.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_18_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_18_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_20_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_20_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_20_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_20_io_in_bits_src_0;
  logic [63:0] vNewPipelineConnectPipe_20_io_in_bits_imm;
  logic vNewPipelineConnectPipe_20_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_20_io_in_bits_robIdx_value;
  logic [7:0] vNewPipelineConnectPipe_20_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_20_io_in_bits_rfWen;
  logic vNewPipelineConnectPipe_20_io_in_bits_fpWen;
  logic [49:0] vNewPipelineConnectPipe_20_io_in_bits_pc;
  logic vNewPipelineConnectPipe_20_io_in_bits_preDecode_isRVC;
  logic vNewPipelineConnectPipe_20_io_in_bits_ftqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_20_io_in_bits_ftqIdx_value;
  logic [3:0] vNewPipelineConnectPipe_20_io_in_bits_ftqOffset;
  logic vNewPipelineConnectPipe_20_io_in_bits_loadWaitBit;
  logic vNewPipelineConnectPipe_20_io_in_bits_waitForRobIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_20_io_in_bits_waitForRobIdx_value;
  logic vNewPipelineConnectPipe_20_io_in_bits_storeSetHit;
  logic vNewPipelineConnectPipe_20_io_in_bits_loadWaitStrict;
  logic vNewPipelineConnectPipe_20_io_in_bits_sqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_20_io_in_bits_sqIdx_value;
  logic vNewPipelineConnectPipe_20_io_in_bits_lqIdx_flag;
  logic [6:0] vNewPipelineConnectPipe_20_io_in_bits_lqIdx_value;
  logic [63:0] vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_20_io_out_ready;
  logic vNewPipelineConnectPipe_20_io_rightOutFire;
  logic vNewPipelineConnectPipe_20_io_isFlush;
  wire vNewPipelineConnectPipe_20_g_io_in_ready;
  wire vNewPipelineConnectPipe_20_i_io_in_ready;
  wire vNewPipelineConnectPipe_20_g_io_out_valid;
  wire vNewPipelineConnectPipe_20_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_20_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_20_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_20_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_20_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_20_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_20_i_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_20_g_io_out_bits_imm;
  wire [63:0] vNewPipelineConnectPipe_20_i_io_out_bits_imm;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_20_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_20_i_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_20_g_io_out_bits_pdest;
  wire [7:0] vNewPipelineConnectPipe_20_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_rfWen;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_fpWen;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_fpWen;
  wire [49:0] vNewPipelineConnectPipe_20_g_io_out_bits_pc;
  wire [49:0] vNewPipelineConnectPipe_20_i_io_out_bits_pc;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_preDecode_isRVC;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_preDecode_isRVC;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_ftqIdx_flag;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_ftqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_20_g_io_out_bits_ftqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_20_i_io_out_bits_ftqIdx_value;
  wire [3:0] vNewPipelineConnectPipe_20_g_io_out_bits_ftqOffset;
  wire [3:0] vNewPipelineConnectPipe_20_i_io_out_bits_ftqOffset;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_loadWaitBit;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_loadWaitBit;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_waitForRobIdx_flag;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_waitForRobIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_20_g_io_out_bits_waitForRobIdx_value;
  wire [7:0] vNewPipelineConnectPipe_20_i_io_out_bits_waitForRobIdx_value;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_storeSetHit;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_storeSetHit;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_loadWaitStrict;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_loadWaitStrict;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_sqIdx_flag;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_sqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_20_g_io_out_bits_sqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_20_i_io_out_bits_sqIdx_value;
  wire vNewPipelineConnectPipe_20_g_io_out_bits_lqIdx_flag;
  wire vNewPipelineConnectPipe_20_i_io_out_bits_lqIdx_flag;
  wire [6:0] vNewPipelineConnectPipe_20_g_io_out_bits_lqIdx_value;
  wire [6:0] vNewPipelineConnectPipe_20_i_io_out_bits_lqIdx_value;
  wire [63:0] vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_20 u_g_NewPipelineConnectPipe_20 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_20_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_20_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_20_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_20_io_in_bits_src_0), .io_in_bits_imm(vNewPipelineConnectPipe_20_io_in_bits_imm), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_20_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_20_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_20_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_20_io_in_bits_fpWen), .io_in_bits_pc(vNewPipelineConnectPipe_20_io_in_bits_pc), .io_in_bits_preDecode_isRVC(vNewPipelineConnectPipe_20_io_in_bits_preDecode_isRVC), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_20_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_20_io_in_bits_ftqOffset), .io_in_bits_loadWaitBit(vNewPipelineConnectPipe_20_io_in_bits_loadWaitBit), .io_in_bits_waitForRobIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_waitForRobIdx_flag), .io_in_bits_waitForRobIdx_value(vNewPipelineConnectPipe_20_io_in_bits_waitForRobIdx_value), .io_in_bits_storeSetHit(vNewPipelineConnectPipe_20_io_in_bits_storeSetHit), .io_in_bits_loadWaitStrict(vNewPipelineConnectPipe_20_io_in_bits_loadWaitStrict), .io_in_bits_sqIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_sqIdx_flag), .io_in_bits_sqIdx_value(vNewPipelineConnectPipe_20_io_in_bits_sqIdx_value), .io_in_bits_lqIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_lqIdx_flag), .io_in_bits_lqIdx_value(vNewPipelineConnectPipe_20_io_in_bits_lqIdx_value), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_20_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_20_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_20_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_20_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_20_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_20_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_20_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_20_g_io_out_bits_src_0), .io_out_bits_imm(vNewPipelineConnectPipe_20_g_io_out_bits_imm), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_20_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_20_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_20_g_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_20_g_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_20_g_io_out_bits_fpWen), .io_out_bits_pc(vNewPipelineConnectPipe_20_g_io_out_bits_pc), .io_out_bits_preDecode_isRVC(vNewPipelineConnectPipe_20_g_io_out_bits_preDecode_isRVC), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_20_g_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_20_g_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_20_g_io_out_bits_ftqOffset), .io_out_bits_loadWaitBit(vNewPipelineConnectPipe_20_g_io_out_bits_loadWaitBit), .io_out_bits_waitForRobIdx_flag(vNewPipelineConnectPipe_20_g_io_out_bits_waitForRobIdx_flag), .io_out_bits_waitForRobIdx_value(vNewPipelineConnectPipe_20_g_io_out_bits_waitForRobIdx_value), .io_out_bits_storeSetHit(vNewPipelineConnectPipe_20_g_io_out_bits_storeSetHit), .io_out_bits_loadWaitStrict(vNewPipelineConnectPipe_20_g_io_out_bits_loadWaitStrict), .io_out_bits_sqIdx_flag(vNewPipelineConnectPipe_20_g_io_out_bits_sqIdx_flag), .io_out_bits_sqIdx_value(vNewPipelineConnectPipe_20_g_io_out_bits_sqIdx_value), .io_out_bits_lqIdx_flag(vNewPipelineConnectPipe_20_g_io_out_bits_lqIdx_flag), .io_out_bits_lqIdx_value(vNewPipelineConnectPipe_20_g_io_out_bits_lqIdx_value), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_20_xs u_i_NewPipelineConnectPipe_20 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_20_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_20_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_20_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_20_io_in_bits_src_0), .io_in_bits_imm(vNewPipelineConnectPipe_20_io_in_bits_imm), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_20_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_20_io_in_bits_pdest), .io_in_bits_rfWen(vNewPipelineConnectPipe_20_io_in_bits_rfWen), .io_in_bits_fpWen(vNewPipelineConnectPipe_20_io_in_bits_fpWen), .io_in_bits_pc(vNewPipelineConnectPipe_20_io_in_bits_pc), .io_in_bits_preDecode_isRVC(vNewPipelineConnectPipe_20_io_in_bits_preDecode_isRVC), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_20_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_20_io_in_bits_ftqOffset), .io_in_bits_loadWaitBit(vNewPipelineConnectPipe_20_io_in_bits_loadWaitBit), .io_in_bits_waitForRobIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_waitForRobIdx_flag), .io_in_bits_waitForRobIdx_value(vNewPipelineConnectPipe_20_io_in_bits_waitForRobIdx_value), .io_in_bits_storeSetHit(vNewPipelineConnectPipe_20_io_in_bits_storeSetHit), .io_in_bits_loadWaitStrict(vNewPipelineConnectPipe_20_io_in_bits_loadWaitStrict), .io_in_bits_sqIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_sqIdx_flag), .io_in_bits_sqIdx_value(vNewPipelineConnectPipe_20_io_in_bits_sqIdx_value), .io_in_bits_lqIdx_flag(vNewPipelineConnectPipe_20_io_in_bits_lqIdx_flag), .io_in_bits_lqIdx_value(vNewPipelineConnectPipe_20_io_in_bits_lqIdx_value), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_20_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_20_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_20_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_20_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_20_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_20_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_20_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_20_i_io_out_bits_src_0), .io_out_bits_imm(vNewPipelineConnectPipe_20_i_io_out_bits_imm), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_20_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_20_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_20_i_io_out_bits_pdest), .io_out_bits_rfWen(vNewPipelineConnectPipe_20_i_io_out_bits_rfWen), .io_out_bits_fpWen(vNewPipelineConnectPipe_20_i_io_out_bits_fpWen), .io_out_bits_pc(vNewPipelineConnectPipe_20_i_io_out_bits_pc), .io_out_bits_preDecode_isRVC(vNewPipelineConnectPipe_20_i_io_out_bits_preDecode_isRVC), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_20_i_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_20_i_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_20_i_io_out_bits_ftqOffset), .io_out_bits_loadWaitBit(vNewPipelineConnectPipe_20_i_io_out_bits_loadWaitBit), .io_out_bits_waitForRobIdx_flag(vNewPipelineConnectPipe_20_i_io_out_bits_waitForRobIdx_flag), .io_out_bits_waitForRobIdx_value(vNewPipelineConnectPipe_20_i_io_out_bits_waitForRobIdx_value), .io_out_bits_storeSetHit(vNewPipelineConnectPipe_20_i_io_out_bits_storeSetHit), .io_out_bits_loadWaitStrict(vNewPipelineConnectPipe_20_i_io_out_bits_loadWaitStrict), .io_out_bits_sqIdx_flag(vNewPipelineConnectPipe_20_i_io_out_bits_sqIdx_flag), .io_out_bits_sqIdx_value(vNewPipelineConnectPipe_20_i_io_out_bits_sqIdx_value), .io_out_bits_lqIdx_flag(vNewPipelineConnectPipe_20_i_io_out_bits_lqIdx_flag), .io_out_bits_lqIdx_value(vNewPipelineConnectPipe_20_i_io_out_bits_lqIdx_value), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_20_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_20_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_20_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_20_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_20_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_20_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_20_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_20_io_in_bits_imm <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_20_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_fpWen <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_pc <= 50'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_20_io_in_bits_preDecode_isRVC <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_ftqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_ftqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_ftqOffset <= 4'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_loadWaitBit <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_waitForRobIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_waitForRobIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_storeSetHit <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_loadWaitStrict <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_sqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_sqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_lqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_lqIdx_value <= 7'($urandom);
      vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_20_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_20_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_20_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_20_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_20_g_io_in_ready !== vNewPipelineConnectPipe_20_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_in_ready, vNewPipelineConnectPipe_20_i_io_in_ready); end
    if (vNewPipelineConnectPipe_20_g_io_out_valid !== vNewPipelineConnectPipe_20_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_valid, vNewPipelineConnectPipe_20_i_io_out_valid); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_fuType !== vNewPipelineConnectPipe_20_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_fuType, vNewPipelineConnectPipe_20_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_20_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_20_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_20_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_src_0, vNewPipelineConnectPipe_20_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_imm !== vNewPipelineConnectPipe_20_i_io_out_bits_imm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_imm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_imm, vNewPipelineConnectPipe_20_i_io_out_bits_imm); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_20_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_20_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_20_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_20_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_pdest !== vNewPipelineConnectPipe_20_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_pdest, vNewPipelineConnectPipe_20_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_rfWen !== vNewPipelineConnectPipe_20_i_io_out_bits_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_rfWen, vNewPipelineConnectPipe_20_i_io_out_bits_rfWen); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_fpWen !== vNewPipelineConnectPipe_20_i_io_out_bits_fpWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_fpWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_fpWen, vNewPipelineConnectPipe_20_i_io_out_bits_fpWen); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_pc !== vNewPipelineConnectPipe_20_i_io_out_bits_pc) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_pc mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_pc, vNewPipelineConnectPipe_20_i_io_out_bits_pc); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_preDecode_isRVC !== vNewPipelineConnectPipe_20_i_io_out_bits_preDecode_isRVC) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_preDecode_isRVC mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_preDecode_isRVC, vNewPipelineConnectPipe_20_i_io_out_bits_preDecode_isRVC); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_ftqIdx_flag !== vNewPipelineConnectPipe_20_i_io_out_bits_ftqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_ftqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_ftqIdx_flag, vNewPipelineConnectPipe_20_i_io_out_bits_ftqIdx_flag); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_ftqIdx_value !== vNewPipelineConnectPipe_20_i_io_out_bits_ftqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_ftqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_ftqIdx_value, vNewPipelineConnectPipe_20_i_io_out_bits_ftqIdx_value); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_ftqOffset !== vNewPipelineConnectPipe_20_i_io_out_bits_ftqOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_ftqOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_ftqOffset, vNewPipelineConnectPipe_20_i_io_out_bits_ftqOffset); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_loadWaitBit !== vNewPipelineConnectPipe_20_i_io_out_bits_loadWaitBit) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_loadWaitBit mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_loadWaitBit, vNewPipelineConnectPipe_20_i_io_out_bits_loadWaitBit); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_waitForRobIdx_flag !== vNewPipelineConnectPipe_20_i_io_out_bits_waitForRobIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_waitForRobIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_waitForRobIdx_flag, vNewPipelineConnectPipe_20_i_io_out_bits_waitForRobIdx_flag); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_waitForRobIdx_value !== vNewPipelineConnectPipe_20_i_io_out_bits_waitForRobIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_waitForRobIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_waitForRobIdx_value, vNewPipelineConnectPipe_20_i_io_out_bits_waitForRobIdx_value); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_storeSetHit !== vNewPipelineConnectPipe_20_i_io_out_bits_storeSetHit) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_storeSetHit mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_storeSetHit, vNewPipelineConnectPipe_20_i_io_out_bits_storeSetHit); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_loadWaitStrict !== vNewPipelineConnectPipe_20_i_io_out_bits_loadWaitStrict) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_loadWaitStrict mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_loadWaitStrict, vNewPipelineConnectPipe_20_i_io_out_bits_loadWaitStrict); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_sqIdx_flag !== vNewPipelineConnectPipe_20_i_io_out_bits_sqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_sqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_sqIdx_flag, vNewPipelineConnectPipe_20_i_io_out_bits_sqIdx_flag); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_sqIdx_value !== vNewPipelineConnectPipe_20_i_io_out_bits_sqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_sqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_sqIdx_value, vNewPipelineConnectPipe_20_i_io_out_bits_sqIdx_value); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_lqIdx_flag !== vNewPipelineConnectPipe_20_i_io_out_bits_lqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_lqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_lqIdx_flag, vNewPipelineConnectPipe_20_i_io_out_bits_lqIdx_flag); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_lqIdx_value !== vNewPipelineConnectPipe_20_i_io_out_bits_lqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_lqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_lqIdx_value, vNewPipelineConnectPipe_20_i_io_out_bits_lqIdx_value); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_20.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_20_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_20_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_23_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_23_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_23_io_in_bits_fuOpType;
  logic [127:0] vNewPipelineConnectPipe_23_io_in_bits_src_0;
  logic [127:0] vNewPipelineConnectPipe_23_io_in_bits_src_1;
  logic [127:0] vNewPipelineConnectPipe_23_io_in_bits_src_2;
  logic [127:0] vNewPipelineConnectPipe_23_io_in_bits_src_3;
  logic [127:0] vNewPipelineConnectPipe_23_io_in_bits_src_4;
  logic vNewPipelineConnectPipe_23_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_23_io_in_bits_robIdx_value;
  logic [6:0] vNewPipelineConnectPipe_23_io_in_bits_pdest;
  logic vNewPipelineConnectPipe_23_io_in_bits_vecWen;
  logic vNewPipelineConnectPipe_23_io_in_bits_v0Wen;
  logic vNewPipelineConnectPipe_23_io_in_bits_vlWen;
  logic vNewPipelineConnectPipe_23_io_in_bits_vpu_vma;
  logic vNewPipelineConnectPipe_23_io_in_bits_vpu_vta;
  logic [1:0] vNewPipelineConnectPipe_23_io_in_bits_vpu_vsew;
  logic [2:0] vNewPipelineConnectPipe_23_io_in_bits_vpu_vlmul;
  logic vNewPipelineConnectPipe_23_io_in_bits_vpu_vm;
  logic [7:0] vNewPipelineConnectPipe_23_io_in_bits_vpu_vstart;
  logic [6:0] vNewPipelineConnectPipe_23_io_in_bits_vpu_vuopIdx;
  logic vNewPipelineConnectPipe_23_io_in_bits_vpu_lastUop;
  logic [127:0] vNewPipelineConnectPipe_23_io_in_bits_vpu_vmask;
  logic [2:0] vNewPipelineConnectPipe_23_io_in_bits_vpu_nf;
  logic [1:0] vNewPipelineConnectPipe_23_io_in_bits_vpu_veew;
  logic vNewPipelineConnectPipe_23_io_in_bits_vpu_isVleff;
  logic vNewPipelineConnectPipe_23_io_in_bits_ftqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_23_io_in_bits_ftqIdx_value;
  logic [3:0] vNewPipelineConnectPipe_23_io_in_bits_ftqOffset;
  logic [4:0] vNewPipelineConnectPipe_23_io_in_bits_numLsElem;
  logic vNewPipelineConnectPipe_23_io_in_bits_sqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_23_io_in_bits_sqIdx_value;
  logic vNewPipelineConnectPipe_23_io_in_bits_lqIdx_flag;
  logic [6:0] vNewPipelineConnectPipe_23_io_in_bits_lqIdx_value;
  logic [63:0] vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_issueTime;
  logic vNewPipelineConnectPipe_23_io_out_ready;
  logic vNewPipelineConnectPipe_23_io_rightOutFire;
  logic vNewPipelineConnectPipe_23_io_isFlush;
  wire vNewPipelineConnectPipe_23_g_io_in_ready;
  wire vNewPipelineConnectPipe_23_i_io_in_ready;
  wire vNewPipelineConnectPipe_23_g_io_out_valid;
  wire vNewPipelineConnectPipe_23_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_23_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_23_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_23_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_23_i_io_out_bits_fuOpType;
  wire [127:0] vNewPipelineConnectPipe_23_g_io_out_bits_src_0;
  wire [127:0] vNewPipelineConnectPipe_23_i_io_out_bits_src_0;
  wire [127:0] vNewPipelineConnectPipe_23_g_io_out_bits_src_1;
  wire [127:0] vNewPipelineConnectPipe_23_i_io_out_bits_src_1;
  wire [127:0] vNewPipelineConnectPipe_23_g_io_out_bits_src_2;
  wire [127:0] vNewPipelineConnectPipe_23_i_io_out_bits_src_2;
  wire [127:0] vNewPipelineConnectPipe_23_g_io_out_bits_src_3;
  wire [127:0] vNewPipelineConnectPipe_23_i_io_out_bits_src_3;
  wire [127:0] vNewPipelineConnectPipe_23_g_io_out_bits_src_4;
  wire [127:0] vNewPipelineConnectPipe_23_i_io_out_bits_src_4;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_23_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_23_i_io_out_bits_robIdx_value;
  wire [6:0] vNewPipelineConnectPipe_23_g_io_out_bits_pdest;
  wire [6:0] vNewPipelineConnectPipe_23_i_io_out_bits_pdest;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_vecWen;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_v0Wen;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_vlWen;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_vlWen;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vma;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vma;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vta;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vta;
  wire [1:0] vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vsew;
  wire [1:0] vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vsew;
  wire [2:0] vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vlmul;
  wire [2:0] vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vlmul;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vm;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vm;
  wire [7:0] vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vstart;
  wire [7:0] vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vstart;
  wire [6:0] vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vuopIdx;
  wire [6:0] vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vuopIdx;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_vpu_lastUop;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_vpu_lastUop;
  wire [127:0] vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vmask;
  wire [127:0] vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vmask;
  wire [2:0] vNewPipelineConnectPipe_23_g_io_out_bits_vpu_nf;
  wire [2:0] vNewPipelineConnectPipe_23_i_io_out_bits_vpu_nf;
  wire [1:0] vNewPipelineConnectPipe_23_g_io_out_bits_vpu_veew;
  wire [1:0] vNewPipelineConnectPipe_23_i_io_out_bits_vpu_veew;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_vpu_isVleff;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_vpu_isVleff;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_ftqIdx_flag;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_ftqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_23_g_io_out_bits_ftqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_23_i_io_out_bits_ftqIdx_value;
  wire [3:0] vNewPipelineConnectPipe_23_g_io_out_bits_ftqOffset;
  wire [3:0] vNewPipelineConnectPipe_23_i_io_out_bits_ftqOffset;
  wire [4:0] vNewPipelineConnectPipe_23_g_io_out_bits_numLsElem;
  wire [4:0] vNewPipelineConnectPipe_23_i_io_out_bits_numLsElem;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_sqIdx_flag;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_sqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_23_g_io_out_bits_sqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_23_i_io_out_bits_sqIdx_value;
  wire vNewPipelineConnectPipe_23_g_io_out_bits_lqIdx_flag;
  wire vNewPipelineConnectPipe_23_i_io_out_bits_lqIdx_flag;
  wire [6:0] vNewPipelineConnectPipe_23_g_io_out_bits_lqIdx_value;
  wire [6:0] vNewPipelineConnectPipe_23_i_io_out_bits_lqIdx_value;
  wire [63:0] vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_issueTime;
  NewPipelineConnectPipe_23 u_g_NewPipelineConnectPipe_23 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_23_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_23_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_23_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_23_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_23_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_23_io_in_bits_src_2), .io_in_bits_src_3(vNewPipelineConnectPipe_23_io_in_bits_src_3), .io_in_bits_src_4(vNewPipelineConnectPipe_23_io_in_bits_src_4), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_23_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_23_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_23_io_in_bits_pdest), .io_in_bits_vecWen(vNewPipelineConnectPipe_23_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_23_io_in_bits_v0Wen), .io_in_bits_vlWen(vNewPipelineConnectPipe_23_io_in_bits_vlWen), .io_in_bits_vpu_vma(vNewPipelineConnectPipe_23_io_in_bits_vpu_vma), .io_in_bits_vpu_vta(vNewPipelineConnectPipe_23_io_in_bits_vpu_vta), .io_in_bits_vpu_vsew(vNewPipelineConnectPipe_23_io_in_bits_vpu_vsew), .io_in_bits_vpu_vlmul(vNewPipelineConnectPipe_23_io_in_bits_vpu_vlmul), .io_in_bits_vpu_vm(vNewPipelineConnectPipe_23_io_in_bits_vpu_vm), .io_in_bits_vpu_vstart(vNewPipelineConnectPipe_23_io_in_bits_vpu_vstart), .io_in_bits_vpu_vuopIdx(vNewPipelineConnectPipe_23_io_in_bits_vpu_vuopIdx), .io_in_bits_vpu_lastUop(vNewPipelineConnectPipe_23_io_in_bits_vpu_lastUop), .io_in_bits_vpu_vmask(vNewPipelineConnectPipe_23_io_in_bits_vpu_vmask), .io_in_bits_vpu_nf(vNewPipelineConnectPipe_23_io_in_bits_vpu_nf), .io_in_bits_vpu_veew(vNewPipelineConnectPipe_23_io_in_bits_vpu_veew), .io_in_bits_vpu_isVleff(vNewPipelineConnectPipe_23_io_in_bits_vpu_isVleff), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_23_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_23_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_23_io_in_bits_ftqOffset), .io_in_bits_numLsElem(vNewPipelineConnectPipe_23_io_in_bits_numLsElem), .io_in_bits_sqIdx_flag(vNewPipelineConnectPipe_23_io_in_bits_sqIdx_flag), .io_in_bits_sqIdx_value(vNewPipelineConnectPipe_23_io_in_bits_sqIdx_value), .io_in_bits_lqIdx_flag(vNewPipelineConnectPipe_23_io_in_bits_lqIdx_flag), .io_in_bits_lqIdx_value(vNewPipelineConnectPipe_23_io_in_bits_lqIdx_value), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_23_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_23_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_23_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_23_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_23_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_23_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_23_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_23_g_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_23_g_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_23_g_io_out_bits_src_2), .io_out_bits_src_3(vNewPipelineConnectPipe_23_g_io_out_bits_src_3), .io_out_bits_src_4(vNewPipelineConnectPipe_23_g_io_out_bits_src_4), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_23_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_23_g_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_23_g_io_out_bits_pdest), .io_out_bits_vecWen(vNewPipelineConnectPipe_23_g_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_23_g_io_out_bits_v0Wen), .io_out_bits_vlWen(vNewPipelineConnectPipe_23_g_io_out_bits_vlWen), .io_out_bits_vpu_vma(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vma), .io_out_bits_vpu_vta(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vta), .io_out_bits_vpu_vsew(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vsew), .io_out_bits_vpu_vlmul(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vlmul), .io_out_bits_vpu_vm(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vm), .io_out_bits_vpu_vstart(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vstart), .io_out_bits_vpu_vuopIdx(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vuopIdx), .io_out_bits_vpu_lastUop(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_lastUop), .io_out_bits_vpu_vmask(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vmask), .io_out_bits_vpu_nf(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_nf), .io_out_bits_vpu_veew(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_veew), .io_out_bits_vpu_isVleff(vNewPipelineConnectPipe_23_g_io_out_bits_vpu_isVleff), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_23_g_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_23_g_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_23_g_io_out_bits_ftqOffset), .io_out_bits_numLsElem(vNewPipelineConnectPipe_23_g_io_out_bits_numLsElem), .io_out_bits_sqIdx_flag(vNewPipelineConnectPipe_23_g_io_out_bits_sqIdx_flag), .io_out_bits_sqIdx_value(vNewPipelineConnectPipe_23_g_io_out_bits_sqIdx_value), .io_out_bits_lqIdx_flag(vNewPipelineConnectPipe_23_g_io_out_bits_lqIdx_flag), .io_out_bits_lqIdx_value(vNewPipelineConnectPipe_23_g_io_out_bits_lqIdx_value), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_issueTime));
  NewPipelineConnectPipe_23_xs u_i_NewPipelineConnectPipe_23 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_23_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_23_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_23_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_23_io_in_bits_src_0), .io_in_bits_src_1(vNewPipelineConnectPipe_23_io_in_bits_src_1), .io_in_bits_src_2(vNewPipelineConnectPipe_23_io_in_bits_src_2), .io_in_bits_src_3(vNewPipelineConnectPipe_23_io_in_bits_src_3), .io_in_bits_src_4(vNewPipelineConnectPipe_23_io_in_bits_src_4), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_23_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_23_io_in_bits_robIdx_value), .io_in_bits_pdest(vNewPipelineConnectPipe_23_io_in_bits_pdest), .io_in_bits_vecWen(vNewPipelineConnectPipe_23_io_in_bits_vecWen), .io_in_bits_v0Wen(vNewPipelineConnectPipe_23_io_in_bits_v0Wen), .io_in_bits_vlWen(vNewPipelineConnectPipe_23_io_in_bits_vlWen), .io_in_bits_vpu_vma(vNewPipelineConnectPipe_23_io_in_bits_vpu_vma), .io_in_bits_vpu_vta(vNewPipelineConnectPipe_23_io_in_bits_vpu_vta), .io_in_bits_vpu_vsew(vNewPipelineConnectPipe_23_io_in_bits_vpu_vsew), .io_in_bits_vpu_vlmul(vNewPipelineConnectPipe_23_io_in_bits_vpu_vlmul), .io_in_bits_vpu_vm(vNewPipelineConnectPipe_23_io_in_bits_vpu_vm), .io_in_bits_vpu_vstart(vNewPipelineConnectPipe_23_io_in_bits_vpu_vstart), .io_in_bits_vpu_vuopIdx(vNewPipelineConnectPipe_23_io_in_bits_vpu_vuopIdx), .io_in_bits_vpu_lastUop(vNewPipelineConnectPipe_23_io_in_bits_vpu_lastUop), .io_in_bits_vpu_vmask(vNewPipelineConnectPipe_23_io_in_bits_vpu_vmask), .io_in_bits_vpu_nf(vNewPipelineConnectPipe_23_io_in_bits_vpu_nf), .io_in_bits_vpu_veew(vNewPipelineConnectPipe_23_io_in_bits_vpu_veew), .io_in_bits_vpu_isVleff(vNewPipelineConnectPipe_23_io_in_bits_vpu_isVleff), .io_in_bits_ftqIdx_flag(vNewPipelineConnectPipe_23_io_in_bits_ftqIdx_flag), .io_in_bits_ftqIdx_value(vNewPipelineConnectPipe_23_io_in_bits_ftqIdx_value), .io_in_bits_ftqOffset(vNewPipelineConnectPipe_23_io_in_bits_ftqOffset), .io_in_bits_numLsElem(vNewPipelineConnectPipe_23_io_in_bits_numLsElem), .io_in_bits_sqIdx_flag(vNewPipelineConnectPipe_23_io_in_bits_sqIdx_flag), .io_in_bits_sqIdx_value(vNewPipelineConnectPipe_23_io_in_bits_sqIdx_value), .io_in_bits_lqIdx_flag(vNewPipelineConnectPipe_23_io_in_bits_lqIdx_flag), .io_in_bits_lqIdx_value(vNewPipelineConnectPipe_23_io_in_bits_lqIdx_value), .io_in_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_enqRsTime), .io_in_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_selectTime), .io_in_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_issueTime), .io_out_ready(vNewPipelineConnectPipe_23_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_23_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_23_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_23_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_23_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_23_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_23_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_23_i_io_out_bits_src_0), .io_out_bits_src_1(vNewPipelineConnectPipe_23_i_io_out_bits_src_1), .io_out_bits_src_2(vNewPipelineConnectPipe_23_i_io_out_bits_src_2), .io_out_bits_src_3(vNewPipelineConnectPipe_23_i_io_out_bits_src_3), .io_out_bits_src_4(vNewPipelineConnectPipe_23_i_io_out_bits_src_4), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_23_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_23_i_io_out_bits_robIdx_value), .io_out_bits_pdest(vNewPipelineConnectPipe_23_i_io_out_bits_pdest), .io_out_bits_vecWen(vNewPipelineConnectPipe_23_i_io_out_bits_vecWen), .io_out_bits_v0Wen(vNewPipelineConnectPipe_23_i_io_out_bits_v0Wen), .io_out_bits_vlWen(vNewPipelineConnectPipe_23_i_io_out_bits_vlWen), .io_out_bits_vpu_vma(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vma), .io_out_bits_vpu_vta(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vta), .io_out_bits_vpu_vsew(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vsew), .io_out_bits_vpu_vlmul(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vlmul), .io_out_bits_vpu_vm(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vm), .io_out_bits_vpu_vstart(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vstart), .io_out_bits_vpu_vuopIdx(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vuopIdx), .io_out_bits_vpu_lastUop(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_lastUop), .io_out_bits_vpu_vmask(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vmask), .io_out_bits_vpu_nf(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_nf), .io_out_bits_vpu_veew(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_veew), .io_out_bits_vpu_isVleff(vNewPipelineConnectPipe_23_i_io_out_bits_vpu_isVleff), .io_out_bits_ftqIdx_flag(vNewPipelineConnectPipe_23_i_io_out_bits_ftqIdx_flag), .io_out_bits_ftqIdx_value(vNewPipelineConnectPipe_23_i_io_out_bits_ftqIdx_value), .io_out_bits_ftqOffset(vNewPipelineConnectPipe_23_i_io_out_bits_ftqOffset), .io_out_bits_numLsElem(vNewPipelineConnectPipe_23_i_io_out_bits_numLsElem), .io_out_bits_sqIdx_flag(vNewPipelineConnectPipe_23_i_io_out_bits_sqIdx_flag), .io_out_bits_sqIdx_value(vNewPipelineConnectPipe_23_i_io_out_bits_sqIdx_value), .io_out_bits_lqIdx_flag(vNewPipelineConnectPipe_23_i_io_out_bits_lqIdx_flag), .io_out_bits_lqIdx_value(vNewPipelineConnectPipe_23_i_io_out_bits_lqIdx_value), .io_out_bits_perfDebugInfo_enqRsTime(vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_enqRsTime), .io_out_bits_perfDebugInfo_selectTime(vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_selectTime), .io_out_bits_perfDebugInfo_issueTime(vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_issueTime));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_23_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_23_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_23_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_23_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_23_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_23_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_src_0 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_src_1 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_src_2 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_src_3 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_src_4 <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_pdest <= 7'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vecWen <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_v0Wen <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vlWen <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_vma <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_vta <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_vsew <= 2'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_vlmul <= 3'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_vm <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_vstart <= 8'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_vuopIdx <= 7'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_lastUop <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_vmask <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_vpu_nf <= 3'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_veew <= 2'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_vpu_isVleff <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_ftqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_ftqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_ftqOffset <= 4'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_numLsElem <= 5'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_sqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_sqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_lqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_lqIdx_value <= 7'($urandom);
      vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_in_bits_perfDebugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_23_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_23_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_23_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_23_g_io_in_ready !== vNewPipelineConnectPipe_23_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_in_ready, vNewPipelineConnectPipe_23_i_io_in_ready); end
    if (vNewPipelineConnectPipe_23_g_io_out_valid !== vNewPipelineConnectPipe_23_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_valid, vNewPipelineConnectPipe_23_i_io_out_valid); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_fuType !== vNewPipelineConnectPipe_23_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_fuType, vNewPipelineConnectPipe_23_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_23_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_23_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_23_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_src_0, vNewPipelineConnectPipe_23_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_src_1 !== vNewPipelineConnectPipe_23_i_io_out_bits_src_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_src_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_src_1, vNewPipelineConnectPipe_23_i_io_out_bits_src_1); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_src_2 !== vNewPipelineConnectPipe_23_i_io_out_bits_src_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_src_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_src_2, vNewPipelineConnectPipe_23_i_io_out_bits_src_2); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_src_3 !== vNewPipelineConnectPipe_23_i_io_out_bits_src_3) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_src_3 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_src_3, vNewPipelineConnectPipe_23_i_io_out_bits_src_3); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_src_4 !== vNewPipelineConnectPipe_23_i_io_out_bits_src_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_src_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_src_4, vNewPipelineConnectPipe_23_i_io_out_bits_src_4); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_23_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_23_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_23_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_23_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_pdest !== vNewPipelineConnectPipe_23_i_io_out_bits_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_pdest, vNewPipelineConnectPipe_23_i_io_out_bits_pdest); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vecWen !== vNewPipelineConnectPipe_23_i_io_out_bits_vecWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vecWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vecWen, vNewPipelineConnectPipe_23_i_io_out_bits_vecWen); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_v0Wen !== vNewPipelineConnectPipe_23_i_io_out_bits_v0Wen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_v0Wen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_v0Wen, vNewPipelineConnectPipe_23_i_io_out_bits_v0Wen); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vlWen !== vNewPipelineConnectPipe_23_i_io_out_bits_vlWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vlWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vlWen, vNewPipelineConnectPipe_23_i_io_out_bits_vlWen); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vma !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vma) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_vma mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vma, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vma); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vta !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vta) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_vta mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vta, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vta); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vsew !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vsew) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_vsew mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vsew, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vsew); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vlmul !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vlmul) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_vlmul mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vlmul, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vlmul); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vm !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_vm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vm, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vm); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vstart !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vstart) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_vstart mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vstart, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vstart); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vuopIdx !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vuopIdx) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_vuopIdx mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vuopIdx, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vuopIdx); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_lastUop !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_lastUop) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_lastUop mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_lastUop, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_lastUop); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vmask !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vmask) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_vmask mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_vmask, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_vmask); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_nf !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_nf) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_nf mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_nf, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_nf); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_veew !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_veew) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_veew mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_veew, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_veew); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_vpu_isVleff !== vNewPipelineConnectPipe_23_i_io_out_bits_vpu_isVleff) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_vpu_isVleff mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_vpu_isVleff, vNewPipelineConnectPipe_23_i_io_out_bits_vpu_isVleff); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_ftqIdx_flag !== vNewPipelineConnectPipe_23_i_io_out_bits_ftqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_ftqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_ftqIdx_flag, vNewPipelineConnectPipe_23_i_io_out_bits_ftqIdx_flag); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_ftqIdx_value !== vNewPipelineConnectPipe_23_i_io_out_bits_ftqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_ftqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_ftqIdx_value, vNewPipelineConnectPipe_23_i_io_out_bits_ftqIdx_value); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_ftqOffset !== vNewPipelineConnectPipe_23_i_io_out_bits_ftqOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_ftqOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_ftqOffset, vNewPipelineConnectPipe_23_i_io_out_bits_ftqOffset); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_numLsElem !== vNewPipelineConnectPipe_23_i_io_out_bits_numLsElem) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_numLsElem mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_numLsElem, vNewPipelineConnectPipe_23_i_io_out_bits_numLsElem); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_sqIdx_flag !== vNewPipelineConnectPipe_23_i_io_out_bits_sqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_sqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_sqIdx_flag, vNewPipelineConnectPipe_23_i_io_out_bits_sqIdx_flag); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_sqIdx_value !== vNewPipelineConnectPipe_23_i_io_out_bits_sqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_sqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_sqIdx_value, vNewPipelineConnectPipe_23_i_io_out_bits_sqIdx_value); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_lqIdx_flag !== vNewPipelineConnectPipe_23_i_io_out_bits_lqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_lqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_lqIdx_flag, vNewPipelineConnectPipe_23_i_io_out_bits_lqIdx_flag); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_lqIdx_value !== vNewPipelineConnectPipe_23_i_io_out_bits_lqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_lqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_lqIdx_value, vNewPipelineConnectPipe_23_i_io_out_bits_lqIdx_value); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_enqRsTime !== vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_perfDebugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_enqRsTime, vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_selectTime !== vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_perfDebugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_selectTime, vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_selectTime); end
    if (vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_issueTime !== vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_23.io_out_bits_perfDebugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_23_g_io_out_bits_perfDebugInfo_issueTime, vNewPipelineConnectPipe_23_i_io_out_bits_perfDebugInfo_issueTime); end
  end

  logic vNewPipelineConnectPipe_25_io_in_valid;
  logic [34:0] vNewPipelineConnectPipe_25_io_in_bits_fuType;
  logic [8:0] vNewPipelineConnectPipe_25_io_in_bits_fuOpType;
  logic [63:0] vNewPipelineConnectPipe_25_io_in_bits_src_0;
  logic vNewPipelineConnectPipe_25_io_in_bits_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_25_io_in_bits_robIdx_value;
  logic vNewPipelineConnectPipe_25_io_in_bits_sqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_25_io_in_bits_sqIdx_value;
  logic vNewPipelineConnectPipe_25_io_out_ready;
  logic vNewPipelineConnectPipe_25_io_rightOutFire;
  logic vNewPipelineConnectPipe_25_io_isFlush;
  wire vNewPipelineConnectPipe_25_g_io_in_ready;
  wire vNewPipelineConnectPipe_25_i_io_in_ready;
  wire vNewPipelineConnectPipe_25_g_io_out_valid;
  wire vNewPipelineConnectPipe_25_i_io_out_valid;
  wire [34:0] vNewPipelineConnectPipe_25_g_io_out_bits_fuType;
  wire [34:0] vNewPipelineConnectPipe_25_i_io_out_bits_fuType;
  wire [8:0] vNewPipelineConnectPipe_25_g_io_out_bits_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_25_i_io_out_bits_fuOpType;
  wire [63:0] vNewPipelineConnectPipe_25_g_io_out_bits_src_0;
  wire [63:0] vNewPipelineConnectPipe_25_i_io_out_bits_src_0;
  wire vNewPipelineConnectPipe_25_g_io_out_bits_robIdx_flag;
  wire vNewPipelineConnectPipe_25_i_io_out_bits_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_25_g_io_out_bits_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_25_i_io_out_bits_robIdx_value;
  wire vNewPipelineConnectPipe_25_g_io_out_bits_sqIdx_flag;
  wire vNewPipelineConnectPipe_25_i_io_out_bits_sqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_25_g_io_out_bits_sqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_25_i_io_out_bits_sqIdx_value;
  NewPipelineConnectPipe_25 u_g_NewPipelineConnectPipe_25 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_25_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_25_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_25_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_25_io_in_bits_src_0), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_25_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_25_io_in_bits_robIdx_value), .io_in_bits_sqIdx_flag(vNewPipelineConnectPipe_25_io_in_bits_sqIdx_flag), .io_in_bits_sqIdx_value(vNewPipelineConnectPipe_25_io_in_bits_sqIdx_value), .io_out_ready(vNewPipelineConnectPipe_25_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_25_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_25_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_25_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_25_g_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_25_g_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_25_g_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_25_g_io_out_bits_src_0), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_25_g_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_25_g_io_out_bits_robIdx_value), .io_out_bits_sqIdx_flag(vNewPipelineConnectPipe_25_g_io_out_bits_sqIdx_flag), .io_out_bits_sqIdx_value(vNewPipelineConnectPipe_25_g_io_out_bits_sqIdx_value));
  NewPipelineConnectPipe_25_xs u_i_NewPipelineConnectPipe_25 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_25_io_in_valid), .io_in_bits_fuType(vNewPipelineConnectPipe_25_io_in_bits_fuType), .io_in_bits_fuOpType(vNewPipelineConnectPipe_25_io_in_bits_fuOpType), .io_in_bits_src_0(vNewPipelineConnectPipe_25_io_in_bits_src_0), .io_in_bits_robIdx_flag(vNewPipelineConnectPipe_25_io_in_bits_robIdx_flag), .io_in_bits_robIdx_value(vNewPipelineConnectPipe_25_io_in_bits_robIdx_value), .io_in_bits_sqIdx_flag(vNewPipelineConnectPipe_25_io_in_bits_sqIdx_flag), .io_in_bits_sqIdx_value(vNewPipelineConnectPipe_25_io_in_bits_sqIdx_value), .io_out_ready(vNewPipelineConnectPipe_25_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_25_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_25_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_25_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_25_i_io_out_valid), .io_out_bits_fuType(vNewPipelineConnectPipe_25_i_io_out_bits_fuType), .io_out_bits_fuOpType(vNewPipelineConnectPipe_25_i_io_out_bits_fuOpType), .io_out_bits_src_0(vNewPipelineConnectPipe_25_i_io_out_bits_src_0), .io_out_bits_robIdx_flag(vNewPipelineConnectPipe_25_i_io_out_bits_robIdx_flag), .io_out_bits_robIdx_value(vNewPipelineConnectPipe_25_i_io_out_bits_robIdx_value), .io_out_bits_sqIdx_flag(vNewPipelineConnectPipe_25_i_io_out_bits_sqIdx_flag), .io_out_bits_sqIdx_value(vNewPipelineConnectPipe_25_i_io_out_bits_sqIdx_value));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_25_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_25_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_25_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_25_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_25_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_25_io_in_bits_fuType <= 35'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_25_io_in_bits_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_25_io_in_bits_src_0 <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_25_io_in_bits_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_25_io_in_bits_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_25_io_in_bits_sqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_25_io_in_bits_sqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_25_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_25_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_25_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_25_g_io_in_ready !== vNewPipelineConnectPipe_25_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_in_ready, vNewPipelineConnectPipe_25_i_io_in_ready); end
    if (vNewPipelineConnectPipe_25_g_io_out_valid !== vNewPipelineConnectPipe_25_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_out_valid, vNewPipelineConnectPipe_25_i_io_out_valid); end
    if (vNewPipelineConnectPipe_25_g_io_out_bits_fuType !== vNewPipelineConnectPipe_25_i_io_out_bits_fuType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_out_bits_fuType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_out_bits_fuType, vNewPipelineConnectPipe_25_i_io_out_bits_fuType); end
    if (vNewPipelineConnectPipe_25_g_io_out_bits_fuOpType !== vNewPipelineConnectPipe_25_i_io_out_bits_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_out_bits_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_out_bits_fuOpType, vNewPipelineConnectPipe_25_i_io_out_bits_fuOpType); end
    if (vNewPipelineConnectPipe_25_g_io_out_bits_src_0 !== vNewPipelineConnectPipe_25_i_io_out_bits_src_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_out_bits_src_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_out_bits_src_0, vNewPipelineConnectPipe_25_i_io_out_bits_src_0); end
    if (vNewPipelineConnectPipe_25_g_io_out_bits_robIdx_flag !== vNewPipelineConnectPipe_25_i_io_out_bits_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_out_bits_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_out_bits_robIdx_flag, vNewPipelineConnectPipe_25_i_io_out_bits_robIdx_flag); end
    if (vNewPipelineConnectPipe_25_g_io_out_bits_robIdx_value !== vNewPipelineConnectPipe_25_i_io_out_bits_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_out_bits_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_out_bits_robIdx_value, vNewPipelineConnectPipe_25_i_io_out_bits_robIdx_value); end
    if (vNewPipelineConnectPipe_25_g_io_out_bits_sqIdx_flag !== vNewPipelineConnectPipe_25_i_io_out_bits_sqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_out_bits_sqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_out_bits_sqIdx_flag, vNewPipelineConnectPipe_25_i_io_out_bits_sqIdx_flag); end
    if (vNewPipelineConnectPipe_25_g_io_out_bits_sqIdx_value !== vNewPipelineConnectPipe_25_i_io_out_bits_sqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_25.io_out_bits_sqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_25_g_io_out_bits_sqIdx_value, vNewPipelineConnectPipe_25_i_io_out_bits_sqIdx_value); end
  end

  logic vNewPipelineConnectPipe_27_io_in_valid;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_3;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_4;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_5;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_6;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_7;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_13;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_15;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_19;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_21;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_23;
  logic [3:0] vNewPipelineConnectPipe_27_io_in_bits_uop_trigger;
  logic [8:0] vNewPipelineConnectPipe_27_io_in_bits_uop_fuOpType;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_vecWen;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_v0Wen;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_vlWen;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_flushPipe;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vma;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vta;
  logic [1:0] vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vsew;
  logic [2:0] vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vlmul;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vm;
  logic [7:0] vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vstart;
  logic [6:0] vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vuopIdx;
  logic [127:0] vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vmask;
  logic [7:0] vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vl;
  logic [2:0] vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_nf;
  logic [1:0] vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_veew;
  logic [7:0] vNewPipelineConnectPipe_27_io_in_bits_uop_pdest;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_27_io_in_bits_uop_robIdx_value;
  logic [63:0] vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_issueTime;
  logic vNewPipelineConnectPipe_27_io_in_bits_uop_replayInst;
  logic [127:0] vNewPipelineConnectPipe_27_io_in_bits_data;
  logic [2:0] vNewPipelineConnectPipe_27_io_in_bits_vdIdx;
  logic [2:0] vNewPipelineConnectPipe_27_io_in_bits_vdIdxInField;
  logic vNewPipelineConnectPipe_27_io_out_ready;
  logic vNewPipelineConnectPipe_27_io_rightOutFire;
  logic vNewPipelineConnectPipe_27_io_isFlush;
  wire vNewPipelineConnectPipe_27_g_io_in_ready;
  wire vNewPipelineConnectPipe_27_i_io_in_ready;
  wire vNewPipelineConnectPipe_27_g_io_out_valid;
  wire vNewPipelineConnectPipe_27_i_io_out_valid;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_3;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_3;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_4;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_4;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_5;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_5;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_6;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_6;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_7;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_7;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_13;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_13;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_15;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_15;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_19;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_19;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_21;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_21;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_23;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_23;
  wire [3:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_trigger;
  wire [3:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_trigger;
  wire [8:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_fuOpType;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_vecWen;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_vecWen;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_v0Wen;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_v0Wen;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_vlWen;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_vlWen;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_flushPipe;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_flushPipe;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vma;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vma;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vta;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vta;
  wire [1:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vsew;
  wire [1:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vsew;
  wire [2:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vlmul;
  wire [2:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vlmul;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vm;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vm;
  wire [7:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vstart;
  wire [7:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vstart;
  wire [6:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vuopIdx;
  wire [6:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vuopIdx;
  wire [127:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vmask;
  wire [127:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vmask;
  wire [7:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vl;
  wire [7:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vl;
  wire [2:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_nf;
  wire [2:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_nf;
  wire [1:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_veew;
  wire [1:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_veew;
  wire [7:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_pdest;
  wire [7:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_pdest;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_robIdx_flag;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_robIdx_value;
  wire [63:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_issueTime;
  wire vNewPipelineConnectPipe_27_g_io_out_bits_uop_replayInst;
  wire vNewPipelineConnectPipe_27_i_io_out_bits_uop_replayInst;
  wire [127:0] vNewPipelineConnectPipe_27_g_io_out_bits_data;
  wire [127:0] vNewPipelineConnectPipe_27_i_io_out_bits_data;
  wire [2:0] vNewPipelineConnectPipe_27_g_io_out_bits_vdIdx;
  wire [2:0] vNewPipelineConnectPipe_27_i_io_out_bits_vdIdx;
  wire [2:0] vNewPipelineConnectPipe_27_g_io_out_bits_vdIdxInField;
  wire [2:0] vNewPipelineConnectPipe_27_i_io_out_bits_vdIdxInField;
  NewPipelineConnectPipe_27 u_g_NewPipelineConnectPipe_27 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_27_io_in_valid), .io_in_bits_uop_exceptionVec_3(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_3), .io_in_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_4), .io_in_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_5), .io_in_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_6), .io_in_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_7), .io_in_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_13), .io_in_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_15), .io_in_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_19), .io_in_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_21), .io_in_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_23), .io_in_bits_uop_trigger(vNewPipelineConnectPipe_27_io_in_bits_uop_trigger), .io_in_bits_uop_fuOpType(vNewPipelineConnectPipe_27_io_in_bits_uop_fuOpType), .io_in_bits_uop_vecWen(vNewPipelineConnectPipe_27_io_in_bits_uop_vecWen), .io_in_bits_uop_v0Wen(vNewPipelineConnectPipe_27_io_in_bits_uop_v0Wen), .io_in_bits_uop_vlWen(vNewPipelineConnectPipe_27_io_in_bits_uop_vlWen), .io_in_bits_uop_flushPipe(vNewPipelineConnectPipe_27_io_in_bits_uop_flushPipe), .io_in_bits_uop_vpu_vma(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vma), .io_in_bits_uop_vpu_vta(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vta), .io_in_bits_uop_vpu_vsew(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vsew), .io_in_bits_uop_vpu_vlmul(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vlmul), .io_in_bits_uop_vpu_vm(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vm), .io_in_bits_uop_vpu_vstart(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vstart), .io_in_bits_uop_vpu_vuopIdx(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vuopIdx), .io_in_bits_uop_vpu_vmask(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vmask), .io_in_bits_uop_vpu_vl(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vl), .io_in_bits_uop_vpu_nf(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_nf), .io_in_bits_uop_vpu_veew(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_veew), .io_in_bits_uop_pdest(vNewPipelineConnectPipe_27_io_in_bits_uop_pdest), .io_in_bits_uop_robIdx_flag(vNewPipelineConnectPipe_27_io_in_bits_uop_robIdx_flag), .io_in_bits_uop_robIdx_value(vNewPipelineConnectPipe_27_io_in_bits_uop_robIdx_value), .io_in_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_enqRsTime), .io_in_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_selectTime), .io_in_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_issueTime), .io_in_bits_uop_replayInst(vNewPipelineConnectPipe_27_io_in_bits_uop_replayInst), .io_in_bits_data(vNewPipelineConnectPipe_27_io_in_bits_data), .io_in_bits_vdIdx(vNewPipelineConnectPipe_27_io_in_bits_vdIdx), .io_in_bits_vdIdxInField(vNewPipelineConnectPipe_27_io_in_bits_vdIdxInField), .io_out_ready(vNewPipelineConnectPipe_27_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_27_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_27_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_27_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_27_g_io_out_valid), .io_out_bits_uop_exceptionVec_3(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_3), .io_out_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_4), .io_out_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_5), .io_out_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_6), .io_out_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_7), .io_out_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_13), .io_out_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_15), .io_out_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_19), .io_out_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_21), .io_out_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_23), .io_out_bits_uop_trigger(vNewPipelineConnectPipe_27_g_io_out_bits_uop_trigger), .io_out_bits_uop_fuOpType(vNewPipelineConnectPipe_27_g_io_out_bits_uop_fuOpType), .io_out_bits_uop_vecWen(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vecWen), .io_out_bits_uop_v0Wen(vNewPipelineConnectPipe_27_g_io_out_bits_uop_v0Wen), .io_out_bits_uop_vlWen(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vlWen), .io_out_bits_uop_flushPipe(vNewPipelineConnectPipe_27_g_io_out_bits_uop_flushPipe), .io_out_bits_uop_vpu_vma(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vma), .io_out_bits_uop_vpu_vta(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vta), .io_out_bits_uop_vpu_vsew(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vsew), .io_out_bits_uop_vpu_vlmul(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vlmul), .io_out_bits_uop_vpu_vm(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vm), .io_out_bits_uop_vpu_vstart(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vstart), .io_out_bits_uop_vpu_vuopIdx(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vuopIdx), .io_out_bits_uop_vpu_vmask(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vmask), .io_out_bits_uop_vpu_vl(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vl), .io_out_bits_uop_vpu_nf(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_nf), .io_out_bits_uop_vpu_veew(vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_veew), .io_out_bits_uop_pdest(vNewPipelineConnectPipe_27_g_io_out_bits_uop_pdest), .io_out_bits_uop_robIdx_flag(vNewPipelineConnectPipe_27_g_io_out_bits_uop_robIdx_flag), .io_out_bits_uop_robIdx_value(vNewPipelineConnectPipe_27_g_io_out_bits_uop_robIdx_value), .io_out_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_enqRsTime), .io_out_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_selectTime), .io_out_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_issueTime), .io_out_bits_uop_replayInst(vNewPipelineConnectPipe_27_g_io_out_bits_uop_replayInst), .io_out_bits_data(vNewPipelineConnectPipe_27_g_io_out_bits_data), .io_out_bits_vdIdx(vNewPipelineConnectPipe_27_g_io_out_bits_vdIdx), .io_out_bits_vdIdxInField(vNewPipelineConnectPipe_27_g_io_out_bits_vdIdxInField));
  NewPipelineConnectPipe_27_xs u_i_NewPipelineConnectPipe_27 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_27_io_in_valid), .io_in_bits_uop_exceptionVec_3(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_3), .io_in_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_4), .io_in_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_5), .io_in_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_6), .io_in_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_7), .io_in_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_13), .io_in_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_15), .io_in_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_19), .io_in_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_21), .io_in_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_23), .io_in_bits_uop_trigger(vNewPipelineConnectPipe_27_io_in_bits_uop_trigger), .io_in_bits_uop_fuOpType(vNewPipelineConnectPipe_27_io_in_bits_uop_fuOpType), .io_in_bits_uop_vecWen(vNewPipelineConnectPipe_27_io_in_bits_uop_vecWen), .io_in_bits_uop_v0Wen(vNewPipelineConnectPipe_27_io_in_bits_uop_v0Wen), .io_in_bits_uop_vlWen(vNewPipelineConnectPipe_27_io_in_bits_uop_vlWen), .io_in_bits_uop_flushPipe(vNewPipelineConnectPipe_27_io_in_bits_uop_flushPipe), .io_in_bits_uop_vpu_vma(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vma), .io_in_bits_uop_vpu_vta(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vta), .io_in_bits_uop_vpu_vsew(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vsew), .io_in_bits_uop_vpu_vlmul(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vlmul), .io_in_bits_uop_vpu_vm(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vm), .io_in_bits_uop_vpu_vstart(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vstart), .io_in_bits_uop_vpu_vuopIdx(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vuopIdx), .io_in_bits_uop_vpu_vmask(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vmask), .io_in_bits_uop_vpu_vl(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vl), .io_in_bits_uop_vpu_nf(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_nf), .io_in_bits_uop_vpu_veew(vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_veew), .io_in_bits_uop_pdest(vNewPipelineConnectPipe_27_io_in_bits_uop_pdest), .io_in_bits_uop_robIdx_flag(vNewPipelineConnectPipe_27_io_in_bits_uop_robIdx_flag), .io_in_bits_uop_robIdx_value(vNewPipelineConnectPipe_27_io_in_bits_uop_robIdx_value), .io_in_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_enqRsTime), .io_in_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_selectTime), .io_in_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_issueTime), .io_in_bits_uop_replayInst(vNewPipelineConnectPipe_27_io_in_bits_uop_replayInst), .io_in_bits_data(vNewPipelineConnectPipe_27_io_in_bits_data), .io_in_bits_vdIdx(vNewPipelineConnectPipe_27_io_in_bits_vdIdx), .io_in_bits_vdIdxInField(vNewPipelineConnectPipe_27_io_in_bits_vdIdxInField), .io_out_ready(vNewPipelineConnectPipe_27_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_27_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_27_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_27_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_27_i_io_out_valid), .io_out_bits_uop_exceptionVec_3(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_3), .io_out_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_4), .io_out_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_5), .io_out_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_6), .io_out_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_7), .io_out_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_13), .io_out_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_15), .io_out_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_19), .io_out_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_21), .io_out_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_23), .io_out_bits_uop_trigger(vNewPipelineConnectPipe_27_i_io_out_bits_uop_trigger), .io_out_bits_uop_fuOpType(vNewPipelineConnectPipe_27_i_io_out_bits_uop_fuOpType), .io_out_bits_uop_vecWen(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vecWen), .io_out_bits_uop_v0Wen(vNewPipelineConnectPipe_27_i_io_out_bits_uop_v0Wen), .io_out_bits_uop_vlWen(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vlWen), .io_out_bits_uop_flushPipe(vNewPipelineConnectPipe_27_i_io_out_bits_uop_flushPipe), .io_out_bits_uop_vpu_vma(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vma), .io_out_bits_uop_vpu_vta(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vta), .io_out_bits_uop_vpu_vsew(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vsew), .io_out_bits_uop_vpu_vlmul(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vlmul), .io_out_bits_uop_vpu_vm(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vm), .io_out_bits_uop_vpu_vstart(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vstart), .io_out_bits_uop_vpu_vuopIdx(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vuopIdx), .io_out_bits_uop_vpu_vmask(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vmask), .io_out_bits_uop_vpu_vl(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vl), .io_out_bits_uop_vpu_nf(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_nf), .io_out_bits_uop_vpu_veew(vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_veew), .io_out_bits_uop_pdest(vNewPipelineConnectPipe_27_i_io_out_bits_uop_pdest), .io_out_bits_uop_robIdx_flag(vNewPipelineConnectPipe_27_i_io_out_bits_uop_robIdx_flag), .io_out_bits_uop_robIdx_value(vNewPipelineConnectPipe_27_i_io_out_bits_uop_robIdx_value), .io_out_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_enqRsTime), .io_out_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_selectTime), .io_out_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_issueTime), .io_out_bits_uop_replayInst(vNewPipelineConnectPipe_27_i_io_out_bits_uop_replayInst), .io_out_bits_data(vNewPipelineConnectPipe_27_i_io_out_bits_data), .io_out_bits_vdIdx(vNewPipelineConnectPipe_27_i_io_out_bits_vdIdx), .io_out_bits_vdIdxInField(vNewPipelineConnectPipe_27_i_io_out_bits_vdIdxInField));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_27_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_27_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_27_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_27_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_27_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_3 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_4 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_5 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_6 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_7 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_13 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_15 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_19 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_21 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_exceptionVec_23 <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_trigger <= 4'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vecWen <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_v0Wen <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vlWen <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_flushPipe <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vma <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vta <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vsew <= 2'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vlmul <= 3'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vm <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vstart <= 8'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vuopIdx <= 7'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vmask <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_vl <= 8'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_nf <= 3'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_vpu_veew <= 2'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_27_io_in_bits_uop_debugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_27_io_in_bits_uop_replayInst <= 1'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_data <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_27_io_in_bits_vdIdx <= 3'($urandom);
      vNewPipelineConnectPipe_27_io_in_bits_vdIdxInField <= 3'($urandom);
      vNewPipelineConnectPipe_27_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_27_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_27_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_27_g_io_in_ready !== vNewPipelineConnectPipe_27_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_in_ready, vNewPipelineConnectPipe_27_i_io_in_ready); end
    if (vNewPipelineConnectPipe_27_g_io_out_valid !== vNewPipelineConnectPipe_27_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_valid, vNewPipelineConnectPipe_27_i_io_out_valid); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_3 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_3) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_3 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_3, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_3); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_4 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_4, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_4); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_5 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_5) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_5 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_5, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_5); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_6 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_6) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_6 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_6, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_6); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_7 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_7) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_7 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_7, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_7); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_13 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_13) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_13 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_13, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_13); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_15 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_15) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_15 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_15, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_15); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_19 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_19) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_19 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_19, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_19); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_21 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_21) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_21 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_21, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_21); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_23 !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_23) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_exceptionVec_23 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_exceptionVec_23, vNewPipelineConnectPipe_27_i_io_out_bits_uop_exceptionVec_23); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_trigger !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_trigger) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_trigger mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_trigger, vNewPipelineConnectPipe_27_i_io_out_bits_uop_trigger); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_fuOpType !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_fuOpType, vNewPipelineConnectPipe_27_i_io_out_bits_uop_fuOpType); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vecWen !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vecWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vecWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vecWen, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vecWen); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_v0Wen !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_v0Wen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_v0Wen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_v0Wen, vNewPipelineConnectPipe_27_i_io_out_bits_uop_v0Wen); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vlWen !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vlWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vlWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vlWen, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vlWen); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_flushPipe !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_flushPipe) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_flushPipe mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_flushPipe, vNewPipelineConnectPipe_27_i_io_out_bits_uop_flushPipe); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vma !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vma) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vma mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vma, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vma); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vta !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vta) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vta mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vta, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vta); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vsew !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vsew) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vsew mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vsew, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vsew); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vlmul !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vlmul) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vlmul mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vlmul, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vlmul); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vm !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vm) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vm mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vm, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vm); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vstart !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vstart) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vstart mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vstart, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vstart); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vuopIdx !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vuopIdx) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vuopIdx mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vuopIdx, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vuopIdx); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vmask !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vmask) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vmask mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vmask, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vmask); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vl !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vl) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_vl mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_vl, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_vl); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_nf !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_nf) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_nf mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_nf, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_nf); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_veew !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_veew) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_vpu_veew mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_vpu_veew, vNewPipelineConnectPipe_27_i_io_out_bits_uop_vpu_veew); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_pdest !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_pdest, vNewPipelineConnectPipe_27_i_io_out_bits_uop_pdest); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_robIdx_flag !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_robIdx_flag, vNewPipelineConnectPipe_27_i_io_out_bits_uop_robIdx_flag); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_robIdx_value !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_robIdx_value, vNewPipelineConnectPipe_27_i_io_out_bits_uop_robIdx_value); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_enqRsTime !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_debugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_enqRsTime, vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_selectTime !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_debugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_selectTime, vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_selectTime); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_issueTime !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_debugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_debugInfo_issueTime, vNewPipelineConnectPipe_27_i_io_out_bits_uop_debugInfo_issueTime); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_uop_replayInst !== vNewPipelineConnectPipe_27_i_io_out_bits_uop_replayInst) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_uop_replayInst mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_uop_replayInst, vNewPipelineConnectPipe_27_i_io_out_bits_uop_replayInst); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_data !== vNewPipelineConnectPipe_27_i_io_out_bits_data) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_data mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_data, vNewPipelineConnectPipe_27_i_io_out_bits_data); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_vdIdx !== vNewPipelineConnectPipe_27_i_io_out_bits_vdIdx) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_vdIdx mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_vdIdx, vNewPipelineConnectPipe_27_i_io_out_bits_vdIdx); end
    if (vNewPipelineConnectPipe_27_g_io_out_bits_vdIdxInField !== vNewPipelineConnectPipe_27_i_io_out_bits_vdIdxInField) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_27.io_out_bits_vdIdxInField mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_27_g_io_out_bits_vdIdxInField, vNewPipelineConnectPipe_27_i_io_out_bits_vdIdxInField); end
  end

  logic vNewPipelineConnectPipe_31_io_in_valid;
  logic [49:0] vNewPipelineConnectPipe_31_io_in_bits_vaddr;
  logic [127:0] vNewPipelineConnectPipe_31_io_in_bits_data;
  logic [15:0] vNewPipelineConnectPipe_31_io_in_bits_mask;
  logic [47:0] vNewPipelineConnectPipe_31_io_in_bits_addr;
  logic vNewPipelineConnectPipe_31_io_in_bits_vecValid;
  logic vNewPipelineConnectPipe_31_io_out_ready;
  logic vNewPipelineConnectPipe_31_io_rightOutFire;
  wire vNewPipelineConnectPipe_31_g_io_in_ready;
  wire vNewPipelineConnectPipe_31_i_io_in_ready;
  wire vNewPipelineConnectPipe_31_g_io_out_valid;
  wire vNewPipelineConnectPipe_31_i_io_out_valid;
  wire [49:0] vNewPipelineConnectPipe_31_g_io_out_bits_vaddr;
  wire [49:0] vNewPipelineConnectPipe_31_i_io_out_bits_vaddr;
  wire [127:0] vNewPipelineConnectPipe_31_g_io_out_bits_data;
  wire [127:0] vNewPipelineConnectPipe_31_i_io_out_bits_data;
  wire [15:0] vNewPipelineConnectPipe_31_g_io_out_bits_mask;
  wire [15:0] vNewPipelineConnectPipe_31_i_io_out_bits_mask;
  wire [47:0] vNewPipelineConnectPipe_31_g_io_out_bits_addr;
  wire [47:0] vNewPipelineConnectPipe_31_i_io_out_bits_addr;
  wire vNewPipelineConnectPipe_31_g_io_out_bits_vecValid;
  wire vNewPipelineConnectPipe_31_i_io_out_bits_vecValid;
  NewPipelineConnectPipe_31 u_g_NewPipelineConnectPipe_31 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_31_io_in_valid), .io_in_bits_vaddr(vNewPipelineConnectPipe_31_io_in_bits_vaddr), .io_in_bits_data(vNewPipelineConnectPipe_31_io_in_bits_data), .io_in_bits_mask(vNewPipelineConnectPipe_31_io_in_bits_mask), .io_in_bits_addr(vNewPipelineConnectPipe_31_io_in_bits_addr), .io_in_bits_vecValid(vNewPipelineConnectPipe_31_io_in_bits_vecValid), .io_out_ready(vNewPipelineConnectPipe_31_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_31_io_rightOutFire), .io_in_ready(vNewPipelineConnectPipe_31_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_31_g_io_out_valid), .io_out_bits_vaddr(vNewPipelineConnectPipe_31_g_io_out_bits_vaddr), .io_out_bits_data(vNewPipelineConnectPipe_31_g_io_out_bits_data), .io_out_bits_mask(vNewPipelineConnectPipe_31_g_io_out_bits_mask), .io_out_bits_addr(vNewPipelineConnectPipe_31_g_io_out_bits_addr), .io_out_bits_vecValid(vNewPipelineConnectPipe_31_g_io_out_bits_vecValid));
  NewPipelineConnectPipe_31_xs u_i_NewPipelineConnectPipe_31 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_31_io_in_valid), .io_in_bits_vaddr(vNewPipelineConnectPipe_31_io_in_bits_vaddr), .io_in_bits_data(vNewPipelineConnectPipe_31_io_in_bits_data), .io_in_bits_mask(vNewPipelineConnectPipe_31_io_in_bits_mask), .io_in_bits_addr(vNewPipelineConnectPipe_31_io_in_bits_addr), .io_in_bits_vecValid(vNewPipelineConnectPipe_31_io_in_bits_vecValid), .io_out_ready(vNewPipelineConnectPipe_31_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_31_io_rightOutFire), .io_in_ready(vNewPipelineConnectPipe_31_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_31_i_io_out_valid), .io_out_bits_vaddr(vNewPipelineConnectPipe_31_i_io_out_bits_vaddr), .io_out_bits_data(vNewPipelineConnectPipe_31_i_io_out_bits_data), .io_out_bits_mask(vNewPipelineConnectPipe_31_i_io_out_bits_mask), .io_out_bits_addr(vNewPipelineConnectPipe_31_i_io_out_bits_addr), .io_out_bits_vecValid(vNewPipelineConnectPipe_31_i_io_out_bits_vecValid));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_31_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_31_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_31_io_rightOutFire <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_31_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_31_io_in_bits_vaddr <= 50'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_31_io_in_bits_data <= 128'({$urandom(), $urandom(), $urandom(), $urandom()});
      vNewPipelineConnectPipe_31_io_in_bits_mask <= 16'($urandom);
      vNewPipelineConnectPipe_31_io_in_bits_addr <= 48'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_31_io_in_bits_vecValid <= 1'($urandom);
      vNewPipelineConnectPipe_31_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_31_io_rightOutFire <= ($urandom_range(0,3) != 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_31_g_io_in_ready !== vNewPipelineConnectPipe_31_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_31.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_31_g_io_in_ready, vNewPipelineConnectPipe_31_i_io_in_ready); end
    if (vNewPipelineConnectPipe_31_g_io_out_valid !== vNewPipelineConnectPipe_31_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_31.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_31_g_io_out_valid, vNewPipelineConnectPipe_31_i_io_out_valid); end
    if (vNewPipelineConnectPipe_31_g_io_out_bits_vaddr !== vNewPipelineConnectPipe_31_i_io_out_bits_vaddr) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_31.io_out_bits_vaddr mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_31_g_io_out_bits_vaddr, vNewPipelineConnectPipe_31_i_io_out_bits_vaddr); end
    if (vNewPipelineConnectPipe_31_g_io_out_bits_data !== vNewPipelineConnectPipe_31_i_io_out_bits_data) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_31.io_out_bits_data mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_31_g_io_out_bits_data, vNewPipelineConnectPipe_31_i_io_out_bits_data); end
    if (vNewPipelineConnectPipe_31_g_io_out_bits_mask !== vNewPipelineConnectPipe_31_i_io_out_bits_mask) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_31.io_out_bits_mask mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_31_g_io_out_bits_mask, vNewPipelineConnectPipe_31_i_io_out_bits_mask); end
    if (vNewPipelineConnectPipe_31_g_io_out_bits_addr !== vNewPipelineConnectPipe_31_i_io_out_bits_addr) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_31.io_out_bits_addr mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_31_g_io_out_bits_addr, vNewPipelineConnectPipe_31_i_io_out_bits_addr); end
    if (vNewPipelineConnectPipe_31_g_io_out_bits_vecValid !== vNewPipelineConnectPipe_31_i_io_out_bits_vecValid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_31.io_out_bits_vecValid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_31_g_io_out_bits_vecValid, vNewPipelineConnectPipe_31_i_io_out_bits_vecValid); end
  end

  logic vNewPipelineConnectPipe_32_io_in_valid;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_0;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_1;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_2;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_3;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_4;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_5;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_6;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_7;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_8;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_9;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_10;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_11;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_12;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_13;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_14;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_15;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_16;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_17;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_18;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_19;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_20;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_21;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_22;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_23;
  logic [3:0] vNewPipelineConnectPipe_32_io_in_bits_uop_trigger;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_flushPipe;
  logic vNewPipelineConnectPipe_32_io_in_bits_uop_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_32_io_in_bits_uop_robIdx_value;
  logic [63:0] vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_issueTime;
  logic vNewPipelineConnectPipe_32_io_in_bits_debug_isMMIO;
  logic vNewPipelineConnectPipe_32_io_out_ready;
  logic vNewPipelineConnectPipe_32_io_rightOutFire;
  wire vNewPipelineConnectPipe_32_g_io_in_ready;
  wire vNewPipelineConnectPipe_32_i_io_in_ready;
  wire vNewPipelineConnectPipe_32_g_io_out_valid;
  wire vNewPipelineConnectPipe_32_i_io_out_valid;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_0;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_0;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_1;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_1;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_2;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_2;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_3;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_3;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_4;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_4;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_5;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_5;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_6;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_6;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_7;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_7;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_8;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_8;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_9;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_9;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_10;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_10;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_11;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_11;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_12;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_12;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_13;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_13;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_14;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_14;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_15;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_15;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_16;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_16;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_17;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_17;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_18;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_18;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_19;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_19;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_20;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_20;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_21;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_21;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_22;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_22;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_23;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_23;
  wire [3:0] vNewPipelineConnectPipe_32_g_io_out_bits_uop_trigger;
  wire [3:0] vNewPipelineConnectPipe_32_i_io_out_bits_uop_trigger;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_flushPipe;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_flushPipe;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_uop_robIdx_flag;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_uop_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_32_g_io_out_bits_uop_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_32_i_io_out_bits_uop_robIdx_value;
  wire [63:0] vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_issueTime;
  wire vNewPipelineConnectPipe_32_g_io_out_bits_debug_isMMIO;
  wire vNewPipelineConnectPipe_32_i_io_out_bits_debug_isMMIO;
  NewPipelineConnectPipe_32 u_g_NewPipelineConnectPipe_32 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_32_io_in_valid), .io_in_bits_uop_exceptionVec_0(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_0), .io_in_bits_uop_exceptionVec_1(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_1), .io_in_bits_uop_exceptionVec_2(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_2), .io_in_bits_uop_exceptionVec_3(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_3), .io_in_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_4), .io_in_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_5), .io_in_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_6), .io_in_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_7), .io_in_bits_uop_exceptionVec_8(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_8), .io_in_bits_uop_exceptionVec_9(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_9), .io_in_bits_uop_exceptionVec_10(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_10), .io_in_bits_uop_exceptionVec_11(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_11), .io_in_bits_uop_exceptionVec_12(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_12), .io_in_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_13), .io_in_bits_uop_exceptionVec_14(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_14), .io_in_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_15), .io_in_bits_uop_exceptionVec_16(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_16), .io_in_bits_uop_exceptionVec_17(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_17), .io_in_bits_uop_exceptionVec_18(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_18), .io_in_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_19), .io_in_bits_uop_exceptionVec_20(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_20), .io_in_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_21), .io_in_bits_uop_exceptionVec_22(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_22), .io_in_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_23), .io_in_bits_uop_trigger(vNewPipelineConnectPipe_32_io_in_bits_uop_trigger), .io_in_bits_uop_flushPipe(vNewPipelineConnectPipe_32_io_in_bits_uop_flushPipe), .io_in_bits_uop_robIdx_flag(vNewPipelineConnectPipe_32_io_in_bits_uop_robIdx_flag), .io_in_bits_uop_robIdx_value(vNewPipelineConnectPipe_32_io_in_bits_uop_robIdx_value), .io_in_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_enqRsTime), .io_in_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_selectTime), .io_in_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_issueTime), .io_in_bits_debug_isMMIO(vNewPipelineConnectPipe_32_io_in_bits_debug_isMMIO), .io_out_ready(vNewPipelineConnectPipe_32_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_32_io_rightOutFire), .io_in_ready(vNewPipelineConnectPipe_32_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_32_g_io_out_valid), .io_out_bits_uop_exceptionVec_0(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_0), .io_out_bits_uop_exceptionVec_1(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_1), .io_out_bits_uop_exceptionVec_2(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_2), .io_out_bits_uop_exceptionVec_3(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_3), .io_out_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_4), .io_out_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_5), .io_out_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_6), .io_out_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_7), .io_out_bits_uop_exceptionVec_8(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_8), .io_out_bits_uop_exceptionVec_9(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_9), .io_out_bits_uop_exceptionVec_10(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_10), .io_out_bits_uop_exceptionVec_11(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_11), .io_out_bits_uop_exceptionVec_12(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_12), .io_out_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_13), .io_out_bits_uop_exceptionVec_14(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_14), .io_out_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_15), .io_out_bits_uop_exceptionVec_16(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_16), .io_out_bits_uop_exceptionVec_17(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_17), .io_out_bits_uop_exceptionVec_18(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_18), .io_out_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_19), .io_out_bits_uop_exceptionVec_20(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_20), .io_out_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_21), .io_out_bits_uop_exceptionVec_22(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_22), .io_out_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_23), .io_out_bits_uop_trigger(vNewPipelineConnectPipe_32_g_io_out_bits_uop_trigger), .io_out_bits_uop_flushPipe(vNewPipelineConnectPipe_32_g_io_out_bits_uop_flushPipe), .io_out_bits_uop_robIdx_flag(vNewPipelineConnectPipe_32_g_io_out_bits_uop_robIdx_flag), .io_out_bits_uop_robIdx_value(vNewPipelineConnectPipe_32_g_io_out_bits_uop_robIdx_value), .io_out_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_enqRsTime), .io_out_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_selectTime), .io_out_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_issueTime), .io_out_bits_debug_isMMIO(vNewPipelineConnectPipe_32_g_io_out_bits_debug_isMMIO));
  NewPipelineConnectPipe_32_xs u_i_NewPipelineConnectPipe_32 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_32_io_in_valid), .io_in_bits_uop_exceptionVec_0(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_0), .io_in_bits_uop_exceptionVec_1(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_1), .io_in_bits_uop_exceptionVec_2(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_2), .io_in_bits_uop_exceptionVec_3(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_3), .io_in_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_4), .io_in_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_5), .io_in_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_6), .io_in_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_7), .io_in_bits_uop_exceptionVec_8(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_8), .io_in_bits_uop_exceptionVec_9(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_9), .io_in_bits_uop_exceptionVec_10(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_10), .io_in_bits_uop_exceptionVec_11(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_11), .io_in_bits_uop_exceptionVec_12(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_12), .io_in_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_13), .io_in_bits_uop_exceptionVec_14(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_14), .io_in_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_15), .io_in_bits_uop_exceptionVec_16(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_16), .io_in_bits_uop_exceptionVec_17(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_17), .io_in_bits_uop_exceptionVec_18(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_18), .io_in_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_19), .io_in_bits_uop_exceptionVec_20(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_20), .io_in_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_21), .io_in_bits_uop_exceptionVec_22(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_22), .io_in_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_23), .io_in_bits_uop_trigger(vNewPipelineConnectPipe_32_io_in_bits_uop_trigger), .io_in_bits_uop_flushPipe(vNewPipelineConnectPipe_32_io_in_bits_uop_flushPipe), .io_in_bits_uop_robIdx_flag(vNewPipelineConnectPipe_32_io_in_bits_uop_robIdx_flag), .io_in_bits_uop_robIdx_value(vNewPipelineConnectPipe_32_io_in_bits_uop_robIdx_value), .io_in_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_enqRsTime), .io_in_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_selectTime), .io_in_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_issueTime), .io_in_bits_debug_isMMIO(vNewPipelineConnectPipe_32_io_in_bits_debug_isMMIO), .io_out_ready(vNewPipelineConnectPipe_32_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_32_io_rightOutFire), .io_in_ready(vNewPipelineConnectPipe_32_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_32_i_io_out_valid), .io_out_bits_uop_exceptionVec_0(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_0), .io_out_bits_uop_exceptionVec_1(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_1), .io_out_bits_uop_exceptionVec_2(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_2), .io_out_bits_uop_exceptionVec_3(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_3), .io_out_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_4), .io_out_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_5), .io_out_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_6), .io_out_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_7), .io_out_bits_uop_exceptionVec_8(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_8), .io_out_bits_uop_exceptionVec_9(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_9), .io_out_bits_uop_exceptionVec_10(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_10), .io_out_bits_uop_exceptionVec_11(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_11), .io_out_bits_uop_exceptionVec_12(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_12), .io_out_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_13), .io_out_bits_uop_exceptionVec_14(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_14), .io_out_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_15), .io_out_bits_uop_exceptionVec_16(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_16), .io_out_bits_uop_exceptionVec_17(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_17), .io_out_bits_uop_exceptionVec_18(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_18), .io_out_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_19), .io_out_bits_uop_exceptionVec_20(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_20), .io_out_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_21), .io_out_bits_uop_exceptionVec_22(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_22), .io_out_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_23), .io_out_bits_uop_trigger(vNewPipelineConnectPipe_32_i_io_out_bits_uop_trigger), .io_out_bits_uop_flushPipe(vNewPipelineConnectPipe_32_i_io_out_bits_uop_flushPipe), .io_out_bits_uop_robIdx_flag(vNewPipelineConnectPipe_32_i_io_out_bits_uop_robIdx_flag), .io_out_bits_uop_robIdx_value(vNewPipelineConnectPipe_32_i_io_out_bits_uop_robIdx_value), .io_out_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_enqRsTime), .io_out_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_selectTime), .io_out_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_issueTime), .io_out_bits_debug_isMMIO(vNewPipelineConnectPipe_32_i_io_out_bits_debug_isMMIO));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_32_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_32_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_32_io_rightOutFire <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_32_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_0 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_1 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_2 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_3 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_4 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_5 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_6 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_7 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_8 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_9 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_10 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_11 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_12 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_13 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_14 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_15 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_16 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_17 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_18 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_19 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_20 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_21 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_22 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_exceptionVec_23 <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_trigger <= 4'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_flushPipe <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_32_io_in_bits_uop_debugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_32_io_in_bits_debug_isMMIO <= 1'($urandom);
      vNewPipelineConnectPipe_32_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_32_io_rightOutFire <= ($urandom_range(0,3) != 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_32_g_io_in_ready !== vNewPipelineConnectPipe_32_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_in_ready, vNewPipelineConnectPipe_32_i_io_in_ready); end
    if (vNewPipelineConnectPipe_32_g_io_out_valid !== vNewPipelineConnectPipe_32_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_valid, vNewPipelineConnectPipe_32_i_io_out_valid); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_0 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_0) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_0 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_0, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_0); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_1 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_1) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_1 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_1, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_1); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_2 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_2) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_2 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_2, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_2); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_3 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_3) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_3 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_3, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_3); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_4 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_4, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_4); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_5 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_5) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_5 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_5, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_5); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_6 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_6) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_6 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_6, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_6); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_7 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_7) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_7 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_7, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_7); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_8 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_8) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_8 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_8, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_8); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_9 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_9) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_9 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_9, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_9); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_10 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_10) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_10 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_10, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_10); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_11 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_11) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_11 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_11, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_11); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_12 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_12) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_12 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_12, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_12); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_13 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_13) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_13 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_13, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_13); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_14 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_14) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_14 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_14, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_14); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_15 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_15) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_15 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_15, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_15); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_16 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_16) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_16 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_16, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_16); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_17 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_17) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_17 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_17, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_17); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_18 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_18) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_18 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_18, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_18); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_19 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_19) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_19 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_19, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_19); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_20 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_20) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_20 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_20, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_20); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_21 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_21) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_21 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_21, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_21); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_22 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_22) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_22 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_22, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_22); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_23 !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_23) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_exceptionVec_23 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_exceptionVec_23, vNewPipelineConnectPipe_32_i_io_out_bits_uop_exceptionVec_23); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_trigger !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_trigger) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_trigger mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_trigger, vNewPipelineConnectPipe_32_i_io_out_bits_uop_trigger); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_flushPipe !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_flushPipe) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_flushPipe mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_flushPipe, vNewPipelineConnectPipe_32_i_io_out_bits_uop_flushPipe); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_robIdx_flag !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_robIdx_flag, vNewPipelineConnectPipe_32_i_io_out_bits_uop_robIdx_flag); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_robIdx_value !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_robIdx_value, vNewPipelineConnectPipe_32_i_io_out_bits_uop_robIdx_value); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_enqRsTime !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_debugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_enqRsTime, vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_selectTime !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_debugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_selectTime, vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_selectTime); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_issueTime !== vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_uop_debugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_uop_debugInfo_issueTime, vNewPipelineConnectPipe_32_i_io_out_bits_uop_debugInfo_issueTime); end
    if (vNewPipelineConnectPipe_32_g_io_out_bits_debug_isMMIO !== vNewPipelineConnectPipe_32_i_io_out_bits_debug_isMMIO) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_32.io_out_bits_debug_isMMIO mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_32_g_io_out_bits_debug_isMMIO, vNewPipelineConnectPipe_32_i_io_out_bits_debug_isMMIO); end
  end

  logic vNewPipelineConnectPipe_33_io_in_valid;
  logic [63:0] vNewPipelineConnectPipe_33_io_in_bits_vaddr;
  logic [49:0] vNewPipelineConnectPipe_33_io_in_bits_basevaddr;
  logic [15:0] vNewPipelineConnectPipe_33_io_in_bits_mask;
  logic [3:0] vNewPipelineConnectPipe_33_io_in_bits_reg_offset;
  logic [2:0] vNewPipelineConnectPipe_33_io_in_bits_alignedType;
  logic vNewPipelineConnectPipe_33_io_in_bits_vecActive;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_4;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_5;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_6;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_7;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_13;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_15;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_19;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_21;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_23;
  logic [3:0] vNewPipelineConnectPipe_33_io_in_bits_uop_trigger;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_preDecodeInfo_isRVC;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_ftqPtr_flag;
  logic [5:0] vNewPipelineConnectPipe_33_io_in_bits_uop_ftqPtr_value;
  logic [3:0] vNewPipelineConnectPipe_33_io_in_bits_uop_ftqOffset;
  logic [8:0] vNewPipelineConnectPipe_33_io_in_bits_uop_fuOpType;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_rfWen;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_fpWen;
  logic [7:0] vNewPipelineConnectPipe_33_io_in_bits_uop_vpu_vstart;
  logic [1:0] vNewPipelineConnectPipe_33_io_in_bits_uop_vpu_veew;
  logic [6:0] vNewPipelineConnectPipe_33_io_in_bits_uop_uopIdx;
  logic [7:0] vNewPipelineConnectPipe_33_io_in_bits_uop_pdest;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_robIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_33_io_in_bits_uop_robIdx_value;
  logic [63:0] vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_enqRsTime;
  logic [63:0] vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_selectTime;
  logic [63:0] vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_issueTime;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_storeSetHit;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_waitForRobIdx_flag;
  logic [7:0] vNewPipelineConnectPipe_33_io_in_bits_uop_waitForRobIdx_value;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_loadWaitBit;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_loadWaitStrict;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_lqIdx_flag;
  logic [6:0] vNewPipelineConnectPipe_33_io_in_bits_uop_lqIdx_value;
  logic vNewPipelineConnectPipe_33_io_in_bits_uop_sqIdx_flag;
  logic [5:0] vNewPipelineConnectPipe_33_io_in_bits_uop_sqIdx_value;
  logic [3:0] vNewPipelineConnectPipe_33_io_in_bits_mBIndex;
  logic [7:0] vNewPipelineConnectPipe_33_io_in_bits_elemIdx;
  logic [7:0] vNewPipelineConnectPipe_33_io_in_bits_elemIdxInsideVd;
  logic vNewPipelineConnectPipe_33_io_out_ready;
  logic vNewPipelineConnectPipe_33_io_rightOutFire;
  logic vNewPipelineConnectPipe_33_io_isFlush;
  wire vNewPipelineConnectPipe_33_g_io_in_ready;
  wire vNewPipelineConnectPipe_33_i_io_in_ready;
  wire vNewPipelineConnectPipe_33_g_io_out_valid;
  wire vNewPipelineConnectPipe_33_i_io_out_valid;
  wire [63:0] vNewPipelineConnectPipe_33_g_io_out_bits_vaddr;
  wire [63:0] vNewPipelineConnectPipe_33_i_io_out_bits_vaddr;
  wire [49:0] vNewPipelineConnectPipe_33_g_io_out_bits_basevaddr;
  wire [49:0] vNewPipelineConnectPipe_33_i_io_out_bits_basevaddr;
  wire [15:0] vNewPipelineConnectPipe_33_g_io_out_bits_mask;
  wire [15:0] vNewPipelineConnectPipe_33_i_io_out_bits_mask;
  wire [3:0] vNewPipelineConnectPipe_33_g_io_out_bits_reg_offset;
  wire [3:0] vNewPipelineConnectPipe_33_i_io_out_bits_reg_offset;
  wire [2:0] vNewPipelineConnectPipe_33_g_io_out_bits_alignedType;
  wire [2:0] vNewPipelineConnectPipe_33_i_io_out_bits_alignedType;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_vecActive;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_vecActive;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_4;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_4;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_5;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_5;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_6;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_6;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_7;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_7;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_13;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_13;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_15;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_15;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_19;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_19;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_21;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_21;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_23;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_23;
  wire [3:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_trigger;
  wire [3:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_trigger;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_preDecodeInfo_isRVC;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_preDecodeInfo_isRVC;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqPtr_flag;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqPtr_flag;
  wire [5:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqPtr_value;
  wire [5:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqPtr_value;
  wire [3:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqOffset;
  wire [3:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqOffset;
  wire [8:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_fuOpType;
  wire [8:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_fuOpType;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_rfWen;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_rfWen;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_fpWen;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_fpWen;
  wire [7:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_vpu_vstart;
  wire [7:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_vpu_vstart;
  wire [1:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_vpu_veew;
  wire [1:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_vpu_veew;
  wire [6:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_uopIdx;
  wire [6:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_uopIdx;
  wire [7:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_pdest;
  wire [7:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_pdest;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_robIdx_flag;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_robIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_robIdx_value;
  wire [7:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_robIdx_value;
  wire [63:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_enqRsTime;
  wire [63:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_selectTime;
  wire [63:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_issueTime;
  wire [63:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_issueTime;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_storeSetHit;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_storeSetHit;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_waitForRobIdx_flag;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_waitForRobIdx_flag;
  wire [7:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_waitForRobIdx_value;
  wire [7:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_waitForRobIdx_value;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_loadWaitBit;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_loadWaitBit;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_loadWaitStrict;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_loadWaitStrict;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_lqIdx_flag;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_lqIdx_flag;
  wire [6:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_lqIdx_value;
  wire [6:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_lqIdx_value;
  wire vNewPipelineConnectPipe_33_g_io_out_bits_uop_sqIdx_flag;
  wire vNewPipelineConnectPipe_33_i_io_out_bits_uop_sqIdx_flag;
  wire [5:0] vNewPipelineConnectPipe_33_g_io_out_bits_uop_sqIdx_value;
  wire [5:0] vNewPipelineConnectPipe_33_i_io_out_bits_uop_sqIdx_value;
  wire [3:0] vNewPipelineConnectPipe_33_g_io_out_bits_mBIndex;
  wire [3:0] vNewPipelineConnectPipe_33_i_io_out_bits_mBIndex;
  wire [7:0] vNewPipelineConnectPipe_33_g_io_out_bits_elemIdx;
  wire [7:0] vNewPipelineConnectPipe_33_i_io_out_bits_elemIdx;
  wire [7:0] vNewPipelineConnectPipe_33_g_io_out_bits_elemIdxInsideVd;
  wire [7:0] vNewPipelineConnectPipe_33_i_io_out_bits_elemIdxInsideVd;
  NewPipelineConnectPipe_33 u_g_NewPipelineConnectPipe_33 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_33_io_in_valid), .io_in_bits_vaddr(vNewPipelineConnectPipe_33_io_in_bits_vaddr), .io_in_bits_basevaddr(vNewPipelineConnectPipe_33_io_in_bits_basevaddr), .io_in_bits_mask(vNewPipelineConnectPipe_33_io_in_bits_mask), .io_in_bits_reg_offset(vNewPipelineConnectPipe_33_io_in_bits_reg_offset), .io_in_bits_alignedType(vNewPipelineConnectPipe_33_io_in_bits_alignedType), .io_in_bits_vecActive(vNewPipelineConnectPipe_33_io_in_bits_vecActive), .io_in_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_4), .io_in_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_5), .io_in_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_6), .io_in_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_7), .io_in_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_13), .io_in_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_15), .io_in_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_19), .io_in_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_21), .io_in_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_23), .io_in_bits_uop_trigger(vNewPipelineConnectPipe_33_io_in_bits_uop_trigger), .io_in_bits_uop_preDecodeInfo_isRVC(vNewPipelineConnectPipe_33_io_in_bits_uop_preDecodeInfo_isRVC), .io_in_bits_uop_ftqPtr_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_ftqPtr_flag), .io_in_bits_uop_ftqPtr_value(vNewPipelineConnectPipe_33_io_in_bits_uop_ftqPtr_value), .io_in_bits_uop_ftqOffset(vNewPipelineConnectPipe_33_io_in_bits_uop_ftqOffset), .io_in_bits_uop_fuOpType(vNewPipelineConnectPipe_33_io_in_bits_uop_fuOpType), .io_in_bits_uop_rfWen(vNewPipelineConnectPipe_33_io_in_bits_uop_rfWen), .io_in_bits_uop_fpWen(vNewPipelineConnectPipe_33_io_in_bits_uop_fpWen), .io_in_bits_uop_vpu_vstart(vNewPipelineConnectPipe_33_io_in_bits_uop_vpu_vstart), .io_in_bits_uop_vpu_veew(vNewPipelineConnectPipe_33_io_in_bits_uop_vpu_veew), .io_in_bits_uop_uopIdx(vNewPipelineConnectPipe_33_io_in_bits_uop_uopIdx), .io_in_bits_uop_pdest(vNewPipelineConnectPipe_33_io_in_bits_uop_pdest), .io_in_bits_uop_robIdx_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_robIdx_flag), .io_in_bits_uop_robIdx_value(vNewPipelineConnectPipe_33_io_in_bits_uop_robIdx_value), .io_in_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_enqRsTime), .io_in_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_selectTime), .io_in_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_issueTime), .io_in_bits_uop_storeSetHit(vNewPipelineConnectPipe_33_io_in_bits_uop_storeSetHit), .io_in_bits_uop_waitForRobIdx_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_waitForRobIdx_flag), .io_in_bits_uop_waitForRobIdx_value(vNewPipelineConnectPipe_33_io_in_bits_uop_waitForRobIdx_value), .io_in_bits_uop_loadWaitBit(vNewPipelineConnectPipe_33_io_in_bits_uop_loadWaitBit), .io_in_bits_uop_loadWaitStrict(vNewPipelineConnectPipe_33_io_in_bits_uop_loadWaitStrict), .io_in_bits_uop_lqIdx_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_lqIdx_flag), .io_in_bits_uop_lqIdx_value(vNewPipelineConnectPipe_33_io_in_bits_uop_lqIdx_value), .io_in_bits_uop_sqIdx_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_sqIdx_flag), .io_in_bits_uop_sqIdx_value(vNewPipelineConnectPipe_33_io_in_bits_uop_sqIdx_value), .io_in_bits_mBIndex(vNewPipelineConnectPipe_33_io_in_bits_mBIndex), .io_in_bits_elemIdx(vNewPipelineConnectPipe_33_io_in_bits_elemIdx), .io_in_bits_elemIdxInsideVd(vNewPipelineConnectPipe_33_io_in_bits_elemIdxInsideVd), .io_out_ready(vNewPipelineConnectPipe_33_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_33_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_33_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_33_g_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_33_g_io_out_valid), .io_out_bits_vaddr(vNewPipelineConnectPipe_33_g_io_out_bits_vaddr), .io_out_bits_basevaddr(vNewPipelineConnectPipe_33_g_io_out_bits_basevaddr), .io_out_bits_mask(vNewPipelineConnectPipe_33_g_io_out_bits_mask), .io_out_bits_reg_offset(vNewPipelineConnectPipe_33_g_io_out_bits_reg_offset), .io_out_bits_alignedType(vNewPipelineConnectPipe_33_g_io_out_bits_alignedType), .io_out_bits_vecActive(vNewPipelineConnectPipe_33_g_io_out_bits_vecActive), .io_out_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_4), .io_out_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_5), .io_out_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_6), .io_out_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_7), .io_out_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_13), .io_out_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_15), .io_out_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_19), .io_out_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_21), .io_out_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_23), .io_out_bits_uop_trigger(vNewPipelineConnectPipe_33_g_io_out_bits_uop_trigger), .io_out_bits_uop_preDecodeInfo_isRVC(vNewPipelineConnectPipe_33_g_io_out_bits_uop_preDecodeInfo_isRVC), .io_out_bits_uop_ftqPtr_flag(vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqPtr_flag), .io_out_bits_uop_ftqPtr_value(vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqPtr_value), .io_out_bits_uop_ftqOffset(vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqOffset), .io_out_bits_uop_fuOpType(vNewPipelineConnectPipe_33_g_io_out_bits_uop_fuOpType), .io_out_bits_uop_rfWen(vNewPipelineConnectPipe_33_g_io_out_bits_uop_rfWen), .io_out_bits_uop_fpWen(vNewPipelineConnectPipe_33_g_io_out_bits_uop_fpWen), .io_out_bits_uop_vpu_vstart(vNewPipelineConnectPipe_33_g_io_out_bits_uop_vpu_vstart), .io_out_bits_uop_vpu_veew(vNewPipelineConnectPipe_33_g_io_out_bits_uop_vpu_veew), .io_out_bits_uop_uopIdx(vNewPipelineConnectPipe_33_g_io_out_bits_uop_uopIdx), .io_out_bits_uop_pdest(vNewPipelineConnectPipe_33_g_io_out_bits_uop_pdest), .io_out_bits_uop_robIdx_flag(vNewPipelineConnectPipe_33_g_io_out_bits_uop_robIdx_flag), .io_out_bits_uop_robIdx_value(vNewPipelineConnectPipe_33_g_io_out_bits_uop_robIdx_value), .io_out_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_enqRsTime), .io_out_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_selectTime), .io_out_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_issueTime), .io_out_bits_uop_storeSetHit(vNewPipelineConnectPipe_33_g_io_out_bits_uop_storeSetHit), .io_out_bits_uop_waitForRobIdx_flag(vNewPipelineConnectPipe_33_g_io_out_bits_uop_waitForRobIdx_flag), .io_out_bits_uop_waitForRobIdx_value(vNewPipelineConnectPipe_33_g_io_out_bits_uop_waitForRobIdx_value), .io_out_bits_uop_loadWaitBit(vNewPipelineConnectPipe_33_g_io_out_bits_uop_loadWaitBit), .io_out_bits_uop_loadWaitStrict(vNewPipelineConnectPipe_33_g_io_out_bits_uop_loadWaitStrict), .io_out_bits_uop_lqIdx_flag(vNewPipelineConnectPipe_33_g_io_out_bits_uop_lqIdx_flag), .io_out_bits_uop_lqIdx_value(vNewPipelineConnectPipe_33_g_io_out_bits_uop_lqIdx_value), .io_out_bits_uop_sqIdx_flag(vNewPipelineConnectPipe_33_g_io_out_bits_uop_sqIdx_flag), .io_out_bits_uop_sqIdx_value(vNewPipelineConnectPipe_33_g_io_out_bits_uop_sqIdx_value), .io_out_bits_mBIndex(vNewPipelineConnectPipe_33_g_io_out_bits_mBIndex), .io_out_bits_elemIdx(vNewPipelineConnectPipe_33_g_io_out_bits_elemIdx), .io_out_bits_elemIdxInsideVd(vNewPipelineConnectPipe_33_g_io_out_bits_elemIdxInsideVd));
  NewPipelineConnectPipe_33_xs u_i_NewPipelineConnectPipe_33 (.clock(clk), .reset(rst), .io_in_valid(vNewPipelineConnectPipe_33_io_in_valid), .io_in_bits_vaddr(vNewPipelineConnectPipe_33_io_in_bits_vaddr), .io_in_bits_basevaddr(vNewPipelineConnectPipe_33_io_in_bits_basevaddr), .io_in_bits_mask(vNewPipelineConnectPipe_33_io_in_bits_mask), .io_in_bits_reg_offset(vNewPipelineConnectPipe_33_io_in_bits_reg_offset), .io_in_bits_alignedType(vNewPipelineConnectPipe_33_io_in_bits_alignedType), .io_in_bits_vecActive(vNewPipelineConnectPipe_33_io_in_bits_vecActive), .io_in_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_4), .io_in_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_5), .io_in_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_6), .io_in_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_7), .io_in_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_13), .io_in_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_15), .io_in_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_19), .io_in_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_21), .io_in_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_23), .io_in_bits_uop_trigger(vNewPipelineConnectPipe_33_io_in_bits_uop_trigger), .io_in_bits_uop_preDecodeInfo_isRVC(vNewPipelineConnectPipe_33_io_in_bits_uop_preDecodeInfo_isRVC), .io_in_bits_uop_ftqPtr_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_ftqPtr_flag), .io_in_bits_uop_ftqPtr_value(vNewPipelineConnectPipe_33_io_in_bits_uop_ftqPtr_value), .io_in_bits_uop_ftqOffset(vNewPipelineConnectPipe_33_io_in_bits_uop_ftqOffset), .io_in_bits_uop_fuOpType(vNewPipelineConnectPipe_33_io_in_bits_uop_fuOpType), .io_in_bits_uop_rfWen(vNewPipelineConnectPipe_33_io_in_bits_uop_rfWen), .io_in_bits_uop_fpWen(vNewPipelineConnectPipe_33_io_in_bits_uop_fpWen), .io_in_bits_uop_vpu_vstart(vNewPipelineConnectPipe_33_io_in_bits_uop_vpu_vstart), .io_in_bits_uop_vpu_veew(vNewPipelineConnectPipe_33_io_in_bits_uop_vpu_veew), .io_in_bits_uop_uopIdx(vNewPipelineConnectPipe_33_io_in_bits_uop_uopIdx), .io_in_bits_uop_pdest(vNewPipelineConnectPipe_33_io_in_bits_uop_pdest), .io_in_bits_uop_robIdx_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_robIdx_flag), .io_in_bits_uop_robIdx_value(vNewPipelineConnectPipe_33_io_in_bits_uop_robIdx_value), .io_in_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_enqRsTime), .io_in_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_selectTime), .io_in_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_issueTime), .io_in_bits_uop_storeSetHit(vNewPipelineConnectPipe_33_io_in_bits_uop_storeSetHit), .io_in_bits_uop_waitForRobIdx_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_waitForRobIdx_flag), .io_in_bits_uop_waitForRobIdx_value(vNewPipelineConnectPipe_33_io_in_bits_uop_waitForRobIdx_value), .io_in_bits_uop_loadWaitBit(vNewPipelineConnectPipe_33_io_in_bits_uop_loadWaitBit), .io_in_bits_uop_loadWaitStrict(vNewPipelineConnectPipe_33_io_in_bits_uop_loadWaitStrict), .io_in_bits_uop_lqIdx_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_lqIdx_flag), .io_in_bits_uop_lqIdx_value(vNewPipelineConnectPipe_33_io_in_bits_uop_lqIdx_value), .io_in_bits_uop_sqIdx_flag(vNewPipelineConnectPipe_33_io_in_bits_uop_sqIdx_flag), .io_in_bits_uop_sqIdx_value(vNewPipelineConnectPipe_33_io_in_bits_uop_sqIdx_value), .io_in_bits_mBIndex(vNewPipelineConnectPipe_33_io_in_bits_mBIndex), .io_in_bits_elemIdx(vNewPipelineConnectPipe_33_io_in_bits_elemIdx), .io_in_bits_elemIdxInsideVd(vNewPipelineConnectPipe_33_io_in_bits_elemIdxInsideVd), .io_out_ready(vNewPipelineConnectPipe_33_io_out_ready), .io_rightOutFire(vNewPipelineConnectPipe_33_io_rightOutFire), .io_isFlush(vNewPipelineConnectPipe_33_io_isFlush), .io_in_ready(vNewPipelineConnectPipe_33_i_io_in_ready), .io_out_valid(vNewPipelineConnectPipe_33_i_io_out_valid), .io_out_bits_vaddr(vNewPipelineConnectPipe_33_i_io_out_bits_vaddr), .io_out_bits_basevaddr(vNewPipelineConnectPipe_33_i_io_out_bits_basevaddr), .io_out_bits_mask(vNewPipelineConnectPipe_33_i_io_out_bits_mask), .io_out_bits_reg_offset(vNewPipelineConnectPipe_33_i_io_out_bits_reg_offset), .io_out_bits_alignedType(vNewPipelineConnectPipe_33_i_io_out_bits_alignedType), .io_out_bits_vecActive(vNewPipelineConnectPipe_33_i_io_out_bits_vecActive), .io_out_bits_uop_exceptionVec_4(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_4), .io_out_bits_uop_exceptionVec_5(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_5), .io_out_bits_uop_exceptionVec_6(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_6), .io_out_bits_uop_exceptionVec_7(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_7), .io_out_bits_uop_exceptionVec_13(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_13), .io_out_bits_uop_exceptionVec_15(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_15), .io_out_bits_uop_exceptionVec_19(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_19), .io_out_bits_uop_exceptionVec_21(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_21), .io_out_bits_uop_exceptionVec_23(vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_23), .io_out_bits_uop_trigger(vNewPipelineConnectPipe_33_i_io_out_bits_uop_trigger), .io_out_bits_uop_preDecodeInfo_isRVC(vNewPipelineConnectPipe_33_i_io_out_bits_uop_preDecodeInfo_isRVC), .io_out_bits_uop_ftqPtr_flag(vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqPtr_flag), .io_out_bits_uop_ftqPtr_value(vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqPtr_value), .io_out_bits_uop_ftqOffset(vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqOffset), .io_out_bits_uop_fuOpType(vNewPipelineConnectPipe_33_i_io_out_bits_uop_fuOpType), .io_out_bits_uop_rfWen(vNewPipelineConnectPipe_33_i_io_out_bits_uop_rfWen), .io_out_bits_uop_fpWen(vNewPipelineConnectPipe_33_i_io_out_bits_uop_fpWen), .io_out_bits_uop_vpu_vstart(vNewPipelineConnectPipe_33_i_io_out_bits_uop_vpu_vstart), .io_out_bits_uop_vpu_veew(vNewPipelineConnectPipe_33_i_io_out_bits_uop_vpu_veew), .io_out_bits_uop_uopIdx(vNewPipelineConnectPipe_33_i_io_out_bits_uop_uopIdx), .io_out_bits_uop_pdest(vNewPipelineConnectPipe_33_i_io_out_bits_uop_pdest), .io_out_bits_uop_robIdx_flag(vNewPipelineConnectPipe_33_i_io_out_bits_uop_robIdx_flag), .io_out_bits_uop_robIdx_value(vNewPipelineConnectPipe_33_i_io_out_bits_uop_robIdx_value), .io_out_bits_uop_debugInfo_enqRsTime(vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_enqRsTime), .io_out_bits_uop_debugInfo_selectTime(vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_selectTime), .io_out_bits_uop_debugInfo_issueTime(vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_issueTime), .io_out_bits_uop_storeSetHit(vNewPipelineConnectPipe_33_i_io_out_bits_uop_storeSetHit), .io_out_bits_uop_waitForRobIdx_flag(vNewPipelineConnectPipe_33_i_io_out_bits_uop_waitForRobIdx_flag), .io_out_bits_uop_waitForRobIdx_value(vNewPipelineConnectPipe_33_i_io_out_bits_uop_waitForRobIdx_value), .io_out_bits_uop_loadWaitBit(vNewPipelineConnectPipe_33_i_io_out_bits_uop_loadWaitBit), .io_out_bits_uop_loadWaitStrict(vNewPipelineConnectPipe_33_i_io_out_bits_uop_loadWaitStrict), .io_out_bits_uop_lqIdx_flag(vNewPipelineConnectPipe_33_i_io_out_bits_uop_lqIdx_flag), .io_out_bits_uop_lqIdx_value(vNewPipelineConnectPipe_33_i_io_out_bits_uop_lqIdx_value), .io_out_bits_uop_sqIdx_flag(vNewPipelineConnectPipe_33_i_io_out_bits_uop_sqIdx_flag), .io_out_bits_uop_sqIdx_value(vNewPipelineConnectPipe_33_i_io_out_bits_uop_sqIdx_value), .io_out_bits_mBIndex(vNewPipelineConnectPipe_33_i_io_out_bits_mBIndex), .io_out_bits_elemIdx(vNewPipelineConnectPipe_33_i_io_out_bits_elemIdx), .io_out_bits_elemIdxInsideVd(vNewPipelineConnectPipe_33_i_io_out_bits_elemIdxInsideVd));
  always @(negedge clk) begin
    if (rst) begin
      vNewPipelineConnectPipe_33_io_in_valid <= 1'b0;
      vNewPipelineConnectPipe_33_io_out_ready <= 1'b0;
      vNewPipelineConnectPipe_33_io_rightOutFire <= 1'b0;
      vNewPipelineConnectPipe_33_io_isFlush <= 1'b0;
    end else begin
      vNewPipelineConnectPipe_33_io_in_valid <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_33_io_in_bits_vaddr <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_33_io_in_bits_basevaddr <= 50'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_33_io_in_bits_mask <= 16'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_reg_offset <= 4'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_alignedType <= 3'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_vecActive <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_4 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_5 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_6 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_7 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_13 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_15 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_19 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_21 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_exceptionVec_23 <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_trigger <= 4'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_preDecodeInfo_isRVC <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_ftqPtr_flag <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_ftqPtr_value <= 6'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_ftqOffset <= 4'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_fuOpType <= 9'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_rfWen <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_fpWen <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_vpu_vstart <= 8'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_vpu_veew <= 2'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_uopIdx <= 7'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_pdest <= 8'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_robIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_robIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_enqRsTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_selectTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_33_io_in_bits_uop_debugInfo_issueTime <= 64'({$urandom(), $urandom()});
      vNewPipelineConnectPipe_33_io_in_bits_uop_storeSetHit <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_waitForRobIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_waitForRobIdx_value <= 8'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_loadWaitBit <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_loadWaitStrict <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_lqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_lqIdx_value <= 7'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_sqIdx_flag <= 1'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_uop_sqIdx_value <= 6'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_mBIndex <= 4'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_elemIdx <= 8'($urandom);
      vNewPipelineConnectPipe_33_io_in_bits_elemIdxInsideVd <= 8'($urandom);
      vNewPipelineConnectPipe_33_io_out_ready <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_33_io_rightOutFire <= ($urandom_range(0,3) != 0);
      vNewPipelineConnectPipe_33_io_isFlush <= ($urandom_range(0,15) == 0);
    end
  end
  always @(negedge clk) if (!rst && cycle > WARMUP) begin
    #4; checks++;
    if (vNewPipelineConnectPipe_33_g_io_in_ready !== vNewPipelineConnectPipe_33_i_io_in_ready) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_in_ready mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_in_ready, vNewPipelineConnectPipe_33_i_io_in_ready); end
    if (vNewPipelineConnectPipe_33_g_io_out_valid !== vNewPipelineConnectPipe_33_i_io_out_valid) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_valid mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_valid, vNewPipelineConnectPipe_33_i_io_out_valid); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_vaddr !== vNewPipelineConnectPipe_33_i_io_out_bits_vaddr) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_vaddr mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_vaddr, vNewPipelineConnectPipe_33_i_io_out_bits_vaddr); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_basevaddr !== vNewPipelineConnectPipe_33_i_io_out_bits_basevaddr) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_basevaddr mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_basevaddr, vNewPipelineConnectPipe_33_i_io_out_bits_basevaddr); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_mask !== vNewPipelineConnectPipe_33_i_io_out_bits_mask) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_mask mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_mask, vNewPipelineConnectPipe_33_i_io_out_bits_mask); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_reg_offset !== vNewPipelineConnectPipe_33_i_io_out_bits_reg_offset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_reg_offset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_reg_offset, vNewPipelineConnectPipe_33_i_io_out_bits_reg_offset); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_alignedType !== vNewPipelineConnectPipe_33_i_io_out_bits_alignedType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_alignedType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_alignedType, vNewPipelineConnectPipe_33_i_io_out_bits_alignedType); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_vecActive !== vNewPipelineConnectPipe_33_i_io_out_bits_vecActive) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_vecActive mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_vecActive, vNewPipelineConnectPipe_33_i_io_out_bits_vecActive); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_4 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_4) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_4 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_4, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_4); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_5 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_5) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_5 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_5, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_5); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_6 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_6) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_6 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_6, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_6); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_7 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_7) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_7 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_7, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_7); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_13 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_13) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_13 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_13, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_13); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_15 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_15) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_15 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_15, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_15); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_19 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_19) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_19 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_19, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_19); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_21 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_21) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_21 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_21, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_21); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_23 !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_23) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_exceptionVec_23 mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_exceptionVec_23, vNewPipelineConnectPipe_33_i_io_out_bits_uop_exceptionVec_23); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_trigger !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_trigger) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_trigger mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_trigger, vNewPipelineConnectPipe_33_i_io_out_bits_uop_trigger); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_preDecodeInfo_isRVC !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_preDecodeInfo_isRVC) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_preDecodeInfo_isRVC mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_preDecodeInfo_isRVC, vNewPipelineConnectPipe_33_i_io_out_bits_uop_preDecodeInfo_isRVC); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqPtr_flag !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqPtr_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_ftqPtr_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqPtr_flag, vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqPtr_flag); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqPtr_value !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqPtr_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_ftqPtr_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqPtr_value, vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqPtr_value); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqOffset !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqOffset) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_ftqOffset mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_ftqOffset, vNewPipelineConnectPipe_33_i_io_out_bits_uop_ftqOffset); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_fuOpType !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_fuOpType) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_fuOpType mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_fuOpType, vNewPipelineConnectPipe_33_i_io_out_bits_uop_fuOpType); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_rfWen !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_rfWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_rfWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_rfWen, vNewPipelineConnectPipe_33_i_io_out_bits_uop_rfWen); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_fpWen !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_fpWen) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_fpWen mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_fpWen, vNewPipelineConnectPipe_33_i_io_out_bits_uop_fpWen); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_vpu_vstart !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_vpu_vstart) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_vpu_vstart mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_vpu_vstart, vNewPipelineConnectPipe_33_i_io_out_bits_uop_vpu_vstart); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_vpu_veew !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_vpu_veew) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_vpu_veew mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_vpu_veew, vNewPipelineConnectPipe_33_i_io_out_bits_uop_vpu_veew); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_uopIdx !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_uopIdx) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_uopIdx mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_uopIdx, vNewPipelineConnectPipe_33_i_io_out_bits_uop_uopIdx); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_pdest !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_pdest) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_pdest mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_pdest, vNewPipelineConnectPipe_33_i_io_out_bits_uop_pdest); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_robIdx_flag !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_robIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_robIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_robIdx_flag, vNewPipelineConnectPipe_33_i_io_out_bits_uop_robIdx_flag); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_robIdx_value !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_robIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_robIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_robIdx_value, vNewPipelineConnectPipe_33_i_io_out_bits_uop_robIdx_value); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_enqRsTime !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_enqRsTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_debugInfo_enqRsTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_enqRsTime, vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_enqRsTime); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_selectTime !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_selectTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_debugInfo_selectTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_selectTime, vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_selectTime); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_issueTime !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_issueTime) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_debugInfo_issueTime mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_debugInfo_issueTime, vNewPipelineConnectPipe_33_i_io_out_bits_uop_debugInfo_issueTime); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_storeSetHit !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_storeSetHit) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_storeSetHit mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_storeSetHit, vNewPipelineConnectPipe_33_i_io_out_bits_uop_storeSetHit); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_waitForRobIdx_flag !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_waitForRobIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_waitForRobIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_waitForRobIdx_flag, vNewPipelineConnectPipe_33_i_io_out_bits_uop_waitForRobIdx_flag); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_waitForRobIdx_value !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_waitForRobIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_waitForRobIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_waitForRobIdx_value, vNewPipelineConnectPipe_33_i_io_out_bits_uop_waitForRobIdx_value); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_loadWaitBit !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_loadWaitBit) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_loadWaitBit mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_loadWaitBit, vNewPipelineConnectPipe_33_i_io_out_bits_uop_loadWaitBit); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_loadWaitStrict !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_loadWaitStrict) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_loadWaitStrict mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_loadWaitStrict, vNewPipelineConnectPipe_33_i_io_out_bits_uop_loadWaitStrict); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_lqIdx_flag !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_lqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_lqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_lqIdx_flag, vNewPipelineConnectPipe_33_i_io_out_bits_uop_lqIdx_flag); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_lqIdx_value !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_lqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_lqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_lqIdx_value, vNewPipelineConnectPipe_33_i_io_out_bits_uop_lqIdx_value); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_sqIdx_flag !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_sqIdx_flag) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_sqIdx_flag mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_sqIdx_flag, vNewPipelineConnectPipe_33_i_io_out_bits_uop_sqIdx_flag); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_uop_sqIdx_value !== vNewPipelineConnectPipe_33_i_io_out_bits_uop_sqIdx_value) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_uop_sqIdx_value mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_uop_sqIdx_value, vNewPipelineConnectPipe_33_i_io_out_bits_uop_sqIdx_value); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_mBIndex !== vNewPipelineConnectPipe_33_i_io_out_bits_mBIndex) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_mBIndex mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_mBIndex, vNewPipelineConnectPipe_33_i_io_out_bits_mBIndex); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_elemIdx !== vNewPipelineConnectPipe_33_i_io_out_bits_elemIdx) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_elemIdx mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_elemIdx, vNewPipelineConnectPipe_33_i_io_out_bits_elemIdx); end
    if (vNewPipelineConnectPipe_33_g_io_out_bits_elemIdxInsideVd !== vNewPipelineConnectPipe_33_i_io_out_bits_elemIdxInsideVd) begin errors++;
      $display("[%0t] NewPipelineConnectPipe_33.io_out_bits_elemIdxInsideVd mismatch g=%h i=%h", $time, vNewPipelineConnectPipe_33_g_io_out_bits_elemIdxInsideVd, vNewPipelineConnectPipe_33_i_io_out_bits_elemIdxInsideVd); end
  end

  initial begin
    if (!$value$plusargs("ncycles=%d", NCYCLES)) NCYCLES = 50000;
    $fsdbDumpfile("novas.fsdb"); $fsdbDumpvars(0, tb);
    rst = 1; repeat (5) @(posedge clk); rst = 0;
    repeat (NCYCLES) @(posedge clk);
    $display("---------------------------------------------");
    $display("checks=%0d errors=%0d", checks, errors);
    if (errors == 0 && checks > 1000) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule

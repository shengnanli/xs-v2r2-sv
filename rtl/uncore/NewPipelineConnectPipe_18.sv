// NewPipelineConnectPipe_18 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）

module NewPipelineConnectPipe_18(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_imm,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  io_in_bits_isFirstIssue,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  io_in_bits_sqIdx_flag,
  input  [5:0] io_in_bits_sqIdx_value,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  io_out_ready,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_imm,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output io_out_bits_isFirstIssue,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output io_out_bits_sqIdx_flag,
  output [5:0] io_out_bits_sqIdx_value,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [399:0] out_bus;
  assign io_out_bits_fuType = out_bus[399:365];
  assign io_out_bits_fuOpType = out_bus[364:356];
  assign io_out_bits_src_0 = out_bus[355:292];
  assign io_out_bits_imm = out_bus[291:228];
  assign io_out_bits_robIdx_flag = out_bus[227:227];
  assign io_out_bits_robIdx_value = out_bus[226:219];
  assign io_out_bits_isFirstIssue = out_bus[218:218];
  assign io_out_bits_pdest = out_bus[217:210];
  assign io_out_bits_rfWen = out_bus[209:209];
  assign io_out_bits_ftqIdx_value = out_bus[208:203];
  assign io_out_bits_ftqOffset = out_bus[202:199];
  assign io_out_bits_sqIdx_flag = out_bus[198:198];
  assign io_out_bits_sqIdx_value = out_bus[197:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(400)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_imm, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_isFirstIssue, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_sqIdx_flag, io_in_bits_sqIdx_value, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

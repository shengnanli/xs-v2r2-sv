// NewPipelineConnectPipe_8 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）

module NewPipelineConnectPipe_8(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  [63:0] io_in_bits_src_2,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  io_in_bits_fpWen,
  input  io_in_bits_vecWen,
  input  io_in_bits_v0Wen,
  input  io_in_bits_fpu_wflags,
  input  [1:0] io_in_bits_fpu_fmt,
  input  [2:0] io_in_bits_fpu_rm,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output [63:0] io_out_bits_src_2,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output io_out_bits_vecWen,
  output io_out_bits_v0Wen,
  output io_out_bits_fpu_wflags,
  output [1:0] io_out_bits_fpu_fmt,
  output [2:0] io_out_bits_fpu_rm,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [454:0] out_bus;
  assign io_out_bits_fuType = out_bus[454:420];
  assign io_out_bits_fuOpType = out_bus[419:411];
  assign io_out_bits_src_0 = out_bus[410:347];
  assign io_out_bits_src_1 = out_bus[346:283];
  assign io_out_bits_src_2 = out_bus[282:219];
  assign io_out_bits_robIdx_flag = out_bus[218:218];
  assign io_out_bits_robIdx_value = out_bus[217:210];
  assign io_out_bits_pdest = out_bus[209:202];
  assign io_out_bits_rfWen = out_bus[201:201];
  assign io_out_bits_fpWen = out_bus[200:200];
  assign io_out_bits_vecWen = out_bus[199:199];
  assign io_out_bits_v0Wen = out_bus[198:198];
  assign io_out_bits_fpu_wflags = out_bus[197:197];
  assign io_out_bits_fpu_fmt = out_bus[196:195];
  assign io_out_bits_fpu_rm = out_bus[194:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(455)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_src_2, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_fpu_wflags, io_in_bits_fpu_fmt, io_in_bits_fpu_rm, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

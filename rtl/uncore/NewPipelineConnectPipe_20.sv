// NewPipelineConnectPipe_20 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）

module NewPipelineConnectPipe_20(
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
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  io_in_bits_fpWen,
  input  [49:0] io_in_bits_pc,
  input  io_in_bits_preDecode_isRVC,
  input  io_in_bits_ftqIdx_flag,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  io_in_bits_loadWaitBit,
  input  io_in_bits_waitForRobIdx_flag,
  input  [7:0] io_in_bits_waitForRobIdx_value,
  input  io_in_bits_storeSetHit,
  input  io_in_bits_loadWaitStrict,
  input  io_in_bits_sqIdx_flag,
  input  [5:0] io_in_bits_sqIdx_value,
  input  io_in_bits_lqIdx_flag,
  input  [6:0] io_in_bits_lqIdx_value,
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
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output [49:0] io_out_bits_pc,
  output io_out_bits_preDecode_isRVC,
  output io_out_bits_ftqIdx_flag,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output io_out_bits_loadWaitBit,
  output io_out_bits_waitForRobIdx_flag,
  output [7:0] io_out_bits_waitForRobIdx_value,
  output io_out_bits_storeSetHit,
  output io_out_bits_loadWaitStrict,
  output io_out_bits_sqIdx_flag,
  output [5:0] io_out_bits_sqIdx_value,
  output io_out_bits_lqIdx_flag,
  output [6:0] io_out_bits_lqIdx_value,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [471:0] out_bus;
  assign io_out_bits_fuType = out_bus[471:437];
  assign io_out_bits_fuOpType = out_bus[436:428];
  assign io_out_bits_src_0 = out_bus[427:364];
  assign io_out_bits_imm = out_bus[363:300];
  assign io_out_bits_robIdx_flag = out_bus[299:299];
  assign io_out_bits_robIdx_value = out_bus[298:291];
  assign io_out_bits_pdest = out_bus[290:283];
  assign io_out_bits_rfWen = out_bus[282:282];
  assign io_out_bits_fpWen = out_bus[281:281];
  assign io_out_bits_pc = out_bus[280:231];
  assign io_out_bits_preDecode_isRVC = out_bus[230:230];
  assign io_out_bits_ftqIdx_flag = out_bus[229:229];
  assign io_out_bits_ftqIdx_value = out_bus[228:223];
  assign io_out_bits_ftqOffset = out_bus[222:219];
  assign io_out_bits_loadWaitBit = out_bus[218:218];
  assign io_out_bits_waitForRobIdx_flag = out_bus[217:217];
  assign io_out_bits_waitForRobIdx_value = out_bus[216:209];
  assign io_out_bits_storeSetHit = out_bus[208:208];
  assign io_out_bits_loadWaitStrict = out_bus[207:207];
  assign io_out_bits_sqIdx_flag = out_bus[206:206];
  assign io_out_bits_sqIdx_value = out_bus[205:200];
  assign io_out_bits_lqIdx_flag = out_bus[199:199];
  assign io_out_bits_lqIdx_value = out_bus[198:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(472)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_imm, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_pc, io_in_bits_preDecode_isRVC, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_loadWaitBit, io_in_bits_waitForRobIdx_flag, io_in_bits_waitForRobIdx_value, io_in_bits_storeSetHit, io_in_bits_loadWaitStrict, io_in_bits_sqIdx_flag, io_in_bits_sqIdx_value, io_in_bits_lqIdx_flag, io_in_bits_lqIdx_value, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

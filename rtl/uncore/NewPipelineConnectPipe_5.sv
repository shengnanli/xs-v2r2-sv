// NewPipelineConnectPipe_5 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）
// 本文件只做端口适配与直通，不含逻辑。
// 端口规模：32 输入 / 28 输出。

module NewPipelineConnectPipe_5(
  input  clock,
  input  reset,
  input  io_in_valid,
  input  [34:0] io_in_bits_fuType,
  input  [8:0] io_in_bits_fuOpType,
  input  [63:0] io_in_bits_src_0,
  input  [63:0] io_in_bits_src_1,
  input  [63:0] io_in_bits_imm,
  input  [4:0] io_in_bits_nextPcOffset,
  input  io_in_bits_robIdx_flag,
  input  [7:0] io_in_bits_robIdx_value,
  input  [7:0] io_in_bits_pdest,
  input  io_in_bits_rfWen,
  input  io_in_bits_fpWen,
  input  io_in_bits_vecWen,
  input  io_in_bits_v0Wen,
  input  io_in_bits_vlWen,
  input  [1:0] io_in_bits_fpu_typeTagOut,
  input  io_in_bits_fpu_wflags,
  input  [1:0] io_in_bits_fpu_typ,
  input  [2:0] io_in_bits_fpu_rm,
  input  [49:0] io_in_bits_pc,
  input  io_in_bits_ftqIdx_flag,
  input  [5:0] io_in_bits_ftqIdx_value,
  input  [3:0] io_in_bits_ftqOffset,
  input  [49:0] io_in_bits_predictInfo_target,
  input  io_in_bits_predictInfo_taken,
  input  [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  [63:0] io_in_bits_perfDebugInfo_issueTime,
  output io_out_valid,
  output [34:0] io_out_bits_fuType,
  output [8:0] io_out_bits_fuOpType,
  output [63:0] io_out_bits_src_0,
  output [63:0] io_out_bits_src_1,
  output [63:0] io_out_bits_imm,
  output [4:0] io_out_bits_nextPcOffset,
  output io_out_bits_robIdx_flag,
  output [7:0] io_out_bits_robIdx_value,
  output [7:0] io_out_bits_pdest,
  output io_out_bits_rfWen,
  output io_out_bits_fpWen,
  output io_out_bits_vecWen,
  output io_out_bits_v0Wen,
  output io_out_bits_vlWen,
  output [1:0] io_out_bits_fpu_typeTagOut,
  output io_out_bits_fpu_wflags,
  output [1:0] io_out_bits_fpu_typ,
  output [2:0] io_out_bits_fpu_rm,
  output [49:0] io_out_bits_pc,
  output io_out_bits_ftqIdx_flag,
  output [5:0] io_out_bits_ftqIdx_value,
  output [3:0] io_out_bits_ftqOffset,
  output [49:0] io_out_bits_predictInfo_target,
  output io_out_bits_predictInfo_taken,
  output [63:0] io_out_bits_perfDebugInfo_enqRsTime,
  output [63:0] io_out_bits_perfDebugInfo_selectTime,
  output [63:0] io_out_bits_perfDebugInfo_issueTime,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [574:0] out_bus;
  assign io_out_bits_fuType = out_bus[574:540];
  assign io_out_bits_fuOpType = out_bus[539:531];
  assign io_out_bits_src_0 = out_bus[530:467];
  assign io_out_bits_src_1 = out_bus[466:403];
  assign io_out_bits_imm = out_bus[402:339];
  assign io_out_bits_nextPcOffset = out_bus[338:334];
  assign io_out_bits_robIdx_flag = out_bus[333:333];
  assign io_out_bits_robIdx_value = out_bus[332:325];
  assign io_out_bits_pdest = out_bus[324:317];
  assign io_out_bits_rfWen = out_bus[316:316];
  assign io_out_bits_fpWen = out_bus[315:315];
  assign io_out_bits_vecWen = out_bus[314:314];
  assign io_out_bits_v0Wen = out_bus[313:313];
  assign io_out_bits_vlWen = out_bus[312:312];
  assign io_out_bits_fpu_typeTagOut = out_bus[311:310];
  assign io_out_bits_fpu_wflags = out_bus[309:309];
  assign io_out_bits_fpu_typ = out_bus[308:307];
  assign io_out_bits_fpu_rm = out_bus[306:304];
  assign io_out_bits_pc = out_bus[303:254];
  assign io_out_bits_ftqIdx_flag = out_bus[253:253];
  assign io_out_bits_ftqIdx_value = out_bus[252:247];
  assign io_out_bits_ftqOffset = out_bus[246:243];
  assign io_out_bits_predictInfo_target = out_bus[242:193];
  assign io_out_bits_predictInfo_taken = out_bus[192:192];
  assign io_out_bits_perfDebugInfo_enqRsTime = out_bus[191:128];
  assign io_out_bits_perfDebugInfo_selectTime = out_bus[127:64];
  assign io_out_bits_perfDebugInfo_issueTime = out_bus[63:0];
  xs_PipelineConnect #(.DATA_WIDTH(575)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(/* 上游未用，golden 已 DCE */),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_fuType, io_in_bits_fuOpType, io_in_bits_src_0, io_in_bits_src_1, io_in_bits_imm, io_in_bits_nextPcOffset, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_vlWen, io_in_bits_fpu_typeTagOut, io_in_bits_fpu_wflags, io_in_bits_fpu_typ, io_in_bits_fpu_rm, io_in_bits_pc, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_predictInfo_target, io_in_bits_predictInfo_taken, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime}),
    .io_out_ready(1'b1),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

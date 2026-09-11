// NewPipelineConnectPipe_33 —— NewPipelineConnectPipe_25 单态化变体 wrapper（核体见 NewPipelineConnectPipe_25.sv）

module NewPipelineConnectPipe_33(
  input  clock,
  input  reset,
  output io_in_ready,
  input  io_in_valid,
  input  [63:0] io_in_bits_vaddr,
  input  [49:0] io_in_bits_basevaddr,
  input  [15:0] io_in_bits_mask,
  input  [3:0] io_in_bits_reg_offset,
  input  [2:0] io_in_bits_alignedType,
  input  io_in_bits_vecActive,
  input  io_in_bits_uop_exceptionVec_4,
  input  io_in_bits_uop_exceptionVec_5,
  input  io_in_bits_uop_exceptionVec_6,
  input  io_in_bits_uop_exceptionVec_7,
  input  io_in_bits_uop_exceptionVec_13,
  input  io_in_bits_uop_exceptionVec_15,
  input  io_in_bits_uop_exceptionVec_19,
  input  io_in_bits_uop_exceptionVec_21,
  input  io_in_bits_uop_exceptionVec_23,
  input  [3:0] io_in_bits_uop_trigger,
  input  io_in_bits_uop_preDecodeInfo_isRVC,
  input  io_in_bits_uop_ftqPtr_flag,
  input  [5:0] io_in_bits_uop_ftqPtr_value,
  input  [3:0] io_in_bits_uop_ftqOffset,
  input  [8:0] io_in_bits_uop_fuOpType,
  input  io_in_bits_uop_rfWen,
  input  io_in_bits_uop_fpWen,
  input  [7:0] io_in_bits_uop_vpu_vstart,
  input  [1:0] io_in_bits_uop_vpu_veew,
  input  [6:0] io_in_bits_uop_uopIdx,
  input  [7:0] io_in_bits_uop_pdest,
  input  io_in_bits_uop_robIdx_flag,
  input  [7:0] io_in_bits_uop_robIdx_value,
  input  [63:0] io_in_bits_uop_debugInfo_enqRsTime,
  input  [63:0] io_in_bits_uop_debugInfo_selectTime,
  input  [63:0] io_in_bits_uop_debugInfo_issueTime,
  input  io_in_bits_uop_storeSetHit,
  input  io_in_bits_uop_waitForRobIdx_flag,
  input  [7:0] io_in_bits_uop_waitForRobIdx_value,
  input  io_in_bits_uop_loadWaitBit,
  input  io_in_bits_uop_loadWaitStrict,
  input  io_in_bits_uop_lqIdx_flag,
  input  [6:0] io_in_bits_uop_lqIdx_value,
  input  io_in_bits_uop_sqIdx_flag,
  input  [5:0] io_in_bits_uop_sqIdx_value,
  input  [3:0] io_in_bits_mBIndex,
  input  [7:0] io_in_bits_elemIdx,
  input  [7:0] io_in_bits_elemIdxInsideVd,
  input  io_out_ready,
  output io_out_valid,
  output [63:0] io_out_bits_vaddr,
  output [49:0] io_out_bits_basevaddr,
  output [15:0] io_out_bits_mask,
  output [3:0] io_out_bits_reg_offset,
  output [2:0] io_out_bits_alignedType,
  output io_out_bits_vecActive,
  output io_out_bits_uop_exceptionVec_4,
  output io_out_bits_uop_exceptionVec_5,
  output io_out_bits_uop_exceptionVec_6,
  output io_out_bits_uop_exceptionVec_7,
  output io_out_bits_uop_exceptionVec_13,
  output io_out_bits_uop_exceptionVec_15,
  output io_out_bits_uop_exceptionVec_19,
  output io_out_bits_uop_exceptionVec_21,
  output io_out_bits_uop_exceptionVec_23,
  output [3:0] io_out_bits_uop_trigger,
  output io_out_bits_uop_preDecodeInfo_isRVC,
  output io_out_bits_uop_ftqPtr_flag,
  output [5:0] io_out_bits_uop_ftqPtr_value,
  output [3:0] io_out_bits_uop_ftqOffset,
  output [8:0] io_out_bits_uop_fuOpType,
  output io_out_bits_uop_rfWen,
  output io_out_bits_uop_fpWen,
  output [7:0] io_out_bits_uop_vpu_vstart,
  output [1:0] io_out_bits_uop_vpu_veew,
  output [6:0] io_out_bits_uop_uopIdx,
  output [7:0] io_out_bits_uop_pdest,
  output io_out_bits_uop_robIdx_flag,
  output [7:0] io_out_bits_uop_robIdx_value,
  output [63:0] io_out_bits_uop_debugInfo_enqRsTime,
  output [63:0] io_out_bits_uop_debugInfo_selectTime,
  output [63:0] io_out_bits_uop_debugInfo_issueTime,
  output io_out_bits_uop_storeSetHit,
  output io_out_bits_uop_waitForRobIdx_flag,
  output [7:0] io_out_bits_uop_waitForRobIdx_value,
  output io_out_bits_uop_loadWaitBit,
  output io_out_bits_uop_loadWaitStrict,
  output io_out_bits_uop_lqIdx_flag,
  output [6:0] io_out_bits_uop_lqIdx_value,
  output io_out_bits_uop_sqIdx_flag,
  output [5:0] io_out_bits_uop_sqIdx_value,
  output [3:0] io_out_bits_mBIndex,
  output [7:0] io_out_bits_elemIdx,
  output [7:0] io_out_bits_elemIdxInsideVd,
  input  io_rightOutFire,
  input  io_isFlush
);
  wire [446:0] out_bus;
  assign io_out_bits_vaddr = out_bus[446:383];
  assign io_out_bits_basevaddr = out_bus[382:333];
  assign io_out_bits_mask = out_bus[332:317];
  assign io_out_bits_reg_offset = out_bus[316:313];
  assign io_out_bits_alignedType = out_bus[312:310];
  assign io_out_bits_vecActive = out_bus[309:309];
  assign io_out_bits_uop_exceptionVec_4 = out_bus[308:308];
  assign io_out_bits_uop_exceptionVec_5 = out_bus[307:307];
  assign io_out_bits_uop_exceptionVec_6 = out_bus[306:306];
  assign io_out_bits_uop_exceptionVec_7 = out_bus[305:305];
  assign io_out_bits_uop_exceptionVec_13 = out_bus[304:304];
  assign io_out_bits_uop_exceptionVec_15 = out_bus[303:303];
  assign io_out_bits_uop_exceptionVec_19 = out_bus[302:302];
  assign io_out_bits_uop_exceptionVec_21 = out_bus[301:301];
  assign io_out_bits_uop_exceptionVec_23 = out_bus[300:300];
  assign io_out_bits_uop_trigger = out_bus[299:296];
  assign io_out_bits_uop_preDecodeInfo_isRVC = out_bus[295:295];
  assign io_out_bits_uop_ftqPtr_flag = out_bus[294:294];
  assign io_out_bits_uop_ftqPtr_value = out_bus[293:288];
  assign io_out_bits_uop_ftqOffset = out_bus[287:284];
  assign io_out_bits_uop_fuOpType = out_bus[283:275];
  assign io_out_bits_uop_rfWen = out_bus[274:274];
  assign io_out_bits_uop_fpWen = out_bus[273:273];
  assign io_out_bits_uop_vpu_vstart = out_bus[272:265];
  assign io_out_bits_uop_vpu_veew = out_bus[264:263];
  assign io_out_bits_uop_uopIdx = out_bus[262:256];
  assign io_out_bits_uop_pdest = out_bus[255:248];
  assign io_out_bits_uop_robIdx_flag = out_bus[247:247];
  assign io_out_bits_uop_robIdx_value = out_bus[246:239];
  assign io_out_bits_uop_debugInfo_enqRsTime = out_bus[238:175];
  assign io_out_bits_uop_debugInfo_selectTime = out_bus[174:111];
  assign io_out_bits_uop_debugInfo_issueTime = out_bus[110:47];
  assign io_out_bits_uop_storeSetHit = out_bus[46:46];
  assign io_out_bits_uop_waitForRobIdx_flag = out_bus[45:45];
  assign io_out_bits_uop_waitForRobIdx_value = out_bus[44:37];
  assign io_out_bits_uop_loadWaitBit = out_bus[36:36];
  assign io_out_bits_uop_loadWaitStrict = out_bus[35:35];
  assign io_out_bits_uop_lqIdx_flag = out_bus[34:34];
  assign io_out_bits_uop_lqIdx_value = out_bus[33:27];
  assign io_out_bits_uop_sqIdx_flag = out_bus[26:26];
  assign io_out_bits_uop_sqIdx_value = out_bus[25:20];
  assign io_out_bits_mBIndex = out_bus[19:16];
  assign io_out_bits_elemIdx = out_bus[15:8];
  assign io_out_bits_elemIdxInsideVd = out_bus[7:0];
  xs_PipelineConnect #(.DATA_WIDTH(447)) u_core (
    .clock(clock),
    .reset(reset),
    .io_in_ready(io_in_ready),
    .io_in_valid(io_in_valid),
    .io_in_bits({io_in_bits_vaddr, io_in_bits_basevaddr, io_in_bits_mask, io_in_bits_reg_offset, io_in_bits_alignedType, io_in_bits_vecActive, io_in_bits_uop_exceptionVec_4, io_in_bits_uop_exceptionVec_5, io_in_bits_uop_exceptionVec_6, io_in_bits_uop_exceptionVec_7, io_in_bits_uop_exceptionVec_13, io_in_bits_uop_exceptionVec_15, io_in_bits_uop_exceptionVec_19, io_in_bits_uop_exceptionVec_21, io_in_bits_uop_exceptionVec_23, io_in_bits_uop_trigger, io_in_bits_uop_preDecodeInfo_isRVC, io_in_bits_uop_ftqPtr_flag, io_in_bits_uop_ftqPtr_value, io_in_bits_uop_ftqOffset, io_in_bits_uop_fuOpType, io_in_bits_uop_rfWen, io_in_bits_uop_fpWen, io_in_bits_uop_vpu_vstart, io_in_bits_uop_vpu_veew, io_in_bits_uop_uopIdx, io_in_bits_uop_pdest, io_in_bits_uop_robIdx_flag, io_in_bits_uop_robIdx_value, io_in_bits_uop_debugInfo_enqRsTime, io_in_bits_uop_debugInfo_selectTime, io_in_bits_uop_debugInfo_issueTime, io_in_bits_uop_storeSetHit, io_in_bits_uop_waitForRobIdx_flag, io_in_bits_uop_waitForRobIdx_value, io_in_bits_uop_loadWaitBit, io_in_bits_uop_loadWaitStrict, io_in_bits_uop_lqIdx_flag, io_in_bits_uop_lqIdx_value, io_in_bits_uop_sqIdx_flag, io_in_bits_uop_sqIdx_value, io_in_bits_mBIndex, io_in_bits_elemIdx, io_in_bits_elemIdxInsideVd}),
    .io_out_ready(io_out_ready),
    .io_out_valid(io_out_valid),
    .io_out_bits(out_bus),
    .io_rightOutFire(io_rightOutFire),
    .io_isFlush(io_isFlush)
  );
endmodule

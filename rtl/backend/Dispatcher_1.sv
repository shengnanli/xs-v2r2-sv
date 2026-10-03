// Dispatcher_1.sv — exact-port Dispatcher wrapper with readable route core.
// Acceptance masks and field maps are checked against G1 by
// scripts/gen_dispatcher_200c.py before this file is written.

module Dispatcher_1 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [34:0] io_in_bits_fuType,
  input  logic [8:0] io_in_bits_fuOpType,
  input  logic [63:0] io_in_bits_imm,
  input  logic [4:0] io_in_bits_nextPcOffset,
  input  logic io_in_bits_robIdx_flag,
  input  logic [7:0] io_in_bits_robIdx_value,
  input  logic [7:0] io_in_bits_pdest,
  input  logic io_in_bits_rfWen,
  input  logic [49:0] io_in_bits_pc,
  input  logic io_in_bits_preDecode_valid,
  input  logic io_in_bits_preDecode_isRVC,
  input  logic [1:0] io_in_bits_preDecode_brType,
  input  logic io_in_bits_preDecode_isCall,
  input  logic io_in_bits_preDecode_isRet,
  input  logic io_in_bits_ftqIdx_flag,
  input  logic [5:0] io_in_bits_ftqIdx_value,
  input  logic [3:0] io_in_bits_ftqOffset,
  input  logic [49:0] io_in_bits_predictInfo_target,
  input  logic io_in_bits_predictInfo_taken,
  input  logic io_in_bits_perfDebugInfo_eliminatedMove,
  input  logic [63:0] io_in_bits_perfDebugInfo_renameTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_dispatchTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_enqRsTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_selectTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_issueTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_writebackTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_runahead_checkpoint_id,
  input  logic [63:0] io_in_bits_perfDebugInfo_tlbFirstReqTime,
  input  logic [63:0] io_in_bits_perfDebugInfo_tlbRespTime,
  input  logic [55:0] io_in_bits_debug_seqNum_seqNum,
  input  logic [7:0] io_in_bits_debug_seqNum_uopIdx,
  input  logic io_out_0_ready,
  output logic io_out_0_valid,
  output logic [8:0] io_out_0_bits_fuOpType,
  output logic [63:0] io_out_0_bits_imm,
  output logic [4:0] io_out_0_bits_nextPcOffset,
  output logic io_out_0_bits_robIdx_flag,
  output logic [7:0] io_out_0_bits_robIdx_value,
  output logic [7:0] io_out_0_bits_pdest,
  output logic [49:0] io_out_0_bits_pc,
  output logic io_out_0_bits_preDecode_valid,
  output logic io_out_0_bits_preDecode_isRVC,
  output logic [1:0] io_out_0_bits_preDecode_brType,
  output logic io_out_0_bits_preDecode_isCall,
  output logic io_out_0_bits_preDecode_isRet,
  output logic io_out_0_bits_ftqIdx_flag,
  output logic [5:0] io_out_0_bits_ftqIdx_value,
  output logic [3:0] io_out_0_bits_ftqOffset,
  output logic io_out_0_bits_predictInfo_taken,
  output logic io_out_0_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0] io_out_0_bits_perfDebugInfo_renameTime,
  output logic [63:0] io_out_0_bits_perfDebugInfo_dispatchTime,
  output logic [63:0] io_out_0_bits_perfDebugInfo_enqRsTime,
  output logic [63:0] io_out_0_bits_perfDebugInfo_selectTime,
  output logic [63:0] io_out_0_bits_perfDebugInfo_issueTime,
  output logic [63:0] io_out_0_bits_perfDebugInfo_writebackTime,
  output logic [63:0] io_out_0_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_0_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_0_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0] io_out_0_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_0_bits_debug_seqNum_uopIdx,
  input  logic io_out_1_ready,
  output logic io_out_1_valid,
  output logic [8:0] io_out_1_bits_fuOpType,
  output logic [63:0] io_out_1_bits_imm,
  output logic [4:0] io_out_1_bits_nextPcOffset,
  output logic io_out_1_bits_robIdx_flag,
  output logic [7:0] io_out_1_bits_robIdx_value,
  output logic [7:0] io_out_1_bits_pdest,
  output logic io_out_1_bits_rfWen,
  output logic [49:0] io_out_1_bits_pc,
  output logic io_out_1_bits_preDecode_valid,
  output logic io_out_1_bits_preDecode_isRVC,
  output logic [1:0] io_out_1_bits_preDecode_brType,
  output logic io_out_1_bits_preDecode_isCall,
  output logic io_out_1_bits_preDecode_isRet,
  output logic io_out_1_bits_ftqIdx_flag,
  output logic [5:0] io_out_1_bits_ftqIdx_value,
  output logic [3:0] io_out_1_bits_ftqOffset,
  output logic [49:0] io_out_1_bits_predictInfo_target,
  output logic io_out_1_bits_predictInfo_taken,
  output logic io_out_1_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0] io_out_1_bits_perfDebugInfo_renameTime,
  output logic [63:0] io_out_1_bits_perfDebugInfo_dispatchTime,
  output logic [63:0] io_out_1_bits_perfDebugInfo_enqRsTime,
  output logic [63:0] io_out_1_bits_perfDebugInfo_selectTime,
  output logic [63:0] io_out_1_bits_perfDebugInfo_issueTime,
  output logic [63:0] io_out_1_bits_perfDebugInfo_writebackTime,
  output logic [63:0] io_out_1_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_1_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_1_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0] io_out_1_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_1_bits_debug_seqNum_uopIdx
);

  xs_Dispatcher_core #(
    .OUTPUTS(2),
    .ACCEPT_MASK('{35'h2, 35'h1})
  ) route_core (
    .clock(clock), .reset(reset), .in_ready(io_in_ready),
    .in_valid(io_in_valid), .in_fu_type(io_in_bits_fuType),
    .out_ready({io_out_1_ready, io_out_0_ready}),
    .out_valid({io_out_1_valid, io_out_0_valid})
  );

  // Output 0 payload order (MSB to LSB): fuOpType, imm, nextPcOffset, robIdx_flag, robIdx_value, pdest, pc, preDecode_valid, preDecode_isRVC, preDecode_brType, preDecode_isCall, preDecode_isRet, ftqIdx_flag, ftqIdx_value, ftqOffset, predictInfo_taken, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [803:0] payload_0;
  assign payload_0 = {io_in_bits_fuOpType, io_in_bits_imm, io_in_bits_nextPcOffset, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_pc, io_in_bits_preDecode_valid, io_in_bits_preDecode_isRVC, io_in_bits_preDecode_brType, io_in_bits_preDecode_isCall, io_in_bits_preDecode_isRet, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_predictInfo_taken, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
  assign io_out_0_bits_debug_seqNum_uopIdx = payload_0[7:0];
  assign io_out_0_bits_debug_seqNum_seqNum = payload_0[63:8];
  assign io_out_0_bits_perfDebugInfo_tlbRespTime = payload_0[127:64];
  assign io_out_0_bits_perfDebugInfo_tlbFirstReqTime = payload_0[191:128];
  assign io_out_0_bits_perfDebugInfo_runahead_checkpoint_id = payload_0[255:192];
  assign io_out_0_bits_perfDebugInfo_writebackTime = payload_0[319:256];
  assign io_out_0_bits_perfDebugInfo_issueTime = payload_0[383:320];
  assign io_out_0_bits_perfDebugInfo_selectTime = payload_0[447:384];
  assign io_out_0_bits_perfDebugInfo_enqRsTime = payload_0[511:448];
  assign io_out_0_bits_perfDebugInfo_dispatchTime = payload_0[575:512];
  assign io_out_0_bits_perfDebugInfo_renameTime = payload_0[639:576];
  assign io_out_0_bits_perfDebugInfo_eliminatedMove = payload_0[640:640];
  assign io_out_0_bits_predictInfo_taken = payload_0[641:641];
  assign io_out_0_bits_ftqOffset = payload_0[645:642];
  assign io_out_0_bits_ftqIdx_value = payload_0[651:646];
  assign io_out_0_bits_ftqIdx_flag = payload_0[652:652];
  assign io_out_0_bits_preDecode_isRet = payload_0[653:653];
  assign io_out_0_bits_preDecode_isCall = payload_0[654:654];
  assign io_out_0_bits_preDecode_brType = payload_0[656:655];
  assign io_out_0_bits_preDecode_isRVC = payload_0[657:657];
  assign io_out_0_bits_preDecode_valid = payload_0[658:658];
  assign io_out_0_bits_pc = payload_0[708:659];
  assign io_out_0_bits_pdest = payload_0[716:709];
  assign io_out_0_bits_robIdx_value = payload_0[724:717];
  assign io_out_0_bits_robIdx_flag = payload_0[725:725];
  assign io_out_0_bits_nextPcOffset = payload_0[730:726];
  assign io_out_0_bits_imm = payload_0[794:731];
  assign io_out_0_bits_fuOpType = payload_0[803:795];
  // Output 1 payload order (MSB to LSB): fuOpType, imm, nextPcOffset, robIdx_flag, robIdx_value, pdest, rfWen, pc, preDecode_valid, preDecode_isRVC, preDecode_brType, preDecode_isCall, preDecode_isRet, ftqIdx_flag, ftqIdx_value, ftqOffset, predictInfo_target, predictInfo_taken, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [854:0] payload_1;
  assign payload_1 = {io_in_bits_fuOpType, io_in_bits_imm, io_in_bits_nextPcOffset, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_pc, io_in_bits_preDecode_valid, io_in_bits_preDecode_isRVC, io_in_bits_preDecode_brType, io_in_bits_preDecode_isCall, io_in_bits_preDecode_isRet, io_in_bits_ftqIdx_flag, io_in_bits_ftqIdx_value, io_in_bits_ftqOffset, io_in_bits_predictInfo_target, io_in_bits_predictInfo_taken, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
  assign io_out_1_bits_debug_seqNum_uopIdx = payload_1[7:0];
  assign io_out_1_bits_debug_seqNum_seqNum = payload_1[63:8];
  assign io_out_1_bits_perfDebugInfo_tlbRespTime = payload_1[127:64];
  assign io_out_1_bits_perfDebugInfo_tlbFirstReqTime = payload_1[191:128];
  assign io_out_1_bits_perfDebugInfo_runahead_checkpoint_id = payload_1[255:192];
  assign io_out_1_bits_perfDebugInfo_writebackTime = payload_1[319:256];
  assign io_out_1_bits_perfDebugInfo_issueTime = payload_1[383:320];
  assign io_out_1_bits_perfDebugInfo_selectTime = payload_1[447:384];
  assign io_out_1_bits_perfDebugInfo_enqRsTime = payload_1[511:448];
  assign io_out_1_bits_perfDebugInfo_dispatchTime = payload_1[575:512];
  assign io_out_1_bits_perfDebugInfo_renameTime = payload_1[639:576];
  assign io_out_1_bits_perfDebugInfo_eliminatedMove = payload_1[640:640];
  assign io_out_1_bits_predictInfo_taken = payload_1[641:641];
  assign io_out_1_bits_predictInfo_target = payload_1[691:642];
  assign io_out_1_bits_ftqOffset = payload_1[695:692];
  assign io_out_1_bits_ftqIdx_value = payload_1[701:696];
  assign io_out_1_bits_ftqIdx_flag = payload_1[702:702];
  assign io_out_1_bits_preDecode_isRet = payload_1[703:703];
  assign io_out_1_bits_preDecode_isCall = payload_1[704:704];
  assign io_out_1_bits_preDecode_brType = payload_1[706:705];
  assign io_out_1_bits_preDecode_isRVC = payload_1[707:707];
  assign io_out_1_bits_preDecode_valid = payload_1[708:708];
  assign io_out_1_bits_pc = payload_1[758:709];
  assign io_out_1_bits_rfWen = payload_1[759:759];
  assign io_out_1_bits_pdest = payload_1[767:760];
  assign io_out_1_bits_robIdx_value = payload_1[775:768];
  assign io_out_1_bits_robIdx_flag = payload_1[776:776];
  assign io_out_1_bits_nextPcOffset = payload_1[781:777];
  assign io_out_1_bits_imm = payload_1[845:782];
  assign io_out_1_bits_fuOpType = payload_1[854:846];
endmodule

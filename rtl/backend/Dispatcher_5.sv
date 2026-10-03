// Dispatcher_5.sv — exact-port Dispatcher wrapper with readable route core.
// Acceptance masks and field maps are checked against G1 by
// scripts/gen_dispatcher_200c.py before this file is written.

module Dispatcher_5 (
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
  input  logic io_in_bits_fpWen,
  input  logic io_in_bits_vecWen,
  input  logic io_in_bits_v0Wen,
  input  logic io_in_bits_vlWen,
  input  logic [1:0] io_in_bits_fpu_typeTagOut,
  input  logic io_in_bits_fpu_wflags,
  input  logic [1:0] io_in_bits_fpu_typ,
  input  logic [2:0] io_in_bits_fpu_rm,
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
  output logic [7:0] io_out_1_bits_debug_seqNum_uopIdx,
  input  logic io_out_2_ready,
  output logic io_out_2_valid,
  output logic [1:0] io_out_2_bits_fpu_typeTagOut,
  output logic io_out_2_bits_fpu_wflags,
  output logic [1:0] io_out_2_bits_fpu_typ,
  output logic [2:0] io_out_2_bits_fpu_rm,
  output logic io_out_2_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0] io_out_2_bits_perfDebugInfo_renameTime,
  output logic [63:0] io_out_2_bits_perfDebugInfo_dispatchTime,
  output logic [63:0] io_out_2_bits_perfDebugInfo_enqRsTime,
  output logic [63:0] io_out_2_bits_perfDebugInfo_selectTime,
  output logic [63:0] io_out_2_bits_perfDebugInfo_issueTime,
  output logic [63:0] io_out_2_bits_perfDebugInfo_writebackTime,
  output logic [63:0] io_out_2_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_2_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_2_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0] io_out_2_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_2_bits_debug_seqNum_uopIdx,
  input  logic io_out_3_ready,
  output logic io_out_3_valid,
  output logic [8:0] io_out_3_bits_fuOpType,
  output logic io_out_3_bits_robIdx_flag,
  output logic [7:0] io_out_3_bits_robIdx_value,
  output logic [7:0] io_out_3_bits_pdest,
  output logic io_out_3_bits_rfWen,
  output logic io_out_3_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0] io_out_3_bits_perfDebugInfo_renameTime,
  output logic [63:0] io_out_3_bits_perfDebugInfo_dispatchTime,
  output logic [63:0] io_out_3_bits_perfDebugInfo_enqRsTime,
  output logic [63:0] io_out_3_bits_perfDebugInfo_selectTime,
  output logic [63:0] io_out_3_bits_perfDebugInfo_issueTime,
  output logic [63:0] io_out_3_bits_perfDebugInfo_writebackTime,
  output logic [63:0] io_out_3_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_3_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_3_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0] io_out_3_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_3_bits_debug_seqNum_uopIdx,
  input  logic io_out_4_ready,
  output logic io_out_4_valid,
  output logic [8:0] io_out_4_bits_fuOpType,
  output logic io_out_4_bits_robIdx_flag,
  output logic [7:0] io_out_4_bits_robIdx_value,
  output logic [7:0] io_out_4_bits_pdest,
  output logic io_out_4_bits_vlWen,
  output logic io_out_4_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0] io_out_4_bits_perfDebugInfo_renameTime,
  output logic [63:0] io_out_4_bits_perfDebugInfo_dispatchTime,
  output logic [63:0] io_out_4_bits_perfDebugInfo_enqRsTime,
  output logic [63:0] io_out_4_bits_perfDebugInfo_selectTime,
  output logic [63:0] io_out_4_bits_perfDebugInfo_issueTime,
  output logic [63:0] io_out_4_bits_perfDebugInfo_writebackTime,
  output logic [63:0] io_out_4_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_4_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_4_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0] io_out_4_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_4_bits_debug_seqNum_uopIdx,
  input  logic io_out_5_ready,
  output logic io_out_5_valid,
  output logic [8:0] io_out_5_bits_fuOpType,
  output logic io_out_5_bits_robIdx_flag,
  output logic [7:0] io_out_5_bits_robIdx_value,
  output logic [7:0] io_out_5_bits_pdest,
  output logic io_out_5_bits_fpWen,
  output logic io_out_5_bits_vecWen,
  output logic io_out_5_bits_v0Wen,
  output logic io_out_5_bits_perfDebugInfo_eliminatedMove,
  output logic [63:0] io_out_5_bits_perfDebugInfo_renameTime,
  output logic [63:0] io_out_5_bits_perfDebugInfo_dispatchTime,
  output logic [63:0] io_out_5_bits_perfDebugInfo_enqRsTime,
  output logic [63:0] io_out_5_bits_perfDebugInfo_selectTime,
  output logic [63:0] io_out_5_bits_perfDebugInfo_issueTime,
  output logic [63:0] io_out_5_bits_perfDebugInfo_writebackTime,
  output logic [63:0] io_out_5_bits_perfDebugInfo_runahead_checkpoint_id,
  output logic [63:0] io_out_5_bits_perfDebugInfo_tlbFirstReqTime,
  output logic [63:0] io_out_5_bits_perfDebugInfo_tlbRespTime,
  output logic [55:0] io_out_5_bits_debug_seqNum_seqNum,
  output logic [7:0] io_out_5_bits_debug_seqNum_uopIdx
);

  xs_Dispatcher_core #(
    .OUTPUTS(6),
    .ACCEPT_MASK('{35'h2, 35'h1, 35'h4, 35'h10000000, 35'h20000000, 35'h8})
  ) route_core (
    .clock(clock), .reset(reset), .in_ready(io_in_ready),
    .in_valid(io_in_valid), .in_fu_type(io_in_bits_fuType),
    .out_ready({io_out_5_ready, io_out_4_ready, io_out_3_ready, io_out_2_ready, io_out_1_ready, io_out_0_ready}),
    .out_valid({io_out_5_valid, io_out_4_valid, io_out_3_valid, io_out_2_valid, io_out_1_valid, io_out_0_valid})
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
  // Output 2 payload order (MSB to LSB): fpu_typeTagOut, fpu_wflags, fpu_typ, fpu_rm, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [648:0] payload_2;
  assign payload_2 = {io_in_bits_fpu_typeTagOut, io_in_bits_fpu_wflags, io_in_bits_fpu_typ, io_in_bits_fpu_rm, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
  assign io_out_2_bits_debug_seqNum_uopIdx = payload_2[7:0];
  assign io_out_2_bits_debug_seqNum_seqNum = payload_2[63:8];
  assign io_out_2_bits_perfDebugInfo_tlbRespTime = payload_2[127:64];
  assign io_out_2_bits_perfDebugInfo_tlbFirstReqTime = payload_2[191:128];
  assign io_out_2_bits_perfDebugInfo_runahead_checkpoint_id = payload_2[255:192];
  assign io_out_2_bits_perfDebugInfo_writebackTime = payload_2[319:256];
  assign io_out_2_bits_perfDebugInfo_issueTime = payload_2[383:320];
  assign io_out_2_bits_perfDebugInfo_selectTime = payload_2[447:384];
  assign io_out_2_bits_perfDebugInfo_enqRsTime = payload_2[511:448];
  assign io_out_2_bits_perfDebugInfo_dispatchTime = payload_2[575:512];
  assign io_out_2_bits_perfDebugInfo_renameTime = payload_2[639:576];
  assign io_out_2_bits_perfDebugInfo_eliminatedMove = payload_2[640:640];
  assign io_out_2_bits_fpu_rm = payload_2[643:641];
  assign io_out_2_bits_fpu_typ = payload_2[645:644];
  assign io_out_2_bits_fpu_wflags = payload_2[646:646];
  assign io_out_2_bits_fpu_typeTagOut = payload_2[648:647];
  // Output 3 payload order (MSB to LSB): fuOpType, robIdx_flag, robIdx_value, pdest, rfWen, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [667:0] payload_3;
  assign payload_3 = {io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
  assign io_out_3_bits_debug_seqNum_uopIdx = payload_3[7:0];
  assign io_out_3_bits_debug_seqNum_seqNum = payload_3[63:8];
  assign io_out_3_bits_perfDebugInfo_tlbRespTime = payload_3[127:64];
  assign io_out_3_bits_perfDebugInfo_tlbFirstReqTime = payload_3[191:128];
  assign io_out_3_bits_perfDebugInfo_runahead_checkpoint_id = payload_3[255:192];
  assign io_out_3_bits_perfDebugInfo_writebackTime = payload_3[319:256];
  assign io_out_3_bits_perfDebugInfo_issueTime = payload_3[383:320];
  assign io_out_3_bits_perfDebugInfo_selectTime = payload_3[447:384];
  assign io_out_3_bits_perfDebugInfo_enqRsTime = payload_3[511:448];
  assign io_out_3_bits_perfDebugInfo_dispatchTime = payload_3[575:512];
  assign io_out_3_bits_perfDebugInfo_renameTime = payload_3[639:576];
  assign io_out_3_bits_perfDebugInfo_eliminatedMove = payload_3[640:640];
  assign io_out_3_bits_rfWen = payload_3[641:641];
  assign io_out_3_bits_pdest = payload_3[649:642];
  assign io_out_3_bits_robIdx_value = payload_3[657:650];
  assign io_out_3_bits_robIdx_flag = payload_3[658:658];
  assign io_out_3_bits_fuOpType = payload_3[667:659];
  // Output 4 payload order (MSB to LSB): fuOpType, robIdx_flag, robIdx_value, pdest, vlWen, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [667:0] payload_4;
  assign payload_4 = {io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_vlWen, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
  assign io_out_4_bits_debug_seqNum_uopIdx = payload_4[7:0];
  assign io_out_4_bits_debug_seqNum_seqNum = payload_4[63:8];
  assign io_out_4_bits_perfDebugInfo_tlbRespTime = payload_4[127:64];
  assign io_out_4_bits_perfDebugInfo_tlbFirstReqTime = payload_4[191:128];
  assign io_out_4_bits_perfDebugInfo_runahead_checkpoint_id = payload_4[255:192];
  assign io_out_4_bits_perfDebugInfo_writebackTime = payload_4[319:256];
  assign io_out_4_bits_perfDebugInfo_issueTime = payload_4[383:320];
  assign io_out_4_bits_perfDebugInfo_selectTime = payload_4[447:384];
  assign io_out_4_bits_perfDebugInfo_enqRsTime = payload_4[511:448];
  assign io_out_4_bits_perfDebugInfo_dispatchTime = payload_4[575:512];
  assign io_out_4_bits_perfDebugInfo_renameTime = payload_4[639:576];
  assign io_out_4_bits_perfDebugInfo_eliminatedMove = payload_4[640:640];
  assign io_out_4_bits_vlWen = payload_4[641:641];
  assign io_out_4_bits_pdest = payload_4[649:642];
  assign io_out_4_bits_robIdx_value = payload_4[657:650];
  assign io_out_4_bits_robIdx_flag = payload_4[658:658];
  assign io_out_4_bits_fuOpType = payload_4[667:659];
  // Output 5 payload order (MSB to LSB): fuOpType, robIdx_flag, robIdx_value, pdest, fpWen, vecWen, v0Wen, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [669:0] payload_5;
  assign payload_5 = {io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_fpWen, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
  assign io_out_5_bits_debug_seqNum_uopIdx = payload_5[7:0];
  assign io_out_5_bits_debug_seqNum_seqNum = payload_5[63:8];
  assign io_out_5_bits_perfDebugInfo_tlbRespTime = payload_5[127:64];
  assign io_out_5_bits_perfDebugInfo_tlbFirstReqTime = payload_5[191:128];
  assign io_out_5_bits_perfDebugInfo_runahead_checkpoint_id = payload_5[255:192];
  assign io_out_5_bits_perfDebugInfo_writebackTime = payload_5[319:256];
  assign io_out_5_bits_perfDebugInfo_issueTime = payload_5[383:320];
  assign io_out_5_bits_perfDebugInfo_selectTime = payload_5[447:384];
  assign io_out_5_bits_perfDebugInfo_enqRsTime = payload_5[511:448];
  assign io_out_5_bits_perfDebugInfo_dispatchTime = payload_5[575:512];
  assign io_out_5_bits_perfDebugInfo_renameTime = payload_5[639:576];
  assign io_out_5_bits_perfDebugInfo_eliminatedMove = payload_5[640:640];
  assign io_out_5_bits_v0Wen = payload_5[641:641];
  assign io_out_5_bits_vecWen = payload_5[642:642];
  assign io_out_5_bits_fpWen = payload_5[643:643];
  assign io_out_5_bits_pdest = payload_5[651:644];
  assign io_out_5_bits_robIdx_value = payload_5[659:652];
  assign io_out_5_bits_robIdx_flag = payload_5[660:660];
  assign io_out_5_bits_fuOpType = payload_5[669:661];
endmodule

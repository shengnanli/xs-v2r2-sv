// Dispatcher_14.sv — exact-port Dispatcher wrapper with readable route core.
// Acceptance masks and field maps are checked against G1 by
// scripts/gen_dispatcher_200c.py before this file is written.

module Dispatcher_14 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [34:0] io_in_bits_fuType,
  input  logic [8:0] io_in_bits_fuOpType,
  input  logic io_in_bits_robIdx_flag,
  input  logic [7:0] io_in_bits_robIdx_value,
  input  logic [7:0] io_in_bits_pdest,
  input  logic io_in_bits_rfWen,
  input  logic io_in_bits_vlWen,
  input  logic io_in_bits_vpu_vma,
  input  logic io_in_bits_vpu_vta,
  input  logic [1:0] io_in_bits_vpu_vsew,
  input  logic [2:0] io_in_bits_vpu_vlmul,
  input  logic io_in_bits_vpu_vm,
  input  logic [7:0] io_in_bits_vpu_vstart,
  input  logic io_in_bits_vpu_fpu_isFoldTo1_2,
  input  logic io_in_bits_vpu_fpu_isFoldTo1_4,
  input  logic io_in_bits_vpu_fpu_isFoldTo1_8,
  input  logic [6:0] io_in_bits_vpu_vuopIdx,
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
  output logic [1:0] io_out_0_bits_vpu_vsew,
  output logic [2:0] io_out_0_bits_vpu_vlmul,
  output logic io_out_0_bits_vpu_vm,
  output logic io_out_0_bits_vpu_fpu_isFoldTo1_2,
  output logic io_out_0_bits_vpu_fpu_isFoldTo1_4,
  output logic io_out_0_bits_vpu_fpu_isFoldTo1_8,
  output logic [6:0] io_out_0_bits_vpu_vuopIdx,
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
  output logic [1:0] io_out_1_bits_vpu_vsew,
  output logic [2:0] io_out_1_bits_vpu_vlmul,
  output logic io_out_1_bits_vpu_vm,
  output logic [6:0] io_out_1_bits_vpu_vuopIdx,
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
  output logic [8:0] io_out_2_bits_fuOpType,
  output logic io_out_2_bits_vpu_vma,
  output logic io_out_2_bits_vpu_vta,
  output logic [1:0] io_out_2_bits_vpu_vsew,
  output logic [2:0] io_out_2_bits_vpu_vlmul,
  output logic io_out_2_bits_vpu_vm,
  output logic [7:0] io_out_2_bits_vpu_vstart,
  output logic [6:0] io_out_2_bits_vpu_vuopIdx,
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
  output logic io_out_3_bits_vlWen,
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
  output logic [7:0] io_out_3_bits_debug_seqNum_uopIdx
);

  xs_Dispatcher_core #(
    .OUTPUTS(4),
    .ACCEPT_MASK('{35'h1000000, 35'h8000000, 35'h40000, 35'h40000000})
  ) route_core (
    .clock(clock), .reset(reset), .in_ready(io_in_ready),
    .in_valid(io_in_valid), .in_fu_type(io_in_bits_fuType),
    .out_ready({io_out_3_ready, io_out_2_ready, io_out_1_ready, io_out_0_ready}),
    .out_valid({io_out_3_valid, io_out_2_valid, io_out_1_valid, io_out_0_valid})
  );

  // Output 0 payload order (MSB to LSB): fuOpType, vpu_vsew, vpu_vlmul, vpu_vm, vpu_fpu_isFoldTo1_2, vpu_fpu_isFoldTo1_4, vpu_fpu_isFoldTo1_8, vpu_vuopIdx, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [665:0] payload_0;
  assign payload_0 = {io_in_bits_fuOpType, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_vm, io_in_bits_vpu_fpu_isFoldTo1_2, io_in_bits_vpu_fpu_isFoldTo1_4, io_in_bits_vpu_fpu_isFoldTo1_8, io_in_bits_vpu_vuopIdx, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
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
  assign io_out_0_bits_vpu_vuopIdx = payload_0[647:641];
  assign io_out_0_bits_vpu_fpu_isFoldTo1_8 = payload_0[648:648];
  assign io_out_0_bits_vpu_fpu_isFoldTo1_4 = payload_0[649:649];
  assign io_out_0_bits_vpu_fpu_isFoldTo1_2 = payload_0[650:650];
  assign io_out_0_bits_vpu_vm = payload_0[651:651];
  assign io_out_0_bits_vpu_vlmul = payload_0[654:652];
  assign io_out_0_bits_vpu_vsew = payload_0[656:655];
  assign io_out_0_bits_fuOpType = payload_0[665:657];
  // Output 1 payload order (MSB to LSB): fuOpType, vpu_vsew, vpu_vlmul, vpu_vm, vpu_vuopIdx, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [662:0] payload_1;
  assign payload_1 = {io_in_bits_fuOpType, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vuopIdx, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
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
  assign io_out_1_bits_vpu_vuopIdx = payload_1[647:641];
  assign io_out_1_bits_vpu_vm = payload_1[648:648];
  assign io_out_1_bits_vpu_vlmul = payload_1[651:649];
  assign io_out_1_bits_vpu_vsew = payload_1[653:652];
  assign io_out_1_bits_fuOpType = payload_1[662:654];
  // Output 2 payload order (MSB to LSB): fuOpType, vpu_vma, vpu_vta, vpu_vsew, vpu_vlmul, vpu_vm, vpu_vstart, vpu_vuopIdx, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [672:0] payload_2;
  assign payload_2 = {io_in_bits_fuOpType, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_vuopIdx, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
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
  assign io_out_2_bits_vpu_vuopIdx = payload_2[647:641];
  assign io_out_2_bits_vpu_vstart = payload_2[655:648];
  assign io_out_2_bits_vpu_vm = payload_2[656:656];
  assign io_out_2_bits_vpu_vlmul = payload_2[659:657];
  assign io_out_2_bits_vpu_vsew = payload_2[661:660];
  assign io_out_2_bits_vpu_vta = payload_2[662:662];
  assign io_out_2_bits_vpu_vma = payload_2[663:663];
  assign io_out_2_bits_fuOpType = payload_2[672:664];
  // Output 3 payload order (MSB to LSB): fuOpType, robIdx_flag, robIdx_value, pdest, rfWen, vlWen, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [668:0] payload_3;
  assign payload_3 = {io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_rfWen, io_in_bits_vlWen, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
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
  assign io_out_3_bits_vlWen = payload_3[641:641];
  assign io_out_3_bits_rfWen = payload_3[642:642];
  assign io_out_3_bits_pdest = payload_3[650:643];
  assign io_out_3_bits_robIdx_value = payload_3[658:651];
  assign io_out_3_bits_robIdx_flag = payload_3[659:659];
  assign io_out_3_bits_fuOpType = payload_3[668:660];
endmodule

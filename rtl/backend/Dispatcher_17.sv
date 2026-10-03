// Dispatcher_17.sv — exact-port Dispatcher wrapper with readable route core.
// Acceptance masks and field maps are checked against G1 by
// scripts/gen_dispatcher_200c.py before this file is written.

module Dispatcher_17 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [34:0] io_in_bits_fuType,
  input  logic [8:0] io_in_bits_fuOpType,
  input  logic io_in_bits_robIdx_flag,
  input  logic [7:0] io_in_bits_robIdx_value,
  input  logic [6:0] io_in_bits_pdest,
  input  logic io_in_bits_vecWen,
  input  logic io_in_bits_v0Wen,
  input  logic io_in_bits_fpu_wflags,
  input  logic io_in_bits_vpu_vma,
  input  logic io_in_bits_vpu_vta,
  input  logic [1:0] io_in_bits_vpu_vsew,
  input  logic [2:0] io_in_bits_vpu_vlmul,
  input  logic io_in_bits_vpu_vm,
  input  logic [7:0] io_in_bits_vpu_vstart,
  input  logic [6:0] io_in_bits_vpu_vuopIdx,
  input  logic io_in_bits_vpu_isNarrow,
  input  logic io_in_bits_vpu_isDstMask,
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
  output logic io_out_0_bits_robIdx_flag,
  output logic [7:0] io_out_0_bits_robIdx_value,
  output logic [6:0] io_out_0_bits_pdest,
  output logic io_out_0_bits_vecWen,
  output logic io_out_0_bits_v0Wen,
  output logic io_out_0_bits_fpu_wflags,
  output logic io_out_0_bits_vpu_vma,
  output logic io_out_0_bits_vpu_vta,
  output logic [1:0] io_out_0_bits_vpu_vsew,
  output logic [2:0] io_out_0_bits_vpu_vlmul,
  output logic io_out_0_bits_vpu_vm,
  output logic [7:0] io_out_0_bits_vpu_vstart,
  output logic [6:0] io_out_0_bits_vpu_vuopIdx,
  output logic io_out_0_bits_vpu_isNarrow,
  output logic io_out_0_bits_vpu_isDstMask,
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
  output logic io_out_1_bits_robIdx_flag,
  output logic [7:0] io_out_1_bits_robIdx_value,
  output logic [6:0] io_out_1_bits_pdest,
  output logic io_out_1_bits_vecWen,
  output logic io_out_1_bits_v0Wen,
  output logic io_out_1_bits_vpu_vma,
  output logic io_out_1_bits_vpu_vta,
  output logic [1:0] io_out_1_bits_vpu_vsew,
  output logic io_out_1_bits_vpu_vm,
  output logic [7:0] io_out_1_bits_vpu_vstart,
  output logic [6:0] io_out_1_bits_vpu_vuopIdx,
  output logic io_out_1_bits_vpu_isNarrow,
  output logic io_out_1_bits_vpu_isDstMask,
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
    .ACCEPT_MASK('{35'h4000000, 35'h400000})
  ) route_core (
    .clock(clock), .reset(reset), .in_ready(io_in_ready),
    .in_valid(io_in_valid), .in_fu_type(io_in_bits_fuType),
    .out_ready({io_out_1_ready, io_out_0_ready}),
    .out_valid({io_out_1_valid, io_out_0_valid})
  );

  // Output 0 payload order (MSB to LSB): fuOpType, robIdx_flag, robIdx_value, pdest, vecWen, v0Wen, fpu_wflags, vpu_vma, vpu_vta, vpu_vsew, vpu_vlmul, vpu_vm, vpu_vstart, vpu_vuopIdx, vpu_isNarrow, vpu_isDstMask, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [693:0] payload_0;
  assign payload_0 = {io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_fpu_wflags, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vlmul, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_isNarrow, io_in_bits_vpu_isDstMask, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
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
  assign io_out_0_bits_vpu_isDstMask = payload_0[641:641];
  assign io_out_0_bits_vpu_isNarrow = payload_0[642:642];
  assign io_out_0_bits_vpu_vuopIdx = payload_0[649:643];
  assign io_out_0_bits_vpu_vstart = payload_0[657:650];
  assign io_out_0_bits_vpu_vm = payload_0[658:658];
  assign io_out_0_bits_vpu_vlmul = payload_0[661:659];
  assign io_out_0_bits_vpu_vsew = payload_0[663:662];
  assign io_out_0_bits_vpu_vta = payload_0[664:664];
  assign io_out_0_bits_vpu_vma = payload_0[665:665];
  assign io_out_0_bits_fpu_wflags = payload_0[666:666];
  assign io_out_0_bits_v0Wen = payload_0[667:667];
  assign io_out_0_bits_vecWen = payload_0[668:668];
  assign io_out_0_bits_pdest = payload_0[675:669];
  assign io_out_0_bits_robIdx_value = payload_0[683:676];
  assign io_out_0_bits_robIdx_flag = payload_0[684:684];
  assign io_out_0_bits_fuOpType = payload_0[693:685];
  // Output 1 payload order (MSB to LSB): fuOpType, robIdx_flag, robIdx_value, pdest, vecWen, v0Wen, vpu_vma, vpu_vta, vpu_vsew, vpu_vm, vpu_vstart, vpu_vuopIdx, vpu_isNarrow, vpu_isDstMask, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [689:0] payload_1;
  assign payload_1 = {io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_vecWen, io_in_bits_v0Wen, io_in_bits_vpu_vma, io_in_bits_vpu_vta, io_in_bits_vpu_vsew, io_in_bits_vpu_vm, io_in_bits_vpu_vstart, io_in_bits_vpu_vuopIdx, io_in_bits_vpu_isNarrow, io_in_bits_vpu_isDstMask, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
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
  assign io_out_1_bits_vpu_isDstMask = payload_1[641:641];
  assign io_out_1_bits_vpu_isNarrow = payload_1[642:642];
  assign io_out_1_bits_vpu_vuopIdx = payload_1[649:643];
  assign io_out_1_bits_vpu_vstart = payload_1[657:650];
  assign io_out_1_bits_vpu_vm = payload_1[658:658];
  assign io_out_1_bits_vpu_vsew = payload_1[660:659];
  assign io_out_1_bits_vpu_vta = payload_1[661:661];
  assign io_out_1_bits_vpu_vma = payload_1[662:662];
  assign io_out_1_bits_v0Wen = payload_1[663:663];
  assign io_out_1_bits_vecWen = payload_1[664:664];
  assign io_out_1_bits_pdest = payload_1[671:665];
  assign io_out_1_bits_robIdx_value = payload_1[679:672];
  assign io_out_1_bits_robIdx_flag = payload_1[680:680];
  assign io_out_1_bits_fuOpType = payload_1[689:681];
endmodule

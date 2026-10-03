// Dispatcher_9.sv — exact-port Dispatcher wrapper with readable route core.
// Acceptance masks and field maps are checked against G1 by
// scripts/gen_dispatcher_200c.py before this file is written.

module Dispatcher_9 (
  input  logic clock,
  input  logic reset,
  output logic io_in_ready,
  input  logic io_in_valid,
  input  logic [34:0] io_in_bits_fuType,
  input  logic [8:0] io_in_bits_fuOpType,
  input  logic io_in_bits_robIdx_flag,
  input  logic [7:0] io_in_bits_robIdx_value,
  input  logic [7:0] io_in_bits_pdest,
  input  logic io_in_bits_fpWen,
  input  logic io_in_bits_fpu_wflags,
  input  logic [1:0] io_in_bits_fpu_fmt,
  input  logic [2:0] io_in_bits_fpu_rm,
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
  output logic [7:0] io_out_0_bits_pdest,
  output logic io_out_0_bits_fpWen,
  output logic io_out_0_bits_fpu_wflags,
  output logic [1:0] io_out_0_bits_fpu_fmt,
  output logic [2:0] io_out_0_bits_fpu_rm,
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
  output logic [7:0] io_out_0_bits_debug_seqNum_uopIdx
);

  xs_Dispatcher_core #(
    .OUTPUTS(1),
    .ACCEPT_MASK('{35'h4000})
  ) route_core (
    .clock(clock), .reset(reset), .in_ready(io_in_ready),
    .in_valid(io_in_valid), .in_fu_type(io_in_bits_fuType),
    .out_ready({io_out_0_ready}),
    .out_valid({io_out_0_valid})
  );

  // Output 0 payload order (MSB to LSB): fuOpType, robIdx_flag, robIdx_value, pdest, fpWen, fpu_wflags, fpu_fmt, fpu_rm, perfDebugInfo_eliminatedMove, perfDebugInfo_renameTime, perfDebugInfo_dispatchTime, perfDebugInfo_enqRsTime, perfDebugInfo_selectTime, perfDebugInfo_issueTime, perfDebugInfo_writebackTime, perfDebugInfo_runahead_checkpoint_id, perfDebugInfo_tlbFirstReqTime, perfDebugInfo_tlbRespTime, debug_seqNum_seqNum, debug_seqNum_uopIdx.
  logic [673:0] payload_0;
  assign payload_0 = {io_in_bits_fuOpType, io_in_bits_robIdx_flag, io_in_bits_robIdx_value, io_in_bits_pdest, io_in_bits_fpWen, io_in_bits_fpu_wflags, io_in_bits_fpu_fmt, io_in_bits_fpu_rm, io_in_bits_perfDebugInfo_eliminatedMove, io_in_bits_perfDebugInfo_renameTime, io_in_bits_perfDebugInfo_dispatchTime, io_in_bits_perfDebugInfo_enqRsTime, io_in_bits_perfDebugInfo_selectTime, io_in_bits_perfDebugInfo_issueTime, io_in_bits_perfDebugInfo_writebackTime, io_in_bits_perfDebugInfo_runahead_checkpoint_id, io_in_bits_perfDebugInfo_tlbFirstReqTime, io_in_bits_perfDebugInfo_tlbRespTime, io_in_bits_debug_seqNum_seqNum, io_in_bits_debug_seqNum_uopIdx};
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
  assign io_out_0_bits_fpu_rm = payload_0[643:641];
  assign io_out_0_bits_fpu_fmt = payload_0[645:644];
  assign io_out_0_bits_fpu_wflags = payload_0[646:646];
  assign io_out_0_bits_fpWen = payload_0[647:647];
  assign io_out_0_bits_pdest = payload_0[655:648];
  assign io_out_0_bits_robIdx_value = payload_0[663:656];
  assign io_out_0_bits_robIdx_flag = payload_0[664:664];
  assign io_out_0_bits_fuOpType = payload_0[673:665];
endmodule

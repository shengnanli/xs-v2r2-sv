// Five-input CHI response arbiter with remembered pending requests.
// The shared core implements the G1 arbitration timing: asynchronous reset,
// lowest pending lane at or above the previous winner, then fixed-priority fallback.
// Payload fields absent from lanes 0..3 are driven to zero before the mux.
// This keeps the one-hot mux explicit and makes the lane shape auditable.
module FastArbiter_27(
  input          clock,
  input          reset,
  output         io_in_0_ready,
  input          io_in_0_valid,
  input  [10:0]  io_in_0_bits_tgtID,
  input  [11:0]  io_in_0_bits_txnID,
  input  [10:0]  io_in_0_bits_homeNID,
  input  [3:0]   io_in_0_bits_opcode,
  input  [1:0]   io_in_0_bits_respErr,
  input  [2:0]   io_in_0_bits_resp,
  input  [3:0]   io_in_0_bits_dataSource,
  input  [11:0]  io_in_0_bits_dbID,
  input  [1:0]   io_in_0_bits_ccID,
  input  [1:0]   io_in_0_bits_dataID,
  input          io_in_0_bits_traceTag,
  input  [31:0]  io_in_0_bits_be,
  input  [255:0] io_in_0_bits_data,
  input  [31:0]  io_in_0_bits_dataCheck,
  input  [3:0]   io_in_0_bits_poison,
  output         io_in_1_ready,
  input          io_in_1_valid,
  input  [10:0]  io_in_1_bits_tgtID,
  input  [11:0]  io_in_1_bits_txnID,
  input  [10:0]  io_in_1_bits_homeNID,
  input  [3:0]   io_in_1_bits_opcode,
  input  [1:0]   io_in_1_bits_respErr,
  input  [2:0]   io_in_1_bits_resp,
  input  [3:0]   io_in_1_bits_dataSource,
  input  [11:0]  io_in_1_bits_dbID,
  input  [1:0]   io_in_1_bits_ccID,
  input  [1:0]   io_in_1_bits_dataID,
  input          io_in_1_bits_traceTag,
  input  [31:0]  io_in_1_bits_be,
  input  [255:0] io_in_1_bits_data,
  input  [31:0]  io_in_1_bits_dataCheck,
  input  [3:0]   io_in_1_bits_poison,
  output         io_in_2_ready,
  input          io_in_2_valid,
  input  [10:0]  io_in_2_bits_tgtID,
  input  [11:0]  io_in_2_bits_txnID,
  input  [10:0]  io_in_2_bits_homeNID,
  input  [3:0]   io_in_2_bits_opcode,
  input  [1:0]   io_in_2_bits_respErr,
  input  [2:0]   io_in_2_bits_resp,
  input  [3:0]   io_in_2_bits_dataSource,
  input  [11:0]  io_in_2_bits_dbID,
  input  [1:0]   io_in_2_bits_ccID,
  input  [1:0]   io_in_2_bits_dataID,
  input          io_in_2_bits_traceTag,
  input  [31:0]  io_in_2_bits_be,
  input  [255:0] io_in_2_bits_data,
  input  [31:0]  io_in_2_bits_dataCheck,
  input  [3:0]   io_in_2_bits_poison,
  output         io_in_3_ready,
  input          io_in_3_valid,
  input  [10:0]  io_in_3_bits_tgtID,
  input  [11:0]  io_in_3_bits_txnID,
  input  [10:0]  io_in_3_bits_homeNID,
  input  [3:0]   io_in_3_bits_opcode,
  input  [1:0]   io_in_3_bits_respErr,
  input  [2:0]   io_in_3_bits_resp,
  input  [3:0]   io_in_3_bits_dataSource,
  input  [11:0]  io_in_3_bits_dbID,
  input  [1:0]   io_in_3_bits_ccID,
  input  [1:0]   io_in_3_bits_dataID,
  input          io_in_3_bits_traceTag,
  input  [31:0]  io_in_3_bits_be,
  input  [255:0] io_in_3_bits_data,
  input  [31:0]  io_in_3_bits_dataCheck,
  input  [3:0]   io_in_3_bits_poison,
  output         io_in_4_ready,
  input          io_in_4_valid,
  input  [3:0]   io_in_4_bits_qos,
  input  [10:0]  io_in_4_bits_tgtID,
  input  [11:0]  io_in_4_bits_txnID,
  input  [10:0]  io_in_4_bits_homeNID,
  input  [3:0]   io_in_4_bits_opcode,
  input  [1:0]   io_in_4_bits_respErr,
  input  [2:0]   io_in_4_bits_resp,
  input  [3:0]   io_in_4_bits_dataSource,
  input  [2:0]   io_in_4_bits_cBusy,
  input  [11:0]  io_in_4_bits_dbID,
  input  [1:0]   io_in_4_bits_ccID,
  input  [1:0]   io_in_4_bits_dataID,
  input  [1:0]   io_in_4_bits_tagOp,
  input  [7:0]   io_in_4_bits_tag,
  input  [1:0]   io_in_4_bits_tu,
  input          io_in_4_bits_traceTag,
  input  [3:0]   io_in_4_bits_rsvdc,
  input  [31:0]  io_in_4_bits_be,
  input  [255:0] io_in_4_bits_data,
  input  [31:0]  io_in_4_bits_dataCheck,
  input  [3:0]   io_in_4_bits_poison,
  input          io_out_ready,
  output         io_out_valid,
  output [3:0]   io_out_bits_qos,
  output [10:0]  io_out_bits_tgtID,
  output [11:0]  io_out_bits_txnID,
  output [10:0]  io_out_bits_homeNID,
  output [3:0]   io_out_bits_opcode,
  output [1:0]   io_out_bits_respErr,
  output [2:0]   io_out_bits_resp,
  output [3:0]   io_out_bits_dataSource,
  output [2:0]   io_out_bits_cBusy,
  output [11:0]  io_out_bits_dbID,
  output [1:0]   io_out_bits_ccID,
  output [1:0]   io_out_bits_dataID,
  output [1:0]   io_out_bits_tagOp,
  output [7:0]   io_out_bits_tag,
  output [1:0]   io_out_bits_tu,
  output         io_out_bits_traceTag,
  output [3:0]   io_out_bits_rsvdc,
  output [31:0]  io_out_bits_be,
  output [255:0] io_out_bits_data,
  output [31:0]  io_out_bits_dataCheck,
  output [3:0]   io_out_bits_poison
);
  typedef struct packed {
    logic [3:0] qos;
    logic [10:0] tgtID;
    logic [11:0] txnID;
    logic [10:0] homeNID;
    logic [3:0] opcode;
    logic [1:0] respErr;
    logic [2:0] resp;
    logic [3:0] dataSource;
    logic [2:0] cBusy;
    logic [11:0] dbID;
    logic [1:0] ccID;
    logic [1:0] dataID;
    logic [1:0] tagOp;
    logic [7:0] tag;
    logic [1:0] tu;
    logic [0:0] traceTag;
    logic [3:0] rsvdc;
    logic [31:0] be;
    logic [255:0] data;
    logic [31:0] dataCheck;
    logic [3:0] poison;
  } response_payload_t;
  localparam int PAYLOAD_WIDTH = 411;
  response_payload_t lane_0, lane_1, lane_2, lane_3, lane_4;
  logic [4:0] valid_lanes;
  logic [4:0] ready_lanes;
  logic [4:0][PAYLOAD_WIDTH-1:0] lane_payloads;
  logic [PAYLOAD_WIDTH-1:0] selected_payload_bits;
  response_payload_t selected_payload;

  assign lane_0.qos = 4'h0;
  assign lane_0.tgtID = io_in_0_bits_tgtID;
  assign lane_0.txnID = io_in_0_bits_txnID;
  assign lane_0.homeNID = io_in_0_bits_homeNID;
  assign lane_0.opcode = io_in_0_bits_opcode;
  assign lane_0.respErr = io_in_0_bits_respErr;
  assign lane_0.resp = io_in_0_bits_resp;
  assign lane_0.dataSource = io_in_0_bits_dataSource;
  assign lane_0.cBusy = 3'h0;
  assign lane_0.dbID = io_in_0_bits_dbID;
  assign lane_0.ccID = io_in_0_bits_ccID;
  assign lane_0.dataID = io_in_0_bits_dataID;
  assign lane_0.tagOp = 2'h0;
  assign lane_0.tag = 8'h0;
  assign lane_0.tu = 2'h0;
  assign lane_0.traceTag = io_in_0_bits_traceTag;
  assign lane_0.rsvdc = 4'h0;
  assign lane_0.be = io_in_0_bits_be;
  assign lane_0.data = io_in_0_bits_data;
  assign lane_0.dataCheck = io_in_0_bits_dataCheck;
  assign lane_0.poison = io_in_0_bits_poison;
  assign lane_1.qos = 4'h0;
  assign lane_1.tgtID = io_in_1_bits_tgtID;
  assign lane_1.txnID = io_in_1_bits_txnID;
  assign lane_1.homeNID = io_in_1_bits_homeNID;
  assign lane_1.opcode = io_in_1_bits_opcode;
  assign lane_1.respErr = io_in_1_bits_respErr;
  assign lane_1.resp = io_in_1_bits_resp;
  assign lane_1.dataSource = io_in_1_bits_dataSource;
  assign lane_1.cBusy = 3'h0;
  assign lane_1.dbID = io_in_1_bits_dbID;
  assign lane_1.ccID = io_in_1_bits_ccID;
  assign lane_1.dataID = io_in_1_bits_dataID;
  assign lane_1.tagOp = 2'h0;
  assign lane_1.tag = 8'h0;
  assign lane_1.tu = 2'h0;
  assign lane_1.traceTag = io_in_1_bits_traceTag;
  assign lane_1.rsvdc = 4'h0;
  assign lane_1.be = io_in_1_bits_be;
  assign lane_1.data = io_in_1_bits_data;
  assign lane_1.dataCheck = io_in_1_bits_dataCheck;
  assign lane_1.poison = io_in_1_bits_poison;
  assign lane_2.qos = 4'h0;
  assign lane_2.tgtID = io_in_2_bits_tgtID;
  assign lane_2.txnID = io_in_2_bits_txnID;
  assign lane_2.homeNID = io_in_2_bits_homeNID;
  assign lane_2.opcode = io_in_2_bits_opcode;
  assign lane_2.respErr = io_in_2_bits_respErr;
  assign lane_2.resp = io_in_2_bits_resp;
  assign lane_2.dataSource = io_in_2_bits_dataSource;
  assign lane_2.cBusy = 3'h0;
  assign lane_2.dbID = io_in_2_bits_dbID;
  assign lane_2.ccID = io_in_2_bits_ccID;
  assign lane_2.dataID = io_in_2_bits_dataID;
  assign lane_2.tagOp = 2'h0;
  assign lane_2.tag = 8'h0;
  assign lane_2.tu = 2'h0;
  assign lane_2.traceTag = io_in_2_bits_traceTag;
  assign lane_2.rsvdc = 4'h0;
  assign lane_2.be = io_in_2_bits_be;
  assign lane_2.data = io_in_2_bits_data;
  assign lane_2.dataCheck = io_in_2_bits_dataCheck;
  assign lane_2.poison = io_in_2_bits_poison;
  assign lane_3.qos = 4'h0;
  assign lane_3.tgtID = io_in_3_bits_tgtID;
  assign lane_3.txnID = io_in_3_bits_txnID;
  assign lane_3.homeNID = io_in_3_bits_homeNID;
  assign lane_3.opcode = io_in_3_bits_opcode;
  assign lane_3.respErr = io_in_3_bits_respErr;
  assign lane_3.resp = io_in_3_bits_resp;
  assign lane_3.dataSource = io_in_3_bits_dataSource;
  assign lane_3.cBusy = 3'h0;
  assign lane_3.dbID = io_in_3_bits_dbID;
  assign lane_3.ccID = io_in_3_bits_ccID;
  assign lane_3.dataID = io_in_3_bits_dataID;
  assign lane_3.tagOp = 2'h0;
  assign lane_3.tag = 8'h0;
  assign lane_3.tu = 2'h0;
  assign lane_3.traceTag = io_in_3_bits_traceTag;
  assign lane_3.rsvdc = 4'h0;
  assign lane_3.be = io_in_3_bits_be;
  assign lane_3.data = io_in_3_bits_data;
  assign lane_3.dataCheck = io_in_3_bits_dataCheck;
  assign lane_3.poison = io_in_3_bits_poison;
  assign lane_4.qos = io_in_4_bits_qos;
  assign lane_4.tgtID = io_in_4_bits_tgtID;
  assign lane_4.txnID = io_in_4_bits_txnID;
  assign lane_4.homeNID = io_in_4_bits_homeNID;
  assign lane_4.opcode = io_in_4_bits_opcode;
  assign lane_4.respErr = io_in_4_bits_respErr;
  assign lane_4.resp = io_in_4_bits_resp;
  assign lane_4.dataSource = io_in_4_bits_dataSource;
  assign lane_4.cBusy = io_in_4_bits_cBusy;
  assign lane_4.dbID = io_in_4_bits_dbID;
  assign lane_4.ccID = io_in_4_bits_ccID;
  assign lane_4.dataID = io_in_4_bits_dataID;
  assign lane_4.tagOp = io_in_4_bits_tagOp;
  assign lane_4.tag = io_in_4_bits_tag;
  assign lane_4.tu = io_in_4_bits_tu;
  assign lane_4.traceTag = io_in_4_bits_traceTag;
  assign lane_4.rsvdc = io_in_4_bits_rsvdc;
  assign lane_4.be = io_in_4_bits_be;
  assign lane_4.data = io_in_4_bits_data;
  assign lane_4.dataCheck = io_in_4_bits_dataCheck;
  assign lane_4.poison = io_in_4_bits_poison;
  assign valid_lanes = {io_in_4_valid, io_in_3_valid, io_in_2_valid, io_in_1_valid, io_in_0_valid};
  assign lane_payloads[0] = lane_0;
  assign lane_payloads[1] = lane_1;
  assign lane_payloads[2] = lane_2;
  assign lane_payloads[3] = lane_3;
  assign lane_payloads[4] = lane_4;

  xs_FastArbiter_core #(.N(5), .W(PAYLOAD_WIDTH)) u_arbiter (
    .clock(clock), .reset(reset), .in_valid(valid_lanes), .in_bits(lane_payloads),
    .in_ready(ready_lanes), .out_ready(io_out_ready),
    .out_valid(io_out_valid), .out_bits(selected_payload_bits));
  assign selected_payload = selected_payload_bits;
  assign io_in_0_ready = ready_lanes[0];
  assign io_in_1_ready = ready_lanes[1];
  assign io_in_2_ready = ready_lanes[2];
  assign io_in_3_ready = ready_lanes[3];
  assign io_in_4_ready = ready_lanes[4];
  assign io_out_bits_qos = selected_payload.qos;
  assign io_out_bits_tgtID = selected_payload.tgtID;
  assign io_out_bits_txnID = selected_payload.txnID;
  assign io_out_bits_homeNID = selected_payload.homeNID;
  assign io_out_bits_opcode = selected_payload.opcode;
  assign io_out_bits_respErr = selected_payload.respErr;
  assign io_out_bits_resp = selected_payload.resp;
  assign io_out_bits_dataSource = selected_payload.dataSource;
  assign io_out_bits_cBusy = selected_payload.cBusy;
  assign io_out_bits_dbID = selected_payload.dbID;
  assign io_out_bits_ccID = selected_payload.ccID;
  assign io_out_bits_dataID = selected_payload.dataID;
  assign io_out_bits_tagOp = selected_payload.tagOp;
  assign io_out_bits_tag = selected_payload.tag;
  assign io_out_bits_tu = selected_payload.tu;
  assign io_out_bits_traceTag = selected_payload.traceTag;
  assign io_out_bits_rsvdc = selected_payload.rsvdc;
  assign io_out_bits_be = selected_payload.be;
  assign io_out_bits_data = selected_payload.data;
  assign io_out_bits_dataCheck = selected_payload.dataCheck;
  assign io_out_bits_poison = selected_payload.poison;
endmodule

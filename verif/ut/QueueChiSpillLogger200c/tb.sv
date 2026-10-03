// Focused G1 differential regression for the five remaining 200c leaves.
// Inputs are driven on falling edges; every known observable output is
// compared after the following rising edge against the untouched golden.
`timescale 1ns/1ps
module tb;
  bit clock = 1'b0;
  logic reset = 1'b0;
  integer errors = 0, checks = 0;
  integer cycles = 0;
  always #5 clock = ~clock;

  // Queue1_CHIDAT
  logic g_Queue1_CHIDAT_io_enq_ready;
  logic i_Queue1_CHIDAT_io_enq_ready;
  logic g_Queue1_CHIDAT_io_enq_valid;
  logic i_Queue1_CHIDAT_io_enq_valid;
  logic [3:0] g_Queue1_CHIDAT_io_enq_bits_qos;
  logic [3:0] i_Queue1_CHIDAT_io_enq_bits_qos;
  logic [10:0] g_Queue1_CHIDAT_io_enq_bits_tgtID;
  logic [10:0] i_Queue1_CHIDAT_io_enq_bits_tgtID;
  logic [10:0] g_Queue1_CHIDAT_io_enq_bits_srcID;
  logic [10:0] i_Queue1_CHIDAT_io_enq_bits_srcID;
  logic [11:0] g_Queue1_CHIDAT_io_enq_bits_txnID;
  logic [11:0] i_Queue1_CHIDAT_io_enq_bits_txnID;
  logic [10:0] g_Queue1_CHIDAT_io_enq_bits_homeNID;
  logic [10:0] i_Queue1_CHIDAT_io_enq_bits_homeNID;
  logic [3:0] g_Queue1_CHIDAT_io_enq_bits_opcode;
  logic [3:0] i_Queue1_CHIDAT_io_enq_bits_opcode;
  logic [1:0] g_Queue1_CHIDAT_io_enq_bits_respErr;
  logic [1:0] i_Queue1_CHIDAT_io_enq_bits_respErr;
  logic [2:0] g_Queue1_CHIDAT_io_enq_bits_resp;
  logic [2:0] i_Queue1_CHIDAT_io_enq_bits_resp;
  logic [3:0] g_Queue1_CHIDAT_io_enq_bits_dataSource;
  logic [3:0] i_Queue1_CHIDAT_io_enq_bits_dataSource;
  logic [2:0] g_Queue1_CHIDAT_io_enq_bits_cBusy;
  logic [2:0] i_Queue1_CHIDAT_io_enq_bits_cBusy;
  logic [11:0] g_Queue1_CHIDAT_io_enq_bits_dbID;
  logic [11:0] i_Queue1_CHIDAT_io_enq_bits_dbID;
  logic [1:0] g_Queue1_CHIDAT_io_enq_bits_ccID;
  logic [1:0] i_Queue1_CHIDAT_io_enq_bits_ccID;
  logic [1:0] g_Queue1_CHIDAT_io_enq_bits_dataID;
  logic [1:0] i_Queue1_CHIDAT_io_enq_bits_dataID;
  logic [1:0] g_Queue1_CHIDAT_io_enq_bits_tagOp;
  logic [1:0] i_Queue1_CHIDAT_io_enq_bits_tagOp;
  logic [7:0] g_Queue1_CHIDAT_io_enq_bits_tag;
  logic [7:0] i_Queue1_CHIDAT_io_enq_bits_tag;
  logic [1:0] g_Queue1_CHIDAT_io_enq_bits_tu;
  logic [1:0] i_Queue1_CHIDAT_io_enq_bits_tu;
  logic g_Queue1_CHIDAT_io_enq_bits_traceTag;
  logic i_Queue1_CHIDAT_io_enq_bits_traceTag;
  logic [3:0] g_Queue1_CHIDAT_io_enq_bits_rsvdc;
  logic [3:0] i_Queue1_CHIDAT_io_enq_bits_rsvdc;
  logic [31:0] g_Queue1_CHIDAT_io_enq_bits_be;
  logic [31:0] i_Queue1_CHIDAT_io_enq_bits_be;
  logic [255:0] g_Queue1_CHIDAT_io_enq_bits_data;
  logic [255:0] i_Queue1_CHIDAT_io_enq_bits_data;
  logic [31:0] g_Queue1_CHIDAT_io_enq_bits_dataCheck;
  logic [31:0] i_Queue1_CHIDAT_io_enq_bits_dataCheck;
  logic [3:0] g_Queue1_CHIDAT_io_enq_bits_poison;
  logic [3:0] i_Queue1_CHIDAT_io_enq_bits_poison;
  logic g_Queue1_CHIDAT_io_deq_ready;
  logic i_Queue1_CHIDAT_io_deq_ready;
  logic g_Queue1_CHIDAT_io_deq_valid;
  logic i_Queue1_CHIDAT_io_deq_valid;
  logic [3:0] g_Queue1_CHIDAT_io_deq_bits_qos;
  logic [3:0] i_Queue1_CHIDAT_io_deq_bits_qos;
  logic [10:0] g_Queue1_CHIDAT_io_deq_bits_tgtID;
  logic [10:0] i_Queue1_CHIDAT_io_deq_bits_tgtID;
  logic [10:0] g_Queue1_CHIDAT_io_deq_bits_srcID;
  logic [10:0] i_Queue1_CHIDAT_io_deq_bits_srcID;
  logic [11:0] g_Queue1_CHIDAT_io_deq_bits_txnID;
  logic [11:0] i_Queue1_CHIDAT_io_deq_bits_txnID;
  logic [10:0] g_Queue1_CHIDAT_io_deq_bits_homeNID;
  logic [10:0] i_Queue1_CHIDAT_io_deq_bits_homeNID;
  logic [3:0] g_Queue1_CHIDAT_io_deq_bits_opcode;
  logic [3:0] i_Queue1_CHIDAT_io_deq_bits_opcode;
  logic [1:0] g_Queue1_CHIDAT_io_deq_bits_respErr;
  logic [1:0] i_Queue1_CHIDAT_io_deq_bits_respErr;
  logic [2:0] g_Queue1_CHIDAT_io_deq_bits_resp;
  logic [2:0] i_Queue1_CHIDAT_io_deq_bits_resp;
  logic [3:0] g_Queue1_CHIDAT_io_deq_bits_dataSource;
  logic [3:0] i_Queue1_CHIDAT_io_deq_bits_dataSource;
  logic [2:0] g_Queue1_CHIDAT_io_deq_bits_cBusy;
  logic [2:0] i_Queue1_CHIDAT_io_deq_bits_cBusy;
  logic [11:0] g_Queue1_CHIDAT_io_deq_bits_dbID;
  logic [11:0] i_Queue1_CHIDAT_io_deq_bits_dbID;
  logic [1:0] g_Queue1_CHIDAT_io_deq_bits_ccID;
  logic [1:0] i_Queue1_CHIDAT_io_deq_bits_ccID;
  logic [1:0] g_Queue1_CHIDAT_io_deq_bits_dataID;
  logic [1:0] i_Queue1_CHIDAT_io_deq_bits_dataID;
  logic [1:0] g_Queue1_CHIDAT_io_deq_bits_tagOp;
  logic [1:0] i_Queue1_CHIDAT_io_deq_bits_tagOp;
  logic [7:0] g_Queue1_CHIDAT_io_deq_bits_tag;
  logic [7:0] i_Queue1_CHIDAT_io_deq_bits_tag;
  logic [1:0] g_Queue1_CHIDAT_io_deq_bits_tu;
  logic [1:0] i_Queue1_CHIDAT_io_deq_bits_tu;
  logic g_Queue1_CHIDAT_io_deq_bits_traceTag;
  logic i_Queue1_CHIDAT_io_deq_bits_traceTag;
  logic [3:0] g_Queue1_CHIDAT_io_deq_bits_rsvdc;
  logic [3:0] i_Queue1_CHIDAT_io_deq_bits_rsvdc;
  logic [31:0] g_Queue1_CHIDAT_io_deq_bits_be;
  logic [31:0] i_Queue1_CHIDAT_io_deq_bits_be;
  logic [255:0] g_Queue1_CHIDAT_io_deq_bits_data;
  logic [255:0] i_Queue1_CHIDAT_io_deq_bits_data;
  logic [31:0] g_Queue1_CHIDAT_io_deq_bits_dataCheck;
  logic [31:0] i_Queue1_CHIDAT_io_deq_bits_dataCheck;
  logic [3:0] g_Queue1_CHIDAT_io_deq_bits_poison;
  logic [3:0] i_Queue1_CHIDAT_io_deq_bits_poison;

  Queue1_CHIDAT g_Queue1_CHIDAT (
    .clock(clock),
    .reset(reset),
    .io_enq_ready(g_Queue1_CHIDAT_io_enq_ready),
    .io_enq_valid(g_Queue1_CHIDAT_io_enq_valid),
    .io_enq_bits_qos(g_Queue1_CHIDAT_io_enq_bits_qos),
    .io_enq_bits_tgtID(g_Queue1_CHIDAT_io_enq_bits_tgtID),
    .io_enq_bits_srcID(g_Queue1_CHIDAT_io_enq_bits_srcID),
    .io_enq_bits_txnID(g_Queue1_CHIDAT_io_enq_bits_txnID),
    .io_enq_bits_homeNID(g_Queue1_CHIDAT_io_enq_bits_homeNID),
    .io_enq_bits_opcode(g_Queue1_CHIDAT_io_enq_bits_opcode),
    .io_enq_bits_respErr(g_Queue1_CHIDAT_io_enq_bits_respErr),
    .io_enq_bits_resp(g_Queue1_CHIDAT_io_enq_bits_resp),
    .io_enq_bits_dataSource(g_Queue1_CHIDAT_io_enq_bits_dataSource),
    .io_enq_bits_cBusy(g_Queue1_CHIDAT_io_enq_bits_cBusy),
    .io_enq_bits_dbID(g_Queue1_CHIDAT_io_enq_bits_dbID),
    .io_enq_bits_ccID(g_Queue1_CHIDAT_io_enq_bits_ccID),
    .io_enq_bits_dataID(g_Queue1_CHIDAT_io_enq_bits_dataID),
    .io_enq_bits_tagOp(g_Queue1_CHIDAT_io_enq_bits_tagOp),
    .io_enq_bits_tag(g_Queue1_CHIDAT_io_enq_bits_tag),
    .io_enq_bits_tu(g_Queue1_CHIDAT_io_enq_bits_tu),
    .io_enq_bits_traceTag(g_Queue1_CHIDAT_io_enq_bits_traceTag),
    .io_enq_bits_rsvdc(g_Queue1_CHIDAT_io_enq_bits_rsvdc),
    .io_enq_bits_be(g_Queue1_CHIDAT_io_enq_bits_be),
    .io_enq_bits_data(g_Queue1_CHIDAT_io_enq_bits_data),
    .io_enq_bits_dataCheck(g_Queue1_CHIDAT_io_enq_bits_dataCheck),
    .io_enq_bits_poison(g_Queue1_CHIDAT_io_enq_bits_poison),
    .io_deq_ready(g_Queue1_CHIDAT_io_deq_ready),
    .io_deq_valid(g_Queue1_CHIDAT_io_deq_valid),
    .io_deq_bits_qos(g_Queue1_CHIDAT_io_deq_bits_qos),
    .io_deq_bits_tgtID(g_Queue1_CHIDAT_io_deq_bits_tgtID),
    .io_deq_bits_srcID(g_Queue1_CHIDAT_io_deq_bits_srcID),
    .io_deq_bits_txnID(g_Queue1_CHIDAT_io_deq_bits_txnID),
    .io_deq_bits_homeNID(g_Queue1_CHIDAT_io_deq_bits_homeNID),
    .io_deq_bits_opcode(g_Queue1_CHIDAT_io_deq_bits_opcode),
    .io_deq_bits_respErr(g_Queue1_CHIDAT_io_deq_bits_respErr),
    .io_deq_bits_resp(g_Queue1_CHIDAT_io_deq_bits_resp),
    .io_deq_bits_dataSource(g_Queue1_CHIDAT_io_deq_bits_dataSource),
    .io_deq_bits_cBusy(g_Queue1_CHIDAT_io_deq_bits_cBusy),
    .io_deq_bits_dbID(g_Queue1_CHIDAT_io_deq_bits_dbID),
    .io_deq_bits_ccID(g_Queue1_CHIDAT_io_deq_bits_ccID),
    .io_deq_bits_dataID(g_Queue1_CHIDAT_io_deq_bits_dataID),
    .io_deq_bits_tagOp(g_Queue1_CHIDAT_io_deq_bits_tagOp),
    .io_deq_bits_tag(g_Queue1_CHIDAT_io_deq_bits_tag),
    .io_deq_bits_tu(g_Queue1_CHIDAT_io_deq_bits_tu),
    .io_deq_bits_traceTag(g_Queue1_CHIDAT_io_deq_bits_traceTag),
    .io_deq_bits_rsvdc(g_Queue1_CHIDAT_io_deq_bits_rsvdc),
    .io_deq_bits_be(g_Queue1_CHIDAT_io_deq_bits_be),
    .io_deq_bits_data(g_Queue1_CHIDAT_io_deq_bits_data),
    .io_deq_bits_dataCheck(g_Queue1_CHIDAT_io_deq_bits_dataCheck),
    .io_deq_bits_poison(g_Queue1_CHIDAT_io_deq_bits_poison)
  );

  Queue1_CHIDAT_xs i_Queue1_CHIDAT (
    .clock(clock),
    .reset(reset),
    .io_enq_ready(i_Queue1_CHIDAT_io_enq_ready),
    .io_enq_valid(i_Queue1_CHIDAT_io_enq_valid),
    .io_enq_bits_qos(i_Queue1_CHIDAT_io_enq_bits_qos),
    .io_enq_bits_tgtID(i_Queue1_CHIDAT_io_enq_bits_tgtID),
    .io_enq_bits_srcID(i_Queue1_CHIDAT_io_enq_bits_srcID),
    .io_enq_bits_txnID(i_Queue1_CHIDAT_io_enq_bits_txnID),
    .io_enq_bits_homeNID(i_Queue1_CHIDAT_io_enq_bits_homeNID),
    .io_enq_bits_opcode(i_Queue1_CHIDAT_io_enq_bits_opcode),
    .io_enq_bits_respErr(i_Queue1_CHIDAT_io_enq_bits_respErr),
    .io_enq_bits_resp(i_Queue1_CHIDAT_io_enq_bits_resp),
    .io_enq_bits_dataSource(i_Queue1_CHIDAT_io_enq_bits_dataSource),
    .io_enq_bits_cBusy(i_Queue1_CHIDAT_io_enq_bits_cBusy),
    .io_enq_bits_dbID(i_Queue1_CHIDAT_io_enq_bits_dbID),
    .io_enq_bits_ccID(i_Queue1_CHIDAT_io_enq_bits_ccID),
    .io_enq_bits_dataID(i_Queue1_CHIDAT_io_enq_bits_dataID),
    .io_enq_bits_tagOp(i_Queue1_CHIDAT_io_enq_bits_tagOp),
    .io_enq_bits_tag(i_Queue1_CHIDAT_io_enq_bits_tag),
    .io_enq_bits_tu(i_Queue1_CHIDAT_io_enq_bits_tu),
    .io_enq_bits_traceTag(i_Queue1_CHIDAT_io_enq_bits_traceTag),
    .io_enq_bits_rsvdc(i_Queue1_CHIDAT_io_enq_bits_rsvdc),
    .io_enq_bits_be(i_Queue1_CHIDAT_io_enq_bits_be),
    .io_enq_bits_data(i_Queue1_CHIDAT_io_enq_bits_data),
    .io_enq_bits_dataCheck(i_Queue1_CHIDAT_io_enq_bits_dataCheck),
    .io_enq_bits_poison(i_Queue1_CHIDAT_io_enq_bits_poison),
    .io_deq_ready(i_Queue1_CHIDAT_io_deq_ready),
    .io_deq_valid(i_Queue1_CHIDAT_io_deq_valid),
    .io_deq_bits_qos(i_Queue1_CHIDAT_io_deq_bits_qos),
    .io_deq_bits_tgtID(i_Queue1_CHIDAT_io_deq_bits_tgtID),
    .io_deq_bits_srcID(i_Queue1_CHIDAT_io_deq_bits_srcID),
    .io_deq_bits_txnID(i_Queue1_CHIDAT_io_deq_bits_txnID),
    .io_deq_bits_homeNID(i_Queue1_CHIDAT_io_deq_bits_homeNID),
    .io_deq_bits_opcode(i_Queue1_CHIDAT_io_deq_bits_opcode),
    .io_deq_bits_respErr(i_Queue1_CHIDAT_io_deq_bits_respErr),
    .io_deq_bits_resp(i_Queue1_CHIDAT_io_deq_bits_resp),
    .io_deq_bits_dataSource(i_Queue1_CHIDAT_io_deq_bits_dataSource),
    .io_deq_bits_cBusy(i_Queue1_CHIDAT_io_deq_bits_cBusy),
    .io_deq_bits_dbID(i_Queue1_CHIDAT_io_deq_bits_dbID),
    .io_deq_bits_ccID(i_Queue1_CHIDAT_io_deq_bits_ccID),
    .io_deq_bits_dataID(i_Queue1_CHIDAT_io_deq_bits_dataID),
    .io_deq_bits_tagOp(i_Queue1_CHIDAT_io_deq_bits_tagOp),
    .io_deq_bits_tag(i_Queue1_CHIDAT_io_deq_bits_tag),
    .io_deq_bits_tu(i_Queue1_CHIDAT_io_deq_bits_tu),
    .io_deq_bits_traceTag(i_Queue1_CHIDAT_io_deq_bits_traceTag),
    .io_deq_bits_rsvdc(i_Queue1_CHIDAT_io_deq_bits_rsvdc),
    .io_deq_bits_be(i_Queue1_CHIDAT_io_deq_bits_be),
    .io_deq_bits_data(i_Queue1_CHIDAT_io_deq_bits_data),
    .io_deq_bits_dataCheck(i_Queue1_CHIDAT_io_deq_bits_dataCheck),
    .io_deq_bits_poison(i_Queue1_CHIDAT_io_deq_bits_poison)
  );

  // Queue1_CHIRSP
  logic g_Queue1_CHIRSP_io_enq_ready;
  logic i_Queue1_CHIRSP_io_enq_ready;
  logic g_Queue1_CHIRSP_io_enq_valid;
  logic i_Queue1_CHIRSP_io_enq_valid;
  logic [3:0] g_Queue1_CHIRSP_io_enq_bits_qos;
  logic [3:0] i_Queue1_CHIRSP_io_enq_bits_qos;
  logic [10:0] g_Queue1_CHIRSP_io_enq_bits_tgtID;
  logic [10:0] i_Queue1_CHIRSP_io_enq_bits_tgtID;
  logic [10:0] g_Queue1_CHIRSP_io_enq_bits_srcID;
  logic [10:0] i_Queue1_CHIRSP_io_enq_bits_srcID;
  logic [11:0] g_Queue1_CHIRSP_io_enq_bits_txnID;
  logic [11:0] i_Queue1_CHIRSP_io_enq_bits_txnID;
  logic [4:0] g_Queue1_CHIRSP_io_enq_bits_opcode;
  logic [4:0] i_Queue1_CHIRSP_io_enq_bits_opcode;
  logic [1:0] g_Queue1_CHIRSP_io_enq_bits_respErr;
  logic [1:0] i_Queue1_CHIRSP_io_enq_bits_respErr;
  logic [2:0] g_Queue1_CHIRSP_io_enq_bits_resp;
  logic [2:0] i_Queue1_CHIRSP_io_enq_bits_resp;
  logic [2:0] g_Queue1_CHIRSP_io_enq_bits_fwdState;
  logic [2:0] i_Queue1_CHIRSP_io_enq_bits_fwdState;
  logic [2:0] g_Queue1_CHIRSP_io_enq_bits_cBusy;
  logic [2:0] i_Queue1_CHIRSP_io_enq_bits_cBusy;
  logic [11:0] g_Queue1_CHIRSP_io_enq_bits_dbID;
  logic [11:0] i_Queue1_CHIRSP_io_enq_bits_dbID;
  logic [3:0] g_Queue1_CHIRSP_io_enq_bits_pCrdType;
  logic [3:0] i_Queue1_CHIRSP_io_enq_bits_pCrdType;
  logic [1:0] g_Queue1_CHIRSP_io_enq_bits_tagOp;
  logic [1:0] i_Queue1_CHIRSP_io_enq_bits_tagOp;
  logic g_Queue1_CHIRSP_io_enq_bits_traceTag;
  logic i_Queue1_CHIRSP_io_enq_bits_traceTag;
  logic g_Queue1_CHIRSP_io_deq_ready;
  logic i_Queue1_CHIRSP_io_deq_ready;
  logic g_Queue1_CHIRSP_io_deq_valid;
  logic i_Queue1_CHIRSP_io_deq_valid;
  logic [3:0] g_Queue1_CHIRSP_io_deq_bits_qos;
  logic [3:0] i_Queue1_CHIRSP_io_deq_bits_qos;
  logic [10:0] g_Queue1_CHIRSP_io_deq_bits_tgtID;
  logic [10:0] i_Queue1_CHIRSP_io_deq_bits_tgtID;
  logic [10:0] g_Queue1_CHIRSP_io_deq_bits_srcID;
  logic [10:0] i_Queue1_CHIRSP_io_deq_bits_srcID;
  logic [11:0] g_Queue1_CHIRSP_io_deq_bits_txnID;
  logic [11:0] i_Queue1_CHIRSP_io_deq_bits_txnID;
  logic [4:0] g_Queue1_CHIRSP_io_deq_bits_opcode;
  logic [4:0] i_Queue1_CHIRSP_io_deq_bits_opcode;
  logic [1:0] g_Queue1_CHIRSP_io_deq_bits_respErr;
  logic [1:0] i_Queue1_CHIRSP_io_deq_bits_respErr;
  logic [2:0] g_Queue1_CHIRSP_io_deq_bits_resp;
  logic [2:0] i_Queue1_CHIRSP_io_deq_bits_resp;
  logic [2:0] g_Queue1_CHIRSP_io_deq_bits_fwdState;
  logic [2:0] i_Queue1_CHIRSP_io_deq_bits_fwdState;
  logic [2:0] g_Queue1_CHIRSP_io_deq_bits_cBusy;
  logic [2:0] i_Queue1_CHIRSP_io_deq_bits_cBusy;
  logic [11:0] g_Queue1_CHIRSP_io_deq_bits_dbID;
  logic [11:0] i_Queue1_CHIRSP_io_deq_bits_dbID;
  logic [3:0] g_Queue1_CHIRSP_io_deq_bits_pCrdType;
  logic [3:0] i_Queue1_CHIRSP_io_deq_bits_pCrdType;
  logic [1:0] g_Queue1_CHIRSP_io_deq_bits_tagOp;
  logic [1:0] i_Queue1_CHIRSP_io_deq_bits_tagOp;
  logic g_Queue1_CHIRSP_io_deq_bits_traceTag;
  logic i_Queue1_CHIRSP_io_deq_bits_traceTag;

  Queue1_CHIRSP g_Queue1_CHIRSP (
    .clock(clock),
    .reset(reset),
    .io_enq_ready(g_Queue1_CHIRSP_io_enq_ready),
    .io_enq_valid(g_Queue1_CHIRSP_io_enq_valid),
    .io_enq_bits_qos(g_Queue1_CHIRSP_io_enq_bits_qos),
    .io_enq_bits_tgtID(g_Queue1_CHIRSP_io_enq_bits_tgtID),
    .io_enq_bits_srcID(g_Queue1_CHIRSP_io_enq_bits_srcID),
    .io_enq_bits_txnID(g_Queue1_CHIRSP_io_enq_bits_txnID),
    .io_enq_bits_opcode(g_Queue1_CHIRSP_io_enq_bits_opcode),
    .io_enq_bits_respErr(g_Queue1_CHIRSP_io_enq_bits_respErr),
    .io_enq_bits_resp(g_Queue1_CHIRSP_io_enq_bits_resp),
    .io_enq_bits_fwdState(g_Queue1_CHIRSP_io_enq_bits_fwdState),
    .io_enq_bits_cBusy(g_Queue1_CHIRSP_io_enq_bits_cBusy),
    .io_enq_bits_dbID(g_Queue1_CHIRSP_io_enq_bits_dbID),
    .io_enq_bits_pCrdType(g_Queue1_CHIRSP_io_enq_bits_pCrdType),
    .io_enq_bits_tagOp(g_Queue1_CHIRSP_io_enq_bits_tagOp),
    .io_enq_bits_traceTag(g_Queue1_CHIRSP_io_enq_bits_traceTag),
    .io_deq_ready(g_Queue1_CHIRSP_io_deq_ready),
    .io_deq_valid(g_Queue1_CHIRSP_io_deq_valid),
    .io_deq_bits_qos(g_Queue1_CHIRSP_io_deq_bits_qos),
    .io_deq_bits_tgtID(g_Queue1_CHIRSP_io_deq_bits_tgtID),
    .io_deq_bits_srcID(g_Queue1_CHIRSP_io_deq_bits_srcID),
    .io_deq_bits_txnID(g_Queue1_CHIRSP_io_deq_bits_txnID),
    .io_deq_bits_opcode(g_Queue1_CHIRSP_io_deq_bits_opcode),
    .io_deq_bits_respErr(g_Queue1_CHIRSP_io_deq_bits_respErr),
    .io_deq_bits_resp(g_Queue1_CHIRSP_io_deq_bits_resp),
    .io_deq_bits_fwdState(g_Queue1_CHIRSP_io_deq_bits_fwdState),
    .io_deq_bits_cBusy(g_Queue1_CHIRSP_io_deq_bits_cBusy),
    .io_deq_bits_dbID(g_Queue1_CHIRSP_io_deq_bits_dbID),
    .io_deq_bits_pCrdType(g_Queue1_CHIRSP_io_deq_bits_pCrdType),
    .io_deq_bits_tagOp(g_Queue1_CHIRSP_io_deq_bits_tagOp),
    .io_deq_bits_traceTag(g_Queue1_CHIRSP_io_deq_bits_traceTag)
  );

  Queue1_CHIRSP_xs i_Queue1_CHIRSP (
    .clock(clock),
    .reset(reset),
    .io_enq_ready(i_Queue1_CHIRSP_io_enq_ready),
    .io_enq_valid(i_Queue1_CHIRSP_io_enq_valid),
    .io_enq_bits_qos(i_Queue1_CHIRSP_io_enq_bits_qos),
    .io_enq_bits_tgtID(i_Queue1_CHIRSP_io_enq_bits_tgtID),
    .io_enq_bits_srcID(i_Queue1_CHIRSP_io_enq_bits_srcID),
    .io_enq_bits_txnID(i_Queue1_CHIRSP_io_enq_bits_txnID),
    .io_enq_bits_opcode(i_Queue1_CHIRSP_io_enq_bits_opcode),
    .io_enq_bits_respErr(i_Queue1_CHIRSP_io_enq_bits_respErr),
    .io_enq_bits_resp(i_Queue1_CHIRSP_io_enq_bits_resp),
    .io_enq_bits_fwdState(i_Queue1_CHIRSP_io_enq_bits_fwdState),
    .io_enq_bits_cBusy(i_Queue1_CHIRSP_io_enq_bits_cBusy),
    .io_enq_bits_dbID(i_Queue1_CHIRSP_io_enq_bits_dbID),
    .io_enq_bits_pCrdType(i_Queue1_CHIRSP_io_enq_bits_pCrdType),
    .io_enq_bits_tagOp(i_Queue1_CHIRSP_io_enq_bits_tagOp),
    .io_enq_bits_traceTag(i_Queue1_CHIRSP_io_enq_bits_traceTag),
    .io_deq_ready(i_Queue1_CHIRSP_io_deq_ready),
    .io_deq_valid(i_Queue1_CHIRSP_io_deq_valid),
    .io_deq_bits_qos(i_Queue1_CHIRSP_io_deq_bits_qos),
    .io_deq_bits_tgtID(i_Queue1_CHIRSP_io_deq_bits_tgtID),
    .io_deq_bits_srcID(i_Queue1_CHIRSP_io_deq_bits_srcID),
    .io_deq_bits_txnID(i_Queue1_CHIRSP_io_deq_bits_txnID),
    .io_deq_bits_opcode(i_Queue1_CHIRSP_io_deq_bits_opcode),
    .io_deq_bits_respErr(i_Queue1_CHIRSP_io_deq_bits_respErr),
    .io_deq_bits_resp(i_Queue1_CHIRSP_io_deq_bits_resp),
    .io_deq_bits_fwdState(i_Queue1_CHIRSP_io_deq_bits_fwdState),
    .io_deq_bits_cBusy(i_Queue1_CHIRSP_io_deq_bits_cBusy),
    .io_deq_bits_dbID(i_Queue1_CHIRSP_io_deq_bits_dbID),
    .io_deq_bits_pCrdType(i_Queue1_CHIRSP_io_deq_bits_pCrdType),
    .io_deq_bits_tagOp(i_Queue1_CHIRSP_io_deq_bits_tagOp),
    .io_deq_bits_traceTag(i_Queue1_CHIRSP_io_deq_bits_traceTag)
  );

  // SpillRegister_7
  logic g_SpillRegister_7_io_in_valid;
  logic i_SpillRegister_7_io_in_valid;
  logic g_SpillRegister_7_io_in_bits_0;
  logic i_SpillRegister_7_io_in_bits_0;
  logic g_SpillRegister_7_io_in_bits_1;
  logic i_SpillRegister_7_io_in_bits_1;
  logic g_SpillRegister_7_io_in_bits_2;
  logic i_SpillRegister_7_io_in_bits_2;
  logic g_SpillRegister_7_io_in_bits_3;
  logic i_SpillRegister_7_io_in_bits_3;
  logic g_SpillRegister_7_io_in_bits_4;
  logic i_SpillRegister_7_io_in_bits_4;
  logic g_SpillRegister_7_io_in_bits_5;
  logic i_SpillRegister_7_io_in_bits_5;
  logic g_SpillRegister_7_io_in_bits_6;
  logic i_SpillRegister_7_io_in_bits_6;
  logic g_SpillRegister_7_io_in_bits_7;
  logic i_SpillRegister_7_io_in_bits_7;
  logic g_SpillRegister_7_io_in_bits_8;
  logic i_SpillRegister_7_io_in_bits_8;
  logic g_SpillRegister_7_io_in_bits_9;
  logic i_SpillRegister_7_io_in_bits_9;
  logic g_SpillRegister_7_io_in_bits_10;
  logic i_SpillRegister_7_io_in_bits_10;
  logic g_SpillRegister_7_io_in_bits_11;
  logic i_SpillRegister_7_io_in_bits_11;
  logic g_SpillRegister_7_io_in_bits_12;
  logic i_SpillRegister_7_io_in_bits_12;
  logic g_SpillRegister_7_io_in_bits_13;
  logic i_SpillRegister_7_io_in_bits_13;
  logic g_SpillRegister_7_io_in_bits_14;
  logic i_SpillRegister_7_io_in_bits_14;
  logic g_SpillRegister_7_io_in_bits_15;
  logic i_SpillRegister_7_io_in_bits_15;
  logic g_SpillRegister_7_io_in_bits_16;
  logic i_SpillRegister_7_io_in_bits_16;
  logic g_SpillRegister_7_io_in_bits_17;
  logic i_SpillRegister_7_io_in_bits_17;
  logic g_SpillRegister_7_io_in_bits_18;
  logic i_SpillRegister_7_io_in_bits_18;
  logic g_SpillRegister_7_io_in_bits_19;
  logic i_SpillRegister_7_io_in_bits_19;
  logic g_SpillRegister_7_io_in_bits_20;
  logic i_SpillRegister_7_io_in_bits_20;
  logic g_SpillRegister_7_io_in_bits_21;
  logic i_SpillRegister_7_io_in_bits_21;
  logic g_SpillRegister_7_io_in_bits_22;
  logic i_SpillRegister_7_io_in_bits_22;
  logic g_SpillRegister_7_io_in_bits_23;
  logic i_SpillRegister_7_io_in_bits_23;
  logic g_SpillRegister_7_io_in_bits_24;
  logic i_SpillRegister_7_io_in_bits_24;
  logic g_SpillRegister_7_io_in_bits_25;
  logic i_SpillRegister_7_io_in_bits_25;
  logic g_SpillRegister_7_io_in_bits_26;
  logic i_SpillRegister_7_io_in_bits_26;
  logic g_SpillRegister_7_io_in_bits_27;
  logic i_SpillRegister_7_io_in_bits_27;
  logic g_SpillRegister_7_io_in_bits_28;
  logic i_SpillRegister_7_io_in_bits_28;
  logic g_SpillRegister_7_io_in_bits_29;
  logic i_SpillRegister_7_io_in_bits_29;
  logic g_SpillRegister_7_io_in_bits_30;
  logic i_SpillRegister_7_io_in_bits_30;
  logic g_SpillRegister_7_io_in_bits_31;
  logic i_SpillRegister_7_io_in_bits_31;
  logic g_SpillRegister_7_io_out_ready;
  logic i_SpillRegister_7_io_out_ready;
  logic g_SpillRegister_7_io_out_valid;
  logic i_SpillRegister_7_io_out_valid;
  logic g_SpillRegister_7_io_out_bits_0;
  logic i_SpillRegister_7_io_out_bits_0;
  logic g_SpillRegister_7_io_out_bits_1;
  logic i_SpillRegister_7_io_out_bits_1;
  logic g_SpillRegister_7_io_out_bits_2;
  logic i_SpillRegister_7_io_out_bits_2;
  logic g_SpillRegister_7_io_out_bits_3;
  logic i_SpillRegister_7_io_out_bits_3;
  logic g_SpillRegister_7_io_out_bits_4;
  logic i_SpillRegister_7_io_out_bits_4;
  logic g_SpillRegister_7_io_out_bits_5;
  logic i_SpillRegister_7_io_out_bits_5;
  logic g_SpillRegister_7_io_out_bits_6;
  logic i_SpillRegister_7_io_out_bits_6;
  logic g_SpillRegister_7_io_out_bits_7;
  logic i_SpillRegister_7_io_out_bits_7;
  logic g_SpillRegister_7_io_out_bits_8;
  logic i_SpillRegister_7_io_out_bits_8;
  logic g_SpillRegister_7_io_out_bits_9;
  logic i_SpillRegister_7_io_out_bits_9;
  logic g_SpillRegister_7_io_out_bits_10;
  logic i_SpillRegister_7_io_out_bits_10;
  logic g_SpillRegister_7_io_out_bits_11;
  logic i_SpillRegister_7_io_out_bits_11;
  logic g_SpillRegister_7_io_out_bits_12;
  logic i_SpillRegister_7_io_out_bits_12;
  logic g_SpillRegister_7_io_out_bits_13;
  logic i_SpillRegister_7_io_out_bits_13;
  logic g_SpillRegister_7_io_out_bits_14;
  logic i_SpillRegister_7_io_out_bits_14;
  logic g_SpillRegister_7_io_out_bits_15;
  logic i_SpillRegister_7_io_out_bits_15;
  logic g_SpillRegister_7_io_out_bits_16;
  logic i_SpillRegister_7_io_out_bits_16;
  logic g_SpillRegister_7_io_out_bits_17;
  logic i_SpillRegister_7_io_out_bits_17;
  logic g_SpillRegister_7_io_out_bits_18;
  logic i_SpillRegister_7_io_out_bits_18;
  logic g_SpillRegister_7_io_out_bits_19;
  logic i_SpillRegister_7_io_out_bits_19;
  logic g_SpillRegister_7_io_out_bits_20;
  logic i_SpillRegister_7_io_out_bits_20;
  logic g_SpillRegister_7_io_out_bits_21;
  logic i_SpillRegister_7_io_out_bits_21;
  logic g_SpillRegister_7_io_out_bits_22;
  logic i_SpillRegister_7_io_out_bits_22;
  logic g_SpillRegister_7_io_out_bits_23;
  logic i_SpillRegister_7_io_out_bits_23;
  logic g_SpillRegister_7_io_out_bits_24;
  logic i_SpillRegister_7_io_out_bits_24;
  logic g_SpillRegister_7_io_out_bits_25;
  logic i_SpillRegister_7_io_out_bits_25;
  logic g_SpillRegister_7_io_out_bits_26;
  logic i_SpillRegister_7_io_out_bits_26;
  logic g_SpillRegister_7_io_out_bits_27;
  logic i_SpillRegister_7_io_out_bits_27;
  logic g_SpillRegister_7_io_out_bits_28;
  logic i_SpillRegister_7_io_out_bits_28;
  logic g_SpillRegister_7_io_out_bits_29;
  logic i_SpillRegister_7_io_out_bits_29;
  logic g_SpillRegister_7_io_out_bits_30;
  logic i_SpillRegister_7_io_out_bits_30;
  logic g_SpillRegister_7_io_out_bits_31;
  logic i_SpillRegister_7_io_out_bits_31;

  SpillRegister_7 g_SpillRegister_7 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(g_SpillRegister_7_io_in_valid),
    .io_in_bits_0(g_SpillRegister_7_io_in_bits_0),
    .io_in_bits_1(g_SpillRegister_7_io_in_bits_1),
    .io_in_bits_2(g_SpillRegister_7_io_in_bits_2),
    .io_in_bits_3(g_SpillRegister_7_io_in_bits_3),
    .io_in_bits_4(g_SpillRegister_7_io_in_bits_4),
    .io_in_bits_5(g_SpillRegister_7_io_in_bits_5),
    .io_in_bits_6(g_SpillRegister_7_io_in_bits_6),
    .io_in_bits_7(g_SpillRegister_7_io_in_bits_7),
    .io_in_bits_8(g_SpillRegister_7_io_in_bits_8),
    .io_in_bits_9(g_SpillRegister_7_io_in_bits_9),
    .io_in_bits_10(g_SpillRegister_7_io_in_bits_10),
    .io_in_bits_11(g_SpillRegister_7_io_in_bits_11),
    .io_in_bits_12(g_SpillRegister_7_io_in_bits_12),
    .io_in_bits_13(g_SpillRegister_7_io_in_bits_13),
    .io_in_bits_14(g_SpillRegister_7_io_in_bits_14),
    .io_in_bits_15(g_SpillRegister_7_io_in_bits_15),
    .io_in_bits_16(g_SpillRegister_7_io_in_bits_16),
    .io_in_bits_17(g_SpillRegister_7_io_in_bits_17),
    .io_in_bits_18(g_SpillRegister_7_io_in_bits_18),
    .io_in_bits_19(g_SpillRegister_7_io_in_bits_19),
    .io_in_bits_20(g_SpillRegister_7_io_in_bits_20),
    .io_in_bits_21(g_SpillRegister_7_io_in_bits_21),
    .io_in_bits_22(g_SpillRegister_7_io_in_bits_22),
    .io_in_bits_23(g_SpillRegister_7_io_in_bits_23),
    .io_in_bits_24(g_SpillRegister_7_io_in_bits_24),
    .io_in_bits_25(g_SpillRegister_7_io_in_bits_25),
    .io_in_bits_26(g_SpillRegister_7_io_in_bits_26),
    .io_in_bits_27(g_SpillRegister_7_io_in_bits_27),
    .io_in_bits_28(g_SpillRegister_7_io_in_bits_28),
    .io_in_bits_29(g_SpillRegister_7_io_in_bits_29),
    .io_in_bits_30(g_SpillRegister_7_io_in_bits_30),
    .io_in_bits_31(g_SpillRegister_7_io_in_bits_31),
    .io_out_ready(g_SpillRegister_7_io_out_ready),
    .io_out_valid(g_SpillRegister_7_io_out_valid),
    .io_out_bits_0(g_SpillRegister_7_io_out_bits_0),
    .io_out_bits_1(g_SpillRegister_7_io_out_bits_1),
    .io_out_bits_2(g_SpillRegister_7_io_out_bits_2),
    .io_out_bits_3(g_SpillRegister_7_io_out_bits_3),
    .io_out_bits_4(g_SpillRegister_7_io_out_bits_4),
    .io_out_bits_5(g_SpillRegister_7_io_out_bits_5),
    .io_out_bits_6(g_SpillRegister_7_io_out_bits_6),
    .io_out_bits_7(g_SpillRegister_7_io_out_bits_7),
    .io_out_bits_8(g_SpillRegister_7_io_out_bits_8),
    .io_out_bits_9(g_SpillRegister_7_io_out_bits_9),
    .io_out_bits_10(g_SpillRegister_7_io_out_bits_10),
    .io_out_bits_11(g_SpillRegister_7_io_out_bits_11),
    .io_out_bits_12(g_SpillRegister_7_io_out_bits_12),
    .io_out_bits_13(g_SpillRegister_7_io_out_bits_13),
    .io_out_bits_14(g_SpillRegister_7_io_out_bits_14),
    .io_out_bits_15(g_SpillRegister_7_io_out_bits_15),
    .io_out_bits_16(g_SpillRegister_7_io_out_bits_16),
    .io_out_bits_17(g_SpillRegister_7_io_out_bits_17),
    .io_out_bits_18(g_SpillRegister_7_io_out_bits_18),
    .io_out_bits_19(g_SpillRegister_7_io_out_bits_19),
    .io_out_bits_20(g_SpillRegister_7_io_out_bits_20),
    .io_out_bits_21(g_SpillRegister_7_io_out_bits_21),
    .io_out_bits_22(g_SpillRegister_7_io_out_bits_22),
    .io_out_bits_23(g_SpillRegister_7_io_out_bits_23),
    .io_out_bits_24(g_SpillRegister_7_io_out_bits_24),
    .io_out_bits_25(g_SpillRegister_7_io_out_bits_25),
    .io_out_bits_26(g_SpillRegister_7_io_out_bits_26),
    .io_out_bits_27(g_SpillRegister_7_io_out_bits_27),
    .io_out_bits_28(g_SpillRegister_7_io_out_bits_28),
    .io_out_bits_29(g_SpillRegister_7_io_out_bits_29),
    .io_out_bits_30(g_SpillRegister_7_io_out_bits_30),
    .io_out_bits_31(g_SpillRegister_7_io_out_bits_31)
  );

  SpillRegister_7_xs i_SpillRegister_7 (
    .clock(clock),
    .reset(reset),
    .io_in_valid(i_SpillRegister_7_io_in_valid),
    .io_in_bits_0(i_SpillRegister_7_io_in_bits_0),
    .io_in_bits_1(i_SpillRegister_7_io_in_bits_1),
    .io_in_bits_2(i_SpillRegister_7_io_in_bits_2),
    .io_in_bits_3(i_SpillRegister_7_io_in_bits_3),
    .io_in_bits_4(i_SpillRegister_7_io_in_bits_4),
    .io_in_bits_5(i_SpillRegister_7_io_in_bits_5),
    .io_in_bits_6(i_SpillRegister_7_io_in_bits_6),
    .io_in_bits_7(i_SpillRegister_7_io_in_bits_7),
    .io_in_bits_8(i_SpillRegister_7_io_in_bits_8),
    .io_in_bits_9(i_SpillRegister_7_io_in_bits_9),
    .io_in_bits_10(i_SpillRegister_7_io_in_bits_10),
    .io_in_bits_11(i_SpillRegister_7_io_in_bits_11),
    .io_in_bits_12(i_SpillRegister_7_io_in_bits_12),
    .io_in_bits_13(i_SpillRegister_7_io_in_bits_13),
    .io_in_bits_14(i_SpillRegister_7_io_in_bits_14),
    .io_in_bits_15(i_SpillRegister_7_io_in_bits_15),
    .io_in_bits_16(i_SpillRegister_7_io_in_bits_16),
    .io_in_bits_17(i_SpillRegister_7_io_in_bits_17),
    .io_in_bits_18(i_SpillRegister_7_io_in_bits_18),
    .io_in_bits_19(i_SpillRegister_7_io_in_bits_19),
    .io_in_bits_20(i_SpillRegister_7_io_in_bits_20),
    .io_in_bits_21(i_SpillRegister_7_io_in_bits_21),
    .io_in_bits_22(i_SpillRegister_7_io_in_bits_22),
    .io_in_bits_23(i_SpillRegister_7_io_in_bits_23),
    .io_in_bits_24(i_SpillRegister_7_io_in_bits_24),
    .io_in_bits_25(i_SpillRegister_7_io_in_bits_25),
    .io_in_bits_26(i_SpillRegister_7_io_in_bits_26),
    .io_in_bits_27(i_SpillRegister_7_io_in_bits_27),
    .io_in_bits_28(i_SpillRegister_7_io_in_bits_28),
    .io_in_bits_29(i_SpillRegister_7_io_in_bits_29),
    .io_in_bits_30(i_SpillRegister_7_io_in_bits_30),
    .io_in_bits_31(i_SpillRegister_7_io_in_bits_31),
    .io_out_ready(i_SpillRegister_7_io_out_ready),
    .io_out_valid(i_SpillRegister_7_io_out_valid),
    .io_out_bits_0(i_SpillRegister_7_io_out_bits_0),
    .io_out_bits_1(i_SpillRegister_7_io_out_bits_1),
    .io_out_bits_2(i_SpillRegister_7_io_out_bits_2),
    .io_out_bits_3(i_SpillRegister_7_io_out_bits_3),
    .io_out_bits_4(i_SpillRegister_7_io_out_bits_4),
    .io_out_bits_5(i_SpillRegister_7_io_out_bits_5),
    .io_out_bits_6(i_SpillRegister_7_io_out_bits_6),
    .io_out_bits_7(i_SpillRegister_7_io_out_bits_7),
    .io_out_bits_8(i_SpillRegister_7_io_out_bits_8),
    .io_out_bits_9(i_SpillRegister_7_io_out_bits_9),
    .io_out_bits_10(i_SpillRegister_7_io_out_bits_10),
    .io_out_bits_11(i_SpillRegister_7_io_out_bits_11),
    .io_out_bits_12(i_SpillRegister_7_io_out_bits_12),
    .io_out_bits_13(i_SpillRegister_7_io_out_bits_13),
    .io_out_bits_14(i_SpillRegister_7_io_out_bits_14),
    .io_out_bits_15(i_SpillRegister_7_io_out_bits_15),
    .io_out_bits_16(i_SpillRegister_7_io_out_bits_16),
    .io_out_bits_17(i_SpillRegister_7_io_out_bits_17),
    .io_out_bits_18(i_SpillRegister_7_io_out_bits_18),
    .io_out_bits_19(i_SpillRegister_7_io_out_bits_19),
    .io_out_bits_20(i_SpillRegister_7_io_out_bits_20),
    .io_out_bits_21(i_SpillRegister_7_io_out_bits_21),
    .io_out_bits_22(i_SpillRegister_7_io_out_bits_22),
    .io_out_bits_23(i_SpillRegister_7_io_out_bits_23),
    .io_out_bits_24(i_SpillRegister_7_io_out_bits_24),
    .io_out_bits_25(i_SpillRegister_7_io_out_bits_25),
    .io_out_bits_26(i_SpillRegister_7_io_out_bits_26),
    .io_out_bits_27(i_SpillRegister_7_io_out_bits_27),
    .io_out_bits_28(i_SpillRegister_7_io_out_bits_28),
    .io_out_bits_29(i_SpillRegister_7_io_out_bits_29),
    .io_out_bits_30(i_SpillRegister_7_io_out_bits_30),
    .io_out_bits_31(i_SpillRegister_7_io_out_bits_31)
  );

  // TLLogger_1
  logic g_TLLogger_1_auto_in_a_ready;
  logic i_TLLogger_1_auto_in_a_ready;
  logic g_TLLogger_1_auto_in_a_valid;
  logic i_TLLogger_1_auto_in_a_valid;
  logic [3:0] g_TLLogger_1_auto_in_a_bits_opcode;
  logic [3:0] i_TLLogger_1_auto_in_a_bits_opcode;
  logic [2:0] g_TLLogger_1_auto_in_a_bits_param;
  logic [2:0] i_TLLogger_1_auto_in_a_bits_param;
  logic [2:0] g_TLLogger_1_auto_in_a_bits_size;
  logic [2:0] i_TLLogger_1_auto_in_a_bits_size;
  logic [3:0] g_TLLogger_1_auto_in_a_bits_source;
  logic [3:0] i_TLLogger_1_auto_in_a_bits_source;
  logic [47:0] g_TLLogger_1_auto_in_a_bits_address;
  logic [47:0] i_TLLogger_1_auto_in_a_bits_address;
  logic [1:0] g_TLLogger_1_auto_in_a_bits_user_alias;
  logic [1:0] i_TLLogger_1_auto_in_a_bits_user_alias;
  logic [4:0] g_TLLogger_1_auto_in_a_bits_user_reqSource;
  logic [4:0] i_TLLogger_1_auto_in_a_bits_user_reqSource;
  logic g_TLLogger_1_auto_in_a_bits_user_needHint;
  logic i_TLLogger_1_auto_in_a_bits_user_needHint;
  logic [31:0] g_TLLogger_1_auto_in_a_bits_mask;
  logic [31:0] i_TLLogger_1_auto_in_a_bits_mask;
  logic [255:0] g_TLLogger_1_auto_in_a_bits_data;
  logic [255:0] i_TLLogger_1_auto_in_a_bits_data;
  logic g_TLLogger_1_auto_in_a_bits_corrupt;
  logic i_TLLogger_1_auto_in_a_bits_corrupt;
  logic g_TLLogger_1_auto_in_d_ready;
  logic i_TLLogger_1_auto_in_d_ready;
  logic g_TLLogger_1_auto_in_d_valid;
  logic i_TLLogger_1_auto_in_d_valid;
  logic [3:0] g_TLLogger_1_auto_in_d_bits_opcode;
  logic [3:0] i_TLLogger_1_auto_in_d_bits_opcode;
  logic [1:0] g_TLLogger_1_auto_in_d_bits_param;
  logic [1:0] i_TLLogger_1_auto_in_d_bits_param;
  logic [2:0] g_TLLogger_1_auto_in_d_bits_size;
  logic [2:0] i_TLLogger_1_auto_in_d_bits_size;
  logic [3:0] g_TLLogger_1_auto_in_d_bits_source;
  logic [3:0] i_TLLogger_1_auto_in_d_bits_source;
  logic [9:0] g_TLLogger_1_auto_in_d_bits_sink;
  logic [9:0] i_TLLogger_1_auto_in_d_bits_sink;
  logic g_TLLogger_1_auto_in_d_bits_denied;
  logic i_TLLogger_1_auto_in_d_bits_denied;
  logic [255:0] g_TLLogger_1_auto_in_d_bits_data;
  logic [255:0] i_TLLogger_1_auto_in_d_bits_data;
  logic g_TLLogger_1_auto_in_d_bits_corrupt;
  logic i_TLLogger_1_auto_in_d_bits_corrupt;
  logic g_TLLogger_1_auto_out_a_ready;
  logic i_TLLogger_1_auto_out_a_ready;
  logic g_TLLogger_1_auto_out_a_valid;
  logic i_TLLogger_1_auto_out_a_valid;
  logic [3:0] g_TLLogger_1_auto_out_a_bits_opcode;
  logic [3:0] i_TLLogger_1_auto_out_a_bits_opcode;
  logic [2:0] g_TLLogger_1_auto_out_a_bits_param;
  logic [2:0] i_TLLogger_1_auto_out_a_bits_param;
  logic [2:0] g_TLLogger_1_auto_out_a_bits_size;
  logic [2:0] i_TLLogger_1_auto_out_a_bits_size;
  logic [3:0] g_TLLogger_1_auto_out_a_bits_source;
  logic [3:0] i_TLLogger_1_auto_out_a_bits_source;
  logic [47:0] g_TLLogger_1_auto_out_a_bits_address;
  logic [47:0] i_TLLogger_1_auto_out_a_bits_address;
  logic [1:0] g_TLLogger_1_auto_out_a_bits_user_alias;
  logic [1:0] i_TLLogger_1_auto_out_a_bits_user_alias;
  logic [4:0] g_TLLogger_1_auto_out_a_bits_user_reqSource;
  logic [4:0] i_TLLogger_1_auto_out_a_bits_user_reqSource;
  logic g_TLLogger_1_auto_out_a_bits_user_needHint;
  logic i_TLLogger_1_auto_out_a_bits_user_needHint;
  logic [31:0] g_TLLogger_1_auto_out_a_bits_mask;
  logic [31:0] i_TLLogger_1_auto_out_a_bits_mask;
  logic [255:0] g_TLLogger_1_auto_out_a_bits_data;
  logic [255:0] i_TLLogger_1_auto_out_a_bits_data;
  logic g_TLLogger_1_auto_out_a_bits_corrupt;
  logic i_TLLogger_1_auto_out_a_bits_corrupt;
  logic g_TLLogger_1_auto_out_d_ready;
  logic i_TLLogger_1_auto_out_d_ready;
  logic g_TLLogger_1_auto_out_d_valid;
  logic i_TLLogger_1_auto_out_d_valid;
  logic [3:0] g_TLLogger_1_auto_out_d_bits_opcode;
  logic [3:0] i_TLLogger_1_auto_out_d_bits_opcode;
  logic [1:0] g_TLLogger_1_auto_out_d_bits_param;
  logic [1:0] i_TLLogger_1_auto_out_d_bits_param;
  logic [2:0] g_TLLogger_1_auto_out_d_bits_size;
  logic [2:0] i_TLLogger_1_auto_out_d_bits_size;
  logic [3:0] g_TLLogger_1_auto_out_d_bits_source;
  logic [3:0] i_TLLogger_1_auto_out_d_bits_source;
  logic [9:0] g_TLLogger_1_auto_out_d_bits_sink;
  logic [9:0] i_TLLogger_1_auto_out_d_bits_sink;
  logic g_TLLogger_1_auto_out_d_bits_denied;
  logic i_TLLogger_1_auto_out_d_bits_denied;
  logic [255:0] g_TLLogger_1_auto_out_d_bits_data;
  logic [255:0] i_TLLogger_1_auto_out_d_bits_data;
  logic g_TLLogger_1_auto_out_d_bits_corrupt;
  logic i_TLLogger_1_auto_out_d_bits_corrupt;

  TLLogger_1 g_TLLogger_1 (
    .auto_in_a_ready(g_TLLogger_1_auto_in_a_ready),
    .auto_in_a_valid(g_TLLogger_1_auto_in_a_valid),
    .auto_in_a_bits_opcode(g_TLLogger_1_auto_in_a_bits_opcode),
    .auto_in_a_bits_param(g_TLLogger_1_auto_in_a_bits_param),
    .auto_in_a_bits_size(g_TLLogger_1_auto_in_a_bits_size),
    .auto_in_a_bits_source(g_TLLogger_1_auto_in_a_bits_source),
    .auto_in_a_bits_address(g_TLLogger_1_auto_in_a_bits_address),
    .auto_in_a_bits_user_alias(g_TLLogger_1_auto_in_a_bits_user_alias),
    .auto_in_a_bits_user_reqSource(g_TLLogger_1_auto_in_a_bits_user_reqSource),
    .auto_in_a_bits_user_needHint(g_TLLogger_1_auto_in_a_bits_user_needHint),
    .auto_in_a_bits_mask(g_TLLogger_1_auto_in_a_bits_mask),
    .auto_in_a_bits_data(g_TLLogger_1_auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(g_TLLogger_1_auto_in_a_bits_corrupt),
    .auto_in_d_ready(g_TLLogger_1_auto_in_d_ready),
    .auto_in_d_valid(g_TLLogger_1_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_TLLogger_1_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(g_TLLogger_1_auto_in_d_bits_param),
    .auto_in_d_bits_size(g_TLLogger_1_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_TLLogger_1_auto_in_d_bits_source),
    .auto_in_d_bits_sink(g_TLLogger_1_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(g_TLLogger_1_auto_in_d_bits_denied),
    .auto_in_d_bits_data(g_TLLogger_1_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(g_TLLogger_1_auto_in_d_bits_corrupt),
    .auto_out_a_ready(g_TLLogger_1_auto_out_a_ready),
    .auto_out_a_valid(g_TLLogger_1_auto_out_a_valid),
    .auto_out_a_bits_opcode(g_TLLogger_1_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(g_TLLogger_1_auto_out_a_bits_param),
    .auto_out_a_bits_size(g_TLLogger_1_auto_out_a_bits_size),
    .auto_out_a_bits_source(g_TLLogger_1_auto_out_a_bits_source),
    .auto_out_a_bits_address(g_TLLogger_1_auto_out_a_bits_address),
    .auto_out_a_bits_user_alias(g_TLLogger_1_auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_reqSource(g_TLLogger_1_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint(g_TLLogger_1_auto_out_a_bits_user_needHint),
    .auto_out_a_bits_mask(g_TLLogger_1_auto_out_a_bits_mask),
    .auto_out_a_bits_data(g_TLLogger_1_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(g_TLLogger_1_auto_out_a_bits_corrupt),
    .auto_out_d_ready(g_TLLogger_1_auto_out_d_ready),
    .auto_out_d_valid(g_TLLogger_1_auto_out_d_valid),
    .auto_out_d_bits_opcode(g_TLLogger_1_auto_out_d_bits_opcode),
    .auto_out_d_bits_param(g_TLLogger_1_auto_out_d_bits_param),
    .auto_out_d_bits_size(g_TLLogger_1_auto_out_d_bits_size),
    .auto_out_d_bits_source(g_TLLogger_1_auto_out_d_bits_source),
    .auto_out_d_bits_sink(g_TLLogger_1_auto_out_d_bits_sink),
    .auto_out_d_bits_denied(g_TLLogger_1_auto_out_d_bits_denied),
    .auto_out_d_bits_data(g_TLLogger_1_auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(g_TLLogger_1_auto_out_d_bits_corrupt)
  );

  TLLogger_1_xs i_TLLogger_1 (
    .auto_in_a_ready(i_TLLogger_1_auto_in_a_ready),
    .auto_in_a_valid(i_TLLogger_1_auto_in_a_valid),
    .auto_in_a_bits_opcode(i_TLLogger_1_auto_in_a_bits_opcode),
    .auto_in_a_bits_param(i_TLLogger_1_auto_in_a_bits_param),
    .auto_in_a_bits_size(i_TLLogger_1_auto_in_a_bits_size),
    .auto_in_a_bits_source(i_TLLogger_1_auto_in_a_bits_source),
    .auto_in_a_bits_address(i_TLLogger_1_auto_in_a_bits_address),
    .auto_in_a_bits_user_alias(i_TLLogger_1_auto_in_a_bits_user_alias),
    .auto_in_a_bits_user_reqSource(i_TLLogger_1_auto_in_a_bits_user_reqSource),
    .auto_in_a_bits_user_needHint(i_TLLogger_1_auto_in_a_bits_user_needHint),
    .auto_in_a_bits_mask(i_TLLogger_1_auto_in_a_bits_mask),
    .auto_in_a_bits_data(i_TLLogger_1_auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(i_TLLogger_1_auto_in_a_bits_corrupt),
    .auto_in_d_ready(i_TLLogger_1_auto_in_d_ready),
    .auto_in_d_valid(i_TLLogger_1_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_TLLogger_1_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(i_TLLogger_1_auto_in_d_bits_param),
    .auto_in_d_bits_size(i_TLLogger_1_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_TLLogger_1_auto_in_d_bits_source),
    .auto_in_d_bits_sink(i_TLLogger_1_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(i_TLLogger_1_auto_in_d_bits_denied),
    .auto_in_d_bits_data(i_TLLogger_1_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(i_TLLogger_1_auto_in_d_bits_corrupt),
    .auto_out_a_ready(i_TLLogger_1_auto_out_a_ready),
    .auto_out_a_valid(i_TLLogger_1_auto_out_a_valid),
    .auto_out_a_bits_opcode(i_TLLogger_1_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(i_TLLogger_1_auto_out_a_bits_param),
    .auto_out_a_bits_size(i_TLLogger_1_auto_out_a_bits_size),
    .auto_out_a_bits_source(i_TLLogger_1_auto_out_a_bits_source),
    .auto_out_a_bits_address(i_TLLogger_1_auto_out_a_bits_address),
    .auto_out_a_bits_user_alias(i_TLLogger_1_auto_out_a_bits_user_alias),
    .auto_out_a_bits_user_reqSource(i_TLLogger_1_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_user_needHint(i_TLLogger_1_auto_out_a_bits_user_needHint),
    .auto_out_a_bits_mask(i_TLLogger_1_auto_out_a_bits_mask),
    .auto_out_a_bits_data(i_TLLogger_1_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(i_TLLogger_1_auto_out_a_bits_corrupt),
    .auto_out_d_ready(i_TLLogger_1_auto_out_d_ready),
    .auto_out_d_valid(i_TLLogger_1_auto_out_d_valid),
    .auto_out_d_bits_opcode(i_TLLogger_1_auto_out_d_bits_opcode),
    .auto_out_d_bits_param(i_TLLogger_1_auto_out_d_bits_param),
    .auto_out_d_bits_size(i_TLLogger_1_auto_out_d_bits_size),
    .auto_out_d_bits_source(i_TLLogger_1_auto_out_d_bits_source),
    .auto_out_d_bits_sink(i_TLLogger_1_auto_out_d_bits_sink),
    .auto_out_d_bits_denied(i_TLLogger_1_auto_out_d_bits_denied),
    .auto_out_d_bits_data(i_TLLogger_1_auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(i_TLLogger_1_auto_out_d_bits_corrupt)
  );

  // TLLogger_2
  logic g_TLLogger_2_auto_in_a_ready;
  logic i_TLLogger_2_auto_in_a_ready;
  logic g_TLLogger_2_auto_in_a_valid;
  logic i_TLLogger_2_auto_in_a_valid;
  logic [3:0] g_TLLogger_2_auto_in_a_bits_opcode;
  logic [3:0] i_TLLogger_2_auto_in_a_bits_opcode;
  logic [2:0] g_TLLogger_2_auto_in_a_bits_param;
  logic [2:0] i_TLLogger_2_auto_in_a_bits_param;
  logic [2:0] g_TLLogger_2_auto_in_a_bits_size;
  logic [2:0] i_TLLogger_2_auto_in_a_bits_size;
  logic [3:0] g_TLLogger_2_auto_in_a_bits_source;
  logic [3:0] i_TLLogger_2_auto_in_a_bits_source;
  logic [47:0] g_TLLogger_2_auto_in_a_bits_address;
  logic [47:0] i_TLLogger_2_auto_in_a_bits_address;
  logic [4:0] g_TLLogger_2_auto_in_a_bits_user_reqSource;
  logic [4:0] i_TLLogger_2_auto_in_a_bits_user_reqSource;
  logic [31:0] g_TLLogger_2_auto_in_a_bits_mask;
  logic [31:0] i_TLLogger_2_auto_in_a_bits_mask;
  logic [255:0] g_TLLogger_2_auto_in_a_bits_data;
  logic [255:0] i_TLLogger_2_auto_in_a_bits_data;
  logic g_TLLogger_2_auto_in_a_bits_corrupt;
  logic i_TLLogger_2_auto_in_a_bits_corrupt;
  logic g_TLLogger_2_auto_in_d_ready;
  logic i_TLLogger_2_auto_in_d_ready;
  logic g_TLLogger_2_auto_in_d_valid;
  logic i_TLLogger_2_auto_in_d_valid;
  logic [3:0] g_TLLogger_2_auto_in_d_bits_opcode;
  logic [3:0] i_TLLogger_2_auto_in_d_bits_opcode;
  logic [1:0] g_TLLogger_2_auto_in_d_bits_param;
  logic [1:0] i_TLLogger_2_auto_in_d_bits_param;
  logic [2:0] g_TLLogger_2_auto_in_d_bits_size;
  logic [2:0] i_TLLogger_2_auto_in_d_bits_size;
  logic [3:0] g_TLLogger_2_auto_in_d_bits_source;
  logic [3:0] i_TLLogger_2_auto_in_d_bits_source;
  logic [9:0] g_TLLogger_2_auto_in_d_bits_sink;
  logic [9:0] i_TLLogger_2_auto_in_d_bits_sink;
  logic g_TLLogger_2_auto_in_d_bits_denied;
  logic i_TLLogger_2_auto_in_d_bits_denied;
  logic [255:0] g_TLLogger_2_auto_in_d_bits_data;
  logic [255:0] i_TLLogger_2_auto_in_d_bits_data;
  logic g_TLLogger_2_auto_in_d_bits_corrupt;
  logic i_TLLogger_2_auto_in_d_bits_corrupt;
  logic g_TLLogger_2_auto_out_a_ready;
  logic i_TLLogger_2_auto_out_a_ready;
  logic g_TLLogger_2_auto_out_a_valid;
  logic i_TLLogger_2_auto_out_a_valid;
  logic [3:0] g_TLLogger_2_auto_out_a_bits_opcode;
  logic [3:0] i_TLLogger_2_auto_out_a_bits_opcode;
  logic [2:0] g_TLLogger_2_auto_out_a_bits_param;
  logic [2:0] i_TLLogger_2_auto_out_a_bits_param;
  logic [2:0] g_TLLogger_2_auto_out_a_bits_size;
  logic [2:0] i_TLLogger_2_auto_out_a_bits_size;
  logic [3:0] g_TLLogger_2_auto_out_a_bits_source;
  logic [3:0] i_TLLogger_2_auto_out_a_bits_source;
  logic [47:0] g_TLLogger_2_auto_out_a_bits_address;
  logic [47:0] i_TLLogger_2_auto_out_a_bits_address;
  logic [4:0] g_TLLogger_2_auto_out_a_bits_user_reqSource;
  logic [4:0] i_TLLogger_2_auto_out_a_bits_user_reqSource;
  logic [31:0] g_TLLogger_2_auto_out_a_bits_mask;
  logic [31:0] i_TLLogger_2_auto_out_a_bits_mask;
  logic [255:0] g_TLLogger_2_auto_out_a_bits_data;
  logic [255:0] i_TLLogger_2_auto_out_a_bits_data;
  logic g_TLLogger_2_auto_out_a_bits_corrupt;
  logic i_TLLogger_2_auto_out_a_bits_corrupt;
  logic g_TLLogger_2_auto_out_d_ready;
  logic i_TLLogger_2_auto_out_d_ready;
  logic g_TLLogger_2_auto_out_d_valid;
  logic i_TLLogger_2_auto_out_d_valid;
  logic [3:0] g_TLLogger_2_auto_out_d_bits_opcode;
  logic [3:0] i_TLLogger_2_auto_out_d_bits_opcode;
  logic [1:0] g_TLLogger_2_auto_out_d_bits_param;
  logic [1:0] i_TLLogger_2_auto_out_d_bits_param;
  logic [2:0] g_TLLogger_2_auto_out_d_bits_size;
  logic [2:0] i_TLLogger_2_auto_out_d_bits_size;
  logic [3:0] g_TLLogger_2_auto_out_d_bits_source;
  logic [3:0] i_TLLogger_2_auto_out_d_bits_source;
  logic [9:0] g_TLLogger_2_auto_out_d_bits_sink;
  logic [9:0] i_TLLogger_2_auto_out_d_bits_sink;
  logic g_TLLogger_2_auto_out_d_bits_denied;
  logic i_TLLogger_2_auto_out_d_bits_denied;
  logic [255:0] g_TLLogger_2_auto_out_d_bits_data;
  logic [255:0] i_TLLogger_2_auto_out_d_bits_data;
  logic g_TLLogger_2_auto_out_d_bits_corrupt;
  logic i_TLLogger_2_auto_out_d_bits_corrupt;

  TLLogger_2 g_TLLogger_2 (
    .auto_in_a_ready(g_TLLogger_2_auto_in_a_ready),
    .auto_in_a_valid(g_TLLogger_2_auto_in_a_valid),
    .auto_in_a_bits_opcode(g_TLLogger_2_auto_in_a_bits_opcode),
    .auto_in_a_bits_param(g_TLLogger_2_auto_in_a_bits_param),
    .auto_in_a_bits_size(g_TLLogger_2_auto_in_a_bits_size),
    .auto_in_a_bits_source(g_TLLogger_2_auto_in_a_bits_source),
    .auto_in_a_bits_address(g_TLLogger_2_auto_in_a_bits_address),
    .auto_in_a_bits_user_reqSource(g_TLLogger_2_auto_in_a_bits_user_reqSource),
    .auto_in_a_bits_mask(g_TLLogger_2_auto_in_a_bits_mask),
    .auto_in_a_bits_data(g_TLLogger_2_auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(g_TLLogger_2_auto_in_a_bits_corrupt),
    .auto_in_d_ready(g_TLLogger_2_auto_in_d_ready),
    .auto_in_d_valid(g_TLLogger_2_auto_in_d_valid),
    .auto_in_d_bits_opcode(g_TLLogger_2_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(g_TLLogger_2_auto_in_d_bits_param),
    .auto_in_d_bits_size(g_TLLogger_2_auto_in_d_bits_size),
    .auto_in_d_bits_source(g_TLLogger_2_auto_in_d_bits_source),
    .auto_in_d_bits_sink(g_TLLogger_2_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(g_TLLogger_2_auto_in_d_bits_denied),
    .auto_in_d_bits_data(g_TLLogger_2_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(g_TLLogger_2_auto_in_d_bits_corrupt),
    .auto_out_a_ready(g_TLLogger_2_auto_out_a_ready),
    .auto_out_a_valid(g_TLLogger_2_auto_out_a_valid),
    .auto_out_a_bits_opcode(g_TLLogger_2_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(g_TLLogger_2_auto_out_a_bits_param),
    .auto_out_a_bits_size(g_TLLogger_2_auto_out_a_bits_size),
    .auto_out_a_bits_source(g_TLLogger_2_auto_out_a_bits_source),
    .auto_out_a_bits_address(g_TLLogger_2_auto_out_a_bits_address),
    .auto_out_a_bits_user_reqSource(g_TLLogger_2_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_mask(g_TLLogger_2_auto_out_a_bits_mask),
    .auto_out_a_bits_data(g_TLLogger_2_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(g_TLLogger_2_auto_out_a_bits_corrupt),
    .auto_out_d_ready(g_TLLogger_2_auto_out_d_ready),
    .auto_out_d_valid(g_TLLogger_2_auto_out_d_valid),
    .auto_out_d_bits_opcode(g_TLLogger_2_auto_out_d_bits_opcode),
    .auto_out_d_bits_param(g_TLLogger_2_auto_out_d_bits_param),
    .auto_out_d_bits_size(g_TLLogger_2_auto_out_d_bits_size),
    .auto_out_d_bits_source(g_TLLogger_2_auto_out_d_bits_source),
    .auto_out_d_bits_sink(g_TLLogger_2_auto_out_d_bits_sink),
    .auto_out_d_bits_denied(g_TLLogger_2_auto_out_d_bits_denied),
    .auto_out_d_bits_data(g_TLLogger_2_auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(g_TLLogger_2_auto_out_d_bits_corrupt)
  );

  TLLogger_2_xs i_TLLogger_2 (
    .auto_in_a_ready(i_TLLogger_2_auto_in_a_ready),
    .auto_in_a_valid(i_TLLogger_2_auto_in_a_valid),
    .auto_in_a_bits_opcode(i_TLLogger_2_auto_in_a_bits_opcode),
    .auto_in_a_bits_param(i_TLLogger_2_auto_in_a_bits_param),
    .auto_in_a_bits_size(i_TLLogger_2_auto_in_a_bits_size),
    .auto_in_a_bits_source(i_TLLogger_2_auto_in_a_bits_source),
    .auto_in_a_bits_address(i_TLLogger_2_auto_in_a_bits_address),
    .auto_in_a_bits_user_reqSource(i_TLLogger_2_auto_in_a_bits_user_reqSource),
    .auto_in_a_bits_mask(i_TLLogger_2_auto_in_a_bits_mask),
    .auto_in_a_bits_data(i_TLLogger_2_auto_in_a_bits_data),
    .auto_in_a_bits_corrupt(i_TLLogger_2_auto_in_a_bits_corrupt),
    .auto_in_d_ready(i_TLLogger_2_auto_in_d_ready),
    .auto_in_d_valid(i_TLLogger_2_auto_in_d_valid),
    .auto_in_d_bits_opcode(i_TLLogger_2_auto_in_d_bits_opcode),
    .auto_in_d_bits_param(i_TLLogger_2_auto_in_d_bits_param),
    .auto_in_d_bits_size(i_TLLogger_2_auto_in_d_bits_size),
    .auto_in_d_bits_source(i_TLLogger_2_auto_in_d_bits_source),
    .auto_in_d_bits_sink(i_TLLogger_2_auto_in_d_bits_sink),
    .auto_in_d_bits_denied(i_TLLogger_2_auto_in_d_bits_denied),
    .auto_in_d_bits_data(i_TLLogger_2_auto_in_d_bits_data),
    .auto_in_d_bits_corrupt(i_TLLogger_2_auto_in_d_bits_corrupt),
    .auto_out_a_ready(i_TLLogger_2_auto_out_a_ready),
    .auto_out_a_valid(i_TLLogger_2_auto_out_a_valid),
    .auto_out_a_bits_opcode(i_TLLogger_2_auto_out_a_bits_opcode),
    .auto_out_a_bits_param(i_TLLogger_2_auto_out_a_bits_param),
    .auto_out_a_bits_size(i_TLLogger_2_auto_out_a_bits_size),
    .auto_out_a_bits_source(i_TLLogger_2_auto_out_a_bits_source),
    .auto_out_a_bits_address(i_TLLogger_2_auto_out_a_bits_address),
    .auto_out_a_bits_user_reqSource(i_TLLogger_2_auto_out_a_bits_user_reqSource),
    .auto_out_a_bits_mask(i_TLLogger_2_auto_out_a_bits_mask),
    .auto_out_a_bits_data(i_TLLogger_2_auto_out_a_bits_data),
    .auto_out_a_bits_corrupt(i_TLLogger_2_auto_out_a_bits_corrupt),
    .auto_out_d_ready(i_TLLogger_2_auto_out_d_ready),
    .auto_out_d_valid(i_TLLogger_2_auto_out_d_valid),
    .auto_out_d_bits_opcode(i_TLLogger_2_auto_out_d_bits_opcode),
    .auto_out_d_bits_param(i_TLLogger_2_auto_out_d_bits_param),
    .auto_out_d_bits_size(i_TLLogger_2_auto_out_d_bits_size),
    .auto_out_d_bits_source(i_TLLogger_2_auto_out_d_bits_source),
    .auto_out_d_bits_sink(i_TLLogger_2_auto_out_d_bits_sink),
    .auto_out_d_bits_denied(i_TLLogger_2_auto_out_d_bits_denied),
    .auto_out_d_bits_data(i_TLLogger_2_auto_out_d_bits_data),
    .auto_out_d_bits_corrupt(i_TLLogger_2_auto_out_d_bits_corrupt)
  );

  task automatic check_outputs;
    begin
      if (!1'b0 && !$isunknown(g_Queue1_CHIDAT_io_enq_ready) && !$isunknown(i_Queue1_CHIDAT_io_enq_ready)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_enq_ready !== i_Queue1_CHIDAT_io_enq_ready) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_enq_ready g=%h i=%h", g_Queue1_CHIDAT_io_enq_ready, i_Queue1_CHIDAT_io_enq_ready);
        end
      end
      if (!1'b0 && !$isunknown(g_Queue1_CHIDAT_io_deq_valid) && !$isunknown(i_Queue1_CHIDAT_io_deq_valid)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_valid !== i_Queue1_CHIDAT_io_deq_valid) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_valid g=%h i=%h", g_Queue1_CHIDAT_io_deq_valid, i_Queue1_CHIDAT_io_deq_valid);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_qos) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_qos)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_qos !== i_Queue1_CHIDAT_io_deq_bits_qos) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_qos g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_qos, i_Queue1_CHIDAT_io_deq_bits_qos);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_tgtID) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_tgtID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_tgtID !== i_Queue1_CHIDAT_io_deq_bits_tgtID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_tgtID g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_tgtID, i_Queue1_CHIDAT_io_deq_bits_tgtID);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_srcID) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_srcID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_srcID !== i_Queue1_CHIDAT_io_deq_bits_srcID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_srcID g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_srcID, i_Queue1_CHIDAT_io_deq_bits_srcID);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_txnID) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_txnID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_txnID !== i_Queue1_CHIDAT_io_deq_bits_txnID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_txnID g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_txnID, i_Queue1_CHIDAT_io_deq_bits_txnID);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_homeNID) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_homeNID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_homeNID !== i_Queue1_CHIDAT_io_deq_bits_homeNID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_homeNID g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_homeNID, i_Queue1_CHIDAT_io_deq_bits_homeNID);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_opcode) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_opcode)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_opcode !== i_Queue1_CHIDAT_io_deq_bits_opcode) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_opcode g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_opcode, i_Queue1_CHIDAT_io_deq_bits_opcode);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_respErr) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_respErr)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_respErr !== i_Queue1_CHIDAT_io_deq_bits_respErr) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_respErr g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_respErr, i_Queue1_CHIDAT_io_deq_bits_respErr);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_resp) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_resp)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_resp !== i_Queue1_CHIDAT_io_deq_bits_resp) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_resp g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_resp, i_Queue1_CHIDAT_io_deq_bits_resp);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_dataSource) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_dataSource)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_dataSource !== i_Queue1_CHIDAT_io_deq_bits_dataSource) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_dataSource g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_dataSource, i_Queue1_CHIDAT_io_deq_bits_dataSource);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_cBusy) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_cBusy)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_cBusy !== i_Queue1_CHIDAT_io_deq_bits_cBusy) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_cBusy g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_cBusy, i_Queue1_CHIDAT_io_deq_bits_cBusy);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_dbID) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_dbID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_dbID !== i_Queue1_CHIDAT_io_deq_bits_dbID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_dbID g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_dbID, i_Queue1_CHIDAT_io_deq_bits_dbID);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_ccID) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_ccID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_ccID !== i_Queue1_CHIDAT_io_deq_bits_ccID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_ccID g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_ccID, i_Queue1_CHIDAT_io_deq_bits_ccID);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_dataID) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_dataID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_dataID !== i_Queue1_CHIDAT_io_deq_bits_dataID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_dataID g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_dataID, i_Queue1_CHIDAT_io_deq_bits_dataID);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_tagOp) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_tagOp)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_tagOp !== i_Queue1_CHIDAT_io_deq_bits_tagOp) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_tagOp g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_tagOp, i_Queue1_CHIDAT_io_deq_bits_tagOp);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_tag) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_tag)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_tag !== i_Queue1_CHIDAT_io_deq_bits_tag) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_tag g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_tag, i_Queue1_CHIDAT_io_deq_bits_tag);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_tu) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_tu)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_tu !== i_Queue1_CHIDAT_io_deq_bits_tu) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_tu g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_tu, i_Queue1_CHIDAT_io_deq_bits_tu);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_traceTag) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_traceTag)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_traceTag !== i_Queue1_CHIDAT_io_deq_bits_traceTag) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_traceTag g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_traceTag, i_Queue1_CHIDAT_io_deq_bits_traceTag);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_rsvdc) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_rsvdc)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_rsvdc !== i_Queue1_CHIDAT_io_deq_bits_rsvdc) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_rsvdc g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_rsvdc, i_Queue1_CHIDAT_io_deq_bits_rsvdc);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_be) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_be)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_be !== i_Queue1_CHIDAT_io_deq_bits_be) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_be g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_be, i_Queue1_CHIDAT_io_deq_bits_be);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_data) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_data)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_data !== i_Queue1_CHIDAT_io_deq_bits_data) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_data g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_data, i_Queue1_CHIDAT_io_deq_bits_data);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_dataCheck) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_dataCheck)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_dataCheck !== i_Queue1_CHIDAT_io_deq_bits_dataCheck) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_dataCheck g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_dataCheck, i_Queue1_CHIDAT_io_deq_bits_dataCheck);
        end
      end
      if (!(g_Queue1_CHIDAT_io_deq_valid === 1'b0 || i_Queue1_CHIDAT_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIDAT_io_deq_bits_poison) && !$isunknown(i_Queue1_CHIDAT_io_deq_bits_poison)) begin
        checks = checks + 1;
        if (g_Queue1_CHIDAT_io_deq_bits_poison !== i_Queue1_CHIDAT_io_deq_bits_poison) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIDAT.io_deq_bits_poison g=%h i=%h", g_Queue1_CHIDAT_io_deq_bits_poison, i_Queue1_CHIDAT_io_deq_bits_poison);
        end
      end
      if (!1'b0 && !$isunknown(g_Queue1_CHIRSP_io_enq_ready) && !$isunknown(i_Queue1_CHIRSP_io_enq_ready)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_enq_ready !== i_Queue1_CHIRSP_io_enq_ready) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_enq_ready g=%h i=%h", g_Queue1_CHIRSP_io_enq_ready, i_Queue1_CHIRSP_io_enq_ready);
        end
      end
      if (!1'b0 && !$isunknown(g_Queue1_CHIRSP_io_deq_valid) && !$isunknown(i_Queue1_CHIRSP_io_deq_valid)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_valid !== i_Queue1_CHIRSP_io_deq_valid) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_valid g=%h i=%h", g_Queue1_CHIRSP_io_deq_valid, i_Queue1_CHIRSP_io_deq_valid);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_qos) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_qos)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_qos !== i_Queue1_CHIRSP_io_deq_bits_qos) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_qos g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_qos, i_Queue1_CHIRSP_io_deq_bits_qos);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_tgtID) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_tgtID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_tgtID !== i_Queue1_CHIRSP_io_deq_bits_tgtID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_tgtID g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_tgtID, i_Queue1_CHIRSP_io_deq_bits_tgtID);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_srcID) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_srcID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_srcID !== i_Queue1_CHIRSP_io_deq_bits_srcID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_srcID g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_srcID, i_Queue1_CHIRSP_io_deq_bits_srcID);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_txnID) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_txnID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_txnID !== i_Queue1_CHIRSP_io_deq_bits_txnID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_txnID g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_txnID, i_Queue1_CHIRSP_io_deq_bits_txnID);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_opcode) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_opcode)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_opcode !== i_Queue1_CHIRSP_io_deq_bits_opcode) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_opcode g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_opcode, i_Queue1_CHIRSP_io_deq_bits_opcode);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_respErr) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_respErr)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_respErr !== i_Queue1_CHIRSP_io_deq_bits_respErr) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_respErr g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_respErr, i_Queue1_CHIRSP_io_deq_bits_respErr);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_resp) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_resp)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_resp !== i_Queue1_CHIRSP_io_deq_bits_resp) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_resp g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_resp, i_Queue1_CHIRSP_io_deq_bits_resp);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_fwdState) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_fwdState)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_fwdState !== i_Queue1_CHIRSP_io_deq_bits_fwdState) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_fwdState g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_fwdState, i_Queue1_CHIRSP_io_deq_bits_fwdState);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_cBusy) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_cBusy)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_cBusy !== i_Queue1_CHIRSP_io_deq_bits_cBusy) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_cBusy g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_cBusy, i_Queue1_CHIRSP_io_deq_bits_cBusy);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_dbID) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_dbID)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_dbID !== i_Queue1_CHIRSP_io_deq_bits_dbID) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_dbID g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_dbID, i_Queue1_CHIRSP_io_deq_bits_dbID);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_pCrdType) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_pCrdType)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_pCrdType !== i_Queue1_CHIRSP_io_deq_bits_pCrdType) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_pCrdType g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_pCrdType, i_Queue1_CHIRSP_io_deq_bits_pCrdType);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_tagOp) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_tagOp)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_tagOp !== i_Queue1_CHIRSP_io_deq_bits_tagOp) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_tagOp g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_tagOp, i_Queue1_CHIRSP_io_deq_bits_tagOp);
        end
      end
      if (!(g_Queue1_CHIRSP_io_deq_valid === 1'b0 || i_Queue1_CHIRSP_io_deq_valid === 1'b0) && !$isunknown(g_Queue1_CHIRSP_io_deq_bits_traceTag) && !$isunknown(i_Queue1_CHIRSP_io_deq_bits_traceTag)) begin
        checks = checks + 1;
        if (g_Queue1_CHIRSP_io_deq_bits_traceTag !== i_Queue1_CHIRSP_io_deq_bits_traceTag) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH Queue1_CHIRSP.io_deq_bits_traceTag g=%h i=%h", g_Queue1_CHIRSP_io_deq_bits_traceTag, i_Queue1_CHIRSP_io_deq_bits_traceTag);
        end
      end
      if (!1'b0 && !$isunknown(g_SpillRegister_7_io_out_valid) && !$isunknown(i_SpillRegister_7_io_out_valid)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_valid !== i_SpillRegister_7_io_out_valid) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_valid g=%h i=%h", g_SpillRegister_7_io_out_valid, i_SpillRegister_7_io_out_valid);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_0) && !$isunknown(i_SpillRegister_7_io_out_bits_0)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_0 !== i_SpillRegister_7_io_out_bits_0) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_0 g=%h i=%h", g_SpillRegister_7_io_out_bits_0, i_SpillRegister_7_io_out_bits_0);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_1) && !$isunknown(i_SpillRegister_7_io_out_bits_1)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_1 !== i_SpillRegister_7_io_out_bits_1) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_1 g=%h i=%h", g_SpillRegister_7_io_out_bits_1, i_SpillRegister_7_io_out_bits_1);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_2) && !$isunknown(i_SpillRegister_7_io_out_bits_2)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_2 !== i_SpillRegister_7_io_out_bits_2) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_2 g=%h i=%h", g_SpillRegister_7_io_out_bits_2, i_SpillRegister_7_io_out_bits_2);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_3) && !$isunknown(i_SpillRegister_7_io_out_bits_3)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_3 !== i_SpillRegister_7_io_out_bits_3) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_3 g=%h i=%h", g_SpillRegister_7_io_out_bits_3, i_SpillRegister_7_io_out_bits_3);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_4) && !$isunknown(i_SpillRegister_7_io_out_bits_4)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_4 !== i_SpillRegister_7_io_out_bits_4) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_4 g=%h i=%h", g_SpillRegister_7_io_out_bits_4, i_SpillRegister_7_io_out_bits_4);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_5) && !$isunknown(i_SpillRegister_7_io_out_bits_5)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_5 !== i_SpillRegister_7_io_out_bits_5) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_5 g=%h i=%h", g_SpillRegister_7_io_out_bits_5, i_SpillRegister_7_io_out_bits_5);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_6) && !$isunknown(i_SpillRegister_7_io_out_bits_6)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_6 !== i_SpillRegister_7_io_out_bits_6) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_6 g=%h i=%h", g_SpillRegister_7_io_out_bits_6, i_SpillRegister_7_io_out_bits_6);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_7) && !$isunknown(i_SpillRegister_7_io_out_bits_7)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_7 !== i_SpillRegister_7_io_out_bits_7) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_7 g=%h i=%h", g_SpillRegister_7_io_out_bits_7, i_SpillRegister_7_io_out_bits_7);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_8) && !$isunknown(i_SpillRegister_7_io_out_bits_8)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_8 !== i_SpillRegister_7_io_out_bits_8) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_8 g=%h i=%h", g_SpillRegister_7_io_out_bits_8, i_SpillRegister_7_io_out_bits_8);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_9) && !$isunknown(i_SpillRegister_7_io_out_bits_9)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_9 !== i_SpillRegister_7_io_out_bits_9) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_9 g=%h i=%h", g_SpillRegister_7_io_out_bits_9, i_SpillRegister_7_io_out_bits_9);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_10) && !$isunknown(i_SpillRegister_7_io_out_bits_10)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_10 !== i_SpillRegister_7_io_out_bits_10) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_10 g=%h i=%h", g_SpillRegister_7_io_out_bits_10, i_SpillRegister_7_io_out_bits_10);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_11) && !$isunknown(i_SpillRegister_7_io_out_bits_11)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_11 !== i_SpillRegister_7_io_out_bits_11) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_11 g=%h i=%h", g_SpillRegister_7_io_out_bits_11, i_SpillRegister_7_io_out_bits_11);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_12) && !$isunknown(i_SpillRegister_7_io_out_bits_12)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_12 !== i_SpillRegister_7_io_out_bits_12) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_12 g=%h i=%h", g_SpillRegister_7_io_out_bits_12, i_SpillRegister_7_io_out_bits_12);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_13) && !$isunknown(i_SpillRegister_7_io_out_bits_13)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_13 !== i_SpillRegister_7_io_out_bits_13) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_13 g=%h i=%h", g_SpillRegister_7_io_out_bits_13, i_SpillRegister_7_io_out_bits_13);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_14) && !$isunknown(i_SpillRegister_7_io_out_bits_14)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_14 !== i_SpillRegister_7_io_out_bits_14) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_14 g=%h i=%h", g_SpillRegister_7_io_out_bits_14, i_SpillRegister_7_io_out_bits_14);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_15) && !$isunknown(i_SpillRegister_7_io_out_bits_15)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_15 !== i_SpillRegister_7_io_out_bits_15) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_15 g=%h i=%h", g_SpillRegister_7_io_out_bits_15, i_SpillRegister_7_io_out_bits_15);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_16) && !$isunknown(i_SpillRegister_7_io_out_bits_16)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_16 !== i_SpillRegister_7_io_out_bits_16) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_16 g=%h i=%h", g_SpillRegister_7_io_out_bits_16, i_SpillRegister_7_io_out_bits_16);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_17) && !$isunknown(i_SpillRegister_7_io_out_bits_17)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_17 !== i_SpillRegister_7_io_out_bits_17) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_17 g=%h i=%h", g_SpillRegister_7_io_out_bits_17, i_SpillRegister_7_io_out_bits_17);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_18) && !$isunknown(i_SpillRegister_7_io_out_bits_18)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_18 !== i_SpillRegister_7_io_out_bits_18) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_18 g=%h i=%h", g_SpillRegister_7_io_out_bits_18, i_SpillRegister_7_io_out_bits_18);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_19) && !$isunknown(i_SpillRegister_7_io_out_bits_19)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_19 !== i_SpillRegister_7_io_out_bits_19) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_19 g=%h i=%h", g_SpillRegister_7_io_out_bits_19, i_SpillRegister_7_io_out_bits_19);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_20) && !$isunknown(i_SpillRegister_7_io_out_bits_20)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_20 !== i_SpillRegister_7_io_out_bits_20) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_20 g=%h i=%h", g_SpillRegister_7_io_out_bits_20, i_SpillRegister_7_io_out_bits_20);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_21) && !$isunknown(i_SpillRegister_7_io_out_bits_21)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_21 !== i_SpillRegister_7_io_out_bits_21) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_21 g=%h i=%h", g_SpillRegister_7_io_out_bits_21, i_SpillRegister_7_io_out_bits_21);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_22) && !$isunknown(i_SpillRegister_7_io_out_bits_22)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_22 !== i_SpillRegister_7_io_out_bits_22) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_22 g=%h i=%h", g_SpillRegister_7_io_out_bits_22, i_SpillRegister_7_io_out_bits_22);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_23) && !$isunknown(i_SpillRegister_7_io_out_bits_23)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_23 !== i_SpillRegister_7_io_out_bits_23) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_23 g=%h i=%h", g_SpillRegister_7_io_out_bits_23, i_SpillRegister_7_io_out_bits_23);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_24) && !$isunknown(i_SpillRegister_7_io_out_bits_24)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_24 !== i_SpillRegister_7_io_out_bits_24) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_24 g=%h i=%h", g_SpillRegister_7_io_out_bits_24, i_SpillRegister_7_io_out_bits_24);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_25) && !$isunknown(i_SpillRegister_7_io_out_bits_25)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_25 !== i_SpillRegister_7_io_out_bits_25) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_25 g=%h i=%h", g_SpillRegister_7_io_out_bits_25, i_SpillRegister_7_io_out_bits_25);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_26) && !$isunknown(i_SpillRegister_7_io_out_bits_26)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_26 !== i_SpillRegister_7_io_out_bits_26) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_26 g=%h i=%h", g_SpillRegister_7_io_out_bits_26, i_SpillRegister_7_io_out_bits_26);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_27) && !$isunknown(i_SpillRegister_7_io_out_bits_27)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_27 !== i_SpillRegister_7_io_out_bits_27) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_27 g=%h i=%h", g_SpillRegister_7_io_out_bits_27, i_SpillRegister_7_io_out_bits_27);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_28) && !$isunknown(i_SpillRegister_7_io_out_bits_28)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_28 !== i_SpillRegister_7_io_out_bits_28) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_28 g=%h i=%h", g_SpillRegister_7_io_out_bits_28, i_SpillRegister_7_io_out_bits_28);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_29) && !$isunknown(i_SpillRegister_7_io_out_bits_29)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_29 !== i_SpillRegister_7_io_out_bits_29) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_29 g=%h i=%h", g_SpillRegister_7_io_out_bits_29, i_SpillRegister_7_io_out_bits_29);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_30) && !$isunknown(i_SpillRegister_7_io_out_bits_30)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_30 !== i_SpillRegister_7_io_out_bits_30) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_30 g=%h i=%h", g_SpillRegister_7_io_out_bits_30, i_SpillRegister_7_io_out_bits_30);
        end
      end
      if (!(g_SpillRegister_7_io_out_valid === 1'b0 || i_SpillRegister_7_io_out_valid === 1'b0) && !$isunknown(g_SpillRegister_7_io_out_bits_31) && !$isunknown(i_SpillRegister_7_io_out_bits_31)) begin
        checks = checks + 1;
        if (g_SpillRegister_7_io_out_bits_31 !== i_SpillRegister_7_io_out_bits_31) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH SpillRegister_7.io_out_bits_31 g=%h i=%h", g_SpillRegister_7_io_out_bits_31, i_SpillRegister_7_io_out_bits_31);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_a_ready) && !$isunknown(i_TLLogger_1_auto_in_a_ready)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_a_ready !== i_TLLogger_1_auto_in_a_ready) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_a_ready g=%h i=%h", g_TLLogger_1_auto_in_a_ready, i_TLLogger_1_auto_in_a_ready);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_valid) && !$isunknown(i_TLLogger_1_auto_in_d_valid)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_valid !== i_TLLogger_1_auto_in_d_valid) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_valid g=%h i=%h", g_TLLogger_1_auto_in_d_valid, i_TLLogger_1_auto_in_d_valid);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_bits_opcode) && !$isunknown(i_TLLogger_1_auto_in_d_bits_opcode)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_bits_opcode !== i_TLLogger_1_auto_in_d_bits_opcode) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_bits_opcode g=%h i=%h", g_TLLogger_1_auto_in_d_bits_opcode, i_TLLogger_1_auto_in_d_bits_opcode);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_bits_param) && !$isunknown(i_TLLogger_1_auto_in_d_bits_param)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_bits_param !== i_TLLogger_1_auto_in_d_bits_param) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_bits_param g=%h i=%h", g_TLLogger_1_auto_in_d_bits_param, i_TLLogger_1_auto_in_d_bits_param);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_bits_size) && !$isunknown(i_TLLogger_1_auto_in_d_bits_size)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_bits_size !== i_TLLogger_1_auto_in_d_bits_size) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_bits_size g=%h i=%h", g_TLLogger_1_auto_in_d_bits_size, i_TLLogger_1_auto_in_d_bits_size);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_bits_source) && !$isunknown(i_TLLogger_1_auto_in_d_bits_source)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_bits_source !== i_TLLogger_1_auto_in_d_bits_source) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_bits_source g=%h i=%h", g_TLLogger_1_auto_in_d_bits_source, i_TLLogger_1_auto_in_d_bits_source);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_bits_sink) && !$isunknown(i_TLLogger_1_auto_in_d_bits_sink)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_bits_sink !== i_TLLogger_1_auto_in_d_bits_sink) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_bits_sink g=%h i=%h", g_TLLogger_1_auto_in_d_bits_sink, i_TLLogger_1_auto_in_d_bits_sink);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_bits_denied) && !$isunknown(i_TLLogger_1_auto_in_d_bits_denied)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_bits_denied !== i_TLLogger_1_auto_in_d_bits_denied) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_bits_denied g=%h i=%h", g_TLLogger_1_auto_in_d_bits_denied, i_TLLogger_1_auto_in_d_bits_denied);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_bits_data) && !$isunknown(i_TLLogger_1_auto_in_d_bits_data)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_bits_data !== i_TLLogger_1_auto_in_d_bits_data) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_bits_data g=%h i=%h", g_TLLogger_1_auto_in_d_bits_data, i_TLLogger_1_auto_in_d_bits_data);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_in_d_bits_corrupt) && !$isunknown(i_TLLogger_1_auto_in_d_bits_corrupt)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_in_d_bits_corrupt !== i_TLLogger_1_auto_in_d_bits_corrupt) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_in_d_bits_corrupt g=%h i=%h", g_TLLogger_1_auto_in_d_bits_corrupt, i_TLLogger_1_auto_in_d_bits_corrupt);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_valid) && !$isunknown(i_TLLogger_1_auto_out_a_valid)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_valid !== i_TLLogger_1_auto_out_a_valid) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_valid g=%h i=%h", g_TLLogger_1_auto_out_a_valid, i_TLLogger_1_auto_out_a_valid);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_opcode) && !$isunknown(i_TLLogger_1_auto_out_a_bits_opcode)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_opcode !== i_TLLogger_1_auto_out_a_bits_opcode) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_opcode g=%h i=%h", g_TLLogger_1_auto_out_a_bits_opcode, i_TLLogger_1_auto_out_a_bits_opcode);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_param) && !$isunknown(i_TLLogger_1_auto_out_a_bits_param)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_param !== i_TLLogger_1_auto_out_a_bits_param) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_param g=%h i=%h", g_TLLogger_1_auto_out_a_bits_param, i_TLLogger_1_auto_out_a_bits_param);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_size) && !$isunknown(i_TLLogger_1_auto_out_a_bits_size)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_size !== i_TLLogger_1_auto_out_a_bits_size) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_size g=%h i=%h", g_TLLogger_1_auto_out_a_bits_size, i_TLLogger_1_auto_out_a_bits_size);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_source) && !$isunknown(i_TLLogger_1_auto_out_a_bits_source)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_source !== i_TLLogger_1_auto_out_a_bits_source) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_source g=%h i=%h", g_TLLogger_1_auto_out_a_bits_source, i_TLLogger_1_auto_out_a_bits_source);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_address) && !$isunknown(i_TLLogger_1_auto_out_a_bits_address)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_address !== i_TLLogger_1_auto_out_a_bits_address) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_address g=%h i=%h", g_TLLogger_1_auto_out_a_bits_address, i_TLLogger_1_auto_out_a_bits_address);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_user_alias) && !$isunknown(i_TLLogger_1_auto_out_a_bits_user_alias)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_user_alias !== i_TLLogger_1_auto_out_a_bits_user_alias) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_user_alias g=%h i=%h", g_TLLogger_1_auto_out_a_bits_user_alias, i_TLLogger_1_auto_out_a_bits_user_alias);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_user_reqSource) && !$isunknown(i_TLLogger_1_auto_out_a_bits_user_reqSource)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_user_reqSource !== i_TLLogger_1_auto_out_a_bits_user_reqSource) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_user_reqSource g=%h i=%h", g_TLLogger_1_auto_out_a_bits_user_reqSource, i_TLLogger_1_auto_out_a_bits_user_reqSource);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_user_needHint) && !$isunknown(i_TLLogger_1_auto_out_a_bits_user_needHint)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_user_needHint !== i_TLLogger_1_auto_out_a_bits_user_needHint) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_user_needHint g=%h i=%h", g_TLLogger_1_auto_out_a_bits_user_needHint, i_TLLogger_1_auto_out_a_bits_user_needHint);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_mask) && !$isunknown(i_TLLogger_1_auto_out_a_bits_mask)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_mask !== i_TLLogger_1_auto_out_a_bits_mask) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_mask g=%h i=%h", g_TLLogger_1_auto_out_a_bits_mask, i_TLLogger_1_auto_out_a_bits_mask);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_data) && !$isunknown(i_TLLogger_1_auto_out_a_bits_data)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_data !== i_TLLogger_1_auto_out_a_bits_data) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_data g=%h i=%h", g_TLLogger_1_auto_out_a_bits_data, i_TLLogger_1_auto_out_a_bits_data);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_a_bits_corrupt) && !$isunknown(i_TLLogger_1_auto_out_a_bits_corrupt)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_a_bits_corrupt !== i_TLLogger_1_auto_out_a_bits_corrupt) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_a_bits_corrupt g=%h i=%h", g_TLLogger_1_auto_out_a_bits_corrupt, i_TLLogger_1_auto_out_a_bits_corrupt);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_1_auto_out_d_ready) && !$isunknown(i_TLLogger_1_auto_out_d_ready)) begin
        checks = checks + 1;
        if (g_TLLogger_1_auto_out_d_ready !== i_TLLogger_1_auto_out_d_ready) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_1.auto_out_d_ready g=%h i=%h", g_TLLogger_1_auto_out_d_ready, i_TLLogger_1_auto_out_d_ready);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_a_ready) && !$isunknown(i_TLLogger_2_auto_in_a_ready)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_a_ready !== i_TLLogger_2_auto_in_a_ready) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_a_ready g=%h i=%h", g_TLLogger_2_auto_in_a_ready, i_TLLogger_2_auto_in_a_ready);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_valid) && !$isunknown(i_TLLogger_2_auto_in_d_valid)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_valid !== i_TLLogger_2_auto_in_d_valid) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_valid g=%h i=%h", g_TLLogger_2_auto_in_d_valid, i_TLLogger_2_auto_in_d_valid);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_bits_opcode) && !$isunknown(i_TLLogger_2_auto_in_d_bits_opcode)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_bits_opcode !== i_TLLogger_2_auto_in_d_bits_opcode) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_bits_opcode g=%h i=%h", g_TLLogger_2_auto_in_d_bits_opcode, i_TLLogger_2_auto_in_d_bits_opcode);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_bits_param) && !$isunknown(i_TLLogger_2_auto_in_d_bits_param)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_bits_param !== i_TLLogger_2_auto_in_d_bits_param) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_bits_param g=%h i=%h", g_TLLogger_2_auto_in_d_bits_param, i_TLLogger_2_auto_in_d_bits_param);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_bits_size) && !$isunknown(i_TLLogger_2_auto_in_d_bits_size)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_bits_size !== i_TLLogger_2_auto_in_d_bits_size) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_bits_size g=%h i=%h", g_TLLogger_2_auto_in_d_bits_size, i_TLLogger_2_auto_in_d_bits_size);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_bits_source) && !$isunknown(i_TLLogger_2_auto_in_d_bits_source)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_bits_source !== i_TLLogger_2_auto_in_d_bits_source) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_bits_source g=%h i=%h", g_TLLogger_2_auto_in_d_bits_source, i_TLLogger_2_auto_in_d_bits_source);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_bits_sink) && !$isunknown(i_TLLogger_2_auto_in_d_bits_sink)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_bits_sink !== i_TLLogger_2_auto_in_d_bits_sink) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_bits_sink g=%h i=%h", g_TLLogger_2_auto_in_d_bits_sink, i_TLLogger_2_auto_in_d_bits_sink);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_bits_denied) && !$isunknown(i_TLLogger_2_auto_in_d_bits_denied)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_bits_denied !== i_TLLogger_2_auto_in_d_bits_denied) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_bits_denied g=%h i=%h", g_TLLogger_2_auto_in_d_bits_denied, i_TLLogger_2_auto_in_d_bits_denied);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_bits_data) && !$isunknown(i_TLLogger_2_auto_in_d_bits_data)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_bits_data !== i_TLLogger_2_auto_in_d_bits_data) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_bits_data g=%h i=%h", g_TLLogger_2_auto_in_d_bits_data, i_TLLogger_2_auto_in_d_bits_data);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_in_d_bits_corrupt) && !$isunknown(i_TLLogger_2_auto_in_d_bits_corrupt)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_in_d_bits_corrupt !== i_TLLogger_2_auto_in_d_bits_corrupt) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_in_d_bits_corrupt g=%h i=%h", g_TLLogger_2_auto_in_d_bits_corrupt, i_TLLogger_2_auto_in_d_bits_corrupt);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_valid) && !$isunknown(i_TLLogger_2_auto_out_a_valid)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_valid !== i_TLLogger_2_auto_out_a_valid) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_valid g=%h i=%h", g_TLLogger_2_auto_out_a_valid, i_TLLogger_2_auto_out_a_valid);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_opcode) && !$isunknown(i_TLLogger_2_auto_out_a_bits_opcode)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_opcode !== i_TLLogger_2_auto_out_a_bits_opcode) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_opcode g=%h i=%h", g_TLLogger_2_auto_out_a_bits_opcode, i_TLLogger_2_auto_out_a_bits_opcode);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_param) && !$isunknown(i_TLLogger_2_auto_out_a_bits_param)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_param !== i_TLLogger_2_auto_out_a_bits_param) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_param g=%h i=%h", g_TLLogger_2_auto_out_a_bits_param, i_TLLogger_2_auto_out_a_bits_param);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_size) && !$isunknown(i_TLLogger_2_auto_out_a_bits_size)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_size !== i_TLLogger_2_auto_out_a_bits_size) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_size g=%h i=%h", g_TLLogger_2_auto_out_a_bits_size, i_TLLogger_2_auto_out_a_bits_size);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_source) && !$isunknown(i_TLLogger_2_auto_out_a_bits_source)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_source !== i_TLLogger_2_auto_out_a_bits_source) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_source g=%h i=%h", g_TLLogger_2_auto_out_a_bits_source, i_TLLogger_2_auto_out_a_bits_source);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_address) && !$isunknown(i_TLLogger_2_auto_out_a_bits_address)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_address !== i_TLLogger_2_auto_out_a_bits_address) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_address g=%h i=%h", g_TLLogger_2_auto_out_a_bits_address, i_TLLogger_2_auto_out_a_bits_address);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_user_reqSource) && !$isunknown(i_TLLogger_2_auto_out_a_bits_user_reqSource)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_user_reqSource !== i_TLLogger_2_auto_out_a_bits_user_reqSource) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_user_reqSource g=%h i=%h", g_TLLogger_2_auto_out_a_bits_user_reqSource, i_TLLogger_2_auto_out_a_bits_user_reqSource);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_mask) && !$isunknown(i_TLLogger_2_auto_out_a_bits_mask)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_mask !== i_TLLogger_2_auto_out_a_bits_mask) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_mask g=%h i=%h", g_TLLogger_2_auto_out_a_bits_mask, i_TLLogger_2_auto_out_a_bits_mask);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_data) && !$isunknown(i_TLLogger_2_auto_out_a_bits_data)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_data !== i_TLLogger_2_auto_out_a_bits_data) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_data g=%h i=%h", g_TLLogger_2_auto_out_a_bits_data, i_TLLogger_2_auto_out_a_bits_data);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_a_bits_corrupt) && !$isunknown(i_TLLogger_2_auto_out_a_bits_corrupt)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_a_bits_corrupt !== i_TLLogger_2_auto_out_a_bits_corrupt) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_a_bits_corrupt g=%h i=%h", g_TLLogger_2_auto_out_a_bits_corrupt, i_TLLogger_2_auto_out_a_bits_corrupt);
        end
      end
      if (!1'b0 && !$isunknown(g_TLLogger_2_auto_out_d_ready) && !$isunknown(i_TLLogger_2_auto_out_d_ready)) begin
        checks = checks + 1;
        if (g_TLLogger_2_auto_out_d_ready !== i_TLLogger_2_auto_out_d_ready) begin
          errors = errors + 1;
          if (errors <= 20) $display("MISMATCH TLLogger_2.auto_out_d_ready g=%h i=%h", g_TLLogger_2_auto_out_d_ready, i_TLLogger_2_auto_out_d_ready);
        end
      end
    end
  endtask

  initial begin
    // Delay the reset edge until VCS has applied +vcs+initreg+random.
    #1 reset = 1'b1;
    repeat (3) @(negedge clock);
    reset = 1'b0;
    repeat (200000) begin
      @(negedge clock);
      cycles = cycles + 1;
      g_Queue1_CHIDAT_io_enq_valid = $urandom;
      i_Queue1_CHIDAT_io_enq_valid = g_Queue1_CHIDAT_io_enq_valid;
      g_Queue1_CHIDAT_io_enq_bits_qos = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_qos = g_Queue1_CHIDAT_io_enq_bits_qos;
      g_Queue1_CHIDAT_io_enq_bits_tgtID = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_tgtID = g_Queue1_CHIDAT_io_enq_bits_tgtID;
      g_Queue1_CHIDAT_io_enq_bits_srcID = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_srcID = g_Queue1_CHIDAT_io_enq_bits_srcID;
      g_Queue1_CHIDAT_io_enq_bits_txnID = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_txnID = g_Queue1_CHIDAT_io_enq_bits_txnID;
      g_Queue1_CHIDAT_io_enq_bits_homeNID = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_homeNID = g_Queue1_CHIDAT_io_enq_bits_homeNID;
      g_Queue1_CHIDAT_io_enq_bits_opcode = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_opcode = g_Queue1_CHIDAT_io_enq_bits_opcode;
      g_Queue1_CHIDAT_io_enq_bits_respErr = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_respErr = g_Queue1_CHIDAT_io_enq_bits_respErr;
      g_Queue1_CHIDAT_io_enq_bits_resp = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_resp = g_Queue1_CHIDAT_io_enq_bits_resp;
      g_Queue1_CHIDAT_io_enq_bits_dataSource = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_dataSource = g_Queue1_CHIDAT_io_enq_bits_dataSource;
      g_Queue1_CHIDAT_io_enq_bits_cBusy = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_cBusy = g_Queue1_CHIDAT_io_enq_bits_cBusy;
      g_Queue1_CHIDAT_io_enq_bits_dbID = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_dbID = g_Queue1_CHIDAT_io_enq_bits_dbID;
      g_Queue1_CHIDAT_io_enq_bits_ccID = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_ccID = g_Queue1_CHIDAT_io_enq_bits_ccID;
      g_Queue1_CHIDAT_io_enq_bits_dataID = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_dataID = g_Queue1_CHIDAT_io_enq_bits_dataID;
      g_Queue1_CHIDAT_io_enq_bits_tagOp = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_tagOp = g_Queue1_CHIDAT_io_enq_bits_tagOp;
      g_Queue1_CHIDAT_io_enq_bits_tag = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_tag = g_Queue1_CHIDAT_io_enq_bits_tag;
      g_Queue1_CHIDAT_io_enq_bits_tu = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_tu = g_Queue1_CHIDAT_io_enq_bits_tu;
      g_Queue1_CHIDAT_io_enq_bits_traceTag = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_traceTag = g_Queue1_CHIDAT_io_enq_bits_traceTag;
      g_Queue1_CHIDAT_io_enq_bits_rsvdc = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_rsvdc = g_Queue1_CHIDAT_io_enq_bits_rsvdc;
      g_Queue1_CHIDAT_io_enq_bits_be = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_be = g_Queue1_CHIDAT_io_enq_bits_be;
      g_Queue1_CHIDAT_io_enq_bits_data = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_data = g_Queue1_CHIDAT_io_enq_bits_data;
      g_Queue1_CHIDAT_io_enq_bits_dataCheck = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_dataCheck = g_Queue1_CHIDAT_io_enq_bits_dataCheck;
      g_Queue1_CHIDAT_io_enq_bits_poison = $urandom;
      i_Queue1_CHIDAT_io_enq_bits_poison = g_Queue1_CHIDAT_io_enq_bits_poison;
      g_Queue1_CHIDAT_io_deq_ready = $urandom;
      i_Queue1_CHIDAT_io_deq_ready = g_Queue1_CHIDAT_io_deq_ready;
      g_Queue1_CHIRSP_io_enq_valid = $urandom;
      i_Queue1_CHIRSP_io_enq_valid = g_Queue1_CHIRSP_io_enq_valid;
      g_Queue1_CHIRSP_io_enq_bits_qos = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_qos = g_Queue1_CHIRSP_io_enq_bits_qos;
      g_Queue1_CHIRSP_io_enq_bits_tgtID = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_tgtID = g_Queue1_CHIRSP_io_enq_bits_tgtID;
      g_Queue1_CHIRSP_io_enq_bits_srcID = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_srcID = g_Queue1_CHIRSP_io_enq_bits_srcID;
      g_Queue1_CHIRSP_io_enq_bits_txnID = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_txnID = g_Queue1_CHIRSP_io_enq_bits_txnID;
      g_Queue1_CHIRSP_io_enq_bits_opcode = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_opcode = g_Queue1_CHIRSP_io_enq_bits_opcode;
      g_Queue1_CHIRSP_io_enq_bits_respErr = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_respErr = g_Queue1_CHIRSP_io_enq_bits_respErr;
      g_Queue1_CHIRSP_io_enq_bits_resp = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_resp = g_Queue1_CHIRSP_io_enq_bits_resp;
      g_Queue1_CHIRSP_io_enq_bits_fwdState = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_fwdState = g_Queue1_CHIRSP_io_enq_bits_fwdState;
      g_Queue1_CHIRSP_io_enq_bits_cBusy = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_cBusy = g_Queue1_CHIRSP_io_enq_bits_cBusy;
      g_Queue1_CHIRSP_io_enq_bits_dbID = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_dbID = g_Queue1_CHIRSP_io_enq_bits_dbID;
      g_Queue1_CHIRSP_io_enq_bits_pCrdType = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_pCrdType = g_Queue1_CHIRSP_io_enq_bits_pCrdType;
      g_Queue1_CHIRSP_io_enq_bits_tagOp = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_tagOp = g_Queue1_CHIRSP_io_enq_bits_tagOp;
      g_Queue1_CHIRSP_io_enq_bits_traceTag = $urandom;
      i_Queue1_CHIRSP_io_enq_bits_traceTag = g_Queue1_CHIRSP_io_enq_bits_traceTag;
      g_Queue1_CHIRSP_io_deq_ready = $urandom;
      i_Queue1_CHIRSP_io_deq_ready = g_Queue1_CHIRSP_io_deq_ready;
      g_SpillRegister_7_io_in_valid = $urandom;
      i_SpillRegister_7_io_in_valid = g_SpillRegister_7_io_in_valid;
      g_SpillRegister_7_io_in_bits_0 = $urandom;
      i_SpillRegister_7_io_in_bits_0 = g_SpillRegister_7_io_in_bits_0;
      g_SpillRegister_7_io_in_bits_1 = $urandom;
      i_SpillRegister_7_io_in_bits_1 = g_SpillRegister_7_io_in_bits_1;
      g_SpillRegister_7_io_in_bits_2 = $urandom;
      i_SpillRegister_7_io_in_bits_2 = g_SpillRegister_7_io_in_bits_2;
      g_SpillRegister_7_io_in_bits_3 = $urandom;
      i_SpillRegister_7_io_in_bits_3 = g_SpillRegister_7_io_in_bits_3;
      g_SpillRegister_7_io_in_bits_4 = $urandom;
      i_SpillRegister_7_io_in_bits_4 = g_SpillRegister_7_io_in_bits_4;
      g_SpillRegister_7_io_in_bits_5 = $urandom;
      i_SpillRegister_7_io_in_bits_5 = g_SpillRegister_7_io_in_bits_5;
      g_SpillRegister_7_io_in_bits_6 = $urandom;
      i_SpillRegister_7_io_in_bits_6 = g_SpillRegister_7_io_in_bits_6;
      g_SpillRegister_7_io_in_bits_7 = $urandom;
      i_SpillRegister_7_io_in_bits_7 = g_SpillRegister_7_io_in_bits_7;
      g_SpillRegister_7_io_in_bits_8 = $urandom;
      i_SpillRegister_7_io_in_bits_8 = g_SpillRegister_7_io_in_bits_8;
      g_SpillRegister_7_io_in_bits_9 = $urandom;
      i_SpillRegister_7_io_in_bits_9 = g_SpillRegister_7_io_in_bits_9;
      g_SpillRegister_7_io_in_bits_10 = $urandom;
      i_SpillRegister_7_io_in_bits_10 = g_SpillRegister_7_io_in_bits_10;
      g_SpillRegister_7_io_in_bits_11 = $urandom;
      i_SpillRegister_7_io_in_bits_11 = g_SpillRegister_7_io_in_bits_11;
      g_SpillRegister_7_io_in_bits_12 = $urandom;
      i_SpillRegister_7_io_in_bits_12 = g_SpillRegister_7_io_in_bits_12;
      g_SpillRegister_7_io_in_bits_13 = $urandom;
      i_SpillRegister_7_io_in_bits_13 = g_SpillRegister_7_io_in_bits_13;
      g_SpillRegister_7_io_in_bits_14 = $urandom;
      i_SpillRegister_7_io_in_bits_14 = g_SpillRegister_7_io_in_bits_14;
      g_SpillRegister_7_io_in_bits_15 = $urandom;
      i_SpillRegister_7_io_in_bits_15 = g_SpillRegister_7_io_in_bits_15;
      g_SpillRegister_7_io_in_bits_16 = $urandom;
      i_SpillRegister_7_io_in_bits_16 = g_SpillRegister_7_io_in_bits_16;
      g_SpillRegister_7_io_in_bits_17 = $urandom;
      i_SpillRegister_7_io_in_bits_17 = g_SpillRegister_7_io_in_bits_17;
      g_SpillRegister_7_io_in_bits_18 = $urandom;
      i_SpillRegister_7_io_in_bits_18 = g_SpillRegister_7_io_in_bits_18;
      g_SpillRegister_7_io_in_bits_19 = $urandom;
      i_SpillRegister_7_io_in_bits_19 = g_SpillRegister_7_io_in_bits_19;
      g_SpillRegister_7_io_in_bits_20 = $urandom;
      i_SpillRegister_7_io_in_bits_20 = g_SpillRegister_7_io_in_bits_20;
      g_SpillRegister_7_io_in_bits_21 = $urandom;
      i_SpillRegister_7_io_in_bits_21 = g_SpillRegister_7_io_in_bits_21;
      g_SpillRegister_7_io_in_bits_22 = $urandom;
      i_SpillRegister_7_io_in_bits_22 = g_SpillRegister_7_io_in_bits_22;
      g_SpillRegister_7_io_in_bits_23 = $urandom;
      i_SpillRegister_7_io_in_bits_23 = g_SpillRegister_7_io_in_bits_23;
      g_SpillRegister_7_io_in_bits_24 = $urandom;
      i_SpillRegister_7_io_in_bits_24 = g_SpillRegister_7_io_in_bits_24;
      g_SpillRegister_7_io_in_bits_25 = $urandom;
      i_SpillRegister_7_io_in_bits_25 = g_SpillRegister_7_io_in_bits_25;
      g_SpillRegister_7_io_in_bits_26 = $urandom;
      i_SpillRegister_7_io_in_bits_26 = g_SpillRegister_7_io_in_bits_26;
      g_SpillRegister_7_io_in_bits_27 = $urandom;
      i_SpillRegister_7_io_in_bits_27 = g_SpillRegister_7_io_in_bits_27;
      g_SpillRegister_7_io_in_bits_28 = $urandom;
      i_SpillRegister_7_io_in_bits_28 = g_SpillRegister_7_io_in_bits_28;
      g_SpillRegister_7_io_in_bits_29 = $urandom;
      i_SpillRegister_7_io_in_bits_29 = g_SpillRegister_7_io_in_bits_29;
      g_SpillRegister_7_io_in_bits_30 = $urandom;
      i_SpillRegister_7_io_in_bits_30 = g_SpillRegister_7_io_in_bits_30;
      g_SpillRegister_7_io_in_bits_31 = $urandom;
      i_SpillRegister_7_io_in_bits_31 = g_SpillRegister_7_io_in_bits_31;
      g_SpillRegister_7_io_out_ready = $urandom;
      i_SpillRegister_7_io_out_ready = g_SpillRegister_7_io_out_ready;
      g_TLLogger_1_auto_in_a_valid = $urandom;
      i_TLLogger_1_auto_in_a_valid = g_TLLogger_1_auto_in_a_valid;
      g_TLLogger_1_auto_in_a_bits_opcode = $urandom;
      i_TLLogger_1_auto_in_a_bits_opcode = g_TLLogger_1_auto_in_a_bits_opcode;
      g_TLLogger_1_auto_in_a_bits_param = $urandom;
      i_TLLogger_1_auto_in_a_bits_param = g_TLLogger_1_auto_in_a_bits_param;
      g_TLLogger_1_auto_in_a_bits_size = $urandom;
      i_TLLogger_1_auto_in_a_bits_size = g_TLLogger_1_auto_in_a_bits_size;
      g_TLLogger_1_auto_in_a_bits_source = $urandom;
      i_TLLogger_1_auto_in_a_bits_source = g_TLLogger_1_auto_in_a_bits_source;
      g_TLLogger_1_auto_in_a_bits_address = $urandom;
      i_TLLogger_1_auto_in_a_bits_address = g_TLLogger_1_auto_in_a_bits_address;
      g_TLLogger_1_auto_in_a_bits_user_alias = $urandom;
      i_TLLogger_1_auto_in_a_bits_user_alias = g_TLLogger_1_auto_in_a_bits_user_alias;
      g_TLLogger_1_auto_in_a_bits_user_reqSource = $urandom;
      i_TLLogger_1_auto_in_a_bits_user_reqSource = g_TLLogger_1_auto_in_a_bits_user_reqSource;
      g_TLLogger_1_auto_in_a_bits_user_needHint = $urandom;
      i_TLLogger_1_auto_in_a_bits_user_needHint = g_TLLogger_1_auto_in_a_bits_user_needHint;
      g_TLLogger_1_auto_in_a_bits_mask = $urandom;
      i_TLLogger_1_auto_in_a_bits_mask = g_TLLogger_1_auto_in_a_bits_mask;
      g_TLLogger_1_auto_in_a_bits_data = $urandom;
      i_TLLogger_1_auto_in_a_bits_data = g_TLLogger_1_auto_in_a_bits_data;
      g_TLLogger_1_auto_in_a_bits_corrupt = $urandom;
      i_TLLogger_1_auto_in_a_bits_corrupt = g_TLLogger_1_auto_in_a_bits_corrupt;
      g_TLLogger_1_auto_in_d_ready = $urandom;
      i_TLLogger_1_auto_in_d_ready = g_TLLogger_1_auto_in_d_ready;
      g_TLLogger_1_auto_out_a_ready = $urandom;
      i_TLLogger_1_auto_out_a_ready = g_TLLogger_1_auto_out_a_ready;
      g_TLLogger_1_auto_out_d_valid = $urandom;
      i_TLLogger_1_auto_out_d_valid = g_TLLogger_1_auto_out_d_valid;
      g_TLLogger_1_auto_out_d_bits_opcode = $urandom;
      i_TLLogger_1_auto_out_d_bits_opcode = g_TLLogger_1_auto_out_d_bits_opcode;
      g_TLLogger_1_auto_out_d_bits_param = $urandom;
      i_TLLogger_1_auto_out_d_bits_param = g_TLLogger_1_auto_out_d_bits_param;
      g_TLLogger_1_auto_out_d_bits_size = $urandom;
      i_TLLogger_1_auto_out_d_bits_size = g_TLLogger_1_auto_out_d_bits_size;
      g_TLLogger_1_auto_out_d_bits_source = $urandom;
      i_TLLogger_1_auto_out_d_bits_source = g_TLLogger_1_auto_out_d_bits_source;
      g_TLLogger_1_auto_out_d_bits_sink = $urandom;
      i_TLLogger_1_auto_out_d_bits_sink = g_TLLogger_1_auto_out_d_bits_sink;
      g_TLLogger_1_auto_out_d_bits_denied = $urandom;
      i_TLLogger_1_auto_out_d_bits_denied = g_TLLogger_1_auto_out_d_bits_denied;
      g_TLLogger_1_auto_out_d_bits_data = $urandom;
      i_TLLogger_1_auto_out_d_bits_data = g_TLLogger_1_auto_out_d_bits_data;
      g_TLLogger_1_auto_out_d_bits_corrupt = $urandom;
      i_TLLogger_1_auto_out_d_bits_corrupt = g_TLLogger_1_auto_out_d_bits_corrupt;
      g_TLLogger_2_auto_in_a_valid = $urandom;
      i_TLLogger_2_auto_in_a_valid = g_TLLogger_2_auto_in_a_valid;
      g_TLLogger_2_auto_in_a_bits_opcode = $urandom;
      i_TLLogger_2_auto_in_a_bits_opcode = g_TLLogger_2_auto_in_a_bits_opcode;
      g_TLLogger_2_auto_in_a_bits_param = $urandom;
      i_TLLogger_2_auto_in_a_bits_param = g_TLLogger_2_auto_in_a_bits_param;
      g_TLLogger_2_auto_in_a_bits_size = $urandom;
      i_TLLogger_2_auto_in_a_bits_size = g_TLLogger_2_auto_in_a_bits_size;
      g_TLLogger_2_auto_in_a_bits_source = $urandom;
      i_TLLogger_2_auto_in_a_bits_source = g_TLLogger_2_auto_in_a_bits_source;
      g_TLLogger_2_auto_in_a_bits_address = $urandom;
      i_TLLogger_2_auto_in_a_bits_address = g_TLLogger_2_auto_in_a_bits_address;
      g_TLLogger_2_auto_in_a_bits_user_reqSource = $urandom;
      i_TLLogger_2_auto_in_a_bits_user_reqSource = g_TLLogger_2_auto_in_a_bits_user_reqSource;
      g_TLLogger_2_auto_in_a_bits_mask = $urandom;
      i_TLLogger_2_auto_in_a_bits_mask = g_TLLogger_2_auto_in_a_bits_mask;
      g_TLLogger_2_auto_in_a_bits_data = $urandom;
      i_TLLogger_2_auto_in_a_bits_data = g_TLLogger_2_auto_in_a_bits_data;
      g_TLLogger_2_auto_in_a_bits_corrupt = $urandom;
      i_TLLogger_2_auto_in_a_bits_corrupt = g_TLLogger_2_auto_in_a_bits_corrupt;
      g_TLLogger_2_auto_in_d_ready = $urandom;
      i_TLLogger_2_auto_in_d_ready = g_TLLogger_2_auto_in_d_ready;
      g_TLLogger_2_auto_out_a_ready = $urandom;
      i_TLLogger_2_auto_out_a_ready = g_TLLogger_2_auto_out_a_ready;
      g_TLLogger_2_auto_out_d_valid = $urandom;
      i_TLLogger_2_auto_out_d_valid = g_TLLogger_2_auto_out_d_valid;
      g_TLLogger_2_auto_out_d_bits_opcode = $urandom;
      i_TLLogger_2_auto_out_d_bits_opcode = g_TLLogger_2_auto_out_d_bits_opcode;
      g_TLLogger_2_auto_out_d_bits_param = $urandom;
      i_TLLogger_2_auto_out_d_bits_param = g_TLLogger_2_auto_out_d_bits_param;
      g_TLLogger_2_auto_out_d_bits_size = $urandom;
      i_TLLogger_2_auto_out_d_bits_size = g_TLLogger_2_auto_out_d_bits_size;
      g_TLLogger_2_auto_out_d_bits_source = $urandom;
      i_TLLogger_2_auto_out_d_bits_source = g_TLLogger_2_auto_out_d_bits_source;
      g_TLLogger_2_auto_out_d_bits_sink = $urandom;
      i_TLLogger_2_auto_out_d_bits_sink = g_TLLogger_2_auto_out_d_bits_sink;
      g_TLLogger_2_auto_out_d_bits_denied = $urandom;
      i_TLLogger_2_auto_out_d_bits_denied = g_TLLogger_2_auto_out_d_bits_denied;
      g_TLLogger_2_auto_out_d_bits_data = $urandom;
      i_TLLogger_2_auto_out_d_bits_data = g_TLLogger_2_auto_out_d_bits_data;
      g_TLLogger_2_auto_out_d_bits_corrupt = $urandom;
      i_TLLogger_2_auto_out_d_bits_corrupt = g_TLLogger_2_auto_out_d_bits_corrupt;
      @(posedge clock);
      #1 check_outputs();
    end
    $display("cycles=%0d checks=%0d errors=%0d", cycles, checks, errors);
    if (errors != 0 || checks == 0) $fatal(1, "differential test failed");
    $display("TEST PASSED");
    $finish;
  end
endmodule

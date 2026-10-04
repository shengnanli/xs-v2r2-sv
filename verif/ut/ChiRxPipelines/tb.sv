// tb —— ChiRxPipelines：TL2CHICoupledL2 的 rxdatPipe / rxrspPipe（Pipeline_12 / Pipeline_13）双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= Pipeline_12 =================
  int unsigned p12_mode = 0;
  logic p12_reset;
  wire  p12_g_io_in_ready, p12_i_io_in_ready;
  logic p12_s0_io_in_ready = '0, p12_s1_io_in_ready = '0;
  logic p12_io_in_valid;
  logic [3:0] p12_io_in_bits_qos;
  logic [10:0] p12_io_in_bits_tgtID;
  logic [10:0] p12_io_in_bits_srcID;
  logic [11:0] p12_io_in_bits_txnID;
  logic [10:0] p12_io_in_bits_homeNID;
  logic [3:0] p12_io_in_bits_opcode;
  logic [1:0] p12_io_in_bits_respErr;
  logic [2:0] p12_io_in_bits_resp;
  logic [3:0] p12_io_in_bits_dataSource;
  logic [2:0] p12_io_in_bits_cBusy;
  logic [11:0] p12_io_in_bits_dbID;
  logic [1:0] p12_io_in_bits_ccID;
  logic [1:0] p12_io_in_bits_dataID;
  logic [1:0] p12_io_in_bits_tagOp;
  logic [7:0] p12_io_in_bits_tag;
  logic [1:0] p12_io_in_bits_tu;
  logic p12_io_in_bits_traceTag;
  logic [3:0] p12_io_in_bits_rsvdc;
  logic [31:0] p12_io_in_bits_be;
  logic [255:0] p12_io_in_bits_data;
  logic [31:0] p12_io_in_bits_dataCheck;
  logic [3:0] p12_io_in_bits_poison;
  logic p12_io_out_ready;
  wire  p12_g_io_out_valid, p12_i_io_out_valid;
  logic p12_s0_io_out_valid = '0, p12_s1_io_out_valid = '0;
  wire  [3:0] p12_g_io_out_bits_qos, p12_i_io_out_bits_qos;
  logic [3:0] p12_s0_io_out_bits_qos = '0, p12_s1_io_out_bits_qos = '0;
  wire  [10:0] p12_g_io_out_bits_tgtID, p12_i_io_out_bits_tgtID;
  logic [10:0] p12_s0_io_out_bits_tgtID = '0, p12_s1_io_out_bits_tgtID = '0;
  wire  [10:0] p12_g_io_out_bits_srcID, p12_i_io_out_bits_srcID;
  logic [10:0] p12_s0_io_out_bits_srcID = '0, p12_s1_io_out_bits_srcID = '0;
  wire  [11:0] p12_g_io_out_bits_txnID, p12_i_io_out_bits_txnID;
  logic [11:0] p12_s0_io_out_bits_txnID = '0, p12_s1_io_out_bits_txnID = '0;
  wire  [10:0] p12_g_io_out_bits_homeNID, p12_i_io_out_bits_homeNID;
  logic [10:0] p12_s0_io_out_bits_homeNID = '0, p12_s1_io_out_bits_homeNID = '0;
  wire  [3:0] p12_g_io_out_bits_opcode, p12_i_io_out_bits_opcode;
  logic [3:0] p12_s0_io_out_bits_opcode = '0, p12_s1_io_out_bits_opcode = '0;
  wire  [1:0] p12_g_io_out_bits_respErr, p12_i_io_out_bits_respErr;
  logic [1:0] p12_s0_io_out_bits_respErr = '0, p12_s1_io_out_bits_respErr = '0;
  wire  [2:0] p12_g_io_out_bits_resp, p12_i_io_out_bits_resp;
  logic [2:0] p12_s0_io_out_bits_resp = '0, p12_s1_io_out_bits_resp = '0;
  wire  [3:0] p12_g_io_out_bits_dataSource, p12_i_io_out_bits_dataSource;
  logic [3:0] p12_s0_io_out_bits_dataSource = '0, p12_s1_io_out_bits_dataSource = '0;
  wire  [2:0] p12_g_io_out_bits_cBusy, p12_i_io_out_bits_cBusy;
  logic [2:0] p12_s0_io_out_bits_cBusy = '0, p12_s1_io_out_bits_cBusy = '0;
  wire  [11:0] p12_g_io_out_bits_dbID, p12_i_io_out_bits_dbID;
  logic [11:0] p12_s0_io_out_bits_dbID = '0, p12_s1_io_out_bits_dbID = '0;
  wire  [1:0] p12_g_io_out_bits_ccID, p12_i_io_out_bits_ccID;
  logic [1:0] p12_s0_io_out_bits_ccID = '0, p12_s1_io_out_bits_ccID = '0;
  wire  [1:0] p12_g_io_out_bits_dataID, p12_i_io_out_bits_dataID;
  logic [1:0] p12_s0_io_out_bits_dataID = '0, p12_s1_io_out_bits_dataID = '0;
  wire  [1:0] p12_g_io_out_bits_tagOp, p12_i_io_out_bits_tagOp;
  logic [1:0] p12_s0_io_out_bits_tagOp = '0, p12_s1_io_out_bits_tagOp = '0;
  wire  [7:0] p12_g_io_out_bits_tag, p12_i_io_out_bits_tag;
  logic [7:0] p12_s0_io_out_bits_tag = '0, p12_s1_io_out_bits_tag = '0;
  wire  [1:0] p12_g_io_out_bits_tu, p12_i_io_out_bits_tu;
  logic [1:0] p12_s0_io_out_bits_tu = '0, p12_s1_io_out_bits_tu = '0;
  wire  p12_g_io_out_bits_traceTag, p12_i_io_out_bits_traceTag;
  logic p12_s0_io_out_bits_traceTag = '0, p12_s1_io_out_bits_traceTag = '0;
  wire  [3:0] p12_g_io_out_bits_rsvdc, p12_i_io_out_bits_rsvdc;
  logic [3:0] p12_s0_io_out_bits_rsvdc = '0, p12_s1_io_out_bits_rsvdc = '0;
  wire  [31:0] p12_g_io_out_bits_be, p12_i_io_out_bits_be;
  logic [31:0] p12_s0_io_out_bits_be = '0, p12_s1_io_out_bits_be = '0;
  wire  [255:0] p12_g_io_out_bits_data, p12_i_io_out_bits_data;
  logic [255:0] p12_s0_io_out_bits_data = '0, p12_s1_io_out_bits_data = '0;
  wire  [31:0] p12_g_io_out_bits_dataCheck, p12_i_io_out_bits_dataCheck;
  logic [31:0] p12_s0_io_out_bits_dataCheck = '0, p12_s1_io_out_bits_dataCheck = '0;
  wire  [3:0] p12_g_io_out_bits_poison, p12_i_io_out_bits_poison;
  logic [3:0] p12_s0_io_out_bits_poison = '0, p12_s1_io_out_bits_poison = '0;
  int p12_cov_enq = 0;
  int p12_cov_deq = 0;
  int p12_cov_backpressure = 0;
  int p12_cov_enq_deq_same = 0;
  int p12_cov_full_refused = 0;
  logic [0:0] p12_armed = '0;
  int p12_armed_at = -1;
  Pipeline_12 p12_u_gold (
    .clock(clk),
    .reset(p12_reset),
    .io_in_ready(p12_g_io_in_ready),
    .io_in_valid(p12_io_in_valid),
    .io_in_bits_qos(p12_io_in_bits_qos),
    .io_in_bits_tgtID(p12_io_in_bits_tgtID),
    .io_in_bits_srcID(p12_io_in_bits_srcID),
    .io_in_bits_txnID(p12_io_in_bits_txnID),
    .io_in_bits_homeNID(p12_io_in_bits_homeNID),
    .io_in_bits_opcode(p12_io_in_bits_opcode),
    .io_in_bits_respErr(p12_io_in_bits_respErr),
    .io_in_bits_resp(p12_io_in_bits_resp),
    .io_in_bits_dataSource(p12_io_in_bits_dataSource),
    .io_in_bits_cBusy(p12_io_in_bits_cBusy),
    .io_in_bits_dbID(p12_io_in_bits_dbID),
    .io_in_bits_ccID(p12_io_in_bits_ccID),
    .io_in_bits_dataID(p12_io_in_bits_dataID),
    .io_in_bits_tagOp(p12_io_in_bits_tagOp),
    .io_in_bits_tag(p12_io_in_bits_tag),
    .io_in_bits_tu(p12_io_in_bits_tu),
    .io_in_bits_traceTag(p12_io_in_bits_traceTag),
    .io_in_bits_rsvdc(p12_io_in_bits_rsvdc),
    .io_in_bits_be(p12_io_in_bits_be),
    .io_in_bits_data(p12_io_in_bits_data),
    .io_in_bits_dataCheck(p12_io_in_bits_dataCheck),
    .io_in_bits_poison(p12_io_in_bits_poison),
    .io_out_ready(p12_io_out_ready),
    .io_out_valid(p12_g_io_out_valid),
    .io_out_bits_qos(p12_g_io_out_bits_qos),
    .io_out_bits_tgtID(p12_g_io_out_bits_tgtID),
    .io_out_bits_srcID(p12_g_io_out_bits_srcID),
    .io_out_bits_txnID(p12_g_io_out_bits_txnID),
    .io_out_bits_homeNID(p12_g_io_out_bits_homeNID),
    .io_out_bits_opcode(p12_g_io_out_bits_opcode),
    .io_out_bits_respErr(p12_g_io_out_bits_respErr),
    .io_out_bits_resp(p12_g_io_out_bits_resp),
    .io_out_bits_dataSource(p12_g_io_out_bits_dataSource),
    .io_out_bits_cBusy(p12_g_io_out_bits_cBusy),
    .io_out_bits_dbID(p12_g_io_out_bits_dbID),
    .io_out_bits_ccID(p12_g_io_out_bits_ccID),
    .io_out_bits_dataID(p12_g_io_out_bits_dataID),
    .io_out_bits_tagOp(p12_g_io_out_bits_tagOp),
    .io_out_bits_tag(p12_g_io_out_bits_tag),
    .io_out_bits_tu(p12_g_io_out_bits_tu),
    .io_out_bits_traceTag(p12_g_io_out_bits_traceTag),
    .io_out_bits_rsvdc(p12_g_io_out_bits_rsvdc),
    .io_out_bits_be(p12_g_io_out_bits_be),
    .io_out_bits_data(p12_g_io_out_bits_data),
    .io_out_bits_dataCheck(p12_g_io_out_bits_dataCheck),
    .io_out_bits_poison(p12_g_io_out_bits_poison)
  );
  Pipeline_12_xs p12_u_impl (
    .clock(clk),
    .reset(p12_reset),
    .io_in_ready(p12_i_io_in_ready),
    .io_in_valid(p12_io_in_valid),
    .io_in_bits_qos(p12_io_in_bits_qos),
    .io_in_bits_tgtID(p12_io_in_bits_tgtID),
    .io_in_bits_srcID(p12_io_in_bits_srcID),
    .io_in_bits_txnID(p12_io_in_bits_txnID),
    .io_in_bits_homeNID(p12_io_in_bits_homeNID),
    .io_in_bits_opcode(p12_io_in_bits_opcode),
    .io_in_bits_respErr(p12_io_in_bits_respErr),
    .io_in_bits_resp(p12_io_in_bits_resp),
    .io_in_bits_dataSource(p12_io_in_bits_dataSource),
    .io_in_bits_cBusy(p12_io_in_bits_cBusy),
    .io_in_bits_dbID(p12_io_in_bits_dbID),
    .io_in_bits_ccID(p12_io_in_bits_ccID),
    .io_in_bits_dataID(p12_io_in_bits_dataID),
    .io_in_bits_tagOp(p12_io_in_bits_tagOp),
    .io_in_bits_tag(p12_io_in_bits_tag),
    .io_in_bits_tu(p12_io_in_bits_tu),
    .io_in_bits_traceTag(p12_io_in_bits_traceTag),
    .io_in_bits_rsvdc(p12_io_in_bits_rsvdc),
    .io_in_bits_be(p12_io_in_bits_be),
    .io_in_bits_data(p12_io_in_bits_data),
    .io_in_bits_dataCheck(p12_io_in_bits_dataCheck),
    .io_in_bits_poison(p12_io_in_bits_poison),
    .io_out_ready(p12_io_out_ready),
    .io_out_valid(p12_i_io_out_valid),
    .io_out_bits_qos(p12_i_io_out_bits_qos),
    .io_out_bits_tgtID(p12_i_io_out_bits_tgtID),
    .io_out_bits_srcID(p12_i_io_out_bits_srcID),
    .io_out_bits_txnID(p12_i_io_out_bits_txnID),
    .io_out_bits_homeNID(p12_i_io_out_bits_homeNID),
    .io_out_bits_opcode(p12_i_io_out_bits_opcode),
    .io_out_bits_respErr(p12_i_io_out_bits_respErr),
    .io_out_bits_resp(p12_i_io_out_bits_resp),
    .io_out_bits_dataSource(p12_i_io_out_bits_dataSource),
    .io_out_bits_cBusy(p12_i_io_out_bits_cBusy),
    .io_out_bits_dbID(p12_i_io_out_bits_dbID),
    .io_out_bits_ccID(p12_i_io_out_bits_ccID),
    .io_out_bits_dataID(p12_i_io_out_bits_dataID),
    .io_out_bits_tagOp(p12_i_io_out_bits_tagOp),
    .io_out_bits_tag(p12_i_io_out_bits_tag),
    .io_out_bits_tu(p12_i_io_out_bits_tu),
    .io_out_bits_traceTag(p12_i_io_out_bits_traceTag),
    .io_out_bits_rsvdc(p12_i_io_out_bits_rsvdc),
    .io_out_bits_be(p12_i_io_out_bits_be),
    .io_out_bits_data(p12_i_io_out_bits_data),
    .io_out_bits_dataCheck(p12_i_io_out_bits_dataCheck),
    .io_out_bits_poison(p12_i_io_out_bits_poison)
  );

  // ================= Pipeline_13 =================
  int unsigned p13_mode = 0;
  logic p13_reset;
  wire  p13_g_io_in_ready, p13_i_io_in_ready;
  logic p13_s0_io_in_ready = '0, p13_s1_io_in_ready = '0;
  logic p13_io_in_valid;
  logic [3:0] p13_io_in_bits_qos;
  logic [10:0] p13_io_in_bits_tgtID;
  logic [10:0] p13_io_in_bits_srcID;
  logic [11:0] p13_io_in_bits_txnID;
  logic [4:0] p13_io_in_bits_opcode;
  logic [1:0] p13_io_in_bits_respErr;
  logic [2:0] p13_io_in_bits_resp;
  logic [2:0] p13_io_in_bits_fwdState;
  logic [2:0] p13_io_in_bits_cBusy;
  logic [11:0] p13_io_in_bits_dbID;
  logic [3:0] p13_io_in_bits_pCrdType;
  logic [1:0] p13_io_in_bits_tagOp;
  logic p13_io_in_bits_traceTag;
  logic p13_io_out_ready;
  wire  p13_g_io_out_valid, p13_i_io_out_valid;
  logic p13_s0_io_out_valid = '0, p13_s1_io_out_valid = '0;
  wire  [3:0] p13_g_io_out_bits_qos, p13_i_io_out_bits_qos;
  logic [3:0] p13_s0_io_out_bits_qos = '0, p13_s1_io_out_bits_qos = '0;
  wire  [10:0] p13_g_io_out_bits_tgtID, p13_i_io_out_bits_tgtID;
  logic [10:0] p13_s0_io_out_bits_tgtID = '0, p13_s1_io_out_bits_tgtID = '0;
  wire  [10:0] p13_g_io_out_bits_srcID, p13_i_io_out_bits_srcID;
  logic [10:0] p13_s0_io_out_bits_srcID = '0, p13_s1_io_out_bits_srcID = '0;
  wire  [11:0] p13_g_io_out_bits_txnID, p13_i_io_out_bits_txnID;
  logic [11:0] p13_s0_io_out_bits_txnID = '0, p13_s1_io_out_bits_txnID = '0;
  wire  [4:0] p13_g_io_out_bits_opcode, p13_i_io_out_bits_opcode;
  logic [4:0] p13_s0_io_out_bits_opcode = '0, p13_s1_io_out_bits_opcode = '0;
  wire  [1:0] p13_g_io_out_bits_respErr, p13_i_io_out_bits_respErr;
  logic [1:0] p13_s0_io_out_bits_respErr = '0, p13_s1_io_out_bits_respErr = '0;
  wire  [2:0] p13_g_io_out_bits_resp, p13_i_io_out_bits_resp;
  logic [2:0] p13_s0_io_out_bits_resp = '0, p13_s1_io_out_bits_resp = '0;
  wire  [2:0] p13_g_io_out_bits_fwdState, p13_i_io_out_bits_fwdState;
  logic [2:0] p13_s0_io_out_bits_fwdState = '0, p13_s1_io_out_bits_fwdState = '0;
  wire  [2:0] p13_g_io_out_bits_cBusy, p13_i_io_out_bits_cBusy;
  logic [2:0] p13_s0_io_out_bits_cBusy = '0, p13_s1_io_out_bits_cBusy = '0;
  wire  [11:0] p13_g_io_out_bits_dbID, p13_i_io_out_bits_dbID;
  logic [11:0] p13_s0_io_out_bits_dbID = '0, p13_s1_io_out_bits_dbID = '0;
  wire  [3:0] p13_g_io_out_bits_pCrdType, p13_i_io_out_bits_pCrdType;
  logic [3:0] p13_s0_io_out_bits_pCrdType = '0, p13_s1_io_out_bits_pCrdType = '0;
  wire  [1:0] p13_g_io_out_bits_tagOp, p13_i_io_out_bits_tagOp;
  logic [1:0] p13_s0_io_out_bits_tagOp = '0, p13_s1_io_out_bits_tagOp = '0;
  wire  p13_g_io_out_bits_traceTag, p13_i_io_out_bits_traceTag;
  logic p13_s0_io_out_bits_traceTag = '0, p13_s1_io_out_bits_traceTag = '0;
  int p13_cov_enq = 0;
  int p13_cov_deq = 0;
  int p13_cov_backpressure = 0;
  int p13_cov_enq_deq_same = 0;
  int p13_cov_full_refused = 0;
  logic [0:0] p13_armed = '0;
  int p13_armed_at = -1;
  Pipeline_13 p13_u_gold (
    .clock(clk),
    .reset(p13_reset),
    .io_in_ready(p13_g_io_in_ready),
    .io_in_valid(p13_io_in_valid),
    .io_in_bits_qos(p13_io_in_bits_qos),
    .io_in_bits_tgtID(p13_io_in_bits_tgtID),
    .io_in_bits_srcID(p13_io_in_bits_srcID),
    .io_in_bits_txnID(p13_io_in_bits_txnID),
    .io_in_bits_opcode(p13_io_in_bits_opcode),
    .io_in_bits_respErr(p13_io_in_bits_respErr),
    .io_in_bits_resp(p13_io_in_bits_resp),
    .io_in_bits_fwdState(p13_io_in_bits_fwdState),
    .io_in_bits_cBusy(p13_io_in_bits_cBusy),
    .io_in_bits_dbID(p13_io_in_bits_dbID),
    .io_in_bits_pCrdType(p13_io_in_bits_pCrdType),
    .io_in_bits_tagOp(p13_io_in_bits_tagOp),
    .io_in_bits_traceTag(p13_io_in_bits_traceTag),
    .io_out_ready(p13_io_out_ready),
    .io_out_valid(p13_g_io_out_valid),
    .io_out_bits_qos(p13_g_io_out_bits_qos),
    .io_out_bits_tgtID(p13_g_io_out_bits_tgtID),
    .io_out_bits_srcID(p13_g_io_out_bits_srcID),
    .io_out_bits_txnID(p13_g_io_out_bits_txnID),
    .io_out_bits_opcode(p13_g_io_out_bits_opcode),
    .io_out_bits_respErr(p13_g_io_out_bits_respErr),
    .io_out_bits_resp(p13_g_io_out_bits_resp),
    .io_out_bits_fwdState(p13_g_io_out_bits_fwdState),
    .io_out_bits_cBusy(p13_g_io_out_bits_cBusy),
    .io_out_bits_dbID(p13_g_io_out_bits_dbID),
    .io_out_bits_pCrdType(p13_g_io_out_bits_pCrdType),
    .io_out_bits_tagOp(p13_g_io_out_bits_tagOp),
    .io_out_bits_traceTag(p13_g_io_out_bits_traceTag)
  );
  Pipeline_13_xs p13_u_impl (
    .clock(clk),
    .reset(p13_reset),
    .io_in_ready(p13_i_io_in_ready),
    .io_in_valid(p13_io_in_valid),
    .io_in_bits_qos(p13_io_in_bits_qos),
    .io_in_bits_tgtID(p13_io_in_bits_tgtID),
    .io_in_bits_srcID(p13_io_in_bits_srcID),
    .io_in_bits_txnID(p13_io_in_bits_txnID),
    .io_in_bits_opcode(p13_io_in_bits_opcode),
    .io_in_bits_respErr(p13_io_in_bits_respErr),
    .io_in_bits_resp(p13_io_in_bits_resp),
    .io_in_bits_fwdState(p13_io_in_bits_fwdState),
    .io_in_bits_cBusy(p13_io_in_bits_cBusy),
    .io_in_bits_dbID(p13_io_in_bits_dbID),
    .io_in_bits_pCrdType(p13_io_in_bits_pCrdType),
    .io_in_bits_tagOp(p13_io_in_bits_tagOp),
    .io_in_bits_traceTag(p13_io_in_bits_traceTag),
    .io_out_ready(p13_io_out_ready),
    .io_out_valid(p13_i_io_out_valid),
    .io_out_bits_qos(p13_i_io_out_bits_qos),
    .io_out_bits_tgtID(p13_i_io_out_bits_tgtID),
    .io_out_bits_srcID(p13_i_io_out_bits_srcID),
    .io_out_bits_txnID(p13_i_io_out_bits_txnID),
    .io_out_bits_opcode(p13_i_io_out_bits_opcode),
    .io_out_bits_respErr(p13_i_io_out_bits_respErr),
    .io_out_bits_resp(p13_i_io_out_bits_resp),
    .io_out_bits_fwdState(p13_i_io_out_bits_fwdState),
    .io_out_bits_cBusy(p13_i_io_out_bits_cBusy),
    .io_out_bits_dbID(p13_i_io_out_bits_dbID),
    .io_out_bits_pCrdType(p13_i_io_out_bits_pCrdType),
    .io_out_bits_tagOp(p13_i_io_out_bits_tagOp),
    .io_out_bits_traceTag(p13_i_io_out_bits_traceTag)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) p12_mode = $urandom_range(0, 15);
      p12_io_in_valid = 1'($urandom);
      p12_io_in_bits_qos = 4'($urandom);
      p12_io_in_bits_tgtID = 11'($urandom);
      p12_io_in_bits_srcID = 11'($urandom);
      p12_io_in_bits_txnID = 12'($urandom);
      p12_io_in_bits_homeNID = 11'($urandom);
      p12_io_in_bits_opcode = 4'($urandom);
      p12_io_in_bits_respErr = 2'($urandom);
      p12_io_in_bits_resp = 3'($urandom);
      p12_io_in_bits_dataSource = 4'($urandom);
      p12_io_in_bits_cBusy = 3'($urandom);
      p12_io_in_bits_dbID = 12'($urandom);
      p12_io_in_bits_ccID = 2'($urandom);
      p12_io_in_bits_dataID = 2'($urandom);
      p12_io_in_bits_tagOp = 2'($urandom);
      p12_io_in_bits_tag = 8'($urandom);
      p12_io_in_bits_tu = 2'($urandom);
      p12_io_in_bits_traceTag = 1'($urandom);
      p12_io_in_bits_rsvdc = 4'($urandom);
      p12_io_in_bits_be = 32'($urandom);
      p12_io_in_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      p12_io_in_bits_dataCheck = 32'($urandom);
      p12_io_in_bits_poison = 4'($urandom);
      p12_io_out_ready = 1'($urandom);
      p12_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p12
        case (p12_mode % 3)
          0: p12_io_in_valid = ($urandom_range(0, 3) == 0);
          1: p12_io_in_valid = ($urandom_range(0, 3) != 0);
          default: ;
        endcase
        p12_io_out_ready = ($urandom_range(0, 3) != 0);
      end
      if (cyc % 4000 == 0) p13_mode = $urandom_range(0, 15);
      p13_io_in_valid = 1'($urandom);
      p13_io_in_bits_qos = 4'($urandom);
      p13_io_in_bits_tgtID = 11'($urandom);
      p13_io_in_bits_srcID = 11'($urandom);
      p13_io_in_bits_txnID = 12'($urandom);
      p13_io_in_bits_opcode = 5'($urandom);
      p13_io_in_bits_respErr = 2'($urandom);
      p13_io_in_bits_resp = 3'($urandom);
      p13_io_in_bits_fwdState = 3'($urandom);
      p13_io_in_bits_cBusy = 3'($urandom);
      p13_io_in_bits_dbID = 12'($urandom);
      p13_io_in_bits_pCrdType = 4'($urandom);
      p13_io_in_bits_tagOp = 2'($urandom);
      p13_io_in_bits_traceTag = 1'($urandom);
      p13_io_out_ready = 1'($urandom);
      p13_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_p13
        case (p13_mode % 3)
          0: p13_io_in_valid = ($urandom_range(0, 3) == 0);
          1: p13_io_in_valid = ($urandom_range(0, 3) != 0);
          default: ;
        endcase
        p13_io_out_ready = ($urandom_range(0, 3) != 0);
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&p12_armed)) begin
        checks++;
        if (p12_g_io_in_ready !== p12_i_io_in_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_in_ready g=%h i=%h", cyc, p12_g_io_in_ready, p12_i_io_in_ready);
        end
        p12_s1_io_in_ready |= p12_g_io_in_ready;
        p12_s0_io_in_ready |= ~p12_g_io_in_ready;
        checks++;
        if (p12_g_io_out_valid !== p12_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_valid g=%h i=%h", cyc, p12_g_io_out_valid, p12_i_io_out_valid);
        end
        p12_s1_io_out_valid |= p12_g_io_out_valid;
        p12_s0_io_out_valid |= ~p12_g_io_out_valid;
        checks++;
        if (p12_g_io_out_bits_qos !== p12_i_io_out_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_qos g=%h i=%h", cyc, p12_g_io_out_bits_qos, p12_i_io_out_bits_qos);
        end
        p12_s1_io_out_bits_qos |= p12_g_io_out_bits_qos;
        p12_s0_io_out_bits_qos |= ~p12_g_io_out_bits_qos;
        checks++;
        if (p12_g_io_out_bits_tgtID !== p12_i_io_out_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_tgtID g=%h i=%h", cyc, p12_g_io_out_bits_tgtID, p12_i_io_out_bits_tgtID);
        end
        p12_s1_io_out_bits_tgtID |= p12_g_io_out_bits_tgtID;
        p12_s0_io_out_bits_tgtID |= ~p12_g_io_out_bits_tgtID;
        checks++;
        if (p12_g_io_out_bits_srcID !== p12_i_io_out_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_srcID g=%h i=%h", cyc, p12_g_io_out_bits_srcID, p12_i_io_out_bits_srcID);
        end
        p12_s1_io_out_bits_srcID |= p12_g_io_out_bits_srcID;
        p12_s0_io_out_bits_srcID |= ~p12_g_io_out_bits_srcID;
        checks++;
        if (p12_g_io_out_bits_txnID !== p12_i_io_out_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_txnID g=%h i=%h", cyc, p12_g_io_out_bits_txnID, p12_i_io_out_bits_txnID);
        end
        p12_s1_io_out_bits_txnID |= p12_g_io_out_bits_txnID;
        p12_s0_io_out_bits_txnID |= ~p12_g_io_out_bits_txnID;
        checks++;
        if (p12_g_io_out_bits_homeNID !== p12_i_io_out_bits_homeNID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_homeNID g=%h i=%h", cyc, p12_g_io_out_bits_homeNID, p12_i_io_out_bits_homeNID);
        end
        p12_s1_io_out_bits_homeNID |= p12_g_io_out_bits_homeNID;
        p12_s0_io_out_bits_homeNID |= ~p12_g_io_out_bits_homeNID;
        checks++;
        if (p12_g_io_out_bits_opcode !== p12_i_io_out_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_opcode g=%h i=%h", cyc, p12_g_io_out_bits_opcode, p12_i_io_out_bits_opcode);
        end
        p12_s1_io_out_bits_opcode |= p12_g_io_out_bits_opcode;
        p12_s0_io_out_bits_opcode |= ~p12_g_io_out_bits_opcode;
        checks++;
        if (p12_g_io_out_bits_respErr !== p12_i_io_out_bits_respErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_respErr g=%h i=%h", cyc, p12_g_io_out_bits_respErr, p12_i_io_out_bits_respErr);
        end
        p12_s1_io_out_bits_respErr |= p12_g_io_out_bits_respErr;
        p12_s0_io_out_bits_respErr |= ~p12_g_io_out_bits_respErr;
        checks++;
        if (p12_g_io_out_bits_resp !== p12_i_io_out_bits_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_resp g=%h i=%h", cyc, p12_g_io_out_bits_resp, p12_i_io_out_bits_resp);
        end
        p12_s1_io_out_bits_resp |= p12_g_io_out_bits_resp;
        p12_s0_io_out_bits_resp |= ~p12_g_io_out_bits_resp;
        checks++;
        if (p12_g_io_out_bits_dataSource !== p12_i_io_out_bits_dataSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_dataSource g=%h i=%h", cyc, p12_g_io_out_bits_dataSource, p12_i_io_out_bits_dataSource);
        end
        p12_s1_io_out_bits_dataSource |= p12_g_io_out_bits_dataSource;
        p12_s0_io_out_bits_dataSource |= ~p12_g_io_out_bits_dataSource;
        checks++;
        if (p12_g_io_out_bits_cBusy !== p12_i_io_out_bits_cBusy) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_cBusy g=%h i=%h", cyc, p12_g_io_out_bits_cBusy, p12_i_io_out_bits_cBusy);
        end
        p12_s1_io_out_bits_cBusy |= p12_g_io_out_bits_cBusy;
        p12_s0_io_out_bits_cBusy |= ~p12_g_io_out_bits_cBusy;
        checks++;
        if (p12_g_io_out_bits_dbID !== p12_i_io_out_bits_dbID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_dbID g=%h i=%h", cyc, p12_g_io_out_bits_dbID, p12_i_io_out_bits_dbID);
        end
        p12_s1_io_out_bits_dbID |= p12_g_io_out_bits_dbID;
        p12_s0_io_out_bits_dbID |= ~p12_g_io_out_bits_dbID;
        checks++;
        if (p12_g_io_out_bits_ccID !== p12_i_io_out_bits_ccID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_ccID g=%h i=%h", cyc, p12_g_io_out_bits_ccID, p12_i_io_out_bits_ccID);
        end
        p12_s1_io_out_bits_ccID |= p12_g_io_out_bits_ccID;
        p12_s0_io_out_bits_ccID |= ~p12_g_io_out_bits_ccID;
        checks++;
        if (p12_g_io_out_bits_dataID !== p12_i_io_out_bits_dataID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_dataID g=%h i=%h", cyc, p12_g_io_out_bits_dataID, p12_i_io_out_bits_dataID);
        end
        p12_s1_io_out_bits_dataID |= p12_g_io_out_bits_dataID;
        p12_s0_io_out_bits_dataID |= ~p12_g_io_out_bits_dataID;
        checks++;
        if (p12_g_io_out_bits_tagOp !== p12_i_io_out_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_tagOp g=%h i=%h", cyc, p12_g_io_out_bits_tagOp, p12_i_io_out_bits_tagOp);
        end
        p12_s1_io_out_bits_tagOp |= p12_g_io_out_bits_tagOp;
        p12_s0_io_out_bits_tagOp |= ~p12_g_io_out_bits_tagOp;
        checks++;
        if (p12_g_io_out_bits_tag !== p12_i_io_out_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_tag g=%h i=%h", cyc, p12_g_io_out_bits_tag, p12_i_io_out_bits_tag);
        end
        p12_s1_io_out_bits_tag |= p12_g_io_out_bits_tag;
        p12_s0_io_out_bits_tag |= ~p12_g_io_out_bits_tag;
        checks++;
        if (p12_g_io_out_bits_tu !== p12_i_io_out_bits_tu) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_tu g=%h i=%h", cyc, p12_g_io_out_bits_tu, p12_i_io_out_bits_tu);
        end
        p12_s1_io_out_bits_tu |= p12_g_io_out_bits_tu;
        p12_s0_io_out_bits_tu |= ~p12_g_io_out_bits_tu;
        checks++;
        if (p12_g_io_out_bits_traceTag !== p12_i_io_out_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_traceTag g=%h i=%h", cyc, p12_g_io_out_bits_traceTag, p12_i_io_out_bits_traceTag);
        end
        p12_s1_io_out_bits_traceTag |= p12_g_io_out_bits_traceTag;
        p12_s0_io_out_bits_traceTag |= ~p12_g_io_out_bits_traceTag;
        checks++;
        if (p12_g_io_out_bits_rsvdc !== p12_i_io_out_bits_rsvdc) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_rsvdc g=%h i=%h", cyc, p12_g_io_out_bits_rsvdc, p12_i_io_out_bits_rsvdc);
        end
        p12_s1_io_out_bits_rsvdc |= p12_g_io_out_bits_rsvdc;
        p12_s0_io_out_bits_rsvdc |= ~p12_g_io_out_bits_rsvdc;
        checks++;
        if (p12_g_io_out_bits_be !== p12_i_io_out_bits_be) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_be g=%h i=%h", cyc, p12_g_io_out_bits_be, p12_i_io_out_bits_be);
        end
        p12_s1_io_out_bits_be |= p12_g_io_out_bits_be;
        p12_s0_io_out_bits_be |= ~p12_g_io_out_bits_be;
        checks++;
        if (p12_g_io_out_bits_data !== p12_i_io_out_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_data g=%h i=%h", cyc, p12_g_io_out_bits_data, p12_i_io_out_bits_data);
        end
        p12_s1_io_out_bits_data |= p12_g_io_out_bits_data;
        p12_s0_io_out_bits_data |= ~p12_g_io_out_bits_data;
        checks++;
        if (p12_g_io_out_bits_dataCheck !== p12_i_io_out_bits_dataCheck) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_dataCheck g=%h i=%h", cyc, p12_g_io_out_bits_dataCheck, p12_i_io_out_bits_dataCheck);
        end
        p12_s1_io_out_bits_dataCheck |= p12_g_io_out_bits_dataCheck;
        p12_s0_io_out_bits_dataCheck |= ~p12_g_io_out_bits_dataCheck;
        checks++;
        if (p12_g_io_out_bits_poison !== p12_i_io_out_bits_poison) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_12.io_out_bits_poison g=%h i=%h", cyc, p12_g_io_out_bits_poison, p12_i_io_out_bits_poison);
        end
        p12_s1_io_out_bits_poison |= p12_g_io_out_bits_poison;
        p12_s0_io_out_bits_poison |= ~p12_g_io_out_bits_poison;
        if (p12_io_in_valid && p12_g_io_in_ready) p12_cov_enq++;
        if (p12_g_io_out_valid && p12_io_out_ready) p12_cov_deq++;
        if (p12_g_io_out_valid && !p12_io_out_ready) p12_cov_backpressure++;
        if (p12_io_in_valid && p12_g_io_in_ready && p12_g_io_out_valid && p12_io_out_ready) p12_cov_enq_deq_same++;
        if (p12_io_in_valid && !p12_g_io_in_ready) p12_cov_full_refused++;
      end
      if (p12_io_in_valid && p12_g_io_in_ready && !p12_reset) p12_armed[0] = 1'b1;
      if (p12_armed_at < 0 && (&p12_armed)) p12_armed_at = cyc + 1;
      if (cyc >= RESET_CYC + 0 && (&p13_armed)) begin
        checks++;
        if (p13_g_io_in_ready !== p13_i_io_in_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_in_ready g=%h i=%h", cyc, p13_g_io_in_ready, p13_i_io_in_ready);
        end
        p13_s1_io_in_ready |= p13_g_io_in_ready;
        p13_s0_io_in_ready |= ~p13_g_io_in_ready;
        checks++;
        if (p13_g_io_out_valid !== p13_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_valid g=%h i=%h", cyc, p13_g_io_out_valid, p13_i_io_out_valid);
        end
        p13_s1_io_out_valid |= p13_g_io_out_valid;
        p13_s0_io_out_valid |= ~p13_g_io_out_valid;
        checks++;
        if (p13_g_io_out_bits_qos !== p13_i_io_out_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_qos g=%h i=%h", cyc, p13_g_io_out_bits_qos, p13_i_io_out_bits_qos);
        end
        p13_s1_io_out_bits_qos |= p13_g_io_out_bits_qos;
        p13_s0_io_out_bits_qos |= ~p13_g_io_out_bits_qos;
        checks++;
        if (p13_g_io_out_bits_tgtID !== p13_i_io_out_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_tgtID g=%h i=%h", cyc, p13_g_io_out_bits_tgtID, p13_i_io_out_bits_tgtID);
        end
        p13_s1_io_out_bits_tgtID |= p13_g_io_out_bits_tgtID;
        p13_s0_io_out_bits_tgtID |= ~p13_g_io_out_bits_tgtID;
        checks++;
        if (p13_g_io_out_bits_srcID !== p13_i_io_out_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_srcID g=%h i=%h", cyc, p13_g_io_out_bits_srcID, p13_i_io_out_bits_srcID);
        end
        p13_s1_io_out_bits_srcID |= p13_g_io_out_bits_srcID;
        p13_s0_io_out_bits_srcID |= ~p13_g_io_out_bits_srcID;
        checks++;
        if (p13_g_io_out_bits_txnID !== p13_i_io_out_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_txnID g=%h i=%h", cyc, p13_g_io_out_bits_txnID, p13_i_io_out_bits_txnID);
        end
        p13_s1_io_out_bits_txnID |= p13_g_io_out_bits_txnID;
        p13_s0_io_out_bits_txnID |= ~p13_g_io_out_bits_txnID;
        checks++;
        if (p13_g_io_out_bits_opcode !== p13_i_io_out_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_opcode g=%h i=%h", cyc, p13_g_io_out_bits_opcode, p13_i_io_out_bits_opcode);
        end
        p13_s1_io_out_bits_opcode |= p13_g_io_out_bits_opcode;
        p13_s0_io_out_bits_opcode |= ~p13_g_io_out_bits_opcode;
        checks++;
        if (p13_g_io_out_bits_respErr !== p13_i_io_out_bits_respErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_respErr g=%h i=%h", cyc, p13_g_io_out_bits_respErr, p13_i_io_out_bits_respErr);
        end
        p13_s1_io_out_bits_respErr |= p13_g_io_out_bits_respErr;
        p13_s0_io_out_bits_respErr |= ~p13_g_io_out_bits_respErr;
        checks++;
        if (p13_g_io_out_bits_resp !== p13_i_io_out_bits_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_resp g=%h i=%h", cyc, p13_g_io_out_bits_resp, p13_i_io_out_bits_resp);
        end
        p13_s1_io_out_bits_resp |= p13_g_io_out_bits_resp;
        p13_s0_io_out_bits_resp |= ~p13_g_io_out_bits_resp;
        checks++;
        if (p13_g_io_out_bits_fwdState !== p13_i_io_out_bits_fwdState) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_fwdState g=%h i=%h", cyc, p13_g_io_out_bits_fwdState, p13_i_io_out_bits_fwdState);
        end
        p13_s1_io_out_bits_fwdState |= p13_g_io_out_bits_fwdState;
        p13_s0_io_out_bits_fwdState |= ~p13_g_io_out_bits_fwdState;
        checks++;
        if (p13_g_io_out_bits_cBusy !== p13_i_io_out_bits_cBusy) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_cBusy g=%h i=%h", cyc, p13_g_io_out_bits_cBusy, p13_i_io_out_bits_cBusy);
        end
        p13_s1_io_out_bits_cBusy |= p13_g_io_out_bits_cBusy;
        p13_s0_io_out_bits_cBusy |= ~p13_g_io_out_bits_cBusy;
        checks++;
        if (p13_g_io_out_bits_dbID !== p13_i_io_out_bits_dbID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_dbID g=%h i=%h", cyc, p13_g_io_out_bits_dbID, p13_i_io_out_bits_dbID);
        end
        p13_s1_io_out_bits_dbID |= p13_g_io_out_bits_dbID;
        p13_s0_io_out_bits_dbID |= ~p13_g_io_out_bits_dbID;
        checks++;
        if (p13_g_io_out_bits_pCrdType !== p13_i_io_out_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_pCrdType g=%h i=%h", cyc, p13_g_io_out_bits_pCrdType, p13_i_io_out_bits_pCrdType);
        end
        p13_s1_io_out_bits_pCrdType |= p13_g_io_out_bits_pCrdType;
        p13_s0_io_out_bits_pCrdType |= ~p13_g_io_out_bits_pCrdType;
        checks++;
        if (p13_g_io_out_bits_tagOp !== p13_i_io_out_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_tagOp g=%h i=%h", cyc, p13_g_io_out_bits_tagOp, p13_i_io_out_bits_tagOp);
        end
        p13_s1_io_out_bits_tagOp |= p13_g_io_out_bits_tagOp;
        p13_s0_io_out_bits_tagOp |= ~p13_g_io_out_bits_tagOp;
        checks++;
        if (p13_g_io_out_bits_traceTag !== p13_i_io_out_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d Pipeline_13.io_out_bits_traceTag g=%h i=%h", cyc, p13_g_io_out_bits_traceTag, p13_i_io_out_bits_traceTag);
        end
        p13_s1_io_out_bits_traceTag |= p13_g_io_out_bits_traceTag;
        p13_s0_io_out_bits_traceTag |= ~p13_g_io_out_bits_traceTag;
        if (p13_io_in_valid && p13_g_io_in_ready) p13_cov_enq++;
        if (p13_g_io_out_valid && p13_io_out_ready) p13_cov_deq++;
        if (p13_g_io_out_valid && !p13_io_out_ready) p13_cov_backpressure++;
        if (p13_io_in_valid && p13_g_io_in_ready && p13_g_io_out_valid && p13_io_out_ready) p13_cov_enq_deq_same++;
        if (p13_io_in_valid && !p13_g_io_in_ready) p13_cov_full_refused++;
      end
      if (p13_io_in_valid && p13_g_io_in_ready && !p13_reset) p13_armed[0] = 1'b1;
      if (p13_armed_at < 0 && (&p13_armed)) p13_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(p12_s0_io_in_ready && p12_s1_io_in_ready)) begin cov_fail++; $display("[COV] Pipeline_12.io_in_ready 未见过 0 和 1"); end
    if (!(p12_s0_io_out_valid && p12_s1_io_out_valid)) begin cov_fail++; $display("[COV] Pipeline_12.io_out_valid 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_qos[0] && p12_s1_io_out_bits_qos[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_qos[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_qos[1] && p12_s1_io_out_bits_qos[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_qos[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_qos[2] && p12_s1_io_out_bits_qos[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_qos[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_qos[3] && p12_s1_io_out_bits_qos[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_qos[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[0] && p12_s1_io_out_bits_tgtID[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[1] && p12_s1_io_out_bits_tgtID[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[2] && p12_s1_io_out_bits_tgtID[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[3] && p12_s1_io_out_bits_tgtID[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[4] && p12_s1_io_out_bits_tgtID[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[5] && p12_s1_io_out_bits_tgtID[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[6] && p12_s1_io_out_bits_tgtID[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[7] && p12_s1_io_out_bits_tgtID[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[8] && p12_s1_io_out_bits_tgtID[8])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[8] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[9] && p12_s1_io_out_bits_tgtID[9])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[9] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tgtID[10] && p12_s1_io_out_bits_tgtID[10])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tgtID[10] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[0] && p12_s1_io_out_bits_srcID[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[1] && p12_s1_io_out_bits_srcID[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[2] && p12_s1_io_out_bits_srcID[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[3] && p12_s1_io_out_bits_srcID[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[4] && p12_s1_io_out_bits_srcID[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[5] && p12_s1_io_out_bits_srcID[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[6] && p12_s1_io_out_bits_srcID[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[7] && p12_s1_io_out_bits_srcID[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[8] && p12_s1_io_out_bits_srcID[8])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[8] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[9] && p12_s1_io_out_bits_srcID[9])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[9] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_srcID[10] && p12_s1_io_out_bits_srcID[10])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_srcID[10] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[0] && p12_s1_io_out_bits_txnID[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[1] && p12_s1_io_out_bits_txnID[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[2] && p12_s1_io_out_bits_txnID[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[3] && p12_s1_io_out_bits_txnID[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[4] && p12_s1_io_out_bits_txnID[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[5] && p12_s1_io_out_bits_txnID[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[6] && p12_s1_io_out_bits_txnID[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[7] && p12_s1_io_out_bits_txnID[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[8] && p12_s1_io_out_bits_txnID[8])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[8] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[9] && p12_s1_io_out_bits_txnID[9])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[9] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[10] && p12_s1_io_out_bits_txnID[10])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[10] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_txnID[11] && p12_s1_io_out_bits_txnID[11])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_txnID[11] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[0] && p12_s1_io_out_bits_homeNID[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[1] && p12_s1_io_out_bits_homeNID[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[2] && p12_s1_io_out_bits_homeNID[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[3] && p12_s1_io_out_bits_homeNID[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[4] && p12_s1_io_out_bits_homeNID[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[5] && p12_s1_io_out_bits_homeNID[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[6] && p12_s1_io_out_bits_homeNID[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[7] && p12_s1_io_out_bits_homeNID[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[8] && p12_s1_io_out_bits_homeNID[8])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[8] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[9] && p12_s1_io_out_bits_homeNID[9])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[9] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_homeNID[10] && p12_s1_io_out_bits_homeNID[10])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_homeNID[10] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_opcode[0] && p12_s1_io_out_bits_opcode[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_opcode[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_opcode[1] && p12_s1_io_out_bits_opcode[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_opcode[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_opcode[2] && p12_s1_io_out_bits_opcode[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_opcode[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_opcode[3] && p12_s1_io_out_bits_opcode[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_opcode[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_respErr[0] && p12_s1_io_out_bits_respErr[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_respErr[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_respErr[1] && p12_s1_io_out_bits_respErr[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_respErr[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_resp[0] && p12_s1_io_out_bits_resp[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_resp[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_resp[1] && p12_s1_io_out_bits_resp[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_resp[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_resp[2] && p12_s1_io_out_bits_resp[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_resp[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataSource[0] && p12_s1_io_out_bits_dataSource[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataSource[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataSource[1] && p12_s1_io_out_bits_dataSource[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataSource[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataSource[2] && p12_s1_io_out_bits_dataSource[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataSource[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataSource[3] && p12_s1_io_out_bits_dataSource[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataSource[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_cBusy[0] && p12_s1_io_out_bits_cBusy[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_cBusy[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_cBusy[1] && p12_s1_io_out_bits_cBusy[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_cBusy[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_cBusy[2] && p12_s1_io_out_bits_cBusy[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_cBusy[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[0] && p12_s1_io_out_bits_dbID[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[1] && p12_s1_io_out_bits_dbID[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[2] && p12_s1_io_out_bits_dbID[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[3] && p12_s1_io_out_bits_dbID[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[4] && p12_s1_io_out_bits_dbID[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[5] && p12_s1_io_out_bits_dbID[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[6] && p12_s1_io_out_bits_dbID[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[7] && p12_s1_io_out_bits_dbID[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[8] && p12_s1_io_out_bits_dbID[8])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[8] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[9] && p12_s1_io_out_bits_dbID[9])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[9] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[10] && p12_s1_io_out_bits_dbID[10])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[10] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dbID[11] && p12_s1_io_out_bits_dbID[11])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dbID[11] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_ccID[0] && p12_s1_io_out_bits_ccID[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_ccID[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_ccID[1] && p12_s1_io_out_bits_ccID[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_ccID[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataID[0] && p12_s1_io_out_bits_dataID[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataID[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataID[1] && p12_s1_io_out_bits_dataID[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataID[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tagOp[0] && p12_s1_io_out_bits_tagOp[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tagOp[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tagOp[1] && p12_s1_io_out_bits_tagOp[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tagOp[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tag[0] && p12_s1_io_out_bits_tag[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tag[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tag[1] && p12_s1_io_out_bits_tag[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tag[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tag[2] && p12_s1_io_out_bits_tag[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tag[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tag[3] && p12_s1_io_out_bits_tag[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tag[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tag[4] && p12_s1_io_out_bits_tag[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tag[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tag[5] && p12_s1_io_out_bits_tag[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tag[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tag[6] && p12_s1_io_out_bits_tag[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tag[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tag[7] && p12_s1_io_out_bits_tag[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tag[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tu[0] && p12_s1_io_out_bits_tu[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tu[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_tu[1] && p12_s1_io_out_bits_tu[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_tu[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_traceTag && p12_s1_io_out_bits_traceTag)) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_traceTag 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_rsvdc[0] && p12_s1_io_out_bits_rsvdc[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_rsvdc[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_rsvdc[1] && p12_s1_io_out_bits_rsvdc[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_rsvdc[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_rsvdc[2] && p12_s1_io_out_bits_rsvdc[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_rsvdc[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_rsvdc[3] && p12_s1_io_out_bits_rsvdc[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_rsvdc[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[0] && p12_s1_io_out_bits_be[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[1] && p12_s1_io_out_bits_be[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[2] && p12_s1_io_out_bits_be[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[3] && p12_s1_io_out_bits_be[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[4] && p12_s1_io_out_bits_be[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[5] && p12_s1_io_out_bits_be[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[6] && p12_s1_io_out_bits_be[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[7] && p12_s1_io_out_bits_be[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[8] && p12_s1_io_out_bits_be[8])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[8] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[9] && p12_s1_io_out_bits_be[9])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[9] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[10] && p12_s1_io_out_bits_be[10])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[10] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[11] && p12_s1_io_out_bits_be[11])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[11] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[12] && p12_s1_io_out_bits_be[12])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[12] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[13] && p12_s1_io_out_bits_be[13])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[13] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[14] && p12_s1_io_out_bits_be[14])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[14] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[15] && p12_s1_io_out_bits_be[15])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[15] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[16] && p12_s1_io_out_bits_be[16])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[16] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[17] && p12_s1_io_out_bits_be[17])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[17] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[18] && p12_s1_io_out_bits_be[18])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[18] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[19] && p12_s1_io_out_bits_be[19])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[19] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[20] && p12_s1_io_out_bits_be[20])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[20] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[21] && p12_s1_io_out_bits_be[21])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[21] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[22] && p12_s1_io_out_bits_be[22])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[22] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[23] && p12_s1_io_out_bits_be[23])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[23] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[24] && p12_s1_io_out_bits_be[24])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[24] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[25] && p12_s1_io_out_bits_be[25])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[25] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[26] && p12_s1_io_out_bits_be[26])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[26] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[27] && p12_s1_io_out_bits_be[27])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[27] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[28] && p12_s1_io_out_bits_be[28])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[28] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[29] && p12_s1_io_out_bits_be[29])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[29] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[30] && p12_s1_io_out_bits_be[30])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[30] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_be[31] && p12_s1_io_out_bits_be[31])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_be[31] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[0] && p12_s1_io_out_bits_data[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[1] && p12_s1_io_out_bits_data[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[2] && p12_s1_io_out_bits_data[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[3] && p12_s1_io_out_bits_data[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[4] && p12_s1_io_out_bits_data[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[5] && p12_s1_io_out_bits_data[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[6] && p12_s1_io_out_bits_data[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[7] && p12_s1_io_out_bits_data[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[8] && p12_s1_io_out_bits_data[8])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[8] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[9] && p12_s1_io_out_bits_data[9])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[9] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[10] && p12_s1_io_out_bits_data[10])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[10] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[11] && p12_s1_io_out_bits_data[11])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[11] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[12] && p12_s1_io_out_bits_data[12])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[12] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[13] && p12_s1_io_out_bits_data[13])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[13] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[14] && p12_s1_io_out_bits_data[14])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[14] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[15] && p12_s1_io_out_bits_data[15])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[15] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[16] && p12_s1_io_out_bits_data[16])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[16] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[17] && p12_s1_io_out_bits_data[17])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[17] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[18] && p12_s1_io_out_bits_data[18])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[18] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[19] && p12_s1_io_out_bits_data[19])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[19] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[20] && p12_s1_io_out_bits_data[20])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[20] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[21] && p12_s1_io_out_bits_data[21])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[21] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[22] && p12_s1_io_out_bits_data[22])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[22] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[23] && p12_s1_io_out_bits_data[23])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[23] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[24] && p12_s1_io_out_bits_data[24])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[24] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[25] && p12_s1_io_out_bits_data[25])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[25] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[26] && p12_s1_io_out_bits_data[26])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[26] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[27] && p12_s1_io_out_bits_data[27])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[27] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[28] && p12_s1_io_out_bits_data[28])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[28] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[29] && p12_s1_io_out_bits_data[29])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[29] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[30] && p12_s1_io_out_bits_data[30])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[30] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[31] && p12_s1_io_out_bits_data[31])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[31] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[32] && p12_s1_io_out_bits_data[32])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[32] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[33] && p12_s1_io_out_bits_data[33])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[33] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[34] && p12_s1_io_out_bits_data[34])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[34] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[35] && p12_s1_io_out_bits_data[35])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[35] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[36] && p12_s1_io_out_bits_data[36])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[36] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[37] && p12_s1_io_out_bits_data[37])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[37] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[38] && p12_s1_io_out_bits_data[38])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[38] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[39] && p12_s1_io_out_bits_data[39])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[39] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[40] && p12_s1_io_out_bits_data[40])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[40] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[41] && p12_s1_io_out_bits_data[41])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[41] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[42] && p12_s1_io_out_bits_data[42])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[42] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[43] && p12_s1_io_out_bits_data[43])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[43] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[44] && p12_s1_io_out_bits_data[44])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[44] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[45] && p12_s1_io_out_bits_data[45])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[45] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[46] && p12_s1_io_out_bits_data[46])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[46] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[47] && p12_s1_io_out_bits_data[47])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[47] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[48] && p12_s1_io_out_bits_data[48])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[48] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[49] && p12_s1_io_out_bits_data[49])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[49] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[50] && p12_s1_io_out_bits_data[50])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[50] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[51] && p12_s1_io_out_bits_data[51])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[51] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[52] && p12_s1_io_out_bits_data[52])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[52] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[53] && p12_s1_io_out_bits_data[53])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[53] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[54] && p12_s1_io_out_bits_data[54])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[54] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[55] && p12_s1_io_out_bits_data[55])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[55] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[56] && p12_s1_io_out_bits_data[56])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[56] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[57] && p12_s1_io_out_bits_data[57])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[57] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[58] && p12_s1_io_out_bits_data[58])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[58] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[59] && p12_s1_io_out_bits_data[59])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[59] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[60] && p12_s1_io_out_bits_data[60])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[60] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[61] && p12_s1_io_out_bits_data[61])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[61] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[62] && p12_s1_io_out_bits_data[62])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[62] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[63] && p12_s1_io_out_bits_data[63])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[63] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[64] && p12_s1_io_out_bits_data[64])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[64] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[65] && p12_s1_io_out_bits_data[65])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[65] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[66] && p12_s1_io_out_bits_data[66])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[66] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[67] && p12_s1_io_out_bits_data[67])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[67] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[68] && p12_s1_io_out_bits_data[68])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[68] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[69] && p12_s1_io_out_bits_data[69])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[69] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[70] && p12_s1_io_out_bits_data[70])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[70] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[71] && p12_s1_io_out_bits_data[71])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[71] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[72] && p12_s1_io_out_bits_data[72])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[72] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[73] && p12_s1_io_out_bits_data[73])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[73] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[74] && p12_s1_io_out_bits_data[74])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[74] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[75] && p12_s1_io_out_bits_data[75])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[75] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[76] && p12_s1_io_out_bits_data[76])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[76] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[77] && p12_s1_io_out_bits_data[77])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[77] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[78] && p12_s1_io_out_bits_data[78])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[78] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[79] && p12_s1_io_out_bits_data[79])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[79] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[80] && p12_s1_io_out_bits_data[80])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[80] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[81] && p12_s1_io_out_bits_data[81])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[81] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[82] && p12_s1_io_out_bits_data[82])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[82] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[83] && p12_s1_io_out_bits_data[83])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[83] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[84] && p12_s1_io_out_bits_data[84])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[84] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[85] && p12_s1_io_out_bits_data[85])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[85] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[86] && p12_s1_io_out_bits_data[86])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[86] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[87] && p12_s1_io_out_bits_data[87])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[87] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[88] && p12_s1_io_out_bits_data[88])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[88] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[89] && p12_s1_io_out_bits_data[89])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[89] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[90] && p12_s1_io_out_bits_data[90])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[90] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[91] && p12_s1_io_out_bits_data[91])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[91] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[92] && p12_s1_io_out_bits_data[92])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[92] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[93] && p12_s1_io_out_bits_data[93])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[93] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[94] && p12_s1_io_out_bits_data[94])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[94] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[95] && p12_s1_io_out_bits_data[95])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[95] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[96] && p12_s1_io_out_bits_data[96])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[96] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[97] && p12_s1_io_out_bits_data[97])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[97] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[98] && p12_s1_io_out_bits_data[98])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[98] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[99] && p12_s1_io_out_bits_data[99])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[99] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[100] && p12_s1_io_out_bits_data[100])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[100] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[101] && p12_s1_io_out_bits_data[101])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[101] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[102] && p12_s1_io_out_bits_data[102])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[102] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[103] && p12_s1_io_out_bits_data[103])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[103] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[104] && p12_s1_io_out_bits_data[104])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[104] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[105] && p12_s1_io_out_bits_data[105])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[105] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[106] && p12_s1_io_out_bits_data[106])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[106] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[107] && p12_s1_io_out_bits_data[107])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[107] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[108] && p12_s1_io_out_bits_data[108])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[108] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[109] && p12_s1_io_out_bits_data[109])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[109] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[110] && p12_s1_io_out_bits_data[110])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[110] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[111] && p12_s1_io_out_bits_data[111])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[111] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[112] && p12_s1_io_out_bits_data[112])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[112] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[113] && p12_s1_io_out_bits_data[113])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[113] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[114] && p12_s1_io_out_bits_data[114])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[114] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[115] && p12_s1_io_out_bits_data[115])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[115] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[116] && p12_s1_io_out_bits_data[116])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[116] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[117] && p12_s1_io_out_bits_data[117])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[117] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[118] && p12_s1_io_out_bits_data[118])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[118] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[119] && p12_s1_io_out_bits_data[119])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[119] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[120] && p12_s1_io_out_bits_data[120])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[120] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[121] && p12_s1_io_out_bits_data[121])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[121] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[122] && p12_s1_io_out_bits_data[122])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[122] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[123] && p12_s1_io_out_bits_data[123])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[123] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[124] && p12_s1_io_out_bits_data[124])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[124] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[125] && p12_s1_io_out_bits_data[125])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[125] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[126] && p12_s1_io_out_bits_data[126])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[126] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[127] && p12_s1_io_out_bits_data[127])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[127] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[128] && p12_s1_io_out_bits_data[128])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[128] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[129] && p12_s1_io_out_bits_data[129])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[129] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[130] && p12_s1_io_out_bits_data[130])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[130] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[131] && p12_s1_io_out_bits_data[131])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[131] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[132] && p12_s1_io_out_bits_data[132])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[132] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[133] && p12_s1_io_out_bits_data[133])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[133] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[134] && p12_s1_io_out_bits_data[134])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[134] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[135] && p12_s1_io_out_bits_data[135])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[135] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[136] && p12_s1_io_out_bits_data[136])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[136] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[137] && p12_s1_io_out_bits_data[137])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[137] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[138] && p12_s1_io_out_bits_data[138])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[138] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[139] && p12_s1_io_out_bits_data[139])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[139] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[140] && p12_s1_io_out_bits_data[140])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[140] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[141] && p12_s1_io_out_bits_data[141])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[141] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[142] && p12_s1_io_out_bits_data[142])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[142] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[143] && p12_s1_io_out_bits_data[143])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[143] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[144] && p12_s1_io_out_bits_data[144])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[144] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[145] && p12_s1_io_out_bits_data[145])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[145] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[146] && p12_s1_io_out_bits_data[146])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[146] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[147] && p12_s1_io_out_bits_data[147])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[147] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[148] && p12_s1_io_out_bits_data[148])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[148] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[149] && p12_s1_io_out_bits_data[149])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[149] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[150] && p12_s1_io_out_bits_data[150])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[150] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[151] && p12_s1_io_out_bits_data[151])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[151] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[152] && p12_s1_io_out_bits_data[152])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[152] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[153] && p12_s1_io_out_bits_data[153])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[153] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[154] && p12_s1_io_out_bits_data[154])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[154] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[155] && p12_s1_io_out_bits_data[155])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[155] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[156] && p12_s1_io_out_bits_data[156])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[156] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[157] && p12_s1_io_out_bits_data[157])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[157] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[158] && p12_s1_io_out_bits_data[158])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[158] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[159] && p12_s1_io_out_bits_data[159])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[159] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[160] && p12_s1_io_out_bits_data[160])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[160] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[161] && p12_s1_io_out_bits_data[161])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[161] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[162] && p12_s1_io_out_bits_data[162])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[162] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[163] && p12_s1_io_out_bits_data[163])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[163] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[164] && p12_s1_io_out_bits_data[164])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[164] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[165] && p12_s1_io_out_bits_data[165])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[165] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[166] && p12_s1_io_out_bits_data[166])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[166] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[167] && p12_s1_io_out_bits_data[167])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[167] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[168] && p12_s1_io_out_bits_data[168])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[168] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[169] && p12_s1_io_out_bits_data[169])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[169] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[170] && p12_s1_io_out_bits_data[170])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[170] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[171] && p12_s1_io_out_bits_data[171])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[171] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[172] && p12_s1_io_out_bits_data[172])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[172] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[173] && p12_s1_io_out_bits_data[173])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[173] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[174] && p12_s1_io_out_bits_data[174])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[174] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[175] && p12_s1_io_out_bits_data[175])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[175] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[176] && p12_s1_io_out_bits_data[176])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[176] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[177] && p12_s1_io_out_bits_data[177])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[177] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[178] && p12_s1_io_out_bits_data[178])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[178] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[179] && p12_s1_io_out_bits_data[179])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[179] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[180] && p12_s1_io_out_bits_data[180])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[180] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[181] && p12_s1_io_out_bits_data[181])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[181] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[182] && p12_s1_io_out_bits_data[182])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[182] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[183] && p12_s1_io_out_bits_data[183])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[183] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[184] && p12_s1_io_out_bits_data[184])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[184] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[185] && p12_s1_io_out_bits_data[185])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[185] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[186] && p12_s1_io_out_bits_data[186])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[186] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[187] && p12_s1_io_out_bits_data[187])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[187] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[188] && p12_s1_io_out_bits_data[188])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[188] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[189] && p12_s1_io_out_bits_data[189])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[189] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[190] && p12_s1_io_out_bits_data[190])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[190] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[191] && p12_s1_io_out_bits_data[191])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[191] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[192] && p12_s1_io_out_bits_data[192])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[192] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[193] && p12_s1_io_out_bits_data[193])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[193] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[194] && p12_s1_io_out_bits_data[194])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[194] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[195] && p12_s1_io_out_bits_data[195])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[195] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[196] && p12_s1_io_out_bits_data[196])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[196] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[197] && p12_s1_io_out_bits_data[197])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[197] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[198] && p12_s1_io_out_bits_data[198])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[198] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[199] && p12_s1_io_out_bits_data[199])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[199] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[200] && p12_s1_io_out_bits_data[200])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[200] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[201] && p12_s1_io_out_bits_data[201])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[201] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[202] && p12_s1_io_out_bits_data[202])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[202] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[203] && p12_s1_io_out_bits_data[203])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[203] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[204] && p12_s1_io_out_bits_data[204])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[204] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[205] && p12_s1_io_out_bits_data[205])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[205] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[206] && p12_s1_io_out_bits_data[206])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[206] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[207] && p12_s1_io_out_bits_data[207])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[207] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[208] && p12_s1_io_out_bits_data[208])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[208] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[209] && p12_s1_io_out_bits_data[209])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[209] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[210] && p12_s1_io_out_bits_data[210])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[210] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[211] && p12_s1_io_out_bits_data[211])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[211] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[212] && p12_s1_io_out_bits_data[212])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[212] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[213] && p12_s1_io_out_bits_data[213])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[213] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[214] && p12_s1_io_out_bits_data[214])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[214] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[215] && p12_s1_io_out_bits_data[215])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[215] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[216] && p12_s1_io_out_bits_data[216])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[216] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[217] && p12_s1_io_out_bits_data[217])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[217] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[218] && p12_s1_io_out_bits_data[218])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[218] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[219] && p12_s1_io_out_bits_data[219])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[219] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[220] && p12_s1_io_out_bits_data[220])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[220] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[221] && p12_s1_io_out_bits_data[221])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[221] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[222] && p12_s1_io_out_bits_data[222])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[222] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[223] && p12_s1_io_out_bits_data[223])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[223] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[224] && p12_s1_io_out_bits_data[224])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[224] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[225] && p12_s1_io_out_bits_data[225])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[225] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[226] && p12_s1_io_out_bits_data[226])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[226] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[227] && p12_s1_io_out_bits_data[227])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[227] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[228] && p12_s1_io_out_bits_data[228])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[228] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[229] && p12_s1_io_out_bits_data[229])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[229] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[230] && p12_s1_io_out_bits_data[230])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[230] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[231] && p12_s1_io_out_bits_data[231])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[231] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[232] && p12_s1_io_out_bits_data[232])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[232] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[233] && p12_s1_io_out_bits_data[233])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[233] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[234] && p12_s1_io_out_bits_data[234])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[234] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[235] && p12_s1_io_out_bits_data[235])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[235] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[236] && p12_s1_io_out_bits_data[236])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[236] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[237] && p12_s1_io_out_bits_data[237])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[237] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[238] && p12_s1_io_out_bits_data[238])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[238] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[239] && p12_s1_io_out_bits_data[239])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[239] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[240] && p12_s1_io_out_bits_data[240])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[240] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[241] && p12_s1_io_out_bits_data[241])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[241] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[242] && p12_s1_io_out_bits_data[242])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[242] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[243] && p12_s1_io_out_bits_data[243])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[243] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[244] && p12_s1_io_out_bits_data[244])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[244] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[245] && p12_s1_io_out_bits_data[245])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[245] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[246] && p12_s1_io_out_bits_data[246])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[246] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[247] && p12_s1_io_out_bits_data[247])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[247] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[248] && p12_s1_io_out_bits_data[248])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[248] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[249] && p12_s1_io_out_bits_data[249])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[249] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[250] && p12_s1_io_out_bits_data[250])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[250] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[251] && p12_s1_io_out_bits_data[251])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[251] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[252] && p12_s1_io_out_bits_data[252])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[252] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[253] && p12_s1_io_out_bits_data[253])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[253] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[254] && p12_s1_io_out_bits_data[254])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[254] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_data[255] && p12_s1_io_out_bits_data[255])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_data[255] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[0] && p12_s1_io_out_bits_dataCheck[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[1] && p12_s1_io_out_bits_dataCheck[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[2] && p12_s1_io_out_bits_dataCheck[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[3] && p12_s1_io_out_bits_dataCheck[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[3] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[4] && p12_s1_io_out_bits_dataCheck[4])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[4] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[5] && p12_s1_io_out_bits_dataCheck[5])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[5] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[6] && p12_s1_io_out_bits_dataCheck[6])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[6] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[7] && p12_s1_io_out_bits_dataCheck[7])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[7] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[8] && p12_s1_io_out_bits_dataCheck[8])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[8] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[9] && p12_s1_io_out_bits_dataCheck[9])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[9] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[10] && p12_s1_io_out_bits_dataCheck[10])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[10] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[11] && p12_s1_io_out_bits_dataCheck[11])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[11] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[12] && p12_s1_io_out_bits_dataCheck[12])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[12] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[13] && p12_s1_io_out_bits_dataCheck[13])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[13] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[14] && p12_s1_io_out_bits_dataCheck[14])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[14] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[15] && p12_s1_io_out_bits_dataCheck[15])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[15] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[16] && p12_s1_io_out_bits_dataCheck[16])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[16] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[17] && p12_s1_io_out_bits_dataCheck[17])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[17] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[18] && p12_s1_io_out_bits_dataCheck[18])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[18] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[19] && p12_s1_io_out_bits_dataCheck[19])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[19] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[20] && p12_s1_io_out_bits_dataCheck[20])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[20] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[21] && p12_s1_io_out_bits_dataCheck[21])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[21] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[22] && p12_s1_io_out_bits_dataCheck[22])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[22] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[23] && p12_s1_io_out_bits_dataCheck[23])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[23] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[24] && p12_s1_io_out_bits_dataCheck[24])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[24] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[25] && p12_s1_io_out_bits_dataCheck[25])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[25] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[26] && p12_s1_io_out_bits_dataCheck[26])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[26] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[27] && p12_s1_io_out_bits_dataCheck[27])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[27] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[28] && p12_s1_io_out_bits_dataCheck[28])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[28] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[29] && p12_s1_io_out_bits_dataCheck[29])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[29] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[30] && p12_s1_io_out_bits_dataCheck[30])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[30] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_dataCheck[31] && p12_s1_io_out_bits_dataCheck[31])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_dataCheck[31] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_poison[0] && p12_s1_io_out_bits_poison[0])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_poison[0] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_poison[1] && p12_s1_io_out_bits_poison[1])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_poison[1] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_poison[2] && p12_s1_io_out_bits_poison[2])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_poison[2] 未见过 0 和 1"); end
    if (!(p12_s0_io_out_bits_poison[3] && p12_s1_io_out_bits_poison[3])) begin cov_fail++; $display("[COV] Pipeline_12.io_out_bits_poison[3] 未见过 0 和 1"); end
    $display("[ARM] Pipeline_12 armed_at=%0d", p12_armed_at);
    if (p12_armed_at < 0) begin cov_fail++; $display("[ARM] Pipeline_12 从未 arm"); end
    $display("[COV] Pipeline_12.enq = %0d", p12_cov_enq);
    if (p12_cov_enq < 100) begin cov_fail++; $display("[COV] Pipeline_12.enq < 100"); end
    $display("[COV] Pipeline_12.deq = %0d", p12_cov_deq);
    if (p12_cov_deq < 100) begin cov_fail++; $display("[COV] Pipeline_12.deq < 100"); end
    $display("[COV] Pipeline_12.backpressure = %0d", p12_cov_backpressure);
    if (p12_cov_backpressure < 100) begin cov_fail++; $display("[COV] Pipeline_12.backpressure < 100"); end
    $display("[COV] Pipeline_12.enq_deq_same = %0d", p12_cov_enq_deq_same);
    if (p12_cov_enq_deq_same < 100) begin cov_fail++; $display("[COV] Pipeline_12.enq_deq_same < 100"); end
    $display("[COV] Pipeline_12.full_refused = %0d", p12_cov_full_refused);
    if (p12_cov_full_refused < 100) begin cov_fail++; $display("[COV] Pipeline_12.full_refused < 100"); end
    if (!(p13_s0_io_in_ready && p13_s1_io_in_ready)) begin cov_fail++; $display("[COV] Pipeline_13.io_in_ready 未见过 0 和 1"); end
    if (!(p13_s0_io_out_valid && p13_s1_io_out_valid)) begin cov_fail++; $display("[COV] Pipeline_13.io_out_valid 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_qos[0] && p13_s1_io_out_bits_qos[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_qos[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_qos[1] && p13_s1_io_out_bits_qos[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_qos[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_qos[2] && p13_s1_io_out_bits_qos[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_qos[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_qos[3] && p13_s1_io_out_bits_qos[3])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_qos[3] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[0] && p13_s1_io_out_bits_tgtID[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[1] && p13_s1_io_out_bits_tgtID[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[2] && p13_s1_io_out_bits_tgtID[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[3] && p13_s1_io_out_bits_tgtID[3])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[3] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[4] && p13_s1_io_out_bits_tgtID[4])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[4] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[5] && p13_s1_io_out_bits_tgtID[5])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[5] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[6] && p13_s1_io_out_bits_tgtID[6])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[6] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[7] && p13_s1_io_out_bits_tgtID[7])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[7] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[8] && p13_s1_io_out_bits_tgtID[8])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[8] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[9] && p13_s1_io_out_bits_tgtID[9])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[9] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tgtID[10] && p13_s1_io_out_bits_tgtID[10])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tgtID[10] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[0] && p13_s1_io_out_bits_srcID[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[1] && p13_s1_io_out_bits_srcID[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[2] && p13_s1_io_out_bits_srcID[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[3] && p13_s1_io_out_bits_srcID[3])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[3] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[4] && p13_s1_io_out_bits_srcID[4])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[4] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[5] && p13_s1_io_out_bits_srcID[5])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[5] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[6] && p13_s1_io_out_bits_srcID[6])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[6] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[7] && p13_s1_io_out_bits_srcID[7])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[7] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[8] && p13_s1_io_out_bits_srcID[8])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[8] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[9] && p13_s1_io_out_bits_srcID[9])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[9] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_srcID[10] && p13_s1_io_out_bits_srcID[10])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_srcID[10] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[0] && p13_s1_io_out_bits_txnID[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[1] && p13_s1_io_out_bits_txnID[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[2] && p13_s1_io_out_bits_txnID[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[3] && p13_s1_io_out_bits_txnID[3])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[3] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[4] && p13_s1_io_out_bits_txnID[4])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[4] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[5] && p13_s1_io_out_bits_txnID[5])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[5] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[6] && p13_s1_io_out_bits_txnID[6])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[6] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[7] && p13_s1_io_out_bits_txnID[7])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[7] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[8] && p13_s1_io_out_bits_txnID[8])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[8] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[9] && p13_s1_io_out_bits_txnID[9])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[9] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[10] && p13_s1_io_out_bits_txnID[10])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[10] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_txnID[11] && p13_s1_io_out_bits_txnID[11])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_txnID[11] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_opcode[0] && p13_s1_io_out_bits_opcode[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_opcode[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_opcode[1] && p13_s1_io_out_bits_opcode[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_opcode[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_opcode[2] && p13_s1_io_out_bits_opcode[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_opcode[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_opcode[3] && p13_s1_io_out_bits_opcode[3])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_opcode[3] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_opcode[4] && p13_s1_io_out_bits_opcode[4])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_opcode[4] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_respErr[0] && p13_s1_io_out_bits_respErr[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_respErr[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_respErr[1] && p13_s1_io_out_bits_respErr[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_respErr[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_resp[0] && p13_s1_io_out_bits_resp[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_resp[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_resp[1] && p13_s1_io_out_bits_resp[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_resp[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_resp[2] && p13_s1_io_out_bits_resp[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_resp[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_fwdState[0] && p13_s1_io_out_bits_fwdState[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_fwdState[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_fwdState[1] && p13_s1_io_out_bits_fwdState[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_fwdState[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_fwdState[2] && p13_s1_io_out_bits_fwdState[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_fwdState[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_cBusy[0] && p13_s1_io_out_bits_cBusy[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_cBusy[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_cBusy[1] && p13_s1_io_out_bits_cBusy[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_cBusy[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_cBusy[2] && p13_s1_io_out_bits_cBusy[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_cBusy[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[0] && p13_s1_io_out_bits_dbID[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[1] && p13_s1_io_out_bits_dbID[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[2] && p13_s1_io_out_bits_dbID[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[3] && p13_s1_io_out_bits_dbID[3])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[3] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[4] && p13_s1_io_out_bits_dbID[4])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[4] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[5] && p13_s1_io_out_bits_dbID[5])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[5] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[6] && p13_s1_io_out_bits_dbID[6])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[6] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[7] && p13_s1_io_out_bits_dbID[7])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[7] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[8] && p13_s1_io_out_bits_dbID[8])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[8] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[9] && p13_s1_io_out_bits_dbID[9])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[9] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[10] && p13_s1_io_out_bits_dbID[10])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[10] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_dbID[11] && p13_s1_io_out_bits_dbID[11])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_dbID[11] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_pCrdType[0] && p13_s1_io_out_bits_pCrdType[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_pCrdType[1] && p13_s1_io_out_bits_pCrdType[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_pCrdType[2] && p13_s1_io_out_bits_pCrdType[2])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_pCrdType[3] && p13_s1_io_out_bits_pCrdType[3])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tagOp[0] && p13_s1_io_out_bits_tagOp[0])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tagOp[0] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_tagOp[1] && p13_s1_io_out_bits_tagOp[1])) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_tagOp[1] 未见过 0 和 1"); end
    if (!(p13_s0_io_out_bits_traceTag && p13_s1_io_out_bits_traceTag)) begin cov_fail++; $display("[COV] Pipeline_13.io_out_bits_traceTag 未见过 0 和 1"); end
    $display("[ARM] Pipeline_13 armed_at=%0d", p13_armed_at);
    if (p13_armed_at < 0) begin cov_fail++; $display("[ARM] Pipeline_13 从未 arm"); end
    $display("[COV] Pipeline_13.enq = %0d", p13_cov_enq);
    if (p13_cov_enq < 100) begin cov_fail++; $display("[COV] Pipeline_13.enq < 100"); end
    $display("[COV] Pipeline_13.deq = %0d", p13_cov_deq);
    if (p13_cov_deq < 100) begin cov_fail++; $display("[COV] Pipeline_13.deq < 100"); end
    $display("[COV] Pipeline_13.backpressure = %0d", p13_cov_backpressure);
    if (p13_cov_backpressure < 100) begin cov_fail++; $display("[COV] Pipeline_13.backpressure < 100"); end
    $display("[COV] Pipeline_13.enq_deq_same = %0d", p13_cov_enq_deq_same);
    if (p13_cov_enq_deq_same < 100) begin cov_fail++; $display("[COV] Pipeline_13.enq_deq_same < 100"); end
    $display("[COV] Pipeline_13.full_refused = %0d", p13_cov_full_refused);
    if (p13_cov_full_refused < 100) begin cov_fail++; $display("[COV] Pipeline_13.full_refused < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule

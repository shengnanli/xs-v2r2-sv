// tb —— LCredit2Decoupled_2：L2 LinkMonitor 的 RXDAT 链路层接收端（非阻塞、15 信用）双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= LCredit2Decoupled_2 =================
  int unsigned lc_mode = 0;
  logic lc_reset;
  logic lc_io_in_flitv;
  logic [421:0] lc_io_in_flit;
  wire  lc_g_io_in_lcrdv, lc_i_io_in_lcrdv;
  logic lc_s0_io_in_lcrdv = '0, lc_s1_io_in_lcrdv = '0;
  logic lc_io_out_ready;
  wire  lc_g_io_out_valid, lc_i_io_out_valid;
  logic lc_s0_io_out_valid = '0, lc_s1_io_out_valid = '0;
  wire  [3:0] lc_g_io_out_bits_qos, lc_i_io_out_bits_qos;
  logic [3:0] lc_s0_io_out_bits_qos = '0, lc_s1_io_out_bits_qos = '0;
  wire  [10:0] lc_g_io_out_bits_tgtID, lc_i_io_out_bits_tgtID;
  logic [10:0] lc_s0_io_out_bits_tgtID = '0, lc_s1_io_out_bits_tgtID = '0;
  wire  [10:0] lc_g_io_out_bits_srcID, lc_i_io_out_bits_srcID;
  logic [10:0] lc_s0_io_out_bits_srcID = '0, lc_s1_io_out_bits_srcID = '0;
  wire  [11:0] lc_g_io_out_bits_txnID, lc_i_io_out_bits_txnID;
  logic [11:0] lc_s0_io_out_bits_txnID = '0, lc_s1_io_out_bits_txnID = '0;
  wire  [10:0] lc_g_io_out_bits_homeNID, lc_i_io_out_bits_homeNID;
  logic [10:0] lc_s0_io_out_bits_homeNID = '0, lc_s1_io_out_bits_homeNID = '0;
  wire  [3:0] lc_g_io_out_bits_opcode, lc_i_io_out_bits_opcode;
  logic [3:0] lc_s0_io_out_bits_opcode = '0, lc_s1_io_out_bits_opcode = '0;
  wire  [1:0] lc_g_io_out_bits_respErr, lc_i_io_out_bits_respErr;
  logic [1:0] lc_s0_io_out_bits_respErr = '0, lc_s1_io_out_bits_respErr = '0;
  wire  [2:0] lc_g_io_out_bits_resp, lc_i_io_out_bits_resp;
  logic [2:0] lc_s0_io_out_bits_resp = '0, lc_s1_io_out_bits_resp = '0;
  wire  [3:0] lc_g_io_out_bits_dataSource, lc_i_io_out_bits_dataSource;
  logic [3:0] lc_s0_io_out_bits_dataSource = '0, lc_s1_io_out_bits_dataSource = '0;
  wire  [2:0] lc_g_io_out_bits_cBusy, lc_i_io_out_bits_cBusy;
  logic [2:0] lc_s0_io_out_bits_cBusy = '0, lc_s1_io_out_bits_cBusy = '0;
  wire  [11:0] lc_g_io_out_bits_dbID, lc_i_io_out_bits_dbID;
  logic [11:0] lc_s0_io_out_bits_dbID = '0, lc_s1_io_out_bits_dbID = '0;
  wire  [1:0] lc_g_io_out_bits_ccID, lc_i_io_out_bits_ccID;
  logic [1:0] lc_s0_io_out_bits_ccID = '0, lc_s1_io_out_bits_ccID = '0;
  wire  [1:0] lc_g_io_out_bits_dataID, lc_i_io_out_bits_dataID;
  logic [1:0] lc_s0_io_out_bits_dataID = '0, lc_s1_io_out_bits_dataID = '0;
  wire  [1:0] lc_g_io_out_bits_tagOp, lc_i_io_out_bits_tagOp;
  logic [1:0] lc_s0_io_out_bits_tagOp = '0, lc_s1_io_out_bits_tagOp = '0;
  wire  [7:0] lc_g_io_out_bits_tag, lc_i_io_out_bits_tag;
  logic [7:0] lc_s0_io_out_bits_tag = '0, lc_s1_io_out_bits_tag = '0;
  wire  [1:0] lc_g_io_out_bits_tu, lc_i_io_out_bits_tu;
  logic [1:0] lc_s0_io_out_bits_tu = '0, lc_s1_io_out_bits_tu = '0;
  wire  lc_g_io_out_bits_traceTag, lc_i_io_out_bits_traceTag;
  logic lc_s0_io_out_bits_traceTag = '0, lc_s1_io_out_bits_traceTag = '0;
  wire  [3:0] lc_g_io_out_bits_rsvdc, lc_i_io_out_bits_rsvdc;
  logic [3:0] lc_s0_io_out_bits_rsvdc = '0, lc_s1_io_out_bits_rsvdc = '0;
  wire  [31:0] lc_g_io_out_bits_be, lc_i_io_out_bits_be;
  logic [31:0] lc_s0_io_out_bits_be = '0, lc_s1_io_out_bits_be = '0;
  wire  [255:0] lc_g_io_out_bits_data, lc_i_io_out_bits_data;
  logic [255:0] lc_s0_io_out_bits_data = '0, lc_s1_io_out_bits_data = '0;
  wire  [31:0] lc_g_io_out_bits_dataCheck, lc_i_io_out_bits_dataCheck;
  logic [31:0] lc_s0_io_out_bits_dataCheck = '0, lc_s1_io_out_bits_dataCheck = '0;
  wire  [3:0] lc_g_io_out_bits_poison, lc_i_io_out_bits_poison;
  logic [3:0] lc_s0_io_out_bits_poison = '0, lc_s1_io_out_bits_poison = '0;
  logic [1:0] lc_io_state_state;
  wire  lc_g_io_reclaimLCredit, lc_i_io_reclaimLCredit;
  logic lc_s0_io_reclaimLCredit = '0, lc_s1_io_reclaimLCredit = '0;
  int lc_cov_lcrdv = 0;
  int lc_cov_data_out = 0;
  int lc_cov_lcrd_return_dropped = 0;
  int lc_cov_pool_empty = 0;
  int lc_cov_reclaim = 0;
  logic [0:0] lc_armed = '0;
  int lc_armed_at = -1;
  LCredit2Decoupled_2 lc_u_gold (
    .clock(clk),
    .reset(lc_reset),
    .io_in_flitv(lc_io_in_flitv),
    .io_in_flit(lc_io_in_flit),
    .io_in_lcrdv(lc_g_io_in_lcrdv),
    .io_out_ready(lc_io_out_ready),
    .io_out_valid(lc_g_io_out_valid),
    .io_out_bits_qos(lc_g_io_out_bits_qos),
    .io_out_bits_tgtID(lc_g_io_out_bits_tgtID),
    .io_out_bits_srcID(lc_g_io_out_bits_srcID),
    .io_out_bits_txnID(lc_g_io_out_bits_txnID),
    .io_out_bits_homeNID(lc_g_io_out_bits_homeNID),
    .io_out_bits_opcode(lc_g_io_out_bits_opcode),
    .io_out_bits_respErr(lc_g_io_out_bits_respErr),
    .io_out_bits_resp(lc_g_io_out_bits_resp),
    .io_out_bits_dataSource(lc_g_io_out_bits_dataSource),
    .io_out_bits_cBusy(lc_g_io_out_bits_cBusy),
    .io_out_bits_dbID(lc_g_io_out_bits_dbID),
    .io_out_bits_ccID(lc_g_io_out_bits_ccID),
    .io_out_bits_dataID(lc_g_io_out_bits_dataID),
    .io_out_bits_tagOp(lc_g_io_out_bits_tagOp),
    .io_out_bits_tag(lc_g_io_out_bits_tag),
    .io_out_bits_tu(lc_g_io_out_bits_tu),
    .io_out_bits_traceTag(lc_g_io_out_bits_traceTag),
    .io_out_bits_rsvdc(lc_g_io_out_bits_rsvdc),
    .io_out_bits_be(lc_g_io_out_bits_be),
    .io_out_bits_data(lc_g_io_out_bits_data),
    .io_out_bits_dataCheck(lc_g_io_out_bits_dataCheck),
    .io_out_bits_poison(lc_g_io_out_bits_poison),
    .io_state_state(lc_io_state_state),
    .io_reclaimLCredit(lc_g_io_reclaimLCredit)
  );
  LCredit2Decoupled_2_xs lc_u_impl (
    .clock(clk),
    .reset(lc_reset),
    .io_in_flitv(lc_io_in_flitv),
    .io_in_flit(lc_io_in_flit),
    .io_in_lcrdv(lc_i_io_in_lcrdv),
    .io_out_ready(lc_io_out_ready),
    .io_out_valid(lc_i_io_out_valid),
    .io_out_bits_qos(lc_i_io_out_bits_qos),
    .io_out_bits_tgtID(lc_i_io_out_bits_tgtID),
    .io_out_bits_srcID(lc_i_io_out_bits_srcID),
    .io_out_bits_txnID(lc_i_io_out_bits_txnID),
    .io_out_bits_homeNID(lc_i_io_out_bits_homeNID),
    .io_out_bits_opcode(lc_i_io_out_bits_opcode),
    .io_out_bits_respErr(lc_i_io_out_bits_respErr),
    .io_out_bits_resp(lc_i_io_out_bits_resp),
    .io_out_bits_dataSource(lc_i_io_out_bits_dataSource),
    .io_out_bits_cBusy(lc_i_io_out_bits_cBusy),
    .io_out_bits_dbID(lc_i_io_out_bits_dbID),
    .io_out_bits_ccID(lc_i_io_out_bits_ccID),
    .io_out_bits_dataID(lc_i_io_out_bits_dataID),
    .io_out_bits_tagOp(lc_i_io_out_bits_tagOp),
    .io_out_bits_tag(lc_i_io_out_bits_tag),
    .io_out_bits_tu(lc_i_io_out_bits_tu),
    .io_out_bits_traceTag(lc_i_io_out_bits_traceTag),
    .io_out_bits_rsvdc(lc_i_io_out_bits_rsvdc),
    .io_out_bits_be(lc_i_io_out_bits_be),
    .io_out_bits_data(lc_i_io_out_bits_data),
    .io_out_bits_dataCheck(lc_i_io_out_bits_dataCheck),
    .io_out_bits_poison(lc_i_io_out_bits_poison),
    .io_state_state(lc_io_state_state),
    .io_reclaimLCredit(lc_i_io_reclaimLCredit)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) lc_mode = $urandom_range(0, 15);
      lc_io_in_flitv = 1'($urandom);
      lc_io_in_flit = 422'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      lc_io_out_ready = 1'($urandom);
      lc_io_state_state = 2'($urandom);
      lc_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_lc
        if ($urandom_range(0, 3) != 0) lc_io_state_state = 2'h2;
        if ($urandom_range(0, 3) == 0) lc_io_in_flit[52:49] = 4'h0;
        case (lc_mode % 3)
          0: lc_io_in_flitv = ($urandom_range(0, 3) == 0);
          1: lc_io_in_flitv = ($urandom_range(0, 3) != 0);
          default: ;
        endcase
        lc_io_out_ready = ($urandom_range(0, 3) != 0);
      end
      #4;
      lc_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&lc_armed)) begin
        checks++;
        if (lc_g_io_in_lcrdv !== lc_i_io_in_lcrdv) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_in_lcrdv g=%h i=%h", cyc, lc_g_io_in_lcrdv, lc_i_io_in_lcrdv);
        end
        lc_s1_io_in_lcrdv |= lc_g_io_in_lcrdv;
        lc_s0_io_in_lcrdv |= ~lc_g_io_in_lcrdv;
        checks++;
        if (lc_g_io_out_valid !== lc_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_valid g=%h i=%h", cyc, lc_g_io_out_valid, lc_i_io_out_valid);
        end
        lc_s1_io_out_valid |= lc_g_io_out_valid;
        lc_s0_io_out_valid |= ~lc_g_io_out_valid;
        checks++;
        if (lc_g_io_out_bits_qos !== lc_i_io_out_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_qos g=%h i=%h", cyc, lc_g_io_out_bits_qos, lc_i_io_out_bits_qos);
        end
        lc_s1_io_out_bits_qos |= lc_g_io_out_bits_qos;
        lc_s0_io_out_bits_qos |= ~lc_g_io_out_bits_qos;
        checks++;
        if (lc_g_io_out_bits_tgtID !== lc_i_io_out_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_tgtID g=%h i=%h", cyc, lc_g_io_out_bits_tgtID, lc_i_io_out_bits_tgtID);
        end
        lc_s1_io_out_bits_tgtID |= lc_g_io_out_bits_tgtID;
        lc_s0_io_out_bits_tgtID |= ~lc_g_io_out_bits_tgtID;
        checks++;
        if (lc_g_io_out_bits_srcID !== lc_i_io_out_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_srcID g=%h i=%h", cyc, lc_g_io_out_bits_srcID, lc_i_io_out_bits_srcID);
        end
        lc_s1_io_out_bits_srcID |= lc_g_io_out_bits_srcID;
        lc_s0_io_out_bits_srcID |= ~lc_g_io_out_bits_srcID;
        checks++;
        if (lc_g_io_out_bits_txnID !== lc_i_io_out_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_txnID g=%h i=%h", cyc, lc_g_io_out_bits_txnID, lc_i_io_out_bits_txnID);
        end
        lc_s1_io_out_bits_txnID |= lc_g_io_out_bits_txnID;
        lc_s0_io_out_bits_txnID |= ~lc_g_io_out_bits_txnID;
        checks++;
        if (lc_g_io_out_bits_homeNID !== lc_i_io_out_bits_homeNID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_homeNID g=%h i=%h", cyc, lc_g_io_out_bits_homeNID, lc_i_io_out_bits_homeNID);
        end
        lc_s1_io_out_bits_homeNID |= lc_g_io_out_bits_homeNID;
        lc_s0_io_out_bits_homeNID |= ~lc_g_io_out_bits_homeNID;
        checks++;
        if (lc_g_io_out_bits_opcode !== lc_i_io_out_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_opcode g=%h i=%h", cyc, lc_g_io_out_bits_opcode, lc_i_io_out_bits_opcode);
        end
        lc_s1_io_out_bits_opcode |= lc_g_io_out_bits_opcode;
        lc_s0_io_out_bits_opcode |= ~lc_g_io_out_bits_opcode;
        checks++;
        if (lc_g_io_out_bits_respErr !== lc_i_io_out_bits_respErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_respErr g=%h i=%h", cyc, lc_g_io_out_bits_respErr, lc_i_io_out_bits_respErr);
        end
        lc_s1_io_out_bits_respErr |= lc_g_io_out_bits_respErr;
        lc_s0_io_out_bits_respErr |= ~lc_g_io_out_bits_respErr;
        checks++;
        if (lc_g_io_out_bits_resp !== lc_i_io_out_bits_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_resp g=%h i=%h", cyc, lc_g_io_out_bits_resp, lc_i_io_out_bits_resp);
        end
        lc_s1_io_out_bits_resp |= lc_g_io_out_bits_resp;
        lc_s0_io_out_bits_resp |= ~lc_g_io_out_bits_resp;
        checks++;
        if (lc_g_io_out_bits_dataSource !== lc_i_io_out_bits_dataSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_dataSource g=%h i=%h", cyc, lc_g_io_out_bits_dataSource, lc_i_io_out_bits_dataSource);
        end
        lc_s1_io_out_bits_dataSource |= lc_g_io_out_bits_dataSource;
        lc_s0_io_out_bits_dataSource |= ~lc_g_io_out_bits_dataSource;
        checks++;
        if (lc_g_io_out_bits_cBusy !== lc_i_io_out_bits_cBusy) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_cBusy g=%h i=%h", cyc, lc_g_io_out_bits_cBusy, lc_i_io_out_bits_cBusy);
        end
        lc_s1_io_out_bits_cBusy |= lc_g_io_out_bits_cBusy;
        lc_s0_io_out_bits_cBusy |= ~lc_g_io_out_bits_cBusy;
        checks++;
        if (lc_g_io_out_bits_dbID !== lc_i_io_out_bits_dbID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_dbID g=%h i=%h", cyc, lc_g_io_out_bits_dbID, lc_i_io_out_bits_dbID);
        end
        lc_s1_io_out_bits_dbID |= lc_g_io_out_bits_dbID;
        lc_s0_io_out_bits_dbID |= ~lc_g_io_out_bits_dbID;
        checks++;
        if (lc_g_io_out_bits_ccID !== lc_i_io_out_bits_ccID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_ccID g=%h i=%h", cyc, lc_g_io_out_bits_ccID, lc_i_io_out_bits_ccID);
        end
        lc_s1_io_out_bits_ccID |= lc_g_io_out_bits_ccID;
        lc_s0_io_out_bits_ccID |= ~lc_g_io_out_bits_ccID;
        checks++;
        if (lc_g_io_out_bits_dataID !== lc_i_io_out_bits_dataID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_dataID g=%h i=%h", cyc, lc_g_io_out_bits_dataID, lc_i_io_out_bits_dataID);
        end
        lc_s1_io_out_bits_dataID |= lc_g_io_out_bits_dataID;
        lc_s0_io_out_bits_dataID |= ~lc_g_io_out_bits_dataID;
        checks++;
        if (lc_g_io_out_bits_tagOp !== lc_i_io_out_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_tagOp g=%h i=%h", cyc, lc_g_io_out_bits_tagOp, lc_i_io_out_bits_tagOp);
        end
        lc_s1_io_out_bits_tagOp |= lc_g_io_out_bits_tagOp;
        lc_s0_io_out_bits_tagOp |= ~lc_g_io_out_bits_tagOp;
        checks++;
        if (lc_g_io_out_bits_tag !== lc_i_io_out_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_tag g=%h i=%h", cyc, lc_g_io_out_bits_tag, lc_i_io_out_bits_tag);
        end
        lc_s1_io_out_bits_tag |= lc_g_io_out_bits_tag;
        lc_s0_io_out_bits_tag |= ~lc_g_io_out_bits_tag;
        checks++;
        if (lc_g_io_out_bits_tu !== lc_i_io_out_bits_tu) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_tu g=%h i=%h", cyc, lc_g_io_out_bits_tu, lc_i_io_out_bits_tu);
        end
        lc_s1_io_out_bits_tu |= lc_g_io_out_bits_tu;
        lc_s0_io_out_bits_tu |= ~lc_g_io_out_bits_tu;
        checks++;
        if (lc_g_io_out_bits_traceTag !== lc_i_io_out_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_traceTag g=%h i=%h", cyc, lc_g_io_out_bits_traceTag, lc_i_io_out_bits_traceTag);
        end
        lc_s1_io_out_bits_traceTag |= lc_g_io_out_bits_traceTag;
        lc_s0_io_out_bits_traceTag |= ~lc_g_io_out_bits_traceTag;
        checks++;
        if (lc_g_io_out_bits_rsvdc !== lc_i_io_out_bits_rsvdc) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_rsvdc g=%h i=%h", cyc, lc_g_io_out_bits_rsvdc, lc_i_io_out_bits_rsvdc);
        end
        lc_s1_io_out_bits_rsvdc |= lc_g_io_out_bits_rsvdc;
        lc_s0_io_out_bits_rsvdc |= ~lc_g_io_out_bits_rsvdc;
        checks++;
        if (lc_g_io_out_bits_be !== lc_i_io_out_bits_be) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_be g=%h i=%h", cyc, lc_g_io_out_bits_be, lc_i_io_out_bits_be);
        end
        lc_s1_io_out_bits_be |= lc_g_io_out_bits_be;
        lc_s0_io_out_bits_be |= ~lc_g_io_out_bits_be;
        checks++;
        if (lc_g_io_out_bits_data !== lc_i_io_out_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_data g=%h i=%h", cyc, lc_g_io_out_bits_data, lc_i_io_out_bits_data);
        end
        lc_s1_io_out_bits_data |= lc_g_io_out_bits_data;
        lc_s0_io_out_bits_data |= ~lc_g_io_out_bits_data;
        checks++;
        if (lc_g_io_out_bits_dataCheck !== lc_i_io_out_bits_dataCheck) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_dataCheck g=%h i=%h", cyc, lc_g_io_out_bits_dataCheck, lc_i_io_out_bits_dataCheck);
        end
        lc_s1_io_out_bits_dataCheck |= lc_g_io_out_bits_dataCheck;
        lc_s0_io_out_bits_dataCheck |= ~lc_g_io_out_bits_dataCheck;
        checks++;
        if (lc_g_io_out_bits_poison !== lc_i_io_out_bits_poison) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_out_bits_poison g=%h i=%h", cyc, lc_g_io_out_bits_poison, lc_i_io_out_bits_poison);
        end
        lc_s1_io_out_bits_poison |= lc_g_io_out_bits_poison;
        lc_s0_io_out_bits_poison |= ~lc_g_io_out_bits_poison;
        checks++;
        if (lc_g_io_reclaimLCredit !== lc_i_io_reclaimLCredit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_2.io_reclaimLCredit g=%h i=%h", cyc, lc_g_io_reclaimLCredit, lc_i_io_reclaimLCredit);
        end
        lc_s1_io_reclaimLCredit |= lc_g_io_reclaimLCredit;
        lc_s0_io_reclaimLCredit |= ~lc_g_io_reclaimLCredit;
        if (lc_g_io_in_lcrdv) lc_cov_lcrdv++;
        if (lc_g_io_out_valid && lc_io_out_ready) lc_cov_data_out++;
        if (lc_io_in_flitv && lc_io_in_flit[52:49] == 4'h0 && !lc_g_io_reclaimLCredit) lc_cov_lcrd_return_dropped++;
        if (lc_u_gold.lcreditPool == 5'h0) lc_cov_pool_empty++;
        if (lc_g_io_reclaimLCredit) lc_cov_reclaim++;
      end
      if (lc_armed_at < 0 && (&lc_armed)) lc_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(lc_s0_io_in_lcrdv && lc_s1_io_in_lcrdv)) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_in_lcrdv 未见过 0 和 1"); end
    if (!(lc_s0_io_out_valid && lc_s1_io_out_valid)) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_valid 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_qos[0] && lc_s1_io_out_bits_qos[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_qos[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_qos[1] && lc_s1_io_out_bits_qos[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_qos[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_qos[2] && lc_s1_io_out_bits_qos[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_qos[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_qos[3] && lc_s1_io_out_bits_qos[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_qos[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[0] && lc_s1_io_out_bits_tgtID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[1] && lc_s1_io_out_bits_tgtID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[2] && lc_s1_io_out_bits_tgtID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[3] && lc_s1_io_out_bits_tgtID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[4] && lc_s1_io_out_bits_tgtID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[5] && lc_s1_io_out_bits_tgtID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[6] && lc_s1_io_out_bits_tgtID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[7] && lc_s1_io_out_bits_tgtID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[8] && lc_s1_io_out_bits_tgtID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[9] && lc_s1_io_out_bits_tgtID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[10] && lc_s1_io_out_bits_tgtID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tgtID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[0] && lc_s1_io_out_bits_srcID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[1] && lc_s1_io_out_bits_srcID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[2] && lc_s1_io_out_bits_srcID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[3] && lc_s1_io_out_bits_srcID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[4] && lc_s1_io_out_bits_srcID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[5] && lc_s1_io_out_bits_srcID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[6] && lc_s1_io_out_bits_srcID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[7] && lc_s1_io_out_bits_srcID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[8] && lc_s1_io_out_bits_srcID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[9] && lc_s1_io_out_bits_srcID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[10] && lc_s1_io_out_bits_srcID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_srcID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[0] && lc_s1_io_out_bits_txnID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[1] && lc_s1_io_out_bits_txnID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[2] && lc_s1_io_out_bits_txnID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[3] && lc_s1_io_out_bits_txnID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[4] && lc_s1_io_out_bits_txnID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[5] && lc_s1_io_out_bits_txnID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[6] && lc_s1_io_out_bits_txnID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[7] && lc_s1_io_out_bits_txnID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[8] && lc_s1_io_out_bits_txnID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[9] && lc_s1_io_out_bits_txnID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[10] && lc_s1_io_out_bits_txnID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[11] && lc_s1_io_out_bits_txnID[11])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_txnID[11] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[0] && lc_s1_io_out_bits_homeNID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[1] && lc_s1_io_out_bits_homeNID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[2] && lc_s1_io_out_bits_homeNID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[3] && lc_s1_io_out_bits_homeNID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[4] && lc_s1_io_out_bits_homeNID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[5] && lc_s1_io_out_bits_homeNID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[6] && lc_s1_io_out_bits_homeNID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[7] && lc_s1_io_out_bits_homeNID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[8] && lc_s1_io_out_bits_homeNID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[9] && lc_s1_io_out_bits_homeNID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_homeNID[10] && lc_s1_io_out_bits_homeNID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_homeNID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[0] && lc_s1_io_out_bits_opcode[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_opcode[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[1] && lc_s1_io_out_bits_opcode[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_opcode[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[2] && lc_s1_io_out_bits_opcode[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_opcode[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[3] && lc_s1_io_out_bits_opcode[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_opcode[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_respErr[0] && lc_s1_io_out_bits_respErr[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_respErr[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_respErr[1] && lc_s1_io_out_bits_respErr[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_respErr[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_resp[0] && lc_s1_io_out_bits_resp[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_resp[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_resp[1] && lc_s1_io_out_bits_resp[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_resp[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_resp[2] && lc_s1_io_out_bits_resp[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_resp[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataSource[0] && lc_s1_io_out_bits_dataSource[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataSource[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataSource[1] && lc_s1_io_out_bits_dataSource[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataSource[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataSource[2] && lc_s1_io_out_bits_dataSource[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataSource[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataSource[3] && lc_s1_io_out_bits_dataSource[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataSource[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_cBusy[0] && lc_s1_io_out_bits_cBusy[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_cBusy[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_cBusy[1] && lc_s1_io_out_bits_cBusy[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_cBusy[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_cBusy[2] && lc_s1_io_out_bits_cBusy[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_cBusy[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[0] && lc_s1_io_out_bits_dbID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[1] && lc_s1_io_out_bits_dbID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[2] && lc_s1_io_out_bits_dbID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[3] && lc_s1_io_out_bits_dbID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[4] && lc_s1_io_out_bits_dbID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[5] && lc_s1_io_out_bits_dbID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[6] && lc_s1_io_out_bits_dbID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[7] && lc_s1_io_out_bits_dbID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[8] && lc_s1_io_out_bits_dbID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[9] && lc_s1_io_out_bits_dbID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[10] && lc_s1_io_out_bits_dbID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[11] && lc_s1_io_out_bits_dbID[11])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dbID[11] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_ccID[0] && lc_s1_io_out_bits_ccID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_ccID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_ccID[1] && lc_s1_io_out_bits_ccID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_ccID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataID[0] && lc_s1_io_out_bits_dataID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataID[1] && lc_s1_io_out_bits_dataID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tagOp[0] && lc_s1_io_out_bits_tagOp[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tagOp[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tagOp[1] && lc_s1_io_out_bits_tagOp[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tagOp[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tag[0] && lc_s1_io_out_bits_tag[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tag[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tag[1] && lc_s1_io_out_bits_tag[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tag[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tag[2] && lc_s1_io_out_bits_tag[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tag[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tag[3] && lc_s1_io_out_bits_tag[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tag[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tag[4] && lc_s1_io_out_bits_tag[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tag[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tag[5] && lc_s1_io_out_bits_tag[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tag[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tag[6] && lc_s1_io_out_bits_tag[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tag[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tag[7] && lc_s1_io_out_bits_tag[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tag[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tu[0] && lc_s1_io_out_bits_tu[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tu[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tu[1] && lc_s1_io_out_bits_tu[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_tu[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_traceTag && lc_s1_io_out_bits_traceTag)) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_traceTag 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_rsvdc[0] && lc_s1_io_out_bits_rsvdc[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_rsvdc[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_rsvdc[1] && lc_s1_io_out_bits_rsvdc[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_rsvdc[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_rsvdc[2] && lc_s1_io_out_bits_rsvdc[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_rsvdc[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_rsvdc[3] && lc_s1_io_out_bits_rsvdc[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_rsvdc[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[0] && lc_s1_io_out_bits_be[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[1] && lc_s1_io_out_bits_be[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[2] && lc_s1_io_out_bits_be[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[3] && lc_s1_io_out_bits_be[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[4] && lc_s1_io_out_bits_be[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[5] && lc_s1_io_out_bits_be[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[6] && lc_s1_io_out_bits_be[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[7] && lc_s1_io_out_bits_be[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[8] && lc_s1_io_out_bits_be[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[9] && lc_s1_io_out_bits_be[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[10] && lc_s1_io_out_bits_be[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[11] && lc_s1_io_out_bits_be[11])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[11] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[12] && lc_s1_io_out_bits_be[12])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[12] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[13] && lc_s1_io_out_bits_be[13])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[13] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[14] && lc_s1_io_out_bits_be[14])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[14] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[15] && lc_s1_io_out_bits_be[15])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[15] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[16] && lc_s1_io_out_bits_be[16])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[16] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[17] && lc_s1_io_out_bits_be[17])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[17] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[18] && lc_s1_io_out_bits_be[18])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[18] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[19] && lc_s1_io_out_bits_be[19])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[19] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[20] && lc_s1_io_out_bits_be[20])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[20] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[21] && lc_s1_io_out_bits_be[21])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[21] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[22] && lc_s1_io_out_bits_be[22])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[22] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[23] && lc_s1_io_out_bits_be[23])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[23] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[24] && lc_s1_io_out_bits_be[24])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[24] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[25] && lc_s1_io_out_bits_be[25])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[25] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[26] && lc_s1_io_out_bits_be[26])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[26] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[27] && lc_s1_io_out_bits_be[27])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[27] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[28] && lc_s1_io_out_bits_be[28])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[28] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[29] && lc_s1_io_out_bits_be[29])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[29] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[30] && lc_s1_io_out_bits_be[30])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[30] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_be[31] && lc_s1_io_out_bits_be[31])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_be[31] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[0] && lc_s1_io_out_bits_data[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[1] && lc_s1_io_out_bits_data[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[2] && lc_s1_io_out_bits_data[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[3] && lc_s1_io_out_bits_data[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[4] && lc_s1_io_out_bits_data[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[5] && lc_s1_io_out_bits_data[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[6] && lc_s1_io_out_bits_data[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[7] && lc_s1_io_out_bits_data[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[8] && lc_s1_io_out_bits_data[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[9] && lc_s1_io_out_bits_data[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[10] && lc_s1_io_out_bits_data[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[11] && lc_s1_io_out_bits_data[11])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[11] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[12] && lc_s1_io_out_bits_data[12])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[12] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[13] && lc_s1_io_out_bits_data[13])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[13] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[14] && lc_s1_io_out_bits_data[14])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[14] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[15] && lc_s1_io_out_bits_data[15])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[15] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[16] && lc_s1_io_out_bits_data[16])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[16] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[17] && lc_s1_io_out_bits_data[17])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[17] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[18] && lc_s1_io_out_bits_data[18])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[18] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[19] && lc_s1_io_out_bits_data[19])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[19] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[20] && lc_s1_io_out_bits_data[20])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[20] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[21] && lc_s1_io_out_bits_data[21])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[21] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[22] && lc_s1_io_out_bits_data[22])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[22] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[23] && lc_s1_io_out_bits_data[23])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[23] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[24] && lc_s1_io_out_bits_data[24])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[24] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[25] && lc_s1_io_out_bits_data[25])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[25] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[26] && lc_s1_io_out_bits_data[26])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[26] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[27] && lc_s1_io_out_bits_data[27])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[27] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[28] && lc_s1_io_out_bits_data[28])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[28] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[29] && lc_s1_io_out_bits_data[29])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[29] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[30] && lc_s1_io_out_bits_data[30])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[30] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[31] && lc_s1_io_out_bits_data[31])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[31] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[32] && lc_s1_io_out_bits_data[32])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[32] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[33] && lc_s1_io_out_bits_data[33])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[33] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[34] && lc_s1_io_out_bits_data[34])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[34] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[35] && lc_s1_io_out_bits_data[35])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[35] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[36] && lc_s1_io_out_bits_data[36])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[36] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[37] && lc_s1_io_out_bits_data[37])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[37] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[38] && lc_s1_io_out_bits_data[38])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[38] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[39] && lc_s1_io_out_bits_data[39])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[39] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[40] && lc_s1_io_out_bits_data[40])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[40] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[41] && lc_s1_io_out_bits_data[41])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[41] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[42] && lc_s1_io_out_bits_data[42])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[42] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[43] && lc_s1_io_out_bits_data[43])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[43] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[44] && lc_s1_io_out_bits_data[44])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[44] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[45] && lc_s1_io_out_bits_data[45])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[45] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[46] && lc_s1_io_out_bits_data[46])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[46] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[47] && lc_s1_io_out_bits_data[47])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[47] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[48] && lc_s1_io_out_bits_data[48])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[48] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[49] && lc_s1_io_out_bits_data[49])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[49] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[50] && lc_s1_io_out_bits_data[50])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[50] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[51] && lc_s1_io_out_bits_data[51])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[51] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[52] && lc_s1_io_out_bits_data[52])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[52] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[53] && lc_s1_io_out_bits_data[53])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[53] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[54] && lc_s1_io_out_bits_data[54])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[54] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[55] && lc_s1_io_out_bits_data[55])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[55] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[56] && lc_s1_io_out_bits_data[56])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[56] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[57] && lc_s1_io_out_bits_data[57])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[57] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[58] && lc_s1_io_out_bits_data[58])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[58] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[59] && lc_s1_io_out_bits_data[59])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[59] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[60] && lc_s1_io_out_bits_data[60])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[60] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[61] && lc_s1_io_out_bits_data[61])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[61] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[62] && lc_s1_io_out_bits_data[62])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[62] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[63] && lc_s1_io_out_bits_data[63])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[63] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[64] && lc_s1_io_out_bits_data[64])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[64] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[65] && lc_s1_io_out_bits_data[65])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[65] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[66] && lc_s1_io_out_bits_data[66])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[66] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[67] && lc_s1_io_out_bits_data[67])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[67] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[68] && lc_s1_io_out_bits_data[68])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[68] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[69] && lc_s1_io_out_bits_data[69])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[69] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[70] && lc_s1_io_out_bits_data[70])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[70] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[71] && lc_s1_io_out_bits_data[71])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[71] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[72] && lc_s1_io_out_bits_data[72])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[72] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[73] && lc_s1_io_out_bits_data[73])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[73] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[74] && lc_s1_io_out_bits_data[74])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[74] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[75] && lc_s1_io_out_bits_data[75])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[75] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[76] && lc_s1_io_out_bits_data[76])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[76] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[77] && lc_s1_io_out_bits_data[77])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[77] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[78] && lc_s1_io_out_bits_data[78])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[78] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[79] && lc_s1_io_out_bits_data[79])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[79] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[80] && lc_s1_io_out_bits_data[80])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[80] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[81] && lc_s1_io_out_bits_data[81])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[81] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[82] && lc_s1_io_out_bits_data[82])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[82] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[83] && lc_s1_io_out_bits_data[83])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[83] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[84] && lc_s1_io_out_bits_data[84])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[84] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[85] && lc_s1_io_out_bits_data[85])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[85] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[86] && lc_s1_io_out_bits_data[86])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[86] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[87] && lc_s1_io_out_bits_data[87])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[87] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[88] && lc_s1_io_out_bits_data[88])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[88] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[89] && lc_s1_io_out_bits_data[89])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[89] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[90] && lc_s1_io_out_bits_data[90])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[90] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[91] && lc_s1_io_out_bits_data[91])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[91] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[92] && lc_s1_io_out_bits_data[92])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[92] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[93] && lc_s1_io_out_bits_data[93])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[93] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[94] && lc_s1_io_out_bits_data[94])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[94] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[95] && lc_s1_io_out_bits_data[95])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[95] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[96] && lc_s1_io_out_bits_data[96])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[96] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[97] && lc_s1_io_out_bits_data[97])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[97] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[98] && lc_s1_io_out_bits_data[98])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[98] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[99] && lc_s1_io_out_bits_data[99])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[99] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[100] && lc_s1_io_out_bits_data[100])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[100] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[101] && lc_s1_io_out_bits_data[101])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[101] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[102] && lc_s1_io_out_bits_data[102])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[102] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[103] && lc_s1_io_out_bits_data[103])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[103] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[104] && lc_s1_io_out_bits_data[104])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[104] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[105] && lc_s1_io_out_bits_data[105])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[105] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[106] && lc_s1_io_out_bits_data[106])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[106] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[107] && lc_s1_io_out_bits_data[107])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[107] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[108] && lc_s1_io_out_bits_data[108])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[108] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[109] && lc_s1_io_out_bits_data[109])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[109] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[110] && lc_s1_io_out_bits_data[110])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[110] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[111] && lc_s1_io_out_bits_data[111])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[111] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[112] && lc_s1_io_out_bits_data[112])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[112] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[113] && lc_s1_io_out_bits_data[113])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[113] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[114] && lc_s1_io_out_bits_data[114])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[114] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[115] && lc_s1_io_out_bits_data[115])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[115] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[116] && lc_s1_io_out_bits_data[116])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[116] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[117] && lc_s1_io_out_bits_data[117])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[117] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[118] && lc_s1_io_out_bits_data[118])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[118] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[119] && lc_s1_io_out_bits_data[119])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[119] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[120] && lc_s1_io_out_bits_data[120])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[120] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[121] && lc_s1_io_out_bits_data[121])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[121] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[122] && lc_s1_io_out_bits_data[122])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[122] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[123] && lc_s1_io_out_bits_data[123])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[123] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[124] && lc_s1_io_out_bits_data[124])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[124] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[125] && lc_s1_io_out_bits_data[125])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[125] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[126] && lc_s1_io_out_bits_data[126])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[126] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[127] && lc_s1_io_out_bits_data[127])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[127] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[128] && lc_s1_io_out_bits_data[128])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[128] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[129] && lc_s1_io_out_bits_data[129])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[129] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[130] && lc_s1_io_out_bits_data[130])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[130] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[131] && lc_s1_io_out_bits_data[131])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[131] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[132] && lc_s1_io_out_bits_data[132])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[132] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[133] && lc_s1_io_out_bits_data[133])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[133] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[134] && lc_s1_io_out_bits_data[134])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[134] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[135] && lc_s1_io_out_bits_data[135])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[135] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[136] && lc_s1_io_out_bits_data[136])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[136] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[137] && lc_s1_io_out_bits_data[137])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[137] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[138] && lc_s1_io_out_bits_data[138])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[138] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[139] && lc_s1_io_out_bits_data[139])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[139] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[140] && lc_s1_io_out_bits_data[140])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[140] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[141] && lc_s1_io_out_bits_data[141])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[141] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[142] && lc_s1_io_out_bits_data[142])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[142] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[143] && lc_s1_io_out_bits_data[143])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[143] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[144] && lc_s1_io_out_bits_data[144])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[144] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[145] && lc_s1_io_out_bits_data[145])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[145] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[146] && lc_s1_io_out_bits_data[146])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[146] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[147] && lc_s1_io_out_bits_data[147])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[147] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[148] && lc_s1_io_out_bits_data[148])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[148] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[149] && lc_s1_io_out_bits_data[149])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[149] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[150] && lc_s1_io_out_bits_data[150])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[150] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[151] && lc_s1_io_out_bits_data[151])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[151] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[152] && lc_s1_io_out_bits_data[152])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[152] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[153] && lc_s1_io_out_bits_data[153])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[153] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[154] && lc_s1_io_out_bits_data[154])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[154] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[155] && lc_s1_io_out_bits_data[155])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[155] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[156] && lc_s1_io_out_bits_data[156])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[156] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[157] && lc_s1_io_out_bits_data[157])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[157] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[158] && lc_s1_io_out_bits_data[158])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[158] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[159] && lc_s1_io_out_bits_data[159])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[159] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[160] && lc_s1_io_out_bits_data[160])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[160] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[161] && lc_s1_io_out_bits_data[161])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[161] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[162] && lc_s1_io_out_bits_data[162])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[162] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[163] && lc_s1_io_out_bits_data[163])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[163] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[164] && lc_s1_io_out_bits_data[164])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[164] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[165] && lc_s1_io_out_bits_data[165])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[165] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[166] && lc_s1_io_out_bits_data[166])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[166] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[167] && lc_s1_io_out_bits_data[167])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[167] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[168] && lc_s1_io_out_bits_data[168])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[168] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[169] && lc_s1_io_out_bits_data[169])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[169] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[170] && lc_s1_io_out_bits_data[170])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[170] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[171] && lc_s1_io_out_bits_data[171])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[171] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[172] && lc_s1_io_out_bits_data[172])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[172] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[173] && lc_s1_io_out_bits_data[173])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[173] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[174] && lc_s1_io_out_bits_data[174])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[174] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[175] && lc_s1_io_out_bits_data[175])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[175] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[176] && lc_s1_io_out_bits_data[176])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[176] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[177] && lc_s1_io_out_bits_data[177])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[177] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[178] && lc_s1_io_out_bits_data[178])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[178] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[179] && lc_s1_io_out_bits_data[179])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[179] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[180] && lc_s1_io_out_bits_data[180])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[180] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[181] && lc_s1_io_out_bits_data[181])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[181] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[182] && lc_s1_io_out_bits_data[182])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[182] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[183] && lc_s1_io_out_bits_data[183])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[183] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[184] && lc_s1_io_out_bits_data[184])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[184] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[185] && lc_s1_io_out_bits_data[185])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[185] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[186] && lc_s1_io_out_bits_data[186])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[186] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[187] && lc_s1_io_out_bits_data[187])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[187] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[188] && lc_s1_io_out_bits_data[188])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[188] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[189] && lc_s1_io_out_bits_data[189])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[189] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[190] && lc_s1_io_out_bits_data[190])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[190] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[191] && lc_s1_io_out_bits_data[191])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[191] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[192] && lc_s1_io_out_bits_data[192])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[192] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[193] && lc_s1_io_out_bits_data[193])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[193] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[194] && lc_s1_io_out_bits_data[194])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[194] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[195] && lc_s1_io_out_bits_data[195])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[195] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[196] && lc_s1_io_out_bits_data[196])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[196] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[197] && lc_s1_io_out_bits_data[197])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[197] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[198] && lc_s1_io_out_bits_data[198])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[198] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[199] && lc_s1_io_out_bits_data[199])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[199] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[200] && lc_s1_io_out_bits_data[200])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[200] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[201] && lc_s1_io_out_bits_data[201])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[201] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[202] && lc_s1_io_out_bits_data[202])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[202] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[203] && lc_s1_io_out_bits_data[203])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[203] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[204] && lc_s1_io_out_bits_data[204])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[204] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[205] && lc_s1_io_out_bits_data[205])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[205] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[206] && lc_s1_io_out_bits_data[206])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[206] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[207] && lc_s1_io_out_bits_data[207])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[207] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[208] && lc_s1_io_out_bits_data[208])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[208] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[209] && lc_s1_io_out_bits_data[209])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[209] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[210] && lc_s1_io_out_bits_data[210])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[210] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[211] && lc_s1_io_out_bits_data[211])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[211] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[212] && lc_s1_io_out_bits_data[212])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[212] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[213] && lc_s1_io_out_bits_data[213])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[213] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[214] && lc_s1_io_out_bits_data[214])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[214] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[215] && lc_s1_io_out_bits_data[215])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[215] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[216] && lc_s1_io_out_bits_data[216])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[216] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[217] && lc_s1_io_out_bits_data[217])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[217] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[218] && lc_s1_io_out_bits_data[218])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[218] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[219] && lc_s1_io_out_bits_data[219])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[219] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[220] && lc_s1_io_out_bits_data[220])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[220] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[221] && lc_s1_io_out_bits_data[221])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[221] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[222] && lc_s1_io_out_bits_data[222])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[222] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[223] && lc_s1_io_out_bits_data[223])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[223] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[224] && lc_s1_io_out_bits_data[224])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[224] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[225] && lc_s1_io_out_bits_data[225])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[225] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[226] && lc_s1_io_out_bits_data[226])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[226] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[227] && lc_s1_io_out_bits_data[227])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[227] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[228] && lc_s1_io_out_bits_data[228])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[228] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[229] && lc_s1_io_out_bits_data[229])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[229] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[230] && lc_s1_io_out_bits_data[230])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[230] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[231] && lc_s1_io_out_bits_data[231])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[231] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[232] && lc_s1_io_out_bits_data[232])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[232] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[233] && lc_s1_io_out_bits_data[233])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[233] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[234] && lc_s1_io_out_bits_data[234])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[234] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[235] && lc_s1_io_out_bits_data[235])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[235] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[236] && lc_s1_io_out_bits_data[236])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[236] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[237] && lc_s1_io_out_bits_data[237])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[237] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[238] && lc_s1_io_out_bits_data[238])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[238] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[239] && lc_s1_io_out_bits_data[239])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[239] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[240] && lc_s1_io_out_bits_data[240])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[240] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[241] && lc_s1_io_out_bits_data[241])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[241] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[242] && lc_s1_io_out_bits_data[242])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[242] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[243] && lc_s1_io_out_bits_data[243])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[243] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[244] && lc_s1_io_out_bits_data[244])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[244] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[245] && lc_s1_io_out_bits_data[245])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[245] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[246] && lc_s1_io_out_bits_data[246])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[246] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[247] && lc_s1_io_out_bits_data[247])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[247] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[248] && lc_s1_io_out_bits_data[248])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[248] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[249] && lc_s1_io_out_bits_data[249])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[249] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[250] && lc_s1_io_out_bits_data[250])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[250] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[251] && lc_s1_io_out_bits_data[251])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[251] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[252] && lc_s1_io_out_bits_data[252])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[252] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[253] && lc_s1_io_out_bits_data[253])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[253] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[254] && lc_s1_io_out_bits_data[254])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[254] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_data[255] && lc_s1_io_out_bits_data[255])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_data[255] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[0] && lc_s1_io_out_bits_dataCheck[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[1] && lc_s1_io_out_bits_dataCheck[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[2] && lc_s1_io_out_bits_dataCheck[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[3] && lc_s1_io_out_bits_dataCheck[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[4] && lc_s1_io_out_bits_dataCheck[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[5] && lc_s1_io_out_bits_dataCheck[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[6] && lc_s1_io_out_bits_dataCheck[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[7] && lc_s1_io_out_bits_dataCheck[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[8] && lc_s1_io_out_bits_dataCheck[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[9] && lc_s1_io_out_bits_dataCheck[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[10] && lc_s1_io_out_bits_dataCheck[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[11] && lc_s1_io_out_bits_dataCheck[11])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[11] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[12] && lc_s1_io_out_bits_dataCheck[12])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[12] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[13] && lc_s1_io_out_bits_dataCheck[13])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[13] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[14] && lc_s1_io_out_bits_dataCheck[14])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[14] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[15] && lc_s1_io_out_bits_dataCheck[15])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[15] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[16] && lc_s1_io_out_bits_dataCheck[16])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[16] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[17] && lc_s1_io_out_bits_dataCheck[17])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[17] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[18] && lc_s1_io_out_bits_dataCheck[18])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[18] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[19] && lc_s1_io_out_bits_dataCheck[19])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[19] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[20] && lc_s1_io_out_bits_dataCheck[20])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[20] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[21] && lc_s1_io_out_bits_dataCheck[21])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[21] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[22] && lc_s1_io_out_bits_dataCheck[22])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[22] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[23] && lc_s1_io_out_bits_dataCheck[23])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[23] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[24] && lc_s1_io_out_bits_dataCheck[24])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[24] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[25] && lc_s1_io_out_bits_dataCheck[25])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[25] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[26] && lc_s1_io_out_bits_dataCheck[26])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[26] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[27] && lc_s1_io_out_bits_dataCheck[27])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[27] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[28] && lc_s1_io_out_bits_dataCheck[28])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[28] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[29] && lc_s1_io_out_bits_dataCheck[29])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[29] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[30] && lc_s1_io_out_bits_dataCheck[30])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[30] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dataCheck[31] && lc_s1_io_out_bits_dataCheck[31])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_dataCheck[31] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_poison[0] && lc_s1_io_out_bits_poison[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_poison[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_poison[1] && lc_s1_io_out_bits_poison[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_poison[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_poison[2] && lc_s1_io_out_bits_poison[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_poison[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_poison[3] && lc_s1_io_out_bits_poison[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_out_bits_poison[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_reclaimLCredit && lc_s1_io_reclaimLCredit)) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.io_reclaimLCredit 未见过 0 和 1"); end
    $display("[ARM] LCredit2Decoupled_2 armed_at=%0d", lc_armed_at);
    if (lc_armed_at < 0) begin cov_fail++; $display("[ARM] LCredit2Decoupled_2 从未 arm"); end
    $display("[COV] LCredit2Decoupled_2.lcrdv = %0d", lc_cov_lcrdv);
    if (lc_cov_lcrdv < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.lcrdv < 100"); end
    $display("[COV] LCredit2Decoupled_2.data_out = %0d", lc_cov_data_out);
    if (lc_cov_data_out < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.data_out < 100"); end
    $display("[COV] LCredit2Decoupled_2.lcrd_return_dropped = %0d", lc_cov_lcrd_return_dropped);
    if (lc_cov_lcrd_return_dropped < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.lcrd_return_dropped < 100"); end
    $display("[COV] LCredit2Decoupled_2.pool_empty = %0d", lc_cov_pool_empty);
    if (lc_cov_pool_empty < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.pool_empty < 100"); end
    $display("[COV] LCredit2Decoupled_2.reclaim = %0d", lc_cov_reclaim);
    if (lc_cov_reclaim < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_2.reclaim < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule

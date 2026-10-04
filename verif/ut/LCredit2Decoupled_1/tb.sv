// tb —— LCredit2Decoupled_1：L2 LinkMonitor 的 RXRSP 链路层接收端（非阻塞、15 信用）双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= LCredit2Decoupled_1 =================
  int unsigned lc_mode = 0;
  logic lc_reset;
  logic lc_io_in_flitv;
  logic [72:0] lc_io_in_flit;
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
  wire  [4:0] lc_g_io_out_bits_opcode, lc_i_io_out_bits_opcode;
  logic [4:0] lc_s0_io_out_bits_opcode = '0, lc_s1_io_out_bits_opcode = '0;
  wire  [1:0] lc_g_io_out_bits_respErr, lc_i_io_out_bits_respErr;
  logic [1:0] lc_s0_io_out_bits_respErr = '0, lc_s1_io_out_bits_respErr = '0;
  wire  [2:0] lc_g_io_out_bits_resp, lc_i_io_out_bits_resp;
  logic [2:0] lc_s0_io_out_bits_resp = '0, lc_s1_io_out_bits_resp = '0;
  wire  [2:0] lc_g_io_out_bits_fwdState, lc_i_io_out_bits_fwdState;
  logic [2:0] lc_s0_io_out_bits_fwdState = '0, lc_s1_io_out_bits_fwdState = '0;
  wire  [2:0] lc_g_io_out_bits_cBusy, lc_i_io_out_bits_cBusy;
  logic [2:0] lc_s0_io_out_bits_cBusy = '0, lc_s1_io_out_bits_cBusy = '0;
  wire  [11:0] lc_g_io_out_bits_dbID, lc_i_io_out_bits_dbID;
  logic [11:0] lc_s0_io_out_bits_dbID = '0, lc_s1_io_out_bits_dbID = '0;
  wire  [3:0] lc_g_io_out_bits_pCrdType, lc_i_io_out_bits_pCrdType;
  logic [3:0] lc_s0_io_out_bits_pCrdType = '0, lc_s1_io_out_bits_pCrdType = '0;
  wire  [1:0] lc_g_io_out_bits_tagOp, lc_i_io_out_bits_tagOp;
  logic [1:0] lc_s0_io_out_bits_tagOp = '0, lc_s1_io_out_bits_tagOp = '0;
  wire  lc_g_io_out_bits_traceTag, lc_i_io_out_bits_traceTag;
  logic lc_s0_io_out_bits_traceTag = '0, lc_s1_io_out_bits_traceTag = '0;
  logic [1:0] lc_io_state_state;
  wire  lc_g_io_reclaimLCredit, lc_i_io_reclaimLCredit;
  logic lc_s0_io_reclaimLCredit = '0, lc_s1_io_reclaimLCredit = '0;
  int lc_cov_lcrdv = 0;
  int lc_cov_rsp_out = 0;
  int lc_cov_lcrd_return_dropped = 0;
  int lc_cov_give_and_accept = 0;
  int lc_cov_pool_empty = 0;
  int lc_cov_reclaim = 0;
  logic [0:0] lc_armed = '0;
  int lc_armed_at = -1;
  LCredit2Decoupled_1 lc_u_gold (
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
    .io_out_bits_opcode(lc_g_io_out_bits_opcode),
    .io_out_bits_respErr(lc_g_io_out_bits_respErr),
    .io_out_bits_resp(lc_g_io_out_bits_resp),
    .io_out_bits_fwdState(lc_g_io_out_bits_fwdState),
    .io_out_bits_cBusy(lc_g_io_out_bits_cBusy),
    .io_out_bits_dbID(lc_g_io_out_bits_dbID),
    .io_out_bits_pCrdType(lc_g_io_out_bits_pCrdType),
    .io_out_bits_tagOp(lc_g_io_out_bits_tagOp),
    .io_out_bits_traceTag(lc_g_io_out_bits_traceTag),
    .io_state_state(lc_io_state_state),
    .io_reclaimLCredit(lc_g_io_reclaimLCredit)
  );
  LCredit2Decoupled_1_xs lc_u_impl (
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
    .io_out_bits_opcode(lc_i_io_out_bits_opcode),
    .io_out_bits_respErr(lc_i_io_out_bits_respErr),
    .io_out_bits_resp(lc_i_io_out_bits_resp),
    .io_out_bits_fwdState(lc_i_io_out_bits_fwdState),
    .io_out_bits_cBusy(lc_i_io_out_bits_cBusy),
    .io_out_bits_dbID(lc_i_io_out_bits_dbID),
    .io_out_bits_pCrdType(lc_i_io_out_bits_pCrdType),
    .io_out_bits_tagOp(lc_i_io_out_bits_tagOp),
    .io_out_bits_traceTag(lc_i_io_out_bits_traceTag),
    .io_state_state(lc_io_state_state),
    .io_reclaimLCredit(lc_i_io_reclaimLCredit)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) lc_mode = $urandom_range(0, 15);
      lc_io_in_flitv = 1'($urandom);
      lc_io_in_flit = 73'({$urandom, $urandom, $urandom});
      lc_io_out_ready = 1'($urandom);
      lc_io_state_state = 2'($urandom);
      lc_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_lc
        if ($urandom_range(0, 3) != 0) lc_io_state_state = 2'h2;
        case ($urandom_range(0, 7))
          0, 1: lc_io_in_flit[42:38] = 5'h0;
          2: lc_io_in_flit[42:38] = 5'h3;
          3: lc_io_in_flit[42:38] = 5'h7;
          default: ;
        endcase
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
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_in_lcrdv g=%h i=%h", cyc, lc_g_io_in_lcrdv, lc_i_io_in_lcrdv);
        end
        lc_s1_io_in_lcrdv |= lc_g_io_in_lcrdv;
        lc_s0_io_in_lcrdv |= ~lc_g_io_in_lcrdv;
        checks++;
        if (lc_g_io_out_valid !== lc_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_valid g=%h i=%h", cyc, lc_g_io_out_valid, lc_i_io_out_valid);
        end
        lc_s1_io_out_valid |= lc_g_io_out_valid;
        lc_s0_io_out_valid |= ~lc_g_io_out_valid;
        checks++;
        if (lc_g_io_out_bits_qos !== lc_i_io_out_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_qos g=%h i=%h", cyc, lc_g_io_out_bits_qos, lc_i_io_out_bits_qos);
        end
        lc_s1_io_out_bits_qos |= lc_g_io_out_bits_qos;
        lc_s0_io_out_bits_qos |= ~lc_g_io_out_bits_qos;
        checks++;
        if (lc_g_io_out_bits_tgtID !== lc_i_io_out_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_tgtID g=%h i=%h", cyc, lc_g_io_out_bits_tgtID, lc_i_io_out_bits_tgtID);
        end
        lc_s1_io_out_bits_tgtID |= lc_g_io_out_bits_tgtID;
        lc_s0_io_out_bits_tgtID |= ~lc_g_io_out_bits_tgtID;
        checks++;
        if (lc_g_io_out_bits_srcID !== lc_i_io_out_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_srcID g=%h i=%h", cyc, lc_g_io_out_bits_srcID, lc_i_io_out_bits_srcID);
        end
        lc_s1_io_out_bits_srcID |= lc_g_io_out_bits_srcID;
        lc_s0_io_out_bits_srcID |= ~lc_g_io_out_bits_srcID;
        checks++;
        if (lc_g_io_out_bits_txnID !== lc_i_io_out_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_txnID g=%h i=%h", cyc, lc_g_io_out_bits_txnID, lc_i_io_out_bits_txnID);
        end
        lc_s1_io_out_bits_txnID |= lc_g_io_out_bits_txnID;
        lc_s0_io_out_bits_txnID |= ~lc_g_io_out_bits_txnID;
        checks++;
        if (lc_g_io_out_bits_opcode !== lc_i_io_out_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_opcode g=%h i=%h", cyc, lc_g_io_out_bits_opcode, lc_i_io_out_bits_opcode);
        end
        lc_s1_io_out_bits_opcode |= lc_g_io_out_bits_opcode;
        lc_s0_io_out_bits_opcode |= ~lc_g_io_out_bits_opcode;
        checks++;
        if (lc_g_io_out_bits_respErr !== lc_i_io_out_bits_respErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_respErr g=%h i=%h", cyc, lc_g_io_out_bits_respErr, lc_i_io_out_bits_respErr);
        end
        lc_s1_io_out_bits_respErr |= lc_g_io_out_bits_respErr;
        lc_s0_io_out_bits_respErr |= ~lc_g_io_out_bits_respErr;
        checks++;
        if (lc_g_io_out_bits_resp !== lc_i_io_out_bits_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_resp g=%h i=%h", cyc, lc_g_io_out_bits_resp, lc_i_io_out_bits_resp);
        end
        lc_s1_io_out_bits_resp |= lc_g_io_out_bits_resp;
        lc_s0_io_out_bits_resp |= ~lc_g_io_out_bits_resp;
        checks++;
        if (lc_g_io_out_bits_fwdState !== lc_i_io_out_bits_fwdState) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_fwdState g=%h i=%h", cyc, lc_g_io_out_bits_fwdState, lc_i_io_out_bits_fwdState);
        end
        lc_s1_io_out_bits_fwdState |= lc_g_io_out_bits_fwdState;
        lc_s0_io_out_bits_fwdState |= ~lc_g_io_out_bits_fwdState;
        checks++;
        if (lc_g_io_out_bits_cBusy !== lc_i_io_out_bits_cBusy) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_cBusy g=%h i=%h", cyc, lc_g_io_out_bits_cBusy, lc_i_io_out_bits_cBusy);
        end
        lc_s1_io_out_bits_cBusy |= lc_g_io_out_bits_cBusy;
        lc_s0_io_out_bits_cBusy |= ~lc_g_io_out_bits_cBusy;
        checks++;
        if (lc_g_io_out_bits_dbID !== lc_i_io_out_bits_dbID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_dbID g=%h i=%h", cyc, lc_g_io_out_bits_dbID, lc_i_io_out_bits_dbID);
        end
        lc_s1_io_out_bits_dbID |= lc_g_io_out_bits_dbID;
        lc_s0_io_out_bits_dbID |= ~lc_g_io_out_bits_dbID;
        checks++;
        if (lc_g_io_out_bits_pCrdType !== lc_i_io_out_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_pCrdType g=%h i=%h", cyc, lc_g_io_out_bits_pCrdType, lc_i_io_out_bits_pCrdType);
        end
        lc_s1_io_out_bits_pCrdType |= lc_g_io_out_bits_pCrdType;
        lc_s0_io_out_bits_pCrdType |= ~lc_g_io_out_bits_pCrdType;
        checks++;
        if (lc_g_io_out_bits_tagOp !== lc_i_io_out_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_tagOp g=%h i=%h", cyc, lc_g_io_out_bits_tagOp, lc_i_io_out_bits_tagOp);
        end
        lc_s1_io_out_bits_tagOp |= lc_g_io_out_bits_tagOp;
        lc_s0_io_out_bits_tagOp |= ~lc_g_io_out_bits_tagOp;
        checks++;
        if (lc_g_io_out_bits_traceTag !== lc_i_io_out_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_out_bits_traceTag g=%h i=%h", cyc, lc_g_io_out_bits_traceTag, lc_i_io_out_bits_traceTag);
        end
        lc_s1_io_out_bits_traceTag |= lc_g_io_out_bits_traceTag;
        lc_s0_io_out_bits_traceTag |= ~lc_g_io_out_bits_traceTag;
        checks++;
        if (lc_g_io_reclaimLCredit !== lc_i_io_reclaimLCredit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LCredit2Decoupled_1.io_reclaimLCredit g=%h i=%h", cyc, lc_g_io_reclaimLCredit, lc_i_io_reclaimLCredit);
        end
        lc_s1_io_reclaimLCredit |= lc_g_io_reclaimLCredit;
        lc_s0_io_reclaimLCredit |= ~lc_g_io_reclaimLCredit;
        if (lc_g_io_in_lcrdv) lc_cov_lcrdv++;
        if (lc_g_io_out_valid && lc_io_out_ready) lc_cov_rsp_out++;
        if (lc_io_in_flitv && lc_io_in_flit[42:38] == 5'h0 && !lc_g_io_reclaimLCredit) lc_cov_lcrd_return_dropped++;
        if (lc_u_gold.lcreditOut && lc_u_gold.accept_probe) lc_cov_give_and_accept++;
        if (lc_u_gold.lcreditPool == 5'h0) lc_cov_pool_empty++;
        if (lc_g_io_reclaimLCredit) lc_cov_reclaim++;
      end
      if (lc_armed_at < 0 && (&lc_armed)) lc_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(lc_s0_io_in_lcrdv && lc_s1_io_in_lcrdv)) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_in_lcrdv 未见过 0 和 1"); end
    if (!(lc_s0_io_out_valid && lc_s1_io_out_valid)) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_valid 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_qos[0] && lc_s1_io_out_bits_qos[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_qos[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_qos[1] && lc_s1_io_out_bits_qos[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_qos[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_qos[2] && lc_s1_io_out_bits_qos[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_qos[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_qos[3] && lc_s1_io_out_bits_qos[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_qos[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[0] && lc_s1_io_out_bits_tgtID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[1] && lc_s1_io_out_bits_tgtID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[2] && lc_s1_io_out_bits_tgtID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[3] && lc_s1_io_out_bits_tgtID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[4] && lc_s1_io_out_bits_tgtID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[5] && lc_s1_io_out_bits_tgtID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[6] && lc_s1_io_out_bits_tgtID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[7] && lc_s1_io_out_bits_tgtID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[8] && lc_s1_io_out_bits_tgtID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[9] && lc_s1_io_out_bits_tgtID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tgtID[10] && lc_s1_io_out_bits_tgtID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tgtID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[0] && lc_s1_io_out_bits_srcID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[1] && lc_s1_io_out_bits_srcID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[2] && lc_s1_io_out_bits_srcID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[3] && lc_s1_io_out_bits_srcID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[4] && lc_s1_io_out_bits_srcID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[5] && lc_s1_io_out_bits_srcID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[6] && lc_s1_io_out_bits_srcID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[7] && lc_s1_io_out_bits_srcID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[8] && lc_s1_io_out_bits_srcID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[9] && lc_s1_io_out_bits_srcID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_srcID[10] && lc_s1_io_out_bits_srcID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_srcID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[0] && lc_s1_io_out_bits_txnID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[1] && lc_s1_io_out_bits_txnID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[2] && lc_s1_io_out_bits_txnID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[3] && lc_s1_io_out_bits_txnID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[4] && lc_s1_io_out_bits_txnID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[5] && lc_s1_io_out_bits_txnID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[6] && lc_s1_io_out_bits_txnID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[7] && lc_s1_io_out_bits_txnID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[8] && lc_s1_io_out_bits_txnID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[9] && lc_s1_io_out_bits_txnID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[10] && lc_s1_io_out_bits_txnID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_txnID[11] && lc_s1_io_out_bits_txnID[11])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_txnID[11] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[0] && lc_s1_io_out_bits_opcode[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_opcode[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[1] && lc_s1_io_out_bits_opcode[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_opcode[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[2] && lc_s1_io_out_bits_opcode[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_opcode[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[3] && lc_s1_io_out_bits_opcode[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_opcode[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_opcode[4] && lc_s1_io_out_bits_opcode[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_opcode[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_respErr[0] && lc_s1_io_out_bits_respErr[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_respErr[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_respErr[1] && lc_s1_io_out_bits_respErr[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_respErr[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_resp[0] && lc_s1_io_out_bits_resp[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_resp[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_resp[1] && lc_s1_io_out_bits_resp[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_resp[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_resp[2] && lc_s1_io_out_bits_resp[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_resp[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_fwdState[0] && lc_s1_io_out_bits_fwdState[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_fwdState[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_fwdState[1] && lc_s1_io_out_bits_fwdState[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_fwdState[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_fwdState[2] && lc_s1_io_out_bits_fwdState[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_fwdState[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_cBusy[0] && lc_s1_io_out_bits_cBusy[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_cBusy[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_cBusy[1] && lc_s1_io_out_bits_cBusy[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_cBusy[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_cBusy[2] && lc_s1_io_out_bits_cBusy[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_cBusy[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[0] && lc_s1_io_out_bits_dbID[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[1] && lc_s1_io_out_bits_dbID[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[2] && lc_s1_io_out_bits_dbID[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[3] && lc_s1_io_out_bits_dbID[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[4] && lc_s1_io_out_bits_dbID[4])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[4] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[5] && lc_s1_io_out_bits_dbID[5])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[5] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[6] && lc_s1_io_out_bits_dbID[6])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[6] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[7] && lc_s1_io_out_bits_dbID[7])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[7] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[8] && lc_s1_io_out_bits_dbID[8])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[8] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[9] && lc_s1_io_out_bits_dbID[9])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[9] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[10] && lc_s1_io_out_bits_dbID[10])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[10] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_dbID[11] && lc_s1_io_out_bits_dbID[11])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_dbID[11] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_pCrdType[0] && lc_s1_io_out_bits_pCrdType[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_pCrdType[1] && lc_s1_io_out_bits_pCrdType[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_pCrdType[2] && lc_s1_io_out_bits_pCrdType[2])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_pCrdType[3] && lc_s1_io_out_bits_pCrdType[3])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tagOp[0] && lc_s1_io_out_bits_tagOp[0])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tagOp[0] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_tagOp[1] && lc_s1_io_out_bits_tagOp[1])) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_tagOp[1] 未见过 0 和 1"); end
    if (!(lc_s0_io_out_bits_traceTag && lc_s1_io_out_bits_traceTag)) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_out_bits_traceTag 未见过 0 和 1"); end
    if (!(lc_s0_io_reclaimLCredit && lc_s1_io_reclaimLCredit)) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.io_reclaimLCredit 未见过 0 和 1"); end
    $display("[ARM] LCredit2Decoupled_1 armed_at=%0d", lc_armed_at);
    if (lc_armed_at < 0) begin cov_fail++; $display("[ARM] LCredit2Decoupled_1 从未 arm"); end
    $display("[COV] LCredit2Decoupled_1.lcrdv = %0d", lc_cov_lcrdv);
    if (lc_cov_lcrdv < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.lcrdv < 100"); end
    $display("[COV] LCredit2Decoupled_1.rsp_out = %0d", lc_cov_rsp_out);
    if (lc_cov_rsp_out < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.rsp_out < 100"); end
    $display("[COV] LCredit2Decoupled_1.lcrd_return_dropped = %0d", lc_cov_lcrd_return_dropped);
    if (lc_cov_lcrd_return_dropped < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.lcrd_return_dropped < 100"); end
    $display("[COV] LCredit2Decoupled_1.give_and_accept = %0d", lc_cov_give_and_accept);
    if (lc_cov_give_and_accept < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.give_and_accept < 100"); end
    $display("[COV] LCredit2Decoupled_1.pool_empty = %0d", lc_cov_pool_empty);
    if (lc_cov_pool_empty < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.pool_empty < 100"); end
    $display("[COV] LCredit2Decoupled_1.reclaim = %0d", lc_cov_reclaim);
    if (lc_cov_reclaim < 100) begin cov_fail++; $display("[COV] LCredit2Decoupled_1.reclaim < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule

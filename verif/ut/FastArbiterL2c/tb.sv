// tb —— FastArbiterL2c：L2 顶层 3 个 FastArbiter 变体（FastArbiter / _1 / _26）的双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= FastArbiter =================
  int unsigned fa0_mode = 0;
  logic fa0_reset;
  wire  fa0_g_io_in_0_ready, fa0_i_io_in_0_ready;
  logic fa0_s0_io_in_0_ready = '0, fa0_s1_io_in_0_ready = '0;
  logic fa0_io_in_0_valid;
  logic [32:0] fa0_io_in_0_bits_tag;
  logic [8:0] fa0_io_in_0_bits_set;
  logic fa0_io_in_0_bits_needT;
  logic [6:0] fa0_io_in_0_bits_source;
  logic [43:0] fa0_io_in_0_bits_vaddr;
  logic [4:0] fa0_io_in_0_bits_reqsource;
  wire  fa0_g_io_in_1_ready, fa0_i_io_in_1_ready;
  logic fa0_s0_io_in_1_ready = '0, fa0_s1_io_in_1_ready = '0;
  logic fa0_io_in_1_valid;
  logic [32:0] fa0_io_in_1_bits_tag;
  logic [8:0] fa0_io_in_1_bits_set;
  logic fa0_io_in_1_bits_needT;
  logic [6:0] fa0_io_in_1_bits_source;
  logic [43:0] fa0_io_in_1_bits_vaddr;
  logic [4:0] fa0_io_in_1_bits_reqsource;
  wire  fa0_g_io_in_2_ready, fa0_i_io_in_2_ready;
  logic fa0_s0_io_in_2_ready = '0, fa0_s1_io_in_2_ready = '0;
  logic fa0_io_in_2_valid;
  logic [32:0] fa0_io_in_2_bits_tag;
  logic [8:0] fa0_io_in_2_bits_set;
  logic fa0_io_in_2_bits_needT;
  logic [6:0] fa0_io_in_2_bits_source;
  logic [43:0] fa0_io_in_2_bits_vaddr;
  logic [4:0] fa0_io_in_2_bits_reqsource;
  wire  fa0_g_io_in_3_ready, fa0_i_io_in_3_ready;
  logic fa0_s0_io_in_3_ready = '0, fa0_s1_io_in_3_ready = '0;
  logic fa0_io_in_3_valid;
  logic [32:0] fa0_io_in_3_bits_tag;
  logic [8:0] fa0_io_in_3_bits_set;
  logic fa0_io_in_3_bits_needT;
  logic [6:0] fa0_io_in_3_bits_source;
  logic [43:0] fa0_io_in_3_bits_vaddr;
  logic [4:0] fa0_io_in_3_bits_reqsource;
  logic fa0_io_out_ready;
  wire  fa0_g_io_out_valid, fa0_i_io_out_valid;
  logic fa0_s0_io_out_valid = '0, fa0_s1_io_out_valid = '0;
  wire  [32:0] fa0_g_io_out_bits_tag, fa0_i_io_out_bits_tag;
  logic [32:0] fa0_s0_io_out_bits_tag = '0, fa0_s1_io_out_bits_tag = '0;
  wire  [8:0] fa0_g_io_out_bits_set, fa0_i_io_out_bits_set;
  logic [8:0] fa0_s0_io_out_bits_set = '0, fa0_s1_io_out_bits_set = '0;
  wire  fa0_g_io_out_bits_needT, fa0_i_io_out_bits_needT;
  logic fa0_s0_io_out_bits_needT = '0, fa0_s1_io_out_bits_needT = '0;
  wire  [6:0] fa0_g_io_out_bits_source, fa0_i_io_out_bits_source;
  logic [6:0] fa0_s0_io_out_bits_source = '0, fa0_s1_io_out_bits_source = '0;
  wire  [43:0] fa0_g_io_out_bits_vaddr, fa0_i_io_out_bits_vaddr;
  logic [43:0] fa0_s0_io_out_bits_vaddr = '0, fa0_s1_io_out_bits_vaddr = '0;
  wire  [4:0] fa0_g_io_out_bits_reqsource, fa0_i_io_out_bits_reqsource;
  logic [4:0] fa0_s0_io_out_bits_reqsource = '0, fa0_s1_io_out_bits_reqsource = '0;
  int fa0_cov_fire = 0;
  int fa0_cov_contend = 0;
  int fa0_cov_rr_pick = 0;
  int fa0_cov_grant3 = 0;
  int fa0_cov_grant0 = 0;
  logic [0:0] fa0_armed = '0;
  int fa0_armed_at = -1;
  FastArbiter fa0_u_gold (
    .clock(clk),
    .reset(fa0_reset),
    .io_in_0_ready(fa0_g_io_in_0_ready),
    .io_in_0_valid(fa0_io_in_0_valid),
    .io_in_0_bits_tag(fa0_io_in_0_bits_tag),
    .io_in_0_bits_set(fa0_io_in_0_bits_set),
    .io_in_0_bits_needT(fa0_io_in_0_bits_needT),
    .io_in_0_bits_source(fa0_io_in_0_bits_source),
    .io_in_0_bits_vaddr(fa0_io_in_0_bits_vaddr),
    .io_in_0_bits_reqsource(fa0_io_in_0_bits_reqsource),
    .io_in_1_ready(fa0_g_io_in_1_ready),
    .io_in_1_valid(fa0_io_in_1_valid),
    .io_in_1_bits_tag(fa0_io_in_1_bits_tag),
    .io_in_1_bits_set(fa0_io_in_1_bits_set),
    .io_in_1_bits_needT(fa0_io_in_1_bits_needT),
    .io_in_1_bits_source(fa0_io_in_1_bits_source),
    .io_in_1_bits_vaddr(fa0_io_in_1_bits_vaddr),
    .io_in_1_bits_reqsource(fa0_io_in_1_bits_reqsource),
    .io_in_2_ready(fa0_g_io_in_2_ready),
    .io_in_2_valid(fa0_io_in_2_valid),
    .io_in_2_bits_tag(fa0_io_in_2_bits_tag),
    .io_in_2_bits_set(fa0_io_in_2_bits_set),
    .io_in_2_bits_needT(fa0_io_in_2_bits_needT),
    .io_in_2_bits_source(fa0_io_in_2_bits_source),
    .io_in_2_bits_vaddr(fa0_io_in_2_bits_vaddr),
    .io_in_2_bits_reqsource(fa0_io_in_2_bits_reqsource),
    .io_in_3_ready(fa0_g_io_in_3_ready),
    .io_in_3_valid(fa0_io_in_3_valid),
    .io_in_3_bits_tag(fa0_io_in_3_bits_tag),
    .io_in_3_bits_set(fa0_io_in_3_bits_set),
    .io_in_3_bits_needT(fa0_io_in_3_bits_needT),
    .io_in_3_bits_source(fa0_io_in_3_bits_source),
    .io_in_3_bits_vaddr(fa0_io_in_3_bits_vaddr),
    .io_in_3_bits_reqsource(fa0_io_in_3_bits_reqsource),
    .io_out_ready(fa0_io_out_ready),
    .io_out_valid(fa0_g_io_out_valid),
    .io_out_bits_tag(fa0_g_io_out_bits_tag),
    .io_out_bits_set(fa0_g_io_out_bits_set),
    .io_out_bits_needT(fa0_g_io_out_bits_needT),
    .io_out_bits_source(fa0_g_io_out_bits_source),
    .io_out_bits_vaddr(fa0_g_io_out_bits_vaddr),
    .io_out_bits_reqsource(fa0_g_io_out_bits_reqsource)
  );
  FastArbiter_xs fa0_u_impl (
    .clock(clk),
    .reset(fa0_reset),
    .io_in_0_ready(fa0_i_io_in_0_ready),
    .io_in_0_valid(fa0_io_in_0_valid),
    .io_in_0_bits_tag(fa0_io_in_0_bits_tag),
    .io_in_0_bits_set(fa0_io_in_0_bits_set),
    .io_in_0_bits_needT(fa0_io_in_0_bits_needT),
    .io_in_0_bits_source(fa0_io_in_0_bits_source),
    .io_in_0_bits_vaddr(fa0_io_in_0_bits_vaddr),
    .io_in_0_bits_reqsource(fa0_io_in_0_bits_reqsource),
    .io_in_1_ready(fa0_i_io_in_1_ready),
    .io_in_1_valid(fa0_io_in_1_valid),
    .io_in_1_bits_tag(fa0_io_in_1_bits_tag),
    .io_in_1_bits_set(fa0_io_in_1_bits_set),
    .io_in_1_bits_needT(fa0_io_in_1_bits_needT),
    .io_in_1_bits_source(fa0_io_in_1_bits_source),
    .io_in_1_bits_vaddr(fa0_io_in_1_bits_vaddr),
    .io_in_1_bits_reqsource(fa0_io_in_1_bits_reqsource),
    .io_in_2_ready(fa0_i_io_in_2_ready),
    .io_in_2_valid(fa0_io_in_2_valid),
    .io_in_2_bits_tag(fa0_io_in_2_bits_tag),
    .io_in_2_bits_set(fa0_io_in_2_bits_set),
    .io_in_2_bits_needT(fa0_io_in_2_bits_needT),
    .io_in_2_bits_source(fa0_io_in_2_bits_source),
    .io_in_2_bits_vaddr(fa0_io_in_2_bits_vaddr),
    .io_in_2_bits_reqsource(fa0_io_in_2_bits_reqsource),
    .io_in_3_ready(fa0_i_io_in_3_ready),
    .io_in_3_valid(fa0_io_in_3_valid),
    .io_in_3_bits_tag(fa0_io_in_3_bits_tag),
    .io_in_3_bits_set(fa0_io_in_3_bits_set),
    .io_in_3_bits_needT(fa0_io_in_3_bits_needT),
    .io_in_3_bits_source(fa0_io_in_3_bits_source),
    .io_in_3_bits_vaddr(fa0_io_in_3_bits_vaddr),
    .io_in_3_bits_reqsource(fa0_io_in_3_bits_reqsource),
    .io_out_ready(fa0_io_out_ready),
    .io_out_valid(fa0_i_io_out_valid),
    .io_out_bits_tag(fa0_i_io_out_bits_tag),
    .io_out_bits_set(fa0_i_io_out_bits_set),
    .io_out_bits_needT(fa0_i_io_out_bits_needT),
    .io_out_bits_source(fa0_i_io_out_bits_source),
    .io_out_bits_vaddr(fa0_i_io_out_bits_vaddr),
    .io_out_bits_reqsource(fa0_i_io_out_bits_reqsource)
  );

  // ================= FastArbiter_1 =================
  int unsigned fa1_mode = 0;
  logic fa1_reset;
  wire  fa1_g_io_in_0_ready, fa1_i_io_in_0_ready;
  logic fa1_s0_io_in_0_ready = '0, fa1_s1_io_in_0_ready = '0;
  logic fa1_io_in_0_valid;
  logic [4:0] fa1_io_in_0_bits_pfSource;
  wire  fa1_g_io_in_1_ready, fa1_i_io_in_1_ready;
  logic fa1_s0_io_in_1_ready = '0, fa1_s1_io_in_1_ready = '0;
  logic fa1_io_in_1_valid;
  logic [4:0] fa1_io_in_1_bits_pfSource;
  wire  fa1_g_io_in_2_ready, fa1_i_io_in_2_ready;
  logic fa1_s0_io_in_2_ready = '0, fa1_s1_io_in_2_ready = '0;
  logic fa1_io_in_2_valid;
  logic [4:0] fa1_io_in_2_bits_pfSource;
  wire  fa1_g_io_in_3_ready, fa1_i_io_in_3_ready;
  logic fa1_s0_io_in_3_ready = '0, fa1_s1_io_in_3_ready = '0;
  logic fa1_io_in_3_valid;
  logic [4:0] fa1_io_in_3_bits_pfSource;
  logic fa1_io_out_ready;
  wire  fa1_g_io_out_valid, fa1_i_io_out_valid;
  logic fa1_s0_io_out_valid = '0, fa1_s1_io_out_valid = '0;
  wire  [4:0] fa1_g_io_out_bits_pfSource, fa1_i_io_out_bits_pfSource;
  logic [4:0] fa1_s0_io_out_bits_pfSource = '0, fa1_s1_io_out_bits_pfSource = '0;
  int fa1_cov_fire = 0;
  int fa1_cov_contend = 0;
  int fa1_cov_rr_pick = 0;
  int fa1_cov_grant3 = 0;
  int fa1_cov_grant0 = 0;
  logic [0:0] fa1_armed = '0;
  int fa1_armed_at = -1;
  FastArbiter_1 fa1_u_gold (
    .clock(clk),
    .reset(fa1_reset),
    .io_in_0_ready(fa1_g_io_in_0_ready),
    .io_in_0_valid(fa1_io_in_0_valid),
    .io_in_0_bits_pfSource(fa1_io_in_0_bits_pfSource),
    .io_in_1_ready(fa1_g_io_in_1_ready),
    .io_in_1_valid(fa1_io_in_1_valid),
    .io_in_1_bits_pfSource(fa1_io_in_1_bits_pfSource),
    .io_in_2_ready(fa1_g_io_in_2_ready),
    .io_in_2_valid(fa1_io_in_2_valid),
    .io_in_2_bits_pfSource(fa1_io_in_2_bits_pfSource),
    .io_in_3_ready(fa1_g_io_in_3_ready),
    .io_in_3_valid(fa1_io_in_3_valid),
    .io_in_3_bits_pfSource(fa1_io_in_3_bits_pfSource),
    .io_out_ready(fa1_io_out_ready),
    .io_out_valid(fa1_g_io_out_valid),
    .io_out_bits_pfSource(fa1_g_io_out_bits_pfSource)
  );
  FastArbiter_1_xs fa1_u_impl (
    .clock(clk),
    .reset(fa1_reset),
    .io_in_0_ready(fa1_i_io_in_0_ready),
    .io_in_0_valid(fa1_io_in_0_valid),
    .io_in_0_bits_pfSource(fa1_io_in_0_bits_pfSource),
    .io_in_1_ready(fa1_i_io_in_1_ready),
    .io_in_1_valid(fa1_io_in_1_valid),
    .io_in_1_bits_pfSource(fa1_io_in_1_bits_pfSource),
    .io_in_2_ready(fa1_i_io_in_2_ready),
    .io_in_2_valid(fa1_io_in_2_valid),
    .io_in_2_bits_pfSource(fa1_io_in_2_bits_pfSource),
    .io_in_3_ready(fa1_i_io_in_3_ready),
    .io_in_3_valid(fa1_io_in_3_valid),
    .io_in_3_bits_pfSource(fa1_io_in_3_bits_pfSource),
    .io_out_ready(fa1_io_out_ready),
    .io_out_valid(fa1_i_io_out_valid),
    .io_out_bits_pfSource(fa1_i_io_out_bits_pfSource)
  );

  // ================= FastArbiter_26 =================
  int unsigned fa26_mode = 0;
  logic fa26_reset;
  wire  fa26_g_io_in_0_ready, fa26_i_io_in_0_ready;
  logic fa26_s0_io_in_0_ready = '0, fa26_s1_io_in_0_ready = '0;
  logic fa26_io_in_0_valid;
  logic [3:0] fa26_io_in_0_bits_qos;
  logic [10:0] fa26_io_in_0_bits_tgtID;
  logic [11:0] fa26_io_in_0_bits_txnID;
  logic [4:0] fa26_io_in_0_bits_opcode;
  logic [1:0] fa26_io_in_0_bits_respErr;
  logic [2:0] fa26_io_in_0_bits_resp;
  logic [2:0] fa26_io_in_0_bits_fwdState;
  logic [2:0] fa26_io_in_0_bits_cBusy;
  logic [11:0] fa26_io_in_0_bits_dbID;
  logic [3:0] fa26_io_in_0_bits_pCrdType;
  logic [1:0] fa26_io_in_0_bits_tagOp;
  logic fa26_io_in_0_bits_traceTag;
  wire  fa26_g_io_in_1_ready, fa26_i_io_in_1_ready;
  logic fa26_s0_io_in_1_ready = '0, fa26_s1_io_in_1_ready = '0;
  logic fa26_io_in_1_valid;
  logic [3:0] fa26_io_in_1_bits_qos;
  logic [10:0] fa26_io_in_1_bits_tgtID;
  logic [11:0] fa26_io_in_1_bits_txnID;
  logic [4:0] fa26_io_in_1_bits_opcode;
  logic [1:0] fa26_io_in_1_bits_respErr;
  logic [2:0] fa26_io_in_1_bits_resp;
  logic [2:0] fa26_io_in_1_bits_fwdState;
  logic [2:0] fa26_io_in_1_bits_cBusy;
  logic [11:0] fa26_io_in_1_bits_dbID;
  logic [3:0] fa26_io_in_1_bits_pCrdType;
  logic [1:0] fa26_io_in_1_bits_tagOp;
  logic fa26_io_in_1_bits_traceTag;
  wire  fa26_g_io_in_2_ready, fa26_i_io_in_2_ready;
  logic fa26_s0_io_in_2_ready = '0, fa26_s1_io_in_2_ready = '0;
  logic fa26_io_in_2_valid;
  logic [3:0] fa26_io_in_2_bits_qos;
  logic [10:0] fa26_io_in_2_bits_tgtID;
  logic [11:0] fa26_io_in_2_bits_txnID;
  logic [4:0] fa26_io_in_2_bits_opcode;
  logic [1:0] fa26_io_in_2_bits_respErr;
  logic [2:0] fa26_io_in_2_bits_resp;
  logic [2:0] fa26_io_in_2_bits_fwdState;
  logic [2:0] fa26_io_in_2_bits_cBusy;
  logic [11:0] fa26_io_in_2_bits_dbID;
  logic [3:0] fa26_io_in_2_bits_pCrdType;
  logic [1:0] fa26_io_in_2_bits_tagOp;
  logic fa26_io_in_2_bits_traceTag;
  wire  fa26_g_io_in_3_ready, fa26_i_io_in_3_ready;
  logic fa26_s0_io_in_3_ready = '0, fa26_s1_io_in_3_ready = '0;
  logic fa26_io_in_3_valid;
  logic [3:0] fa26_io_in_3_bits_qos;
  logic [10:0] fa26_io_in_3_bits_tgtID;
  logic [11:0] fa26_io_in_3_bits_txnID;
  logic [4:0] fa26_io_in_3_bits_opcode;
  logic [1:0] fa26_io_in_3_bits_respErr;
  logic [2:0] fa26_io_in_3_bits_resp;
  logic [2:0] fa26_io_in_3_bits_fwdState;
  logic [2:0] fa26_io_in_3_bits_cBusy;
  logic [11:0] fa26_io_in_3_bits_dbID;
  logic [3:0] fa26_io_in_3_bits_pCrdType;
  logic [1:0] fa26_io_in_3_bits_tagOp;
  logic fa26_io_in_3_bits_traceTag;
  logic fa26_io_out_ready;
  wire  fa26_g_io_out_valid, fa26_i_io_out_valid;
  logic fa26_s0_io_out_valid = '0, fa26_s1_io_out_valid = '0;
  wire  [3:0] fa26_g_io_out_bits_qos, fa26_i_io_out_bits_qos;
  logic [3:0] fa26_s0_io_out_bits_qos = '0, fa26_s1_io_out_bits_qos = '0;
  wire  [10:0] fa26_g_io_out_bits_tgtID, fa26_i_io_out_bits_tgtID;
  logic [10:0] fa26_s0_io_out_bits_tgtID = '0, fa26_s1_io_out_bits_tgtID = '0;
  wire  [11:0] fa26_g_io_out_bits_txnID, fa26_i_io_out_bits_txnID;
  logic [11:0] fa26_s0_io_out_bits_txnID = '0, fa26_s1_io_out_bits_txnID = '0;
  wire  [4:0] fa26_g_io_out_bits_opcode, fa26_i_io_out_bits_opcode;
  logic [4:0] fa26_s0_io_out_bits_opcode = '0, fa26_s1_io_out_bits_opcode = '0;
  wire  [1:0] fa26_g_io_out_bits_respErr, fa26_i_io_out_bits_respErr;
  logic [1:0] fa26_s0_io_out_bits_respErr = '0, fa26_s1_io_out_bits_respErr = '0;
  wire  [2:0] fa26_g_io_out_bits_resp, fa26_i_io_out_bits_resp;
  logic [2:0] fa26_s0_io_out_bits_resp = '0, fa26_s1_io_out_bits_resp = '0;
  wire  [2:0] fa26_g_io_out_bits_fwdState, fa26_i_io_out_bits_fwdState;
  logic [2:0] fa26_s0_io_out_bits_fwdState = '0, fa26_s1_io_out_bits_fwdState = '0;
  wire  [2:0] fa26_g_io_out_bits_cBusy, fa26_i_io_out_bits_cBusy;
  logic [2:0] fa26_s0_io_out_bits_cBusy = '0, fa26_s1_io_out_bits_cBusy = '0;
  wire  [11:0] fa26_g_io_out_bits_dbID, fa26_i_io_out_bits_dbID;
  logic [11:0] fa26_s0_io_out_bits_dbID = '0, fa26_s1_io_out_bits_dbID = '0;
  wire  [3:0] fa26_g_io_out_bits_pCrdType, fa26_i_io_out_bits_pCrdType;
  logic [3:0] fa26_s0_io_out_bits_pCrdType = '0, fa26_s1_io_out_bits_pCrdType = '0;
  wire  [1:0] fa26_g_io_out_bits_tagOp, fa26_i_io_out_bits_tagOp;
  logic [1:0] fa26_s0_io_out_bits_tagOp = '0, fa26_s1_io_out_bits_tagOp = '0;
  wire  fa26_g_io_out_bits_traceTag, fa26_i_io_out_bits_traceTag;
  logic fa26_s0_io_out_bits_traceTag = '0, fa26_s1_io_out_bits_traceTag = '0;
  wire  [1:0] fa26_g_io_chosen, fa26_i_io_chosen;
  logic [1:0] fa26_s0_io_chosen = '0, fa26_s1_io_chosen = '0;
  int fa26_cov_fire = 0;
  int fa26_cov_contend = 0;
  int fa26_cov_rr_pick = 0;
  int fa26_cov_grant3 = 0;
  int fa26_cov_grant0 = 0;
  logic [0:0] fa26_armed = '0;
  int fa26_armed_at = -1;
  FastArbiter_26 fa26_u_gold (
    .clock(clk),
    .reset(fa26_reset),
    .io_in_0_ready(fa26_g_io_in_0_ready),
    .io_in_0_valid(fa26_io_in_0_valid),
    .io_in_0_bits_qos(fa26_io_in_0_bits_qos),
    .io_in_0_bits_tgtID(fa26_io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(fa26_io_in_0_bits_txnID),
    .io_in_0_bits_opcode(fa26_io_in_0_bits_opcode),
    .io_in_0_bits_respErr(fa26_io_in_0_bits_respErr),
    .io_in_0_bits_resp(fa26_io_in_0_bits_resp),
    .io_in_0_bits_fwdState(fa26_io_in_0_bits_fwdState),
    .io_in_0_bits_cBusy(fa26_io_in_0_bits_cBusy),
    .io_in_0_bits_dbID(fa26_io_in_0_bits_dbID),
    .io_in_0_bits_pCrdType(fa26_io_in_0_bits_pCrdType),
    .io_in_0_bits_tagOp(fa26_io_in_0_bits_tagOp),
    .io_in_0_bits_traceTag(fa26_io_in_0_bits_traceTag),
    .io_in_1_ready(fa26_g_io_in_1_ready),
    .io_in_1_valid(fa26_io_in_1_valid),
    .io_in_1_bits_qos(fa26_io_in_1_bits_qos),
    .io_in_1_bits_tgtID(fa26_io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(fa26_io_in_1_bits_txnID),
    .io_in_1_bits_opcode(fa26_io_in_1_bits_opcode),
    .io_in_1_bits_respErr(fa26_io_in_1_bits_respErr),
    .io_in_1_bits_resp(fa26_io_in_1_bits_resp),
    .io_in_1_bits_fwdState(fa26_io_in_1_bits_fwdState),
    .io_in_1_bits_cBusy(fa26_io_in_1_bits_cBusy),
    .io_in_1_bits_dbID(fa26_io_in_1_bits_dbID),
    .io_in_1_bits_pCrdType(fa26_io_in_1_bits_pCrdType),
    .io_in_1_bits_tagOp(fa26_io_in_1_bits_tagOp),
    .io_in_1_bits_traceTag(fa26_io_in_1_bits_traceTag),
    .io_in_2_ready(fa26_g_io_in_2_ready),
    .io_in_2_valid(fa26_io_in_2_valid),
    .io_in_2_bits_qos(fa26_io_in_2_bits_qos),
    .io_in_2_bits_tgtID(fa26_io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(fa26_io_in_2_bits_txnID),
    .io_in_2_bits_opcode(fa26_io_in_2_bits_opcode),
    .io_in_2_bits_respErr(fa26_io_in_2_bits_respErr),
    .io_in_2_bits_resp(fa26_io_in_2_bits_resp),
    .io_in_2_bits_fwdState(fa26_io_in_2_bits_fwdState),
    .io_in_2_bits_cBusy(fa26_io_in_2_bits_cBusy),
    .io_in_2_bits_dbID(fa26_io_in_2_bits_dbID),
    .io_in_2_bits_pCrdType(fa26_io_in_2_bits_pCrdType),
    .io_in_2_bits_tagOp(fa26_io_in_2_bits_tagOp),
    .io_in_2_bits_traceTag(fa26_io_in_2_bits_traceTag),
    .io_in_3_ready(fa26_g_io_in_3_ready),
    .io_in_3_valid(fa26_io_in_3_valid),
    .io_in_3_bits_qos(fa26_io_in_3_bits_qos),
    .io_in_3_bits_tgtID(fa26_io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(fa26_io_in_3_bits_txnID),
    .io_in_3_bits_opcode(fa26_io_in_3_bits_opcode),
    .io_in_3_bits_respErr(fa26_io_in_3_bits_respErr),
    .io_in_3_bits_resp(fa26_io_in_3_bits_resp),
    .io_in_3_bits_fwdState(fa26_io_in_3_bits_fwdState),
    .io_in_3_bits_cBusy(fa26_io_in_3_bits_cBusy),
    .io_in_3_bits_dbID(fa26_io_in_3_bits_dbID),
    .io_in_3_bits_pCrdType(fa26_io_in_3_bits_pCrdType),
    .io_in_3_bits_tagOp(fa26_io_in_3_bits_tagOp),
    .io_in_3_bits_traceTag(fa26_io_in_3_bits_traceTag),
    .io_out_ready(fa26_io_out_ready),
    .io_out_valid(fa26_g_io_out_valid),
    .io_out_bits_qos(fa26_g_io_out_bits_qos),
    .io_out_bits_tgtID(fa26_g_io_out_bits_tgtID),
    .io_out_bits_txnID(fa26_g_io_out_bits_txnID),
    .io_out_bits_opcode(fa26_g_io_out_bits_opcode),
    .io_out_bits_respErr(fa26_g_io_out_bits_respErr),
    .io_out_bits_resp(fa26_g_io_out_bits_resp),
    .io_out_bits_fwdState(fa26_g_io_out_bits_fwdState),
    .io_out_bits_cBusy(fa26_g_io_out_bits_cBusy),
    .io_out_bits_dbID(fa26_g_io_out_bits_dbID),
    .io_out_bits_pCrdType(fa26_g_io_out_bits_pCrdType),
    .io_out_bits_tagOp(fa26_g_io_out_bits_tagOp),
    .io_out_bits_traceTag(fa26_g_io_out_bits_traceTag),
    .io_chosen(fa26_g_io_chosen)
  );
  FastArbiter_26_xs fa26_u_impl (
    .clock(clk),
    .reset(fa26_reset),
    .io_in_0_ready(fa26_i_io_in_0_ready),
    .io_in_0_valid(fa26_io_in_0_valid),
    .io_in_0_bits_qos(fa26_io_in_0_bits_qos),
    .io_in_0_bits_tgtID(fa26_io_in_0_bits_tgtID),
    .io_in_0_bits_txnID(fa26_io_in_0_bits_txnID),
    .io_in_0_bits_opcode(fa26_io_in_0_bits_opcode),
    .io_in_0_bits_respErr(fa26_io_in_0_bits_respErr),
    .io_in_0_bits_resp(fa26_io_in_0_bits_resp),
    .io_in_0_bits_fwdState(fa26_io_in_0_bits_fwdState),
    .io_in_0_bits_cBusy(fa26_io_in_0_bits_cBusy),
    .io_in_0_bits_dbID(fa26_io_in_0_bits_dbID),
    .io_in_0_bits_pCrdType(fa26_io_in_0_bits_pCrdType),
    .io_in_0_bits_tagOp(fa26_io_in_0_bits_tagOp),
    .io_in_0_bits_traceTag(fa26_io_in_0_bits_traceTag),
    .io_in_1_ready(fa26_i_io_in_1_ready),
    .io_in_1_valid(fa26_io_in_1_valid),
    .io_in_1_bits_qos(fa26_io_in_1_bits_qos),
    .io_in_1_bits_tgtID(fa26_io_in_1_bits_tgtID),
    .io_in_1_bits_txnID(fa26_io_in_1_bits_txnID),
    .io_in_1_bits_opcode(fa26_io_in_1_bits_opcode),
    .io_in_1_bits_respErr(fa26_io_in_1_bits_respErr),
    .io_in_1_bits_resp(fa26_io_in_1_bits_resp),
    .io_in_1_bits_fwdState(fa26_io_in_1_bits_fwdState),
    .io_in_1_bits_cBusy(fa26_io_in_1_bits_cBusy),
    .io_in_1_bits_dbID(fa26_io_in_1_bits_dbID),
    .io_in_1_bits_pCrdType(fa26_io_in_1_bits_pCrdType),
    .io_in_1_bits_tagOp(fa26_io_in_1_bits_tagOp),
    .io_in_1_bits_traceTag(fa26_io_in_1_bits_traceTag),
    .io_in_2_ready(fa26_i_io_in_2_ready),
    .io_in_2_valid(fa26_io_in_2_valid),
    .io_in_2_bits_qos(fa26_io_in_2_bits_qos),
    .io_in_2_bits_tgtID(fa26_io_in_2_bits_tgtID),
    .io_in_2_bits_txnID(fa26_io_in_2_bits_txnID),
    .io_in_2_bits_opcode(fa26_io_in_2_bits_opcode),
    .io_in_2_bits_respErr(fa26_io_in_2_bits_respErr),
    .io_in_2_bits_resp(fa26_io_in_2_bits_resp),
    .io_in_2_bits_fwdState(fa26_io_in_2_bits_fwdState),
    .io_in_2_bits_cBusy(fa26_io_in_2_bits_cBusy),
    .io_in_2_bits_dbID(fa26_io_in_2_bits_dbID),
    .io_in_2_bits_pCrdType(fa26_io_in_2_bits_pCrdType),
    .io_in_2_bits_tagOp(fa26_io_in_2_bits_tagOp),
    .io_in_2_bits_traceTag(fa26_io_in_2_bits_traceTag),
    .io_in_3_ready(fa26_i_io_in_3_ready),
    .io_in_3_valid(fa26_io_in_3_valid),
    .io_in_3_bits_qos(fa26_io_in_3_bits_qos),
    .io_in_3_bits_tgtID(fa26_io_in_3_bits_tgtID),
    .io_in_3_bits_txnID(fa26_io_in_3_bits_txnID),
    .io_in_3_bits_opcode(fa26_io_in_3_bits_opcode),
    .io_in_3_bits_respErr(fa26_io_in_3_bits_respErr),
    .io_in_3_bits_resp(fa26_io_in_3_bits_resp),
    .io_in_3_bits_fwdState(fa26_io_in_3_bits_fwdState),
    .io_in_3_bits_cBusy(fa26_io_in_3_bits_cBusy),
    .io_in_3_bits_dbID(fa26_io_in_3_bits_dbID),
    .io_in_3_bits_pCrdType(fa26_io_in_3_bits_pCrdType),
    .io_in_3_bits_tagOp(fa26_io_in_3_bits_tagOp),
    .io_in_3_bits_traceTag(fa26_io_in_3_bits_traceTag),
    .io_out_ready(fa26_io_out_ready),
    .io_out_valid(fa26_i_io_out_valid),
    .io_out_bits_qos(fa26_i_io_out_bits_qos),
    .io_out_bits_tgtID(fa26_i_io_out_bits_tgtID),
    .io_out_bits_txnID(fa26_i_io_out_bits_txnID),
    .io_out_bits_opcode(fa26_i_io_out_bits_opcode),
    .io_out_bits_respErr(fa26_i_io_out_bits_respErr),
    .io_out_bits_resp(fa26_i_io_out_bits_resp),
    .io_out_bits_fwdState(fa26_i_io_out_bits_fwdState),
    .io_out_bits_cBusy(fa26_i_io_out_bits_cBusy),
    .io_out_bits_dbID(fa26_i_io_out_bits_dbID),
    .io_out_bits_pCrdType(fa26_i_io_out_bits_pCrdType),
    .io_out_bits_tagOp(fa26_i_io_out_bits_tagOp),
    .io_out_bits_traceTag(fa26_i_io_out_bits_traceTag),
    .io_chosen(fa26_i_io_chosen)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) fa0_mode = $urandom_range(0, 15);
      fa0_io_in_0_valid = 1'($urandom);
      fa0_io_in_0_bits_tag = 33'({$urandom, $urandom});
      fa0_io_in_0_bits_set = 9'($urandom);
      fa0_io_in_0_bits_needT = 1'($urandom);
      fa0_io_in_0_bits_source = 7'($urandom);
      fa0_io_in_0_bits_vaddr = 44'({$urandom, $urandom});
      fa0_io_in_0_bits_reqsource = 5'($urandom);
      fa0_io_in_1_valid = 1'($urandom);
      fa0_io_in_1_bits_tag = 33'({$urandom, $urandom});
      fa0_io_in_1_bits_set = 9'($urandom);
      fa0_io_in_1_bits_needT = 1'($urandom);
      fa0_io_in_1_bits_source = 7'($urandom);
      fa0_io_in_1_bits_vaddr = 44'({$urandom, $urandom});
      fa0_io_in_1_bits_reqsource = 5'($urandom);
      fa0_io_in_2_valid = 1'($urandom);
      fa0_io_in_2_bits_tag = 33'({$urandom, $urandom});
      fa0_io_in_2_bits_set = 9'($urandom);
      fa0_io_in_2_bits_needT = 1'($urandom);
      fa0_io_in_2_bits_source = 7'($urandom);
      fa0_io_in_2_bits_vaddr = 44'({$urandom, $urandom});
      fa0_io_in_2_bits_reqsource = 5'($urandom);
      fa0_io_in_3_valid = 1'($urandom);
      fa0_io_in_3_bits_tag = 33'({$urandom, $urandom});
      fa0_io_in_3_bits_set = 9'($urandom);
      fa0_io_in_3_bits_needT = 1'($urandom);
      fa0_io_in_3_bits_source = 7'($urandom);
      fa0_io_in_3_bits_vaddr = 44'({$urandom, $urandom});
      fa0_io_in_3_bits_reqsource = 5'($urandom);
      fa0_io_out_ready = 1'($urandom);
      fa0_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_fa0
        case (fa0_mode % 3)
          0: begin
            fa0_io_in_0_valid = ($urandom_range(0, 3) == 0); fa0_io_in_1_valid = ($urandom_range(0, 3) == 0);
            fa0_io_in_2_valid = ($urandom_range(0, 3) == 0); fa0_io_in_3_valid = ($urandom_range(0, 3) == 0);
          end
          1: begin
            fa0_io_in_0_valid = ($urandom_range(0, 3) != 0); fa0_io_in_1_valid = ($urandom_range(0, 3) != 0);
            fa0_io_in_2_valid = ($urandom_range(0, 3) != 0); fa0_io_in_3_valid = ($urandom_range(0, 3) != 0);
          end
          default: ;
        endcase
        fa0_io_out_ready = ($urandom_range(0, 3) != 0);
      end
      if (cyc % 4000 == 0) fa1_mode = $urandom_range(0, 15);
      fa1_io_in_0_valid = 1'($urandom);
      fa1_io_in_0_bits_pfSource = 5'($urandom);
      fa1_io_in_1_valid = 1'($urandom);
      fa1_io_in_1_bits_pfSource = 5'($urandom);
      fa1_io_in_2_valid = 1'($urandom);
      fa1_io_in_2_bits_pfSource = 5'($urandom);
      fa1_io_in_3_valid = 1'($urandom);
      fa1_io_in_3_bits_pfSource = 5'($urandom);
      fa1_io_out_ready = 1'($urandom);
      fa1_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_fa1
        case (fa1_mode % 3)
          0: begin
            fa1_io_in_0_valid = ($urandom_range(0, 3) == 0); fa1_io_in_1_valid = ($urandom_range(0, 3) == 0);
            fa1_io_in_2_valid = ($urandom_range(0, 3) == 0); fa1_io_in_3_valid = ($urandom_range(0, 3) == 0);
          end
          1: begin
            fa1_io_in_0_valid = ($urandom_range(0, 3) != 0); fa1_io_in_1_valid = ($urandom_range(0, 3) != 0);
            fa1_io_in_2_valid = ($urandom_range(0, 3) != 0); fa1_io_in_3_valid = ($urandom_range(0, 3) != 0);
          end
          default: ;
        endcase
        fa1_io_out_ready = ($urandom_range(0, 3) != 0);
      end
      if (cyc % 4000 == 0) fa26_mode = $urandom_range(0, 15);
      fa26_io_in_0_valid = 1'($urandom);
      fa26_io_in_0_bits_qos = 4'($urandom);
      fa26_io_in_0_bits_tgtID = 11'($urandom);
      fa26_io_in_0_bits_txnID = 12'($urandom);
      fa26_io_in_0_bits_opcode = 5'($urandom);
      fa26_io_in_0_bits_respErr = 2'($urandom);
      fa26_io_in_0_bits_resp = 3'($urandom);
      fa26_io_in_0_bits_fwdState = 3'($urandom);
      fa26_io_in_0_bits_cBusy = 3'($urandom);
      fa26_io_in_0_bits_dbID = 12'($urandom);
      fa26_io_in_0_bits_pCrdType = 4'($urandom);
      fa26_io_in_0_bits_tagOp = 2'($urandom);
      fa26_io_in_0_bits_traceTag = 1'($urandom);
      fa26_io_in_1_valid = 1'($urandom);
      fa26_io_in_1_bits_qos = 4'($urandom);
      fa26_io_in_1_bits_tgtID = 11'($urandom);
      fa26_io_in_1_bits_txnID = 12'($urandom);
      fa26_io_in_1_bits_opcode = 5'($urandom);
      fa26_io_in_1_bits_respErr = 2'($urandom);
      fa26_io_in_1_bits_resp = 3'($urandom);
      fa26_io_in_1_bits_fwdState = 3'($urandom);
      fa26_io_in_1_bits_cBusy = 3'($urandom);
      fa26_io_in_1_bits_dbID = 12'($urandom);
      fa26_io_in_1_bits_pCrdType = 4'($urandom);
      fa26_io_in_1_bits_tagOp = 2'($urandom);
      fa26_io_in_1_bits_traceTag = 1'($urandom);
      fa26_io_in_2_valid = 1'($urandom);
      fa26_io_in_2_bits_qos = 4'($urandom);
      fa26_io_in_2_bits_tgtID = 11'($urandom);
      fa26_io_in_2_bits_txnID = 12'($urandom);
      fa26_io_in_2_bits_opcode = 5'($urandom);
      fa26_io_in_2_bits_respErr = 2'($urandom);
      fa26_io_in_2_bits_resp = 3'($urandom);
      fa26_io_in_2_bits_fwdState = 3'($urandom);
      fa26_io_in_2_bits_cBusy = 3'($urandom);
      fa26_io_in_2_bits_dbID = 12'($urandom);
      fa26_io_in_2_bits_pCrdType = 4'($urandom);
      fa26_io_in_2_bits_tagOp = 2'($urandom);
      fa26_io_in_2_bits_traceTag = 1'($urandom);
      fa26_io_in_3_valid = 1'($urandom);
      fa26_io_in_3_bits_qos = 4'($urandom);
      fa26_io_in_3_bits_tgtID = 11'($urandom);
      fa26_io_in_3_bits_txnID = 12'($urandom);
      fa26_io_in_3_bits_opcode = 5'($urandom);
      fa26_io_in_3_bits_respErr = 2'($urandom);
      fa26_io_in_3_bits_resp = 3'($urandom);
      fa26_io_in_3_bits_fwdState = 3'($urandom);
      fa26_io_in_3_bits_cBusy = 3'($urandom);
      fa26_io_in_3_bits_dbID = 12'($urandom);
      fa26_io_in_3_bits_pCrdType = 4'($urandom);
      fa26_io_in_3_bits_tagOp = 2'($urandom);
      fa26_io_in_3_bits_traceTag = 1'($urandom);
      fa26_io_out_ready = 1'($urandom);
      fa26_reset = (cyc < RESET_CYC) || ($urandom_range(0, 39999) == 0);
      begin : stim_fa26
        case (fa26_mode % 3)
          0: begin
            fa26_io_in_0_valid = ($urandom_range(0, 3) == 0); fa26_io_in_1_valid = ($urandom_range(0, 3) == 0);
            fa26_io_in_2_valid = ($urandom_range(0, 3) == 0); fa26_io_in_3_valid = ($urandom_range(0, 3) == 0);
          end
          1: begin
            fa26_io_in_0_valid = ($urandom_range(0, 3) != 0); fa26_io_in_1_valid = ($urandom_range(0, 3) != 0);
            fa26_io_in_2_valid = ($urandom_range(0, 3) != 0); fa26_io_in_3_valid = ($urandom_range(0, 3) != 0);
          end
          default: ;
        endcase
        fa26_io_out_ready = ($urandom_range(0, 3) != 0);
      end
      #4;
      fa0_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&fa0_armed)) begin
        checks++;
        if (fa0_g_io_in_0_ready !== fa0_i_io_in_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_in_0_ready g=%h i=%h", cyc, fa0_g_io_in_0_ready, fa0_i_io_in_0_ready);
        end
        fa0_s1_io_in_0_ready |= fa0_g_io_in_0_ready;
        fa0_s0_io_in_0_ready |= ~fa0_g_io_in_0_ready;
        checks++;
        if (fa0_g_io_in_1_ready !== fa0_i_io_in_1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_in_1_ready g=%h i=%h", cyc, fa0_g_io_in_1_ready, fa0_i_io_in_1_ready);
        end
        fa0_s1_io_in_1_ready |= fa0_g_io_in_1_ready;
        fa0_s0_io_in_1_ready |= ~fa0_g_io_in_1_ready;
        checks++;
        if (fa0_g_io_in_2_ready !== fa0_i_io_in_2_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_in_2_ready g=%h i=%h", cyc, fa0_g_io_in_2_ready, fa0_i_io_in_2_ready);
        end
        fa0_s1_io_in_2_ready |= fa0_g_io_in_2_ready;
        fa0_s0_io_in_2_ready |= ~fa0_g_io_in_2_ready;
        checks++;
        if (fa0_g_io_in_3_ready !== fa0_i_io_in_3_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_in_3_ready g=%h i=%h", cyc, fa0_g_io_in_3_ready, fa0_i_io_in_3_ready);
        end
        fa0_s1_io_in_3_ready |= fa0_g_io_in_3_ready;
        fa0_s0_io_in_3_ready |= ~fa0_g_io_in_3_ready;
        checks++;
        if (fa0_g_io_out_valid !== fa0_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_out_valid g=%h i=%h", cyc, fa0_g_io_out_valid, fa0_i_io_out_valid);
        end
        fa0_s1_io_out_valid |= fa0_g_io_out_valid;
        fa0_s0_io_out_valid |= ~fa0_g_io_out_valid;
        checks++;
        if (fa0_g_io_out_bits_tag !== fa0_i_io_out_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_out_bits_tag g=%h i=%h", cyc, fa0_g_io_out_bits_tag, fa0_i_io_out_bits_tag);
        end
        fa0_s1_io_out_bits_tag |= fa0_g_io_out_bits_tag;
        fa0_s0_io_out_bits_tag |= ~fa0_g_io_out_bits_tag;
        checks++;
        if (fa0_g_io_out_bits_set !== fa0_i_io_out_bits_set) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_out_bits_set g=%h i=%h", cyc, fa0_g_io_out_bits_set, fa0_i_io_out_bits_set);
        end
        fa0_s1_io_out_bits_set |= fa0_g_io_out_bits_set;
        fa0_s0_io_out_bits_set |= ~fa0_g_io_out_bits_set;
        checks++;
        if (fa0_g_io_out_bits_needT !== fa0_i_io_out_bits_needT) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_out_bits_needT g=%h i=%h", cyc, fa0_g_io_out_bits_needT, fa0_i_io_out_bits_needT);
        end
        fa0_s1_io_out_bits_needT |= fa0_g_io_out_bits_needT;
        fa0_s0_io_out_bits_needT |= ~fa0_g_io_out_bits_needT;
        checks++;
        if (fa0_g_io_out_bits_source !== fa0_i_io_out_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_out_bits_source g=%h i=%h", cyc, fa0_g_io_out_bits_source, fa0_i_io_out_bits_source);
        end
        fa0_s1_io_out_bits_source |= fa0_g_io_out_bits_source;
        fa0_s0_io_out_bits_source |= ~fa0_g_io_out_bits_source;
        checks++;
        if (fa0_g_io_out_bits_vaddr !== fa0_i_io_out_bits_vaddr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_out_bits_vaddr g=%h i=%h", cyc, fa0_g_io_out_bits_vaddr, fa0_i_io_out_bits_vaddr);
        end
        fa0_s1_io_out_bits_vaddr |= fa0_g_io_out_bits_vaddr;
        fa0_s0_io_out_bits_vaddr |= ~fa0_g_io_out_bits_vaddr;
        checks++;
        if (fa0_g_io_out_bits_reqsource !== fa0_i_io_out_bits_reqsource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter.io_out_bits_reqsource g=%h i=%h", cyc, fa0_g_io_out_bits_reqsource, fa0_i_io_out_bits_reqsource);
        end
        fa0_s1_io_out_bits_reqsource |= fa0_g_io_out_bits_reqsource;
        fa0_s0_io_out_bits_reqsource |= ~fa0_g_io_out_bits_reqsource;
        if (fa0_io_out_ready && fa0_g_io_out_valid) fa0_cov_fire++;
        if (fa0_io_in_0_valid && fa0_io_in_3_valid && fa0_io_out_ready) fa0_cov_contend++;
        if (|(fa0_u_gold.rrSelOH & fa0_u_gold.valids)) fa0_cov_rr_pick++;
        if (fa0_g_io_in_3_ready) fa0_cov_grant3++;
        if (fa0_g_io_in_0_ready) fa0_cov_grant0++;
      end
      if (fa0_armed_at < 0 && (&fa0_armed)) fa0_armed_at = cyc + 1;
      fa1_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&fa1_armed)) begin
        checks++;
        if (fa1_g_io_in_0_ready !== fa1_i_io_in_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_1.io_in_0_ready g=%h i=%h", cyc, fa1_g_io_in_0_ready, fa1_i_io_in_0_ready);
        end
        fa1_s1_io_in_0_ready |= fa1_g_io_in_0_ready;
        fa1_s0_io_in_0_ready |= ~fa1_g_io_in_0_ready;
        checks++;
        if (fa1_g_io_in_1_ready !== fa1_i_io_in_1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_1.io_in_1_ready g=%h i=%h", cyc, fa1_g_io_in_1_ready, fa1_i_io_in_1_ready);
        end
        fa1_s1_io_in_1_ready |= fa1_g_io_in_1_ready;
        fa1_s0_io_in_1_ready |= ~fa1_g_io_in_1_ready;
        checks++;
        if (fa1_g_io_in_2_ready !== fa1_i_io_in_2_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_1.io_in_2_ready g=%h i=%h", cyc, fa1_g_io_in_2_ready, fa1_i_io_in_2_ready);
        end
        fa1_s1_io_in_2_ready |= fa1_g_io_in_2_ready;
        fa1_s0_io_in_2_ready |= ~fa1_g_io_in_2_ready;
        checks++;
        if (fa1_g_io_in_3_ready !== fa1_i_io_in_3_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_1.io_in_3_ready g=%h i=%h", cyc, fa1_g_io_in_3_ready, fa1_i_io_in_3_ready);
        end
        fa1_s1_io_in_3_ready |= fa1_g_io_in_3_ready;
        fa1_s0_io_in_3_ready |= ~fa1_g_io_in_3_ready;
        checks++;
        if (fa1_g_io_out_valid !== fa1_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_1.io_out_valid g=%h i=%h", cyc, fa1_g_io_out_valid, fa1_i_io_out_valid);
        end
        fa1_s1_io_out_valid |= fa1_g_io_out_valid;
        fa1_s0_io_out_valid |= ~fa1_g_io_out_valid;
        checks++;
        if (fa1_g_io_out_bits_pfSource !== fa1_i_io_out_bits_pfSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_1.io_out_bits_pfSource g=%h i=%h", cyc, fa1_g_io_out_bits_pfSource, fa1_i_io_out_bits_pfSource);
        end
        fa1_s1_io_out_bits_pfSource |= fa1_g_io_out_bits_pfSource;
        fa1_s0_io_out_bits_pfSource |= ~fa1_g_io_out_bits_pfSource;
        if (fa1_io_out_ready && fa1_g_io_out_valid) fa1_cov_fire++;
        if (fa1_io_in_0_valid && fa1_io_in_3_valid && fa1_io_out_ready) fa1_cov_contend++;
        if (|(fa1_u_gold.rrSelOH & fa1_u_gold.valids)) fa1_cov_rr_pick++;
        if (fa1_g_io_in_3_ready) fa1_cov_grant3++;
        if (fa1_g_io_in_0_ready) fa1_cov_grant0++;
      end
      if (fa1_armed_at < 0 && (&fa1_armed)) fa1_armed_at = cyc + 1;
      fa26_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&fa26_armed)) begin
        checks++;
        if (fa26_g_io_in_0_ready !== fa26_i_io_in_0_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_in_0_ready g=%h i=%h", cyc, fa26_g_io_in_0_ready, fa26_i_io_in_0_ready);
        end
        fa26_s1_io_in_0_ready |= fa26_g_io_in_0_ready;
        fa26_s0_io_in_0_ready |= ~fa26_g_io_in_0_ready;
        checks++;
        if (fa26_g_io_in_1_ready !== fa26_i_io_in_1_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_in_1_ready g=%h i=%h", cyc, fa26_g_io_in_1_ready, fa26_i_io_in_1_ready);
        end
        fa26_s1_io_in_1_ready |= fa26_g_io_in_1_ready;
        fa26_s0_io_in_1_ready |= ~fa26_g_io_in_1_ready;
        checks++;
        if (fa26_g_io_in_2_ready !== fa26_i_io_in_2_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_in_2_ready g=%h i=%h", cyc, fa26_g_io_in_2_ready, fa26_i_io_in_2_ready);
        end
        fa26_s1_io_in_2_ready |= fa26_g_io_in_2_ready;
        fa26_s0_io_in_2_ready |= ~fa26_g_io_in_2_ready;
        checks++;
        if (fa26_g_io_in_3_ready !== fa26_i_io_in_3_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_in_3_ready g=%h i=%h", cyc, fa26_g_io_in_3_ready, fa26_i_io_in_3_ready);
        end
        fa26_s1_io_in_3_ready |= fa26_g_io_in_3_ready;
        fa26_s0_io_in_3_ready |= ~fa26_g_io_in_3_ready;
        checks++;
        if (fa26_g_io_out_valid !== fa26_i_io_out_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_valid g=%h i=%h", cyc, fa26_g_io_out_valid, fa26_i_io_out_valid);
        end
        fa26_s1_io_out_valid |= fa26_g_io_out_valid;
        fa26_s0_io_out_valid |= ~fa26_g_io_out_valid;
        checks++;
        if (fa26_g_io_out_bits_qos !== fa26_i_io_out_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_qos g=%h i=%h", cyc, fa26_g_io_out_bits_qos, fa26_i_io_out_bits_qos);
        end
        fa26_s1_io_out_bits_qos |= fa26_g_io_out_bits_qos;
        fa26_s0_io_out_bits_qos |= ~fa26_g_io_out_bits_qos;
        checks++;
        if (fa26_g_io_out_bits_tgtID !== fa26_i_io_out_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_tgtID g=%h i=%h", cyc, fa26_g_io_out_bits_tgtID, fa26_i_io_out_bits_tgtID);
        end
        fa26_s1_io_out_bits_tgtID |= fa26_g_io_out_bits_tgtID;
        fa26_s0_io_out_bits_tgtID |= ~fa26_g_io_out_bits_tgtID;
        checks++;
        if (fa26_g_io_out_bits_txnID !== fa26_i_io_out_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_txnID g=%h i=%h", cyc, fa26_g_io_out_bits_txnID, fa26_i_io_out_bits_txnID);
        end
        fa26_s1_io_out_bits_txnID |= fa26_g_io_out_bits_txnID;
        fa26_s0_io_out_bits_txnID |= ~fa26_g_io_out_bits_txnID;
        checks++;
        if (fa26_g_io_out_bits_opcode !== fa26_i_io_out_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_opcode g=%h i=%h", cyc, fa26_g_io_out_bits_opcode, fa26_i_io_out_bits_opcode);
        end
        fa26_s1_io_out_bits_opcode |= fa26_g_io_out_bits_opcode;
        fa26_s0_io_out_bits_opcode |= ~fa26_g_io_out_bits_opcode;
        checks++;
        if (fa26_g_io_out_bits_respErr !== fa26_i_io_out_bits_respErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_respErr g=%h i=%h", cyc, fa26_g_io_out_bits_respErr, fa26_i_io_out_bits_respErr);
        end
        fa26_s1_io_out_bits_respErr |= fa26_g_io_out_bits_respErr;
        fa26_s0_io_out_bits_respErr |= ~fa26_g_io_out_bits_respErr;
        checks++;
        if (fa26_g_io_out_bits_resp !== fa26_i_io_out_bits_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_resp g=%h i=%h", cyc, fa26_g_io_out_bits_resp, fa26_i_io_out_bits_resp);
        end
        fa26_s1_io_out_bits_resp |= fa26_g_io_out_bits_resp;
        fa26_s0_io_out_bits_resp |= ~fa26_g_io_out_bits_resp;
        checks++;
        if (fa26_g_io_out_bits_fwdState !== fa26_i_io_out_bits_fwdState) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_fwdState g=%h i=%h", cyc, fa26_g_io_out_bits_fwdState, fa26_i_io_out_bits_fwdState);
        end
        fa26_s1_io_out_bits_fwdState |= fa26_g_io_out_bits_fwdState;
        fa26_s0_io_out_bits_fwdState |= ~fa26_g_io_out_bits_fwdState;
        checks++;
        if (fa26_g_io_out_bits_cBusy !== fa26_i_io_out_bits_cBusy) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_cBusy g=%h i=%h", cyc, fa26_g_io_out_bits_cBusy, fa26_i_io_out_bits_cBusy);
        end
        fa26_s1_io_out_bits_cBusy |= fa26_g_io_out_bits_cBusy;
        fa26_s0_io_out_bits_cBusy |= ~fa26_g_io_out_bits_cBusy;
        checks++;
        if (fa26_g_io_out_bits_dbID !== fa26_i_io_out_bits_dbID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_dbID g=%h i=%h", cyc, fa26_g_io_out_bits_dbID, fa26_i_io_out_bits_dbID);
        end
        fa26_s1_io_out_bits_dbID |= fa26_g_io_out_bits_dbID;
        fa26_s0_io_out_bits_dbID |= ~fa26_g_io_out_bits_dbID;
        checks++;
        if (fa26_g_io_out_bits_pCrdType !== fa26_i_io_out_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_pCrdType g=%h i=%h", cyc, fa26_g_io_out_bits_pCrdType, fa26_i_io_out_bits_pCrdType);
        end
        fa26_s1_io_out_bits_pCrdType |= fa26_g_io_out_bits_pCrdType;
        fa26_s0_io_out_bits_pCrdType |= ~fa26_g_io_out_bits_pCrdType;
        checks++;
        if (fa26_g_io_out_bits_tagOp !== fa26_i_io_out_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_tagOp g=%h i=%h", cyc, fa26_g_io_out_bits_tagOp, fa26_i_io_out_bits_tagOp);
        end
        fa26_s1_io_out_bits_tagOp |= fa26_g_io_out_bits_tagOp;
        fa26_s0_io_out_bits_tagOp |= ~fa26_g_io_out_bits_tagOp;
        checks++;
        if (fa26_g_io_out_bits_traceTag !== fa26_i_io_out_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_out_bits_traceTag g=%h i=%h", cyc, fa26_g_io_out_bits_traceTag, fa26_i_io_out_bits_traceTag);
        end
        fa26_s1_io_out_bits_traceTag |= fa26_g_io_out_bits_traceTag;
        fa26_s0_io_out_bits_traceTag |= ~fa26_g_io_out_bits_traceTag;
        checks++;
        if (fa26_g_io_chosen !== fa26_i_io_chosen) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d FastArbiter_26.io_chosen g=%h i=%h", cyc, fa26_g_io_chosen, fa26_i_io_chosen);
        end
        fa26_s1_io_chosen |= fa26_g_io_chosen;
        fa26_s0_io_chosen |= ~fa26_g_io_chosen;
        if (fa26_io_out_ready && fa26_g_io_out_valid) fa26_cov_fire++;
        if (fa26_io_in_0_valid && fa26_io_in_3_valid && fa26_io_out_ready) fa26_cov_contend++;
        if (|(fa26_u_gold.rrSelOH & fa26_u_gold.valids)) fa26_cov_rr_pick++;
        if (fa26_g_io_in_3_ready) fa26_cov_grant3++;
        if (fa26_g_io_in_0_ready) fa26_cov_grant0++;
      end
      if (fa26_armed_at < 0 && (&fa26_armed)) fa26_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(fa0_s0_io_in_0_ready && fa0_s1_io_in_0_ready)) begin cov_fail++; $display("[COV] FastArbiter.io_in_0_ready 未见过 0 和 1"); end
    if (!(fa0_s0_io_in_1_ready && fa0_s1_io_in_1_ready)) begin cov_fail++; $display("[COV] FastArbiter.io_in_1_ready 未见过 0 和 1"); end
    if (!(fa0_s0_io_in_2_ready && fa0_s1_io_in_2_ready)) begin cov_fail++; $display("[COV] FastArbiter.io_in_2_ready 未见过 0 和 1"); end
    if (!(fa0_s0_io_in_3_ready && fa0_s1_io_in_3_ready)) begin cov_fail++; $display("[COV] FastArbiter.io_in_3_ready 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_valid && fa0_s1_io_out_valid)) begin cov_fail++; $display("[COV] FastArbiter.io_out_valid 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[0] && fa0_s1_io_out_bits_tag[0])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[0] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[1] && fa0_s1_io_out_bits_tag[1])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[1] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[2] && fa0_s1_io_out_bits_tag[2])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[2] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[3] && fa0_s1_io_out_bits_tag[3])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[3] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[4] && fa0_s1_io_out_bits_tag[4])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[4] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[5] && fa0_s1_io_out_bits_tag[5])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[5] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[6] && fa0_s1_io_out_bits_tag[6])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[6] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[7] && fa0_s1_io_out_bits_tag[7])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[7] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[8] && fa0_s1_io_out_bits_tag[8])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[8] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[9] && fa0_s1_io_out_bits_tag[9])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[9] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[10] && fa0_s1_io_out_bits_tag[10])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[10] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[11] && fa0_s1_io_out_bits_tag[11])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[11] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[12] && fa0_s1_io_out_bits_tag[12])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[12] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[13] && fa0_s1_io_out_bits_tag[13])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[13] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[14] && fa0_s1_io_out_bits_tag[14])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[14] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[15] && fa0_s1_io_out_bits_tag[15])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[15] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[16] && fa0_s1_io_out_bits_tag[16])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[16] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[17] && fa0_s1_io_out_bits_tag[17])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[17] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[18] && fa0_s1_io_out_bits_tag[18])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[18] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[19] && fa0_s1_io_out_bits_tag[19])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[19] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[20] && fa0_s1_io_out_bits_tag[20])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[20] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[21] && fa0_s1_io_out_bits_tag[21])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[21] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[22] && fa0_s1_io_out_bits_tag[22])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[22] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[23] && fa0_s1_io_out_bits_tag[23])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[23] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[24] && fa0_s1_io_out_bits_tag[24])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[24] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[25] && fa0_s1_io_out_bits_tag[25])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[25] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[26] && fa0_s1_io_out_bits_tag[26])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[26] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[27] && fa0_s1_io_out_bits_tag[27])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[27] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[28] && fa0_s1_io_out_bits_tag[28])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[28] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[29] && fa0_s1_io_out_bits_tag[29])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[29] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[30] && fa0_s1_io_out_bits_tag[30])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[30] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[31] && fa0_s1_io_out_bits_tag[31])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[31] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_tag[32] && fa0_s1_io_out_bits_tag[32])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_tag[32] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[0] && fa0_s1_io_out_bits_set[0])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[0] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[1] && fa0_s1_io_out_bits_set[1])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[1] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[2] && fa0_s1_io_out_bits_set[2])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[2] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[3] && fa0_s1_io_out_bits_set[3])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[3] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[4] && fa0_s1_io_out_bits_set[4])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[4] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[5] && fa0_s1_io_out_bits_set[5])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[5] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[6] && fa0_s1_io_out_bits_set[6])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[6] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[7] && fa0_s1_io_out_bits_set[7])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[7] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_set[8] && fa0_s1_io_out_bits_set[8])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_set[8] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_needT && fa0_s1_io_out_bits_needT)) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_needT 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_source[0] && fa0_s1_io_out_bits_source[0])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_source[0] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_source[1] && fa0_s1_io_out_bits_source[1])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_source[1] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_source[2] && fa0_s1_io_out_bits_source[2])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_source[2] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_source[3] && fa0_s1_io_out_bits_source[3])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_source[3] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_source[4] && fa0_s1_io_out_bits_source[4])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_source[4] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_source[5] && fa0_s1_io_out_bits_source[5])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_source[5] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_source[6] && fa0_s1_io_out_bits_source[6])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_source[6] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[0] && fa0_s1_io_out_bits_vaddr[0])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[0] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[1] && fa0_s1_io_out_bits_vaddr[1])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[1] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[2] && fa0_s1_io_out_bits_vaddr[2])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[2] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[3] && fa0_s1_io_out_bits_vaddr[3])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[3] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[4] && fa0_s1_io_out_bits_vaddr[4])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[4] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[5] && fa0_s1_io_out_bits_vaddr[5])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[5] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[6] && fa0_s1_io_out_bits_vaddr[6])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[6] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[7] && fa0_s1_io_out_bits_vaddr[7])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[7] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[8] && fa0_s1_io_out_bits_vaddr[8])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[8] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[9] && fa0_s1_io_out_bits_vaddr[9])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[9] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[10] && fa0_s1_io_out_bits_vaddr[10])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[10] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[11] && fa0_s1_io_out_bits_vaddr[11])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[11] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[12] && fa0_s1_io_out_bits_vaddr[12])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[12] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[13] && fa0_s1_io_out_bits_vaddr[13])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[13] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[14] && fa0_s1_io_out_bits_vaddr[14])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[14] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[15] && fa0_s1_io_out_bits_vaddr[15])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[15] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[16] && fa0_s1_io_out_bits_vaddr[16])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[16] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[17] && fa0_s1_io_out_bits_vaddr[17])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[17] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[18] && fa0_s1_io_out_bits_vaddr[18])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[18] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[19] && fa0_s1_io_out_bits_vaddr[19])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[19] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[20] && fa0_s1_io_out_bits_vaddr[20])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[20] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[21] && fa0_s1_io_out_bits_vaddr[21])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[21] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[22] && fa0_s1_io_out_bits_vaddr[22])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[22] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[23] && fa0_s1_io_out_bits_vaddr[23])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[23] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[24] && fa0_s1_io_out_bits_vaddr[24])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[24] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[25] && fa0_s1_io_out_bits_vaddr[25])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[25] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[26] && fa0_s1_io_out_bits_vaddr[26])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[26] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[27] && fa0_s1_io_out_bits_vaddr[27])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[27] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[28] && fa0_s1_io_out_bits_vaddr[28])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[28] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[29] && fa0_s1_io_out_bits_vaddr[29])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[29] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[30] && fa0_s1_io_out_bits_vaddr[30])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[30] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[31] && fa0_s1_io_out_bits_vaddr[31])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[31] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[32] && fa0_s1_io_out_bits_vaddr[32])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[32] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[33] && fa0_s1_io_out_bits_vaddr[33])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[33] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[34] && fa0_s1_io_out_bits_vaddr[34])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[34] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[35] && fa0_s1_io_out_bits_vaddr[35])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[35] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[36] && fa0_s1_io_out_bits_vaddr[36])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[36] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[37] && fa0_s1_io_out_bits_vaddr[37])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[37] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[38] && fa0_s1_io_out_bits_vaddr[38])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[38] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[39] && fa0_s1_io_out_bits_vaddr[39])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[39] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[40] && fa0_s1_io_out_bits_vaddr[40])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[40] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[41] && fa0_s1_io_out_bits_vaddr[41])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[41] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[42] && fa0_s1_io_out_bits_vaddr[42])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[42] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_vaddr[43] && fa0_s1_io_out_bits_vaddr[43])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_vaddr[43] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_reqsource[0] && fa0_s1_io_out_bits_reqsource[0])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_reqsource[0] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_reqsource[1] && fa0_s1_io_out_bits_reqsource[1])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_reqsource[1] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_reqsource[2] && fa0_s1_io_out_bits_reqsource[2])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_reqsource[2] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_reqsource[3] && fa0_s1_io_out_bits_reqsource[3])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_reqsource[3] 未见过 0 和 1"); end
    if (!(fa0_s0_io_out_bits_reqsource[4] && fa0_s1_io_out_bits_reqsource[4])) begin cov_fail++; $display("[COV] FastArbiter.io_out_bits_reqsource[4] 未见过 0 和 1"); end
    $display("[ARM] FastArbiter armed_at=%0d", fa0_armed_at);
    if (fa0_armed_at < 0) begin cov_fail++; $display("[ARM] FastArbiter 从未 arm"); end
    $display("[COV] FastArbiter.fire = %0d", fa0_cov_fire);
    if (fa0_cov_fire < 100) begin cov_fail++; $display("[COV] FastArbiter.fire < 100"); end
    $display("[COV] FastArbiter.contend = %0d", fa0_cov_contend);
    if (fa0_cov_contend < 100) begin cov_fail++; $display("[COV] FastArbiter.contend < 100"); end
    $display("[COV] FastArbiter.rr_pick = %0d", fa0_cov_rr_pick);
    if (fa0_cov_rr_pick < 100) begin cov_fail++; $display("[COV] FastArbiter.rr_pick < 100"); end
    $display("[COV] FastArbiter.grant3 = %0d", fa0_cov_grant3);
    if (fa0_cov_grant3 < 100) begin cov_fail++; $display("[COV] FastArbiter.grant3 < 100"); end
    $display("[COV] FastArbiter.grant0 = %0d", fa0_cov_grant0);
    if (fa0_cov_grant0 < 100) begin cov_fail++; $display("[COV] FastArbiter.grant0 < 100"); end
    if (!(fa1_s0_io_in_0_ready && fa1_s1_io_in_0_ready)) begin cov_fail++; $display("[COV] FastArbiter_1.io_in_0_ready 未见过 0 和 1"); end
    if (!(fa1_s0_io_in_1_ready && fa1_s1_io_in_1_ready)) begin cov_fail++; $display("[COV] FastArbiter_1.io_in_1_ready 未见过 0 和 1"); end
    if (!(fa1_s0_io_in_2_ready && fa1_s1_io_in_2_ready)) begin cov_fail++; $display("[COV] FastArbiter_1.io_in_2_ready 未见过 0 和 1"); end
    if (!(fa1_s0_io_in_3_ready && fa1_s1_io_in_3_ready)) begin cov_fail++; $display("[COV] FastArbiter_1.io_in_3_ready 未见过 0 和 1"); end
    if (!(fa1_s0_io_out_valid && fa1_s1_io_out_valid)) begin cov_fail++; $display("[COV] FastArbiter_1.io_out_valid 未见过 0 和 1"); end
    if (!(fa1_s0_io_out_bits_pfSource[0] && fa1_s1_io_out_bits_pfSource[0])) begin cov_fail++; $display("[COV] FastArbiter_1.io_out_bits_pfSource[0] 未见过 0 和 1"); end
    if (!(fa1_s0_io_out_bits_pfSource[1] && fa1_s1_io_out_bits_pfSource[1])) begin cov_fail++; $display("[COV] FastArbiter_1.io_out_bits_pfSource[1] 未见过 0 和 1"); end
    if (!(fa1_s0_io_out_bits_pfSource[2] && fa1_s1_io_out_bits_pfSource[2])) begin cov_fail++; $display("[COV] FastArbiter_1.io_out_bits_pfSource[2] 未见过 0 和 1"); end
    if (!(fa1_s0_io_out_bits_pfSource[3] && fa1_s1_io_out_bits_pfSource[3])) begin cov_fail++; $display("[COV] FastArbiter_1.io_out_bits_pfSource[3] 未见过 0 和 1"); end
    if (!(fa1_s0_io_out_bits_pfSource[4] && fa1_s1_io_out_bits_pfSource[4])) begin cov_fail++; $display("[COV] FastArbiter_1.io_out_bits_pfSource[4] 未见过 0 和 1"); end
    $display("[ARM] FastArbiter_1 armed_at=%0d", fa1_armed_at);
    if (fa1_armed_at < 0) begin cov_fail++; $display("[ARM] FastArbiter_1 从未 arm"); end
    $display("[COV] FastArbiter_1.fire = %0d", fa1_cov_fire);
    if (fa1_cov_fire < 100) begin cov_fail++; $display("[COV] FastArbiter_1.fire < 100"); end
    $display("[COV] FastArbiter_1.contend = %0d", fa1_cov_contend);
    if (fa1_cov_contend < 100) begin cov_fail++; $display("[COV] FastArbiter_1.contend < 100"); end
    $display("[COV] FastArbiter_1.rr_pick = %0d", fa1_cov_rr_pick);
    if (fa1_cov_rr_pick < 100) begin cov_fail++; $display("[COV] FastArbiter_1.rr_pick < 100"); end
    $display("[COV] FastArbiter_1.grant3 = %0d", fa1_cov_grant3);
    if (fa1_cov_grant3 < 100) begin cov_fail++; $display("[COV] FastArbiter_1.grant3 < 100"); end
    $display("[COV] FastArbiter_1.grant0 = %0d", fa1_cov_grant0);
    if (fa1_cov_grant0 < 100) begin cov_fail++; $display("[COV] FastArbiter_1.grant0 < 100"); end
    if (!(fa26_s0_io_in_0_ready && fa26_s1_io_in_0_ready)) begin cov_fail++; $display("[COV] FastArbiter_26.io_in_0_ready 未见过 0 和 1"); end
    if (!(fa26_s0_io_in_1_ready && fa26_s1_io_in_1_ready)) begin cov_fail++; $display("[COV] FastArbiter_26.io_in_1_ready 未见过 0 和 1"); end
    if (!(fa26_s0_io_in_2_ready && fa26_s1_io_in_2_ready)) begin cov_fail++; $display("[COV] FastArbiter_26.io_in_2_ready 未见过 0 和 1"); end
    if (!(fa26_s0_io_in_3_ready && fa26_s1_io_in_3_ready)) begin cov_fail++; $display("[COV] FastArbiter_26.io_in_3_ready 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_valid && fa26_s1_io_out_valid)) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_valid 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_qos[0] && fa26_s1_io_out_bits_qos[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_qos[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_qos[1] && fa26_s1_io_out_bits_qos[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_qos[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_qos[2] && fa26_s1_io_out_bits_qos[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_qos[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_qos[3] && fa26_s1_io_out_bits_qos[3])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_qos[3] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[0] && fa26_s1_io_out_bits_tgtID[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[1] && fa26_s1_io_out_bits_tgtID[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[2] && fa26_s1_io_out_bits_tgtID[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[3] && fa26_s1_io_out_bits_tgtID[3])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[3] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[4] && fa26_s1_io_out_bits_tgtID[4])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[4] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[5] && fa26_s1_io_out_bits_tgtID[5])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[5] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[6] && fa26_s1_io_out_bits_tgtID[6])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[6] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[7] && fa26_s1_io_out_bits_tgtID[7])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[7] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[8] && fa26_s1_io_out_bits_tgtID[8])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[8] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[9] && fa26_s1_io_out_bits_tgtID[9])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[9] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tgtID[10] && fa26_s1_io_out_bits_tgtID[10])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tgtID[10] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[0] && fa26_s1_io_out_bits_txnID[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[1] && fa26_s1_io_out_bits_txnID[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[2] && fa26_s1_io_out_bits_txnID[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[3] && fa26_s1_io_out_bits_txnID[3])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[3] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[4] && fa26_s1_io_out_bits_txnID[4])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[4] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[5] && fa26_s1_io_out_bits_txnID[5])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[5] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[6] && fa26_s1_io_out_bits_txnID[6])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[6] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[7] && fa26_s1_io_out_bits_txnID[7])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[7] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[8] && fa26_s1_io_out_bits_txnID[8])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[8] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[9] && fa26_s1_io_out_bits_txnID[9])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[9] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[10] && fa26_s1_io_out_bits_txnID[10])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[10] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_txnID[11] && fa26_s1_io_out_bits_txnID[11])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_txnID[11] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_opcode[0] && fa26_s1_io_out_bits_opcode[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_opcode[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_opcode[1] && fa26_s1_io_out_bits_opcode[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_opcode[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_opcode[2] && fa26_s1_io_out_bits_opcode[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_opcode[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_opcode[3] && fa26_s1_io_out_bits_opcode[3])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_opcode[3] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_opcode[4] && fa26_s1_io_out_bits_opcode[4])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_opcode[4] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_respErr[0] && fa26_s1_io_out_bits_respErr[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_respErr[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_respErr[1] && fa26_s1_io_out_bits_respErr[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_respErr[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_resp[0] && fa26_s1_io_out_bits_resp[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_resp[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_resp[1] && fa26_s1_io_out_bits_resp[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_resp[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_resp[2] && fa26_s1_io_out_bits_resp[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_resp[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_fwdState[0] && fa26_s1_io_out_bits_fwdState[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_fwdState[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_fwdState[1] && fa26_s1_io_out_bits_fwdState[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_fwdState[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_fwdState[2] && fa26_s1_io_out_bits_fwdState[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_fwdState[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_cBusy[0] && fa26_s1_io_out_bits_cBusy[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_cBusy[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_cBusy[1] && fa26_s1_io_out_bits_cBusy[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_cBusy[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_cBusy[2] && fa26_s1_io_out_bits_cBusy[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_cBusy[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[0] && fa26_s1_io_out_bits_dbID[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[1] && fa26_s1_io_out_bits_dbID[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[2] && fa26_s1_io_out_bits_dbID[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[3] && fa26_s1_io_out_bits_dbID[3])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[3] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[4] && fa26_s1_io_out_bits_dbID[4])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[4] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[5] && fa26_s1_io_out_bits_dbID[5])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[5] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[6] && fa26_s1_io_out_bits_dbID[6])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[6] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[7] && fa26_s1_io_out_bits_dbID[7])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[7] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[8] && fa26_s1_io_out_bits_dbID[8])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[8] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[9] && fa26_s1_io_out_bits_dbID[9])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[9] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[10] && fa26_s1_io_out_bits_dbID[10])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[10] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_dbID[11] && fa26_s1_io_out_bits_dbID[11])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_dbID[11] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_pCrdType[0] && fa26_s1_io_out_bits_pCrdType[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_pCrdType[1] && fa26_s1_io_out_bits_pCrdType[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_pCrdType[2] && fa26_s1_io_out_bits_pCrdType[2])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_pCrdType[3] && fa26_s1_io_out_bits_pCrdType[3])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tagOp[0] && fa26_s1_io_out_bits_tagOp[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tagOp[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_tagOp[1] && fa26_s1_io_out_bits_tagOp[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_tagOp[1] 未见过 0 和 1"); end
    if (!(fa26_s0_io_out_bits_traceTag && fa26_s1_io_out_bits_traceTag)) begin cov_fail++; $display("[COV] FastArbiter_26.io_out_bits_traceTag 未见过 0 和 1"); end
    if (!(fa26_s0_io_chosen[0] && fa26_s1_io_chosen[0])) begin cov_fail++; $display("[COV] FastArbiter_26.io_chosen[0] 未见过 0 和 1"); end
    if (!(fa26_s0_io_chosen[1] && fa26_s1_io_chosen[1])) begin cov_fail++; $display("[COV] FastArbiter_26.io_chosen[1] 未见过 0 和 1"); end
    $display("[ARM] FastArbiter_26 armed_at=%0d", fa26_armed_at);
    if (fa26_armed_at < 0) begin cov_fail++; $display("[ARM] FastArbiter_26 从未 arm"); end
    $display("[COV] FastArbiter_26.fire = %0d", fa26_cov_fire);
    if (fa26_cov_fire < 100) begin cov_fail++; $display("[COV] FastArbiter_26.fire < 100"); end
    $display("[COV] FastArbiter_26.contend = %0d", fa26_cov_contend);
    if (fa26_cov_contend < 100) begin cov_fail++; $display("[COV] FastArbiter_26.contend < 100"); end
    $display("[COV] FastArbiter_26.rr_pick = %0d", fa26_cov_rr_pick);
    if (fa26_cov_rr_pick < 100) begin cov_fail++; $display("[COV] FastArbiter_26.rr_pick < 100"); end
    $display("[COV] FastArbiter_26.grant3 = %0d", fa26_cov_grant3);
    if (fa26_cov_grant3 < 100) begin cov_fail++; $display("[COV] FastArbiter_26.grant3 < 100"); end
    $display("[COV] FastArbiter_26.grant0 = %0d", fa26_cov_grant0);
    if (fa26_cov_grant0 < 100) begin cov_fail++; $display("[COV] FastArbiter_26.grant0 < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule

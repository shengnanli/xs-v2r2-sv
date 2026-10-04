// tb —— LinkMonitor：L2 的 CHI 链路层（链路激活握手 + L-Credit 流控 + flit 打包/解包）双例化 UT。
// 本文件由 gen.py 生成（scripts/dual_tb_lib.py），勿手改。
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= LinkMonitor =================
  int unsigned lm_mode = 0;
  logic lm_reset;
  wire  lm_g_io_in_tx_req_ready, lm_i_io_in_tx_req_ready;
  logic lm_s0_io_in_tx_req_ready = '0, lm_s1_io_in_tx_req_ready = '0;
  logic lm_io_in_tx_req_valid;
  logic [3:0] lm_io_in_tx_req_bits_qos;
  logic [10:0] lm_io_in_tx_req_bits_tgtID;
  logic [11:0] lm_io_in_tx_req_bits_txnID;
  logic [10:0] lm_io_in_tx_req_bits_returnNID;
  logic lm_io_in_tx_req_bits_stashNIDValid;
  logic [11:0] lm_io_in_tx_req_bits_returnTxnID;
  logic [6:0] lm_io_in_tx_req_bits_opcode;
  logic [2:0] lm_io_in_tx_req_bits_size;
  logic [47:0] lm_io_in_tx_req_bits_addr;
  logic lm_io_in_tx_req_bits_ns;
  logic lm_io_in_tx_req_bits_likelyshared;
  logic lm_io_in_tx_req_bits_allowRetry;
  logic [1:0] lm_io_in_tx_req_bits_order;
  logic [3:0] lm_io_in_tx_req_bits_pCrdType;
  logic lm_io_in_tx_req_bits_memAttr_allocate;
  logic lm_io_in_tx_req_bits_memAttr_cacheable;
  logic lm_io_in_tx_req_bits_memAttr_device;
  logic lm_io_in_tx_req_bits_memAttr_ewa;
  logic lm_io_in_tx_req_bits_snpAttr;
  logic [7:0] lm_io_in_tx_req_bits_lpIDWithPadding;
  logic lm_io_in_tx_req_bits_snoopMe;
  logic lm_io_in_tx_req_bits_expCompAck;
  logic [1:0] lm_io_in_tx_req_bits_tagOp;
  logic lm_io_in_tx_req_bits_traceTag;
  logic lm_io_in_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] lm_io_in_tx_req_bits_mpam_partID;
  logic lm_io_in_tx_req_bits_mpam_mpamNS;
  logic [3:0] lm_io_in_tx_req_bits_rsvdc;
  wire  lm_g_io_in_tx_rsp_ready, lm_i_io_in_tx_rsp_ready;
  logic lm_s0_io_in_tx_rsp_ready = '0, lm_s1_io_in_tx_rsp_ready = '0;
  logic lm_io_in_tx_rsp_valid;
  logic [3:0] lm_io_in_tx_rsp_bits_qos;
  logic [10:0] lm_io_in_tx_rsp_bits_tgtID;
  logic [11:0] lm_io_in_tx_rsp_bits_txnID;
  logic [4:0] lm_io_in_tx_rsp_bits_opcode;
  logic [1:0] lm_io_in_tx_rsp_bits_respErr;
  logic [2:0] lm_io_in_tx_rsp_bits_resp;
  logic [2:0] lm_io_in_tx_rsp_bits_fwdState;
  logic [2:0] lm_io_in_tx_rsp_bits_cBusy;
  logic [11:0] lm_io_in_tx_rsp_bits_dbID;
  logic [3:0] lm_io_in_tx_rsp_bits_pCrdType;
  logic [1:0] lm_io_in_tx_rsp_bits_tagOp;
  logic lm_io_in_tx_rsp_bits_traceTag;
  wire  lm_g_io_in_tx_dat_ready, lm_i_io_in_tx_dat_ready;
  logic lm_s0_io_in_tx_dat_ready = '0, lm_s1_io_in_tx_dat_ready = '0;
  logic lm_io_in_tx_dat_valid;
  logic [3:0] lm_io_in_tx_dat_bits_qos;
  logic [10:0] lm_io_in_tx_dat_bits_tgtID;
  logic [11:0] lm_io_in_tx_dat_bits_txnID;
  logic [10:0] lm_io_in_tx_dat_bits_homeNID;
  logic [3:0] lm_io_in_tx_dat_bits_opcode;
  logic [1:0] lm_io_in_tx_dat_bits_respErr;
  logic [2:0] lm_io_in_tx_dat_bits_resp;
  logic [3:0] lm_io_in_tx_dat_bits_dataSource;
  logic [2:0] lm_io_in_tx_dat_bits_cBusy;
  logic [11:0] lm_io_in_tx_dat_bits_dbID;
  logic [1:0] lm_io_in_tx_dat_bits_ccID;
  logic [1:0] lm_io_in_tx_dat_bits_dataID;
  logic [1:0] lm_io_in_tx_dat_bits_tagOp;
  logic [7:0] lm_io_in_tx_dat_bits_tag;
  logic [1:0] lm_io_in_tx_dat_bits_tu;
  logic lm_io_in_tx_dat_bits_traceTag;
  logic [3:0] lm_io_in_tx_dat_bits_rsvdc;
  logic [31:0] lm_io_in_tx_dat_bits_be;
  logic [255:0] lm_io_in_tx_dat_bits_data;
  logic [31:0] lm_io_in_tx_dat_bits_dataCheck;
  logic [3:0] lm_io_in_tx_dat_bits_poison;
  logic lm_io_in_rx_rsp_ready;
  wire  lm_g_io_in_rx_rsp_valid, lm_i_io_in_rx_rsp_valid;
  logic lm_s0_io_in_rx_rsp_valid = '0, lm_s1_io_in_rx_rsp_valid = '0;
  wire  [3:0] lm_g_io_in_rx_rsp_bits_qos, lm_i_io_in_rx_rsp_bits_qos;
  logic [3:0] lm_s0_io_in_rx_rsp_bits_qos = '0, lm_s1_io_in_rx_rsp_bits_qos = '0;
  wire  [10:0] lm_g_io_in_rx_rsp_bits_tgtID, lm_i_io_in_rx_rsp_bits_tgtID;
  logic [10:0] lm_s0_io_in_rx_rsp_bits_tgtID = '0, lm_s1_io_in_rx_rsp_bits_tgtID = '0;
  wire  [10:0] lm_g_io_in_rx_rsp_bits_srcID, lm_i_io_in_rx_rsp_bits_srcID;
  logic [10:0] lm_s0_io_in_rx_rsp_bits_srcID = '0, lm_s1_io_in_rx_rsp_bits_srcID = '0;
  wire  [11:0] lm_g_io_in_rx_rsp_bits_txnID, lm_i_io_in_rx_rsp_bits_txnID;
  logic [11:0] lm_s0_io_in_rx_rsp_bits_txnID = '0, lm_s1_io_in_rx_rsp_bits_txnID = '0;
  wire  [4:0] lm_g_io_in_rx_rsp_bits_opcode, lm_i_io_in_rx_rsp_bits_opcode;
  logic [4:0] lm_s0_io_in_rx_rsp_bits_opcode = '0, lm_s1_io_in_rx_rsp_bits_opcode = '0;
  wire  [1:0] lm_g_io_in_rx_rsp_bits_respErr, lm_i_io_in_rx_rsp_bits_respErr;
  logic [1:0] lm_s0_io_in_rx_rsp_bits_respErr = '0, lm_s1_io_in_rx_rsp_bits_respErr = '0;
  wire  [2:0] lm_g_io_in_rx_rsp_bits_resp, lm_i_io_in_rx_rsp_bits_resp;
  logic [2:0] lm_s0_io_in_rx_rsp_bits_resp = '0, lm_s1_io_in_rx_rsp_bits_resp = '0;
  wire  [2:0] lm_g_io_in_rx_rsp_bits_fwdState, lm_i_io_in_rx_rsp_bits_fwdState;
  logic [2:0] lm_s0_io_in_rx_rsp_bits_fwdState = '0, lm_s1_io_in_rx_rsp_bits_fwdState = '0;
  wire  [2:0] lm_g_io_in_rx_rsp_bits_cBusy, lm_i_io_in_rx_rsp_bits_cBusy;
  logic [2:0] lm_s0_io_in_rx_rsp_bits_cBusy = '0, lm_s1_io_in_rx_rsp_bits_cBusy = '0;
  wire  [11:0] lm_g_io_in_rx_rsp_bits_dbID, lm_i_io_in_rx_rsp_bits_dbID;
  logic [11:0] lm_s0_io_in_rx_rsp_bits_dbID = '0, lm_s1_io_in_rx_rsp_bits_dbID = '0;
  wire  [3:0] lm_g_io_in_rx_rsp_bits_pCrdType, lm_i_io_in_rx_rsp_bits_pCrdType;
  logic [3:0] lm_s0_io_in_rx_rsp_bits_pCrdType = '0, lm_s1_io_in_rx_rsp_bits_pCrdType = '0;
  wire  [1:0] lm_g_io_in_rx_rsp_bits_tagOp, lm_i_io_in_rx_rsp_bits_tagOp;
  logic [1:0] lm_s0_io_in_rx_rsp_bits_tagOp = '0, lm_s1_io_in_rx_rsp_bits_tagOp = '0;
  wire  lm_g_io_in_rx_rsp_bits_traceTag, lm_i_io_in_rx_rsp_bits_traceTag;
  logic lm_s0_io_in_rx_rsp_bits_traceTag = '0, lm_s1_io_in_rx_rsp_bits_traceTag = '0;
  logic lm_io_in_rx_dat_ready;
  wire  lm_g_io_in_rx_dat_valid, lm_i_io_in_rx_dat_valid;
  logic lm_s0_io_in_rx_dat_valid = '0, lm_s1_io_in_rx_dat_valid = '0;
  wire  [3:0] lm_g_io_in_rx_dat_bits_qos, lm_i_io_in_rx_dat_bits_qos;
  logic [3:0] lm_s0_io_in_rx_dat_bits_qos = '0, lm_s1_io_in_rx_dat_bits_qos = '0;
  wire  [10:0] lm_g_io_in_rx_dat_bits_tgtID, lm_i_io_in_rx_dat_bits_tgtID;
  logic [10:0] lm_s0_io_in_rx_dat_bits_tgtID = '0, lm_s1_io_in_rx_dat_bits_tgtID = '0;
  wire  [10:0] lm_g_io_in_rx_dat_bits_srcID, lm_i_io_in_rx_dat_bits_srcID;
  logic [10:0] lm_s0_io_in_rx_dat_bits_srcID = '0, lm_s1_io_in_rx_dat_bits_srcID = '0;
  wire  [11:0] lm_g_io_in_rx_dat_bits_txnID, lm_i_io_in_rx_dat_bits_txnID;
  logic [11:0] lm_s0_io_in_rx_dat_bits_txnID = '0, lm_s1_io_in_rx_dat_bits_txnID = '0;
  wire  [10:0] lm_g_io_in_rx_dat_bits_homeNID, lm_i_io_in_rx_dat_bits_homeNID;
  logic [10:0] lm_s0_io_in_rx_dat_bits_homeNID = '0, lm_s1_io_in_rx_dat_bits_homeNID = '0;
  wire  [3:0] lm_g_io_in_rx_dat_bits_opcode, lm_i_io_in_rx_dat_bits_opcode;
  logic [3:0] lm_s0_io_in_rx_dat_bits_opcode = '0, lm_s1_io_in_rx_dat_bits_opcode = '0;
  wire  [1:0] lm_g_io_in_rx_dat_bits_respErr, lm_i_io_in_rx_dat_bits_respErr;
  logic [1:0] lm_s0_io_in_rx_dat_bits_respErr = '0, lm_s1_io_in_rx_dat_bits_respErr = '0;
  wire  [2:0] lm_g_io_in_rx_dat_bits_resp, lm_i_io_in_rx_dat_bits_resp;
  logic [2:0] lm_s0_io_in_rx_dat_bits_resp = '0, lm_s1_io_in_rx_dat_bits_resp = '0;
  wire  [3:0] lm_g_io_in_rx_dat_bits_dataSource, lm_i_io_in_rx_dat_bits_dataSource;
  logic [3:0] lm_s0_io_in_rx_dat_bits_dataSource = '0, lm_s1_io_in_rx_dat_bits_dataSource = '0;
  wire  [2:0] lm_g_io_in_rx_dat_bits_cBusy, lm_i_io_in_rx_dat_bits_cBusy;
  logic [2:0] lm_s0_io_in_rx_dat_bits_cBusy = '0, lm_s1_io_in_rx_dat_bits_cBusy = '0;
  wire  [11:0] lm_g_io_in_rx_dat_bits_dbID, lm_i_io_in_rx_dat_bits_dbID;
  logic [11:0] lm_s0_io_in_rx_dat_bits_dbID = '0, lm_s1_io_in_rx_dat_bits_dbID = '0;
  wire  [1:0] lm_g_io_in_rx_dat_bits_ccID, lm_i_io_in_rx_dat_bits_ccID;
  logic [1:0] lm_s0_io_in_rx_dat_bits_ccID = '0, lm_s1_io_in_rx_dat_bits_ccID = '0;
  wire  [1:0] lm_g_io_in_rx_dat_bits_dataID, lm_i_io_in_rx_dat_bits_dataID;
  logic [1:0] lm_s0_io_in_rx_dat_bits_dataID = '0, lm_s1_io_in_rx_dat_bits_dataID = '0;
  wire  [1:0] lm_g_io_in_rx_dat_bits_tagOp, lm_i_io_in_rx_dat_bits_tagOp;
  logic [1:0] lm_s0_io_in_rx_dat_bits_tagOp = '0, lm_s1_io_in_rx_dat_bits_tagOp = '0;
  wire  [7:0] lm_g_io_in_rx_dat_bits_tag, lm_i_io_in_rx_dat_bits_tag;
  logic [7:0] lm_s0_io_in_rx_dat_bits_tag = '0, lm_s1_io_in_rx_dat_bits_tag = '0;
  wire  [1:0] lm_g_io_in_rx_dat_bits_tu, lm_i_io_in_rx_dat_bits_tu;
  logic [1:0] lm_s0_io_in_rx_dat_bits_tu = '0, lm_s1_io_in_rx_dat_bits_tu = '0;
  wire  lm_g_io_in_rx_dat_bits_traceTag, lm_i_io_in_rx_dat_bits_traceTag;
  logic lm_s0_io_in_rx_dat_bits_traceTag = '0, lm_s1_io_in_rx_dat_bits_traceTag = '0;
  wire  [3:0] lm_g_io_in_rx_dat_bits_rsvdc, lm_i_io_in_rx_dat_bits_rsvdc;
  logic [3:0] lm_s0_io_in_rx_dat_bits_rsvdc = '0, lm_s1_io_in_rx_dat_bits_rsvdc = '0;
  wire  [31:0] lm_g_io_in_rx_dat_bits_be, lm_i_io_in_rx_dat_bits_be;
  logic [31:0] lm_s0_io_in_rx_dat_bits_be = '0, lm_s1_io_in_rx_dat_bits_be = '0;
  wire  [255:0] lm_g_io_in_rx_dat_bits_data, lm_i_io_in_rx_dat_bits_data;
  logic [255:0] lm_s0_io_in_rx_dat_bits_data = '0, lm_s1_io_in_rx_dat_bits_data = '0;
  wire  [31:0] lm_g_io_in_rx_dat_bits_dataCheck, lm_i_io_in_rx_dat_bits_dataCheck;
  logic [31:0] lm_s0_io_in_rx_dat_bits_dataCheck = '0, lm_s1_io_in_rx_dat_bits_dataCheck = '0;
  wire  [3:0] lm_g_io_in_rx_dat_bits_poison, lm_i_io_in_rx_dat_bits_poison;
  logic [3:0] lm_s0_io_in_rx_dat_bits_poison = '0, lm_s1_io_in_rx_dat_bits_poison = '0;
  logic lm_io_in_rx_snp_ready;
  wire  lm_g_io_in_rx_snp_valid, lm_i_io_in_rx_snp_valid;
  logic lm_s0_io_in_rx_snp_valid = '0, lm_s1_io_in_rx_snp_valid = '0;
  wire  [3:0] lm_g_io_in_rx_snp_bits_qos, lm_i_io_in_rx_snp_bits_qos;
  logic [3:0] lm_s0_io_in_rx_snp_bits_qos = '0, lm_s1_io_in_rx_snp_bits_qos = '0;
  wire  [10:0] lm_g_io_in_rx_snp_bits_srcID, lm_i_io_in_rx_snp_bits_srcID;
  logic [10:0] lm_s0_io_in_rx_snp_bits_srcID = '0, lm_s1_io_in_rx_snp_bits_srcID = '0;
  wire  [11:0] lm_g_io_in_rx_snp_bits_txnID, lm_i_io_in_rx_snp_bits_txnID;
  logic [11:0] lm_s0_io_in_rx_snp_bits_txnID = '0, lm_s1_io_in_rx_snp_bits_txnID = '0;
  wire  [10:0] lm_g_io_in_rx_snp_bits_fwdNID, lm_i_io_in_rx_snp_bits_fwdNID;
  logic [10:0] lm_s0_io_in_rx_snp_bits_fwdNID = '0, lm_s1_io_in_rx_snp_bits_fwdNID = '0;
  wire  [11:0] lm_g_io_in_rx_snp_bits_fwdTxnID, lm_i_io_in_rx_snp_bits_fwdTxnID;
  logic [11:0] lm_s0_io_in_rx_snp_bits_fwdTxnID = '0, lm_s1_io_in_rx_snp_bits_fwdTxnID = '0;
  wire  [4:0] lm_g_io_in_rx_snp_bits_opcode, lm_i_io_in_rx_snp_bits_opcode;
  logic [4:0] lm_s0_io_in_rx_snp_bits_opcode = '0, lm_s1_io_in_rx_snp_bits_opcode = '0;
  wire  [44:0] lm_g_io_in_rx_snp_bits_addr, lm_i_io_in_rx_snp_bits_addr;
  logic [44:0] lm_s0_io_in_rx_snp_bits_addr = '0, lm_s1_io_in_rx_snp_bits_addr = '0;
  wire  lm_g_io_in_rx_snp_bits_ns, lm_i_io_in_rx_snp_bits_ns;
  logic lm_s0_io_in_rx_snp_bits_ns = '0, lm_s1_io_in_rx_snp_bits_ns = '0;
  wire  lm_g_io_in_rx_snp_bits_doNotGoToSD, lm_i_io_in_rx_snp_bits_doNotGoToSD;
  logic lm_s0_io_in_rx_snp_bits_doNotGoToSD = '0, lm_s1_io_in_rx_snp_bits_doNotGoToSD = '0;
  wire  lm_g_io_in_rx_snp_bits_retToSrc, lm_i_io_in_rx_snp_bits_retToSrc;
  logic lm_s0_io_in_rx_snp_bits_retToSrc = '0, lm_s1_io_in_rx_snp_bits_retToSrc = '0;
  wire  lm_g_io_in_rx_snp_bits_traceTag, lm_i_io_in_rx_snp_bits_traceTag;
  logic lm_s0_io_in_rx_snp_bits_traceTag = '0, lm_s1_io_in_rx_snp_bits_traceTag = '0;
  wire  lm_g_io_in_rx_snp_bits_mpam_perfMonGroup, lm_i_io_in_rx_snp_bits_mpam_perfMonGroup;
  logic lm_s0_io_in_rx_snp_bits_mpam_perfMonGroup = '0, lm_s1_io_in_rx_snp_bits_mpam_perfMonGroup = '0;
  wire  [8:0] lm_g_io_in_rx_snp_bits_mpam_partID, lm_i_io_in_rx_snp_bits_mpam_partID;
  logic [8:0] lm_s0_io_in_rx_snp_bits_mpam_partID = '0, lm_s1_io_in_rx_snp_bits_mpam_partID = '0;
  wire  lm_g_io_in_rx_snp_bits_mpam_mpamNS, lm_i_io_in_rx_snp_bits_mpam_mpamNS;
  logic lm_s0_io_in_rx_snp_bits_mpam_mpamNS = '0, lm_s1_io_in_rx_snp_bits_mpam_mpamNS = '0;
  wire  lm_g_io_out_txsactive, lm_i_io_out_txsactive;
  logic lm_s0_io_out_txsactive = '0, lm_s1_io_out_txsactive = '0;
  logic lm_io_out_rxsactive;
  wire  lm_g_io_out_syscoreq, lm_i_io_out_syscoreq;
  logic lm_s0_io_out_syscoreq = '0, lm_s1_io_out_syscoreq = '0;
  logic lm_io_out_syscoack;
  wire  lm_g_io_out_tx_linkactivereq, lm_i_io_out_tx_linkactivereq;
  logic lm_s0_io_out_tx_linkactivereq = '0, lm_s1_io_out_tx_linkactivereq = '0;
  logic lm_io_out_tx_linkactiveack;
  wire  lm_g_io_out_tx_req_flitpend, lm_i_io_out_tx_req_flitpend;
  logic lm_s0_io_out_tx_req_flitpend = '0, lm_s1_io_out_tx_req_flitpend = '0;
  wire  lm_g_io_out_tx_req_flitv, lm_i_io_out_tx_req_flitv;
  logic lm_s0_io_out_tx_req_flitv = '0, lm_s1_io_out_tx_req_flitv = '0;
  wire  [161:0] lm_g_io_out_tx_req_flit, lm_i_io_out_tx_req_flit;
  logic [161:0] lm_s0_io_out_tx_req_flit = '0, lm_s1_io_out_tx_req_flit = '0;
  logic lm_io_out_tx_req_lcrdv;
  wire  lm_g_io_out_tx_rsp_flitpend, lm_i_io_out_tx_rsp_flitpend;
  logic lm_s0_io_out_tx_rsp_flitpend = '0, lm_s1_io_out_tx_rsp_flitpend = '0;
  wire  lm_g_io_out_tx_rsp_flitv, lm_i_io_out_tx_rsp_flitv;
  logic lm_s0_io_out_tx_rsp_flitv = '0, lm_s1_io_out_tx_rsp_flitv = '0;
  wire  [72:0] lm_g_io_out_tx_rsp_flit, lm_i_io_out_tx_rsp_flit;
  logic [72:0] lm_s0_io_out_tx_rsp_flit = '0, lm_s1_io_out_tx_rsp_flit = '0;
  logic lm_io_out_tx_rsp_lcrdv;
  wire  lm_g_io_out_tx_dat_flitpend, lm_i_io_out_tx_dat_flitpend;
  logic lm_s0_io_out_tx_dat_flitpend = '0, lm_s1_io_out_tx_dat_flitpend = '0;
  wire  lm_g_io_out_tx_dat_flitv, lm_i_io_out_tx_dat_flitv;
  logic lm_s0_io_out_tx_dat_flitv = '0, lm_s1_io_out_tx_dat_flitv = '0;
  wire  [421:0] lm_g_io_out_tx_dat_flit, lm_i_io_out_tx_dat_flit;
  logic [421:0] lm_s0_io_out_tx_dat_flit = '0, lm_s1_io_out_tx_dat_flit = '0;
  logic lm_io_out_tx_dat_lcrdv;
  logic lm_io_out_rx_linkactivereq;
  wire  lm_g_io_out_rx_linkactiveack, lm_i_io_out_rx_linkactiveack;
  logic lm_s0_io_out_rx_linkactiveack = '0, lm_s1_io_out_rx_linkactiveack = '0;
  logic lm_io_out_rx_rsp_flitpend;
  logic lm_io_out_rx_rsp_flitv;
  logic [72:0] lm_io_out_rx_rsp_flit;
  wire  lm_g_io_out_rx_rsp_lcrdv, lm_i_io_out_rx_rsp_lcrdv;
  logic lm_s0_io_out_rx_rsp_lcrdv = '0, lm_s1_io_out_rx_rsp_lcrdv = '0;
  logic lm_io_out_rx_dat_flitpend;
  logic lm_io_out_rx_dat_flitv;
  logic [421:0] lm_io_out_rx_dat_flit;
  wire  lm_g_io_out_rx_dat_lcrdv, lm_i_io_out_rx_dat_lcrdv;
  logic lm_s0_io_out_rx_dat_lcrdv = '0, lm_s1_io_out_rx_dat_lcrdv = '0;
  logic lm_io_out_rx_snp_flitpend;
  logic lm_io_out_rx_snp_flitv;
  logic [114:0] lm_io_out_rx_snp_flit;
  wire  lm_g_io_out_rx_snp_lcrdv, lm_i_io_out_rx_snp_lcrdv;
  logic lm_s0_io_out_rx_snp_lcrdv = '0, lm_s1_io_out_rx_snp_lcrdv = '0;
  logic [10:0] lm_io_nodeID;
  int lm_cov_tx_run = 0;
  int lm_cov_rx_run = 0;
  int lm_cov_rx_deact_wait = 0;
  int lm_cov_first_cycle_after_reset = 0;
  int lm_cov_retry_ack = 0;
  int lm_cov_pcrd_grant = 0;
  int lm_cov_no_allow_retry_req = 0;
  int lm_cov_tx_dat_flit = 0;
  int lm_cov_rx_snp_out = 0;
  int lm_cov_rx_dat_out = 0;
  logic [6:0] lm_armed = '0;
  int lm_armed_at = -1;
  LinkMonitor lm_u_gold (
    .clock(clk),
    .reset(lm_reset),
    .io_in_tx_req_ready(lm_g_io_in_tx_req_ready),
    .io_in_tx_req_valid(lm_io_in_tx_req_valid),
    .io_in_tx_req_bits_qos(lm_io_in_tx_req_bits_qos),
    .io_in_tx_req_bits_tgtID(lm_io_in_tx_req_bits_tgtID),
    .io_in_tx_req_bits_txnID(lm_io_in_tx_req_bits_txnID),
    .io_in_tx_req_bits_returnNID(lm_io_in_tx_req_bits_returnNID),
    .io_in_tx_req_bits_stashNIDValid(lm_io_in_tx_req_bits_stashNIDValid),
    .io_in_tx_req_bits_returnTxnID(lm_io_in_tx_req_bits_returnTxnID),
    .io_in_tx_req_bits_opcode(lm_io_in_tx_req_bits_opcode),
    .io_in_tx_req_bits_size(lm_io_in_tx_req_bits_size),
    .io_in_tx_req_bits_addr(lm_io_in_tx_req_bits_addr),
    .io_in_tx_req_bits_ns(lm_io_in_tx_req_bits_ns),
    .io_in_tx_req_bits_likelyshared(lm_io_in_tx_req_bits_likelyshared),
    .io_in_tx_req_bits_allowRetry(lm_io_in_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order(lm_io_in_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType(lm_io_in_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate(lm_io_in_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable(lm_io_in_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device(lm_io_in_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa(lm_io_in_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr(lm_io_in_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_lpIDWithPadding(lm_io_in_tx_req_bits_lpIDWithPadding),
    .io_in_tx_req_bits_snoopMe(lm_io_in_tx_req_bits_snoopMe),
    .io_in_tx_req_bits_expCompAck(lm_io_in_tx_req_bits_expCompAck),
    .io_in_tx_req_bits_tagOp(lm_io_in_tx_req_bits_tagOp),
    .io_in_tx_req_bits_traceTag(lm_io_in_tx_req_bits_traceTag),
    .io_in_tx_req_bits_mpam_perfMonGroup(lm_io_in_tx_req_bits_mpam_perfMonGroup),
    .io_in_tx_req_bits_mpam_partID(lm_io_in_tx_req_bits_mpam_partID),
    .io_in_tx_req_bits_mpam_mpamNS(lm_io_in_tx_req_bits_mpam_mpamNS),
    .io_in_tx_req_bits_rsvdc(lm_io_in_tx_req_bits_rsvdc),
    .io_in_tx_rsp_ready(lm_g_io_in_tx_rsp_ready),
    .io_in_tx_rsp_valid(lm_io_in_tx_rsp_valid),
    .io_in_tx_rsp_bits_qos(lm_io_in_tx_rsp_bits_qos),
    .io_in_tx_rsp_bits_tgtID(lm_io_in_tx_rsp_bits_tgtID),
    .io_in_tx_rsp_bits_txnID(lm_io_in_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode(lm_io_in_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_respErr(lm_io_in_tx_rsp_bits_respErr),
    .io_in_tx_rsp_bits_resp(lm_io_in_tx_rsp_bits_resp),
    .io_in_tx_rsp_bits_fwdState(lm_io_in_tx_rsp_bits_fwdState),
    .io_in_tx_rsp_bits_cBusy(lm_io_in_tx_rsp_bits_cBusy),
    .io_in_tx_rsp_bits_dbID(lm_io_in_tx_rsp_bits_dbID),
    .io_in_tx_rsp_bits_pCrdType(lm_io_in_tx_rsp_bits_pCrdType),
    .io_in_tx_rsp_bits_tagOp(lm_io_in_tx_rsp_bits_tagOp),
    .io_in_tx_rsp_bits_traceTag(lm_io_in_tx_rsp_bits_traceTag),
    .io_in_tx_dat_ready(lm_g_io_in_tx_dat_ready),
    .io_in_tx_dat_valid(lm_io_in_tx_dat_valid),
    .io_in_tx_dat_bits_qos(lm_io_in_tx_dat_bits_qos),
    .io_in_tx_dat_bits_tgtID(lm_io_in_tx_dat_bits_tgtID),
    .io_in_tx_dat_bits_txnID(lm_io_in_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_homeNID(lm_io_in_tx_dat_bits_homeNID),
    .io_in_tx_dat_bits_opcode(lm_io_in_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_respErr(lm_io_in_tx_dat_bits_respErr),
    .io_in_tx_dat_bits_resp(lm_io_in_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataSource(lm_io_in_tx_dat_bits_dataSource),
    .io_in_tx_dat_bits_cBusy(lm_io_in_tx_dat_bits_cBusy),
    .io_in_tx_dat_bits_dbID(lm_io_in_tx_dat_bits_dbID),
    .io_in_tx_dat_bits_ccID(lm_io_in_tx_dat_bits_ccID),
    .io_in_tx_dat_bits_dataID(lm_io_in_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_tagOp(lm_io_in_tx_dat_bits_tagOp),
    .io_in_tx_dat_bits_tag(lm_io_in_tx_dat_bits_tag),
    .io_in_tx_dat_bits_tu(lm_io_in_tx_dat_bits_tu),
    .io_in_tx_dat_bits_traceTag(lm_io_in_tx_dat_bits_traceTag),
    .io_in_tx_dat_bits_rsvdc(lm_io_in_tx_dat_bits_rsvdc),
    .io_in_tx_dat_bits_be(lm_io_in_tx_dat_bits_be),
    .io_in_tx_dat_bits_data(lm_io_in_tx_dat_bits_data),
    .io_in_tx_dat_bits_dataCheck(lm_io_in_tx_dat_bits_dataCheck),
    .io_in_tx_dat_bits_poison(lm_io_in_tx_dat_bits_poison),
    .io_in_rx_rsp_ready(lm_io_in_rx_rsp_ready),
    .io_in_rx_rsp_valid(lm_g_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_qos(lm_g_io_in_rx_rsp_bits_qos),
    .io_in_rx_rsp_bits_tgtID(lm_g_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID(lm_g_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID(lm_g_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode(lm_g_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_respErr(lm_g_io_in_rx_rsp_bits_respErr),
    .io_in_rx_rsp_bits_resp(lm_g_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState(lm_g_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_cBusy(lm_g_io_in_rx_rsp_bits_cBusy),
    .io_in_rx_rsp_bits_dbID(lm_g_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType(lm_g_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_rsp_bits_tagOp(lm_g_io_in_rx_rsp_bits_tagOp),
    .io_in_rx_rsp_bits_traceTag(lm_g_io_in_rx_rsp_bits_traceTag),
    .io_in_rx_dat_ready(lm_io_in_rx_dat_ready),
    .io_in_rx_dat_valid(lm_g_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_qos(lm_g_io_in_rx_dat_bits_qos),
    .io_in_rx_dat_bits_tgtID(lm_g_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID(lm_g_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID(lm_g_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID(lm_g_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode(lm_g_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_respErr(lm_g_io_in_rx_dat_bits_respErr),
    .io_in_rx_dat_bits_resp(lm_g_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource(lm_g_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_cBusy(lm_g_io_in_rx_dat_bits_cBusy),
    .io_in_rx_dat_bits_dbID(lm_g_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_ccID(lm_g_io_in_rx_dat_bits_ccID),
    .io_in_rx_dat_bits_dataID(lm_g_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_tagOp(lm_g_io_in_rx_dat_bits_tagOp),
    .io_in_rx_dat_bits_tag(lm_g_io_in_rx_dat_bits_tag),
    .io_in_rx_dat_bits_tu(lm_g_io_in_rx_dat_bits_tu),
    .io_in_rx_dat_bits_traceTag(lm_g_io_in_rx_dat_bits_traceTag),
    .io_in_rx_dat_bits_rsvdc(lm_g_io_in_rx_dat_bits_rsvdc),
    .io_in_rx_dat_bits_be(lm_g_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data(lm_g_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck(lm_g_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_dat_bits_poison(lm_g_io_in_rx_dat_bits_poison),
    .io_in_rx_snp_ready(lm_io_in_rx_snp_ready),
    .io_in_rx_snp_valid(lm_g_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_qos(lm_g_io_in_rx_snp_bits_qos),
    .io_in_rx_snp_bits_srcID(lm_g_io_in_rx_snp_bits_srcID),
    .io_in_rx_snp_bits_txnID(lm_g_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID(lm_g_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID(lm_g_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode(lm_g_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr(lm_g_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_ns(lm_g_io_in_rx_snp_bits_ns),
    .io_in_rx_snp_bits_doNotGoToSD(lm_g_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc(lm_g_io_in_rx_snp_bits_retToSrc),
    .io_in_rx_snp_bits_traceTag(lm_g_io_in_rx_snp_bits_traceTag),
    .io_in_rx_snp_bits_mpam_perfMonGroup(lm_g_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_in_rx_snp_bits_mpam_partID(lm_g_io_in_rx_snp_bits_mpam_partID),
    .io_in_rx_snp_bits_mpam_mpamNS(lm_g_io_in_rx_snp_bits_mpam_mpamNS),
    .io_out_txsactive(lm_g_io_out_txsactive),
    .io_out_rxsactive(lm_io_out_rxsactive),
    .io_out_syscoreq(lm_g_io_out_syscoreq),
    .io_out_syscoack(lm_io_out_syscoack),
    .io_out_tx_linkactivereq(lm_g_io_out_tx_linkactivereq),
    .io_out_tx_linkactiveack(lm_io_out_tx_linkactiveack),
    .io_out_tx_req_flitpend(lm_g_io_out_tx_req_flitpend),
    .io_out_tx_req_flitv(lm_g_io_out_tx_req_flitv),
    .io_out_tx_req_flit(lm_g_io_out_tx_req_flit),
    .io_out_tx_req_lcrdv(lm_io_out_tx_req_lcrdv),
    .io_out_tx_rsp_flitpend(lm_g_io_out_tx_rsp_flitpend),
    .io_out_tx_rsp_flitv(lm_g_io_out_tx_rsp_flitv),
    .io_out_tx_rsp_flit(lm_g_io_out_tx_rsp_flit),
    .io_out_tx_rsp_lcrdv(lm_io_out_tx_rsp_lcrdv),
    .io_out_tx_dat_flitpend(lm_g_io_out_tx_dat_flitpend),
    .io_out_tx_dat_flitv(lm_g_io_out_tx_dat_flitv),
    .io_out_tx_dat_flit(lm_g_io_out_tx_dat_flit),
    .io_out_tx_dat_lcrdv(lm_io_out_tx_dat_lcrdv),
    .io_out_rx_linkactivereq(lm_io_out_rx_linkactivereq),
    .io_out_rx_linkactiveack(lm_g_io_out_rx_linkactiveack),
    .io_out_rx_rsp_flitpend(lm_io_out_rx_rsp_flitpend),
    .io_out_rx_rsp_flitv(lm_io_out_rx_rsp_flitv),
    .io_out_rx_rsp_flit(lm_io_out_rx_rsp_flit),
    .io_out_rx_rsp_lcrdv(lm_g_io_out_rx_rsp_lcrdv),
    .io_out_rx_dat_flitpend(lm_io_out_rx_dat_flitpend),
    .io_out_rx_dat_flitv(lm_io_out_rx_dat_flitv),
    .io_out_rx_dat_flit(lm_io_out_rx_dat_flit),
    .io_out_rx_dat_lcrdv(lm_g_io_out_rx_dat_lcrdv),
    .io_out_rx_snp_flitpend(lm_io_out_rx_snp_flitpend),
    .io_out_rx_snp_flitv(lm_io_out_rx_snp_flitv),
    .io_out_rx_snp_flit(lm_io_out_rx_snp_flit),
    .io_out_rx_snp_lcrdv(lm_g_io_out_rx_snp_lcrdv),
    .io_nodeID(lm_io_nodeID)
  );
  LinkMonitor_xs lm_u_impl (
    .clock(clk),
    .reset(lm_reset),
    .io_in_tx_req_ready(lm_i_io_in_tx_req_ready),
    .io_in_tx_req_valid(lm_io_in_tx_req_valid),
    .io_in_tx_req_bits_qos(lm_io_in_tx_req_bits_qos),
    .io_in_tx_req_bits_tgtID(lm_io_in_tx_req_bits_tgtID),
    .io_in_tx_req_bits_txnID(lm_io_in_tx_req_bits_txnID),
    .io_in_tx_req_bits_returnNID(lm_io_in_tx_req_bits_returnNID),
    .io_in_tx_req_bits_stashNIDValid(lm_io_in_tx_req_bits_stashNIDValid),
    .io_in_tx_req_bits_returnTxnID(lm_io_in_tx_req_bits_returnTxnID),
    .io_in_tx_req_bits_opcode(lm_io_in_tx_req_bits_opcode),
    .io_in_tx_req_bits_size(lm_io_in_tx_req_bits_size),
    .io_in_tx_req_bits_addr(lm_io_in_tx_req_bits_addr),
    .io_in_tx_req_bits_ns(lm_io_in_tx_req_bits_ns),
    .io_in_tx_req_bits_likelyshared(lm_io_in_tx_req_bits_likelyshared),
    .io_in_tx_req_bits_allowRetry(lm_io_in_tx_req_bits_allowRetry),
    .io_in_tx_req_bits_order(lm_io_in_tx_req_bits_order),
    .io_in_tx_req_bits_pCrdType(lm_io_in_tx_req_bits_pCrdType),
    .io_in_tx_req_bits_memAttr_allocate(lm_io_in_tx_req_bits_memAttr_allocate),
    .io_in_tx_req_bits_memAttr_cacheable(lm_io_in_tx_req_bits_memAttr_cacheable),
    .io_in_tx_req_bits_memAttr_device(lm_io_in_tx_req_bits_memAttr_device),
    .io_in_tx_req_bits_memAttr_ewa(lm_io_in_tx_req_bits_memAttr_ewa),
    .io_in_tx_req_bits_snpAttr(lm_io_in_tx_req_bits_snpAttr),
    .io_in_tx_req_bits_lpIDWithPadding(lm_io_in_tx_req_bits_lpIDWithPadding),
    .io_in_tx_req_bits_snoopMe(lm_io_in_tx_req_bits_snoopMe),
    .io_in_tx_req_bits_expCompAck(lm_io_in_tx_req_bits_expCompAck),
    .io_in_tx_req_bits_tagOp(lm_io_in_tx_req_bits_tagOp),
    .io_in_tx_req_bits_traceTag(lm_io_in_tx_req_bits_traceTag),
    .io_in_tx_req_bits_mpam_perfMonGroup(lm_io_in_tx_req_bits_mpam_perfMonGroup),
    .io_in_tx_req_bits_mpam_partID(lm_io_in_tx_req_bits_mpam_partID),
    .io_in_tx_req_bits_mpam_mpamNS(lm_io_in_tx_req_bits_mpam_mpamNS),
    .io_in_tx_req_bits_rsvdc(lm_io_in_tx_req_bits_rsvdc),
    .io_in_tx_rsp_ready(lm_i_io_in_tx_rsp_ready),
    .io_in_tx_rsp_valid(lm_io_in_tx_rsp_valid),
    .io_in_tx_rsp_bits_qos(lm_io_in_tx_rsp_bits_qos),
    .io_in_tx_rsp_bits_tgtID(lm_io_in_tx_rsp_bits_tgtID),
    .io_in_tx_rsp_bits_txnID(lm_io_in_tx_rsp_bits_txnID),
    .io_in_tx_rsp_bits_opcode(lm_io_in_tx_rsp_bits_opcode),
    .io_in_tx_rsp_bits_respErr(lm_io_in_tx_rsp_bits_respErr),
    .io_in_tx_rsp_bits_resp(lm_io_in_tx_rsp_bits_resp),
    .io_in_tx_rsp_bits_fwdState(lm_io_in_tx_rsp_bits_fwdState),
    .io_in_tx_rsp_bits_cBusy(lm_io_in_tx_rsp_bits_cBusy),
    .io_in_tx_rsp_bits_dbID(lm_io_in_tx_rsp_bits_dbID),
    .io_in_tx_rsp_bits_pCrdType(lm_io_in_tx_rsp_bits_pCrdType),
    .io_in_tx_rsp_bits_tagOp(lm_io_in_tx_rsp_bits_tagOp),
    .io_in_tx_rsp_bits_traceTag(lm_io_in_tx_rsp_bits_traceTag),
    .io_in_tx_dat_ready(lm_i_io_in_tx_dat_ready),
    .io_in_tx_dat_valid(lm_io_in_tx_dat_valid),
    .io_in_tx_dat_bits_qos(lm_io_in_tx_dat_bits_qos),
    .io_in_tx_dat_bits_tgtID(lm_io_in_tx_dat_bits_tgtID),
    .io_in_tx_dat_bits_txnID(lm_io_in_tx_dat_bits_txnID),
    .io_in_tx_dat_bits_homeNID(lm_io_in_tx_dat_bits_homeNID),
    .io_in_tx_dat_bits_opcode(lm_io_in_tx_dat_bits_opcode),
    .io_in_tx_dat_bits_respErr(lm_io_in_tx_dat_bits_respErr),
    .io_in_tx_dat_bits_resp(lm_io_in_tx_dat_bits_resp),
    .io_in_tx_dat_bits_dataSource(lm_io_in_tx_dat_bits_dataSource),
    .io_in_tx_dat_bits_cBusy(lm_io_in_tx_dat_bits_cBusy),
    .io_in_tx_dat_bits_dbID(lm_io_in_tx_dat_bits_dbID),
    .io_in_tx_dat_bits_ccID(lm_io_in_tx_dat_bits_ccID),
    .io_in_tx_dat_bits_dataID(lm_io_in_tx_dat_bits_dataID),
    .io_in_tx_dat_bits_tagOp(lm_io_in_tx_dat_bits_tagOp),
    .io_in_tx_dat_bits_tag(lm_io_in_tx_dat_bits_tag),
    .io_in_tx_dat_bits_tu(lm_io_in_tx_dat_bits_tu),
    .io_in_tx_dat_bits_traceTag(lm_io_in_tx_dat_bits_traceTag),
    .io_in_tx_dat_bits_rsvdc(lm_io_in_tx_dat_bits_rsvdc),
    .io_in_tx_dat_bits_be(lm_io_in_tx_dat_bits_be),
    .io_in_tx_dat_bits_data(lm_io_in_tx_dat_bits_data),
    .io_in_tx_dat_bits_dataCheck(lm_io_in_tx_dat_bits_dataCheck),
    .io_in_tx_dat_bits_poison(lm_io_in_tx_dat_bits_poison),
    .io_in_rx_rsp_ready(lm_io_in_rx_rsp_ready),
    .io_in_rx_rsp_valid(lm_i_io_in_rx_rsp_valid),
    .io_in_rx_rsp_bits_qos(lm_i_io_in_rx_rsp_bits_qos),
    .io_in_rx_rsp_bits_tgtID(lm_i_io_in_rx_rsp_bits_tgtID),
    .io_in_rx_rsp_bits_srcID(lm_i_io_in_rx_rsp_bits_srcID),
    .io_in_rx_rsp_bits_txnID(lm_i_io_in_rx_rsp_bits_txnID),
    .io_in_rx_rsp_bits_opcode(lm_i_io_in_rx_rsp_bits_opcode),
    .io_in_rx_rsp_bits_respErr(lm_i_io_in_rx_rsp_bits_respErr),
    .io_in_rx_rsp_bits_resp(lm_i_io_in_rx_rsp_bits_resp),
    .io_in_rx_rsp_bits_fwdState(lm_i_io_in_rx_rsp_bits_fwdState),
    .io_in_rx_rsp_bits_cBusy(lm_i_io_in_rx_rsp_bits_cBusy),
    .io_in_rx_rsp_bits_dbID(lm_i_io_in_rx_rsp_bits_dbID),
    .io_in_rx_rsp_bits_pCrdType(lm_i_io_in_rx_rsp_bits_pCrdType),
    .io_in_rx_rsp_bits_tagOp(lm_i_io_in_rx_rsp_bits_tagOp),
    .io_in_rx_rsp_bits_traceTag(lm_i_io_in_rx_rsp_bits_traceTag),
    .io_in_rx_dat_ready(lm_io_in_rx_dat_ready),
    .io_in_rx_dat_valid(lm_i_io_in_rx_dat_valid),
    .io_in_rx_dat_bits_qos(lm_i_io_in_rx_dat_bits_qos),
    .io_in_rx_dat_bits_tgtID(lm_i_io_in_rx_dat_bits_tgtID),
    .io_in_rx_dat_bits_srcID(lm_i_io_in_rx_dat_bits_srcID),
    .io_in_rx_dat_bits_txnID(lm_i_io_in_rx_dat_bits_txnID),
    .io_in_rx_dat_bits_homeNID(lm_i_io_in_rx_dat_bits_homeNID),
    .io_in_rx_dat_bits_opcode(lm_i_io_in_rx_dat_bits_opcode),
    .io_in_rx_dat_bits_respErr(lm_i_io_in_rx_dat_bits_respErr),
    .io_in_rx_dat_bits_resp(lm_i_io_in_rx_dat_bits_resp),
    .io_in_rx_dat_bits_dataSource(lm_i_io_in_rx_dat_bits_dataSource),
    .io_in_rx_dat_bits_cBusy(lm_i_io_in_rx_dat_bits_cBusy),
    .io_in_rx_dat_bits_dbID(lm_i_io_in_rx_dat_bits_dbID),
    .io_in_rx_dat_bits_ccID(lm_i_io_in_rx_dat_bits_ccID),
    .io_in_rx_dat_bits_dataID(lm_i_io_in_rx_dat_bits_dataID),
    .io_in_rx_dat_bits_tagOp(lm_i_io_in_rx_dat_bits_tagOp),
    .io_in_rx_dat_bits_tag(lm_i_io_in_rx_dat_bits_tag),
    .io_in_rx_dat_bits_tu(lm_i_io_in_rx_dat_bits_tu),
    .io_in_rx_dat_bits_traceTag(lm_i_io_in_rx_dat_bits_traceTag),
    .io_in_rx_dat_bits_rsvdc(lm_i_io_in_rx_dat_bits_rsvdc),
    .io_in_rx_dat_bits_be(lm_i_io_in_rx_dat_bits_be),
    .io_in_rx_dat_bits_data(lm_i_io_in_rx_dat_bits_data),
    .io_in_rx_dat_bits_dataCheck(lm_i_io_in_rx_dat_bits_dataCheck),
    .io_in_rx_dat_bits_poison(lm_i_io_in_rx_dat_bits_poison),
    .io_in_rx_snp_ready(lm_io_in_rx_snp_ready),
    .io_in_rx_snp_valid(lm_i_io_in_rx_snp_valid),
    .io_in_rx_snp_bits_qos(lm_i_io_in_rx_snp_bits_qos),
    .io_in_rx_snp_bits_srcID(lm_i_io_in_rx_snp_bits_srcID),
    .io_in_rx_snp_bits_txnID(lm_i_io_in_rx_snp_bits_txnID),
    .io_in_rx_snp_bits_fwdNID(lm_i_io_in_rx_snp_bits_fwdNID),
    .io_in_rx_snp_bits_fwdTxnID(lm_i_io_in_rx_snp_bits_fwdTxnID),
    .io_in_rx_snp_bits_opcode(lm_i_io_in_rx_snp_bits_opcode),
    .io_in_rx_snp_bits_addr(lm_i_io_in_rx_snp_bits_addr),
    .io_in_rx_snp_bits_ns(lm_i_io_in_rx_snp_bits_ns),
    .io_in_rx_snp_bits_doNotGoToSD(lm_i_io_in_rx_snp_bits_doNotGoToSD),
    .io_in_rx_snp_bits_retToSrc(lm_i_io_in_rx_snp_bits_retToSrc),
    .io_in_rx_snp_bits_traceTag(lm_i_io_in_rx_snp_bits_traceTag),
    .io_in_rx_snp_bits_mpam_perfMonGroup(lm_i_io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_in_rx_snp_bits_mpam_partID(lm_i_io_in_rx_snp_bits_mpam_partID),
    .io_in_rx_snp_bits_mpam_mpamNS(lm_i_io_in_rx_snp_bits_mpam_mpamNS),
    .io_out_txsactive(lm_i_io_out_txsactive),
    .io_out_rxsactive(lm_io_out_rxsactive),
    .io_out_syscoreq(lm_i_io_out_syscoreq),
    .io_out_syscoack(lm_io_out_syscoack),
    .io_out_tx_linkactivereq(lm_i_io_out_tx_linkactivereq),
    .io_out_tx_linkactiveack(lm_io_out_tx_linkactiveack),
    .io_out_tx_req_flitpend(lm_i_io_out_tx_req_flitpend),
    .io_out_tx_req_flitv(lm_i_io_out_tx_req_flitv),
    .io_out_tx_req_flit(lm_i_io_out_tx_req_flit),
    .io_out_tx_req_lcrdv(lm_io_out_tx_req_lcrdv),
    .io_out_tx_rsp_flitpend(lm_i_io_out_tx_rsp_flitpend),
    .io_out_tx_rsp_flitv(lm_i_io_out_tx_rsp_flitv),
    .io_out_tx_rsp_flit(lm_i_io_out_tx_rsp_flit),
    .io_out_tx_rsp_lcrdv(lm_io_out_tx_rsp_lcrdv),
    .io_out_tx_dat_flitpend(lm_i_io_out_tx_dat_flitpend),
    .io_out_tx_dat_flitv(lm_i_io_out_tx_dat_flitv),
    .io_out_tx_dat_flit(lm_i_io_out_tx_dat_flit),
    .io_out_tx_dat_lcrdv(lm_io_out_tx_dat_lcrdv),
    .io_out_rx_linkactivereq(lm_io_out_rx_linkactivereq),
    .io_out_rx_linkactiveack(lm_i_io_out_rx_linkactiveack),
    .io_out_rx_rsp_flitpend(lm_io_out_rx_rsp_flitpend),
    .io_out_rx_rsp_flitv(lm_io_out_rx_rsp_flitv),
    .io_out_rx_rsp_flit(lm_io_out_rx_rsp_flit),
    .io_out_rx_rsp_lcrdv(lm_i_io_out_rx_rsp_lcrdv),
    .io_out_rx_dat_flitpend(lm_io_out_rx_dat_flitpend),
    .io_out_rx_dat_flitv(lm_io_out_rx_dat_flitv),
    .io_out_rx_dat_flit(lm_io_out_rx_dat_flit),
    .io_out_rx_dat_lcrdv(lm_i_io_out_rx_dat_lcrdv),
    .io_out_rx_snp_flitpend(lm_io_out_rx_snp_flitpend),
    .io_out_rx_snp_flitv(lm_io_out_rx_snp_flitv),
    .io_out_rx_snp_flit(lm_io_out_rx_snp_flit),
    .io_out_rx_snp_lcrdv(lm_i_io_out_rx_snp_lcrdv),
    .io_nodeID(lm_io_nodeID)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) lm_mode = $urandom_range(0, 15);
      lm_io_in_tx_req_valid = 1'($urandom);
      lm_io_in_tx_req_bits_qos = 4'($urandom);
      lm_io_in_tx_req_bits_tgtID = 11'($urandom);
      lm_io_in_tx_req_bits_txnID = 12'($urandom);
      lm_io_in_tx_req_bits_returnNID = 11'($urandom);
      lm_io_in_tx_req_bits_stashNIDValid = 1'($urandom);
      lm_io_in_tx_req_bits_returnTxnID = 12'($urandom);
      lm_io_in_tx_req_bits_opcode = 7'($urandom);
      lm_io_in_tx_req_bits_size = 3'($urandom);
      lm_io_in_tx_req_bits_addr = 48'({$urandom, $urandom});
      lm_io_in_tx_req_bits_ns = 1'($urandom);
      lm_io_in_tx_req_bits_likelyshared = 1'($urandom);
      lm_io_in_tx_req_bits_allowRetry = 1'($urandom);
      lm_io_in_tx_req_bits_order = 2'($urandom);
      lm_io_in_tx_req_bits_pCrdType = 4'($urandom);
      lm_io_in_tx_req_bits_memAttr_allocate = 1'($urandom);
      lm_io_in_tx_req_bits_memAttr_cacheable = 1'($urandom);
      lm_io_in_tx_req_bits_memAttr_device = 1'($urandom);
      lm_io_in_tx_req_bits_memAttr_ewa = 1'($urandom);
      lm_io_in_tx_req_bits_snpAttr = 1'($urandom);
      lm_io_in_tx_req_bits_lpIDWithPadding = 8'($urandom);
      lm_io_in_tx_req_bits_snoopMe = 1'($urandom);
      lm_io_in_tx_req_bits_expCompAck = 1'($urandom);
      lm_io_in_tx_req_bits_tagOp = 2'($urandom);
      lm_io_in_tx_req_bits_traceTag = 1'($urandom);
      lm_io_in_tx_req_bits_mpam_perfMonGroup = 1'($urandom);
      lm_io_in_tx_req_bits_mpam_partID = 9'($urandom);
      lm_io_in_tx_req_bits_mpam_mpamNS = 1'($urandom);
      lm_io_in_tx_req_bits_rsvdc = 4'($urandom);
      lm_io_in_tx_rsp_valid = 1'($urandom);
      lm_io_in_tx_rsp_bits_qos = 4'($urandom);
      lm_io_in_tx_rsp_bits_tgtID = 11'($urandom);
      lm_io_in_tx_rsp_bits_txnID = 12'($urandom);
      lm_io_in_tx_rsp_bits_opcode = 5'($urandom);
      lm_io_in_tx_rsp_bits_respErr = 2'($urandom);
      lm_io_in_tx_rsp_bits_resp = 3'($urandom);
      lm_io_in_tx_rsp_bits_fwdState = 3'($urandom);
      lm_io_in_tx_rsp_bits_cBusy = 3'($urandom);
      lm_io_in_tx_rsp_bits_dbID = 12'($urandom);
      lm_io_in_tx_rsp_bits_pCrdType = 4'($urandom);
      lm_io_in_tx_rsp_bits_tagOp = 2'($urandom);
      lm_io_in_tx_rsp_bits_traceTag = 1'($urandom);
      lm_io_in_tx_dat_valid = 1'($urandom);
      lm_io_in_tx_dat_bits_qos = 4'($urandom);
      lm_io_in_tx_dat_bits_tgtID = 11'($urandom);
      lm_io_in_tx_dat_bits_txnID = 12'($urandom);
      lm_io_in_tx_dat_bits_homeNID = 11'($urandom);
      lm_io_in_tx_dat_bits_opcode = 4'($urandom);
      lm_io_in_tx_dat_bits_respErr = 2'($urandom);
      lm_io_in_tx_dat_bits_resp = 3'($urandom);
      lm_io_in_tx_dat_bits_dataSource = 4'($urandom);
      lm_io_in_tx_dat_bits_cBusy = 3'($urandom);
      lm_io_in_tx_dat_bits_dbID = 12'($urandom);
      lm_io_in_tx_dat_bits_ccID = 2'($urandom);
      lm_io_in_tx_dat_bits_dataID = 2'($urandom);
      lm_io_in_tx_dat_bits_tagOp = 2'($urandom);
      lm_io_in_tx_dat_bits_tag = 8'($urandom);
      lm_io_in_tx_dat_bits_tu = 2'($urandom);
      lm_io_in_tx_dat_bits_traceTag = 1'($urandom);
      lm_io_in_tx_dat_bits_rsvdc = 4'($urandom);
      lm_io_in_tx_dat_bits_be = 32'($urandom);
      lm_io_in_tx_dat_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      lm_io_in_tx_dat_bits_dataCheck = 32'($urandom);
      lm_io_in_tx_dat_bits_poison = 4'($urandom);
      lm_io_in_rx_rsp_ready = 1'($urandom);
      lm_io_in_rx_dat_ready = 1'($urandom);
      lm_io_in_rx_snp_ready = 1'($urandom);
      lm_io_out_rxsactive = 1'($urandom);
      lm_io_out_syscoack = 1'($urandom);
      lm_io_out_tx_linkactiveack = 1'($urandom);
      lm_io_out_tx_req_lcrdv = 1'($urandom);
      lm_io_out_tx_rsp_lcrdv = 1'($urandom);
      lm_io_out_tx_dat_lcrdv = 1'($urandom);
      lm_io_out_rx_linkactivereq = 1'($urandom);
      lm_io_out_rx_rsp_flitpend = 1'($urandom);
      lm_io_out_rx_rsp_flitv = 1'($urandom);
      lm_io_out_rx_rsp_flit = 73'({$urandom, $urandom, $urandom});
      lm_io_out_rx_dat_flitpend = 1'($urandom);
      lm_io_out_rx_dat_flitv = 1'($urandom);
      lm_io_out_rx_dat_flit = 422'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      lm_io_out_rx_snp_flitpend = 1'($urandom);
      lm_io_out_rx_snp_flitv = 1'($urandom);
      lm_io_out_rx_snp_flit = 115'({$urandom, $urandom, $urandom, $urandom});
      lm_io_nodeID = 11'($urandom);
      lm_reset = (cyc < RESET_CYC) || ($urandom_range(0, 999) == 0);
      begin : stim_lm
        case (lm_mode % 3)
          0: begin
            lm_io_out_tx_linkactiveack = ($urandom_range(0, 15) != 0);
            lm_io_out_rx_linkactivereq = ($urandom_range(0, 15) != 0);
          end
          1: begin
            lm_io_out_rx_linkactivereq = ($urandom_range(0, 7) == 0);
            lm_io_out_rx_rsp_flitv = ($urandom_range(0, 7) == 0);
            lm_io_out_rx_dat_flitv = ($urandom_range(0, 7) == 0);
            lm_io_out_rx_snp_flitv = ($urandom_range(0, 7) == 0);
          end
          default: ;
        endcase
        case ($urandom_range(0, 7))
          0: lm_io_out_rx_rsp_flit[42:38] = 5'h3;
          1: lm_io_out_rx_rsp_flit[42:38] = 5'h7;
          2: lm_io_out_rx_rsp_flit[42:38] = 5'h0;
          default: ;
        endcase
      end
      #4;
      if (cyc >= RESET_CYC + 0 && (&lm_armed)) begin
        checks++;
        if (lm_g_io_in_tx_req_ready !== lm_i_io_in_tx_req_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_tx_req_ready g=%h i=%h", cyc, lm_g_io_in_tx_req_ready, lm_i_io_in_tx_req_ready);
        end
        lm_s1_io_in_tx_req_ready |= lm_g_io_in_tx_req_ready;
        lm_s0_io_in_tx_req_ready |= ~lm_g_io_in_tx_req_ready;
        checks++;
        if (lm_g_io_in_tx_rsp_ready !== lm_i_io_in_tx_rsp_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_tx_rsp_ready g=%h i=%h", cyc, lm_g_io_in_tx_rsp_ready, lm_i_io_in_tx_rsp_ready);
        end
        lm_s1_io_in_tx_rsp_ready |= lm_g_io_in_tx_rsp_ready;
        lm_s0_io_in_tx_rsp_ready |= ~lm_g_io_in_tx_rsp_ready;
        checks++;
        if (lm_g_io_in_tx_dat_ready !== lm_i_io_in_tx_dat_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_tx_dat_ready g=%h i=%h", cyc, lm_g_io_in_tx_dat_ready, lm_i_io_in_tx_dat_ready);
        end
        lm_s1_io_in_tx_dat_ready |= lm_g_io_in_tx_dat_ready;
        lm_s0_io_in_tx_dat_ready |= ~lm_g_io_in_tx_dat_ready;
        checks++;
        if (lm_g_io_in_rx_rsp_valid !== lm_i_io_in_rx_rsp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_valid g=%h i=%h", cyc, lm_g_io_in_rx_rsp_valid, lm_i_io_in_rx_rsp_valid);
        end
        lm_s1_io_in_rx_rsp_valid |= lm_g_io_in_rx_rsp_valid;
        lm_s0_io_in_rx_rsp_valid |= ~lm_g_io_in_rx_rsp_valid;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_qos !== lm_i_io_in_rx_rsp_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_qos g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_qos, lm_i_io_in_rx_rsp_bits_qos);
        end
        lm_s1_io_in_rx_rsp_bits_qos |= lm_g_io_in_rx_rsp_bits_qos;
        lm_s0_io_in_rx_rsp_bits_qos |= ~lm_g_io_in_rx_rsp_bits_qos;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_tgtID !== lm_i_io_in_rx_rsp_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_tgtID g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_tgtID, lm_i_io_in_rx_rsp_bits_tgtID);
        end
        lm_s1_io_in_rx_rsp_bits_tgtID |= lm_g_io_in_rx_rsp_bits_tgtID;
        lm_s0_io_in_rx_rsp_bits_tgtID |= ~lm_g_io_in_rx_rsp_bits_tgtID;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_srcID !== lm_i_io_in_rx_rsp_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_srcID g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_srcID, lm_i_io_in_rx_rsp_bits_srcID);
        end
        lm_s1_io_in_rx_rsp_bits_srcID |= lm_g_io_in_rx_rsp_bits_srcID;
        lm_s0_io_in_rx_rsp_bits_srcID |= ~lm_g_io_in_rx_rsp_bits_srcID;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_txnID !== lm_i_io_in_rx_rsp_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_txnID g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_txnID, lm_i_io_in_rx_rsp_bits_txnID);
        end
        lm_s1_io_in_rx_rsp_bits_txnID |= lm_g_io_in_rx_rsp_bits_txnID;
        lm_s0_io_in_rx_rsp_bits_txnID |= ~lm_g_io_in_rx_rsp_bits_txnID;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_opcode !== lm_i_io_in_rx_rsp_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_opcode g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_opcode, lm_i_io_in_rx_rsp_bits_opcode);
        end
        lm_s1_io_in_rx_rsp_bits_opcode |= lm_g_io_in_rx_rsp_bits_opcode;
        lm_s0_io_in_rx_rsp_bits_opcode |= ~lm_g_io_in_rx_rsp_bits_opcode;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_respErr !== lm_i_io_in_rx_rsp_bits_respErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_respErr g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_respErr, lm_i_io_in_rx_rsp_bits_respErr);
        end
        lm_s1_io_in_rx_rsp_bits_respErr |= lm_g_io_in_rx_rsp_bits_respErr;
        lm_s0_io_in_rx_rsp_bits_respErr |= ~lm_g_io_in_rx_rsp_bits_respErr;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_resp !== lm_i_io_in_rx_rsp_bits_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_resp g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_resp, lm_i_io_in_rx_rsp_bits_resp);
        end
        lm_s1_io_in_rx_rsp_bits_resp |= lm_g_io_in_rx_rsp_bits_resp;
        lm_s0_io_in_rx_rsp_bits_resp |= ~lm_g_io_in_rx_rsp_bits_resp;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_fwdState !== lm_i_io_in_rx_rsp_bits_fwdState) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_fwdState g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_fwdState, lm_i_io_in_rx_rsp_bits_fwdState);
        end
        lm_s1_io_in_rx_rsp_bits_fwdState |= lm_g_io_in_rx_rsp_bits_fwdState;
        lm_s0_io_in_rx_rsp_bits_fwdState |= ~lm_g_io_in_rx_rsp_bits_fwdState;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_cBusy !== lm_i_io_in_rx_rsp_bits_cBusy) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_cBusy g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_cBusy, lm_i_io_in_rx_rsp_bits_cBusy);
        end
        lm_s1_io_in_rx_rsp_bits_cBusy |= lm_g_io_in_rx_rsp_bits_cBusy;
        lm_s0_io_in_rx_rsp_bits_cBusy |= ~lm_g_io_in_rx_rsp_bits_cBusy;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_dbID !== lm_i_io_in_rx_rsp_bits_dbID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_dbID g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_dbID, lm_i_io_in_rx_rsp_bits_dbID);
        end
        lm_s1_io_in_rx_rsp_bits_dbID |= lm_g_io_in_rx_rsp_bits_dbID;
        lm_s0_io_in_rx_rsp_bits_dbID |= ~lm_g_io_in_rx_rsp_bits_dbID;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_pCrdType !== lm_i_io_in_rx_rsp_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_pCrdType g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_pCrdType, lm_i_io_in_rx_rsp_bits_pCrdType);
        end
        lm_s1_io_in_rx_rsp_bits_pCrdType |= lm_g_io_in_rx_rsp_bits_pCrdType;
        lm_s0_io_in_rx_rsp_bits_pCrdType |= ~lm_g_io_in_rx_rsp_bits_pCrdType;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_tagOp !== lm_i_io_in_rx_rsp_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_tagOp g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_tagOp, lm_i_io_in_rx_rsp_bits_tagOp);
        end
        lm_s1_io_in_rx_rsp_bits_tagOp |= lm_g_io_in_rx_rsp_bits_tagOp;
        lm_s0_io_in_rx_rsp_bits_tagOp |= ~lm_g_io_in_rx_rsp_bits_tagOp;
        checks++;
        if (lm_g_io_in_rx_rsp_bits_traceTag !== lm_i_io_in_rx_rsp_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_rsp_bits_traceTag g=%h i=%h", cyc, lm_g_io_in_rx_rsp_bits_traceTag, lm_i_io_in_rx_rsp_bits_traceTag);
        end
        lm_s1_io_in_rx_rsp_bits_traceTag |= lm_g_io_in_rx_rsp_bits_traceTag;
        lm_s0_io_in_rx_rsp_bits_traceTag |= ~lm_g_io_in_rx_rsp_bits_traceTag;
        checks++;
        if (lm_g_io_in_rx_dat_valid !== lm_i_io_in_rx_dat_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_valid g=%h i=%h", cyc, lm_g_io_in_rx_dat_valid, lm_i_io_in_rx_dat_valid);
        end
        lm_s1_io_in_rx_dat_valid |= lm_g_io_in_rx_dat_valid;
        lm_s0_io_in_rx_dat_valid |= ~lm_g_io_in_rx_dat_valid;
        checks++;
        if (lm_g_io_in_rx_dat_bits_qos !== lm_i_io_in_rx_dat_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_qos g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_qos, lm_i_io_in_rx_dat_bits_qos);
        end
        lm_s1_io_in_rx_dat_bits_qos |= lm_g_io_in_rx_dat_bits_qos;
        lm_s0_io_in_rx_dat_bits_qos |= ~lm_g_io_in_rx_dat_bits_qos;
        checks++;
        if (lm_g_io_in_rx_dat_bits_tgtID !== lm_i_io_in_rx_dat_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_tgtID g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_tgtID, lm_i_io_in_rx_dat_bits_tgtID);
        end
        lm_s1_io_in_rx_dat_bits_tgtID |= lm_g_io_in_rx_dat_bits_tgtID;
        lm_s0_io_in_rx_dat_bits_tgtID |= ~lm_g_io_in_rx_dat_bits_tgtID;
        checks++;
        if (lm_g_io_in_rx_dat_bits_srcID !== lm_i_io_in_rx_dat_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_srcID g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_srcID, lm_i_io_in_rx_dat_bits_srcID);
        end
        lm_s1_io_in_rx_dat_bits_srcID |= lm_g_io_in_rx_dat_bits_srcID;
        lm_s0_io_in_rx_dat_bits_srcID |= ~lm_g_io_in_rx_dat_bits_srcID;
        checks++;
        if (lm_g_io_in_rx_dat_bits_txnID !== lm_i_io_in_rx_dat_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_txnID g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_txnID, lm_i_io_in_rx_dat_bits_txnID);
        end
        lm_s1_io_in_rx_dat_bits_txnID |= lm_g_io_in_rx_dat_bits_txnID;
        lm_s0_io_in_rx_dat_bits_txnID |= ~lm_g_io_in_rx_dat_bits_txnID;
        checks++;
        if (lm_g_io_in_rx_dat_bits_homeNID !== lm_i_io_in_rx_dat_bits_homeNID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_homeNID g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_homeNID, lm_i_io_in_rx_dat_bits_homeNID);
        end
        lm_s1_io_in_rx_dat_bits_homeNID |= lm_g_io_in_rx_dat_bits_homeNID;
        lm_s0_io_in_rx_dat_bits_homeNID |= ~lm_g_io_in_rx_dat_bits_homeNID;
        checks++;
        if (lm_g_io_in_rx_dat_bits_opcode !== lm_i_io_in_rx_dat_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_opcode g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_opcode, lm_i_io_in_rx_dat_bits_opcode);
        end
        lm_s1_io_in_rx_dat_bits_opcode |= lm_g_io_in_rx_dat_bits_opcode;
        lm_s0_io_in_rx_dat_bits_opcode |= ~lm_g_io_in_rx_dat_bits_opcode;
        checks++;
        if (lm_g_io_in_rx_dat_bits_respErr !== lm_i_io_in_rx_dat_bits_respErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_respErr g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_respErr, lm_i_io_in_rx_dat_bits_respErr);
        end
        lm_s1_io_in_rx_dat_bits_respErr |= lm_g_io_in_rx_dat_bits_respErr;
        lm_s0_io_in_rx_dat_bits_respErr |= ~lm_g_io_in_rx_dat_bits_respErr;
        checks++;
        if (lm_g_io_in_rx_dat_bits_resp !== lm_i_io_in_rx_dat_bits_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_resp g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_resp, lm_i_io_in_rx_dat_bits_resp);
        end
        lm_s1_io_in_rx_dat_bits_resp |= lm_g_io_in_rx_dat_bits_resp;
        lm_s0_io_in_rx_dat_bits_resp |= ~lm_g_io_in_rx_dat_bits_resp;
        checks++;
        if (lm_g_io_in_rx_dat_bits_dataSource !== lm_i_io_in_rx_dat_bits_dataSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_dataSource g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_dataSource, lm_i_io_in_rx_dat_bits_dataSource);
        end
        lm_s1_io_in_rx_dat_bits_dataSource |= lm_g_io_in_rx_dat_bits_dataSource;
        lm_s0_io_in_rx_dat_bits_dataSource |= ~lm_g_io_in_rx_dat_bits_dataSource;
        checks++;
        if (lm_g_io_in_rx_dat_bits_cBusy !== lm_i_io_in_rx_dat_bits_cBusy) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_cBusy g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_cBusy, lm_i_io_in_rx_dat_bits_cBusy);
        end
        lm_s1_io_in_rx_dat_bits_cBusy |= lm_g_io_in_rx_dat_bits_cBusy;
        lm_s0_io_in_rx_dat_bits_cBusy |= ~lm_g_io_in_rx_dat_bits_cBusy;
        checks++;
        if (lm_g_io_in_rx_dat_bits_dbID !== lm_i_io_in_rx_dat_bits_dbID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_dbID g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_dbID, lm_i_io_in_rx_dat_bits_dbID);
        end
        lm_s1_io_in_rx_dat_bits_dbID |= lm_g_io_in_rx_dat_bits_dbID;
        lm_s0_io_in_rx_dat_bits_dbID |= ~lm_g_io_in_rx_dat_bits_dbID;
        checks++;
        if (lm_g_io_in_rx_dat_bits_ccID !== lm_i_io_in_rx_dat_bits_ccID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_ccID g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_ccID, lm_i_io_in_rx_dat_bits_ccID);
        end
        lm_s1_io_in_rx_dat_bits_ccID |= lm_g_io_in_rx_dat_bits_ccID;
        lm_s0_io_in_rx_dat_bits_ccID |= ~lm_g_io_in_rx_dat_bits_ccID;
        checks++;
        if (lm_g_io_in_rx_dat_bits_dataID !== lm_i_io_in_rx_dat_bits_dataID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_dataID g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_dataID, lm_i_io_in_rx_dat_bits_dataID);
        end
        lm_s1_io_in_rx_dat_bits_dataID |= lm_g_io_in_rx_dat_bits_dataID;
        lm_s0_io_in_rx_dat_bits_dataID |= ~lm_g_io_in_rx_dat_bits_dataID;
        checks++;
        if (lm_g_io_in_rx_dat_bits_tagOp !== lm_i_io_in_rx_dat_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_tagOp g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_tagOp, lm_i_io_in_rx_dat_bits_tagOp);
        end
        lm_s1_io_in_rx_dat_bits_tagOp |= lm_g_io_in_rx_dat_bits_tagOp;
        lm_s0_io_in_rx_dat_bits_tagOp |= ~lm_g_io_in_rx_dat_bits_tagOp;
        checks++;
        if (lm_g_io_in_rx_dat_bits_tag !== lm_i_io_in_rx_dat_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_tag g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_tag, lm_i_io_in_rx_dat_bits_tag);
        end
        lm_s1_io_in_rx_dat_bits_tag |= lm_g_io_in_rx_dat_bits_tag;
        lm_s0_io_in_rx_dat_bits_tag |= ~lm_g_io_in_rx_dat_bits_tag;
        checks++;
        if (lm_g_io_in_rx_dat_bits_tu !== lm_i_io_in_rx_dat_bits_tu) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_tu g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_tu, lm_i_io_in_rx_dat_bits_tu);
        end
        lm_s1_io_in_rx_dat_bits_tu |= lm_g_io_in_rx_dat_bits_tu;
        lm_s0_io_in_rx_dat_bits_tu |= ~lm_g_io_in_rx_dat_bits_tu;
        checks++;
        if (lm_g_io_in_rx_dat_bits_traceTag !== lm_i_io_in_rx_dat_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_traceTag g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_traceTag, lm_i_io_in_rx_dat_bits_traceTag);
        end
        lm_s1_io_in_rx_dat_bits_traceTag |= lm_g_io_in_rx_dat_bits_traceTag;
        lm_s0_io_in_rx_dat_bits_traceTag |= ~lm_g_io_in_rx_dat_bits_traceTag;
        checks++;
        if (lm_g_io_in_rx_dat_bits_rsvdc !== lm_i_io_in_rx_dat_bits_rsvdc) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_rsvdc g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_rsvdc, lm_i_io_in_rx_dat_bits_rsvdc);
        end
        lm_s1_io_in_rx_dat_bits_rsvdc |= lm_g_io_in_rx_dat_bits_rsvdc;
        lm_s0_io_in_rx_dat_bits_rsvdc |= ~lm_g_io_in_rx_dat_bits_rsvdc;
        checks++;
        if (lm_g_io_in_rx_dat_bits_be !== lm_i_io_in_rx_dat_bits_be) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_be g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_be, lm_i_io_in_rx_dat_bits_be);
        end
        lm_s1_io_in_rx_dat_bits_be |= lm_g_io_in_rx_dat_bits_be;
        lm_s0_io_in_rx_dat_bits_be |= ~lm_g_io_in_rx_dat_bits_be;
        checks++;
        if (lm_g_io_in_rx_dat_bits_data !== lm_i_io_in_rx_dat_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_data g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_data, lm_i_io_in_rx_dat_bits_data);
        end
        lm_s1_io_in_rx_dat_bits_data |= lm_g_io_in_rx_dat_bits_data;
        lm_s0_io_in_rx_dat_bits_data |= ~lm_g_io_in_rx_dat_bits_data;
        checks++;
        if (lm_g_io_in_rx_dat_bits_dataCheck !== lm_i_io_in_rx_dat_bits_dataCheck) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_dataCheck g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_dataCheck, lm_i_io_in_rx_dat_bits_dataCheck);
        end
        lm_s1_io_in_rx_dat_bits_dataCheck |= lm_g_io_in_rx_dat_bits_dataCheck;
        lm_s0_io_in_rx_dat_bits_dataCheck |= ~lm_g_io_in_rx_dat_bits_dataCheck;
        checks++;
        if (lm_g_io_in_rx_dat_bits_poison !== lm_i_io_in_rx_dat_bits_poison) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_dat_bits_poison g=%h i=%h", cyc, lm_g_io_in_rx_dat_bits_poison, lm_i_io_in_rx_dat_bits_poison);
        end
        lm_s1_io_in_rx_dat_bits_poison |= lm_g_io_in_rx_dat_bits_poison;
        lm_s0_io_in_rx_dat_bits_poison |= ~lm_g_io_in_rx_dat_bits_poison;
        checks++;
        if (lm_g_io_in_rx_snp_valid !== lm_i_io_in_rx_snp_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_valid g=%h i=%h", cyc, lm_g_io_in_rx_snp_valid, lm_i_io_in_rx_snp_valid);
        end
        lm_s1_io_in_rx_snp_valid |= lm_g_io_in_rx_snp_valid;
        lm_s0_io_in_rx_snp_valid |= ~lm_g_io_in_rx_snp_valid;
        checks++;
        if (lm_g_io_in_rx_snp_bits_qos !== lm_i_io_in_rx_snp_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_qos g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_qos, lm_i_io_in_rx_snp_bits_qos);
        end
        lm_s1_io_in_rx_snp_bits_qos |= lm_g_io_in_rx_snp_bits_qos;
        lm_s0_io_in_rx_snp_bits_qos |= ~lm_g_io_in_rx_snp_bits_qos;
        checks++;
        if (lm_g_io_in_rx_snp_bits_srcID !== lm_i_io_in_rx_snp_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_srcID g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_srcID, lm_i_io_in_rx_snp_bits_srcID);
        end
        lm_s1_io_in_rx_snp_bits_srcID |= lm_g_io_in_rx_snp_bits_srcID;
        lm_s0_io_in_rx_snp_bits_srcID |= ~lm_g_io_in_rx_snp_bits_srcID;
        checks++;
        if (lm_g_io_in_rx_snp_bits_txnID !== lm_i_io_in_rx_snp_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_txnID g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_txnID, lm_i_io_in_rx_snp_bits_txnID);
        end
        lm_s1_io_in_rx_snp_bits_txnID |= lm_g_io_in_rx_snp_bits_txnID;
        lm_s0_io_in_rx_snp_bits_txnID |= ~lm_g_io_in_rx_snp_bits_txnID;
        checks++;
        if (lm_g_io_in_rx_snp_bits_fwdNID !== lm_i_io_in_rx_snp_bits_fwdNID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_fwdNID g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_fwdNID, lm_i_io_in_rx_snp_bits_fwdNID);
        end
        lm_s1_io_in_rx_snp_bits_fwdNID |= lm_g_io_in_rx_snp_bits_fwdNID;
        lm_s0_io_in_rx_snp_bits_fwdNID |= ~lm_g_io_in_rx_snp_bits_fwdNID;
        checks++;
        if (lm_g_io_in_rx_snp_bits_fwdTxnID !== lm_i_io_in_rx_snp_bits_fwdTxnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_fwdTxnID g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_fwdTxnID, lm_i_io_in_rx_snp_bits_fwdTxnID);
        end
        lm_s1_io_in_rx_snp_bits_fwdTxnID |= lm_g_io_in_rx_snp_bits_fwdTxnID;
        lm_s0_io_in_rx_snp_bits_fwdTxnID |= ~lm_g_io_in_rx_snp_bits_fwdTxnID;
        checks++;
        if (lm_g_io_in_rx_snp_bits_opcode !== lm_i_io_in_rx_snp_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_opcode g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_opcode, lm_i_io_in_rx_snp_bits_opcode);
        end
        lm_s1_io_in_rx_snp_bits_opcode |= lm_g_io_in_rx_snp_bits_opcode;
        lm_s0_io_in_rx_snp_bits_opcode |= ~lm_g_io_in_rx_snp_bits_opcode;
        checks++;
        if (lm_g_io_in_rx_snp_bits_addr !== lm_i_io_in_rx_snp_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_addr g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_addr, lm_i_io_in_rx_snp_bits_addr);
        end
        lm_s1_io_in_rx_snp_bits_addr |= lm_g_io_in_rx_snp_bits_addr;
        lm_s0_io_in_rx_snp_bits_addr |= ~lm_g_io_in_rx_snp_bits_addr;
        checks++;
        if (lm_g_io_in_rx_snp_bits_ns !== lm_i_io_in_rx_snp_bits_ns) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_ns g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_ns, lm_i_io_in_rx_snp_bits_ns);
        end
        lm_s1_io_in_rx_snp_bits_ns |= lm_g_io_in_rx_snp_bits_ns;
        lm_s0_io_in_rx_snp_bits_ns |= ~lm_g_io_in_rx_snp_bits_ns;
        checks++;
        if (lm_g_io_in_rx_snp_bits_doNotGoToSD !== lm_i_io_in_rx_snp_bits_doNotGoToSD) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_doNotGoToSD g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_doNotGoToSD, lm_i_io_in_rx_snp_bits_doNotGoToSD);
        end
        lm_s1_io_in_rx_snp_bits_doNotGoToSD |= lm_g_io_in_rx_snp_bits_doNotGoToSD;
        lm_s0_io_in_rx_snp_bits_doNotGoToSD |= ~lm_g_io_in_rx_snp_bits_doNotGoToSD;
        checks++;
        if (lm_g_io_in_rx_snp_bits_retToSrc !== lm_i_io_in_rx_snp_bits_retToSrc) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_retToSrc g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_retToSrc, lm_i_io_in_rx_snp_bits_retToSrc);
        end
        lm_s1_io_in_rx_snp_bits_retToSrc |= lm_g_io_in_rx_snp_bits_retToSrc;
        lm_s0_io_in_rx_snp_bits_retToSrc |= ~lm_g_io_in_rx_snp_bits_retToSrc;
        checks++;
        if (lm_g_io_in_rx_snp_bits_traceTag !== lm_i_io_in_rx_snp_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_traceTag g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_traceTag, lm_i_io_in_rx_snp_bits_traceTag);
        end
        lm_s1_io_in_rx_snp_bits_traceTag |= lm_g_io_in_rx_snp_bits_traceTag;
        lm_s0_io_in_rx_snp_bits_traceTag |= ~lm_g_io_in_rx_snp_bits_traceTag;
        checks++;
        if (lm_g_io_in_rx_snp_bits_mpam_perfMonGroup !== lm_i_io_in_rx_snp_bits_mpam_perfMonGroup) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_mpam_perfMonGroup g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_mpam_perfMonGroup, lm_i_io_in_rx_snp_bits_mpam_perfMonGroup);
        end
        lm_s1_io_in_rx_snp_bits_mpam_perfMonGroup |= lm_g_io_in_rx_snp_bits_mpam_perfMonGroup;
        lm_s0_io_in_rx_snp_bits_mpam_perfMonGroup |= ~lm_g_io_in_rx_snp_bits_mpam_perfMonGroup;
        checks++;
        if (lm_g_io_in_rx_snp_bits_mpam_partID !== lm_i_io_in_rx_snp_bits_mpam_partID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_mpam_partID g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_mpam_partID, lm_i_io_in_rx_snp_bits_mpam_partID);
        end
        lm_s1_io_in_rx_snp_bits_mpam_partID |= lm_g_io_in_rx_snp_bits_mpam_partID;
        lm_s0_io_in_rx_snp_bits_mpam_partID |= ~lm_g_io_in_rx_snp_bits_mpam_partID;
        checks++;
        if (lm_g_io_in_rx_snp_bits_mpam_mpamNS !== lm_i_io_in_rx_snp_bits_mpam_mpamNS) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_in_rx_snp_bits_mpam_mpamNS g=%h i=%h", cyc, lm_g_io_in_rx_snp_bits_mpam_mpamNS, lm_i_io_in_rx_snp_bits_mpam_mpamNS);
        end
        lm_s1_io_in_rx_snp_bits_mpam_mpamNS |= lm_g_io_in_rx_snp_bits_mpam_mpamNS;
        lm_s0_io_in_rx_snp_bits_mpam_mpamNS |= ~lm_g_io_in_rx_snp_bits_mpam_mpamNS;
        checks++;
        if (lm_g_io_out_txsactive !== lm_i_io_out_txsactive) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_txsactive g=%h i=%h", cyc, lm_g_io_out_txsactive, lm_i_io_out_txsactive);
        end
        lm_s1_io_out_txsactive |= lm_g_io_out_txsactive;
        lm_s0_io_out_txsactive |= ~lm_g_io_out_txsactive;
        checks++;
        if (lm_g_io_out_syscoreq !== lm_i_io_out_syscoreq) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_syscoreq g=%h i=%h", cyc, lm_g_io_out_syscoreq, lm_i_io_out_syscoreq);
        end
        lm_s1_io_out_syscoreq |= lm_g_io_out_syscoreq;
        lm_s0_io_out_syscoreq |= ~lm_g_io_out_syscoreq;
        checks++;
        if (lm_g_io_out_tx_linkactivereq !== lm_i_io_out_tx_linkactivereq) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_linkactivereq g=%h i=%h", cyc, lm_g_io_out_tx_linkactivereq, lm_i_io_out_tx_linkactivereq);
        end
        lm_s1_io_out_tx_linkactivereq |= lm_g_io_out_tx_linkactivereq;
        lm_s0_io_out_tx_linkactivereq |= ~lm_g_io_out_tx_linkactivereq;
        checks++;
        if (lm_g_io_out_tx_req_flitpend !== lm_i_io_out_tx_req_flitpend) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_req_flitpend g=%h i=%h", cyc, lm_g_io_out_tx_req_flitpend, lm_i_io_out_tx_req_flitpend);
        end
        lm_s1_io_out_tx_req_flitpend |= lm_g_io_out_tx_req_flitpend;
        lm_s0_io_out_tx_req_flitpend |= ~lm_g_io_out_tx_req_flitpend;
        checks++;
        if (lm_g_io_out_tx_req_flitv !== lm_i_io_out_tx_req_flitv) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_req_flitv g=%h i=%h", cyc, lm_g_io_out_tx_req_flitv, lm_i_io_out_tx_req_flitv);
        end
        lm_s1_io_out_tx_req_flitv |= lm_g_io_out_tx_req_flitv;
        lm_s0_io_out_tx_req_flitv |= ~lm_g_io_out_tx_req_flitv;
        checks++;
        if (lm_g_io_out_tx_req_flit !== lm_i_io_out_tx_req_flit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_req_flit g=%h i=%h", cyc, lm_g_io_out_tx_req_flit, lm_i_io_out_tx_req_flit);
        end
        lm_s1_io_out_tx_req_flit |= lm_g_io_out_tx_req_flit;
        lm_s0_io_out_tx_req_flit |= ~lm_g_io_out_tx_req_flit;
        checks++;
        if (lm_g_io_out_tx_rsp_flitpend !== lm_i_io_out_tx_rsp_flitpend) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_rsp_flitpend g=%h i=%h", cyc, lm_g_io_out_tx_rsp_flitpend, lm_i_io_out_tx_rsp_flitpend);
        end
        lm_s1_io_out_tx_rsp_flitpend |= lm_g_io_out_tx_rsp_flitpend;
        lm_s0_io_out_tx_rsp_flitpend |= ~lm_g_io_out_tx_rsp_flitpend;
        checks++;
        if (lm_g_io_out_tx_rsp_flitv !== lm_i_io_out_tx_rsp_flitv) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_rsp_flitv g=%h i=%h", cyc, lm_g_io_out_tx_rsp_flitv, lm_i_io_out_tx_rsp_flitv);
        end
        lm_s1_io_out_tx_rsp_flitv |= lm_g_io_out_tx_rsp_flitv;
        lm_s0_io_out_tx_rsp_flitv |= ~lm_g_io_out_tx_rsp_flitv;
        checks++;
        if (lm_g_io_out_tx_rsp_flit !== lm_i_io_out_tx_rsp_flit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_rsp_flit g=%h i=%h", cyc, lm_g_io_out_tx_rsp_flit, lm_i_io_out_tx_rsp_flit);
        end
        lm_s1_io_out_tx_rsp_flit |= lm_g_io_out_tx_rsp_flit;
        lm_s0_io_out_tx_rsp_flit |= ~lm_g_io_out_tx_rsp_flit;
        checks++;
        if (lm_g_io_out_tx_dat_flitpend !== lm_i_io_out_tx_dat_flitpend) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_dat_flitpend g=%h i=%h", cyc, lm_g_io_out_tx_dat_flitpend, lm_i_io_out_tx_dat_flitpend);
        end
        lm_s1_io_out_tx_dat_flitpend |= lm_g_io_out_tx_dat_flitpend;
        lm_s0_io_out_tx_dat_flitpend |= ~lm_g_io_out_tx_dat_flitpend;
        checks++;
        if (lm_g_io_out_tx_dat_flitv !== lm_i_io_out_tx_dat_flitv) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_dat_flitv g=%h i=%h", cyc, lm_g_io_out_tx_dat_flitv, lm_i_io_out_tx_dat_flitv);
        end
        lm_s1_io_out_tx_dat_flitv |= lm_g_io_out_tx_dat_flitv;
        lm_s0_io_out_tx_dat_flitv |= ~lm_g_io_out_tx_dat_flitv;
        checks++;
        if (lm_g_io_out_tx_dat_flit !== lm_i_io_out_tx_dat_flit) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_tx_dat_flit g=%h i=%h", cyc, lm_g_io_out_tx_dat_flit, lm_i_io_out_tx_dat_flit);
        end
        lm_s1_io_out_tx_dat_flit |= lm_g_io_out_tx_dat_flit;
        lm_s0_io_out_tx_dat_flit |= ~lm_g_io_out_tx_dat_flit;
        checks++;
        if (lm_g_io_out_rx_linkactiveack !== lm_i_io_out_rx_linkactiveack) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_rx_linkactiveack g=%h i=%h", cyc, lm_g_io_out_rx_linkactiveack, lm_i_io_out_rx_linkactiveack);
        end
        lm_s1_io_out_rx_linkactiveack |= lm_g_io_out_rx_linkactiveack;
        lm_s0_io_out_rx_linkactiveack |= ~lm_g_io_out_rx_linkactiveack;
        checks++;
        if (lm_g_io_out_rx_rsp_lcrdv !== lm_i_io_out_rx_rsp_lcrdv) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_rx_rsp_lcrdv g=%h i=%h", cyc, lm_g_io_out_rx_rsp_lcrdv, lm_i_io_out_rx_rsp_lcrdv);
        end
        lm_s1_io_out_rx_rsp_lcrdv |= lm_g_io_out_rx_rsp_lcrdv;
        lm_s0_io_out_rx_rsp_lcrdv |= ~lm_g_io_out_rx_rsp_lcrdv;
        checks++;
        if (lm_g_io_out_rx_dat_lcrdv !== lm_i_io_out_rx_dat_lcrdv) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_rx_dat_lcrdv g=%h i=%h", cyc, lm_g_io_out_rx_dat_lcrdv, lm_i_io_out_rx_dat_lcrdv);
        end
        lm_s1_io_out_rx_dat_lcrdv |= lm_g_io_out_rx_dat_lcrdv;
        lm_s0_io_out_rx_dat_lcrdv |= ~lm_g_io_out_rx_dat_lcrdv;
        checks++;
        if (lm_g_io_out_rx_snp_lcrdv !== lm_i_io_out_rx_snp_lcrdv) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d LinkMonitor.io_out_rx_snp_lcrdv g=%h i=%h", cyc, lm_g_io_out_rx_snp_lcrdv, lm_i_io_out_rx_snp_lcrdv);
        end
        lm_s1_io_out_rx_snp_lcrdv |= lm_g_io_out_rx_snp_lcrdv;
        lm_s0_io_out_rx_snp_lcrdv |= ~lm_g_io_out_rx_snp_lcrdv;
        if (lm_u_gold.txState == 2'h2) lm_cov_tx_run++;
        if (lm_u_gold.rxState == 2'h2) lm_cov_rx_run++;
        if (!lm_io_out_rx_linkactivereq && lm_g_io_out_rx_linkactiveack && !lm_u_gold._LCredit2Decoupled_rxrsp_io_reclaimLCredit) lm_cov_rx_deact_wait++;
        if (!lm_reset && !lm_u_gold.exitcoDone_REG) lm_cov_first_cycle_after_reset++;
        if (lm_g_io_in_rx_rsp_valid && lm_io_in_rx_rsp_ready && lm_g_io_in_rx_rsp_bits_opcode == 5'h3) lm_cov_retry_ack++;
        if (lm_g_io_in_rx_rsp_valid && lm_io_in_rx_rsp_ready && lm_g_io_in_rx_rsp_bits_opcode == 5'h7) lm_cov_pcrd_grant++;
        if (lm_io_in_tx_req_valid && lm_g_io_in_tx_req_ready && !lm_io_in_tx_req_bits_allowRetry) lm_cov_no_allow_retry_req++;
        if (lm_g_io_out_tx_dat_flitv) lm_cov_tx_dat_flit++;
        if (lm_g_io_in_rx_snp_valid && lm_io_in_rx_snp_ready) lm_cov_rx_snp_out++;
        if (lm_g_io_in_rx_dat_valid && lm_io_in_rx_dat_ready) lm_cov_rx_dat_out++;
      end
      if (lm_u_gold.Decoupled2LCredit_txreqLink.flitv) lm_armed[0] = 1'b1;
      if (lm_u_gold.Decoupled2LCredit_txrspLink.flitv) lm_armed[1] = 1'b1;
      if (lm_u_gold.Decoupled2LCredit_txdatLink.flitv) lm_armed[2] = 1'b1;
      if (lm_u_gold.LCredit2Decoupled_rxsnp.queue.do_enq && lm_u_gold.LCredit2Decoupled_rxsnp.queue.enq_ptr_value == 2'd0) lm_armed[3] = 1'b1;
      if (lm_u_gold.LCredit2Decoupled_rxsnp.queue.do_enq && lm_u_gold.LCredit2Decoupled_rxsnp.queue.enq_ptr_value == 2'd1) lm_armed[4] = 1'b1;
      if (lm_u_gold.LCredit2Decoupled_rxsnp.queue.do_enq && lm_u_gold.LCredit2Decoupled_rxsnp.queue.enq_ptr_value == 2'd2) lm_armed[5] = 1'b1;
      if (lm_u_gold.LCredit2Decoupled_rxsnp.queue.do_enq && lm_u_gold.LCredit2Decoupled_rxsnp.queue.enq_ptr_value == 2'd3) lm_armed[6] = 1'b1;
      if (lm_armed_at < 0 && (&lm_armed)) lm_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(lm_s0_io_in_tx_req_ready && lm_s1_io_in_tx_req_ready)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_tx_req_ready 未见过 0 和 1"); end
    if (!(lm_s0_io_in_tx_rsp_ready && lm_s1_io_in_tx_rsp_ready)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_tx_rsp_ready 未见过 0 和 1"); end
    if (!(lm_s0_io_in_tx_dat_ready && lm_s1_io_in_tx_dat_ready)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_tx_dat_ready 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_valid && lm_s1_io_in_rx_rsp_valid)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_valid 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_qos[0] && lm_s1_io_in_rx_rsp_bits_qos[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_qos[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_qos[1] && lm_s1_io_in_rx_rsp_bits_qos[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_qos[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_qos[2] && lm_s1_io_in_rx_rsp_bits_qos[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_qos[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_qos[3] && lm_s1_io_in_rx_rsp_bits_qos[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_qos[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[0] && lm_s1_io_in_rx_rsp_bits_tgtID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[1] && lm_s1_io_in_rx_rsp_bits_tgtID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[2] && lm_s1_io_in_rx_rsp_bits_tgtID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[3] && lm_s1_io_in_rx_rsp_bits_tgtID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[4] && lm_s1_io_in_rx_rsp_bits_tgtID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[5] && lm_s1_io_in_rx_rsp_bits_tgtID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[6] && lm_s1_io_in_rx_rsp_bits_tgtID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[7] && lm_s1_io_in_rx_rsp_bits_tgtID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[8] && lm_s1_io_in_rx_rsp_bits_tgtID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[9] && lm_s1_io_in_rx_rsp_bits_tgtID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tgtID[10] && lm_s1_io_in_rx_rsp_bits_tgtID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tgtID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[0] && lm_s1_io_in_rx_rsp_bits_srcID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[1] && lm_s1_io_in_rx_rsp_bits_srcID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[2] && lm_s1_io_in_rx_rsp_bits_srcID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[3] && lm_s1_io_in_rx_rsp_bits_srcID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[4] && lm_s1_io_in_rx_rsp_bits_srcID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[5] && lm_s1_io_in_rx_rsp_bits_srcID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[6] && lm_s1_io_in_rx_rsp_bits_srcID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[7] && lm_s1_io_in_rx_rsp_bits_srcID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[8] && lm_s1_io_in_rx_rsp_bits_srcID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[9] && lm_s1_io_in_rx_rsp_bits_srcID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_srcID[10] && lm_s1_io_in_rx_rsp_bits_srcID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_srcID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[0] && lm_s1_io_in_rx_rsp_bits_txnID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[1] && lm_s1_io_in_rx_rsp_bits_txnID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[2] && lm_s1_io_in_rx_rsp_bits_txnID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[3] && lm_s1_io_in_rx_rsp_bits_txnID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[4] && lm_s1_io_in_rx_rsp_bits_txnID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[5] && lm_s1_io_in_rx_rsp_bits_txnID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[6] && lm_s1_io_in_rx_rsp_bits_txnID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[7] && lm_s1_io_in_rx_rsp_bits_txnID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[8] && lm_s1_io_in_rx_rsp_bits_txnID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[9] && lm_s1_io_in_rx_rsp_bits_txnID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[10] && lm_s1_io_in_rx_rsp_bits_txnID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_txnID[11] && lm_s1_io_in_rx_rsp_bits_txnID[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_txnID[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_opcode[0] && lm_s1_io_in_rx_rsp_bits_opcode[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_opcode[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_opcode[1] && lm_s1_io_in_rx_rsp_bits_opcode[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_opcode[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_opcode[2] && lm_s1_io_in_rx_rsp_bits_opcode[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_opcode[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_opcode[3] && lm_s1_io_in_rx_rsp_bits_opcode[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_opcode[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_opcode[4] && lm_s1_io_in_rx_rsp_bits_opcode[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_opcode[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_respErr[0] && lm_s1_io_in_rx_rsp_bits_respErr[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_respErr[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_respErr[1] && lm_s1_io_in_rx_rsp_bits_respErr[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_respErr[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_resp[0] && lm_s1_io_in_rx_rsp_bits_resp[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_resp[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_resp[1] && lm_s1_io_in_rx_rsp_bits_resp[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_resp[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_resp[2] && lm_s1_io_in_rx_rsp_bits_resp[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_resp[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_fwdState[0] && lm_s1_io_in_rx_rsp_bits_fwdState[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_fwdState[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_fwdState[1] && lm_s1_io_in_rx_rsp_bits_fwdState[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_fwdState[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_fwdState[2] && lm_s1_io_in_rx_rsp_bits_fwdState[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_fwdState[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_cBusy[0] && lm_s1_io_in_rx_rsp_bits_cBusy[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_cBusy[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_cBusy[1] && lm_s1_io_in_rx_rsp_bits_cBusy[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_cBusy[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_cBusy[2] && lm_s1_io_in_rx_rsp_bits_cBusy[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_cBusy[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[0] && lm_s1_io_in_rx_rsp_bits_dbID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[1] && lm_s1_io_in_rx_rsp_bits_dbID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[2] && lm_s1_io_in_rx_rsp_bits_dbID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[3] && lm_s1_io_in_rx_rsp_bits_dbID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[4] && lm_s1_io_in_rx_rsp_bits_dbID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[5] && lm_s1_io_in_rx_rsp_bits_dbID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[6] && lm_s1_io_in_rx_rsp_bits_dbID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[7] && lm_s1_io_in_rx_rsp_bits_dbID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[8] && lm_s1_io_in_rx_rsp_bits_dbID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[9] && lm_s1_io_in_rx_rsp_bits_dbID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[10] && lm_s1_io_in_rx_rsp_bits_dbID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_dbID[11] && lm_s1_io_in_rx_rsp_bits_dbID[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_dbID[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_pCrdType[0] && lm_s1_io_in_rx_rsp_bits_pCrdType[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_pCrdType[1] && lm_s1_io_in_rx_rsp_bits_pCrdType[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_pCrdType[2] && lm_s1_io_in_rx_rsp_bits_pCrdType[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_pCrdType[3] && lm_s1_io_in_rx_rsp_bits_pCrdType[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tagOp[0] && lm_s1_io_in_rx_rsp_bits_tagOp[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tagOp[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_tagOp[1] && lm_s1_io_in_rx_rsp_bits_tagOp[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_tagOp[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_rsp_bits_traceTag && lm_s1_io_in_rx_rsp_bits_traceTag)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_rsp_bits_traceTag 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_valid && lm_s1_io_in_rx_dat_valid)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_valid 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_qos[0] && lm_s1_io_in_rx_dat_bits_qos[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_qos[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_qos[1] && lm_s1_io_in_rx_dat_bits_qos[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_qos[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_qos[2] && lm_s1_io_in_rx_dat_bits_qos[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_qos[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_qos[3] && lm_s1_io_in_rx_dat_bits_qos[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_qos[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[0] && lm_s1_io_in_rx_dat_bits_tgtID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[1] && lm_s1_io_in_rx_dat_bits_tgtID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[2] && lm_s1_io_in_rx_dat_bits_tgtID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[3] && lm_s1_io_in_rx_dat_bits_tgtID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[4] && lm_s1_io_in_rx_dat_bits_tgtID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[5] && lm_s1_io_in_rx_dat_bits_tgtID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[6] && lm_s1_io_in_rx_dat_bits_tgtID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[7] && lm_s1_io_in_rx_dat_bits_tgtID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[8] && lm_s1_io_in_rx_dat_bits_tgtID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[9] && lm_s1_io_in_rx_dat_bits_tgtID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tgtID[10] && lm_s1_io_in_rx_dat_bits_tgtID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tgtID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[0] && lm_s1_io_in_rx_dat_bits_srcID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[1] && lm_s1_io_in_rx_dat_bits_srcID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[2] && lm_s1_io_in_rx_dat_bits_srcID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[3] && lm_s1_io_in_rx_dat_bits_srcID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[4] && lm_s1_io_in_rx_dat_bits_srcID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[5] && lm_s1_io_in_rx_dat_bits_srcID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[6] && lm_s1_io_in_rx_dat_bits_srcID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[7] && lm_s1_io_in_rx_dat_bits_srcID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[8] && lm_s1_io_in_rx_dat_bits_srcID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[9] && lm_s1_io_in_rx_dat_bits_srcID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_srcID[10] && lm_s1_io_in_rx_dat_bits_srcID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_srcID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[0] && lm_s1_io_in_rx_dat_bits_txnID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[1] && lm_s1_io_in_rx_dat_bits_txnID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[2] && lm_s1_io_in_rx_dat_bits_txnID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[3] && lm_s1_io_in_rx_dat_bits_txnID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[4] && lm_s1_io_in_rx_dat_bits_txnID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[5] && lm_s1_io_in_rx_dat_bits_txnID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[6] && lm_s1_io_in_rx_dat_bits_txnID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[7] && lm_s1_io_in_rx_dat_bits_txnID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[8] && lm_s1_io_in_rx_dat_bits_txnID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[9] && lm_s1_io_in_rx_dat_bits_txnID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[10] && lm_s1_io_in_rx_dat_bits_txnID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_txnID[11] && lm_s1_io_in_rx_dat_bits_txnID[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_txnID[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[0] && lm_s1_io_in_rx_dat_bits_homeNID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[1] && lm_s1_io_in_rx_dat_bits_homeNID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[2] && lm_s1_io_in_rx_dat_bits_homeNID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[3] && lm_s1_io_in_rx_dat_bits_homeNID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[4] && lm_s1_io_in_rx_dat_bits_homeNID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[5] && lm_s1_io_in_rx_dat_bits_homeNID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[6] && lm_s1_io_in_rx_dat_bits_homeNID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[7] && lm_s1_io_in_rx_dat_bits_homeNID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[8] && lm_s1_io_in_rx_dat_bits_homeNID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[9] && lm_s1_io_in_rx_dat_bits_homeNID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_homeNID[10] && lm_s1_io_in_rx_dat_bits_homeNID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_homeNID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_opcode[0] && lm_s1_io_in_rx_dat_bits_opcode[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_opcode[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_opcode[1] && lm_s1_io_in_rx_dat_bits_opcode[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_opcode[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_opcode[2] && lm_s1_io_in_rx_dat_bits_opcode[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_opcode[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_opcode[3] && lm_s1_io_in_rx_dat_bits_opcode[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_opcode[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_respErr[0] && lm_s1_io_in_rx_dat_bits_respErr[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_respErr[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_respErr[1] && lm_s1_io_in_rx_dat_bits_respErr[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_respErr[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_resp[0] && lm_s1_io_in_rx_dat_bits_resp[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_resp[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_resp[1] && lm_s1_io_in_rx_dat_bits_resp[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_resp[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_resp[2] && lm_s1_io_in_rx_dat_bits_resp[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_resp[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataSource[0] && lm_s1_io_in_rx_dat_bits_dataSource[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataSource[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataSource[1] && lm_s1_io_in_rx_dat_bits_dataSource[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataSource[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataSource[2] && lm_s1_io_in_rx_dat_bits_dataSource[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataSource[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataSource[3] && lm_s1_io_in_rx_dat_bits_dataSource[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataSource[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_cBusy[0] && lm_s1_io_in_rx_dat_bits_cBusy[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_cBusy[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_cBusy[1] && lm_s1_io_in_rx_dat_bits_cBusy[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_cBusy[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_cBusy[2] && lm_s1_io_in_rx_dat_bits_cBusy[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_cBusy[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[0] && lm_s1_io_in_rx_dat_bits_dbID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[1] && lm_s1_io_in_rx_dat_bits_dbID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[2] && lm_s1_io_in_rx_dat_bits_dbID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[3] && lm_s1_io_in_rx_dat_bits_dbID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[4] && lm_s1_io_in_rx_dat_bits_dbID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[5] && lm_s1_io_in_rx_dat_bits_dbID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[6] && lm_s1_io_in_rx_dat_bits_dbID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[7] && lm_s1_io_in_rx_dat_bits_dbID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[8] && lm_s1_io_in_rx_dat_bits_dbID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[9] && lm_s1_io_in_rx_dat_bits_dbID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[10] && lm_s1_io_in_rx_dat_bits_dbID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dbID[11] && lm_s1_io_in_rx_dat_bits_dbID[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dbID[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_ccID[0] && lm_s1_io_in_rx_dat_bits_ccID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_ccID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_ccID[1] && lm_s1_io_in_rx_dat_bits_ccID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_ccID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataID[0] && lm_s1_io_in_rx_dat_bits_dataID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataID[1] && lm_s1_io_in_rx_dat_bits_dataID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tagOp[0] && lm_s1_io_in_rx_dat_bits_tagOp[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tagOp[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tagOp[1] && lm_s1_io_in_rx_dat_bits_tagOp[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tagOp[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tag[0] && lm_s1_io_in_rx_dat_bits_tag[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tag[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tag[1] && lm_s1_io_in_rx_dat_bits_tag[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tag[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tag[2] && lm_s1_io_in_rx_dat_bits_tag[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tag[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tag[3] && lm_s1_io_in_rx_dat_bits_tag[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tag[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tag[4] && lm_s1_io_in_rx_dat_bits_tag[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tag[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tag[5] && lm_s1_io_in_rx_dat_bits_tag[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tag[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tag[6] && lm_s1_io_in_rx_dat_bits_tag[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tag[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tag[7] && lm_s1_io_in_rx_dat_bits_tag[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tag[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tu[0] && lm_s1_io_in_rx_dat_bits_tu[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tu[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_tu[1] && lm_s1_io_in_rx_dat_bits_tu[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_tu[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_traceTag && lm_s1_io_in_rx_dat_bits_traceTag)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_traceTag 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_rsvdc[0] && lm_s1_io_in_rx_dat_bits_rsvdc[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_rsvdc[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_rsvdc[1] && lm_s1_io_in_rx_dat_bits_rsvdc[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_rsvdc[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_rsvdc[2] && lm_s1_io_in_rx_dat_bits_rsvdc[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_rsvdc[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_rsvdc[3] && lm_s1_io_in_rx_dat_bits_rsvdc[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_rsvdc[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[0] && lm_s1_io_in_rx_dat_bits_be[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[1] && lm_s1_io_in_rx_dat_bits_be[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[2] && lm_s1_io_in_rx_dat_bits_be[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[3] && lm_s1_io_in_rx_dat_bits_be[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[4] && lm_s1_io_in_rx_dat_bits_be[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[5] && lm_s1_io_in_rx_dat_bits_be[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[6] && lm_s1_io_in_rx_dat_bits_be[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[7] && lm_s1_io_in_rx_dat_bits_be[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[8] && lm_s1_io_in_rx_dat_bits_be[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[9] && lm_s1_io_in_rx_dat_bits_be[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[10] && lm_s1_io_in_rx_dat_bits_be[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[11] && lm_s1_io_in_rx_dat_bits_be[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[12] && lm_s1_io_in_rx_dat_bits_be[12])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[12] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[13] && lm_s1_io_in_rx_dat_bits_be[13])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[13] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[14] && lm_s1_io_in_rx_dat_bits_be[14])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[14] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[15] && lm_s1_io_in_rx_dat_bits_be[15])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[15] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[16] && lm_s1_io_in_rx_dat_bits_be[16])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[16] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[17] && lm_s1_io_in_rx_dat_bits_be[17])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[17] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[18] && lm_s1_io_in_rx_dat_bits_be[18])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[18] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[19] && lm_s1_io_in_rx_dat_bits_be[19])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[19] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[20] && lm_s1_io_in_rx_dat_bits_be[20])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[20] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[21] && lm_s1_io_in_rx_dat_bits_be[21])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[21] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[22] && lm_s1_io_in_rx_dat_bits_be[22])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[22] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[23] && lm_s1_io_in_rx_dat_bits_be[23])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[23] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[24] && lm_s1_io_in_rx_dat_bits_be[24])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[24] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[25] && lm_s1_io_in_rx_dat_bits_be[25])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[25] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[26] && lm_s1_io_in_rx_dat_bits_be[26])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[26] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[27] && lm_s1_io_in_rx_dat_bits_be[27])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[27] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[28] && lm_s1_io_in_rx_dat_bits_be[28])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[28] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[29] && lm_s1_io_in_rx_dat_bits_be[29])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[29] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[30] && lm_s1_io_in_rx_dat_bits_be[30])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[30] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_be[31] && lm_s1_io_in_rx_dat_bits_be[31])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_be[31] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[0] && lm_s1_io_in_rx_dat_bits_data[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[1] && lm_s1_io_in_rx_dat_bits_data[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[2] && lm_s1_io_in_rx_dat_bits_data[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[3] && lm_s1_io_in_rx_dat_bits_data[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[4] && lm_s1_io_in_rx_dat_bits_data[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[5] && lm_s1_io_in_rx_dat_bits_data[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[6] && lm_s1_io_in_rx_dat_bits_data[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[7] && lm_s1_io_in_rx_dat_bits_data[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[8] && lm_s1_io_in_rx_dat_bits_data[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[9] && lm_s1_io_in_rx_dat_bits_data[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[10] && lm_s1_io_in_rx_dat_bits_data[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[11] && lm_s1_io_in_rx_dat_bits_data[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[12] && lm_s1_io_in_rx_dat_bits_data[12])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[12] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[13] && lm_s1_io_in_rx_dat_bits_data[13])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[13] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[14] && lm_s1_io_in_rx_dat_bits_data[14])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[14] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[15] && lm_s1_io_in_rx_dat_bits_data[15])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[15] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[16] && lm_s1_io_in_rx_dat_bits_data[16])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[16] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[17] && lm_s1_io_in_rx_dat_bits_data[17])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[17] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[18] && lm_s1_io_in_rx_dat_bits_data[18])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[18] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[19] && lm_s1_io_in_rx_dat_bits_data[19])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[19] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[20] && lm_s1_io_in_rx_dat_bits_data[20])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[20] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[21] && lm_s1_io_in_rx_dat_bits_data[21])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[21] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[22] && lm_s1_io_in_rx_dat_bits_data[22])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[22] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[23] && lm_s1_io_in_rx_dat_bits_data[23])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[23] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[24] && lm_s1_io_in_rx_dat_bits_data[24])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[24] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[25] && lm_s1_io_in_rx_dat_bits_data[25])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[25] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[26] && lm_s1_io_in_rx_dat_bits_data[26])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[26] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[27] && lm_s1_io_in_rx_dat_bits_data[27])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[27] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[28] && lm_s1_io_in_rx_dat_bits_data[28])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[28] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[29] && lm_s1_io_in_rx_dat_bits_data[29])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[29] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[30] && lm_s1_io_in_rx_dat_bits_data[30])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[30] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[31] && lm_s1_io_in_rx_dat_bits_data[31])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[31] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[32] && lm_s1_io_in_rx_dat_bits_data[32])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[32] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[33] && lm_s1_io_in_rx_dat_bits_data[33])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[33] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[34] && lm_s1_io_in_rx_dat_bits_data[34])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[34] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[35] && lm_s1_io_in_rx_dat_bits_data[35])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[35] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[36] && lm_s1_io_in_rx_dat_bits_data[36])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[36] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[37] && lm_s1_io_in_rx_dat_bits_data[37])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[37] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[38] && lm_s1_io_in_rx_dat_bits_data[38])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[38] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[39] && lm_s1_io_in_rx_dat_bits_data[39])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[39] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[40] && lm_s1_io_in_rx_dat_bits_data[40])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[40] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[41] && lm_s1_io_in_rx_dat_bits_data[41])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[41] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[42] && lm_s1_io_in_rx_dat_bits_data[42])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[42] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[43] && lm_s1_io_in_rx_dat_bits_data[43])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[43] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[44] && lm_s1_io_in_rx_dat_bits_data[44])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[44] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[45] && lm_s1_io_in_rx_dat_bits_data[45])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[45] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[46] && lm_s1_io_in_rx_dat_bits_data[46])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[46] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[47] && lm_s1_io_in_rx_dat_bits_data[47])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[47] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[48] && lm_s1_io_in_rx_dat_bits_data[48])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[48] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[49] && lm_s1_io_in_rx_dat_bits_data[49])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[49] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[50] && lm_s1_io_in_rx_dat_bits_data[50])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[50] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[51] && lm_s1_io_in_rx_dat_bits_data[51])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[51] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[52] && lm_s1_io_in_rx_dat_bits_data[52])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[52] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[53] && lm_s1_io_in_rx_dat_bits_data[53])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[53] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[54] && lm_s1_io_in_rx_dat_bits_data[54])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[54] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[55] && lm_s1_io_in_rx_dat_bits_data[55])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[55] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[56] && lm_s1_io_in_rx_dat_bits_data[56])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[56] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[57] && lm_s1_io_in_rx_dat_bits_data[57])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[57] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[58] && lm_s1_io_in_rx_dat_bits_data[58])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[58] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[59] && lm_s1_io_in_rx_dat_bits_data[59])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[59] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[60] && lm_s1_io_in_rx_dat_bits_data[60])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[60] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[61] && lm_s1_io_in_rx_dat_bits_data[61])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[61] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[62] && lm_s1_io_in_rx_dat_bits_data[62])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[62] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[63] && lm_s1_io_in_rx_dat_bits_data[63])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[63] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[64] && lm_s1_io_in_rx_dat_bits_data[64])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[64] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[65] && lm_s1_io_in_rx_dat_bits_data[65])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[65] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[66] && lm_s1_io_in_rx_dat_bits_data[66])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[66] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[67] && lm_s1_io_in_rx_dat_bits_data[67])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[67] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[68] && lm_s1_io_in_rx_dat_bits_data[68])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[68] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[69] && lm_s1_io_in_rx_dat_bits_data[69])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[69] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[70] && lm_s1_io_in_rx_dat_bits_data[70])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[70] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[71] && lm_s1_io_in_rx_dat_bits_data[71])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[71] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[72] && lm_s1_io_in_rx_dat_bits_data[72])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[72] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[73] && lm_s1_io_in_rx_dat_bits_data[73])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[73] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[74] && lm_s1_io_in_rx_dat_bits_data[74])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[74] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[75] && lm_s1_io_in_rx_dat_bits_data[75])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[75] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[76] && lm_s1_io_in_rx_dat_bits_data[76])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[76] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[77] && lm_s1_io_in_rx_dat_bits_data[77])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[77] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[78] && lm_s1_io_in_rx_dat_bits_data[78])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[78] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[79] && lm_s1_io_in_rx_dat_bits_data[79])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[79] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[80] && lm_s1_io_in_rx_dat_bits_data[80])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[80] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[81] && lm_s1_io_in_rx_dat_bits_data[81])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[81] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[82] && lm_s1_io_in_rx_dat_bits_data[82])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[82] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[83] && lm_s1_io_in_rx_dat_bits_data[83])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[83] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[84] && lm_s1_io_in_rx_dat_bits_data[84])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[84] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[85] && lm_s1_io_in_rx_dat_bits_data[85])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[85] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[86] && lm_s1_io_in_rx_dat_bits_data[86])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[86] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[87] && lm_s1_io_in_rx_dat_bits_data[87])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[87] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[88] && lm_s1_io_in_rx_dat_bits_data[88])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[88] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[89] && lm_s1_io_in_rx_dat_bits_data[89])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[89] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[90] && lm_s1_io_in_rx_dat_bits_data[90])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[90] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[91] && lm_s1_io_in_rx_dat_bits_data[91])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[91] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[92] && lm_s1_io_in_rx_dat_bits_data[92])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[92] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[93] && lm_s1_io_in_rx_dat_bits_data[93])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[93] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[94] && lm_s1_io_in_rx_dat_bits_data[94])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[94] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[95] && lm_s1_io_in_rx_dat_bits_data[95])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[95] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[96] && lm_s1_io_in_rx_dat_bits_data[96])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[96] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[97] && lm_s1_io_in_rx_dat_bits_data[97])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[97] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[98] && lm_s1_io_in_rx_dat_bits_data[98])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[98] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[99] && lm_s1_io_in_rx_dat_bits_data[99])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[99] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[100] && lm_s1_io_in_rx_dat_bits_data[100])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[100] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[101] && lm_s1_io_in_rx_dat_bits_data[101])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[101] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[102] && lm_s1_io_in_rx_dat_bits_data[102])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[102] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[103] && lm_s1_io_in_rx_dat_bits_data[103])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[103] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[104] && lm_s1_io_in_rx_dat_bits_data[104])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[104] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[105] && lm_s1_io_in_rx_dat_bits_data[105])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[105] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[106] && lm_s1_io_in_rx_dat_bits_data[106])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[106] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[107] && lm_s1_io_in_rx_dat_bits_data[107])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[107] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[108] && lm_s1_io_in_rx_dat_bits_data[108])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[108] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[109] && lm_s1_io_in_rx_dat_bits_data[109])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[109] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[110] && lm_s1_io_in_rx_dat_bits_data[110])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[110] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[111] && lm_s1_io_in_rx_dat_bits_data[111])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[111] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[112] && lm_s1_io_in_rx_dat_bits_data[112])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[112] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[113] && lm_s1_io_in_rx_dat_bits_data[113])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[113] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[114] && lm_s1_io_in_rx_dat_bits_data[114])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[114] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[115] && lm_s1_io_in_rx_dat_bits_data[115])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[115] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[116] && lm_s1_io_in_rx_dat_bits_data[116])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[116] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[117] && lm_s1_io_in_rx_dat_bits_data[117])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[117] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[118] && lm_s1_io_in_rx_dat_bits_data[118])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[118] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[119] && lm_s1_io_in_rx_dat_bits_data[119])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[119] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[120] && lm_s1_io_in_rx_dat_bits_data[120])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[120] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[121] && lm_s1_io_in_rx_dat_bits_data[121])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[121] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[122] && lm_s1_io_in_rx_dat_bits_data[122])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[122] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[123] && lm_s1_io_in_rx_dat_bits_data[123])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[123] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[124] && lm_s1_io_in_rx_dat_bits_data[124])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[124] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[125] && lm_s1_io_in_rx_dat_bits_data[125])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[125] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[126] && lm_s1_io_in_rx_dat_bits_data[126])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[126] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[127] && lm_s1_io_in_rx_dat_bits_data[127])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[127] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[128] && lm_s1_io_in_rx_dat_bits_data[128])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[128] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[129] && lm_s1_io_in_rx_dat_bits_data[129])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[129] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[130] && lm_s1_io_in_rx_dat_bits_data[130])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[130] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[131] && lm_s1_io_in_rx_dat_bits_data[131])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[131] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[132] && lm_s1_io_in_rx_dat_bits_data[132])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[132] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[133] && lm_s1_io_in_rx_dat_bits_data[133])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[133] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[134] && lm_s1_io_in_rx_dat_bits_data[134])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[134] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[135] && lm_s1_io_in_rx_dat_bits_data[135])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[135] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[136] && lm_s1_io_in_rx_dat_bits_data[136])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[136] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[137] && lm_s1_io_in_rx_dat_bits_data[137])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[137] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[138] && lm_s1_io_in_rx_dat_bits_data[138])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[138] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[139] && lm_s1_io_in_rx_dat_bits_data[139])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[139] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[140] && lm_s1_io_in_rx_dat_bits_data[140])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[140] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[141] && lm_s1_io_in_rx_dat_bits_data[141])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[141] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[142] && lm_s1_io_in_rx_dat_bits_data[142])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[142] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[143] && lm_s1_io_in_rx_dat_bits_data[143])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[143] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[144] && lm_s1_io_in_rx_dat_bits_data[144])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[144] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[145] && lm_s1_io_in_rx_dat_bits_data[145])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[145] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[146] && lm_s1_io_in_rx_dat_bits_data[146])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[146] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[147] && lm_s1_io_in_rx_dat_bits_data[147])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[147] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[148] && lm_s1_io_in_rx_dat_bits_data[148])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[148] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[149] && lm_s1_io_in_rx_dat_bits_data[149])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[149] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[150] && lm_s1_io_in_rx_dat_bits_data[150])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[150] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[151] && lm_s1_io_in_rx_dat_bits_data[151])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[151] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[152] && lm_s1_io_in_rx_dat_bits_data[152])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[152] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[153] && lm_s1_io_in_rx_dat_bits_data[153])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[153] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[154] && lm_s1_io_in_rx_dat_bits_data[154])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[154] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[155] && lm_s1_io_in_rx_dat_bits_data[155])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[155] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[156] && lm_s1_io_in_rx_dat_bits_data[156])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[156] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[157] && lm_s1_io_in_rx_dat_bits_data[157])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[157] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[158] && lm_s1_io_in_rx_dat_bits_data[158])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[158] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[159] && lm_s1_io_in_rx_dat_bits_data[159])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[159] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[160] && lm_s1_io_in_rx_dat_bits_data[160])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[160] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[161] && lm_s1_io_in_rx_dat_bits_data[161])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[161] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[162] && lm_s1_io_in_rx_dat_bits_data[162])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[162] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[163] && lm_s1_io_in_rx_dat_bits_data[163])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[163] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[164] && lm_s1_io_in_rx_dat_bits_data[164])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[164] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[165] && lm_s1_io_in_rx_dat_bits_data[165])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[165] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[166] && lm_s1_io_in_rx_dat_bits_data[166])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[166] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[167] && lm_s1_io_in_rx_dat_bits_data[167])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[167] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[168] && lm_s1_io_in_rx_dat_bits_data[168])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[168] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[169] && lm_s1_io_in_rx_dat_bits_data[169])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[169] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[170] && lm_s1_io_in_rx_dat_bits_data[170])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[170] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[171] && lm_s1_io_in_rx_dat_bits_data[171])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[171] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[172] && lm_s1_io_in_rx_dat_bits_data[172])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[172] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[173] && lm_s1_io_in_rx_dat_bits_data[173])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[173] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[174] && lm_s1_io_in_rx_dat_bits_data[174])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[174] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[175] && lm_s1_io_in_rx_dat_bits_data[175])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[175] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[176] && lm_s1_io_in_rx_dat_bits_data[176])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[176] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[177] && lm_s1_io_in_rx_dat_bits_data[177])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[177] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[178] && lm_s1_io_in_rx_dat_bits_data[178])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[178] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[179] && lm_s1_io_in_rx_dat_bits_data[179])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[179] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[180] && lm_s1_io_in_rx_dat_bits_data[180])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[180] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[181] && lm_s1_io_in_rx_dat_bits_data[181])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[181] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[182] && lm_s1_io_in_rx_dat_bits_data[182])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[182] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[183] && lm_s1_io_in_rx_dat_bits_data[183])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[183] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[184] && lm_s1_io_in_rx_dat_bits_data[184])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[184] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[185] && lm_s1_io_in_rx_dat_bits_data[185])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[185] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[186] && lm_s1_io_in_rx_dat_bits_data[186])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[186] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[187] && lm_s1_io_in_rx_dat_bits_data[187])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[187] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[188] && lm_s1_io_in_rx_dat_bits_data[188])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[188] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[189] && lm_s1_io_in_rx_dat_bits_data[189])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[189] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[190] && lm_s1_io_in_rx_dat_bits_data[190])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[190] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[191] && lm_s1_io_in_rx_dat_bits_data[191])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[191] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[192] && lm_s1_io_in_rx_dat_bits_data[192])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[192] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[193] && lm_s1_io_in_rx_dat_bits_data[193])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[193] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[194] && lm_s1_io_in_rx_dat_bits_data[194])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[194] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[195] && lm_s1_io_in_rx_dat_bits_data[195])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[195] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[196] && lm_s1_io_in_rx_dat_bits_data[196])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[196] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[197] && lm_s1_io_in_rx_dat_bits_data[197])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[197] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[198] && lm_s1_io_in_rx_dat_bits_data[198])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[198] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[199] && lm_s1_io_in_rx_dat_bits_data[199])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[199] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[200] && lm_s1_io_in_rx_dat_bits_data[200])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[200] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[201] && lm_s1_io_in_rx_dat_bits_data[201])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[201] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[202] && lm_s1_io_in_rx_dat_bits_data[202])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[202] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[203] && lm_s1_io_in_rx_dat_bits_data[203])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[203] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[204] && lm_s1_io_in_rx_dat_bits_data[204])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[204] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[205] && lm_s1_io_in_rx_dat_bits_data[205])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[205] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[206] && lm_s1_io_in_rx_dat_bits_data[206])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[206] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[207] && lm_s1_io_in_rx_dat_bits_data[207])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[207] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[208] && lm_s1_io_in_rx_dat_bits_data[208])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[208] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[209] && lm_s1_io_in_rx_dat_bits_data[209])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[209] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[210] && lm_s1_io_in_rx_dat_bits_data[210])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[210] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[211] && lm_s1_io_in_rx_dat_bits_data[211])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[211] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[212] && lm_s1_io_in_rx_dat_bits_data[212])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[212] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[213] && lm_s1_io_in_rx_dat_bits_data[213])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[213] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[214] && lm_s1_io_in_rx_dat_bits_data[214])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[214] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[215] && lm_s1_io_in_rx_dat_bits_data[215])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[215] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[216] && lm_s1_io_in_rx_dat_bits_data[216])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[216] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[217] && lm_s1_io_in_rx_dat_bits_data[217])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[217] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[218] && lm_s1_io_in_rx_dat_bits_data[218])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[218] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[219] && lm_s1_io_in_rx_dat_bits_data[219])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[219] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[220] && lm_s1_io_in_rx_dat_bits_data[220])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[220] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[221] && lm_s1_io_in_rx_dat_bits_data[221])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[221] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[222] && lm_s1_io_in_rx_dat_bits_data[222])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[222] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[223] && lm_s1_io_in_rx_dat_bits_data[223])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[223] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[224] && lm_s1_io_in_rx_dat_bits_data[224])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[224] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[225] && lm_s1_io_in_rx_dat_bits_data[225])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[225] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[226] && lm_s1_io_in_rx_dat_bits_data[226])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[226] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[227] && lm_s1_io_in_rx_dat_bits_data[227])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[227] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[228] && lm_s1_io_in_rx_dat_bits_data[228])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[228] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[229] && lm_s1_io_in_rx_dat_bits_data[229])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[229] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[230] && lm_s1_io_in_rx_dat_bits_data[230])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[230] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[231] && lm_s1_io_in_rx_dat_bits_data[231])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[231] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[232] && lm_s1_io_in_rx_dat_bits_data[232])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[232] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[233] && lm_s1_io_in_rx_dat_bits_data[233])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[233] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[234] && lm_s1_io_in_rx_dat_bits_data[234])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[234] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[235] && lm_s1_io_in_rx_dat_bits_data[235])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[235] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[236] && lm_s1_io_in_rx_dat_bits_data[236])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[236] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[237] && lm_s1_io_in_rx_dat_bits_data[237])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[237] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[238] && lm_s1_io_in_rx_dat_bits_data[238])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[238] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[239] && lm_s1_io_in_rx_dat_bits_data[239])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[239] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[240] && lm_s1_io_in_rx_dat_bits_data[240])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[240] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[241] && lm_s1_io_in_rx_dat_bits_data[241])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[241] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[242] && lm_s1_io_in_rx_dat_bits_data[242])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[242] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[243] && lm_s1_io_in_rx_dat_bits_data[243])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[243] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[244] && lm_s1_io_in_rx_dat_bits_data[244])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[244] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[245] && lm_s1_io_in_rx_dat_bits_data[245])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[245] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[246] && lm_s1_io_in_rx_dat_bits_data[246])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[246] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[247] && lm_s1_io_in_rx_dat_bits_data[247])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[247] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[248] && lm_s1_io_in_rx_dat_bits_data[248])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[248] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[249] && lm_s1_io_in_rx_dat_bits_data[249])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[249] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[250] && lm_s1_io_in_rx_dat_bits_data[250])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[250] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[251] && lm_s1_io_in_rx_dat_bits_data[251])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[251] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[252] && lm_s1_io_in_rx_dat_bits_data[252])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[252] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[253] && lm_s1_io_in_rx_dat_bits_data[253])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[253] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[254] && lm_s1_io_in_rx_dat_bits_data[254])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[254] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_data[255] && lm_s1_io_in_rx_dat_bits_data[255])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_data[255] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[0] && lm_s1_io_in_rx_dat_bits_dataCheck[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[1] && lm_s1_io_in_rx_dat_bits_dataCheck[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[2] && lm_s1_io_in_rx_dat_bits_dataCheck[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[3] && lm_s1_io_in_rx_dat_bits_dataCheck[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[4] && lm_s1_io_in_rx_dat_bits_dataCheck[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[5] && lm_s1_io_in_rx_dat_bits_dataCheck[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[6] && lm_s1_io_in_rx_dat_bits_dataCheck[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[7] && lm_s1_io_in_rx_dat_bits_dataCheck[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[8] && lm_s1_io_in_rx_dat_bits_dataCheck[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[9] && lm_s1_io_in_rx_dat_bits_dataCheck[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[10] && lm_s1_io_in_rx_dat_bits_dataCheck[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[11] && lm_s1_io_in_rx_dat_bits_dataCheck[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[12] && lm_s1_io_in_rx_dat_bits_dataCheck[12])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[12] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[13] && lm_s1_io_in_rx_dat_bits_dataCheck[13])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[13] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[14] && lm_s1_io_in_rx_dat_bits_dataCheck[14])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[14] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[15] && lm_s1_io_in_rx_dat_bits_dataCheck[15])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[15] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[16] && lm_s1_io_in_rx_dat_bits_dataCheck[16])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[16] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[17] && lm_s1_io_in_rx_dat_bits_dataCheck[17])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[17] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[18] && lm_s1_io_in_rx_dat_bits_dataCheck[18])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[18] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[19] && lm_s1_io_in_rx_dat_bits_dataCheck[19])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[19] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[20] && lm_s1_io_in_rx_dat_bits_dataCheck[20])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[20] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[21] && lm_s1_io_in_rx_dat_bits_dataCheck[21])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[21] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[22] && lm_s1_io_in_rx_dat_bits_dataCheck[22])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[22] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[23] && lm_s1_io_in_rx_dat_bits_dataCheck[23])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[23] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[24] && lm_s1_io_in_rx_dat_bits_dataCheck[24])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[24] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[25] && lm_s1_io_in_rx_dat_bits_dataCheck[25])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[25] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[26] && lm_s1_io_in_rx_dat_bits_dataCheck[26])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[26] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[27] && lm_s1_io_in_rx_dat_bits_dataCheck[27])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[27] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[28] && lm_s1_io_in_rx_dat_bits_dataCheck[28])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[28] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[29] && lm_s1_io_in_rx_dat_bits_dataCheck[29])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[29] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[30] && lm_s1_io_in_rx_dat_bits_dataCheck[30])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[30] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_dataCheck[31] && lm_s1_io_in_rx_dat_bits_dataCheck[31])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_dataCheck[31] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_poison[0] && lm_s1_io_in_rx_dat_bits_poison[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_poison[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_poison[1] && lm_s1_io_in_rx_dat_bits_poison[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_poison[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_poison[2] && lm_s1_io_in_rx_dat_bits_poison[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_poison[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_dat_bits_poison[3] && lm_s1_io_in_rx_dat_bits_poison[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_dat_bits_poison[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_valid && lm_s1_io_in_rx_snp_valid)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_valid 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_qos[0] && lm_s1_io_in_rx_snp_bits_qos[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_qos[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_qos[1] && lm_s1_io_in_rx_snp_bits_qos[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_qos[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_qos[2] && lm_s1_io_in_rx_snp_bits_qos[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_qos[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_qos[3] && lm_s1_io_in_rx_snp_bits_qos[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_qos[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[0] && lm_s1_io_in_rx_snp_bits_srcID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[1] && lm_s1_io_in_rx_snp_bits_srcID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[2] && lm_s1_io_in_rx_snp_bits_srcID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[3] && lm_s1_io_in_rx_snp_bits_srcID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[4] && lm_s1_io_in_rx_snp_bits_srcID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[5] && lm_s1_io_in_rx_snp_bits_srcID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[6] && lm_s1_io_in_rx_snp_bits_srcID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[7] && lm_s1_io_in_rx_snp_bits_srcID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[8] && lm_s1_io_in_rx_snp_bits_srcID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[9] && lm_s1_io_in_rx_snp_bits_srcID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_srcID[10] && lm_s1_io_in_rx_snp_bits_srcID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_srcID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[0] && lm_s1_io_in_rx_snp_bits_txnID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[1] && lm_s1_io_in_rx_snp_bits_txnID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[2] && lm_s1_io_in_rx_snp_bits_txnID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[3] && lm_s1_io_in_rx_snp_bits_txnID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[4] && lm_s1_io_in_rx_snp_bits_txnID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[5] && lm_s1_io_in_rx_snp_bits_txnID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[6] && lm_s1_io_in_rx_snp_bits_txnID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[7] && lm_s1_io_in_rx_snp_bits_txnID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[8] && lm_s1_io_in_rx_snp_bits_txnID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[9] && lm_s1_io_in_rx_snp_bits_txnID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[10] && lm_s1_io_in_rx_snp_bits_txnID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_txnID[11] && lm_s1_io_in_rx_snp_bits_txnID[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_txnID[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[0] && lm_s1_io_in_rx_snp_bits_fwdNID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[1] && lm_s1_io_in_rx_snp_bits_fwdNID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[2] && lm_s1_io_in_rx_snp_bits_fwdNID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[3] && lm_s1_io_in_rx_snp_bits_fwdNID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[4] && lm_s1_io_in_rx_snp_bits_fwdNID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[5] && lm_s1_io_in_rx_snp_bits_fwdNID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[6] && lm_s1_io_in_rx_snp_bits_fwdNID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[7] && lm_s1_io_in_rx_snp_bits_fwdNID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[8] && lm_s1_io_in_rx_snp_bits_fwdNID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[9] && lm_s1_io_in_rx_snp_bits_fwdNID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdNID[10] && lm_s1_io_in_rx_snp_bits_fwdNID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdNID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[0] && lm_s1_io_in_rx_snp_bits_fwdTxnID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[1] && lm_s1_io_in_rx_snp_bits_fwdTxnID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[2] && lm_s1_io_in_rx_snp_bits_fwdTxnID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[3] && lm_s1_io_in_rx_snp_bits_fwdTxnID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[4] && lm_s1_io_in_rx_snp_bits_fwdTxnID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[5] && lm_s1_io_in_rx_snp_bits_fwdTxnID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[6] && lm_s1_io_in_rx_snp_bits_fwdTxnID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[7] && lm_s1_io_in_rx_snp_bits_fwdTxnID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[8] && lm_s1_io_in_rx_snp_bits_fwdTxnID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[9] && lm_s1_io_in_rx_snp_bits_fwdTxnID[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[10] && lm_s1_io_in_rx_snp_bits_fwdTxnID[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_fwdTxnID[11] && lm_s1_io_in_rx_snp_bits_fwdTxnID[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_fwdTxnID[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_opcode[0] && lm_s1_io_in_rx_snp_bits_opcode[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_opcode[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_opcode[1] && lm_s1_io_in_rx_snp_bits_opcode[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_opcode[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_opcode[2] && lm_s1_io_in_rx_snp_bits_opcode[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_opcode[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_opcode[3] && lm_s1_io_in_rx_snp_bits_opcode[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_opcode[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_opcode[4] && lm_s1_io_in_rx_snp_bits_opcode[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_opcode[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[0] && lm_s1_io_in_rx_snp_bits_addr[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[1] && lm_s1_io_in_rx_snp_bits_addr[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[2] && lm_s1_io_in_rx_snp_bits_addr[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[3] && lm_s1_io_in_rx_snp_bits_addr[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[4] && lm_s1_io_in_rx_snp_bits_addr[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[5] && lm_s1_io_in_rx_snp_bits_addr[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[6] && lm_s1_io_in_rx_snp_bits_addr[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[7] && lm_s1_io_in_rx_snp_bits_addr[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[8] && lm_s1_io_in_rx_snp_bits_addr[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[9] && lm_s1_io_in_rx_snp_bits_addr[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[10] && lm_s1_io_in_rx_snp_bits_addr[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[11] && lm_s1_io_in_rx_snp_bits_addr[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[12] && lm_s1_io_in_rx_snp_bits_addr[12])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[12] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[13] && lm_s1_io_in_rx_snp_bits_addr[13])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[13] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[14] && lm_s1_io_in_rx_snp_bits_addr[14])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[14] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[15] && lm_s1_io_in_rx_snp_bits_addr[15])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[15] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[16] && lm_s1_io_in_rx_snp_bits_addr[16])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[16] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[17] && lm_s1_io_in_rx_snp_bits_addr[17])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[17] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[18] && lm_s1_io_in_rx_snp_bits_addr[18])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[18] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[19] && lm_s1_io_in_rx_snp_bits_addr[19])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[19] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[20] && lm_s1_io_in_rx_snp_bits_addr[20])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[20] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[21] && lm_s1_io_in_rx_snp_bits_addr[21])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[21] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[22] && lm_s1_io_in_rx_snp_bits_addr[22])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[22] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[23] && lm_s1_io_in_rx_snp_bits_addr[23])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[23] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[24] && lm_s1_io_in_rx_snp_bits_addr[24])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[24] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[25] && lm_s1_io_in_rx_snp_bits_addr[25])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[25] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[26] && lm_s1_io_in_rx_snp_bits_addr[26])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[26] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[27] && lm_s1_io_in_rx_snp_bits_addr[27])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[27] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[28] && lm_s1_io_in_rx_snp_bits_addr[28])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[28] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[29] && lm_s1_io_in_rx_snp_bits_addr[29])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[29] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[30] && lm_s1_io_in_rx_snp_bits_addr[30])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[30] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[31] && lm_s1_io_in_rx_snp_bits_addr[31])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[31] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[32] && lm_s1_io_in_rx_snp_bits_addr[32])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[32] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[33] && lm_s1_io_in_rx_snp_bits_addr[33])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[33] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[34] && lm_s1_io_in_rx_snp_bits_addr[34])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[34] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[35] && lm_s1_io_in_rx_snp_bits_addr[35])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[35] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[36] && lm_s1_io_in_rx_snp_bits_addr[36])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[36] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[37] && lm_s1_io_in_rx_snp_bits_addr[37])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[37] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[38] && lm_s1_io_in_rx_snp_bits_addr[38])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[38] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[39] && lm_s1_io_in_rx_snp_bits_addr[39])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[39] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[40] && lm_s1_io_in_rx_snp_bits_addr[40])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[40] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[41] && lm_s1_io_in_rx_snp_bits_addr[41])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[41] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[42] && lm_s1_io_in_rx_snp_bits_addr[42])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[42] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[43] && lm_s1_io_in_rx_snp_bits_addr[43])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[43] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_addr[44] && lm_s1_io_in_rx_snp_bits_addr[44])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_addr[44] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_ns && lm_s1_io_in_rx_snp_bits_ns)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_ns 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_doNotGoToSD && lm_s1_io_in_rx_snp_bits_doNotGoToSD)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_doNotGoToSD 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_retToSrc && lm_s1_io_in_rx_snp_bits_retToSrc)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_retToSrc 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_traceTag && lm_s1_io_in_rx_snp_bits_traceTag)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_traceTag 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_perfMonGroup && lm_s1_io_in_rx_snp_bits_mpam_perfMonGroup)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_perfMonGroup 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[0] && lm_s1_io_in_rx_snp_bits_mpam_partID[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[1] && lm_s1_io_in_rx_snp_bits_mpam_partID[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[2] && lm_s1_io_in_rx_snp_bits_mpam_partID[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[3] && lm_s1_io_in_rx_snp_bits_mpam_partID[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[4] && lm_s1_io_in_rx_snp_bits_mpam_partID[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[5] && lm_s1_io_in_rx_snp_bits_mpam_partID[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[6] && lm_s1_io_in_rx_snp_bits_mpam_partID[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[7] && lm_s1_io_in_rx_snp_bits_mpam_partID[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_partID[8] && lm_s1_io_in_rx_snp_bits_mpam_partID[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_partID[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_in_rx_snp_bits_mpam_mpamNS && lm_s1_io_in_rx_snp_bits_mpam_mpamNS)) begin cov_fail++; $display("[COV] LinkMonitor.io_in_rx_snp_bits_mpam_mpamNS 未见过 0 和 1"); end
    if (!(lm_s0_io_out_txsactive && lm_s1_io_out_txsactive)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_txsactive 未见过 0 和 1"); end
    if (!(lm_s0_io_out_syscoreq && lm_s1_io_out_syscoreq)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_syscoreq 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_linkactivereq && lm_s1_io_out_tx_linkactivereq)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_linkactivereq 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flitpend && lm_s1_io_out_tx_req_flitpend)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flitpend 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flitv && lm_s1_io_out_tx_req_flitv)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flitv 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[0] && lm_s1_io_out_tx_req_flit[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[1] && lm_s1_io_out_tx_req_flit[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[2] && lm_s1_io_out_tx_req_flit[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[3] && lm_s1_io_out_tx_req_flit[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[4] && lm_s1_io_out_tx_req_flit[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[5] && lm_s1_io_out_tx_req_flit[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[6] && lm_s1_io_out_tx_req_flit[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[7] && lm_s1_io_out_tx_req_flit[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[8] && lm_s1_io_out_tx_req_flit[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[9] && lm_s1_io_out_tx_req_flit[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[10] && lm_s1_io_out_tx_req_flit[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[11] && lm_s1_io_out_tx_req_flit[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[12] && lm_s1_io_out_tx_req_flit[12])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[12] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[13] && lm_s1_io_out_tx_req_flit[13])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[13] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[14] && lm_s1_io_out_tx_req_flit[14])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[14] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[15] && lm_s1_io_out_tx_req_flit[15])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[15] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[16] && lm_s1_io_out_tx_req_flit[16])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[16] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[17] && lm_s1_io_out_tx_req_flit[17])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[17] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[18] && lm_s1_io_out_tx_req_flit[18])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[18] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[19] && lm_s1_io_out_tx_req_flit[19])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[19] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[20] && lm_s1_io_out_tx_req_flit[20])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[20] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[21] && lm_s1_io_out_tx_req_flit[21])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[21] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[22] && lm_s1_io_out_tx_req_flit[22])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[22] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[23] && lm_s1_io_out_tx_req_flit[23])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[23] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[24] && lm_s1_io_out_tx_req_flit[24])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[24] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[25] && lm_s1_io_out_tx_req_flit[25])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[25] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[26] && lm_s1_io_out_tx_req_flit[26])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[26] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[27] && lm_s1_io_out_tx_req_flit[27])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[27] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[28] && lm_s1_io_out_tx_req_flit[28])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[28] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[29] && lm_s1_io_out_tx_req_flit[29])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[29] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[30] && lm_s1_io_out_tx_req_flit[30])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[30] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[31] && lm_s1_io_out_tx_req_flit[31])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[31] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[32] && lm_s1_io_out_tx_req_flit[32])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[32] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[33] && lm_s1_io_out_tx_req_flit[33])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[33] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[34] && lm_s1_io_out_tx_req_flit[34])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[34] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[35] && lm_s1_io_out_tx_req_flit[35])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[35] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[36] && lm_s1_io_out_tx_req_flit[36])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[36] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[37] && lm_s1_io_out_tx_req_flit[37])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[37] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[38] && lm_s1_io_out_tx_req_flit[38])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[38] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[39] && lm_s1_io_out_tx_req_flit[39])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[39] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[40] && lm_s1_io_out_tx_req_flit[40])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[40] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[41] && lm_s1_io_out_tx_req_flit[41])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[41] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[42] && lm_s1_io_out_tx_req_flit[42])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[42] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[43] && lm_s1_io_out_tx_req_flit[43])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[43] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[44] && lm_s1_io_out_tx_req_flit[44])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[44] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[45] && lm_s1_io_out_tx_req_flit[45])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[45] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[46] && lm_s1_io_out_tx_req_flit[46])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[46] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[47] && lm_s1_io_out_tx_req_flit[47])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[47] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[48] && lm_s1_io_out_tx_req_flit[48])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[48] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[49] && lm_s1_io_out_tx_req_flit[49])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[49] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[50] && lm_s1_io_out_tx_req_flit[50])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[50] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[51] && lm_s1_io_out_tx_req_flit[51])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[51] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[52] && lm_s1_io_out_tx_req_flit[52])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[52] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[53] && lm_s1_io_out_tx_req_flit[53])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[53] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[54] && lm_s1_io_out_tx_req_flit[54])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[54] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[55] && lm_s1_io_out_tx_req_flit[55])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[55] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[56] && lm_s1_io_out_tx_req_flit[56])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[56] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[57] && lm_s1_io_out_tx_req_flit[57])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[57] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[58] && lm_s1_io_out_tx_req_flit[58])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[58] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[59] && lm_s1_io_out_tx_req_flit[59])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[59] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[60] && lm_s1_io_out_tx_req_flit[60])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[60] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[61] && lm_s1_io_out_tx_req_flit[61])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[61] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[62] && lm_s1_io_out_tx_req_flit[62])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[62] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[63] && lm_s1_io_out_tx_req_flit[63])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[63] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[64] && lm_s1_io_out_tx_req_flit[64])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[64] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[65] && lm_s1_io_out_tx_req_flit[65])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[65] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[66] && lm_s1_io_out_tx_req_flit[66])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[66] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[67] && lm_s1_io_out_tx_req_flit[67])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[67] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[68] && lm_s1_io_out_tx_req_flit[68])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[68] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[69] && lm_s1_io_out_tx_req_flit[69])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[69] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[70] && lm_s1_io_out_tx_req_flit[70])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[70] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[71] && lm_s1_io_out_tx_req_flit[71])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[71] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[72] && lm_s1_io_out_tx_req_flit[72])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[72] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[73] && lm_s1_io_out_tx_req_flit[73])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[73] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[74] && lm_s1_io_out_tx_req_flit[74])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[74] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[75] && lm_s1_io_out_tx_req_flit[75])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[75] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[76] && lm_s1_io_out_tx_req_flit[76])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[76] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[77] && lm_s1_io_out_tx_req_flit[77])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[77] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[78] && lm_s1_io_out_tx_req_flit[78])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[78] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[79] && lm_s1_io_out_tx_req_flit[79])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[79] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[80] && lm_s1_io_out_tx_req_flit[80])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[80] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[81] && lm_s1_io_out_tx_req_flit[81])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[81] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[82] && lm_s1_io_out_tx_req_flit[82])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[82] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[83] && lm_s1_io_out_tx_req_flit[83])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[83] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[84] && lm_s1_io_out_tx_req_flit[84])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[84] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[85] && lm_s1_io_out_tx_req_flit[85])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[85] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[86] && lm_s1_io_out_tx_req_flit[86])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[86] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[87] && lm_s1_io_out_tx_req_flit[87])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[87] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[88] && lm_s1_io_out_tx_req_flit[88])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[88] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[89] && lm_s1_io_out_tx_req_flit[89])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[89] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[90] && lm_s1_io_out_tx_req_flit[90])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[90] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[91] && lm_s1_io_out_tx_req_flit[91])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[91] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[92] && lm_s1_io_out_tx_req_flit[92])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[92] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[93] && lm_s1_io_out_tx_req_flit[93])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[93] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[94] && lm_s1_io_out_tx_req_flit[94])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[94] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[95] && lm_s1_io_out_tx_req_flit[95])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[95] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[96] && lm_s1_io_out_tx_req_flit[96])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[96] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[97] && lm_s1_io_out_tx_req_flit[97])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[97] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[98] && lm_s1_io_out_tx_req_flit[98])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[98] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[99] && lm_s1_io_out_tx_req_flit[99])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[99] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[100] && lm_s1_io_out_tx_req_flit[100])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[100] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[101] && lm_s1_io_out_tx_req_flit[101])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[101] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[102] && lm_s1_io_out_tx_req_flit[102])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[102] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[103] && lm_s1_io_out_tx_req_flit[103])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[103] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[104] && lm_s1_io_out_tx_req_flit[104])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[104] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[105] && lm_s1_io_out_tx_req_flit[105])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[105] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[106] && lm_s1_io_out_tx_req_flit[106])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[106] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[107] && lm_s1_io_out_tx_req_flit[107])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[107] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[108] && lm_s1_io_out_tx_req_flit[108])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[108] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[109] && lm_s1_io_out_tx_req_flit[109])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[109] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[110] && lm_s1_io_out_tx_req_flit[110])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[110] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[111] && lm_s1_io_out_tx_req_flit[111])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[111] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[112] && lm_s1_io_out_tx_req_flit[112])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[112] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[113] && lm_s1_io_out_tx_req_flit[113])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[113] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[114] && lm_s1_io_out_tx_req_flit[114])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[114] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[115] && lm_s1_io_out_tx_req_flit[115])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[115] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[116] && lm_s1_io_out_tx_req_flit[116])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[116] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[117] && lm_s1_io_out_tx_req_flit[117])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[117] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[118] && lm_s1_io_out_tx_req_flit[118])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[118] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[119] && lm_s1_io_out_tx_req_flit[119])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[119] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[120] && lm_s1_io_out_tx_req_flit[120])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[120] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[121] && lm_s1_io_out_tx_req_flit[121])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[121] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[122] && lm_s1_io_out_tx_req_flit[122])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[122] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[123] && lm_s1_io_out_tx_req_flit[123])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[123] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[124] && lm_s1_io_out_tx_req_flit[124])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[124] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[125] && lm_s1_io_out_tx_req_flit[125])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[125] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[126] && lm_s1_io_out_tx_req_flit[126])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[126] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[127] && lm_s1_io_out_tx_req_flit[127])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[127] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[128] && lm_s1_io_out_tx_req_flit[128])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[128] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[129] && lm_s1_io_out_tx_req_flit[129])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[129] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[130] && lm_s1_io_out_tx_req_flit[130])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[130] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[131] && lm_s1_io_out_tx_req_flit[131])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[131] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[132] && lm_s1_io_out_tx_req_flit[132])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[132] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[133] && lm_s1_io_out_tx_req_flit[133])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[133] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[134] && lm_s1_io_out_tx_req_flit[134])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[134] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[135] && lm_s1_io_out_tx_req_flit[135])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[135] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[136] && lm_s1_io_out_tx_req_flit[136])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[136] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[137] && lm_s1_io_out_tx_req_flit[137])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[137] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[138] && lm_s1_io_out_tx_req_flit[138])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[138] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[139] && lm_s1_io_out_tx_req_flit[139])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[139] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[140] && lm_s1_io_out_tx_req_flit[140])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[140] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[141] && lm_s1_io_out_tx_req_flit[141])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[141] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[142] && lm_s1_io_out_tx_req_flit[142])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[142] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[143] && lm_s1_io_out_tx_req_flit[143])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[143] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[144] && lm_s1_io_out_tx_req_flit[144])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[144] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[145] && lm_s1_io_out_tx_req_flit[145])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[145] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[146] && lm_s1_io_out_tx_req_flit[146])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[146] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[147] && lm_s1_io_out_tx_req_flit[147])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[147] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[148] && lm_s1_io_out_tx_req_flit[148])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[148] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[149] && lm_s1_io_out_tx_req_flit[149])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[149] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[150] && lm_s1_io_out_tx_req_flit[150])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[150] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[151] && lm_s1_io_out_tx_req_flit[151])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[151] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[152] && lm_s1_io_out_tx_req_flit[152])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[152] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[153] && lm_s1_io_out_tx_req_flit[153])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[153] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[154] && lm_s1_io_out_tx_req_flit[154])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[154] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[155] && lm_s1_io_out_tx_req_flit[155])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[155] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[156] && lm_s1_io_out_tx_req_flit[156])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[156] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[157] && lm_s1_io_out_tx_req_flit[157])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[157] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[158] && lm_s1_io_out_tx_req_flit[158])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[158] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[159] && lm_s1_io_out_tx_req_flit[159])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[159] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[160] && lm_s1_io_out_tx_req_flit[160])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[160] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_req_flit[161] && lm_s1_io_out_tx_req_flit[161])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_req_flit[161] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flitpend && lm_s1_io_out_tx_rsp_flitpend)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flitpend 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flitv && lm_s1_io_out_tx_rsp_flitv)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flitv 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[0] && lm_s1_io_out_tx_rsp_flit[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[1] && lm_s1_io_out_tx_rsp_flit[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[2] && lm_s1_io_out_tx_rsp_flit[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[3] && lm_s1_io_out_tx_rsp_flit[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[4] && lm_s1_io_out_tx_rsp_flit[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[5] && lm_s1_io_out_tx_rsp_flit[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[6] && lm_s1_io_out_tx_rsp_flit[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[7] && lm_s1_io_out_tx_rsp_flit[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[8] && lm_s1_io_out_tx_rsp_flit[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[9] && lm_s1_io_out_tx_rsp_flit[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[10] && lm_s1_io_out_tx_rsp_flit[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[11] && lm_s1_io_out_tx_rsp_flit[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[12] && lm_s1_io_out_tx_rsp_flit[12])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[12] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[13] && lm_s1_io_out_tx_rsp_flit[13])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[13] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[14] && lm_s1_io_out_tx_rsp_flit[14])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[14] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[15] && lm_s1_io_out_tx_rsp_flit[15])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[15] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[16] && lm_s1_io_out_tx_rsp_flit[16])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[16] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[17] && lm_s1_io_out_tx_rsp_flit[17])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[17] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[18] && lm_s1_io_out_tx_rsp_flit[18])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[18] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[19] && lm_s1_io_out_tx_rsp_flit[19])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[19] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[20] && lm_s1_io_out_tx_rsp_flit[20])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[20] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[21] && lm_s1_io_out_tx_rsp_flit[21])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[21] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[22] && lm_s1_io_out_tx_rsp_flit[22])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[22] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[23] && lm_s1_io_out_tx_rsp_flit[23])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[23] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[24] && lm_s1_io_out_tx_rsp_flit[24])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[24] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[25] && lm_s1_io_out_tx_rsp_flit[25])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[25] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[26] && lm_s1_io_out_tx_rsp_flit[26])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[26] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[27] && lm_s1_io_out_tx_rsp_flit[27])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[27] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[28] && lm_s1_io_out_tx_rsp_flit[28])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[28] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[29] && lm_s1_io_out_tx_rsp_flit[29])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[29] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[30] && lm_s1_io_out_tx_rsp_flit[30])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[30] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[31] && lm_s1_io_out_tx_rsp_flit[31])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[31] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[32] && lm_s1_io_out_tx_rsp_flit[32])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[32] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[33] && lm_s1_io_out_tx_rsp_flit[33])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[33] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[34] && lm_s1_io_out_tx_rsp_flit[34])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[34] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[35] && lm_s1_io_out_tx_rsp_flit[35])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[35] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[36] && lm_s1_io_out_tx_rsp_flit[36])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[36] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[37] && lm_s1_io_out_tx_rsp_flit[37])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[37] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[38] && lm_s1_io_out_tx_rsp_flit[38])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[38] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[39] && lm_s1_io_out_tx_rsp_flit[39])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[39] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[40] && lm_s1_io_out_tx_rsp_flit[40])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[40] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[41] && lm_s1_io_out_tx_rsp_flit[41])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[41] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[42] && lm_s1_io_out_tx_rsp_flit[42])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[42] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[43] && lm_s1_io_out_tx_rsp_flit[43])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[43] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[44] && lm_s1_io_out_tx_rsp_flit[44])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[44] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[45] && lm_s1_io_out_tx_rsp_flit[45])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[45] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[46] && lm_s1_io_out_tx_rsp_flit[46])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[46] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[47] && lm_s1_io_out_tx_rsp_flit[47])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[47] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[48] && lm_s1_io_out_tx_rsp_flit[48])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[48] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[49] && lm_s1_io_out_tx_rsp_flit[49])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[49] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[50] && lm_s1_io_out_tx_rsp_flit[50])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[50] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[51] && lm_s1_io_out_tx_rsp_flit[51])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[51] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[52] && lm_s1_io_out_tx_rsp_flit[52])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[52] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[53] && lm_s1_io_out_tx_rsp_flit[53])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[53] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[54] && lm_s1_io_out_tx_rsp_flit[54])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[54] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[55] && lm_s1_io_out_tx_rsp_flit[55])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[55] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[56] && lm_s1_io_out_tx_rsp_flit[56])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[56] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[57] && lm_s1_io_out_tx_rsp_flit[57])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[57] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[58] && lm_s1_io_out_tx_rsp_flit[58])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[58] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[59] && lm_s1_io_out_tx_rsp_flit[59])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[59] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[60] && lm_s1_io_out_tx_rsp_flit[60])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[60] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[61] && lm_s1_io_out_tx_rsp_flit[61])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[61] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[62] && lm_s1_io_out_tx_rsp_flit[62])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[62] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[63] && lm_s1_io_out_tx_rsp_flit[63])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[63] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[64] && lm_s1_io_out_tx_rsp_flit[64])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[64] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[65] && lm_s1_io_out_tx_rsp_flit[65])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[65] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[66] && lm_s1_io_out_tx_rsp_flit[66])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[66] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[67] && lm_s1_io_out_tx_rsp_flit[67])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[67] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[68] && lm_s1_io_out_tx_rsp_flit[68])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[68] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[69] && lm_s1_io_out_tx_rsp_flit[69])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[69] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[70] && lm_s1_io_out_tx_rsp_flit[70])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[70] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[71] && lm_s1_io_out_tx_rsp_flit[71])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[71] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_rsp_flit[72] && lm_s1_io_out_tx_rsp_flit[72])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_rsp_flit[72] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flitpend && lm_s1_io_out_tx_dat_flitpend)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flitpend 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flitv && lm_s1_io_out_tx_dat_flitv)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flitv 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[0] && lm_s1_io_out_tx_dat_flit[0])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[0] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[1] && lm_s1_io_out_tx_dat_flit[1])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[1] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[2] && lm_s1_io_out_tx_dat_flit[2])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[2] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[3] && lm_s1_io_out_tx_dat_flit[3])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[3] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[4] && lm_s1_io_out_tx_dat_flit[4])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[4] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[5] && lm_s1_io_out_tx_dat_flit[5])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[5] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[6] && lm_s1_io_out_tx_dat_flit[6])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[6] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[7] && lm_s1_io_out_tx_dat_flit[7])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[7] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[8] && lm_s1_io_out_tx_dat_flit[8])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[8] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[9] && lm_s1_io_out_tx_dat_flit[9])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[9] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[10] && lm_s1_io_out_tx_dat_flit[10])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[10] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[11] && lm_s1_io_out_tx_dat_flit[11])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[11] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[12] && lm_s1_io_out_tx_dat_flit[12])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[12] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[13] && lm_s1_io_out_tx_dat_flit[13])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[13] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[14] && lm_s1_io_out_tx_dat_flit[14])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[14] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[15] && lm_s1_io_out_tx_dat_flit[15])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[15] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[16] && lm_s1_io_out_tx_dat_flit[16])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[16] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[17] && lm_s1_io_out_tx_dat_flit[17])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[17] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[18] && lm_s1_io_out_tx_dat_flit[18])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[18] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[19] && lm_s1_io_out_tx_dat_flit[19])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[19] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[20] && lm_s1_io_out_tx_dat_flit[20])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[20] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[21] && lm_s1_io_out_tx_dat_flit[21])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[21] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[22] && lm_s1_io_out_tx_dat_flit[22])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[22] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[23] && lm_s1_io_out_tx_dat_flit[23])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[23] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[24] && lm_s1_io_out_tx_dat_flit[24])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[24] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[25] && lm_s1_io_out_tx_dat_flit[25])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[25] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[26] && lm_s1_io_out_tx_dat_flit[26])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[26] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[27] && lm_s1_io_out_tx_dat_flit[27])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[27] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[28] && lm_s1_io_out_tx_dat_flit[28])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[28] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[29] && lm_s1_io_out_tx_dat_flit[29])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[29] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[30] && lm_s1_io_out_tx_dat_flit[30])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[30] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[31] && lm_s1_io_out_tx_dat_flit[31])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[31] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[32] && lm_s1_io_out_tx_dat_flit[32])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[32] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[33] && lm_s1_io_out_tx_dat_flit[33])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[33] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[34] && lm_s1_io_out_tx_dat_flit[34])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[34] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[35] && lm_s1_io_out_tx_dat_flit[35])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[35] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[36] && lm_s1_io_out_tx_dat_flit[36])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[36] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[37] && lm_s1_io_out_tx_dat_flit[37])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[37] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[38] && lm_s1_io_out_tx_dat_flit[38])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[38] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[39] && lm_s1_io_out_tx_dat_flit[39])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[39] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[40] && lm_s1_io_out_tx_dat_flit[40])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[40] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[41] && lm_s1_io_out_tx_dat_flit[41])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[41] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[42] && lm_s1_io_out_tx_dat_flit[42])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[42] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[43] && lm_s1_io_out_tx_dat_flit[43])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[43] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[44] && lm_s1_io_out_tx_dat_flit[44])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[44] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[45] && lm_s1_io_out_tx_dat_flit[45])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[45] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[46] && lm_s1_io_out_tx_dat_flit[46])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[46] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[47] && lm_s1_io_out_tx_dat_flit[47])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[47] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[48] && lm_s1_io_out_tx_dat_flit[48])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[48] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[49] && lm_s1_io_out_tx_dat_flit[49])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[49] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[50] && lm_s1_io_out_tx_dat_flit[50])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[50] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[51] && lm_s1_io_out_tx_dat_flit[51])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[51] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[52] && lm_s1_io_out_tx_dat_flit[52])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[52] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[53] && lm_s1_io_out_tx_dat_flit[53])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[53] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[54] && lm_s1_io_out_tx_dat_flit[54])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[54] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[55] && lm_s1_io_out_tx_dat_flit[55])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[55] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[56] && lm_s1_io_out_tx_dat_flit[56])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[56] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[57] && lm_s1_io_out_tx_dat_flit[57])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[57] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[58] && lm_s1_io_out_tx_dat_flit[58])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[58] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[59] && lm_s1_io_out_tx_dat_flit[59])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[59] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[60] && lm_s1_io_out_tx_dat_flit[60])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[60] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[61] && lm_s1_io_out_tx_dat_flit[61])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[61] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[62] && lm_s1_io_out_tx_dat_flit[62])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[62] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[63] && lm_s1_io_out_tx_dat_flit[63])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[63] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[64] && lm_s1_io_out_tx_dat_flit[64])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[64] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[65] && lm_s1_io_out_tx_dat_flit[65])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[65] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[66] && lm_s1_io_out_tx_dat_flit[66])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[66] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[67] && lm_s1_io_out_tx_dat_flit[67])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[67] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[68] && lm_s1_io_out_tx_dat_flit[68])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[68] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[69] && lm_s1_io_out_tx_dat_flit[69])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[69] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[70] && lm_s1_io_out_tx_dat_flit[70])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[70] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[71] && lm_s1_io_out_tx_dat_flit[71])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[71] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[72] && lm_s1_io_out_tx_dat_flit[72])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[72] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[73] && lm_s1_io_out_tx_dat_flit[73])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[73] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[74] && lm_s1_io_out_tx_dat_flit[74])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[74] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[75] && lm_s1_io_out_tx_dat_flit[75])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[75] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[76] && lm_s1_io_out_tx_dat_flit[76])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[76] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[77] && lm_s1_io_out_tx_dat_flit[77])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[77] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[78] && lm_s1_io_out_tx_dat_flit[78])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[78] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[79] && lm_s1_io_out_tx_dat_flit[79])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[79] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[80] && lm_s1_io_out_tx_dat_flit[80])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[80] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[81] && lm_s1_io_out_tx_dat_flit[81])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[81] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[82] && lm_s1_io_out_tx_dat_flit[82])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[82] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[83] && lm_s1_io_out_tx_dat_flit[83])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[83] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[84] && lm_s1_io_out_tx_dat_flit[84])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[84] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[85] && lm_s1_io_out_tx_dat_flit[85])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[85] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[86] && lm_s1_io_out_tx_dat_flit[86])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[86] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[87] && lm_s1_io_out_tx_dat_flit[87])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[87] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[88] && lm_s1_io_out_tx_dat_flit[88])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[88] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[89] && lm_s1_io_out_tx_dat_flit[89])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[89] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[90] && lm_s1_io_out_tx_dat_flit[90])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[90] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[91] && lm_s1_io_out_tx_dat_flit[91])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[91] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[92] && lm_s1_io_out_tx_dat_flit[92])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[92] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[93] && lm_s1_io_out_tx_dat_flit[93])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[93] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[94] && lm_s1_io_out_tx_dat_flit[94])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[94] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[95] && lm_s1_io_out_tx_dat_flit[95])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[95] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[96] && lm_s1_io_out_tx_dat_flit[96])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[96] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[97] && lm_s1_io_out_tx_dat_flit[97])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[97] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[98] && lm_s1_io_out_tx_dat_flit[98])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[98] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[99] && lm_s1_io_out_tx_dat_flit[99])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[99] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[100] && lm_s1_io_out_tx_dat_flit[100])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[100] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[101] && lm_s1_io_out_tx_dat_flit[101])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[101] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[102] && lm_s1_io_out_tx_dat_flit[102])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[102] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[103] && lm_s1_io_out_tx_dat_flit[103])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[103] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[104] && lm_s1_io_out_tx_dat_flit[104])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[104] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[105] && lm_s1_io_out_tx_dat_flit[105])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[105] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[106] && lm_s1_io_out_tx_dat_flit[106])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[106] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[107] && lm_s1_io_out_tx_dat_flit[107])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[107] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[108] && lm_s1_io_out_tx_dat_flit[108])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[108] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[109] && lm_s1_io_out_tx_dat_flit[109])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[109] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[110] && lm_s1_io_out_tx_dat_flit[110])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[110] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[111] && lm_s1_io_out_tx_dat_flit[111])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[111] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[112] && lm_s1_io_out_tx_dat_flit[112])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[112] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[113] && lm_s1_io_out_tx_dat_flit[113])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[113] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[114] && lm_s1_io_out_tx_dat_flit[114])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[114] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[115] && lm_s1_io_out_tx_dat_flit[115])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[115] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[116] && lm_s1_io_out_tx_dat_flit[116])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[116] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[117] && lm_s1_io_out_tx_dat_flit[117])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[117] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[118] && lm_s1_io_out_tx_dat_flit[118])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[118] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[119] && lm_s1_io_out_tx_dat_flit[119])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[119] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[120] && lm_s1_io_out_tx_dat_flit[120])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[120] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[121] && lm_s1_io_out_tx_dat_flit[121])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[121] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[122] && lm_s1_io_out_tx_dat_flit[122])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[122] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[123] && lm_s1_io_out_tx_dat_flit[123])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[123] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[124] && lm_s1_io_out_tx_dat_flit[124])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[124] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[125] && lm_s1_io_out_tx_dat_flit[125])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[125] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[126] && lm_s1_io_out_tx_dat_flit[126])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[126] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[127] && lm_s1_io_out_tx_dat_flit[127])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[127] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[128] && lm_s1_io_out_tx_dat_flit[128])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[128] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[129] && lm_s1_io_out_tx_dat_flit[129])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[129] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[130] && lm_s1_io_out_tx_dat_flit[130])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[130] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[131] && lm_s1_io_out_tx_dat_flit[131])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[131] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[132] && lm_s1_io_out_tx_dat_flit[132])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[132] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[133] && lm_s1_io_out_tx_dat_flit[133])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[133] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[134] && lm_s1_io_out_tx_dat_flit[134])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[134] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[135] && lm_s1_io_out_tx_dat_flit[135])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[135] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[136] && lm_s1_io_out_tx_dat_flit[136])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[136] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[137] && lm_s1_io_out_tx_dat_flit[137])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[137] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[138] && lm_s1_io_out_tx_dat_flit[138])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[138] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[139] && lm_s1_io_out_tx_dat_flit[139])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[139] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[140] && lm_s1_io_out_tx_dat_flit[140])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[140] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[141] && lm_s1_io_out_tx_dat_flit[141])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[141] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[142] && lm_s1_io_out_tx_dat_flit[142])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[142] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[143] && lm_s1_io_out_tx_dat_flit[143])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[143] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[144] && lm_s1_io_out_tx_dat_flit[144])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[144] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[145] && lm_s1_io_out_tx_dat_flit[145])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[145] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[146] && lm_s1_io_out_tx_dat_flit[146])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[146] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[147] && lm_s1_io_out_tx_dat_flit[147])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[147] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[148] && lm_s1_io_out_tx_dat_flit[148])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[148] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[149] && lm_s1_io_out_tx_dat_flit[149])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[149] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[150] && lm_s1_io_out_tx_dat_flit[150])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[150] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[151] && lm_s1_io_out_tx_dat_flit[151])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[151] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[152] && lm_s1_io_out_tx_dat_flit[152])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[152] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[153] && lm_s1_io_out_tx_dat_flit[153])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[153] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[154] && lm_s1_io_out_tx_dat_flit[154])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[154] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[155] && lm_s1_io_out_tx_dat_flit[155])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[155] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[156] && lm_s1_io_out_tx_dat_flit[156])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[156] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[157] && lm_s1_io_out_tx_dat_flit[157])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[157] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[158] && lm_s1_io_out_tx_dat_flit[158])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[158] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[159] && lm_s1_io_out_tx_dat_flit[159])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[159] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[160] && lm_s1_io_out_tx_dat_flit[160])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[160] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[161] && lm_s1_io_out_tx_dat_flit[161])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[161] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[162] && lm_s1_io_out_tx_dat_flit[162])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[162] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[163] && lm_s1_io_out_tx_dat_flit[163])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[163] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[164] && lm_s1_io_out_tx_dat_flit[164])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[164] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[165] && lm_s1_io_out_tx_dat_flit[165])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[165] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[166] && lm_s1_io_out_tx_dat_flit[166])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[166] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[167] && lm_s1_io_out_tx_dat_flit[167])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[167] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[168] && lm_s1_io_out_tx_dat_flit[168])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[168] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[169] && lm_s1_io_out_tx_dat_flit[169])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[169] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[170] && lm_s1_io_out_tx_dat_flit[170])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[170] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[171] && lm_s1_io_out_tx_dat_flit[171])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[171] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[172] && lm_s1_io_out_tx_dat_flit[172])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[172] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[173] && lm_s1_io_out_tx_dat_flit[173])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[173] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[174] && lm_s1_io_out_tx_dat_flit[174])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[174] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[175] && lm_s1_io_out_tx_dat_flit[175])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[175] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[176] && lm_s1_io_out_tx_dat_flit[176])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[176] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[177] && lm_s1_io_out_tx_dat_flit[177])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[177] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[178] && lm_s1_io_out_tx_dat_flit[178])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[178] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[179] && lm_s1_io_out_tx_dat_flit[179])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[179] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[180] && lm_s1_io_out_tx_dat_flit[180])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[180] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[181] && lm_s1_io_out_tx_dat_flit[181])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[181] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[182] && lm_s1_io_out_tx_dat_flit[182])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[182] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[183] && lm_s1_io_out_tx_dat_flit[183])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[183] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[184] && lm_s1_io_out_tx_dat_flit[184])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[184] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[185] && lm_s1_io_out_tx_dat_flit[185])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[185] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[186] && lm_s1_io_out_tx_dat_flit[186])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[186] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[187] && lm_s1_io_out_tx_dat_flit[187])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[187] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[188] && lm_s1_io_out_tx_dat_flit[188])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[188] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[189] && lm_s1_io_out_tx_dat_flit[189])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[189] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[190] && lm_s1_io_out_tx_dat_flit[190])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[190] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[191] && lm_s1_io_out_tx_dat_flit[191])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[191] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[192] && lm_s1_io_out_tx_dat_flit[192])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[192] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[193] && lm_s1_io_out_tx_dat_flit[193])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[193] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[194] && lm_s1_io_out_tx_dat_flit[194])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[194] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[195] && lm_s1_io_out_tx_dat_flit[195])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[195] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[196] && lm_s1_io_out_tx_dat_flit[196])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[196] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[197] && lm_s1_io_out_tx_dat_flit[197])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[197] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[198] && lm_s1_io_out_tx_dat_flit[198])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[198] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[199] && lm_s1_io_out_tx_dat_flit[199])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[199] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[200] && lm_s1_io_out_tx_dat_flit[200])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[200] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[201] && lm_s1_io_out_tx_dat_flit[201])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[201] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[202] && lm_s1_io_out_tx_dat_flit[202])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[202] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[203] && lm_s1_io_out_tx_dat_flit[203])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[203] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[204] && lm_s1_io_out_tx_dat_flit[204])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[204] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[205] && lm_s1_io_out_tx_dat_flit[205])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[205] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[206] && lm_s1_io_out_tx_dat_flit[206])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[206] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[207] && lm_s1_io_out_tx_dat_flit[207])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[207] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[208] && lm_s1_io_out_tx_dat_flit[208])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[208] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[209] && lm_s1_io_out_tx_dat_flit[209])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[209] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[210] && lm_s1_io_out_tx_dat_flit[210])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[210] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[211] && lm_s1_io_out_tx_dat_flit[211])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[211] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[212] && lm_s1_io_out_tx_dat_flit[212])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[212] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[213] && lm_s1_io_out_tx_dat_flit[213])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[213] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[214] && lm_s1_io_out_tx_dat_flit[214])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[214] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[215] && lm_s1_io_out_tx_dat_flit[215])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[215] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[216] && lm_s1_io_out_tx_dat_flit[216])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[216] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[217] && lm_s1_io_out_tx_dat_flit[217])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[217] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[218] && lm_s1_io_out_tx_dat_flit[218])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[218] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[219] && lm_s1_io_out_tx_dat_flit[219])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[219] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[220] && lm_s1_io_out_tx_dat_flit[220])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[220] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[221] && lm_s1_io_out_tx_dat_flit[221])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[221] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[222] && lm_s1_io_out_tx_dat_flit[222])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[222] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[223] && lm_s1_io_out_tx_dat_flit[223])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[223] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[224] && lm_s1_io_out_tx_dat_flit[224])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[224] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[225] && lm_s1_io_out_tx_dat_flit[225])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[225] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[226] && lm_s1_io_out_tx_dat_flit[226])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[226] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[227] && lm_s1_io_out_tx_dat_flit[227])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[227] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[228] && lm_s1_io_out_tx_dat_flit[228])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[228] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[229] && lm_s1_io_out_tx_dat_flit[229])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[229] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[230] && lm_s1_io_out_tx_dat_flit[230])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[230] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[231] && lm_s1_io_out_tx_dat_flit[231])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[231] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[232] && lm_s1_io_out_tx_dat_flit[232])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[232] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[233] && lm_s1_io_out_tx_dat_flit[233])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[233] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[234] && lm_s1_io_out_tx_dat_flit[234])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[234] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[235] && lm_s1_io_out_tx_dat_flit[235])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[235] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[236] && lm_s1_io_out_tx_dat_flit[236])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[236] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[237] && lm_s1_io_out_tx_dat_flit[237])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[237] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[238] && lm_s1_io_out_tx_dat_flit[238])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[238] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[239] && lm_s1_io_out_tx_dat_flit[239])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[239] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[240] && lm_s1_io_out_tx_dat_flit[240])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[240] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[241] && lm_s1_io_out_tx_dat_flit[241])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[241] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[242] && lm_s1_io_out_tx_dat_flit[242])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[242] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[243] && lm_s1_io_out_tx_dat_flit[243])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[243] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[244] && lm_s1_io_out_tx_dat_flit[244])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[244] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[245] && lm_s1_io_out_tx_dat_flit[245])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[245] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[246] && lm_s1_io_out_tx_dat_flit[246])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[246] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[247] && lm_s1_io_out_tx_dat_flit[247])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[247] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[248] && lm_s1_io_out_tx_dat_flit[248])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[248] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[249] && lm_s1_io_out_tx_dat_flit[249])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[249] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[250] && lm_s1_io_out_tx_dat_flit[250])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[250] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[251] && lm_s1_io_out_tx_dat_flit[251])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[251] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[252] && lm_s1_io_out_tx_dat_flit[252])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[252] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[253] && lm_s1_io_out_tx_dat_flit[253])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[253] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[254] && lm_s1_io_out_tx_dat_flit[254])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[254] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[255] && lm_s1_io_out_tx_dat_flit[255])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[255] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[256] && lm_s1_io_out_tx_dat_flit[256])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[256] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[257] && lm_s1_io_out_tx_dat_flit[257])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[257] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[258] && lm_s1_io_out_tx_dat_flit[258])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[258] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[259] && lm_s1_io_out_tx_dat_flit[259])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[259] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[260] && lm_s1_io_out_tx_dat_flit[260])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[260] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[261] && lm_s1_io_out_tx_dat_flit[261])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[261] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[262] && lm_s1_io_out_tx_dat_flit[262])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[262] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[263] && lm_s1_io_out_tx_dat_flit[263])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[263] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[264] && lm_s1_io_out_tx_dat_flit[264])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[264] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[265] && lm_s1_io_out_tx_dat_flit[265])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[265] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[266] && lm_s1_io_out_tx_dat_flit[266])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[266] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[267] && lm_s1_io_out_tx_dat_flit[267])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[267] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[268] && lm_s1_io_out_tx_dat_flit[268])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[268] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[269] && lm_s1_io_out_tx_dat_flit[269])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[269] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[270] && lm_s1_io_out_tx_dat_flit[270])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[270] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[271] && lm_s1_io_out_tx_dat_flit[271])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[271] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[272] && lm_s1_io_out_tx_dat_flit[272])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[272] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[273] && lm_s1_io_out_tx_dat_flit[273])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[273] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[274] && lm_s1_io_out_tx_dat_flit[274])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[274] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[275] && lm_s1_io_out_tx_dat_flit[275])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[275] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[276] && lm_s1_io_out_tx_dat_flit[276])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[276] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[277] && lm_s1_io_out_tx_dat_flit[277])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[277] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[278] && lm_s1_io_out_tx_dat_flit[278])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[278] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[279] && lm_s1_io_out_tx_dat_flit[279])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[279] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[280] && lm_s1_io_out_tx_dat_flit[280])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[280] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[281] && lm_s1_io_out_tx_dat_flit[281])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[281] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[282] && lm_s1_io_out_tx_dat_flit[282])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[282] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[283] && lm_s1_io_out_tx_dat_flit[283])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[283] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[284] && lm_s1_io_out_tx_dat_flit[284])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[284] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[285] && lm_s1_io_out_tx_dat_flit[285])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[285] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[286] && lm_s1_io_out_tx_dat_flit[286])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[286] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[287] && lm_s1_io_out_tx_dat_flit[287])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[287] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[288] && lm_s1_io_out_tx_dat_flit[288])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[288] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[289] && lm_s1_io_out_tx_dat_flit[289])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[289] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[290] && lm_s1_io_out_tx_dat_flit[290])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[290] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[291] && lm_s1_io_out_tx_dat_flit[291])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[291] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[292] && lm_s1_io_out_tx_dat_flit[292])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[292] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[293] && lm_s1_io_out_tx_dat_flit[293])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[293] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[294] && lm_s1_io_out_tx_dat_flit[294])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[294] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[295] && lm_s1_io_out_tx_dat_flit[295])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[295] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[296] && lm_s1_io_out_tx_dat_flit[296])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[296] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[297] && lm_s1_io_out_tx_dat_flit[297])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[297] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[298] && lm_s1_io_out_tx_dat_flit[298])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[298] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[299] && lm_s1_io_out_tx_dat_flit[299])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[299] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[300] && lm_s1_io_out_tx_dat_flit[300])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[300] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[301] && lm_s1_io_out_tx_dat_flit[301])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[301] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[302] && lm_s1_io_out_tx_dat_flit[302])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[302] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[303] && lm_s1_io_out_tx_dat_flit[303])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[303] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[304] && lm_s1_io_out_tx_dat_flit[304])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[304] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[305] && lm_s1_io_out_tx_dat_flit[305])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[305] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[306] && lm_s1_io_out_tx_dat_flit[306])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[306] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[307] && lm_s1_io_out_tx_dat_flit[307])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[307] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[308] && lm_s1_io_out_tx_dat_flit[308])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[308] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[309] && lm_s1_io_out_tx_dat_flit[309])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[309] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[310] && lm_s1_io_out_tx_dat_flit[310])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[310] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[311] && lm_s1_io_out_tx_dat_flit[311])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[311] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[312] && lm_s1_io_out_tx_dat_flit[312])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[312] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[313] && lm_s1_io_out_tx_dat_flit[313])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[313] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[314] && lm_s1_io_out_tx_dat_flit[314])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[314] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[315] && lm_s1_io_out_tx_dat_flit[315])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[315] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[316] && lm_s1_io_out_tx_dat_flit[316])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[316] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[317] && lm_s1_io_out_tx_dat_flit[317])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[317] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[318] && lm_s1_io_out_tx_dat_flit[318])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[318] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[319] && lm_s1_io_out_tx_dat_flit[319])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[319] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[320] && lm_s1_io_out_tx_dat_flit[320])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[320] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[321] && lm_s1_io_out_tx_dat_flit[321])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[321] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[322] && lm_s1_io_out_tx_dat_flit[322])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[322] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[323] && lm_s1_io_out_tx_dat_flit[323])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[323] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[324] && lm_s1_io_out_tx_dat_flit[324])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[324] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[325] && lm_s1_io_out_tx_dat_flit[325])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[325] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[326] && lm_s1_io_out_tx_dat_flit[326])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[326] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[327] && lm_s1_io_out_tx_dat_flit[327])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[327] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[328] && lm_s1_io_out_tx_dat_flit[328])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[328] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[329] && lm_s1_io_out_tx_dat_flit[329])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[329] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[330] && lm_s1_io_out_tx_dat_flit[330])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[330] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[331] && lm_s1_io_out_tx_dat_flit[331])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[331] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[332] && lm_s1_io_out_tx_dat_flit[332])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[332] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[333] && lm_s1_io_out_tx_dat_flit[333])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[333] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[334] && lm_s1_io_out_tx_dat_flit[334])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[334] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[335] && lm_s1_io_out_tx_dat_flit[335])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[335] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[336] && lm_s1_io_out_tx_dat_flit[336])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[336] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[337] && lm_s1_io_out_tx_dat_flit[337])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[337] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[338] && lm_s1_io_out_tx_dat_flit[338])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[338] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[339] && lm_s1_io_out_tx_dat_flit[339])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[339] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[340] && lm_s1_io_out_tx_dat_flit[340])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[340] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[341] && lm_s1_io_out_tx_dat_flit[341])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[341] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[342] && lm_s1_io_out_tx_dat_flit[342])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[342] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[343] && lm_s1_io_out_tx_dat_flit[343])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[343] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[344] && lm_s1_io_out_tx_dat_flit[344])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[344] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[345] && lm_s1_io_out_tx_dat_flit[345])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[345] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[346] && lm_s1_io_out_tx_dat_flit[346])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[346] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[347] && lm_s1_io_out_tx_dat_flit[347])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[347] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[348] && lm_s1_io_out_tx_dat_flit[348])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[348] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[349] && lm_s1_io_out_tx_dat_flit[349])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[349] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[350] && lm_s1_io_out_tx_dat_flit[350])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[350] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[351] && lm_s1_io_out_tx_dat_flit[351])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[351] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[352] && lm_s1_io_out_tx_dat_flit[352])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[352] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[353] && lm_s1_io_out_tx_dat_flit[353])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[353] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[354] && lm_s1_io_out_tx_dat_flit[354])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[354] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[355] && lm_s1_io_out_tx_dat_flit[355])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[355] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[356] && lm_s1_io_out_tx_dat_flit[356])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[356] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[357] && lm_s1_io_out_tx_dat_flit[357])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[357] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[358] && lm_s1_io_out_tx_dat_flit[358])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[358] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[359] && lm_s1_io_out_tx_dat_flit[359])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[359] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[360] && lm_s1_io_out_tx_dat_flit[360])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[360] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[361] && lm_s1_io_out_tx_dat_flit[361])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[361] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[362] && lm_s1_io_out_tx_dat_flit[362])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[362] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[363] && lm_s1_io_out_tx_dat_flit[363])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[363] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[364] && lm_s1_io_out_tx_dat_flit[364])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[364] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[365] && lm_s1_io_out_tx_dat_flit[365])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[365] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[366] && lm_s1_io_out_tx_dat_flit[366])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[366] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[367] && lm_s1_io_out_tx_dat_flit[367])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[367] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[368] && lm_s1_io_out_tx_dat_flit[368])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[368] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[369] && lm_s1_io_out_tx_dat_flit[369])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[369] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[370] && lm_s1_io_out_tx_dat_flit[370])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[370] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[371] && lm_s1_io_out_tx_dat_flit[371])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[371] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[372] && lm_s1_io_out_tx_dat_flit[372])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[372] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[373] && lm_s1_io_out_tx_dat_flit[373])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[373] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[374] && lm_s1_io_out_tx_dat_flit[374])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[374] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[375] && lm_s1_io_out_tx_dat_flit[375])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[375] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[376] && lm_s1_io_out_tx_dat_flit[376])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[376] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[377] && lm_s1_io_out_tx_dat_flit[377])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[377] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[378] && lm_s1_io_out_tx_dat_flit[378])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[378] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[379] && lm_s1_io_out_tx_dat_flit[379])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[379] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[380] && lm_s1_io_out_tx_dat_flit[380])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[380] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[381] && lm_s1_io_out_tx_dat_flit[381])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[381] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[382] && lm_s1_io_out_tx_dat_flit[382])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[382] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[383] && lm_s1_io_out_tx_dat_flit[383])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[383] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[384] && lm_s1_io_out_tx_dat_flit[384])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[384] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[385] && lm_s1_io_out_tx_dat_flit[385])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[385] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[386] && lm_s1_io_out_tx_dat_flit[386])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[386] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[387] && lm_s1_io_out_tx_dat_flit[387])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[387] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[388] && lm_s1_io_out_tx_dat_flit[388])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[388] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[389] && lm_s1_io_out_tx_dat_flit[389])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[389] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[390] && lm_s1_io_out_tx_dat_flit[390])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[390] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[391] && lm_s1_io_out_tx_dat_flit[391])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[391] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[392] && lm_s1_io_out_tx_dat_flit[392])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[392] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[393] && lm_s1_io_out_tx_dat_flit[393])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[393] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[394] && lm_s1_io_out_tx_dat_flit[394])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[394] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[395] && lm_s1_io_out_tx_dat_flit[395])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[395] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[396] && lm_s1_io_out_tx_dat_flit[396])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[396] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[397] && lm_s1_io_out_tx_dat_flit[397])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[397] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[398] && lm_s1_io_out_tx_dat_flit[398])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[398] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[399] && lm_s1_io_out_tx_dat_flit[399])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[399] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[400] && lm_s1_io_out_tx_dat_flit[400])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[400] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[401] && lm_s1_io_out_tx_dat_flit[401])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[401] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[402] && lm_s1_io_out_tx_dat_flit[402])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[402] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[403] && lm_s1_io_out_tx_dat_flit[403])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[403] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[404] && lm_s1_io_out_tx_dat_flit[404])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[404] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[405] && lm_s1_io_out_tx_dat_flit[405])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[405] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[406] && lm_s1_io_out_tx_dat_flit[406])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[406] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[407] && lm_s1_io_out_tx_dat_flit[407])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[407] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[408] && lm_s1_io_out_tx_dat_flit[408])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[408] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[409] && lm_s1_io_out_tx_dat_flit[409])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[409] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[410] && lm_s1_io_out_tx_dat_flit[410])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[410] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[411] && lm_s1_io_out_tx_dat_flit[411])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[411] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[412] && lm_s1_io_out_tx_dat_flit[412])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[412] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[413] && lm_s1_io_out_tx_dat_flit[413])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[413] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[414] && lm_s1_io_out_tx_dat_flit[414])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[414] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[415] && lm_s1_io_out_tx_dat_flit[415])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[415] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[416] && lm_s1_io_out_tx_dat_flit[416])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[416] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[417] && lm_s1_io_out_tx_dat_flit[417])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[417] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[418] && lm_s1_io_out_tx_dat_flit[418])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[418] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[419] && lm_s1_io_out_tx_dat_flit[419])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[419] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[420] && lm_s1_io_out_tx_dat_flit[420])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[420] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_tx_dat_flit[421] && lm_s1_io_out_tx_dat_flit[421])) begin cov_fail++; $display("[COV] LinkMonitor.io_out_tx_dat_flit[421] 未见过 0 和 1"); end
    if (!(lm_s0_io_out_rx_linkactiveack && lm_s1_io_out_rx_linkactiveack)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_rx_linkactiveack 未见过 0 和 1"); end
    if (!(lm_s0_io_out_rx_rsp_lcrdv && lm_s1_io_out_rx_rsp_lcrdv)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_rx_rsp_lcrdv 未见过 0 和 1"); end
    if (!(lm_s0_io_out_rx_dat_lcrdv && lm_s1_io_out_rx_dat_lcrdv)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_rx_dat_lcrdv 未见过 0 和 1"); end
    if (!(lm_s0_io_out_rx_snp_lcrdv && lm_s1_io_out_rx_snp_lcrdv)) begin cov_fail++; $display("[COV] LinkMonitor.io_out_rx_snp_lcrdv 未见过 0 和 1"); end
    $display("[ARM] LinkMonitor armed_at=%0d", lm_armed_at);
    if (lm_armed_at < 0) begin cov_fail++; $display("[ARM] LinkMonitor 从未 arm"); end
    $display("[COV] LinkMonitor.tx_run = %0d", lm_cov_tx_run);
    if (lm_cov_tx_run < 100) begin cov_fail++; $display("[COV] LinkMonitor.tx_run < 100"); end
    $display("[COV] LinkMonitor.rx_run = %0d", lm_cov_rx_run);
    if (lm_cov_rx_run < 100) begin cov_fail++; $display("[COV] LinkMonitor.rx_run < 100"); end
    $display("[COV] LinkMonitor.rx_deact_wait = %0d", lm_cov_rx_deact_wait);
    if (lm_cov_rx_deact_wait < 100) begin cov_fail++; $display("[COV] LinkMonitor.rx_deact_wait < 100"); end
    $display("[COV] LinkMonitor.first_cycle_after_reset = %0d", lm_cov_first_cycle_after_reset);
    if (lm_cov_first_cycle_after_reset < 100) begin cov_fail++; $display("[COV] LinkMonitor.first_cycle_after_reset < 100"); end
    $display("[COV] LinkMonitor.retry_ack = %0d", lm_cov_retry_ack);
    if (lm_cov_retry_ack < 100) begin cov_fail++; $display("[COV] LinkMonitor.retry_ack < 100"); end
    $display("[COV] LinkMonitor.pcrd_grant = %0d", lm_cov_pcrd_grant);
    if (lm_cov_pcrd_grant < 100) begin cov_fail++; $display("[COV] LinkMonitor.pcrd_grant < 100"); end
    $display("[COV] LinkMonitor.no_allow_retry_req = %0d", lm_cov_no_allow_retry_req);
    if (lm_cov_no_allow_retry_req < 100) begin cov_fail++; $display("[COV] LinkMonitor.no_allow_retry_req < 100"); end
    $display("[COV] LinkMonitor.tx_dat_flit = %0d", lm_cov_tx_dat_flit);
    if (lm_cov_tx_dat_flit < 100) begin cov_fail++; $display("[COV] LinkMonitor.tx_dat_flit < 100"); end
    $display("[COV] LinkMonitor.rx_snp_out = %0d", lm_cov_rx_snp_out);
    if (lm_cov_rx_snp_out < 100) begin cov_fail++; $display("[COV] LinkMonitor.rx_snp_out < 100"); end
    $display("[COV] LinkMonitor.rx_dat_out = %0d", lm_cov_rx_dat_out);
    if (lm_cov_rx_dat_out < 100) begin cov_fail++; $display("[COV] LinkMonitor.rx_dat_out < 100"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule

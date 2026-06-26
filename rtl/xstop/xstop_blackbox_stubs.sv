// 自动生成:scripts/gen_xstop.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// 子模块类型黑盒 stub(空体,所有 output 驱 0)。
// 注:UT/FM 默认用 golden 子模块真定义(-f 闭包);本 stub 仅备快速 elaborate。

module CHILogger(
  input  io_up_txsactive,
  output  io_up_rxsactive,
  input  io_up_syscoreq,
  output  io_up_syscoack,
  input  io_up_tx_linkactivereq,
  output  io_up_tx_linkactiveack,
  input  io_up_tx_req_flitpend,
  input  io_up_tx_req_flitv,
  input  [161:0] io_up_tx_req_flit,
  output  io_up_tx_req_lcrdv,
  input  io_up_tx_rsp_flitpend,
  input  io_up_tx_rsp_flitv,
  input  [72:0] io_up_tx_rsp_flit,
  output  io_up_tx_rsp_lcrdv,
  input  io_up_tx_dat_flitpend,
  input  io_up_tx_dat_flitv,
  input  [421:0] io_up_tx_dat_flit,
  output  io_up_tx_dat_lcrdv,
  output  io_up_rx_linkactivereq,
  input  io_up_rx_linkactiveack,
  output  io_up_rx_rsp_flitpend,
  output  io_up_rx_rsp_flitv,
  output  [72:0] io_up_rx_rsp_flit,
  input  io_up_rx_rsp_lcrdv,
  output  io_up_rx_dat_flitpend,
  output  io_up_rx_dat_flitv,
  output  [421:0] io_up_rx_dat_flit,
  input  io_up_rx_dat_lcrdv,
  output  io_up_rx_snp_flitpend,
  output  io_up_rx_snp_flitv,
  output  [114:0] io_up_rx_snp_flit,
  input  io_up_rx_snp_lcrdv,
  output  io_down_txsactive,
  input  io_down_rxsactive,
  output  io_down_syscoreq,
  input  io_down_syscoack,
  output  io_down_tx_linkactivereq,
  input  io_down_tx_linkactiveack,
  output  io_down_tx_req_flitpend,
  output  io_down_tx_req_flitv,
  output  [161:0] io_down_tx_req_flit,
  input  io_down_tx_req_lcrdv,
  output  io_down_tx_rsp_flitpend,
  output  io_down_tx_rsp_flitv,
  output  [72:0] io_down_tx_rsp_flit,
  input  io_down_tx_rsp_lcrdv,
  output  io_down_tx_dat_flitpend,
  output  io_down_tx_dat_flitv,
  output  [421:0] io_down_tx_dat_flit,
  input  io_down_tx_dat_lcrdv,
  input  io_down_rx_linkactivereq,
  output  io_down_rx_linkactiveack,
  input  io_down_rx_rsp_flitpend,
  input  io_down_rx_rsp_flitv,
  input  [72:0] io_down_rx_rsp_flit,
  output  io_down_rx_rsp_lcrdv,
  input  io_down_rx_dat_flitpend,
  input  io_down_rx_dat_flitv,
  input  [421:0] io_down_rx_dat_flit,
  output  io_down_rx_dat_lcrdv,
  input  io_down_rx_snp_flitpend,
  input  io_down_rx_snp_flitv,
  input  [114:0] io_down_rx_snp_flit,
  output  io_down_rx_snp_lcrdv
);
  assign io_up_rxsactive = '0;
  assign io_up_syscoack = '0;
  assign io_up_tx_linkactiveack = '0;
  assign io_up_tx_req_lcrdv = '0;
  assign io_up_tx_rsp_lcrdv = '0;
  assign io_up_tx_dat_lcrdv = '0;
  assign io_up_rx_linkactivereq = '0;
  assign io_up_rx_rsp_flitpend = '0;
  assign io_up_rx_rsp_flitv = '0;
  assign io_up_rx_rsp_flit = '0;
  assign io_up_rx_dat_flitpend = '0;
  assign io_up_rx_dat_flitv = '0;
  assign io_up_rx_dat_flit = '0;
  assign io_up_rx_snp_flitpend = '0;
  assign io_up_rx_snp_flitv = '0;
  assign io_up_rx_snp_flit = '0;
  assign io_down_txsactive = '0;
  assign io_down_syscoreq = '0;
  assign io_down_tx_linkactivereq = '0;
  assign io_down_tx_req_flitpend = '0;
  assign io_down_tx_req_flitv = '0;
  assign io_down_tx_req_flit = '0;
  assign io_down_tx_rsp_flitpend = '0;
  assign io_down_tx_rsp_flitv = '0;
  assign io_down_tx_rsp_flit = '0;
  assign io_down_tx_dat_flitpend = '0;
  assign io_down_tx_dat_flitv = '0;
  assign io_down_tx_dat_flit = '0;
  assign io_down_rx_linkactiveack = '0;
  assign io_down_rx_rsp_lcrdv = '0;
  assign io_down_rx_dat_lcrdv = '0;
  assign io_down_rx_snp_lcrdv = '0;
endmodule

module FastArbiter_77(
  input  clock,
  input  reset,
  input  io_in_0_valid,
  input  [3:0] io_in_0_bits_qos,
  input  [10:0] io_in_0_bits_srcID,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_fwdNID,
  input  [11:0] io_in_0_bits_fwdTxnID,
  input  [4:0] io_in_0_bits_opcode,
  input  [44:0] io_in_0_bits_addr,
  input  io_in_0_bits_ns,
  input  io_in_0_bits_doNotGoToSD,
  input  io_in_0_bits_retToSrc,
  input  io_in_0_bits_traceTag,
  input  io_in_0_bits_mpam_perfMonGroup,
  input  [8:0] io_in_0_bits_mpam_partID,
  input  io_in_0_bits_mpam_mpamNS,
  input  io_in_1_valid,
  input  [3:0] io_in_1_bits_qos,
  input  [10:0] io_in_1_bits_srcID,
  input  [11:0] io_in_1_bits_txnID,
  input  [10:0] io_in_1_bits_fwdNID,
  input  [11:0] io_in_1_bits_fwdTxnID,
  input  [4:0] io_in_1_bits_opcode,
  input  [44:0] io_in_1_bits_addr,
  input  io_in_1_bits_ns,
  input  io_in_1_bits_doNotGoToSD,
  input  io_in_1_bits_retToSrc,
  input  io_in_1_bits_traceTag,
  input  io_in_1_bits_mpam_perfMonGroup,
  input  [8:0] io_in_1_bits_mpam_partID,
  input  io_in_1_bits_mpam_mpamNS,
  input  io_out_ready,
  output  io_out_valid,
  output  [3:0] io_out_bits_qos,
  output  [10:0] io_out_bits_srcID,
  output  [11:0] io_out_bits_txnID,
  output  [10:0] io_out_bits_fwdNID,
  output  [11:0] io_out_bits_fwdTxnID,
  output  [4:0] io_out_bits_opcode,
  output  [44:0] io_out_bits_addr,
  output  io_out_bits_ns,
  output  io_out_bits_doNotGoToSD,
  output  io_out_bits_retToSrc,
  output  io_out_bits_traceTag,
  output  io_out_bits_mpam_perfMonGroup,
  output  [8:0] io_out_bits_mpam_partID,
  output  io_out_bits_mpam_mpamNS,
  output  io_chosen
);
  assign io_out_valid = '0;
  assign io_out_bits_qos = '0;
  assign io_out_bits_srcID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_fwdNID = '0;
  assign io_out_bits_fwdTxnID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_addr = '0;
  assign io_out_bits_ns = '0;
  assign io_out_bits_doNotGoToSD = '0;
  assign io_out_bits_retToSrc = '0;
  assign io_out_bits_traceTag = '0;
  assign io_out_bits_mpam_perfMonGroup = '0;
  assign io_out_bits_mpam_partID = '0;
  assign io_out_bits_mpam_mpamNS = '0;
  assign io_chosen = '0;
endmodule

module FastArbiter_78(
  input  clock,
  input  reset,
  input  io_in_0_valid,
  input  [3:0] io_in_0_bits_qos,
  input  [10:0] io_in_0_bits_tgtID,
  input  [10:0] io_in_0_bits_srcID,
  input  [11:0] io_in_0_bits_txnID,
  input  [4:0] io_in_0_bits_opcode,
  input  [1:0] io_in_0_bits_respErr,
  input  [2:0] io_in_0_bits_resp,
  input  [2:0] io_in_0_bits_fwdState,
  input  [2:0] io_in_0_bits_cBusy,
  input  [11:0] io_in_0_bits_dbID,
  input  [3:0] io_in_0_bits_pCrdType,
  input  [1:0] io_in_0_bits_tagOp,
  input  io_in_0_bits_traceTag,
  input  io_in_1_valid,
  input  [3:0] io_in_1_bits_qos,
  input  [10:0] io_in_1_bits_tgtID,
  input  [10:0] io_in_1_bits_srcID,
  input  [11:0] io_in_1_bits_txnID,
  input  [4:0] io_in_1_bits_opcode,
  input  [1:0] io_in_1_bits_respErr,
  input  [2:0] io_in_1_bits_resp,
  input  [2:0] io_in_1_bits_fwdState,
  input  [2:0] io_in_1_bits_cBusy,
  input  [11:0] io_in_1_bits_dbID,
  input  [3:0] io_in_1_bits_pCrdType,
  input  [1:0] io_in_1_bits_tagOp,
  input  io_in_1_bits_traceTag,
  input  io_out_ready,
  output  io_out_valid,
  output  [3:0] io_out_bits_qos,
  output  [10:0] io_out_bits_tgtID,
  output  [10:0] io_out_bits_srcID,
  output  [11:0] io_out_bits_txnID,
  output  [4:0] io_out_bits_opcode,
  output  [1:0] io_out_bits_respErr,
  output  [2:0] io_out_bits_resp,
  output  [2:0] io_out_bits_fwdState,
  output  [2:0] io_out_bits_cBusy,
  output  [11:0] io_out_bits_dbID,
  output  [3:0] io_out_bits_pCrdType,
  output  [1:0] io_out_bits_tagOp,
  output  io_out_bits_traceTag,
  output  io_chosen
);
  assign io_out_valid = '0;
  assign io_out_bits_qos = '0;
  assign io_out_bits_tgtID = '0;
  assign io_out_bits_srcID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_respErr = '0;
  assign io_out_bits_resp = '0;
  assign io_out_bits_fwdState = '0;
  assign io_out_bits_cBusy = '0;
  assign io_out_bits_dbID = '0;
  assign io_out_bits_pCrdType = '0;
  assign io_out_bits_tagOp = '0;
  assign io_out_bits_traceTag = '0;
  assign io_chosen = '0;
endmodule

module FastArbiter_79(
  input  clock,
  input  reset,
  input  io_in_0_valid,
  input  [3:0] io_in_0_bits_qos,
  input  [10:0] io_in_0_bits_tgtID,
  input  [10:0] io_in_0_bits_srcID,
  input  [11:0] io_in_0_bits_txnID,
  input  [10:0] io_in_0_bits_homeNID,
  input  [3:0] io_in_0_bits_opcode,
  input  [1:0] io_in_0_bits_respErr,
  input  [2:0] io_in_0_bits_resp,
  input  [3:0] io_in_0_bits_dataSource,
  input  [2:0] io_in_0_bits_cBusy,
  input  [11:0] io_in_0_bits_dbID,
  input  [1:0] io_in_0_bits_ccID,
  input  [1:0] io_in_0_bits_dataID,
  input  [1:0] io_in_0_bits_tagOp,
  input  [7:0] io_in_0_bits_tag,
  input  [1:0] io_in_0_bits_tu,
  input  io_in_0_bits_traceTag,
  input  [3:0] io_in_0_bits_rsvdc,
  input  [31:0] io_in_0_bits_be,
  input  [255:0] io_in_0_bits_data,
  input  [31:0] io_in_0_bits_dataCheck,
  input  [3:0] io_in_0_bits_poison,
  input  io_in_1_valid,
  input  [3:0] io_in_1_bits_qos,
  input  [10:0] io_in_1_bits_tgtID,
  input  [10:0] io_in_1_bits_srcID,
  input  [11:0] io_in_1_bits_txnID,
  input  [10:0] io_in_1_bits_homeNID,
  input  [3:0] io_in_1_bits_opcode,
  input  [1:0] io_in_1_bits_respErr,
  input  [2:0] io_in_1_bits_resp,
  input  [3:0] io_in_1_bits_dataSource,
  input  [2:0] io_in_1_bits_cBusy,
  input  [11:0] io_in_1_bits_dbID,
  input  [1:0] io_in_1_bits_ccID,
  input  [1:0] io_in_1_bits_dataID,
  input  [1:0] io_in_1_bits_tagOp,
  input  [7:0] io_in_1_bits_tag,
  input  [1:0] io_in_1_bits_tu,
  input  io_in_1_bits_traceTag,
  input  [3:0] io_in_1_bits_rsvdc,
  input  [31:0] io_in_1_bits_be,
  input  [255:0] io_in_1_bits_data,
  input  [31:0] io_in_1_bits_dataCheck,
  input  [3:0] io_in_1_bits_poison,
  input  io_out_ready,
  output  io_out_valid,
  output  [3:0] io_out_bits_qos,
  output  [10:0] io_out_bits_tgtID,
  output  [10:0] io_out_bits_srcID,
  output  [11:0] io_out_bits_txnID,
  output  [10:0] io_out_bits_homeNID,
  output  [3:0] io_out_bits_opcode,
  output  [1:0] io_out_bits_respErr,
  output  [2:0] io_out_bits_resp,
  output  [3:0] io_out_bits_dataSource,
  output  [2:0] io_out_bits_cBusy,
  output  [11:0] io_out_bits_dbID,
  output  [1:0] io_out_bits_ccID,
  output  [1:0] io_out_bits_dataID,
  output  [1:0] io_out_bits_tagOp,
  output  [7:0] io_out_bits_tag,
  output  [1:0] io_out_bits_tu,
  output  io_out_bits_traceTag,
  output  [3:0] io_out_bits_rsvdc,
  output  [31:0] io_out_bits_be,
  output  [255:0] io_out_bits_data,
  output  [31:0] io_out_bits_dataCheck,
  output  [3:0] io_out_bits_poison,
  output  io_chosen
);
  assign io_out_valid = '0;
  assign io_out_bits_qos = '0;
  assign io_out_bits_tgtID = '0;
  assign io_out_bits_srcID = '0;
  assign io_out_bits_txnID = '0;
  assign io_out_bits_homeNID = '0;
  assign io_out_bits_opcode = '0;
  assign io_out_bits_respErr = '0;
  assign io_out_bits_resp = '0;
  assign io_out_bits_dataSource = '0;
  assign io_out_bits_cBusy = '0;
  assign io_out_bits_dbID = '0;
  assign io_out_bits_ccID = '0;
  assign io_out_bits_dataID = '0;
  assign io_out_bits_tagOp = '0;
  assign io_out_bits_tag = '0;
  assign io_out_bits_tu = '0;
  assign io_out_bits_traceTag = '0;
  assign io_out_bits_rsvdc = '0;
  assign io_out_bits_be = '0;
  assign io_out_bits_data = '0;
  assign io_out_bits_dataCheck = '0;
  assign io_out_bits_poison = '0;
  assign io_chosen = '0;
endmodule

module IntBuffer(
  input  clock,
  input  reset,
  input  auto_in_0,
  output  auto_out_0
);
  assign auto_out_0 = '0;
endmodule

module MemMisc(
  input  clock,
  input  reset,
  output  auto_debugModule_debug_dmOuter_dmOuter_int_out_0,
  input  auto_plic_int_in_0,
  output  auto_plic_int_out_1_0,
  output  auto_plic_int_out_0_0,
  output  auto_clint_int_out_0,
  output  auto_clint_int_out_1,
  output  auto_axi4xbar_in_1_aw_ready,
  input  auto_axi4xbar_in_1_aw_valid,
  input  [4:0] auto_axi4xbar_in_1_aw_bits_id,
  input  [48:0] auto_axi4xbar_in_1_aw_bits_addr,
  input  [7:0] auto_axi4xbar_in_1_aw_bits_len,
  input  [2:0] auto_axi4xbar_in_1_aw_bits_size,
  input  [1:0] auto_axi4xbar_in_1_aw_bits_burst,
  input  [3:0] auto_axi4xbar_in_1_aw_bits_cache,
  input  [3:0] auto_axi4xbar_in_1_aw_bits_qos,
  output  auto_axi4xbar_in_1_w_ready,
  input  auto_axi4xbar_in_1_w_valid,
  input  [255:0] auto_axi4xbar_in_1_w_bits_data,
  input  [31:0] auto_axi4xbar_in_1_w_bits_strb,
  input  auto_axi4xbar_in_1_w_bits_last,
  output  auto_axi4xbar_in_1_b_valid,
  output  [4:0] auto_axi4xbar_in_1_b_bits_id,
  output  auto_axi4xbar_in_1_ar_ready,
  input  auto_axi4xbar_in_1_ar_valid,
  input  [4:0] auto_axi4xbar_in_1_ar_bits_id,
  input  [48:0] auto_axi4xbar_in_1_ar_bits_addr,
  input  [7:0] auto_axi4xbar_in_1_ar_bits_len,
  input  [2:0] auto_axi4xbar_in_1_ar_bits_size,
  input  [1:0] auto_axi4xbar_in_1_ar_bits_burst,
  input  [3:0] auto_axi4xbar_in_1_ar_bits_cache,
  input  [3:0] auto_axi4xbar_in_1_ar_bits_qos,
  output  auto_axi4xbar_in_1_r_valid,
  output  [4:0] auto_axi4xbar_in_1_r_bits_id,
  output  [255:0] auto_axi4xbar_in_1_r_bits_data,
  output  auto_axi4xbar_in_1_r_bits_last,
  output  auto_axi4xbar_in_0_aw_ready,
  input  auto_axi4xbar_in_0_aw_valid,
  input  [5:0] auto_axi4xbar_in_0_aw_bits_id,
  input  [48:0] auto_axi4xbar_in_0_aw_bits_addr,
  input  [7:0] auto_axi4xbar_in_0_aw_bits_len,
  input  [2:0] auto_axi4xbar_in_0_aw_bits_size,
  input  [1:0] auto_axi4xbar_in_0_aw_bits_burst,
  input  [3:0] auto_axi4xbar_in_0_aw_bits_qos,
  output  auto_axi4xbar_in_0_w_ready,
  input  auto_axi4xbar_in_0_w_valid,
  input  [255:0] auto_axi4xbar_in_0_w_bits_data,
  input  [31:0] auto_axi4xbar_in_0_w_bits_strb,
  input  auto_axi4xbar_in_0_w_bits_last,
  output  auto_axi4xbar_in_0_b_valid,
  output  [5:0] auto_axi4xbar_in_0_b_bits_id,
  output  auto_axi4xbar_in_0_ar_ready,
  input  auto_axi4xbar_in_0_ar_valid,
  input  [5:0] auto_axi4xbar_in_0_ar_bits_id,
  input  [48:0] auto_axi4xbar_in_0_ar_bits_addr,
  input  [7:0] auto_axi4xbar_in_0_ar_bits_len,
  input  [2:0] auto_axi4xbar_in_0_ar_bits_size,
  input  [1:0] auto_axi4xbar_in_0_ar_bits_burst,
  input  [3:0] auto_axi4xbar_in_0_ar_bits_qos,
  output  auto_axi4xbar_in_0_r_valid,
  output  [5:0] auto_axi4xbar_in_0_r_bits_id,
  output  [255:0] auto_axi4xbar_in_0_r_bits_data,
  output  auto_axi4xbar_in_0_r_bits_last,
  input  memory_0_aw_ready,
  output  memory_0_aw_valid,
  output  [13:0] memory_0_aw_bits_id,
  output  [47:0] memory_0_aw_bits_addr,
  output  [7:0] memory_0_aw_bits_len,
  output  [2:0] memory_0_aw_bits_size,
  output  [1:0] memory_0_aw_bits_burst,
  output  memory_0_aw_bits_lock,
  output  [3:0] memory_0_aw_bits_cache,
  output  [2:0] memory_0_aw_bits_prot,
  output  [3:0] memory_0_aw_bits_qos,
  input  memory_0_w_ready,
  output  memory_0_w_valid,
  output  [255:0] memory_0_w_bits_data,
  output  [31:0] memory_0_w_bits_strb,
  output  memory_0_w_bits_last,
  output  memory_0_b_ready,
  input  memory_0_b_valid,
  input  [13:0] memory_0_b_bits_id,
  input  [1:0] memory_0_b_bits_resp,
  input  memory_0_ar_ready,
  output  memory_0_ar_valid,
  output  [13:0] memory_0_ar_bits_id,
  output  [47:0] memory_0_ar_bits_addr,
  output  [7:0] memory_0_ar_bits_len,
  output  [2:0] memory_0_ar_bits_size,
  output  [1:0] memory_0_ar_bits_burst,
  output  memory_0_ar_bits_lock,
  output  [3:0] memory_0_ar_bits_cache,
  output  [2:0] memory_0_ar_bits_prot,
  output  [3:0] memory_0_ar_bits_qos,
  output  memory_0_r_ready,
  input  memory_0_r_valid,
  input  [13:0] memory_0_r_bits_id,
  input  [255:0] memory_0_r_bits_data,
  input  [1:0] memory_0_r_bits_resp,
  input  memory_0_r_bits_last,
  input  peripheral_0_aw_ready,
  output  peripheral_0_aw_valid,
  output  [1:0] peripheral_0_aw_bits_id,
  output  [30:0] peripheral_0_aw_bits_addr,
  output  [7:0] peripheral_0_aw_bits_len,
  output  [2:0] peripheral_0_aw_bits_size,
  output  [1:0] peripheral_0_aw_bits_burst,
  output  peripheral_0_aw_bits_lock,
  output  [3:0] peripheral_0_aw_bits_cache,
  output  [2:0] peripheral_0_aw_bits_prot,
  output  [3:0] peripheral_0_aw_bits_qos,
  input  peripheral_0_w_ready,
  output  peripheral_0_w_valid,
  output  [63:0] peripheral_0_w_bits_data,
  output  [7:0] peripheral_0_w_bits_strb,
  output  peripheral_0_w_bits_last,
  output  peripheral_0_b_ready,
  input  peripheral_0_b_valid,
  input  [1:0] peripheral_0_b_bits_id,
  input  [1:0] peripheral_0_b_bits_resp,
  input  peripheral_0_ar_ready,
  output  peripheral_0_ar_valid,
  output  [1:0] peripheral_0_ar_bits_id,
  output  [30:0] peripheral_0_ar_bits_addr,
  output  [7:0] peripheral_0_ar_bits_len,
  output  [2:0] peripheral_0_ar_bits_size,
  output  [1:0] peripheral_0_ar_bits_burst,
  output  peripheral_0_ar_bits_lock,
  output  [3:0] peripheral_0_ar_bits_cache,
  output  [2:0] peripheral_0_ar_bits_prot,
  output  [3:0] peripheral_0_ar_bits_qos,
  output  peripheral_0_r_ready,
  input  peripheral_0_r_valid,
  input  [1:0] peripheral_0_r_bits_id,
  input  [63:0] peripheral_0_r_bits_data,
  input  [1:0] peripheral_0_r_bits_resp,
  input  peripheral_0_r_bits_last,
  output  debug_module_io_resetCtrl_hartResetReq_0,
  input  debug_module_io_resetCtrl_hartIsInReset_0,
  input  debug_module_io_debugIO_clock,
  input  debug_module_io_debugIO_reset,
  input  debug_module_io_debugIO_systemjtag_jtag_TCK,
  input  debug_module_io_debugIO_systemjtag_jtag_TMS,
  input  debug_module_io_debugIO_systemjtag_jtag_TDI,
  output  debug_module_io_debugIO_systemjtag_jtag_TDO_data,
  output  debug_module_io_debugIO_systemjtag_jtag_TDO_driven,
  input  debug_module_io_debugIO_systemjtag_reset,
  input  [10:0] debug_module_io_debugIO_systemjtag_mfr_id,
  input  [15:0] debug_module_io_debugIO_systemjtag_part_number,
  input  [3:0] debug_module_io_debugIO_systemjtag_version,
  output  debug_module_io_debugIO_ndreset,
  output  debug_module_io_debugIO_dmactive,
  input  debug_module_io_debugIO_dmactiveAck,
  input  debug_module_io_clock,
  input  debug_module_io_reset,
  input  [63:0] ext_intrs,
  input  rtc_clock,
  input  pll0_lock,
  output  [31:0] pll0_ctrl_0,
  output  [31:0] pll0_ctrl_1,
  output  [31:0] pll0_ctrl_2,
  output  [31:0] pll0_ctrl_3,
  output  [31:0] pll0_ctrl_4,
  output  [31:0] pll0_ctrl_5,
  input  [47:0] cacheable_check_req_0_bits_addr,
  input  [47:0] cacheable_check_req_1_bits_addr,
  output  cacheable_check_resp_0_ld,
  output  cacheable_check_resp_0_st,
  output  cacheable_check_resp_0_instr,
  output  cacheable_check_resp_0_mmio,
  output  cacheable_check_resp_0_atomic,
  output  cacheable_check_resp_1_ld,
  output  cacheable_check_resp_1_st,
  output  cacheable_check_resp_1_instr,
  output  cacheable_check_resp_1_mmio,
  output  cacheable_check_resp_1_atomic,
  output  clintTime_valid,
  output  [63:0] clintTime_bits
);
  assign auto_debugModule_debug_dmOuter_dmOuter_int_out_0 = '0;
  assign auto_plic_int_out_1_0 = '0;
  assign auto_plic_int_out_0_0 = '0;
  assign auto_clint_int_out_0 = '0;
  assign auto_clint_int_out_1 = '0;
  assign auto_axi4xbar_in_1_aw_ready = '0;
  assign auto_axi4xbar_in_1_w_ready = '0;
  assign auto_axi4xbar_in_1_b_valid = '0;
  assign auto_axi4xbar_in_1_b_bits_id = '0;
  assign auto_axi4xbar_in_1_ar_ready = '0;
  assign auto_axi4xbar_in_1_r_valid = '0;
  assign auto_axi4xbar_in_1_r_bits_id = '0;
  assign auto_axi4xbar_in_1_r_bits_data = '0;
  assign auto_axi4xbar_in_1_r_bits_last = '0;
  assign auto_axi4xbar_in_0_aw_ready = '0;
  assign auto_axi4xbar_in_0_w_ready = '0;
  assign auto_axi4xbar_in_0_b_valid = '0;
  assign auto_axi4xbar_in_0_b_bits_id = '0;
  assign auto_axi4xbar_in_0_ar_ready = '0;
  assign auto_axi4xbar_in_0_r_valid = '0;
  assign auto_axi4xbar_in_0_r_bits_id = '0;
  assign auto_axi4xbar_in_0_r_bits_data = '0;
  assign auto_axi4xbar_in_0_r_bits_last = '0;
  assign memory_0_aw_valid = '0;
  assign memory_0_aw_bits_id = '0;
  assign memory_0_aw_bits_addr = '0;
  assign memory_0_aw_bits_len = '0;
  assign memory_0_aw_bits_size = '0;
  assign memory_0_aw_bits_burst = '0;
  assign memory_0_aw_bits_lock = '0;
  assign memory_0_aw_bits_cache = '0;
  assign memory_0_aw_bits_prot = '0;
  assign memory_0_aw_bits_qos = '0;
  assign memory_0_w_valid = '0;
  assign memory_0_w_bits_data = '0;
  assign memory_0_w_bits_strb = '0;
  assign memory_0_w_bits_last = '0;
  assign memory_0_b_ready = '0;
  assign memory_0_ar_valid = '0;
  assign memory_0_ar_bits_id = '0;
  assign memory_0_ar_bits_addr = '0;
  assign memory_0_ar_bits_len = '0;
  assign memory_0_ar_bits_size = '0;
  assign memory_0_ar_bits_burst = '0;
  assign memory_0_ar_bits_lock = '0;
  assign memory_0_ar_bits_cache = '0;
  assign memory_0_ar_bits_prot = '0;
  assign memory_0_ar_bits_qos = '0;
  assign memory_0_r_ready = '0;
  assign peripheral_0_aw_valid = '0;
  assign peripheral_0_aw_bits_id = '0;
  assign peripheral_0_aw_bits_addr = '0;
  assign peripheral_0_aw_bits_len = '0;
  assign peripheral_0_aw_bits_size = '0;
  assign peripheral_0_aw_bits_burst = '0;
  assign peripheral_0_aw_bits_lock = '0;
  assign peripheral_0_aw_bits_cache = '0;
  assign peripheral_0_aw_bits_prot = '0;
  assign peripheral_0_aw_bits_qos = '0;
  assign peripheral_0_w_valid = '0;
  assign peripheral_0_w_bits_data = '0;
  assign peripheral_0_w_bits_strb = '0;
  assign peripheral_0_w_bits_last = '0;
  assign peripheral_0_b_ready = '0;
  assign peripheral_0_ar_valid = '0;
  assign peripheral_0_ar_bits_id = '0;
  assign peripheral_0_ar_bits_addr = '0;
  assign peripheral_0_ar_bits_len = '0;
  assign peripheral_0_ar_bits_size = '0;
  assign peripheral_0_ar_bits_burst = '0;
  assign peripheral_0_ar_bits_lock = '0;
  assign peripheral_0_ar_bits_cache = '0;
  assign peripheral_0_ar_bits_prot = '0;
  assign peripheral_0_ar_bits_qos = '0;
  assign peripheral_0_r_ready = '0;
  assign debug_module_io_resetCtrl_hartResetReq_0 = '0;
  assign debug_module_io_debugIO_systemjtag_jtag_TDO_data = '0;
  assign debug_module_io_debugIO_systemjtag_jtag_TDO_driven = '0;
  assign debug_module_io_debugIO_ndreset = '0;
  assign debug_module_io_debugIO_dmactive = '0;
  assign pll0_ctrl_0 = '0;
  assign pll0_ctrl_1 = '0;
  assign pll0_ctrl_2 = '0;
  assign pll0_ctrl_3 = '0;
  assign pll0_ctrl_4 = '0;
  assign pll0_ctrl_5 = '0;
  assign cacheable_check_resp_0_ld = '0;
  assign cacheable_check_resp_0_st = '0;
  assign cacheable_check_resp_0_instr = '0;
  assign cacheable_check_resp_0_mmio = '0;
  assign cacheable_check_resp_0_atomic = '0;
  assign cacheable_check_resp_1_ld = '0;
  assign cacheable_check_resp_1_st = '0;
  assign cacheable_check_resp_1_instr = '0;
  assign cacheable_check_resp_1_mmio = '0;
  assign cacheable_check_resp_1_atomic = '0;
  assign clintTime_valid = '0;
  assign clintTime_bits = '0;
endmodule

module OpenLLC(
  input  clock,
  input  reset,
  input  io_rn_0_txsactive,
  output  io_rn_0_rxsactive,
  input  io_rn_0_syscoreq,
  output  io_rn_0_syscoack,
  input  io_rn_0_tx_linkactivereq,
  output  io_rn_0_tx_linkactiveack,
  input  io_rn_0_tx_req_flitpend,
  input  io_rn_0_tx_req_flitv,
  input  [161:0] io_rn_0_tx_req_flit,
  output  io_rn_0_tx_req_lcrdv,
  input  io_rn_0_tx_rsp_flitpend,
  input  io_rn_0_tx_rsp_flitv,
  input  [72:0] io_rn_0_tx_rsp_flit,
  output  io_rn_0_tx_rsp_lcrdv,
  input  io_rn_0_tx_dat_flitpend,
  input  io_rn_0_tx_dat_flitv,
  input  [421:0] io_rn_0_tx_dat_flit,
  output  io_rn_0_tx_dat_lcrdv,
  output  io_rn_0_rx_linkactivereq,
  input  io_rn_0_rx_linkactiveack,
  output  io_rn_0_rx_rsp_flitpend,
  output  io_rn_0_rx_rsp_flitv,
  output  [72:0] io_rn_0_rx_rsp_flit,
  input  io_rn_0_rx_rsp_lcrdv,
  output  io_rn_0_rx_dat_flitpend,
  output  io_rn_0_rx_dat_flitv,
  output  [421:0] io_rn_0_rx_dat_flit,
  input  io_rn_0_rx_dat_lcrdv,
  output  io_rn_0_rx_snp_flitpend,
  output  io_rn_0_rx_snp_flitv,
  output  [114:0] io_rn_0_rx_snp_flit,
  input  io_rn_0_rx_snp_lcrdv,
  output  io_sn_txsactive,
  input  io_sn_rxsactive,
  output  io_sn_tx_linkactivereq,
  input  io_sn_tx_linkactiveack,
  output  io_sn_tx_req_flitpend,
  output  io_sn_tx_req_flitv,
  output  [161:0] io_sn_tx_req_flit,
  input  io_sn_tx_req_lcrdv,
  output  io_sn_tx_dat_flitpend,
  output  io_sn_tx_dat_flitv,
  output  [421:0] io_sn_tx_dat_flit,
  input  io_sn_tx_dat_lcrdv,
  input  io_sn_rx_linkactivereq,
  output  io_sn_rx_linkactiveack,
  input  io_sn_rx_rsp_flitpend,
  input  io_sn_rx_rsp_flitv,
  input  [72:0] io_sn_rx_rsp_flit,
  output  io_sn_rx_rsp_lcrdv,
  input  io_sn_rx_dat_flitpend,
  input  io_sn_rx_dat_flitv,
  input  [421:0] io_sn_rx_dat_flit,
  output  io_sn_rx_dat_lcrdv,
  input  io_debugTopDown_robHeadPaddr_0_valid,
  input  [47:0] io_debugTopDown_robHeadPaddr_0_bits,
  output  io_debugTopDown_addrMatch_0,
  output  io_l3Miss
);
  assign io_rn_0_rxsactive = '0;
  assign io_rn_0_syscoack = '0;
  assign io_rn_0_tx_linkactiveack = '0;
  assign io_rn_0_tx_req_lcrdv = '0;
  assign io_rn_0_tx_rsp_lcrdv = '0;
  assign io_rn_0_tx_dat_lcrdv = '0;
  assign io_rn_0_rx_linkactivereq = '0;
  assign io_rn_0_rx_rsp_flitpend = '0;
  assign io_rn_0_rx_rsp_flitv = '0;
  assign io_rn_0_rx_rsp_flit = '0;
  assign io_rn_0_rx_dat_flitpend = '0;
  assign io_rn_0_rx_dat_flitv = '0;
  assign io_rn_0_rx_dat_flit = '0;
  assign io_rn_0_rx_snp_flitpend = '0;
  assign io_rn_0_rx_snp_flitv = '0;
  assign io_rn_0_rx_snp_flit = '0;
  assign io_sn_txsactive = '0;
  assign io_sn_tx_linkactivereq = '0;
  assign io_sn_tx_req_flitpend = '0;
  assign io_sn_tx_req_flitv = '0;
  assign io_sn_tx_req_flit = '0;
  assign io_sn_tx_dat_flitpend = '0;
  assign io_sn_tx_dat_flitv = '0;
  assign io_sn_tx_dat_flit = '0;
  assign io_sn_rx_linkactiveack = '0;
  assign io_sn_rx_rsp_lcrdv = '0;
  assign io_sn_rx_dat_lcrdv = '0;
  assign io_debugTopDown_addrMatch_0 = '0;
  assign io_l3Miss = '0;
endmodule

module OpenNCB(
  input  clock,
  input  reset,
  input  auto_axi4_out_aw_ready,
  output  auto_axi4_out_aw_valid,
  output  [5:0] auto_axi4_out_aw_bits_id,
  output  [48:0] auto_axi4_out_aw_bits_addr,
  output  [7:0] auto_axi4_out_aw_bits_len,
  output  [2:0] auto_axi4_out_aw_bits_size,
  output  [1:0] auto_axi4_out_aw_bits_burst,
  output  [3:0] auto_axi4_out_aw_bits_qos,
  input  auto_axi4_out_w_ready,
  output  auto_axi4_out_w_valid,
  output  [255:0] auto_axi4_out_w_bits_data,
  output  [31:0] auto_axi4_out_w_bits_strb,
  output  auto_axi4_out_w_bits_last,
  input  auto_axi4_out_b_valid,
  input  [5:0] auto_axi4_out_b_bits_id,
  input  auto_axi4_out_ar_ready,
  output  auto_axi4_out_ar_valid,
  output  [5:0] auto_axi4_out_ar_bits_id,
  output  [48:0] auto_axi4_out_ar_bits_addr,
  output  [7:0] auto_axi4_out_ar_bits_len,
  output  [2:0] auto_axi4_out_ar_bits_size,
  output  [1:0] auto_axi4_out_ar_bits_burst,
  output  [3:0] auto_axi4_out_ar_bits_qos,
  input  auto_axi4_out_r_valid,
  input  [5:0] auto_axi4_out_r_bits_id,
  input  [255:0] auto_axi4_out_r_bits_data,
  input  auto_axi4_out_r_bits_last,
  input  io_chi_txsactive,
  output  io_chi_rxsactive,
  input  io_chi_tx_linkactivereq,
  output  io_chi_tx_linkactiveack,
  input  io_chi_tx_req_flitpend,
  input  io_chi_tx_req_flitv,
  input  [161:0] io_chi_tx_req_flit,
  output  io_chi_tx_req_lcrdv,
  input  io_chi_tx_dat_flitpend,
  input  io_chi_tx_dat_flitv,
  input  [421:0] io_chi_tx_dat_flit,
  output  io_chi_tx_dat_lcrdv,
  output  io_chi_rx_linkactivereq,
  input  io_chi_rx_linkactiveack,
  output  io_chi_rx_rsp_flitpend,
  output  io_chi_rx_rsp_flitv,
  output  [72:0] io_chi_rx_rsp_flit,
  input  io_chi_rx_rsp_lcrdv,
  output  io_chi_rx_dat_flitpend,
  output  io_chi_rx_dat_flitv,
  output  [421:0] io_chi_rx_dat_flit,
  input  io_chi_rx_dat_lcrdv
);
  assign auto_axi4_out_aw_valid = '0;
  assign auto_axi4_out_aw_bits_id = '0;
  assign auto_axi4_out_aw_bits_addr = '0;
  assign auto_axi4_out_aw_bits_len = '0;
  assign auto_axi4_out_aw_bits_size = '0;
  assign auto_axi4_out_aw_bits_burst = '0;
  assign auto_axi4_out_aw_bits_qos = '0;
  assign auto_axi4_out_w_valid = '0;
  assign auto_axi4_out_w_bits_data = '0;
  assign auto_axi4_out_w_bits_strb = '0;
  assign auto_axi4_out_w_bits_last = '0;
  assign auto_axi4_out_ar_valid = '0;
  assign auto_axi4_out_ar_bits_id = '0;
  assign auto_axi4_out_ar_bits_addr = '0;
  assign auto_axi4_out_ar_bits_len = '0;
  assign auto_axi4_out_ar_bits_size = '0;
  assign auto_axi4_out_ar_bits_burst = '0;
  assign auto_axi4_out_ar_bits_qos = '0;
  assign io_chi_rxsactive = '0;
  assign io_chi_tx_linkactiveack = '0;
  assign io_chi_tx_req_lcrdv = '0;
  assign io_chi_tx_dat_lcrdv = '0;
  assign io_chi_rx_linkactivereq = '0;
  assign io_chi_rx_rsp_flitpend = '0;
  assign io_chi_rx_rsp_flitv = '0;
  assign io_chi_rx_rsp_flit = '0;
  assign io_chi_rx_dat_flitpend = '0;
  assign io_chi_rx_dat_flitv = '0;
  assign io_chi_rx_dat_flit = '0;
endmodule

module OpenNCB_1(
  input  clock,
  input  reset,
  input  auto_axi4_out_aw_ready,
  output  auto_axi4_out_aw_valid,
  output  [4:0] auto_axi4_out_aw_bits_id,
  output  [48:0] auto_axi4_out_aw_bits_addr,
  output  [7:0] auto_axi4_out_aw_bits_len,
  output  [2:0] auto_axi4_out_aw_bits_size,
  output  [1:0] auto_axi4_out_aw_bits_burst,
  output  [3:0] auto_axi4_out_aw_bits_cache,
  output  [3:0] auto_axi4_out_aw_bits_qos,
  input  auto_axi4_out_w_ready,
  output  auto_axi4_out_w_valid,
  output  [255:0] auto_axi4_out_w_bits_data,
  output  [31:0] auto_axi4_out_w_bits_strb,
  output  auto_axi4_out_w_bits_last,
  input  auto_axi4_out_b_valid,
  input  [4:0] auto_axi4_out_b_bits_id,
  input  auto_axi4_out_ar_ready,
  output  auto_axi4_out_ar_valid,
  output  [4:0] auto_axi4_out_ar_bits_id,
  output  [48:0] auto_axi4_out_ar_bits_addr,
  output  [7:0] auto_axi4_out_ar_bits_len,
  output  [2:0] auto_axi4_out_ar_bits_size,
  output  [1:0] auto_axi4_out_ar_bits_burst,
  output  [3:0] auto_axi4_out_ar_bits_cache,
  output  [3:0] auto_axi4_out_ar_bits_qos,
  input  auto_axi4_out_r_valid,
  input  [4:0] auto_axi4_out_r_bits_id,
  input  [255:0] auto_axi4_out_r_bits_data,
  input  auto_axi4_out_r_bits_last,
  input  io_chi_txsactive,
  output  io_chi_rxsactive,
  input  io_chi_tx_linkactivereq,
  output  io_chi_tx_linkactiveack,
  input  io_chi_tx_req_flitpend,
  input  io_chi_tx_req_flitv,
  input  [161:0] io_chi_tx_req_flit,
  output  io_chi_tx_req_lcrdv,
  input  io_chi_tx_dat_flitpend,
  input  io_chi_tx_dat_flitv,
  input  [421:0] io_chi_tx_dat_flit,
  output  io_chi_tx_dat_lcrdv,
  output  io_chi_rx_linkactivereq,
  input  io_chi_rx_linkactiveack,
  output  io_chi_rx_rsp_flitpend,
  output  io_chi_rx_rsp_flitv,
  output  [72:0] io_chi_rx_rsp_flit,
  input  io_chi_rx_rsp_lcrdv,
  output  io_chi_rx_dat_flitpend,
  output  io_chi_rx_dat_flitv,
  output  [421:0] io_chi_rx_dat_flit,
  input  io_chi_rx_dat_lcrdv
);
  assign auto_axi4_out_aw_valid = '0;
  assign auto_axi4_out_aw_bits_id = '0;
  assign auto_axi4_out_aw_bits_addr = '0;
  assign auto_axi4_out_aw_bits_len = '0;
  assign auto_axi4_out_aw_bits_size = '0;
  assign auto_axi4_out_aw_bits_burst = '0;
  assign auto_axi4_out_aw_bits_cache = '0;
  assign auto_axi4_out_aw_bits_qos = '0;
  assign auto_axi4_out_w_valid = '0;
  assign auto_axi4_out_w_bits_data = '0;
  assign auto_axi4_out_w_bits_strb = '0;
  assign auto_axi4_out_w_bits_last = '0;
  assign auto_axi4_out_ar_valid = '0;
  assign auto_axi4_out_ar_bits_id = '0;
  assign auto_axi4_out_ar_bits_addr = '0;
  assign auto_axi4_out_ar_bits_len = '0;
  assign auto_axi4_out_ar_bits_size = '0;
  assign auto_axi4_out_ar_bits_burst = '0;
  assign auto_axi4_out_ar_bits_cache = '0;
  assign auto_axi4_out_ar_bits_qos = '0;
  assign io_chi_rxsactive = '0;
  assign io_chi_tx_linkactiveack = '0;
  assign io_chi_tx_req_lcrdv = '0;
  assign io_chi_tx_dat_lcrdv = '0;
  assign io_chi_rx_linkactivereq = '0;
  assign io_chi_rx_rsp_flitpend = '0;
  assign io_chi_rx_rsp_flitv = '0;
  assign io_chi_rx_rsp_flit = '0;
  assign io_chi_rx_dat_flitpend = '0;
  assign io_chi_rx_dat_flitv = '0;
  assign io_chi_rx_dat_flit = '0;
endmodule

module ReceiverLinkMonitor(
  input  clock,
  input  reset,
  input  io_in_txsactive,
  output  io_in_rxsactive,
  input  io_in_syscoreq,
  output  io_in_syscoack,
  input  io_in_tx_linkactivereq,
  output  io_in_tx_linkactiveack,
  input  io_in_tx_req_flitpend,
  input  io_in_tx_req_flitv,
  input  [161:0] io_in_tx_req_flit,
  output  io_in_tx_req_lcrdv,
  input  io_in_tx_rsp_flitpend,
  input  io_in_tx_rsp_flitv,
  input  [72:0] io_in_tx_rsp_flit,
  output  io_in_tx_rsp_lcrdv,
  input  io_in_tx_dat_flitpend,
  input  io_in_tx_dat_flitv,
  input  [421:0] io_in_tx_dat_flit,
  output  io_in_tx_dat_lcrdv,
  output  io_in_rx_linkactivereq,
  input  io_in_rx_linkactiveack,
  output  io_in_rx_rsp_flitpend,
  output  io_in_rx_rsp_flitv,
  output  [72:0] io_in_rx_rsp_flit,
  input  io_in_rx_rsp_lcrdv,
  output  io_in_rx_dat_flitpend,
  output  io_in_rx_dat_flitv,
  output  [421:0] io_in_rx_dat_flit,
  input  io_in_rx_dat_lcrdv,
  output  io_in_rx_snp_flitpend,
  output  io_in_rx_snp_flitv,
  output  [114:0] io_in_rx_snp_flit,
  input  io_in_rx_snp_lcrdv,
  input  io_out_tx_req_ready,
  output  io_out_tx_req_valid,
  output  [3:0] io_out_tx_req_bits_qos,
  output  [10:0] io_out_tx_req_bits_srcID,
  output  [11:0] io_out_tx_req_bits_txnID,
  output  [10:0] io_out_tx_req_bits_returnNID,
  output  io_out_tx_req_bits_stashNIDValid,
  output  [11:0] io_out_tx_req_bits_returnTxnID,
  output  [6:0] io_out_tx_req_bits_opcode,
  output  [2:0] io_out_tx_req_bits_size,
  output  [47:0] io_out_tx_req_bits_addr,
  output  io_out_tx_req_bits_ns,
  output  io_out_tx_req_bits_likelyshared,
  output  io_out_tx_req_bits_allowRetry,
  output  [1:0] io_out_tx_req_bits_order,
  output  [3:0] io_out_tx_req_bits_pCrdType,
  output  io_out_tx_req_bits_memAttr_allocate,
  output  io_out_tx_req_bits_memAttr_cacheable,
  output  io_out_tx_req_bits_memAttr_device,
  output  io_out_tx_req_bits_memAttr_ewa,
  output  io_out_tx_req_bits_snpAttr,
  output  [7:0] io_out_tx_req_bits_lpIDWithPadding,
  output  io_out_tx_req_bits_snoopMe,
  output  io_out_tx_req_bits_expCompAck,
  output  [1:0] io_out_tx_req_bits_tagOp,
  output  io_out_tx_req_bits_traceTag,
  output  io_out_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_out_tx_req_bits_mpam_partID,
  output  io_out_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_out_tx_req_bits_rsvdc,
  input  io_out_tx_rsp_ready,
  output  io_out_tx_rsp_valid,
  output  [3:0] io_out_tx_rsp_bits_qos,
  output  [10:0] io_out_tx_rsp_bits_tgtID,
  output  [10:0] io_out_tx_rsp_bits_srcID,
  output  [11:0] io_out_tx_rsp_bits_txnID,
  output  [4:0] io_out_tx_rsp_bits_opcode,
  output  [1:0] io_out_tx_rsp_bits_respErr,
  output  [2:0] io_out_tx_rsp_bits_resp,
  output  [2:0] io_out_tx_rsp_bits_fwdState,
  output  [2:0] io_out_tx_rsp_bits_cBusy,
  output  [11:0] io_out_tx_rsp_bits_dbID,
  output  [3:0] io_out_tx_rsp_bits_pCrdType,
  output  [1:0] io_out_tx_rsp_bits_tagOp,
  output  io_out_tx_rsp_bits_traceTag,
  input  io_out_tx_dat_ready,
  output  io_out_tx_dat_valid,
  output  [3:0] io_out_tx_dat_bits_qos,
  output  [10:0] io_out_tx_dat_bits_tgtID,
  output  [10:0] io_out_tx_dat_bits_srcID,
  output  [11:0] io_out_tx_dat_bits_txnID,
  output  [10:0] io_out_tx_dat_bits_homeNID,
  output  [3:0] io_out_tx_dat_bits_opcode,
  output  [1:0] io_out_tx_dat_bits_respErr,
  output  [2:0] io_out_tx_dat_bits_resp,
  output  [3:0] io_out_tx_dat_bits_dataSource,
  output  [2:0] io_out_tx_dat_bits_cBusy,
  output  [11:0] io_out_tx_dat_bits_dbID,
  output  [1:0] io_out_tx_dat_bits_ccID,
  output  [1:0] io_out_tx_dat_bits_dataID,
  output  [1:0] io_out_tx_dat_bits_tagOp,
  output  [7:0] io_out_tx_dat_bits_tag,
  output  [1:0] io_out_tx_dat_bits_tu,
  output  io_out_tx_dat_bits_traceTag,
  output  [3:0] io_out_tx_dat_bits_rsvdc,
  output  [31:0] io_out_tx_dat_bits_be,
  output  [255:0] io_out_tx_dat_bits_data,
  output  [31:0] io_out_tx_dat_bits_dataCheck,
  output  [3:0] io_out_tx_dat_bits_poison,
  output  io_out_rx_rsp_ready,
  input  io_out_rx_rsp_valid,
  input  [3:0] io_out_rx_rsp_bits_qos,
  input  [10:0] io_out_rx_rsp_bits_tgtID,
  input  [10:0] io_out_rx_rsp_bits_srcID,
  input  [11:0] io_out_rx_rsp_bits_txnID,
  input  [4:0] io_out_rx_rsp_bits_opcode,
  input  [1:0] io_out_rx_rsp_bits_respErr,
  input  [2:0] io_out_rx_rsp_bits_resp,
  input  [2:0] io_out_rx_rsp_bits_fwdState,
  input  [2:0] io_out_rx_rsp_bits_cBusy,
  input  [11:0] io_out_rx_rsp_bits_dbID,
  input  [3:0] io_out_rx_rsp_bits_pCrdType,
  input  [1:0] io_out_rx_rsp_bits_tagOp,
  input  io_out_rx_rsp_bits_traceTag,
  output  io_out_rx_dat_ready,
  input  io_out_rx_dat_valid,
  input  [3:0] io_out_rx_dat_bits_qos,
  input  [10:0] io_out_rx_dat_bits_tgtID,
  input  [10:0] io_out_rx_dat_bits_srcID,
  input  [11:0] io_out_rx_dat_bits_txnID,
  input  [10:0] io_out_rx_dat_bits_homeNID,
  input  [3:0] io_out_rx_dat_bits_opcode,
  input  [1:0] io_out_rx_dat_bits_respErr,
  input  [2:0] io_out_rx_dat_bits_resp,
  input  [3:0] io_out_rx_dat_bits_dataSource,
  input  [2:0] io_out_rx_dat_bits_cBusy,
  input  [11:0] io_out_rx_dat_bits_dbID,
  input  [1:0] io_out_rx_dat_bits_ccID,
  input  [1:0] io_out_rx_dat_bits_dataID,
  input  [1:0] io_out_rx_dat_bits_tagOp,
  input  [7:0] io_out_rx_dat_bits_tag,
  input  [1:0] io_out_rx_dat_bits_tu,
  input  io_out_rx_dat_bits_traceTag,
  input  [3:0] io_out_rx_dat_bits_rsvdc,
  input  [31:0] io_out_rx_dat_bits_be,
  input  [255:0] io_out_rx_dat_bits_data,
  input  [31:0] io_out_rx_dat_bits_dataCheck,
  input  [3:0] io_out_rx_dat_bits_poison,
  output  io_out_rx_snp_ready,
  input  io_out_rx_snp_valid,
  input  [3:0] io_out_rx_snp_bits_qos,
  input  [10:0] io_out_rx_snp_bits_srcID,
  input  [11:0] io_out_rx_snp_bits_txnID,
  input  [10:0] io_out_rx_snp_bits_fwdNID,
  input  [11:0] io_out_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_rx_snp_bits_opcode,
  input  [44:0] io_out_rx_snp_bits_addr,
  input  io_out_rx_snp_bits_ns,
  input  io_out_rx_snp_bits_doNotGoToSD,
  input  io_out_rx_snp_bits_retToSrc,
  input  io_out_rx_snp_bits_traceTag,
  input  io_out_rx_snp_bits_mpam_perfMonGroup,
  input  [8:0] io_out_rx_snp_bits_mpam_partID,
  input  io_out_rx_snp_bits_mpam_mpamNS
);
  assign io_in_rxsactive = '0;
  assign io_in_syscoack = '0;
  assign io_in_tx_linkactiveack = '0;
  assign io_in_tx_req_lcrdv = '0;
  assign io_in_tx_rsp_lcrdv = '0;
  assign io_in_tx_dat_lcrdv = '0;
  assign io_in_rx_linkactivereq = '0;
  assign io_in_rx_rsp_flitpend = '0;
  assign io_in_rx_rsp_flitv = '0;
  assign io_in_rx_rsp_flit = '0;
  assign io_in_rx_dat_flitpend = '0;
  assign io_in_rx_dat_flitv = '0;
  assign io_in_rx_dat_flit = '0;
  assign io_in_rx_snp_flitpend = '0;
  assign io_in_rx_snp_flitv = '0;
  assign io_in_rx_snp_flit = '0;
  assign io_out_tx_req_valid = '0;
  assign io_out_tx_req_bits_qos = '0;
  assign io_out_tx_req_bits_srcID = '0;
  assign io_out_tx_req_bits_txnID = '0;
  assign io_out_tx_req_bits_returnNID = '0;
  assign io_out_tx_req_bits_stashNIDValid = '0;
  assign io_out_tx_req_bits_returnTxnID = '0;
  assign io_out_tx_req_bits_opcode = '0;
  assign io_out_tx_req_bits_size = '0;
  assign io_out_tx_req_bits_addr = '0;
  assign io_out_tx_req_bits_ns = '0;
  assign io_out_tx_req_bits_likelyshared = '0;
  assign io_out_tx_req_bits_allowRetry = '0;
  assign io_out_tx_req_bits_order = '0;
  assign io_out_tx_req_bits_pCrdType = '0;
  assign io_out_tx_req_bits_memAttr_allocate = '0;
  assign io_out_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_tx_req_bits_memAttr_device = '0;
  assign io_out_tx_req_bits_memAttr_ewa = '0;
  assign io_out_tx_req_bits_snpAttr = '0;
  assign io_out_tx_req_bits_lpIDWithPadding = '0;
  assign io_out_tx_req_bits_snoopMe = '0;
  assign io_out_tx_req_bits_expCompAck = '0;
  assign io_out_tx_req_bits_tagOp = '0;
  assign io_out_tx_req_bits_traceTag = '0;
  assign io_out_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_out_tx_req_bits_mpam_partID = '0;
  assign io_out_tx_req_bits_mpam_mpamNS = '0;
  assign io_out_tx_req_bits_rsvdc = '0;
  assign io_out_tx_rsp_valid = '0;
  assign io_out_tx_rsp_bits_qos = '0;
  assign io_out_tx_rsp_bits_tgtID = '0;
  assign io_out_tx_rsp_bits_srcID = '0;
  assign io_out_tx_rsp_bits_txnID = '0;
  assign io_out_tx_rsp_bits_opcode = '0;
  assign io_out_tx_rsp_bits_respErr = '0;
  assign io_out_tx_rsp_bits_resp = '0;
  assign io_out_tx_rsp_bits_fwdState = '0;
  assign io_out_tx_rsp_bits_cBusy = '0;
  assign io_out_tx_rsp_bits_dbID = '0;
  assign io_out_tx_rsp_bits_pCrdType = '0;
  assign io_out_tx_rsp_bits_tagOp = '0;
  assign io_out_tx_rsp_bits_traceTag = '0;
  assign io_out_tx_dat_valid = '0;
  assign io_out_tx_dat_bits_qos = '0;
  assign io_out_tx_dat_bits_tgtID = '0;
  assign io_out_tx_dat_bits_srcID = '0;
  assign io_out_tx_dat_bits_txnID = '0;
  assign io_out_tx_dat_bits_homeNID = '0;
  assign io_out_tx_dat_bits_opcode = '0;
  assign io_out_tx_dat_bits_respErr = '0;
  assign io_out_tx_dat_bits_resp = '0;
  assign io_out_tx_dat_bits_dataSource = '0;
  assign io_out_tx_dat_bits_cBusy = '0;
  assign io_out_tx_dat_bits_dbID = '0;
  assign io_out_tx_dat_bits_ccID = '0;
  assign io_out_tx_dat_bits_dataID = '0;
  assign io_out_tx_dat_bits_tagOp = '0;
  assign io_out_tx_dat_bits_tag = '0;
  assign io_out_tx_dat_bits_tu = '0;
  assign io_out_tx_dat_bits_traceTag = '0;
  assign io_out_tx_dat_bits_rsvdc = '0;
  assign io_out_tx_dat_bits_be = '0;
  assign io_out_tx_dat_bits_data = '0;
  assign io_out_tx_dat_bits_dataCheck = '0;
  assign io_out_tx_dat_bits_poison = '0;
  assign io_out_rx_rsp_ready = '0;
  assign io_out_rx_dat_ready = '0;
  assign io_out_rx_snp_ready = '0;
endmodule

module ResetGen(
  input  clock,
  input  reset,
  output  o_reset
);
  assign o_reset = '0;
endmodule

module TransmitterLinkMonitor(
  input  clock,
  input  reset,
  output  io_in_tx_req_ready,
  input  io_in_tx_req_valid,
  input  [3:0] io_in_tx_req_bits_qos,
  input  [10:0] io_in_tx_req_bits_tgtID,
  input  [10:0] io_in_tx_req_bits_srcID,
  input  [11:0] io_in_tx_req_bits_txnID,
  input  [10:0] io_in_tx_req_bits_returnNID,
  input  io_in_tx_req_bits_stashNIDValid,
  input  [11:0] io_in_tx_req_bits_returnTxnID,
  input  [6:0] io_in_tx_req_bits_opcode,
  input  [2:0] io_in_tx_req_bits_size,
  input  [47:0] io_in_tx_req_bits_addr,
  input  io_in_tx_req_bits_ns,
  input  io_in_tx_req_bits_likelyshared,
  input  io_in_tx_req_bits_allowRetry,
  input  [1:0] io_in_tx_req_bits_order,
  input  [3:0] io_in_tx_req_bits_pCrdType,
  input  io_in_tx_req_bits_memAttr_allocate,
  input  io_in_tx_req_bits_memAttr_cacheable,
  input  io_in_tx_req_bits_memAttr_device,
  input  io_in_tx_req_bits_memAttr_ewa,
  input  io_in_tx_req_bits_snpAttr,
  input  [7:0] io_in_tx_req_bits_lpIDWithPadding,
  input  io_in_tx_req_bits_snoopMe,
  input  io_in_tx_req_bits_expCompAck,
  input  [1:0] io_in_tx_req_bits_tagOp,
  input  io_in_tx_req_bits_traceTag,
  input  io_in_tx_req_bits_mpam_perfMonGroup,
  input  [8:0] io_in_tx_req_bits_mpam_partID,
  input  io_in_tx_req_bits_mpam_mpamNS,
  input  [3:0] io_in_tx_req_bits_rsvdc,
  output  io_in_tx_rsp_ready,
  input  io_in_tx_rsp_valid,
  input  [3:0] io_in_tx_rsp_bits_qos,
  input  [10:0] io_in_tx_rsp_bits_tgtID,
  input  [10:0] io_in_tx_rsp_bits_srcID,
  input  [11:0] io_in_tx_rsp_bits_txnID,
  input  [4:0] io_in_tx_rsp_bits_opcode,
  input  [1:0] io_in_tx_rsp_bits_respErr,
  input  [2:0] io_in_tx_rsp_bits_resp,
  input  [2:0] io_in_tx_rsp_bits_fwdState,
  input  [2:0] io_in_tx_rsp_bits_cBusy,
  input  [11:0] io_in_tx_rsp_bits_dbID,
  input  [3:0] io_in_tx_rsp_bits_pCrdType,
  input  [1:0] io_in_tx_rsp_bits_tagOp,
  input  io_in_tx_rsp_bits_traceTag,
  output  io_in_tx_dat_ready,
  input  io_in_tx_dat_valid,
  input  [3:0] io_in_tx_dat_bits_qos,
  input  [10:0] io_in_tx_dat_bits_tgtID,
  input  [10:0] io_in_tx_dat_bits_srcID,
  input  [11:0] io_in_tx_dat_bits_txnID,
  input  [10:0] io_in_tx_dat_bits_homeNID,
  input  [3:0] io_in_tx_dat_bits_opcode,
  input  [1:0] io_in_tx_dat_bits_respErr,
  input  [2:0] io_in_tx_dat_bits_resp,
  input  [3:0] io_in_tx_dat_bits_dataSource,
  input  [2:0] io_in_tx_dat_bits_cBusy,
  input  [11:0] io_in_tx_dat_bits_dbID,
  input  [1:0] io_in_tx_dat_bits_ccID,
  input  [1:0] io_in_tx_dat_bits_dataID,
  input  [1:0] io_in_tx_dat_bits_tagOp,
  input  [7:0] io_in_tx_dat_bits_tag,
  input  [1:0] io_in_tx_dat_bits_tu,
  input  io_in_tx_dat_bits_traceTag,
  input  [3:0] io_in_tx_dat_bits_rsvdc,
  input  [31:0] io_in_tx_dat_bits_be,
  input  [255:0] io_in_tx_dat_bits_data,
  input  [31:0] io_in_tx_dat_bits_dataCheck,
  input  [3:0] io_in_tx_dat_bits_poison,
  input  io_in_rx_rsp_ready,
  output  io_in_rx_rsp_valid,
  output  [3:0] io_in_rx_rsp_bits_qos,
  output  [10:0] io_in_rx_rsp_bits_tgtID,
  output  [10:0] io_in_rx_rsp_bits_srcID,
  output  [11:0] io_in_rx_rsp_bits_txnID,
  output  [4:0] io_in_rx_rsp_bits_opcode,
  output  [1:0] io_in_rx_rsp_bits_respErr,
  output  [2:0] io_in_rx_rsp_bits_resp,
  output  [2:0] io_in_rx_rsp_bits_fwdState,
  output  [2:0] io_in_rx_rsp_bits_cBusy,
  output  [11:0] io_in_rx_rsp_bits_dbID,
  output  [3:0] io_in_rx_rsp_bits_pCrdType,
  output  [1:0] io_in_rx_rsp_bits_tagOp,
  output  io_in_rx_rsp_bits_traceTag,
  input  io_in_rx_dat_ready,
  output  io_in_rx_dat_valid,
  output  [3:0] io_in_rx_dat_bits_qos,
  output  [10:0] io_in_rx_dat_bits_tgtID,
  output  [10:0] io_in_rx_dat_bits_srcID,
  output  [11:0] io_in_rx_dat_bits_txnID,
  output  [10:0] io_in_rx_dat_bits_homeNID,
  output  [3:0] io_in_rx_dat_bits_opcode,
  output  [1:0] io_in_rx_dat_bits_respErr,
  output  [2:0] io_in_rx_dat_bits_resp,
  output  [3:0] io_in_rx_dat_bits_dataSource,
  output  [2:0] io_in_rx_dat_bits_cBusy,
  output  [11:0] io_in_rx_dat_bits_dbID,
  output  [1:0] io_in_rx_dat_bits_ccID,
  output  [1:0] io_in_rx_dat_bits_dataID,
  output  [1:0] io_in_rx_dat_bits_tagOp,
  output  [7:0] io_in_rx_dat_bits_tag,
  output  [1:0] io_in_rx_dat_bits_tu,
  output  io_in_rx_dat_bits_traceTag,
  output  [3:0] io_in_rx_dat_bits_rsvdc,
  output  [31:0] io_in_rx_dat_bits_be,
  output  [255:0] io_in_rx_dat_bits_data,
  output  [31:0] io_in_rx_dat_bits_dataCheck,
  output  [3:0] io_in_rx_dat_bits_poison,
  input  io_in_rx_snp_ready,
  output  io_in_rx_snp_valid,
  output  [3:0] io_in_rx_snp_bits_qos,
  output  [10:0] io_in_rx_snp_bits_srcID,
  output  [11:0] io_in_rx_snp_bits_txnID,
  output  [10:0] io_in_rx_snp_bits_fwdNID,
  output  [11:0] io_in_rx_snp_bits_fwdTxnID,
  output  [4:0] io_in_rx_snp_bits_opcode,
  output  [44:0] io_in_rx_snp_bits_addr,
  output  io_in_rx_snp_bits_ns,
  output  io_in_rx_snp_bits_doNotGoToSD,
  output  io_in_rx_snp_bits_retToSrc,
  output  io_in_rx_snp_bits_traceTag,
  output  io_in_rx_snp_bits_mpam_perfMonGroup,
  output  [8:0] io_in_rx_snp_bits_mpam_partID,
  output  io_in_rx_snp_bits_mpam_mpamNS,
  output  io_out_txsactive,
  input  io_out_rxsactive,
  output  io_out_syscoreq,
  input  io_out_syscoack,
  output  io_out_tx_linkactivereq,
  input  io_out_tx_linkactiveack,
  output  io_out_tx_req_flitpend,
  output  io_out_tx_req_flitv,
  output  [161:0] io_out_tx_req_flit,
  input  io_out_tx_req_lcrdv,
  output  io_out_tx_rsp_flitpend,
  output  io_out_tx_rsp_flitv,
  output  [72:0] io_out_tx_rsp_flit,
  input  io_out_tx_rsp_lcrdv,
  output  io_out_tx_dat_flitpend,
  output  io_out_tx_dat_flitv,
  output  [421:0] io_out_tx_dat_flit,
  input  io_out_tx_dat_lcrdv,
  input  io_out_rx_linkactivereq,
  output  io_out_rx_linkactiveack,
  input  io_out_rx_rsp_flitpend,
  input  io_out_rx_rsp_flitv,
  input  [72:0] io_out_rx_rsp_flit,
  output  io_out_rx_rsp_lcrdv,
  input  io_out_rx_dat_flitpend,
  input  io_out_rx_dat_flitv,
  input  [421:0] io_out_rx_dat_flit,
  output  io_out_rx_dat_lcrdv,
  input  io_out_rx_snp_flitpend,
  input  io_out_rx_snp_flitv,
  input  [114:0] io_out_rx_snp_flit,
  output  io_out_rx_snp_lcrdv
);
  assign io_in_tx_req_ready = '0;
  assign io_in_tx_rsp_ready = '0;
  assign io_in_tx_dat_ready = '0;
  assign io_in_rx_rsp_valid = '0;
  assign io_in_rx_rsp_bits_qos = '0;
  assign io_in_rx_rsp_bits_tgtID = '0;
  assign io_in_rx_rsp_bits_srcID = '0;
  assign io_in_rx_rsp_bits_txnID = '0;
  assign io_in_rx_rsp_bits_opcode = '0;
  assign io_in_rx_rsp_bits_respErr = '0;
  assign io_in_rx_rsp_bits_resp = '0;
  assign io_in_rx_rsp_bits_fwdState = '0;
  assign io_in_rx_rsp_bits_cBusy = '0;
  assign io_in_rx_rsp_bits_dbID = '0;
  assign io_in_rx_rsp_bits_pCrdType = '0;
  assign io_in_rx_rsp_bits_tagOp = '0;
  assign io_in_rx_rsp_bits_traceTag = '0;
  assign io_in_rx_dat_valid = '0;
  assign io_in_rx_dat_bits_qos = '0;
  assign io_in_rx_dat_bits_tgtID = '0;
  assign io_in_rx_dat_bits_srcID = '0;
  assign io_in_rx_dat_bits_txnID = '0;
  assign io_in_rx_dat_bits_homeNID = '0;
  assign io_in_rx_dat_bits_opcode = '0;
  assign io_in_rx_dat_bits_respErr = '0;
  assign io_in_rx_dat_bits_resp = '0;
  assign io_in_rx_dat_bits_dataSource = '0;
  assign io_in_rx_dat_bits_cBusy = '0;
  assign io_in_rx_dat_bits_dbID = '0;
  assign io_in_rx_dat_bits_ccID = '0;
  assign io_in_rx_dat_bits_dataID = '0;
  assign io_in_rx_dat_bits_tagOp = '0;
  assign io_in_rx_dat_bits_tag = '0;
  assign io_in_rx_dat_bits_tu = '0;
  assign io_in_rx_dat_bits_traceTag = '0;
  assign io_in_rx_dat_bits_rsvdc = '0;
  assign io_in_rx_dat_bits_be = '0;
  assign io_in_rx_dat_bits_data = '0;
  assign io_in_rx_dat_bits_dataCheck = '0;
  assign io_in_rx_dat_bits_poison = '0;
  assign io_in_rx_snp_valid = '0;
  assign io_in_rx_snp_bits_qos = '0;
  assign io_in_rx_snp_bits_srcID = '0;
  assign io_in_rx_snp_bits_txnID = '0;
  assign io_in_rx_snp_bits_fwdNID = '0;
  assign io_in_rx_snp_bits_fwdTxnID = '0;
  assign io_in_rx_snp_bits_opcode = '0;
  assign io_in_rx_snp_bits_addr = '0;
  assign io_in_rx_snp_bits_ns = '0;
  assign io_in_rx_snp_bits_doNotGoToSD = '0;
  assign io_in_rx_snp_bits_retToSrc = '0;
  assign io_in_rx_snp_bits_traceTag = '0;
  assign io_in_rx_snp_bits_mpam_perfMonGroup = '0;
  assign io_in_rx_snp_bits_mpam_partID = '0;
  assign io_in_rx_snp_bits_mpam_mpamNS = '0;
  assign io_out_txsactive = '0;
  assign io_out_syscoreq = '0;
  assign io_out_tx_linkactivereq = '0;
  assign io_out_tx_req_flitpend = '0;
  assign io_out_tx_req_flitv = '0;
  assign io_out_tx_req_flit = '0;
  assign io_out_tx_rsp_flitpend = '0;
  assign io_out_tx_rsp_flitv = '0;
  assign io_out_tx_rsp_flit = '0;
  assign io_out_tx_dat_flitpend = '0;
  assign io_out_tx_dat_flitv = '0;
  assign io_out_tx_dat_flit = '0;
  assign io_out_rx_linkactiveack = '0;
  assign io_out_rx_rsp_lcrdv = '0;
  assign io_out_rx_dat_lcrdv = '0;
  assign io_out_rx_snp_lcrdv = '0;
endmodule

module XSTile(
  input  clock,
  input  reset,
  output  auto_l2top_inner_beu_int_out_0,
  input  auto_l2top_inner_nmi_int_in_0,
  input  auto_l2top_inner_nmi_int_in_1,
  input  auto_l2top_inner_plic_int_in_1_0,
  input  auto_l2top_inner_plic_int_in_0_0,
  input  auto_l2top_inner_debug_int_in_0,
  input  auto_l2top_inner_clint_int_in_0,
  input  auto_l2top_inner_clint_int_in_1,
  input  [5:0] io_hartId,
  input  io_msiInfo_valid,
  input  [10:0] io_msiInfo_bits,
  input  [47:0] io_reset_vector,
  output  io_cpu_halt,
  output  io_cpu_crtical_error,
  output  io_hartIsInReset,
  input  io_traceCoreInterface_fromEncoder_enable,
  input  io_traceCoreInterface_fromEncoder_stall,
  output  [2:0] io_traceCoreInterface_toEncoder_priv,
  output  [63:0] io_traceCoreInterface_toEncoder_trap_cause,
  output  [49:0] io_traceCoreInterface_toEncoder_trap_tval,
  output  [49:0] io_traceCoreInterface_toEncoder_groups_0_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toEncoder_groups_0_bits_itype,
  output  [6:0] io_traceCoreInterface_toEncoder_groups_0_bits_iretire,
  output  io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize,
  output  [49:0] io_traceCoreInterface_toEncoder_groups_1_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toEncoder_groups_1_bits_itype,
  output  [6:0] io_traceCoreInterface_toEncoder_groups_1_bits_iretire,
  output  io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize,
  output  [49:0] io_traceCoreInterface_toEncoder_groups_2_bits_iaddr,
  output  [3:0] io_traceCoreInterface_toEncoder_groups_2_bits_itype,
  output  [6:0] io_traceCoreInterface_toEncoder_groups_2_bits_iretire,
  output  io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize,
  output  io_debugTopDown_robHeadPaddr_valid,
  output  [47:0] io_debugTopDown_robHeadPaddr_bits,
  input  io_debugTopDown_l3MissMatch,
  input  io_l3Miss,
  output  io_chi_txsactive,
  input  io_chi_rxsactive,
  output  io_chi_syscoreq,
  input  io_chi_syscoack,
  output  io_chi_tx_linkactivereq,
  input  io_chi_tx_linkactiveack,
  output  io_chi_tx_req_flitpend,
  output  io_chi_tx_req_flitv,
  output  [161:0] io_chi_tx_req_flit,
  input  io_chi_tx_req_lcrdv,
  output  io_chi_tx_rsp_flitpend,
  output  io_chi_tx_rsp_flitv,
  output  [72:0] io_chi_tx_rsp_flit,
  input  io_chi_tx_rsp_lcrdv,
  output  io_chi_tx_dat_flitpend,
  output  io_chi_tx_dat_flitv,
  output  [421:0] io_chi_tx_dat_flit,
  input  io_chi_tx_dat_lcrdv,
  input  io_chi_rx_linkactivereq,
  output  io_chi_rx_linkactiveack,
  input  io_chi_rx_rsp_flitpend,
  input  io_chi_rx_rsp_flitv,
  input  [72:0] io_chi_rx_rsp_flit,
  output  io_chi_rx_rsp_lcrdv,
  input  io_chi_rx_dat_flitpend,
  input  io_chi_rx_dat_flitv,
  input  [421:0] io_chi_rx_dat_flit,
  output  io_chi_rx_dat_lcrdv,
  input  io_chi_rx_snp_flitpend,
  input  io_chi_rx_snp_flitv,
  input  [114:0] io_chi_rx_snp_flit,
  output  io_chi_rx_snp_lcrdv,
  input  [10:0] io_nodeID,
  input  io_clintTime_valid,
  input  [63:0] io_clintTime_bits,
  input  io_dft_ram_hold,
  input  io_dft_ram_bypass,
  input  io_dft_ram_bp_clken,
  input  io_dft_ram_aux_clk,
  input  io_dft_ram_aux_ckbp,
  input  io_dft_ram_mcp_hold,
  input  [63:0] io_dft_ram_ctl,
  input  io_dft_cgen,
  input  io_dft_reset_lgc_rst_n,
  input  io_dft_reset_mode,
  input  io_dft_reset_scan_mode
);
  assign auto_l2top_inner_beu_int_out_0 = '0;
  assign io_cpu_halt = '0;
  assign io_cpu_crtical_error = '0;
  assign io_hartIsInReset = '0;
  assign io_traceCoreInterface_toEncoder_priv = '0;
  assign io_traceCoreInterface_toEncoder_trap_cause = '0;
  assign io_traceCoreInterface_toEncoder_trap_tval = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_iaddr = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_itype = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_iretire = '0;
  assign io_traceCoreInterface_toEncoder_groups_0_bits_ilastsize = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_bits_iaddr = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_bits_itype = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_bits_iretire = '0;
  assign io_traceCoreInterface_toEncoder_groups_1_bits_ilastsize = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_bits_iaddr = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_bits_itype = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_bits_iretire = '0;
  assign io_traceCoreInterface_toEncoder_groups_2_bits_ilastsize = '0;
  assign io_debugTopDown_robHeadPaddr_valid = '0;
  assign io_debugTopDown_robHeadPaddr_bits = '0;
  assign io_chi_txsactive = '0;
  assign io_chi_syscoreq = '0;
  assign io_chi_tx_linkactivereq = '0;
  assign io_chi_tx_req_flitpend = '0;
  assign io_chi_tx_req_flitv = '0;
  assign io_chi_tx_req_flit = '0;
  assign io_chi_tx_rsp_flitpend = '0;
  assign io_chi_tx_rsp_flitv = '0;
  assign io_chi_tx_rsp_flit = '0;
  assign io_chi_tx_dat_flitpend = '0;
  assign io_chi_tx_dat_flitv = '0;
  assign io_chi_tx_dat_flit = '0;
  assign io_chi_rx_linkactiveack = '0;
  assign io_chi_rx_rsp_lcrdv = '0;
  assign io_chi_rx_dat_lcrdv = '0;
  assign io_chi_rx_snp_lcrdv = '0;
endmodule


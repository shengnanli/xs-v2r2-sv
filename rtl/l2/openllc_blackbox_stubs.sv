// 自动生成:scripts/gen_openllc.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// 8 子模块类型黑盒 stub(空体,所有 output 驱 0)。
// 注:UT/FM 默认用 golden 子模块真定义(-f 闭包);本 stub 仅备快速 elaborate。

module MMIODiverger(
  input  clock,
  input  reset,
  output  io_in_0_tx_req_ready,
  input  io_in_0_tx_req_valid,
  input  [3:0] io_in_0_tx_req_bits_qos,
  input  [10:0] io_in_0_tx_req_bits_tgtID,
  input  [10:0] io_in_0_tx_req_bits_srcID,
  input  [11:0] io_in_0_tx_req_bits_txnID,
  input  [10:0] io_in_0_tx_req_bits_returnNID,
  input  io_in_0_tx_req_bits_stashNIDValid,
  input  [11:0] io_in_0_tx_req_bits_returnTxnID,
  input  [6:0] io_in_0_tx_req_bits_opcode,
  input  [2:0] io_in_0_tx_req_bits_size,
  input  [47:0] io_in_0_tx_req_bits_addr,
  input  io_in_0_tx_req_bits_ns,
  input  io_in_0_tx_req_bits_likelyshared,
  input  io_in_0_tx_req_bits_allowRetry,
  input  [1:0] io_in_0_tx_req_bits_order,
  input  [3:0] io_in_0_tx_req_bits_pCrdType,
  input  io_in_0_tx_req_bits_memAttr_allocate,
  input  io_in_0_tx_req_bits_memAttr_cacheable,
  input  io_in_0_tx_req_bits_memAttr_device,
  input  io_in_0_tx_req_bits_memAttr_ewa,
  input  io_in_0_tx_req_bits_snpAttr,
  input  [7:0] io_in_0_tx_req_bits_lpIDWithPadding,
  input  io_in_0_tx_req_bits_snoopMe,
  input  io_in_0_tx_req_bits_expCompAck,
  input  [1:0] io_in_0_tx_req_bits_tagOp,
  input  io_in_0_tx_req_bits_traceTag,
  input  io_in_0_tx_req_bits_mpam_perfMonGroup,
  input  [8:0] io_in_0_tx_req_bits_mpam_partID,
  input  io_in_0_tx_req_bits_mpam_mpamNS,
  input  [3:0] io_in_0_tx_req_bits_rsvdc,
  output  io_in_0_tx_rsp_ready,
  input  io_in_0_tx_rsp_valid,
  input  [10:0] io_in_0_tx_rsp_bits_srcID,
  input  [11:0] io_in_0_tx_rsp_bits_txnID,
  input  [4:0] io_in_0_tx_rsp_bits_opcode,
  input  [11:0] io_in_0_tx_rsp_bits_dbID,
  output  io_in_0_tx_dat_ready,
  input  io_in_0_tx_dat_valid,
  input  [3:0] io_in_0_tx_dat_bits_qos,
  input  [10:0] io_in_0_tx_dat_bits_tgtID,
  input  [10:0] io_in_0_tx_dat_bits_srcID,
  input  [11:0] io_in_0_tx_dat_bits_txnID,
  input  [10:0] io_in_0_tx_dat_bits_homeNID,
  input  [3:0] io_in_0_tx_dat_bits_opcode,
  input  [1:0] io_in_0_tx_dat_bits_respErr,
  input  [2:0] io_in_0_tx_dat_bits_resp,
  input  [3:0] io_in_0_tx_dat_bits_dataSource,
  input  [2:0] io_in_0_tx_dat_bits_cBusy,
  input  [11:0] io_in_0_tx_dat_bits_dbID,
  input  [1:0] io_in_0_tx_dat_bits_ccID,
  input  [1:0] io_in_0_tx_dat_bits_dataID,
  input  [1:0] io_in_0_tx_dat_bits_tagOp,
  input  [7:0] io_in_0_tx_dat_bits_tag,
  input  [1:0] io_in_0_tx_dat_bits_tu,
  input  io_in_0_tx_dat_bits_traceTag,
  input  [3:0] io_in_0_tx_dat_bits_rsvdc,
  input  [31:0] io_in_0_tx_dat_bits_be,
  input  [255:0] io_in_0_tx_dat_bits_data,
  input  [31:0] io_in_0_tx_dat_bits_dataCheck,
  input  [3:0] io_in_0_tx_dat_bits_poison,
  input  io_in_0_rx_rsp_ready,
  output  io_in_0_rx_rsp_valid,
  output  [3:0] io_in_0_rx_rsp_bits_qos,
  output  [11:0] io_in_0_rx_rsp_bits_txnID,
  output  [4:0] io_in_0_rx_rsp_bits_opcode,
  output  [1:0] io_in_0_rx_rsp_bits_respErr,
  output  [2:0] io_in_0_rx_rsp_bits_resp,
  output  [2:0] io_in_0_rx_rsp_bits_fwdState,
  output  [2:0] io_in_0_rx_rsp_bits_cBusy,
  output  [11:0] io_in_0_rx_rsp_bits_dbID,
  output  [3:0] io_in_0_rx_rsp_bits_pCrdType,
  output  [1:0] io_in_0_rx_rsp_bits_tagOp,
  output  io_in_0_rx_rsp_bits_traceTag,
  input  io_in_0_rx_dat_ready,
  output  io_in_0_rx_dat_valid,
  output  [3:0] io_in_0_rx_dat_bits_qos,
  output  [11:0] io_in_0_rx_dat_bits_txnID,
  output  [10:0] io_in_0_rx_dat_bits_homeNID,
  output  [3:0] io_in_0_rx_dat_bits_opcode,
  output  [1:0] io_in_0_rx_dat_bits_respErr,
  output  [2:0] io_in_0_rx_dat_bits_resp,
  output  [3:0] io_in_0_rx_dat_bits_dataSource,
  output  [2:0] io_in_0_rx_dat_bits_cBusy,
  output  [11:0] io_in_0_rx_dat_bits_dbID,
  output  [1:0] io_in_0_rx_dat_bits_ccID,
  output  [1:0] io_in_0_rx_dat_bits_dataID,
  output  [1:0] io_in_0_rx_dat_bits_tagOp,
  output  [7:0] io_in_0_rx_dat_bits_tag,
  output  [1:0] io_in_0_rx_dat_bits_tu,
  output  io_in_0_rx_dat_bits_traceTag,
  output  [3:0] io_in_0_rx_dat_bits_rsvdc,
  output  [31:0] io_in_0_rx_dat_bits_be,
  output  [255:0] io_in_0_rx_dat_bits_data,
  output  [31:0] io_in_0_rx_dat_bits_dataCheck,
  output  [3:0] io_in_0_rx_dat_bits_poison,
  input  io_in_0_rx_snp_ready,
  output  io_in_0_rx_snp_valid,
  output  [11:0] io_in_0_rx_snp_bits_txnID,
  output  [10:0] io_in_0_rx_snp_bits_fwdNID,
  output  [11:0] io_in_0_rx_snp_bits_fwdTxnID,
  output  [4:0] io_in_0_rx_snp_bits_opcode,
  output  [44:0] io_in_0_rx_snp_bits_addr,
  output  io_in_0_rx_snp_bits_doNotGoToSD,
  output  io_in_0_rx_snp_bits_retToSrc,
  input  io_out_cache_0_tx_req_ready,
  output  io_out_cache_0_tx_req_valid,
  output  [3:0] io_out_cache_0_tx_req_bits_qos,
  output  [10:0] io_out_cache_0_tx_req_bits_tgtID,
  output  [10:0] io_out_cache_0_tx_req_bits_srcID,
  output  [11:0] io_out_cache_0_tx_req_bits_txnID,
  output  [10:0] io_out_cache_0_tx_req_bits_returnNID,
  output  io_out_cache_0_tx_req_bits_stashNIDValid,
  output  [11:0] io_out_cache_0_tx_req_bits_returnTxnID,
  output  [6:0] io_out_cache_0_tx_req_bits_opcode,
  output  [2:0] io_out_cache_0_tx_req_bits_size,
  output  [47:0] io_out_cache_0_tx_req_bits_addr,
  output  io_out_cache_0_tx_req_bits_ns,
  output  io_out_cache_0_tx_req_bits_likelyshared,
  output  io_out_cache_0_tx_req_bits_allowRetry,
  output  [1:0] io_out_cache_0_tx_req_bits_order,
  output  [3:0] io_out_cache_0_tx_req_bits_pCrdType,
  output  io_out_cache_0_tx_req_bits_memAttr_allocate,
  output  io_out_cache_0_tx_req_bits_memAttr_cacheable,
  output  io_out_cache_0_tx_req_bits_memAttr_device,
  output  io_out_cache_0_tx_req_bits_memAttr_ewa,
  output  io_out_cache_0_tx_req_bits_snpAttr,
  output  [7:0] io_out_cache_0_tx_req_bits_lpIDWithPadding,
  output  io_out_cache_0_tx_req_bits_snoopMe,
  output  io_out_cache_0_tx_req_bits_expCompAck,
  output  [1:0] io_out_cache_0_tx_req_bits_tagOp,
  output  io_out_cache_0_tx_req_bits_traceTag,
  output  io_out_cache_0_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_out_cache_0_tx_req_bits_mpam_partID,
  output  io_out_cache_0_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_out_cache_0_tx_req_bits_rsvdc,
  input  io_out_cache_0_tx_rsp_ready,
  output  io_out_cache_0_tx_rsp_valid,
  output  [10:0] io_out_cache_0_tx_rsp_bits_srcID,
  output  [11:0] io_out_cache_0_tx_rsp_bits_txnID,
  output  [4:0] io_out_cache_0_tx_rsp_bits_opcode,
  output  [11:0] io_out_cache_0_tx_rsp_bits_dbID,
  input  io_out_cache_0_tx_dat_ready,
  output  io_out_cache_0_tx_dat_valid,
  output  [3:0] io_out_cache_0_tx_dat_bits_qos,
  output  [10:0] io_out_cache_0_tx_dat_bits_tgtID,
  output  [10:0] io_out_cache_0_tx_dat_bits_srcID,
  output  [11:0] io_out_cache_0_tx_dat_bits_txnID,
  output  [10:0] io_out_cache_0_tx_dat_bits_homeNID,
  output  [3:0] io_out_cache_0_tx_dat_bits_opcode,
  output  [1:0] io_out_cache_0_tx_dat_bits_respErr,
  output  [2:0] io_out_cache_0_tx_dat_bits_resp,
  output  [3:0] io_out_cache_0_tx_dat_bits_dataSource,
  output  [2:0] io_out_cache_0_tx_dat_bits_cBusy,
  output  [11:0] io_out_cache_0_tx_dat_bits_dbID,
  output  [1:0] io_out_cache_0_tx_dat_bits_ccID,
  output  [1:0] io_out_cache_0_tx_dat_bits_dataID,
  output  [1:0] io_out_cache_0_tx_dat_bits_tagOp,
  output  [7:0] io_out_cache_0_tx_dat_bits_tag,
  output  [1:0] io_out_cache_0_tx_dat_bits_tu,
  output  io_out_cache_0_tx_dat_bits_traceTag,
  output  [3:0] io_out_cache_0_tx_dat_bits_rsvdc,
  output  [31:0] io_out_cache_0_tx_dat_bits_be,
  output  [255:0] io_out_cache_0_tx_dat_bits_data,
  output  [31:0] io_out_cache_0_tx_dat_bits_dataCheck,
  output  [3:0] io_out_cache_0_tx_dat_bits_poison,
  output  io_out_cache_0_rx_rsp_ready,
  input  io_out_cache_0_rx_rsp_valid,
  input  [3:0] io_out_cache_0_rx_rsp_bits_qos,
  input  [11:0] io_out_cache_0_rx_rsp_bits_txnID,
  input  [4:0] io_out_cache_0_rx_rsp_bits_opcode,
  input  [1:0] io_out_cache_0_rx_rsp_bits_respErr,
  input  [2:0] io_out_cache_0_rx_rsp_bits_resp,
  input  [2:0] io_out_cache_0_rx_rsp_bits_fwdState,
  input  [2:0] io_out_cache_0_rx_rsp_bits_cBusy,
  input  [11:0] io_out_cache_0_rx_rsp_bits_dbID,
  input  [3:0] io_out_cache_0_rx_rsp_bits_pCrdType,
  input  [1:0] io_out_cache_0_rx_rsp_bits_tagOp,
  input  io_out_cache_0_rx_rsp_bits_traceTag,
  output  io_out_cache_0_rx_dat_ready,
  input  io_out_cache_0_rx_dat_valid,
  input  [11:0] io_out_cache_0_rx_dat_bits_txnID,
  input  [10:0] io_out_cache_0_rx_dat_bits_homeNID,
  input  [3:0] io_out_cache_0_rx_dat_bits_opcode,
  input  [2:0] io_out_cache_0_rx_dat_bits_resp,
  input  [3:0] io_out_cache_0_rx_dat_bits_dataSource,
  input  [11:0] io_out_cache_0_rx_dat_bits_dbID,
  input  [1:0] io_out_cache_0_rx_dat_bits_dataID,
  input  [31:0] io_out_cache_0_rx_dat_bits_be,
  input  [255:0] io_out_cache_0_rx_dat_bits_data,
  input  [31:0] io_out_cache_0_rx_dat_bits_dataCheck,
  output  io_out_cache_0_rx_snp_ready,
  input  io_out_cache_0_rx_snp_valid,
  input  [11:0] io_out_cache_0_rx_snp_bits_txnID,
  input  [10:0] io_out_cache_0_rx_snp_bits_fwdNID,
  input  [11:0] io_out_cache_0_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_cache_0_rx_snp_bits_opcode,
  input  [44:0] io_out_cache_0_rx_snp_bits_addr,
  input  io_out_cache_0_rx_snp_bits_doNotGoToSD,
  input  io_out_cache_0_rx_snp_bits_retToSrc,
  input  io_out_uncache_tx_req_ready,
  output  io_out_uncache_tx_req_valid,
  output  [3:0] io_out_uncache_tx_req_bits_qos,
  output  [10:0] io_out_uncache_tx_req_bits_tgtID,
  output  [10:0] io_out_uncache_tx_req_bits_srcID,
  output  [11:0] io_out_uncache_tx_req_bits_txnID,
  output  [10:0] io_out_uncache_tx_req_bits_returnNID,
  output  io_out_uncache_tx_req_bits_stashNIDValid,
  output  [11:0] io_out_uncache_tx_req_bits_returnTxnID,
  output  [6:0] io_out_uncache_tx_req_bits_opcode,
  output  [2:0] io_out_uncache_tx_req_bits_size,
  output  [47:0] io_out_uncache_tx_req_bits_addr,
  output  io_out_uncache_tx_req_bits_ns,
  output  io_out_uncache_tx_req_bits_likelyshared,
  output  io_out_uncache_tx_req_bits_allowRetry,
  output  [3:0] io_out_uncache_tx_req_bits_pCrdType,
  output  io_out_uncache_tx_req_bits_memAttr_allocate,
  output  io_out_uncache_tx_req_bits_memAttr_cacheable,
  output  io_out_uncache_tx_req_bits_memAttr_device,
  output  io_out_uncache_tx_req_bits_memAttr_ewa,
  output  io_out_uncache_tx_req_bits_snpAttr,
  output  [7:0] io_out_uncache_tx_req_bits_lpIDWithPadding,
  output  io_out_uncache_tx_req_bits_snoopMe,
  output  io_out_uncache_tx_req_bits_expCompAck,
  output  [1:0] io_out_uncache_tx_req_bits_tagOp,
  output  io_out_uncache_tx_req_bits_traceTag,
  output  io_out_uncache_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_out_uncache_tx_req_bits_mpam_partID,
  output  io_out_uncache_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_out_uncache_tx_req_bits_rsvdc,
  input  io_out_uncache_tx_dat_ready,
  output  io_out_uncache_tx_dat_valid,
  output  [3:0] io_out_uncache_tx_dat_bits_qos,
  output  [10:0] io_out_uncache_tx_dat_bits_tgtID,
  output  [10:0] io_out_uncache_tx_dat_bits_srcID,
  output  [11:0] io_out_uncache_tx_dat_bits_txnID,
  output  [10:0] io_out_uncache_tx_dat_bits_homeNID,
  output  [3:0] io_out_uncache_tx_dat_bits_opcode,
  output  [1:0] io_out_uncache_tx_dat_bits_respErr,
  output  [2:0] io_out_uncache_tx_dat_bits_resp,
  output  [3:0] io_out_uncache_tx_dat_bits_dataSource,
  output  [2:0] io_out_uncache_tx_dat_bits_cBusy,
  output  [11:0] io_out_uncache_tx_dat_bits_dbID,
  output  [1:0] io_out_uncache_tx_dat_bits_ccID,
  output  [1:0] io_out_uncache_tx_dat_bits_dataID,
  output  [1:0] io_out_uncache_tx_dat_bits_tagOp,
  output  [7:0] io_out_uncache_tx_dat_bits_tag,
  output  [1:0] io_out_uncache_tx_dat_bits_tu,
  output  io_out_uncache_tx_dat_bits_traceTag,
  output  [3:0] io_out_uncache_tx_dat_bits_rsvdc,
  output  [31:0] io_out_uncache_tx_dat_bits_be,
  output  [255:0] io_out_uncache_tx_dat_bits_data,
  output  [31:0] io_out_uncache_tx_dat_bits_dataCheck,
  output  [3:0] io_out_uncache_tx_dat_bits_poison,
  output  io_out_uncache_rx_rsp_ready,
  input  io_out_uncache_rx_rsp_valid,
  input  [3:0] io_out_uncache_rx_rsp_bits_qos,
  input  [10:0] io_out_uncache_rx_rsp_bits_tgtID,
  input  [11:0] io_out_uncache_rx_rsp_bits_txnID,
  input  [4:0] io_out_uncache_rx_rsp_bits_opcode,
  input  [1:0] io_out_uncache_rx_rsp_bits_respErr,
  input  [2:0] io_out_uncache_rx_rsp_bits_resp,
  input  [2:0] io_out_uncache_rx_rsp_bits_fwdState,
  input  [2:0] io_out_uncache_rx_rsp_bits_cBusy,
  input  [11:0] io_out_uncache_rx_rsp_bits_dbID,
  input  [3:0] io_out_uncache_rx_rsp_bits_pCrdType,
  input  [1:0] io_out_uncache_rx_rsp_bits_tagOp,
  input  io_out_uncache_rx_rsp_bits_traceTag,
  output  io_out_uncache_rx_dat_ready,
  input  io_out_uncache_rx_dat_valid,
  input  [3:0] io_out_uncache_rx_dat_bits_qos,
  input  [10:0] io_out_uncache_rx_dat_bits_tgtID,
  input  [11:0] io_out_uncache_rx_dat_bits_txnID,
  input  [10:0] io_out_uncache_rx_dat_bits_homeNID,
  input  [3:0] io_out_uncache_rx_dat_bits_opcode,
  input  [1:0] io_out_uncache_rx_dat_bits_respErr,
  input  [2:0] io_out_uncache_rx_dat_bits_resp,
  input  [3:0] io_out_uncache_rx_dat_bits_dataSource,
  input  [2:0] io_out_uncache_rx_dat_bits_cBusy,
  input  [11:0] io_out_uncache_rx_dat_bits_dbID,
  input  [1:0] io_out_uncache_rx_dat_bits_ccID,
  input  [1:0] io_out_uncache_rx_dat_bits_dataID,
  input  [1:0] io_out_uncache_rx_dat_bits_tagOp,
  input  [7:0] io_out_uncache_rx_dat_bits_tag,
  input  [1:0] io_out_uncache_rx_dat_bits_tu,
  input  io_out_uncache_rx_dat_bits_traceTag,
  input  [3:0] io_out_uncache_rx_dat_bits_rsvdc,
  input  [31:0] io_out_uncache_rx_dat_bits_be,
  input  [255:0] io_out_uncache_rx_dat_bits_data,
  input  [31:0] io_out_uncache_rx_dat_bits_dataCheck,
  input  [3:0] io_out_uncache_rx_dat_bits_poison
);
  assign io_in_0_tx_req_ready = '0;
  assign io_in_0_tx_rsp_ready = '0;
  assign io_in_0_tx_dat_ready = '0;
  assign io_in_0_rx_rsp_valid = '0;
  assign io_in_0_rx_rsp_bits_qos = '0;
  assign io_in_0_rx_rsp_bits_txnID = '0;
  assign io_in_0_rx_rsp_bits_opcode = '0;
  assign io_in_0_rx_rsp_bits_respErr = '0;
  assign io_in_0_rx_rsp_bits_resp = '0;
  assign io_in_0_rx_rsp_bits_fwdState = '0;
  assign io_in_0_rx_rsp_bits_cBusy = '0;
  assign io_in_0_rx_rsp_bits_dbID = '0;
  assign io_in_0_rx_rsp_bits_pCrdType = '0;
  assign io_in_0_rx_rsp_bits_tagOp = '0;
  assign io_in_0_rx_rsp_bits_traceTag = '0;
  assign io_in_0_rx_dat_valid = '0;
  assign io_in_0_rx_dat_bits_qos = '0;
  assign io_in_0_rx_dat_bits_txnID = '0;
  assign io_in_0_rx_dat_bits_homeNID = '0;
  assign io_in_0_rx_dat_bits_opcode = '0;
  assign io_in_0_rx_dat_bits_respErr = '0;
  assign io_in_0_rx_dat_bits_resp = '0;
  assign io_in_0_rx_dat_bits_dataSource = '0;
  assign io_in_0_rx_dat_bits_cBusy = '0;
  assign io_in_0_rx_dat_bits_dbID = '0;
  assign io_in_0_rx_dat_bits_ccID = '0;
  assign io_in_0_rx_dat_bits_dataID = '0;
  assign io_in_0_rx_dat_bits_tagOp = '0;
  assign io_in_0_rx_dat_bits_tag = '0;
  assign io_in_0_rx_dat_bits_tu = '0;
  assign io_in_0_rx_dat_bits_traceTag = '0;
  assign io_in_0_rx_dat_bits_rsvdc = '0;
  assign io_in_0_rx_dat_bits_be = '0;
  assign io_in_0_rx_dat_bits_data = '0;
  assign io_in_0_rx_dat_bits_dataCheck = '0;
  assign io_in_0_rx_dat_bits_poison = '0;
  assign io_in_0_rx_snp_valid = '0;
  assign io_in_0_rx_snp_bits_txnID = '0;
  assign io_in_0_rx_snp_bits_fwdNID = '0;
  assign io_in_0_rx_snp_bits_fwdTxnID = '0;
  assign io_in_0_rx_snp_bits_opcode = '0;
  assign io_in_0_rx_snp_bits_addr = '0;
  assign io_in_0_rx_snp_bits_doNotGoToSD = '0;
  assign io_in_0_rx_snp_bits_retToSrc = '0;
  assign io_out_cache_0_tx_req_valid = '0;
  assign io_out_cache_0_tx_req_bits_qos = '0;
  assign io_out_cache_0_tx_req_bits_tgtID = '0;
  assign io_out_cache_0_tx_req_bits_srcID = '0;
  assign io_out_cache_0_tx_req_bits_txnID = '0;
  assign io_out_cache_0_tx_req_bits_returnNID = '0;
  assign io_out_cache_0_tx_req_bits_stashNIDValid = '0;
  assign io_out_cache_0_tx_req_bits_returnTxnID = '0;
  assign io_out_cache_0_tx_req_bits_opcode = '0;
  assign io_out_cache_0_tx_req_bits_size = '0;
  assign io_out_cache_0_tx_req_bits_addr = '0;
  assign io_out_cache_0_tx_req_bits_ns = '0;
  assign io_out_cache_0_tx_req_bits_likelyshared = '0;
  assign io_out_cache_0_tx_req_bits_allowRetry = '0;
  assign io_out_cache_0_tx_req_bits_order = '0;
  assign io_out_cache_0_tx_req_bits_pCrdType = '0;
  assign io_out_cache_0_tx_req_bits_memAttr_allocate = '0;
  assign io_out_cache_0_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_cache_0_tx_req_bits_memAttr_device = '0;
  assign io_out_cache_0_tx_req_bits_memAttr_ewa = '0;
  assign io_out_cache_0_tx_req_bits_snpAttr = '0;
  assign io_out_cache_0_tx_req_bits_lpIDWithPadding = '0;
  assign io_out_cache_0_tx_req_bits_snoopMe = '0;
  assign io_out_cache_0_tx_req_bits_expCompAck = '0;
  assign io_out_cache_0_tx_req_bits_tagOp = '0;
  assign io_out_cache_0_tx_req_bits_traceTag = '0;
  assign io_out_cache_0_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_out_cache_0_tx_req_bits_mpam_partID = '0;
  assign io_out_cache_0_tx_req_bits_mpam_mpamNS = '0;
  assign io_out_cache_0_tx_req_bits_rsvdc = '0;
  assign io_out_cache_0_tx_rsp_valid = '0;
  assign io_out_cache_0_tx_rsp_bits_srcID = '0;
  assign io_out_cache_0_tx_rsp_bits_txnID = '0;
  assign io_out_cache_0_tx_rsp_bits_opcode = '0;
  assign io_out_cache_0_tx_rsp_bits_dbID = '0;
  assign io_out_cache_0_tx_dat_valid = '0;
  assign io_out_cache_0_tx_dat_bits_qos = '0;
  assign io_out_cache_0_tx_dat_bits_tgtID = '0;
  assign io_out_cache_0_tx_dat_bits_srcID = '0;
  assign io_out_cache_0_tx_dat_bits_txnID = '0;
  assign io_out_cache_0_tx_dat_bits_homeNID = '0;
  assign io_out_cache_0_tx_dat_bits_opcode = '0;
  assign io_out_cache_0_tx_dat_bits_respErr = '0;
  assign io_out_cache_0_tx_dat_bits_resp = '0;
  assign io_out_cache_0_tx_dat_bits_dataSource = '0;
  assign io_out_cache_0_tx_dat_bits_cBusy = '0;
  assign io_out_cache_0_tx_dat_bits_dbID = '0;
  assign io_out_cache_0_tx_dat_bits_ccID = '0;
  assign io_out_cache_0_tx_dat_bits_dataID = '0;
  assign io_out_cache_0_tx_dat_bits_tagOp = '0;
  assign io_out_cache_0_tx_dat_bits_tag = '0;
  assign io_out_cache_0_tx_dat_bits_tu = '0;
  assign io_out_cache_0_tx_dat_bits_traceTag = '0;
  assign io_out_cache_0_tx_dat_bits_rsvdc = '0;
  assign io_out_cache_0_tx_dat_bits_be = '0;
  assign io_out_cache_0_tx_dat_bits_data = '0;
  assign io_out_cache_0_tx_dat_bits_dataCheck = '0;
  assign io_out_cache_0_tx_dat_bits_poison = '0;
  assign io_out_cache_0_rx_rsp_ready = '0;
  assign io_out_cache_0_rx_dat_ready = '0;
  assign io_out_cache_0_rx_snp_ready = '0;
  assign io_out_uncache_tx_req_valid = '0;
  assign io_out_uncache_tx_req_bits_qos = '0;
  assign io_out_uncache_tx_req_bits_tgtID = '0;
  assign io_out_uncache_tx_req_bits_srcID = '0;
  assign io_out_uncache_tx_req_bits_txnID = '0;
  assign io_out_uncache_tx_req_bits_returnNID = '0;
  assign io_out_uncache_tx_req_bits_stashNIDValid = '0;
  assign io_out_uncache_tx_req_bits_returnTxnID = '0;
  assign io_out_uncache_tx_req_bits_opcode = '0;
  assign io_out_uncache_tx_req_bits_size = '0;
  assign io_out_uncache_tx_req_bits_addr = '0;
  assign io_out_uncache_tx_req_bits_ns = '0;
  assign io_out_uncache_tx_req_bits_likelyshared = '0;
  assign io_out_uncache_tx_req_bits_allowRetry = '0;
  assign io_out_uncache_tx_req_bits_pCrdType = '0;
  assign io_out_uncache_tx_req_bits_memAttr_allocate = '0;
  assign io_out_uncache_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_uncache_tx_req_bits_memAttr_device = '0;
  assign io_out_uncache_tx_req_bits_memAttr_ewa = '0;
  assign io_out_uncache_tx_req_bits_snpAttr = '0;
  assign io_out_uncache_tx_req_bits_lpIDWithPadding = '0;
  assign io_out_uncache_tx_req_bits_snoopMe = '0;
  assign io_out_uncache_tx_req_bits_expCompAck = '0;
  assign io_out_uncache_tx_req_bits_tagOp = '0;
  assign io_out_uncache_tx_req_bits_traceTag = '0;
  assign io_out_uncache_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_out_uncache_tx_req_bits_mpam_partID = '0;
  assign io_out_uncache_tx_req_bits_mpam_mpamNS = '0;
  assign io_out_uncache_tx_req_bits_rsvdc = '0;
  assign io_out_uncache_tx_dat_valid = '0;
  assign io_out_uncache_tx_dat_bits_qos = '0;
  assign io_out_uncache_tx_dat_bits_tgtID = '0;
  assign io_out_uncache_tx_dat_bits_srcID = '0;
  assign io_out_uncache_tx_dat_bits_txnID = '0;
  assign io_out_uncache_tx_dat_bits_homeNID = '0;
  assign io_out_uncache_tx_dat_bits_opcode = '0;
  assign io_out_uncache_tx_dat_bits_respErr = '0;
  assign io_out_uncache_tx_dat_bits_resp = '0;
  assign io_out_uncache_tx_dat_bits_dataSource = '0;
  assign io_out_uncache_tx_dat_bits_cBusy = '0;
  assign io_out_uncache_tx_dat_bits_dbID = '0;
  assign io_out_uncache_tx_dat_bits_ccID = '0;
  assign io_out_uncache_tx_dat_bits_dataID = '0;
  assign io_out_uncache_tx_dat_bits_tagOp = '0;
  assign io_out_uncache_tx_dat_bits_tag = '0;
  assign io_out_uncache_tx_dat_bits_tu = '0;
  assign io_out_uncache_tx_dat_bits_traceTag = '0;
  assign io_out_uncache_tx_dat_bits_rsvdc = '0;
  assign io_out_uncache_tx_dat_bits_be = '0;
  assign io_out_uncache_tx_dat_bits_data = '0;
  assign io_out_uncache_tx_dat_bits_dataCheck = '0;
  assign io_out_uncache_tx_dat_bits_poison = '0;
  assign io_out_uncache_rx_rsp_ready = '0;
  assign io_out_uncache_rx_dat_ready = '0;
endmodule

module MMIOMerger(
  output  io_in_cache_tx_req_ready,
  input  io_in_cache_tx_req_valid,
  input  [10:0] io_in_cache_tx_req_bits_tgtID,
  input  [10:0] io_in_cache_tx_req_bits_srcID,
  input  [11:0] io_in_cache_tx_req_bits_txnID,
  input  [6:0] io_in_cache_tx_req_bits_opcode,
  input  [2:0] io_in_cache_tx_req_bits_size,
  input  [47:0] io_in_cache_tx_req_bits_addr,
  input  io_in_cache_tx_req_bits_allowRetry,
  input  [1:0] io_in_cache_tx_req_bits_order,
  input  [3:0] io_in_cache_tx_req_bits_pCrdType,
  input  io_in_cache_tx_req_bits_memAttr_allocate,
  input  io_in_cache_tx_req_bits_memAttr_cacheable,
  input  io_in_cache_tx_req_bits_memAttr_device,
  input  io_in_cache_tx_req_bits_memAttr_ewa,
  input  io_in_cache_tx_req_bits_snpAttr,
  input  io_in_cache_tx_req_bits_expCompAck,
  output  io_in_cache_tx_dat_ready,
  input  io_in_cache_tx_dat_valid,
  input  [10:0] io_in_cache_tx_dat_bits_tgtID,
  input  [10:0] io_in_cache_tx_dat_bits_srcID,
  input  [11:0] io_in_cache_tx_dat_bits_txnID,
  input  [10:0] io_in_cache_tx_dat_bits_homeNID,
  input  [3:0] io_in_cache_tx_dat_bits_opcode,
  input  [2:0] io_in_cache_tx_dat_bits_resp,
  input  [3:0] io_in_cache_tx_dat_bits_dataSource,
  input  [11:0] io_in_cache_tx_dat_bits_dbID,
  input  [1:0] io_in_cache_tx_dat_bits_dataID,
  input  [31:0] io_in_cache_tx_dat_bits_be,
  input  [255:0] io_in_cache_tx_dat_bits_data,
  input  [31:0] io_in_cache_tx_dat_bits_dataCheck,
  input  io_in_cache_rx_rsp_ready,
  output  io_in_cache_rx_rsp_valid,
  output  [10:0] io_in_cache_rx_rsp_bits_srcID,
  output  [11:0] io_in_cache_rx_rsp_bits_txnID,
  output  [4:0] io_in_cache_rx_rsp_bits_opcode,
  output  [11:0] io_in_cache_rx_rsp_bits_dbID,
  input  io_in_cache_rx_dat_ready,
  output  io_in_cache_rx_dat_valid,
  output  [10:0] io_in_cache_rx_dat_bits_srcID,
  output  [11:0] io_in_cache_rx_dat_bits_txnID,
  output  [3:0] io_in_cache_rx_dat_bits_opcode,
  output  [2:0] io_in_cache_rx_dat_bits_resp,
  output  [1:0] io_in_cache_rx_dat_bits_dataID,
  output  [255:0] io_in_cache_rx_dat_bits_data,
  output  io_in_uncache_tx_req_ready,
  input  io_in_uncache_tx_req_valid,
  input  [3:0] io_in_uncache_tx_req_bits_qos,
  input  [10:0] io_in_uncache_tx_req_bits_tgtID,
  input  [10:0] io_in_uncache_tx_req_bits_srcID,
  input  [11:0] io_in_uncache_tx_req_bits_txnID,
  input  [10:0] io_in_uncache_tx_req_bits_returnNID,
  input  io_in_uncache_tx_req_bits_stashNIDValid,
  input  [11:0] io_in_uncache_tx_req_bits_returnTxnID,
  input  [6:0] io_in_uncache_tx_req_bits_opcode,
  input  [2:0] io_in_uncache_tx_req_bits_size,
  input  [47:0] io_in_uncache_tx_req_bits_addr,
  input  io_in_uncache_tx_req_bits_ns,
  input  io_in_uncache_tx_req_bits_likelyshared,
  input  io_in_uncache_tx_req_bits_allowRetry,
  input  [3:0] io_in_uncache_tx_req_bits_pCrdType,
  input  io_in_uncache_tx_req_bits_memAttr_allocate,
  input  io_in_uncache_tx_req_bits_memAttr_cacheable,
  input  io_in_uncache_tx_req_bits_memAttr_device,
  input  io_in_uncache_tx_req_bits_memAttr_ewa,
  input  io_in_uncache_tx_req_bits_snpAttr,
  input  [7:0] io_in_uncache_tx_req_bits_lpIDWithPadding,
  input  io_in_uncache_tx_req_bits_snoopMe,
  input  io_in_uncache_tx_req_bits_expCompAck,
  input  [1:0] io_in_uncache_tx_req_bits_tagOp,
  input  io_in_uncache_tx_req_bits_traceTag,
  input  io_in_uncache_tx_req_bits_mpam_perfMonGroup,
  input  [8:0] io_in_uncache_tx_req_bits_mpam_partID,
  input  io_in_uncache_tx_req_bits_mpam_mpamNS,
  input  [3:0] io_in_uncache_tx_req_bits_rsvdc,
  output  io_in_uncache_tx_dat_ready,
  input  io_in_uncache_tx_dat_valid,
  input  [3:0] io_in_uncache_tx_dat_bits_qos,
  input  [10:0] io_in_uncache_tx_dat_bits_tgtID,
  input  [10:0] io_in_uncache_tx_dat_bits_srcID,
  input  [11:0] io_in_uncache_tx_dat_bits_txnID,
  input  [10:0] io_in_uncache_tx_dat_bits_homeNID,
  input  [3:0] io_in_uncache_tx_dat_bits_opcode,
  input  [1:0] io_in_uncache_tx_dat_bits_respErr,
  input  [2:0] io_in_uncache_tx_dat_bits_resp,
  input  [3:0] io_in_uncache_tx_dat_bits_dataSource,
  input  [2:0] io_in_uncache_tx_dat_bits_cBusy,
  input  [11:0] io_in_uncache_tx_dat_bits_dbID,
  input  [1:0] io_in_uncache_tx_dat_bits_ccID,
  input  [1:0] io_in_uncache_tx_dat_bits_dataID,
  input  [1:0] io_in_uncache_tx_dat_bits_tagOp,
  input  [7:0] io_in_uncache_tx_dat_bits_tag,
  input  [1:0] io_in_uncache_tx_dat_bits_tu,
  input  io_in_uncache_tx_dat_bits_traceTag,
  input  [3:0] io_in_uncache_tx_dat_bits_rsvdc,
  input  [31:0] io_in_uncache_tx_dat_bits_be,
  input  [255:0] io_in_uncache_tx_dat_bits_data,
  input  [31:0] io_in_uncache_tx_dat_bits_dataCheck,
  input  [3:0] io_in_uncache_tx_dat_bits_poison,
  input  io_in_uncache_rx_rsp_ready,
  output  io_in_uncache_rx_rsp_valid,
  output  [3:0] io_in_uncache_rx_rsp_bits_qos,
  output  [10:0] io_in_uncache_rx_rsp_bits_tgtID,
  output  [11:0] io_in_uncache_rx_rsp_bits_txnID,
  output  [4:0] io_in_uncache_rx_rsp_bits_opcode,
  output  [1:0] io_in_uncache_rx_rsp_bits_respErr,
  output  [2:0] io_in_uncache_rx_rsp_bits_resp,
  output  [2:0] io_in_uncache_rx_rsp_bits_fwdState,
  output  [2:0] io_in_uncache_rx_rsp_bits_cBusy,
  output  [11:0] io_in_uncache_rx_rsp_bits_dbID,
  output  [3:0] io_in_uncache_rx_rsp_bits_pCrdType,
  output  [1:0] io_in_uncache_rx_rsp_bits_tagOp,
  output  io_in_uncache_rx_rsp_bits_traceTag,
  input  io_in_uncache_rx_dat_ready,
  output  io_in_uncache_rx_dat_valid,
  output  [3:0] io_in_uncache_rx_dat_bits_qos,
  output  [10:0] io_in_uncache_rx_dat_bits_tgtID,
  output  [11:0] io_in_uncache_rx_dat_bits_txnID,
  output  [10:0] io_in_uncache_rx_dat_bits_homeNID,
  output  [3:0] io_in_uncache_rx_dat_bits_opcode,
  output  [1:0] io_in_uncache_rx_dat_bits_respErr,
  output  [2:0] io_in_uncache_rx_dat_bits_resp,
  output  [3:0] io_in_uncache_rx_dat_bits_dataSource,
  output  [2:0] io_in_uncache_rx_dat_bits_cBusy,
  output  [11:0] io_in_uncache_rx_dat_bits_dbID,
  output  [1:0] io_in_uncache_rx_dat_bits_ccID,
  output  [1:0] io_in_uncache_rx_dat_bits_dataID,
  output  [1:0] io_in_uncache_rx_dat_bits_tagOp,
  output  [7:0] io_in_uncache_rx_dat_bits_tag,
  output  [1:0] io_in_uncache_rx_dat_bits_tu,
  output  io_in_uncache_rx_dat_bits_traceTag,
  output  [3:0] io_in_uncache_rx_dat_bits_rsvdc,
  output  [31:0] io_in_uncache_rx_dat_bits_be,
  output  [255:0] io_in_uncache_rx_dat_bits_data,
  output  [31:0] io_in_uncache_rx_dat_bits_dataCheck,
  output  [3:0] io_in_uncache_rx_dat_bits_poison,
  input  io_out_tx_req_ready,
  output  io_out_tx_req_valid,
  output  [3:0] io_out_tx_req_bits_qos,
  output  [10:0] io_out_tx_req_bits_tgtID,
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
  input  [3:0] io_out_rx_dat_bits_poison
);
  assign io_in_cache_tx_req_ready = '0;
  assign io_in_cache_tx_dat_ready = '0;
  assign io_in_cache_rx_rsp_valid = '0;
  assign io_in_cache_rx_rsp_bits_srcID = '0;
  assign io_in_cache_rx_rsp_bits_txnID = '0;
  assign io_in_cache_rx_rsp_bits_opcode = '0;
  assign io_in_cache_rx_rsp_bits_dbID = '0;
  assign io_in_cache_rx_dat_valid = '0;
  assign io_in_cache_rx_dat_bits_srcID = '0;
  assign io_in_cache_rx_dat_bits_txnID = '0;
  assign io_in_cache_rx_dat_bits_opcode = '0;
  assign io_in_cache_rx_dat_bits_resp = '0;
  assign io_in_cache_rx_dat_bits_dataID = '0;
  assign io_in_cache_rx_dat_bits_data = '0;
  assign io_in_uncache_tx_req_ready = '0;
  assign io_in_uncache_tx_dat_ready = '0;
  assign io_in_uncache_rx_rsp_valid = '0;
  assign io_in_uncache_rx_rsp_bits_qos = '0;
  assign io_in_uncache_rx_rsp_bits_tgtID = '0;
  assign io_in_uncache_rx_rsp_bits_txnID = '0;
  assign io_in_uncache_rx_rsp_bits_opcode = '0;
  assign io_in_uncache_rx_rsp_bits_respErr = '0;
  assign io_in_uncache_rx_rsp_bits_resp = '0;
  assign io_in_uncache_rx_rsp_bits_fwdState = '0;
  assign io_in_uncache_rx_rsp_bits_cBusy = '0;
  assign io_in_uncache_rx_rsp_bits_dbID = '0;
  assign io_in_uncache_rx_rsp_bits_pCrdType = '0;
  assign io_in_uncache_rx_rsp_bits_tagOp = '0;
  assign io_in_uncache_rx_rsp_bits_traceTag = '0;
  assign io_in_uncache_rx_dat_valid = '0;
  assign io_in_uncache_rx_dat_bits_qos = '0;
  assign io_in_uncache_rx_dat_bits_tgtID = '0;
  assign io_in_uncache_rx_dat_bits_txnID = '0;
  assign io_in_uncache_rx_dat_bits_homeNID = '0;
  assign io_in_uncache_rx_dat_bits_opcode = '0;
  assign io_in_uncache_rx_dat_bits_respErr = '0;
  assign io_in_uncache_rx_dat_bits_resp = '0;
  assign io_in_uncache_rx_dat_bits_dataSource = '0;
  assign io_in_uncache_rx_dat_bits_cBusy = '0;
  assign io_in_uncache_rx_dat_bits_dbID = '0;
  assign io_in_uncache_rx_dat_bits_ccID = '0;
  assign io_in_uncache_rx_dat_bits_dataID = '0;
  assign io_in_uncache_rx_dat_bits_tagOp = '0;
  assign io_in_uncache_rx_dat_bits_tag = '0;
  assign io_in_uncache_rx_dat_bits_tu = '0;
  assign io_in_uncache_rx_dat_bits_traceTag = '0;
  assign io_in_uncache_rx_dat_bits_rsvdc = '0;
  assign io_in_uncache_rx_dat_bits_be = '0;
  assign io_in_uncache_rx_dat_bits_data = '0;
  assign io_in_uncache_rx_dat_bits_dataCheck = '0;
  assign io_in_uncache_rx_dat_bits_poison = '0;
  assign io_out_tx_req_valid = '0;
  assign io_out_tx_req_bits_qos = '0;
  assign io_out_tx_req_bits_tgtID = '0;
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
endmodule

module RNLinkMonitor(
  input  clock,
  input  reset,
  input  io_in_tx_req_ready,
  output  io_in_tx_req_valid,
  output  [3:0] io_in_tx_req_bits_qos,
  output  [10:0] io_in_tx_req_bits_tgtID,
  output  [10:0] io_in_tx_req_bits_srcID,
  output  [11:0] io_in_tx_req_bits_txnID,
  output  [10:0] io_in_tx_req_bits_returnNID,
  output  io_in_tx_req_bits_stashNIDValid,
  output  [11:0] io_in_tx_req_bits_returnTxnID,
  output  [6:0] io_in_tx_req_bits_opcode,
  output  [2:0] io_in_tx_req_bits_size,
  output  [47:0] io_in_tx_req_bits_addr,
  output  io_in_tx_req_bits_ns,
  output  io_in_tx_req_bits_likelyshared,
  output  io_in_tx_req_bits_allowRetry,
  output  [1:0] io_in_tx_req_bits_order,
  output  [3:0] io_in_tx_req_bits_pCrdType,
  output  io_in_tx_req_bits_memAttr_allocate,
  output  io_in_tx_req_bits_memAttr_cacheable,
  output  io_in_tx_req_bits_memAttr_device,
  output  io_in_tx_req_bits_memAttr_ewa,
  output  io_in_tx_req_bits_snpAttr,
  output  [7:0] io_in_tx_req_bits_lpIDWithPadding,
  output  io_in_tx_req_bits_snoopMe,
  output  io_in_tx_req_bits_expCompAck,
  output  [1:0] io_in_tx_req_bits_tagOp,
  output  io_in_tx_req_bits_traceTag,
  output  io_in_tx_req_bits_mpam_perfMonGroup,
  output  [8:0] io_in_tx_req_bits_mpam_partID,
  output  io_in_tx_req_bits_mpam_mpamNS,
  output  [3:0] io_in_tx_req_bits_rsvdc,
  input  io_in_tx_rsp_ready,
  output  io_in_tx_rsp_valid,
  output  [10:0] io_in_tx_rsp_bits_srcID,
  output  [11:0] io_in_tx_rsp_bits_txnID,
  output  [4:0] io_in_tx_rsp_bits_opcode,
  output  [11:0] io_in_tx_rsp_bits_dbID,
  input  io_in_tx_dat_ready,
  output  io_in_tx_dat_valid,
  output  [3:0] io_in_tx_dat_bits_qos,
  output  [10:0] io_in_tx_dat_bits_tgtID,
  output  [10:0] io_in_tx_dat_bits_srcID,
  output  [11:0] io_in_tx_dat_bits_txnID,
  output  [10:0] io_in_tx_dat_bits_homeNID,
  output  [3:0] io_in_tx_dat_bits_opcode,
  output  [1:0] io_in_tx_dat_bits_respErr,
  output  [2:0] io_in_tx_dat_bits_resp,
  output  [3:0] io_in_tx_dat_bits_dataSource,
  output  [2:0] io_in_tx_dat_bits_cBusy,
  output  [11:0] io_in_tx_dat_bits_dbID,
  output  [1:0] io_in_tx_dat_bits_ccID,
  output  [1:0] io_in_tx_dat_bits_dataID,
  output  [1:0] io_in_tx_dat_bits_tagOp,
  output  [7:0] io_in_tx_dat_bits_tag,
  output  [1:0] io_in_tx_dat_bits_tu,
  output  io_in_tx_dat_bits_traceTag,
  output  [3:0] io_in_tx_dat_bits_rsvdc,
  output  [31:0] io_in_tx_dat_bits_be,
  output  [255:0] io_in_tx_dat_bits_data,
  output  [31:0] io_in_tx_dat_bits_dataCheck,
  output  [3:0] io_in_tx_dat_bits_poison,
  output  io_in_rx_rsp_ready,
  input  io_in_rx_rsp_valid,
  input  [3:0] io_in_rx_rsp_bits_qos,
  input  [11:0] io_in_rx_rsp_bits_txnID,
  input  [4:0] io_in_rx_rsp_bits_opcode,
  input  [1:0] io_in_rx_rsp_bits_respErr,
  input  [2:0] io_in_rx_rsp_bits_resp,
  input  [2:0] io_in_rx_rsp_bits_fwdState,
  input  [2:0] io_in_rx_rsp_bits_cBusy,
  input  [11:0] io_in_rx_rsp_bits_dbID,
  input  [3:0] io_in_rx_rsp_bits_pCrdType,
  input  [1:0] io_in_rx_rsp_bits_tagOp,
  input  io_in_rx_rsp_bits_traceTag,
  output  io_in_rx_dat_ready,
  input  io_in_rx_dat_valid,
  input  [3:0] io_in_rx_dat_bits_qos,
  input  [11:0] io_in_rx_dat_bits_txnID,
  input  [10:0] io_in_rx_dat_bits_homeNID,
  input  [3:0] io_in_rx_dat_bits_opcode,
  input  [1:0] io_in_rx_dat_bits_respErr,
  input  [2:0] io_in_rx_dat_bits_resp,
  input  [3:0] io_in_rx_dat_bits_dataSource,
  input  [2:0] io_in_rx_dat_bits_cBusy,
  input  [11:0] io_in_rx_dat_bits_dbID,
  input  [1:0] io_in_rx_dat_bits_ccID,
  input  [1:0] io_in_rx_dat_bits_dataID,
  input  [1:0] io_in_rx_dat_bits_tagOp,
  input  [7:0] io_in_rx_dat_bits_tag,
  input  [1:0] io_in_rx_dat_bits_tu,
  input  io_in_rx_dat_bits_traceTag,
  input  [3:0] io_in_rx_dat_bits_rsvdc,
  input  [31:0] io_in_rx_dat_bits_be,
  input  [255:0] io_in_rx_dat_bits_data,
  input  [31:0] io_in_rx_dat_bits_dataCheck,
  input  [3:0] io_in_rx_dat_bits_poison,
  output  io_in_rx_snp_ready,
  input  io_in_rx_snp_valid,
  input  [11:0] io_in_rx_snp_bits_txnID,
  input  [10:0] io_in_rx_snp_bits_fwdNID,
  input  [11:0] io_in_rx_snp_bits_fwdTxnID,
  input  [4:0] io_in_rx_snp_bits_opcode,
  input  [44:0] io_in_rx_snp_bits_addr,
  input  io_in_rx_snp_bits_doNotGoToSD,
  input  io_in_rx_snp_bits_retToSrc,
  input  io_out_txsactive,
  output  io_out_rxsactive,
  input  io_out_syscoreq,
  output  io_out_syscoack,
  input  io_out_tx_linkactivereq,
  output  io_out_tx_linkactiveack,
  input  io_out_tx_req_flitpend,
  input  io_out_tx_req_flitv,
  input  [161:0] io_out_tx_req_flit,
  output  io_out_tx_req_lcrdv,
  input  io_out_tx_rsp_flitpend,
  input  io_out_tx_rsp_flitv,
  input  [72:0] io_out_tx_rsp_flit,
  output  io_out_tx_rsp_lcrdv,
  input  io_out_tx_dat_flitpend,
  input  io_out_tx_dat_flitv,
  input  [421:0] io_out_tx_dat_flit,
  output  io_out_tx_dat_lcrdv,
  output  io_out_rx_linkactivereq,
  input  io_out_rx_linkactiveack,
  output  io_out_rx_rsp_flitpend,
  output  io_out_rx_rsp_flitv,
  output  [72:0] io_out_rx_rsp_flit,
  input  io_out_rx_rsp_lcrdv,
  output  io_out_rx_dat_flitpend,
  output  io_out_rx_dat_flitv,
  output  [421:0] io_out_rx_dat_flit,
  input  io_out_rx_dat_lcrdv,
  output  io_out_rx_snp_flitpend,
  output  io_out_rx_snp_flitv,
  output  [114:0] io_out_rx_snp_flit,
  input  io_out_rx_snp_lcrdv
);
  assign io_in_tx_req_valid = '0;
  assign io_in_tx_req_bits_qos = '0;
  assign io_in_tx_req_bits_tgtID = '0;
  assign io_in_tx_req_bits_srcID = '0;
  assign io_in_tx_req_bits_txnID = '0;
  assign io_in_tx_req_bits_returnNID = '0;
  assign io_in_tx_req_bits_stashNIDValid = '0;
  assign io_in_tx_req_bits_returnTxnID = '0;
  assign io_in_tx_req_bits_opcode = '0;
  assign io_in_tx_req_bits_size = '0;
  assign io_in_tx_req_bits_addr = '0;
  assign io_in_tx_req_bits_ns = '0;
  assign io_in_tx_req_bits_likelyshared = '0;
  assign io_in_tx_req_bits_allowRetry = '0;
  assign io_in_tx_req_bits_order = '0;
  assign io_in_tx_req_bits_pCrdType = '0;
  assign io_in_tx_req_bits_memAttr_allocate = '0;
  assign io_in_tx_req_bits_memAttr_cacheable = '0;
  assign io_in_tx_req_bits_memAttr_device = '0;
  assign io_in_tx_req_bits_memAttr_ewa = '0;
  assign io_in_tx_req_bits_snpAttr = '0;
  assign io_in_tx_req_bits_lpIDWithPadding = '0;
  assign io_in_tx_req_bits_snoopMe = '0;
  assign io_in_tx_req_bits_expCompAck = '0;
  assign io_in_tx_req_bits_tagOp = '0;
  assign io_in_tx_req_bits_traceTag = '0;
  assign io_in_tx_req_bits_mpam_perfMonGroup = '0;
  assign io_in_tx_req_bits_mpam_partID = '0;
  assign io_in_tx_req_bits_mpam_mpamNS = '0;
  assign io_in_tx_req_bits_rsvdc = '0;
  assign io_in_tx_rsp_valid = '0;
  assign io_in_tx_rsp_bits_srcID = '0;
  assign io_in_tx_rsp_bits_txnID = '0;
  assign io_in_tx_rsp_bits_opcode = '0;
  assign io_in_tx_rsp_bits_dbID = '0;
  assign io_in_tx_dat_valid = '0;
  assign io_in_tx_dat_bits_qos = '0;
  assign io_in_tx_dat_bits_tgtID = '0;
  assign io_in_tx_dat_bits_srcID = '0;
  assign io_in_tx_dat_bits_txnID = '0;
  assign io_in_tx_dat_bits_homeNID = '0;
  assign io_in_tx_dat_bits_opcode = '0;
  assign io_in_tx_dat_bits_respErr = '0;
  assign io_in_tx_dat_bits_resp = '0;
  assign io_in_tx_dat_bits_dataSource = '0;
  assign io_in_tx_dat_bits_cBusy = '0;
  assign io_in_tx_dat_bits_dbID = '0;
  assign io_in_tx_dat_bits_ccID = '0;
  assign io_in_tx_dat_bits_dataID = '0;
  assign io_in_tx_dat_bits_tagOp = '0;
  assign io_in_tx_dat_bits_tag = '0;
  assign io_in_tx_dat_bits_tu = '0;
  assign io_in_tx_dat_bits_traceTag = '0;
  assign io_in_tx_dat_bits_rsvdc = '0;
  assign io_in_tx_dat_bits_be = '0;
  assign io_in_tx_dat_bits_data = '0;
  assign io_in_tx_dat_bits_dataCheck = '0;
  assign io_in_tx_dat_bits_poison = '0;
  assign io_in_rx_rsp_ready = '0;
  assign io_in_rx_dat_ready = '0;
  assign io_in_rx_snp_ready = '0;
  assign io_out_rxsactive = '0;
  assign io_out_syscoack = '0;
  assign io_out_tx_linkactiveack = '0;
  assign io_out_tx_req_lcrdv = '0;
  assign io_out_tx_rsp_lcrdv = '0;
  assign io_out_tx_dat_lcrdv = '0;
  assign io_out_rx_linkactivereq = '0;
  assign io_out_rx_rsp_flitpend = '0;
  assign io_out_rx_rsp_flitv = '0;
  assign io_out_rx_rsp_flit = '0;
  assign io_out_rx_dat_flitpend = '0;
  assign io_out_rx_dat_flitv = '0;
  assign io_out_rx_dat_flit = '0;
  assign io_out_rx_snp_flitpend = '0;
  assign io_out_rx_snp_flitv = '0;
  assign io_out_rx_snp_flit = '0;
endmodule

module RNXbar(
  input  clock,
  input  reset,
  output  io_in_0_tx_req_ready,
  input  io_in_0_tx_req_valid,
  input  [3:0] io_in_0_tx_req_bits_qos,
  input  [10:0] io_in_0_tx_req_bits_tgtID,
  input  [10:0] io_in_0_tx_req_bits_srcID,
  input  [11:0] io_in_0_tx_req_bits_txnID,
  input  [10:0] io_in_0_tx_req_bits_returnNID,
  input  io_in_0_tx_req_bits_stashNIDValid,
  input  [11:0] io_in_0_tx_req_bits_returnTxnID,
  input  [6:0] io_in_0_tx_req_bits_opcode,
  input  [2:0] io_in_0_tx_req_bits_size,
  input  [47:0] io_in_0_tx_req_bits_addr,
  input  io_in_0_tx_req_bits_ns,
  input  io_in_0_tx_req_bits_likelyshared,
  input  io_in_0_tx_req_bits_allowRetry,
  input  [1:0] io_in_0_tx_req_bits_order,
  input  [3:0] io_in_0_tx_req_bits_pCrdType,
  input  io_in_0_tx_req_bits_memAttr_allocate,
  input  io_in_0_tx_req_bits_memAttr_cacheable,
  input  io_in_0_tx_req_bits_memAttr_device,
  input  io_in_0_tx_req_bits_memAttr_ewa,
  input  io_in_0_tx_req_bits_snpAttr,
  input  [7:0] io_in_0_tx_req_bits_lpIDWithPadding,
  input  io_in_0_tx_req_bits_snoopMe,
  input  io_in_0_tx_req_bits_expCompAck,
  input  [1:0] io_in_0_tx_req_bits_tagOp,
  input  io_in_0_tx_req_bits_traceTag,
  input  io_in_0_tx_req_bits_mpam_perfMonGroup,
  input  [8:0] io_in_0_tx_req_bits_mpam_partID,
  input  io_in_0_tx_req_bits_mpam_mpamNS,
  input  [3:0] io_in_0_tx_req_bits_rsvdc,
  output  io_in_0_tx_rsp_ready,
  input  io_in_0_tx_rsp_valid,
  input  [10:0] io_in_0_tx_rsp_bits_srcID,
  input  [11:0] io_in_0_tx_rsp_bits_txnID,
  input  [4:0] io_in_0_tx_rsp_bits_opcode,
  input  [11:0] io_in_0_tx_rsp_bits_dbID,
  output  io_in_0_tx_dat_ready,
  input  io_in_0_tx_dat_valid,
  input  [3:0] io_in_0_tx_dat_bits_qos,
  input  [10:0] io_in_0_tx_dat_bits_tgtID,
  input  [10:0] io_in_0_tx_dat_bits_srcID,
  input  [11:0] io_in_0_tx_dat_bits_txnID,
  input  [10:0] io_in_0_tx_dat_bits_homeNID,
  input  [3:0] io_in_0_tx_dat_bits_opcode,
  input  [1:0] io_in_0_tx_dat_bits_respErr,
  input  [2:0] io_in_0_tx_dat_bits_resp,
  input  [3:0] io_in_0_tx_dat_bits_dataSource,
  input  [2:0] io_in_0_tx_dat_bits_cBusy,
  input  [11:0] io_in_0_tx_dat_bits_dbID,
  input  [1:0] io_in_0_tx_dat_bits_ccID,
  input  [1:0] io_in_0_tx_dat_bits_dataID,
  input  [1:0] io_in_0_tx_dat_bits_tagOp,
  input  [7:0] io_in_0_tx_dat_bits_tag,
  input  [1:0] io_in_0_tx_dat_bits_tu,
  input  io_in_0_tx_dat_bits_traceTag,
  input  [3:0] io_in_0_tx_dat_bits_rsvdc,
  input  [31:0] io_in_0_tx_dat_bits_be,
  input  [255:0] io_in_0_tx_dat_bits_data,
  input  [31:0] io_in_0_tx_dat_bits_dataCheck,
  input  [3:0] io_in_0_tx_dat_bits_poison,
  input  io_in_0_rx_rsp_ready,
  output  io_in_0_rx_rsp_valid,
  output  [3:0] io_in_0_rx_rsp_bits_qos,
  output  [11:0] io_in_0_rx_rsp_bits_txnID,
  output  [4:0] io_in_0_rx_rsp_bits_opcode,
  output  [1:0] io_in_0_rx_rsp_bits_respErr,
  output  [2:0] io_in_0_rx_rsp_bits_resp,
  output  [2:0] io_in_0_rx_rsp_bits_fwdState,
  output  [2:0] io_in_0_rx_rsp_bits_cBusy,
  output  [11:0] io_in_0_rx_rsp_bits_dbID,
  output  [3:0] io_in_0_rx_rsp_bits_pCrdType,
  output  [1:0] io_in_0_rx_rsp_bits_tagOp,
  output  io_in_0_rx_rsp_bits_traceTag,
  input  io_in_0_rx_dat_ready,
  output  io_in_0_rx_dat_valid,
  output  [11:0] io_in_0_rx_dat_bits_txnID,
  output  [10:0] io_in_0_rx_dat_bits_homeNID,
  output  [3:0] io_in_0_rx_dat_bits_opcode,
  output  [2:0] io_in_0_rx_dat_bits_resp,
  output  [3:0] io_in_0_rx_dat_bits_dataSource,
  output  [11:0] io_in_0_rx_dat_bits_dbID,
  output  [1:0] io_in_0_rx_dat_bits_dataID,
  output  [31:0] io_in_0_rx_dat_bits_be,
  output  [255:0] io_in_0_rx_dat_bits_data,
  output  [31:0] io_in_0_rx_dat_bits_dataCheck,
  input  io_in_0_rx_snp_ready,
  output  io_in_0_rx_snp_valid,
  output  [11:0] io_in_0_rx_snp_bits_txnID,
  output  [10:0] io_in_0_rx_snp_bits_fwdNID,
  output  [11:0] io_in_0_rx_snp_bits_fwdTxnID,
  output  [4:0] io_in_0_rx_snp_bits_opcode,
  output  [44:0] io_in_0_rx_snp_bits_addr,
  output  io_in_0_rx_snp_bits_doNotGoToSD,
  output  io_in_0_rx_snp_bits_retToSrc,
  input  io_out_0_tx_req_ready,
  output  io_out_0_tx_req_valid,
  output  [10:0] io_out_0_tx_req_bits_tgtID,
  output  [10:0] io_out_0_tx_req_bits_srcID,
  output  [11:0] io_out_0_tx_req_bits_txnID,
  output  [6:0] io_out_0_tx_req_bits_opcode,
  output  [2:0] io_out_0_tx_req_bits_size,
  output  [47:0] io_out_0_tx_req_bits_addr,
  output  io_out_0_tx_req_bits_allowRetry,
  output  [1:0] io_out_0_tx_req_bits_order,
  output  [3:0] io_out_0_tx_req_bits_pCrdType,
  output  io_out_0_tx_req_bits_memAttr_allocate,
  output  io_out_0_tx_req_bits_memAttr_cacheable,
  output  io_out_0_tx_req_bits_memAttr_device,
  output  io_out_0_tx_req_bits_memAttr_ewa,
  output  io_out_0_tx_req_bits_snpAttr,
  output  io_out_0_tx_req_bits_expCompAck,
  output  io_out_0_tx_rsp_valid,
  output  [10:0] io_out_0_tx_rsp_bits_srcID,
  output  [11:0] io_out_0_tx_rsp_bits_txnID,
  output  [4:0] io_out_0_tx_rsp_bits_opcode,
  output  [11:0] io_out_0_tx_rsp_bits_dbID,
  output  io_out_0_tx_dat_valid,
  output  [10:0] io_out_0_tx_dat_bits_srcID,
  output  [11:0] io_out_0_tx_dat_bits_txnID,
  output  [3:0] io_out_0_tx_dat_bits_opcode,
  output  [2:0] io_out_0_tx_dat_bits_resp,
  output  [1:0] io_out_0_tx_dat_bits_dataID,
  output  [255:0] io_out_0_tx_dat_bits_data,
  output  io_out_0_rx_rsp_ready,
  input  io_out_0_rx_rsp_valid,
  input  [10:0] io_out_0_rx_rsp_bits_tgtID,
  input  [10:0] io_out_0_rx_rsp_bits_srcID,
  input  [11:0] io_out_0_rx_rsp_bits_txnID,
  input  [4:0] io_out_0_rx_rsp_bits_opcode,
  input  [2:0] io_out_0_rx_rsp_bits_resp,
  input  [2:0] io_out_0_rx_rsp_bits_fwdState,
  input  [11:0] io_out_0_rx_rsp_bits_dbID,
  input  [3:0] io_out_0_rx_rsp_bits_pCrdType,
  output  io_out_0_rx_dat_ready,
  input  io_out_0_rx_dat_valid,
  input  [10:0] io_out_0_rx_dat_bits_tgtID,
  input  [10:0] io_out_0_rx_dat_bits_srcID,
  input  [11:0] io_out_0_rx_dat_bits_txnID,
  input  [10:0] io_out_0_rx_dat_bits_homeNID,
  input  [3:0] io_out_0_rx_dat_bits_opcode,
  input  [2:0] io_out_0_rx_dat_bits_resp,
  input  [3:0] io_out_0_rx_dat_bits_dataSource,
  input  [11:0] io_out_0_rx_dat_bits_dbID,
  input  [1:0] io_out_0_rx_dat_bits_dataID,
  input  [31:0] io_out_0_rx_dat_bits_be,
  input  [255:0] io_out_0_rx_dat_bits_data,
  input  [31:0] io_out_0_rx_dat_bits_dataCheck,
  output  io_out_0_rx_snp_ready,
  input  io_out_0_rx_snp_valid,
  input  [11:0] io_out_0_rx_snp_bits_txnID,
  input  [10:0] io_out_0_rx_snp_bits_fwdNID,
  input  [11:0] io_out_0_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_0_rx_snp_bits_opcode,
  input  [44:0] io_out_0_rx_snp_bits_addr,
  input  io_out_0_rx_snp_bits_doNotGoToSD,
  input  io_out_0_rx_snp_bits_retToSrc,
  input  io_out_1_tx_req_ready,
  output  io_out_1_tx_req_valid,
  output  [10:0] io_out_1_tx_req_bits_tgtID,
  output  [10:0] io_out_1_tx_req_bits_srcID,
  output  [11:0] io_out_1_tx_req_bits_txnID,
  output  [6:0] io_out_1_tx_req_bits_opcode,
  output  [2:0] io_out_1_tx_req_bits_size,
  output  [47:0] io_out_1_tx_req_bits_addr,
  output  io_out_1_tx_req_bits_allowRetry,
  output  [1:0] io_out_1_tx_req_bits_order,
  output  [3:0] io_out_1_tx_req_bits_pCrdType,
  output  io_out_1_tx_req_bits_memAttr_allocate,
  output  io_out_1_tx_req_bits_memAttr_cacheable,
  output  io_out_1_tx_req_bits_memAttr_device,
  output  io_out_1_tx_req_bits_memAttr_ewa,
  output  io_out_1_tx_req_bits_snpAttr,
  output  io_out_1_tx_req_bits_expCompAck,
  output  io_out_1_tx_rsp_valid,
  output  [10:0] io_out_1_tx_rsp_bits_srcID,
  output  [11:0] io_out_1_tx_rsp_bits_txnID,
  output  [4:0] io_out_1_tx_rsp_bits_opcode,
  output  [11:0] io_out_1_tx_rsp_bits_dbID,
  output  io_out_1_tx_dat_valid,
  output  [10:0] io_out_1_tx_dat_bits_srcID,
  output  [11:0] io_out_1_tx_dat_bits_txnID,
  output  [3:0] io_out_1_tx_dat_bits_opcode,
  output  [2:0] io_out_1_tx_dat_bits_resp,
  output  [1:0] io_out_1_tx_dat_bits_dataID,
  output  [255:0] io_out_1_tx_dat_bits_data,
  output  io_out_1_rx_rsp_ready,
  input  io_out_1_rx_rsp_valid,
  input  [10:0] io_out_1_rx_rsp_bits_tgtID,
  input  [10:0] io_out_1_rx_rsp_bits_srcID,
  input  [11:0] io_out_1_rx_rsp_bits_txnID,
  input  [4:0] io_out_1_rx_rsp_bits_opcode,
  input  [2:0] io_out_1_rx_rsp_bits_resp,
  input  [2:0] io_out_1_rx_rsp_bits_fwdState,
  input  [11:0] io_out_1_rx_rsp_bits_dbID,
  input  [3:0] io_out_1_rx_rsp_bits_pCrdType,
  output  io_out_1_rx_dat_ready,
  input  io_out_1_rx_dat_valid,
  input  [10:0] io_out_1_rx_dat_bits_tgtID,
  input  [10:0] io_out_1_rx_dat_bits_srcID,
  input  [11:0] io_out_1_rx_dat_bits_txnID,
  input  [10:0] io_out_1_rx_dat_bits_homeNID,
  input  [3:0] io_out_1_rx_dat_bits_opcode,
  input  [2:0] io_out_1_rx_dat_bits_resp,
  input  [3:0] io_out_1_rx_dat_bits_dataSource,
  input  [11:0] io_out_1_rx_dat_bits_dbID,
  input  [1:0] io_out_1_rx_dat_bits_dataID,
  input  [31:0] io_out_1_rx_dat_bits_be,
  input  [255:0] io_out_1_rx_dat_bits_data,
  input  [31:0] io_out_1_rx_dat_bits_dataCheck,
  output  io_out_1_rx_snp_ready,
  input  io_out_1_rx_snp_valid,
  input  [11:0] io_out_1_rx_snp_bits_txnID,
  input  [10:0] io_out_1_rx_snp_bits_fwdNID,
  input  [11:0] io_out_1_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_1_rx_snp_bits_opcode,
  input  [44:0] io_out_1_rx_snp_bits_addr,
  input  io_out_1_rx_snp_bits_doNotGoToSD,
  input  io_out_1_rx_snp_bits_retToSrc,
  input  io_out_2_tx_req_ready,
  output  io_out_2_tx_req_valid,
  output  [10:0] io_out_2_tx_req_bits_tgtID,
  output  [10:0] io_out_2_tx_req_bits_srcID,
  output  [11:0] io_out_2_tx_req_bits_txnID,
  output  [6:0] io_out_2_tx_req_bits_opcode,
  output  [2:0] io_out_2_tx_req_bits_size,
  output  [47:0] io_out_2_tx_req_bits_addr,
  output  io_out_2_tx_req_bits_allowRetry,
  output  [1:0] io_out_2_tx_req_bits_order,
  output  [3:0] io_out_2_tx_req_bits_pCrdType,
  output  io_out_2_tx_req_bits_memAttr_allocate,
  output  io_out_2_tx_req_bits_memAttr_cacheable,
  output  io_out_2_tx_req_bits_memAttr_device,
  output  io_out_2_tx_req_bits_memAttr_ewa,
  output  io_out_2_tx_req_bits_snpAttr,
  output  io_out_2_tx_req_bits_expCompAck,
  output  io_out_2_tx_rsp_valid,
  output  [10:0] io_out_2_tx_rsp_bits_srcID,
  output  [11:0] io_out_2_tx_rsp_bits_txnID,
  output  [4:0] io_out_2_tx_rsp_bits_opcode,
  output  [11:0] io_out_2_tx_rsp_bits_dbID,
  output  io_out_2_tx_dat_valid,
  output  [10:0] io_out_2_tx_dat_bits_srcID,
  output  [11:0] io_out_2_tx_dat_bits_txnID,
  output  [3:0] io_out_2_tx_dat_bits_opcode,
  output  [2:0] io_out_2_tx_dat_bits_resp,
  output  [1:0] io_out_2_tx_dat_bits_dataID,
  output  [255:0] io_out_2_tx_dat_bits_data,
  output  io_out_2_rx_rsp_ready,
  input  io_out_2_rx_rsp_valid,
  input  [10:0] io_out_2_rx_rsp_bits_tgtID,
  input  [10:0] io_out_2_rx_rsp_bits_srcID,
  input  [11:0] io_out_2_rx_rsp_bits_txnID,
  input  [4:0] io_out_2_rx_rsp_bits_opcode,
  input  [2:0] io_out_2_rx_rsp_bits_resp,
  input  [2:0] io_out_2_rx_rsp_bits_fwdState,
  input  [11:0] io_out_2_rx_rsp_bits_dbID,
  input  [3:0] io_out_2_rx_rsp_bits_pCrdType,
  output  io_out_2_rx_dat_ready,
  input  io_out_2_rx_dat_valid,
  input  [10:0] io_out_2_rx_dat_bits_tgtID,
  input  [10:0] io_out_2_rx_dat_bits_srcID,
  input  [11:0] io_out_2_rx_dat_bits_txnID,
  input  [10:0] io_out_2_rx_dat_bits_homeNID,
  input  [3:0] io_out_2_rx_dat_bits_opcode,
  input  [2:0] io_out_2_rx_dat_bits_resp,
  input  [3:0] io_out_2_rx_dat_bits_dataSource,
  input  [11:0] io_out_2_rx_dat_bits_dbID,
  input  [1:0] io_out_2_rx_dat_bits_dataID,
  input  [31:0] io_out_2_rx_dat_bits_be,
  input  [255:0] io_out_2_rx_dat_bits_data,
  input  [31:0] io_out_2_rx_dat_bits_dataCheck,
  output  io_out_2_rx_snp_ready,
  input  io_out_2_rx_snp_valid,
  input  [11:0] io_out_2_rx_snp_bits_txnID,
  input  [10:0] io_out_2_rx_snp_bits_fwdNID,
  input  [11:0] io_out_2_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_2_rx_snp_bits_opcode,
  input  [44:0] io_out_2_rx_snp_bits_addr,
  input  io_out_2_rx_snp_bits_doNotGoToSD,
  input  io_out_2_rx_snp_bits_retToSrc,
  input  io_out_3_tx_req_ready,
  output  io_out_3_tx_req_valid,
  output  [10:0] io_out_3_tx_req_bits_tgtID,
  output  [10:0] io_out_3_tx_req_bits_srcID,
  output  [11:0] io_out_3_tx_req_bits_txnID,
  output  [6:0] io_out_3_tx_req_bits_opcode,
  output  [2:0] io_out_3_tx_req_bits_size,
  output  [47:0] io_out_3_tx_req_bits_addr,
  output  io_out_3_tx_req_bits_allowRetry,
  output  [1:0] io_out_3_tx_req_bits_order,
  output  [3:0] io_out_3_tx_req_bits_pCrdType,
  output  io_out_3_tx_req_bits_memAttr_allocate,
  output  io_out_3_tx_req_bits_memAttr_cacheable,
  output  io_out_3_tx_req_bits_memAttr_device,
  output  io_out_3_tx_req_bits_memAttr_ewa,
  output  io_out_3_tx_req_bits_snpAttr,
  output  io_out_3_tx_req_bits_expCompAck,
  output  io_out_3_tx_rsp_valid,
  output  [10:0] io_out_3_tx_rsp_bits_srcID,
  output  [11:0] io_out_3_tx_rsp_bits_txnID,
  output  [4:0] io_out_3_tx_rsp_bits_opcode,
  output  [11:0] io_out_3_tx_rsp_bits_dbID,
  output  io_out_3_tx_dat_valid,
  output  [10:0] io_out_3_tx_dat_bits_srcID,
  output  [11:0] io_out_3_tx_dat_bits_txnID,
  output  [3:0] io_out_3_tx_dat_bits_opcode,
  output  [2:0] io_out_3_tx_dat_bits_resp,
  output  [1:0] io_out_3_tx_dat_bits_dataID,
  output  [255:0] io_out_3_tx_dat_bits_data,
  output  io_out_3_rx_rsp_ready,
  input  io_out_3_rx_rsp_valid,
  input  [10:0] io_out_3_rx_rsp_bits_tgtID,
  input  [10:0] io_out_3_rx_rsp_bits_srcID,
  input  [11:0] io_out_3_rx_rsp_bits_txnID,
  input  [4:0] io_out_3_rx_rsp_bits_opcode,
  input  [2:0] io_out_3_rx_rsp_bits_resp,
  input  [2:0] io_out_3_rx_rsp_bits_fwdState,
  input  [11:0] io_out_3_rx_rsp_bits_dbID,
  input  [3:0] io_out_3_rx_rsp_bits_pCrdType,
  output  io_out_3_rx_dat_ready,
  input  io_out_3_rx_dat_valid,
  input  [10:0] io_out_3_rx_dat_bits_tgtID,
  input  [10:0] io_out_3_rx_dat_bits_srcID,
  input  [11:0] io_out_3_rx_dat_bits_txnID,
  input  [10:0] io_out_3_rx_dat_bits_homeNID,
  input  [3:0] io_out_3_rx_dat_bits_opcode,
  input  [2:0] io_out_3_rx_dat_bits_resp,
  input  [3:0] io_out_3_rx_dat_bits_dataSource,
  input  [11:0] io_out_3_rx_dat_bits_dbID,
  input  [1:0] io_out_3_rx_dat_bits_dataID,
  input  [31:0] io_out_3_rx_dat_bits_be,
  input  [255:0] io_out_3_rx_dat_bits_data,
  input  [31:0] io_out_3_rx_dat_bits_dataCheck,
  output  io_out_3_rx_snp_ready,
  input  io_out_3_rx_snp_valid,
  input  [11:0] io_out_3_rx_snp_bits_txnID,
  input  [10:0] io_out_3_rx_snp_bits_fwdNID,
  input  [11:0] io_out_3_rx_snp_bits_fwdTxnID,
  input  [4:0] io_out_3_rx_snp_bits_opcode,
  input  [44:0] io_out_3_rx_snp_bits_addr,
  input  io_out_3_rx_snp_bits_doNotGoToSD,
  input  io_out_3_rx_snp_bits_retToSrc,
  input  io_snpMasks_0_0,
  input  io_snpMasks_1_0,
  input  io_snpMasks_2_0,
  input  io_snpMasks_3_0
);
  assign io_in_0_tx_req_ready = '0;
  assign io_in_0_tx_rsp_ready = '0;
  assign io_in_0_tx_dat_ready = '0;
  assign io_in_0_rx_rsp_valid = '0;
  assign io_in_0_rx_rsp_bits_qos = '0;
  assign io_in_0_rx_rsp_bits_txnID = '0;
  assign io_in_0_rx_rsp_bits_opcode = '0;
  assign io_in_0_rx_rsp_bits_respErr = '0;
  assign io_in_0_rx_rsp_bits_resp = '0;
  assign io_in_0_rx_rsp_bits_fwdState = '0;
  assign io_in_0_rx_rsp_bits_cBusy = '0;
  assign io_in_0_rx_rsp_bits_dbID = '0;
  assign io_in_0_rx_rsp_bits_pCrdType = '0;
  assign io_in_0_rx_rsp_bits_tagOp = '0;
  assign io_in_0_rx_rsp_bits_traceTag = '0;
  assign io_in_0_rx_dat_valid = '0;
  assign io_in_0_rx_dat_bits_txnID = '0;
  assign io_in_0_rx_dat_bits_homeNID = '0;
  assign io_in_0_rx_dat_bits_opcode = '0;
  assign io_in_0_rx_dat_bits_resp = '0;
  assign io_in_0_rx_dat_bits_dataSource = '0;
  assign io_in_0_rx_dat_bits_dbID = '0;
  assign io_in_0_rx_dat_bits_dataID = '0;
  assign io_in_0_rx_dat_bits_be = '0;
  assign io_in_0_rx_dat_bits_data = '0;
  assign io_in_0_rx_dat_bits_dataCheck = '0;
  assign io_in_0_rx_snp_valid = '0;
  assign io_in_0_rx_snp_bits_txnID = '0;
  assign io_in_0_rx_snp_bits_fwdNID = '0;
  assign io_in_0_rx_snp_bits_fwdTxnID = '0;
  assign io_in_0_rx_snp_bits_opcode = '0;
  assign io_in_0_rx_snp_bits_addr = '0;
  assign io_in_0_rx_snp_bits_doNotGoToSD = '0;
  assign io_in_0_rx_snp_bits_retToSrc = '0;
  assign io_out_0_tx_req_valid = '0;
  assign io_out_0_tx_req_bits_tgtID = '0;
  assign io_out_0_tx_req_bits_srcID = '0;
  assign io_out_0_tx_req_bits_txnID = '0;
  assign io_out_0_tx_req_bits_opcode = '0;
  assign io_out_0_tx_req_bits_size = '0;
  assign io_out_0_tx_req_bits_addr = '0;
  assign io_out_0_tx_req_bits_allowRetry = '0;
  assign io_out_0_tx_req_bits_order = '0;
  assign io_out_0_tx_req_bits_pCrdType = '0;
  assign io_out_0_tx_req_bits_memAttr_allocate = '0;
  assign io_out_0_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_0_tx_req_bits_memAttr_device = '0;
  assign io_out_0_tx_req_bits_memAttr_ewa = '0;
  assign io_out_0_tx_req_bits_snpAttr = '0;
  assign io_out_0_tx_req_bits_expCompAck = '0;
  assign io_out_0_tx_rsp_valid = '0;
  assign io_out_0_tx_rsp_bits_srcID = '0;
  assign io_out_0_tx_rsp_bits_txnID = '0;
  assign io_out_0_tx_rsp_bits_opcode = '0;
  assign io_out_0_tx_rsp_bits_dbID = '0;
  assign io_out_0_tx_dat_valid = '0;
  assign io_out_0_tx_dat_bits_srcID = '0;
  assign io_out_0_tx_dat_bits_txnID = '0;
  assign io_out_0_tx_dat_bits_opcode = '0;
  assign io_out_0_tx_dat_bits_resp = '0;
  assign io_out_0_tx_dat_bits_dataID = '0;
  assign io_out_0_tx_dat_bits_data = '0;
  assign io_out_0_rx_rsp_ready = '0;
  assign io_out_0_rx_dat_ready = '0;
  assign io_out_0_rx_snp_ready = '0;
  assign io_out_1_tx_req_valid = '0;
  assign io_out_1_tx_req_bits_tgtID = '0;
  assign io_out_1_tx_req_bits_srcID = '0;
  assign io_out_1_tx_req_bits_txnID = '0;
  assign io_out_1_tx_req_bits_opcode = '0;
  assign io_out_1_tx_req_bits_size = '0;
  assign io_out_1_tx_req_bits_addr = '0;
  assign io_out_1_tx_req_bits_allowRetry = '0;
  assign io_out_1_tx_req_bits_order = '0;
  assign io_out_1_tx_req_bits_pCrdType = '0;
  assign io_out_1_tx_req_bits_memAttr_allocate = '0;
  assign io_out_1_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_1_tx_req_bits_memAttr_device = '0;
  assign io_out_1_tx_req_bits_memAttr_ewa = '0;
  assign io_out_1_tx_req_bits_snpAttr = '0;
  assign io_out_1_tx_req_bits_expCompAck = '0;
  assign io_out_1_tx_rsp_valid = '0;
  assign io_out_1_tx_rsp_bits_srcID = '0;
  assign io_out_1_tx_rsp_bits_txnID = '0;
  assign io_out_1_tx_rsp_bits_opcode = '0;
  assign io_out_1_tx_rsp_bits_dbID = '0;
  assign io_out_1_tx_dat_valid = '0;
  assign io_out_1_tx_dat_bits_srcID = '0;
  assign io_out_1_tx_dat_bits_txnID = '0;
  assign io_out_1_tx_dat_bits_opcode = '0;
  assign io_out_1_tx_dat_bits_resp = '0;
  assign io_out_1_tx_dat_bits_dataID = '0;
  assign io_out_1_tx_dat_bits_data = '0;
  assign io_out_1_rx_rsp_ready = '0;
  assign io_out_1_rx_dat_ready = '0;
  assign io_out_1_rx_snp_ready = '0;
  assign io_out_2_tx_req_valid = '0;
  assign io_out_2_tx_req_bits_tgtID = '0;
  assign io_out_2_tx_req_bits_srcID = '0;
  assign io_out_2_tx_req_bits_txnID = '0;
  assign io_out_2_tx_req_bits_opcode = '0;
  assign io_out_2_tx_req_bits_size = '0;
  assign io_out_2_tx_req_bits_addr = '0;
  assign io_out_2_tx_req_bits_allowRetry = '0;
  assign io_out_2_tx_req_bits_order = '0;
  assign io_out_2_tx_req_bits_pCrdType = '0;
  assign io_out_2_tx_req_bits_memAttr_allocate = '0;
  assign io_out_2_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_2_tx_req_bits_memAttr_device = '0;
  assign io_out_2_tx_req_bits_memAttr_ewa = '0;
  assign io_out_2_tx_req_bits_snpAttr = '0;
  assign io_out_2_tx_req_bits_expCompAck = '0;
  assign io_out_2_tx_rsp_valid = '0;
  assign io_out_2_tx_rsp_bits_srcID = '0;
  assign io_out_2_tx_rsp_bits_txnID = '0;
  assign io_out_2_tx_rsp_bits_opcode = '0;
  assign io_out_2_tx_rsp_bits_dbID = '0;
  assign io_out_2_tx_dat_valid = '0;
  assign io_out_2_tx_dat_bits_srcID = '0;
  assign io_out_2_tx_dat_bits_txnID = '0;
  assign io_out_2_tx_dat_bits_opcode = '0;
  assign io_out_2_tx_dat_bits_resp = '0;
  assign io_out_2_tx_dat_bits_dataID = '0;
  assign io_out_2_tx_dat_bits_data = '0;
  assign io_out_2_rx_rsp_ready = '0;
  assign io_out_2_rx_dat_ready = '0;
  assign io_out_2_rx_snp_ready = '0;
  assign io_out_3_tx_req_valid = '0;
  assign io_out_3_tx_req_bits_tgtID = '0;
  assign io_out_3_tx_req_bits_srcID = '0;
  assign io_out_3_tx_req_bits_txnID = '0;
  assign io_out_3_tx_req_bits_opcode = '0;
  assign io_out_3_tx_req_bits_size = '0;
  assign io_out_3_tx_req_bits_addr = '0;
  assign io_out_3_tx_req_bits_allowRetry = '0;
  assign io_out_3_tx_req_bits_order = '0;
  assign io_out_3_tx_req_bits_pCrdType = '0;
  assign io_out_3_tx_req_bits_memAttr_allocate = '0;
  assign io_out_3_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_3_tx_req_bits_memAttr_device = '0;
  assign io_out_3_tx_req_bits_memAttr_ewa = '0;
  assign io_out_3_tx_req_bits_snpAttr = '0;
  assign io_out_3_tx_req_bits_expCompAck = '0;
  assign io_out_3_tx_rsp_valid = '0;
  assign io_out_3_tx_rsp_bits_srcID = '0;
  assign io_out_3_tx_rsp_bits_txnID = '0;
  assign io_out_3_tx_rsp_bits_opcode = '0;
  assign io_out_3_tx_rsp_bits_dbID = '0;
  assign io_out_3_tx_dat_valid = '0;
  assign io_out_3_tx_dat_bits_srcID = '0;
  assign io_out_3_tx_dat_bits_txnID = '0;
  assign io_out_3_tx_dat_bits_opcode = '0;
  assign io_out_3_tx_dat_bits_resp = '0;
  assign io_out_3_tx_dat_bits_dataID = '0;
  assign io_out_3_tx_dat_bits_data = '0;
  assign io_out_3_rx_rsp_ready = '0;
  assign io_out_3_rx_dat_ready = '0;
  assign io_out_3_rx_snp_ready = '0;
endmodule

module SNLinkMonitor(
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
  output  io_out_txsactive,
  input  io_out_rxsactive,
  output  io_out_tx_linkactivereq,
  input  io_out_tx_linkactiveack,
  output  io_out_tx_req_flitpend,
  output  io_out_tx_req_flitv,
  output  [161:0] io_out_tx_req_flit,
  input  io_out_tx_req_lcrdv,
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
  output  io_out_rx_dat_lcrdv
);
  assign io_in_tx_req_ready = '0;
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
  assign io_out_txsactive = '0;
  assign io_out_tx_linkactivereq = '0;
  assign io_out_tx_req_flitpend = '0;
  assign io_out_tx_req_flitv = '0;
  assign io_out_tx_req_flit = '0;
  assign io_out_tx_dat_flitpend = '0;
  assign io_out_tx_dat_flitv = '0;
  assign io_out_tx_dat_flit = '0;
  assign io_out_rx_linkactiveack = '0;
  assign io_out_rx_rsp_lcrdv = '0;
  assign io_out_rx_dat_lcrdv = '0;
endmodule

module SNXbar(
  input  clock,
  input  reset,
  output  io_in_0_tx_req_ready,
  input  io_in_0_tx_req_valid,
  input  [10:0] io_in_0_tx_req_bits_tgtID,
  input  [10:0] io_in_0_tx_req_bits_srcID,
  input  [11:0] io_in_0_tx_req_bits_txnID,
  input  [6:0] io_in_0_tx_req_bits_opcode,
  input  [2:0] io_in_0_tx_req_bits_size,
  input  [47:0] io_in_0_tx_req_bits_addr,
  input  io_in_0_tx_req_bits_allowRetry,
  input  [1:0] io_in_0_tx_req_bits_order,
  input  [3:0] io_in_0_tx_req_bits_pCrdType,
  input  io_in_0_tx_req_bits_memAttr_allocate,
  input  io_in_0_tx_req_bits_memAttr_cacheable,
  input  io_in_0_tx_req_bits_memAttr_device,
  input  io_in_0_tx_req_bits_memAttr_ewa,
  input  io_in_0_tx_req_bits_snpAttr,
  input  io_in_0_tx_req_bits_expCompAck,
  output  io_in_0_tx_dat_ready,
  input  io_in_0_tx_dat_valid,
  input  [10:0] io_in_0_tx_dat_bits_tgtID,
  input  [10:0] io_in_0_tx_dat_bits_srcID,
  input  [11:0] io_in_0_tx_dat_bits_txnID,
  input  [10:0] io_in_0_tx_dat_bits_homeNID,
  input  [3:0] io_in_0_tx_dat_bits_opcode,
  input  [2:0] io_in_0_tx_dat_bits_resp,
  input  [3:0] io_in_0_tx_dat_bits_dataSource,
  input  [11:0] io_in_0_tx_dat_bits_dbID,
  input  [1:0] io_in_0_tx_dat_bits_dataID,
  input  [31:0] io_in_0_tx_dat_bits_be,
  input  [255:0] io_in_0_tx_dat_bits_data,
  input  [31:0] io_in_0_tx_dat_bits_dataCheck,
  output  io_in_0_rx_rsp_valid,
  output  [10:0] io_in_0_rx_rsp_bits_srcID,
  output  [11:0] io_in_0_rx_rsp_bits_txnID,
  output  [4:0] io_in_0_rx_rsp_bits_opcode,
  output  [11:0] io_in_0_rx_rsp_bits_dbID,
  output  io_in_0_rx_dat_valid,
  output  [10:0] io_in_0_rx_dat_bits_srcID,
  output  [11:0] io_in_0_rx_dat_bits_txnID,
  output  [3:0] io_in_0_rx_dat_bits_opcode,
  output  [2:0] io_in_0_rx_dat_bits_resp,
  output  [1:0] io_in_0_rx_dat_bits_dataID,
  output  [255:0] io_in_0_rx_dat_bits_data,
  output  io_in_1_tx_req_ready,
  input  io_in_1_tx_req_valid,
  input  [10:0] io_in_1_tx_req_bits_tgtID,
  input  [10:0] io_in_1_tx_req_bits_srcID,
  input  [11:0] io_in_1_tx_req_bits_txnID,
  input  [6:0] io_in_1_tx_req_bits_opcode,
  input  [2:0] io_in_1_tx_req_bits_size,
  input  [47:0] io_in_1_tx_req_bits_addr,
  input  io_in_1_tx_req_bits_allowRetry,
  input  [1:0] io_in_1_tx_req_bits_order,
  input  [3:0] io_in_1_tx_req_bits_pCrdType,
  input  io_in_1_tx_req_bits_memAttr_allocate,
  input  io_in_1_tx_req_bits_memAttr_cacheable,
  input  io_in_1_tx_req_bits_memAttr_device,
  input  io_in_1_tx_req_bits_memAttr_ewa,
  input  io_in_1_tx_req_bits_snpAttr,
  input  io_in_1_tx_req_bits_expCompAck,
  output  io_in_1_tx_dat_ready,
  input  io_in_1_tx_dat_valid,
  input  [10:0] io_in_1_tx_dat_bits_tgtID,
  input  [10:0] io_in_1_tx_dat_bits_srcID,
  input  [11:0] io_in_1_tx_dat_bits_txnID,
  input  [10:0] io_in_1_tx_dat_bits_homeNID,
  input  [3:0] io_in_1_tx_dat_bits_opcode,
  input  [2:0] io_in_1_tx_dat_bits_resp,
  input  [3:0] io_in_1_tx_dat_bits_dataSource,
  input  [11:0] io_in_1_tx_dat_bits_dbID,
  input  [1:0] io_in_1_tx_dat_bits_dataID,
  input  [31:0] io_in_1_tx_dat_bits_be,
  input  [255:0] io_in_1_tx_dat_bits_data,
  input  [31:0] io_in_1_tx_dat_bits_dataCheck,
  output  io_in_1_rx_rsp_valid,
  output  [10:0] io_in_1_rx_rsp_bits_srcID,
  output  [11:0] io_in_1_rx_rsp_bits_txnID,
  output  [4:0] io_in_1_rx_rsp_bits_opcode,
  output  [11:0] io_in_1_rx_rsp_bits_dbID,
  output  io_in_1_rx_dat_valid,
  output  [10:0] io_in_1_rx_dat_bits_srcID,
  output  [11:0] io_in_1_rx_dat_bits_txnID,
  output  [3:0] io_in_1_rx_dat_bits_opcode,
  output  [2:0] io_in_1_rx_dat_bits_resp,
  output  [1:0] io_in_1_rx_dat_bits_dataID,
  output  [255:0] io_in_1_rx_dat_bits_data,
  output  io_in_2_tx_req_ready,
  input  io_in_2_tx_req_valid,
  input  [10:0] io_in_2_tx_req_bits_tgtID,
  input  [10:0] io_in_2_tx_req_bits_srcID,
  input  [11:0] io_in_2_tx_req_bits_txnID,
  input  [6:0] io_in_2_tx_req_bits_opcode,
  input  [2:0] io_in_2_tx_req_bits_size,
  input  [47:0] io_in_2_tx_req_bits_addr,
  input  io_in_2_tx_req_bits_allowRetry,
  input  [1:0] io_in_2_tx_req_bits_order,
  input  [3:0] io_in_2_tx_req_bits_pCrdType,
  input  io_in_2_tx_req_bits_memAttr_allocate,
  input  io_in_2_tx_req_bits_memAttr_cacheable,
  input  io_in_2_tx_req_bits_memAttr_device,
  input  io_in_2_tx_req_bits_memAttr_ewa,
  input  io_in_2_tx_req_bits_snpAttr,
  input  io_in_2_tx_req_bits_expCompAck,
  output  io_in_2_tx_dat_ready,
  input  io_in_2_tx_dat_valid,
  input  [10:0] io_in_2_tx_dat_bits_tgtID,
  input  [10:0] io_in_2_tx_dat_bits_srcID,
  input  [11:0] io_in_2_tx_dat_bits_txnID,
  input  [10:0] io_in_2_tx_dat_bits_homeNID,
  input  [3:0] io_in_2_tx_dat_bits_opcode,
  input  [2:0] io_in_2_tx_dat_bits_resp,
  input  [3:0] io_in_2_tx_dat_bits_dataSource,
  input  [11:0] io_in_2_tx_dat_bits_dbID,
  input  [1:0] io_in_2_tx_dat_bits_dataID,
  input  [31:0] io_in_2_tx_dat_bits_be,
  input  [255:0] io_in_2_tx_dat_bits_data,
  input  [31:0] io_in_2_tx_dat_bits_dataCheck,
  output  io_in_2_rx_rsp_valid,
  output  [10:0] io_in_2_rx_rsp_bits_srcID,
  output  [11:0] io_in_2_rx_rsp_bits_txnID,
  output  [4:0] io_in_2_rx_rsp_bits_opcode,
  output  [11:0] io_in_2_rx_rsp_bits_dbID,
  output  io_in_2_rx_dat_valid,
  output  [10:0] io_in_2_rx_dat_bits_srcID,
  output  [11:0] io_in_2_rx_dat_bits_txnID,
  output  [3:0] io_in_2_rx_dat_bits_opcode,
  output  [2:0] io_in_2_rx_dat_bits_resp,
  output  [1:0] io_in_2_rx_dat_bits_dataID,
  output  [255:0] io_in_2_rx_dat_bits_data,
  output  io_in_3_tx_req_ready,
  input  io_in_3_tx_req_valid,
  input  [10:0] io_in_3_tx_req_bits_tgtID,
  input  [10:0] io_in_3_tx_req_bits_srcID,
  input  [11:0] io_in_3_tx_req_bits_txnID,
  input  [6:0] io_in_3_tx_req_bits_opcode,
  input  [2:0] io_in_3_tx_req_bits_size,
  input  [47:0] io_in_3_tx_req_bits_addr,
  input  io_in_3_tx_req_bits_allowRetry,
  input  [1:0] io_in_3_tx_req_bits_order,
  input  [3:0] io_in_3_tx_req_bits_pCrdType,
  input  io_in_3_tx_req_bits_memAttr_allocate,
  input  io_in_3_tx_req_bits_memAttr_cacheable,
  input  io_in_3_tx_req_bits_memAttr_device,
  input  io_in_3_tx_req_bits_memAttr_ewa,
  input  io_in_3_tx_req_bits_snpAttr,
  input  io_in_3_tx_req_bits_expCompAck,
  output  io_in_3_tx_dat_ready,
  input  io_in_3_tx_dat_valid,
  input  [10:0] io_in_3_tx_dat_bits_tgtID,
  input  [10:0] io_in_3_tx_dat_bits_srcID,
  input  [11:0] io_in_3_tx_dat_bits_txnID,
  input  [10:0] io_in_3_tx_dat_bits_homeNID,
  input  [3:0] io_in_3_tx_dat_bits_opcode,
  input  [2:0] io_in_3_tx_dat_bits_resp,
  input  [3:0] io_in_3_tx_dat_bits_dataSource,
  input  [11:0] io_in_3_tx_dat_bits_dbID,
  input  [1:0] io_in_3_tx_dat_bits_dataID,
  input  [31:0] io_in_3_tx_dat_bits_be,
  input  [255:0] io_in_3_tx_dat_bits_data,
  input  [31:0] io_in_3_tx_dat_bits_dataCheck,
  output  io_in_3_rx_rsp_valid,
  output  [10:0] io_in_3_rx_rsp_bits_srcID,
  output  [11:0] io_in_3_rx_rsp_bits_txnID,
  output  [4:0] io_in_3_rx_rsp_bits_opcode,
  output  [11:0] io_in_3_rx_rsp_bits_dbID,
  output  io_in_3_rx_dat_valid,
  output  [10:0] io_in_3_rx_dat_bits_srcID,
  output  [11:0] io_in_3_rx_dat_bits_txnID,
  output  [3:0] io_in_3_rx_dat_bits_opcode,
  output  [2:0] io_in_3_rx_dat_bits_resp,
  output  [1:0] io_in_3_rx_dat_bits_dataID,
  output  [255:0] io_in_3_rx_dat_bits_data,
  input  io_out_tx_req_ready,
  output  io_out_tx_req_valid,
  output  [10:0] io_out_tx_req_bits_tgtID,
  output  [10:0] io_out_tx_req_bits_srcID,
  output  [11:0] io_out_tx_req_bits_txnID,
  output  [6:0] io_out_tx_req_bits_opcode,
  output  [2:0] io_out_tx_req_bits_size,
  output  [47:0] io_out_tx_req_bits_addr,
  output  io_out_tx_req_bits_allowRetry,
  output  [1:0] io_out_tx_req_bits_order,
  output  [3:0] io_out_tx_req_bits_pCrdType,
  output  io_out_tx_req_bits_memAttr_allocate,
  output  io_out_tx_req_bits_memAttr_cacheable,
  output  io_out_tx_req_bits_memAttr_device,
  output  io_out_tx_req_bits_memAttr_ewa,
  output  io_out_tx_req_bits_snpAttr,
  output  io_out_tx_req_bits_expCompAck,
  input  io_out_tx_dat_ready,
  output  io_out_tx_dat_valid,
  output  [10:0] io_out_tx_dat_bits_tgtID,
  output  [10:0] io_out_tx_dat_bits_srcID,
  output  [11:0] io_out_tx_dat_bits_txnID,
  output  [10:0] io_out_tx_dat_bits_homeNID,
  output  [3:0] io_out_tx_dat_bits_opcode,
  output  [2:0] io_out_tx_dat_bits_resp,
  output  [3:0] io_out_tx_dat_bits_dataSource,
  output  [11:0] io_out_tx_dat_bits_dbID,
  output  [1:0] io_out_tx_dat_bits_dataID,
  output  [31:0] io_out_tx_dat_bits_be,
  output  [255:0] io_out_tx_dat_bits_data,
  output  [31:0] io_out_tx_dat_bits_dataCheck,
  output  io_out_rx_rsp_ready,
  input  io_out_rx_rsp_valid,
  input  [10:0] io_out_rx_rsp_bits_srcID,
  input  [11:0] io_out_rx_rsp_bits_txnID,
  input  [4:0] io_out_rx_rsp_bits_opcode,
  input  [11:0] io_out_rx_rsp_bits_dbID,
  output  io_out_rx_dat_ready,
  input  io_out_rx_dat_valid,
  input  [10:0] io_out_rx_dat_bits_srcID,
  input  [11:0] io_out_rx_dat_bits_txnID,
  input  [3:0] io_out_rx_dat_bits_opcode,
  input  [2:0] io_out_rx_dat_bits_resp,
  input  [1:0] io_out_rx_dat_bits_dataID,
  input  [255:0] io_out_rx_dat_bits_data
);
  assign io_in_0_tx_req_ready = '0;
  assign io_in_0_tx_dat_ready = '0;
  assign io_in_0_rx_rsp_valid = '0;
  assign io_in_0_rx_rsp_bits_srcID = '0;
  assign io_in_0_rx_rsp_bits_txnID = '0;
  assign io_in_0_rx_rsp_bits_opcode = '0;
  assign io_in_0_rx_rsp_bits_dbID = '0;
  assign io_in_0_rx_dat_valid = '0;
  assign io_in_0_rx_dat_bits_srcID = '0;
  assign io_in_0_rx_dat_bits_txnID = '0;
  assign io_in_0_rx_dat_bits_opcode = '0;
  assign io_in_0_rx_dat_bits_resp = '0;
  assign io_in_0_rx_dat_bits_dataID = '0;
  assign io_in_0_rx_dat_bits_data = '0;
  assign io_in_1_tx_req_ready = '0;
  assign io_in_1_tx_dat_ready = '0;
  assign io_in_1_rx_rsp_valid = '0;
  assign io_in_1_rx_rsp_bits_srcID = '0;
  assign io_in_1_rx_rsp_bits_txnID = '0;
  assign io_in_1_rx_rsp_bits_opcode = '0;
  assign io_in_1_rx_rsp_bits_dbID = '0;
  assign io_in_1_rx_dat_valid = '0;
  assign io_in_1_rx_dat_bits_srcID = '0;
  assign io_in_1_rx_dat_bits_txnID = '0;
  assign io_in_1_rx_dat_bits_opcode = '0;
  assign io_in_1_rx_dat_bits_resp = '0;
  assign io_in_1_rx_dat_bits_dataID = '0;
  assign io_in_1_rx_dat_bits_data = '0;
  assign io_in_2_tx_req_ready = '0;
  assign io_in_2_tx_dat_ready = '0;
  assign io_in_2_rx_rsp_valid = '0;
  assign io_in_2_rx_rsp_bits_srcID = '0;
  assign io_in_2_rx_rsp_bits_txnID = '0;
  assign io_in_2_rx_rsp_bits_opcode = '0;
  assign io_in_2_rx_rsp_bits_dbID = '0;
  assign io_in_2_rx_dat_valid = '0;
  assign io_in_2_rx_dat_bits_srcID = '0;
  assign io_in_2_rx_dat_bits_txnID = '0;
  assign io_in_2_rx_dat_bits_opcode = '0;
  assign io_in_2_rx_dat_bits_resp = '0;
  assign io_in_2_rx_dat_bits_dataID = '0;
  assign io_in_2_rx_dat_bits_data = '0;
  assign io_in_3_tx_req_ready = '0;
  assign io_in_3_tx_dat_ready = '0;
  assign io_in_3_rx_rsp_valid = '0;
  assign io_in_3_rx_rsp_bits_srcID = '0;
  assign io_in_3_rx_rsp_bits_txnID = '0;
  assign io_in_3_rx_rsp_bits_opcode = '0;
  assign io_in_3_rx_rsp_bits_dbID = '0;
  assign io_in_3_rx_dat_valid = '0;
  assign io_in_3_rx_dat_bits_srcID = '0;
  assign io_in_3_rx_dat_bits_txnID = '0;
  assign io_in_3_rx_dat_bits_opcode = '0;
  assign io_in_3_rx_dat_bits_resp = '0;
  assign io_in_3_rx_dat_bits_dataID = '0;
  assign io_in_3_rx_dat_bits_data = '0;
  assign io_out_tx_req_valid = '0;
  assign io_out_tx_req_bits_tgtID = '0;
  assign io_out_tx_req_bits_srcID = '0;
  assign io_out_tx_req_bits_txnID = '0;
  assign io_out_tx_req_bits_opcode = '0;
  assign io_out_tx_req_bits_size = '0;
  assign io_out_tx_req_bits_addr = '0;
  assign io_out_tx_req_bits_allowRetry = '0;
  assign io_out_tx_req_bits_order = '0;
  assign io_out_tx_req_bits_pCrdType = '0;
  assign io_out_tx_req_bits_memAttr_allocate = '0;
  assign io_out_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_tx_req_bits_memAttr_device = '0;
  assign io_out_tx_req_bits_memAttr_ewa = '0;
  assign io_out_tx_req_bits_snpAttr = '0;
  assign io_out_tx_req_bits_expCompAck = '0;
  assign io_out_tx_dat_valid = '0;
  assign io_out_tx_dat_bits_tgtID = '0;
  assign io_out_tx_dat_bits_srcID = '0;
  assign io_out_tx_dat_bits_txnID = '0;
  assign io_out_tx_dat_bits_homeNID = '0;
  assign io_out_tx_dat_bits_opcode = '0;
  assign io_out_tx_dat_bits_resp = '0;
  assign io_out_tx_dat_bits_dataSource = '0;
  assign io_out_tx_dat_bits_dbID = '0;
  assign io_out_tx_dat_bits_dataID = '0;
  assign io_out_tx_dat_bits_be = '0;
  assign io_out_tx_dat_bits_data = '0;
  assign io_out_tx_dat_bits_dataCheck = '0;
  assign io_out_rx_rsp_ready = '0;
  assign io_out_rx_dat_ready = '0;
endmodule

module Slice_4(
  input  clock,
  input  reset,
  output  io_in_tx_req_ready,
  input  io_in_tx_req_valid,
  input  [10:0] io_in_tx_req_bits_tgtID,
  input  [10:0] io_in_tx_req_bits_srcID,
  input  [11:0] io_in_tx_req_bits_txnID,
  input  [6:0] io_in_tx_req_bits_opcode,
  input  [2:0] io_in_tx_req_bits_size,
  input  [47:0] io_in_tx_req_bits_addr,
  input  io_in_tx_req_bits_allowRetry,
  input  [1:0] io_in_tx_req_bits_order,
  input  [3:0] io_in_tx_req_bits_pCrdType,
  input  io_in_tx_req_bits_memAttr_allocate,
  input  io_in_tx_req_bits_memAttr_cacheable,
  input  io_in_tx_req_bits_memAttr_device,
  input  io_in_tx_req_bits_memAttr_ewa,
  input  io_in_tx_req_bits_snpAttr,
  input  io_in_tx_req_bits_expCompAck,
  input  io_in_tx_rsp_valid,
  input  [10:0] io_in_tx_rsp_bits_srcID,
  input  [11:0] io_in_tx_rsp_bits_txnID,
  input  [4:0] io_in_tx_rsp_bits_opcode,
  input  [11:0] io_in_tx_rsp_bits_dbID,
  input  io_in_tx_dat_valid,
  input  [10:0] io_in_tx_dat_bits_srcID,
  input  [11:0] io_in_tx_dat_bits_txnID,
  input  [3:0] io_in_tx_dat_bits_opcode,
  input  [2:0] io_in_tx_dat_bits_resp,
  input  [1:0] io_in_tx_dat_bits_dataID,
  input  [255:0] io_in_tx_dat_bits_data,
  input  io_in_rx_rsp_ready,
  output  io_in_rx_rsp_valid,
  output  [10:0] io_in_rx_rsp_bits_tgtID,
  output  [10:0] io_in_rx_rsp_bits_srcID,
  output  [11:0] io_in_rx_rsp_bits_txnID,
  output  [4:0] io_in_rx_rsp_bits_opcode,
  output  [2:0] io_in_rx_rsp_bits_resp,
  output  [2:0] io_in_rx_rsp_bits_fwdState,
  output  [11:0] io_in_rx_rsp_bits_dbID,
  output  [3:0] io_in_rx_rsp_bits_pCrdType,
  input  io_in_rx_dat_ready,
  output  io_in_rx_dat_valid,
  output  [10:0] io_in_rx_dat_bits_tgtID,
  output  [10:0] io_in_rx_dat_bits_srcID,
  output  [11:0] io_in_rx_dat_bits_txnID,
  output  [10:0] io_in_rx_dat_bits_homeNID,
  output  [3:0] io_in_rx_dat_bits_opcode,
  output  [2:0] io_in_rx_dat_bits_resp,
  output  [3:0] io_in_rx_dat_bits_dataSource,
  output  [11:0] io_in_rx_dat_bits_dbID,
  output  [1:0] io_in_rx_dat_bits_dataID,
  output  [31:0] io_in_rx_dat_bits_be,
  output  [255:0] io_in_rx_dat_bits_data,
  output  [31:0] io_in_rx_dat_bits_dataCheck,
  input  io_in_rx_snp_ready,
  output  io_in_rx_snp_valid,
  output  [11:0] io_in_rx_snp_bits_txnID,
  output  [10:0] io_in_rx_snp_bits_fwdNID,
  output  [11:0] io_in_rx_snp_bits_fwdTxnID,
  output  [4:0] io_in_rx_snp_bits_opcode,
  output  [44:0] io_in_rx_snp_bits_addr,
  output  io_in_rx_snp_bits_doNotGoToSD,
  output  io_in_rx_snp_bits_retToSrc,
  input  io_out_tx_req_ready,
  output  io_out_tx_req_valid,
  output  [10:0] io_out_tx_req_bits_tgtID,
  output  [10:0] io_out_tx_req_bits_srcID,
  output  [11:0] io_out_tx_req_bits_txnID,
  output  [6:0] io_out_tx_req_bits_opcode,
  output  [2:0] io_out_tx_req_bits_size,
  output  [47:0] io_out_tx_req_bits_addr,
  output  io_out_tx_req_bits_allowRetry,
  output  [1:0] io_out_tx_req_bits_order,
  output  [3:0] io_out_tx_req_bits_pCrdType,
  output  io_out_tx_req_bits_memAttr_allocate,
  output  io_out_tx_req_bits_memAttr_cacheable,
  output  io_out_tx_req_bits_memAttr_device,
  output  io_out_tx_req_bits_memAttr_ewa,
  output  io_out_tx_req_bits_snpAttr,
  output  io_out_tx_req_bits_expCompAck,
  input  io_out_tx_dat_ready,
  output  io_out_tx_dat_valid,
  output  [10:0] io_out_tx_dat_bits_tgtID,
  output  [10:0] io_out_tx_dat_bits_srcID,
  output  [11:0] io_out_tx_dat_bits_txnID,
  output  [10:0] io_out_tx_dat_bits_homeNID,
  output  [3:0] io_out_tx_dat_bits_opcode,
  output  [2:0] io_out_tx_dat_bits_resp,
  output  [3:0] io_out_tx_dat_bits_dataSource,
  output  [11:0] io_out_tx_dat_bits_dbID,
  output  [1:0] io_out_tx_dat_bits_dataID,
  output  [31:0] io_out_tx_dat_bits_be,
  output  [255:0] io_out_tx_dat_bits_data,
  output  [31:0] io_out_tx_dat_bits_dataCheck,
  input  io_out_rx_rsp_valid,
  input  [10:0] io_out_rx_rsp_bits_srcID,
  input  [11:0] io_out_rx_rsp_bits_txnID,
  input  [4:0] io_out_rx_rsp_bits_opcode,
  input  [11:0] io_out_rx_rsp_bits_dbID,
  input  io_out_rx_dat_valid,
  input  [10:0] io_out_rx_dat_bits_srcID,
  input  [11:0] io_out_rx_dat_bits_txnID,
  input  [3:0] io_out_rx_dat_bits_opcode,
  input  [2:0] io_out_rx_dat_bits_resp,
  input  [1:0] io_out_rx_dat_bits_dataID,
  input  [255:0] io_out_rx_dat_bits_data,
  output  io_snpMask_0,
  output  io_msStatus_0_valid,
  output  [11:0] io_msStatus_0_bits_set,
  output  [27:0] io_msStatus_0_bits_tag,
  output  [6:0] io_msStatus_0_bits_opcode,
  output  io_msStatus_0_bits_is_miss,
  output  io_msStatus_1_valid,
  output  [11:0] io_msStatus_1_bits_set,
  output  [27:0] io_msStatus_1_bits_tag,
  output  [6:0] io_msStatus_1_bits_opcode,
  output  io_msStatus_1_bits_is_miss,
  output  io_msStatus_2_valid,
  output  [11:0] io_msStatus_2_bits_set,
  output  [27:0] io_msStatus_2_bits_tag,
  output  [6:0] io_msStatus_2_bits_opcode,
  output  io_msStatus_2_bits_is_miss,
  output  io_msStatus_3_valid,
  output  [11:0] io_msStatus_3_bits_set,
  output  [27:0] io_msStatus_3_bits_tag,
  output  [6:0] io_msStatus_3_bits_opcode,
  output  io_msStatus_3_bits_is_miss,
  output  io_msStatus_4_valid,
  output  [11:0] io_msStatus_4_bits_set,
  output  [27:0] io_msStatus_4_bits_tag,
  output  [6:0] io_msStatus_4_bits_opcode,
  output  io_msStatus_4_bits_is_miss,
  output  io_msStatus_5_valid,
  output  [11:0] io_msStatus_5_bits_set,
  output  [27:0] io_msStatus_5_bits_tag,
  output  [6:0] io_msStatus_5_bits_opcode,
  output  io_msStatus_5_bits_is_miss,
  output  io_msStatus_6_valid,
  output  [11:0] io_msStatus_6_bits_set,
  output  [27:0] io_msStatus_6_bits_tag,
  output  [6:0] io_msStatus_6_bits_opcode,
  output  io_msStatus_6_bits_is_miss,
  output  io_msStatus_7_valid,
  output  [11:0] io_msStatus_7_bits_set,
  output  [27:0] io_msStatus_7_bits_tag,
  output  [6:0] io_msStatus_7_bits_opcode,
  output  io_msStatus_7_bits_is_miss,
  output  io_msStatus_8_valid,
  output  [11:0] io_msStatus_8_bits_set,
  output  [27:0] io_msStatus_8_bits_tag,
  output  [6:0] io_msStatus_8_bits_opcode,
  output  io_msStatus_8_bits_is_miss,
  output  io_msStatus_9_valid,
  output  [11:0] io_msStatus_9_bits_set,
  output  [27:0] io_msStatus_9_bits_tag,
  output  [6:0] io_msStatus_9_bits_opcode,
  output  io_msStatus_9_bits_is_miss,
  output  io_msStatus_10_valid,
  output  [11:0] io_msStatus_10_bits_set,
  output  [27:0] io_msStatus_10_bits_tag,
  output  [6:0] io_msStatus_10_bits_opcode,
  output  io_msStatus_10_bits_is_miss,
  output  io_msStatus_11_valid,
  output  [11:0] io_msStatus_11_bits_set,
  output  [27:0] io_msStatus_11_bits_tag,
  output  [6:0] io_msStatus_11_bits_opcode,
  output  io_msStatus_11_bits_is_miss,
  output  io_msStatus_12_valid,
  output  [11:0] io_msStatus_12_bits_set,
  output  [27:0] io_msStatus_12_bits_tag,
  output  [6:0] io_msStatus_12_bits_opcode,
  output  io_msStatus_12_bits_is_miss,
  output  io_msStatus_13_valid,
  output  [11:0] io_msStatus_13_bits_set,
  output  [27:0] io_msStatus_13_bits_tag,
  output  [6:0] io_msStatus_13_bits_opcode,
  output  io_msStatus_13_bits_is_miss,
  output  io_msStatus_14_valid,
  output  [11:0] io_msStatus_14_bits_set,
  output  [27:0] io_msStatus_14_bits_tag,
  output  [6:0] io_msStatus_14_bits_opcode,
  output  io_msStatus_14_bits_is_miss,
  output  io_msStatus_15_valid,
  output  [11:0] io_msStatus_15_bits_set,
  output  [27:0] io_msStatus_15_bits_tag,
  output  [6:0] io_msStatus_15_bits_opcode,
  output  io_msStatus_15_bits_is_miss,
  output  io_l3Miss
);
  assign io_in_tx_req_ready = '0;
  assign io_in_rx_rsp_valid = '0;
  assign io_in_rx_rsp_bits_tgtID = '0;
  assign io_in_rx_rsp_bits_srcID = '0;
  assign io_in_rx_rsp_bits_txnID = '0;
  assign io_in_rx_rsp_bits_opcode = '0;
  assign io_in_rx_rsp_bits_resp = '0;
  assign io_in_rx_rsp_bits_fwdState = '0;
  assign io_in_rx_rsp_bits_dbID = '0;
  assign io_in_rx_rsp_bits_pCrdType = '0;
  assign io_in_rx_dat_valid = '0;
  assign io_in_rx_dat_bits_tgtID = '0;
  assign io_in_rx_dat_bits_srcID = '0;
  assign io_in_rx_dat_bits_txnID = '0;
  assign io_in_rx_dat_bits_homeNID = '0;
  assign io_in_rx_dat_bits_opcode = '0;
  assign io_in_rx_dat_bits_resp = '0;
  assign io_in_rx_dat_bits_dataSource = '0;
  assign io_in_rx_dat_bits_dbID = '0;
  assign io_in_rx_dat_bits_dataID = '0;
  assign io_in_rx_dat_bits_be = '0;
  assign io_in_rx_dat_bits_data = '0;
  assign io_in_rx_dat_bits_dataCheck = '0;
  assign io_in_rx_snp_valid = '0;
  assign io_in_rx_snp_bits_txnID = '0;
  assign io_in_rx_snp_bits_fwdNID = '0;
  assign io_in_rx_snp_bits_fwdTxnID = '0;
  assign io_in_rx_snp_bits_opcode = '0;
  assign io_in_rx_snp_bits_addr = '0;
  assign io_in_rx_snp_bits_doNotGoToSD = '0;
  assign io_in_rx_snp_bits_retToSrc = '0;
  assign io_out_tx_req_valid = '0;
  assign io_out_tx_req_bits_tgtID = '0;
  assign io_out_tx_req_bits_srcID = '0;
  assign io_out_tx_req_bits_txnID = '0;
  assign io_out_tx_req_bits_opcode = '0;
  assign io_out_tx_req_bits_size = '0;
  assign io_out_tx_req_bits_addr = '0;
  assign io_out_tx_req_bits_allowRetry = '0;
  assign io_out_tx_req_bits_order = '0;
  assign io_out_tx_req_bits_pCrdType = '0;
  assign io_out_tx_req_bits_memAttr_allocate = '0;
  assign io_out_tx_req_bits_memAttr_cacheable = '0;
  assign io_out_tx_req_bits_memAttr_device = '0;
  assign io_out_tx_req_bits_memAttr_ewa = '0;
  assign io_out_tx_req_bits_snpAttr = '0;
  assign io_out_tx_req_bits_expCompAck = '0;
  assign io_out_tx_dat_valid = '0;
  assign io_out_tx_dat_bits_tgtID = '0;
  assign io_out_tx_dat_bits_srcID = '0;
  assign io_out_tx_dat_bits_txnID = '0;
  assign io_out_tx_dat_bits_homeNID = '0;
  assign io_out_tx_dat_bits_opcode = '0;
  assign io_out_tx_dat_bits_resp = '0;
  assign io_out_tx_dat_bits_dataSource = '0;
  assign io_out_tx_dat_bits_dbID = '0;
  assign io_out_tx_dat_bits_dataID = '0;
  assign io_out_tx_dat_bits_be = '0;
  assign io_out_tx_dat_bits_data = '0;
  assign io_out_tx_dat_bits_dataCheck = '0;
  assign io_snpMask_0 = '0;
  assign io_msStatus_0_valid = '0;
  assign io_msStatus_0_bits_set = '0;
  assign io_msStatus_0_bits_tag = '0;
  assign io_msStatus_0_bits_opcode = '0;
  assign io_msStatus_0_bits_is_miss = '0;
  assign io_msStatus_1_valid = '0;
  assign io_msStatus_1_bits_set = '0;
  assign io_msStatus_1_bits_tag = '0;
  assign io_msStatus_1_bits_opcode = '0;
  assign io_msStatus_1_bits_is_miss = '0;
  assign io_msStatus_2_valid = '0;
  assign io_msStatus_2_bits_set = '0;
  assign io_msStatus_2_bits_tag = '0;
  assign io_msStatus_2_bits_opcode = '0;
  assign io_msStatus_2_bits_is_miss = '0;
  assign io_msStatus_3_valid = '0;
  assign io_msStatus_3_bits_set = '0;
  assign io_msStatus_3_bits_tag = '0;
  assign io_msStatus_3_bits_opcode = '0;
  assign io_msStatus_3_bits_is_miss = '0;
  assign io_msStatus_4_valid = '0;
  assign io_msStatus_4_bits_set = '0;
  assign io_msStatus_4_bits_tag = '0;
  assign io_msStatus_4_bits_opcode = '0;
  assign io_msStatus_4_bits_is_miss = '0;
  assign io_msStatus_5_valid = '0;
  assign io_msStatus_5_bits_set = '0;
  assign io_msStatus_5_bits_tag = '0;
  assign io_msStatus_5_bits_opcode = '0;
  assign io_msStatus_5_bits_is_miss = '0;
  assign io_msStatus_6_valid = '0;
  assign io_msStatus_6_bits_set = '0;
  assign io_msStatus_6_bits_tag = '0;
  assign io_msStatus_6_bits_opcode = '0;
  assign io_msStatus_6_bits_is_miss = '0;
  assign io_msStatus_7_valid = '0;
  assign io_msStatus_7_bits_set = '0;
  assign io_msStatus_7_bits_tag = '0;
  assign io_msStatus_7_bits_opcode = '0;
  assign io_msStatus_7_bits_is_miss = '0;
  assign io_msStatus_8_valid = '0;
  assign io_msStatus_8_bits_set = '0;
  assign io_msStatus_8_bits_tag = '0;
  assign io_msStatus_8_bits_opcode = '0;
  assign io_msStatus_8_bits_is_miss = '0;
  assign io_msStatus_9_valid = '0;
  assign io_msStatus_9_bits_set = '0;
  assign io_msStatus_9_bits_tag = '0;
  assign io_msStatus_9_bits_opcode = '0;
  assign io_msStatus_9_bits_is_miss = '0;
  assign io_msStatus_10_valid = '0;
  assign io_msStatus_10_bits_set = '0;
  assign io_msStatus_10_bits_tag = '0;
  assign io_msStatus_10_bits_opcode = '0;
  assign io_msStatus_10_bits_is_miss = '0;
  assign io_msStatus_11_valid = '0;
  assign io_msStatus_11_bits_set = '0;
  assign io_msStatus_11_bits_tag = '0;
  assign io_msStatus_11_bits_opcode = '0;
  assign io_msStatus_11_bits_is_miss = '0;
  assign io_msStatus_12_valid = '0;
  assign io_msStatus_12_bits_set = '0;
  assign io_msStatus_12_bits_tag = '0;
  assign io_msStatus_12_bits_opcode = '0;
  assign io_msStatus_12_bits_is_miss = '0;
  assign io_msStatus_13_valid = '0;
  assign io_msStatus_13_bits_set = '0;
  assign io_msStatus_13_bits_tag = '0;
  assign io_msStatus_13_bits_opcode = '0;
  assign io_msStatus_13_bits_is_miss = '0;
  assign io_msStatus_14_valid = '0;
  assign io_msStatus_14_bits_set = '0;
  assign io_msStatus_14_bits_tag = '0;
  assign io_msStatus_14_bits_opcode = '0;
  assign io_msStatus_14_bits_is_miss = '0;
  assign io_msStatus_15_valid = '0;
  assign io_msStatus_15_bits_set = '0;
  assign io_msStatus_15_bits_tag = '0;
  assign io_msStatus_15_bits_opcode = '0;
  assign io_msStatus_15_bits_is_miss = '0;
  assign io_l3Miss = '0;
endmodule

module TopDownMonitor_1(
  input  io_msStatus_0_0_valid,
  input  [11:0] io_msStatus_0_0_bits_set,
  input  [27:0] io_msStatus_0_0_bits_tag,
  input  [6:0] io_msStatus_0_0_bits_opcode,
  input  io_msStatus_0_0_bits_is_miss,
  input  io_msStatus_0_1_valid,
  input  [11:0] io_msStatus_0_1_bits_set,
  input  [27:0] io_msStatus_0_1_bits_tag,
  input  [6:0] io_msStatus_0_1_bits_opcode,
  input  io_msStatus_0_1_bits_is_miss,
  input  io_msStatus_0_2_valid,
  input  [11:0] io_msStatus_0_2_bits_set,
  input  [27:0] io_msStatus_0_2_bits_tag,
  input  [6:0] io_msStatus_0_2_bits_opcode,
  input  io_msStatus_0_2_bits_is_miss,
  input  io_msStatus_0_3_valid,
  input  [11:0] io_msStatus_0_3_bits_set,
  input  [27:0] io_msStatus_0_3_bits_tag,
  input  [6:0] io_msStatus_0_3_bits_opcode,
  input  io_msStatus_0_3_bits_is_miss,
  input  io_msStatus_0_4_valid,
  input  [11:0] io_msStatus_0_4_bits_set,
  input  [27:0] io_msStatus_0_4_bits_tag,
  input  [6:0] io_msStatus_0_4_bits_opcode,
  input  io_msStatus_0_4_bits_is_miss,
  input  io_msStatus_0_5_valid,
  input  [11:0] io_msStatus_0_5_bits_set,
  input  [27:0] io_msStatus_0_5_bits_tag,
  input  [6:0] io_msStatus_0_5_bits_opcode,
  input  io_msStatus_0_5_bits_is_miss,
  input  io_msStatus_0_6_valid,
  input  [11:0] io_msStatus_0_6_bits_set,
  input  [27:0] io_msStatus_0_6_bits_tag,
  input  [6:0] io_msStatus_0_6_bits_opcode,
  input  io_msStatus_0_6_bits_is_miss,
  input  io_msStatus_0_7_valid,
  input  [11:0] io_msStatus_0_7_bits_set,
  input  [27:0] io_msStatus_0_7_bits_tag,
  input  [6:0] io_msStatus_0_7_bits_opcode,
  input  io_msStatus_0_7_bits_is_miss,
  input  io_msStatus_0_8_valid,
  input  [11:0] io_msStatus_0_8_bits_set,
  input  [27:0] io_msStatus_0_8_bits_tag,
  input  [6:0] io_msStatus_0_8_bits_opcode,
  input  io_msStatus_0_8_bits_is_miss,
  input  io_msStatus_0_9_valid,
  input  [11:0] io_msStatus_0_9_bits_set,
  input  [27:0] io_msStatus_0_9_bits_tag,
  input  [6:0] io_msStatus_0_9_bits_opcode,
  input  io_msStatus_0_9_bits_is_miss,
  input  io_msStatus_0_10_valid,
  input  [11:0] io_msStatus_0_10_bits_set,
  input  [27:0] io_msStatus_0_10_bits_tag,
  input  [6:0] io_msStatus_0_10_bits_opcode,
  input  io_msStatus_0_10_bits_is_miss,
  input  io_msStatus_0_11_valid,
  input  [11:0] io_msStatus_0_11_bits_set,
  input  [27:0] io_msStatus_0_11_bits_tag,
  input  [6:0] io_msStatus_0_11_bits_opcode,
  input  io_msStatus_0_11_bits_is_miss,
  input  io_msStatus_0_12_valid,
  input  [11:0] io_msStatus_0_12_bits_set,
  input  [27:0] io_msStatus_0_12_bits_tag,
  input  [6:0] io_msStatus_0_12_bits_opcode,
  input  io_msStatus_0_12_bits_is_miss,
  input  io_msStatus_0_13_valid,
  input  [11:0] io_msStatus_0_13_bits_set,
  input  [27:0] io_msStatus_0_13_bits_tag,
  input  [6:0] io_msStatus_0_13_bits_opcode,
  input  io_msStatus_0_13_bits_is_miss,
  input  io_msStatus_0_14_valid,
  input  [11:0] io_msStatus_0_14_bits_set,
  input  [27:0] io_msStatus_0_14_bits_tag,
  input  [6:0] io_msStatus_0_14_bits_opcode,
  input  io_msStatus_0_14_bits_is_miss,
  input  io_msStatus_0_15_valid,
  input  [11:0] io_msStatus_0_15_bits_set,
  input  [27:0] io_msStatus_0_15_bits_tag,
  input  [6:0] io_msStatus_0_15_bits_opcode,
  input  io_msStatus_0_15_bits_is_miss,
  input  io_msStatus_1_0_valid,
  input  [11:0] io_msStatus_1_0_bits_set,
  input  [27:0] io_msStatus_1_0_bits_tag,
  input  [6:0] io_msStatus_1_0_bits_opcode,
  input  io_msStatus_1_0_bits_is_miss,
  input  io_msStatus_1_1_valid,
  input  [11:0] io_msStatus_1_1_bits_set,
  input  [27:0] io_msStatus_1_1_bits_tag,
  input  [6:0] io_msStatus_1_1_bits_opcode,
  input  io_msStatus_1_1_bits_is_miss,
  input  io_msStatus_1_2_valid,
  input  [11:0] io_msStatus_1_2_bits_set,
  input  [27:0] io_msStatus_1_2_bits_tag,
  input  [6:0] io_msStatus_1_2_bits_opcode,
  input  io_msStatus_1_2_bits_is_miss,
  input  io_msStatus_1_3_valid,
  input  [11:0] io_msStatus_1_3_bits_set,
  input  [27:0] io_msStatus_1_3_bits_tag,
  input  [6:0] io_msStatus_1_3_bits_opcode,
  input  io_msStatus_1_3_bits_is_miss,
  input  io_msStatus_1_4_valid,
  input  [11:0] io_msStatus_1_4_bits_set,
  input  [27:0] io_msStatus_1_4_bits_tag,
  input  [6:0] io_msStatus_1_4_bits_opcode,
  input  io_msStatus_1_4_bits_is_miss,
  input  io_msStatus_1_5_valid,
  input  [11:0] io_msStatus_1_5_bits_set,
  input  [27:0] io_msStatus_1_5_bits_tag,
  input  [6:0] io_msStatus_1_5_bits_opcode,
  input  io_msStatus_1_5_bits_is_miss,
  input  io_msStatus_1_6_valid,
  input  [11:0] io_msStatus_1_6_bits_set,
  input  [27:0] io_msStatus_1_6_bits_tag,
  input  [6:0] io_msStatus_1_6_bits_opcode,
  input  io_msStatus_1_6_bits_is_miss,
  input  io_msStatus_1_7_valid,
  input  [11:0] io_msStatus_1_7_bits_set,
  input  [27:0] io_msStatus_1_7_bits_tag,
  input  [6:0] io_msStatus_1_7_bits_opcode,
  input  io_msStatus_1_7_bits_is_miss,
  input  io_msStatus_1_8_valid,
  input  [11:0] io_msStatus_1_8_bits_set,
  input  [27:0] io_msStatus_1_8_bits_tag,
  input  [6:0] io_msStatus_1_8_bits_opcode,
  input  io_msStatus_1_8_bits_is_miss,
  input  io_msStatus_1_9_valid,
  input  [11:0] io_msStatus_1_9_bits_set,
  input  [27:0] io_msStatus_1_9_bits_tag,
  input  [6:0] io_msStatus_1_9_bits_opcode,
  input  io_msStatus_1_9_bits_is_miss,
  input  io_msStatus_1_10_valid,
  input  [11:0] io_msStatus_1_10_bits_set,
  input  [27:0] io_msStatus_1_10_bits_tag,
  input  [6:0] io_msStatus_1_10_bits_opcode,
  input  io_msStatus_1_10_bits_is_miss,
  input  io_msStatus_1_11_valid,
  input  [11:0] io_msStatus_1_11_bits_set,
  input  [27:0] io_msStatus_1_11_bits_tag,
  input  [6:0] io_msStatus_1_11_bits_opcode,
  input  io_msStatus_1_11_bits_is_miss,
  input  io_msStatus_1_12_valid,
  input  [11:0] io_msStatus_1_12_bits_set,
  input  [27:0] io_msStatus_1_12_bits_tag,
  input  [6:0] io_msStatus_1_12_bits_opcode,
  input  io_msStatus_1_12_bits_is_miss,
  input  io_msStatus_1_13_valid,
  input  [11:0] io_msStatus_1_13_bits_set,
  input  [27:0] io_msStatus_1_13_bits_tag,
  input  [6:0] io_msStatus_1_13_bits_opcode,
  input  io_msStatus_1_13_bits_is_miss,
  input  io_msStatus_1_14_valid,
  input  [11:0] io_msStatus_1_14_bits_set,
  input  [27:0] io_msStatus_1_14_bits_tag,
  input  [6:0] io_msStatus_1_14_bits_opcode,
  input  io_msStatus_1_14_bits_is_miss,
  input  io_msStatus_1_15_valid,
  input  [11:0] io_msStatus_1_15_bits_set,
  input  [27:0] io_msStatus_1_15_bits_tag,
  input  [6:0] io_msStatus_1_15_bits_opcode,
  input  io_msStatus_1_15_bits_is_miss,
  input  io_msStatus_2_0_valid,
  input  [11:0] io_msStatus_2_0_bits_set,
  input  [27:0] io_msStatus_2_0_bits_tag,
  input  [6:0] io_msStatus_2_0_bits_opcode,
  input  io_msStatus_2_0_bits_is_miss,
  input  io_msStatus_2_1_valid,
  input  [11:0] io_msStatus_2_1_bits_set,
  input  [27:0] io_msStatus_2_1_bits_tag,
  input  [6:0] io_msStatus_2_1_bits_opcode,
  input  io_msStatus_2_1_bits_is_miss,
  input  io_msStatus_2_2_valid,
  input  [11:0] io_msStatus_2_2_bits_set,
  input  [27:0] io_msStatus_2_2_bits_tag,
  input  [6:0] io_msStatus_2_2_bits_opcode,
  input  io_msStatus_2_2_bits_is_miss,
  input  io_msStatus_2_3_valid,
  input  [11:0] io_msStatus_2_3_bits_set,
  input  [27:0] io_msStatus_2_3_bits_tag,
  input  [6:0] io_msStatus_2_3_bits_opcode,
  input  io_msStatus_2_3_bits_is_miss,
  input  io_msStatus_2_4_valid,
  input  [11:0] io_msStatus_2_4_bits_set,
  input  [27:0] io_msStatus_2_4_bits_tag,
  input  [6:0] io_msStatus_2_4_bits_opcode,
  input  io_msStatus_2_4_bits_is_miss,
  input  io_msStatus_2_5_valid,
  input  [11:0] io_msStatus_2_5_bits_set,
  input  [27:0] io_msStatus_2_5_bits_tag,
  input  [6:0] io_msStatus_2_5_bits_opcode,
  input  io_msStatus_2_5_bits_is_miss,
  input  io_msStatus_2_6_valid,
  input  [11:0] io_msStatus_2_6_bits_set,
  input  [27:0] io_msStatus_2_6_bits_tag,
  input  [6:0] io_msStatus_2_6_bits_opcode,
  input  io_msStatus_2_6_bits_is_miss,
  input  io_msStatus_2_7_valid,
  input  [11:0] io_msStatus_2_7_bits_set,
  input  [27:0] io_msStatus_2_7_bits_tag,
  input  [6:0] io_msStatus_2_7_bits_opcode,
  input  io_msStatus_2_7_bits_is_miss,
  input  io_msStatus_2_8_valid,
  input  [11:0] io_msStatus_2_8_bits_set,
  input  [27:0] io_msStatus_2_8_bits_tag,
  input  [6:0] io_msStatus_2_8_bits_opcode,
  input  io_msStatus_2_8_bits_is_miss,
  input  io_msStatus_2_9_valid,
  input  [11:0] io_msStatus_2_9_bits_set,
  input  [27:0] io_msStatus_2_9_bits_tag,
  input  [6:0] io_msStatus_2_9_bits_opcode,
  input  io_msStatus_2_9_bits_is_miss,
  input  io_msStatus_2_10_valid,
  input  [11:0] io_msStatus_2_10_bits_set,
  input  [27:0] io_msStatus_2_10_bits_tag,
  input  [6:0] io_msStatus_2_10_bits_opcode,
  input  io_msStatus_2_10_bits_is_miss,
  input  io_msStatus_2_11_valid,
  input  [11:0] io_msStatus_2_11_bits_set,
  input  [27:0] io_msStatus_2_11_bits_tag,
  input  [6:0] io_msStatus_2_11_bits_opcode,
  input  io_msStatus_2_11_bits_is_miss,
  input  io_msStatus_2_12_valid,
  input  [11:0] io_msStatus_2_12_bits_set,
  input  [27:0] io_msStatus_2_12_bits_tag,
  input  [6:0] io_msStatus_2_12_bits_opcode,
  input  io_msStatus_2_12_bits_is_miss,
  input  io_msStatus_2_13_valid,
  input  [11:0] io_msStatus_2_13_bits_set,
  input  [27:0] io_msStatus_2_13_bits_tag,
  input  [6:0] io_msStatus_2_13_bits_opcode,
  input  io_msStatus_2_13_bits_is_miss,
  input  io_msStatus_2_14_valid,
  input  [11:0] io_msStatus_2_14_bits_set,
  input  [27:0] io_msStatus_2_14_bits_tag,
  input  [6:0] io_msStatus_2_14_bits_opcode,
  input  io_msStatus_2_14_bits_is_miss,
  input  io_msStatus_2_15_valid,
  input  [11:0] io_msStatus_2_15_bits_set,
  input  [27:0] io_msStatus_2_15_bits_tag,
  input  [6:0] io_msStatus_2_15_bits_opcode,
  input  io_msStatus_2_15_bits_is_miss,
  input  io_msStatus_3_0_valid,
  input  [11:0] io_msStatus_3_0_bits_set,
  input  [27:0] io_msStatus_3_0_bits_tag,
  input  [6:0] io_msStatus_3_0_bits_opcode,
  input  io_msStatus_3_0_bits_is_miss,
  input  io_msStatus_3_1_valid,
  input  [11:0] io_msStatus_3_1_bits_set,
  input  [27:0] io_msStatus_3_1_bits_tag,
  input  [6:0] io_msStatus_3_1_bits_opcode,
  input  io_msStatus_3_1_bits_is_miss,
  input  io_msStatus_3_2_valid,
  input  [11:0] io_msStatus_3_2_bits_set,
  input  [27:0] io_msStatus_3_2_bits_tag,
  input  [6:0] io_msStatus_3_2_bits_opcode,
  input  io_msStatus_3_2_bits_is_miss,
  input  io_msStatus_3_3_valid,
  input  [11:0] io_msStatus_3_3_bits_set,
  input  [27:0] io_msStatus_3_3_bits_tag,
  input  [6:0] io_msStatus_3_3_bits_opcode,
  input  io_msStatus_3_3_bits_is_miss,
  input  io_msStatus_3_4_valid,
  input  [11:0] io_msStatus_3_4_bits_set,
  input  [27:0] io_msStatus_3_4_bits_tag,
  input  [6:0] io_msStatus_3_4_bits_opcode,
  input  io_msStatus_3_4_bits_is_miss,
  input  io_msStatus_3_5_valid,
  input  [11:0] io_msStatus_3_5_bits_set,
  input  [27:0] io_msStatus_3_5_bits_tag,
  input  [6:0] io_msStatus_3_5_bits_opcode,
  input  io_msStatus_3_5_bits_is_miss,
  input  io_msStatus_3_6_valid,
  input  [11:0] io_msStatus_3_6_bits_set,
  input  [27:0] io_msStatus_3_6_bits_tag,
  input  [6:0] io_msStatus_3_6_bits_opcode,
  input  io_msStatus_3_6_bits_is_miss,
  input  io_msStatus_3_7_valid,
  input  [11:0] io_msStatus_3_7_bits_set,
  input  [27:0] io_msStatus_3_7_bits_tag,
  input  [6:0] io_msStatus_3_7_bits_opcode,
  input  io_msStatus_3_7_bits_is_miss,
  input  io_msStatus_3_8_valid,
  input  [11:0] io_msStatus_3_8_bits_set,
  input  [27:0] io_msStatus_3_8_bits_tag,
  input  [6:0] io_msStatus_3_8_bits_opcode,
  input  io_msStatus_3_8_bits_is_miss,
  input  io_msStatus_3_9_valid,
  input  [11:0] io_msStatus_3_9_bits_set,
  input  [27:0] io_msStatus_3_9_bits_tag,
  input  [6:0] io_msStatus_3_9_bits_opcode,
  input  io_msStatus_3_9_bits_is_miss,
  input  io_msStatus_3_10_valid,
  input  [11:0] io_msStatus_3_10_bits_set,
  input  [27:0] io_msStatus_3_10_bits_tag,
  input  [6:0] io_msStatus_3_10_bits_opcode,
  input  io_msStatus_3_10_bits_is_miss,
  input  io_msStatus_3_11_valid,
  input  [11:0] io_msStatus_3_11_bits_set,
  input  [27:0] io_msStatus_3_11_bits_tag,
  input  [6:0] io_msStatus_3_11_bits_opcode,
  input  io_msStatus_3_11_bits_is_miss,
  input  io_msStatus_3_12_valid,
  input  [11:0] io_msStatus_3_12_bits_set,
  input  [27:0] io_msStatus_3_12_bits_tag,
  input  [6:0] io_msStatus_3_12_bits_opcode,
  input  io_msStatus_3_12_bits_is_miss,
  input  io_msStatus_3_13_valid,
  input  [11:0] io_msStatus_3_13_bits_set,
  input  [27:0] io_msStatus_3_13_bits_tag,
  input  [6:0] io_msStatus_3_13_bits_opcode,
  input  io_msStatus_3_13_bits_is_miss,
  input  io_msStatus_3_14_valid,
  input  [11:0] io_msStatus_3_14_bits_set,
  input  [27:0] io_msStatus_3_14_bits_tag,
  input  [6:0] io_msStatus_3_14_bits_opcode,
  input  io_msStatus_3_14_bits_is_miss,
  input  io_msStatus_3_15_valid,
  input  [11:0] io_msStatus_3_15_bits_set,
  input  [27:0] io_msStatus_3_15_bits_tag,
  input  [6:0] io_msStatus_3_15_bits_opcode,
  input  io_msStatus_3_15_bits_is_miss,
  input  io_debugTopDown_robHeadPaddr_0_valid,
  input  [47:0] io_debugTopDown_robHeadPaddr_0_bits,
  output  io_debugTopDown_addrMatch_0
);
  assign io_debugTopDown_addrMatch_0 = '0;
endmodule


// 自动生成: gen_mmio_ut.py —— 勿手改
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP = 16;
  bit clk=0, rst;
  int errors=0, checks=0, cyc=0;
  always #5 clk = ~clk;

  logic auto_mmio_in_a_valid;
  logic [3:0] auto_mmio_in_a_bits_opcode;
  logic [2:0] auto_mmio_in_a_bits_param;
  logic [1:0] auto_mmio_in_a_bits_size;
  logic [2:0] auto_mmio_in_a_bits_source;
  logic [47:0] auto_mmio_in_a_bits_address;
  logic auto_mmio_in_a_bits_user_memBackType_MM;
  logic auto_mmio_in_a_bits_user_memPageType_NC;
  logic [7:0] auto_mmio_in_a_bits_mask;
  logic [63:0] auto_mmio_in_a_bits_data;
  logic auto_mmio_in_a_bits_corrupt;
  logic auto_mmio_in_d_ready;
  logic io_tx_req_ready;
  logic io_tx_dat_ready;
  logic io_rx_rsp_valid;
  logic [3:0] io_rx_rsp_bits_qos;
  logic [10:0] io_rx_rsp_bits_tgtID;
  logic [10:0] io_rx_rsp_bits_srcID;
  logic [11:0] io_rx_rsp_bits_txnID;
  logic [4:0] io_rx_rsp_bits_opcode;
  logic [1:0] io_rx_rsp_bits_respErr;
  logic [2:0] io_rx_rsp_bits_resp;
  logic [2:0] io_rx_rsp_bits_fwdState;
  logic [2:0] io_rx_rsp_bits_cBusy;
  logic [11:0] io_rx_rsp_bits_dbID;
  logic [3:0] io_rx_rsp_bits_pCrdType;
  logic [1:0] io_rx_rsp_bits_tagOp;
  logic io_rx_rsp_bits_traceTag;
  logic io_rx_dat_valid;
  logic [3:0] io_rx_dat_bits_qos;
  logic [10:0] io_rx_dat_bits_tgtID;
  logic [10:0] io_rx_dat_bits_srcID;
  logic [11:0] io_rx_dat_bits_txnID;
  logic [10:0] io_rx_dat_bits_homeNID;
  logic [3:0] io_rx_dat_bits_opcode;
  logic [1:0] io_rx_dat_bits_respErr;
  logic [2:0] io_rx_dat_bits_resp;
  logic [3:0] io_rx_dat_bits_dataSource;
  logic [2:0] io_rx_dat_bits_cBusy;
  logic [11:0] io_rx_dat_bits_dbID;
  logic [1:0] io_rx_dat_bits_ccID;
  logic [1:0] io_rx_dat_bits_dataID;
  logic [1:0] io_rx_dat_bits_tagOp;
  logic [7:0] io_rx_dat_bits_tag;
  logic [1:0] io_rx_dat_bits_tu;
  logic io_rx_dat_bits_traceTag;
  logic [3:0] io_rx_dat_bits_rsvdc;
  logic [31:0] io_rx_dat_bits_be;
  logic [255:0] io_rx_dat_bits_data;
  logic [31:0] io_rx_dat_bits_dataCheck;
  logic [3:0] io_rx_dat_bits_poison;
  logic io_pCrd_0_grant;
  logic io_pCrd_1_grant;
  logic io_pCrd_2_grant;
  logic io_pCrd_3_grant;
  logic io_pCrd_4_grant;
  logic io_pCrd_5_grant;
  logic io_pCrd_6_grant;
  logic io_pCrd_7_grant;
  logic g_auto_mmio_in_a_ready;
  logic i_auto_mmio_in_a_ready;
  logic g_auto_mmio_in_d_valid;
  logic i_auto_mmio_in_d_valid;
  logic [3:0] g_auto_mmio_in_d_bits_opcode;
  logic [3:0] i_auto_mmio_in_d_bits_opcode;
  logic [1:0] g_auto_mmio_in_d_bits_param;
  logic [1:0] i_auto_mmio_in_d_bits_param;
  logic [1:0] g_auto_mmio_in_d_bits_size;
  logic [1:0] i_auto_mmio_in_d_bits_size;
  logic [2:0] g_auto_mmio_in_d_bits_source;
  logic [2:0] i_auto_mmio_in_d_bits_source;
  logic g_auto_mmio_in_d_bits_sink;
  logic i_auto_mmio_in_d_bits_sink;
  logic g_auto_mmio_in_d_bits_denied;
  logic i_auto_mmio_in_d_bits_denied;
  logic [63:0] g_auto_mmio_in_d_bits_data;
  logic [63:0] i_auto_mmio_in_d_bits_data;
  logic g_auto_mmio_in_d_bits_corrupt;
  logic i_auto_mmio_in_d_bits_corrupt;
  logic g_io_tx_req_valid;
  logic i_io_tx_req_valid;
  logic [3:0] g_io_tx_req_bits_qos;
  logic [3:0] i_io_tx_req_bits_qos;
  logic [10:0] g_io_tx_req_bits_tgtID;
  logic [10:0] i_io_tx_req_bits_tgtID;
  logic [10:0] g_io_tx_req_bits_srcID;
  logic [10:0] i_io_tx_req_bits_srcID;
  logic [11:0] g_io_tx_req_bits_txnID;
  logic [11:0] i_io_tx_req_bits_txnID;
  logic [10:0] g_io_tx_req_bits_returnNID;
  logic [10:0] i_io_tx_req_bits_returnNID;
  logic g_io_tx_req_bits_stashNIDValid;
  logic i_io_tx_req_bits_stashNIDValid;
  logic [11:0] g_io_tx_req_bits_returnTxnID;
  logic [11:0] i_io_tx_req_bits_returnTxnID;
  logic [6:0] g_io_tx_req_bits_opcode;
  logic [6:0] i_io_tx_req_bits_opcode;
  logic [2:0] g_io_tx_req_bits_size;
  logic [2:0] i_io_tx_req_bits_size;
  logic [47:0] g_io_tx_req_bits_addr;
  logic [47:0] i_io_tx_req_bits_addr;
  logic g_io_tx_req_bits_ns;
  logic i_io_tx_req_bits_ns;
  logic g_io_tx_req_bits_likelyshared;
  logic i_io_tx_req_bits_likelyshared;
  logic g_io_tx_req_bits_allowRetry;
  logic i_io_tx_req_bits_allowRetry;
  logic [1:0] g_io_tx_req_bits_order;
  logic [1:0] i_io_tx_req_bits_order;
  logic [3:0] g_io_tx_req_bits_pCrdType;
  logic [3:0] i_io_tx_req_bits_pCrdType;
  logic g_io_tx_req_bits_memAttr_allocate;
  logic i_io_tx_req_bits_memAttr_allocate;
  logic g_io_tx_req_bits_memAttr_cacheable;
  logic i_io_tx_req_bits_memAttr_cacheable;
  logic g_io_tx_req_bits_memAttr_device;
  logic i_io_tx_req_bits_memAttr_device;
  logic g_io_tx_req_bits_memAttr_ewa;
  logic i_io_tx_req_bits_memAttr_ewa;
  logic g_io_tx_req_bits_snpAttr;
  logic i_io_tx_req_bits_snpAttr;
  logic [7:0] g_io_tx_req_bits_lpIDWithPadding;
  logic [7:0] i_io_tx_req_bits_lpIDWithPadding;
  logic g_io_tx_req_bits_snoopMe;
  logic i_io_tx_req_bits_snoopMe;
  logic g_io_tx_req_bits_expCompAck;
  logic i_io_tx_req_bits_expCompAck;
  logic [1:0] g_io_tx_req_bits_tagOp;
  logic [1:0] i_io_tx_req_bits_tagOp;
  logic g_io_tx_req_bits_traceTag;
  logic i_io_tx_req_bits_traceTag;
  logic g_io_tx_req_bits_mpam_perfMonGroup;
  logic i_io_tx_req_bits_mpam_perfMonGroup;
  logic [8:0] g_io_tx_req_bits_mpam_partID;
  logic [8:0] i_io_tx_req_bits_mpam_partID;
  logic g_io_tx_req_bits_mpam_mpamNS;
  logic i_io_tx_req_bits_mpam_mpamNS;
  logic [3:0] g_io_tx_req_bits_rsvdc;
  logic [3:0] i_io_tx_req_bits_rsvdc;
  logic g_io_tx_dat_valid;
  logic i_io_tx_dat_valid;
  logic [3:0] g_io_tx_dat_bits_qos;
  logic [3:0] i_io_tx_dat_bits_qos;
  logic [10:0] g_io_tx_dat_bits_tgtID;
  logic [10:0] i_io_tx_dat_bits_tgtID;
  logic [10:0] g_io_tx_dat_bits_srcID;
  logic [10:0] i_io_tx_dat_bits_srcID;
  logic [11:0] g_io_tx_dat_bits_txnID;
  logic [11:0] i_io_tx_dat_bits_txnID;
  logic [10:0] g_io_tx_dat_bits_homeNID;
  logic [10:0] i_io_tx_dat_bits_homeNID;
  logic [3:0] g_io_tx_dat_bits_opcode;
  logic [3:0] i_io_tx_dat_bits_opcode;
  logic [1:0] g_io_tx_dat_bits_respErr;
  logic [1:0] i_io_tx_dat_bits_respErr;
  logic [2:0] g_io_tx_dat_bits_resp;
  logic [2:0] i_io_tx_dat_bits_resp;
  logic [3:0] g_io_tx_dat_bits_dataSource;
  logic [3:0] i_io_tx_dat_bits_dataSource;
  logic [2:0] g_io_tx_dat_bits_cBusy;
  logic [2:0] i_io_tx_dat_bits_cBusy;
  logic [11:0] g_io_tx_dat_bits_dbID;
  logic [11:0] i_io_tx_dat_bits_dbID;
  logic [1:0] g_io_tx_dat_bits_ccID;
  logic [1:0] i_io_tx_dat_bits_ccID;
  logic [1:0] g_io_tx_dat_bits_dataID;
  logic [1:0] i_io_tx_dat_bits_dataID;
  logic [1:0] g_io_tx_dat_bits_tagOp;
  logic [1:0] i_io_tx_dat_bits_tagOp;
  logic [7:0] g_io_tx_dat_bits_tag;
  logic [7:0] i_io_tx_dat_bits_tag;
  logic [1:0] g_io_tx_dat_bits_tu;
  logic [1:0] i_io_tx_dat_bits_tu;
  logic g_io_tx_dat_bits_traceTag;
  logic i_io_tx_dat_bits_traceTag;
  logic [3:0] g_io_tx_dat_bits_rsvdc;
  logic [3:0] i_io_tx_dat_bits_rsvdc;
  logic [31:0] g_io_tx_dat_bits_be;
  logic [31:0] i_io_tx_dat_bits_be;
  logic [255:0] g_io_tx_dat_bits_data;
  logic [255:0] i_io_tx_dat_bits_data;
  logic [31:0] g_io_tx_dat_bits_dataCheck;
  logic [31:0] i_io_tx_dat_bits_dataCheck;
  logic [3:0] g_io_tx_dat_bits_poison;
  logic [3:0] i_io_tx_dat_bits_poison;
  logic g_io_rx_rsp_ready;
  logic i_io_rx_rsp_ready;
  logic g_io_rx_dat_ready;
  logic i_io_rx_dat_ready;
  logic g_io_pCrd_0_query_valid;
  logic i_io_pCrd_0_query_valid;
  logic [3:0] g_io_pCrd_0_query_bits_pCrdType;
  logic [3:0] i_io_pCrd_0_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_0_query_bits_srcID;
  logic [10:0] i_io_pCrd_0_query_bits_srcID;
  logic g_io_pCrd_1_query_valid;
  logic i_io_pCrd_1_query_valid;
  logic [3:0] g_io_pCrd_1_query_bits_pCrdType;
  logic [3:0] i_io_pCrd_1_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_1_query_bits_srcID;
  logic [10:0] i_io_pCrd_1_query_bits_srcID;
  logic g_io_pCrd_2_query_valid;
  logic i_io_pCrd_2_query_valid;
  logic [3:0] g_io_pCrd_2_query_bits_pCrdType;
  logic [3:0] i_io_pCrd_2_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_2_query_bits_srcID;
  logic [10:0] i_io_pCrd_2_query_bits_srcID;
  logic g_io_pCrd_3_query_valid;
  logic i_io_pCrd_3_query_valid;
  logic [3:0] g_io_pCrd_3_query_bits_pCrdType;
  logic [3:0] i_io_pCrd_3_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_3_query_bits_srcID;
  logic [10:0] i_io_pCrd_3_query_bits_srcID;
  logic g_io_pCrd_4_query_valid;
  logic i_io_pCrd_4_query_valid;
  logic [3:0] g_io_pCrd_4_query_bits_pCrdType;
  logic [3:0] i_io_pCrd_4_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_4_query_bits_srcID;
  logic [10:0] i_io_pCrd_4_query_bits_srcID;
  logic g_io_pCrd_5_query_valid;
  logic i_io_pCrd_5_query_valid;
  logic [3:0] g_io_pCrd_5_query_bits_pCrdType;
  logic [3:0] i_io_pCrd_5_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_5_query_bits_srcID;
  logic [10:0] i_io_pCrd_5_query_bits_srcID;
  logic g_io_pCrd_6_query_valid;
  logic i_io_pCrd_6_query_valid;
  logic [3:0] g_io_pCrd_6_query_bits_pCrdType;
  logic [3:0] i_io_pCrd_6_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_6_query_bits_srcID;
  logic [10:0] i_io_pCrd_6_query_bits_srcID;
  logic g_io_pCrd_7_query_valid;
  logic i_io_pCrd_7_query_valid;
  logic [3:0] g_io_pCrd_7_query_bits_pCrdType;
  logic [3:0] i_io_pCrd_7_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_7_query_bits_srcID;
  logic [10:0] i_io_pCrd_7_query_bits_srcID;

  MMIOBridge dut_g (
    .clock(clk),
    .reset(rst),
    .auto_mmio_in_a_valid(auto_mmio_in_a_valid),
    .auto_mmio_in_a_bits_opcode(auto_mmio_in_a_bits_opcode),
    .auto_mmio_in_a_bits_param(auto_mmio_in_a_bits_param),
    .auto_mmio_in_a_bits_size(auto_mmio_in_a_bits_size),
    .auto_mmio_in_a_bits_source(auto_mmio_in_a_bits_source),
    .auto_mmio_in_a_bits_address(auto_mmio_in_a_bits_address),
    .auto_mmio_in_a_bits_user_memBackType_MM(auto_mmio_in_a_bits_user_memBackType_MM),
    .auto_mmio_in_a_bits_user_memPageType_NC(auto_mmio_in_a_bits_user_memPageType_NC),
    .auto_mmio_in_a_bits_mask(auto_mmio_in_a_bits_mask),
    .auto_mmio_in_a_bits_data(auto_mmio_in_a_bits_data),
    .auto_mmio_in_a_bits_corrupt(auto_mmio_in_a_bits_corrupt),
    .auto_mmio_in_d_ready(auto_mmio_in_d_ready),
    .io_tx_req_ready(io_tx_req_ready),
    .io_tx_dat_ready(io_tx_dat_ready),
    .io_rx_rsp_valid(io_rx_rsp_valid),
    .io_rx_rsp_bits_qos(io_rx_rsp_bits_qos),
    .io_rx_rsp_bits_tgtID(io_rx_rsp_bits_tgtID),
    .io_rx_rsp_bits_srcID(io_rx_rsp_bits_srcID),
    .io_rx_rsp_bits_txnID(io_rx_rsp_bits_txnID),
    .io_rx_rsp_bits_opcode(io_rx_rsp_bits_opcode),
    .io_rx_rsp_bits_respErr(io_rx_rsp_bits_respErr),
    .io_rx_rsp_bits_resp(io_rx_rsp_bits_resp),
    .io_rx_rsp_bits_fwdState(io_rx_rsp_bits_fwdState),
    .io_rx_rsp_bits_cBusy(io_rx_rsp_bits_cBusy),
    .io_rx_rsp_bits_dbID(io_rx_rsp_bits_dbID),
    .io_rx_rsp_bits_pCrdType(io_rx_rsp_bits_pCrdType),
    .io_rx_rsp_bits_tagOp(io_rx_rsp_bits_tagOp),
    .io_rx_rsp_bits_traceTag(io_rx_rsp_bits_traceTag),
    .io_rx_dat_valid(io_rx_dat_valid),
    .io_rx_dat_bits_qos(io_rx_dat_bits_qos),
    .io_rx_dat_bits_tgtID(io_rx_dat_bits_tgtID),
    .io_rx_dat_bits_srcID(io_rx_dat_bits_srcID),
    .io_rx_dat_bits_txnID(io_rx_dat_bits_txnID),
    .io_rx_dat_bits_homeNID(io_rx_dat_bits_homeNID),
    .io_rx_dat_bits_opcode(io_rx_dat_bits_opcode),
    .io_rx_dat_bits_respErr(io_rx_dat_bits_respErr),
    .io_rx_dat_bits_resp(io_rx_dat_bits_resp),
    .io_rx_dat_bits_dataSource(io_rx_dat_bits_dataSource),
    .io_rx_dat_bits_cBusy(io_rx_dat_bits_cBusy),
    .io_rx_dat_bits_dbID(io_rx_dat_bits_dbID),
    .io_rx_dat_bits_ccID(io_rx_dat_bits_ccID),
    .io_rx_dat_bits_dataID(io_rx_dat_bits_dataID),
    .io_rx_dat_bits_tagOp(io_rx_dat_bits_tagOp),
    .io_rx_dat_bits_tag(io_rx_dat_bits_tag),
    .io_rx_dat_bits_tu(io_rx_dat_bits_tu),
    .io_rx_dat_bits_traceTag(io_rx_dat_bits_traceTag),
    .io_rx_dat_bits_rsvdc(io_rx_dat_bits_rsvdc),
    .io_rx_dat_bits_be(io_rx_dat_bits_be),
    .io_rx_dat_bits_data(io_rx_dat_bits_data),
    .io_rx_dat_bits_dataCheck(io_rx_dat_bits_dataCheck),
    .io_rx_dat_bits_poison(io_rx_dat_bits_poison),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .auto_mmio_in_a_ready(g_auto_mmio_in_a_ready),
    .auto_mmio_in_d_valid(g_auto_mmio_in_d_valid),
    .auto_mmio_in_d_bits_opcode(g_auto_mmio_in_d_bits_opcode),
    .auto_mmio_in_d_bits_param(g_auto_mmio_in_d_bits_param),
    .auto_mmio_in_d_bits_size(g_auto_mmio_in_d_bits_size),
    .auto_mmio_in_d_bits_source(g_auto_mmio_in_d_bits_source),
    .auto_mmio_in_d_bits_sink(g_auto_mmio_in_d_bits_sink),
    .auto_mmio_in_d_bits_denied(g_auto_mmio_in_d_bits_denied),
    .auto_mmio_in_d_bits_data(g_auto_mmio_in_d_bits_data),
    .auto_mmio_in_d_bits_corrupt(g_auto_mmio_in_d_bits_corrupt),
    .io_tx_req_valid(g_io_tx_req_valid),
    .io_tx_req_bits_qos(g_io_tx_req_bits_qos),
    .io_tx_req_bits_tgtID(g_io_tx_req_bits_tgtID),
    .io_tx_req_bits_srcID(g_io_tx_req_bits_srcID),
    .io_tx_req_bits_txnID(g_io_tx_req_bits_txnID),
    .io_tx_req_bits_returnNID(g_io_tx_req_bits_returnNID),
    .io_tx_req_bits_stashNIDValid(g_io_tx_req_bits_stashNIDValid),
    .io_tx_req_bits_returnTxnID(g_io_tx_req_bits_returnTxnID),
    .io_tx_req_bits_opcode(g_io_tx_req_bits_opcode),
    .io_tx_req_bits_size(g_io_tx_req_bits_size),
    .io_tx_req_bits_addr(g_io_tx_req_bits_addr),
    .io_tx_req_bits_ns(g_io_tx_req_bits_ns),
    .io_tx_req_bits_likelyshared(g_io_tx_req_bits_likelyshared),
    .io_tx_req_bits_allowRetry(g_io_tx_req_bits_allowRetry),
    .io_tx_req_bits_order(g_io_tx_req_bits_order),
    .io_tx_req_bits_pCrdType(g_io_tx_req_bits_pCrdType),
    .io_tx_req_bits_memAttr_allocate(g_io_tx_req_bits_memAttr_allocate),
    .io_tx_req_bits_memAttr_cacheable(g_io_tx_req_bits_memAttr_cacheable),
    .io_tx_req_bits_memAttr_device(g_io_tx_req_bits_memAttr_device),
    .io_tx_req_bits_memAttr_ewa(g_io_tx_req_bits_memAttr_ewa),
    .io_tx_req_bits_snpAttr(g_io_tx_req_bits_snpAttr),
    .io_tx_req_bits_lpIDWithPadding(g_io_tx_req_bits_lpIDWithPadding),
    .io_tx_req_bits_snoopMe(g_io_tx_req_bits_snoopMe),
    .io_tx_req_bits_expCompAck(g_io_tx_req_bits_expCompAck),
    .io_tx_req_bits_tagOp(g_io_tx_req_bits_tagOp),
    .io_tx_req_bits_traceTag(g_io_tx_req_bits_traceTag),
    .io_tx_req_bits_mpam_perfMonGroup(g_io_tx_req_bits_mpam_perfMonGroup),
    .io_tx_req_bits_mpam_partID(g_io_tx_req_bits_mpam_partID),
    .io_tx_req_bits_mpam_mpamNS(g_io_tx_req_bits_mpam_mpamNS),
    .io_tx_req_bits_rsvdc(g_io_tx_req_bits_rsvdc),
    .io_tx_dat_valid(g_io_tx_dat_valid),
    .io_tx_dat_bits_qos(g_io_tx_dat_bits_qos),
    .io_tx_dat_bits_tgtID(g_io_tx_dat_bits_tgtID),
    .io_tx_dat_bits_srcID(g_io_tx_dat_bits_srcID),
    .io_tx_dat_bits_txnID(g_io_tx_dat_bits_txnID),
    .io_tx_dat_bits_homeNID(g_io_tx_dat_bits_homeNID),
    .io_tx_dat_bits_opcode(g_io_tx_dat_bits_opcode),
    .io_tx_dat_bits_respErr(g_io_tx_dat_bits_respErr),
    .io_tx_dat_bits_resp(g_io_tx_dat_bits_resp),
    .io_tx_dat_bits_dataSource(g_io_tx_dat_bits_dataSource),
    .io_tx_dat_bits_cBusy(g_io_tx_dat_bits_cBusy),
    .io_tx_dat_bits_dbID(g_io_tx_dat_bits_dbID),
    .io_tx_dat_bits_ccID(g_io_tx_dat_bits_ccID),
    .io_tx_dat_bits_dataID(g_io_tx_dat_bits_dataID),
    .io_tx_dat_bits_tagOp(g_io_tx_dat_bits_tagOp),
    .io_tx_dat_bits_tag(g_io_tx_dat_bits_tag),
    .io_tx_dat_bits_tu(g_io_tx_dat_bits_tu),
    .io_tx_dat_bits_traceTag(g_io_tx_dat_bits_traceTag),
    .io_tx_dat_bits_rsvdc(g_io_tx_dat_bits_rsvdc),
    .io_tx_dat_bits_be(g_io_tx_dat_bits_be),
    .io_tx_dat_bits_data(g_io_tx_dat_bits_data),
    .io_tx_dat_bits_dataCheck(g_io_tx_dat_bits_dataCheck),
    .io_tx_dat_bits_poison(g_io_tx_dat_bits_poison),
    .io_rx_rsp_ready(g_io_rx_rsp_ready),
    .io_rx_dat_ready(g_io_rx_dat_ready),
    .io_pCrd_0_query_valid(g_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(g_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(g_io_pCrd_0_query_bits_srcID),
    .io_pCrd_1_query_valid(g_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(g_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(g_io_pCrd_1_query_bits_srcID),
    .io_pCrd_2_query_valid(g_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(g_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(g_io_pCrd_2_query_bits_srcID),
    .io_pCrd_3_query_valid(g_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(g_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(g_io_pCrd_3_query_bits_srcID),
    .io_pCrd_4_query_valid(g_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(g_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(g_io_pCrd_4_query_bits_srcID),
    .io_pCrd_5_query_valid(g_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(g_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(g_io_pCrd_5_query_bits_srcID),
    .io_pCrd_6_query_valid(g_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(g_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(g_io_pCrd_6_query_bits_srcID),
    .io_pCrd_7_query_valid(g_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(g_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(g_io_pCrd_7_query_bits_srcID)
  );

  MMIOBridge_xs dut_i (
    .clock(clk),
    .reset(rst),
    .auto_mmio_in_a_valid(auto_mmio_in_a_valid),
    .auto_mmio_in_a_bits_opcode(auto_mmio_in_a_bits_opcode),
    .auto_mmio_in_a_bits_param(auto_mmio_in_a_bits_param),
    .auto_mmio_in_a_bits_size(auto_mmio_in_a_bits_size),
    .auto_mmio_in_a_bits_source(auto_mmio_in_a_bits_source),
    .auto_mmio_in_a_bits_address(auto_mmio_in_a_bits_address),
    .auto_mmio_in_a_bits_user_memBackType_MM(auto_mmio_in_a_bits_user_memBackType_MM),
    .auto_mmio_in_a_bits_user_memPageType_NC(auto_mmio_in_a_bits_user_memPageType_NC),
    .auto_mmio_in_a_bits_mask(auto_mmio_in_a_bits_mask),
    .auto_mmio_in_a_bits_data(auto_mmio_in_a_bits_data),
    .auto_mmio_in_a_bits_corrupt(auto_mmio_in_a_bits_corrupt),
    .auto_mmio_in_d_ready(auto_mmio_in_d_ready),
    .io_tx_req_ready(io_tx_req_ready),
    .io_tx_dat_ready(io_tx_dat_ready),
    .io_rx_rsp_valid(io_rx_rsp_valid),
    .io_rx_rsp_bits_qos(io_rx_rsp_bits_qos),
    .io_rx_rsp_bits_tgtID(io_rx_rsp_bits_tgtID),
    .io_rx_rsp_bits_srcID(io_rx_rsp_bits_srcID),
    .io_rx_rsp_bits_txnID(io_rx_rsp_bits_txnID),
    .io_rx_rsp_bits_opcode(io_rx_rsp_bits_opcode),
    .io_rx_rsp_bits_respErr(io_rx_rsp_bits_respErr),
    .io_rx_rsp_bits_resp(io_rx_rsp_bits_resp),
    .io_rx_rsp_bits_fwdState(io_rx_rsp_bits_fwdState),
    .io_rx_rsp_bits_cBusy(io_rx_rsp_bits_cBusy),
    .io_rx_rsp_bits_dbID(io_rx_rsp_bits_dbID),
    .io_rx_rsp_bits_pCrdType(io_rx_rsp_bits_pCrdType),
    .io_rx_rsp_bits_tagOp(io_rx_rsp_bits_tagOp),
    .io_rx_rsp_bits_traceTag(io_rx_rsp_bits_traceTag),
    .io_rx_dat_valid(io_rx_dat_valid),
    .io_rx_dat_bits_qos(io_rx_dat_bits_qos),
    .io_rx_dat_bits_tgtID(io_rx_dat_bits_tgtID),
    .io_rx_dat_bits_srcID(io_rx_dat_bits_srcID),
    .io_rx_dat_bits_txnID(io_rx_dat_bits_txnID),
    .io_rx_dat_bits_homeNID(io_rx_dat_bits_homeNID),
    .io_rx_dat_bits_opcode(io_rx_dat_bits_opcode),
    .io_rx_dat_bits_respErr(io_rx_dat_bits_respErr),
    .io_rx_dat_bits_resp(io_rx_dat_bits_resp),
    .io_rx_dat_bits_dataSource(io_rx_dat_bits_dataSource),
    .io_rx_dat_bits_cBusy(io_rx_dat_bits_cBusy),
    .io_rx_dat_bits_dbID(io_rx_dat_bits_dbID),
    .io_rx_dat_bits_ccID(io_rx_dat_bits_ccID),
    .io_rx_dat_bits_dataID(io_rx_dat_bits_dataID),
    .io_rx_dat_bits_tagOp(io_rx_dat_bits_tagOp),
    .io_rx_dat_bits_tag(io_rx_dat_bits_tag),
    .io_rx_dat_bits_tu(io_rx_dat_bits_tu),
    .io_rx_dat_bits_traceTag(io_rx_dat_bits_traceTag),
    .io_rx_dat_bits_rsvdc(io_rx_dat_bits_rsvdc),
    .io_rx_dat_bits_be(io_rx_dat_bits_be),
    .io_rx_dat_bits_data(io_rx_dat_bits_data),
    .io_rx_dat_bits_dataCheck(io_rx_dat_bits_dataCheck),
    .io_rx_dat_bits_poison(io_rx_dat_bits_poison),
    .io_pCrd_0_grant(io_pCrd_0_grant),
    .io_pCrd_1_grant(io_pCrd_1_grant),
    .io_pCrd_2_grant(io_pCrd_2_grant),
    .io_pCrd_3_grant(io_pCrd_3_grant),
    .io_pCrd_4_grant(io_pCrd_4_grant),
    .io_pCrd_5_grant(io_pCrd_5_grant),
    .io_pCrd_6_grant(io_pCrd_6_grant),
    .io_pCrd_7_grant(io_pCrd_7_grant),
    .auto_mmio_in_a_ready(i_auto_mmio_in_a_ready),
    .auto_mmio_in_d_valid(i_auto_mmio_in_d_valid),
    .auto_mmio_in_d_bits_opcode(i_auto_mmio_in_d_bits_opcode),
    .auto_mmio_in_d_bits_param(i_auto_mmio_in_d_bits_param),
    .auto_mmio_in_d_bits_size(i_auto_mmio_in_d_bits_size),
    .auto_mmio_in_d_bits_source(i_auto_mmio_in_d_bits_source),
    .auto_mmio_in_d_bits_sink(i_auto_mmio_in_d_bits_sink),
    .auto_mmio_in_d_bits_denied(i_auto_mmio_in_d_bits_denied),
    .auto_mmio_in_d_bits_data(i_auto_mmio_in_d_bits_data),
    .auto_mmio_in_d_bits_corrupt(i_auto_mmio_in_d_bits_corrupt),
    .io_tx_req_valid(i_io_tx_req_valid),
    .io_tx_req_bits_qos(i_io_tx_req_bits_qos),
    .io_tx_req_bits_tgtID(i_io_tx_req_bits_tgtID),
    .io_tx_req_bits_srcID(i_io_tx_req_bits_srcID),
    .io_tx_req_bits_txnID(i_io_tx_req_bits_txnID),
    .io_tx_req_bits_returnNID(i_io_tx_req_bits_returnNID),
    .io_tx_req_bits_stashNIDValid(i_io_tx_req_bits_stashNIDValid),
    .io_tx_req_bits_returnTxnID(i_io_tx_req_bits_returnTxnID),
    .io_tx_req_bits_opcode(i_io_tx_req_bits_opcode),
    .io_tx_req_bits_size(i_io_tx_req_bits_size),
    .io_tx_req_bits_addr(i_io_tx_req_bits_addr),
    .io_tx_req_bits_ns(i_io_tx_req_bits_ns),
    .io_tx_req_bits_likelyshared(i_io_tx_req_bits_likelyshared),
    .io_tx_req_bits_allowRetry(i_io_tx_req_bits_allowRetry),
    .io_tx_req_bits_order(i_io_tx_req_bits_order),
    .io_tx_req_bits_pCrdType(i_io_tx_req_bits_pCrdType),
    .io_tx_req_bits_memAttr_allocate(i_io_tx_req_bits_memAttr_allocate),
    .io_tx_req_bits_memAttr_cacheable(i_io_tx_req_bits_memAttr_cacheable),
    .io_tx_req_bits_memAttr_device(i_io_tx_req_bits_memAttr_device),
    .io_tx_req_bits_memAttr_ewa(i_io_tx_req_bits_memAttr_ewa),
    .io_tx_req_bits_snpAttr(i_io_tx_req_bits_snpAttr),
    .io_tx_req_bits_lpIDWithPadding(i_io_tx_req_bits_lpIDWithPadding),
    .io_tx_req_bits_snoopMe(i_io_tx_req_bits_snoopMe),
    .io_tx_req_bits_expCompAck(i_io_tx_req_bits_expCompAck),
    .io_tx_req_bits_tagOp(i_io_tx_req_bits_tagOp),
    .io_tx_req_bits_traceTag(i_io_tx_req_bits_traceTag),
    .io_tx_req_bits_mpam_perfMonGroup(i_io_tx_req_bits_mpam_perfMonGroup),
    .io_tx_req_bits_mpam_partID(i_io_tx_req_bits_mpam_partID),
    .io_tx_req_bits_mpam_mpamNS(i_io_tx_req_bits_mpam_mpamNS),
    .io_tx_req_bits_rsvdc(i_io_tx_req_bits_rsvdc),
    .io_tx_dat_valid(i_io_tx_dat_valid),
    .io_tx_dat_bits_qos(i_io_tx_dat_bits_qos),
    .io_tx_dat_bits_tgtID(i_io_tx_dat_bits_tgtID),
    .io_tx_dat_bits_srcID(i_io_tx_dat_bits_srcID),
    .io_tx_dat_bits_txnID(i_io_tx_dat_bits_txnID),
    .io_tx_dat_bits_homeNID(i_io_tx_dat_bits_homeNID),
    .io_tx_dat_bits_opcode(i_io_tx_dat_bits_opcode),
    .io_tx_dat_bits_respErr(i_io_tx_dat_bits_respErr),
    .io_tx_dat_bits_resp(i_io_tx_dat_bits_resp),
    .io_tx_dat_bits_dataSource(i_io_tx_dat_bits_dataSource),
    .io_tx_dat_bits_cBusy(i_io_tx_dat_bits_cBusy),
    .io_tx_dat_bits_dbID(i_io_tx_dat_bits_dbID),
    .io_tx_dat_bits_ccID(i_io_tx_dat_bits_ccID),
    .io_tx_dat_bits_dataID(i_io_tx_dat_bits_dataID),
    .io_tx_dat_bits_tagOp(i_io_tx_dat_bits_tagOp),
    .io_tx_dat_bits_tag(i_io_tx_dat_bits_tag),
    .io_tx_dat_bits_tu(i_io_tx_dat_bits_tu),
    .io_tx_dat_bits_traceTag(i_io_tx_dat_bits_traceTag),
    .io_tx_dat_bits_rsvdc(i_io_tx_dat_bits_rsvdc),
    .io_tx_dat_bits_be(i_io_tx_dat_bits_be),
    .io_tx_dat_bits_data(i_io_tx_dat_bits_data),
    .io_tx_dat_bits_dataCheck(i_io_tx_dat_bits_dataCheck),
    .io_tx_dat_bits_poison(i_io_tx_dat_bits_poison),
    .io_rx_rsp_ready(i_io_rx_rsp_ready),
    .io_rx_dat_ready(i_io_rx_dat_ready),
    .io_pCrd_0_query_valid(i_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(i_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(i_io_pCrd_0_query_bits_srcID),
    .io_pCrd_1_query_valid(i_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(i_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(i_io_pCrd_1_query_bits_srcID),
    .io_pCrd_2_query_valid(i_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(i_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(i_io_pCrd_2_query_bits_srcID),
    .io_pCrd_3_query_valid(i_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(i_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(i_io_pCrd_3_query_bits_srcID),
    .io_pCrd_4_query_valid(i_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(i_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(i_io_pCrd_4_query_bits_srcID),
    .io_pCrd_5_query_valid(i_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(i_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(i_io_pCrd_5_query_bits_srcID),
    .io_pCrd_6_query_valid(i_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(i_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(i_io_pCrd_6_query_bits_srcID),
    .io_pCrd_7_query_valid(i_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(i_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(i_io_pCrd_7_query_bits_srcID)
  );

  task automatic drive_random();
    auto_mmio_in_a_valid = $random;
    auto_mmio_in_a_bits_opcode = $random;
    auto_mmio_in_a_bits_param = $random;
    auto_mmio_in_a_bits_size = $random;
    auto_mmio_in_a_bits_source = $random;
    auto_mmio_in_a_bits_address = $random;
    auto_mmio_in_a_bits_user_memBackType_MM = $random;
    auto_mmio_in_a_bits_user_memPageType_NC = $random;
    auto_mmio_in_a_bits_mask = $random;
    auto_mmio_in_a_bits_data = $random;
    auto_mmio_in_a_bits_corrupt = $random;
    auto_mmio_in_d_ready = $random;
    io_tx_req_ready = $random;
    io_tx_dat_ready = $random;
    io_rx_rsp_valid = $random;
    io_rx_rsp_bits_qos = $random;
    io_rx_rsp_bits_tgtID = $random;
    io_rx_rsp_bits_srcID = $random;
    io_rx_rsp_bits_txnID = $random;
    io_rx_rsp_bits_opcode = $random;
    io_rx_rsp_bits_respErr = $random;
    io_rx_rsp_bits_resp = $random;
    io_rx_rsp_bits_fwdState = $random;
    io_rx_rsp_bits_cBusy = $random;
    io_rx_rsp_bits_dbID = $random;
    io_rx_rsp_bits_pCrdType = $random;
    io_rx_rsp_bits_tagOp = $random;
    io_rx_rsp_bits_traceTag = $random;
    io_rx_dat_valid = $random;
    io_rx_dat_bits_qos = $random;
    io_rx_dat_bits_tgtID = $random;
    io_rx_dat_bits_srcID = $random;
    io_rx_dat_bits_txnID = $random;
    io_rx_dat_bits_homeNID = $random;
    io_rx_dat_bits_opcode = $random;
    io_rx_dat_bits_respErr = $random;
    io_rx_dat_bits_resp = $random;
    io_rx_dat_bits_dataSource = $random;
    io_rx_dat_bits_cBusy = $random;
    io_rx_dat_bits_dbID = $random;
    io_rx_dat_bits_ccID = $random;
    io_rx_dat_bits_dataID = $random;
    io_rx_dat_bits_tagOp = $random;
    io_rx_dat_bits_tag = $random;
    io_rx_dat_bits_tu = $random;
    io_rx_dat_bits_traceTag = $random;
    io_rx_dat_bits_rsvdc = $random;
    io_rx_dat_bits_be = $random;
    io_rx_dat_bits_data = $random;
    io_rx_dat_bits_dataCheck = $random;
    io_rx_dat_bits_poison = $random;
    io_pCrd_0_grant = $random;
    io_pCrd_1_grant = $random;
    io_pCrd_2_grant = $random;
    io_pCrd_3_grant = $random;
    io_pCrd_4_grant = $random;
    io_pCrd_5_grant = $random;
    io_pCrd_6_grant = $random;
    io_pCrd_7_grant = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_auto_mmio_in_a_ready !== i_auto_mmio_in_a_ready) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_a_ready: g=%h i=%h", cyc, g_auto_mmio_in_a_ready, i_auto_mmio_in_a_ready); end
    if (g_auto_mmio_in_d_valid !== i_auto_mmio_in_d_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_valid: g=%h i=%h", cyc, g_auto_mmio_in_d_valid, i_auto_mmio_in_d_valid); end
    if (g_auto_mmio_in_d_bits_opcode !== i_auto_mmio_in_d_bits_opcode) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_bits_opcode: g=%h i=%h", cyc, g_auto_mmio_in_d_bits_opcode, i_auto_mmio_in_d_bits_opcode); end
    if (g_auto_mmio_in_d_bits_param !== i_auto_mmio_in_d_bits_param) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_bits_param: g=%h i=%h", cyc, g_auto_mmio_in_d_bits_param, i_auto_mmio_in_d_bits_param); end
    if (g_auto_mmio_in_d_bits_size !== i_auto_mmio_in_d_bits_size) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_bits_size: g=%h i=%h", cyc, g_auto_mmio_in_d_bits_size, i_auto_mmio_in_d_bits_size); end
    if (g_auto_mmio_in_d_bits_source !== i_auto_mmio_in_d_bits_source) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_bits_source: g=%h i=%h", cyc, g_auto_mmio_in_d_bits_source, i_auto_mmio_in_d_bits_source); end
    if (g_auto_mmio_in_d_bits_sink !== i_auto_mmio_in_d_bits_sink) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_bits_sink: g=%h i=%h", cyc, g_auto_mmio_in_d_bits_sink, i_auto_mmio_in_d_bits_sink); end
    if (g_auto_mmio_in_d_bits_denied !== i_auto_mmio_in_d_bits_denied) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_bits_denied: g=%h i=%h", cyc, g_auto_mmio_in_d_bits_denied, i_auto_mmio_in_d_bits_denied); end
    if (g_auto_mmio_in_d_bits_data !== i_auto_mmio_in_d_bits_data) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_bits_data: g=%h i=%h", cyc, g_auto_mmio_in_d_bits_data, i_auto_mmio_in_d_bits_data); end
    if (g_auto_mmio_in_d_bits_corrupt !== i_auto_mmio_in_d_bits_corrupt) begin errors++; if (errors<=40) $display("[%0d] MISMATCH auto_mmio_in_d_bits_corrupt: g=%h i=%h", cyc, g_auto_mmio_in_d_bits_corrupt, i_auto_mmio_in_d_bits_corrupt); end
    if (g_io_tx_req_valid !== i_io_tx_req_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_valid: g=%h i=%h", cyc, g_io_tx_req_valid, i_io_tx_req_valid); end
    if (g_io_tx_req_bits_qos !== i_io_tx_req_bits_qos) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_qos: g=%h i=%h", cyc, g_io_tx_req_bits_qos, i_io_tx_req_bits_qos); end
    if (g_io_tx_req_bits_tgtID !== i_io_tx_req_bits_tgtID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_tgtID: g=%h i=%h", cyc, g_io_tx_req_bits_tgtID, i_io_tx_req_bits_tgtID); end
    if (g_io_tx_req_bits_srcID !== i_io_tx_req_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_srcID: g=%h i=%h", cyc, g_io_tx_req_bits_srcID, i_io_tx_req_bits_srcID); end
    if (g_io_tx_req_bits_txnID !== i_io_tx_req_bits_txnID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_txnID: g=%h i=%h", cyc, g_io_tx_req_bits_txnID, i_io_tx_req_bits_txnID); end
    if (g_io_tx_req_bits_returnNID !== i_io_tx_req_bits_returnNID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_returnNID: g=%h i=%h", cyc, g_io_tx_req_bits_returnNID, i_io_tx_req_bits_returnNID); end
    if (g_io_tx_req_bits_stashNIDValid !== i_io_tx_req_bits_stashNIDValid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_stashNIDValid: g=%h i=%h", cyc, g_io_tx_req_bits_stashNIDValid, i_io_tx_req_bits_stashNIDValid); end
    if (g_io_tx_req_bits_returnTxnID !== i_io_tx_req_bits_returnTxnID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_returnTxnID: g=%h i=%h", cyc, g_io_tx_req_bits_returnTxnID, i_io_tx_req_bits_returnTxnID); end
    if (g_io_tx_req_bits_opcode !== i_io_tx_req_bits_opcode) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_opcode: g=%h i=%h", cyc, g_io_tx_req_bits_opcode, i_io_tx_req_bits_opcode); end
    if (g_io_tx_req_bits_size !== i_io_tx_req_bits_size) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_size: g=%h i=%h", cyc, g_io_tx_req_bits_size, i_io_tx_req_bits_size); end
    if (g_io_tx_req_bits_addr !== i_io_tx_req_bits_addr) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_addr: g=%h i=%h", cyc, g_io_tx_req_bits_addr, i_io_tx_req_bits_addr); end
    if (g_io_tx_req_bits_ns !== i_io_tx_req_bits_ns) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_ns: g=%h i=%h", cyc, g_io_tx_req_bits_ns, i_io_tx_req_bits_ns); end
    if (g_io_tx_req_bits_likelyshared !== i_io_tx_req_bits_likelyshared) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_likelyshared: g=%h i=%h", cyc, g_io_tx_req_bits_likelyshared, i_io_tx_req_bits_likelyshared); end
    if (g_io_tx_req_bits_allowRetry !== i_io_tx_req_bits_allowRetry) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_allowRetry: g=%h i=%h", cyc, g_io_tx_req_bits_allowRetry, i_io_tx_req_bits_allowRetry); end
    if (g_io_tx_req_bits_order !== i_io_tx_req_bits_order) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_order: g=%h i=%h", cyc, g_io_tx_req_bits_order, i_io_tx_req_bits_order); end
    if (g_io_tx_req_bits_pCrdType !== i_io_tx_req_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_pCrdType: g=%h i=%h", cyc, g_io_tx_req_bits_pCrdType, i_io_tx_req_bits_pCrdType); end
    if (g_io_tx_req_bits_memAttr_allocate !== i_io_tx_req_bits_memAttr_allocate) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_memAttr_allocate: g=%h i=%h", cyc, g_io_tx_req_bits_memAttr_allocate, i_io_tx_req_bits_memAttr_allocate); end
    if (g_io_tx_req_bits_memAttr_cacheable !== i_io_tx_req_bits_memAttr_cacheable) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_memAttr_cacheable: g=%h i=%h", cyc, g_io_tx_req_bits_memAttr_cacheable, i_io_tx_req_bits_memAttr_cacheable); end
    if (g_io_tx_req_bits_memAttr_device !== i_io_tx_req_bits_memAttr_device) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_memAttr_device: g=%h i=%h", cyc, g_io_tx_req_bits_memAttr_device, i_io_tx_req_bits_memAttr_device); end
    if (g_io_tx_req_bits_memAttr_ewa !== i_io_tx_req_bits_memAttr_ewa) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_memAttr_ewa: g=%h i=%h", cyc, g_io_tx_req_bits_memAttr_ewa, i_io_tx_req_bits_memAttr_ewa); end
    if (g_io_tx_req_bits_snpAttr !== i_io_tx_req_bits_snpAttr) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_snpAttr: g=%h i=%h", cyc, g_io_tx_req_bits_snpAttr, i_io_tx_req_bits_snpAttr); end
    if (g_io_tx_req_bits_lpIDWithPadding !== i_io_tx_req_bits_lpIDWithPadding) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_lpIDWithPadding: g=%h i=%h", cyc, g_io_tx_req_bits_lpIDWithPadding, i_io_tx_req_bits_lpIDWithPadding); end
    if (g_io_tx_req_bits_snoopMe !== i_io_tx_req_bits_snoopMe) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_snoopMe: g=%h i=%h", cyc, g_io_tx_req_bits_snoopMe, i_io_tx_req_bits_snoopMe); end
    if (g_io_tx_req_bits_expCompAck !== i_io_tx_req_bits_expCompAck) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_expCompAck: g=%h i=%h", cyc, g_io_tx_req_bits_expCompAck, i_io_tx_req_bits_expCompAck); end
    if (g_io_tx_req_bits_tagOp !== i_io_tx_req_bits_tagOp) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_tagOp: g=%h i=%h", cyc, g_io_tx_req_bits_tagOp, i_io_tx_req_bits_tagOp); end
    if (g_io_tx_req_bits_traceTag !== i_io_tx_req_bits_traceTag) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_traceTag: g=%h i=%h", cyc, g_io_tx_req_bits_traceTag, i_io_tx_req_bits_traceTag); end
    if (g_io_tx_req_bits_mpam_perfMonGroup !== i_io_tx_req_bits_mpam_perfMonGroup) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_mpam_perfMonGroup: g=%h i=%h", cyc, g_io_tx_req_bits_mpam_perfMonGroup, i_io_tx_req_bits_mpam_perfMonGroup); end
    if (g_io_tx_req_bits_mpam_partID !== i_io_tx_req_bits_mpam_partID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_mpam_partID: g=%h i=%h", cyc, g_io_tx_req_bits_mpam_partID, i_io_tx_req_bits_mpam_partID); end
    if (g_io_tx_req_bits_mpam_mpamNS !== i_io_tx_req_bits_mpam_mpamNS) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_mpam_mpamNS: g=%h i=%h", cyc, g_io_tx_req_bits_mpam_mpamNS, i_io_tx_req_bits_mpam_mpamNS); end
    if (g_io_tx_req_bits_rsvdc !== i_io_tx_req_bits_rsvdc) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_req_bits_rsvdc: g=%h i=%h", cyc, g_io_tx_req_bits_rsvdc, i_io_tx_req_bits_rsvdc); end
    if (g_io_tx_dat_valid !== i_io_tx_dat_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_valid: g=%h i=%h", cyc, g_io_tx_dat_valid, i_io_tx_dat_valid); end
    if (g_io_tx_dat_bits_qos !== i_io_tx_dat_bits_qos) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_qos: g=%h i=%h", cyc, g_io_tx_dat_bits_qos, i_io_tx_dat_bits_qos); end
    if (g_io_tx_dat_bits_tgtID !== i_io_tx_dat_bits_tgtID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_tgtID: g=%h i=%h", cyc, g_io_tx_dat_bits_tgtID, i_io_tx_dat_bits_tgtID); end
    if (g_io_tx_dat_bits_srcID !== i_io_tx_dat_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_srcID: g=%h i=%h", cyc, g_io_tx_dat_bits_srcID, i_io_tx_dat_bits_srcID); end
    if (g_io_tx_dat_bits_txnID !== i_io_tx_dat_bits_txnID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_txnID: g=%h i=%h", cyc, g_io_tx_dat_bits_txnID, i_io_tx_dat_bits_txnID); end
    if (g_io_tx_dat_bits_homeNID !== i_io_tx_dat_bits_homeNID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_homeNID: g=%h i=%h", cyc, g_io_tx_dat_bits_homeNID, i_io_tx_dat_bits_homeNID); end
    if (g_io_tx_dat_bits_opcode !== i_io_tx_dat_bits_opcode) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_opcode: g=%h i=%h", cyc, g_io_tx_dat_bits_opcode, i_io_tx_dat_bits_opcode); end
    if (g_io_tx_dat_bits_respErr !== i_io_tx_dat_bits_respErr) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_respErr: g=%h i=%h", cyc, g_io_tx_dat_bits_respErr, i_io_tx_dat_bits_respErr); end
    if (g_io_tx_dat_bits_resp !== i_io_tx_dat_bits_resp) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_resp: g=%h i=%h", cyc, g_io_tx_dat_bits_resp, i_io_tx_dat_bits_resp); end
    if (g_io_tx_dat_bits_dataSource !== i_io_tx_dat_bits_dataSource) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_dataSource: g=%h i=%h", cyc, g_io_tx_dat_bits_dataSource, i_io_tx_dat_bits_dataSource); end
    if (g_io_tx_dat_bits_cBusy !== i_io_tx_dat_bits_cBusy) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_cBusy: g=%h i=%h", cyc, g_io_tx_dat_bits_cBusy, i_io_tx_dat_bits_cBusy); end
    if (g_io_tx_dat_bits_dbID !== i_io_tx_dat_bits_dbID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_dbID: g=%h i=%h", cyc, g_io_tx_dat_bits_dbID, i_io_tx_dat_bits_dbID); end
    if (g_io_tx_dat_bits_ccID !== i_io_tx_dat_bits_ccID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_ccID: g=%h i=%h", cyc, g_io_tx_dat_bits_ccID, i_io_tx_dat_bits_ccID); end
    if (g_io_tx_dat_bits_dataID !== i_io_tx_dat_bits_dataID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_dataID: g=%h i=%h", cyc, g_io_tx_dat_bits_dataID, i_io_tx_dat_bits_dataID); end
    if (g_io_tx_dat_bits_tagOp !== i_io_tx_dat_bits_tagOp) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_tagOp: g=%h i=%h", cyc, g_io_tx_dat_bits_tagOp, i_io_tx_dat_bits_tagOp); end
    if (g_io_tx_dat_bits_tag !== i_io_tx_dat_bits_tag) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_tag: g=%h i=%h", cyc, g_io_tx_dat_bits_tag, i_io_tx_dat_bits_tag); end
    if (g_io_tx_dat_bits_tu !== i_io_tx_dat_bits_tu) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_tu: g=%h i=%h", cyc, g_io_tx_dat_bits_tu, i_io_tx_dat_bits_tu); end
    if (g_io_tx_dat_bits_traceTag !== i_io_tx_dat_bits_traceTag) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_traceTag: g=%h i=%h", cyc, g_io_tx_dat_bits_traceTag, i_io_tx_dat_bits_traceTag); end
    if (g_io_tx_dat_bits_rsvdc !== i_io_tx_dat_bits_rsvdc) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_rsvdc: g=%h i=%h", cyc, g_io_tx_dat_bits_rsvdc, i_io_tx_dat_bits_rsvdc); end
    if (g_io_tx_dat_bits_be !== i_io_tx_dat_bits_be) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_be: g=%h i=%h", cyc, g_io_tx_dat_bits_be, i_io_tx_dat_bits_be); end
    if (g_io_tx_dat_bits_data !== i_io_tx_dat_bits_data) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_data: g=%h i=%h", cyc, g_io_tx_dat_bits_data, i_io_tx_dat_bits_data); end
    if (g_io_tx_dat_bits_dataCheck !== i_io_tx_dat_bits_dataCheck) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_dataCheck: g=%h i=%h", cyc, g_io_tx_dat_bits_dataCheck, i_io_tx_dat_bits_dataCheck); end
    if (g_io_tx_dat_bits_poison !== i_io_tx_dat_bits_poison) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_tx_dat_bits_poison: g=%h i=%h", cyc, g_io_tx_dat_bits_poison, i_io_tx_dat_bits_poison); end
    if (g_io_rx_rsp_ready !== i_io_rx_rsp_ready) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_rx_rsp_ready: g=%h i=%h", cyc, g_io_rx_rsp_ready, i_io_rx_rsp_ready); end
    if (g_io_rx_dat_ready !== i_io_rx_dat_ready) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_rx_dat_ready: g=%h i=%h", cyc, g_io_rx_dat_ready, i_io_rx_dat_ready); end
    if (g_io_pCrd_0_query_valid !== i_io_pCrd_0_query_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_0_query_valid: g=%h i=%h", cyc, g_io_pCrd_0_query_valid, i_io_pCrd_0_query_valid); end
    if (g_io_pCrd_0_query_bits_pCrdType !== i_io_pCrd_0_query_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_0_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_0_query_bits_pCrdType, i_io_pCrd_0_query_bits_pCrdType); end
    if (g_io_pCrd_0_query_bits_srcID !== i_io_pCrd_0_query_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_0_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_0_query_bits_srcID, i_io_pCrd_0_query_bits_srcID); end
    if (g_io_pCrd_1_query_valid !== i_io_pCrd_1_query_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_1_query_valid: g=%h i=%h", cyc, g_io_pCrd_1_query_valid, i_io_pCrd_1_query_valid); end
    if (g_io_pCrd_1_query_bits_pCrdType !== i_io_pCrd_1_query_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_1_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_1_query_bits_pCrdType, i_io_pCrd_1_query_bits_pCrdType); end
    if (g_io_pCrd_1_query_bits_srcID !== i_io_pCrd_1_query_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_1_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_1_query_bits_srcID, i_io_pCrd_1_query_bits_srcID); end
    if (g_io_pCrd_2_query_valid !== i_io_pCrd_2_query_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_2_query_valid: g=%h i=%h", cyc, g_io_pCrd_2_query_valid, i_io_pCrd_2_query_valid); end
    if (g_io_pCrd_2_query_bits_pCrdType !== i_io_pCrd_2_query_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_2_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_2_query_bits_pCrdType, i_io_pCrd_2_query_bits_pCrdType); end
    if (g_io_pCrd_2_query_bits_srcID !== i_io_pCrd_2_query_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_2_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_2_query_bits_srcID, i_io_pCrd_2_query_bits_srcID); end
    if (g_io_pCrd_3_query_valid !== i_io_pCrd_3_query_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_3_query_valid: g=%h i=%h", cyc, g_io_pCrd_3_query_valid, i_io_pCrd_3_query_valid); end
    if (g_io_pCrd_3_query_bits_pCrdType !== i_io_pCrd_3_query_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_3_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_3_query_bits_pCrdType, i_io_pCrd_3_query_bits_pCrdType); end
    if (g_io_pCrd_3_query_bits_srcID !== i_io_pCrd_3_query_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_3_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_3_query_bits_srcID, i_io_pCrd_3_query_bits_srcID); end
    if (g_io_pCrd_4_query_valid !== i_io_pCrd_4_query_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_4_query_valid: g=%h i=%h", cyc, g_io_pCrd_4_query_valid, i_io_pCrd_4_query_valid); end
    if (g_io_pCrd_4_query_bits_pCrdType !== i_io_pCrd_4_query_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_4_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_4_query_bits_pCrdType, i_io_pCrd_4_query_bits_pCrdType); end
    if (g_io_pCrd_4_query_bits_srcID !== i_io_pCrd_4_query_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_4_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_4_query_bits_srcID, i_io_pCrd_4_query_bits_srcID); end
    if (g_io_pCrd_5_query_valid !== i_io_pCrd_5_query_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_5_query_valid: g=%h i=%h", cyc, g_io_pCrd_5_query_valid, i_io_pCrd_5_query_valid); end
    if (g_io_pCrd_5_query_bits_pCrdType !== i_io_pCrd_5_query_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_5_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_5_query_bits_pCrdType, i_io_pCrd_5_query_bits_pCrdType); end
    if (g_io_pCrd_5_query_bits_srcID !== i_io_pCrd_5_query_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_5_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_5_query_bits_srcID, i_io_pCrd_5_query_bits_srcID); end
    if (g_io_pCrd_6_query_valid !== i_io_pCrd_6_query_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_6_query_valid: g=%h i=%h", cyc, g_io_pCrd_6_query_valid, i_io_pCrd_6_query_valid); end
    if (g_io_pCrd_6_query_bits_pCrdType !== i_io_pCrd_6_query_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_6_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_6_query_bits_pCrdType, i_io_pCrd_6_query_bits_pCrdType); end
    if (g_io_pCrd_6_query_bits_srcID !== i_io_pCrd_6_query_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_6_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_6_query_bits_srcID, i_io_pCrd_6_query_bits_srcID); end
    if (g_io_pCrd_7_query_valid !== i_io_pCrd_7_query_valid) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_7_query_valid: g=%h i=%h", cyc, g_io_pCrd_7_query_valid, i_io_pCrd_7_query_valid); end
    if (g_io_pCrd_7_query_bits_pCrdType !== i_io_pCrd_7_query_bits_pCrdType) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_7_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_7_query_bits_pCrdType, i_io_pCrd_7_query_bits_pCrdType); end
    if (g_io_pCrd_7_query_bits_srcID !== i_io_pCrd_7_query_bits_srcID) begin errors++; if (errors<=40) $display("[%0d] MISMATCH io_pCrd_7_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_7_query_bits_srcID, i_io_pCrd_7_query_bits_srcID); end
  endtask

  initial begin
    rst = 1'b1;
    auto_mmio_in_a_valid = '0;
    auto_mmio_in_a_bits_opcode = '0;
    auto_mmio_in_a_bits_param = '0;
    auto_mmio_in_a_bits_size = '0;
    auto_mmio_in_a_bits_source = '0;
    auto_mmio_in_a_bits_address = '0;
    auto_mmio_in_a_bits_user_memBackType_MM = '0;
    auto_mmio_in_a_bits_user_memPageType_NC = '0;
    auto_mmio_in_a_bits_mask = '0;
    auto_mmio_in_a_bits_data = '0;
    auto_mmio_in_a_bits_corrupt = '0;
    auto_mmio_in_d_ready = '0;
    io_tx_req_ready = '0;
    io_tx_dat_ready = '0;
    io_rx_rsp_valid = '0;
    io_rx_rsp_bits_qos = '0;
    io_rx_rsp_bits_tgtID = '0;
    io_rx_rsp_bits_srcID = '0;
    io_rx_rsp_bits_txnID = '0;
    io_rx_rsp_bits_opcode = '0;
    io_rx_rsp_bits_respErr = '0;
    io_rx_rsp_bits_resp = '0;
    io_rx_rsp_bits_fwdState = '0;
    io_rx_rsp_bits_cBusy = '0;
    io_rx_rsp_bits_dbID = '0;
    io_rx_rsp_bits_pCrdType = '0;
    io_rx_rsp_bits_tagOp = '0;
    io_rx_rsp_bits_traceTag = '0;
    io_rx_dat_valid = '0;
    io_rx_dat_bits_qos = '0;
    io_rx_dat_bits_tgtID = '0;
    io_rx_dat_bits_srcID = '0;
    io_rx_dat_bits_txnID = '0;
    io_rx_dat_bits_homeNID = '0;
    io_rx_dat_bits_opcode = '0;
    io_rx_dat_bits_respErr = '0;
    io_rx_dat_bits_resp = '0;
    io_rx_dat_bits_dataSource = '0;
    io_rx_dat_bits_cBusy = '0;
    io_rx_dat_bits_dbID = '0;
    io_rx_dat_bits_ccID = '0;
    io_rx_dat_bits_dataID = '0;
    io_rx_dat_bits_tagOp = '0;
    io_rx_dat_bits_tag = '0;
    io_rx_dat_bits_tu = '0;
    io_rx_dat_bits_traceTag = '0;
    io_rx_dat_bits_rsvdc = '0;
    io_rx_dat_bits_be = '0;
    io_rx_dat_bits_data = '0;
    io_rx_dat_bits_dataCheck = '0;
    io_rx_dat_bits_poison = '0;
    io_pCrd_0_grant = '0;
    io_pCrd_1_grant = '0;
    io_pCrd_2_grant = '0;
    io_pCrd_3_grant = '0;
    io_pCrd_4_grant = '0;
    io_pCrd_5_grant = '0;
    io_pCrd_6_grant = '0;
    io_pCrd_7_grant = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc=0; cyc<NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors==0) $display("TEST PASSED: checks=%0d errors=0", checks);
    else $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule

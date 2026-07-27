`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int unsigned WARMUP  = 8;
  bit clk = 0, rst;
  int errors = 0, checks = 0, cyc = 0;
  always #5 clk = ~clk;

  logic io_req_valid;
  logic [3:0] io_req_bits_opcode;
  logic [1:0] io_req_bits_size;
  logic [2:0] io_req_bits_source;
  logic [47:0] io_req_bits_address;
  logic io_req_bits_user_memBackType_MM;
  logic io_req_bits_user_memPageType_NC;
  logic [7:0] io_req_bits_mask;
  logic [63:0] io_req_bits_data;
  logic io_req_bits_corrupt;
  logic io_resp_ready;
  logic io_chi_tx_req_ready;
  logic io_chi_tx_dat_ready;
  logic io_chi_rx_rsp_valid;
  logic [10:0] io_chi_rx_rsp_bits_srcID;
  logic [4:0] io_chi_rx_rsp_bits_opcode;
  logic [1:0] io_chi_rx_rsp_bits_respErr;
  logic [11:0] io_chi_rx_rsp_bits_dbID;
  logic [3:0] io_chi_rx_rsp_bits_pCrdType;
  logic io_chi_rx_rsp_bits_traceTag;
  logic io_chi_rx_dat_valid;
  logic [1:0] io_chi_rx_dat_bits_respErr;
  logic [255:0] io_chi_rx_dat_bits_data;
  logic [31:0] io_chi_rx_dat_bits_dataCheck;
  logic [3:0] io_chi_rx_dat_bits_poison;
  logic io_id;
  logic io_pCrd_grant;
  logic g_io_req_ready, i_io_req_ready;
  logic g_io_resp_valid, i_io_resp_valid;
  logic [3:0] g_io_resp_bits_opcode, i_io_resp_bits_opcode;
  logic [1:0] g_io_resp_bits_size, i_io_resp_bits_size;
  logic [2:0] g_io_resp_bits_source, i_io_resp_bits_source;
  logic g_io_resp_bits_denied, i_io_resp_bits_denied;
  logic [63:0] g_io_resp_bits_data, i_io_resp_bits_data;
  logic g_io_resp_bits_corrupt, i_io_resp_bits_corrupt;
  logic g_io_chi_tx_req_valid, i_io_chi_tx_req_valid;
  logic [11:0] g_io_chi_tx_req_bits_txnID, i_io_chi_tx_req_bits_txnID;
  logic [6:0] g_io_chi_tx_req_bits_opcode, i_io_chi_tx_req_bits_opcode;
  logic [2:0] g_io_chi_tx_req_bits_size, i_io_chi_tx_req_bits_size;
  logic [47:0] g_io_chi_tx_req_bits_addr, i_io_chi_tx_req_bits_addr;
  logic g_io_chi_tx_req_bits_allowRetry, i_io_chi_tx_req_bits_allowRetry;
  logic [1:0] g_io_chi_tx_req_bits_order, i_io_chi_tx_req_bits_order;
  logic [3:0] g_io_chi_tx_req_bits_pCrdType, i_io_chi_tx_req_bits_pCrdType;
  logic g_io_chi_tx_req_bits_memAttr_device, i_io_chi_tx_req_bits_memAttr_device;
  logic g_io_chi_tx_req_bits_memAttr_ewa, i_io_chi_tx_req_bits_memAttr_ewa;
  logic g_io_chi_tx_dat_valid, i_io_chi_tx_dat_valid;
  logic [10:0] g_io_chi_tx_dat_bits_tgtID, i_io_chi_tx_dat_bits_tgtID;
  logic [11:0] g_io_chi_tx_dat_bits_txnID, i_io_chi_tx_dat_bits_txnID;
  logic [1:0] g_io_chi_tx_dat_bits_respErr, i_io_chi_tx_dat_bits_respErr;
  logic [1:0] g_io_chi_tx_dat_bits_ccID, i_io_chi_tx_dat_bits_ccID;
  logic [1:0] g_io_chi_tx_dat_bits_dataID, i_io_chi_tx_dat_bits_dataID;
  logic g_io_chi_tx_dat_bits_traceTag, i_io_chi_tx_dat_bits_traceTag;
  logic [31:0] g_io_chi_tx_dat_bits_be, i_io_chi_tx_dat_bits_be;
  logic [255:0] g_io_chi_tx_dat_bits_data, i_io_chi_tx_dat_bits_data;
  logic [31:0] g_io_chi_tx_dat_bits_dataCheck, i_io_chi_tx_dat_bits_dataCheck;
  logic [3:0] g_io_chi_tx_dat_bits_poison, i_io_chi_tx_dat_bits_poison;
  logic g_io_chi_rx_rsp_ready, i_io_chi_rx_rsp_ready;
  logic g_io_chi_rx_dat_ready, i_io_chi_rx_dat_ready;
  logic g_io_pCrd_query_valid, i_io_pCrd_query_valid;
  logic [3:0] g_io_pCrd_query_bits_pCrdType, i_io_pCrd_query_bits_pCrdType;
  logic [10:0] g_io_pCrd_query_bits_srcID, i_io_pCrd_query_bits_srcID;
  logic g_io_waitOnReadReceipt, i_io_waitOnReadReceipt;

  MMIOBridgeEntry dut_g (
    .clock(clk),
    .reset(rst),
    .io_req_valid(io_req_valid),
    .io_req_bits_opcode(io_req_bits_opcode),
    .io_req_bits_size(io_req_bits_size),
    .io_req_bits_source(io_req_bits_source),
    .io_req_bits_address(io_req_bits_address),
    .io_req_bits_user_memBackType_MM(io_req_bits_user_memBackType_MM),
    .io_req_bits_user_memPageType_NC(io_req_bits_user_memPageType_NC),
    .io_req_bits_mask(io_req_bits_mask),
    .io_req_bits_data(io_req_bits_data),
    .io_req_bits_corrupt(io_req_bits_corrupt),
    .io_resp_ready(io_resp_ready),
    .io_chi_tx_req_ready(io_chi_tx_req_ready),
    .io_chi_tx_dat_ready(io_chi_tx_dat_ready),
    .io_chi_rx_rsp_valid(io_chi_rx_rsp_valid),
    .io_chi_rx_rsp_bits_srcID(io_chi_rx_rsp_bits_srcID),
    .io_chi_rx_rsp_bits_opcode(io_chi_rx_rsp_bits_opcode),
    .io_chi_rx_rsp_bits_respErr(io_chi_rx_rsp_bits_respErr),
    .io_chi_rx_rsp_bits_dbID(io_chi_rx_rsp_bits_dbID),
    .io_chi_rx_rsp_bits_pCrdType(io_chi_rx_rsp_bits_pCrdType),
    .io_chi_rx_rsp_bits_traceTag(io_chi_rx_rsp_bits_traceTag),
    .io_chi_rx_dat_valid(io_chi_rx_dat_valid),
    .io_chi_rx_dat_bits_respErr(io_chi_rx_dat_bits_respErr),
    .io_chi_rx_dat_bits_data(io_chi_rx_dat_bits_data),
    .io_chi_rx_dat_bits_dataCheck(io_chi_rx_dat_bits_dataCheck),
    .io_chi_rx_dat_bits_poison(io_chi_rx_dat_bits_poison),
    .io_id(io_id),
    .io_pCrd_grant(io_pCrd_grant),
    .io_req_ready(g_io_req_ready),
    .io_resp_valid(g_io_resp_valid),
    .io_resp_bits_opcode(g_io_resp_bits_opcode),
    .io_resp_bits_size(g_io_resp_bits_size),
    .io_resp_bits_source(g_io_resp_bits_source),
    .io_resp_bits_denied(g_io_resp_bits_denied),
    .io_resp_bits_data(g_io_resp_bits_data),
    .io_resp_bits_corrupt(g_io_resp_bits_corrupt),
    .io_chi_tx_req_valid(g_io_chi_tx_req_valid),
    .io_chi_tx_req_bits_txnID(g_io_chi_tx_req_bits_txnID),
    .io_chi_tx_req_bits_opcode(g_io_chi_tx_req_bits_opcode),
    .io_chi_tx_req_bits_size(g_io_chi_tx_req_bits_size),
    .io_chi_tx_req_bits_addr(g_io_chi_tx_req_bits_addr),
    .io_chi_tx_req_bits_allowRetry(g_io_chi_tx_req_bits_allowRetry),
    .io_chi_tx_req_bits_order(g_io_chi_tx_req_bits_order),
    .io_chi_tx_req_bits_pCrdType(g_io_chi_tx_req_bits_pCrdType),
    .io_chi_tx_req_bits_memAttr_device(g_io_chi_tx_req_bits_memAttr_device),
    .io_chi_tx_req_bits_memAttr_ewa(g_io_chi_tx_req_bits_memAttr_ewa),
    .io_chi_tx_dat_valid(g_io_chi_tx_dat_valid),
    .io_chi_tx_dat_bits_tgtID(g_io_chi_tx_dat_bits_tgtID),
    .io_chi_tx_dat_bits_txnID(g_io_chi_tx_dat_bits_txnID),
    .io_chi_tx_dat_bits_respErr(g_io_chi_tx_dat_bits_respErr),
    .io_chi_tx_dat_bits_ccID(g_io_chi_tx_dat_bits_ccID),
    .io_chi_tx_dat_bits_dataID(g_io_chi_tx_dat_bits_dataID),
    .io_chi_tx_dat_bits_traceTag(g_io_chi_tx_dat_bits_traceTag),
    .io_chi_tx_dat_bits_be(g_io_chi_tx_dat_bits_be),
    .io_chi_tx_dat_bits_data(g_io_chi_tx_dat_bits_data),
    .io_chi_tx_dat_bits_dataCheck(g_io_chi_tx_dat_bits_dataCheck),
    .io_chi_tx_dat_bits_poison(g_io_chi_tx_dat_bits_poison),
    .io_chi_rx_rsp_ready(g_io_chi_rx_rsp_ready),
    .io_chi_rx_dat_ready(g_io_chi_rx_dat_ready),
    .io_pCrd_query_valid(g_io_pCrd_query_valid),
    .io_pCrd_query_bits_pCrdType(g_io_pCrd_query_bits_pCrdType),
    .io_pCrd_query_bits_srcID(g_io_pCrd_query_bits_srcID),
    .io_waitOnReadReceipt(g_io_waitOnReadReceipt)
  );

  MMIOBridgeEntry_xs dut_i (
    .clock(clk),
    .reset(rst),
    .io_req_valid(io_req_valid),
    .io_req_bits_opcode(io_req_bits_opcode),
    .io_req_bits_size(io_req_bits_size),
    .io_req_bits_source(io_req_bits_source),
    .io_req_bits_address(io_req_bits_address),
    .io_req_bits_user_memBackType_MM(io_req_bits_user_memBackType_MM),
    .io_req_bits_user_memPageType_NC(io_req_bits_user_memPageType_NC),
    .io_req_bits_mask(io_req_bits_mask),
    .io_req_bits_data(io_req_bits_data),
    .io_req_bits_corrupt(io_req_bits_corrupt),
    .io_resp_ready(io_resp_ready),
    .io_chi_tx_req_ready(io_chi_tx_req_ready),
    .io_chi_tx_dat_ready(io_chi_tx_dat_ready),
    .io_chi_rx_rsp_valid(io_chi_rx_rsp_valid),
    .io_chi_rx_rsp_bits_srcID(io_chi_rx_rsp_bits_srcID),
    .io_chi_rx_rsp_bits_opcode(io_chi_rx_rsp_bits_opcode),
    .io_chi_rx_rsp_bits_respErr(io_chi_rx_rsp_bits_respErr),
    .io_chi_rx_rsp_bits_dbID(io_chi_rx_rsp_bits_dbID),
    .io_chi_rx_rsp_bits_pCrdType(io_chi_rx_rsp_bits_pCrdType),
    .io_chi_rx_rsp_bits_traceTag(io_chi_rx_rsp_bits_traceTag),
    .io_chi_rx_dat_valid(io_chi_rx_dat_valid),
    .io_chi_rx_dat_bits_respErr(io_chi_rx_dat_bits_respErr),
    .io_chi_rx_dat_bits_data(io_chi_rx_dat_bits_data),
    .io_chi_rx_dat_bits_dataCheck(io_chi_rx_dat_bits_dataCheck),
    .io_chi_rx_dat_bits_poison(io_chi_rx_dat_bits_poison),
    .io_id(io_id),
    .io_pCrd_grant(io_pCrd_grant),
    .io_req_ready(i_io_req_ready),
    .io_resp_valid(i_io_resp_valid),
    .io_resp_bits_opcode(i_io_resp_bits_opcode),
    .io_resp_bits_size(i_io_resp_bits_size),
    .io_resp_bits_source(i_io_resp_bits_source),
    .io_resp_bits_denied(i_io_resp_bits_denied),
    .io_resp_bits_data(i_io_resp_bits_data),
    .io_resp_bits_corrupt(i_io_resp_bits_corrupt),
    .io_chi_tx_req_valid(i_io_chi_tx_req_valid),
    .io_chi_tx_req_bits_txnID(i_io_chi_tx_req_bits_txnID),
    .io_chi_tx_req_bits_opcode(i_io_chi_tx_req_bits_opcode),
    .io_chi_tx_req_bits_size(i_io_chi_tx_req_bits_size),
    .io_chi_tx_req_bits_addr(i_io_chi_tx_req_bits_addr),
    .io_chi_tx_req_bits_allowRetry(i_io_chi_tx_req_bits_allowRetry),
    .io_chi_tx_req_bits_order(i_io_chi_tx_req_bits_order),
    .io_chi_tx_req_bits_pCrdType(i_io_chi_tx_req_bits_pCrdType),
    .io_chi_tx_req_bits_memAttr_device(i_io_chi_tx_req_bits_memAttr_device),
    .io_chi_tx_req_bits_memAttr_ewa(i_io_chi_tx_req_bits_memAttr_ewa),
    .io_chi_tx_dat_valid(i_io_chi_tx_dat_valid),
    .io_chi_tx_dat_bits_tgtID(i_io_chi_tx_dat_bits_tgtID),
    .io_chi_tx_dat_bits_txnID(i_io_chi_tx_dat_bits_txnID),
    .io_chi_tx_dat_bits_respErr(i_io_chi_tx_dat_bits_respErr),
    .io_chi_tx_dat_bits_ccID(i_io_chi_tx_dat_bits_ccID),
    .io_chi_tx_dat_bits_dataID(i_io_chi_tx_dat_bits_dataID),
    .io_chi_tx_dat_bits_traceTag(i_io_chi_tx_dat_bits_traceTag),
    .io_chi_tx_dat_bits_be(i_io_chi_tx_dat_bits_be),
    .io_chi_tx_dat_bits_data(i_io_chi_tx_dat_bits_data),
    .io_chi_tx_dat_bits_dataCheck(i_io_chi_tx_dat_bits_dataCheck),
    .io_chi_tx_dat_bits_poison(i_io_chi_tx_dat_bits_poison),
    .io_chi_rx_rsp_ready(i_io_chi_rx_rsp_ready),
    .io_chi_rx_dat_ready(i_io_chi_rx_dat_ready),
    .io_pCrd_query_valid(i_io_pCrd_query_valid),
    .io_pCrd_query_bits_pCrdType(i_io_pCrd_query_bits_pCrdType),
    .io_pCrd_query_bits_srcID(i_io_pCrd_query_bits_srcID),
    .io_waitOnReadReceipt(i_io_waitOnReadReceipt)
  );

  task automatic drive_random();
    io_req_valid = $random;
    io_req_bits_opcode = $random;
    io_req_bits_size = $random;
    io_req_bits_source = $random;
    io_req_bits_address = {$random, $random};
    io_req_bits_user_memBackType_MM = $random;
    io_req_bits_user_memPageType_NC = $random;
    io_req_bits_mask = $random;
    io_req_bits_data = {$random, $random};
    io_req_bits_corrupt = $random;
    io_resp_ready = $random;
    io_chi_tx_req_ready = $random;
    io_chi_tx_dat_ready = $random;
    io_chi_rx_rsp_valid = $random;
    io_chi_rx_rsp_bits_srcID = $random;
    io_chi_rx_rsp_bits_opcode = $random;
    io_chi_rx_rsp_bits_respErr = $random;
    io_chi_rx_rsp_bits_dbID = $random;
    io_chi_rx_rsp_bits_pCrdType = $random;
    io_chi_rx_rsp_bits_traceTag = $random;
    io_chi_rx_dat_valid = $random;
    io_chi_rx_dat_bits_respErr = $random;
    io_chi_rx_dat_bits_data = {$random, $random, $random, $random, $random, $random, $random, $random};
    io_chi_rx_dat_bits_dataCheck = $random;
    io_chi_rx_dat_bits_poison = $random;
    io_id = $random;
    io_pCrd_grant = $random;
  endtask

  task automatic check_outputs();
    checks++;
    if (g_io_req_ready !== i_io_req_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_req_ready: g=%h i=%h", cyc, g_io_req_ready, i_io_req_ready); end
    if (g_io_resp_valid !== i_io_resp_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_resp_valid: g=%h i=%h", cyc, g_io_resp_valid, i_io_resp_valid); end
    if (g_io_resp_bits_opcode !== i_io_resp_bits_opcode) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_resp_bits_opcode: g=%h i=%h", cyc, g_io_resp_bits_opcode, i_io_resp_bits_opcode); end
    if (g_io_resp_bits_size !== i_io_resp_bits_size) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_resp_bits_size: g=%h i=%h", cyc, g_io_resp_bits_size, i_io_resp_bits_size); end
    if (g_io_resp_bits_source !== i_io_resp_bits_source) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_resp_bits_source: g=%h i=%h", cyc, g_io_resp_bits_source, i_io_resp_bits_source); end
    if (g_io_resp_bits_denied !== i_io_resp_bits_denied) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_resp_bits_denied: g=%h i=%h", cyc, g_io_resp_bits_denied, i_io_resp_bits_denied); end
    if (g_io_resp_bits_data !== i_io_resp_bits_data) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_resp_bits_data: g=%h i=%h", cyc, g_io_resp_bits_data, i_io_resp_bits_data); end
    if (g_io_resp_bits_corrupt !== i_io_resp_bits_corrupt) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_resp_bits_corrupt: g=%h i=%h", cyc, g_io_resp_bits_corrupt, i_io_resp_bits_corrupt); end
    if (g_io_chi_tx_req_valid !== i_io_chi_tx_req_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_valid: g=%h i=%h", cyc, g_io_chi_tx_req_valid, i_io_chi_tx_req_valid); end
    if (g_io_chi_tx_req_bits_txnID !== i_io_chi_tx_req_bits_txnID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_txnID: g=%h i=%h", cyc, g_io_chi_tx_req_bits_txnID, i_io_chi_tx_req_bits_txnID); end
    if (g_io_chi_tx_req_bits_opcode !== i_io_chi_tx_req_bits_opcode) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_opcode: g=%h i=%h", cyc, g_io_chi_tx_req_bits_opcode, i_io_chi_tx_req_bits_opcode); end
    if (g_io_chi_tx_req_bits_size !== i_io_chi_tx_req_bits_size) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_size: g=%h i=%h", cyc, g_io_chi_tx_req_bits_size, i_io_chi_tx_req_bits_size); end
    if (g_io_chi_tx_req_bits_addr !== i_io_chi_tx_req_bits_addr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_addr: g=%h i=%h", cyc, g_io_chi_tx_req_bits_addr, i_io_chi_tx_req_bits_addr); end
    if (g_io_chi_tx_req_bits_allowRetry !== i_io_chi_tx_req_bits_allowRetry) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_allowRetry: g=%h i=%h", cyc, g_io_chi_tx_req_bits_allowRetry, i_io_chi_tx_req_bits_allowRetry); end
    if (g_io_chi_tx_req_bits_order !== i_io_chi_tx_req_bits_order) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_order: g=%h i=%h", cyc, g_io_chi_tx_req_bits_order, i_io_chi_tx_req_bits_order); end
    if (g_io_chi_tx_req_bits_pCrdType !== i_io_chi_tx_req_bits_pCrdType) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_pCrdType: g=%h i=%h", cyc, g_io_chi_tx_req_bits_pCrdType, i_io_chi_tx_req_bits_pCrdType); end
    if (g_io_chi_tx_req_bits_memAttr_device !== i_io_chi_tx_req_bits_memAttr_device) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_memAttr_device: g=%h i=%h", cyc, g_io_chi_tx_req_bits_memAttr_device, i_io_chi_tx_req_bits_memAttr_device); end
    if (g_io_chi_tx_req_bits_memAttr_ewa !== i_io_chi_tx_req_bits_memAttr_ewa) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_req_bits_memAttr_ewa: g=%h i=%h", cyc, g_io_chi_tx_req_bits_memAttr_ewa, i_io_chi_tx_req_bits_memAttr_ewa); end
    if (g_io_chi_tx_dat_valid !== i_io_chi_tx_dat_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_valid: g=%h i=%h", cyc, g_io_chi_tx_dat_valid, i_io_chi_tx_dat_valid); end
    if (g_io_chi_tx_dat_bits_tgtID !== i_io_chi_tx_dat_bits_tgtID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_tgtID: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_tgtID, i_io_chi_tx_dat_bits_tgtID); end
    if (g_io_chi_tx_dat_bits_txnID !== i_io_chi_tx_dat_bits_txnID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_txnID: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_txnID, i_io_chi_tx_dat_bits_txnID); end
    if (g_io_chi_tx_dat_bits_respErr !== i_io_chi_tx_dat_bits_respErr) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_respErr: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_respErr, i_io_chi_tx_dat_bits_respErr); end
    if (g_io_chi_tx_dat_bits_ccID !== i_io_chi_tx_dat_bits_ccID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_ccID: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_ccID, i_io_chi_tx_dat_bits_ccID); end
    if (g_io_chi_tx_dat_bits_dataID !== i_io_chi_tx_dat_bits_dataID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_dataID: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_dataID, i_io_chi_tx_dat_bits_dataID); end
    if (g_io_chi_tx_dat_bits_traceTag !== i_io_chi_tx_dat_bits_traceTag) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_traceTag: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_traceTag, i_io_chi_tx_dat_bits_traceTag); end
    if (g_io_chi_tx_dat_bits_be !== i_io_chi_tx_dat_bits_be) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_be: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_be, i_io_chi_tx_dat_bits_be); end
    if (g_io_chi_tx_dat_bits_data !== i_io_chi_tx_dat_bits_data) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_data: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_data, i_io_chi_tx_dat_bits_data); end
    if (g_io_chi_tx_dat_bits_dataCheck !== i_io_chi_tx_dat_bits_dataCheck) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_dataCheck: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_dataCheck, i_io_chi_tx_dat_bits_dataCheck); end
    if (g_io_chi_tx_dat_bits_poison !== i_io_chi_tx_dat_bits_poison) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_tx_dat_bits_poison: g=%h i=%h", cyc, g_io_chi_tx_dat_bits_poison, i_io_chi_tx_dat_bits_poison); end
    if (g_io_chi_rx_rsp_ready !== i_io_chi_rx_rsp_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_rx_rsp_ready: g=%h i=%h", cyc, g_io_chi_rx_rsp_ready, i_io_chi_rx_rsp_ready); end
    if (g_io_chi_rx_dat_ready !== i_io_chi_rx_dat_ready) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_chi_rx_dat_ready: g=%h i=%h", cyc, g_io_chi_rx_dat_ready, i_io_chi_rx_dat_ready); end
    if (g_io_pCrd_query_valid !== i_io_pCrd_query_valid) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_pCrd_query_valid: g=%h i=%h", cyc, g_io_pCrd_query_valid, i_io_pCrd_query_valid); end
    if (g_io_pCrd_query_bits_pCrdType !== i_io_pCrd_query_bits_pCrdType) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_pCrd_query_bits_pCrdType: g=%h i=%h", cyc, g_io_pCrd_query_bits_pCrdType, i_io_pCrd_query_bits_pCrdType); end
    if (g_io_pCrd_query_bits_srcID !== i_io_pCrd_query_bits_srcID) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_pCrd_query_bits_srcID: g=%h i=%h", cyc, g_io_pCrd_query_bits_srcID, i_io_pCrd_query_bits_srcID); end
    if (g_io_waitOnReadReceipt !== i_io_waitOnReadReceipt) begin errors++; if (errors<=20) $display("[%0d] MISMATCH io_waitOnReadReceipt: g=%h i=%h", cyc, g_io_waitOnReadReceipt, i_io_waitOnReadReceipt); end
  endtask

  initial begin
    rst = 1'b1;
    io_req_valid = '0;
    io_req_bits_opcode = '0;
    io_req_bits_size = '0;
    io_req_bits_source = '0;
    io_req_bits_address = '0;
    io_req_bits_user_memBackType_MM = '0;
    io_req_bits_user_memPageType_NC = '0;
    io_req_bits_mask = '0;
    io_req_bits_data = '0;
    io_req_bits_corrupt = '0;
    io_resp_ready = '0;
    io_chi_tx_req_ready = '0;
    io_chi_tx_dat_ready = '0;
    io_chi_rx_rsp_valid = '0;
    io_chi_rx_rsp_bits_srcID = '0;
    io_chi_rx_rsp_bits_opcode = '0;
    io_chi_rx_rsp_bits_respErr = '0;
    io_chi_rx_rsp_bits_dbID = '0;
    io_chi_rx_rsp_bits_pCrdType = '0;
    io_chi_rx_rsp_bits_traceTag = '0;
    io_chi_rx_dat_valid = '0;
    io_chi_rx_dat_bits_respErr = '0;
    io_chi_rx_dat_bits_data = '0;
    io_chi_rx_dat_bits_dataCheck = '0;
    io_chi_rx_dat_bits_poison = '0;
    io_id = '0;
    io_pCrd_grant = '0;
    repeat (6) @(posedge clk);
    @(negedge clk); rst = 1'b0;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      drive_random();
      @(posedge clk);
      #1;
      if (cyc >= WARMUP) check_outputs();
    end
    if (errors == 0) $display("TEST PASSED: checks=%0d errors=0", checks);
    else $display("TEST FAILED: checks=%0d errors=%0d", checks, errors);
    $finish;
  end
endmodule

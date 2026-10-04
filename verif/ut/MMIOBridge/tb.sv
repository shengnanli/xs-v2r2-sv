// MMIOBridge 双例化 UT（由 gen.py 生成，勿手改）
`timescale 1ns/1ps
module tb;
  int unsigned NCYCLES = 200000;
  int errors = 0, checks = 0, cov_fail = 0;
  int unsigned cyc = 0;
  logic clk = 1'b0;
  always #5 clk = ~clk;
  localparam int RESET_CYC = 8;

  // ================= MMIOBridge =================
  int unsigned mb_mode = 0;
  wire [15:0] mb_rsp_rdy = {mb_u_gold._entries_15_io_chi_rx_rsp_ready, mb_u_gold._entries_14_io_chi_rx_rsp_ready, mb_u_gold._entries_13_io_chi_rx_rsp_ready, mb_u_gold._entries_12_io_chi_rx_rsp_ready, mb_u_gold._entries_11_io_chi_rx_rsp_ready, mb_u_gold._entries_10_io_chi_rx_rsp_ready, mb_u_gold._entries_9_io_chi_rx_rsp_ready, mb_u_gold._entries_8_io_chi_rx_rsp_ready, mb_u_gold._entries_7_io_chi_rx_rsp_ready, mb_u_gold._entries_6_io_chi_rx_rsp_ready, mb_u_gold._entries_5_io_chi_rx_rsp_ready, mb_u_gold._entries_4_io_chi_rx_rsp_ready, mb_u_gold._entries_3_io_chi_rx_rsp_ready, mb_u_gold._entries_2_io_chi_rx_rsp_ready, mb_u_gold._entries_1_io_chi_rx_rsp_ready, mb_u_gold._entries_0_io_chi_rx_rsp_ready};
  wire [15:0] mb_dat_rdy = {mb_u_gold._entries_15_io_chi_rx_dat_ready, mb_u_gold._entries_14_io_chi_rx_dat_ready, mb_u_gold._entries_13_io_chi_rx_dat_ready, mb_u_gold._entries_12_io_chi_rx_dat_ready, mb_u_gold._entries_11_io_chi_rx_dat_ready, mb_u_gold._entries_10_io_chi_rx_dat_ready, mb_u_gold._entries_9_io_chi_rx_dat_ready, mb_u_gold._entries_8_io_chi_rx_dat_ready, mb_u_gold._entries_7_io_chi_rx_dat_ready, mb_u_gold._entries_6_io_chi_rx_dat_ready, mb_u_gold._entries_5_io_chi_rx_dat_ready, mb_u_gold._entries_4_io_chi_rx_dat_ready, mb_u_gold._entries_3_io_chi_rx_dat_ready, mb_u_gold._entries_2_io_chi_rx_dat_ready, mb_u_gold._entries_1_io_chi_rx_dat_ready, mb_u_gold._entries_0_io_chi_rx_dat_ready};
  initial begin
    #1;
    force mb_u_impl.entries_0.u_core.s_txreq = mb_u_gold.entries_0.s_txreq;
    force mb_u_impl.entries_0.u_core.s_ncbwrdata = mb_u_gold.entries_0.s_ncbwrdata;
    force mb_u_impl.entries_0.u_core.s_resp = mb_u_gold.entries_0.s_resp;
    force mb_u_impl.entries_0.u_core.w_comp = mb_u_gold.entries_0.w_comp;
    force mb_u_impl.entries_0.u_core.w_dbidresp = mb_u_gold.entries_0.w_dbidresp;
    force mb_u_impl.entries_0.u_core.w_compdata = mb_u_gold.entries_0.w_compdata;
    force mb_u_impl.entries_0.u_core.w_pcrdgrant = mb_u_gold.entries_0.w_pcrdgrant;
    force mb_u_impl.entries_0.u_core.w_readreceipt = mb_u_gold.entries_0.w_readreceipt;
    force mb_u_impl.entries_0.u_core.allowRetry = mb_u_gold.entries_0.allowRetry;
    force mb_u_impl.entries_0.u_core.req_opcode = mb_u_gold.entries_0.req_opcode;
    force mb_u_impl.entries_0.u_core.req_size = mb_u_gold.entries_0.req_size;
    force mb_u_impl.entries_0.u_core.req_source = mb_u_gold.entries_0.req_source;
    force mb_u_impl.entries_0.u_core.req_address = mb_u_gold.entries_0.req_address;
    force mb_u_impl.entries_0.u_core.req_user_memBackType_MM = mb_u_gold.entries_0.req_user_memBackType_MM;
    force mb_u_impl.entries_0.u_core.req_user_memPageType_NC = mb_u_gold.entries_0.req_user_memPageType_NC;
    force mb_u_impl.entries_0.u_core.req_mask = mb_u_gold.entries_0.req_mask;
    force mb_u_impl.entries_0.u_core.req_data = mb_u_gold.entries_0.req_data;
    force mb_u_impl.entries_0.u_core.req_corrupt = mb_u_gold.entries_0.req_corrupt;
    force mb_u_impl.entries_0.u_core.rdata = mb_u_gold.entries_0.rdata;
    force mb_u_impl.entries_0.u_core.srcID = mb_u_gold.entries_0.srcID;
    force mb_u_impl.entries_0.u_core.dbID = mb_u_gold.entries_0.dbID;
    force mb_u_impl.entries_0.u_core.pCrdType = mb_u_gold.entries_0.pCrdType;
    force mb_u_impl.entries_0.u_core.denied = mb_u_gold.entries_0.denied;
    force mb_u_impl.entries_0.u_core.corrupt = mb_u_gold.entries_0.corrupt;
    force mb_u_impl.entries_0.u_core.traceTag = mb_u_gold.entries_0.traceTag;
    force mb_u_impl.entries_1.u_core.s_txreq = mb_u_gold.entries_1.s_txreq;
    force mb_u_impl.entries_1.u_core.s_ncbwrdata = mb_u_gold.entries_1.s_ncbwrdata;
    force mb_u_impl.entries_1.u_core.s_resp = mb_u_gold.entries_1.s_resp;
    force mb_u_impl.entries_1.u_core.w_comp = mb_u_gold.entries_1.w_comp;
    force mb_u_impl.entries_1.u_core.w_dbidresp = mb_u_gold.entries_1.w_dbidresp;
    force mb_u_impl.entries_1.u_core.w_compdata = mb_u_gold.entries_1.w_compdata;
    force mb_u_impl.entries_1.u_core.w_pcrdgrant = mb_u_gold.entries_1.w_pcrdgrant;
    force mb_u_impl.entries_1.u_core.w_readreceipt = mb_u_gold.entries_1.w_readreceipt;
    force mb_u_impl.entries_1.u_core.allowRetry = mb_u_gold.entries_1.allowRetry;
    force mb_u_impl.entries_1.u_core.req_opcode = mb_u_gold.entries_1.req_opcode;
    force mb_u_impl.entries_1.u_core.req_size = mb_u_gold.entries_1.req_size;
    force mb_u_impl.entries_1.u_core.req_source = mb_u_gold.entries_1.req_source;
    force mb_u_impl.entries_1.u_core.req_address = mb_u_gold.entries_1.req_address;
    force mb_u_impl.entries_1.u_core.req_user_memBackType_MM = mb_u_gold.entries_1.req_user_memBackType_MM;
    force mb_u_impl.entries_1.u_core.req_user_memPageType_NC = mb_u_gold.entries_1.req_user_memPageType_NC;
    force mb_u_impl.entries_1.u_core.req_mask = mb_u_gold.entries_1.req_mask;
    force mb_u_impl.entries_1.u_core.req_data = mb_u_gold.entries_1.req_data;
    force mb_u_impl.entries_1.u_core.req_corrupt = mb_u_gold.entries_1.req_corrupt;
    force mb_u_impl.entries_1.u_core.rdata = mb_u_gold.entries_1.rdata;
    force mb_u_impl.entries_1.u_core.srcID = mb_u_gold.entries_1.srcID;
    force mb_u_impl.entries_1.u_core.dbID = mb_u_gold.entries_1.dbID;
    force mb_u_impl.entries_1.u_core.pCrdType = mb_u_gold.entries_1.pCrdType;
    force mb_u_impl.entries_1.u_core.denied = mb_u_gold.entries_1.denied;
    force mb_u_impl.entries_1.u_core.corrupt = mb_u_gold.entries_1.corrupt;
    force mb_u_impl.entries_1.u_core.traceTag = mb_u_gold.entries_1.traceTag;
    force mb_u_impl.entries_2.u_core.s_txreq = mb_u_gold.entries_2.s_txreq;
    force mb_u_impl.entries_2.u_core.s_ncbwrdata = mb_u_gold.entries_2.s_ncbwrdata;
    force mb_u_impl.entries_2.u_core.s_resp = mb_u_gold.entries_2.s_resp;
    force mb_u_impl.entries_2.u_core.w_comp = mb_u_gold.entries_2.w_comp;
    force mb_u_impl.entries_2.u_core.w_dbidresp = mb_u_gold.entries_2.w_dbidresp;
    force mb_u_impl.entries_2.u_core.w_compdata = mb_u_gold.entries_2.w_compdata;
    force mb_u_impl.entries_2.u_core.w_pcrdgrant = mb_u_gold.entries_2.w_pcrdgrant;
    force mb_u_impl.entries_2.u_core.w_readreceipt = mb_u_gold.entries_2.w_readreceipt;
    force mb_u_impl.entries_2.u_core.allowRetry = mb_u_gold.entries_2.allowRetry;
    force mb_u_impl.entries_2.u_core.req_opcode = mb_u_gold.entries_2.req_opcode;
    force mb_u_impl.entries_2.u_core.req_size = mb_u_gold.entries_2.req_size;
    force mb_u_impl.entries_2.u_core.req_source = mb_u_gold.entries_2.req_source;
    force mb_u_impl.entries_2.u_core.req_address = mb_u_gold.entries_2.req_address;
    force mb_u_impl.entries_2.u_core.req_user_memBackType_MM = mb_u_gold.entries_2.req_user_memBackType_MM;
    force mb_u_impl.entries_2.u_core.req_user_memPageType_NC = mb_u_gold.entries_2.req_user_memPageType_NC;
    force mb_u_impl.entries_2.u_core.req_mask = mb_u_gold.entries_2.req_mask;
    force mb_u_impl.entries_2.u_core.req_data = mb_u_gold.entries_2.req_data;
    force mb_u_impl.entries_2.u_core.req_corrupt = mb_u_gold.entries_2.req_corrupt;
    force mb_u_impl.entries_2.u_core.rdata = mb_u_gold.entries_2.rdata;
    force mb_u_impl.entries_2.u_core.srcID = mb_u_gold.entries_2.srcID;
    force mb_u_impl.entries_2.u_core.dbID = mb_u_gold.entries_2.dbID;
    force mb_u_impl.entries_2.u_core.pCrdType = mb_u_gold.entries_2.pCrdType;
    force mb_u_impl.entries_2.u_core.denied = mb_u_gold.entries_2.denied;
    force mb_u_impl.entries_2.u_core.corrupt = mb_u_gold.entries_2.corrupt;
    force mb_u_impl.entries_2.u_core.traceTag = mb_u_gold.entries_2.traceTag;
    force mb_u_impl.entries_3.u_core.s_txreq = mb_u_gold.entries_3.s_txreq;
    force mb_u_impl.entries_3.u_core.s_ncbwrdata = mb_u_gold.entries_3.s_ncbwrdata;
    force mb_u_impl.entries_3.u_core.s_resp = mb_u_gold.entries_3.s_resp;
    force mb_u_impl.entries_3.u_core.w_comp = mb_u_gold.entries_3.w_comp;
    force mb_u_impl.entries_3.u_core.w_dbidresp = mb_u_gold.entries_3.w_dbidresp;
    force mb_u_impl.entries_3.u_core.w_compdata = mb_u_gold.entries_3.w_compdata;
    force mb_u_impl.entries_3.u_core.w_pcrdgrant = mb_u_gold.entries_3.w_pcrdgrant;
    force mb_u_impl.entries_3.u_core.w_readreceipt = mb_u_gold.entries_3.w_readreceipt;
    force mb_u_impl.entries_3.u_core.allowRetry = mb_u_gold.entries_3.allowRetry;
    force mb_u_impl.entries_3.u_core.req_opcode = mb_u_gold.entries_3.req_opcode;
    force mb_u_impl.entries_3.u_core.req_size = mb_u_gold.entries_3.req_size;
    force mb_u_impl.entries_3.u_core.req_source = mb_u_gold.entries_3.req_source;
    force mb_u_impl.entries_3.u_core.req_address = mb_u_gold.entries_3.req_address;
    force mb_u_impl.entries_3.u_core.req_user_memBackType_MM = mb_u_gold.entries_3.req_user_memBackType_MM;
    force mb_u_impl.entries_3.u_core.req_user_memPageType_NC = mb_u_gold.entries_3.req_user_memPageType_NC;
    force mb_u_impl.entries_3.u_core.req_mask = mb_u_gold.entries_3.req_mask;
    force mb_u_impl.entries_3.u_core.req_data = mb_u_gold.entries_3.req_data;
    force mb_u_impl.entries_3.u_core.req_corrupt = mb_u_gold.entries_3.req_corrupt;
    force mb_u_impl.entries_3.u_core.rdata = mb_u_gold.entries_3.rdata;
    force mb_u_impl.entries_3.u_core.srcID = mb_u_gold.entries_3.srcID;
    force mb_u_impl.entries_3.u_core.dbID = mb_u_gold.entries_3.dbID;
    force mb_u_impl.entries_3.u_core.pCrdType = mb_u_gold.entries_3.pCrdType;
    force mb_u_impl.entries_3.u_core.denied = mb_u_gold.entries_3.denied;
    force mb_u_impl.entries_3.u_core.corrupt = mb_u_gold.entries_3.corrupt;
    force mb_u_impl.entries_3.u_core.traceTag = mb_u_gold.entries_3.traceTag;
    force mb_u_impl.entries_4.u_core.s_txreq = mb_u_gold.entries_4.s_txreq;
    force mb_u_impl.entries_4.u_core.s_ncbwrdata = mb_u_gold.entries_4.s_ncbwrdata;
    force mb_u_impl.entries_4.u_core.s_resp = mb_u_gold.entries_4.s_resp;
    force mb_u_impl.entries_4.u_core.w_comp = mb_u_gold.entries_4.w_comp;
    force mb_u_impl.entries_4.u_core.w_dbidresp = mb_u_gold.entries_4.w_dbidresp;
    force mb_u_impl.entries_4.u_core.w_compdata = mb_u_gold.entries_4.w_compdata;
    force mb_u_impl.entries_4.u_core.w_pcrdgrant = mb_u_gold.entries_4.w_pcrdgrant;
    force mb_u_impl.entries_4.u_core.w_readreceipt = mb_u_gold.entries_4.w_readreceipt;
    force mb_u_impl.entries_4.u_core.allowRetry = mb_u_gold.entries_4.allowRetry;
    force mb_u_impl.entries_4.u_core.req_opcode = mb_u_gold.entries_4.req_opcode;
    force mb_u_impl.entries_4.u_core.req_size = mb_u_gold.entries_4.req_size;
    force mb_u_impl.entries_4.u_core.req_source = mb_u_gold.entries_4.req_source;
    force mb_u_impl.entries_4.u_core.req_address = mb_u_gold.entries_4.req_address;
    force mb_u_impl.entries_4.u_core.req_user_memBackType_MM = mb_u_gold.entries_4.req_user_memBackType_MM;
    force mb_u_impl.entries_4.u_core.req_user_memPageType_NC = mb_u_gold.entries_4.req_user_memPageType_NC;
    force mb_u_impl.entries_4.u_core.req_mask = mb_u_gold.entries_4.req_mask;
    force mb_u_impl.entries_4.u_core.req_data = mb_u_gold.entries_4.req_data;
    force mb_u_impl.entries_4.u_core.req_corrupt = mb_u_gold.entries_4.req_corrupt;
    force mb_u_impl.entries_4.u_core.rdata = mb_u_gold.entries_4.rdata;
    force mb_u_impl.entries_4.u_core.srcID = mb_u_gold.entries_4.srcID;
    force mb_u_impl.entries_4.u_core.dbID = mb_u_gold.entries_4.dbID;
    force mb_u_impl.entries_4.u_core.pCrdType = mb_u_gold.entries_4.pCrdType;
    force mb_u_impl.entries_4.u_core.denied = mb_u_gold.entries_4.denied;
    force mb_u_impl.entries_4.u_core.corrupt = mb_u_gold.entries_4.corrupt;
    force mb_u_impl.entries_4.u_core.traceTag = mb_u_gold.entries_4.traceTag;
    force mb_u_impl.entries_5.u_core.s_txreq = mb_u_gold.entries_5.s_txreq;
    force mb_u_impl.entries_5.u_core.s_ncbwrdata = mb_u_gold.entries_5.s_ncbwrdata;
    force mb_u_impl.entries_5.u_core.s_resp = mb_u_gold.entries_5.s_resp;
    force mb_u_impl.entries_5.u_core.w_comp = mb_u_gold.entries_5.w_comp;
    force mb_u_impl.entries_5.u_core.w_dbidresp = mb_u_gold.entries_5.w_dbidresp;
    force mb_u_impl.entries_5.u_core.w_compdata = mb_u_gold.entries_5.w_compdata;
    force mb_u_impl.entries_5.u_core.w_pcrdgrant = mb_u_gold.entries_5.w_pcrdgrant;
    force mb_u_impl.entries_5.u_core.w_readreceipt = mb_u_gold.entries_5.w_readreceipt;
    force mb_u_impl.entries_5.u_core.allowRetry = mb_u_gold.entries_5.allowRetry;
    force mb_u_impl.entries_5.u_core.req_opcode = mb_u_gold.entries_5.req_opcode;
    force mb_u_impl.entries_5.u_core.req_size = mb_u_gold.entries_5.req_size;
    force mb_u_impl.entries_5.u_core.req_source = mb_u_gold.entries_5.req_source;
    force mb_u_impl.entries_5.u_core.req_address = mb_u_gold.entries_5.req_address;
    force mb_u_impl.entries_5.u_core.req_user_memBackType_MM = mb_u_gold.entries_5.req_user_memBackType_MM;
    force mb_u_impl.entries_5.u_core.req_user_memPageType_NC = mb_u_gold.entries_5.req_user_memPageType_NC;
    force mb_u_impl.entries_5.u_core.req_mask = mb_u_gold.entries_5.req_mask;
    force mb_u_impl.entries_5.u_core.req_data = mb_u_gold.entries_5.req_data;
    force mb_u_impl.entries_5.u_core.req_corrupt = mb_u_gold.entries_5.req_corrupt;
    force mb_u_impl.entries_5.u_core.rdata = mb_u_gold.entries_5.rdata;
    force mb_u_impl.entries_5.u_core.srcID = mb_u_gold.entries_5.srcID;
    force mb_u_impl.entries_5.u_core.dbID = mb_u_gold.entries_5.dbID;
    force mb_u_impl.entries_5.u_core.pCrdType = mb_u_gold.entries_5.pCrdType;
    force mb_u_impl.entries_5.u_core.denied = mb_u_gold.entries_5.denied;
    force mb_u_impl.entries_5.u_core.corrupt = mb_u_gold.entries_5.corrupt;
    force mb_u_impl.entries_5.u_core.traceTag = mb_u_gold.entries_5.traceTag;
    force mb_u_impl.entries_6.u_core.s_txreq = mb_u_gold.entries_6.s_txreq;
    force mb_u_impl.entries_6.u_core.s_ncbwrdata = mb_u_gold.entries_6.s_ncbwrdata;
    force mb_u_impl.entries_6.u_core.s_resp = mb_u_gold.entries_6.s_resp;
    force mb_u_impl.entries_6.u_core.w_comp = mb_u_gold.entries_6.w_comp;
    force mb_u_impl.entries_6.u_core.w_dbidresp = mb_u_gold.entries_6.w_dbidresp;
    force mb_u_impl.entries_6.u_core.w_compdata = mb_u_gold.entries_6.w_compdata;
    force mb_u_impl.entries_6.u_core.w_pcrdgrant = mb_u_gold.entries_6.w_pcrdgrant;
    force mb_u_impl.entries_6.u_core.w_readreceipt = mb_u_gold.entries_6.w_readreceipt;
    force mb_u_impl.entries_6.u_core.allowRetry = mb_u_gold.entries_6.allowRetry;
    force mb_u_impl.entries_6.u_core.req_opcode = mb_u_gold.entries_6.req_opcode;
    force mb_u_impl.entries_6.u_core.req_size = mb_u_gold.entries_6.req_size;
    force mb_u_impl.entries_6.u_core.req_source = mb_u_gold.entries_6.req_source;
    force mb_u_impl.entries_6.u_core.req_address = mb_u_gold.entries_6.req_address;
    force mb_u_impl.entries_6.u_core.req_user_memBackType_MM = mb_u_gold.entries_6.req_user_memBackType_MM;
    force mb_u_impl.entries_6.u_core.req_user_memPageType_NC = mb_u_gold.entries_6.req_user_memPageType_NC;
    force mb_u_impl.entries_6.u_core.req_mask = mb_u_gold.entries_6.req_mask;
    force mb_u_impl.entries_6.u_core.req_data = mb_u_gold.entries_6.req_data;
    force mb_u_impl.entries_6.u_core.req_corrupt = mb_u_gold.entries_6.req_corrupt;
    force mb_u_impl.entries_6.u_core.rdata = mb_u_gold.entries_6.rdata;
    force mb_u_impl.entries_6.u_core.srcID = mb_u_gold.entries_6.srcID;
    force mb_u_impl.entries_6.u_core.dbID = mb_u_gold.entries_6.dbID;
    force mb_u_impl.entries_6.u_core.pCrdType = mb_u_gold.entries_6.pCrdType;
    force mb_u_impl.entries_6.u_core.denied = mb_u_gold.entries_6.denied;
    force mb_u_impl.entries_6.u_core.corrupt = mb_u_gold.entries_6.corrupt;
    force mb_u_impl.entries_6.u_core.traceTag = mb_u_gold.entries_6.traceTag;
    force mb_u_impl.entries_7.u_core.s_txreq = mb_u_gold.entries_7.s_txreq;
    force mb_u_impl.entries_7.u_core.s_ncbwrdata = mb_u_gold.entries_7.s_ncbwrdata;
    force mb_u_impl.entries_7.u_core.s_resp = mb_u_gold.entries_7.s_resp;
    force mb_u_impl.entries_7.u_core.w_comp = mb_u_gold.entries_7.w_comp;
    force mb_u_impl.entries_7.u_core.w_dbidresp = mb_u_gold.entries_7.w_dbidresp;
    force mb_u_impl.entries_7.u_core.w_compdata = mb_u_gold.entries_7.w_compdata;
    force mb_u_impl.entries_7.u_core.w_pcrdgrant = mb_u_gold.entries_7.w_pcrdgrant;
    force mb_u_impl.entries_7.u_core.w_readreceipt = mb_u_gold.entries_7.w_readreceipt;
    force mb_u_impl.entries_7.u_core.allowRetry = mb_u_gold.entries_7.allowRetry;
    force mb_u_impl.entries_7.u_core.req_opcode = mb_u_gold.entries_7.req_opcode;
    force mb_u_impl.entries_7.u_core.req_size = mb_u_gold.entries_7.req_size;
    force mb_u_impl.entries_7.u_core.req_source = mb_u_gold.entries_7.req_source;
    force mb_u_impl.entries_7.u_core.req_address = mb_u_gold.entries_7.req_address;
    force mb_u_impl.entries_7.u_core.req_user_memBackType_MM = mb_u_gold.entries_7.req_user_memBackType_MM;
    force mb_u_impl.entries_7.u_core.req_user_memPageType_NC = mb_u_gold.entries_7.req_user_memPageType_NC;
    force mb_u_impl.entries_7.u_core.req_mask = mb_u_gold.entries_7.req_mask;
    force mb_u_impl.entries_7.u_core.req_data = mb_u_gold.entries_7.req_data;
    force mb_u_impl.entries_7.u_core.req_corrupt = mb_u_gold.entries_7.req_corrupt;
    force mb_u_impl.entries_7.u_core.rdata = mb_u_gold.entries_7.rdata;
    force mb_u_impl.entries_7.u_core.srcID = mb_u_gold.entries_7.srcID;
    force mb_u_impl.entries_7.u_core.dbID = mb_u_gold.entries_7.dbID;
    force mb_u_impl.entries_7.u_core.pCrdType = mb_u_gold.entries_7.pCrdType;
    force mb_u_impl.entries_7.u_core.denied = mb_u_gold.entries_7.denied;
    force mb_u_impl.entries_7.u_core.corrupt = mb_u_gold.entries_7.corrupt;
    force mb_u_impl.entries_7.u_core.traceTag = mb_u_gold.entries_7.traceTag;
    force mb_u_impl.entries_8.u_core.s_txreq = mb_u_gold.entries_8.s_txreq;
    force mb_u_impl.entries_8.u_core.s_ncbwrdata = mb_u_gold.entries_8.s_ncbwrdata;
    force mb_u_impl.entries_8.u_core.s_resp = mb_u_gold.entries_8.s_resp;
    force mb_u_impl.entries_8.u_core.w_comp = mb_u_gold.entries_8.w_comp;
    force mb_u_impl.entries_8.u_core.w_dbidresp = mb_u_gold.entries_8.w_dbidresp;
    force mb_u_impl.entries_8.u_core.w_compdata = mb_u_gold.entries_8.w_compdata;
    force mb_u_impl.entries_8.u_core.w_pcrdgrant = mb_u_gold.entries_8.w_pcrdgrant;
    force mb_u_impl.entries_8.u_core.w_readreceipt = mb_u_gold.entries_8.w_readreceipt;
    force mb_u_impl.entries_8.u_core.allowRetry = mb_u_gold.entries_8.allowRetry;
    force mb_u_impl.entries_8.u_core.req_opcode = mb_u_gold.entries_8.req_opcode;
    force mb_u_impl.entries_8.u_core.req_size = mb_u_gold.entries_8.req_size;
    force mb_u_impl.entries_8.u_core.req_source = mb_u_gold.entries_8.req_source;
    force mb_u_impl.entries_8.u_core.req_address = mb_u_gold.entries_8.req_address;
    force mb_u_impl.entries_8.u_core.req_user_memBackType_MM = mb_u_gold.entries_8.req_user_memBackType_MM;
    force mb_u_impl.entries_8.u_core.req_user_memPageType_NC = mb_u_gold.entries_8.req_user_memPageType_NC;
    force mb_u_impl.entries_8.u_core.req_mask = mb_u_gold.entries_8.req_mask;
    force mb_u_impl.entries_8.u_core.req_data = mb_u_gold.entries_8.req_data;
    force mb_u_impl.entries_8.u_core.req_corrupt = mb_u_gold.entries_8.req_corrupt;
    force mb_u_impl.entries_8.u_core.rdata = mb_u_gold.entries_8.rdata;
    force mb_u_impl.entries_8.u_core.srcID = mb_u_gold.entries_8.srcID;
    force mb_u_impl.entries_8.u_core.dbID = mb_u_gold.entries_8.dbID;
    force mb_u_impl.entries_8.u_core.pCrdType = mb_u_gold.entries_8.pCrdType;
    force mb_u_impl.entries_8.u_core.denied = mb_u_gold.entries_8.denied;
    force mb_u_impl.entries_8.u_core.corrupt = mb_u_gold.entries_8.corrupt;
    force mb_u_impl.entries_8.u_core.traceTag = mb_u_gold.entries_8.traceTag;
    force mb_u_impl.entries_9.u_core.s_txreq = mb_u_gold.entries_9.s_txreq;
    force mb_u_impl.entries_9.u_core.s_ncbwrdata = mb_u_gold.entries_9.s_ncbwrdata;
    force mb_u_impl.entries_9.u_core.s_resp = mb_u_gold.entries_9.s_resp;
    force mb_u_impl.entries_9.u_core.w_comp = mb_u_gold.entries_9.w_comp;
    force mb_u_impl.entries_9.u_core.w_dbidresp = mb_u_gold.entries_9.w_dbidresp;
    force mb_u_impl.entries_9.u_core.w_compdata = mb_u_gold.entries_9.w_compdata;
    force mb_u_impl.entries_9.u_core.w_pcrdgrant = mb_u_gold.entries_9.w_pcrdgrant;
    force mb_u_impl.entries_9.u_core.w_readreceipt = mb_u_gold.entries_9.w_readreceipt;
    force mb_u_impl.entries_9.u_core.allowRetry = mb_u_gold.entries_9.allowRetry;
    force mb_u_impl.entries_9.u_core.req_opcode = mb_u_gold.entries_9.req_opcode;
    force mb_u_impl.entries_9.u_core.req_size = mb_u_gold.entries_9.req_size;
    force mb_u_impl.entries_9.u_core.req_source = mb_u_gold.entries_9.req_source;
    force mb_u_impl.entries_9.u_core.req_address = mb_u_gold.entries_9.req_address;
    force mb_u_impl.entries_9.u_core.req_user_memBackType_MM = mb_u_gold.entries_9.req_user_memBackType_MM;
    force mb_u_impl.entries_9.u_core.req_user_memPageType_NC = mb_u_gold.entries_9.req_user_memPageType_NC;
    force mb_u_impl.entries_9.u_core.req_mask = mb_u_gold.entries_9.req_mask;
    force mb_u_impl.entries_9.u_core.req_data = mb_u_gold.entries_9.req_data;
    force mb_u_impl.entries_9.u_core.req_corrupt = mb_u_gold.entries_9.req_corrupt;
    force mb_u_impl.entries_9.u_core.rdata = mb_u_gold.entries_9.rdata;
    force mb_u_impl.entries_9.u_core.srcID = mb_u_gold.entries_9.srcID;
    force mb_u_impl.entries_9.u_core.dbID = mb_u_gold.entries_9.dbID;
    force mb_u_impl.entries_9.u_core.pCrdType = mb_u_gold.entries_9.pCrdType;
    force mb_u_impl.entries_9.u_core.denied = mb_u_gold.entries_9.denied;
    force mb_u_impl.entries_9.u_core.corrupt = mb_u_gold.entries_9.corrupt;
    force mb_u_impl.entries_9.u_core.traceTag = mb_u_gold.entries_9.traceTag;
    force mb_u_impl.entries_10.u_core.s_txreq = mb_u_gold.entries_10.s_txreq;
    force mb_u_impl.entries_10.u_core.s_ncbwrdata = mb_u_gold.entries_10.s_ncbwrdata;
    force mb_u_impl.entries_10.u_core.s_resp = mb_u_gold.entries_10.s_resp;
    force mb_u_impl.entries_10.u_core.w_comp = mb_u_gold.entries_10.w_comp;
    force mb_u_impl.entries_10.u_core.w_dbidresp = mb_u_gold.entries_10.w_dbidresp;
    force mb_u_impl.entries_10.u_core.w_compdata = mb_u_gold.entries_10.w_compdata;
    force mb_u_impl.entries_10.u_core.w_pcrdgrant = mb_u_gold.entries_10.w_pcrdgrant;
    force mb_u_impl.entries_10.u_core.w_readreceipt = mb_u_gold.entries_10.w_readreceipt;
    force mb_u_impl.entries_10.u_core.allowRetry = mb_u_gold.entries_10.allowRetry;
    force mb_u_impl.entries_10.u_core.req_opcode = mb_u_gold.entries_10.req_opcode;
    force mb_u_impl.entries_10.u_core.req_size = mb_u_gold.entries_10.req_size;
    force mb_u_impl.entries_10.u_core.req_source = mb_u_gold.entries_10.req_source;
    force mb_u_impl.entries_10.u_core.req_address = mb_u_gold.entries_10.req_address;
    force mb_u_impl.entries_10.u_core.req_user_memBackType_MM = mb_u_gold.entries_10.req_user_memBackType_MM;
    force mb_u_impl.entries_10.u_core.req_user_memPageType_NC = mb_u_gold.entries_10.req_user_memPageType_NC;
    force mb_u_impl.entries_10.u_core.req_mask = mb_u_gold.entries_10.req_mask;
    force mb_u_impl.entries_10.u_core.req_data = mb_u_gold.entries_10.req_data;
    force mb_u_impl.entries_10.u_core.req_corrupt = mb_u_gold.entries_10.req_corrupt;
    force mb_u_impl.entries_10.u_core.rdata = mb_u_gold.entries_10.rdata;
    force mb_u_impl.entries_10.u_core.srcID = mb_u_gold.entries_10.srcID;
    force mb_u_impl.entries_10.u_core.dbID = mb_u_gold.entries_10.dbID;
    force mb_u_impl.entries_10.u_core.pCrdType = mb_u_gold.entries_10.pCrdType;
    force mb_u_impl.entries_10.u_core.denied = mb_u_gold.entries_10.denied;
    force mb_u_impl.entries_10.u_core.corrupt = mb_u_gold.entries_10.corrupt;
    force mb_u_impl.entries_10.u_core.traceTag = mb_u_gold.entries_10.traceTag;
    force mb_u_impl.entries_11.u_core.s_txreq = mb_u_gold.entries_11.s_txreq;
    force mb_u_impl.entries_11.u_core.s_ncbwrdata = mb_u_gold.entries_11.s_ncbwrdata;
    force mb_u_impl.entries_11.u_core.s_resp = mb_u_gold.entries_11.s_resp;
    force mb_u_impl.entries_11.u_core.w_comp = mb_u_gold.entries_11.w_comp;
    force mb_u_impl.entries_11.u_core.w_dbidresp = mb_u_gold.entries_11.w_dbidresp;
    force mb_u_impl.entries_11.u_core.w_compdata = mb_u_gold.entries_11.w_compdata;
    force mb_u_impl.entries_11.u_core.w_pcrdgrant = mb_u_gold.entries_11.w_pcrdgrant;
    force mb_u_impl.entries_11.u_core.w_readreceipt = mb_u_gold.entries_11.w_readreceipt;
    force mb_u_impl.entries_11.u_core.allowRetry = mb_u_gold.entries_11.allowRetry;
    force mb_u_impl.entries_11.u_core.req_opcode = mb_u_gold.entries_11.req_opcode;
    force mb_u_impl.entries_11.u_core.req_size = mb_u_gold.entries_11.req_size;
    force mb_u_impl.entries_11.u_core.req_source = mb_u_gold.entries_11.req_source;
    force mb_u_impl.entries_11.u_core.req_address = mb_u_gold.entries_11.req_address;
    force mb_u_impl.entries_11.u_core.req_user_memBackType_MM = mb_u_gold.entries_11.req_user_memBackType_MM;
    force mb_u_impl.entries_11.u_core.req_user_memPageType_NC = mb_u_gold.entries_11.req_user_memPageType_NC;
    force mb_u_impl.entries_11.u_core.req_mask = mb_u_gold.entries_11.req_mask;
    force mb_u_impl.entries_11.u_core.req_data = mb_u_gold.entries_11.req_data;
    force mb_u_impl.entries_11.u_core.req_corrupt = mb_u_gold.entries_11.req_corrupt;
    force mb_u_impl.entries_11.u_core.rdata = mb_u_gold.entries_11.rdata;
    force mb_u_impl.entries_11.u_core.srcID = mb_u_gold.entries_11.srcID;
    force mb_u_impl.entries_11.u_core.dbID = mb_u_gold.entries_11.dbID;
    force mb_u_impl.entries_11.u_core.pCrdType = mb_u_gold.entries_11.pCrdType;
    force mb_u_impl.entries_11.u_core.denied = mb_u_gold.entries_11.denied;
    force mb_u_impl.entries_11.u_core.corrupt = mb_u_gold.entries_11.corrupt;
    force mb_u_impl.entries_11.u_core.traceTag = mb_u_gold.entries_11.traceTag;
    force mb_u_impl.entries_12.u_core.s_txreq = mb_u_gold.entries_12.s_txreq;
    force mb_u_impl.entries_12.u_core.s_ncbwrdata = mb_u_gold.entries_12.s_ncbwrdata;
    force mb_u_impl.entries_12.u_core.s_resp = mb_u_gold.entries_12.s_resp;
    force mb_u_impl.entries_12.u_core.w_comp = mb_u_gold.entries_12.w_comp;
    force mb_u_impl.entries_12.u_core.w_dbidresp = mb_u_gold.entries_12.w_dbidresp;
    force mb_u_impl.entries_12.u_core.w_compdata = mb_u_gold.entries_12.w_compdata;
    force mb_u_impl.entries_12.u_core.w_pcrdgrant = mb_u_gold.entries_12.w_pcrdgrant;
    force mb_u_impl.entries_12.u_core.w_readreceipt = mb_u_gold.entries_12.w_readreceipt;
    force mb_u_impl.entries_12.u_core.allowRetry = mb_u_gold.entries_12.allowRetry;
    force mb_u_impl.entries_12.u_core.req_opcode = mb_u_gold.entries_12.req_opcode;
    force mb_u_impl.entries_12.u_core.req_size = mb_u_gold.entries_12.req_size;
    force mb_u_impl.entries_12.u_core.req_source = mb_u_gold.entries_12.req_source;
    force mb_u_impl.entries_12.u_core.req_address = mb_u_gold.entries_12.req_address;
    force mb_u_impl.entries_12.u_core.req_user_memBackType_MM = mb_u_gold.entries_12.req_user_memBackType_MM;
    force mb_u_impl.entries_12.u_core.req_user_memPageType_NC = mb_u_gold.entries_12.req_user_memPageType_NC;
    force mb_u_impl.entries_12.u_core.req_mask = mb_u_gold.entries_12.req_mask;
    force mb_u_impl.entries_12.u_core.req_data = mb_u_gold.entries_12.req_data;
    force mb_u_impl.entries_12.u_core.req_corrupt = mb_u_gold.entries_12.req_corrupt;
    force mb_u_impl.entries_12.u_core.rdata = mb_u_gold.entries_12.rdata;
    force mb_u_impl.entries_12.u_core.srcID = mb_u_gold.entries_12.srcID;
    force mb_u_impl.entries_12.u_core.dbID = mb_u_gold.entries_12.dbID;
    force mb_u_impl.entries_12.u_core.pCrdType = mb_u_gold.entries_12.pCrdType;
    force mb_u_impl.entries_12.u_core.denied = mb_u_gold.entries_12.denied;
    force mb_u_impl.entries_12.u_core.corrupt = mb_u_gold.entries_12.corrupt;
    force mb_u_impl.entries_12.u_core.traceTag = mb_u_gold.entries_12.traceTag;
    force mb_u_impl.entries_13.u_core.s_txreq = mb_u_gold.entries_13.s_txreq;
    force mb_u_impl.entries_13.u_core.s_ncbwrdata = mb_u_gold.entries_13.s_ncbwrdata;
    force mb_u_impl.entries_13.u_core.s_resp = mb_u_gold.entries_13.s_resp;
    force mb_u_impl.entries_13.u_core.w_comp = mb_u_gold.entries_13.w_comp;
    force mb_u_impl.entries_13.u_core.w_dbidresp = mb_u_gold.entries_13.w_dbidresp;
    force mb_u_impl.entries_13.u_core.w_compdata = mb_u_gold.entries_13.w_compdata;
    force mb_u_impl.entries_13.u_core.w_pcrdgrant = mb_u_gold.entries_13.w_pcrdgrant;
    force mb_u_impl.entries_13.u_core.w_readreceipt = mb_u_gold.entries_13.w_readreceipt;
    force mb_u_impl.entries_13.u_core.allowRetry = mb_u_gold.entries_13.allowRetry;
    force mb_u_impl.entries_13.u_core.req_opcode = mb_u_gold.entries_13.req_opcode;
    force mb_u_impl.entries_13.u_core.req_size = mb_u_gold.entries_13.req_size;
    force mb_u_impl.entries_13.u_core.req_source = mb_u_gold.entries_13.req_source;
    force mb_u_impl.entries_13.u_core.req_address = mb_u_gold.entries_13.req_address;
    force mb_u_impl.entries_13.u_core.req_user_memBackType_MM = mb_u_gold.entries_13.req_user_memBackType_MM;
    force mb_u_impl.entries_13.u_core.req_user_memPageType_NC = mb_u_gold.entries_13.req_user_memPageType_NC;
    force mb_u_impl.entries_13.u_core.req_mask = mb_u_gold.entries_13.req_mask;
    force mb_u_impl.entries_13.u_core.req_data = mb_u_gold.entries_13.req_data;
    force mb_u_impl.entries_13.u_core.req_corrupt = mb_u_gold.entries_13.req_corrupt;
    force mb_u_impl.entries_13.u_core.rdata = mb_u_gold.entries_13.rdata;
    force mb_u_impl.entries_13.u_core.srcID = mb_u_gold.entries_13.srcID;
    force mb_u_impl.entries_13.u_core.dbID = mb_u_gold.entries_13.dbID;
    force mb_u_impl.entries_13.u_core.pCrdType = mb_u_gold.entries_13.pCrdType;
    force mb_u_impl.entries_13.u_core.denied = mb_u_gold.entries_13.denied;
    force mb_u_impl.entries_13.u_core.corrupt = mb_u_gold.entries_13.corrupt;
    force mb_u_impl.entries_13.u_core.traceTag = mb_u_gold.entries_13.traceTag;
    force mb_u_impl.entries_14.u_core.s_txreq = mb_u_gold.entries_14.s_txreq;
    force mb_u_impl.entries_14.u_core.s_ncbwrdata = mb_u_gold.entries_14.s_ncbwrdata;
    force mb_u_impl.entries_14.u_core.s_resp = mb_u_gold.entries_14.s_resp;
    force mb_u_impl.entries_14.u_core.w_comp = mb_u_gold.entries_14.w_comp;
    force mb_u_impl.entries_14.u_core.w_dbidresp = mb_u_gold.entries_14.w_dbidresp;
    force mb_u_impl.entries_14.u_core.w_compdata = mb_u_gold.entries_14.w_compdata;
    force mb_u_impl.entries_14.u_core.w_pcrdgrant = mb_u_gold.entries_14.w_pcrdgrant;
    force mb_u_impl.entries_14.u_core.w_readreceipt = mb_u_gold.entries_14.w_readreceipt;
    force mb_u_impl.entries_14.u_core.allowRetry = mb_u_gold.entries_14.allowRetry;
    force mb_u_impl.entries_14.u_core.req_opcode = mb_u_gold.entries_14.req_opcode;
    force mb_u_impl.entries_14.u_core.req_size = mb_u_gold.entries_14.req_size;
    force mb_u_impl.entries_14.u_core.req_source = mb_u_gold.entries_14.req_source;
    force mb_u_impl.entries_14.u_core.req_address = mb_u_gold.entries_14.req_address;
    force mb_u_impl.entries_14.u_core.req_user_memBackType_MM = mb_u_gold.entries_14.req_user_memBackType_MM;
    force mb_u_impl.entries_14.u_core.req_user_memPageType_NC = mb_u_gold.entries_14.req_user_memPageType_NC;
    force mb_u_impl.entries_14.u_core.req_mask = mb_u_gold.entries_14.req_mask;
    force mb_u_impl.entries_14.u_core.req_data = mb_u_gold.entries_14.req_data;
    force mb_u_impl.entries_14.u_core.req_corrupt = mb_u_gold.entries_14.req_corrupt;
    force mb_u_impl.entries_14.u_core.rdata = mb_u_gold.entries_14.rdata;
    force mb_u_impl.entries_14.u_core.srcID = mb_u_gold.entries_14.srcID;
    force mb_u_impl.entries_14.u_core.dbID = mb_u_gold.entries_14.dbID;
    force mb_u_impl.entries_14.u_core.pCrdType = mb_u_gold.entries_14.pCrdType;
    force mb_u_impl.entries_14.u_core.denied = mb_u_gold.entries_14.denied;
    force mb_u_impl.entries_14.u_core.corrupt = mb_u_gold.entries_14.corrupt;
    force mb_u_impl.entries_14.u_core.traceTag = mb_u_gold.entries_14.traceTag;
    force mb_u_impl.entries_15.u_core.s_txreq = mb_u_gold.entries_15.s_txreq;
    force mb_u_impl.entries_15.u_core.s_ncbwrdata = mb_u_gold.entries_15.s_ncbwrdata;
    force mb_u_impl.entries_15.u_core.s_resp = mb_u_gold.entries_15.s_resp;
    force mb_u_impl.entries_15.u_core.w_comp = mb_u_gold.entries_15.w_comp;
    force mb_u_impl.entries_15.u_core.w_dbidresp = mb_u_gold.entries_15.w_dbidresp;
    force mb_u_impl.entries_15.u_core.w_compdata = mb_u_gold.entries_15.w_compdata;
    force mb_u_impl.entries_15.u_core.w_pcrdgrant = mb_u_gold.entries_15.w_pcrdgrant;
    force mb_u_impl.entries_15.u_core.w_readreceipt = mb_u_gold.entries_15.w_readreceipt;
    force mb_u_impl.entries_15.u_core.allowRetry = mb_u_gold.entries_15.allowRetry;
    force mb_u_impl.entries_15.u_core.req_opcode = mb_u_gold.entries_15.req_opcode;
    force mb_u_impl.entries_15.u_core.req_size = mb_u_gold.entries_15.req_size;
    force mb_u_impl.entries_15.u_core.req_source = mb_u_gold.entries_15.req_source;
    force mb_u_impl.entries_15.u_core.req_address = mb_u_gold.entries_15.req_address;
    force mb_u_impl.entries_15.u_core.req_user_memBackType_MM = mb_u_gold.entries_15.req_user_memBackType_MM;
    force mb_u_impl.entries_15.u_core.req_user_memPageType_NC = mb_u_gold.entries_15.req_user_memPageType_NC;
    force mb_u_impl.entries_15.u_core.req_mask = mb_u_gold.entries_15.req_mask;
    force mb_u_impl.entries_15.u_core.req_data = mb_u_gold.entries_15.req_data;
    force mb_u_impl.entries_15.u_core.req_corrupt = mb_u_gold.entries_15.req_corrupt;
    force mb_u_impl.entries_15.u_core.rdata = mb_u_gold.entries_15.rdata;
    force mb_u_impl.entries_15.u_core.srcID = mb_u_gold.entries_15.srcID;
    force mb_u_impl.entries_15.u_core.dbID = mb_u_gold.entries_15.dbID;
    force mb_u_impl.entries_15.u_core.pCrdType = mb_u_gold.entries_15.pCrdType;
    force mb_u_impl.entries_15.u_core.denied = mb_u_gold.entries_15.denied;
    force mb_u_impl.entries_15.u_core.corrupt = mb_u_gold.entries_15.corrupt;
    force mb_u_impl.entries_15.u_core.traceTag = mb_u_gold.entries_15.traceTag;
    #0;
    release mb_u_impl.entries_0.u_core.s_txreq;
    release mb_u_impl.entries_0.u_core.s_ncbwrdata;
    release mb_u_impl.entries_0.u_core.s_resp;
    release mb_u_impl.entries_0.u_core.w_comp;
    release mb_u_impl.entries_0.u_core.w_dbidresp;
    release mb_u_impl.entries_0.u_core.w_compdata;
    release mb_u_impl.entries_0.u_core.w_pcrdgrant;
    release mb_u_impl.entries_0.u_core.w_readreceipt;
    release mb_u_impl.entries_0.u_core.allowRetry;
    release mb_u_impl.entries_0.u_core.req_opcode;
    release mb_u_impl.entries_0.u_core.req_size;
    release mb_u_impl.entries_0.u_core.req_source;
    release mb_u_impl.entries_0.u_core.req_address;
    release mb_u_impl.entries_0.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_0.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_0.u_core.req_mask;
    release mb_u_impl.entries_0.u_core.req_data;
    release mb_u_impl.entries_0.u_core.req_corrupt;
    release mb_u_impl.entries_0.u_core.rdata;
    release mb_u_impl.entries_0.u_core.srcID;
    release mb_u_impl.entries_0.u_core.dbID;
    release mb_u_impl.entries_0.u_core.pCrdType;
    release mb_u_impl.entries_0.u_core.denied;
    release mb_u_impl.entries_0.u_core.corrupt;
    release mb_u_impl.entries_0.u_core.traceTag;
    release mb_u_impl.entries_1.u_core.s_txreq;
    release mb_u_impl.entries_1.u_core.s_ncbwrdata;
    release mb_u_impl.entries_1.u_core.s_resp;
    release mb_u_impl.entries_1.u_core.w_comp;
    release mb_u_impl.entries_1.u_core.w_dbidresp;
    release mb_u_impl.entries_1.u_core.w_compdata;
    release mb_u_impl.entries_1.u_core.w_pcrdgrant;
    release mb_u_impl.entries_1.u_core.w_readreceipt;
    release mb_u_impl.entries_1.u_core.allowRetry;
    release mb_u_impl.entries_1.u_core.req_opcode;
    release mb_u_impl.entries_1.u_core.req_size;
    release mb_u_impl.entries_1.u_core.req_source;
    release mb_u_impl.entries_1.u_core.req_address;
    release mb_u_impl.entries_1.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_1.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_1.u_core.req_mask;
    release mb_u_impl.entries_1.u_core.req_data;
    release mb_u_impl.entries_1.u_core.req_corrupt;
    release mb_u_impl.entries_1.u_core.rdata;
    release mb_u_impl.entries_1.u_core.srcID;
    release mb_u_impl.entries_1.u_core.dbID;
    release mb_u_impl.entries_1.u_core.pCrdType;
    release mb_u_impl.entries_1.u_core.denied;
    release mb_u_impl.entries_1.u_core.corrupt;
    release mb_u_impl.entries_1.u_core.traceTag;
    release mb_u_impl.entries_2.u_core.s_txreq;
    release mb_u_impl.entries_2.u_core.s_ncbwrdata;
    release mb_u_impl.entries_2.u_core.s_resp;
    release mb_u_impl.entries_2.u_core.w_comp;
    release mb_u_impl.entries_2.u_core.w_dbidresp;
    release mb_u_impl.entries_2.u_core.w_compdata;
    release mb_u_impl.entries_2.u_core.w_pcrdgrant;
    release mb_u_impl.entries_2.u_core.w_readreceipt;
    release mb_u_impl.entries_2.u_core.allowRetry;
    release mb_u_impl.entries_2.u_core.req_opcode;
    release mb_u_impl.entries_2.u_core.req_size;
    release mb_u_impl.entries_2.u_core.req_source;
    release mb_u_impl.entries_2.u_core.req_address;
    release mb_u_impl.entries_2.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_2.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_2.u_core.req_mask;
    release mb_u_impl.entries_2.u_core.req_data;
    release mb_u_impl.entries_2.u_core.req_corrupt;
    release mb_u_impl.entries_2.u_core.rdata;
    release mb_u_impl.entries_2.u_core.srcID;
    release mb_u_impl.entries_2.u_core.dbID;
    release mb_u_impl.entries_2.u_core.pCrdType;
    release mb_u_impl.entries_2.u_core.denied;
    release mb_u_impl.entries_2.u_core.corrupt;
    release mb_u_impl.entries_2.u_core.traceTag;
    release mb_u_impl.entries_3.u_core.s_txreq;
    release mb_u_impl.entries_3.u_core.s_ncbwrdata;
    release mb_u_impl.entries_3.u_core.s_resp;
    release mb_u_impl.entries_3.u_core.w_comp;
    release mb_u_impl.entries_3.u_core.w_dbidresp;
    release mb_u_impl.entries_3.u_core.w_compdata;
    release mb_u_impl.entries_3.u_core.w_pcrdgrant;
    release mb_u_impl.entries_3.u_core.w_readreceipt;
    release mb_u_impl.entries_3.u_core.allowRetry;
    release mb_u_impl.entries_3.u_core.req_opcode;
    release mb_u_impl.entries_3.u_core.req_size;
    release mb_u_impl.entries_3.u_core.req_source;
    release mb_u_impl.entries_3.u_core.req_address;
    release mb_u_impl.entries_3.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_3.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_3.u_core.req_mask;
    release mb_u_impl.entries_3.u_core.req_data;
    release mb_u_impl.entries_3.u_core.req_corrupt;
    release mb_u_impl.entries_3.u_core.rdata;
    release mb_u_impl.entries_3.u_core.srcID;
    release mb_u_impl.entries_3.u_core.dbID;
    release mb_u_impl.entries_3.u_core.pCrdType;
    release mb_u_impl.entries_3.u_core.denied;
    release mb_u_impl.entries_3.u_core.corrupt;
    release mb_u_impl.entries_3.u_core.traceTag;
    release mb_u_impl.entries_4.u_core.s_txreq;
    release mb_u_impl.entries_4.u_core.s_ncbwrdata;
    release mb_u_impl.entries_4.u_core.s_resp;
    release mb_u_impl.entries_4.u_core.w_comp;
    release mb_u_impl.entries_4.u_core.w_dbidresp;
    release mb_u_impl.entries_4.u_core.w_compdata;
    release mb_u_impl.entries_4.u_core.w_pcrdgrant;
    release mb_u_impl.entries_4.u_core.w_readreceipt;
    release mb_u_impl.entries_4.u_core.allowRetry;
    release mb_u_impl.entries_4.u_core.req_opcode;
    release mb_u_impl.entries_4.u_core.req_size;
    release mb_u_impl.entries_4.u_core.req_source;
    release mb_u_impl.entries_4.u_core.req_address;
    release mb_u_impl.entries_4.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_4.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_4.u_core.req_mask;
    release mb_u_impl.entries_4.u_core.req_data;
    release mb_u_impl.entries_4.u_core.req_corrupt;
    release mb_u_impl.entries_4.u_core.rdata;
    release mb_u_impl.entries_4.u_core.srcID;
    release mb_u_impl.entries_4.u_core.dbID;
    release mb_u_impl.entries_4.u_core.pCrdType;
    release mb_u_impl.entries_4.u_core.denied;
    release mb_u_impl.entries_4.u_core.corrupt;
    release mb_u_impl.entries_4.u_core.traceTag;
    release mb_u_impl.entries_5.u_core.s_txreq;
    release mb_u_impl.entries_5.u_core.s_ncbwrdata;
    release mb_u_impl.entries_5.u_core.s_resp;
    release mb_u_impl.entries_5.u_core.w_comp;
    release mb_u_impl.entries_5.u_core.w_dbidresp;
    release mb_u_impl.entries_5.u_core.w_compdata;
    release mb_u_impl.entries_5.u_core.w_pcrdgrant;
    release mb_u_impl.entries_5.u_core.w_readreceipt;
    release mb_u_impl.entries_5.u_core.allowRetry;
    release mb_u_impl.entries_5.u_core.req_opcode;
    release mb_u_impl.entries_5.u_core.req_size;
    release mb_u_impl.entries_5.u_core.req_source;
    release mb_u_impl.entries_5.u_core.req_address;
    release mb_u_impl.entries_5.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_5.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_5.u_core.req_mask;
    release mb_u_impl.entries_5.u_core.req_data;
    release mb_u_impl.entries_5.u_core.req_corrupt;
    release mb_u_impl.entries_5.u_core.rdata;
    release mb_u_impl.entries_5.u_core.srcID;
    release mb_u_impl.entries_5.u_core.dbID;
    release mb_u_impl.entries_5.u_core.pCrdType;
    release mb_u_impl.entries_5.u_core.denied;
    release mb_u_impl.entries_5.u_core.corrupt;
    release mb_u_impl.entries_5.u_core.traceTag;
    release mb_u_impl.entries_6.u_core.s_txreq;
    release mb_u_impl.entries_6.u_core.s_ncbwrdata;
    release mb_u_impl.entries_6.u_core.s_resp;
    release mb_u_impl.entries_6.u_core.w_comp;
    release mb_u_impl.entries_6.u_core.w_dbidresp;
    release mb_u_impl.entries_6.u_core.w_compdata;
    release mb_u_impl.entries_6.u_core.w_pcrdgrant;
    release mb_u_impl.entries_6.u_core.w_readreceipt;
    release mb_u_impl.entries_6.u_core.allowRetry;
    release mb_u_impl.entries_6.u_core.req_opcode;
    release mb_u_impl.entries_6.u_core.req_size;
    release mb_u_impl.entries_6.u_core.req_source;
    release mb_u_impl.entries_6.u_core.req_address;
    release mb_u_impl.entries_6.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_6.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_6.u_core.req_mask;
    release mb_u_impl.entries_6.u_core.req_data;
    release mb_u_impl.entries_6.u_core.req_corrupt;
    release mb_u_impl.entries_6.u_core.rdata;
    release mb_u_impl.entries_6.u_core.srcID;
    release mb_u_impl.entries_6.u_core.dbID;
    release mb_u_impl.entries_6.u_core.pCrdType;
    release mb_u_impl.entries_6.u_core.denied;
    release mb_u_impl.entries_6.u_core.corrupt;
    release mb_u_impl.entries_6.u_core.traceTag;
    release mb_u_impl.entries_7.u_core.s_txreq;
    release mb_u_impl.entries_7.u_core.s_ncbwrdata;
    release mb_u_impl.entries_7.u_core.s_resp;
    release mb_u_impl.entries_7.u_core.w_comp;
    release mb_u_impl.entries_7.u_core.w_dbidresp;
    release mb_u_impl.entries_7.u_core.w_compdata;
    release mb_u_impl.entries_7.u_core.w_pcrdgrant;
    release mb_u_impl.entries_7.u_core.w_readreceipt;
    release mb_u_impl.entries_7.u_core.allowRetry;
    release mb_u_impl.entries_7.u_core.req_opcode;
    release mb_u_impl.entries_7.u_core.req_size;
    release mb_u_impl.entries_7.u_core.req_source;
    release mb_u_impl.entries_7.u_core.req_address;
    release mb_u_impl.entries_7.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_7.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_7.u_core.req_mask;
    release mb_u_impl.entries_7.u_core.req_data;
    release mb_u_impl.entries_7.u_core.req_corrupt;
    release mb_u_impl.entries_7.u_core.rdata;
    release mb_u_impl.entries_7.u_core.srcID;
    release mb_u_impl.entries_7.u_core.dbID;
    release mb_u_impl.entries_7.u_core.pCrdType;
    release mb_u_impl.entries_7.u_core.denied;
    release mb_u_impl.entries_7.u_core.corrupt;
    release mb_u_impl.entries_7.u_core.traceTag;
    release mb_u_impl.entries_8.u_core.s_txreq;
    release mb_u_impl.entries_8.u_core.s_ncbwrdata;
    release mb_u_impl.entries_8.u_core.s_resp;
    release mb_u_impl.entries_8.u_core.w_comp;
    release mb_u_impl.entries_8.u_core.w_dbidresp;
    release mb_u_impl.entries_8.u_core.w_compdata;
    release mb_u_impl.entries_8.u_core.w_pcrdgrant;
    release mb_u_impl.entries_8.u_core.w_readreceipt;
    release mb_u_impl.entries_8.u_core.allowRetry;
    release mb_u_impl.entries_8.u_core.req_opcode;
    release mb_u_impl.entries_8.u_core.req_size;
    release mb_u_impl.entries_8.u_core.req_source;
    release mb_u_impl.entries_8.u_core.req_address;
    release mb_u_impl.entries_8.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_8.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_8.u_core.req_mask;
    release mb_u_impl.entries_8.u_core.req_data;
    release mb_u_impl.entries_8.u_core.req_corrupt;
    release mb_u_impl.entries_8.u_core.rdata;
    release mb_u_impl.entries_8.u_core.srcID;
    release mb_u_impl.entries_8.u_core.dbID;
    release mb_u_impl.entries_8.u_core.pCrdType;
    release mb_u_impl.entries_8.u_core.denied;
    release mb_u_impl.entries_8.u_core.corrupt;
    release mb_u_impl.entries_8.u_core.traceTag;
    release mb_u_impl.entries_9.u_core.s_txreq;
    release mb_u_impl.entries_9.u_core.s_ncbwrdata;
    release mb_u_impl.entries_9.u_core.s_resp;
    release mb_u_impl.entries_9.u_core.w_comp;
    release mb_u_impl.entries_9.u_core.w_dbidresp;
    release mb_u_impl.entries_9.u_core.w_compdata;
    release mb_u_impl.entries_9.u_core.w_pcrdgrant;
    release mb_u_impl.entries_9.u_core.w_readreceipt;
    release mb_u_impl.entries_9.u_core.allowRetry;
    release mb_u_impl.entries_9.u_core.req_opcode;
    release mb_u_impl.entries_9.u_core.req_size;
    release mb_u_impl.entries_9.u_core.req_source;
    release mb_u_impl.entries_9.u_core.req_address;
    release mb_u_impl.entries_9.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_9.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_9.u_core.req_mask;
    release mb_u_impl.entries_9.u_core.req_data;
    release mb_u_impl.entries_9.u_core.req_corrupt;
    release mb_u_impl.entries_9.u_core.rdata;
    release mb_u_impl.entries_9.u_core.srcID;
    release mb_u_impl.entries_9.u_core.dbID;
    release mb_u_impl.entries_9.u_core.pCrdType;
    release mb_u_impl.entries_9.u_core.denied;
    release mb_u_impl.entries_9.u_core.corrupt;
    release mb_u_impl.entries_9.u_core.traceTag;
    release mb_u_impl.entries_10.u_core.s_txreq;
    release mb_u_impl.entries_10.u_core.s_ncbwrdata;
    release mb_u_impl.entries_10.u_core.s_resp;
    release mb_u_impl.entries_10.u_core.w_comp;
    release mb_u_impl.entries_10.u_core.w_dbidresp;
    release mb_u_impl.entries_10.u_core.w_compdata;
    release mb_u_impl.entries_10.u_core.w_pcrdgrant;
    release mb_u_impl.entries_10.u_core.w_readreceipt;
    release mb_u_impl.entries_10.u_core.allowRetry;
    release mb_u_impl.entries_10.u_core.req_opcode;
    release mb_u_impl.entries_10.u_core.req_size;
    release mb_u_impl.entries_10.u_core.req_source;
    release mb_u_impl.entries_10.u_core.req_address;
    release mb_u_impl.entries_10.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_10.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_10.u_core.req_mask;
    release mb_u_impl.entries_10.u_core.req_data;
    release mb_u_impl.entries_10.u_core.req_corrupt;
    release mb_u_impl.entries_10.u_core.rdata;
    release mb_u_impl.entries_10.u_core.srcID;
    release mb_u_impl.entries_10.u_core.dbID;
    release mb_u_impl.entries_10.u_core.pCrdType;
    release mb_u_impl.entries_10.u_core.denied;
    release mb_u_impl.entries_10.u_core.corrupt;
    release mb_u_impl.entries_10.u_core.traceTag;
    release mb_u_impl.entries_11.u_core.s_txreq;
    release mb_u_impl.entries_11.u_core.s_ncbwrdata;
    release mb_u_impl.entries_11.u_core.s_resp;
    release mb_u_impl.entries_11.u_core.w_comp;
    release mb_u_impl.entries_11.u_core.w_dbidresp;
    release mb_u_impl.entries_11.u_core.w_compdata;
    release mb_u_impl.entries_11.u_core.w_pcrdgrant;
    release mb_u_impl.entries_11.u_core.w_readreceipt;
    release mb_u_impl.entries_11.u_core.allowRetry;
    release mb_u_impl.entries_11.u_core.req_opcode;
    release mb_u_impl.entries_11.u_core.req_size;
    release mb_u_impl.entries_11.u_core.req_source;
    release mb_u_impl.entries_11.u_core.req_address;
    release mb_u_impl.entries_11.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_11.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_11.u_core.req_mask;
    release mb_u_impl.entries_11.u_core.req_data;
    release mb_u_impl.entries_11.u_core.req_corrupt;
    release mb_u_impl.entries_11.u_core.rdata;
    release mb_u_impl.entries_11.u_core.srcID;
    release mb_u_impl.entries_11.u_core.dbID;
    release mb_u_impl.entries_11.u_core.pCrdType;
    release mb_u_impl.entries_11.u_core.denied;
    release mb_u_impl.entries_11.u_core.corrupt;
    release mb_u_impl.entries_11.u_core.traceTag;
    release mb_u_impl.entries_12.u_core.s_txreq;
    release mb_u_impl.entries_12.u_core.s_ncbwrdata;
    release mb_u_impl.entries_12.u_core.s_resp;
    release mb_u_impl.entries_12.u_core.w_comp;
    release mb_u_impl.entries_12.u_core.w_dbidresp;
    release mb_u_impl.entries_12.u_core.w_compdata;
    release mb_u_impl.entries_12.u_core.w_pcrdgrant;
    release mb_u_impl.entries_12.u_core.w_readreceipt;
    release mb_u_impl.entries_12.u_core.allowRetry;
    release mb_u_impl.entries_12.u_core.req_opcode;
    release mb_u_impl.entries_12.u_core.req_size;
    release mb_u_impl.entries_12.u_core.req_source;
    release mb_u_impl.entries_12.u_core.req_address;
    release mb_u_impl.entries_12.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_12.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_12.u_core.req_mask;
    release mb_u_impl.entries_12.u_core.req_data;
    release mb_u_impl.entries_12.u_core.req_corrupt;
    release mb_u_impl.entries_12.u_core.rdata;
    release mb_u_impl.entries_12.u_core.srcID;
    release mb_u_impl.entries_12.u_core.dbID;
    release mb_u_impl.entries_12.u_core.pCrdType;
    release mb_u_impl.entries_12.u_core.denied;
    release mb_u_impl.entries_12.u_core.corrupt;
    release mb_u_impl.entries_12.u_core.traceTag;
    release mb_u_impl.entries_13.u_core.s_txreq;
    release mb_u_impl.entries_13.u_core.s_ncbwrdata;
    release mb_u_impl.entries_13.u_core.s_resp;
    release mb_u_impl.entries_13.u_core.w_comp;
    release mb_u_impl.entries_13.u_core.w_dbidresp;
    release mb_u_impl.entries_13.u_core.w_compdata;
    release mb_u_impl.entries_13.u_core.w_pcrdgrant;
    release mb_u_impl.entries_13.u_core.w_readreceipt;
    release mb_u_impl.entries_13.u_core.allowRetry;
    release mb_u_impl.entries_13.u_core.req_opcode;
    release mb_u_impl.entries_13.u_core.req_size;
    release mb_u_impl.entries_13.u_core.req_source;
    release mb_u_impl.entries_13.u_core.req_address;
    release mb_u_impl.entries_13.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_13.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_13.u_core.req_mask;
    release mb_u_impl.entries_13.u_core.req_data;
    release mb_u_impl.entries_13.u_core.req_corrupt;
    release mb_u_impl.entries_13.u_core.rdata;
    release mb_u_impl.entries_13.u_core.srcID;
    release mb_u_impl.entries_13.u_core.dbID;
    release mb_u_impl.entries_13.u_core.pCrdType;
    release mb_u_impl.entries_13.u_core.denied;
    release mb_u_impl.entries_13.u_core.corrupt;
    release mb_u_impl.entries_13.u_core.traceTag;
    release mb_u_impl.entries_14.u_core.s_txreq;
    release mb_u_impl.entries_14.u_core.s_ncbwrdata;
    release mb_u_impl.entries_14.u_core.s_resp;
    release mb_u_impl.entries_14.u_core.w_comp;
    release mb_u_impl.entries_14.u_core.w_dbidresp;
    release mb_u_impl.entries_14.u_core.w_compdata;
    release mb_u_impl.entries_14.u_core.w_pcrdgrant;
    release mb_u_impl.entries_14.u_core.w_readreceipt;
    release mb_u_impl.entries_14.u_core.allowRetry;
    release mb_u_impl.entries_14.u_core.req_opcode;
    release mb_u_impl.entries_14.u_core.req_size;
    release mb_u_impl.entries_14.u_core.req_source;
    release mb_u_impl.entries_14.u_core.req_address;
    release mb_u_impl.entries_14.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_14.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_14.u_core.req_mask;
    release mb_u_impl.entries_14.u_core.req_data;
    release mb_u_impl.entries_14.u_core.req_corrupt;
    release mb_u_impl.entries_14.u_core.rdata;
    release mb_u_impl.entries_14.u_core.srcID;
    release mb_u_impl.entries_14.u_core.dbID;
    release mb_u_impl.entries_14.u_core.pCrdType;
    release mb_u_impl.entries_14.u_core.denied;
    release mb_u_impl.entries_14.u_core.corrupt;
    release mb_u_impl.entries_14.u_core.traceTag;
    release mb_u_impl.entries_15.u_core.s_txreq;
    release mb_u_impl.entries_15.u_core.s_ncbwrdata;
    release mb_u_impl.entries_15.u_core.s_resp;
    release mb_u_impl.entries_15.u_core.w_comp;
    release mb_u_impl.entries_15.u_core.w_dbidresp;
    release mb_u_impl.entries_15.u_core.w_compdata;
    release mb_u_impl.entries_15.u_core.w_pcrdgrant;
    release mb_u_impl.entries_15.u_core.w_readreceipt;
    release mb_u_impl.entries_15.u_core.allowRetry;
    release mb_u_impl.entries_15.u_core.req_opcode;
    release mb_u_impl.entries_15.u_core.req_size;
    release mb_u_impl.entries_15.u_core.req_source;
    release mb_u_impl.entries_15.u_core.req_address;
    release mb_u_impl.entries_15.u_core.req_user_memBackType_MM;
    release mb_u_impl.entries_15.u_core.req_user_memPageType_NC;
    release mb_u_impl.entries_15.u_core.req_mask;
    release mb_u_impl.entries_15.u_core.req_data;
    release mb_u_impl.entries_15.u_core.req_corrupt;
    release mb_u_impl.entries_15.u_core.rdata;
    release mb_u_impl.entries_15.u_core.srcID;
    release mb_u_impl.entries_15.u_core.dbID;
    release mb_u_impl.entries_15.u_core.pCrdType;
    release mb_u_impl.entries_15.u_core.denied;
    release mb_u_impl.entries_15.u_core.corrupt;
    release mb_u_impl.entries_15.u_core.traceTag;
  end
  logic mb_reset;
  wire  mb_g_auto_mmio_in_a_ready, mb_i_auto_mmio_in_a_ready;
  logic mb_s0_auto_mmio_in_a_ready = '0, mb_s1_auto_mmio_in_a_ready = '0;
  logic mb_auto_mmio_in_a_valid;
  logic [3:0] mb_auto_mmio_in_a_bits_opcode;
  logic [2:0] mb_auto_mmio_in_a_bits_param;
  logic [1:0] mb_auto_mmio_in_a_bits_size;
  logic [4:0] mb_auto_mmio_in_a_bits_source;
  logic [47:0] mb_auto_mmio_in_a_bits_address;
  logic mb_auto_mmio_in_a_bits_user_memBackType_MM;
  logic mb_auto_mmio_in_a_bits_user_memPageType_NC;
  logic [7:0] mb_auto_mmio_in_a_bits_mask;
  logic [63:0] mb_auto_mmio_in_a_bits_data;
  logic mb_auto_mmio_in_a_bits_corrupt;
  logic mb_auto_mmio_in_d_ready;
  wire  mb_g_auto_mmio_in_d_valid, mb_i_auto_mmio_in_d_valid;
  logic mb_s0_auto_mmio_in_d_valid = '0, mb_s1_auto_mmio_in_d_valid = '0;
  wire  [3:0] mb_g_auto_mmio_in_d_bits_opcode, mb_i_auto_mmio_in_d_bits_opcode;
  logic [3:0] mb_s0_auto_mmio_in_d_bits_opcode = '0, mb_s1_auto_mmio_in_d_bits_opcode = '0;
  wire  [1:0] mb_g_auto_mmio_in_d_bits_param, mb_i_auto_mmio_in_d_bits_param;
  logic [1:0] mb_s0_auto_mmio_in_d_bits_param = '0, mb_s1_auto_mmio_in_d_bits_param = '0;
  wire  [1:0] mb_g_auto_mmio_in_d_bits_size, mb_i_auto_mmio_in_d_bits_size;
  logic [1:0] mb_s0_auto_mmio_in_d_bits_size = '0, mb_s1_auto_mmio_in_d_bits_size = '0;
  wire  [4:0] mb_g_auto_mmio_in_d_bits_source, mb_i_auto_mmio_in_d_bits_source;
  logic [4:0] mb_s0_auto_mmio_in_d_bits_source = '0, mb_s1_auto_mmio_in_d_bits_source = '0;
  wire  mb_g_auto_mmio_in_d_bits_sink, mb_i_auto_mmio_in_d_bits_sink;
  logic mb_s0_auto_mmio_in_d_bits_sink = '0, mb_s1_auto_mmio_in_d_bits_sink = '0;
  wire  mb_g_auto_mmio_in_d_bits_denied, mb_i_auto_mmio_in_d_bits_denied;
  logic mb_s0_auto_mmio_in_d_bits_denied = '0, mb_s1_auto_mmio_in_d_bits_denied = '0;
  wire  [63:0] mb_g_auto_mmio_in_d_bits_data, mb_i_auto_mmio_in_d_bits_data;
  logic [63:0] mb_s0_auto_mmio_in_d_bits_data = '0, mb_s1_auto_mmio_in_d_bits_data = '0;
  wire  mb_g_auto_mmio_in_d_bits_corrupt, mb_i_auto_mmio_in_d_bits_corrupt;
  logic mb_s0_auto_mmio_in_d_bits_corrupt = '0, mb_s1_auto_mmio_in_d_bits_corrupt = '0;
  logic mb_io_tx_req_ready;
  wire  mb_g_io_tx_req_valid, mb_i_io_tx_req_valid;
  logic mb_s0_io_tx_req_valid = '0, mb_s1_io_tx_req_valid = '0;
  wire  [3:0] mb_g_io_tx_req_bits_qos, mb_i_io_tx_req_bits_qos;
  logic [3:0] mb_s0_io_tx_req_bits_qos = '0, mb_s1_io_tx_req_bits_qos = '0;
  wire  [10:0] mb_g_io_tx_req_bits_tgtID, mb_i_io_tx_req_bits_tgtID;
  logic [10:0] mb_s0_io_tx_req_bits_tgtID = '0, mb_s1_io_tx_req_bits_tgtID = '0;
  wire  [10:0] mb_g_io_tx_req_bits_srcID, mb_i_io_tx_req_bits_srcID;
  logic [10:0] mb_s0_io_tx_req_bits_srcID = '0, mb_s1_io_tx_req_bits_srcID = '0;
  wire  [11:0] mb_g_io_tx_req_bits_txnID, mb_i_io_tx_req_bits_txnID;
  logic [11:0] mb_s0_io_tx_req_bits_txnID = '0, mb_s1_io_tx_req_bits_txnID = '0;
  wire  [10:0] mb_g_io_tx_req_bits_returnNID, mb_i_io_tx_req_bits_returnNID;
  logic [10:0] mb_s0_io_tx_req_bits_returnNID = '0, mb_s1_io_tx_req_bits_returnNID = '0;
  wire  mb_g_io_tx_req_bits_stashNIDValid, mb_i_io_tx_req_bits_stashNIDValid;
  logic mb_s0_io_tx_req_bits_stashNIDValid = '0, mb_s1_io_tx_req_bits_stashNIDValid = '0;
  wire  [11:0] mb_g_io_tx_req_bits_returnTxnID, mb_i_io_tx_req_bits_returnTxnID;
  logic [11:0] mb_s0_io_tx_req_bits_returnTxnID = '0, mb_s1_io_tx_req_bits_returnTxnID = '0;
  wire  [6:0] mb_g_io_tx_req_bits_opcode, mb_i_io_tx_req_bits_opcode;
  logic [6:0] mb_s0_io_tx_req_bits_opcode = '0, mb_s1_io_tx_req_bits_opcode = '0;
  wire  [2:0] mb_g_io_tx_req_bits_size, mb_i_io_tx_req_bits_size;
  logic [2:0] mb_s0_io_tx_req_bits_size = '0, mb_s1_io_tx_req_bits_size = '0;
  wire  [47:0] mb_g_io_tx_req_bits_addr, mb_i_io_tx_req_bits_addr;
  logic [47:0] mb_s0_io_tx_req_bits_addr = '0, mb_s1_io_tx_req_bits_addr = '0;
  wire  mb_g_io_tx_req_bits_ns, mb_i_io_tx_req_bits_ns;
  logic mb_s0_io_tx_req_bits_ns = '0, mb_s1_io_tx_req_bits_ns = '0;
  wire  mb_g_io_tx_req_bits_likelyshared, mb_i_io_tx_req_bits_likelyshared;
  logic mb_s0_io_tx_req_bits_likelyshared = '0, mb_s1_io_tx_req_bits_likelyshared = '0;
  wire  mb_g_io_tx_req_bits_allowRetry, mb_i_io_tx_req_bits_allowRetry;
  logic mb_s0_io_tx_req_bits_allowRetry = '0, mb_s1_io_tx_req_bits_allowRetry = '0;
  wire  [1:0] mb_g_io_tx_req_bits_order, mb_i_io_tx_req_bits_order;
  logic [1:0] mb_s0_io_tx_req_bits_order = '0, mb_s1_io_tx_req_bits_order = '0;
  wire  [3:0] mb_g_io_tx_req_bits_pCrdType, mb_i_io_tx_req_bits_pCrdType;
  logic [3:0] mb_s0_io_tx_req_bits_pCrdType = '0, mb_s1_io_tx_req_bits_pCrdType = '0;
  wire  mb_g_io_tx_req_bits_memAttr_allocate, mb_i_io_tx_req_bits_memAttr_allocate;
  logic mb_s0_io_tx_req_bits_memAttr_allocate = '0, mb_s1_io_tx_req_bits_memAttr_allocate = '0;
  wire  mb_g_io_tx_req_bits_memAttr_cacheable, mb_i_io_tx_req_bits_memAttr_cacheable;
  logic mb_s0_io_tx_req_bits_memAttr_cacheable = '0, mb_s1_io_tx_req_bits_memAttr_cacheable = '0;
  wire  mb_g_io_tx_req_bits_memAttr_device, mb_i_io_tx_req_bits_memAttr_device;
  logic mb_s0_io_tx_req_bits_memAttr_device = '0, mb_s1_io_tx_req_bits_memAttr_device = '0;
  wire  mb_g_io_tx_req_bits_memAttr_ewa, mb_i_io_tx_req_bits_memAttr_ewa;
  logic mb_s0_io_tx_req_bits_memAttr_ewa = '0, mb_s1_io_tx_req_bits_memAttr_ewa = '0;
  wire  mb_g_io_tx_req_bits_snpAttr, mb_i_io_tx_req_bits_snpAttr;
  logic mb_s0_io_tx_req_bits_snpAttr = '0, mb_s1_io_tx_req_bits_snpAttr = '0;
  wire  [7:0] mb_g_io_tx_req_bits_lpIDWithPadding, mb_i_io_tx_req_bits_lpIDWithPadding;
  logic [7:0] mb_s0_io_tx_req_bits_lpIDWithPadding = '0, mb_s1_io_tx_req_bits_lpIDWithPadding = '0;
  wire  mb_g_io_tx_req_bits_snoopMe, mb_i_io_tx_req_bits_snoopMe;
  logic mb_s0_io_tx_req_bits_snoopMe = '0, mb_s1_io_tx_req_bits_snoopMe = '0;
  wire  mb_g_io_tx_req_bits_expCompAck, mb_i_io_tx_req_bits_expCompAck;
  logic mb_s0_io_tx_req_bits_expCompAck = '0, mb_s1_io_tx_req_bits_expCompAck = '0;
  wire  [1:0] mb_g_io_tx_req_bits_tagOp, mb_i_io_tx_req_bits_tagOp;
  logic [1:0] mb_s0_io_tx_req_bits_tagOp = '0, mb_s1_io_tx_req_bits_tagOp = '0;
  wire  mb_g_io_tx_req_bits_traceTag, mb_i_io_tx_req_bits_traceTag;
  logic mb_s0_io_tx_req_bits_traceTag = '0, mb_s1_io_tx_req_bits_traceTag = '0;
  wire  mb_g_io_tx_req_bits_mpam_perfMonGroup, mb_i_io_tx_req_bits_mpam_perfMonGroup;
  logic mb_s0_io_tx_req_bits_mpam_perfMonGroup = '0, mb_s1_io_tx_req_bits_mpam_perfMonGroup = '0;
  wire  [8:0] mb_g_io_tx_req_bits_mpam_partID, mb_i_io_tx_req_bits_mpam_partID;
  logic [8:0] mb_s0_io_tx_req_bits_mpam_partID = '0, mb_s1_io_tx_req_bits_mpam_partID = '0;
  wire  mb_g_io_tx_req_bits_mpam_mpamNS, mb_i_io_tx_req_bits_mpam_mpamNS;
  logic mb_s0_io_tx_req_bits_mpam_mpamNS = '0, mb_s1_io_tx_req_bits_mpam_mpamNS = '0;
  wire  [3:0] mb_g_io_tx_req_bits_rsvdc, mb_i_io_tx_req_bits_rsvdc;
  logic [3:0] mb_s0_io_tx_req_bits_rsvdc = '0, mb_s1_io_tx_req_bits_rsvdc = '0;
  logic mb_io_tx_dat_ready;
  wire  mb_g_io_tx_dat_valid, mb_i_io_tx_dat_valid;
  logic mb_s0_io_tx_dat_valid = '0, mb_s1_io_tx_dat_valid = '0;
  wire  [3:0] mb_g_io_tx_dat_bits_qos, mb_i_io_tx_dat_bits_qos;
  logic [3:0] mb_s0_io_tx_dat_bits_qos = '0, mb_s1_io_tx_dat_bits_qos = '0;
  wire  [10:0] mb_g_io_tx_dat_bits_tgtID, mb_i_io_tx_dat_bits_tgtID;
  logic [10:0] mb_s0_io_tx_dat_bits_tgtID = '0, mb_s1_io_tx_dat_bits_tgtID = '0;
  wire  [10:0] mb_g_io_tx_dat_bits_srcID, mb_i_io_tx_dat_bits_srcID;
  logic [10:0] mb_s0_io_tx_dat_bits_srcID = '0, mb_s1_io_tx_dat_bits_srcID = '0;
  wire  [11:0] mb_g_io_tx_dat_bits_txnID, mb_i_io_tx_dat_bits_txnID;
  logic [11:0] mb_s0_io_tx_dat_bits_txnID = '0, mb_s1_io_tx_dat_bits_txnID = '0;
  wire  [10:0] mb_g_io_tx_dat_bits_homeNID, mb_i_io_tx_dat_bits_homeNID;
  logic [10:0] mb_s0_io_tx_dat_bits_homeNID = '0, mb_s1_io_tx_dat_bits_homeNID = '0;
  wire  [3:0] mb_g_io_tx_dat_bits_opcode, mb_i_io_tx_dat_bits_opcode;
  logic [3:0] mb_s0_io_tx_dat_bits_opcode = '0, mb_s1_io_tx_dat_bits_opcode = '0;
  wire  [1:0] mb_g_io_tx_dat_bits_respErr, mb_i_io_tx_dat_bits_respErr;
  logic [1:0] mb_s0_io_tx_dat_bits_respErr = '0, mb_s1_io_tx_dat_bits_respErr = '0;
  wire  [2:0] mb_g_io_tx_dat_bits_resp, mb_i_io_tx_dat_bits_resp;
  logic [2:0] mb_s0_io_tx_dat_bits_resp = '0, mb_s1_io_tx_dat_bits_resp = '0;
  wire  [3:0] mb_g_io_tx_dat_bits_dataSource, mb_i_io_tx_dat_bits_dataSource;
  logic [3:0] mb_s0_io_tx_dat_bits_dataSource = '0, mb_s1_io_tx_dat_bits_dataSource = '0;
  wire  [2:0] mb_g_io_tx_dat_bits_cBusy, mb_i_io_tx_dat_bits_cBusy;
  logic [2:0] mb_s0_io_tx_dat_bits_cBusy = '0, mb_s1_io_tx_dat_bits_cBusy = '0;
  wire  [11:0] mb_g_io_tx_dat_bits_dbID, mb_i_io_tx_dat_bits_dbID;
  logic [11:0] mb_s0_io_tx_dat_bits_dbID = '0, mb_s1_io_tx_dat_bits_dbID = '0;
  wire  [1:0] mb_g_io_tx_dat_bits_ccID, mb_i_io_tx_dat_bits_ccID;
  logic [1:0] mb_s0_io_tx_dat_bits_ccID = '0, mb_s1_io_tx_dat_bits_ccID = '0;
  wire  [1:0] mb_g_io_tx_dat_bits_dataID, mb_i_io_tx_dat_bits_dataID;
  logic [1:0] mb_s0_io_tx_dat_bits_dataID = '0, mb_s1_io_tx_dat_bits_dataID = '0;
  wire  [1:0] mb_g_io_tx_dat_bits_tagOp, mb_i_io_tx_dat_bits_tagOp;
  logic [1:0] mb_s0_io_tx_dat_bits_tagOp = '0, mb_s1_io_tx_dat_bits_tagOp = '0;
  wire  [7:0] mb_g_io_tx_dat_bits_tag, mb_i_io_tx_dat_bits_tag;
  logic [7:0] mb_s0_io_tx_dat_bits_tag = '0, mb_s1_io_tx_dat_bits_tag = '0;
  wire  [1:0] mb_g_io_tx_dat_bits_tu, mb_i_io_tx_dat_bits_tu;
  logic [1:0] mb_s0_io_tx_dat_bits_tu = '0, mb_s1_io_tx_dat_bits_tu = '0;
  wire  mb_g_io_tx_dat_bits_traceTag, mb_i_io_tx_dat_bits_traceTag;
  logic mb_s0_io_tx_dat_bits_traceTag = '0, mb_s1_io_tx_dat_bits_traceTag = '0;
  wire  [3:0] mb_g_io_tx_dat_bits_rsvdc, mb_i_io_tx_dat_bits_rsvdc;
  logic [3:0] mb_s0_io_tx_dat_bits_rsvdc = '0, mb_s1_io_tx_dat_bits_rsvdc = '0;
  wire  [31:0] mb_g_io_tx_dat_bits_be, mb_i_io_tx_dat_bits_be;
  logic [31:0] mb_s0_io_tx_dat_bits_be = '0, mb_s1_io_tx_dat_bits_be = '0;
  wire  [255:0] mb_g_io_tx_dat_bits_data, mb_i_io_tx_dat_bits_data;
  logic [255:0] mb_s0_io_tx_dat_bits_data = '0, mb_s1_io_tx_dat_bits_data = '0;
  wire  [31:0] mb_g_io_tx_dat_bits_dataCheck, mb_i_io_tx_dat_bits_dataCheck;
  logic [31:0] mb_s0_io_tx_dat_bits_dataCheck = '0, mb_s1_io_tx_dat_bits_dataCheck = '0;
  wire  [3:0] mb_g_io_tx_dat_bits_poison, mb_i_io_tx_dat_bits_poison;
  logic [3:0] mb_s0_io_tx_dat_bits_poison = '0, mb_s1_io_tx_dat_bits_poison = '0;
  wire  mb_g_io_rx_rsp_ready, mb_i_io_rx_rsp_ready;
  logic mb_s0_io_rx_rsp_ready = '0, mb_s1_io_rx_rsp_ready = '0;
  logic mb_io_rx_rsp_valid;
  logic [3:0] mb_io_rx_rsp_bits_qos;
  logic [10:0] mb_io_rx_rsp_bits_tgtID;
  logic [10:0] mb_io_rx_rsp_bits_srcID;
  logic [11:0] mb_io_rx_rsp_bits_txnID;
  logic [4:0] mb_io_rx_rsp_bits_opcode;
  logic [1:0] mb_io_rx_rsp_bits_respErr;
  logic [2:0] mb_io_rx_rsp_bits_resp;
  logic [2:0] mb_io_rx_rsp_bits_fwdState;
  logic [2:0] mb_io_rx_rsp_bits_cBusy;
  logic [11:0] mb_io_rx_rsp_bits_dbID;
  logic [3:0] mb_io_rx_rsp_bits_pCrdType;
  logic [1:0] mb_io_rx_rsp_bits_tagOp;
  logic mb_io_rx_rsp_bits_traceTag;
  wire  mb_g_io_rx_dat_ready, mb_i_io_rx_dat_ready;
  logic mb_s0_io_rx_dat_ready = '0, mb_s1_io_rx_dat_ready = '0;
  logic mb_io_rx_dat_valid;
  logic [3:0] mb_io_rx_dat_bits_qos;
  logic [10:0] mb_io_rx_dat_bits_tgtID;
  logic [10:0] mb_io_rx_dat_bits_srcID;
  logic [11:0] mb_io_rx_dat_bits_txnID;
  logic [10:0] mb_io_rx_dat_bits_homeNID;
  logic [3:0] mb_io_rx_dat_bits_opcode;
  logic [1:0] mb_io_rx_dat_bits_respErr;
  logic [2:0] mb_io_rx_dat_bits_resp;
  logic [3:0] mb_io_rx_dat_bits_dataSource;
  logic [2:0] mb_io_rx_dat_bits_cBusy;
  logic [11:0] mb_io_rx_dat_bits_dbID;
  logic [1:0] mb_io_rx_dat_bits_ccID;
  logic [1:0] mb_io_rx_dat_bits_dataID;
  logic [1:0] mb_io_rx_dat_bits_tagOp;
  logic [7:0] mb_io_rx_dat_bits_tag;
  logic [1:0] mb_io_rx_dat_bits_tu;
  logic mb_io_rx_dat_bits_traceTag;
  logic [3:0] mb_io_rx_dat_bits_rsvdc;
  logic [31:0] mb_io_rx_dat_bits_be;
  logic [255:0] mb_io_rx_dat_bits_data;
  logic [31:0] mb_io_rx_dat_bits_dataCheck;
  logic [3:0] mb_io_rx_dat_bits_poison;
  wire  mb_g_io_pCrd_0_query_valid, mb_i_io_pCrd_0_query_valid;
  logic mb_s0_io_pCrd_0_query_valid = '0, mb_s1_io_pCrd_0_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_0_query_bits_pCrdType, mb_i_io_pCrd_0_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_0_query_bits_pCrdType = '0, mb_s1_io_pCrd_0_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_0_query_bits_srcID, mb_i_io_pCrd_0_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_0_query_bits_srcID = '0, mb_s1_io_pCrd_0_query_bits_srcID = '0;
  logic mb_io_pCrd_0_grant;
  wire  mb_g_io_pCrd_1_query_valid, mb_i_io_pCrd_1_query_valid;
  logic mb_s0_io_pCrd_1_query_valid = '0, mb_s1_io_pCrd_1_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_1_query_bits_pCrdType, mb_i_io_pCrd_1_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_1_query_bits_pCrdType = '0, mb_s1_io_pCrd_1_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_1_query_bits_srcID, mb_i_io_pCrd_1_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_1_query_bits_srcID = '0, mb_s1_io_pCrd_1_query_bits_srcID = '0;
  logic mb_io_pCrd_1_grant;
  wire  mb_g_io_pCrd_2_query_valid, mb_i_io_pCrd_2_query_valid;
  logic mb_s0_io_pCrd_2_query_valid = '0, mb_s1_io_pCrd_2_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_2_query_bits_pCrdType, mb_i_io_pCrd_2_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_2_query_bits_pCrdType = '0, mb_s1_io_pCrd_2_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_2_query_bits_srcID, mb_i_io_pCrd_2_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_2_query_bits_srcID = '0, mb_s1_io_pCrd_2_query_bits_srcID = '0;
  logic mb_io_pCrd_2_grant;
  wire  mb_g_io_pCrd_3_query_valid, mb_i_io_pCrd_3_query_valid;
  logic mb_s0_io_pCrd_3_query_valid = '0, mb_s1_io_pCrd_3_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_3_query_bits_pCrdType, mb_i_io_pCrd_3_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_3_query_bits_pCrdType = '0, mb_s1_io_pCrd_3_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_3_query_bits_srcID, mb_i_io_pCrd_3_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_3_query_bits_srcID = '0, mb_s1_io_pCrd_3_query_bits_srcID = '0;
  logic mb_io_pCrd_3_grant;
  wire  mb_g_io_pCrd_4_query_valid, mb_i_io_pCrd_4_query_valid;
  logic mb_s0_io_pCrd_4_query_valid = '0, mb_s1_io_pCrd_4_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_4_query_bits_pCrdType, mb_i_io_pCrd_4_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_4_query_bits_pCrdType = '0, mb_s1_io_pCrd_4_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_4_query_bits_srcID, mb_i_io_pCrd_4_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_4_query_bits_srcID = '0, mb_s1_io_pCrd_4_query_bits_srcID = '0;
  logic mb_io_pCrd_4_grant;
  wire  mb_g_io_pCrd_5_query_valid, mb_i_io_pCrd_5_query_valid;
  logic mb_s0_io_pCrd_5_query_valid = '0, mb_s1_io_pCrd_5_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_5_query_bits_pCrdType, mb_i_io_pCrd_5_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_5_query_bits_pCrdType = '0, mb_s1_io_pCrd_5_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_5_query_bits_srcID, mb_i_io_pCrd_5_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_5_query_bits_srcID = '0, mb_s1_io_pCrd_5_query_bits_srcID = '0;
  logic mb_io_pCrd_5_grant;
  wire  mb_g_io_pCrd_6_query_valid, mb_i_io_pCrd_6_query_valid;
  logic mb_s0_io_pCrd_6_query_valid = '0, mb_s1_io_pCrd_6_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_6_query_bits_pCrdType, mb_i_io_pCrd_6_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_6_query_bits_pCrdType = '0, mb_s1_io_pCrd_6_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_6_query_bits_srcID, mb_i_io_pCrd_6_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_6_query_bits_srcID = '0, mb_s1_io_pCrd_6_query_bits_srcID = '0;
  logic mb_io_pCrd_6_grant;
  wire  mb_g_io_pCrd_7_query_valid, mb_i_io_pCrd_7_query_valid;
  logic mb_s0_io_pCrd_7_query_valid = '0, mb_s1_io_pCrd_7_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_7_query_bits_pCrdType, mb_i_io_pCrd_7_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_7_query_bits_pCrdType = '0, mb_s1_io_pCrd_7_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_7_query_bits_srcID, mb_i_io_pCrd_7_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_7_query_bits_srcID = '0, mb_s1_io_pCrd_7_query_bits_srcID = '0;
  logic mb_io_pCrd_7_grant;
  wire  mb_g_io_pCrd_8_query_valid, mb_i_io_pCrd_8_query_valid;
  logic mb_s0_io_pCrd_8_query_valid = '0, mb_s1_io_pCrd_8_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_8_query_bits_pCrdType, mb_i_io_pCrd_8_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_8_query_bits_pCrdType = '0, mb_s1_io_pCrd_8_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_8_query_bits_srcID, mb_i_io_pCrd_8_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_8_query_bits_srcID = '0, mb_s1_io_pCrd_8_query_bits_srcID = '0;
  logic mb_io_pCrd_8_grant;
  wire  mb_g_io_pCrd_9_query_valid, mb_i_io_pCrd_9_query_valid;
  logic mb_s0_io_pCrd_9_query_valid = '0, mb_s1_io_pCrd_9_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_9_query_bits_pCrdType, mb_i_io_pCrd_9_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_9_query_bits_pCrdType = '0, mb_s1_io_pCrd_9_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_9_query_bits_srcID, mb_i_io_pCrd_9_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_9_query_bits_srcID = '0, mb_s1_io_pCrd_9_query_bits_srcID = '0;
  logic mb_io_pCrd_9_grant;
  wire  mb_g_io_pCrd_10_query_valid, mb_i_io_pCrd_10_query_valid;
  logic mb_s0_io_pCrd_10_query_valid = '0, mb_s1_io_pCrd_10_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_10_query_bits_pCrdType, mb_i_io_pCrd_10_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_10_query_bits_pCrdType = '0, mb_s1_io_pCrd_10_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_10_query_bits_srcID, mb_i_io_pCrd_10_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_10_query_bits_srcID = '0, mb_s1_io_pCrd_10_query_bits_srcID = '0;
  logic mb_io_pCrd_10_grant;
  wire  mb_g_io_pCrd_11_query_valid, mb_i_io_pCrd_11_query_valid;
  logic mb_s0_io_pCrd_11_query_valid = '0, mb_s1_io_pCrd_11_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_11_query_bits_pCrdType, mb_i_io_pCrd_11_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_11_query_bits_pCrdType = '0, mb_s1_io_pCrd_11_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_11_query_bits_srcID, mb_i_io_pCrd_11_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_11_query_bits_srcID = '0, mb_s1_io_pCrd_11_query_bits_srcID = '0;
  logic mb_io_pCrd_11_grant;
  wire  mb_g_io_pCrd_12_query_valid, mb_i_io_pCrd_12_query_valid;
  logic mb_s0_io_pCrd_12_query_valid = '0, mb_s1_io_pCrd_12_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_12_query_bits_pCrdType, mb_i_io_pCrd_12_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_12_query_bits_pCrdType = '0, mb_s1_io_pCrd_12_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_12_query_bits_srcID, mb_i_io_pCrd_12_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_12_query_bits_srcID = '0, mb_s1_io_pCrd_12_query_bits_srcID = '0;
  logic mb_io_pCrd_12_grant;
  wire  mb_g_io_pCrd_13_query_valid, mb_i_io_pCrd_13_query_valid;
  logic mb_s0_io_pCrd_13_query_valid = '0, mb_s1_io_pCrd_13_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_13_query_bits_pCrdType, mb_i_io_pCrd_13_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_13_query_bits_pCrdType = '0, mb_s1_io_pCrd_13_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_13_query_bits_srcID, mb_i_io_pCrd_13_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_13_query_bits_srcID = '0, mb_s1_io_pCrd_13_query_bits_srcID = '0;
  logic mb_io_pCrd_13_grant;
  wire  mb_g_io_pCrd_14_query_valid, mb_i_io_pCrd_14_query_valid;
  logic mb_s0_io_pCrd_14_query_valid = '0, mb_s1_io_pCrd_14_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_14_query_bits_pCrdType, mb_i_io_pCrd_14_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_14_query_bits_pCrdType = '0, mb_s1_io_pCrd_14_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_14_query_bits_srcID, mb_i_io_pCrd_14_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_14_query_bits_srcID = '0, mb_s1_io_pCrd_14_query_bits_srcID = '0;
  logic mb_io_pCrd_14_grant;
  wire  mb_g_io_pCrd_15_query_valid, mb_i_io_pCrd_15_query_valid;
  logic mb_s0_io_pCrd_15_query_valid = '0, mb_s1_io_pCrd_15_query_valid = '0;
  wire  [3:0] mb_g_io_pCrd_15_query_bits_pCrdType, mb_i_io_pCrd_15_query_bits_pCrdType;
  logic [3:0] mb_s0_io_pCrd_15_query_bits_pCrdType = '0, mb_s1_io_pCrd_15_query_bits_pCrdType = '0;
  wire  [10:0] mb_g_io_pCrd_15_query_bits_srcID, mb_i_io_pCrd_15_query_bits_srcID;
  logic [10:0] mb_s0_io_pCrd_15_query_bits_srcID = '0, mb_s1_io_pCrd_15_query_bits_srcID = '0;
  logic mb_io_pCrd_15_grant;
  int mb_cov_a_fire = 0;
  int mb_cov_a_full = 0;
  int mb_cov_slot15_used = 0;
  int mb_cov_d_read = 0;
  int mb_cov_d_write = 0;
  int mb_cov_txreq_fire = 0;
  int mb_cov_txdat_fire = 0;
  int mb_cov_read_blocked = 0;
  int mb_cov_wait_rr = 0;
  int mb_cov_rxdat_ready = 0;
  int mb_cov_rxdat_miss = 0;
  int mb_cov_pcrd_query = 0;
  logic [0:0] mb_armed = '0;
  int mb_armed_at = -1;
  MMIOBridge mb_u_gold (
    .clock(clk),
    .reset(mb_reset),
    .auto_mmio_in_a_ready(mb_g_auto_mmio_in_a_ready),
    .auto_mmio_in_a_valid(mb_auto_mmio_in_a_valid),
    .auto_mmio_in_a_bits_opcode(mb_auto_mmio_in_a_bits_opcode),
    .auto_mmio_in_a_bits_param(mb_auto_mmio_in_a_bits_param),
    .auto_mmio_in_a_bits_size(mb_auto_mmio_in_a_bits_size),
    .auto_mmio_in_a_bits_source(mb_auto_mmio_in_a_bits_source),
    .auto_mmio_in_a_bits_address(mb_auto_mmio_in_a_bits_address),
    .auto_mmio_in_a_bits_user_memBackType_MM(mb_auto_mmio_in_a_bits_user_memBackType_MM),
    .auto_mmio_in_a_bits_user_memPageType_NC(mb_auto_mmio_in_a_bits_user_memPageType_NC),
    .auto_mmio_in_a_bits_mask(mb_auto_mmio_in_a_bits_mask),
    .auto_mmio_in_a_bits_data(mb_auto_mmio_in_a_bits_data),
    .auto_mmio_in_a_bits_corrupt(mb_auto_mmio_in_a_bits_corrupt),
    .auto_mmio_in_d_ready(mb_auto_mmio_in_d_ready),
    .auto_mmio_in_d_valid(mb_g_auto_mmio_in_d_valid),
    .auto_mmio_in_d_bits_opcode(mb_g_auto_mmio_in_d_bits_opcode),
    .auto_mmio_in_d_bits_param(mb_g_auto_mmio_in_d_bits_param),
    .auto_mmio_in_d_bits_size(mb_g_auto_mmio_in_d_bits_size),
    .auto_mmio_in_d_bits_source(mb_g_auto_mmio_in_d_bits_source),
    .auto_mmio_in_d_bits_sink(mb_g_auto_mmio_in_d_bits_sink),
    .auto_mmio_in_d_bits_denied(mb_g_auto_mmio_in_d_bits_denied),
    .auto_mmio_in_d_bits_data(mb_g_auto_mmio_in_d_bits_data),
    .auto_mmio_in_d_bits_corrupt(mb_g_auto_mmio_in_d_bits_corrupt),
    .io_tx_req_ready(mb_io_tx_req_ready),
    .io_tx_req_valid(mb_g_io_tx_req_valid),
    .io_tx_req_bits_qos(mb_g_io_tx_req_bits_qos),
    .io_tx_req_bits_tgtID(mb_g_io_tx_req_bits_tgtID),
    .io_tx_req_bits_srcID(mb_g_io_tx_req_bits_srcID),
    .io_tx_req_bits_txnID(mb_g_io_tx_req_bits_txnID),
    .io_tx_req_bits_returnNID(mb_g_io_tx_req_bits_returnNID),
    .io_tx_req_bits_stashNIDValid(mb_g_io_tx_req_bits_stashNIDValid),
    .io_tx_req_bits_returnTxnID(mb_g_io_tx_req_bits_returnTxnID),
    .io_tx_req_bits_opcode(mb_g_io_tx_req_bits_opcode),
    .io_tx_req_bits_size(mb_g_io_tx_req_bits_size),
    .io_tx_req_bits_addr(mb_g_io_tx_req_bits_addr),
    .io_tx_req_bits_ns(mb_g_io_tx_req_bits_ns),
    .io_tx_req_bits_likelyshared(mb_g_io_tx_req_bits_likelyshared),
    .io_tx_req_bits_allowRetry(mb_g_io_tx_req_bits_allowRetry),
    .io_tx_req_bits_order(mb_g_io_tx_req_bits_order),
    .io_tx_req_bits_pCrdType(mb_g_io_tx_req_bits_pCrdType),
    .io_tx_req_bits_memAttr_allocate(mb_g_io_tx_req_bits_memAttr_allocate),
    .io_tx_req_bits_memAttr_cacheable(mb_g_io_tx_req_bits_memAttr_cacheable),
    .io_tx_req_bits_memAttr_device(mb_g_io_tx_req_bits_memAttr_device),
    .io_tx_req_bits_memAttr_ewa(mb_g_io_tx_req_bits_memAttr_ewa),
    .io_tx_req_bits_snpAttr(mb_g_io_tx_req_bits_snpAttr),
    .io_tx_req_bits_lpIDWithPadding(mb_g_io_tx_req_bits_lpIDWithPadding),
    .io_tx_req_bits_snoopMe(mb_g_io_tx_req_bits_snoopMe),
    .io_tx_req_bits_expCompAck(mb_g_io_tx_req_bits_expCompAck),
    .io_tx_req_bits_tagOp(mb_g_io_tx_req_bits_tagOp),
    .io_tx_req_bits_traceTag(mb_g_io_tx_req_bits_traceTag),
    .io_tx_req_bits_mpam_perfMonGroup(mb_g_io_tx_req_bits_mpam_perfMonGroup),
    .io_tx_req_bits_mpam_partID(mb_g_io_tx_req_bits_mpam_partID),
    .io_tx_req_bits_mpam_mpamNS(mb_g_io_tx_req_bits_mpam_mpamNS),
    .io_tx_req_bits_rsvdc(mb_g_io_tx_req_bits_rsvdc),
    .io_tx_dat_ready(mb_io_tx_dat_ready),
    .io_tx_dat_valid(mb_g_io_tx_dat_valid),
    .io_tx_dat_bits_qos(mb_g_io_tx_dat_bits_qos),
    .io_tx_dat_bits_tgtID(mb_g_io_tx_dat_bits_tgtID),
    .io_tx_dat_bits_srcID(mb_g_io_tx_dat_bits_srcID),
    .io_tx_dat_bits_txnID(mb_g_io_tx_dat_bits_txnID),
    .io_tx_dat_bits_homeNID(mb_g_io_tx_dat_bits_homeNID),
    .io_tx_dat_bits_opcode(mb_g_io_tx_dat_bits_opcode),
    .io_tx_dat_bits_respErr(mb_g_io_tx_dat_bits_respErr),
    .io_tx_dat_bits_resp(mb_g_io_tx_dat_bits_resp),
    .io_tx_dat_bits_dataSource(mb_g_io_tx_dat_bits_dataSource),
    .io_tx_dat_bits_cBusy(mb_g_io_tx_dat_bits_cBusy),
    .io_tx_dat_bits_dbID(mb_g_io_tx_dat_bits_dbID),
    .io_tx_dat_bits_ccID(mb_g_io_tx_dat_bits_ccID),
    .io_tx_dat_bits_dataID(mb_g_io_tx_dat_bits_dataID),
    .io_tx_dat_bits_tagOp(mb_g_io_tx_dat_bits_tagOp),
    .io_tx_dat_bits_tag(mb_g_io_tx_dat_bits_tag),
    .io_tx_dat_bits_tu(mb_g_io_tx_dat_bits_tu),
    .io_tx_dat_bits_traceTag(mb_g_io_tx_dat_bits_traceTag),
    .io_tx_dat_bits_rsvdc(mb_g_io_tx_dat_bits_rsvdc),
    .io_tx_dat_bits_be(mb_g_io_tx_dat_bits_be),
    .io_tx_dat_bits_data(mb_g_io_tx_dat_bits_data),
    .io_tx_dat_bits_dataCheck(mb_g_io_tx_dat_bits_dataCheck),
    .io_tx_dat_bits_poison(mb_g_io_tx_dat_bits_poison),
    .io_rx_rsp_ready(mb_g_io_rx_rsp_ready),
    .io_rx_rsp_valid(mb_io_rx_rsp_valid),
    .io_rx_rsp_bits_qos(mb_io_rx_rsp_bits_qos),
    .io_rx_rsp_bits_tgtID(mb_io_rx_rsp_bits_tgtID),
    .io_rx_rsp_bits_srcID(mb_io_rx_rsp_bits_srcID),
    .io_rx_rsp_bits_txnID(mb_io_rx_rsp_bits_txnID),
    .io_rx_rsp_bits_opcode(mb_io_rx_rsp_bits_opcode),
    .io_rx_rsp_bits_respErr(mb_io_rx_rsp_bits_respErr),
    .io_rx_rsp_bits_resp(mb_io_rx_rsp_bits_resp),
    .io_rx_rsp_bits_fwdState(mb_io_rx_rsp_bits_fwdState),
    .io_rx_rsp_bits_cBusy(mb_io_rx_rsp_bits_cBusy),
    .io_rx_rsp_bits_dbID(mb_io_rx_rsp_bits_dbID),
    .io_rx_rsp_bits_pCrdType(mb_io_rx_rsp_bits_pCrdType),
    .io_rx_rsp_bits_tagOp(mb_io_rx_rsp_bits_tagOp),
    .io_rx_rsp_bits_traceTag(mb_io_rx_rsp_bits_traceTag),
    .io_rx_dat_ready(mb_g_io_rx_dat_ready),
    .io_rx_dat_valid(mb_io_rx_dat_valid),
    .io_rx_dat_bits_qos(mb_io_rx_dat_bits_qos),
    .io_rx_dat_bits_tgtID(mb_io_rx_dat_bits_tgtID),
    .io_rx_dat_bits_srcID(mb_io_rx_dat_bits_srcID),
    .io_rx_dat_bits_txnID(mb_io_rx_dat_bits_txnID),
    .io_rx_dat_bits_homeNID(mb_io_rx_dat_bits_homeNID),
    .io_rx_dat_bits_opcode(mb_io_rx_dat_bits_opcode),
    .io_rx_dat_bits_respErr(mb_io_rx_dat_bits_respErr),
    .io_rx_dat_bits_resp(mb_io_rx_dat_bits_resp),
    .io_rx_dat_bits_dataSource(mb_io_rx_dat_bits_dataSource),
    .io_rx_dat_bits_cBusy(mb_io_rx_dat_bits_cBusy),
    .io_rx_dat_bits_dbID(mb_io_rx_dat_bits_dbID),
    .io_rx_dat_bits_ccID(mb_io_rx_dat_bits_ccID),
    .io_rx_dat_bits_dataID(mb_io_rx_dat_bits_dataID),
    .io_rx_dat_bits_tagOp(mb_io_rx_dat_bits_tagOp),
    .io_rx_dat_bits_tag(mb_io_rx_dat_bits_tag),
    .io_rx_dat_bits_tu(mb_io_rx_dat_bits_tu),
    .io_rx_dat_bits_traceTag(mb_io_rx_dat_bits_traceTag),
    .io_rx_dat_bits_rsvdc(mb_io_rx_dat_bits_rsvdc),
    .io_rx_dat_bits_be(mb_io_rx_dat_bits_be),
    .io_rx_dat_bits_data(mb_io_rx_dat_bits_data),
    .io_rx_dat_bits_dataCheck(mb_io_rx_dat_bits_dataCheck),
    .io_rx_dat_bits_poison(mb_io_rx_dat_bits_poison),
    .io_pCrd_0_query_valid(mb_g_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(mb_g_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(mb_g_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(mb_io_pCrd_0_grant),
    .io_pCrd_1_query_valid(mb_g_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(mb_g_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(mb_g_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(mb_io_pCrd_1_grant),
    .io_pCrd_2_query_valid(mb_g_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(mb_g_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(mb_g_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(mb_io_pCrd_2_grant),
    .io_pCrd_3_query_valid(mb_g_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(mb_g_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(mb_g_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(mb_io_pCrd_3_grant),
    .io_pCrd_4_query_valid(mb_g_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(mb_g_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(mb_g_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(mb_io_pCrd_4_grant),
    .io_pCrd_5_query_valid(mb_g_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(mb_g_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(mb_g_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(mb_io_pCrd_5_grant),
    .io_pCrd_6_query_valid(mb_g_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(mb_g_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(mb_g_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(mb_io_pCrd_6_grant),
    .io_pCrd_7_query_valid(mb_g_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(mb_g_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(mb_g_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(mb_io_pCrd_7_grant),
    .io_pCrd_8_query_valid(mb_g_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(mb_g_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(mb_g_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(mb_io_pCrd_8_grant),
    .io_pCrd_9_query_valid(mb_g_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(mb_g_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(mb_g_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(mb_io_pCrd_9_grant),
    .io_pCrd_10_query_valid(mb_g_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(mb_g_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(mb_g_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(mb_io_pCrd_10_grant),
    .io_pCrd_11_query_valid(mb_g_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(mb_g_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(mb_g_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(mb_io_pCrd_11_grant),
    .io_pCrd_12_query_valid(mb_g_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(mb_g_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(mb_g_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(mb_io_pCrd_12_grant),
    .io_pCrd_13_query_valid(mb_g_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(mb_g_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(mb_g_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(mb_io_pCrd_13_grant),
    .io_pCrd_14_query_valid(mb_g_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(mb_g_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(mb_g_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(mb_io_pCrd_14_grant),
    .io_pCrd_15_query_valid(mb_g_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(mb_g_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(mb_g_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(mb_io_pCrd_15_grant)
  );
  MMIOBridge_xs mb_u_impl (
    .clock(clk),
    .reset(mb_reset),
    .auto_mmio_in_a_ready(mb_i_auto_mmio_in_a_ready),
    .auto_mmio_in_a_valid(mb_auto_mmio_in_a_valid),
    .auto_mmio_in_a_bits_opcode(mb_auto_mmio_in_a_bits_opcode),
    .auto_mmio_in_a_bits_param(mb_auto_mmio_in_a_bits_param),
    .auto_mmio_in_a_bits_size(mb_auto_mmio_in_a_bits_size),
    .auto_mmio_in_a_bits_source(mb_auto_mmio_in_a_bits_source),
    .auto_mmio_in_a_bits_address(mb_auto_mmio_in_a_bits_address),
    .auto_mmio_in_a_bits_user_memBackType_MM(mb_auto_mmio_in_a_bits_user_memBackType_MM),
    .auto_mmio_in_a_bits_user_memPageType_NC(mb_auto_mmio_in_a_bits_user_memPageType_NC),
    .auto_mmio_in_a_bits_mask(mb_auto_mmio_in_a_bits_mask),
    .auto_mmio_in_a_bits_data(mb_auto_mmio_in_a_bits_data),
    .auto_mmio_in_a_bits_corrupt(mb_auto_mmio_in_a_bits_corrupt),
    .auto_mmio_in_d_ready(mb_auto_mmio_in_d_ready),
    .auto_mmio_in_d_valid(mb_i_auto_mmio_in_d_valid),
    .auto_mmio_in_d_bits_opcode(mb_i_auto_mmio_in_d_bits_opcode),
    .auto_mmio_in_d_bits_param(mb_i_auto_mmio_in_d_bits_param),
    .auto_mmio_in_d_bits_size(mb_i_auto_mmio_in_d_bits_size),
    .auto_mmio_in_d_bits_source(mb_i_auto_mmio_in_d_bits_source),
    .auto_mmio_in_d_bits_sink(mb_i_auto_mmio_in_d_bits_sink),
    .auto_mmio_in_d_bits_denied(mb_i_auto_mmio_in_d_bits_denied),
    .auto_mmio_in_d_bits_data(mb_i_auto_mmio_in_d_bits_data),
    .auto_mmio_in_d_bits_corrupt(mb_i_auto_mmio_in_d_bits_corrupt),
    .io_tx_req_ready(mb_io_tx_req_ready),
    .io_tx_req_valid(mb_i_io_tx_req_valid),
    .io_tx_req_bits_qos(mb_i_io_tx_req_bits_qos),
    .io_tx_req_bits_tgtID(mb_i_io_tx_req_bits_tgtID),
    .io_tx_req_bits_srcID(mb_i_io_tx_req_bits_srcID),
    .io_tx_req_bits_txnID(mb_i_io_tx_req_bits_txnID),
    .io_tx_req_bits_returnNID(mb_i_io_tx_req_bits_returnNID),
    .io_tx_req_bits_stashNIDValid(mb_i_io_tx_req_bits_stashNIDValid),
    .io_tx_req_bits_returnTxnID(mb_i_io_tx_req_bits_returnTxnID),
    .io_tx_req_bits_opcode(mb_i_io_tx_req_bits_opcode),
    .io_tx_req_bits_size(mb_i_io_tx_req_bits_size),
    .io_tx_req_bits_addr(mb_i_io_tx_req_bits_addr),
    .io_tx_req_bits_ns(mb_i_io_tx_req_bits_ns),
    .io_tx_req_bits_likelyshared(mb_i_io_tx_req_bits_likelyshared),
    .io_tx_req_bits_allowRetry(mb_i_io_tx_req_bits_allowRetry),
    .io_tx_req_bits_order(mb_i_io_tx_req_bits_order),
    .io_tx_req_bits_pCrdType(mb_i_io_tx_req_bits_pCrdType),
    .io_tx_req_bits_memAttr_allocate(mb_i_io_tx_req_bits_memAttr_allocate),
    .io_tx_req_bits_memAttr_cacheable(mb_i_io_tx_req_bits_memAttr_cacheable),
    .io_tx_req_bits_memAttr_device(mb_i_io_tx_req_bits_memAttr_device),
    .io_tx_req_bits_memAttr_ewa(mb_i_io_tx_req_bits_memAttr_ewa),
    .io_tx_req_bits_snpAttr(mb_i_io_tx_req_bits_snpAttr),
    .io_tx_req_bits_lpIDWithPadding(mb_i_io_tx_req_bits_lpIDWithPadding),
    .io_tx_req_bits_snoopMe(mb_i_io_tx_req_bits_snoopMe),
    .io_tx_req_bits_expCompAck(mb_i_io_tx_req_bits_expCompAck),
    .io_tx_req_bits_tagOp(mb_i_io_tx_req_bits_tagOp),
    .io_tx_req_bits_traceTag(mb_i_io_tx_req_bits_traceTag),
    .io_tx_req_bits_mpam_perfMonGroup(mb_i_io_tx_req_bits_mpam_perfMonGroup),
    .io_tx_req_bits_mpam_partID(mb_i_io_tx_req_bits_mpam_partID),
    .io_tx_req_bits_mpam_mpamNS(mb_i_io_tx_req_bits_mpam_mpamNS),
    .io_tx_req_bits_rsvdc(mb_i_io_tx_req_bits_rsvdc),
    .io_tx_dat_ready(mb_io_tx_dat_ready),
    .io_tx_dat_valid(mb_i_io_tx_dat_valid),
    .io_tx_dat_bits_qos(mb_i_io_tx_dat_bits_qos),
    .io_tx_dat_bits_tgtID(mb_i_io_tx_dat_bits_tgtID),
    .io_tx_dat_bits_srcID(mb_i_io_tx_dat_bits_srcID),
    .io_tx_dat_bits_txnID(mb_i_io_tx_dat_bits_txnID),
    .io_tx_dat_bits_homeNID(mb_i_io_tx_dat_bits_homeNID),
    .io_tx_dat_bits_opcode(mb_i_io_tx_dat_bits_opcode),
    .io_tx_dat_bits_respErr(mb_i_io_tx_dat_bits_respErr),
    .io_tx_dat_bits_resp(mb_i_io_tx_dat_bits_resp),
    .io_tx_dat_bits_dataSource(mb_i_io_tx_dat_bits_dataSource),
    .io_tx_dat_bits_cBusy(mb_i_io_tx_dat_bits_cBusy),
    .io_tx_dat_bits_dbID(mb_i_io_tx_dat_bits_dbID),
    .io_tx_dat_bits_ccID(mb_i_io_tx_dat_bits_ccID),
    .io_tx_dat_bits_dataID(mb_i_io_tx_dat_bits_dataID),
    .io_tx_dat_bits_tagOp(mb_i_io_tx_dat_bits_tagOp),
    .io_tx_dat_bits_tag(mb_i_io_tx_dat_bits_tag),
    .io_tx_dat_bits_tu(mb_i_io_tx_dat_bits_tu),
    .io_tx_dat_bits_traceTag(mb_i_io_tx_dat_bits_traceTag),
    .io_tx_dat_bits_rsvdc(mb_i_io_tx_dat_bits_rsvdc),
    .io_tx_dat_bits_be(mb_i_io_tx_dat_bits_be),
    .io_tx_dat_bits_data(mb_i_io_tx_dat_bits_data),
    .io_tx_dat_bits_dataCheck(mb_i_io_tx_dat_bits_dataCheck),
    .io_tx_dat_bits_poison(mb_i_io_tx_dat_bits_poison),
    .io_rx_rsp_ready(mb_i_io_rx_rsp_ready),
    .io_rx_rsp_valid(mb_io_rx_rsp_valid),
    .io_rx_rsp_bits_qos(mb_io_rx_rsp_bits_qos),
    .io_rx_rsp_bits_tgtID(mb_io_rx_rsp_bits_tgtID),
    .io_rx_rsp_bits_srcID(mb_io_rx_rsp_bits_srcID),
    .io_rx_rsp_bits_txnID(mb_io_rx_rsp_bits_txnID),
    .io_rx_rsp_bits_opcode(mb_io_rx_rsp_bits_opcode),
    .io_rx_rsp_bits_respErr(mb_io_rx_rsp_bits_respErr),
    .io_rx_rsp_bits_resp(mb_io_rx_rsp_bits_resp),
    .io_rx_rsp_bits_fwdState(mb_io_rx_rsp_bits_fwdState),
    .io_rx_rsp_bits_cBusy(mb_io_rx_rsp_bits_cBusy),
    .io_rx_rsp_bits_dbID(mb_io_rx_rsp_bits_dbID),
    .io_rx_rsp_bits_pCrdType(mb_io_rx_rsp_bits_pCrdType),
    .io_rx_rsp_bits_tagOp(mb_io_rx_rsp_bits_tagOp),
    .io_rx_rsp_bits_traceTag(mb_io_rx_rsp_bits_traceTag),
    .io_rx_dat_ready(mb_i_io_rx_dat_ready),
    .io_rx_dat_valid(mb_io_rx_dat_valid),
    .io_rx_dat_bits_qos(mb_io_rx_dat_bits_qos),
    .io_rx_dat_bits_tgtID(mb_io_rx_dat_bits_tgtID),
    .io_rx_dat_bits_srcID(mb_io_rx_dat_bits_srcID),
    .io_rx_dat_bits_txnID(mb_io_rx_dat_bits_txnID),
    .io_rx_dat_bits_homeNID(mb_io_rx_dat_bits_homeNID),
    .io_rx_dat_bits_opcode(mb_io_rx_dat_bits_opcode),
    .io_rx_dat_bits_respErr(mb_io_rx_dat_bits_respErr),
    .io_rx_dat_bits_resp(mb_io_rx_dat_bits_resp),
    .io_rx_dat_bits_dataSource(mb_io_rx_dat_bits_dataSource),
    .io_rx_dat_bits_cBusy(mb_io_rx_dat_bits_cBusy),
    .io_rx_dat_bits_dbID(mb_io_rx_dat_bits_dbID),
    .io_rx_dat_bits_ccID(mb_io_rx_dat_bits_ccID),
    .io_rx_dat_bits_dataID(mb_io_rx_dat_bits_dataID),
    .io_rx_dat_bits_tagOp(mb_io_rx_dat_bits_tagOp),
    .io_rx_dat_bits_tag(mb_io_rx_dat_bits_tag),
    .io_rx_dat_bits_tu(mb_io_rx_dat_bits_tu),
    .io_rx_dat_bits_traceTag(mb_io_rx_dat_bits_traceTag),
    .io_rx_dat_bits_rsvdc(mb_io_rx_dat_bits_rsvdc),
    .io_rx_dat_bits_be(mb_io_rx_dat_bits_be),
    .io_rx_dat_bits_data(mb_io_rx_dat_bits_data),
    .io_rx_dat_bits_dataCheck(mb_io_rx_dat_bits_dataCheck),
    .io_rx_dat_bits_poison(mb_io_rx_dat_bits_poison),
    .io_pCrd_0_query_valid(mb_i_io_pCrd_0_query_valid),
    .io_pCrd_0_query_bits_pCrdType(mb_i_io_pCrd_0_query_bits_pCrdType),
    .io_pCrd_0_query_bits_srcID(mb_i_io_pCrd_0_query_bits_srcID),
    .io_pCrd_0_grant(mb_io_pCrd_0_grant),
    .io_pCrd_1_query_valid(mb_i_io_pCrd_1_query_valid),
    .io_pCrd_1_query_bits_pCrdType(mb_i_io_pCrd_1_query_bits_pCrdType),
    .io_pCrd_1_query_bits_srcID(mb_i_io_pCrd_1_query_bits_srcID),
    .io_pCrd_1_grant(mb_io_pCrd_1_grant),
    .io_pCrd_2_query_valid(mb_i_io_pCrd_2_query_valid),
    .io_pCrd_2_query_bits_pCrdType(mb_i_io_pCrd_2_query_bits_pCrdType),
    .io_pCrd_2_query_bits_srcID(mb_i_io_pCrd_2_query_bits_srcID),
    .io_pCrd_2_grant(mb_io_pCrd_2_grant),
    .io_pCrd_3_query_valid(mb_i_io_pCrd_3_query_valid),
    .io_pCrd_3_query_bits_pCrdType(mb_i_io_pCrd_3_query_bits_pCrdType),
    .io_pCrd_3_query_bits_srcID(mb_i_io_pCrd_3_query_bits_srcID),
    .io_pCrd_3_grant(mb_io_pCrd_3_grant),
    .io_pCrd_4_query_valid(mb_i_io_pCrd_4_query_valid),
    .io_pCrd_4_query_bits_pCrdType(mb_i_io_pCrd_4_query_bits_pCrdType),
    .io_pCrd_4_query_bits_srcID(mb_i_io_pCrd_4_query_bits_srcID),
    .io_pCrd_4_grant(mb_io_pCrd_4_grant),
    .io_pCrd_5_query_valid(mb_i_io_pCrd_5_query_valid),
    .io_pCrd_5_query_bits_pCrdType(mb_i_io_pCrd_5_query_bits_pCrdType),
    .io_pCrd_5_query_bits_srcID(mb_i_io_pCrd_5_query_bits_srcID),
    .io_pCrd_5_grant(mb_io_pCrd_5_grant),
    .io_pCrd_6_query_valid(mb_i_io_pCrd_6_query_valid),
    .io_pCrd_6_query_bits_pCrdType(mb_i_io_pCrd_6_query_bits_pCrdType),
    .io_pCrd_6_query_bits_srcID(mb_i_io_pCrd_6_query_bits_srcID),
    .io_pCrd_6_grant(mb_io_pCrd_6_grant),
    .io_pCrd_7_query_valid(mb_i_io_pCrd_7_query_valid),
    .io_pCrd_7_query_bits_pCrdType(mb_i_io_pCrd_7_query_bits_pCrdType),
    .io_pCrd_7_query_bits_srcID(mb_i_io_pCrd_7_query_bits_srcID),
    .io_pCrd_7_grant(mb_io_pCrd_7_grant),
    .io_pCrd_8_query_valid(mb_i_io_pCrd_8_query_valid),
    .io_pCrd_8_query_bits_pCrdType(mb_i_io_pCrd_8_query_bits_pCrdType),
    .io_pCrd_8_query_bits_srcID(mb_i_io_pCrd_8_query_bits_srcID),
    .io_pCrd_8_grant(mb_io_pCrd_8_grant),
    .io_pCrd_9_query_valid(mb_i_io_pCrd_9_query_valid),
    .io_pCrd_9_query_bits_pCrdType(mb_i_io_pCrd_9_query_bits_pCrdType),
    .io_pCrd_9_query_bits_srcID(mb_i_io_pCrd_9_query_bits_srcID),
    .io_pCrd_9_grant(mb_io_pCrd_9_grant),
    .io_pCrd_10_query_valid(mb_i_io_pCrd_10_query_valid),
    .io_pCrd_10_query_bits_pCrdType(mb_i_io_pCrd_10_query_bits_pCrdType),
    .io_pCrd_10_query_bits_srcID(mb_i_io_pCrd_10_query_bits_srcID),
    .io_pCrd_10_grant(mb_io_pCrd_10_grant),
    .io_pCrd_11_query_valid(mb_i_io_pCrd_11_query_valid),
    .io_pCrd_11_query_bits_pCrdType(mb_i_io_pCrd_11_query_bits_pCrdType),
    .io_pCrd_11_query_bits_srcID(mb_i_io_pCrd_11_query_bits_srcID),
    .io_pCrd_11_grant(mb_io_pCrd_11_grant),
    .io_pCrd_12_query_valid(mb_i_io_pCrd_12_query_valid),
    .io_pCrd_12_query_bits_pCrdType(mb_i_io_pCrd_12_query_bits_pCrdType),
    .io_pCrd_12_query_bits_srcID(mb_i_io_pCrd_12_query_bits_srcID),
    .io_pCrd_12_grant(mb_io_pCrd_12_grant),
    .io_pCrd_13_query_valid(mb_i_io_pCrd_13_query_valid),
    .io_pCrd_13_query_bits_pCrdType(mb_i_io_pCrd_13_query_bits_pCrdType),
    .io_pCrd_13_query_bits_srcID(mb_i_io_pCrd_13_query_bits_srcID),
    .io_pCrd_13_grant(mb_io_pCrd_13_grant),
    .io_pCrd_14_query_valid(mb_i_io_pCrd_14_query_valid),
    .io_pCrd_14_query_bits_pCrdType(mb_i_io_pCrd_14_query_bits_pCrdType),
    .io_pCrd_14_query_bits_srcID(mb_i_io_pCrd_14_query_bits_srcID),
    .io_pCrd_14_grant(mb_io_pCrd_14_grant),
    .io_pCrd_15_query_valid(mb_i_io_pCrd_15_query_valid),
    .io_pCrd_15_query_bits_pCrdType(mb_i_io_pCrd_15_query_bits_pCrdType),
    .io_pCrd_15_query_bits_srcID(mb_i_io_pCrd_15_query_bits_srcID),
    .io_pCrd_15_grant(mb_io_pCrd_15_grant)
  );

  initial begin
    if ($value$plusargs("ncycles=%d", NCYCLES)) ;
    for (cyc = 0; cyc < NCYCLES; cyc++) begin
      @(negedge clk);
      if (cyc % 4000 == 0) mb_mode = $urandom_range(0, 15);
      mb_auto_mmio_in_a_valid = 1'($urandom);
      mb_auto_mmio_in_a_bits_opcode = 4'($urandom);
      mb_auto_mmio_in_a_bits_param = 3'($urandom);
      mb_auto_mmio_in_a_bits_size = 2'($urandom);
      mb_auto_mmio_in_a_bits_source = 5'($urandom);
      mb_auto_mmio_in_a_bits_address = 48'({$urandom, $urandom});
      mb_auto_mmio_in_a_bits_user_memBackType_MM = 1'($urandom);
      mb_auto_mmio_in_a_bits_user_memPageType_NC = 1'($urandom);
      mb_auto_mmio_in_a_bits_mask = 8'($urandom);
      mb_auto_mmio_in_a_bits_data = 64'({$urandom, $urandom});
      mb_auto_mmio_in_a_bits_corrupt = 1'($urandom);
      mb_auto_mmio_in_d_ready = 1'($urandom);
      mb_io_tx_req_ready = 1'($urandom);
      mb_io_tx_dat_ready = 1'($urandom);
      mb_io_rx_rsp_valid = 1'($urandom);
      mb_io_rx_rsp_bits_qos = 4'($urandom);
      mb_io_rx_rsp_bits_tgtID = 11'($urandom);
      mb_io_rx_rsp_bits_srcID = 11'($urandom);
      mb_io_rx_rsp_bits_txnID = 12'($urandom);
      mb_io_rx_rsp_bits_opcode = 5'($urandom);
      mb_io_rx_rsp_bits_respErr = 2'($urandom);
      mb_io_rx_rsp_bits_resp = 3'($urandom);
      mb_io_rx_rsp_bits_fwdState = 3'($urandom);
      mb_io_rx_rsp_bits_cBusy = 3'($urandom);
      mb_io_rx_rsp_bits_dbID = 12'($urandom);
      mb_io_rx_rsp_bits_pCrdType = 4'($urandom);
      mb_io_rx_rsp_bits_tagOp = 2'($urandom);
      mb_io_rx_rsp_bits_traceTag = 1'($urandom);
      mb_io_rx_dat_valid = 1'($urandom);
      mb_io_rx_dat_bits_qos = 4'($urandom);
      mb_io_rx_dat_bits_tgtID = 11'($urandom);
      mb_io_rx_dat_bits_srcID = 11'($urandom);
      mb_io_rx_dat_bits_txnID = 12'($urandom);
      mb_io_rx_dat_bits_homeNID = 11'($urandom);
      mb_io_rx_dat_bits_opcode = 4'($urandom);
      mb_io_rx_dat_bits_respErr = 2'($urandom);
      mb_io_rx_dat_bits_resp = 3'($urandom);
      mb_io_rx_dat_bits_dataSource = 4'($urandom);
      mb_io_rx_dat_bits_cBusy = 3'($urandom);
      mb_io_rx_dat_bits_dbID = 12'($urandom);
      mb_io_rx_dat_bits_ccID = 2'($urandom);
      mb_io_rx_dat_bits_dataID = 2'($urandom);
      mb_io_rx_dat_bits_tagOp = 2'($urandom);
      mb_io_rx_dat_bits_tag = 8'($urandom);
      mb_io_rx_dat_bits_tu = 2'($urandom);
      mb_io_rx_dat_bits_traceTag = 1'($urandom);
      mb_io_rx_dat_bits_rsvdc = 4'($urandom);
      mb_io_rx_dat_bits_be = 32'($urandom);
      mb_io_rx_dat_bits_data = 256'({$urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom, $urandom});
      mb_io_rx_dat_bits_dataCheck = 32'($urandom);
      mb_io_rx_dat_bits_poison = 4'($urandom);
      mb_io_pCrd_0_grant = 1'($urandom);
      mb_io_pCrd_1_grant = 1'($urandom);
      mb_io_pCrd_2_grant = 1'($urandom);
      mb_io_pCrd_3_grant = 1'($urandom);
      mb_io_pCrd_4_grant = 1'($urandom);
      mb_io_pCrd_5_grant = 1'($urandom);
      mb_io_pCrd_6_grant = 1'($urandom);
      mb_io_pCrd_7_grant = 1'($urandom);
      mb_io_pCrd_8_grant = 1'($urandom);
      mb_io_pCrd_9_grant = 1'($urandom);
      mb_io_pCrd_10_grant = 1'($urandom);
      mb_io_pCrd_11_grant = 1'($urandom);
      mb_io_pCrd_12_grant = 1'($urandom);
      mb_io_pCrd_13_grant = 1'($urandom);
      mb_io_pCrd_14_grant = 1'($urandom);
      mb_io_pCrd_15_grant = 1'($urandom);
      mb_reset = (cyc < RESET_CYC) || ($urandom_range(0, 19999) == 0);
      begin : stim_mb
        case ($urandom_range(0, 7))
          0, 1, 2: mb_auto_mmio_in_a_bits_opcode = 4'h4;
          3, 4:    mb_auto_mmio_in_a_bits_opcode = 4'h0;
          5, 6:    mb_auto_mmio_in_a_bits_opcode = 4'h1;
          default: ;
        endcase
        // txnID：3/4 时间挑一个正在等 RXRSP / RXDAT 的槽（golden 侧槽的 ready），其余在 0..15 随机，1/8 给落空的大值
        begin
          int n; int pick [16];
          n = 0;
          for (int k = 0; k < 16; k++) if (mb_rsp_rdy[k]) begin pick[n] = k; n++; end
          if (n != 0 && $urandom_range(0, 3) != 0) mb_io_rx_rsp_bits_txnID = 12'(pick[$urandom_range(0, n - 1)]);
          else if ($urandom_range(0, 7) != 0) mb_io_rx_rsp_bits_txnID = 12'($urandom_range(0, 15));
          n = 0;
          for (int k = 0; k < 16; k++) if (mb_dat_rdy[k]) begin pick[n] = k; n++; end
          if (n != 0 && $urandom_range(0, 3) != 0) mb_io_rx_dat_bits_txnID = 12'(pick[$urandom_range(0, n - 1)]);
          else if ($urandom_range(0, 7) != 0) mb_io_rx_dat_bits_txnID = 12'($urandom_range(0, 15));
        end
        case ($urandom_range(0, 15))
          0, 1:       mb_io_rx_rsp_bits_opcode = 5'h03;
          2, 3, 4:    mb_io_rx_rsp_bits_opcode = 5'h04;
          5, 6, 7:    mb_io_rx_rsp_bits_opcode = 5'h05;
          8, 9:       mb_io_rx_rsp_bits_opcode = 5'h06;
          10, 11, 12: mb_io_rx_rsp_bits_opcode = 5'h08;
          13:         mb_io_rx_rsp_bits_opcode = 5'h0E;
          default: ;
        endcase
        if ($urandom_range(0, 7) != 0)
          for (int b = 0; b < 32; b++)
            mb_io_rx_dat_bits_dataCheck[b] = ~(^mb_io_rx_dat_bits_data[8*b +: 8]);
        if ($urandom_range(0, 3) != 0) mb_io_rx_dat_bits_respErr = 2'h0;
        if ($urandom_range(0, 3) != 0) mb_io_rx_rsp_bits_respErr = 2'h0;
        if ($urandom_range(0, 7) != 0) mb_io_rx_dat_bits_poison = 4'h0;
        mb_io_pCrd_0_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_1_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_2_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_3_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_4_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_5_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_6_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_7_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_8_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_9_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_10_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_11_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_12_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_13_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_14_grant = ($urandom_range(0, 7) == 0);
        mb_io_pCrd_15_grant = ($urandom_range(0, 7) == 0);
        
        if (mb_mode >= 12) begin
          mb_io_tx_req_ready      = ($urandom_range(0, 7) == 0);
          mb_io_tx_dat_ready      = ($urandom_range(0, 7) == 0);
          mb_auto_mmio_in_d_ready = ($urandom_range(0, 7) == 0);
        end
      end
      #4;
      mb_armed = 1'b1;
      if (cyc >= RESET_CYC + 0 && (&mb_armed)) begin
        checks++;
        if (mb_g_auto_mmio_in_a_ready !== mb_i_auto_mmio_in_a_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_a_ready g=%h i=%h", cyc, mb_g_auto_mmio_in_a_ready, mb_i_auto_mmio_in_a_ready);
        end
        mb_s1_auto_mmio_in_a_ready |= mb_g_auto_mmio_in_a_ready;
        mb_s0_auto_mmio_in_a_ready |= ~mb_g_auto_mmio_in_a_ready;
        checks++;
        if (mb_g_auto_mmio_in_d_valid !== mb_i_auto_mmio_in_d_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_valid g=%h i=%h", cyc, mb_g_auto_mmio_in_d_valid, mb_i_auto_mmio_in_d_valid);
        end
        mb_s1_auto_mmio_in_d_valid |= mb_g_auto_mmio_in_d_valid;
        mb_s0_auto_mmio_in_d_valid |= ~mb_g_auto_mmio_in_d_valid;
        checks++;
        if (mb_g_auto_mmio_in_d_bits_opcode !== mb_i_auto_mmio_in_d_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_bits_opcode g=%h i=%h", cyc, mb_g_auto_mmio_in_d_bits_opcode, mb_i_auto_mmio_in_d_bits_opcode);
        end
        mb_s1_auto_mmio_in_d_bits_opcode |= mb_g_auto_mmio_in_d_bits_opcode;
        mb_s0_auto_mmio_in_d_bits_opcode |= ~mb_g_auto_mmio_in_d_bits_opcode;
        checks++;
        if (mb_g_auto_mmio_in_d_bits_param !== mb_i_auto_mmio_in_d_bits_param) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_bits_param g=%h i=%h", cyc, mb_g_auto_mmio_in_d_bits_param, mb_i_auto_mmio_in_d_bits_param);
        end
        mb_s1_auto_mmio_in_d_bits_param |= mb_g_auto_mmio_in_d_bits_param;
        mb_s0_auto_mmio_in_d_bits_param |= ~mb_g_auto_mmio_in_d_bits_param;
        checks++;
        if (mb_g_auto_mmio_in_d_bits_size !== mb_i_auto_mmio_in_d_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_bits_size g=%h i=%h", cyc, mb_g_auto_mmio_in_d_bits_size, mb_i_auto_mmio_in_d_bits_size);
        end
        mb_s1_auto_mmio_in_d_bits_size |= mb_g_auto_mmio_in_d_bits_size;
        mb_s0_auto_mmio_in_d_bits_size |= ~mb_g_auto_mmio_in_d_bits_size;
        checks++;
        if (mb_g_auto_mmio_in_d_bits_source !== mb_i_auto_mmio_in_d_bits_source) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_bits_source g=%h i=%h", cyc, mb_g_auto_mmio_in_d_bits_source, mb_i_auto_mmio_in_d_bits_source);
        end
        mb_s1_auto_mmio_in_d_bits_source |= mb_g_auto_mmio_in_d_bits_source;
        mb_s0_auto_mmio_in_d_bits_source |= ~mb_g_auto_mmio_in_d_bits_source;
        checks++;
        if (mb_g_auto_mmio_in_d_bits_sink !== mb_i_auto_mmio_in_d_bits_sink) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_bits_sink g=%h i=%h", cyc, mb_g_auto_mmio_in_d_bits_sink, mb_i_auto_mmio_in_d_bits_sink);
        end
        mb_s1_auto_mmio_in_d_bits_sink |= mb_g_auto_mmio_in_d_bits_sink;
        mb_s0_auto_mmio_in_d_bits_sink |= ~mb_g_auto_mmio_in_d_bits_sink;
        checks++;
        if (mb_g_auto_mmio_in_d_bits_denied !== mb_i_auto_mmio_in_d_bits_denied) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_bits_denied g=%h i=%h", cyc, mb_g_auto_mmio_in_d_bits_denied, mb_i_auto_mmio_in_d_bits_denied);
        end
        mb_s1_auto_mmio_in_d_bits_denied |= mb_g_auto_mmio_in_d_bits_denied;
        mb_s0_auto_mmio_in_d_bits_denied |= ~mb_g_auto_mmio_in_d_bits_denied;
        checks++;
        if (mb_g_auto_mmio_in_d_bits_data !== mb_i_auto_mmio_in_d_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_bits_data g=%h i=%h", cyc, mb_g_auto_mmio_in_d_bits_data, mb_i_auto_mmio_in_d_bits_data);
        end
        mb_s1_auto_mmio_in_d_bits_data |= mb_g_auto_mmio_in_d_bits_data;
        mb_s0_auto_mmio_in_d_bits_data |= ~mb_g_auto_mmio_in_d_bits_data;
        checks++;
        if (mb_g_auto_mmio_in_d_bits_corrupt !== mb_i_auto_mmio_in_d_bits_corrupt) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.auto_mmio_in_d_bits_corrupt g=%h i=%h", cyc, mb_g_auto_mmio_in_d_bits_corrupt, mb_i_auto_mmio_in_d_bits_corrupt);
        end
        mb_s1_auto_mmio_in_d_bits_corrupt |= mb_g_auto_mmio_in_d_bits_corrupt;
        mb_s0_auto_mmio_in_d_bits_corrupt |= ~mb_g_auto_mmio_in_d_bits_corrupt;
        checks++;
        if (mb_g_io_tx_req_valid !== mb_i_io_tx_req_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_valid g=%h i=%h", cyc, mb_g_io_tx_req_valid, mb_i_io_tx_req_valid);
        end
        mb_s1_io_tx_req_valid |= mb_g_io_tx_req_valid;
        mb_s0_io_tx_req_valid |= ~mb_g_io_tx_req_valid;
        checks++;
        if (mb_g_io_tx_req_bits_qos !== mb_i_io_tx_req_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_qos g=%h i=%h", cyc, mb_g_io_tx_req_bits_qos, mb_i_io_tx_req_bits_qos);
        end
        mb_s1_io_tx_req_bits_qos |= mb_g_io_tx_req_bits_qos;
        mb_s0_io_tx_req_bits_qos |= ~mb_g_io_tx_req_bits_qos;
        checks++;
        if (mb_g_io_tx_req_bits_tgtID !== mb_i_io_tx_req_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_tgtID g=%h i=%h", cyc, mb_g_io_tx_req_bits_tgtID, mb_i_io_tx_req_bits_tgtID);
        end
        mb_s1_io_tx_req_bits_tgtID |= mb_g_io_tx_req_bits_tgtID;
        mb_s0_io_tx_req_bits_tgtID |= ~mb_g_io_tx_req_bits_tgtID;
        checks++;
        if (mb_g_io_tx_req_bits_srcID !== mb_i_io_tx_req_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_srcID g=%h i=%h", cyc, mb_g_io_tx_req_bits_srcID, mb_i_io_tx_req_bits_srcID);
        end
        mb_s1_io_tx_req_bits_srcID |= mb_g_io_tx_req_bits_srcID;
        mb_s0_io_tx_req_bits_srcID |= ~mb_g_io_tx_req_bits_srcID;
        checks++;
        if (mb_g_io_tx_req_bits_txnID !== mb_i_io_tx_req_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_txnID g=%h i=%h", cyc, mb_g_io_tx_req_bits_txnID, mb_i_io_tx_req_bits_txnID);
        end
        mb_s1_io_tx_req_bits_txnID |= mb_g_io_tx_req_bits_txnID;
        mb_s0_io_tx_req_bits_txnID |= ~mb_g_io_tx_req_bits_txnID;
        checks++;
        if (mb_g_io_tx_req_bits_returnNID !== mb_i_io_tx_req_bits_returnNID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_returnNID g=%h i=%h", cyc, mb_g_io_tx_req_bits_returnNID, mb_i_io_tx_req_bits_returnNID);
        end
        mb_s1_io_tx_req_bits_returnNID |= mb_g_io_tx_req_bits_returnNID;
        mb_s0_io_tx_req_bits_returnNID |= ~mb_g_io_tx_req_bits_returnNID;
        checks++;
        if (mb_g_io_tx_req_bits_stashNIDValid !== mb_i_io_tx_req_bits_stashNIDValid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_stashNIDValid g=%h i=%h", cyc, mb_g_io_tx_req_bits_stashNIDValid, mb_i_io_tx_req_bits_stashNIDValid);
        end
        mb_s1_io_tx_req_bits_stashNIDValid |= mb_g_io_tx_req_bits_stashNIDValid;
        mb_s0_io_tx_req_bits_stashNIDValid |= ~mb_g_io_tx_req_bits_stashNIDValid;
        checks++;
        if (mb_g_io_tx_req_bits_returnTxnID !== mb_i_io_tx_req_bits_returnTxnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_returnTxnID g=%h i=%h", cyc, mb_g_io_tx_req_bits_returnTxnID, mb_i_io_tx_req_bits_returnTxnID);
        end
        mb_s1_io_tx_req_bits_returnTxnID |= mb_g_io_tx_req_bits_returnTxnID;
        mb_s0_io_tx_req_bits_returnTxnID |= ~mb_g_io_tx_req_bits_returnTxnID;
        checks++;
        if (mb_g_io_tx_req_bits_opcode !== mb_i_io_tx_req_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_opcode g=%h i=%h", cyc, mb_g_io_tx_req_bits_opcode, mb_i_io_tx_req_bits_opcode);
        end
        mb_s1_io_tx_req_bits_opcode |= mb_g_io_tx_req_bits_opcode;
        mb_s0_io_tx_req_bits_opcode |= ~mb_g_io_tx_req_bits_opcode;
        checks++;
        if (mb_g_io_tx_req_bits_size !== mb_i_io_tx_req_bits_size) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_size g=%h i=%h", cyc, mb_g_io_tx_req_bits_size, mb_i_io_tx_req_bits_size);
        end
        mb_s1_io_tx_req_bits_size |= mb_g_io_tx_req_bits_size;
        mb_s0_io_tx_req_bits_size |= ~mb_g_io_tx_req_bits_size;
        checks++;
        if (mb_g_io_tx_req_bits_addr !== mb_i_io_tx_req_bits_addr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_addr g=%h i=%h", cyc, mb_g_io_tx_req_bits_addr, mb_i_io_tx_req_bits_addr);
        end
        mb_s1_io_tx_req_bits_addr |= mb_g_io_tx_req_bits_addr;
        mb_s0_io_tx_req_bits_addr |= ~mb_g_io_tx_req_bits_addr;
        checks++;
        if (mb_g_io_tx_req_bits_ns !== mb_i_io_tx_req_bits_ns) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_ns g=%h i=%h", cyc, mb_g_io_tx_req_bits_ns, mb_i_io_tx_req_bits_ns);
        end
        mb_s1_io_tx_req_bits_ns |= mb_g_io_tx_req_bits_ns;
        mb_s0_io_tx_req_bits_ns |= ~mb_g_io_tx_req_bits_ns;
        checks++;
        if (mb_g_io_tx_req_bits_likelyshared !== mb_i_io_tx_req_bits_likelyshared) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_likelyshared g=%h i=%h", cyc, mb_g_io_tx_req_bits_likelyshared, mb_i_io_tx_req_bits_likelyshared);
        end
        mb_s1_io_tx_req_bits_likelyshared |= mb_g_io_tx_req_bits_likelyshared;
        mb_s0_io_tx_req_bits_likelyshared |= ~mb_g_io_tx_req_bits_likelyshared;
        checks++;
        if (mb_g_io_tx_req_bits_allowRetry !== mb_i_io_tx_req_bits_allowRetry) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_allowRetry g=%h i=%h", cyc, mb_g_io_tx_req_bits_allowRetry, mb_i_io_tx_req_bits_allowRetry);
        end
        mb_s1_io_tx_req_bits_allowRetry |= mb_g_io_tx_req_bits_allowRetry;
        mb_s0_io_tx_req_bits_allowRetry |= ~mb_g_io_tx_req_bits_allowRetry;
        checks++;
        if (mb_g_io_tx_req_bits_order !== mb_i_io_tx_req_bits_order) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_order g=%h i=%h", cyc, mb_g_io_tx_req_bits_order, mb_i_io_tx_req_bits_order);
        end
        mb_s1_io_tx_req_bits_order |= mb_g_io_tx_req_bits_order;
        mb_s0_io_tx_req_bits_order |= ~mb_g_io_tx_req_bits_order;
        checks++;
        if (mb_g_io_tx_req_bits_pCrdType !== mb_i_io_tx_req_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_pCrdType g=%h i=%h", cyc, mb_g_io_tx_req_bits_pCrdType, mb_i_io_tx_req_bits_pCrdType);
        end
        mb_s1_io_tx_req_bits_pCrdType |= mb_g_io_tx_req_bits_pCrdType;
        mb_s0_io_tx_req_bits_pCrdType |= ~mb_g_io_tx_req_bits_pCrdType;
        checks++;
        if (mb_g_io_tx_req_bits_memAttr_allocate !== mb_i_io_tx_req_bits_memAttr_allocate) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_memAttr_allocate g=%h i=%h", cyc, mb_g_io_tx_req_bits_memAttr_allocate, mb_i_io_tx_req_bits_memAttr_allocate);
        end
        mb_s1_io_tx_req_bits_memAttr_allocate |= mb_g_io_tx_req_bits_memAttr_allocate;
        mb_s0_io_tx_req_bits_memAttr_allocate |= ~mb_g_io_tx_req_bits_memAttr_allocate;
        checks++;
        if (mb_g_io_tx_req_bits_memAttr_cacheable !== mb_i_io_tx_req_bits_memAttr_cacheable) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_memAttr_cacheable g=%h i=%h", cyc, mb_g_io_tx_req_bits_memAttr_cacheable, mb_i_io_tx_req_bits_memAttr_cacheable);
        end
        mb_s1_io_tx_req_bits_memAttr_cacheable |= mb_g_io_tx_req_bits_memAttr_cacheable;
        mb_s0_io_tx_req_bits_memAttr_cacheable |= ~mb_g_io_tx_req_bits_memAttr_cacheable;
        checks++;
        if (mb_g_io_tx_req_bits_memAttr_device !== mb_i_io_tx_req_bits_memAttr_device) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_memAttr_device g=%h i=%h", cyc, mb_g_io_tx_req_bits_memAttr_device, mb_i_io_tx_req_bits_memAttr_device);
        end
        mb_s1_io_tx_req_bits_memAttr_device |= mb_g_io_tx_req_bits_memAttr_device;
        mb_s0_io_tx_req_bits_memAttr_device |= ~mb_g_io_tx_req_bits_memAttr_device;
        checks++;
        if (mb_g_io_tx_req_bits_memAttr_ewa !== mb_i_io_tx_req_bits_memAttr_ewa) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_memAttr_ewa g=%h i=%h", cyc, mb_g_io_tx_req_bits_memAttr_ewa, mb_i_io_tx_req_bits_memAttr_ewa);
        end
        mb_s1_io_tx_req_bits_memAttr_ewa |= mb_g_io_tx_req_bits_memAttr_ewa;
        mb_s0_io_tx_req_bits_memAttr_ewa |= ~mb_g_io_tx_req_bits_memAttr_ewa;
        checks++;
        if (mb_g_io_tx_req_bits_snpAttr !== mb_i_io_tx_req_bits_snpAttr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_snpAttr g=%h i=%h", cyc, mb_g_io_tx_req_bits_snpAttr, mb_i_io_tx_req_bits_snpAttr);
        end
        mb_s1_io_tx_req_bits_snpAttr |= mb_g_io_tx_req_bits_snpAttr;
        mb_s0_io_tx_req_bits_snpAttr |= ~mb_g_io_tx_req_bits_snpAttr;
        checks++;
        if (mb_g_io_tx_req_bits_lpIDWithPadding !== mb_i_io_tx_req_bits_lpIDWithPadding) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_lpIDWithPadding g=%h i=%h", cyc, mb_g_io_tx_req_bits_lpIDWithPadding, mb_i_io_tx_req_bits_lpIDWithPadding);
        end
        mb_s1_io_tx_req_bits_lpIDWithPadding |= mb_g_io_tx_req_bits_lpIDWithPadding;
        mb_s0_io_tx_req_bits_lpIDWithPadding |= ~mb_g_io_tx_req_bits_lpIDWithPadding;
        checks++;
        if (mb_g_io_tx_req_bits_snoopMe !== mb_i_io_tx_req_bits_snoopMe) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_snoopMe g=%h i=%h", cyc, mb_g_io_tx_req_bits_snoopMe, mb_i_io_tx_req_bits_snoopMe);
        end
        mb_s1_io_tx_req_bits_snoopMe |= mb_g_io_tx_req_bits_snoopMe;
        mb_s0_io_tx_req_bits_snoopMe |= ~mb_g_io_tx_req_bits_snoopMe;
        checks++;
        if (mb_g_io_tx_req_bits_expCompAck !== mb_i_io_tx_req_bits_expCompAck) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_expCompAck g=%h i=%h", cyc, mb_g_io_tx_req_bits_expCompAck, mb_i_io_tx_req_bits_expCompAck);
        end
        mb_s1_io_tx_req_bits_expCompAck |= mb_g_io_tx_req_bits_expCompAck;
        mb_s0_io_tx_req_bits_expCompAck |= ~mb_g_io_tx_req_bits_expCompAck;
        checks++;
        if (mb_g_io_tx_req_bits_tagOp !== mb_i_io_tx_req_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_tagOp g=%h i=%h", cyc, mb_g_io_tx_req_bits_tagOp, mb_i_io_tx_req_bits_tagOp);
        end
        mb_s1_io_tx_req_bits_tagOp |= mb_g_io_tx_req_bits_tagOp;
        mb_s0_io_tx_req_bits_tagOp |= ~mb_g_io_tx_req_bits_tagOp;
        checks++;
        if (mb_g_io_tx_req_bits_traceTag !== mb_i_io_tx_req_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_traceTag g=%h i=%h", cyc, mb_g_io_tx_req_bits_traceTag, mb_i_io_tx_req_bits_traceTag);
        end
        mb_s1_io_tx_req_bits_traceTag |= mb_g_io_tx_req_bits_traceTag;
        mb_s0_io_tx_req_bits_traceTag |= ~mb_g_io_tx_req_bits_traceTag;
        checks++;
        if (mb_g_io_tx_req_bits_mpam_perfMonGroup !== mb_i_io_tx_req_bits_mpam_perfMonGroup) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_mpam_perfMonGroup g=%h i=%h", cyc, mb_g_io_tx_req_bits_mpam_perfMonGroup, mb_i_io_tx_req_bits_mpam_perfMonGroup);
        end
        mb_s1_io_tx_req_bits_mpam_perfMonGroup |= mb_g_io_tx_req_bits_mpam_perfMonGroup;
        mb_s0_io_tx_req_bits_mpam_perfMonGroup |= ~mb_g_io_tx_req_bits_mpam_perfMonGroup;
        checks++;
        if (mb_g_io_tx_req_bits_mpam_partID !== mb_i_io_tx_req_bits_mpam_partID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_mpam_partID g=%h i=%h", cyc, mb_g_io_tx_req_bits_mpam_partID, mb_i_io_tx_req_bits_mpam_partID);
        end
        mb_s1_io_tx_req_bits_mpam_partID |= mb_g_io_tx_req_bits_mpam_partID;
        mb_s0_io_tx_req_bits_mpam_partID |= ~mb_g_io_tx_req_bits_mpam_partID;
        checks++;
        if (mb_g_io_tx_req_bits_mpam_mpamNS !== mb_i_io_tx_req_bits_mpam_mpamNS) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_mpam_mpamNS g=%h i=%h", cyc, mb_g_io_tx_req_bits_mpam_mpamNS, mb_i_io_tx_req_bits_mpam_mpamNS);
        end
        mb_s1_io_tx_req_bits_mpam_mpamNS |= mb_g_io_tx_req_bits_mpam_mpamNS;
        mb_s0_io_tx_req_bits_mpam_mpamNS |= ~mb_g_io_tx_req_bits_mpam_mpamNS;
        checks++;
        if (mb_g_io_tx_req_bits_rsvdc !== mb_i_io_tx_req_bits_rsvdc) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_req_bits_rsvdc g=%h i=%h", cyc, mb_g_io_tx_req_bits_rsvdc, mb_i_io_tx_req_bits_rsvdc);
        end
        mb_s1_io_tx_req_bits_rsvdc |= mb_g_io_tx_req_bits_rsvdc;
        mb_s0_io_tx_req_bits_rsvdc |= ~mb_g_io_tx_req_bits_rsvdc;
        checks++;
        if (mb_g_io_tx_dat_valid !== mb_i_io_tx_dat_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_valid g=%h i=%h", cyc, mb_g_io_tx_dat_valid, mb_i_io_tx_dat_valid);
        end
        mb_s1_io_tx_dat_valid |= mb_g_io_tx_dat_valid;
        mb_s0_io_tx_dat_valid |= ~mb_g_io_tx_dat_valid;
        checks++;
        if (mb_g_io_tx_dat_bits_qos !== mb_i_io_tx_dat_bits_qos) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_qos g=%h i=%h", cyc, mb_g_io_tx_dat_bits_qos, mb_i_io_tx_dat_bits_qos);
        end
        mb_s1_io_tx_dat_bits_qos |= mb_g_io_tx_dat_bits_qos;
        mb_s0_io_tx_dat_bits_qos |= ~mb_g_io_tx_dat_bits_qos;
        checks++;
        if (mb_g_io_tx_dat_bits_tgtID !== mb_i_io_tx_dat_bits_tgtID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_tgtID g=%h i=%h", cyc, mb_g_io_tx_dat_bits_tgtID, mb_i_io_tx_dat_bits_tgtID);
        end
        mb_s1_io_tx_dat_bits_tgtID |= mb_g_io_tx_dat_bits_tgtID;
        mb_s0_io_tx_dat_bits_tgtID |= ~mb_g_io_tx_dat_bits_tgtID;
        checks++;
        if (mb_g_io_tx_dat_bits_srcID !== mb_i_io_tx_dat_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_srcID g=%h i=%h", cyc, mb_g_io_tx_dat_bits_srcID, mb_i_io_tx_dat_bits_srcID);
        end
        mb_s1_io_tx_dat_bits_srcID |= mb_g_io_tx_dat_bits_srcID;
        mb_s0_io_tx_dat_bits_srcID |= ~mb_g_io_tx_dat_bits_srcID;
        checks++;
        if (mb_g_io_tx_dat_bits_txnID !== mb_i_io_tx_dat_bits_txnID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_txnID g=%h i=%h", cyc, mb_g_io_tx_dat_bits_txnID, mb_i_io_tx_dat_bits_txnID);
        end
        mb_s1_io_tx_dat_bits_txnID |= mb_g_io_tx_dat_bits_txnID;
        mb_s0_io_tx_dat_bits_txnID |= ~mb_g_io_tx_dat_bits_txnID;
        checks++;
        if (mb_g_io_tx_dat_bits_homeNID !== mb_i_io_tx_dat_bits_homeNID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_homeNID g=%h i=%h", cyc, mb_g_io_tx_dat_bits_homeNID, mb_i_io_tx_dat_bits_homeNID);
        end
        mb_s1_io_tx_dat_bits_homeNID |= mb_g_io_tx_dat_bits_homeNID;
        mb_s0_io_tx_dat_bits_homeNID |= ~mb_g_io_tx_dat_bits_homeNID;
        checks++;
        if (mb_g_io_tx_dat_bits_opcode !== mb_i_io_tx_dat_bits_opcode) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_opcode g=%h i=%h", cyc, mb_g_io_tx_dat_bits_opcode, mb_i_io_tx_dat_bits_opcode);
        end
        mb_s1_io_tx_dat_bits_opcode |= mb_g_io_tx_dat_bits_opcode;
        mb_s0_io_tx_dat_bits_opcode |= ~mb_g_io_tx_dat_bits_opcode;
        checks++;
        if (mb_g_io_tx_dat_bits_respErr !== mb_i_io_tx_dat_bits_respErr) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_respErr g=%h i=%h", cyc, mb_g_io_tx_dat_bits_respErr, mb_i_io_tx_dat_bits_respErr);
        end
        mb_s1_io_tx_dat_bits_respErr |= mb_g_io_tx_dat_bits_respErr;
        mb_s0_io_tx_dat_bits_respErr |= ~mb_g_io_tx_dat_bits_respErr;
        checks++;
        if (mb_g_io_tx_dat_bits_resp !== mb_i_io_tx_dat_bits_resp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_resp g=%h i=%h", cyc, mb_g_io_tx_dat_bits_resp, mb_i_io_tx_dat_bits_resp);
        end
        mb_s1_io_tx_dat_bits_resp |= mb_g_io_tx_dat_bits_resp;
        mb_s0_io_tx_dat_bits_resp |= ~mb_g_io_tx_dat_bits_resp;
        checks++;
        if (mb_g_io_tx_dat_bits_dataSource !== mb_i_io_tx_dat_bits_dataSource) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_dataSource g=%h i=%h", cyc, mb_g_io_tx_dat_bits_dataSource, mb_i_io_tx_dat_bits_dataSource);
        end
        mb_s1_io_tx_dat_bits_dataSource |= mb_g_io_tx_dat_bits_dataSource;
        mb_s0_io_tx_dat_bits_dataSource |= ~mb_g_io_tx_dat_bits_dataSource;
        checks++;
        if (mb_g_io_tx_dat_bits_cBusy !== mb_i_io_tx_dat_bits_cBusy) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_cBusy g=%h i=%h", cyc, mb_g_io_tx_dat_bits_cBusy, mb_i_io_tx_dat_bits_cBusy);
        end
        mb_s1_io_tx_dat_bits_cBusy |= mb_g_io_tx_dat_bits_cBusy;
        mb_s0_io_tx_dat_bits_cBusy |= ~mb_g_io_tx_dat_bits_cBusy;
        checks++;
        if (mb_g_io_tx_dat_bits_dbID !== mb_i_io_tx_dat_bits_dbID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_dbID g=%h i=%h", cyc, mb_g_io_tx_dat_bits_dbID, mb_i_io_tx_dat_bits_dbID);
        end
        mb_s1_io_tx_dat_bits_dbID |= mb_g_io_tx_dat_bits_dbID;
        mb_s0_io_tx_dat_bits_dbID |= ~mb_g_io_tx_dat_bits_dbID;
        checks++;
        if (mb_g_io_tx_dat_bits_ccID !== mb_i_io_tx_dat_bits_ccID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_ccID g=%h i=%h", cyc, mb_g_io_tx_dat_bits_ccID, mb_i_io_tx_dat_bits_ccID);
        end
        mb_s1_io_tx_dat_bits_ccID |= mb_g_io_tx_dat_bits_ccID;
        mb_s0_io_tx_dat_bits_ccID |= ~mb_g_io_tx_dat_bits_ccID;
        checks++;
        if (mb_g_io_tx_dat_bits_dataID !== mb_i_io_tx_dat_bits_dataID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_dataID g=%h i=%h", cyc, mb_g_io_tx_dat_bits_dataID, mb_i_io_tx_dat_bits_dataID);
        end
        mb_s1_io_tx_dat_bits_dataID |= mb_g_io_tx_dat_bits_dataID;
        mb_s0_io_tx_dat_bits_dataID |= ~mb_g_io_tx_dat_bits_dataID;
        checks++;
        if (mb_g_io_tx_dat_bits_tagOp !== mb_i_io_tx_dat_bits_tagOp) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_tagOp g=%h i=%h", cyc, mb_g_io_tx_dat_bits_tagOp, mb_i_io_tx_dat_bits_tagOp);
        end
        mb_s1_io_tx_dat_bits_tagOp |= mb_g_io_tx_dat_bits_tagOp;
        mb_s0_io_tx_dat_bits_tagOp |= ~mb_g_io_tx_dat_bits_tagOp;
        checks++;
        if (mb_g_io_tx_dat_bits_tag !== mb_i_io_tx_dat_bits_tag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_tag g=%h i=%h", cyc, mb_g_io_tx_dat_bits_tag, mb_i_io_tx_dat_bits_tag);
        end
        mb_s1_io_tx_dat_bits_tag |= mb_g_io_tx_dat_bits_tag;
        mb_s0_io_tx_dat_bits_tag |= ~mb_g_io_tx_dat_bits_tag;
        checks++;
        if (mb_g_io_tx_dat_bits_tu !== mb_i_io_tx_dat_bits_tu) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_tu g=%h i=%h", cyc, mb_g_io_tx_dat_bits_tu, mb_i_io_tx_dat_bits_tu);
        end
        mb_s1_io_tx_dat_bits_tu |= mb_g_io_tx_dat_bits_tu;
        mb_s0_io_tx_dat_bits_tu |= ~mb_g_io_tx_dat_bits_tu;
        checks++;
        if (mb_g_io_tx_dat_bits_traceTag !== mb_i_io_tx_dat_bits_traceTag) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_traceTag g=%h i=%h", cyc, mb_g_io_tx_dat_bits_traceTag, mb_i_io_tx_dat_bits_traceTag);
        end
        mb_s1_io_tx_dat_bits_traceTag |= mb_g_io_tx_dat_bits_traceTag;
        mb_s0_io_tx_dat_bits_traceTag |= ~mb_g_io_tx_dat_bits_traceTag;
        checks++;
        if (mb_g_io_tx_dat_bits_rsvdc !== mb_i_io_tx_dat_bits_rsvdc) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_rsvdc g=%h i=%h", cyc, mb_g_io_tx_dat_bits_rsvdc, mb_i_io_tx_dat_bits_rsvdc);
        end
        mb_s1_io_tx_dat_bits_rsvdc |= mb_g_io_tx_dat_bits_rsvdc;
        mb_s0_io_tx_dat_bits_rsvdc |= ~mb_g_io_tx_dat_bits_rsvdc;
        checks++;
        if (mb_g_io_tx_dat_bits_be !== mb_i_io_tx_dat_bits_be) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_be g=%h i=%h", cyc, mb_g_io_tx_dat_bits_be, mb_i_io_tx_dat_bits_be);
        end
        mb_s1_io_tx_dat_bits_be |= mb_g_io_tx_dat_bits_be;
        mb_s0_io_tx_dat_bits_be |= ~mb_g_io_tx_dat_bits_be;
        checks++;
        if (mb_g_io_tx_dat_bits_data !== mb_i_io_tx_dat_bits_data) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_data g=%h i=%h", cyc, mb_g_io_tx_dat_bits_data, mb_i_io_tx_dat_bits_data);
        end
        mb_s1_io_tx_dat_bits_data |= mb_g_io_tx_dat_bits_data;
        mb_s0_io_tx_dat_bits_data |= ~mb_g_io_tx_dat_bits_data;
        checks++;
        if (mb_g_io_tx_dat_bits_dataCheck !== mb_i_io_tx_dat_bits_dataCheck) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_dataCheck g=%h i=%h", cyc, mb_g_io_tx_dat_bits_dataCheck, mb_i_io_tx_dat_bits_dataCheck);
        end
        mb_s1_io_tx_dat_bits_dataCheck |= mb_g_io_tx_dat_bits_dataCheck;
        mb_s0_io_tx_dat_bits_dataCheck |= ~mb_g_io_tx_dat_bits_dataCheck;
        checks++;
        if (mb_g_io_tx_dat_bits_poison !== mb_i_io_tx_dat_bits_poison) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_tx_dat_bits_poison g=%h i=%h", cyc, mb_g_io_tx_dat_bits_poison, mb_i_io_tx_dat_bits_poison);
        end
        mb_s1_io_tx_dat_bits_poison |= mb_g_io_tx_dat_bits_poison;
        mb_s0_io_tx_dat_bits_poison |= ~mb_g_io_tx_dat_bits_poison;
        checks++;
        if (mb_g_io_rx_rsp_ready !== mb_i_io_rx_rsp_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_rx_rsp_ready g=%h i=%h", cyc, mb_g_io_rx_rsp_ready, mb_i_io_rx_rsp_ready);
        end
        mb_s1_io_rx_rsp_ready |= mb_g_io_rx_rsp_ready;
        mb_s0_io_rx_rsp_ready |= ~mb_g_io_rx_rsp_ready;
        checks++;
        if (mb_g_io_rx_dat_ready !== mb_i_io_rx_dat_ready) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_rx_dat_ready g=%h i=%h", cyc, mb_g_io_rx_dat_ready, mb_i_io_rx_dat_ready);
        end
        mb_s1_io_rx_dat_ready |= mb_g_io_rx_dat_ready;
        mb_s0_io_rx_dat_ready |= ~mb_g_io_rx_dat_ready;
        checks++;
        if (mb_g_io_pCrd_0_query_valid !== mb_i_io_pCrd_0_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_0_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_0_query_valid, mb_i_io_pCrd_0_query_valid);
        end
        mb_s1_io_pCrd_0_query_valid |= mb_g_io_pCrd_0_query_valid;
        mb_s0_io_pCrd_0_query_valid |= ~mb_g_io_pCrd_0_query_valid;
        checks++;
        if (mb_g_io_pCrd_0_query_bits_pCrdType !== mb_i_io_pCrd_0_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_0_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_0_query_bits_pCrdType, mb_i_io_pCrd_0_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_0_query_bits_pCrdType |= mb_g_io_pCrd_0_query_bits_pCrdType;
        mb_s0_io_pCrd_0_query_bits_pCrdType |= ~mb_g_io_pCrd_0_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_0_query_bits_srcID !== mb_i_io_pCrd_0_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_0_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_0_query_bits_srcID, mb_i_io_pCrd_0_query_bits_srcID);
        end
        mb_s1_io_pCrd_0_query_bits_srcID |= mb_g_io_pCrd_0_query_bits_srcID;
        mb_s0_io_pCrd_0_query_bits_srcID |= ~mb_g_io_pCrd_0_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_1_query_valid !== mb_i_io_pCrd_1_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_1_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_1_query_valid, mb_i_io_pCrd_1_query_valid);
        end
        mb_s1_io_pCrd_1_query_valid |= mb_g_io_pCrd_1_query_valid;
        mb_s0_io_pCrd_1_query_valid |= ~mb_g_io_pCrd_1_query_valid;
        checks++;
        if (mb_g_io_pCrd_1_query_bits_pCrdType !== mb_i_io_pCrd_1_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_1_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_1_query_bits_pCrdType, mb_i_io_pCrd_1_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_1_query_bits_pCrdType |= mb_g_io_pCrd_1_query_bits_pCrdType;
        mb_s0_io_pCrd_1_query_bits_pCrdType |= ~mb_g_io_pCrd_1_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_1_query_bits_srcID !== mb_i_io_pCrd_1_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_1_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_1_query_bits_srcID, mb_i_io_pCrd_1_query_bits_srcID);
        end
        mb_s1_io_pCrd_1_query_bits_srcID |= mb_g_io_pCrd_1_query_bits_srcID;
        mb_s0_io_pCrd_1_query_bits_srcID |= ~mb_g_io_pCrd_1_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_2_query_valid !== mb_i_io_pCrd_2_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_2_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_2_query_valid, mb_i_io_pCrd_2_query_valid);
        end
        mb_s1_io_pCrd_2_query_valid |= mb_g_io_pCrd_2_query_valid;
        mb_s0_io_pCrd_2_query_valid |= ~mb_g_io_pCrd_2_query_valid;
        checks++;
        if (mb_g_io_pCrd_2_query_bits_pCrdType !== mb_i_io_pCrd_2_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_2_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_2_query_bits_pCrdType, mb_i_io_pCrd_2_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_2_query_bits_pCrdType |= mb_g_io_pCrd_2_query_bits_pCrdType;
        mb_s0_io_pCrd_2_query_bits_pCrdType |= ~mb_g_io_pCrd_2_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_2_query_bits_srcID !== mb_i_io_pCrd_2_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_2_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_2_query_bits_srcID, mb_i_io_pCrd_2_query_bits_srcID);
        end
        mb_s1_io_pCrd_2_query_bits_srcID |= mb_g_io_pCrd_2_query_bits_srcID;
        mb_s0_io_pCrd_2_query_bits_srcID |= ~mb_g_io_pCrd_2_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_3_query_valid !== mb_i_io_pCrd_3_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_3_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_3_query_valid, mb_i_io_pCrd_3_query_valid);
        end
        mb_s1_io_pCrd_3_query_valid |= mb_g_io_pCrd_3_query_valid;
        mb_s0_io_pCrd_3_query_valid |= ~mb_g_io_pCrd_3_query_valid;
        checks++;
        if (mb_g_io_pCrd_3_query_bits_pCrdType !== mb_i_io_pCrd_3_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_3_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_3_query_bits_pCrdType, mb_i_io_pCrd_3_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_3_query_bits_pCrdType |= mb_g_io_pCrd_3_query_bits_pCrdType;
        mb_s0_io_pCrd_3_query_bits_pCrdType |= ~mb_g_io_pCrd_3_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_3_query_bits_srcID !== mb_i_io_pCrd_3_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_3_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_3_query_bits_srcID, mb_i_io_pCrd_3_query_bits_srcID);
        end
        mb_s1_io_pCrd_3_query_bits_srcID |= mb_g_io_pCrd_3_query_bits_srcID;
        mb_s0_io_pCrd_3_query_bits_srcID |= ~mb_g_io_pCrd_3_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_4_query_valid !== mb_i_io_pCrd_4_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_4_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_4_query_valid, mb_i_io_pCrd_4_query_valid);
        end
        mb_s1_io_pCrd_4_query_valid |= mb_g_io_pCrd_4_query_valid;
        mb_s0_io_pCrd_4_query_valid |= ~mb_g_io_pCrd_4_query_valid;
        checks++;
        if (mb_g_io_pCrd_4_query_bits_pCrdType !== mb_i_io_pCrd_4_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_4_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_4_query_bits_pCrdType, mb_i_io_pCrd_4_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_4_query_bits_pCrdType |= mb_g_io_pCrd_4_query_bits_pCrdType;
        mb_s0_io_pCrd_4_query_bits_pCrdType |= ~mb_g_io_pCrd_4_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_4_query_bits_srcID !== mb_i_io_pCrd_4_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_4_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_4_query_bits_srcID, mb_i_io_pCrd_4_query_bits_srcID);
        end
        mb_s1_io_pCrd_4_query_bits_srcID |= mb_g_io_pCrd_4_query_bits_srcID;
        mb_s0_io_pCrd_4_query_bits_srcID |= ~mb_g_io_pCrd_4_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_5_query_valid !== mb_i_io_pCrd_5_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_5_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_5_query_valid, mb_i_io_pCrd_5_query_valid);
        end
        mb_s1_io_pCrd_5_query_valid |= mb_g_io_pCrd_5_query_valid;
        mb_s0_io_pCrd_5_query_valid |= ~mb_g_io_pCrd_5_query_valid;
        checks++;
        if (mb_g_io_pCrd_5_query_bits_pCrdType !== mb_i_io_pCrd_5_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_5_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_5_query_bits_pCrdType, mb_i_io_pCrd_5_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_5_query_bits_pCrdType |= mb_g_io_pCrd_5_query_bits_pCrdType;
        mb_s0_io_pCrd_5_query_bits_pCrdType |= ~mb_g_io_pCrd_5_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_5_query_bits_srcID !== mb_i_io_pCrd_5_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_5_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_5_query_bits_srcID, mb_i_io_pCrd_5_query_bits_srcID);
        end
        mb_s1_io_pCrd_5_query_bits_srcID |= mb_g_io_pCrd_5_query_bits_srcID;
        mb_s0_io_pCrd_5_query_bits_srcID |= ~mb_g_io_pCrd_5_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_6_query_valid !== mb_i_io_pCrd_6_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_6_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_6_query_valid, mb_i_io_pCrd_6_query_valid);
        end
        mb_s1_io_pCrd_6_query_valid |= mb_g_io_pCrd_6_query_valid;
        mb_s0_io_pCrd_6_query_valid |= ~mb_g_io_pCrd_6_query_valid;
        checks++;
        if (mb_g_io_pCrd_6_query_bits_pCrdType !== mb_i_io_pCrd_6_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_6_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_6_query_bits_pCrdType, mb_i_io_pCrd_6_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_6_query_bits_pCrdType |= mb_g_io_pCrd_6_query_bits_pCrdType;
        mb_s0_io_pCrd_6_query_bits_pCrdType |= ~mb_g_io_pCrd_6_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_6_query_bits_srcID !== mb_i_io_pCrd_6_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_6_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_6_query_bits_srcID, mb_i_io_pCrd_6_query_bits_srcID);
        end
        mb_s1_io_pCrd_6_query_bits_srcID |= mb_g_io_pCrd_6_query_bits_srcID;
        mb_s0_io_pCrd_6_query_bits_srcID |= ~mb_g_io_pCrd_6_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_7_query_valid !== mb_i_io_pCrd_7_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_7_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_7_query_valid, mb_i_io_pCrd_7_query_valid);
        end
        mb_s1_io_pCrd_7_query_valid |= mb_g_io_pCrd_7_query_valid;
        mb_s0_io_pCrd_7_query_valid |= ~mb_g_io_pCrd_7_query_valid;
        checks++;
        if (mb_g_io_pCrd_7_query_bits_pCrdType !== mb_i_io_pCrd_7_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_7_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_7_query_bits_pCrdType, mb_i_io_pCrd_7_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_7_query_bits_pCrdType |= mb_g_io_pCrd_7_query_bits_pCrdType;
        mb_s0_io_pCrd_7_query_bits_pCrdType |= ~mb_g_io_pCrd_7_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_7_query_bits_srcID !== mb_i_io_pCrd_7_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_7_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_7_query_bits_srcID, mb_i_io_pCrd_7_query_bits_srcID);
        end
        mb_s1_io_pCrd_7_query_bits_srcID |= mb_g_io_pCrd_7_query_bits_srcID;
        mb_s0_io_pCrd_7_query_bits_srcID |= ~mb_g_io_pCrd_7_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_8_query_valid !== mb_i_io_pCrd_8_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_8_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_8_query_valid, mb_i_io_pCrd_8_query_valid);
        end
        mb_s1_io_pCrd_8_query_valid |= mb_g_io_pCrd_8_query_valid;
        mb_s0_io_pCrd_8_query_valid |= ~mb_g_io_pCrd_8_query_valid;
        checks++;
        if (mb_g_io_pCrd_8_query_bits_pCrdType !== mb_i_io_pCrd_8_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_8_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_8_query_bits_pCrdType, mb_i_io_pCrd_8_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_8_query_bits_pCrdType |= mb_g_io_pCrd_8_query_bits_pCrdType;
        mb_s0_io_pCrd_8_query_bits_pCrdType |= ~mb_g_io_pCrd_8_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_8_query_bits_srcID !== mb_i_io_pCrd_8_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_8_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_8_query_bits_srcID, mb_i_io_pCrd_8_query_bits_srcID);
        end
        mb_s1_io_pCrd_8_query_bits_srcID |= mb_g_io_pCrd_8_query_bits_srcID;
        mb_s0_io_pCrd_8_query_bits_srcID |= ~mb_g_io_pCrd_8_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_9_query_valid !== mb_i_io_pCrd_9_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_9_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_9_query_valid, mb_i_io_pCrd_9_query_valid);
        end
        mb_s1_io_pCrd_9_query_valid |= mb_g_io_pCrd_9_query_valid;
        mb_s0_io_pCrd_9_query_valid |= ~mb_g_io_pCrd_9_query_valid;
        checks++;
        if (mb_g_io_pCrd_9_query_bits_pCrdType !== mb_i_io_pCrd_9_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_9_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_9_query_bits_pCrdType, mb_i_io_pCrd_9_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_9_query_bits_pCrdType |= mb_g_io_pCrd_9_query_bits_pCrdType;
        mb_s0_io_pCrd_9_query_bits_pCrdType |= ~mb_g_io_pCrd_9_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_9_query_bits_srcID !== mb_i_io_pCrd_9_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_9_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_9_query_bits_srcID, mb_i_io_pCrd_9_query_bits_srcID);
        end
        mb_s1_io_pCrd_9_query_bits_srcID |= mb_g_io_pCrd_9_query_bits_srcID;
        mb_s0_io_pCrd_9_query_bits_srcID |= ~mb_g_io_pCrd_9_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_10_query_valid !== mb_i_io_pCrd_10_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_10_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_10_query_valid, mb_i_io_pCrd_10_query_valid);
        end
        mb_s1_io_pCrd_10_query_valid |= mb_g_io_pCrd_10_query_valid;
        mb_s0_io_pCrd_10_query_valid |= ~mb_g_io_pCrd_10_query_valid;
        checks++;
        if (mb_g_io_pCrd_10_query_bits_pCrdType !== mb_i_io_pCrd_10_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_10_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_10_query_bits_pCrdType, mb_i_io_pCrd_10_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_10_query_bits_pCrdType |= mb_g_io_pCrd_10_query_bits_pCrdType;
        mb_s0_io_pCrd_10_query_bits_pCrdType |= ~mb_g_io_pCrd_10_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_10_query_bits_srcID !== mb_i_io_pCrd_10_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_10_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_10_query_bits_srcID, mb_i_io_pCrd_10_query_bits_srcID);
        end
        mb_s1_io_pCrd_10_query_bits_srcID |= mb_g_io_pCrd_10_query_bits_srcID;
        mb_s0_io_pCrd_10_query_bits_srcID |= ~mb_g_io_pCrd_10_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_11_query_valid !== mb_i_io_pCrd_11_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_11_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_11_query_valid, mb_i_io_pCrd_11_query_valid);
        end
        mb_s1_io_pCrd_11_query_valid |= mb_g_io_pCrd_11_query_valid;
        mb_s0_io_pCrd_11_query_valid |= ~mb_g_io_pCrd_11_query_valid;
        checks++;
        if (mb_g_io_pCrd_11_query_bits_pCrdType !== mb_i_io_pCrd_11_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_11_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_11_query_bits_pCrdType, mb_i_io_pCrd_11_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_11_query_bits_pCrdType |= mb_g_io_pCrd_11_query_bits_pCrdType;
        mb_s0_io_pCrd_11_query_bits_pCrdType |= ~mb_g_io_pCrd_11_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_11_query_bits_srcID !== mb_i_io_pCrd_11_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_11_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_11_query_bits_srcID, mb_i_io_pCrd_11_query_bits_srcID);
        end
        mb_s1_io_pCrd_11_query_bits_srcID |= mb_g_io_pCrd_11_query_bits_srcID;
        mb_s0_io_pCrd_11_query_bits_srcID |= ~mb_g_io_pCrd_11_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_12_query_valid !== mb_i_io_pCrd_12_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_12_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_12_query_valid, mb_i_io_pCrd_12_query_valid);
        end
        mb_s1_io_pCrd_12_query_valid |= mb_g_io_pCrd_12_query_valid;
        mb_s0_io_pCrd_12_query_valid |= ~mb_g_io_pCrd_12_query_valid;
        checks++;
        if (mb_g_io_pCrd_12_query_bits_pCrdType !== mb_i_io_pCrd_12_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_12_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_12_query_bits_pCrdType, mb_i_io_pCrd_12_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_12_query_bits_pCrdType |= mb_g_io_pCrd_12_query_bits_pCrdType;
        mb_s0_io_pCrd_12_query_bits_pCrdType |= ~mb_g_io_pCrd_12_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_12_query_bits_srcID !== mb_i_io_pCrd_12_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_12_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_12_query_bits_srcID, mb_i_io_pCrd_12_query_bits_srcID);
        end
        mb_s1_io_pCrd_12_query_bits_srcID |= mb_g_io_pCrd_12_query_bits_srcID;
        mb_s0_io_pCrd_12_query_bits_srcID |= ~mb_g_io_pCrd_12_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_13_query_valid !== mb_i_io_pCrd_13_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_13_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_13_query_valid, mb_i_io_pCrd_13_query_valid);
        end
        mb_s1_io_pCrd_13_query_valid |= mb_g_io_pCrd_13_query_valid;
        mb_s0_io_pCrd_13_query_valid |= ~mb_g_io_pCrd_13_query_valid;
        checks++;
        if (mb_g_io_pCrd_13_query_bits_pCrdType !== mb_i_io_pCrd_13_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_13_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_13_query_bits_pCrdType, mb_i_io_pCrd_13_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_13_query_bits_pCrdType |= mb_g_io_pCrd_13_query_bits_pCrdType;
        mb_s0_io_pCrd_13_query_bits_pCrdType |= ~mb_g_io_pCrd_13_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_13_query_bits_srcID !== mb_i_io_pCrd_13_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_13_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_13_query_bits_srcID, mb_i_io_pCrd_13_query_bits_srcID);
        end
        mb_s1_io_pCrd_13_query_bits_srcID |= mb_g_io_pCrd_13_query_bits_srcID;
        mb_s0_io_pCrd_13_query_bits_srcID |= ~mb_g_io_pCrd_13_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_14_query_valid !== mb_i_io_pCrd_14_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_14_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_14_query_valid, mb_i_io_pCrd_14_query_valid);
        end
        mb_s1_io_pCrd_14_query_valid |= mb_g_io_pCrd_14_query_valid;
        mb_s0_io_pCrd_14_query_valid |= ~mb_g_io_pCrd_14_query_valid;
        checks++;
        if (mb_g_io_pCrd_14_query_bits_pCrdType !== mb_i_io_pCrd_14_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_14_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_14_query_bits_pCrdType, mb_i_io_pCrd_14_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_14_query_bits_pCrdType |= mb_g_io_pCrd_14_query_bits_pCrdType;
        mb_s0_io_pCrd_14_query_bits_pCrdType |= ~mb_g_io_pCrd_14_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_14_query_bits_srcID !== mb_i_io_pCrd_14_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_14_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_14_query_bits_srcID, mb_i_io_pCrd_14_query_bits_srcID);
        end
        mb_s1_io_pCrd_14_query_bits_srcID |= mb_g_io_pCrd_14_query_bits_srcID;
        mb_s0_io_pCrd_14_query_bits_srcID |= ~mb_g_io_pCrd_14_query_bits_srcID;
        checks++;
        if (mb_g_io_pCrd_15_query_valid !== mb_i_io_pCrd_15_query_valid) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_15_query_valid g=%h i=%h", cyc, mb_g_io_pCrd_15_query_valid, mb_i_io_pCrd_15_query_valid);
        end
        mb_s1_io_pCrd_15_query_valid |= mb_g_io_pCrd_15_query_valid;
        mb_s0_io_pCrd_15_query_valid |= ~mb_g_io_pCrd_15_query_valid;
        checks++;
        if (mb_g_io_pCrd_15_query_bits_pCrdType !== mb_i_io_pCrd_15_query_bits_pCrdType) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_15_query_bits_pCrdType g=%h i=%h", cyc, mb_g_io_pCrd_15_query_bits_pCrdType, mb_i_io_pCrd_15_query_bits_pCrdType);
        end
        mb_s1_io_pCrd_15_query_bits_pCrdType |= mb_g_io_pCrd_15_query_bits_pCrdType;
        mb_s0_io_pCrd_15_query_bits_pCrdType |= ~mb_g_io_pCrd_15_query_bits_pCrdType;
        checks++;
        if (mb_g_io_pCrd_15_query_bits_srcID !== mb_i_io_pCrd_15_query_bits_srcID) begin
          errors++;
          if (errors <= 20) $display("[MISMATCH] cyc=%0d MMIOBridge.io_pCrd_15_query_bits_srcID g=%h i=%h", cyc, mb_g_io_pCrd_15_query_bits_srcID, mb_i_io_pCrd_15_query_bits_srcID);
        end
        mb_s1_io_pCrd_15_query_bits_srcID |= mb_g_io_pCrd_15_query_bits_srcID;
        mb_s0_io_pCrd_15_query_bits_srcID |= ~mb_g_io_pCrd_15_query_bits_srcID;
        if (mb_auto_mmio_in_a_valid && mb_g_auto_mmio_in_a_ready) mb_cov_a_fire++;
        if (mb_auto_mmio_in_a_valid && !mb_g_auto_mmio_in_a_ready) mb_cov_a_full++;
        if (mb_u_gold._entries_15_io_resp_valid) mb_cov_slot15_used++;
        if (mb_g_auto_mmio_in_d_valid && mb_auto_mmio_in_d_ready && mb_g_auto_mmio_in_d_bits_opcode == 4'h1) mb_cov_d_read++;
        if (mb_g_auto_mmio_in_d_valid && mb_auto_mmio_in_d_ready && mb_g_auto_mmio_in_d_bits_opcode == 4'h0) mb_cov_d_write++;
        if (mb_g_io_tx_req_valid && mb_io_tx_req_ready) mb_cov_txreq_fire++;
        if (mb_g_io_tx_dat_valid && mb_io_tx_dat_ready) mb_cov_txdat_fire++;
        if (mb_u_gold.block | mb_u_gold.block_7 | mb_u_gold.block_15) mb_cov_read_blocked++;
        if (|mb_u_gold._waitOnReadReceipt_T) mb_cov_wait_rr++;
        if (mb_io_rx_dat_valid && mb_g_io_rx_dat_ready) mb_cov_rxdat_ready++;
        if (mb_io_rx_dat_valid && !mb_g_io_rx_dat_ready) mb_cov_rxdat_miss++;
        if (mb_g_io_pCrd_9_query_valid) mb_cov_pcrd_query++;
      end
      if (mb_armed_at < 0 && (&mb_armed)) mb_armed_at = cyc + 1;
    end

    // ---- 覆盖闸 ----
    if (!(mb_s0_auto_mmio_in_a_ready && mb_s1_auto_mmio_in_a_ready)) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_a_ready 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_valid && mb_s1_auto_mmio_in_d_valid)) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_valid 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_opcode[0] && mb_s1_auto_mmio_in_d_bits_opcode[0])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_opcode[0] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_size[0] && mb_s1_auto_mmio_in_d_bits_size[0])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_size[0] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_size[1] && mb_s1_auto_mmio_in_d_bits_size[1])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_size[1] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_source[0] && mb_s1_auto_mmio_in_d_bits_source[0])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_source[0] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_source[1] && mb_s1_auto_mmio_in_d_bits_source[1])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_source[1] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_source[2] && mb_s1_auto_mmio_in_d_bits_source[2])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_source[2] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_source[3] && mb_s1_auto_mmio_in_d_bits_source[3])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_source[3] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_source[4] && mb_s1_auto_mmio_in_d_bits_source[4])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_source[4] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_denied && mb_s1_auto_mmio_in_d_bits_denied)) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_denied 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[0] && mb_s1_auto_mmio_in_d_bits_data[0])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[0] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[1] && mb_s1_auto_mmio_in_d_bits_data[1])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[1] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[2] && mb_s1_auto_mmio_in_d_bits_data[2])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[2] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[3] && mb_s1_auto_mmio_in_d_bits_data[3])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[3] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[4] && mb_s1_auto_mmio_in_d_bits_data[4])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[4] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[5] && mb_s1_auto_mmio_in_d_bits_data[5])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[5] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[6] && mb_s1_auto_mmio_in_d_bits_data[6])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[6] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[7] && mb_s1_auto_mmio_in_d_bits_data[7])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[7] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[8] && mb_s1_auto_mmio_in_d_bits_data[8])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[8] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[9] && mb_s1_auto_mmio_in_d_bits_data[9])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[9] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[10] && mb_s1_auto_mmio_in_d_bits_data[10])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[10] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[11] && mb_s1_auto_mmio_in_d_bits_data[11])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[11] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[12] && mb_s1_auto_mmio_in_d_bits_data[12])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[12] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[13] && mb_s1_auto_mmio_in_d_bits_data[13])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[13] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[14] && mb_s1_auto_mmio_in_d_bits_data[14])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[14] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[15] && mb_s1_auto_mmio_in_d_bits_data[15])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[15] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[16] && mb_s1_auto_mmio_in_d_bits_data[16])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[16] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[17] && mb_s1_auto_mmio_in_d_bits_data[17])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[17] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[18] && mb_s1_auto_mmio_in_d_bits_data[18])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[18] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[19] && mb_s1_auto_mmio_in_d_bits_data[19])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[19] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[20] && mb_s1_auto_mmio_in_d_bits_data[20])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[20] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[21] && mb_s1_auto_mmio_in_d_bits_data[21])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[21] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[22] && mb_s1_auto_mmio_in_d_bits_data[22])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[22] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[23] && mb_s1_auto_mmio_in_d_bits_data[23])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[23] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[24] && mb_s1_auto_mmio_in_d_bits_data[24])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[24] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[25] && mb_s1_auto_mmio_in_d_bits_data[25])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[25] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[26] && mb_s1_auto_mmio_in_d_bits_data[26])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[26] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[27] && mb_s1_auto_mmio_in_d_bits_data[27])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[27] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[28] && mb_s1_auto_mmio_in_d_bits_data[28])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[28] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[29] && mb_s1_auto_mmio_in_d_bits_data[29])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[29] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[30] && mb_s1_auto_mmio_in_d_bits_data[30])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[30] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[31] && mb_s1_auto_mmio_in_d_bits_data[31])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[31] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[32] && mb_s1_auto_mmio_in_d_bits_data[32])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[32] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[33] && mb_s1_auto_mmio_in_d_bits_data[33])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[33] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[34] && mb_s1_auto_mmio_in_d_bits_data[34])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[34] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[35] && mb_s1_auto_mmio_in_d_bits_data[35])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[35] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[36] && mb_s1_auto_mmio_in_d_bits_data[36])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[36] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[37] && mb_s1_auto_mmio_in_d_bits_data[37])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[37] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[38] && mb_s1_auto_mmio_in_d_bits_data[38])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[38] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[39] && mb_s1_auto_mmio_in_d_bits_data[39])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[39] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[40] && mb_s1_auto_mmio_in_d_bits_data[40])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[40] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[41] && mb_s1_auto_mmio_in_d_bits_data[41])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[41] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[42] && mb_s1_auto_mmio_in_d_bits_data[42])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[42] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[43] && mb_s1_auto_mmio_in_d_bits_data[43])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[43] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[44] && mb_s1_auto_mmio_in_d_bits_data[44])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[44] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[45] && mb_s1_auto_mmio_in_d_bits_data[45])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[45] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[46] && mb_s1_auto_mmio_in_d_bits_data[46])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[46] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[47] && mb_s1_auto_mmio_in_d_bits_data[47])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[47] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[48] && mb_s1_auto_mmio_in_d_bits_data[48])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[48] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[49] && mb_s1_auto_mmio_in_d_bits_data[49])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[49] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[50] && mb_s1_auto_mmio_in_d_bits_data[50])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[50] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[51] && mb_s1_auto_mmio_in_d_bits_data[51])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[51] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[52] && mb_s1_auto_mmio_in_d_bits_data[52])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[52] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[53] && mb_s1_auto_mmio_in_d_bits_data[53])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[53] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[54] && mb_s1_auto_mmio_in_d_bits_data[54])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[54] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[55] && mb_s1_auto_mmio_in_d_bits_data[55])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[55] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[56] && mb_s1_auto_mmio_in_d_bits_data[56])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[56] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[57] && mb_s1_auto_mmio_in_d_bits_data[57])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[57] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[58] && mb_s1_auto_mmio_in_d_bits_data[58])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[58] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[59] && mb_s1_auto_mmio_in_d_bits_data[59])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[59] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[60] && mb_s1_auto_mmio_in_d_bits_data[60])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[60] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[61] && mb_s1_auto_mmio_in_d_bits_data[61])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[61] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[62] && mb_s1_auto_mmio_in_d_bits_data[62])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[62] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_data[63] && mb_s1_auto_mmio_in_d_bits_data[63])) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_data[63] 未见过 0 和 1"); end
    if (!(mb_s0_auto_mmio_in_d_bits_corrupt && mb_s1_auto_mmio_in_d_bits_corrupt)) begin cov_fail++; $display("[COV] MMIOBridge.auto_mmio_in_d_bits_corrupt 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_valid && mb_s1_io_tx_req_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_txnID[0] && mb_s1_io_tx_req_bits_txnID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_txnID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_txnID[1] && mb_s1_io_tx_req_bits_txnID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_txnID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_txnID[2] && mb_s1_io_tx_req_bits_txnID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_txnID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_txnID[3] && mb_s1_io_tx_req_bits_txnID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_txnID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_opcode[2] && mb_s1_io_tx_req_bits_opcode[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_opcode[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_opcode[3] && mb_s1_io_tx_req_bits_opcode[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_opcode[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_opcode[4] && mb_s1_io_tx_req_bits_opcode[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_opcode[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_size[0] && mb_s1_io_tx_req_bits_size[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_size[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_size[1] && mb_s1_io_tx_req_bits_size[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_size[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[0] && mb_s1_io_tx_req_bits_addr[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[1] && mb_s1_io_tx_req_bits_addr[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[2] && mb_s1_io_tx_req_bits_addr[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[3] && mb_s1_io_tx_req_bits_addr[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[4] && mb_s1_io_tx_req_bits_addr[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[5] && mb_s1_io_tx_req_bits_addr[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[6] && mb_s1_io_tx_req_bits_addr[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[7] && mb_s1_io_tx_req_bits_addr[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[8] && mb_s1_io_tx_req_bits_addr[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[9] && mb_s1_io_tx_req_bits_addr[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[10] && mb_s1_io_tx_req_bits_addr[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[11] && mb_s1_io_tx_req_bits_addr[11])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[11] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[12] && mb_s1_io_tx_req_bits_addr[12])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[12] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[13] && mb_s1_io_tx_req_bits_addr[13])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[13] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[14] && mb_s1_io_tx_req_bits_addr[14])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[14] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[15] && mb_s1_io_tx_req_bits_addr[15])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[15] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[16] && mb_s1_io_tx_req_bits_addr[16])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[16] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[17] && mb_s1_io_tx_req_bits_addr[17])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[17] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[18] && mb_s1_io_tx_req_bits_addr[18])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[18] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[19] && mb_s1_io_tx_req_bits_addr[19])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[19] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[20] && mb_s1_io_tx_req_bits_addr[20])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[20] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[21] && mb_s1_io_tx_req_bits_addr[21])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[21] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[22] && mb_s1_io_tx_req_bits_addr[22])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[22] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[23] && mb_s1_io_tx_req_bits_addr[23])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[23] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[24] && mb_s1_io_tx_req_bits_addr[24])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[24] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[25] && mb_s1_io_tx_req_bits_addr[25])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[25] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[26] && mb_s1_io_tx_req_bits_addr[26])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[26] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[27] && mb_s1_io_tx_req_bits_addr[27])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[27] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[28] && mb_s1_io_tx_req_bits_addr[28])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[28] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[29] && mb_s1_io_tx_req_bits_addr[29])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[29] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[30] && mb_s1_io_tx_req_bits_addr[30])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[30] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[31] && mb_s1_io_tx_req_bits_addr[31])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[31] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[32] && mb_s1_io_tx_req_bits_addr[32])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[32] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[33] && mb_s1_io_tx_req_bits_addr[33])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[33] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[34] && mb_s1_io_tx_req_bits_addr[34])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[34] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[35] && mb_s1_io_tx_req_bits_addr[35])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[35] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[36] && mb_s1_io_tx_req_bits_addr[36])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[36] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[37] && mb_s1_io_tx_req_bits_addr[37])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[37] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[38] && mb_s1_io_tx_req_bits_addr[38])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[38] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[39] && mb_s1_io_tx_req_bits_addr[39])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[39] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[40] && mb_s1_io_tx_req_bits_addr[40])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[40] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[41] && mb_s1_io_tx_req_bits_addr[41])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[41] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[42] && mb_s1_io_tx_req_bits_addr[42])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[42] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[43] && mb_s1_io_tx_req_bits_addr[43])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[43] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[44] && mb_s1_io_tx_req_bits_addr[44])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[44] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[45] && mb_s1_io_tx_req_bits_addr[45])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[45] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[46] && mb_s1_io_tx_req_bits_addr[46])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[46] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_addr[47] && mb_s1_io_tx_req_bits_addr[47])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_addr[47] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_allowRetry && mb_s1_io_tx_req_bits_allowRetry)) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_allowRetry 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_order[0] && mb_s1_io_tx_req_bits_order[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_order[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_pCrdType[0] && mb_s1_io_tx_req_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_pCrdType[1] && mb_s1_io_tx_req_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_pCrdType[2] && mb_s1_io_tx_req_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_pCrdType[3] && mb_s1_io_tx_req_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_memAttr_device && mb_s1_io_tx_req_bits_memAttr_device)) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_memAttr_device 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_req_bits_memAttr_ewa && mb_s1_io_tx_req_bits_memAttr_ewa)) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_req_bits_memAttr_ewa 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_valid && mb_s1_io_tx_dat_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[0] && mb_s1_io_tx_dat_bits_tgtID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[1] && mb_s1_io_tx_dat_bits_tgtID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[2] && mb_s1_io_tx_dat_bits_tgtID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[3] && mb_s1_io_tx_dat_bits_tgtID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[4] && mb_s1_io_tx_dat_bits_tgtID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[5] && mb_s1_io_tx_dat_bits_tgtID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[6] && mb_s1_io_tx_dat_bits_tgtID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[7] && mb_s1_io_tx_dat_bits_tgtID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[8] && mb_s1_io_tx_dat_bits_tgtID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[9] && mb_s1_io_tx_dat_bits_tgtID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_tgtID[10] && mb_s1_io_tx_dat_bits_tgtID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_tgtID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[0] && mb_s1_io_tx_dat_bits_txnID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[1] && mb_s1_io_tx_dat_bits_txnID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[2] && mb_s1_io_tx_dat_bits_txnID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[3] && mb_s1_io_tx_dat_bits_txnID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[4] && mb_s1_io_tx_dat_bits_txnID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[5] && mb_s1_io_tx_dat_bits_txnID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[6] && mb_s1_io_tx_dat_bits_txnID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[7] && mb_s1_io_tx_dat_bits_txnID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[8] && mb_s1_io_tx_dat_bits_txnID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[9] && mb_s1_io_tx_dat_bits_txnID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[10] && mb_s1_io_tx_dat_bits_txnID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_txnID[11] && mb_s1_io_tx_dat_bits_txnID[11])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_txnID[11] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_respErr[1] && mb_s1_io_tx_dat_bits_respErr[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_respErr[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_ccID[0] && mb_s1_io_tx_dat_bits_ccID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_ccID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_ccID[1] && mb_s1_io_tx_dat_bits_ccID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_ccID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataID[1] && mb_s1_io_tx_dat_bits_dataID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_traceTag && mb_s1_io_tx_dat_bits_traceTag)) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_traceTag 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[0] && mb_s1_io_tx_dat_bits_be[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[1] && mb_s1_io_tx_dat_bits_be[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[2] && mb_s1_io_tx_dat_bits_be[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[3] && mb_s1_io_tx_dat_bits_be[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[4] && mb_s1_io_tx_dat_bits_be[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[5] && mb_s1_io_tx_dat_bits_be[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[6] && mb_s1_io_tx_dat_bits_be[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[7] && mb_s1_io_tx_dat_bits_be[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[8] && mb_s1_io_tx_dat_bits_be[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[9] && mb_s1_io_tx_dat_bits_be[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[10] && mb_s1_io_tx_dat_bits_be[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[11] && mb_s1_io_tx_dat_bits_be[11])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[11] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[12] && mb_s1_io_tx_dat_bits_be[12])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[12] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[13] && mb_s1_io_tx_dat_bits_be[13])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[13] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[14] && mb_s1_io_tx_dat_bits_be[14])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[14] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[15] && mb_s1_io_tx_dat_bits_be[15])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[15] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[16] && mb_s1_io_tx_dat_bits_be[16])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[16] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[17] && mb_s1_io_tx_dat_bits_be[17])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[17] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[18] && mb_s1_io_tx_dat_bits_be[18])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[18] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[19] && mb_s1_io_tx_dat_bits_be[19])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[19] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[20] && mb_s1_io_tx_dat_bits_be[20])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[20] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[21] && mb_s1_io_tx_dat_bits_be[21])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[21] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[22] && mb_s1_io_tx_dat_bits_be[22])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[22] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[23] && mb_s1_io_tx_dat_bits_be[23])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[23] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[24] && mb_s1_io_tx_dat_bits_be[24])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[24] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[25] && mb_s1_io_tx_dat_bits_be[25])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[25] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[26] && mb_s1_io_tx_dat_bits_be[26])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[26] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[27] && mb_s1_io_tx_dat_bits_be[27])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[27] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[28] && mb_s1_io_tx_dat_bits_be[28])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[28] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[29] && mb_s1_io_tx_dat_bits_be[29])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[29] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[30] && mb_s1_io_tx_dat_bits_be[30])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[30] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_be[31] && mb_s1_io_tx_dat_bits_be[31])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_be[31] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[0] && mb_s1_io_tx_dat_bits_data[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[1] && mb_s1_io_tx_dat_bits_data[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[2] && mb_s1_io_tx_dat_bits_data[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[3] && mb_s1_io_tx_dat_bits_data[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[4] && mb_s1_io_tx_dat_bits_data[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[5] && mb_s1_io_tx_dat_bits_data[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[6] && mb_s1_io_tx_dat_bits_data[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[7] && mb_s1_io_tx_dat_bits_data[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[8] && mb_s1_io_tx_dat_bits_data[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[9] && mb_s1_io_tx_dat_bits_data[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[10] && mb_s1_io_tx_dat_bits_data[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[11] && mb_s1_io_tx_dat_bits_data[11])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[11] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[12] && mb_s1_io_tx_dat_bits_data[12])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[12] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[13] && mb_s1_io_tx_dat_bits_data[13])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[13] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[14] && mb_s1_io_tx_dat_bits_data[14])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[14] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[15] && mb_s1_io_tx_dat_bits_data[15])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[15] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[16] && mb_s1_io_tx_dat_bits_data[16])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[16] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[17] && mb_s1_io_tx_dat_bits_data[17])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[17] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[18] && mb_s1_io_tx_dat_bits_data[18])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[18] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[19] && mb_s1_io_tx_dat_bits_data[19])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[19] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[20] && mb_s1_io_tx_dat_bits_data[20])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[20] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[21] && mb_s1_io_tx_dat_bits_data[21])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[21] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[22] && mb_s1_io_tx_dat_bits_data[22])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[22] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[23] && mb_s1_io_tx_dat_bits_data[23])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[23] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[24] && mb_s1_io_tx_dat_bits_data[24])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[24] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[25] && mb_s1_io_tx_dat_bits_data[25])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[25] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[26] && mb_s1_io_tx_dat_bits_data[26])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[26] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[27] && mb_s1_io_tx_dat_bits_data[27])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[27] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[28] && mb_s1_io_tx_dat_bits_data[28])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[28] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[29] && mb_s1_io_tx_dat_bits_data[29])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[29] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[30] && mb_s1_io_tx_dat_bits_data[30])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[30] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[31] && mb_s1_io_tx_dat_bits_data[31])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[31] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[32] && mb_s1_io_tx_dat_bits_data[32])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[32] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[33] && mb_s1_io_tx_dat_bits_data[33])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[33] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[34] && mb_s1_io_tx_dat_bits_data[34])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[34] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[35] && mb_s1_io_tx_dat_bits_data[35])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[35] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[36] && mb_s1_io_tx_dat_bits_data[36])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[36] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[37] && mb_s1_io_tx_dat_bits_data[37])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[37] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[38] && mb_s1_io_tx_dat_bits_data[38])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[38] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[39] && mb_s1_io_tx_dat_bits_data[39])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[39] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[40] && mb_s1_io_tx_dat_bits_data[40])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[40] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[41] && mb_s1_io_tx_dat_bits_data[41])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[41] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[42] && mb_s1_io_tx_dat_bits_data[42])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[42] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[43] && mb_s1_io_tx_dat_bits_data[43])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[43] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[44] && mb_s1_io_tx_dat_bits_data[44])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[44] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[45] && mb_s1_io_tx_dat_bits_data[45])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[45] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[46] && mb_s1_io_tx_dat_bits_data[46])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[46] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[47] && mb_s1_io_tx_dat_bits_data[47])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[47] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[48] && mb_s1_io_tx_dat_bits_data[48])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[48] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[49] && mb_s1_io_tx_dat_bits_data[49])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[49] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[50] && mb_s1_io_tx_dat_bits_data[50])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[50] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[51] && mb_s1_io_tx_dat_bits_data[51])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[51] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[52] && mb_s1_io_tx_dat_bits_data[52])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[52] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[53] && mb_s1_io_tx_dat_bits_data[53])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[53] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[54] && mb_s1_io_tx_dat_bits_data[54])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[54] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[55] && mb_s1_io_tx_dat_bits_data[55])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[55] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[56] && mb_s1_io_tx_dat_bits_data[56])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[56] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[57] && mb_s1_io_tx_dat_bits_data[57])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[57] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[58] && mb_s1_io_tx_dat_bits_data[58])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[58] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[59] && mb_s1_io_tx_dat_bits_data[59])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[59] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[60] && mb_s1_io_tx_dat_bits_data[60])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[60] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[61] && mb_s1_io_tx_dat_bits_data[61])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[61] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[62] && mb_s1_io_tx_dat_bits_data[62])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[62] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[63] && mb_s1_io_tx_dat_bits_data[63])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[63] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[64] && mb_s1_io_tx_dat_bits_data[64])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[64] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[65] && mb_s1_io_tx_dat_bits_data[65])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[65] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[66] && mb_s1_io_tx_dat_bits_data[66])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[66] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[67] && mb_s1_io_tx_dat_bits_data[67])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[67] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[68] && mb_s1_io_tx_dat_bits_data[68])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[68] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[69] && mb_s1_io_tx_dat_bits_data[69])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[69] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[70] && mb_s1_io_tx_dat_bits_data[70])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[70] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[71] && mb_s1_io_tx_dat_bits_data[71])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[71] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[72] && mb_s1_io_tx_dat_bits_data[72])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[72] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[73] && mb_s1_io_tx_dat_bits_data[73])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[73] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[74] && mb_s1_io_tx_dat_bits_data[74])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[74] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[75] && mb_s1_io_tx_dat_bits_data[75])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[75] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[76] && mb_s1_io_tx_dat_bits_data[76])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[76] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[77] && mb_s1_io_tx_dat_bits_data[77])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[77] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[78] && mb_s1_io_tx_dat_bits_data[78])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[78] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[79] && mb_s1_io_tx_dat_bits_data[79])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[79] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[80] && mb_s1_io_tx_dat_bits_data[80])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[80] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[81] && mb_s1_io_tx_dat_bits_data[81])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[81] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[82] && mb_s1_io_tx_dat_bits_data[82])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[82] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[83] && mb_s1_io_tx_dat_bits_data[83])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[83] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[84] && mb_s1_io_tx_dat_bits_data[84])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[84] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[85] && mb_s1_io_tx_dat_bits_data[85])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[85] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[86] && mb_s1_io_tx_dat_bits_data[86])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[86] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[87] && mb_s1_io_tx_dat_bits_data[87])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[87] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[88] && mb_s1_io_tx_dat_bits_data[88])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[88] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[89] && mb_s1_io_tx_dat_bits_data[89])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[89] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[90] && mb_s1_io_tx_dat_bits_data[90])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[90] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[91] && mb_s1_io_tx_dat_bits_data[91])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[91] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[92] && mb_s1_io_tx_dat_bits_data[92])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[92] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[93] && mb_s1_io_tx_dat_bits_data[93])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[93] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[94] && mb_s1_io_tx_dat_bits_data[94])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[94] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[95] && mb_s1_io_tx_dat_bits_data[95])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[95] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[96] && mb_s1_io_tx_dat_bits_data[96])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[96] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[97] && mb_s1_io_tx_dat_bits_data[97])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[97] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[98] && mb_s1_io_tx_dat_bits_data[98])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[98] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[99] && mb_s1_io_tx_dat_bits_data[99])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[99] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[100] && mb_s1_io_tx_dat_bits_data[100])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[100] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[101] && mb_s1_io_tx_dat_bits_data[101])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[101] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[102] && mb_s1_io_tx_dat_bits_data[102])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[102] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[103] && mb_s1_io_tx_dat_bits_data[103])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[103] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[104] && mb_s1_io_tx_dat_bits_data[104])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[104] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[105] && mb_s1_io_tx_dat_bits_data[105])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[105] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[106] && mb_s1_io_tx_dat_bits_data[106])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[106] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[107] && mb_s1_io_tx_dat_bits_data[107])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[107] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[108] && mb_s1_io_tx_dat_bits_data[108])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[108] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[109] && mb_s1_io_tx_dat_bits_data[109])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[109] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[110] && mb_s1_io_tx_dat_bits_data[110])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[110] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[111] && mb_s1_io_tx_dat_bits_data[111])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[111] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[112] && mb_s1_io_tx_dat_bits_data[112])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[112] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[113] && mb_s1_io_tx_dat_bits_data[113])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[113] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[114] && mb_s1_io_tx_dat_bits_data[114])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[114] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[115] && mb_s1_io_tx_dat_bits_data[115])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[115] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[116] && mb_s1_io_tx_dat_bits_data[116])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[116] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[117] && mb_s1_io_tx_dat_bits_data[117])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[117] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[118] && mb_s1_io_tx_dat_bits_data[118])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[118] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[119] && mb_s1_io_tx_dat_bits_data[119])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[119] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[120] && mb_s1_io_tx_dat_bits_data[120])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[120] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[121] && mb_s1_io_tx_dat_bits_data[121])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[121] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[122] && mb_s1_io_tx_dat_bits_data[122])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[122] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[123] && mb_s1_io_tx_dat_bits_data[123])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[123] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[124] && mb_s1_io_tx_dat_bits_data[124])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[124] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[125] && mb_s1_io_tx_dat_bits_data[125])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[125] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[126] && mb_s1_io_tx_dat_bits_data[126])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[126] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[127] && mb_s1_io_tx_dat_bits_data[127])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[127] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[128] && mb_s1_io_tx_dat_bits_data[128])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[128] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[129] && mb_s1_io_tx_dat_bits_data[129])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[129] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[130] && mb_s1_io_tx_dat_bits_data[130])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[130] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[131] && mb_s1_io_tx_dat_bits_data[131])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[131] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[132] && mb_s1_io_tx_dat_bits_data[132])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[132] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[133] && mb_s1_io_tx_dat_bits_data[133])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[133] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[134] && mb_s1_io_tx_dat_bits_data[134])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[134] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[135] && mb_s1_io_tx_dat_bits_data[135])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[135] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[136] && mb_s1_io_tx_dat_bits_data[136])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[136] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[137] && mb_s1_io_tx_dat_bits_data[137])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[137] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[138] && mb_s1_io_tx_dat_bits_data[138])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[138] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[139] && mb_s1_io_tx_dat_bits_data[139])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[139] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[140] && mb_s1_io_tx_dat_bits_data[140])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[140] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[141] && mb_s1_io_tx_dat_bits_data[141])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[141] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[142] && mb_s1_io_tx_dat_bits_data[142])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[142] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[143] && mb_s1_io_tx_dat_bits_data[143])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[143] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[144] && mb_s1_io_tx_dat_bits_data[144])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[144] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[145] && mb_s1_io_tx_dat_bits_data[145])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[145] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[146] && mb_s1_io_tx_dat_bits_data[146])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[146] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[147] && mb_s1_io_tx_dat_bits_data[147])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[147] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[148] && mb_s1_io_tx_dat_bits_data[148])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[148] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[149] && mb_s1_io_tx_dat_bits_data[149])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[149] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[150] && mb_s1_io_tx_dat_bits_data[150])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[150] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[151] && mb_s1_io_tx_dat_bits_data[151])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[151] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[152] && mb_s1_io_tx_dat_bits_data[152])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[152] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[153] && mb_s1_io_tx_dat_bits_data[153])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[153] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[154] && mb_s1_io_tx_dat_bits_data[154])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[154] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[155] && mb_s1_io_tx_dat_bits_data[155])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[155] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[156] && mb_s1_io_tx_dat_bits_data[156])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[156] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[157] && mb_s1_io_tx_dat_bits_data[157])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[157] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[158] && mb_s1_io_tx_dat_bits_data[158])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[158] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[159] && mb_s1_io_tx_dat_bits_data[159])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[159] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[160] && mb_s1_io_tx_dat_bits_data[160])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[160] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[161] && mb_s1_io_tx_dat_bits_data[161])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[161] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[162] && mb_s1_io_tx_dat_bits_data[162])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[162] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[163] && mb_s1_io_tx_dat_bits_data[163])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[163] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[164] && mb_s1_io_tx_dat_bits_data[164])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[164] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[165] && mb_s1_io_tx_dat_bits_data[165])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[165] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[166] && mb_s1_io_tx_dat_bits_data[166])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[166] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[167] && mb_s1_io_tx_dat_bits_data[167])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[167] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[168] && mb_s1_io_tx_dat_bits_data[168])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[168] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[169] && mb_s1_io_tx_dat_bits_data[169])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[169] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[170] && mb_s1_io_tx_dat_bits_data[170])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[170] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[171] && mb_s1_io_tx_dat_bits_data[171])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[171] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[172] && mb_s1_io_tx_dat_bits_data[172])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[172] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[173] && mb_s1_io_tx_dat_bits_data[173])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[173] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[174] && mb_s1_io_tx_dat_bits_data[174])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[174] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[175] && mb_s1_io_tx_dat_bits_data[175])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[175] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[176] && mb_s1_io_tx_dat_bits_data[176])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[176] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[177] && mb_s1_io_tx_dat_bits_data[177])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[177] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[178] && mb_s1_io_tx_dat_bits_data[178])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[178] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[179] && mb_s1_io_tx_dat_bits_data[179])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[179] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[180] && mb_s1_io_tx_dat_bits_data[180])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[180] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[181] && mb_s1_io_tx_dat_bits_data[181])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[181] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[182] && mb_s1_io_tx_dat_bits_data[182])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[182] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[183] && mb_s1_io_tx_dat_bits_data[183])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[183] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[184] && mb_s1_io_tx_dat_bits_data[184])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[184] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[185] && mb_s1_io_tx_dat_bits_data[185])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[185] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[186] && mb_s1_io_tx_dat_bits_data[186])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[186] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[187] && mb_s1_io_tx_dat_bits_data[187])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[187] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[188] && mb_s1_io_tx_dat_bits_data[188])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[188] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[189] && mb_s1_io_tx_dat_bits_data[189])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[189] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[190] && mb_s1_io_tx_dat_bits_data[190])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[190] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[191] && mb_s1_io_tx_dat_bits_data[191])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[191] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[192] && mb_s1_io_tx_dat_bits_data[192])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[192] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[193] && mb_s1_io_tx_dat_bits_data[193])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[193] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[194] && mb_s1_io_tx_dat_bits_data[194])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[194] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[195] && mb_s1_io_tx_dat_bits_data[195])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[195] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[196] && mb_s1_io_tx_dat_bits_data[196])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[196] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[197] && mb_s1_io_tx_dat_bits_data[197])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[197] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[198] && mb_s1_io_tx_dat_bits_data[198])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[198] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[199] && mb_s1_io_tx_dat_bits_data[199])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[199] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[200] && mb_s1_io_tx_dat_bits_data[200])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[200] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[201] && mb_s1_io_tx_dat_bits_data[201])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[201] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[202] && mb_s1_io_tx_dat_bits_data[202])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[202] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[203] && mb_s1_io_tx_dat_bits_data[203])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[203] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[204] && mb_s1_io_tx_dat_bits_data[204])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[204] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[205] && mb_s1_io_tx_dat_bits_data[205])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[205] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[206] && mb_s1_io_tx_dat_bits_data[206])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[206] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[207] && mb_s1_io_tx_dat_bits_data[207])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[207] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[208] && mb_s1_io_tx_dat_bits_data[208])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[208] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[209] && mb_s1_io_tx_dat_bits_data[209])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[209] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[210] && mb_s1_io_tx_dat_bits_data[210])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[210] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[211] && mb_s1_io_tx_dat_bits_data[211])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[211] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[212] && mb_s1_io_tx_dat_bits_data[212])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[212] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[213] && mb_s1_io_tx_dat_bits_data[213])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[213] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[214] && mb_s1_io_tx_dat_bits_data[214])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[214] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[215] && mb_s1_io_tx_dat_bits_data[215])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[215] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[216] && mb_s1_io_tx_dat_bits_data[216])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[216] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[217] && mb_s1_io_tx_dat_bits_data[217])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[217] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[218] && mb_s1_io_tx_dat_bits_data[218])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[218] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[219] && mb_s1_io_tx_dat_bits_data[219])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[219] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[220] && mb_s1_io_tx_dat_bits_data[220])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[220] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[221] && mb_s1_io_tx_dat_bits_data[221])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[221] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[222] && mb_s1_io_tx_dat_bits_data[222])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[222] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[223] && mb_s1_io_tx_dat_bits_data[223])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[223] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[224] && mb_s1_io_tx_dat_bits_data[224])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[224] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[225] && mb_s1_io_tx_dat_bits_data[225])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[225] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[226] && mb_s1_io_tx_dat_bits_data[226])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[226] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[227] && mb_s1_io_tx_dat_bits_data[227])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[227] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[228] && mb_s1_io_tx_dat_bits_data[228])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[228] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[229] && mb_s1_io_tx_dat_bits_data[229])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[229] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[230] && mb_s1_io_tx_dat_bits_data[230])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[230] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[231] && mb_s1_io_tx_dat_bits_data[231])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[231] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[232] && mb_s1_io_tx_dat_bits_data[232])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[232] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[233] && mb_s1_io_tx_dat_bits_data[233])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[233] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[234] && mb_s1_io_tx_dat_bits_data[234])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[234] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[235] && mb_s1_io_tx_dat_bits_data[235])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[235] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[236] && mb_s1_io_tx_dat_bits_data[236])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[236] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[237] && mb_s1_io_tx_dat_bits_data[237])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[237] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[238] && mb_s1_io_tx_dat_bits_data[238])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[238] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[239] && mb_s1_io_tx_dat_bits_data[239])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[239] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[240] && mb_s1_io_tx_dat_bits_data[240])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[240] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[241] && mb_s1_io_tx_dat_bits_data[241])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[241] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[242] && mb_s1_io_tx_dat_bits_data[242])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[242] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[243] && mb_s1_io_tx_dat_bits_data[243])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[243] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[244] && mb_s1_io_tx_dat_bits_data[244])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[244] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[245] && mb_s1_io_tx_dat_bits_data[245])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[245] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[246] && mb_s1_io_tx_dat_bits_data[246])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[246] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[247] && mb_s1_io_tx_dat_bits_data[247])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[247] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[248] && mb_s1_io_tx_dat_bits_data[248])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[248] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[249] && mb_s1_io_tx_dat_bits_data[249])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[249] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[250] && mb_s1_io_tx_dat_bits_data[250])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[250] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[251] && mb_s1_io_tx_dat_bits_data[251])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[251] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[252] && mb_s1_io_tx_dat_bits_data[252])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[252] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[253] && mb_s1_io_tx_dat_bits_data[253])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[253] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[254] && mb_s1_io_tx_dat_bits_data[254])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[254] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_data[255] && mb_s1_io_tx_dat_bits_data[255])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_data[255] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[0] && mb_s1_io_tx_dat_bits_dataCheck[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[1] && mb_s1_io_tx_dat_bits_dataCheck[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[2] && mb_s1_io_tx_dat_bits_dataCheck[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[3] && mb_s1_io_tx_dat_bits_dataCheck[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[4] && mb_s1_io_tx_dat_bits_dataCheck[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[5] && mb_s1_io_tx_dat_bits_dataCheck[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[6] && mb_s1_io_tx_dat_bits_dataCheck[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[7] && mb_s1_io_tx_dat_bits_dataCheck[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[8] && mb_s1_io_tx_dat_bits_dataCheck[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[9] && mb_s1_io_tx_dat_bits_dataCheck[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[10] && mb_s1_io_tx_dat_bits_dataCheck[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[11] && mb_s1_io_tx_dat_bits_dataCheck[11])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[11] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[12] && mb_s1_io_tx_dat_bits_dataCheck[12])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[12] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[13] && mb_s1_io_tx_dat_bits_dataCheck[13])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[13] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[14] && mb_s1_io_tx_dat_bits_dataCheck[14])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[14] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[15] && mb_s1_io_tx_dat_bits_dataCheck[15])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[15] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[16] && mb_s1_io_tx_dat_bits_dataCheck[16])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[16] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[17] && mb_s1_io_tx_dat_bits_dataCheck[17])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[17] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[18] && mb_s1_io_tx_dat_bits_dataCheck[18])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[18] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[19] && mb_s1_io_tx_dat_bits_dataCheck[19])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[19] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[20] && mb_s1_io_tx_dat_bits_dataCheck[20])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[20] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[21] && mb_s1_io_tx_dat_bits_dataCheck[21])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[21] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[22] && mb_s1_io_tx_dat_bits_dataCheck[22])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[22] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[23] && mb_s1_io_tx_dat_bits_dataCheck[23])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[23] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[24] && mb_s1_io_tx_dat_bits_dataCheck[24])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[24] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[25] && mb_s1_io_tx_dat_bits_dataCheck[25])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[25] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[26] && mb_s1_io_tx_dat_bits_dataCheck[26])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[26] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[27] && mb_s1_io_tx_dat_bits_dataCheck[27])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[27] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[28] && mb_s1_io_tx_dat_bits_dataCheck[28])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[28] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[29] && mb_s1_io_tx_dat_bits_dataCheck[29])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[29] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[30] && mb_s1_io_tx_dat_bits_dataCheck[30])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[30] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_dataCheck[31] && mb_s1_io_tx_dat_bits_dataCheck[31])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_dataCheck[31] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_poison[0] && mb_s1_io_tx_dat_bits_poison[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_poison[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_poison[1] && mb_s1_io_tx_dat_bits_poison[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_poison[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_poison[2] && mb_s1_io_tx_dat_bits_poison[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_poison[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_tx_dat_bits_poison[3] && mb_s1_io_tx_dat_bits_poison[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_tx_dat_bits_poison[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_rx_dat_ready && mb_s1_io_rx_dat_ready)) begin cov_fail++; $display("[COV] MMIOBridge.io_rx_dat_ready 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_valid && mb_s1_io_pCrd_0_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_pCrdType[0] && mb_s1_io_pCrd_0_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_pCrdType[1] && mb_s1_io_pCrd_0_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_pCrdType[2] && mb_s1_io_pCrd_0_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_pCrdType[3] && mb_s1_io_pCrd_0_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[0] && mb_s1_io_pCrd_0_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[1] && mb_s1_io_pCrd_0_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[2] && mb_s1_io_pCrd_0_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[3] && mb_s1_io_pCrd_0_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[4] && mb_s1_io_pCrd_0_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[5] && mb_s1_io_pCrd_0_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[6] && mb_s1_io_pCrd_0_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[7] && mb_s1_io_pCrd_0_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[8] && mb_s1_io_pCrd_0_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[9] && mb_s1_io_pCrd_0_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_0_query_bits_srcID[10] && mb_s1_io_pCrd_0_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_0_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_valid && mb_s1_io_pCrd_1_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_pCrdType[0] && mb_s1_io_pCrd_1_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_pCrdType[1] && mb_s1_io_pCrd_1_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_pCrdType[2] && mb_s1_io_pCrd_1_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_pCrdType[3] && mb_s1_io_pCrd_1_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[0] && mb_s1_io_pCrd_1_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[1] && mb_s1_io_pCrd_1_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[2] && mb_s1_io_pCrd_1_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[3] && mb_s1_io_pCrd_1_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[4] && mb_s1_io_pCrd_1_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[5] && mb_s1_io_pCrd_1_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[6] && mb_s1_io_pCrd_1_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[7] && mb_s1_io_pCrd_1_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[8] && mb_s1_io_pCrd_1_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[9] && mb_s1_io_pCrd_1_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_1_query_bits_srcID[10] && mb_s1_io_pCrd_1_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_1_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_valid && mb_s1_io_pCrd_2_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_pCrdType[0] && mb_s1_io_pCrd_2_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_pCrdType[1] && mb_s1_io_pCrd_2_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_pCrdType[2] && mb_s1_io_pCrd_2_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_pCrdType[3] && mb_s1_io_pCrd_2_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[0] && mb_s1_io_pCrd_2_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[1] && mb_s1_io_pCrd_2_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[2] && mb_s1_io_pCrd_2_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[3] && mb_s1_io_pCrd_2_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[4] && mb_s1_io_pCrd_2_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[5] && mb_s1_io_pCrd_2_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[6] && mb_s1_io_pCrd_2_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[7] && mb_s1_io_pCrd_2_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[8] && mb_s1_io_pCrd_2_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[9] && mb_s1_io_pCrd_2_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_2_query_bits_srcID[10] && mb_s1_io_pCrd_2_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_2_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_valid && mb_s1_io_pCrd_3_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_pCrdType[0] && mb_s1_io_pCrd_3_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_pCrdType[1] && mb_s1_io_pCrd_3_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_pCrdType[2] && mb_s1_io_pCrd_3_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_pCrdType[3] && mb_s1_io_pCrd_3_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[0] && mb_s1_io_pCrd_3_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[1] && mb_s1_io_pCrd_3_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[2] && mb_s1_io_pCrd_3_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[3] && mb_s1_io_pCrd_3_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[4] && mb_s1_io_pCrd_3_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[5] && mb_s1_io_pCrd_3_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[6] && mb_s1_io_pCrd_3_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[7] && mb_s1_io_pCrd_3_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[8] && mb_s1_io_pCrd_3_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[9] && mb_s1_io_pCrd_3_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_3_query_bits_srcID[10] && mb_s1_io_pCrd_3_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_3_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_valid && mb_s1_io_pCrd_4_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_pCrdType[0] && mb_s1_io_pCrd_4_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_pCrdType[1] && mb_s1_io_pCrd_4_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_pCrdType[2] && mb_s1_io_pCrd_4_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_pCrdType[3] && mb_s1_io_pCrd_4_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[0] && mb_s1_io_pCrd_4_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[1] && mb_s1_io_pCrd_4_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[2] && mb_s1_io_pCrd_4_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[3] && mb_s1_io_pCrd_4_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[4] && mb_s1_io_pCrd_4_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[5] && mb_s1_io_pCrd_4_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[6] && mb_s1_io_pCrd_4_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[7] && mb_s1_io_pCrd_4_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[8] && mb_s1_io_pCrd_4_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[9] && mb_s1_io_pCrd_4_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_4_query_bits_srcID[10] && mb_s1_io_pCrd_4_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_4_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_valid && mb_s1_io_pCrd_5_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_pCrdType[0] && mb_s1_io_pCrd_5_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_pCrdType[1] && mb_s1_io_pCrd_5_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_pCrdType[2] && mb_s1_io_pCrd_5_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_pCrdType[3] && mb_s1_io_pCrd_5_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[0] && mb_s1_io_pCrd_5_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[1] && mb_s1_io_pCrd_5_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[2] && mb_s1_io_pCrd_5_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[3] && mb_s1_io_pCrd_5_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[4] && mb_s1_io_pCrd_5_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[5] && mb_s1_io_pCrd_5_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[6] && mb_s1_io_pCrd_5_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[7] && mb_s1_io_pCrd_5_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[8] && mb_s1_io_pCrd_5_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[9] && mb_s1_io_pCrd_5_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_5_query_bits_srcID[10] && mb_s1_io_pCrd_5_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_5_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_valid && mb_s1_io_pCrd_6_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_pCrdType[0] && mb_s1_io_pCrd_6_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_pCrdType[1] && mb_s1_io_pCrd_6_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_pCrdType[2] && mb_s1_io_pCrd_6_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_pCrdType[3] && mb_s1_io_pCrd_6_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[0] && mb_s1_io_pCrd_6_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[1] && mb_s1_io_pCrd_6_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[2] && mb_s1_io_pCrd_6_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[3] && mb_s1_io_pCrd_6_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[4] && mb_s1_io_pCrd_6_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[5] && mb_s1_io_pCrd_6_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[6] && mb_s1_io_pCrd_6_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[7] && mb_s1_io_pCrd_6_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[8] && mb_s1_io_pCrd_6_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[9] && mb_s1_io_pCrd_6_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_6_query_bits_srcID[10] && mb_s1_io_pCrd_6_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_6_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_valid && mb_s1_io_pCrd_7_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_pCrdType[0] && mb_s1_io_pCrd_7_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_pCrdType[1] && mb_s1_io_pCrd_7_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_pCrdType[2] && mb_s1_io_pCrd_7_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_pCrdType[3] && mb_s1_io_pCrd_7_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[0] && mb_s1_io_pCrd_7_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[1] && mb_s1_io_pCrd_7_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[2] && mb_s1_io_pCrd_7_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[3] && mb_s1_io_pCrd_7_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[4] && mb_s1_io_pCrd_7_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[5] && mb_s1_io_pCrd_7_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[6] && mb_s1_io_pCrd_7_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[7] && mb_s1_io_pCrd_7_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[8] && mb_s1_io_pCrd_7_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[9] && mb_s1_io_pCrd_7_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_7_query_bits_srcID[10] && mb_s1_io_pCrd_7_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_7_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_valid && mb_s1_io_pCrd_8_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_pCrdType[0] && mb_s1_io_pCrd_8_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_pCrdType[1] && mb_s1_io_pCrd_8_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_pCrdType[2] && mb_s1_io_pCrd_8_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_pCrdType[3] && mb_s1_io_pCrd_8_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[0] && mb_s1_io_pCrd_8_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[1] && mb_s1_io_pCrd_8_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[2] && mb_s1_io_pCrd_8_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[3] && mb_s1_io_pCrd_8_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[4] && mb_s1_io_pCrd_8_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[5] && mb_s1_io_pCrd_8_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[6] && mb_s1_io_pCrd_8_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[7] && mb_s1_io_pCrd_8_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[8] && mb_s1_io_pCrd_8_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[9] && mb_s1_io_pCrd_8_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_8_query_bits_srcID[10] && mb_s1_io_pCrd_8_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_8_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_valid && mb_s1_io_pCrd_9_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_pCrdType[0] && mb_s1_io_pCrd_9_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_pCrdType[1] && mb_s1_io_pCrd_9_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_pCrdType[2] && mb_s1_io_pCrd_9_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_pCrdType[3] && mb_s1_io_pCrd_9_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[0] && mb_s1_io_pCrd_9_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[1] && mb_s1_io_pCrd_9_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[2] && mb_s1_io_pCrd_9_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[3] && mb_s1_io_pCrd_9_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[4] && mb_s1_io_pCrd_9_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[5] && mb_s1_io_pCrd_9_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[6] && mb_s1_io_pCrd_9_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[7] && mb_s1_io_pCrd_9_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[8] && mb_s1_io_pCrd_9_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[9] && mb_s1_io_pCrd_9_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_9_query_bits_srcID[10] && mb_s1_io_pCrd_9_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_9_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_valid && mb_s1_io_pCrd_10_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_pCrdType[0] && mb_s1_io_pCrd_10_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_pCrdType[1] && mb_s1_io_pCrd_10_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_pCrdType[2] && mb_s1_io_pCrd_10_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_pCrdType[3] && mb_s1_io_pCrd_10_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[0] && mb_s1_io_pCrd_10_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[1] && mb_s1_io_pCrd_10_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[2] && mb_s1_io_pCrd_10_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[3] && mb_s1_io_pCrd_10_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[4] && mb_s1_io_pCrd_10_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[5] && mb_s1_io_pCrd_10_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[6] && mb_s1_io_pCrd_10_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[7] && mb_s1_io_pCrd_10_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[8] && mb_s1_io_pCrd_10_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[9] && mb_s1_io_pCrd_10_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_10_query_bits_srcID[10] && mb_s1_io_pCrd_10_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_10_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_valid && mb_s1_io_pCrd_11_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_pCrdType[0] && mb_s1_io_pCrd_11_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_pCrdType[1] && mb_s1_io_pCrd_11_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_pCrdType[2] && mb_s1_io_pCrd_11_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_pCrdType[3] && mb_s1_io_pCrd_11_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[0] && mb_s1_io_pCrd_11_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[1] && mb_s1_io_pCrd_11_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[2] && mb_s1_io_pCrd_11_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[3] && mb_s1_io_pCrd_11_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[4] && mb_s1_io_pCrd_11_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[5] && mb_s1_io_pCrd_11_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[6] && mb_s1_io_pCrd_11_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[7] && mb_s1_io_pCrd_11_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[8] && mb_s1_io_pCrd_11_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[9] && mb_s1_io_pCrd_11_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_11_query_bits_srcID[10] && mb_s1_io_pCrd_11_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_11_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_valid && mb_s1_io_pCrd_12_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_pCrdType[0] && mb_s1_io_pCrd_12_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_pCrdType[1] && mb_s1_io_pCrd_12_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_pCrdType[2] && mb_s1_io_pCrd_12_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_pCrdType[3] && mb_s1_io_pCrd_12_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[0] && mb_s1_io_pCrd_12_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[1] && mb_s1_io_pCrd_12_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[2] && mb_s1_io_pCrd_12_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[3] && mb_s1_io_pCrd_12_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[4] && mb_s1_io_pCrd_12_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[5] && mb_s1_io_pCrd_12_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[6] && mb_s1_io_pCrd_12_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[7] && mb_s1_io_pCrd_12_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[8] && mb_s1_io_pCrd_12_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[9] && mb_s1_io_pCrd_12_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_12_query_bits_srcID[10] && mb_s1_io_pCrd_12_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_12_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_valid && mb_s1_io_pCrd_13_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_pCrdType[0] && mb_s1_io_pCrd_13_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_pCrdType[1] && mb_s1_io_pCrd_13_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_pCrdType[2] && mb_s1_io_pCrd_13_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_pCrdType[3] && mb_s1_io_pCrd_13_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[0] && mb_s1_io_pCrd_13_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[1] && mb_s1_io_pCrd_13_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[2] && mb_s1_io_pCrd_13_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[3] && mb_s1_io_pCrd_13_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[4] && mb_s1_io_pCrd_13_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[5] && mb_s1_io_pCrd_13_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[6] && mb_s1_io_pCrd_13_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[7] && mb_s1_io_pCrd_13_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[8] && mb_s1_io_pCrd_13_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[9] && mb_s1_io_pCrd_13_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_13_query_bits_srcID[10] && mb_s1_io_pCrd_13_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_13_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_valid && mb_s1_io_pCrd_14_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_pCrdType[0] && mb_s1_io_pCrd_14_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_pCrdType[1] && mb_s1_io_pCrd_14_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_pCrdType[2] && mb_s1_io_pCrd_14_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_pCrdType[3] && mb_s1_io_pCrd_14_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[0] && mb_s1_io_pCrd_14_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[1] && mb_s1_io_pCrd_14_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[2] && mb_s1_io_pCrd_14_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[3] && mb_s1_io_pCrd_14_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[4] && mb_s1_io_pCrd_14_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[5] && mb_s1_io_pCrd_14_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[6] && mb_s1_io_pCrd_14_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[7] && mb_s1_io_pCrd_14_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[8] && mb_s1_io_pCrd_14_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[9] && mb_s1_io_pCrd_14_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_14_query_bits_srcID[10] && mb_s1_io_pCrd_14_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_14_query_bits_srcID[10] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_valid && mb_s1_io_pCrd_15_query_valid)) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_valid 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_pCrdType[0] && mb_s1_io_pCrd_15_query_bits_pCrdType[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_pCrdType[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_pCrdType[1] && mb_s1_io_pCrd_15_query_bits_pCrdType[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_pCrdType[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_pCrdType[2] && mb_s1_io_pCrd_15_query_bits_pCrdType[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_pCrdType[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_pCrdType[3] && mb_s1_io_pCrd_15_query_bits_pCrdType[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_pCrdType[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[0] && mb_s1_io_pCrd_15_query_bits_srcID[0])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[0] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[1] && mb_s1_io_pCrd_15_query_bits_srcID[1])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[1] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[2] && mb_s1_io_pCrd_15_query_bits_srcID[2])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[2] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[3] && mb_s1_io_pCrd_15_query_bits_srcID[3])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[3] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[4] && mb_s1_io_pCrd_15_query_bits_srcID[4])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[4] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[5] && mb_s1_io_pCrd_15_query_bits_srcID[5])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[5] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[6] && mb_s1_io_pCrd_15_query_bits_srcID[6])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[6] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[7] && mb_s1_io_pCrd_15_query_bits_srcID[7])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[7] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[8] && mb_s1_io_pCrd_15_query_bits_srcID[8])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[8] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[9] && mb_s1_io_pCrd_15_query_bits_srcID[9])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[9] 未见过 0 和 1"); end
    if (!(mb_s0_io_pCrd_15_query_bits_srcID[10] && mb_s1_io_pCrd_15_query_bits_srcID[10])) begin cov_fail++; $display("[COV] MMIOBridge.io_pCrd_15_query_bits_srcID[10] 未见过 0 和 1"); end
    $display("[ARM] MMIOBridge armed_at=%0d", mb_armed_at);
    if (mb_armed_at < 0) begin cov_fail++; $display("[ARM] MMIOBridge 从未 arm"); end
    $display("[COV] MMIOBridge.a_fire = %0d", mb_cov_a_fire);
    if (mb_cov_a_fire < 50) begin cov_fail++; $display("[COV] MMIOBridge.a_fire < 50"); end
    $display("[COV] MMIOBridge.a_full = %0d", mb_cov_a_full);
    if (mb_cov_a_full < 50) begin cov_fail++; $display("[COV] MMIOBridge.a_full < 50"); end
    $display("[COV] MMIOBridge.slot15_used = %0d", mb_cov_slot15_used);
    if (mb_cov_slot15_used < 50) begin cov_fail++; $display("[COV] MMIOBridge.slot15_used < 50"); end
    $display("[COV] MMIOBridge.d_read = %0d", mb_cov_d_read);
    if (mb_cov_d_read < 50) begin cov_fail++; $display("[COV] MMIOBridge.d_read < 50"); end
    $display("[COV] MMIOBridge.d_write = %0d", mb_cov_d_write);
    if (mb_cov_d_write < 50) begin cov_fail++; $display("[COV] MMIOBridge.d_write < 50"); end
    $display("[COV] MMIOBridge.txreq_fire = %0d", mb_cov_txreq_fire);
    if (mb_cov_txreq_fire < 50) begin cov_fail++; $display("[COV] MMIOBridge.txreq_fire < 50"); end
    $display("[COV] MMIOBridge.txdat_fire = %0d", mb_cov_txdat_fire);
    if (mb_cov_txdat_fire < 50) begin cov_fail++; $display("[COV] MMIOBridge.txdat_fire < 50"); end
    $display("[COV] MMIOBridge.read_blocked = %0d", mb_cov_read_blocked);
    if (mb_cov_read_blocked < 50) begin cov_fail++; $display("[COV] MMIOBridge.read_blocked < 50"); end
    $display("[COV] MMIOBridge.wait_rr = %0d", mb_cov_wait_rr);
    if (mb_cov_wait_rr < 50) begin cov_fail++; $display("[COV] MMIOBridge.wait_rr < 50"); end
    $display("[COV] MMIOBridge.rxdat_ready = %0d", mb_cov_rxdat_ready);
    if (mb_cov_rxdat_ready < 50) begin cov_fail++; $display("[COV] MMIOBridge.rxdat_ready < 50"); end
    $display("[COV] MMIOBridge.rxdat_miss = %0d", mb_cov_rxdat_miss);
    if (mb_cov_rxdat_miss < 50) begin cov_fail++; $display("[COV] MMIOBridge.rxdat_miss < 50"); end
    $display("[COV] MMIOBridge.pcrd_query = %0d", mb_cov_pcrd_query);
    if (mb_cov_pcrd_query < 50) begin cov_fail++; $display("[COV] MMIOBridge.pcrd_query < 50"); end
    $display("checks=%0d errors=%0d cov_fail=%0d", checks, errors, cov_fail);
    if (errors == 0 && cov_fail == 0 && checks > 0) $display("TEST PASSED");
    else $display("TEST FAILED");
    $finish;
  end
endmodule

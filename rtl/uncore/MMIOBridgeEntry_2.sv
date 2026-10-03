// MMIOBridgeEntry_2.sv —— TL→CHI MMIO 桥的事务槽，io_id 为 2 位的变体
//
// 核在 rtl/uncore/xs_MMIOBridgeEntry_core.sv（机制、状态标志与怪癖都讲在那里）。MMIOBridge 的 16 个槽
// 按槽号字面量的位宽被单态化成四个模块：MMIOBridgeEntry（槽 0~1，1 位）/ _2（槽 2~3，2 位）/
// _4（槽 4~7，3 位）/ _8（槽 8~15，4 位）；本变体服务槽 2~3。槽号零扩展后作为 CHI TXREQ 的 txnID
// 发出去。本文件只把 golden 同名端口原样接到核上。
module MMIOBridgeEntry_2 (
  input  logic         clock,
  input  logic         reset,
  output logic         io_req_ready,
  input  logic         io_req_valid,
  input  logic [3:0]   io_req_bits_opcode,
  input  logic [1:0]   io_req_bits_size,
  input  logic [4:0]   io_req_bits_source,
  input  logic [47:0]  io_req_bits_address,
  input  logic         io_req_bits_user_memBackType_MM,
  input  logic         io_req_bits_user_memPageType_NC,
  input  logic [7:0]   io_req_bits_mask,
  input  logic [63:0]  io_req_bits_data,
  input  logic         io_req_bits_corrupt,
  input  logic         io_resp_ready,
  output logic         io_resp_valid,
  output logic [3:0]   io_resp_bits_opcode,
  output logic [1:0]   io_resp_bits_size,
  output logic [4:0]   io_resp_bits_source,
  output logic         io_resp_bits_denied,
  output logic [63:0]  io_resp_bits_data,
  output logic         io_resp_bits_corrupt,
  input  logic         io_chi_tx_req_ready,
  output logic         io_chi_tx_req_valid,
  output logic [11:0]  io_chi_tx_req_bits_txnID,
  output logic [6:0]   io_chi_tx_req_bits_opcode,
  output logic [2:0]   io_chi_tx_req_bits_size,
  output logic [47:0]  io_chi_tx_req_bits_addr,
  output logic         io_chi_tx_req_bits_allowRetry,
  output logic [1:0]   io_chi_tx_req_bits_order,
  output logic [3:0]   io_chi_tx_req_bits_pCrdType,
  output logic         io_chi_tx_req_bits_memAttr_device,
  output logic         io_chi_tx_req_bits_memAttr_ewa,
  input  logic         io_chi_tx_dat_ready,
  output logic         io_chi_tx_dat_valid,
  output logic [10:0]  io_chi_tx_dat_bits_tgtID,
  output logic [11:0]  io_chi_tx_dat_bits_txnID,
  output logic [1:0]   io_chi_tx_dat_bits_respErr,
  output logic [1:0]   io_chi_tx_dat_bits_ccID,
  output logic [1:0]   io_chi_tx_dat_bits_dataID,
  output logic         io_chi_tx_dat_bits_traceTag,
  output logic [31:0]  io_chi_tx_dat_bits_be,
  output logic [255:0] io_chi_tx_dat_bits_data,
  output logic [31:0]  io_chi_tx_dat_bits_dataCheck,
  output logic [3:0]   io_chi_tx_dat_bits_poison,
  output logic         io_chi_rx_rsp_ready,
  input  logic         io_chi_rx_rsp_valid,
  input  logic [10:0]  io_chi_rx_rsp_bits_srcID,
  input  logic [4:0]   io_chi_rx_rsp_bits_opcode,
  input  logic [1:0]   io_chi_rx_rsp_bits_respErr,
  input  logic [11:0]  io_chi_rx_rsp_bits_dbID,
  input  logic [3:0]   io_chi_rx_rsp_bits_pCrdType,
  input  logic         io_chi_rx_rsp_bits_traceTag,
  output logic         io_chi_rx_dat_ready,
  input  logic         io_chi_rx_dat_valid,
  input  logic [1:0]   io_chi_rx_dat_bits_respErr,
  input  logic [255:0] io_chi_rx_dat_bits_data,
  input  logic [31:0]  io_chi_rx_dat_bits_dataCheck,
  input  logic [3:0]   io_chi_rx_dat_bits_poison,
  input  logic [1:0]   io_id,
  output logic         io_pCrd_query_valid,
  output logic [3:0]   io_pCrd_query_bits_pCrdType,
  output logic [10:0]  io_pCrd_query_bits_srcID,
  input  logic         io_pCrd_grant,
  output logic         io_waitOnReadReceipt
);

  xs_MMIOBridgeEntry_core #(
    .ID_W(2)
  ) u_core (
    .*
  );

endmodule

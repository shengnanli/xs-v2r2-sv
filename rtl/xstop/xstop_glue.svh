// 自动生成:scripts/gen_xstop.py —— 勿手改(顶层 glue 为从 Scala 意图的可读重写)

// ===================================================================
// CHI 多 die(2 个 outer 节点)Tx/Rx 路由 glue —— 从 Scala 设计意图重写。
//   保留 golden 的布尔/算术结构(地址译码 OR、reduction-OR、仲裁分发),
//   仅把 golden 的 _T_/inner_/outer_ 临时名换成可读具名 wire(见脚本 _RENAME)。
// ===================================================================

  // ① tile 复位:同步复位 OR DebugModule 的 hart 复位请求(送 core_with_l2.reset)。
  wire tileReset = _reset_sync_resetSync_o_reset | _nocMisc_debug_module_io_resetCtrl_hartResetReq_0;

  // ② Tx-REQ 目标 die 地址译码:按 tx_req 地址区间选 outer die,
  //    txReqTgtSel=2'h2 -> die0(tgtID=2),=2'h1 -> die1(tgtID=1)。
  wire txReqAddrHi17IsZero = _linkMonitor_io_out_tx_req_bits_addr[47:31] == 17'h0;
  wire txReqAddrInLowRegions = txReqAddrHi17IsZero | {_linkMonitor_io_out_tx_req_bits_addr[47:40], ~(_linkMonitor_io_out_tx_req_bits_addr[39])} == 9'h0;
  wire [1:0] txReqTgtSel = {_linkMonitor_io_out_tx_req_bits_addr[47:35], ~(_linkMonitor_io_out_tx_req_bits_addr[34])} == 14'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47:37], ~(_linkMonitor_io_out_tx_req_bits_addr[36])} == 12'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47:39], ~(_linkMonitor_io_out_tx_req_bits_addr[38])} == 10'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47:43], ~(_linkMonitor_io_out_tx_req_bits_addr[42])} == 6'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47:33], ~(_linkMonitor_io_out_tx_req_bits_addr[32])} == 16'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47:44], ~(_linkMonitor_io_out_tx_req_bits_addr[43])} == 5'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47:38], ~(_linkMonitor_io_out_tx_req_bits_addr[37])} == 11'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47], ~(_linkMonitor_io_out_tx_req_bits_addr[46])} == 2'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47:45], ~(_linkMonitor_io_out_tx_req_bits_addr[44])} == 4'h0 | ~((txReqAddrInLowRegions | {_linkMonitor_io_out_tx_req_bits_addr[47:34], ~(_linkMonitor_io_out_tx_req_bits_addr[33])} == 15'h0 | {_linkMonitor_io_out_tx_req_bits_addr[47:46], ~(_linkMonitor_io_out_tx_req_bits_addr[45])} == 3'h0) & txReqAddrInLowRegions & txReqAddrHi17IsZero) ? 2'h2 : 2'h1;
  wire [10:0] txReqTgtID = {9'h0, txReqTgtSel};

  // ③ Tx 通道按 tgtID 把本端 linkMonitor 的 valid 分发到 die0/die1。
  wire txReqToDie0Valid = _linkMonitor_io_out_tx_req_valid & txReqTgtSel == 2'h2;
  wire txRspToDie0Valid = _linkMonitor_io_out_tx_rsp_valid & _linkMonitor_io_out_tx_rsp_bits_tgtID == 11'h2;
  wire txDatToDie0Valid = _linkMonitor_io_out_tx_dat_valid & _linkMonitor_io_out_tx_dat_bits_tgtID == 11'h2;
  wire txReqToDie1Valid = _linkMonitor_io_out_tx_req_valid & txReqTgtSel == 2'h1;
  wire txRspToDie1Valid = _linkMonitor_io_out_tx_rsp_valid & _linkMonitor_io_out_tx_rsp_bits_tgtID == 11'h1;
  wire txDatToDie1Valid = _linkMonitor_io_out_tx_dat_valid & _linkMonitor_io_out_tx_dat_bits_tgtID == 11'h1;

  // ⑤ outer die Rx ready 中间量:本端 rx ready & 对应 Rx 仲裁器 out valid
  //    (再在引脚处 & [~]arb_chosen 分发到 die0/die1,见 inst.svh)。
  wire rxSnpReadyAndArbValid = _linkMonitor_io_out_rx_snp_ready & _rxsnpArb_io_out_valid;
  wire rxRspReadyAndArbValid = _linkMonitor_io_out_rx_rsp_ready & _rxrspArb_io_out_valid;
  wire rxDatReadyAndArbValid = _linkMonitor_io_out_rx_dat_ready & _rxdatArb_io_out_valid;

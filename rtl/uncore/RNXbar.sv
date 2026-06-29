// =============================================================================
//  RNXbar —— 香山 V2R2 CHI Request-Node 交叉开关 (可读重写核 xs_RNXbar_core)
// -----------------------------------------------------------------------------
//  源自 OpenLLC 的 RNXbar: 1 个上游 Request-Node (io_in_0, 携带完整 CHIBundleUpstream
//  全字段) × 4 个下游 Home-Node bank (io_out_0..3, 携带精简的 CHIBundleDownstream
//  字段)。从设计意图重写 (非照抄 firtool 优化后的展平命名)。
//
//  数据流 (6 通道):
//    上行 TX (RN→HN, 1→4 按路由位拆分):
//      · TXREQ 路由位 = addr[7:6]  ; 4 个 bank 各一个 FastArbiter_30 (单输入透传黑盒)
//      · TXRSP 路由位 = txnID[10:9]; 4 个 FastArbiter_36
//      · TXDAT 路由位 = txnID[10:9]; 4 个 FastArbiter_31
//      RN 侧 ready = 路由命中 bank 的输出 valid 的或归约 (TXREQ 还 & 该 bank out_ready)。
//    下行 RX (HN→RN, 4→1 仲裁汇聚):
//      · RXRSP : FastArbiter_27 (4 输入, 按 srcID==0 门控), io_chosen 决定 ready 回送
//      · RXDAT : FastArbiter_46 (4 输入, 按 srcID==0 门控)
//      · RXSNP : FastArbiter_44 (4 输入), 但输入先经「snoop 跟踪状态机」缓存一拍 ——
//                这是本核相对 SNXbar 的关键差异, 见下方 snoop 跟踪段落。
//
//  snoop 跟踪状态机 (snpReqs / snpMasks 快照寄存器):
//    每个 HN bank j 有一个 1 深 snoop 槽:
//      · snpReqs_j  : 锁存进来的 snoop 载荷 (txnID/fwdNID/fwdTxnID/opcode/addr/
//                     doNotGoToSD/retToSrc); snpReqs_j_valid 是粘滞位 (一旦收过 snoop
//                     就恒 1, 表示槽内 bits 已是真实快照而非复位 0)。
//      · snpMasks_j : 「该 snoop 仍需投递给 RN」的挂起位 (本设计 1 个 RN ⇒ 1 位)。
//                     接收新 snoop 时置为外部输入 io_snp_mask_set_j (= 上游算出的目标
//                     掩码: 1 需投递 / 0 直接过滤丢弃); RN 取走该 snoop 后清 0。
//    仲裁器输入 valid = snpReqs_j_valid & snpMasks_j  ⇒ 只有「挂起」的 snoop 才参与
//    仲裁、投递给 RN。回送 HN bank 的 rx_snp_ready = 槽当前空 (~挂起) 或本拍正被取走
//    清空 (有快照 valid 且 mask 将清), 即 1 深槽的接收背压。
//
//  黑盒子模块 (15 个 FastArbiter, 仲裁 + 胜者 payload 选择由其内部完成, 本核不重写):
//    txreqArbs ×4 (FastArbiter_30) / txrspArbs ×4 (_36) / txdatArbs ×4 (_31)
//    rxsnpArbs ×1 (_44) / rxrspArbs ×1 (_27) / rxdatArbs ×1 (_46)
//  UT 两侧共用同名黑盒 (同一仲裁内部状态), FM 两侧黑盒按连接配对, 故验证聚焦本核的
//  路由 / 解复用 / snoop 跟踪逻辑。X 铁律: 复位清零 + initreg+0, 不产生 X。
// =============================================================================
module xs_RNXbar_core
  import rnxbar_pkg::*;
(
  input          clock,
  input          reset,
  output         io_in_0_tx_req_ready,
  input          io_in_0_tx_req_valid,
  input  [3:0]   io_in_0_tx_req_bits_qos,
  input  [10:0]  io_in_0_tx_req_bits_tgtID,
  input  [10:0]  io_in_0_tx_req_bits_srcID,
  input  [11:0]  io_in_0_tx_req_bits_txnID,
  input  [10:0]  io_in_0_tx_req_bits_returnNID,
  input          io_in_0_tx_req_bits_stashNIDValid,
  input  [11:0]  io_in_0_tx_req_bits_returnTxnID,
  input  [6:0]   io_in_0_tx_req_bits_opcode,
  input  [2:0]   io_in_0_tx_req_bits_size,
  input  [47:0]  io_in_0_tx_req_bits_addr,
  input          io_in_0_tx_req_bits_ns,
  input          io_in_0_tx_req_bits_likelyshared,
  input          io_in_0_tx_req_bits_allowRetry,
  input  [1:0]   io_in_0_tx_req_bits_order,
  input  [3:0]   io_in_0_tx_req_bits_pCrdType,
  input          io_in_0_tx_req_bits_memAttr_allocate,
  input          io_in_0_tx_req_bits_memAttr_cacheable,
  input          io_in_0_tx_req_bits_memAttr_device,
  input          io_in_0_tx_req_bits_memAttr_ewa,
  input          io_in_0_tx_req_bits_snpAttr,
  input  [7:0]   io_in_0_tx_req_bits_lpIDWithPadding,
  input          io_in_0_tx_req_bits_snoopMe,
  input          io_in_0_tx_req_bits_expCompAck,
  input  [1:0]   io_in_0_tx_req_bits_tagOp,
  input          io_in_0_tx_req_bits_traceTag,
  input          io_in_0_tx_req_bits_mpam_perfMonGroup,
  input  [8:0]   io_in_0_tx_req_bits_mpam_partID,
  input          io_in_0_tx_req_bits_mpam_mpamNS,
  input  [3:0]   io_in_0_tx_req_bits_rsvdc,
  output         io_in_0_tx_rsp_ready,
  input          io_in_0_tx_rsp_valid,
  input  [10:0]  io_in_0_tx_rsp_bits_srcID,
  input  [11:0]  io_in_0_tx_rsp_bits_txnID,
  input  [4:0]   io_in_0_tx_rsp_bits_opcode,
  input  [11:0]  io_in_0_tx_rsp_bits_dbID,
  output         io_in_0_tx_dat_ready,
  input          io_in_0_tx_dat_valid,
  input  [3:0]   io_in_0_tx_dat_bits_qos,
  input  [10:0]  io_in_0_tx_dat_bits_tgtID,
  input  [10:0]  io_in_0_tx_dat_bits_srcID,
  input  [11:0]  io_in_0_tx_dat_bits_txnID,
  input  [10:0]  io_in_0_tx_dat_bits_homeNID,
  input  [3:0]   io_in_0_tx_dat_bits_opcode,
  input  [1:0]   io_in_0_tx_dat_bits_respErr,
  input  [2:0]   io_in_0_tx_dat_bits_resp,
  input  [3:0]   io_in_0_tx_dat_bits_dataSource,
  input  [2:0]   io_in_0_tx_dat_bits_cBusy,
  input  [11:0]  io_in_0_tx_dat_bits_dbID,
  input  [1:0]   io_in_0_tx_dat_bits_ccID,
  input  [1:0]   io_in_0_tx_dat_bits_dataID,
  input  [1:0]   io_in_0_tx_dat_bits_tagOp,
  input  [7:0]   io_in_0_tx_dat_bits_tag,
  input  [1:0]   io_in_0_tx_dat_bits_tu,
  input          io_in_0_tx_dat_bits_traceTag,
  input  [3:0]   io_in_0_tx_dat_bits_rsvdc,
  input  [31:0]  io_in_0_tx_dat_bits_be,
  input  [255:0] io_in_0_tx_dat_bits_data,
  input  [31:0]  io_in_0_tx_dat_bits_dataCheck,
  input  [3:0]   io_in_0_tx_dat_bits_poison,
  input          io_in_0_rx_rsp_ready,
  output         io_in_0_rx_rsp_valid,
  output [3:0]   io_in_0_rx_rsp_bits_qos,
  output [11:0]  io_in_0_rx_rsp_bits_txnID,
  output [4:0]   io_in_0_rx_rsp_bits_opcode,
  output [1:0]   io_in_0_rx_rsp_bits_respErr,
  output [2:0]   io_in_0_rx_rsp_bits_resp,
  output [2:0]   io_in_0_rx_rsp_bits_fwdState,
  output [2:0]   io_in_0_rx_rsp_bits_cBusy,
  output [11:0]  io_in_0_rx_rsp_bits_dbID,
  output [3:0]   io_in_0_rx_rsp_bits_pCrdType,
  output [1:0]   io_in_0_rx_rsp_bits_tagOp,
  output         io_in_0_rx_rsp_bits_traceTag,
  input          io_in_0_rx_dat_ready,
  output         io_in_0_rx_dat_valid,
  output [11:0]  io_in_0_rx_dat_bits_txnID,
  output [10:0]  io_in_0_rx_dat_bits_homeNID,
  output [3:0]   io_in_0_rx_dat_bits_opcode,
  output [2:0]   io_in_0_rx_dat_bits_resp,
  output [3:0]   io_in_0_rx_dat_bits_dataSource,
  output [11:0]  io_in_0_rx_dat_bits_dbID,
  output [1:0]   io_in_0_rx_dat_bits_dataID,
  output [31:0]  io_in_0_rx_dat_bits_be,
  output [255:0] io_in_0_rx_dat_bits_data,
  output [31:0]  io_in_0_rx_dat_bits_dataCheck,
  input          io_in_0_rx_snp_ready,
  output         io_in_0_rx_snp_valid,
  output [11:0]  io_in_0_rx_snp_bits_txnID,
  output [10:0]  io_in_0_rx_snp_bits_fwdNID,
  output [11:0]  io_in_0_rx_snp_bits_fwdTxnID,
  output [4:0]   io_in_0_rx_snp_bits_opcode,
  output [44:0]  io_in_0_rx_snp_bits_addr,
  output         io_in_0_rx_snp_bits_doNotGoToSD,
  output         io_in_0_rx_snp_bits_retToSrc,
  input          io_out_0_tx_req_ready,
  output         io_out_0_tx_req_valid,
  output [10:0]  io_out_0_tx_req_bits_tgtID,
  output [10:0]  io_out_0_tx_req_bits_srcID,
  output [11:0]  io_out_0_tx_req_bits_txnID,
  output [6:0]   io_out_0_tx_req_bits_opcode,
  output [2:0]   io_out_0_tx_req_bits_size,
  output [47:0]  io_out_0_tx_req_bits_addr,
  output         io_out_0_tx_req_bits_allowRetry,
  output [1:0]   io_out_0_tx_req_bits_order,
  output [3:0]   io_out_0_tx_req_bits_pCrdType,
  output         io_out_0_tx_req_bits_memAttr_allocate,
  output         io_out_0_tx_req_bits_memAttr_cacheable,
  output         io_out_0_tx_req_bits_memAttr_device,
  output         io_out_0_tx_req_bits_memAttr_ewa,
  output         io_out_0_tx_req_bits_snpAttr,
  output         io_out_0_tx_req_bits_expCompAck,
  output         io_out_0_tx_rsp_valid,
  output [10:0]  io_out_0_tx_rsp_bits_srcID,
  output [11:0]  io_out_0_tx_rsp_bits_txnID,
  output [4:0]   io_out_0_tx_rsp_bits_opcode,
  output [11:0]  io_out_0_tx_rsp_bits_dbID,
  output         io_out_0_tx_dat_valid,
  output [10:0]  io_out_0_tx_dat_bits_srcID,
  output [11:0]  io_out_0_tx_dat_bits_txnID,
  output [3:0]   io_out_0_tx_dat_bits_opcode,
  output [2:0]   io_out_0_tx_dat_bits_resp,
  output [1:0]   io_out_0_tx_dat_bits_dataID,
  output [255:0] io_out_0_tx_dat_bits_data,
  output         io_out_0_rx_rsp_ready,
  input          io_out_0_rx_rsp_valid,
  input  [10:0]  io_out_0_rx_rsp_bits_tgtID,
  input  [10:0]  io_out_0_rx_rsp_bits_srcID,
  input  [11:0]  io_out_0_rx_rsp_bits_txnID,
  input  [4:0]   io_out_0_rx_rsp_bits_opcode,
  input  [2:0]   io_out_0_rx_rsp_bits_resp,
  input  [2:0]   io_out_0_rx_rsp_bits_fwdState,
  input  [11:0]  io_out_0_rx_rsp_bits_dbID,
  input  [3:0]   io_out_0_rx_rsp_bits_pCrdType,
  output         io_out_0_rx_dat_ready,
  input          io_out_0_rx_dat_valid,
  input  [10:0]  io_out_0_rx_dat_bits_tgtID,
  input  [10:0]  io_out_0_rx_dat_bits_srcID,
  input  [11:0]  io_out_0_rx_dat_bits_txnID,
  input  [10:0]  io_out_0_rx_dat_bits_homeNID,
  input  [3:0]   io_out_0_rx_dat_bits_opcode,
  input  [2:0]   io_out_0_rx_dat_bits_resp,
  input  [3:0]   io_out_0_rx_dat_bits_dataSource,
  input  [11:0]  io_out_0_rx_dat_bits_dbID,
  input  [1:0]   io_out_0_rx_dat_bits_dataID,
  input  [31:0]  io_out_0_rx_dat_bits_be,
  input  [255:0] io_out_0_rx_dat_bits_data,
  input  [31:0]  io_out_0_rx_dat_bits_dataCheck,
  output         io_out_0_rx_snp_ready,
  input          io_out_0_rx_snp_valid,
  input  [11:0]  io_out_0_rx_snp_bits_txnID,
  input  [10:0]  io_out_0_rx_snp_bits_fwdNID,
  input  [11:0]  io_out_0_rx_snp_bits_fwdTxnID,
  input  [4:0]   io_out_0_rx_snp_bits_opcode,
  input  [44:0]  io_out_0_rx_snp_bits_addr,
  input          io_out_0_rx_snp_bits_doNotGoToSD,
  input          io_out_0_rx_snp_bits_retToSrc,
  input          io_out_1_tx_req_ready,
  output         io_out_1_tx_req_valid,
  output [10:0]  io_out_1_tx_req_bits_tgtID,
  output [10:0]  io_out_1_tx_req_bits_srcID,
  output [11:0]  io_out_1_tx_req_bits_txnID,
  output [6:0]   io_out_1_tx_req_bits_opcode,
  output [2:0]   io_out_1_tx_req_bits_size,
  output [47:0]  io_out_1_tx_req_bits_addr,
  output         io_out_1_tx_req_bits_allowRetry,
  output [1:0]   io_out_1_tx_req_bits_order,
  output [3:0]   io_out_1_tx_req_bits_pCrdType,
  output         io_out_1_tx_req_bits_memAttr_allocate,
  output         io_out_1_tx_req_bits_memAttr_cacheable,
  output         io_out_1_tx_req_bits_memAttr_device,
  output         io_out_1_tx_req_bits_memAttr_ewa,
  output         io_out_1_tx_req_bits_snpAttr,
  output         io_out_1_tx_req_bits_expCompAck,
  output         io_out_1_tx_rsp_valid,
  output [10:0]  io_out_1_tx_rsp_bits_srcID,
  output [11:0]  io_out_1_tx_rsp_bits_txnID,
  output [4:0]   io_out_1_tx_rsp_bits_opcode,
  output [11:0]  io_out_1_tx_rsp_bits_dbID,
  output         io_out_1_tx_dat_valid,
  output [10:0]  io_out_1_tx_dat_bits_srcID,
  output [11:0]  io_out_1_tx_dat_bits_txnID,
  output [3:0]   io_out_1_tx_dat_bits_opcode,
  output [2:0]   io_out_1_tx_dat_bits_resp,
  output [1:0]   io_out_1_tx_dat_bits_dataID,
  output [255:0] io_out_1_tx_dat_bits_data,
  output         io_out_1_rx_rsp_ready,
  input          io_out_1_rx_rsp_valid,
  input  [10:0]  io_out_1_rx_rsp_bits_tgtID,
  input  [10:0]  io_out_1_rx_rsp_bits_srcID,
  input  [11:0]  io_out_1_rx_rsp_bits_txnID,
  input  [4:0]   io_out_1_rx_rsp_bits_opcode,
  input  [2:0]   io_out_1_rx_rsp_bits_resp,
  input  [2:0]   io_out_1_rx_rsp_bits_fwdState,
  input  [11:0]  io_out_1_rx_rsp_bits_dbID,
  input  [3:0]   io_out_1_rx_rsp_bits_pCrdType,
  output         io_out_1_rx_dat_ready,
  input          io_out_1_rx_dat_valid,
  input  [10:0]  io_out_1_rx_dat_bits_tgtID,
  input  [10:0]  io_out_1_rx_dat_bits_srcID,
  input  [11:0]  io_out_1_rx_dat_bits_txnID,
  input  [10:0]  io_out_1_rx_dat_bits_homeNID,
  input  [3:0]   io_out_1_rx_dat_bits_opcode,
  input  [2:0]   io_out_1_rx_dat_bits_resp,
  input  [3:0]   io_out_1_rx_dat_bits_dataSource,
  input  [11:0]  io_out_1_rx_dat_bits_dbID,
  input  [1:0]   io_out_1_rx_dat_bits_dataID,
  input  [31:0]  io_out_1_rx_dat_bits_be,
  input  [255:0] io_out_1_rx_dat_bits_data,
  input  [31:0]  io_out_1_rx_dat_bits_dataCheck,
  output         io_out_1_rx_snp_ready,
  input          io_out_1_rx_snp_valid,
  input  [11:0]  io_out_1_rx_snp_bits_txnID,
  input  [10:0]  io_out_1_rx_snp_bits_fwdNID,
  input  [11:0]  io_out_1_rx_snp_bits_fwdTxnID,
  input  [4:0]   io_out_1_rx_snp_bits_opcode,
  input  [44:0]  io_out_1_rx_snp_bits_addr,
  input          io_out_1_rx_snp_bits_doNotGoToSD,
  input          io_out_1_rx_snp_bits_retToSrc,
  input          io_out_2_tx_req_ready,
  output         io_out_2_tx_req_valid,
  output [10:0]  io_out_2_tx_req_bits_tgtID,
  output [10:0]  io_out_2_tx_req_bits_srcID,
  output [11:0]  io_out_2_tx_req_bits_txnID,
  output [6:0]   io_out_2_tx_req_bits_opcode,
  output [2:0]   io_out_2_tx_req_bits_size,
  output [47:0]  io_out_2_tx_req_bits_addr,
  output         io_out_2_tx_req_bits_allowRetry,
  output [1:0]   io_out_2_tx_req_bits_order,
  output [3:0]   io_out_2_tx_req_bits_pCrdType,
  output         io_out_2_tx_req_bits_memAttr_allocate,
  output         io_out_2_tx_req_bits_memAttr_cacheable,
  output         io_out_2_tx_req_bits_memAttr_device,
  output         io_out_2_tx_req_bits_memAttr_ewa,
  output         io_out_2_tx_req_bits_snpAttr,
  output         io_out_2_tx_req_bits_expCompAck,
  output         io_out_2_tx_rsp_valid,
  output [10:0]  io_out_2_tx_rsp_bits_srcID,
  output [11:0]  io_out_2_tx_rsp_bits_txnID,
  output [4:0]   io_out_2_tx_rsp_bits_opcode,
  output [11:0]  io_out_2_tx_rsp_bits_dbID,
  output         io_out_2_tx_dat_valid,
  output [10:0]  io_out_2_tx_dat_bits_srcID,
  output [11:0]  io_out_2_tx_dat_bits_txnID,
  output [3:0]   io_out_2_tx_dat_bits_opcode,
  output [2:0]   io_out_2_tx_dat_bits_resp,
  output [1:0]   io_out_2_tx_dat_bits_dataID,
  output [255:0] io_out_2_tx_dat_bits_data,
  output         io_out_2_rx_rsp_ready,
  input          io_out_2_rx_rsp_valid,
  input  [10:0]  io_out_2_rx_rsp_bits_tgtID,
  input  [10:0]  io_out_2_rx_rsp_bits_srcID,
  input  [11:0]  io_out_2_rx_rsp_bits_txnID,
  input  [4:0]   io_out_2_rx_rsp_bits_opcode,
  input  [2:0]   io_out_2_rx_rsp_bits_resp,
  input  [2:0]   io_out_2_rx_rsp_bits_fwdState,
  input  [11:0]  io_out_2_rx_rsp_bits_dbID,
  input  [3:0]   io_out_2_rx_rsp_bits_pCrdType,
  output         io_out_2_rx_dat_ready,
  input          io_out_2_rx_dat_valid,
  input  [10:0]  io_out_2_rx_dat_bits_tgtID,
  input  [10:0]  io_out_2_rx_dat_bits_srcID,
  input  [11:0]  io_out_2_rx_dat_bits_txnID,
  input  [10:0]  io_out_2_rx_dat_bits_homeNID,
  input  [3:0]   io_out_2_rx_dat_bits_opcode,
  input  [2:0]   io_out_2_rx_dat_bits_resp,
  input  [3:0]   io_out_2_rx_dat_bits_dataSource,
  input  [11:0]  io_out_2_rx_dat_bits_dbID,
  input  [1:0]   io_out_2_rx_dat_bits_dataID,
  input  [31:0]  io_out_2_rx_dat_bits_be,
  input  [255:0] io_out_2_rx_dat_bits_data,
  input  [31:0]  io_out_2_rx_dat_bits_dataCheck,
  output         io_out_2_rx_snp_ready,
  input          io_out_2_rx_snp_valid,
  input  [11:0]  io_out_2_rx_snp_bits_txnID,
  input  [10:0]  io_out_2_rx_snp_bits_fwdNID,
  input  [11:0]  io_out_2_rx_snp_bits_fwdTxnID,
  input  [4:0]   io_out_2_rx_snp_bits_opcode,
  input  [44:0]  io_out_2_rx_snp_bits_addr,
  input          io_out_2_rx_snp_bits_doNotGoToSD,
  input          io_out_2_rx_snp_bits_retToSrc,
  input          io_out_3_tx_req_ready,
  output         io_out_3_tx_req_valid,
  output [10:0]  io_out_3_tx_req_bits_tgtID,
  output [10:0]  io_out_3_tx_req_bits_srcID,
  output [11:0]  io_out_3_tx_req_bits_txnID,
  output [6:0]   io_out_3_tx_req_bits_opcode,
  output [2:0]   io_out_3_tx_req_bits_size,
  output [47:0]  io_out_3_tx_req_bits_addr,
  output         io_out_3_tx_req_bits_allowRetry,
  output [1:0]   io_out_3_tx_req_bits_order,
  output [3:0]   io_out_3_tx_req_bits_pCrdType,
  output         io_out_3_tx_req_bits_memAttr_allocate,
  output         io_out_3_tx_req_bits_memAttr_cacheable,
  output         io_out_3_tx_req_bits_memAttr_device,
  output         io_out_3_tx_req_bits_memAttr_ewa,
  output         io_out_3_tx_req_bits_snpAttr,
  output         io_out_3_tx_req_bits_expCompAck,
  output         io_out_3_tx_rsp_valid,
  output [10:0]  io_out_3_tx_rsp_bits_srcID,
  output [11:0]  io_out_3_tx_rsp_bits_txnID,
  output [4:0]   io_out_3_tx_rsp_bits_opcode,
  output [11:0]  io_out_3_tx_rsp_bits_dbID,
  output         io_out_3_tx_dat_valid,
  output [10:0]  io_out_3_tx_dat_bits_srcID,
  output [11:0]  io_out_3_tx_dat_bits_txnID,
  output [3:0]   io_out_3_tx_dat_bits_opcode,
  output [2:0]   io_out_3_tx_dat_bits_resp,
  output [1:0]   io_out_3_tx_dat_bits_dataID,
  output [255:0] io_out_3_tx_dat_bits_data,
  output         io_out_3_rx_rsp_ready,
  input          io_out_3_rx_rsp_valid,
  input  [10:0]  io_out_3_rx_rsp_bits_tgtID,
  input  [10:0]  io_out_3_rx_rsp_bits_srcID,
  input  [11:0]  io_out_3_rx_rsp_bits_txnID,
  input  [4:0]   io_out_3_rx_rsp_bits_opcode,
  input  [2:0]   io_out_3_rx_rsp_bits_resp,
  input  [2:0]   io_out_3_rx_rsp_bits_fwdState,
  input  [11:0]  io_out_3_rx_rsp_bits_dbID,
  input  [3:0]   io_out_3_rx_rsp_bits_pCrdType,
  output         io_out_3_rx_dat_ready,
  input          io_out_3_rx_dat_valid,
  input  [10:0]  io_out_3_rx_dat_bits_tgtID,
  input  [10:0]  io_out_3_rx_dat_bits_srcID,
  input  [11:0]  io_out_3_rx_dat_bits_txnID,
  input  [10:0]  io_out_3_rx_dat_bits_homeNID,
  input  [3:0]   io_out_3_rx_dat_bits_opcode,
  input  [2:0]   io_out_3_rx_dat_bits_resp,
  input  [3:0]   io_out_3_rx_dat_bits_dataSource,
  input  [11:0]  io_out_3_rx_dat_bits_dbID,
  input  [1:0]   io_out_3_rx_dat_bits_dataID,
  input  [31:0]  io_out_3_rx_dat_bits_be,
  input  [255:0] io_out_3_rx_dat_bits_data,
  input  [31:0]  io_out_3_rx_dat_bits_dataCheck,
  output         io_out_3_rx_snp_ready,
  input          io_out_3_rx_snp_valid,
  input  [11:0]  io_out_3_rx_snp_bits_txnID,
  input  [10:0]  io_out_3_rx_snp_bits_fwdNID,
  input  [11:0]  io_out_3_rx_snp_bits_fwdTxnID,
  input  [4:0]   io_out_3_rx_snp_bits_opcode,
  input  [44:0]  io_out_3_rx_snp_bits_addr,
  input          io_out_3_rx_snp_bits_doNotGoToSD,
  input          io_out_3_rx_snp_bits_retToSrc,
  input          io_snp_mask_set_0,
  input          io_snp_mask_set_1,
  input          io_snp_mask_set_2,
  input          io_snp_mask_set_3
);

  // ===========================================================================
  //  上行 TX: 把 RN (io_in_0) 的 TXREQ / TXRSP / TXDAT flit 打包成结构体, 喂给
  //  各 bank 的仲裁器。结构体字段顺序同 CHI 上游 bundle。
  // ===========================================================================
  rn_req_t in_tx_req;
  rn_rsp_t in_tx_rsp;
  rn_dat_t in_tx_dat;
  assign in_tx_req = '{
    qos: io_in_0_tx_req_bits_qos, tgtID: io_in_0_tx_req_bits_tgtID,
    srcID: io_in_0_tx_req_bits_srcID, txnID: io_in_0_tx_req_bits_txnID,
    returnNID: io_in_0_tx_req_bits_returnNID,
    stashNIDValid: io_in_0_tx_req_bits_stashNIDValid,
    returnTxnID: io_in_0_tx_req_bits_returnTxnID, opcode: io_in_0_tx_req_bits_opcode,
    size: io_in_0_tx_req_bits_size, addr: io_in_0_tx_req_bits_addr,
    ns: io_in_0_tx_req_bits_ns, likelyshared: io_in_0_tx_req_bits_likelyshared,
    allowRetry: io_in_0_tx_req_bits_allowRetry, order: io_in_0_tx_req_bits_order,
    pCrdType: io_in_0_tx_req_bits_pCrdType,
    memAttr_allocate: io_in_0_tx_req_bits_memAttr_allocate,
    memAttr_cacheable: io_in_0_tx_req_bits_memAttr_cacheable,
    memAttr_device: io_in_0_tx_req_bits_memAttr_device,
    memAttr_ewa: io_in_0_tx_req_bits_memAttr_ewa,
    snpAttr: io_in_0_tx_req_bits_snpAttr,
    lpIDWithPadding: io_in_0_tx_req_bits_lpIDWithPadding,
    snoopMe: io_in_0_tx_req_bits_snoopMe, expCompAck: io_in_0_tx_req_bits_expCompAck,
    tagOp: io_in_0_tx_req_bits_tagOp, traceTag: io_in_0_tx_req_bits_traceTag,
    mpam_perfMonGroup: io_in_0_tx_req_bits_mpam_perfMonGroup,
    mpam_partID: io_in_0_tx_req_bits_mpam_partID,
    mpam_mpamNS: io_in_0_tx_req_bits_mpam_mpamNS, rsvdc: io_in_0_tx_req_bits_rsvdc};
  assign in_tx_rsp = '{
    srcID: io_in_0_tx_rsp_bits_srcID, txnID: io_in_0_tx_rsp_bits_txnID,
    opcode: io_in_0_tx_rsp_bits_opcode, dbID: io_in_0_tx_rsp_bits_dbID};
  assign in_tx_dat = '{
    qos: io_in_0_tx_dat_bits_qos, tgtID: io_in_0_tx_dat_bits_tgtID,
    srcID: io_in_0_tx_dat_bits_srcID, txnID: io_in_0_tx_dat_bits_txnID,
    homeNID: io_in_0_tx_dat_bits_homeNID, opcode: io_in_0_tx_dat_bits_opcode,
    respErr: io_in_0_tx_dat_bits_respErr, resp: io_in_0_tx_dat_bits_resp,
    dataSource: io_in_0_tx_dat_bits_dataSource, cBusy: io_in_0_tx_dat_bits_cBusy,
    dbID: io_in_0_tx_dat_bits_dbID, ccID: io_in_0_tx_dat_bits_ccID,
    dataID: io_in_0_tx_dat_bits_dataID, tagOp: io_in_0_tx_dat_bits_tagOp,
    tag: io_in_0_tx_dat_bits_tag, tu: io_in_0_tx_dat_bits_tu,
    traceTag: io_in_0_tx_dat_bits_traceTag, rsvdc: io_in_0_tx_dat_bits_rsvdc,
    be: io_in_0_tx_dat_bits_be, data: io_in_0_tx_dat_bits_data,
    dataCheck: io_in_0_tx_dat_bits_dataCheck, poison: io_in_0_tx_dat_bits_poison};

  // 路由位: REQ 按地址 bank 交织位, RSP/DAT 按事务 ID 高位。
  wire [1:0] txreq_sel = route_req(in_tx_req.addr);
  wire [1:0] txrsp_sel = route_txnid(in_tx_rsp.txnID);
  wire [1:0] txdat_sel = route_txnid(in_tx_dat.txnID);

  // 各 bank 仲裁器输出 valid (打包成位向量) 与全字段输出载荷 (仅部分扇出到 HN 端口)。
  logic [NUM_HN-1:0] txreq_out_valid;
  logic [NUM_HN-1:0] txrsp_out_valid;
  logic [NUM_HN-1:0] txdat_out_valid;
  rn_req_t txreq_arb_out [NUM_HN];
  rn_rsp_t txrsp_arb_out [NUM_HN];
  rn_dat_t txdat_arb_out [NUM_HN];

  // ---- TXREQ: 4 个单输入 FastArbiter_30, 输入由 route_req 门控到目标 bank ----
  for (genvar j = 0; j < NUM_HN; j++) begin : g_txreq
    FastArbiter_30 txreqArbs (
      .io_in_0_valid (io_in_0_tx_req_valid & (txreq_sel == 2'(j))),
      .io_in_0_bits_qos (in_tx_req.qos),
      .io_in_0_bits_tgtID (in_tx_req.tgtID),
      .io_in_0_bits_srcID (in_tx_req.srcID),
      .io_in_0_bits_txnID (in_tx_req.txnID),
      .io_in_0_bits_returnNID (in_tx_req.returnNID),
      .io_in_0_bits_stashNIDValid (in_tx_req.stashNIDValid),
      .io_in_0_bits_returnTxnID (in_tx_req.returnTxnID),
      .io_in_0_bits_opcode (in_tx_req.opcode),
      .io_in_0_bits_size (in_tx_req.size),
      .io_in_0_bits_addr (in_tx_req.addr),
      .io_in_0_bits_ns (in_tx_req.ns),
      .io_in_0_bits_likelyshared (in_tx_req.likelyshared),
      .io_in_0_bits_allowRetry (in_tx_req.allowRetry),
      .io_in_0_bits_order (in_tx_req.order),
      .io_in_0_bits_pCrdType (in_tx_req.pCrdType),
      .io_in_0_bits_memAttr_allocate (in_tx_req.memAttr_allocate),
      .io_in_0_bits_memAttr_cacheable (in_tx_req.memAttr_cacheable),
      .io_in_0_bits_memAttr_device (in_tx_req.memAttr_device),
      .io_in_0_bits_memAttr_ewa (in_tx_req.memAttr_ewa),
      .io_in_0_bits_snpAttr (in_tx_req.snpAttr),
      .io_in_0_bits_lpIDWithPadding (in_tx_req.lpIDWithPadding),
      .io_in_0_bits_snoopMe (in_tx_req.snoopMe),
      .io_in_0_bits_expCompAck (in_tx_req.expCompAck),
      .io_in_0_bits_tagOp (in_tx_req.tagOp),
      .io_in_0_bits_traceTag (in_tx_req.traceTag),
      .io_in_0_bits_mpam_perfMonGroup (in_tx_req.mpam_perfMonGroup),
      .io_in_0_bits_mpam_partID (in_tx_req.mpam_partID),
      .io_in_0_bits_mpam_mpamNS (in_tx_req.mpam_mpamNS),
      .io_in_0_bits_rsvdc (in_tx_req.rsvdc),
      .io_out_valid (txreq_out_valid[j]),
      .io_out_bits_qos (txreq_arb_out[j].qos),
      .io_out_bits_tgtID (txreq_arb_out[j].tgtID),
      .io_out_bits_srcID (txreq_arb_out[j].srcID),
      .io_out_bits_txnID (txreq_arb_out[j].txnID),
      .io_out_bits_returnNID (txreq_arb_out[j].returnNID),
      .io_out_bits_stashNIDValid (txreq_arb_out[j].stashNIDValid),
      .io_out_bits_returnTxnID (txreq_arb_out[j].returnTxnID),
      .io_out_bits_opcode (txreq_arb_out[j].opcode),
      .io_out_bits_size (txreq_arb_out[j].size),
      .io_out_bits_addr (txreq_arb_out[j].addr),
      .io_out_bits_ns (txreq_arb_out[j].ns),
      .io_out_bits_likelyshared (txreq_arb_out[j].likelyshared),
      .io_out_bits_allowRetry (txreq_arb_out[j].allowRetry),
      .io_out_bits_order (txreq_arb_out[j].order),
      .io_out_bits_pCrdType (txreq_arb_out[j].pCrdType),
      .io_out_bits_memAttr_allocate (txreq_arb_out[j].memAttr_allocate),
      .io_out_bits_memAttr_cacheable (txreq_arb_out[j].memAttr_cacheable),
      .io_out_bits_memAttr_device (txreq_arb_out[j].memAttr_device),
      .io_out_bits_memAttr_ewa (txreq_arb_out[j].memAttr_ewa),
      .io_out_bits_snpAttr (txreq_arb_out[j].snpAttr),
      .io_out_bits_lpIDWithPadding (txreq_arb_out[j].lpIDWithPadding),
      .io_out_bits_snoopMe (txreq_arb_out[j].snoopMe),
      .io_out_bits_expCompAck (txreq_arb_out[j].expCompAck),
      .io_out_bits_tagOp (txreq_arb_out[j].tagOp),
      .io_out_bits_traceTag (txreq_arb_out[j].traceTag),
      .io_out_bits_mpam_perfMonGroup (txreq_arb_out[j].mpam_perfMonGroup),
      .io_out_bits_mpam_partID (txreq_arb_out[j].mpam_partID),
      .io_out_bits_mpam_mpamNS (txreq_arb_out[j].mpam_mpamNS),
      .io_out_bits_rsvdc (txreq_arb_out[j].rsvdc)
    );
  end

  // ---- TXRSP: 4 个单输入 FastArbiter_36, 输入由 route_txnid 门控到目标 bank ----
  for (genvar j = 0; j < NUM_HN; j++) begin : g_txrsp
    FastArbiter_36 txrspArbs (
      .io_in_0_valid (io_in_0_tx_rsp_valid & (txrsp_sel == 2'(j))),
      .io_in_0_bits_srcID (in_tx_rsp.srcID),
      .io_in_0_bits_txnID (in_tx_rsp.txnID),
      .io_in_0_bits_opcode (in_tx_rsp.opcode),
      .io_in_0_bits_dbID (in_tx_rsp.dbID),
      .io_out_valid (txrsp_out_valid[j]),
      .io_out_bits_srcID (txrsp_arb_out[j].srcID),
      .io_out_bits_txnID (txrsp_arb_out[j].txnID),
      .io_out_bits_opcode (txrsp_arb_out[j].opcode),
      .io_out_bits_dbID (txrsp_arb_out[j].dbID)
    );
  end

  // ---- TXDAT: 4 个单输入 FastArbiter_31, 输入由 route_txnid 门控到目标 bank ----
  for (genvar j = 0; j < NUM_HN; j++) begin : g_txdat
    FastArbiter_31 txdatArbs (
      .io_in_0_valid (io_in_0_tx_dat_valid & (txdat_sel == 2'(j))),
      .io_in_0_bits_qos (in_tx_dat.qos),
      .io_in_0_bits_tgtID (in_tx_dat.tgtID),
      .io_in_0_bits_srcID (in_tx_dat.srcID),
      .io_in_0_bits_txnID (in_tx_dat.txnID),
      .io_in_0_bits_homeNID (in_tx_dat.homeNID),
      .io_in_0_bits_opcode (in_tx_dat.opcode),
      .io_in_0_bits_respErr (in_tx_dat.respErr),
      .io_in_0_bits_resp (in_tx_dat.resp),
      .io_in_0_bits_dataSource (in_tx_dat.dataSource),
      .io_in_0_bits_cBusy (in_tx_dat.cBusy),
      .io_in_0_bits_dbID (in_tx_dat.dbID),
      .io_in_0_bits_ccID (in_tx_dat.ccID),
      .io_in_0_bits_dataID (in_tx_dat.dataID),
      .io_in_0_bits_tagOp (in_tx_dat.tagOp),
      .io_in_0_bits_tag (in_tx_dat.tag),
      .io_in_0_bits_tu (in_tx_dat.tu),
      .io_in_0_bits_traceTag (in_tx_dat.traceTag),
      .io_in_0_bits_rsvdc (in_tx_dat.rsvdc),
      .io_in_0_bits_be (in_tx_dat.be),
      .io_in_0_bits_data (in_tx_dat.data),
      .io_in_0_bits_dataCheck (in_tx_dat.dataCheck),
      .io_in_0_bits_poison (in_tx_dat.poison),
      .io_out_valid (txdat_out_valid[j]),
      .io_out_bits_qos (txdat_arb_out[j].qos),
      .io_out_bits_tgtID (txdat_arb_out[j].tgtID),
      .io_out_bits_srcID (txdat_arb_out[j].srcID),
      .io_out_bits_txnID (txdat_arb_out[j].txnID),
      .io_out_bits_homeNID (txdat_arb_out[j].homeNID),
      .io_out_bits_opcode (txdat_arb_out[j].opcode),
      .io_out_bits_respErr (txdat_arb_out[j].respErr),
      .io_out_bits_resp (txdat_arb_out[j].resp),
      .io_out_bits_dataSource (txdat_arb_out[j].dataSource),
      .io_out_bits_cBusy (txdat_arb_out[j].cBusy),
      .io_out_bits_dbID (txdat_arb_out[j].dbID),
      .io_out_bits_ccID (txdat_arb_out[j].ccID),
      .io_out_bits_dataID (txdat_arb_out[j].dataID),
      .io_out_bits_tagOp (txdat_arb_out[j].tagOp),
      .io_out_bits_tag (txdat_arb_out[j].tag),
      .io_out_bits_tu (txdat_arb_out[j].tu),
      .io_out_bits_traceTag (txdat_arb_out[j].traceTag),
      .io_out_bits_rsvdc (txdat_arb_out[j].rsvdc),
      .io_out_bits_be (txdat_arb_out[j].be),
      .io_out_bits_data (txdat_arb_out[j].data),
      .io_out_bits_dataCheck (txdat_arb_out[j].dataCheck),
      .io_out_bits_poison (txdat_arb_out[j].poison)
    );
  end
  // ===========================================================================
  //  下行 RX —— snoop 跟踪状态机 (本核相对 SNXbar 的核心增量)
  //  每 HN bank 一个 1 深 snoop 槽: snpReqs_j 锁存载荷 + 粘滞 valid, snpMasks_j 为
  //  挂起位。寄存器沿用 golden 展平命名 (非 io_ 前缀, 不触发命名闸门) 以便 FM 按名配对。
  // ===========================================================================
  reg        snpMasks_0_0;
  reg        snpMasks_1_0;
  reg        snpMasks_2_0;
  reg        snpMasks_3_0;

  reg        snpReqs_0_valid;
  reg [11:0] snpReqs_0_bits_txnID;
  reg [10:0] snpReqs_0_bits_fwdNID;
  reg [11:0] snpReqs_0_bits_fwdTxnID;
  reg [4:0] snpReqs_0_bits_opcode;
  reg [44:0] snpReqs_0_bits_addr;
  reg        snpReqs_0_bits_doNotGoToSD;
  reg        snpReqs_0_bits_retToSrc;
  reg        snpReqs_1_valid;
  reg [11:0] snpReqs_1_bits_txnID;
  reg [10:0] snpReqs_1_bits_fwdNID;
  reg [11:0] snpReqs_1_bits_fwdTxnID;
  reg [4:0] snpReqs_1_bits_opcode;
  reg [44:0] snpReqs_1_bits_addr;
  reg        snpReqs_1_bits_doNotGoToSD;
  reg        snpReqs_1_bits_retToSrc;
  reg        snpReqs_2_valid;
  reg [11:0] snpReqs_2_bits_txnID;
  reg [10:0] snpReqs_2_bits_fwdNID;
  reg [11:0] snpReqs_2_bits_fwdTxnID;
  reg [4:0] snpReqs_2_bits_opcode;
  reg [44:0] snpReqs_2_bits_addr;
  reg        snpReqs_2_bits_doNotGoToSD;
  reg        snpReqs_2_bits_retToSrc;
  reg        snpReqs_3_valid;
  reg [11:0] snpReqs_3_bits_txnID;
  reg [10:0] snpReqs_3_bits_fwdNID;
  reg [11:0] snpReqs_3_bits_fwdTxnID;
  reg [4:0] snpReqs_3_bits_opcode;
  reg [44:0] snpReqs_3_bits_addr;
  reg        snpReqs_3_bits_doNotGoToSD;
  reg        snpReqs_3_bits_retToSrc;

  // 读视图: 把分立寄存器汇聚成按 bank 索引的数组, 供组合逻辑与仲裁器例化引用。
  snp_t snp_req_bits  [NUM_HN];
  wire  snp_req_valid [NUM_HN];
  wire  snp_pending   [NUM_HN];   // = snpMasks_j (单 RN, 1 位)
  assign snp_req_bits[0]  = '{txnID: snpReqs_0_bits_txnID, fwdNID: snpReqs_0_bits_fwdNID, fwdTxnID: snpReqs_0_bits_fwdTxnID, opcode: snpReqs_0_bits_opcode, addr: snpReqs_0_bits_addr, doNotGoToSD: snpReqs_0_bits_doNotGoToSD, retToSrc: snpReqs_0_bits_retToSrc};
  assign snp_req_valid[0] = snpReqs_0_valid;
  assign snp_pending[0]   = snpMasks_0_0;
  assign snp_req_bits[1]  = '{txnID: snpReqs_1_bits_txnID, fwdNID: snpReqs_1_bits_fwdNID, fwdTxnID: snpReqs_1_bits_fwdTxnID, opcode: snpReqs_1_bits_opcode, addr: snpReqs_1_bits_addr, doNotGoToSD: snpReqs_1_bits_doNotGoToSD, retToSrc: snpReqs_1_bits_retToSrc};
  assign snp_req_valid[1] = snpReqs_1_valid;
  assign snp_pending[1]   = snpMasks_1_0;
  assign snp_req_bits[2]  = '{txnID: snpReqs_2_bits_txnID, fwdNID: snpReqs_2_bits_fwdNID, fwdTxnID: snpReqs_2_bits_fwdTxnID, opcode: snpReqs_2_bits_opcode, addr: snpReqs_2_bits_addr, doNotGoToSD: snpReqs_2_bits_doNotGoToSD, retToSrc: snpReqs_2_bits_retToSrc};
  assign snp_req_valid[2] = snpReqs_2_valid;
  assign snp_pending[2]   = snpMasks_2_0;
  assign snp_req_bits[3]  = '{txnID: snpReqs_3_bits_txnID, fwdNID: snpReqs_3_bits_fwdNID, fwdTxnID: snpReqs_3_bits_fwdTxnID, opcode: snpReqs_3_bits_opcode, addr: snpReqs_3_bits_addr, doNotGoToSD: snpReqs_3_bits_doNotGoToSD, retToSrc: snpReqs_3_bits_retToSrc};
  assign snp_req_valid[3] = snpReqs_3_valid;
  assign snp_pending[3]   = snpMasks_3_0;

  // 各 HN bank 进来的 snoop 载荷 / valid。
  snp_t snp_in_bits  [NUM_HN];
  wire  snp_in_valid [NUM_HN];
  assign snp_in_bits[0]  = '{txnID: io_out_0_rx_snp_bits_txnID, fwdNID: io_out_0_rx_snp_bits_fwdNID, fwdTxnID: io_out_0_rx_snp_bits_fwdTxnID, opcode: io_out_0_rx_snp_bits_opcode, addr: io_out_0_rx_snp_bits_addr, doNotGoToSD: io_out_0_rx_snp_bits_doNotGoToSD, retToSrc: io_out_0_rx_snp_bits_retToSrc};
  assign snp_in_valid[0] = io_out_0_rx_snp_valid;
  assign snp_in_bits[1]  = '{txnID: io_out_1_rx_snp_bits_txnID, fwdNID: io_out_1_rx_snp_bits_fwdNID, fwdTxnID: io_out_1_rx_snp_bits_fwdTxnID, opcode: io_out_1_rx_snp_bits_opcode, addr: io_out_1_rx_snp_bits_addr, doNotGoToSD: io_out_1_rx_snp_bits_doNotGoToSD, retToSrc: io_out_1_rx_snp_bits_retToSrc};
  assign snp_in_valid[1] = io_out_1_rx_snp_valid;
  assign snp_in_bits[2]  = '{txnID: io_out_2_rx_snp_bits_txnID, fwdNID: io_out_2_rx_snp_bits_fwdNID, fwdTxnID: io_out_2_rx_snp_bits_fwdTxnID, opcode: io_out_2_rx_snp_bits_opcode, addr: io_out_2_rx_snp_bits_addr, doNotGoToSD: io_out_2_rx_snp_bits_doNotGoToSD, retToSrc: io_out_2_rx_snp_bits_retToSrc};
  assign snp_in_valid[2] = io_out_2_rx_snp_valid;
  assign snp_in_bits[3]  = '{txnID: io_out_3_rx_snp_bits_txnID, fwdNID: io_out_3_rx_snp_bits_fwdNID, fwdTxnID: io_out_3_rx_snp_bits_fwdTxnID, opcode: io_out_3_rx_snp_bits_opcode, addr: io_out_3_rx_snp_bits_addr, doNotGoToSD: io_out_3_rx_snp_bits_doNotGoToSD, retToSrc: io_out_3_rx_snp_bits_retToSrc};
  assign snp_in_valid[3] = io_out_3_rx_snp_valid;

  wire       rxsnp_out_valid;
  wire [1:0] rxsnp_chosen;
  // 合并 snoop 输出握手: RN 这一拍取走仲裁后的 snoop。
  wire snp_deliver_fire = io_in_0_rx_snp_ready & rxsnp_out_valid;
  logic snp_mask_next [NUM_HN];  // 不接收新 snoop 时下一拍挂起位 (取走则清)
  logic snp_in_ready  [NUM_HN];  // 回送给 HN bank 的 rx_snp_ready (1 深槽背压)
  logic snp_accept    [NUM_HN];  // 本拍从 HN bank 接收新 snoop 进槽
  for (genvar j = 0; j < NUM_HN; j++) begin : g_snp_track
    assign snp_mask_next[j] = ~(snp_deliver_fire & (rxsnp_chosen == 2'(j))) & snp_pending[j];
    assign snp_in_ready[j]  = (snp_req_valid[j] & ~snp_mask_next[j]) | ~snp_pending[j];
    assign snp_accept[j]    = snp_in_ready[j] & snp_in_valid[j];
  end

  // 时序: 接收新 snoop 则锁存载荷并把挂起位置为外部掩码 io_snp_mask_set_j; 否则
  // 按 snp_mask_next 演进 (被 RN 取走则清挂起)。valid 为粘滞位。复位全清 (X 铁律)。
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      snpMasks_0_0 <= 1'h0;
      snpMasks_1_0 <= 1'h0;
      snpMasks_2_0 <= 1'h0;
      snpMasks_3_0 <= 1'h0;
      snpReqs_0_valid <= 1'h0;
      snpReqs_0_bits_txnID <= 12'h0;
      snpReqs_0_bits_fwdNID <= 11'h0;
      snpReqs_0_bits_fwdTxnID <= 12'h0;
      snpReqs_0_bits_opcode <= 5'h0;
      snpReqs_0_bits_addr <= 45'h0;
      snpReqs_0_bits_doNotGoToSD <= 1'h0;
      snpReqs_0_bits_retToSrc <= 1'h0;
      snpReqs_1_valid <= 1'h0;
      snpReqs_1_bits_txnID <= 12'h0;
      snpReqs_1_bits_fwdNID <= 11'h0;
      snpReqs_1_bits_fwdTxnID <= 12'h0;
      snpReqs_1_bits_opcode <= 5'h0;
      snpReqs_1_bits_addr <= 45'h0;
      snpReqs_1_bits_doNotGoToSD <= 1'h0;
      snpReqs_1_bits_retToSrc <= 1'h0;
      snpReqs_2_valid <= 1'h0;
      snpReqs_2_bits_txnID <= 12'h0;
      snpReqs_2_bits_fwdNID <= 11'h0;
      snpReqs_2_bits_fwdTxnID <= 12'h0;
      snpReqs_2_bits_opcode <= 5'h0;
      snpReqs_2_bits_addr <= 45'h0;
      snpReqs_2_bits_doNotGoToSD <= 1'h0;
      snpReqs_2_bits_retToSrc <= 1'h0;
      snpReqs_3_valid <= 1'h0;
      snpReqs_3_bits_txnID <= 12'h0;
      snpReqs_3_bits_fwdNID <= 11'h0;
      snpReqs_3_bits_fwdTxnID <= 12'h0;
      snpReqs_3_bits_opcode <= 5'h0;
      snpReqs_3_bits_addr <= 45'h0;
      snpReqs_3_bits_doNotGoToSD <= 1'h0;
      snpReqs_3_bits_retToSrc <= 1'h0;
    end
    else begin
      // ---- HN bank 0 ----
      if (snp_accept[0]) begin
        snpMasks_0_0 <= io_snp_mask_set_0;
        snpReqs_0_bits_txnID <= snp_in_bits[0].txnID;
        snpReqs_0_bits_fwdNID <= snp_in_bits[0].fwdNID;
        snpReqs_0_bits_fwdTxnID <= snp_in_bits[0].fwdTxnID;
        snpReqs_0_bits_opcode <= snp_in_bits[0].opcode;
        snpReqs_0_bits_addr <= snp_in_bits[0].addr;
        snpReqs_0_bits_doNotGoToSD <= snp_in_bits[0].doNotGoToSD;
        snpReqs_0_bits_retToSrc <= snp_in_bits[0].retToSrc;
      end
      else
        snpMasks_0_0 <= snp_mask_next[0];
      snpReqs_0_valid <= snp_accept[0] | snpReqs_0_valid;
      // ---- HN bank 1 ----
      if (snp_accept[1]) begin
        snpMasks_1_0 <= io_snp_mask_set_1;
        snpReqs_1_bits_txnID <= snp_in_bits[1].txnID;
        snpReqs_1_bits_fwdNID <= snp_in_bits[1].fwdNID;
        snpReqs_1_bits_fwdTxnID <= snp_in_bits[1].fwdTxnID;
        snpReqs_1_bits_opcode <= snp_in_bits[1].opcode;
        snpReqs_1_bits_addr <= snp_in_bits[1].addr;
        snpReqs_1_bits_doNotGoToSD <= snp_in_bits[1].doNotGoToSD;
        snpReqs_1_bits_retToSrc <= snp_in_bits[1].retToSrc;
      end
      else
        snpMasks_1_0 <= snp_mask_next[1];
      snpReqs_1_valid <= snp_accept[1] | snpReqs_1_valid;
      // ---- HN bank 2 ----
      if (snp_accept[2]) begin
        snpMasks_2_0 <= io_snp_mask_set_2;
        snpReqs_2_bits_txnID <= snp_in_bits[2].txnID;
        snpReqs_2_bits_fwdNID <= snp_in_bits[2].fwdNID;
        snpReqs_2_bits_fwdTxnID <= snp_in_bits[2].fwdTxnID;
        snpReqs_2_bits_opcode <= snp_in_bits[2].opcode;
        snpReqs_2_bits_addr <= snp_in_bits[2].addr;
        snpReqs_2_bits_doNotGoToSD <= snp_in_bits[2].doNotGoToSD;
        snpReqs_2_bits_retToSrc <= snp_in_bits[2].retToSrc;
      end
      else
        snpMasks_2_0 <= snp_mask_next[2];
      snpReqs_2_valid <= snp_accept[2] | snpReqs_2_valid;
      // ---- HN bank 3 ----
      if (snp_accept[3]) begin
        snpMasks_3_0 <= io_snp_mask_set_3;
        snpReqs_3_bits_txnID <= snp_in_bits[3].txnID;
        snpReqs_3_bits_fwdNID <= snp_in_bits[3].fwdNID;
        snpReqs_3_bits_fwdTxnID <= snp_in_bits[3].fwdTxnID;
        snpReqs_3_bits_opcode <= snp_in_bits[3].opcode;
        snpReqs_3_bits_addr <= snp_in_bits[3].addr;
        snpReqs_3_bits_doNotGoToSD <= snp_in_bits[3].doNotGoToSD;
        snpReqs_3_bits_retToSrc <= snp_in_bits[3].retToSrc;
      end
      else
        snpMasks_3_0 <= snp_mask_next[3];
      snpReqs_3_valid <= snp_accept[3] | snpReqs_3_valid;
    end
  end

  // ---- RXSNP 仲裁器 (FastArbiter_44, 4 输入): 输入 = 挂起的快照 snoop ----
  FastArbiter_44 rxsnpArbs_0 (
    .clock (clock),
    .reset (reset),
    .io_in_0_valid (snp_req_valid[0] & snp_pending[0]),
    .io_in_0_bits_txnID (snp_req_bits[0].txnID),
    .io_in_0_bits_fwdNID (snp_req_bits[0].fwdNID),
    .io_in_0_bits_fwdTxnID (snp_req_bits[0].fwdTxnID),
    .io_in_0_bits_opcode (snp_req_bits[0].opcode),
    .io_in_0_bits_addr (snp_req_bits[0].addr),
    .io_in_0_bits_doNotGoToSD (snp_req_bits[0].doNotGoToSD),
    .io_in_0_bits_retToSrc (snp_req_bits[0].retToSrc),
    .io_in_1_valid (snp_req_valid[1] & snp_pending[1]),
    .io_in_1_bits_txnID (snp_req_bits[1].txnID),
    .io_in_1_bits_fwdNID (snp_req_bits[1].fwdNID),
    .io_in_1_bits_fwdTxnID (snp_req_bits[1].fwdTxnID),
    .io_in_1_bits_opcode (snp_req_bits[1].opcode),
    .io_in_1_bits_addr (snp_req_bits[1].addr),
    .io_in_1_bits_doNotGoToSD (snp_req_bits[1].doNotGoToSD),
    .io_in_1_bits_retToSrc (snp_req_bits[1].retToSrc),
    .io_in_2_valid (snp_req_valid[2] & snp_pending[2]),
    .io_in_2_bits_txnID (snp_req_bits[2].txnID),
    .io_in_2_bits_fwdNID (snp_req_bits[2].fwdNID),
    .io_in_2_bits_fwdTxnID (snp_req_bits[2].fwdTxnID),
    .io_in_2_bits_opcode (snp_req_bits[2].opcode),
    .io_in_2_bits_addr (snp_req_bits[2].addr),
    .io_in_2_bits_doNotGoToSD (snp_req_bits[2].doNotGoToSD),
    .io_in_2_bits_retToSrc (snp_req_bits[2].retToSrc),
    .io_in_3_valid (snp_req_valid[3] & snp_pending[3]),
    .io_in_3_bits_txnID (snp_req_bits[3].txnID),
    .io_in_3_bits_fwdNID (snp_req_bits[3].fwdNID),
    .io_in_3_bits_fwdTxnID (snp_req_bits[3].fwdTxnID),
    .io_in_3_bits_opcode (snp_req_bits[3].opcode),
    .io_in_3_bits_addr (snp_req_bits[3].addr),
    .io_in_3_bits_doNotGoToSD (snp_req_bits[3].doNotGoToSD),
    .io_in_3_bits_retToSrc (snp_req_bits[3].retToSrc),
    .io_out_ready (io_in_0_rx_snp_ready),
    .io_out_valid (rxsnp_out_valid),
    .io_out_bits_txnID (io_in_0_rx_snp_bits_txnID),
    .io_out_bits_fwdNID (io_in_0_rx_snp_bits_fwdNID),
    .io_out_bits_fwdTxnID (io_in_0_rx_snp_bits_fwdTxnID),
    .io_out_bits_opcode (io_in_0_rx_snp_bits_opcode),
    .io_out_bits_addr (io_in_0_rx_snp_bits_addr),
    .io_out_bits_doNotGoToSD (io_in_0_rx_snp_bits_doNotGoToSD),
    .io_out_bits_retToSrc (io_in_0_rx_snp_bits_retToSrc),
    .io_chosen (rxsnp_chosen)
  );

  // ===========================================================================
  //  下行 RX —— RXRSP / RXDAT (4 HN bank → 1 RN 仲裁汇聚)
  //  输入按 srcID==0 (目标 RN 编号) 门控; 仲裁器 io_chosen 决定 ready 回送哪个 bank。
  // ===========================================================================
  hn_rsp_t rxrsp_in_bits  [NUM_HN];
  wire     rxrsp_in_valid [NUM_HN];
  assign rxrsp_in_bits[0]  = '{tgtID: io_out_0_rx_rsp_bits_tgtID, txnID: io_out_0_rx_rsp_bits_txnID, opcode: io_out_0_rx_rsp_bits_opcode, resp: io_out_0_rx_rsp_bits_resp, fwdState: io_out_0_rx_rsp_bits_fwdState, dbID: io_out_0_rx_rsp_bits_dbID, pCrdType: io_out_0_rx_rsp_bits_pCrdType};
  assign rxrsp_in_valid[0] = io_out_0_rx_rsp_valid & (io_out_0_rx_rsp_bits_srcID == 11'h0);
  assign rxrsp_in_bits[1]  = '{tgtID: io_out_1_rx_rsp_bits_tgtID, txnID: io_out_1_rx_rsp_bits_txnID, opcode: io_out_1_rx_rsp_bits_opcode, resp: io_out_1_rx_rsp_bits_resp, fwdState: io_out_1_rx_rsp_bits_fwdState, dbID: io_out_1_rx_rsp_bits_dbID, pCrdType: io_out_1_rx_rsp_bits_pCrdType};
  assign rxrsp_in_valid[1] = io_out_1_rx_rsp_valid & (io_out_1_rx_rsp_bits_srcID == 11'h0);
  assign rxrsp_in_bits[2]  = '{tgtID: io_out_2_rx_rsp_bits_tgtID, txnID: io_out_2_rx_rsp_bits_txnID, opcode: io_out_2_rx_rsp_bits_opcode, resp: io_out_2_rx_rsp_bits_resp, fwdState: io_out_2_rx_rsp_bits_fwdState, dbID: io_out_2_rx_rsp_bits_dbID, pCrdType: io_out_2_rx_rsp_bits_pCrdType};
  assign rxrsp_in_valid[2] = io_out_2_rx_rsp_valid & (io_out_2_rx_rsp_bits_srcID == 11'h0);
  assign rxrsp_in_bits[3]  = '{tgtID: io_out_3_rx_rsp_bits_tgtID, txnID: io_out_3_rx_rsp_bits_txnID, opcode: io_out_3_rx_rsp_bits_opcode, resp: io_out_3_rx_rsp_bits_resp, fwdState: io_out_3_rx_rsp_bits_fwdState, dbID: io_out_3_rx_rsp_bits_dbID, pCrdType: io_out_3_rx_rsp_bits_pCrdType};
  assign rxrsp_in_valid[3] = io_out_3_rx_rsp_valid & (io_out_3_rx_rsp_bits_srcID == 11'h0);

  hn_dat_t rxdat_in_bits  [NUM_HN];
  wire     rxdat_in_valid [NUM_HN];
  assign rxdat_in_bits[0]  = '{tgtID: io_out_0_rx_dat_bits_tgtID, srcID: io_out_0_rx_dat_bits_srcID, txnID: io_out_0_rx_dat_bits_txnID, homeNID: io_out_0_rx_dat_bits_homeNID, opcode: io_out_0_rx_dat_bits_opcode, resp: io_out_0_rx_dat_bits_resp, dataSource: io_out_0_rx_dat_bits_dataSource, dbID: io_out_0_rx_dat_bits_dbID, dataID: io_out_0_rx_dat_bits_dataID, be: io_out_0_rx_dat_bits_be, data: io_out_0_rx_dat_bits_data, dataCheck: io_out_0_rx_dat_bits_dataCheck};
  assign rxdat_in_valid[0] = io_out_0_rx_dat_valid & (io_out_0_rx_dat_bits_srcID == 11'h0);
  assign rxdat_in_bits[1]  = '{tgtID: io_out_1_rx_dat_bits_tgtID, srcID: io_out_1_rx_dat_bits_srcID, txnID: io_out_1_rx_dat_bits_txnID, homeNID: io_out_1_rx_dat_bits_homeNID, opcode: io_out_1_rx_dat_bits_opcode, resp: io_out_1_rx_dat_bits_resp, dataSource: io_out_1_rx_dat_bits_dataSource, dbID: io_out_1_rx_dat_bits_dbID, dataID: io_out_1_rx_dat_bits_dataID, be: io_out_1_rx_dat_bits_be, data: io_out_1_rx_dat_bits_data, dataCheck: io_out_1_rx_dat_bits_dataCheck};
  assign rxdat_in_valid[1] = io_out_1_rx_dat_valid & (io_out_1_rx_dat_bits_srcID == 11'h0);
  assign rxdat_in_bits[2]  = '{tgtID: io_out_2_rx_dat_bits_tgtID, srcID: io_out_2_rx_dat_bits_srcID, txnID: io_out_2_rx_dat_bits_txnID, homeNID: io_out_2_rx_dat_bits_homeNID, opcode: io_out_2_rx_dat_bits_opcode, resp: io_out_2_rx_dat_bits_resp, dataSource: io_out_2_rx_dat_bits_dataSource, dbID: io_out_2_rx_dat_bits_dbID, dataID: io_out_2_rx_dat_bits_dataID, be: io_out_2_rx_dat_bits_be, data: io_out_2_rx_dat_bits_data, dataCheck: io_out_2_rx_dat_bits_dataCheck};
  assign rxdat_in_valid[2] = io_out_2_rx_dat_valid & (io_out_2_rx_dat_bits_srcID == 11'h0);
  assign rxdat_in_bits[3]  = '{tgtID: io_out_3_rx_dat_bits_tgtID, srcID: io_out_3_rx_dat_bits_srcID, txnID: io_out_3_rx_dat_bits_txnID, homeNID: io_out_3_rx_dat_bits_homeNID, opcode: io_out_3_rx_dat_bits_opcode, resp: io_out_3_rx_dat_bits_resp, dataSource: io_out_3_rx_dat_bits_dataSource, dbID: io_out_3_rx_dat_bits_dbID, dataID: io_out_3_rx_dat_bits_dataID, be: io_out_3_rx_dat_bits_be, data: io_out_3_rx_dat_bits_data, dataCheck: io_out_3_rx_dat_bits_dataCheck};
  assign rxdat_in_valid[3] = io_out_3_rx_dat_valid & (io_out_3_rx_dat_bits_srcID == 11'h0);

  wire       rxrsp_out_valid;
  wire [1:0] rxrsp_chosen;
  // ---- RXRSP 仲裁器 (FastArbiter_27): 不存在于 HN 的字段由仲裁器注入常量 0 ----
  FastArbiter_27 rxrspArbs_0 (
    .clock (clock),
    .reset (reset),
    .io_in_0_ready (),
    .io_in_0_valid (rxrsp_in_valid[0]),
    .io_in_0_bits_qos (4'h0),
    .io_in_0_bits_tgtID (rxrsp_in_bits[0].tgtID),
    .io_in_0_bits_txnID (rxrsp_in_bits[0].txnID),
    .io_in_0_bits_opcode (rxrsp_in_bits[0].opcode),
    .io_in_0_bits_respErr (2'h0),
    .io_in_0_bits_resp (rxrsp_in_bits[0].resp),
    .io_in_0_bits_fwdState (rxrsp_in_bits[0].fwdState),
    .io_in_0_bits_cBusy (3'h0),
    .io_in_0_bits_dbID (rxrsp_in_bits[0].dbID),
    .io_in_0_bits_pCrdType (rxrsp_in_bits[0].pCrdType),
    .io_in_0_bits_tagOp (2'h0),
    .io_in_0_bits_traceTag (1'h0),
    .io_in_1_ready (),
    .io_in_1_valid (rxrsp_in_valid[1]),
    .io_in_1_bits_qos (4'h0),
    .io_in_1_bits_tgtID (rxrsp_in_bits[1].tgtID),
    .io_in_1_bits_txnID (rxrsp_in_bits[1].txnID),
    .io_in_1_bits_opcode (rxrsp_in_bits[1].opcode),
    .io_in_1_bits_respErr (2'h0),
    .io_in_1_bits_resp (rxrsp_in_bits[1].resp),
    .io_in_1_bits_fwdState (rxrsp_in_bits[1].fwdState),
    .io_in_1_bits_cBusy (3'h0),
    .io_in_1_bits_dbID (rxrsp_in_bits[1].dbID),
    .io_in_1_bits_pCrdType (rxrsp_in_bits[1].pCrdType),
    .io_in_1_bits_tagOp (2'h0),
    .io_in_1_bits_traceTag (1'h0),
    .io_in_2_ready (),
    .io_in_2_valid (rxrsp_in_valid[2]),
    .io_in_2_bits_qos (4'h0),
    .io_in_2_bits_tgtID (rxrsp_in_bits[2].tgtID),
    .io_in_2_bits_txnID (rxrsp_in_bits[2].txnID),
    .io_in_2_bits_opcode (rxrsp_in_bits[2].opcode),
    .io_in_2_bits_respErr (2'h0),
    .io_in_2_bits_resp (rxrsp_in_bits[2].resp),
    .io_in_2_bits_fwdState (rxrsp_in_bits[2].fwdState),
    .io_in_2_bits_cBusy (3'h0),
    .io_in_2_bits_dbID (rxrsp_in_bits[2].dbID),
    .io_in_2_bits_pCrdType (rxrsp_in_bits[2].pCrdType),
    .io_in_2_bits_tagOp (2'h0),
    .io_in_2_bits_traceTag (1'h0),
    .io_in_3_ready (),
    .io_in_3_valid (rxrsp_in_valid[3]),
    .io_in_3_bits_qos (4'h0),
    .io_in_3_bits_tgtID (rxrsp_in_bits[3].tgtID),
    .io_in_3_bits_txnID (rxrsp_in_bits[3].txnID),
    .io_in_3_bits_opcode (rxrsp_in_bits[3].opcode),
    .io_in_3_bits_respErr (2'h0),
    .io_in_3_bits_resp (rxrsp_in_bits[3].resp),
    .io_in_3_bits_fwdState (rxrsp_in_bits[3].fwdState),
    .io_in_3_bits_cBusy (3'h0),
    .io_in_3_bits_dbID (rxrsp_in_bits[3].dbID),
    .io_in_3_bits_pCrdType (rxrsp_in_bits[3].pCrdType),
    .io_in_3_bits_tagOp (2'h0),
    .io_in_3_bits_traceTag (1'h0),
    .io_out_ready (io_in_0_rx_rsp_ready),
    .io_out_valid (rxrsp_out_valid),
    .io_out_bits_qos (io_in_0_rx_rsp_bits_qos),
    .io_out_bits_tgtID (),
    .io_out_bits_txnID (io_in_0_rx_rsp_bits_txnID),
    .io_out_bits_opcode (io_in_0_rx_rsp_bits_opcode),
    .io_out_bits_respErr (io_in_0_rx_rsp_bits_respErr),
    .io_out_bits_resp (io_in_0_rx_rsp_bits_resp),
    .io_out_bits_fwdState (io_in_0_rx_rsp_bits_fwdState),
    .io_out_bits_cBusy (io_in_0_rx_rsp_bits_cBusy),
    .io_out_bits_dbID (io_in_0_rx_rsp_bits_dbID),
    .io_out_bits_pCrdType (io_in_0_rx_rsp_bits_pCrdType),
    .io_out_bits_tagOp (io_in_0_rx_rsp_bits_tagOp),
    .io_out_bits_traceTag (io_in_0_rx_rsp_bits_traceTag),
    .io_chosen (rxrsp_chosen)
  );

  wire       rxdat_out_valid;
  wire [1:0] rxdat_chosen;
  // ---- RXDAT 仲裁器 (FastArbiter_46): 输出端丢弃 tgtID/srcID ----
  FastArbiter_46 rxdatArbs_0 (
    .clock (clock),
    .reset (reset),
    .io_in_0_valid (rxdat_in_valid[0]),
    .io_in_0_bits_tgtID (rxdat_in_bits[0].tgtID),
    .io_in_0_bits_srcID (rxdat_in_bits[0].srcID),
    .io_in_0_bits_txnID (rxdat_in_bits[0].txnID),
    .io_in_0_bits_homeNID (rxdat_in_bits[0].homeNID),
    .io_in_0_bits_opcode (rxdat_in_bits[0].opcode),
    .io_in_0_bits_resp (rxdat_in_bits[0].resp),
    .io_in_0_bits_dataSource (rxdat_in_bits[0].dataSource),
    .io_in_0_bits_dbID (rxdat_in_bits[0].dbID),
    .io_in_0_bits_dataID (rxdat_in_bits[0].dataID),
    .io_in_0_bits_be (rxdat_in_bits[0].be),
    .io_in_0_bits_data (rxdat_in_bits[0].data),
    .io_in_0_bits_dataCheck (rxdat_in_bits[0].dataCheck),
    .io_in_1_valid (rxdat_in_valid[1]),
    .io_in_1_bits_tgtID (rxdat_in_bits[1].tgtID),
    .io_in_1_bits_srcID (rxdat_in_bits[1].srcID),
    .io_in_1_bits_txnID (rxdat_in_bits[1].txnID),
    .io_in_1_bits_homeNID (rxdat_in_bits[1].homeNID),
    .io_in_1_bits_opcode (rxdat_in_bits[1].opcode),
    .io_in_1_bits_resp (rxdat_in_bits[1].resp),
    .io_in_1_bits_dataSource (rxdat_in_bits[1].dataSource),
    .io_in_1_bits_dbID (rxdat_in_bits[1].dbID),
    .io_in_1_bits_dataID (rxdat_in_bits[1].dataID),
    .io_in_1_bits_be (rxdat_in_bits[1].be),
    .io_in_1_bits_data (rxdat_in_bits[1].data),
    .io_in_1_bits_dataCheck (rxdat_in_bits[1].dataCheck),
    .io_in_2_valid (rxdat_in_valid[2]),
    .io_in_2_bits_tgtID (rxdat_in_bits[2].tgtID),
    .io_in_2_bits_srcID (rxdat_in_bits[2].srcID),
    .io_in_2_bits_txnID (rxdat_in_bits[2].txnID),
    .io_in_2_bits_homeNID (rxdat_in_bits[2].homeNID),
    .io_in_2_bits_opcode (rxdat_in_bits[2].opcode),
    .io_in_2_bits_resp (rxdat_in_bits[2].resp),
    .io_in_2_bits_dataSource (rxdat_in_bits[2].dataSource),
    .io_in_2_bits_dbID (rxdat_in_bits[2].dbID),
    .io_in_2_bits_dataID (rxdat_in_bits[2].dataID),
    .io_in_2_bits_be (rxdat_in_bits[2].be),
    .io_in_2_bits_data (rxdat_in_bits[2].data),
    .io_in_2_bits_dataCheck (rxdat_in_bits[2].dataCheck),
    .io_in_3_valid (rxdat_in_valid[3]),
    .io_in_3_bits_tgtID (rxdat_in_bits[3].tgtID),
    .io_in_3_bits_srcID (rxdat_in_bits[3].srcID),
    .io_in_3_bits_txnID (rxdat_in_bits[3].txnID),
    .io_in_3_bits_homeNID (rxdat_in_bits[3].homeNID),
    .io_in_3_bits_opcode (rxdat_in_bits[3].opcode),
    .io_in_3_bits_resp (rxdat_in_bits[3].resp),
    .io_in_3_bits_dataSource (rxdat_in_bits[3].dataSource),
    .io_in_3_bits_dbID (rxdat_in_bits[3].dbID),
    .io_in_3_bits_dataID (rxdat_in_bits[3].dataID),
    .io_in_3_bits_be (rxdat_in_bits[3].be),
    .io_in_3_bits_data (rxdat_in_bits[3].data),
    .io_in_3_bits_dataCheck (rxdat_in_bits[3].dataCheck),
    .io_out_ready (io_in_0_rx_dat_ready),
    .io_out_valid (rxdat_out_valid),
    .io_out_bits_tgtID (),
    .io_out_bits_srcID (),
    .io_out_bits_txnID (io_in_0_rx_dat_bits_txnID),
    .io_out_bits_homeNID (io_in_0_rx_dat_bits_homeNID),
    .io_out_bits_opcode (io_in_0_rx_dat_bits_opcode),
    .io_out_bits_resp (io_in_0_rx_dat_bits_resp),
    .io_out_bits_dataSource (io_in_0_rx_dat_bits_dataSource),
    .io_out_bits_dbID (io_in_0_rx_dat_bits_dbID),
    .io_out_bits_dataID (io_in_0_rx_dat_bits_dataID),
    .io_out_bits_be (io_in_0_rx_dat_bits_be),
    .io_out_bits_data (io_in_0_rx_dat_bits_data),
    .io_out_bits_dataCheck (io_in_0_rx_dat_bits_dataCheck),
    .io_chosen (rxdat_chosen)
  );

  // ===========================================================================
  //  端口输出装配
  // ===========================================================================
  // ---- RN (io_in_0) 侧: rx valid / tx ready ----
  assign io_in_0_rx_snp_valid = rxsnp_out_valid;
  assign io_in_0_rx_rsp_valid = rxrsp_out_valid;
  assign io_in_0_rx_dat_valid = rxdat_out_valid;

  // RN TX ready: 路由命中 bank 的输出 valid 或归约 (REQ 还需 & 该 bank out_ready)。
  wire [NUM_HN-1:0] hn_txreq_ready;
  assign hn_txreq_ready[HN_0] = io_out_0_tx_req_ready;
  assign hn_txreq_ready[HN_1] = io_out_1_tx_req_ready;
  assign hn_txreq_ready[HN_2] = io_out_2_tx_req_ready;
  assign hn_txreq_ready[HN_3] = io_out_3_tx_req_ready;
  assign io_in_0_tx_req_ready = |(hn_txreq_ready & txreq_out_valid);
  assign io_in_0_tx_rsp_ready = |txrsp_out_valid;
  assign io_in_0_tx_dat_ready = |txdat_out_valid;

  // ---- HN bank 侧 rx ready 解复用: 命中 chosen 的 bank 收到 ready (snoop 用槽背压) ----
  wire rxrsp_deliver_fire = io_in_0_rx_rsp_ready & rxrsp_out_valid;
  wire rxdat_deliver_fire = io_in_0_rx_dat_ready & rxdat_out_valid;
  assign io_out_0_rx_snp_ready = snp_in_ready[HN_0];
  assign io_out_0_rx_rsp_ready = rxrsp_deliver_fire & (rxrsp_chosen == 2'(HN_0));
  assign io_out_0_rx_dat_ready = rxdat_deliver_fire & (rxdat_chosen == 2'(HN_0));
  assign io_out_1_rx_snp_ready = snp_in_ready[HN_1];
  assign io_out_1_rx_rsp_ready = rxrsp_deliver_fire & (rxrsp_chosen == 2'(HN_1));
  assign io_out_1_rx_dat_ready = rxdat_deliver_fire & (rxdat_chosen == 2'(HN_1));
  assign io_out_2_rx_snp_ready = snp_in_ready[HN_2];
  assign io_out_2_rx_rsp_ready = rxrsp_deliver_fire & (rxrsp_chosen == 2'(HN_2));
  assign io_out_2_rx_dat_ready = rxdat_deliver_fire & (rxdat_chosen == 2'(HN_2));
  assign io_out_3_rx_snp_ready = snp_in_ready[HN_3];
  assign io_out_3_rx_rsp_ready = rxrsp_deliver_fire & (rxrsp_chosen == 2'(HN_3));
  assign io_out_3_rx_dat_ready = rxdat_deliver_fire & (rxdat_chosen == 2'(HN_3));

  // ---- HN bank 侧 tx valid + 仲裁胜者载荷 (从全字段输出结构体取 HN 消费的子集) ----
  // HN bank 0
  assign io_out_0_tx_req_valid = txreq_out_valid[HN_0];
  assign io_out_0_tx_req_bits_tgtID = txreq_arb_out[HN_0].tgtID;
  assign io_out_0_tx_req_bits_srcID = txreq_arb_out[HN_0].srcID;
  assign io_out_0_tx_req_bits_txnID = txreq_arb_out[HN_0].txnID;
  assign io_out_0_tx_req_bits_opcode = txreq_arb_out[HN_0].opcode;
  assign io_out_0_tx_req_bits_size = txreq_arb_out[HN_0].size;
  assign io_out_0_tx_req_bits_addr = txreq_arb_out[HN_0].addr;
  assign io_out_0_tx_req_bits_allowRetry = txreq_arb_out[HN_0].allowRetry;
  assign io_out_0_tx_req_bits_order = txreq_arb_out[HN_0].order;
  assign io_out_0_tx_req_bits_pCrdType = txreq_arb_out[HN_0].pCrdType;
  assign io_out_0_tx_req_bits_memAttr_allocate = txreq_arb_out[HN_0].memAttr_allocate;
  assign io_out_0_tx_req_bits_memAttr_cacheable = txreq_arb_out[HN_0].memAttr_cacheable;
  assign io_out_0_tx_req_bits_memAttr_device = txreq_arb_out[HN_0].memAttr_device;
  assign io_out_0_tx_req_bits_memAttr_ewa = txreq_arb_out[HN_0].memAttr_ewa;
  assign io_out_0_tx_req_bits_snpAttr = txreq_arb_out[HN_0].snpAttr;
  assign io_out_0_tx_req_bits_expCompAck = txreq_arb_out[HN_0].expCompAck;
  assign io_out_0_tx_rsp_valid = txrsp_out_valid[HN_0];
  assign io_out_0_tx_rsp_bits_srcID = txrsp_arb_out[HN_0].srcID;
  assign io_out_0_tx_rsp_bits_txnID = txrsp_arb_out[HN_0].txnID;
  assign io_out_0_tx_rsp_bits_opcode = txrsp_arb_out[HN_0].opcode;
  assign io_out_0_tx_rsp_bits_dbID = txrsp_arb_out[HN_0].dbID;
  assign io_out_0_tx_dat_valid = txdat_out_valid[HN_0];
  assign io_out_0_tx_dat_bits_srcID = txdat_arb_out[HN_0].srcID;
  assign io_out_0_tx_dat_bits_txnID = txdat_arb_out[HN_0].txnID;
  assign io_out_0_tx_dat_bits_opcode = txdat_arb_out[HN_0].opcode;
  assign io_out_0_tx_dat_bits_resp = txdat_arb_out[HN_0].resp;
  assign io_out_0_tx_dat_bits_dataID = txdat_arb_out[HN_0].dataID;
  assign io_out_0_tx_dat_bits_data = txdat_arb_out[HN_0].data;
  // HN bank 1
  assign io_out_1_tx_req_valid = txreq_out_valid[HN_1];
  assign io_out_1_tx_req_bits_tgtID = txreq_arb_out[HN_1].tgtID;
  assign io_out_1_tx_req_bits_srcID = txreq_arb_out[HN_1].srcID;
  assign io_out_1_tx_req_bits_txnID = txreq_arb_out[HN_1].txnID;
  assign io_out_1_tx_req_bits_opcode = txreq_arb_out[HN_1].opcode;
  assign io_out_1_tx_req_bits_size = txreq_arb_out[HN_1].size;
  assign io_out_1_tx_req_bits_addr = txreq_arb_out[HN_1].addr;
  assign io_out_1_tx_req_bits_allowRetry = txreq_arb_out[HN_1].allowRetry;
  assign io_out_1_tx_req_bits_order = txreq_arb_out[HN_1].order;
  assign io_out_1_tx_req_bits_pCrdType = txreq_arb_out[HN_1].pCrdType;
  assign io_out_1_tx_req_bits_memAttr_allocate = txreq_arb_out[HN_1].memAttr_allocate;
  assign io_out_1_tx_req_bits_memAttr_cacheable = txreq_arb_out[HN_1].memAttr_cacheable;
  assign io_out_1_tx_req_bits_memAttr_device = txreq_arb_out[HN_1].memAttr_device;
  assign io_out_1_tx_req_bits_memAttr_ewa = txreq_arb_out[HN_1].memAttr_ewa;
  assign io_out_1_tx_req_bits_snpAttr = txreq_arb_out[HN_1].snpAttr;
  assign io_out_1_tx_req_bits_expCompAck = txreq_arb_out[HN_1].expCompAck;
  assign io_out_1_tx_rsp_valid = txrsp_out_valid[HN_1];
  assign io_out_1_tx_rsp_bits_srcID = txrsp_arb_out[HN_1].srcID;
  assign io_out_1_tx_rsp_bits_txnID = txrsp_arb_out[HN_1].txnID;
  assign io_out_1_tx_rsp_bits_opcode = txrsp_arb_out[HN_1].opcode;
  assign io_out_1_tx_rsp_bits_dbID = txrsp_arb_out[HN_1].dbID;
  assign io_out_1_tx_dat_valid = txdat_out_valid[HN_1];
  assign io_out_1_tx_dat_bits_srcID = txdat_arb_out[HN_1].srcID;
  assign io_out_1_tx_dat_bits_txnID = txdat_arb_out[HN_1].txnID;
  assign io_out_1_tx_dat_bits_opcode = txdat_arb_out[HN_1].opcode;
  assign io_out_1_tx_dat_bits_resp = txdat_arb_out[HN_1].resp;
  assign io_out_1_tx_dat_bits_dataID = txdat_arb_out[HN_1].dataID;
  assign io_out_1_tx_dat_bits_data = txdat_arb_out[HN_1].data;
  // HN bank 2
  assign io_out_2_tx_req_valid = txreq_out_valid[HN_2];
  assign io_out_2_tx_req_bits_tgtID = txreq_arb_out[HN_2].tgtID;
  assign io_out_2_tx_req_bits_srcID = txreq_arb_out[HN_2].srcID;
  assign io_out_2_tx_req_bits_txnID = txreq_arb_out[HN_2].txnID;
  assign io_out_2_tx_req_bits_opcode = txreq_arb_out[HN_2].opcode;
  assign io_out_2_tx_req_bits_size = txreq_arb_out[HN_2].size;
  assign io_out_2_tx_req_bits_addr = txreq_arb_out[HN_2].addr;
  assign io_out_2_tx_req_bits_allowRetry = txreq_arb_out[HN_2].allowRetry;
  assign io_out_2_tx_req_bits_order = txreq_arb_out[HN_2].order;
  assign io_out_2_tx_req_bits_pCrdType = txreq_arb_out[HN_2].pCrdType;
  assign io_out_2_tx_req_bits_memAttr_allocate = txreq_arb_out[HN_2].memAttr_allocate;
  assign io_out_2_tx_req_bits_memAttr_cacheable = txreq_arb_out[HN_2].memAttr_cacheable;
  assign io_out_2_tx_req_bits_memAttr_device = txreq_arb_out[HN_2].memAttr_device;
  assign io_out_2_tx_req_bits_memAttr_ewa = txreq_arb_out[HN_2].memAttr_ewa;
  assign io_out_2_tx_req_bits_snpAttr = txreq_arb_out[HN_2].snpAttr;
  assign io_out_2_tx_req_bits_expCompAck = txreq_arb_out[HN_2].expCompAck;
  assign io_out_2_tx_rsp_valid = txrsp_out_valid[HN_2];
  assign io_out_2_tx_rsp_bits_srcID = txrsp_arb_out[HN_2].srcID;
  assign io_out_2_tx_rsp_bits_txnID = txrsp_arb_out[HN_2].txnID;
  assign io_out_2_tx_rsp_bits_opcode = txrsp_arb_out[HN_2].opcode;
  assign io_out_2_tx_rsp_bits_dbID = txrsp_arb_out[HN_2].dbID;
  assign io_out_2_tx_dat_valid = txdat_out_valid[HN_2];
  assign io_out_2_tx_dat_bits_srcID = txdat_arb_out[HN_2].srcID;
  assign io_out_2_tx_dat_bits_txnID = txdat_arb_out[HN_2].txnID;
  assign io_out_2_tx_dat_bits_opcode = txdat_arb_out[HN_2].opcode;
  assign io_out_2_tx_dat_bits_resp = txdat_arb_out[HN_2].resp;
  assign io_out_2_tx_dat_bits_dataID = txdat_arb_out[HN_2].dataID;
  assign io_out_2_tx_dat_bits_data = txdat_arb_out[HN_2].data;
  // HN bank 3
  assign io_out_3_tx_req_valid = txreq_out_valid[HN_3];
  assign io_out_3_tx_req_bits_tgtID = txreq_arb_out[HN_3].tgtID;
  assign io_out_3_tx_req_bits_srcID = txreq_arb_out[HN_3].srcID;
  assign io_out_3_tx_req_bits_txnID = txreq_arb_out[HN_3].txnID;
  assign io_out_3_tx_req_bits_opcode = txreq_arb_out[HN_3].opcode;
  assign io_out_3_tx_req_bits_size = txreq_arb_out[HN_3].size;
  assign io_out_3_tx_req_bits_addr = txreq_arb_out[HN_3].addr;
  assign io_out_3_tx_req_bits_allowRetry = txreq_arb_out[HN_3].allowRetry;
  assign io_out_3_tx_req_bits_order = txreq_arb_out[HN_3].order;
  assign io_out_3_tx_req_bits_pCrdType = txreq_arb_out[HN_3].pCrdType;
  assign io_out_3_tx_req_bits_memAttr_allocate = txreq_arb_out[HN_3].memAttr_allocate;
  assign io_out_3_tx_req_bits_memAttr_cacheable = txreq_arb_out[HN_3].memAttr_cacheable;
  assign io_out_3_tx_req_bits_memAttr_device = txreq_arb_out[HN_3].memAttr_device;
  assign io_out_3_tx_req_bits_memAttr_ewa = txreq_arb_out[HN_3].memAttr_ewa;
  assign io_out_3_tx_req_bits_snpAttr = txreq_arb_out[HN_3].snpAttr;
  assign io_out_3_tx_req_bits_expCompAck = txreq_arb_out[HN_3].expCompAck;
  assign io_out_3_tx_rsp_valid = txrsp_out_valid[HN_3];
  assign io_out_3_tx_rsp_bits_srcID = txrsp_arb_out[HN_3].srcID;
  assign io_out_3_tx_rsp_bits_txnID = txrsp_arb_out[HN_3].txnID;
  assign io_out_3_tx_rsp_bits_opcode = txrsp_arb_out[HN_3].opcode;
  assign io_out_3_tx_rsp_bits_dbID = txrsp_arb_out[HN_3].dbID;
  assign io_out_3_tx_dat_valid = txdat_out_valid[HN_3];
  assign io_out_3_tx_dat_bits_srcID = txdat_arb_out[HN_3].srcID;
  assign io_out_3_tx_dat_bits_txnID = txdat_arb_out[HN_3].txnID;
  assign io_out_3_tx_dat_bits_opcode = txdat_arb_out[HN_3].opcode;
  assign io_out_3_tx_dat_bits_resp = txdat_arb_out[HN_3].resp;
  assign io_out_3_tx_dat_bits_dataID = txdat_arb_out[HN_3].dataID;
  assign io_out_3_tx_dat_bits_data = txdat_arb_out[HN_3].data;

endmodule
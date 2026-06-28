// =============================================================================
//  SNXbar —— 香山 V2R2 CHI Subordinate-Node 交叉开关 (可读重写核 xs_SNXbar_core)
// -----------------------------------------------------------------------------
//  源自 OpenLLC 的 SNXbar: 4 个上游主口 (in_0..in_3, 来自各 HN-F) × 1 个下游
//  从口 (out, 主存 SN)。从设计意图重写 (非照抄 firtool 优化后的展平命名)。
//
//  数据流:
//    上行 TX (主→从): 4 主口的 TXREQ / TXDAT 各经一个 FastArbiter 轮转仲裁, 胜者
//      载荷路由到唯一从口 out; 被授权主口的 ready = out 就绪 & 仲裁有有效输出 &
//      仲裁选中本主口 (io_chosen)。仲裁 + 胜者 payload 多路选择由 FastArbiter 黑盒
//      内部完成, 本核只重写「ready 解复用 (按 chosen)」。
//    下行 RX (从→主): out 回送的 RXRSP / RXDAT 按 flit 的 txnID[10:9] (2 位源主口
//      编号) 解复用回对应主口; 载荷广播给全部主口, 仅 valid 受路由门控。RX 通道无
//      ready 背压, 故 out 侧 rx_*_ready = 各主口接受信号的 OR (路由命中即接受)。
//
//  黑盒子模块 (仲裁主体, 不在本核重写):
//    FastArbiter_47 txreqArb : TXREQ 4 路仲裁;
//    FastArbiter_46 txdatArb : TXDAT 4 路仲裁。
//  二者在 golden 与本核中按同名同端口例化, UT 两侧共用、FM 两侧黑盒, 故仲裁内部
//  状态/选择逻辑等价, 本核验证聚焦路由/解复用。
//
//  验证: golden 同名 SNXbar 例化本核 (端口透传)。叶子级路由逻辑 (除黑盒仲裁器外
//  无其它子例化), UT 双例化逐拍比对全部输出; FM 签名分析证等价。
// =============================================================================
module xs_SNXbar_core
  import snxbar_pkg::*;
(
  input          clock,
  input          reset,

  // ====== 主口 in_0 ======
  output         io_in_0_tx_req_ready,
  input          io_in_0_tx_req_valid,
  input  [10:0]  io_in_0_tx_req_bits_tgtID,
  input  [10:0]  io_in_0_tx_req_bits_srcID,
  input  [11:0]  io_in_0_tx_req_bits_txnID,
  input  [6:0]   io_in_0_tx_req_bits_opcode,
  input  [2:0]   io_in_0_tx_req_bits_size,
  input  [47:0]  io_in_0_tx_req_bits_addr,
  input          io_in_0_tx_req_bits_allowRetry,
  input  [1:0]   io_in_0_tx_req_bits_order,
  input  [3:0]   io_in_0_tx_req_bits_pCrdType,
  input          io_in_0_tx_req_bits_memAttr_allocate,
  input          io_in_0_tx_req_bits_memAttr_cacheable,
  input          io_in_0_tx_req_bits_memAttr_device,
  input          io_in_0_tx_req_bits_memAttr_ewa,
  input          io_in_0_tx_req_bits_snpAttr,
  input          io_in_0_tx_req_bits_expCompAck,
  output         io_in_0_tx_dat_ready,
  input          io_in_0_tx_dat_valid,
  input  [10:0]  io_in_0_tx_dat_bits_tgtID,
  input  [10:0]  io_in_0_tx_dat_bits_srcID,
  input  [11:0]  io_in_0_tx_dat_bits_txnID,
  input  [10:0]  io_in_0_tx_dat_bits_homeNID,
  input  [3:0]   io_in_0_tx_dat_bits_opcode,
  input  [2:0]   io_in_0_tx_dat_bits_resp,
  input  [3:0]   io_in_0_tx_dat_bits_dataSource,
  input  [11:0]  io_in_0_tx_dat_bits_dbID,
  input  [1:0]   io_in_0_tx_dat_bits_dataID,
  input  [31:0]  io_in_0_tx_dat_bits_be,
  input  [255:0] io_in_0_tx_dat_bits_data,
  input  [31:0]  io_in_0_tx_dat_bits_dataCheck,
  output         io_in_0_rx_rsp_valid,
  output [10:0]  io_in_0_rx_rsp_bits_srcID,
  output [11:0]  io_in_0_rx_rsp_bits_txnID,
  output [4:0]   io_in_0_rx_rsp_bits_opcode,
  output [11:0]  io_in_0_rx_rsp_bits_dbID,
  output         io_in_0_rx_dat_valid,
  output [10:0]  io_in_0_rx_dat_bits_srcID,
  output [11:0]  io_in_0_rx_dat_bits_txnID,
  output [3:0]   io_in_0_rx_dat_bits_opcode,
  output [2:0]   io_in_0_rx_dat_bits_resp,
  output [1:0]   io_in_0_rx_dat_bits_dataID,
  output [255:0] io_in_0_rx_dat_bits_data,

  // ====== 主口 in_1 ======
  output         io_in_1_tx_req_ready,
  input          io_in_1_tx_req_valid,
  input  [10:0]  io_in_1_tx_req_bits_tgtID,
  input  [10:0]  io_in_1_tx_req_bits_srcID,
  input  [11:0]  io_in_1_tx_req_bits_txnID,
  input  [6:0]   io_in_1_tx_req_bits_opcode,
  input  [2:0]   io_in_1_tx_req_bits_size,
  input  [47:0]  io_in_1_tx_req_bits_addr,
  input          io_in_1_tx_req_bits_allowRetry,
  input  [1:0]   io_in_1_tx_req_bits_order,
  input  [3:0]   io_in_1_tx_req_bits_pCrdType,
  input          io_in_1_tx_req_bits_memAttr_allocate,
  input          io_in_1_tx_req_bits_memAttr_cacheable,
  input          io_in_1_tx_req_bits_memAttr_device,
  input          io_in_1_tx_req_bits_memAttr_ewa,
  input          io_in_1_tx_req_bits_snpAttr,
  input          io_in_1_tx_req_bits_expCompAck,
  output         io_in_1_tx_dat_ready,
  input          io_in_1_tx_dat_valid,
  input  [10:0]  io_in_1_tx_dat_bits_tgtID,
  input  [10:0]  io_in_1_tx_dat_bits_srcID,
  input  [11:0]  io_in_1_tx_dat_bits_txnID,
  input  [10:0]  io_in_1_tx_dat_bits_homeNID,
  input  [3:0]   io_in_1_tx_dat_bits_opcode,
  input  [2:0]   io_in_1_tx_dat_bits_resp,
  input  [3:0]   io_in_1_tx_dat_bits_dataSource,
  input  [11:0]  io_in_1_tx_dat_bits_dbID,
  input  [1:0]   io_in_1_tx_dat_bits_dataID,
  input  [31:0]  io_in_1_tx_dat_bits_be,
  input  [255:0] io_in_1_tx_dat_bits_data,
  input  [31:0]  io_in_1_tx_dat_bits_dataCheck,
  output         io_in_1_rx_rsp_valid,
  output [10:0]  io_in_1_rx_rsp_bits_srcID,
  output [11:0]  io_in_1_rx_rsp_bits_txnID,
  output [4:0]   io_in_1_rx_rsp_bits_opcode,
  output [11:0]  io_in_1_rx_rsp_bits_dbID,
  output         io_in_1_rx_dat_valid,
  output [10:0]  io_in_1_rx_dat_bits_srcID,
  output [11:0]  io_in_1_rx_dat_bits_txnID,
  output [3:0]   io_in_1_rx_dat_bits_opcode,
  output [2:0]   io_in_1_rx_dat_bits_resp,
  output [1:0]   io_in_1_rx_dat_bits_dataID,
  output [255:0] io_in_1_rx_dat_bits_data,

  // ====== 主口 in_2 ======
  output         io_in_2_tx_req_ready,
  input          io_in_2_tx_req_valid,
  input  [10:0]  io_in_2_tx_req_bits_tgtID,
  input  [10:0]  io_in_2_tx_req_bits_srcID,
  input  [11:0]  io_in_2_tx_req_bits_txnID,
  input  [6:0]   io_in_2_tx_req_bits_opcode,
  input  [2:0]   io_in_2_tx_req_bits_size,
  input  [47:0]  io_in_2_tx_req_bits_addr,
  input          io_in_2_tx_req_bits_allowRetry,
  input  [1:0]   io_in_2_tx_req_bits_order,
  input  [3:0]   io_in_2_tx_req_bits_pCrdType,
  input          io_in_2_tx_req_bits_memAttr_allocate,
  input          io_in_2_tx_req_bits_memAttr_cacheable,
  input          io_in_2_tx_req_bits_memAttr_device,
  input          io_in_2_tx_req_bits_memAttr_ewa,
  input          io_in_2_tx_req_bits_snpAttr,
  input          io_in_2_tx_req_bits_expCompAck,
  output         io_in_2_tx_dat_ready,
  input          io_in_2_tx_dat_valid,
  input  [10:0]  io_in_2_tx_dat_bits_tgtID,
  input  [10:0]  io_in_2_tx_dat_bits_srcID,
  input  [11:0]  io_in_2_tx_dat_bits_txnID,
  input  [10:0]  io_in_2_tx_dat_bits_homeNID,
  input  [3:0]   io_in_2_tx_dat_bits_opcode,
  input  [2:0]   io_in_2_tx_dat_bits_resp,
  input  [3:0]   io_in_2_tx_dat_bits_dataSource,
  input  [11:0]  io_in_2_tx_dat_bits_dbID,
  input  [1:0]   io_in_2_tx_dat_bits_dataID,
  input  [31:0]  io_in_2_tx_dat_bits_be,
  input  [255:0] io_in_2_tx_dat_bits_data,
  input  [31:0]  io_in_2_tx_dat_bits_dataCheck,
  output         io_in_2_rx_rsp_valid,
  output [10:0]  io_in_2_rx_rsp_bits_srcID,
  output [11:0]  io_in_2_rx_rsp_bits_txnID,
  output [4:0]   io_in_2_rx_rsp_bits_opcode,
  output [11:0]  io_in_2_rx_rsp_bits_dbID,
  output         io_in_2_rx_dat_valid,
  output [10:0]  io_in_2_rx_dat_bits_srcID,
  output [11:0]  io_in_2_rx_dat_bits_txnID,
  output [3:0]   io_in_2_rx_dat_bits_opcode,
  output [2:0]   io_in_2_rx_dat_bits_resp,
  output [1:0]   io_in_2_rx_dat_bits_dataID,
  output [255:0] io_in_2_rx_dat_bits_data,

  // ====== 主口 in_3 ======
  output         io_in_3_tx_req_ready,
  input          io_in_3_tx_req_valid,
  input  [10:0]  io_in_3_tx_req_bits_tgtID,
  input  [10:0]  io_in_3_tx_req_bits_srcID,
  input  [11:0]  io_in_3_tx_req_bits_txnID,
  input  [6:0]   io_in_3_tx_req_bits_opcode,
  input  [2:0]   io_in_3_tx_req_bits_size,
  input  [47:0]  io_in_3_tx_req_bits_addr,
  input          io_in_3_tx_req_bits_allowRetry,
  input  [1:0]   io_in_3_tx_req_bits_order,
  input  [3:0]   io_in_3_tx_req_bits_pCrdType,
  input          io_in_3_tx_req_bits_memAttr_allocate,
  input          io_in_3_tx_req_bits_memAttr_cacheable,
  input          io_in_3_tx_req_bits_memAttr_device,
  input          io_in_3_tx_req_bits_memAttr_ewa,
  input          io_in_3_tx_req_bits_snpAttr,
  input          io_in_3_tx_req_bits_expCompAck,
  output         io_in_3_tx_dat_ready,
  input          io_in_3_tx_dat_valid,
  input  [10:0]  io_in_3_tx_dat_bits_tgtID,
  input  [10:0]  io_in_3_tx_dat_bits_srcID,
  input  [11:0]  io_in_3_tx_dat_bits_txnID,
  input  [10:0]  io_in_3_tx_dat_bits_homeNID,
  input  [3:0]   io_in_3_tx_dat_bits_opcode,
  input  [2:0]   io_in_3_tx_dat_bits_resp,
  input  [3:0]   io_in_3_tx_dat_bits_dataSource,
  input  [11:0]  io_in_3_tx_dat_bits_dbID,
  input  [1:0]   io_in_3_tx_dat_bits_dataID,
  input  [31:0]  io_in_3_tx_dat_bits_be,
  input  [255:0] io_in_3_tx_dat_bits_data,
  input  [31:0]  io_in_3_tx_dat_bits_dataCheck,
  output         io_in_3_rx_rsp_valid,
  output [10:0]  io_in_3_rx_rsp_bits_srcID,
  output [11:0]  io_in_3_rx_rsp_bits_txnID,
  output [4:0]   io_in_3_rx_rsp_bits_opcode,
  output [11:0]  io_in_3_rx_rsp_bits_dbID,
  output         io_in_3_rx_dat_valid,
  output [10:0]  io_in_3_rx_dat_bits_srcID,
  output [11:0]  io_in_3_rx_dat_bits_txnID,
  output [3:0]   io_in_3_rx_dat_bits_opcode,
  output [2:0]   io_in_3_rx_dat_bits_resp,
  output [1:0]   io_in_3_rx_dat_bits_dataID,
  output [255:0] io_in_3_rx_dat_bits_data,

  // ====== 从口 out (唯一下游 SN) ======
  input          io_out_tx_req_ready,
  output         io_out_tx_req_valid,
  output [10:0]  io_out_tx_req_bits_tgtID,
  output [10:0]  io_out_tx_req_bits_srcID,
  output [11:0]  io_out_tx_req_bits_txnID,
  output [6:0]   io_out_tx_req_bits_opcode,
  output [2:0]   io_out_tx_req_bits_size,
  output [47:0]  io_out_tx_req_bits_addr,
  output         io_out_tx_req_bits_allowRetry,
  output [1:0]   io_out_tx_req_bits_order,
  output [3:0]   io_out_tx_req_bits_pCrdType,
  output         io_out_tx_req_bits_memAttr_allocate,
  output         io_out_tx_req_bits_memAttr_cacheable,
  output         io_out_tx_req_bits_memAttr_device,
  output         io_out_tx_req_bits_memAttr_ewa,
  output         io_out_tx_req_bits_snpAttr,
  output         io_out_tx_req_bits_expCompAck,
  input          io_out_tx_dat_ready,
  output         io_out_tx_dat_valid,
  output [10:0]  io_out_tx_dat_bits_tgtID,
  output [10:0]  io_out_tx_dat_bits_srcID,
  output [11:0]  io_out_tx_dat_bits_txnID,
  output [10:0]  io_out_tx_dat_bits_homeNID,
  output [3:0]   io_out_tx_dat_bits_opcode,
  output [2:0]   io_out_tx_dat_bits_resp,
  output [3:0]   io_out_tx_dat_bits_dataSource,
  output [11:0]  io_out_tx_dat_bits_dbID,
  output [1:0]   io_out_tx_dat_bits_dataID,
  output [31:0]  io_out_tx_dat_bits_be,
  output [255:0] io_out_tx_dat_bits_data,
  output [31:0]  io_out_tx_dat_bits_dataCheck,
  output         io_out_rx_rsp_ready,
  input          io_out_rx_rsp_valid,
  input  [10:0]  io_out_rx_rsp_bits_srcID,
  input  [11:0]  io_out_rx_rsp_bits_txnID,
  input  [4:0]   io_out_rx_rsp_bits_opcode,
  input  [11:0]  io_out_rx_rsp_bits_dbID,
  output         io_out_rx_dat_ready,
  input          io_out_rx_dat_valid,
  input  [10:0]  io_out_rx_dat_bits_srcID,
  input  [11:0]  io_out_rx_dat_bits_txnID,
  input  [3:0]   io_out_rx_dat_bits_opcode,
  input  [2:0]   io_out_rx_dat_bits_resp,
  input  [1:0]   io_out_rx_dat_bits_dataID,
  input  [255:0] io_out_rx_dat_bits_data
);

  // ===========================================================================
  //  上行 TX: 把 4 个主口的 TXREQ / TXDAT flit 打包成结构体数组 (按主口对齐),
  //  再喂给两个 FastArbiter 黑盒做仲裁。
  // ===========================================================================
  logic [NUM_IN-1:0] tx_req_valid;
  chi_req_t          tx_req [NUM_IN];
  logic [NUM_IN-1:0] tx_dat_valid;
  chi_dat_tx_t       tx_dat [NUM_IN];

  assign tx_req_valid[IN_0] = io_in_0_tx_req_valid;
  assign tx_req[IN_0] = '{
    tgtID:            io_in_0_tx_req_bits_tgtID,
    srcID:            io_in_0_tx_req_bits_srcID,
    txnID:            io_in_0_tx_req_bits_txnID,
    opcode:           io_in_0_tx_req_bits_opcode,
    size:             io_in_0_tx_req_bits_size,
    addr:             io_in_0_tx_req_bits_addr,
    allowRetry:       io_in_0_tx_req_bits_allowRetry,
    order:            io_in_0_tx_req_bits_order,
    pCrdType:         io_in_0_tx_req_bits_pCrdType,
    memAttr_allocate: io_in_0_tx_req_bits_memAttr_allocate,
    memAttr_cacheable:io_in_0_tx_req_bits_memAttr_cacheable,
    memAttr_device:   io_in_0_tx_req_bits_memAttr_device,
    memAttr_ewa:      io_in_0_tx_req_bits_memAttr_ewa,
    snpAttr:          io_in_0_tx_req_bits_snpAttr,
    expCompAck:       io_in_0_tx_req_bits_expCompAck};
  assign tx_req_valid[IN_1] = io_in_1_tx_req_valid;
  assign tx_req[IN_1] = '{
    tgtID:            io_in_1_tx_req_bits_tgtID,
    srcID:            io_in_1_tx_req_bits_srcID,
    txnID:            io_in_1_tx_req_bits_txnID,
    opcode:           io_in_1_tx_req_bits_opcode,
    size:             io_in_1_tx_req_bits_size,
    addr:             io_in_1_tx_req_bits_addr,
    allowRetry:       io_in_1_tx_req_bits_allowRetry,
    order:            io_in_1_tx_req_bits_order,
    pCrdType:         io_in_1_tx_req_bits_pCrdType,
    memAttr_allocate: io_in_1_tx_req_bits_memAttr_allocate,
    memAttr_cacheable:io_in_1_tx_req_bits_memAttr_cacheable,
    memAttr_device:   io_in_1_tx_req_bits_memAttr_device,
    memAttr_ewa:      io_in_1_tx_req_bits_memAttr_ewa,
    snpAttr:          io_in_1_tx_req_bits_snpAttr,
    expCompAck:       io_in_1_tx_req_bits_expCompAck};
  assign tx_req_valid[IN_2] = io_in_2_tx_req_valid;
  assign tx_req[IN_2] = '{
    tgtID:            io_in_2_tx_req_bits_tgtID,
    srcID:            io_in_2_tx_req_bits_srcID,
    txnID:            io_in_2_tx_req_bits_txnID,
    opcode:           io_in_2_tx_req_bits_opcode,
    size:             io_in_2_tx_req_bits_size,
    addr:             io_in_2_tx_req_bits_addr,
    allowRetry:       io_in_2_tx_req_bits_allowRetry,
    order:            io_in_2_tx_req_bits_order,
    pCrdType:         io_in_2_tx_req_bits_pCrdType,
    memAttr_allocate: io_in_2_tx_req_bits_memAttr_allocate,
    memAttr_cacheable:io_in_2_tx_req_bits_memAttr_cacheable,
    memAttr_device:   io_in_2_tx_req_bits_memAttr_device,
    memAttr_ewa:      io_in_2_tx_req_bits_memAttr_ewa,
    snpAttr:          io_in_2_tx_req_bits_snpAttr,
    expCompAck:       io_in_2_tx_req_bits_expCompAck};
  assign tx_req_valid[IN_3] = io_in_3_tx_req_valid;
  assign tx_req[IN_3] = '{
    tgtID:            io_in_3_tx_req_bits_tgtID,
    srcID:            io_in_3_tx_req_bits_srcID,
    txnID:            io_in_3_tx_req_bits_txnID,
    opcode:           io_in_3_tx_req_bits_opcode,
    size:             io_in_3_tx_req_bits_size,
    addr:             io_in_3_tx_req_bits_addr,
    allowRetry:       io_in_3_tx_req_bits_allowRetry,
    order:            io_in_3_tx_req_bits_order,
    pCrdType:         io_in_3_tx_req_bits_pCrdType,
    memAttr_allocate: io_in_3_tx_req_bits_memAttr_allocate,
    memAttr_cacheable:io_in_3_tx_req_bits_memAttr_cacheable,
    memAttr_device:   io_in_3_tx_req_bits_memAttr_device,
    memAttr_ewa:      io_in_3_tx_req_bits_memAttr_ewa,
    snpAttr:          io_in_3_tx_req_bits_snpAttr,
    expCompAck:       io_in_3_tx_req_bits_expCompAck};

  assign tx_dat_valid[IN_0] = io_in_0_tx_dat_valid;
  assign tx_dat[IN_0] = '{
    tgtID:      io_in_0_tx_dat_bits_tgtID,    srcID:      io_in_0_tx_dat_bits_srcID,
    txnID:      io_in_0_tx_dat_bits_txnID,    homeNID:    io_in_0_tx_dat_bits_homeNID,
    opcode:     io_in_0_tx_dat_bits_opcode,   resp:       io_in_0_tx_dat_bits_resp,
    dataSource: io_in_0_tx_dat_bits_dataSource, dbID:     io_in_0_tx_dat_bits_dbID,
    dataID:     io_in_0_tx_dat_bits_dataID,   be:         io_in_0_tx_dat_bits_be,
    data:       io_in_0_tx_dat_bits_data,     dataCheck:  io_in_0_tx_dat_bits_dataCheck};
  assign tx_dat_valid[IN_1] = io_in_1_tx_dat_valid;
  assign tx_dat[IN_1] = '{
    tgtID:      io_in_1_tx_dat_bits_tgtID,    srcID:      io_in_1_tx_dat_bits_srcID,
    txnID:      io_in_1_tx_dat_bits_txnID,    homeNID:    io_in_1_tx_dat_bits_homeNID,
    opcode:     io_in_1_tx_dat_bits_opcode,   resp:       io_in_1_tx_dat_bits_resp,
    dataSource: io_in_1_tx_dat_bits_dataSource, dbID:     io_in_1_tx_dat_bits_dbID,
    dataID:     io_in_1_tx_dat_bits_dataID,   be:         io_in_1_tx_dat_bits_be,
    data:       io_in_1_tx_dat_bits_data,     dataCheck:  io_in_1_tx_dat_bits_dataCheck};
  assign tx_dat_valid[IN_2] = io_in_2_tx_dat_valid;
  assign tx_dat[IN_2] = '{
    tgtID:      io_in_2_tx_dat_bits_tgtID,    srcID:      io_in_2_tx_dat_bits_srcID,
    txnID:      io_in_2_tx_dat_bits_txnID,    homeNID:    io_in_2_tx_dat_bits_homeNID,
    opcode:     io_in_2_tx_dat_bits_opcode,   resp:       io_in_2_tx_dat_bits_resp,
    dataSource: io_in_2_tx_dat_bits_dataSource, dbID:     io_in_2_tx_dat_bits_dbID,
    dataID:     io_in_2_tx_dat_bits_dataID,   be:         io_in_2_tx_dat_bits_be,
    data:       io_in_2_tx_dat_bits_data,     dataCheck:  io_in_2_tx_dat_bits_dataCheck};
  assign tx_dat_valid[IN_3] = io_in_3_tx_dat_valid;
  assign tx_dat[IN_3] = '{
    tgtID:      io_in_3_tx_dat_bits_tgtID,    srcID:      io_in_3_tx_dat_bits_srcID,
    txnID:      io_in_3_tx_dat_bits_txnID,    homeNID:    io_in_3_tx_dat_bits_homeNID,
    opcode:     io_in_3_tx_dat_bits_opcode,   resp:       io_in_3_tx_dat_bits_resp,
    dataSource: io_in_3_tx_dat_bits_dataSource, dbID:     io_in_3_tx_dat_bits_dbID,
    dataID:     io_in_3_tx_dat_bits_dataID,   be:         io_in_3_tx_dat_bits_be,
    data:       io_in_3_tx_dat_bits_data,     dataCheck:  io_in_3_tx_dat_bits_dataCheck};

  // ===========================================================================
  //  TXREQ / TXDAT 仲裁器 (FastArbiter 黑盒): 仲裁 + 胜者载荷多路选择内部完成。
  //  胜者载荷直接驱动从口 out 的 TXREQ / TXDAT (经结构体回收后扇出到端口)。
  // ===========================================================================
  logic        txreq_out_valid;
  logic [1:0]  txreq_chosen;
  chi_req_t    out_tx_req;
  logic        txdat_out_valid;
  logic [1:0]  txdat_chosen;
  chi_dat_tx_t out_tx_dat;

  FastArbiter_47 txreqArb (
    .clock                          (clock),
    .reset                          (reset),
    .io_in_0_valid                  (tx_req_valid[IN_0]),
    .io_in_0_bits_tgtID             (tx_req[IN_0].tgtID),
    .io_in_0_bits_srcID             (tx_req[IN_0].srcID),
    .io_in_0_bits_txnID             (tx_req[IN_0].txnID),
    .io_in_0_bits_opcode            (tx_req[IN_0].opcode),
    .io_in_0_bits_size              (tx_req[IN_0].size),
    .io_in_0_bits_addr              (tx_req[IN_0].addr),
    .io_in_0_bits_allowRetry        (tx_req[IN_0].allowRetry),
    .io_in_0_bits_order             (tx_req[IN_0].order),
    .io_in_0_bits_pCrdType          (tx_req[IN_0].pCrdType),
    .io_in_0_bits_memAttr_allocate  (tx_req[IN_0].memAttr_allocate),
    .io_in_0_bits_memAttr_cacheable (tx_req[IN_0].memAttr_cacheable),
    .io_in_0_bits_memAttr_device    (tx_req[IN_0].memAttr_device),
    .io_in_0_bits_memAttr_ewa       (tx_req[IN_0].memAttr_ewa),
    .io_in_0_bits_snpAttr           (tx_req[IN_0].snpAttr),
    .io_in_0_bits_expCompAck        (tx_req[IN_0].expCompAck),
    .io_in_1_valid                  (tx_req_valid[IN_1]),
    .io_in_1_bits_tgtID             (tx_req[IN_1].tgtID),
    .io_in_1_bits_srcID             (tx_req[IN_1].srcID),
    .io_in_1_bits_txnID             (tx_req[IN_1].txnID),
    .io_in_1_bits_opcode            (tx_req[IN_1].opcode),
    .io_in_1_bits_size              (tx_req[IN_1].size),
    .io_in_1_bits_addr              (tx_req[IN_1].addr),
    .io_in_1_bits_allowRetry        (tx_req[IN_1].allowRetry),
    .io_in_1_bits_order             (tx_req[IN_1].order),
    .io_in_1_bits_pCrdType          (tx_req[IN_1].pCrdType),
    .io_in_1_bits_memAttr_allocate  (tx_req[IN_1].memAttr_allocate),
    .io_in_1_bits_memAttr_cacheable (tx_req[IN_1].memAttr_cacheable),
    .io_in_1_bits_memAttr_device    (tx_req[IN_1].memAttr_device),
    .io_in_1_bits_memAttr_ewa       (tx_req[IN_1].memAttr_ewa),
    .io_in_1_bits_snpAttr           (tx_req[IN_1].snpAttr),
    .io_in_1_bits_expCompAck        (tx_req[IN_1].expCompAck),
    .io_in_2_valid                  (tx_req_valid[IN_2]),
    .io_in_2_bits_tgtID             (tx_req[IN_2].tgtID),
    .io_in_2_bits_srcID             (tx_req[IN_2].srcID),
    .io_in_2_bits_txnID             (tx_req[IN_2].txnID),
    .io_in_2_bits_opcode            (tx_req[IN_2].opcode),
    .io_in_2_bits_size              (tx_req[IN_2].size),
    .io_in_2_bits_addr              (tx_req[IN_2].addr),
    .io_in_2_bits_allowRetry        (tx_req[IN_2].allowRetry),
    .io_in_2_bits_order             (tx_req[IN_2].order),
    .io_in_2_bits_pCrdType          (tx_req[IN_2].pCrdType),
    .io_in_2_bits_memAttr_allocate  (tx_req[IN_2].memAttr_allocate),
    .io_in_2_bits_memAttr_cacheable (tx_req[IN_2].memAttr_cacheable),
    .io_in_2_bits_memAttr_device    (tx_req[IN_2].memAttr_device),
    .io_in_2_bits_memAttr_ewa       (tx_req[IN_2].memAttr_ewa),
    .io_in_2_bits_snpAttr           (tx_req[IN_2].snpAttr),
    .io_in_2_bits_expCompAck        (tx_req[IN_2].expCompAck),
    .io_in_3_valid                  (tx_req_valid[IN_3]),
    .io_in_3_bits_tgtID             (tx_req[IN_3].tgtID),
    .io_in_3_bits_srcID             (tx_req[IN_3].srcID),
    .io_in_3_bits_txnID             (tx_req[IN_3].txnID),
    .io_in_3_bits_opcode            (tx_req[IN_3].opcode),
    .io_in_3_bits_size              (tx_req[IN_3].size),
    .io_in_3_bits_addr              (tx_req[IN_3].addr),
    .io_in_3_bits_allowRetry        (tx_req[IN_3].allowRetry),
    .io_in_3_bits_order             (tx_req[IN_3].order),
    .io_in_3_bits_pCrdType          (tx_req[IN_3].pCrdType),
    .io_in_3_bits_memAttr_allocate  (tx_req[IN_3].memAttr_allocate),
    .io_in_3_bits_memAttr_cacheable (tx_req[IN_3].memAttr_cacheable),
    .io_in_3_bits_memAttr_device    (tx_req[IN_3].memAttr_device),
    .io_in_3_bits_memAttr_ewa       (tx_req[IN_3].memAttr_ewa),
    .io_in_3_bits_snpAttr           (tx_req[IN_3].snpAttr),
    .io_in_3_bits_expCompAck        (tx_req[IN_3].expCompAck),
    .io_out_ready                   (io_out_tx_req_ready),
    .io_out_valid                   (txreq_out_valid),
    .io_out_bits_tgtID              (out_tx_req.tgtID),
    .io_out_bits_srcID              (out_tx_req.srcID),
    .io_out_bits_txnID              (out_tx_req.txnID),
    .io_out_bits_opcode             (out_tx_req.opcode),
    .io_out_bits_size               (out_tx_req.size),
    .io_out_bits_addr               (out_tx_req.addr),
    .io_out_bits_allowRetry         (out_tx_req.allowRetry),
    .io_out_bits_order              (out_tx_req.order),
    .io_out_bits_pCrdType           (out_tx_req.pCrdType),
    .io_out_bits_memAttr_allocate   (out_tx_req.memAttr_allocate),
    .io_out_bits_memAttr_cacheable  (out_tx_req.memAttr_cacheable),
    .io_out_bits_memAttr_device     (out_tx_req.memAttr_device),
    .io_out_bits_memAttr_ewa        (out_tx_req.memAttr_ewa),
    .io_out_bits_snpAttr            (out_tx_req.snpAttr),
    .io_out_bits_expCompAck         (out_tx_req.expCompAck),
    .io_chosen                      (txreq_chosen)
  );

  FastArbiter_46 txdatArb (
    .clock                   (clock),
    .reset                   (reset),
    .io_in_0_valid           (tx_dat_valid[IN_0]),
    .io_in_0_bits_tgtID      (tx_dat[IN_0].tgtID),
    .io_in_0_bits_srcID      (tx_dat[IN_0].srcID),
    .io_in_0_bits_txnID      (tx_dat[IN_0].txnID),
    .io_in_0_bits_homeNID    (tx_dat[IN_0].homeNID),
    .io_in_0_bits_opcode     (tx_dat[IN_0].opcode),
    .io_in_0_bits_resp       (tx_dat[IN_0].resp),
    .io_in_0_bits_dataSource (tx_dat[IN_0].dataSource),
    .io_in_0_bits_dbID       (tx_dat[IN_0].dbID),
    .io_in_0_bits_dataID     (tx_dat[IN_0].dataID),
    .io_in_0_bits_be         (tx_dat[IN_0].be),
    .io_in_0_bits_data       (tx_dat[IN_0].data),
    .io_in_0_bits_dataCheck  (tx_dat[IN_0].dataCheck),
    .io_in_1_valid           (tx_dat_valid[IN_1]),
    .io_in_1_bits_tgtID      (tx_dat[IN_1].tgtID),
    .io_in_1_bits_srcID      (tx_dat[IN_1].srcID),
    .io_in_1_bits_txnID      (tx_dat[IN_1].txnID),
    .io_in_1_bits_homeNID    (tx_dat[IN_1].homeNID),
    .io_in_1_bits_opcode     (tx_dat[IN_1].opcode),
    .io_in_1_bits_resp       (tx_dat[IN_1].resp),
    .io_in_1_bits_dataSource (tx_dat[IN_1].dataSource),
    .io_in_1_bits_dbID       (tx_dat[IN_1].dbID),
    .io_in_1_bits_dataID     (tx_dat[IN_1].dataID),
    .io_in_1_bits_be         (tx_dat[IN_1].be),
    .io_in_1_bits_data       (tx_dat[IN_1].data),
    .io_in_1_bits_dataCheck  (tx_dat[IN_1].dataCheck),
    .io_in_2_valid           (tx_dat_valid[IN_2]),
    .io_in_2_bits_tgtID      (tx_dat[IN_2].tgtID),
    .io_in_2_bits_srcID      (tx_dat[IN_2].srcID),
    .io_in_2_bits_txnID      (tx_dat[IN_2].txnID),
    .io_in_2_bits_homeNID    (tx_dat[IN_2].homeNID),
    .io_in_2_bits_opcode     (tx_dat[IN_2].opcode),
    .io_in_2_bits_resp       (tx_dat[IN_2].resp),
    .io_in_2_bits_dataSource (tx_dat[IN_2].dataSource),
    .io_in_2_bits_dbID       (tx_dat[IN_2].dbID),
    .io_in_2_bits_dataID     (tx_dat[IN_2].dataID),
    .io_in_2_bits_be         (tx_dat[IN_2].be),
    .io_in_2_bits_data       (tx_dat[IN_2].data),
    .io_in_2_bits_dataCheck  (tx_dat[IN_2].dataCheck),
    .io_in_3_valid           (tx_dat_valid[IN_3]),
    .io_in_3_bits_tgtID      (tx_dat[IN_3].tgtID),
    .io_in_3_bits_srcID      (tx_dat[IN_3].srcID),
    .io_in_3_bits_txnID      (tx_dat[IN_3].txnID),
    .io_in_3_bits_homeNID    (tx_dat[IN_3].homeNID),
    .io_in_3_bits_opcode     (tx_dat[IN_3].opcode),
    .io_in_3_bits_resp       (tx_dat[IN_3].resp),
    .io_in_3_bits_dataSource (tx_dat[IN_3].dataSource),
    .io_in_3_bits_dbID       (tx_dat[IN_3].dbID),
    .io_in_3_bits_dataID     (tx_dat[IN_3].dataID),
    .io_in_3_bits_be         (tx_dat[IN_3].be),
    .io_in_3_bits_data       (tx_dat[IN_3].data),
    .io_in_3_bits_dataCheck  (tx_dat[IN_3].dataCheck),
    .io_out_ready            (io_out_tx_dat_ready),
    .io_out_valid            (txdat_out_valid),
    .io_out_bits_tgtID       (out_tx_dat.tgtID),
    .io_out_bits_srcID       (out_tx_dat.srcID),
    .io_out_bits_txnID       (out_tx_dat.txnID),
    .io_out_bits_homeNID     (out_tx_dat.homeNID),
    .io_out_bits_opcode      (out_tx_dat.opcode),
    .io_out_bits_resp        (out_tx_dat.resp),
    .io_out_bits_dataSource  (out_tx_dat.dataSource),
    .io_out_bits_dbID        (out_tx_dat.dbID),
    .io_out_bits_dataID      (out_tx_dat.dataID),
    .io_out_bits_be          (out_tx_dat.be),
    .io_out_bits_data        (out_tx_dat.data),
    .io_out_bits_dataCheck   (out_tx_dat.dataCheck),
    .io_chosen               (txdat_chosen)
  );

  // ===========================================================================
  //  上行 TX ready 解复用: out 就绪 & 仲裁有有效输出 ⇒ 被选中主口 (io_chosen) ready。
  // ===========================================================================
  wire txreq_grant = io_out_tx_req_ready & txreq_out_valid;  // 本拍 TXREQ 真正放行
  wire txdat_grant = io_out_tx_dat_ready & txdat_out_valid;  // 本拍 TXDAT 真正放行

  logic [NUM_IN-1:0] tx_req_ready_o;
  logic [NUM_IN-1:0] tx_dat_ready_o;
  for (genvar i = 0; i < NUM_IN; i++) begin : g_tx_ready
    assign tx_req_ready_o[i] = txreq_grant & (txreq_chosen == 2'(i));
    assign tx_dat_ready_o[i] = txdat_grant & (txdat_chosen == 2'(i));
  end

  // ===========================================================================
  //  下行 RX: out 回送的 RXRSP / RXDAT 按 txnID[10:9] 解复用回主口。
  //  载荷广播 (全部主口取同一 out 载荷), 仅 valid 受路由门控; 无 ready 背压。
  // ===========================================================================
  chi_rsp_t    out_rx_rsp;
  chi_dat_rx_t out_rx_dat;
  assign out_rx_rsp = '{
    srcID:  io_out_rx_rsp_bits_srcID,
    txnID:  io_out_rx_rsp_bits_txnID,
    opcode: io_out_rx_rsp_bits_opcode,
    dbID:   io_out_rx_rsp_bits_dbID};
  assign out_rx_dat = '{
    srcID:  io_out_rx_dat_bits_srcID,
    txnID:  io_out_rx_dat_bits_txnID,
    opcode: io_out_rx_dat_bits_opcode,
    resp:   io_out_rx_dat_bits_resp,
    dataID: io_out_rx_dat_bits_dataID,
    data:   io_out_rx_dat_bits_data};

  logic [NUM_IN-1:0] rx_rsp_valid_o;  // 各主口本拍是否收到 RXRSP (= valid & 路由命中)
  logic [NUM_IN-1:0] rx_dat_valid_o;  // 各主口本拍是否收到 RXDAT
  for (genvar i = 0; i < NUM_IN; i++) begin : g_rx_demux
    assign rx_rsp_valid_o[i] = io_out_rx_rsp_valid & (rx_route(out_rx_rsp.txnID) == 2'(i));
    assign rx_dat_valid_o[i] = io_out_rx_dat_valid & (rx_route(out_rx_dat.txnID) == 2'(i));
  end

  // ===========================================================================
  //  端口输出装配
  // ===========================================================================
  // ---- 主口 in_0 ----
  assign io_in_0_tx_req_ready      = tx_req_ready_o[IN_0];
  assign io_in_0_tx_dat_ready      = tx_dat_ready_o[IN_0];
  assign io_in_0_rx_rsp_valid      = rx_rsp_valid_o[IN_0];
  assign io_in_0_rx_rsp_bits_srcID = out_rx_rsp.srcID;
  assign io_in_0_rx_rsp_bits_txnID = out_rx_rsp.txnID;
  assign io_in_0_rx_rsp_bits_opcode= out_rx_rsp.opcode;
  assign io_in_0_rx_rsp_bits_dbID  = out_rx_rsp.dbID;
  assign io_in_0_rx_dat_valid      = rx_dat_valid_o[IN_0];
  assign io_in_0_rx_dat_bits_srcID = out_rx_dat.srcID;
  assign io_in_0_rx_dat_bits_txnID = out_rx_dat.txnID;
  assign io_in_0_rx_dat_bits_opcode= out_rx_dat.opcode;
  assign io_in_0_rx_dat_bits_resp  = out_rx_dat.resp;
  assign io_in_0_rx_dat_bits_dataID= out_rx_dat.dataID;
  assign io_in_0_rx_dat_bits_data  = out_rx_dat.data;
  // ---- 主口 in_1 ----
  assign io_in_1_tx_req_ready      = tx_req_ready_o[IN_1];
  assign io_in_1_tx_dat_ready      = tx_dat_ready_o[IN_1];
  assign io_in_1_rx_rsp_valid      = rx_rsp_valid_o[IN_1];
  assign io_in_1_rx_rsp_bits_srcID = out_rx_rsp.srcID;
  assign io_in_1_rx_rsp_bits_txnID = out_rx_rsp.txnID;
  assign io_in_1_rx_rsp_bits_opcode= out_rx_rsp.opcode;
  assign io_in_1_rx_rsp_bits_dbID  = out_rx_rsp.dbID;
  assign io_in_1_rx_dat_valid      = rx_dat_valid_o[IN_1];
  assign io_in_1_rx_dat_bits_srcID = out_rx_dat.srcID;
  assign io_in_1_rx_dat_bits_txnID = out_rx_dat.txnID;
  assign io_in_1_rx_dat_bits_opcode= out_rx_dat.opcode;
  assign io_in_1_rx_dat_bits_resp  = out_rx_dat.resp;
  assign io_in_1_rx_dat_bits_dataID= out_rx_dat.dataID;
  assign io_in_1_rx_dat_bits_data  = out_rx_dat.data;
  // ---- 主口 in_2 ----
  assign io_in_2_tx_req_ready      = tx_req_ready_o[IN_2];
  assign io_in_2_tx_dat_ready      = tx_dat_ready_o[IN_2];
  assign io_in_2_rx_rsp_valid      = rx_rsp_valid_o[IN_2];
  assign io_in_2_rx_rsp_bits_srcID = out_rx_rsp.srcID;
  assign io_in_2_rx_rsp_bits_txnID = out_rx_rsp.txnID;
  assign io_in_2_rx_rsp_bits_opcode= out_rx_rsp.opcode;
  assign io_in_2_rx_rsp_bits_dbID  = out_rx_rsp.dbID;
  assign io_in_2_rx_dat_valid      = rx_dat_valid_o[IN_2];
  assign io_in_2_rx_dat_bits_srcID = out_rx_dat.srcID;
  assign io_in_2_rx_dat_bits_txnID = out_rx_dat.txnID;
  assign io_in_2_rx_dat_bits_opcode= out_rx_dat.opcode;
  assign io_in_2_rx_dat_bits_resp  = out_rx_dat.resp;
  assign io_in_2_rx_dat_bits_dataID= out_rx_dat.dataID;
  assign io_in_2_rx_dat_bits_data  = out_rx_dat.data;
  // ---- 主口 in_3 ----
  assign io_in_3_tx_req_ready      = tx_req_ready_o[IN_3];
  assign io_in_3_tx_dat_ready      = tx_dat_ready_o[IN_3];
  assign io_in_3_rx_rsp_valid      = rx_rsp_valid_o[IN_3];
  assign io_in_3_rx_rsp_bits_srcID = out_rx_rsp.srcID;
  assign io_in_3_rx_rsp_bits_txnID = out_rx_rsp.txnID;
  assign io_in_3_rx_rsp_bits_opcode= out_rx_rsp.opcode;
  assign io_in_3_rx_rsp_bits_dbID  = out_rx_rsp.dbID;
  assign io_in_3_rx_dat_valid      = rx_dat_valid_o[IN_3];
  assign io_in_3_rx_dat_bits_srcID = out_rx_dat.srcID;
  assign io_in_3_rx_dat_bits_txnID = out_rx_dat.txnID;
  assign io_in_3_rx_dat_bits_opcode= out_rx_dat.opcode;
  assign io_in_3_rx_dat_bits_resp  = out_rx_dat.resp;
  assign io_in_3_rx_dat_bits_dataID= out_rx_dat.dataID;
  assign io_in_3_rx_dat_bits_data  = out_rx_dat.data;

  // ---- 从口 out: TX 胜者载荷 / RX ready (各主口接受信号 OR) ----
  assign io_out_tx_req_valid               = txreq_out_valid;
  assign io_out_tx_req_bits_tgtID          = out_tx_req.tgtID;
  assign io_out_tx_req_bits_srcID          = out_tx_req.srcID;
  assign io_out_tx_req_bits_txnID          = out_tx_req.txnID;
  assign io_out_tx_req_bits_opcode         = out_tx_req.opcode;
  assign io_out_tx_req_bits_size           = out_tx_req.size;
  assign io_out_tx_req_bits_addr           = out_tx_req.addr;
  assign io_out_tx_req_bits_allowRetry     = out_tx_req.allowRetry;
  assign io_out_tx_req_bits_order          = out_tx_req.order;
  assign io_out_tx_req_bits_pCrdType       = out_tx_req.pCrdType;
  assign io_out_tx_req_bits_memAttr_allocate  = out_tx_req.memAttr_allocate;
  assign io_out_tx_req_bits_memAttr_cacheable = out_tx_req.memAttr_cacheable;
  assign io_out_tx_req_bits_memAttr_device    = out_tx_req.memAttr_device;
  assign io_out_tx_req_bits_memAttr_ewa       = out_tx_req.memAttr_ewa;
  assign io_out_tx_req_bits_snpAttr        = out_tx_req.snpAttr;
  assign io_out_tx_req_bits_expCompAck     = out_tx_req.expCompAck;

  assign io_out_tx_dat_valid               = txdat_out_valid;
  assign io_out_tx_dat_bits_tgtID          = out_tx_dat.tgtID;
  assign io_out_tx_dat_bits_srcID          = out_tx_dat.srcID;
  assign io_out_tx_dat_bits_txnID          = out_tx_dat.txnID;
  assign io_out_tx_dat_bits_homeNID        = out_tx_dat.homeNID;
  assign io_out_tx_dat_bits_opcode         = out_tx_dat.opcode;
  assign io_out_tx_dat_bits_resp           = out_tx_dat.resp;
  assign io_out_tx_dat_bits_dataSource     = out_tx_dat.dataSource;
  assign io_out_tx_dat_bits_dbID           = out_tx_dat.dbID;
  assign io_out_tx_dat_bits_dataID         = out_tx_dat.dataID;
  assign io_out_tx_dat_bits_be             = out_tx_dat.be;
  assign io_out_tx_dat_bits_data           = out_tx_dat.data;
  assign io_out_tx_dat_bits_dataCheck      = out_tx_dat.dataCheck;

  assign io_out_rx_rsp_ready = |rx_rsp_valid_o;
  assign io_out_rx_dat_ready = |rx_dat_valid_o;

endmodule

// =============================================================================
//  LinkMonitor —— 香山 V2R2 CHI 链路层监视器 (可读重写核 xs_LinkMonitor_core)
// -----------------------------------------------------------------------------
//  源自 OpenLLC 的 LinkMonitor (chi/LinkLayer.scala 的 RN 侧链路监视器): 把上层
//  Decoupled(ready/valid) 接口 (io_in_*) 与下层 CHI 物理链路的 flit + L-Credit
//  协议 (io_out_*) 互转, 并管理链路激活/去激活握手。从设计意图重写 (非照抄 firtool
//  的 _GEN/_T 展平命名)。
//
//  本核自身逻辑 (除黑盒子模块外):
//    · LINKACTIVE 状态机 txState/rxState: 由对端 {linkactivereq, linkactiveack}
//      译码 4 态 (STOP/ACTIVATE/RUN/DEACTIVATE), 下发给各 flit 转换子模块;
//      两个方向逻辑对称, 折叠成 link_st[DIR_TX/DIR_RX] 数组循环。
//    · 链路握手: tx.linkactivereq 复位后恒拉高 (本端总想激活链路);
//      rx.linkactiveack = RegNext(rx.linkactivereq) | ~rxDeact —— 即对端撤请求后,
//      仍要把三个 RX 子模块欠的 L-Credit 全部回收 (reclaim 全 1) 才允许撤确认。
//    · 系统一致性: syscoreq 复位后恒高, syscoack 为其 RegNext; txsactive 指示。
//    · 性能计数器: RetryAck / PCrdGrant 响应数、不可重试请求数 (仅监测, 无端口)。
//    · 给上行 (TX) flit 注入本节点 srcID = io_nodeID。
//
//  黑盒子模块 (flit ↔ Decoupled + L-Credit 流控主体, 不在本核重写):
//    Decoupled2LCredit      txreq  : 上层请求 → REQ flit (带 L-Credit 发送);
//    Decoupled2LCredit_1    txrsp  : 上层响应 → RSP flit;
//    Decoupled2LCredit_2    txdat  : 上层写数据 → DAT flit;
//    LCredit2Decoupled      rxsnp  : SNP flit → 上层 (带 L-Credit 接收);
//    LCredit2Decoupled_1    rxrsp  : RSP flit → 上层;
//    LCredit2Decoupled_2    rxdat  : DAT flit → 上层。
//  六者在 golden 与本核同名同端口例化 (io_state_state 取本核的 link 态), UT 两侧
//  共用、FM 两侧黑盒, 故验证聚焦本核的链路态机/握手/计数逻辑。
//
//  验证: golden 同名 LinkMonitor 例化本核; UT 双例化逐拍比对全部输出; FM 签名分析。
// =============================================================================
module xs_LinkMonitor_core
  import linkmonitor_pkg::*;
(
  input          clock,
  input          reset,

  // ====== 上层 TX REQ (Decoupled 请求输入) ======
  output         io_in_tx_req_ready,
  input          io_in_tx_req_valid,
  input  [3:0]   io_in_tx_req_bits_qos,
  input  [10:0]  io_in_tx_req_bits_tgtID,
  input  [11:0]  io_in_tx_req_bits_txnID,
  input  [10:0]  io_in_tx_req_bits_returnNID,
  input          io_in_tx_req_bits_stashNIDValid,
  input  [11:0]  io_in_tx_req_bits_returnTxnID,
  input  [6:0]   io_in_tx_req_bits_opcode,
  input  [2:0]   io_in_tx_req_bits_size,
  input  [47:0]  io_in_tx_req_bits_addr,
  input          io_in_tx_req_bits_ns,
  input          io_in_tx_req_bits_likelyshared,
  input          io_in_tx_req_bits_allowRetry,
  input  [1:0]   io_in_tx_req_bits_order,
  input  [3:0]   io_in_tx_req_bits_pCrdType,
  input          io_in_tx_req_bits_memAttr_allocate,
  input          io_in_tx_req_bits_memAttr_cacheable,
  input          io_in_tx_req_bits_memAttr_device,
  input          io_in_tx_req_bits_memAttr_ewa,
  input          io_in_tx_req_bits_snpAttr,
  input  [7:0]   io_in_tx_req_bits_lpIDWithPadding,
  input          io_in_tx_req_bits_snoopMe,
  input          io_in_tx_req_bits_expCompAck,
  input  [1:0]   io_in_tx_req_bits_tagOp,
  input          io_in_tx_req_bits_traceTag,
  input          io_in_tx_req_bits_mpam_perfMonGroup,
  input  [8:0]   io_in_tx_req_bits_mpam_partID,
  input          io_in_tx_req_bits_mpam_mpamNS,
  input  [3:0]   io_in_tx_req_bits_rsvdc,

  // ====== 上层 TX RSP ======
  output         io_in_tx_rsp_ready,
  input          io_in_tx_rsp_valid,
  input  [3:0]   io_in_tx_rsp_bits_qos,
  input  [10:0]  io_in_tx_rsp_bits_tgtID,
  input  [11:0]  io_in_tx_rsp_bits_txnID,
  input  [4:0]   io_in_tx_rsp_bits_opcode,
  input  [1:0]   io_in_tx_rsp_bits_respErr,
  input  [2:0]   io_in_tx_rsp_bits_resp,
  input  [2:0]   io_in_tx_rsp_bits_fwdState,
  input  [2:0]   io_in_tx_rsp_bits_cBusy,
  input  [11:0]  io_in_tx_rsp_bits_dbID,
  input  [3:0]   io_in_tx_rsp_bits_pCrdType,
  input  [1:0]   io_in_tx_rsp_bits_tagOp,
  input          io_in_tx_rsp_bits_traceTag,

  // ====== 上层 TX DAT ======
  output         io_in_tx_dat_ready,
  input          io_in_tx_dat_valid,
  input  [3:0]   io_in_tx_dat_bits_qos,
  input  [10:0]  io_in_tx_dat_bits_tgtID,
  input  [11:0]  io_in_tx_dat_bits_txnID,
  input  [10:0]  io_in_tx_dat_bits_homeNID,
  input  [3:0]   io_in_tx_dat_bits_opcode,
  input  [1:0]   io_in_tx_dat_bits_respErr,
  input  [2:0]   io_in_tx_dat_bits_resp,
  input  [3:0]   io_in_tx_dat_bits_dataSource,
  input  [2:0]   io_in_tx_dat_bits_cBusy,
  input  [11:0]  io_in_tx_dat_bits_dbID,
  input  [1:0]   io_in_tx_dat_bits_ccID,
  input  [1:0]   io_in_tx_dat_bits_dataID,
  input  [1:0]   io_in_tx_dat_bits_tagOp,
  input  [7:0]   io_in_tx_dat_bits_tag,
  input  [1:0]   io_in_tx_dat_bits_tu,
  input          io_in_tx_dat_bits_traceTag,
  input  [3:0]   io_in_tx_dat_bits_rsvdc,
  input  [31:0]  io_in_tx_dat_bits_be,
  input  [255:0] io_in_tx_dat_bits_data,
  input  [31:0]  io_in_tx_dat_bits_dataCheck,
  input  [3:0]   io_in_tx_dat_bits_poison,

  // ====== 上层 RX RSP (Decoupled 响应输出) ======
  input          io_in_rx_rsp_ready,
  output         io_in_rx_rsp_valid,
  output [3:0]   io_in_rx_rsp_bits_qos,
  output [10:0]  io_in_rx_rsp_bits_tgtID,
  output [10:0]  io_in_rx_rsp_bits_srcID,
  output [11:0]  io_in_rx_rsp_bits_txnID,
  output [4:0]   io_in_rx_rsp_bits_opcode,
  output [1:0]   io_in_rx_rsp_bits_respErr,
  output [2:0]   io_in_rx_rsp_bits_resp,
  output [2:0]   io_in_rx_rsp_bits_fwdState,
  output [2:0]   io_in_rx_rsp_bits_cBusy,
  output [11:0]  io_in_rx_rsp_bits_dbID,
  output [3:0]   io_in_rx_rsp_bits_pCrdType,
  output [1:0]   io_in_rx_rsp_bits_tagOp,
  output         io_in_rx_rsp_bits_traceTag,

  // ====== 上层 RX DAT ======
  input          io_in_rx_dat_ready,
  output         io_in_rx_dat_valid,
  output [3:0]   io_in_rx_dat_bits_qos,
  output [10:0]  io_in_rx_dat_bits_tgtID,
  output [10:0]  io_in_rx_dat_bits_srcID,
  output [11:0]  io_in_rx_dat_bits_txnID,
  output [10:0]  io_in_rx_dat_bits_homeNID,
  output [3:0]   io_in_rx_dat_bits_opcode,
  output [1:0]   io_in_rx_dat_bits_respErr,
  output [2:0]   io_in_rx_dat_bits_resp,
  output [3:0]   io_in_rx_dat_bits_dataSource,
  output [2:0]   io_in_rx_dat_bits_cBusy,
  output [11:0]  io_in_rx_dat_bits_dbID,
  output [1:0]   io_in_rx_dat_bits_ccID,
  output [1:0]   io_in_rx_dat_bits_dataID,
  output [1:0]   io_in_rx_dat_bits_tagOp,
  output [7:0]   io_in_rx_dat_bits_tag,
  output [1:0]   io_in_rx_dat_bits_tu,
  output         io_in_rx_dat_bits_traceTag,
  output [3:0]   io_in_rx_dat_bits_rsvdc,
  output [31:0]  io_in_rx_dat_bits_be,
  output [255:0] io_in_rx_dat_bits_data,
  output [31:0]  io_in_rx_dat_bits_dataCheck,
  output [3:0]   io_in_rx_dat_bits_poison,

  // ====== 上层 RX SNP ======
  input          io_in_rx_snp_ready,
  output         io_in_rx_snp_valid,
  output [3:0]   io_in_rx_snp_bits_qos,
  output [10:0]  io_in_rx_snp_bits_srcID,
  output [11:0]  io_in_rx_snp_bits_txnID,
  output [10:0]  io_in_rx_snp_bits_fwdNID,
  output [11:0]  io_in_rx_snp_bits_fwdTxnID,
  output [4:0]   io_in_rx_snp_bits_opcode,
  output [44:0]  io_in_rx_snp_bits_addr,
  output         io_in_rx_snp_bits_ns,
  output         io_in_rx_snp_bits_doNotGoToSD,
  output         io_in_rx_snp_bits_retToSrc,
  output         io_in_rx_snp_bits_traceTag,
  output         io_in_rx_snp_bits_mpam_perfMonGroup,
  output [8:0]   io_in_rx_snp_bits_mpam_partID,
  output         io_in_rx_snp_bits_mpam_mpamNS,

  // ====== 下层 CHI 物理链路 (flit + L-Credit + linkactive 握手) ======
  output         io_out_txsactive,
  input          io_out_rxsactive,
  output         io_out_syscoreq,
  input          io_out_syscoack,
  output         io_out_tx_linkactivereq,
  input          io_out_tx_linkactiveack,
  output         io_out_tx_req_flitpend,
  output         io_out_tx_req_flitv,
  output [161:0] io_out_tx_req_flit,
  input          io_out_tx_req_lcrdv,
  output         io_out_tx_rsp_flitpend,
  output         io_out_tx_rsp_flitv,
  output [72:0]  io_out_tx_rsp_flit,
  input          io_out_tx_rsp_lcrdv,
  output         io_out_tx_dat_flitpend,
  output         io_out_tx_dat_flitv,
  output [421:0] io_out_tx_dat_flit,
  input          io_out_tx_dat_lcrdv,
  input          io_out_rx_linkactivereq,
  output         io_out_rx_linkactiveack,
  input          io_out_rx_rsp_flitpend,
  input          io_out_rx_rsp_flitv,
  input  [72:0]  io_out_rx_rsp_flit,
  output         io_out_rx_rsp_lcrdv,
  input          io_out_rx_dat_flitpend,
  input          io_out_rx_dat_flitv,
  input  [421:0] io_out_rx_dat_flit,
  output         io_out_rx_dat_lcrdv,
  input          io_out_rx_snp_flitpend,
  input          io_out_rx_snp_flitv,
  input  [114:0] io_out_rx_snp_flit,
  output         io_out_rx_snp_lcrdv,

  input  [10:0]  io_nodeID
);

  // ===========================================================================
  //  子模块对外暴露的内部信号 (用于本核的握手/计数逻辑)
  // ===========================================================================
  wire        txreq_in_ready;     // Decoupled2LCredit txreq 的 io_in_ready
  wire        rxrsp_out_valid;    // LCredit2Decoupled rxrsp 的 io_out_valid
  wire [4:0]  rxrsp_out_opcode;   // LCredit2Decoupled rxrsp 的 io_out_bits_opcode
  wire        rxsnp_reclaim;      // 三个 RX 子模块的 L-Credit 回收完成标志
  wire        rxrsp_reclaim;
  wire        rxdat_reclaim;

  // ===========================================================================
  //  LINKACTIVE 状态机 (TX / RX 两方向对称, 折叠成数组)
  //    DIR_TX 由 {tx.linkactivereq(本端寄存器), tx.linkactiveack(对端)} 译码;
  //    DIR_RX 由 {rx.linkactivereq(对端), rx.linkactiveack(本端寄存器)} 译码。
  // ===========================================================================
  link_state_e link_st [2];        // 链路态寄存器 (RegInit STOP)
  reg          tx_linkactivereq_q; // 本端 tx.linkactivereq (复位后恒 1)
  reg          rx_linkactiveack_d; // RegNext(rx.linkactivereq), 仅时钟无复位
  reg          rx_linkactiveack_q; // 本端 rx.linkactiveack (含 L-Credit 回收保持)
  reg          syscoreq_q;         // 系统一致性请求 (复位后恒 1)
  reg          txsactive_q;        // txsactive 指示

  // 各方向送入译码器的 {req, ack} (读当前寄存器值, 非阻塞更新 ⇒ 用上一拍值)。
  wire [1:0]   reqack_tx = {tx_linkactivereq_q, io_out_tx_linkactiveack};
  wire [1:0]   reqack_rx = {io_out_rx_linkactivereq, rx_linkactiveack_q};

  // 去激活条件: 三个 RX 子模块的 L-Credit 全部回收完毕。
  wire         rx_deact = rxsnp_reclaim & rxrsp_reclaim & rxdat_reclaim;

  // RX RSP 实际握手成功 (上层 ready & 子模块 valid), 供性能计数。
  wire         rxrsp_fire = io_in_rx_rsp_ready & rxrsp_out_valid;

  // ===========================================================================
  //  时序: 链路态机 / 握手寄存器 / 性能计数器 (异步复位)
  // ===========================================================================
  reg [63:0] retryAckCnt;     // 收到的 RetryAck 响应计数 (仅监测, 无输出端口)
  reg [63:0] pCrdGrantCnt;    // 收到的 PCrdGrant 响应计数
  reg [63:0] noAllowRetryCnt; // 发出的不可重试 (allowRetry=0) 请求计数

  integer d;
  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      for (d = 0; d < 2; d = d + 1) link_st[d] <= STOP;
      tx_linkactivereq_q <= 1'b0;
      rx_linkactiveack_q <= 1'b0;
      syscoreq_q         <= 1'b0;
      txsactive_q        <= 1'b0;
      retryAckCnt        <= 64'h0;
      pCrdGrantCnt       <= 64'h0;
      noAllowRetryCnt    <= 64'h0;
    end else begin
      // 链路态机 (两方向同一译码函数)。
      link_st[DIR_TX] <= link_state(reqack_tx[1], reqack_tx[0]);
      link_st[DIR_RX] <= link_state(reqack_rx[1], reqack_rx[0]);
      // 本端 TX 链路始终请求激活; 系统一致性始终请求。
      tx_linkactivereq_q <= 1'b1;
      syscoreq_q         <= 1'b1;
      // RX 确认: 对端请求的延迟值, 或仍有 L-Credit 未回收 (去激活未完成) 时保持高。
      rx_linkactiveack_q <= rx_linkactiveack_d | ~rx_deact;
      // txsactive = syscoreq 或 syscoack (= ~(~syscoreq & ~syscoack))。
      txsactive_q        <= syscoreq_q | io_out_syscoack;
      // 性能计数器。
      if (rxrsp_fire & (rxrsp_out_opcode == RSP_OP_RETRYACK))
        retryAckCnt  <= retryAckCnt + 64'h1;
      if (rxrsp_fire & (rxrsp_out_opcode == RSP_OP_PCRDGRANT))
        pCrdGrantCnt <= pCrdGrantCnt + 64'h1;
      if (txreq_in_ready & io_in_tx_req_valid & ~io_in_tx_req_bits_allowRetry)
        noAllowRetryCnt <= noAllowRetryCnt + 64'h1;
    end
  end

  // rx.linkactiveack 的一拍延迟版 (无复位, 与 golden 的 RegNext 一致)。
  always_ff @(posedge clock)
    rx_linkactiveack_d <= io_out_rx_linkactivereq;

  // ===========================================================================
  //  上行 TX flit 转换子模块 (Decoupled → flit), srcID 注入本节点 io_nodeID。
  // ===========================================================================
  Decoupled2LCredit Decoupled2LCredit_txreq (
    .clock                        (clock),
    .reset                        (reset),
    .io_in_ready                  (txreq_in_ready),
    .io_in_valid                  (io_in_tx_req_valid),
    .io_in_bits_qos               (io_in_tx_req_bits_qos),
    .io_in_bits_tgtID             (io_in_tx_req_bits_tgtID),
    .io_in_bits_srcID             (io_nodeID),
    .io_in_bits_txnID             (io_in_tx_req_bits_txnID),
    .io_in_bits_returnNID         (io_in_tx_req_bits_returnNID),
    .io_in_bits_stashNIDValid     (io_in_tx_req_bits_stashNIDValid),
    .io_in_bits_returnTxnID       (io_in_tx_req_bits_returnTxnID),
    .io_in_bits_opcode            (io_in_tx_req_bits_opcode),
    .io_in_bits_size              (io_in_tx_req_bits_size),
    .io_in_bits_addr              (io_in_tx_req_bits_addr),
    .io_in_bits_ns                (io_in_tx_req_bits_ns),
    .io_in_bits_likelyshared      (io_in_tx_req_bits_likelyshared),
    .io_in_bits_allowRetry        (io_in_tx_req_bits_allowRetry),
    .io_in_bits_order             (io_in_tx_req_bits_order),
    .io_in_bits_pCrdType          (io_in_tx_req_bits_pCrdType),
    .io_in_bits_memAttr_allocate  (io_in_tx_req_bits_memAttr_allocate),
    .io_in_bits_memAttr_cacheable (io_in_tx_req_bits_memAttr_cacheable),
    .io_in_bits_memAttr_device    (io_in_tx_req_bits_memAttr_device),
    .io_in_bits_memAttr_ewa       (io_in_tx_req_bits_memAttr_ewa),
    .io_in_bits_snpAttr           (io_in_tx_req_bits_snpAttr),
    .io_in_bits_lpIDWithPadding   (io_in_tx_req_bits_lpIDWithPadding),
    .io_in_bits_snoopMe           (io_in_tx_req_bits_snoopMe),
    .io_in_bits_expCompAck        (io_in_tx_req_bits_expCompAck),
    .io_in_bits_tagOp             (io_in_tx_req_bits_tagOp),
    .io_in_bits_traceTag          (io_in_tx_req_bits_traceTag),
    .io_in_bits_mpam_perfMonGroup (io_in_tx_req_bits_mpam_perfMonGroup),
    .io_in_bits_mpam_partID       (io_in_tx_req_bits_mpam_partID),
    .io_in_bits_mpam_mpamNS       (io_in_tx_req_bits_mpam_mpamNS),
    .io_in_bits_rsvdc             (io_in_tx_req_bits_rsvdc),
    .io_out_flitpend              (io_out_tx_req_flitpend),
    .io_out_flitv                 (io_out_tx_req_flitv),
    .io_out_flit                  (io_out_tx_req_flit),
    .io_out_lcrdv                 (io_out_tx_req_lcrdv),
    .io_state_state               (link_st[DIR_TX])
  );
  Decoupled2LCredit_1 Decoupled2LCredit_txrsp (
    .clock               (clock),
    .reset               (reset),
    .io_in_ready         (io_in_tx_rsp_ready),
    .io_in_valid         (io_in_tx_rsp_valid),
    .io_in_bits_qos      (io_in_tx_rsp_bits_qos),
    .io_in_bits_tgtID    (io_in_tx_rsp_bits_tgtID),
    .io_in_bits_srcID    (io_nodeID),
    .io_in_bits_txnID    (io_in_tx_rsp_bits_txnID),
    .io_in_bits_opcode   (io_in_tx_rsp_bits_opcode),
    .io_in_bits_respErr  (io_in_tx_rsp_bits_respErr),
    .io_in_bits_resp     (io_in_tx_rsp_bits_resp),
    .io_in_bits_fwdState (io_in_tx_rsp_bits_fwdState),
    .io_in_bits_cBusy    (io_in_tx_rsp_bits_cBusy),
    .io_in_bits_dbID     (io_in_tx_rsp_bits_dbID),
    .io_in_bits_pCrdType (io_in_tx_rsp_bits_pCrdType),
    .io_in_bits_tagOp    (io_in_tx_rsp_bits_tagOp),
    .io_in_bits_traceTag (io_in_tx_rsp_bits_traceTag),
    .io_out_flitpend     (io_out_tx_rsp_flitpend),
    .io_out_flitv        (io_out_tx_rsp_flitv),
    .io_out_flit         (io_out_tx_rsp_flit),
    .io_out_lcrdv        (io_out_tx_rsp_lcrdv),
    .io_state_state      (link_st[DIR_TX])
  );
  Decoupled2LCredit_2 Decoupled2LCredit_txdat (
    .clock                 (clock),
    .reset                 (reset),
    .io_in_ready           (io_in_tx_dat_ready),
    .io_in_valid           (io_in_tx_dat_valid),
    .io_in_bits_qos        (io_in_tx_dat_bits_qos),
    .io_in_bits_tgtID      (io_in_tx_dat_bits_tgtID),
    .io_in_bits_srcID      (io_nodeID),
    .io_in_bits_txnID      (io_in_tx_dat_bits_txnID),
    .io_in_bits_homeNID    (io_in_tx_dat_bits_homeNID),
    .io_in_bits_opcode     (io_in_tx_dat_bits_opcode),
    .io_in_bits_respErr    (io_in_tx_dat_bits_respErr),
    .io_in_bits_resp       (io_in_tx_dat_bits_resp),
    .io_in_bits_dataSource (io_in_tx_dat_bits_dataSource),
    .io_in_bits_cBusy      (io_in_tx_dat_bits_cBusy),
    .io_in_bits_dbID       (io_in_tx_dat_bits_dbID),
    .io_in_bits_ccID       (io_in_tx_dat_bits_ccID),
    .io_in_bits_dataID     (io_in_tx_dat_bits_dataID),
    .io_in_bits_tagOp      (io_in_tx_dat_bits_tagOp),
    .io_in_bits_tag        (io_in_tx_dat_bits_tag),
    .io_in_bits_tu         (io_in_tx_dat_bits_tu),
    .io_in_bits_traceTag   (io_in_tx_dat_bits_traceTag),
    .io_in_bits_rsvdc      (io_in_tx_dat_bits_rsvdc),
    .io_in_bits_be         (io_in_tx_dat_bits_be),
    .io_in_bits_data       (io_in_tx_dat_bits_data),
    .io_in_bits_dataCheck  (io_in_tx_dat_bits_dataCheck),
    .io_in_bits_poison     (io_in_tx_dat_bits_poison),
    .io_out_flitpend       (io_out_tx_dat_flitpend),
    .io_out_flitv          (io_out_tx_dat_flitv),
    .io_out_flit           (io_out_tx_dat_flit),
    .io_out_lcrdv          (io_out_tx_dat_lcrdv),
    .io_state_state        (link_st[DIR_TX])
  );

  // ===========================================================================
  //  下行 RX flit 转换子模块 (flit → Decoupled), 各自回报 L-Credit 回收完成。
  // ===========================================================================
  LCredit2Decoupled LCredit2Decoupled_rxsnp (
    .clock                         (clock),
    .reset                         (reset),
    .io_in_flitv                   (io_out_rx_snp_flitv),
    .io_in_flit                    (io_out_rx_snp_flit),
    .io_in_lcrdv                   (io_out_rx_snp_lcrdv),
    .io_out_ready                  (io_in_rx_snp_ready),
    .io_out_valid                  (io_in_rx_snp_valid),
    .io_out_bits_qos               (io_in_rx_snp_bits_qos),
    .io_out_bits_srcID             (io_in_rx_snp_bits_srcID),
    .io_out_bits_txnID             (io_in_rx_snp_bits_txnID),
    .io_out_bits_fwdNID            (io_in_rx_snp_bits_fwdNID),
    .io_out_bits_fwdTxnID          (io_in_rx_snp_bits_fwdTxnID),
    .io_out_bits_opcode            (io_in_rx_snp_bits_opcode),
    .io_out_bits_addr              (io_in_rx_snp_bits_addr),
    .io_out_bits_ns                (io_in_rx_snp_bits_ns),
    .io_out_bits_doNotGoToSD       (io_in_rx_snp_bits_doNotGoToSD),
    .io_out_bits_retToSrc          (io_in_rx_snp_bits_retToSrc),
    .io_out_bits_traceTag          (io_in_rx_snp_bits_traceTag),
    .io_out_bits_mpam_perfMonGroup (io_in_rx_snp_bits_mpam_perfMonGroup),
    .io_out_bits_mpam_partID       (io_in_rx_snp_bits_mpam_partID),
    .io_out_bits_mpam_mpamNS       (io_in_rx_snp_bits_mpam_mpamNS),
    .io_state_state                (link_st[DIR_RX]),
    .io_reclaimLCredit             (rxsnp_reclaim)
  );
  LCredit2Decoupled_1 LCredit2Decoupled_rxrsp (
    .clock                (clock),
    .reset                (reset),
    .io_in_flitv          (io_out_rx_rsp_flitv),
    .io_in_flit           (io_out_rx_rsp_flit),
    .io_in_lcrdv          (io_out_rx_rsp_lcrdv),
    .io_out_ready         (io_in_rx_rsp_ready),
    .io_out_valid         (rxrsp_out_valid),
    .io_out_bits_qos      (io_in_rx_rsp_bits_qos),
    .io_out_bits_tgtID    (io_in_rx_rsp_bits_tgtID),
    .io_out_bits_srcID    (io_in_rx_rsp_bits_srcID),
    .io_out_bits_txnID    (io_in_rx_rsp_bits_txnID),
    .io_out_bits_opcode   (rxrsp_out_opcode),
    .io_out_bits_respErr  (io_in_rx_rsp_bits_respErr),
    .io_out_bits_resp     (io_in_rx_rsp_bits_resp),
    .io_out_bits_fwdState (io_in_rx_rsp_bits_fwdState),
    .io_out_bits_cBusy    (io_in_rx_rsp_bits_cBusy),
    .io_out_bits_dbID     (io_in_rx_rsp_bits_dbID),
    .io_out_bits_pCrdType (io_in_rx_rsp_bits_pCrdType),
    .io_out_bits_tagOp    (io_in_rx_rsp_bits_tagOp),
    .io_out_bits_traceTag (io_in_rx_rsp_bits_traceTag),
    .io_state_state       (link_st[DIR_RX]),
    .io_reclaimLCredit    (rxrsp_reclaim)
  );
  LCredit2Decoupled_2 LCredit2Decoupled_rxdat (
    .clock                  (clock),
    .reset                  (reset),
    .io_in_flitv            (io_out_rx_dat_flitv),
    .io_in_flit             (io_out_rx_dat_flit),
    .io_in_lcrdv            (io_out_rx_dat_lcrdv),
    .io_out_ready           (io_in_rx_dat_ready),
    .io_out_valid           (io_in_rx_dat_valid),
    .io_out_bits_qos        (io_in_rx_dat_bits_qos),
    .io_out_bits_tgtID      (io_in_rx_dat_bits_tgtID),
    .io_out_bits_srcID      (io_in_rx_dat_bits_srcID),
    .io_out_bits_txnID      (io_in_rx_dat_bits_txnID),
    .io_out_bits_homeNID    (io_in_rx_dat_bits_homeNID),
    .io_out_bits_opcode     (io_in_rx_dat_bits_opcode),
    .io_out_bits_respErr    (io_in_rx_dat_bits_respErr),
    .io_out_bits_resp       (io_in_rx_dat_bits_resp),
    .io_out_bits_dataSource (io_in_rx_dat_bits_dataSource),
    .io_out_bits_cBusy      (io_in_rx_dat_bits_cBusy),
    .io_out_bits_dbID       (io_in_rx_dat_bits_dbID),
    .io_out_bits_ccID       (io_in_rx_dat_bits_ccID),
    .io_out_bits_dataID     (io_in_rx_dat_bits_dataID),
    .io_out_bits_tagOp      (io_in_rx_dat_bits_tagOp),
    .io_out_bits_tag        (io_in_rx_dat_bits_tag),
    .io_out_bits_tu         (io_in_rx_dat_bits_tu),
    .io_out_bits_traceTag   (io_in_rx_dat_bits_traceTag),
    .io_out_bits_rsvdc      (io_in_rx_dat_bits_rsvdc),
    .io_out_bits_be         (io_in_rx_dat_bits_be),
    .io_out_bits_data       (io_in_rx_dat_bits_data),
    .io_out_bits_dataCheck  (io_in_rx_dat_bits_dataCheck),
    .io_out_bits_poison     (io_in_rx_dat_bits_poison),
    .io_state_state         (link_st[DIR_RX]),
    .io_reclaimLCredit      (rxdat_reclaim)
  );

  // ===========================================================================
  //  本核直接驱动的输出 (其余输出由上面子模块直接连出)
  // ===========================================================================
  assign io_in_tx_req_ready       = txreq_in_ready;
  assign io_in_rx_rsp_valid       = rxrsp_out_valid;
  assign io_in_rx_rsp_bits_opcode = rxrsp_out_opcode;
  assign io_out_txsactive         = txsactive_q;
  assign io_out_syscoreq          = syscoreq_q;
  assign io_out_tx_linkactivereq  = tx_linkactivereq_q;
  assign io_out_rx_linkactiveack  = rx_linkactiveack_q;

endmodule

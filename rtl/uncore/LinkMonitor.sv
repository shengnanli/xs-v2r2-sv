// =============================================================================
// LinkMonitor —— L2 的 CHI 链路层（RN-F 侧）：链路激活握手 + L-Credit 流控 + flit 打包/解包
//
// Scala：coupledL2/src/main/scala/coupledL2/tl2chi/chi/LinkLayer.scala，class LinkMonitor
//   （本配置 enableL2Flush=false ⇒ 没有 exitco 端口；txSourceReady=false ⇒ TX 走 Decoupled2LCredit）。
// 位置：TL2CHICoupledL2 里 L2 与 CHI 互联之间的最后一层。上面 io_in_* 是 L2 内部的
//   Decoupled(ready/valid) 通道（tx: req/rsp/dat 发出，rx: rsp/dat/snp 收进），下面 io_out_* 是
//   CHI 物理链路：每通道 flitpend/flitv/flit + 反向 lcrdv（L-Credit），外加 linkactive 握手线、
//   syscoreq/syscoack 系统一致性握手、txsactive。
//
// 机制：
//   §1 链路态机（tx_state / rx_state）：每个方向由 {linkactivereq, linkactiveack} 两根线直接
//      译码成 STOP / ACTIVATE / RUN / DEACTIVATE，打一拍后下发给该方向的 3 个 flit 转换子模块
//      （只有 RUN 才发 flit / 发信用；DEACTIVATE 时要把信用收回）。
//   §2 本端驱动的握手线：
//      tx.linkactivereq = RegNext(!exitcoDone)          本端总想激活 TX 链路
//      rx.linkactiveack = RegNext(RegNext(rx.linkactivereq) || !rxDeact)
//                         对端撤 linkactivereq 后，要等 3 个 RX 子模块都 reclaim 完（不再欠
//                         对端信用）才撤 ack —— 这就是 CHI 去激活要求的"把 L-Credit 收回来"。
//      syscoreq   = RegNext(!exitco) = 复位后恒 1（本配置 exitco 恒 0）
//      txsactive  = RegNext(!exitcoDone)
//      exitcoDone = !syscoreq && !syscoack && RegNext(true.B)
//   §3/§4 6 个 flit 转换子模块（本仓已签重写件，两侧白盒）：见各自文件。
//   §5 3 个 64 位性能计数器（RetryAck / PCrdGrant 响应数、allowRetry=0 的请求数）：Scala 里
//      dontTouch 保住、但没有任何输出 —— golden 里同样存在且无扇出（FM 的 matched-unread 点，
//      由 vmucp 实比，见 verif/fm_target_config/LinkMonitor.tcl）。
//
// 怪癖（照 golden 原样，不"修"）：
//   · exitcoDone 在本配置下恒 0：syscoreq 寄存器与 RegNext(true.B) 是两个"复位 0、之后恒 1"的
//     寄存器，永远同值，所以 !syscoreq && RegNext(true) ≡ 0。golden 照样留着这两个寄存器和
//     syscoack 这条输入，本文件也逐个保留（不化简成常量），于是 FM 可以逐寄存器配对。
//   · tx.linkactivereq 与 txsactive 是两个同次态的寄存器（golden 也是两个），不合并。
//   · RegNext(rx.linkactivereq)（rx_linkactivereq_q）没有复位，golden 同。
// =============================================================================
package linkmonitor_pkg;
  // LINKACTIVE 链路态（LinkLayer.scala LinkStates）
  typedef enum logic [1:0] {
    LINK_STOP       = 2'd0,  // req=0 ack=0
    LINK_ACTIVATE   = 2'd1,  // req=1 ack=0：已请求，待对端确认
    LINK_RUN        = 2'd2,  // req=1 ack=1：正常收发 flit
    LINK_DEACTIVATE = 2'd3   // req=0 ack=1：已撤请求，待对端撤确认
  } link_state_e;

  // MuxLookup(Cat(linkactivereq, linkactiveack), STOP)
  function automatic link_state_e decode_link_state(input logic req, input logic ack);
    unique case ({req, ack})
      2'b10:   decode_link_state = LINK_ACTIVATE;
      2'b11:   decode_link_state = LINK_RUN;
      2'b01:   decode_link_state = LINK_DEACTIVATE;
      default: decode_link_state = LINK_STOP;
    endcase
  endfunction

  // 性能计数器关心的 CHI RSP opcode（HasCHIOpcodes）
  localparam logic [4:0] RSP_RETRY_ACK  = 5'h03;
  localparam logic [4:0] RSP_PCRD_GRANT = 5'h07;
endpackage

// =============================================================================
// xs_LinkMonitor_core —— LinkMonitor 自己的逻辑（§1 态机、§2 握手线、§5 计数器）
//   flit 转换全在 6 个子模块里；本核只看握手线、3 个 reclaim 和两处 fire。
// =============================================================================
module xs_LinkMonitor_core
  import linkmonitor_pkg::*;
(
  input  logic       clock,
  input  logic       reset,
  // CHI 握手线
  input  logic       tx_linkactiveack,     // 对端对本端 TX 激活请求的确认
  input  logic       rx_linkactivereq,     // 对端请求激活本端 RX
  input  logic       syscoack,             // 对端系统一致性确认
  output logic       tx_linkactivereq,
  output logic       rx_linkactiveack,
  output logic       syscoreq,
  output logic       txsactive,
  // 下发给 flit 转换子模块的链路态
  output logic [1:0] tx_state,
  output logic [1:0] rx_state,
  // 3 个 RX 子模块：已不欠对端 L-Credit
  input  logic       rxsnp_reclaim,
  input  logic       rxrsp_reclaim,
  input  logic       rxdat_reclaim,
  // 计数器的事件源
  input  logic       rxrsp_fire,           // io_in.rx.rsp.fire
  input  logic [4:0] rxrsp_opcode,
  input  logic       txreq_fire,           // io_in.tx.req.fire
  input  logic       txreq_allow_retry
);
  // ---------------------------------------------------------------------------
  // §2 握手线的寄存器（全部 RegNext，init=false 的那些异步复位）
  // ---------------------------------------------------------------------------
  logic tx_linkactivereq_q;   // RegNext(!exitcoDone, false)
  logic txsactive_q;          // RegNext(!exitcoDone, false)
  logic syscoreq_q;           // RegNext(!exitco, false)，exitco 恒 0
  logic out_of_reset_q;       // RegNext(true.B, false)：复位后第一拍起为 1
  logic rx_linkactivereq_q;   // RegNext(rx.linkactivereq)，无复位
  logic rx_linkactiveack_q;   // RegNext(rx_linkactivereq_q || !rxDeact, false)
  logic exitco_done;
  logic rx_deact;

  // 退出一致性域完成：syscoreq 已撤且对端已确认（本配置恒 0，见文件头）
  assign exitco_done = ~syscoreq_q & ~syscoack & out_of_reset_q;
  // 3 个 RX 子模块都不欠信用，RX 才算去激活完成
  assign rx_deact    = rxsnp_reclaim & rxrsp_reclaim & rxdat_reclaim;

  // ---------------------------------------------------------------------------
  // §1 链路态机：每个方向按 {req, ack} 译码，打一拍
  // ---------------------------------------------------------------------------
  link_state_e tx_state_q, rx_state_q;

  // §5 性能计数器（无输出，见文件头）。名字照 Scala / golden（retryAckCnt …）：它们没有扇出，
  //    FM 的签名分析配不上无扇出的寄存器，只能靠同名配对（第一跑名字不同时 192 位全成了
  //    unmatched unread，见 docs/lanes/l2-link_prereg.md §4.4）。
  logic [63:0] retryAckCnt;
  logic [63:0] pCrdGrantCnt;
  logic [63:0] noAllowRetryCnt;

  always_ff @(posedge clock or posedge reset) begin
    if (reset) begin
      tx_state_q         <= LINK_STOP;
      rx_state_q         <= LINK_STOP;
      tx_linkactivereq_q <= 1'b0;
      txsactive_q        <= 1'b0;
      syscoreq_q         <= 1'b0;
      out_of_reset_q     <= 1'b0;
      rx_linkactiveack_q <= 1'b0;
      retryAckCnt        <= '0;
      pCrdGrantCnt       <= '0;
      noAllowRetryCnt    <= '0;
    end else begin
      tx_state_q         <= decode_link_state(tx_linkactivereq_q, tx_linkactiveack);
      rx_state_q         <= decode_link_state(rx_linkactivereq, rx_linkactiveack_q);
      tx_linkactivereq_q <= ~exitco_done;
      txsactive_q        <= ~exitco_done;
      syscoreq_q         <= 1'b1;
      out_of_reset_q     <= 1'b1;
      rx_linkactiveack_q <= rx_linkactivereq_q | ~rx_deact;
      if (rxrsp_fire && rxrsp_opcode == RSP_RETRY_ACK)
        retryAckCnt <= retryAckCnt + 64'd1;
      if (rxrsp_fire && rxrsp_opcode == RSP_PCRD_GRANT)
        pCrdGrantCnt <= pCrdGrantCnt + 64'd1;
      if (txreq_fire && !txreq_allow_retry)
        noAllowRetryCnt <= noAllowRetryCnt + 64'd1;
    end
  end

  always_ff @(posedge clock)
    rx_linkactivereq_q <= rx_linkactivereq;

  assign tx_state         = tx_state_q;
  assign rx_state         = rx_state_q;
  assign tx_linkactivereq = tx_linkactivereq_q;
  assign rx_linkactiveack = rx_linkactiveack_q;
  assign syscoreq         = syscoreq_q;
  assign txsactive        = txsactive_q;
endmodule

// =============================================================================
// LinkMonitor —— golden 同名顶层：本核 + 6 个 flit 转换子模块（例化名与 golden 相同）
// =============================================================================
module LinkMonitor (
  input  logic          clock,
  input  logic          reset,
  output logic          io_in_tx_req_ready,
  input  logic          io_in_tx_req_valid,
  input  logic [3:0]    io_in_tx_req_bits_qos,
  input  logic [10:0]   io_in_tx_req_bits_tgtID,
  input  logic [11:0]   io_in_tx_req_bits_txnID,
  input  logic [10:0]   io_in_tx_req_bits_returnNID,
  input  logic          io_in_tx_req_bits_stashNIDValid,
  input  logic [11:0]   io_in_tx_req_bits_returnTxnID,
  input  logic [6:0]    io_in_tx_req_bits_opcode,
  input  logic [2:0]    io_in_tx_req_bits_size,
  input  logic [47:0]   io_in_tx_req_bits_addr,
  input  logic          io_in_tx_req_bits_ns,
  input  logic          io_in_tx_req_bits_likelyshared,
  input  logic          io_in_tx_req_bits_allowRetry,
  input  logic [1:0]    io_in_tx_req_bits_order,
  input  logic [3:0]    io_in_tx_req_bits_pCrdType,
  input  logic          io_in_tx_req_bits_memAttr_allocate,
  input  logic          io_in_tx_req_bits_memAttr_cacheable,
  input  logic          io_in_tx_req_bits_memAttr_device,
  input  logic          io_in_tx_req_bits_memAttr_ewa,
  input  logic          io_in_tx_req_bits_snpAttr,
  input  logic [7:0]    io_in_tx_req_bits_lpIDWithPadding,
  input  logic          io_in_tx_req_bits_snoopMe,
  input  logic          io_in_tx_req_bits_expCompAck,
  input  logic [1:0]    io_in_tx_req_bits_tagOp,
  input  logic          io_in_tx_req_bits_traceTag,
  input  logic          io_in_tx_req_bits_mpam_perfMonGroup,
  input  logic [8:0]    io_in_tx_req_bits_mpam_partID,
  input  logic          io_in_tx_req_bits_mpam_mpamNS,
  input  logic [3:0]    io_in_tx_req_bits_rsvdc,
  output logic          io_in_tx_rsp_ready,
  input  logic          io_in_tx_rsp_valid,
  input  logic [3:0]    io_in_tx_rsp_bits_qos,
  input  logic [10:0]   io_in_tx_rsp_bits_tgtID,
  input  logic [11:0]   io_in_tx_rsp_bits_txnID,
  input  logic [4:0]    io_in_tx_rsp_bits_opcode,
  input  logic [1:0]    io_in_tx_rsp_bits_respErr,
  input  logic [2:0]    io_in_tx_rsp_bits_resp,
  input  logic [2:0]    io_in_tx_rsp_bits_fwdState,
  input  logic [2:0]    io_in_tx_rsp_bits_cBusy,
  input  logic [11:0]   io_in_tx_rsp_bits_dbID,
  input  logic [3:0]    io_in_tx_rsp_bits_pCrdType,
  input  logic [1:0]    io_in_tx_rsp_bits_tagOp,
  input  logic          io_in_tx_rsp_bits_traceTag,
  output logic          io_in_tx_dat_ready,
  input  logic          io_in_tx_dat_valid,
  input  logic [3:0]    io_in_tx_dat_bits_qos,
  input  logic [10:0]   io_in_tx_dat_bits_tgtID,
  input  logic [11:0]   io_in_tx_dat_bits_txnID,
  input  logic [10:0]   io_in_tx_dat_bits_homeNID,
  input  logic [3:0]    io_in_tx_dat_bits_opcode,
  input  logic [1:0]    io_in_tx_dat_bits_respErr,
  input  logic [2:0]    io_in_tx_dat_bits_resp,
  input  logic [3:0]    io_in_tx_dat_bits_dataSource,
  input  logic [2:0]    io_in_tx_dat_bits_cBusy,
  input  logic [11:0]   io_in_tx_dat_bits_dbID,
  input  logic [1:0]    io_in_tx_dat_bits_ccID,
  input  logic [1:0]    io_in_tx_dat_bits_dataID,
  input  logic [1:0]    io_in_tx_dat_bits_tagOp,
  input  logic [7:0]    io_in_tx_dat_bits_tag,
  input  logic [1:0]    io_in_tx_dat_bits_tu,
  input  logic          io_in_tx_dat_bits_traceTag,
  input  logic [3:0]    io_in_tx_dat_bits_rsvdc,
  input  logic [31:0]   io_in_tx_dat_bits_be,
  input  logic [255:0]  io_in_tx_dat_bits_data,
  input  logic [31:0]   io_in_tx_dat_bits_dataCheck,
  input  logic [3:0]    io_in_tx_dat_bits_poison,
  input  logic          io_in_rx_rsp_ready,
  output logic          io_in_rx_rsp_valid,
  output logic [3:0]    io_in_rx_rsp_bits_qos,
  output logic [10:0]   io_in_rx_rsp_bits_tgtID,
  output logic [10:0]   io_in_rx_rsp_bits_srcID,
  output logic [11:0]   io_in_rx_rsp_bits_txnID,
  output logic [4:0]    io_in_rx_rsp_bits_opcode,
  output logic [1:0]    io_in_rx_rsp_bits_respErr,
  output logic [2:0]    io_in_rx_rsp_bits_resp,
  output logic [2:0]    io_in_rx_rsp_bits_fwdState,
  output logic [2:0]    io_in_rx_rsp_bits_cBusy,
  output logic [11:0]   io_in_rx_rsp_bits_dbID,
  output logic [3:0]    io_in_rx_rsp_bits_pCrdType,
  output logic [1:0]    io_in_rx_rsp_bits_tagOp,
  output logic          io_in_rx_rsp_bits_traceTag,
  input  logic          io_in_rx_dat_ready,
  output logic          io_in_rx_dat_valid,
  output logic [3:0]    io_in_rx_dat_bits_qos,
  output logic [10:0]   io_in_rx_dat_bits_tgtID,
  output logic [10:0]   io_in_rx_dat_bits_srcID,
  output logic [11:0]   io_in_rx_dat_bits_txnID,
  output logic [10:0]   io_in_rx_dat_bits_homeNID,
  output logic [3:0]    io_in_rx_dat_bits_opcode,
  output logic [1:0]    io_in_rx_dat_bits_respErr,
  output logic [2:0]    io_in_rx_dat_bits_resp,
  output logic [3:0]    io_in_rx_dat_bits_dataSource,
  output logic [2:0]    io_in_rx_dat_bits_cBusy,
  output logic [11:0]   io_in_rx_dat_bits_dbID,
  output logic [1:0]    io_in_rx_dat_bits_ccID,
  output logic [1:0]    io_in_rx_dat_bits_dataID,
  output logic [1:0]    io_in_rx_dat_bits_tagOp,
  output logic [7:0]    io_in_rx_dat_bits_tag,
  output logic [1:0]    io_in_rx_dat_bits_tu,
  output logic          io_in_rx_dat_bits_traceTag,
  output logic [3:0]    io_in_rx_dat_bits_rsvdc,
  output logic [31:0]   io_in_rx_dat_bits_be,
  output logic [255:0]  io_in_rx_dat_bits_data,
  output logic [31:0]   io_in_rx_dat_bits_dataCheck,
  output logic [3:0]    io_in_rx_dat_bits_poison,
  input  logic          io_in_rx_snp_ready,
  output logic          io_in_rx_snp_valid,
  output logic [3:0]    io_in_rx_snp_bits_qos,
  output logic [10:0]   io_in_rx_snp_bits_srcID,
  output logic [11:0]   io_in_rx_snp_bits_txnID,
  output logic [10:0]   io_in_rx_snp_bits_fwdNID,
  output logic [11:0]   io_in_rx_snp_bits_fwdTxnID,
  output logic [4:0]    io_in_rx_snp_bits_opcode,
  output logic [44:0]   io_in_rx_snp_bits_addr,
  output logic          io_in_rx_snp_bits_ns,
  output logic          io_in_rx_snp_bits_doNotGoToSD,
  output logic          io_in_rx_snp_bits_retToSrc,
  output logic          io_in_rx_snp_bits_traceTag,
  output logic          io_in_rx_snp_bits_mpam_perfMonGroup,
  output logic [8:0]    io_in_rx_snp_bits_mpam_partID,
  output logic          io_in_rx_snp_bits_mpam_mpamNS,
  output logic          io_out_txsactive,
  input  logic          io_out_rxsactive,
  output logic          io_out_syscoreq,
  input  logic          io_out_syscoack,
  output logic          io_out_tx_linkactivereq,
  input  logic          io_out_tx_linkactiveack,
  output logic          io_out_tx_req_flitpend,
  output logic          io_out_tx_req_flitv,
  output logic [161:0]  io_out_tx_req_flit,
  input  logic          io_out_tx_req_lcrdv,
  output logic          io_out_tx_rsp_flitpend,
  output logic          io_out_tx_rsp_flitv,
  output logic [72:0]   io_out_tx_rsp_flit,
  input  logic          io_out_tx_rsp_lcrdv,
  output logic          io_out_tx_dat_flitpend,
  output logic          io_out_tx_dat_flitv,
  output logic [421:0]  io_out_tx_dat_flit,
  input  logic          io_out_tx_dat_lcrdv,
  input  logic          io_out_rx_linkactivereq,
  output logic          io_out_rx_linkactiveack,
  input  logic          io_out_rx_rsp_flitpend,
  input  logic          io_out_rx_rsp_flitv,
  input  logic [72:0]   io_out_rx_rsp_flit,
  output logic          io_out_rx_rsp_lcrdv,
  input  logic          io_out_rx_dat_flitpend,
  input  logic          io_out_rx_dat_flitv,
  input  logic [421:0]  io_out_rx_dat_flit,
  output logic          io_out_rx_dat_lcrdv,
  input  logic          io_out_rx_snp_flitpend,
  input  logic          io_out_rx_snp_flitv,
  input  logic [114:0]  io_out_rx_snp_flit,
  output logic          io_out_rx_snp_lcrdv,
  input  logic [10:0]   io_nodeID
);
  logic [1:0] tx_state;
  logic [1:0] rx_state;
  logic       txreq_in_ready;
  logic       rxrsp_valid;
  logic [4:0] rxrsp_opcode;
  logic       rxsnp_reclaim;
  logic       rxrsp_reclaim;
  logic       rxdat_reclaim;

  // ---------------------------------------------------------------------------
  // §1/§2/§5 链路态机、握手线、计数器
  // ---------------------------------------------------------------------------
  xs_LinkMonitor_core u_core (
    .clock             (clock),
    .reset             (reset),
    .tx_linkactiveack  (io_out_tx_linkactiveack),
    .rx_linkactivereq  (io_out_rx_linkactivereq),
    .syscoack          (io_out_syscoack),
    .tx_linkactivereq  (io_out_tx_linkactivereq),
    .rx_linkactiveack  (io_out_rx_linkactiveack),
    .syscoreq          (io_out_syscoreq),
    .txsactive         (io_out_txsactive),
    .tx_state          (tx_state),
    .rx_state          (rx_state),
    .rxsnp_reclaim     (rxsnp_reclaim),
    .rxrsp_reclaim     (rxrsp_reclaim),
    .rxdat_reclaim     (rxdat_reclaim),
    .rxrsp_fire        (io_in_rx_rsp_ready & rxrsp_valid),
    .rxrsp_opcode      (rxrsp_opcode),
    .txreq_fire        (txreq_in_ready & io_in_tx_req_valid),
    .txreq_allow_retry (io_in_tx_req_bits_allowRetry)
  );

  // ---------------------------------------------------------------------------
  // §3 TX：上层 Decoupled -> CHI flit（Decoupled2LCredit，带 L-Credit 发送）
  //   三个发送端都按 tx_state 决定能否发 flit / 何时把手里的信用还掉；srcID 统一注入 io_nodeID
  //   （Scala setSrcID）。txreq 的 in_ready 还要回来给 noAllowRetry 计数用。
  // ---------------------------------------------------------------------------
  Decoupled2LCredit Decoupled2LCredit_txreqLink (
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
    .io_state_state               (tx_state)
  );
  Decoupled2LCredit_1 Decoupled2LCredit_txrspLink (
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
    .io_state_state      (tx_state)
  );
  Decoupled2LCredit_2 Decoupled2LCredit_txdatLink (
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
    .io_state_state        (tx_state)
  );

  // ---------------------------------------------------------------------------
  // §4 RX：CHI flit -> 上层 Decoupled（LCredit2Decoupled，带 L-Credit 接收）
  //   rxsnp 是阻塞型（4 信用 + 4 项队列 Queue4_CHISNP），rxrsp / rxdat 是非阻塞型（15 信用、
  //   无队列）。三者各报 reclaimLCredit（手里没有欠对端的信用），合起来决定 rx 能否去激活。
  //   rxrsp 的 valid/opcode 还要回来给 RetryAck / PCrdGrant 计数用。
  // ---------------------------------------------------------------------------
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
    .io_state_state                (rx_state),
    .io_reclaimLCredit             (rxsnp_reclaim)
  );
  LCredit2Decoupled_1 LCredit2Decoupled_rxrsp (
    .clock                (clock),
    .reset                (reset),
    .io_in_flitv          (io_out_rx_rsp_flitv),
    .io_in_flit           (io_out_rx_rsp_flit),
    .io_in_lcrdv          (io_out_rx_rsp_lcrdv),
    .io_out_ready         (io_in_rx_rsp_ready),
    .io_out_valid         (rxrsp_valid),
    .io_out_bits_qos      (io_in_rx_rsp_bits_qos),
    .io_out_bits_tgtID    (io_in_rx_rsp_bits_tgtID),
    .io_out_bits_srcID    (io_in_rx_rsp_bits_srcID),
    .io_out_bits_txnID    (io_in_rx_rsp_bits_txnID),
    .io_out_bits_opcode   (rxrsp_opcode),
    .io_out_bits_respErr  (io_in_rx_rsp_bits_respErr),
    .io_out_bits_resp     (io_in_rx_rsp_bits_resp),
    .io_out_bits_fwdState (io_in_rx_rsp_bits_fwdState),
    .io_out_bits_cBusy    (io_in_rx_rsp_bits_cBusy),
    .io_out_bits_dbID     (io_in_rx_rsp_bits_dbID),
    .io_out_bits_pCrdType (io_in_rx_rsp_bits_pCrdType),
    .io_out_bits_tagOp    (io_in_rx_rsp_bits_tagOp),
    .io_out_bits_traceTag (io_in_rx_rsp_bits_traceTag),
    .io_state_state       (rx_state),
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
    .io_state_state         (rx_state),
    .io_reclaimLCredit      (rxdat_reclaim)
  );

  assign io_in_tx_req_ready       = txreq_in_ready;
  assign io_in_rx_rsp_valid       = rxrsp_valid;
  assign io_in_rx_rsp_bits_opcode = rxrsp_opcode;
endmodule

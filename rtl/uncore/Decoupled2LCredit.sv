// =============================================================================
//  Decoupled2LCredit —— CHI 链路层 发送侧 握手转换 可读重写核 (xs_Decoupled2LCredit_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../tl2chi/chi/LinkLayer.scala (class Decoupled2LCredit)
//  把内部 DecoupledIO(valid/ready) 请求打包成 CHI 链路层 L-Credit flit 流发出。
//  本单态: REQ 通道 (payload 162-bit)。无子模块。
//
//  ===== LinkStates (io_state_state 2-bit) =====
//    STOP=0  ACTIVATE=1  RUN=2  DEACTIVATE=3
//    disableFlit    = STOP|ACTIVATE  (此时不接收上游 flit)
//    disableLCredit = STOP           (此时不消费对端给的 L-Credit)
//
//  ===== L-Credit 池 (接收方通过 lcrdv 逐个授信, 最多 15) =====
//    acceptLCredit = lcrdv & ~disableLCredit      (拿到一个信用)
//    returnLCreditValid = ~in.valid & DEACTIVATE & pool!=0  (退出态把多余信用以空 flit 退还)
//    flitv = in.fire | returnLCreditValid          (本拍发出一个 flit)
//    pool: acceptLCredit&~flitv ⇒ +1 ; ~acceptLCredit&flitv ⇒ -1
//    in.ready = pool!=0 & ~disableFlit
//
//  ===== 输出 (全部打一拍) =====
//    flitpend = 复位后恒 1 ; flitv = RegNext(flitv) ; flit = RegEnable(payload, flitv)
//    payload = in.valid ? {所有 bits 字段按 getElements.reverse 顺序拼} : 0 (0 即 LCrdReturn)
// =============================================================================
module xs_Decoupled2LCredit_core (
  input          clock,
  input          reset,
  // ---- io.in (Flipped DecoupledIO, CHIREQ payload) ----
  output         io_in_ready,
  input          io_in_valid,
  input  [3:0]   io_in_bits_qos,
  input  [10:0]  io_in_bits_tgtID,
  input  [10:0]  io_in_bits_srcID,
  input  [11:0]  io_in_bits_txnID,
  input  [10:0]  io_in_bits_returnNID,
  input          io_in_bits_stashNIDValid,
  input  [11:0]  io_in_bits_returnTxnID,
  input  [6:0]   io_in_bits_opcode,
  input  [2:0]   io_in_bits_size,
  input  [47:0]  io_in_bits_addr,
  input          io_in_bits_ns,
  input          io_in_bits_likelyshared,
  input          io_in_bits_allowRetry,
  input  [1:0]   io_in_bits_order,
  input  [3:0]   io_in_bits_pCrdType,
  input          io_in_bits_memAttr_allocate,
  input          io_in_bits_memAttr_cacheable,
  input          io_in_bits_memAttr_device,
  input          io_in_bits_memAttr_ewa,
  input          io_in_bits_snpAttr,
  input  [7:0]   io_in_bits_lpIDWithPadding,
  input          io_in_bits_snoopMe,
  input          io_in_bits_expCompAck,
  input  [1:0]   io_in_bits_tagOp,
  input          io_in_bits_traceTag,
  input          io_in_bits_mpam_perfMonGroup,
  input  [8:0]   io_in_bits_mpam_partID,
  input          io_in_bits_mpam_mpamNS,
  input  [3:0]   io_in_bits_rsvdc,
  // ---- io.out (ChannelIO, CHI 链路层 flit) ----
  output         io_out_flitpend,
  output         io_out_flitv,
  output [161:0] io_out_flit,
  input          io_out_lcrdv,
  // ---- io.state ----
  input  [1:0]   io_state_state
);

  reg  [3:0] lcreditPool;
  reg        out_flitpend;
  reg        out_flitv;
  reg  [161:0] out_flit;

  // ---- 链路状态译码 ----
  wire disableFlit       = (io_state_state == 2'h0) | (io_state_state == 2'h1); // STOP/ACTIVATE
  wire disableLCredit    = (io_state_state == 2'h0);                            // STOP
  wire acceptLCredit     = io_out_lcrdv & ~disableLCredit;
  wire in_ready          = (|lcreditPool) & ~disableFlit;
  wire returnLCreditValid = ~io_in_valid & (io_state_state == 2'h3) & (|lcreditPool); // DEACTIVATE
  wire flitv             = (in_ready & io_in_valid) | returnLCreditValid;

  assign io_in_ready = in_ready;

  // ---- L-Credit 池 + flitpend/flitv 打拍 (异步复位) ----
  always @(posedge clock or posedge reset) begin
    if (reset) begin
      lcreditPool  <= 4'h0;
      out_flitpend <= 1'h0;
      out_flitv    <= 1'h0;
    end
    else begin
      if (acceptLCredit) begin
        if (~flitv) lcreditPool <= lcreditPool + 4'h1;  // 收信用而本拍不发 ⇒ 池 +1
      end
      else if (flitv)
        lcreditPool <= lcreditPool - 4'h1;              // 发 flit 而本拍不收信用 ⇒ 池 -1
      out_flitpend <= 1'h1;
      out_flitv    <= flitv;
    end
  end

  // ---- flit payload 打拍 (仅 flitv 时更新, 无复位) ----
  always @(posedge clock) begin
    if (flitv)
      out_flit <= io_in_valid
        ? {io_in_bits_rsvdc,
           io_in_bits_mpam_perfMonGroup,
           io_in_bits_mpam_partID,
           io_in_bits_mpam_mpamNS,
           io_in_bits_traceTag,
           io_in_bits_tagOp,
           io_in_bits_expCompAck,
           io_in_bits_snoopMe,
           io_in_bits_lpIDWithPadding,
           io_in_bits_snpAttr,
           io_in_bits_memAttr_allocate,
           io_in_bits_memAttr_cacheable,
           io_in_bits_memAttr_device,
           io_in_bits_memAttr_ewa,
           io_in_bits_pCrdType,
           io_in_bits_order,
           io_in_bits_allowRetry,
           io_in_bits_likelyshared,
           io_in_bits_ns,
           io_in_bits_addr,
           io_in_bits_size,
           io_in_bits_opcode,
           io_in_bits_returnTxnID,
           io_in_bits_stashNIDValid,
           io_in_bits_returnNID,
           io_in_bits_txnID,
           io_in_bits_srcID,
           io_in_bits_tgtID,
           io_in_bits_qos}
        : 162'h0;   // 退还信用时发空 flit (opcode=0=LCrdReturn)
  end

  assign io_out_flitpend = out_flitpend;
  assign io_out_flitv    = out_flitv;
  assign io_out_flit     = out_flit;

endmodule

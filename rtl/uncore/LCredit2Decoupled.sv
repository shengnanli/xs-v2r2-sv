// =============================================================================
//  LCredit2Decoupled —— CHI 链路层 接收侧 握手转换 可读重写核 (xs_LCredit2Decoupled_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../tl2chi/chi/LinkLayer.scala (class LCredit2Decoupled)
//  接收对端 CHI 链路层 flit 流, 解包成内部 DecoupledIO 输出。本单态: SNP 通道
//  (payload 115-bit), lcreditNum=4, blocking=true (经一个 4 深 Queue4_CHISNP 缓冲, 黑盒)。
//
//  ===== L-Credit 授信 (本方作为接收者, 通过 lcrdv 逐个发信用给对端) =====
//    lcreditInflight : 已发出、对端尚未用掉的信用数 ; lcreditPool : 还可发的信用数
//    不变式: lcreditInflight + lcreditPool === lcreditNum(=4)
//    accept = lcreditInflight!=0 & in.flitv   (对端用掉一个信用、送来一个 flit)
//    lcreditOut = (lcreditPool > 队列已占) & state==RUN  (有富余且队列留得下 ⇒ 再发一个信用)
//    in.lcrdv = RegNext(lcreditOut)  (信用脉冲打一拍发给对端)
//    更新: lcreditOut&~accept ⇒ inflight+1/pool-1 ; ~lcreditOut&accept ⇒ inflight-1/pool+1
//    reclaimLCredit = lcreditInflight==0  (链路可安全关闭)
//
//  ===== 队列 (blocking) + LCrdReturn 过滤 =====
//    enq.valid = accept, enq.bits 从 in.flit 各位段解包。
//    deq.opcode==0 ⇒ 这是对端退还的 LCrdReturn 空 flit: 直接吞掉(deq.ready=1)、不向下游输出。
//    out.valid = ~isLCrdReturn & deq.valid ; deq.ready = isLCrdReturn | out.ready
// =============================================================================
module xs_LCredit2Decoupled_core (
  input          clock,
  input          reset,
  // ---- io.in (Flipped ChannelIO, CHI 链路层 flit) ----
  input          io_in_flitv,
  input  [114:0] io_in_flit,
  output         io_in_lcrdv,
  // ---- io.out (DecoupledIO CHISNP) ----
  input          io_out_ready,
  output         io_out_valid,
  output [3:0]   io_out_bits_qos,
  output [10:0]  io_out_bits_srcID,
  output [11:0]  io_out_bits_txnID,
  output [10:0]  io_out_bits_fwdNID,
  output [11:0]  io_out_bits_fwdTxnID,
  output [4:0]   io_out_bits_opcode,
  output [44:0]  io_out_bits_addr,
  output         io_out_bits_ns,
  output         io_out_bits_doNotGoToSD,
  output         io_out_bits_retToSrc,
  output         io_out_bits_traceTag,
  output         io_out_bits_mpam_perfMonGroup,
  output [8:0]   io_out_bits_mpam_partID,
  output         io_out_bits_mpam_mpamNS,
  // ---- io.state / reclaim ----
  input  [1:0]   io_state_state,
  output         io_reclaimLCredit
);

  reg  [2:0] lcreditInflight;
  reg  [2:0] lcreditPool;
  reg        in_lcrdv_q;

  wire [2:0] queue_count;
  wire       queue_enq_ready;
  wire       queue_deq_valid;
  wire [4:0] queue_deq_opcode;

  // ---- 信用记账 ----
  wire accept     = (|lcreditInflight) & io_in_flitv;
  wire lcreditOut = (lcreditPool > queue_count) & (io_state_state == 2'h2); // RUN

  always @(posedge clock or posedge reset) begin
    if (reset) begin
      lcreditInflight <= 3'h0;
      lcreditPool     <= 3'h4;   // lcreditNum = 4
      in_lcrdv_q      <= 1'h0;
    end
    else begin
      if (lcreditOut) begin
        if (~accept) begin
          lcreditInflight <= lcreditInflight + 3'h1;
          lcreditPool     <= lcreditPool - 3'h1;
        end
      end
      else if (accept) begin
        lcreditInflight <= lcreditInflight - 3'h1;
        lcreditPool     <= lcreditPool + 3'h1;
      end
      in_lcrdv_q <= lcreditOut;
    end
  end

  assign io_in_lcrdv       = in_lcrdv_q;
  assign io_reclaimLCredit = lcreditInflight == 3'h0;

  // ---- LCrdReturn 过滤 ----
  wire isLCrdReturn = queue_deq_valid & (queue_deq_opcode == 5'h0);
  assign io_out_valid       = ~isLCrdReturn & queue_deq_valid;
  assign io_out_bits_opcode = queue_deq_opcode;

  // ---- 4 深缓冲 (黑盒): enq 从 flit 解包, deq 直连输出 ----
  Queue4_CHISNP queue (
    .clock                         (clock),
    .reset                         (reset),
    .io_enq_ready                  (queue_enq_ready),
    .io_enq_valid                  (accept),
    .io_enq_bits_qos               (io_in_flit[3:0]),
    .io_enq_bits_srcID             (io_in_flit[14:4]),
    .io_enq_bits_txnID             (io_in_flit[26:15]),
    .io_enq_bits_fwdNID            (io_in_flit[37:27]),
    .io_enq_bits_fwdTxnID          (io_in_flit[49:38]),
    .io_enq_bits_opcode            (io_in_flit[54:50]),
    .io_enq_bits_addr              (io_in_flit[99:55]),
    .io_enq_bits_ns                (io_in_flit[100]),
    .io_enq_bits_doNotGoToSD       (io_in_flit[101]),
    .io_enq_bits_retToSrc          (io_in_flit[102]),
    .io_enq_bits_traceTag          (io_in_flit[103]),
    .io_enq_bits_mpam_perfMonGroup (io_in_flit[114]),
    .io_enq_bits_mpam_partID       (io_in_flit[113:105]),
    .io_enq_bits_mpam_mpamNS       (io_in_flit[104]),
    .io_deq_ready                  (isLCrdReturn | io_out_ready),
    .io_deq_valid                  (queue_deq_valid),
    .io_deq_bits_qos               (io_out_bits_qos),
    .io_deq_bits_srcID             (io_out_bits_srcID),
    .io_deq_bits_txnID             (io_out_bits_txnID),
    .io_deq_bits_fwdNID            (io_out_bits_fwdNID),
    .io_deq_bits_fwdTxnID          (io_out_bits_fwdTxnID),
    .io_deq_bits_opcode            (queue_deq_opcode),
    .io_deq_bits_addr              (io_out_bits_addr),
    .io_deq_bits_ns                (io_out_bits_ns),
    .io_deq_bits_doNotGoToSD       (io_out_bits_doNotGoToSD),
    .io_deq_bits_retToSrc          (io_out_bits_retToSrc),
    .io_deq_bits_traceTag          (io_out_bits_traceTag),
    .io_deq_bits_mpam_perfMonGroup (io_out_bits_mpam_perfMonGroup),
    .io_deq_bits_mpam_partID       (io_out_bits_mpam_partID),
    .io_deq_bits_mpam_mpamNS       (io_out_bits_mpam_mpamNS),
    .io_count                      (queue_count)
  );

endmodule

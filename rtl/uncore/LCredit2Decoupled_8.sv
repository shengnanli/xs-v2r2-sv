// =============================================================================
//  LCredit2Decoupled_8 —— CHI 链路层 接收侧 握手转换 可读重写核 (xs_LCredit2Decoupled_8_core)
// -----------------------------------------------------------------------------
//  对照 Scala: coupledL2/.../tl2chi/chi/LinkLayer.scala (class LCredit2Decoupled)
//  与 LCredit2Decoupled 同型 (信用记账 + LCrdReturn 过滤 + blocking 队列), lcreditNum=4,
//  仅净荷/队列不同: 本变体 = REQ(162b) (队列 Queue4_CHIREQ, 黑盒)。控制注释见 LCredit2Decoupled.sv。
//  不变式: lcreditInflight + lcreditPool === 4。LinkStates: RUN=2。
// =============================================================================
module xs_LCredit2Decoupled_8_core(
  input          clock,
  input          reset,
  input          io_in_flitv,
  input  [161:0] io_in_flit,
  output         io_in_lcrdv,
  input          io_out_ready,
  output         io_out_valid,
  output [3:0]   io_out_bits_qos,
  output [10:0]  io_out_bits_srcID,
  output [11:0]  io_out_bits_txnID,
  output [10:0]  io_out_bits_returnNID,
  output         io_out_bits_stashNIDValid,
  output [11:0]  io_out_bits_returnTxnID,
  output [6:0]   io_out_bits_opcode,
  output [2:0]   io_out_bits_size,
  output [47:0]  io_out_bits_addr,
  output         io_out_bits_ns,
  output         io_out_bits_likelyshared,
  output         io_out_bits_allowRetry,
  output [1:0]   io_out_bits_order,
  output [3:0]   io_out_bits_pCrdType,
  output         io_out_bits_memAttr_allocate,
  output         io_out_bits_memAttr_cacheable,
  output         io_out_bits_memAttr_device,
  output         io_out_bits_memAttr_ewa,
  output         io_out_bits_snpAttr,
  output [7:0]   io_out_bits_lpIDWithPadding,
  output         io_out_bits_snoopMe,
  output         io_out_bits_expCompAck,
  output [1:0]   io_out_bits_tagOp,
  output         io_out_bits_traceTag,
  output         io_out_bits_mpam_perfMonGroup,
  output [8:0]   io_out_bits_mpam_partID,
  output         io_out_bits_mpam_mpamNS,
  output [3:0]   io_out_bits_rsvdc,
  input  [1:0]   io_state_state,
  output         io_reclaimLCredit
);

  reg  [2:0] lcreditInflight;
  reg  [2:0] lcreditPool;
  reg        in_lcrdv_q;

  wire [2:0] queue_count;
  wire       queue_enq_ready;
  wire       queue_deq_valid;
  wire [6:0] queue_deq_opcode;

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

  // LCrdReturn (opcode==0) 空 flit: 吞掉不输出
  wire isLCrdReturn = queue_deq_valid & (queue_deq_opcode == 7'h0);
  assign io_out_valid       = ~isLCrdReturn & queue_deq_valid;
  assign io_out_bits_opcode = queue_deq_opcode;

  Queue4_CHIREQ queue (
    .clock                         (clock),
    .reset                         (reset),
    .io_enq_ready                  (queue_enq_ready),
    .io_enq_valid                  (accept),
    .io_enq_bits_qos               (io_in_flit[3:0]),
    .io_enq_bits_tgtID             (io_in_flit[14:4]),
    .io_enq_bits_srcID             (io_in_flit[25:15]),
    .io_enq_bits_txnID             (io_in_flit[37:26]),
    .io_enq_bits_returnNID         (io_in_flit[48:38]),
    .io_enq_bits_stashNIDValid     (io_in_flit[49]),
    .io_enq_bits_returnTxnID       (io_in_flit[61:50]),
    .io_enq_bits_opcode            (io_in_flit[68:62]),
    .io_enq_bits_size              (io_in_flit[71:69]),
    .io_enq_bits_addr              (io_in_flit[119:72]),
    .io_enq_bits_ns                (io_in_flit[120]),
    .io_enq_bits_likelyshared      (io_in_flit[121]),
    .io_enq_bits_allowRetry        (io_in_flit[122]),
    .io_enq_bits_order             (io_in_flit[124:123]),
    .io_enq_bits_pCrdType          (io_in_flit[128:125]),
    .io_enq_bits_memAttr_allocate  (io_in_flit[132]),
    .io_enq_bits_memAttr_cacheable (io_in_flit[131]),
    .io_enq_bits_memAttr_device    (io_in_flit[130]),
    .io_enq_bits_memAttr_ewa       (io_in_flit[129]),
    .io_enq_bits_snpAttr           (io_in_flit[133]),
    .io_enq_bits_lpIDWithPadding   (io_in_flit[141:134]),
    .io_enq_bits_snoopMe           (io_in_flit[142]),
    .io_enq_bits_expCompAck        (io_in_flit[143]),
    .io_enq_bits_tagOp             (io_in_flit[145:144]),
    .io_enq_bits_traceTag          (io_in_flit[146]),
    .io_enq_bits_mpam_perfMonGroup (io_in_flit[157]),
    .io_enq_bits_mpam_partID       (io_in_flit[156:148]),
    .io_enq_bits_mpam_mpamNS       (io_in_flit[147]),
    .io_enq_bits_rsvdc             (io_in_flit[161:158]),
    .io_deq_ready                  (isLCrdReturn | io_out_ready),
    .io_deq_valid                  (queue_deq_valid),
    .io_deq_bits_qos               (io_out_bits_qos),
    .io_deq_bits_srcID             (io_out_bits_srcID),
    .io_deq_bits_txnID             (io_out_bits_txnID),
    .io_deq_bits_returnNID         (io_out_bits_returnNID),
    .io_deq_bits_stashNIDValid     (io_out_bits_stashNIDValid),
    .io_deq_bits_returnTxnID       (io_out_bits_returnTxnID),
    .io_deq_bits_opcode            (queue_deq_opcode),
    .io_deq_bits_size              (io_out_bits_size),
    .io_deq_bits_addr              (io_out_bits_addr),
    .io_deq_bits_ns                (io_out_bits_ns),
    .io_deq_bits_likelyshared      (io_out_bits_likelyshared),
    .io_deq_bits_allowRetry        (io_out_bits_allowRetry),
    .io_deq_bits_order             (io_out_bits_order),
    .io_deq_bits_pCrdType          (io_out_bits_pCrdType),
    .io_deq_bits_memAttr_allocate  (io_out_bits_memAttr_allocate),
    .io_deq_bits_memAttr_cacheable (io_out_bits_memAttr_cacheable),
    .io_deq_bits_memAttr_device    (io_out_bits_memAttr_device),
    .io_deq_bits_memAttr_ewa       (io_out_bits_memAttr_ewa),
    .io_deq_bits_snpAttr           (io_out_bits_snpAttr),
    .io_deq_bits_lpIDWithPadding   (io_out_bits_lpIDWithPadding),
    .io_deq_bits_snoopMe           (io_out_bits_snoopMe),
    .io_deq_bits_expCompAck        (io_out_bits_expCompAck),
    .io_deq_bits_tagOp             (io_out_bits_tagOp),
    .io_deq_bits_traceTag          (io_out_bits_traceTag),
    .io_deq_bits_mpam_perfMonGroup (io_out_bits_mpam_perfMonGroup),
    .io_deq_bits_mpam_partID       (io_out_bits_mpam_partID),
    .io_deq_bits_mpam_mpamNS       (io_out_bits_mpam_mpamNS),
    .io_deq_bits_rsvdc             (io_out_bits_rsvdc),
    .io_count                      (queue_count)
  );

endmodule
